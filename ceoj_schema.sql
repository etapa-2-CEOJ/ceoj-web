-- ============================================================
-- CEOJ - Schema para Supabase
-- Pegá todo esto en el SQL Editor de Supabase y ejecutalo
-- ============================================================

-- PROFILES (datos de usuario vinculados a Supabase Auth)
create table if not exists profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  name text not null default '',
  email text not null default '',
  phone text default '',
  role text not null default 'viewer',
  active boolean default true,
  notes text default '',
  last_login timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- NAMING (debe crearse antes que donantes por la FK)
create table if not exists naming (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  floor text default '',
  m2 text default '',
  amount numeric default 0,
  status text default 'available',
  description text default '',
  img_key text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- DONANTES
create table if not exists donantes (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  email text default '',
  phone text default '',
  compromiso numeric default 0,
  pagado numeric default 0,
  currency text default 'USD',
  status text default 'negociacion',
  naming_id uuid references naming(id) on delete set null,
  date date,
  notes text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ETAPAS
create table if not exists etapas (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  start_date date,
  end_date date,
  pct numeric default 0,
  status text default 'pendiente',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- NOVEDADES
create table if not exists novedades (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text default '',
  date timestamptz default now(),
  type text default 'hito',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- GALLERY
create table if not exists gallery (
  id uuid default gen_random_uuid() primary key,
  title text default '',
  category text default '',
  floor text default '',
  img_key text default '',
  description text default '',
  m2 numeric,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- NOTIFS
create table if not exists notifs (
  id uuid default gen_random_uuid() primary key,
  message text not null,
  type text default 'info',
  read boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- CONFIG (clave-valor para configuracion de la app)
create table if not exists config (
  key text primary key,
  value text default '',
  updated_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table profiles  enable row level security;
alter table naming    enable row level security;
alter table donantes  enable row level security;
alter table etapas    enable row level security;
alter table novedades enable row level security;
alter table gallery   enable row level security;
alter table notifs    enable row level security;
alter table config    enable row level security;

-- Funcion helper: obtiene el rol del usuario actual
create or replace function get_my_role()
returns text language sql security definer stable as $$
  select role from profiles where id = auth.uid()
$$;

-- PROFILES
create policy "Leer propio perfil"         on profiles for select using (id = auth.uid());
create policy "Admin lee todos los perfiles" on profiles for select using (get_my_role() in ('admin','marketing'));
create policy "Usuario actualiza su perfil" on profiles for update using (id = auth.uid());
create policy "Admin actualiza perfiles"   on profiles for update using (get_my_role() = 'admin');
create policy "Registro crea perfil"       on profiles for insert with check (id = auth.uid());
create policy "Admin elimina perfiles"     on profiles for delete using (get_my_role() = 'admin');

-- CONFIG: lectura publica (modo publico la necesita), escritura solo admin
create policy "Config lectura publica"  on config for select using (true);
create policy "Config escritura admin"  on config for all   using (get_my_role() in ('admin','marketing'));

-- NAMING: lectura publica, escritura admin
create policy "Naming lectura publica"  on naming for select using (true);
create policy "Naming escritura admin"  on naming for all   using (get_my_role() in ('admin','marketing'));

-- DONANTES: autenticados leen, admin/mkt escriben
create policy "Donantes lectura auth"   on donantes for select using (auth.role() = 'authenticated');
create policy "Donantes escritura admin" on donantes for all  using (get_my_role() in ('admin','marketing'));

-- ETAPAS: lectura publica, escritura admin
create policy "Etapas lectura publica"  on etapas for select using (true);
create policy "Etapas escritura admin"  on etapas for all    using (get_my_role() in ('admin','marketing'));

-- NOVEDADES: lectura publica, escritura admin
create policy "Novedades lectura publica"  on novedades for select using (true);
create policy "Novedades escritura admin"  on novedades for all    using (get_my_role() in ('admin','marketing'));

-- GALLERY: lectura publica, escritura admin
create policy "Gallery lectura publica"  on gallery for select using (true);
create policy "Gallery escritura admin"  on gallery for all   using (get_my_role() in ('admin','marketing'));

-- NOTIFS: autenticados leen, admin escribe
create policy "Notifs lectura auth"    on notifs for select using (auth.role() = 'authenticated');
create policy "Notifs escritura admin" on notifs for all    using (get_my_role() in ('admin','marketing'));

-- ============================================================
-- DATOS INICIALES (etapas del proyecto)
-- ============================================================

insert into etapas (name, start_date, end_date, pct, status) values
  ('Proyecto ejecutivo',          '2025-01-01', '2026-05-31',  100, 'completado'),
  ('Estructura SS1 y PB',         '2026-06-01', '2026-11-30',   15, 'activo'),
  ('Estructura pisos 1-3',        '2026-12-01', '2027-06-30',    0, 'pendiente'),
  ('Estructura pisos 4-6',        '2027-07-01', '2027-12-31',    0, 'pendiente'),
  ('Terminaciones y equipamiento','2028-01-01', '2029-06-30',    0, 'pendiente'),
  ('Habilitacion y entrega',      '2029-07-01', '2029-12-31',    0, 'pendiente')
on conflict do nothing;

insert into config (key, value) values
  ('nombre',    'Centro Educativo Oholey Jinuj - Etapa 2'),
  ('m2',        '18000'),
  ('alumnos',   '1300'),
  ('costo',     '30000000'),
  ('meta',      '30000000'),
  ('inicio',    '2026-06-01'),
  ('fin',       '2029-12-31'),
  ('direccion', 'Tucuman 3177 / Aguero 841, CABA'),
  ('code_admin','CEOJ2026'),
  ('code_mkt',  'MKTG2026')
on conflict do nothing;
