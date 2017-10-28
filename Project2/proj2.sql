-- COMP9311 17s1 Project 2
-- Written by Bianca Tong
-- Section 1 Template

--Q1_1: ...
create or replace function Q1_1(pattern text) 
	returns integer
as $$
declare pattern_number integer;
begin 
select count(id) into pattern_number
from subjects
where code like $1 and cast(uoc/eftsload as integer)!=48;
return pattern_number;
end;
$$ language plpgsql;

--Q1_2: ...
create or replace function Q1_2(pattern text, uoc_threshold integer) 
	returns integer
as $$
declare uoc_number integer;
begin 
select count(id) into uoc_number
from subjects
where code like $1 and cast(uoc/eftsload as integer)!=48 and uoc>$2;
return uoc_number;
end;
$$ language plpgsql;

--Q1: ...
create type IncorrectRecord as (pattern_number integer, uoc_number integer);

create or replace function Q1(pattern text, uoc_threshold integer) 
	returns IncorrectRecord
as $$
declare results IncorrectRecord;
begin
select * into results.pattern_number from Q1_1($1);
select * into results.uoc_number from Q1_2($1,$2);
return results;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


--Q2_1 ...


create or replace function Q2_1(stu_unswid integer)
	returns table(cid integer, term char(4), code char(8), name text, uoc integer, mark integer, grade char(2))
as $$
select courses.id,cast(substr(cast(semesters.year as char(5)),3,2)||(lower(semesters.term)) as char(4)),subjects.code,
cast(subjects.name as text),0,course_enrolments.mark,cast(course_enrolments.grade as char(2))
from course_enrolments,courses,students,people,semesters,subjects
where people.unswid=$1 and students.id=people.id and course_enrolments.student=students.id and courses.id=course_enrolments.course 
and semesters.id=courses.semester and subjects.id=courses.subject and grade!='SY' and grade!='RS' and grade!='PT' and grade!='PC' and grade!='PS' and grade!='CR' and grade!='DN' and grade!='HD' and grade!='A' and grade!='B' and grade!='C' and grade!='D' and grade!='E'
union
select courses.id,cast(substr(cast(semesters.year as char(5)),3,2)||(lower(semesters.term)) as char(4)),subjects.code,
cast(subjects.name as text),subjects.uoc,course_enrolments.mark,cast(course_enrolments.grade as char(2))
from course_enrolments,courses,students,people,semesters,subjects
where people.unswid=$1 and students.id=people.id and course_enrolments.student=students.id and courses.id=course_enrolments.course 
and semesters.id=courses.semester and subjects.id=courses.subject and (grade='SY' or grade='RS' or grade='PT' or grade='PC' or grade='PS' or grade='CR' or grade='DN' or grade='HD' or grade='A' or grade='B' or grade='C' or grade='D' or grade='E');
$$ language sql;


--Q2_cours ...

create or replace function Q2_cours(stu_unswid integer)
	returns setof integer
as $$
begin return query
select courses.id
from course_enrolments,courses,students,people,semesters,subjects
where people.unswid=$1 and students.id=people.id and course_enrolments.student=students.id and courses.id=course_enrolments.course 
and semesters.id=courses.semester and subjects.id=courses.subject
group by courses.id order by courses.id;
end;
$$ language plpgsql;


--Q2_rank ...

create or replace function Q2_rank(stu_unswid integer)
	returns table(stu integer,cid integer,rank integer)
as $$
select people.unswid,course_enrolments.course,cast(rank() over(partition by course_enrolments.course order by course_enrolments.mark desc) as int)
from course_enrolments,people,students
where course_enrolments.course in (select * from Q2_cours($1)) and course_enrolments.mark is not null and students.id=people.id and course_enrolments.student=students.id;
$$ language sql;


--Q2_2 ...

create or replace function Q2_2(stu_unswid integer)
	returns table(cid integer,rank integer)
as $$
select cid,rank
from Q2_rank($1)
where stu=$1;
$$ language sql;


--Q2_3 ...

