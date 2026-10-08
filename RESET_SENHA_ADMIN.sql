-- CERVEJA NA REDE V31 — RESET MANUAL DA SENHA DE ADMINISTRADOR
-- Execute SOMENTE se você não consegue entrar como administrador.
-- Depois deste comando, a senha será: CNRADMIN2026!

create extension if not exists pgcrypto;

insert into public.admin_settings (id, password_hash, updated_at)
values (1, crypt('CNRADMIN2026!', gen_salt('bf', 12)), now())
on conflict (id) do update
set password_hash = excluded.password_hash,
    updated_at = now();

-- Invalida sessões administrativas antigas para obrigar novo login.
delete from public.admin_sessions;

select id, updated_at from public.admin_settings where id = 1;
