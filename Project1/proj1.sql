-- COMP9311 17s1 Project 1
-- Written by Bianca Tong
-- MyMyUNSW Solution Template


-- Q1: buildings that have more than 30 rooms
create or replace view Q1(unswid, name)
as
SELECT Buildings.unswid,Buildings.name
FROM Buildings
WHERE Buildings.id IN (
SELECT building
FROM Rooms
GROUP BY building having COUNT(building)>=30)
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q2: get details of the current Deans of Faculty
create or replace view Q2(name, faculty, phone, starting)
as
SELECT People.name,OrgUnits.longname,Staff.phone,Affiliations.starting
FROM People,OrgUnits,Staff,Affiliations,Staff_roles,OrgUnit_types
WHERE Staff_roles.name='Dean' AND Affiliations.role=Staff_roles.id 
AND Affiliations.ending is null AND OrgUnit_types.name='Faculty' 
AND OrgUnits.utype=OrgUnit_types.id AND Affiliations.orgunit=OrgUnits.id 
AND Staff.id=Affiliations.staff AND People.id=Staff.id
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q3: get details of the longest-serving and shortest-serving current Deans of Faculty
create or replace view Q3(status, name, faculty, starting)
as
SELECT 'Longest serving'AS status,Q2.name,Q2.faculty,Q2.station FROM Q2 WHERE Q2.station<=ALL(SELECT Q2.station FROM Q2) 
UNION
SELECT 'Shortest serving'AS status,Q2.name,Q2.faculty,Q2.station FROM Q2 WHERE Q2.station>=ALL(SELECT Q2.station FROM Q2)
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q4 UOC/ETFS ratio
create or replace view Q4(ratio,nsubjects)
as
SELECT CAST(uoc/eftsload AS numeric(4,1)), COUNT(CAST(uoc/eftsload AS numeric(4,1)))
FROM Subjects
WHERE eftsload is not null AND eftsload !=0
GROUP BY CAST(uoc/eftsload AS numeric(4,1))
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q5: program enrolment information from 10s1
--...Q5a is a view to find out the students who are international and enrolled in SENGA1 in 10S1
create or replace view Q5a(num)
as
SELECT COUNT(Program_enrolments.id)
FROM Students,Semesters,Streams,Program_enrolments,Stream_enrolments
WHERE Students.stype='intl' AND Semesters.name='Sem1 2010' AND Streams.code='SENGA1' 
AND Program_enrolments.student=Students.id AND Program_enrolments.semester=Semesters.id 
AND Stream_enrolments.stream=Streams.id AND Program_enrolments.id=Stream_enrolments.partof
;
--...Q5b is a view to find out the students who are local and enrolled in 3978 in 10S1
create or replace view Q5b(num)
as
SELECT COUNT(Program_enrolments.id) 
FROM Students,Semesters,Program_enrolments,Programs 
WHERE Students.stype='local' AND Semesters.name='Sem1 2010' AND Programs.code='3978' 
AND Program_enrolments.student=Students.id AND Program_enrolments.semester=Semesters.id 
AND Program_enrolments.program=Programs.id
;
--Q5c is a view to find out students who are enrolled in 10S1 in degrees offered by Faculty of Engineering
create or replace view Q5c(num)
as
SELECT COUNT(Program_enrolments.id)
FROM Semesters,Programs,Program_enrolments,OrgUnit_types,OrgUnits 
WHERE Semesters.name='Sem1 2010' AND OrgUnit_types.name='Faculty' AND OrgUnits.utype=OrgUnit_types.id 
AND OrgUnits.name='Faculty of Engineering' AND Programs.offeredby=OrgUnits.id 
AND Program_enrolments.semester=Semesters.id AND Program_enrolments.program=Programs.id
;



-- Q6: course CodeName
--...Q6 is function to display the subjects code and name together with a space
create or replace function
	Q6(text) returns text
as
$$SELECT CONCAT(code,' ',name) as text FROM Subjects 
WHERE code=$1
$$ language sql;



-- Q7: Percentage of growth of students enrolled in Database Systems
--...Q7_1 is a view to compute the growth of the enrolment of this year and the last year using lag
create or replace view Q7_1(year, term, perc_growth)
as
SELECT Semesters.year,Semesters.term,
CAST(1.0*COUNT(Course_enrolments.student)/lag(COUNT(Course_enrolments.student))over(order by Semesters.starting) AS numeric(4,2)) 
FROM Semesters,Courses,Course_enrolments,Subjects 
WHERE  Course_enrolments.course=Courses.id AND Courses.semester=Semesters.id 
AND Courses.subject=Subjects.id AND Subjects.name='Database Systems' 
AND Semesters.term!='X1' AND Semesters.term!='X2' 
GROUP BY Semesters.id,Semesters.year,Semesters.term 
ORDER BY Semesters.id 
;
--...Q7 is a view to delete the null value in Q7_1
create or replace view Q7(year, term, perc_growth)
as
SELECT * FROM Q7_1
WHERE Q7_1.perc_growth is not null;




