create extension if not exists pgcrypto;

create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique not null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  primary key(group_id,user_id)
);

create table if not exists public.group_state (
  group_id uuid primary key references public.groups(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);

alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_state enable row level security;

drop policy if exists groups_member_select on public.groups;
create policy groups_member_select on public.groups for select to authenticated using (exists (select 1 from public.group_members m where m.group_id=id and m.user_id=auth.uid()));

drop policy if exists members_self_select on public.group_members;
create policy members_self_select on public.group_members for select to authenticated using (user_id=auth.uid());

drop policy if exists state_member_select on public.group_state;
create policy state_member_select on public.group_state for select to authenticated using (exists (select 1 from public.group_members m where m.group_id=group_id and m.user_id=auth.uid()));

drop policy if exists state_member_update on public.group_state;
create policy state_member_update on public.group_state for update to authenticated using (exists (select 1 from public.group_members m where m.group_id=group_id and m.user_id=auth.uid())) with check (exists (select 1 from public.group_members m where m.group_id=group_id and m.user_id=auth.uid()));

drop function if exists public.create_group(text,text);
create or replace function public.create_group(p_name text,p_code text)
returns public.groups
language plpgsql security definer set search_path=public
as $$
declare g public.groups;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  insert into public.groups(name,code,created_by) values(trim(p_name),upper(trim(p_code)),auth.uid()) returning * into g;
  insert into public.group_members(group_id,user_id,role) values(g.id,auth.uid(),'owner');
  insert into public.group_state(group_id,state,updated_by) values(g.id,'{}'::jsonb,auth.uid());
  return g;
end $$;

drop function if exists public.join_group(text);
create or replace function public.join_group(p_code text)
returns public.groups
language plpgsql security definer set search_path=public
as $$
declare g public.groups;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  select * into g from public.groups where code=upper(trim(p_code));
  if g.id is null then raise exception 'group_not_found'; end if;
  insert into public.group_members(group_id,user_id) values(g.id,auth.uid()) on conflict do nothing;
  return g;
end $$;

grant execute on function public.create_group(text,text) to authenticated;
grant execute on function public.join_group(text) to authenticated;
grant select on public.groups to authenticated;
grant select on public.group_members to authenticated;
grant select,update on public.group_state to authenticated;

-- No painel do Supabase: Authentication > Providers > Anonymous = ON.
-- Depois, Database > Replication: adicione public.group_state à publicação supabase_realtime.