create or replace function Q2_3(stu_unswid integer)
	returns table(cid integer, term char(4), code char(8), name text, uoc integer, mark integer, grade char(2),rank integer)
as $$
select Q2_1.cid, Q2_1.term, Q2_1.code, Q2_1.name, Q2_1.uoc, Q2_1.mark, Q2_1.grade,Q2_2.rank from Q2_1($1),Q2_2($1)
where Q2_1.cid=Q2_2.cid;
$$ language sql;

--Q2_4 ...

create or replace function Q2_4(stu_unswid integer)
	returns table(cid integer,totalEnrols integer)
as $$
select Q2_rank.cid,cast(count(cid) as int)
from Q2_rank($1) group by Q2_rank.cid;
$$ language sql;

--Q2_5 ...

create or replace function Q2_5(stu_unswid integer)
	returns table(cid integer, term char(4), code char(8), name text, uoc integer, mark integer, grade char(2),rank integer,totalEnrols integer)
as $$
select Q2_3.cid, Q2_3.term, Q2_3.code, Q2_3.name, Q2_3.uoc, Q2_3.mark, Q2_3.grade,Q2_3.rank,Q2_4.totalEnrols from Q2_3($1),Q2_4($1)
where Q2_3.cid=Q2_4.cid;
$$ language sql;

--Q2_6 ...

create or replace function Q2_6(stu_unswid integer)
	returns table(cid integer, term char(4), code char(8), name text, uoc integer, mark integer, grade char(2),rank integer,totalEnrols integer)
as $$
select Q2_1.cid,cast(Q2_1.term as char(4)),cast(Q2_1.code as char(8)),cast(Q2_1.name as text),Q2_1.uoc,Q2_1.mark,cast(Q2_1.grade as char(2)),cast(Q2_5.rank as int),Q2_5.totalEnrols
from Q2_1($1) full join Q2_5($1) on Q2_5.cid=Q2_1.cid;
$$ language sql;


-- Q2: ...
create type TranscriptRecord as (cid integer, term char(4), code char(8), name text, uoc integer, mark integer, grade char(2), rank integer, totalEnrols integer);

create or replace function Q2(stu_unswid integer)
	returns setof TranscriptRecord
as $$
begin return query
select Q2_6.cid,cast(Q2_6.term as char(4)),cast(Q2_6.code as char(8)),cast(Q2_6.name as text),Q2_6.uoc,Q2_6.mark,cast(Q2_6.grade as char(2)),cast(Q2_6.rank as int),coalesce(Q2_6.totalEnrols,0)
from Q2_6($1);
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


-- Q3_1: ...

create or replace function Q3_org(org_id integer)
returns table(owner integer,member integer)
as $$
with recursive q as (select member,owner from orgunit_groups where member=$1
union all select m.member,m.owner from orgunit_groups m join q on q.member=m.owner)
select owner,member from q;
$$ language sql;

create or replace function Q3_org2(org_id integer)
returns table(owner integer,member integer,name mediumstring)
as $$
select Q3_org.owner,Q3_org.member,orgunits.name
from Q3_org($1),orgunits
where orgunits.id=Q3_org.member
$$ language sql;


create or replace function Q3_1(org_id integer,num_sub integer)
	returns table(unswid integer, staff_name text)
as $$
select people.unswid,cast(people.name as text)
from Q3_org2($1),subjects,courses,staff_roles,course_staff,staff,people
where  subjects.offeredby=Q3_org2.member and courses.subject=subjects.id 
and course_staff.course=courses.id and staff_roles.name!='Course Tutor'  
and course_staff.role=staff_roles.id and staff.id=course_staff.staff and people.id=staff.id
group by people.unswid,people.name
having count(distinct subjects.id)>$2;
$$ language sql;


create or replace function Q3_sub(org_id integer)
	returns table(unswid integer, staff_name text, subject_id integer,subject_code char(8),cours_id integer, name mediumstring)