-- Q8: Least popular subjects
--...Q8_1 is a view about all of the courses which has less than 20 students enrolled
create or replace view Q8_1(id,subject)
as
SELECT Courses.id,Courses.subject FROM Courses,Course_enrolments  
WHERE Course_enrolments.course=Courses.id  
GROUP BY Courses.id,Courses.subject 
HAVING COUNT(Course_enrolments.student)<20 
;
--...Q8_2 is a view about those courses has no student enrolled and not in the course_enrolments table
create or replace view Q8_2(id,subject)
as
SELECT Courses.id,Courses.subject 
FROM Courses left join Course_enrolments on Courses.id=Course_enrolments.course 
WHERE Course_enrolments.course is null
GROUP BY Courses.id 
;
--...Q8_3 is a view about all of the courses which have no students enrolled or less than 20
create or replace view Q8_3(id,subject)
as
SELECT id,subject FROM Q8_1 
UNION ALL 
SELECT id,subject FROM Q8_2 
;
--...Q8_4 is a view about top 20 courses in every subject which has more than 20 courses
create or replace view Q8_4(id,subject)
as
SELECT Courses.id,Courses.subject FROM Courses,Semesters,Subjects limit 0,20 
WHERE Courses.id=Subjects.course AND Courses.semester=Semesters.id 
GROUP BY Courses.id,Courses.subject,Semesters.starting 
HAVING COUNT(Courses.id)>=20
ORDER BY Semesters.starting
--...Q8 is a view about top 20 of the courses in one subjects have less than 20 students enrolled
create or replace view Q8(subject)
as
SELECT Subjects.code,Subjects.name FROM Subjects,Q8_3,Q8_4 
WHERE Q8_3.subject=Subjects.id AND  Q8_4.subject=Subjects.id
GROUP BY Subjects.code,Subjects.name 
;




-- Q9: Database Systems pass rate for both semester in each year
--...Q9_1 is a function about the amount of students who passed the courses in DB
create or replace function Q9_1(integer,text) returns bigint as
$$SELECT COUNT(Course_enrolments.student) as bigint
FROM Semesters,Courses,Course_enrolments,Subjects 
WHERE Semesters.year=$1 AND Semesters.term=$2 AND Courses.semester=Semesters.id 
AND Course_enrolments.course=Courses.id AND Course_enrolments.mark>=50 
AND Courses.subject=Subjects.id AND Subjects.name='Database Systems' 
$$ language sql;
--...Q9_2 is a function about the amount of students who actually received a mark in DB
create or replace function Q9_2(integer,text) returns bigint as
$$SELECT COUNT(Course_enrolments.student) as bigint
FROM Semesters,Courses,Course_enrolments,Subjects  
WHERE Semesters.year=$1 AND Semesters.term=$2 AND Courses.semester=Semesters.id 
AND Course_enrolments.course=Courses.id AND Course_enrolments.mark>=0 
AND Courses.subject=Subjects.id AND Subjects.name='Database Systems' 
$$ language sql;
--...Q9 is a view about the pass rate of S1 and S2 in different year
create or replace view Q9(year, s1_pass_rate, s2_pass_rate)
as
SELECT SUBSTR(CAST(Semesters.year AS VARCHAR(5)),3,2),CAST(1.0*Q9_1(Semesters.year,'S1')/Q9_2(Semesters.year,'S1') AS numeric(4,2)),
CAST(1.0*Q9_1(Semesters.year,'S2')/Q9_2(Semesters.year,'S2') AS numeric(4,2)) 
FROM Semesters
WHERE Q9_2(Semesters.year,'S1')!=0 AND Q9_2(Semesters.year,'S2')!=0
GROUP BY Semesters.year 
ORDER BY Semesters.year 
;


-- Q10: find all students who failed all black series subjects
--...Q10_1 is a view to look for the subjects satisfied 'COMP93' and appeared in every semester from 2002 to 2013
create or replace view Q10_1(id)
as
SELECT Subjects.id 
From Semesters,Subjects,Courses 
WHERE SUBSTR(Subjects.code,1,6)='COMP93' AND Subjects.id=Courses.subject 
AND Courses.semester=Semesters.id 
GROUP BY Subjects.id 
HAVING COUNT(Courses.id)=24 
;
--...Q10_2 is a view about students did not pass the courses of the first subjects,named 'COMP9331',found in Q10_1
create or replace view Q10_2(zid, name)
as
SELECT 'z'||People.unswid,People.name FROM People,Courses,Course_enrolments,Students,Semesters,Subjects 
WHERE Course_enrolments.mark<50 AND Courses.subject=Subjects.id AND Subjects.code='COMP9331'
AND Courses.semester=Semesters.id AND course_enrolments.course=Courses.id AND Students.id=Course_enrolments.student 
AND People.id=Students.id 
GROUP BY People.unswid,People.name 
;
--...Q10_3 is a view about students did not pass the courses of the first subjects,named 'COMP9311',found in Q10_1
create or replace view Q10_3(zid, name)
as
SELECT 'z'||People.unswid,People.name FROM People,Courses,Course_enrolments,Students,Semesters,Subjects 
WHERE Course_enrolments.mark<50 AND Courses.subject=Subjects.id AND Subjects.code='COMP9311'
AND Courses.semester=Semesters.id AND course_enrolments.course=Courses.id AND Students.id=Course_enrolments.student 
AND People.id=Students.id 
GROUP BY People.unswid,People.name 
;
--...Q10 is view to find out students who did not pass both of the two subjects using intersection
create or replace view Q10(zid, name)
as
SELECT Q10_2.zid,Q10_2.name FROM Q10_2 
INTERSECT 
SELECT Q10_3.zid,Q10_3.name FROM Q10_3
;
