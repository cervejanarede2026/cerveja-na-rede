-- CERVEJA NA REDE - V25
-- Execute no Supabase SQL Editor.
-- Mantém os jogadores e configura Storage + administração.

create extension if not exists pgcrypto;

-- Bucket único para fotos de jogadores e fotos de partidas.
insert into storage.buckets (id, name, public)
values ('player-photos', 'player-photos', true)
on conflict (id) do update set public = true;

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

create policy "CNR player photos delete"
on storage.objects for delete to authenticated
using (bucket_id = 'player-photos');

-- Administração. A senha fica armazenada somente como hash.
create table if not exists public.admin_settings (
  id integer primary key,
  password_hash text not null,
  updated_at timestamptz not null default now()
);

alter table public.admin_settings enable row level security;
revoke all on table public.admin_settings from anon, authenticated;

-- Senha inicial: CNRADMIN2026!
-- Troque a senha executando o UPDATE abaixo depois da instalação.
insert into public.admin_settings (id, password_hash)
values (1, crypt('CNRADMIN2026!', gen_salt('bf', 12)))
on conflict (id) do nothing;

create or replace function public.admin_clear_data(p_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  stored_hash text;
begin
  select password_hash into stored_hash
  from public.admin_settings
  where id = 1;

  if stored_hash is null or crypt(coalesce(p_password,''), stored_hash) <> stored_hash then
    return jsonb_build_object('ok', false, 'message', 'Senha inválida');
  end if;

  delete from public.fixed_state
  where key in ('cnr_hist','cnr_tournaments','cnr_current_teams','cnr_match_meta','cnr_match_stats','cnr_match_albums');

  -- Remove somente as fotos dos álbuns de partidas.
  delete from storage.objects
  where bucket_id = 'player-photos'
    and name like 'matches/%';

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.admin_clear_data(text) from public;
grant execute on function public.admin_clear_data(text) to authenticated;

-- Exemplo para trocar a senha depois:
-- update public.admin_settings
-- set password_hash = crypt('SUA_NOVA_SENHA', gen_salt('bf', 12)), updated_at = now()
-- where id = 1;

notify pgrst, 'reload schema';
