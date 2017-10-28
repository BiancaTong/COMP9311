-- COMP9311 17s1 Project 1 Check
--
-- MyMyUNSW Check

create or replace function
	proj1_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj1_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj1_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

-- proj1_check_result:
-- * determines appropriate message, based on count of
--   excess and missing tuples in user output vs expected output

create or replace function
	proj1_check_result(nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return 'correct';
	elsif (nexcess > 0 and nmissing = 0) then
		return 'too many result tuples';
	elsif (nexcess = 0 and nmissing > 0) then
		return 'missing result tuples';
	elsif (nexcess > 0 and nmissing > 0) then
		return 'incorrect result tuples';
	end if;
end;
$$ language plpgsql;

-- proj1_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results

create or replace function
	proj1_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
begin
	if (_type = 'view' and not proj1_view_exists(_name)) then
		return 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (not proj1_table_exists(_res)) then
		return _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
			   'from (('||_query||') except '||
			   '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
			    'from ((select * from '||_res||') '||
			    'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return proj1_check_result(nexcess,nmissing);
	end if;
	return '???';
end;
$$ language plpgsql;

-- proj1_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results

create or replace function
	proj1_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

-- check_all:
-- * run all of the checks and return a table of results

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array['q1', 'q2', 'q3', 'q4', 'q5a', 'q5b', 'q5c','q6','q7','q8','q9','q10'];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


--
-- Check functions for specific test-cases in Project 1
--

create or replace function check_q1() returns text
as $chk$
select proj1_check('view','q1','q1_expected',
                   $$select * from q1$$)
$chk$ language sql;

create or replace function check_q2() returns text
as $chk$
select proj1_check('view','q2','q2_expected',
                   $$select * from q2$$)
$chk$ language sql;

create or replace function check_q3() returns text
as $chk$
select proj1_check('view','q3','q3_expected',
                   $$select * from q3$$)
$chk$ language sql;

create or replace function check_q4() returns text
as $chk$
select proj1_check('view','q4','q4_expected',
                   $$select * from q4$$)
$chk$ language sql;

create or replace function check_q5a() returns text
as $chk$
select proj1_check('view','q5a','q5a_expected',
                   $$select * from q5a$$)
$chk$ language sql;

create or replace function check_q5b() returns text
as $chk$
select proj1_check('view','q5b','q5b_expected',
                   $$select * from q5b$$)
$chk$ language sql;

create or replace function check_q5c() returns text
as $chk$
select proj1_check('view','q5c','q5c_expected',
                   $$select * from q5c$$)
$chk$ language sql;

create or replace function check_q6() returns text
as $chk$
select proj1_check('function','q6','q6_expected',
                   $$select * from q6('COMP9311')$$)
$chk$ language sql;

create or replace function check_q7() returns text
as $chk$
select proj1_check('view','q7','q7_expected',
                   $$select * from q7$$)
$chk$ language sql;

create or replace function check_q8() returns text
as $chk$
select proj1_check('view','q8','q8_expected',
                   $$select * from q8$$)
$chk$ language sql;

create or replace function check_q9() returns text
as $chk$
select proj1_check('view','q9','q9_expected',
                   $$select * from q9$$)
$chk$ language sql;

create or replace function check_q10() returns text
as $chk$
select proj1_check('view','q10','q10_expected',
                   $$select * from q10$$)
$chk$ language sql;

--
-- Tables of expected results for test cases
--

drop table if exists q1_expected;
create table q1_expected (
     unswid shortstring,
     name LongName
);

drop table if exists q2_expected;
create table q2_expected (
	name LongName,
	faculty LongString,
	phone PhoneNumber,
	starting date
);

drop table if exists q3_expected;
create table q3_expected (
	status text,
	name LongName,
	faculty LongString,
	starting date
);

drop table if exists q4_expected;
create table q4_expected (
	ratio numeric(4,1),
	nsubjects bigint
);

drop table if exists q5a_expected;
create table q5a_expected (
    num bigint
);
drop table if exists q5b_expected;
create table q5b_expected (
    num bigint
);
drop table if exists q5c_expected;
create table q5c_expected (
    num bigint
);

drop table if exists q6_expected;
create table q6_expected (
    cname text
);

drop table if exists q7_expected;
create table q7_expected (
    year CourseYearType,
    term character(2),
    perc_growth numeric(4,2)
);

drop table if exists q8_expected;
create table q8_expected (
    subject text
);

drop table if exists q9_expected;
create table q9_expected (
    year text,
	s1_pass_rate numeric(4,2),
    s2_pass_rate numeric(4,2)
);

drop table if exists q10_expected;
create table q10_expected (
    zid text,
    name LongName
);


COPY q1_expected (unswid, name) FROM stdin;
MB	Morven Brown Building
OMB	Old Main Building
EE	Electrical Engineering Building
WEB	Robert Webster Building
MECH	Mechanical Engineering Building
F	Building F
RC	Red Centre
MAT	Mathews Building
K17	Computer Science Building
QUAD	Quadrangle
CHEMSC	Chemical Sciences Building
ASB	Australian School of Business
\.

COPY q2_expected (name, faculty, phone, starting) FROM stdin;
James Donald	Faculty of Arts and Social Sciences	93851739	2001-01-01
Agnes Heah	Faculty of Arts and Social Sciences	93852286	2012-07-25
Merlin Crossley	Faculty of Science	93857916	2010-06-07
Alec Tzannes	Faculty of Built Environment	93854768	2010-03-05
Ross Harley	College of Fine Arts (COFA)	93850758	2013-04-01
Graham Davies	Faculty of Engineering	93854970	2001-01-01
David Dixon	Faculty of Law	93852485	2010-03-05
Peter Smith	Faculty of Medicine	93852451	2010-08-12
Geoffrey Garrett	Australian School of Business	93858700	2013-02-19
\.

COPY q3_expected (status, name, faculty, starting) FROM stdin;
Longest serving	Graham Davies	Faculty of Engineering	2001-01-01
Longest serving	James Donald	Faculty of Arts and Social Sciences	2001-01-01
Shortest serving	Ross Harley	College of Fine Arts (COFA)	2013-04-01
\.

COPY q4_expected (ratio,nsubjects) FROM stdin;
18.5	1
20.0	2
21.3	1
22.8	3
50.3	2
80.0	1
24.1	113
24.0	8866
23.8	11
48.0	9200
\.

COPY q5a_expected (num) FROM stdin;
16
\.

COPY q5b_expected (num) FROM stdin;
54
\.

COPY q5c_expected (num) FROM stdin;
796
\.

-- select * from q6(COMP9311);
COPY q6_expected (cname) FROM stdin;
COMP9311 Database Systems
\.

COPY q7_expected (year, term, perc_growth) FROM stdin;
2003	S2	1.00
2004	S1	1.33
2004	S2	1.25
2005	S1	0.47
2005	S2	1.57
2006	S1	1.27
2006	S2	1.14
2007	S1	0.94
2007	S2	1.40
2008	S1	1.52
2008	S2	0.81
2009	S1	2.23
2009	S2	0.72
2010	S1	1.86
2010	S2	0.54
2011	S1	2.12
2011	S2	0.44
2012	S1	2.33
2012	S2	0.11
2013	S1	0.40
\.

COPY q8_expected (subject) FROM stdin;
GEND1203 Draw the World Within/Without
\.

COPY q9_expected (year, s1_pass_rate, s2_pass_rate) FROM stdin;
03	1.00	1.00
04	1.00	0.85
05	1.00	1.00
06	1.00	1.00
07	1.00	1.00
08	0.81	0.92
09	0.89	0.90
10	0.93	1.00
11	0.91	1.00
12	0.85	1.00
\.

COPY q10_expected (zid, name) FROM stdin;
z3255939	Rosanna Hogarth
z3256382	Viara Alexova
z3218103	Elaine Hon
z3253334	Sarah Sridharan
z3243616	Virginia Glanz
\.