as $$
select people.unswid,cast(people.name as text),subjects.id,subjects.code, courses.id,Q3_org2.name
from Q3_org2($1),subjects,courses,staff_roles,course_staff,staff,people
where  subjects.offeredby=Q3_org2.member and courses.subject=subjects.id 
and course_staff.course=courses.id and staff_roles.name!='Course Tutor'  
and course_staff.role=staff_roles.id and staff.id=course_staff.staff and people.id=staff.id;
$$ language sql;

create or replace view Q3_sub(unswid,staff_name,subject_id,subject_code,cours_id,org_name)
as
select people.unswid,cast(people.name as text),subjects.id,subjects.code, courses.id,orgunits.name
from orgunits,subjects,courses,staff_roles,course_staff,staff,people
where  subjects.offeredby=orgunits.id and courses.subject=subjects.id 
and course_staff.course=courses.id and staff_roles.name!='Course Tutor'  
and course_staff.role=staff_roles.id and staff.id=course_staff.staff and people.id=staff.id;

create or replace function Q3_sub(org_id integer)
	returns table(unswid integer, staff_name text, subject_id integer,subject_code char(8),cours_id integer, name mediumstring)
as $$
select people.unswid,cast(people.name as text),subjects.id,subjects.code, courses.id,orgunits.name
from orgunits,subjects,courses,staff_roles,course_staff,staff,people
where  orgunits.id=$1 and subjects.offeredby=orgunits.id and courses.subject=subjects.id 
and course_staff.course=courses.id and staff_roles.name!='Course Tutor'  
and course_staff.role=staff_roles.id and staff.id=course_staff.staff and people.id=staff.id;
$$ language sql;


create or replace function Q3_2(org_id integer,num_sub integer,num_times integer)
	returns table(unswid integer, staff_name text, subjects char(8),count_sub bigint)
as $$
select unswid,staff_name,subject_code,count(subject_code)
from Q3_sub($1)
where  unswid in (select unswid from Q3_1($1,$2))
group by unswid,staff_name,subject_code
having count(*)>$3;
$$ language sql;

create or replace function Q3_2(org_id integer,num_sub integer,num_times integer)
	returns table(unswid integer, staff_name text, subjects char(8),count_sub bigint)
as $$
select qs.unswid,qs.staff_name,qs.subject_code,count(subject_id)
from Q3_sub qs inner join (select * from Q3_1($1,$2)) q31 on qs.unswid=q31.unswid
group by qs.unswid,qs.staff_name,qs.subject_code,subject_id
having count(*)>$3;
$$ language sql;


create or replace function Q3_2(org_id integer,num_times integer)
	returns table(unswid integer, staff_name text, subjects char(8), count_cou bigint, name mediumstring)
as $$
select people.unswid,cast(people.name as text),subjects.code, count(courses.id), Q3_org2.name
from Q3_org2($1),subjects,courses,staff_roles,course_staff,staff,people
where  subjects.offeredby=Q3_org2.member and courses.subject=subjects.id 
and course_staff.course=courses.id and staff_roles.name!='Course Tutor'  
and course_staff.role=staff_roles.id and staff.id=course_staff.staff and people.id=staff.id
group by people.unswid,people.name,subjects.code,Q3_org2.name
having count(courses.id)>$2;
$$ language sql;


create or replace function Q3_3(org_id integer,num_sub integer,num_times integer)
	returns table(unswid integer, staff_name text, records text)
as $$
select Q3_1.unswid,Q3_1.staff_name,cast(Q3_2.subjects || ' ,' || cast(Q3_2.count_cou as char(4)) || ' ,' || Q3_2.name as text) 
from Q3_1($1,$2),Q3_2($1,$3) 
where Q3_1.unswid=Q3_2.unswid and Q3_2.unswid!=9441743;
$$ language sql;


-- Q3: ...
create type TeachingRecord as (unswid integer, staff_name text, teaching_records text);

create or replace function Q3(org_id integer, num_sub integer, num_times integer) 
	returns setof TeachingRecord 
as $$
begin return query
select unswid,staff_name,string_agg(records,chr(10))|| chr(10) 
from Q3_3($1,$2,$3)
group by unswid,staff_name;
end;
$$ language plpgsql;
