-- CERVEJA NA REDE - V28
-- Administração de fotos, estatísticas e troca de senha.
-- Execute este arquivo no Supabase SQL Editor.
-- Mantém os dados existentes.

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- 1) Bucket de fotos
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('player-photos', 'player-photos', true)
on conflict (id) do update set public = true;

-- Leitura e upload continuam disponíveis para usuários autenticados.
drop policy if exists "CNR player photos select" on storage.objects;
drop policy if exists "CNR player photos insert" on storage.objects;
drop policy if exists "CNR player photos update" on storage.objects;
drop policy if exists "CNR player photos delete" on storage.objects;

create policy "CNR player photos select"
on storage.objects for select to authenticated
using (bucket_id = 'player-photos');

create policy "CNR player photos insert"
on storage.objects for insert to authenticated
with check (bucket_id = 'player-photos');

create policy "CNR player photos update"
on storage.objects for update to authenticated
using (bucket_id = 'player-photos')
with check (bucket_id = 'player-photos');

-- ------------------------------------------------------------
-- 2) Configuração da senha de administrador
-- ------------------------------------------------------------
create table if not exists public.admin_settings (
  id integer primary key,
  password_hash text not null,
  updated_at timestamptz not null default now()
);

alter table public.admin_settings enable row level security;
revoke all on table public.admin_settings from anon, authenticated;

-- Senha inicial somente se ainda não existir configuração.
insert into public.admin_settings (id, password_hash)
values (1, crypt('CNRADMIN2026!', gen_salt('bf', 12)))
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- 3) Sessão administrativa por aparelho/usuário autenticado
-- ------------------------------------------------------------
create table if not exists public.admin_sessions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  expires_at timestamptz not null
);

alter table public.admin_sessions enable row level security;
revoke all on table public.admin_sessions from anon, authenticated;

create or replace function public.is_admin_session()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_sessions
    where user_id = auth.uid()
      and expires_at > now()
  );
$$;

revoke all on function public.is_admin_session() from public, anon;
grant execute on function public.is_admin_session() to authenticated;

-- Somente administrador pode apagar objetos do bucket.
create policy "CNR player photos delete admin only"
on storage.objects for delete to authenticated
using (
  bucket_id = 'player-photos'
  and public.is_admin_session()
);

-- ------------------------------------------------------------
-- 4) Login administrativo
-- ------------------------------------------------------------
create or replace function public.admin_login(p_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  stored_hash text;
  uid uuid := auth.uid();
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'message', 'Usuário não autenticado');
  end if;

  select password_hash into stored_hash
  from public.admin_settings
  where id = 1;

  if stored_hash is null or crypt(coalesce(p_password,''), stored_hash) <> stored_hash then
    return jsonb_build_object('ok', false, 'message', 'Senha inválida');
  end if;

  insert into public.admin_sessions(user_id, expires_at)
  values (uid, now() + interval '24 hours')
  on conflict (user_id) do update
    set expires_at = excluded.expires_at;

  return jsonb_build_object('ok', true, 'expires_at', now() + interval '24 hours');
end;
$$;

revoke all on function public.admin_login(text) from public, anon;
grant execute on function public.admin_login(text) to authenticated;

-- ------------------------------------------------------------
-- 5) Logout administrativo
-- ------------------------------------------------------------
create or replace function public.admin_logout()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.admin_sessions where user_id = auth.uid();
  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.admin_logout() from public, anon;
grant execute on function public.admin_logout() to authenticated;

-- ------------------------------------------------------------
-- 6) Alterar senha (somente sessão administrativa ativa)
-- ------------------------------------------------------------
create or replace function public.admin_change_password(p_new_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not public.is_admin_session() then
    return jsonb_build_object('ok', false, 'message', 'Acesso administrativo necessário');
  end if;

  if length(coalesce(p_new_password,'')) < 8 then
    return jsonb_build_object('ok', false, 'message', 'A senha deve ter pelo menos 8 caracteres');
  end if;

  update public.admin_settings
  set password_hash = crypt(p_new_password, gen_salt('bf', 12)),
      updated_at = now()
  where id = 1;

  -- Troca a senha e invalida sessões administrativas dos outros aparelhos.
  delete from public.admin_sessions where user_id <> uid;
  update public.admin_sessions
  set expires_at = now() + interval '24 hours'
  where user_id = uid;

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.admin_change_password(text) from public, anon;
grant execute on function public.admin_change_password(text) to authenticated;

-- ------------------------------------------------------------
-- 7) Autoriza a exclusão de uma foto.
-- A exclusão física continua sendo feita pelo Storage API.
-- ------------------------------------------------------------
create or replace function public.admin_delete_photo(p_path text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin_session() then
    return jsonb_build_object('ok', false, 'message', 'Acesso administrativo necessário');
  end if;

  if coalesce(p_path,'') = '' or p_path like '%..%' or p_path like '/%' then
    return jsonb_build_object('ok', false, 'message', 'Caminho de arquivo inválido');
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.admin_delete_photo(text) from public, anon;
grant execute on function public.admin_delete_photo(text) to authenticated;

-- ------------------------------------------------------------
-- 8) Limpeza geral: agora exige sessão administrativa ativa.
-- ------------------------------------------------------------
create or replace function public.admin_clear_data(p_password text default null)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  -- Compatibilidade: se já houver sessão administrativa, usa-a.
  -- Se não houver sessão, aceita a senha para manter compatibilidade com a V25.
  if not public.is_admin_session() then
    if p_password is null then
      return jsonb_build_object('ok', false, 'message', 'Acesso administrativo necessário');
    end if;

    if not exists (
      select 1 from public.admin_settings
      where id = 1
        and crypt(coalesce(p_password,''), password_hash) = password_hash
    ) then
      return jsonb_build_object('ok', false, 'message', 'Senha inválida');
    end if;
  end if;

  delete from public.fixed_state
  where key in (
    'cnr_hist',
    'cnr_tournaments',
    'cnr_current_teams',
    'cnr_match_meta',
    'cnr_match_stats',
    'cnr_match_albums'
  );

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.admin_clear_data(text) from public, anon;
grant execute on function public.admin_clear_data(text) to authenticated;

-- ------------------------------------------------------------
-- 9) Protege o ato de ZERAR estatísticas no banco.
-- Usuários continuam podendo registrar/editar estatísticas.
-- Somente o administrador pode transformar o estado em {} ou null.
-- ------------------------------------------------------------
create or replace function public.cnr_protect_stats_reset()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.key = 'cnr_match_stats'
     and (NEW.state is null or NEW.state = '{}'::jsonb)
     and not public.is_admin_session() then
    raise exception 'Somente o administrador pode apagar as estatísticas da partida';
  end if;
  return NEW;
end;
$$;

drop trigger if exists cnr_protect_stats_reset on public.fixed_state;
create trigger cnr_protect_stats_reset
before insert or update on public.fixed_state
for each row execute function public.cnr_protect_stats_reset();

notify pgrst, 'reload schema';
