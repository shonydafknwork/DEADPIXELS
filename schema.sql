-- Run in Supabase SQL editor
create table events(id uuid primary key default gen_random_uuid(), number int generated always as identity,
 name text not null, starts_at timestamptz not null, venue text not null, location text not null default '',
 poster_url text, genres text[] not null default '{}', lineup text[] not null default '{}',
 description text not null default '', published boolean not null default false, created_at timestamptz default now());
create table ticket_types(id uuid primary key default gen_random_uuid(), event_id uuid not null references events on delete cascade,
 name text not null, price numeric not null default 0 check(price>=0), quantity int not null check(quantity>=0));
create table registrations(id uuid primary key default gen_random_uuid(), ref text unique not null,
 event_id uuid not null references events on delete cascade, ticket_type_id uuid not null references ticket_types on delete cascade,
 full_name text not null, email text not null, phone text not null, instagram text, quantity int not null check(quantity between 1 and 10),
 notes text, status text not null default 'pending' check(status in('pending','confirmed','cancelled')), created_at timestamptz default now());
create table admins(user_id uuid primary key references auth.users on delete cascade);

create function is_admin() returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from admins where user_id=auth.uid()) $$;

alter table events enable row level security; alter table ticket_types enable row level security;
alter table registrations enable row level security; alter table admins enable row level security;
create policy ev_read on events for select using (published);
create policy ev_admin on events for all using (is_admin()) with check (is_admin());
create policy tt_read on ticket_types for select using (exists(select 1 from events e where e.id=event_id and e.published));
create policy tt_admin on ticket_types for all using (is_admin()) with check (is_admin());
create policy reg_admin on registrations for all using (is_admin()) with check (is_admin());
create policy adm_self on admins for select using (user_id=auth.uid());

create view ticket_availability as
 select t.id,t.event_id,t.name,t.price,t.quantity,
  (t.quantity-coalesce((select sum(r.quantity) from registrations r where r.ticket_type_id=t.id and r.status<>'cancelled'),0))::int as remaining
 from ticket_types t join events e on e.id=t.event_id where e.published;
grant select on ticket_availability to anon, authenticated;

create function book_tickets(p_ticket_type uuid,p_name text,p_email text,p_phone text,p_instagram text,p_qty int,p_notes text)
returns text language plpgsql security definer set search_path=public as $$
declare t ticket_types%rowtype; taken int; r text;
begin
 select * into t from ticket_types where id=p_ticket_type for update; -- row lock = no overbooking
 if not found then raise exception 'Invalid ticket type'; end if;
 if not exists(select 1 from events where id=t.event_id and published) then raise exception 'Event unavailable'; end if;
 if p_qty<1 or p_qty>10 then raise exception 'Invalid quantity'; end if;
 if length(trim(p_name))<2 or p_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' or length(trim(p_phone))<6 then raise exception 'Invalid details'; end if;
 select coalesce(sum(quantity),0) into taken from registrations where ticket_type_id=t.id and status<>'cancelled';
 if taken+p_qty>t.quantity then raise exception 'Not enough tickets left'; end if;
 r:='DP-'||upper(substr(md5(gen_random_uuid()::text),1,6));
 insert into registrations(ref,event_id,ticket_type_id,full_name,email,phone,instagram,quantity,notes)
 values(r,t.event_id,t.id,trim(p_name),lower(trim(p_email)),trim(p_phone),nullif(trim(p_instagram),''),p_qty,nullif(trim(p_notes),''));
 return r;
end $$;
grant execute on function book_tickets to anon, authenticated;

insert into storage.buckets(id,name,public) values('posters','posters',true);
create policy poster_admin on storage.objects for all to authenticated
 using(bucket_id='posters' and is_admin()) with check(bucket_id='posters' and is_admin());
-- After creating your admin user in Auth > Users:
-- insert into admins(user_id) values ('PASTE-USER-UUID');
