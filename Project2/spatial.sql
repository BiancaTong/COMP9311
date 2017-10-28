-- COMP9311 17s1 Project 2
-- Written by Bianca Tong
-- Section 2 Template

--------------------------------------------------------------------------------
-- Q4
--------------------------------------------------------------------------------
-- drop function
drop function if exists skyline_naive(text) cascade;

-- This function calculates skyline in O(n^2)
create or replace function skyline_naive(dataset text) 
    returns integer 
as $$
declare num integer;
begin
  execute 'create or replace view ' || $1 || '_skyline_naive(x, y) as ' ||
  'select * from ' || $1 || ' as s2 where not exists (select * from ' || $1 ||
  ' as s1 where (s1.x>=s2.x and s1.y>s2.y) or (s1.x>s2.x and s1.y>=s2.y))';
  execute 'select count(x) from ' || $1 || '_skyline_naive' into num;
  return num;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

--------------------------------------------------------------------------------
-- type
create type t as (i integer,x integer,y integer);

-- Q5_table sort points in y desc and x desc order
create or replace function Q5_table(dataset text)
    returns table(i bigint,x integer,y integer)
as $$
 begin
  return query execute 'select row_number() over (order by y desc,x desc) as i,x,y from ' || $1;
 end;
$$ language plpgsql;

-- Q5_other find all the point belong to the skyline
create or replace function Q5_other(dataset text)
    returns setof t
as $$
declare
  r t;
  s t;
begin
  select x into s.x from Q5_table($1) where i=1;
  select y into s.y from Q5_table($1) where i=1;
  for r in select * from Q5_table($1)
  loop
  if r.y=s.y and r.x=s.x then return next r;
  end if;
  if r.y<s.y and r.x>s.x then s.x:=r.x;s.y:=r.y;return next r;
  end if;
  end loop;
  return;
end;
$$ language plpgsql;

-- drop function
drop function if exists skyline(text) cascade;

-- This function simply creates a view to store skyline
create or replace function skyline(dataset text) 
    returns integer 
as $$
declare num integer;
begin
  execute 'create or replace view '|| $1 ||'_skyline(x, y) as 
  select x,y from Q5_other('''||$1||''')';
  execute 'select count(x) from '|| $1 ||'_skyline' into num;
  return num;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

--------------------------------------------------------------------------------
-- Q6
--------------------------------------------------------------------------------
-- drop function
drop function if exists skyband_naive(text) cascade;

-- This function calculates skyband in O(n^2)
create or replace function skyband_naive(dataset text, k integer) 
    returns integer 
as $$
declare num integer;
begin
  execute 'create or replace view ' || $1 || '_skyband_naive(x, y) as ' ||
  'select * from ' || $1 || ' as s2 where not exists (select * from ' || $1 ||
  ' as s1 where (s1.x>=s2.x and s1.y>s2.y) or (s1.x>s2.x and s1.y>=s2.y)) 
  union '
  'select s2.x,s2.y from ' || $1 || ' s1,' || $1 || 
  ' s2 where (s1.x>=s2.x and s1.y>s2.y) or (s1.x>s2.x and s1.y>=s2.y) 
  group by s2.x,s2.y having count(s1.x)<' || $2;
  execute 'select count(x) from ' || $1 || '_skyband_naive' into num;
  return num;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

--------------------------------------------------------------------------------
-- Q7
--------------------------------------------------------------------------------
create type tt as (i integer,x integer,y integer);
create type ttt as (x integer,y integer);
-- Q7_table sort points in y desc and x desc order
create or replace function Q7_table(dataset text)
    returns table(i bigint,x integer,y integer)
as $$
 begin
  return query execute 'select row_number() over (order by y desc,x desc) as i,x,y from ' || $1;
 end;
$$ language plpgsql;

-- Q7_1 find points belong to the skyband_x
create or replace function Q7_1(dataset text)
    returns setof tt
as $$
declare
  r tt;
  s tt;
begin
  select x into s.x from Q7_table($1) order by s.y desc,s.x desc fetch first 1 row only;
  select y into s.y from Q7_table($1) order by s.y desc,s.x desc fetch first 1 row only;
  for r in select * from Q7_table($1)
  loop
  if r.y=s.y and r.x=s.x then return next r;
  end if;
  if r.y<s.y and r.x>s.x then s.x:=r.x;s.y:=r.y;return next r;
  end if;
  end loop;
  return;
end;
$$ language plpgsql;

-- Q7_end loop to find all the points
create or replace function Q7_end(dataset text,k integer)
    returns integer
as $$
declare 
m integer;
a tt;
b tt;
begin
  SET LOCAL client_min_messages = warning;
  drop table if exists ss1 CASCADE;
  --RESET client_min_messages = warning;
  execute 'create table ss1 as select * from ' || $1;
  SET LOCAL client_min_messages = warning;
  drop table if exists ss2 CASCADE;
  --RESET client_min_messages = warning;
  create table ss2 as select * from Q7_1('ss1');
  for q in 2..$2 loop
  for a in select * from Q7_1('ss1') loop
  delete from ss1 where ss1.x=a.x and ss1.y=a.y;
  end loop;
  for b in select * from Q7_1('ss1') loop
  insert into ss2 values(b.i,b.x,b.y);
  end loop;
  end loop;
  select count(x) into m from ss2;
  return m;
end;
$$ language plpgsql;

drop function if exists skyband(text, integer) cascade;

-- This function simply creates a view to store skyband
create or replace function skyband(dataset text, k integer) 
    returns integer 
as $$
declare num integer;n integer;
begin
  execute 'select * from Q7_end(''' ||$1||''','''||$2||''')' into n;
  execute 'create or replace view ' || $1 || '_skyband(x, y) as ' ||
  'select x,y from ss2';
  execute 'select count(x) from ' || $1 || '_skyband' into num;
  return num;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;
