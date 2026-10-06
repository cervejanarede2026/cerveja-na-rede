create extension if not exists pgcrypto;

-- Estrutura antiga (mantida para compatibilidade e migração do CRN-1556)
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(), name text not null, code text unique not null,
  created_by uuid not null default auth.uid(), created_at timestamptz not null default now()
);
create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null, role text not null default 'member', created_at timestamptz not null default now(),
  primary key(group_id,user_id)
);
create table if not exists public.group_state (
  group_id uuid primary key references public.groups(id) on delete cascade,
  state jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now(), updated_by uuid default auth.uid()
);

-- NOVA V16: dados compartilhados por registro, evitando que uma alteração sobrescreva outra.
create table if not exists public.fixed_players (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);
create table if not exists public.fixed_state (
  key text primary key,
  state jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);

alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_state enable row level security;
alter table public.fixed_players enable row level security;
alter table public.fixed_state enable row level security;

drop policy if exists fixed_players_all on public.fixed_players;
create policy fixed_players_all on public.fixed_players for all to authenticated using (true) with check (true);
drop policy if exists fixed_state_all on public.fixed_state;
create policy fixed_state_all on public.fixed_state for all to authenticated using (true) with check (true);

grant select,insert,update,delete on public.fixed_players to authenticated;
grant select,insert,update,delete on public.fixed_state to authenticated;

drop function if exists public.get_fixed_group();
create or replace function public.get_fixed_group()
returns public.groups
language plpgsql security definer set search_path=public
as $$
declare g public.groups;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  -- Usa o grupo CRN-1556 já criado, se existir; caso contrário cria o grupo fixo.
  select * into g from public.groups where code='CRN-1556' limit 1;
  if g.id is null then
    insert into public.groups(name,code,created_by) values('Cerveja na Rede','CRN-1556',auth.uid()) returning * into g;
    insert into public.group_state(group_id,state,updated_by) values(g.id,'{}'::jsonb,auth.uid()) on conflict do nothing;
  end if;
  insert into public.group_members(group_id,user_id,role) values(g.id,auth.uid(),'member') on conflict do nothing;
  return g;
end $$;
grant execute on function public.get_fixed_group() to authenticated;

-- Permissões mínimas do grupo legado, caso ainda sejam necessárias durante a migração.
drop policy if exists groups_member_select on public.groups;
create policy groups_member_select on public.groups for select to authenticated using (exists (select 1 from public.group_members m where m.group_id=id and m.user_id=auth.uid()));
drop policy if exists members_self_select on public.group_members;
create policy members_self_select on public.group_members for select to authenticated using (user_id=auth.uid());
drop policy if exists state_member_select on public.group_state;
create policy state_member_select on public.group_state for select to authenticated using (exists (select 1 from public.group_members m where m.group_id=group_id and m.user_id=auth.uid()));

grant select on public.groups to authenticated;
grant select on public.group_members to authenticated;
grant select on public.group_state to authenticated;

-- Realtime V16
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='fixed_players') then
    alter publication supabase_realtime add table public.fixed_players;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='fixed_state') then
    alter publication supabase_realtime add table public.fixed_state;
  end if;
end $$;

-- Authentication > Providers > Anonymous deve permanecer ON.
