-- ============================================================
-- Invitación de Ian Esteban · Confirmaciones + panel de los papás
-- Pégalo en Supabase > SQL Editor > New query y dale "Run".
-- Se puede correr más de una vez sin problema.
-- ============================================================

-- 1) Confirmaciones de los invitados
create table if not exists public.confirmaciones_ian (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null check (char_length(btrim(nombre)) between 1 and 80),
  asiste     boolean not null,
  personas   int not null default 1 check (personas between 0 and 15),
  mensaje    text check (mensaje is null or char_length(mensaje) <= 300),
  created_at timestamptz not null default now()
);

-- Los invitados (sin cuenta) solo pueden CREAR confirmaciones.
-- Nadie puede leerlas, cambiarlas ni borrarlas desde la web.
alter table public.confirmaciones_ian enable row level security;
revoke all on public.confirmaciones_ian from anon, authenticated;
grant insert (nombre, asiste, personas, mensaje) on public.confirmaciones_ian to anon, authenticated;

drop policy if exists "Invitados confirman" on public.confirmaciones_ian;
create policy "Invitados confirman"
  on public.confirmaciones_ian for insert
  to anon, authenticated
  with check (true);

-- 2) Clave del panel (se guarda cifrada, nunca en texto)
create table if not exists public.panel_ian_config (
  id         int primary key default 1 check (id = 1),
  clave_hash text not null
);
alter table public.panel_ian_config enable row level security;
revoke all on public.panel_ian_config from anon, authenticated;

insert into public.panel_ian_config (id, clave_hash)
values (1, extensions.crypt('9923', extensions.gen_salt('bf')))
on conflict (id) do update set clave_hash = excluded.clave_hash;

-- Registro de intentos fallidos: frena a quien intente adivinar la clave
create table if not exists public.panel_ian_intentos (
  ts timestamptz not null default now()
);
alter table public.panel_ian_intentos enable row level security;
revoke all on public.panel_ian_intentos from anon, authenticated;

-- 3) Funciones del panel (todas revisan la clave en el servidor)
create or replace function public.panel_ian_ok(p_clave text)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  delete from public.panel_ian_intentos where ts < now() - interval '1 day';
  -- Más de 20 fallos en 15 minutos: se bloquea un rato
  if (select count(*) from public.panel_ian_intentos where ts > now() - interval '15 minutes') >= 20 then
    return false;
  end if;
  if exists (select 1 from public.panel_ian_config where clave_hash = extensions.crypt(coalesce(p_clave, ''), clave_hash)) then
    return true;
  end if;
  insert into public.panel_ian_intentos default values;
  return false;
end $$;

create or replace function public.panel_ian_verificar(p_clave text)
returns boolean
language sql security definer
set search_path = public, extensions
as $$ select public.panel_ian_ok(p_clave) $$;

create or replace function public.panel_ian_confirmaciones(p_clave text)
returns setof public.confirmaciones_ian
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  if not public.panel_ian_ok(p_clave) then
    return;  -- sin clave correcta no se devuelve nada
  end if;
  return query select * from public.confirmaciones_ian order by created_at desc;
end $$;

create or replace function public.panel_ian_eliminar(p_clave text, p_id uuid)
returns boolean
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  if not public.panel_ian_ok(p_clave) then
    return false;
  end if;
  delete from public.confirmaciones_ian where id = p_id;
  return true;
end $$;

revoke all on function public.panel_ian_ok(text) from public, anon, authenticated;
revoke all on function public.panel_ian_verificar(text) from public;
revoke all on function public.panel_ian_confirmaciones(text) from public;
revoke all on function public.panel_ian_eliminar(text, uuid) from public;
grant execute on function public.panel_ian_verificar(text) to anon, authenticated;
grant execute on function public.panel_ian_confirmaciones(text) to anon, authenticated;
grant execute on function public.panel_ian_eliminar(text, uuid) to anon, authenticated;

-- Para cambiar la clave más adelante, corre esto con la clave nueva:
-- update public.panel_ian_config set clave_hash = extensions.crypt('NUEVA', extensions.gen_salt('bf')) where id = 1;
