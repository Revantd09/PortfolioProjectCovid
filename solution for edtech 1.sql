Select * from users;
Select * from batches;
Select * from student_batch_maps;
Select * from instructor_batch_maps;
Select * from sessions;
Select * from attendances;
Select * from tests;
Select * from test_scores;

1.users table:  name(user name), active(boolean to check if user is active)
2.batches  table:  name(batch name), active(boolean to check if batch is active)
3.student_batch_maps  table: this table is a mapping of the student and his batch. deactivated_at is the time when a student is made inactive in a batch.
4.instructor_batch_maps  table: this table is a mapping of the instructor and the batch he has been assigned to take class/session.
5.sessions table: Every day session happens where the teacher takes a session or class of students.
6.attendances table: After session or class happens between teacher and student, attendance is given by student. students provide ratings to the teacher.
7.tests table: Test is created by instructor. total_mark is the maximum marks for the test.
8.test_scores table: Marks scored by students are added in the test_scores table.


-- Questions

--*Using the above table schema, please write the following queries. To test your queries, you can use some dummy data.

--3.What is the average marks scored by each student in all the tests the student had appeared?

--4.A student is passed when he scores 40 percent of total marks in a test. Find out how many students passed in each test. Also mention the batch name for that test.

/*
5.A student can be transferred from one batch to another batch. 
If he is transferred from batch a to batch b. batch b’s active=true and batch a’s active=false in student_batch_maps.
At a time, one student can be active in one batch only. 
One Student can not be transferred more than four times. Calculate each students attendance percentage for all the sessions created for his past batch. 
Consider only those sessions for which he was active in that past batch.
*/

--Note - Data is not provided for these tables, you can insert some dummy data if required.

/* Additional Questions added by techTFQ 

6. What is the average percentage of marks scored by each student in all the tests the student had appeared?

7. A student is passed when he scores 40 percent of total marks in a test. Find out how many percentage of students have passed in each test. Also mention the batch name for that test.

8. A student can be transferred from one batch to another batch. If he is transferred from batch a to batch b. batch b’s active=true and batch a’s active=false in student_batch_maps.
    At a time, one student can be active in one batch only. One Student can not be transferred more than four times.
    Calculate each students attendance percentage for all the sessions.
*/
----------------------------------------------------------------------------------------------------------------------------------
-- Question 1

/*
1.Calculate the average rating given by students to each teacher for each 
session created. Also, provide the batch name for which session was conducted.
*/

/*Select * from sessions;
Select * from attendances;
Select * from batches;*/

with avg_rating_teacher as (
select a.session_id as session_id, s.batch_id as batch_id, s.conducted_by as teacher_id, avg(a.rating) as avg_rating
	from attendances a
	join sessions s
	on a.session_id = s.id
	Group by a.session_id, s.conducted_by, s.batch_id
	order by s.conducted_by
)
select ar.session_id, round(ar.avg_rating::numeric,2) as avg_rat, b.name as batch_name, ar.teacher_id as teach_id
from avg_rating_teacher as ar
join batches b 
on ar.batch_id = b.id
order by ar.session_id


---------------------------------------------------------------------------------------------------------------

-- Question 2

/*
2.Find the attendance percentage for each session for each batch.
Also mention the batch name and users name who has conduct that session
*/

Select * from users;
Select * from batches;
Select * from sessions;
Select * from attendances;
Select * from student_batch_maps;

/*select a.session_id, count(session_id) --,a.session_id, sum(a.session_id) as attendance_percentage
from users u
left join attendances a 
on  u.id = a.student_id
Group by a.session_id
Having a.session_id is not null
order by a.session_id*/

/*
What's needed
a) Find total students who attended each session --value
b) find the total students who wer supposed to be present for each session -- total_value
result = a/b * 100
*/

with total_students_per_batch as
		(select batch_id, count(*) as students_per_batch
		from student_batch_maps
		where active = true
		group by batch_id), 
	multiple_batch_students as (
		select active.user_id as student_id, active.batch_id as active_batch, inactive.batch_id as inactive_batch
		from student_batch_maps active
		join student_batch_maps inactive
		on active.user_id = inactive.user_id
		Where active.active = true
		and inactive.active = false
	),
	students_present_per_Session as 
			(Select session_id, count(1) as attended_student
			from attendances a
			join sessions s on s.id = a.session_id
	        Where (a.student_id, s.batch_id) not in (select student_id, inactive_batch
	        from multiple_batch_students)
			group by session_id ) 
Select s.id as session_id,b.name as batch,u.name as teacher, s.batch_id, students_per_batch, attended_student, 
round((attended_student::decimal/students_per_batch::decimal)*100,2) as attendance_percentage
from sessions s
join total_students_per_batch tot
on tot.batch_id = s.batch_id
join students_present_per_Session std 
on std.session_id = s.id 
join batches b on b.id = s.batch_id
join users u on u.id = s.conducted_by;


-----------------------------------------------------------------------------------------------------------------
--Question 
/*3.What is the average marks scored by each student in all 
 the tests the student had appeared?*/

Select * from tests;
Select * from test_scores;

select user_id as student, round(avg(score::decimal),2) as avg_score
from test_scores
group by user_id
order by user_id

---------------------------------------------------------------------------------------
--Question
/*
4.A student is passed when he scores 40 percent of total marks in a test. 
Find out how many students passed in each test.
Also mention the batch name for that test.
*/

Select * from tests;
Select * from test_scores
Select * from batches;

-- version 1
With pass_percentage as
(select u.id, (ts.score::decimal/t.total_mark::decimal) * 100 as percentage, ts.test_id, t.batch_id,t.created_by
from test_scores ts
join tests t
on ts.test_id = t.id
join users u on u.id = ts.user_id
),
pass_status as 
(
    Select case 
            when percentage >= 40.0 Then 'Passed' Else 'Failed'
           End as status,*
    from pass_percentage
)
Select test_id, name, count(status)::int as number_of_students_passed
from pass_status p
join batches b
on p.batch_id = b.id
Where status = 'Passed'
Group by test_id, name
Order by test_id

-- version2
select ts.test_id,b.name as batch,count(1) as students_passed
from tests t
left join test_scores ts on t.id = ts.test_id
join users u on u.id = ts.user_id
join batches b on b.id = t.batch_id
where ((ts.score::decimal/t.total_mark::decimal)*100) >= 40
group by ts.test_id,b.name
order by 1;

------------------------------------------------------------------------------------------------------------------
--Question 
/*
5.A student can be transferred from one batch to another batch. 
If he is transferred from batch a to batch b. batch b’s active=true and batch a’s active=false in student_batch_maps.
At a time, one student can be active in one batch only. 
One Student can not be transferred more than four times. 
Calculate each students attendance percentage for all the sessions created for his past batch. 
Consider only those sessions for which he was active in that past batch.
*/

Select * from users;
Select * from batches;
Select * from student_batch_maps;
Select * from instructor_batch_maps;
Select * from sessions;
Select * from attendances;
Select * from tests;
Select * from test_scores;

with total_sessions as
		(select SBM.user_id as student_id, count(1) as total_sessions_per_student
		from student_batch_maps SBM
		join sessions s on s.batch_id = SBM.batch_id
		where SBM.active = false
		group by SBM.user_id
		order by 1),
     multiple_batch as
		(select inactive.user_id as user_id, inactive.batch_id as inactive_batch, active.batch_id  as active_batch
		from student_batch_maps active
		join student_batch_maps inactive on active.user_id = inactive.user_id
		where active.active = true
		and inactive.active = false
        ),filtered_users as(
    select user_id, count(*) as user_count
    from multiple_batch
    group by user_id
    having count(*)<=3
        ), multiple_batch_students as(
    Select mb.user_id as user_id, 
    mb.inactive_batch as inactive_batch,
    mb.active_batch as active_batch
    from multiple_batch mb
    join filtered_users fu
    on mb.user_id = fu.user_id
        ),
	attended_sessions as
		(select student_id, count(1) as sessions_attended_by_student
		from attendances a
		join sessions s on s.id = a.session_id
		where (a.student_id, s.batch_id)  in (select user_id, inactive_batch from multiple_batch_students)
		group by student_id)
select u.name as student
, round((coalesce(sessions_attended_by_student,0)::decimal/total_sessions_per_student::decimal) * 100,2) as student_attendence_percentage
from total_sessions TS
left join attended_sessions ATTS on ATTS.student_id = TS.student_id
join users u on u.id = TS.student_id
order by 1;
-------------------------------------------------------------------------------------------------------------------
/*6. What is the average percentage of marks scored by each student 
in all the tests the student had appeared?*/

Select * from tests;
Select * from test_scores;

with percentage_marks as
(select u.name as student, ts.test_id, t.total_mark, ts.score
	, round((ts.score::decimal/t.total_mark::decimal)*100,2) as marks_percentage
	from test_scores ts
	join tests t on t.id = ts.test_id
	join users u on u.id = ts.user_id)
select student, round(avg(marks_percentage),2) as avg_marks_percent
from percentage_marks
group by student
order by 1;

-------------------------------------------------------------------------------------------
/*
7. A student is passed when he scores 40 percent of total marks in a test. 
Find out how many percentage of students have passed in each test. 
Also mention the batch name for that test.
*/
Select * from tests;
Select * from test_scores;
Select * from users;
Select * from batches;

With pass_students as(
select ts.test_id as test_id,b.name as batch,count(1) as students_passed
from tests t
left join test_scores ts on t.id = ts.test_id
join users u on u.id = ts.user_id
join batches b on b.id = t.batch_id
where ((ts.score::decimal/t.total_mark::decimal)*100) >= 40
group by ts.test_id,b.name
order by 1
)
select tsc.test_id, Round(ps.students_passed::decimal/count(tsc.test_id)::decimal * 100,2) as pass_percentage,
ps.batch as batch 
from test_scores tsc
left join pass_students ps
on tsc.test_id = ps.test_id
Group by tsc.test_id, ps.students_passed, ps.batch
order by tsc.test_id

-------------------------------------------------------------------------------------------------------
-- Question 8 
/*
8. A student can be transferred from one batch to another batch. 
    If he is transferred from batch a to batch b. batch b’s active=true and batch a’s active=false in student_batch_maps.
    At a time, one student can be active in one batch only. 
    One Student can not be transferred more than four times.
    Calculate each students attendance percentage for all the sessions.
*/


Select * from users;
Select * from batches;
Select * from student_batch_maps;
Select * from instructor_batch_maps;
Select * from sessions;
Select * from attendances;
Select * from tests;
Select * from test_scores;


    
with total_sessions as
		(
        select SBM.user_id as student_id, count(1) as total_sessions_per_student
		from student_batch_maps SBM
		join sessions s on s.batch_id = SBM.batch_id
		where SBM.active = true
		group by SBM.user_id
		order by 1
        ),
multiple_batch as 
        ( 
        SELECT inactive.user_id as user_id, inactive.batch_id AS inactive_batch, active.batch_id AS active_batch, 
        COUNT(*) OVER (PARTITION BY inactive.user_id) AS user_count
        FROM student_batch_maps active
        JOIN student_batch_maps inactive ON active.user_id = inactive.user_id
        WHERE active.active = true
        AND inactive.active = false
        ),
multiple_batch_students as 
        (
        Select user_id, inactive_batch, active_batch
        from multiple_batch
        WHERE user_count <= 3
        ),
attended_sessions as
		(
        select student_id, count(1) as sessions_attended_by_student
		from attendances a
		join sessions s on s.id = a.session_id
		where (a.student_id, s.batch_id) not in (select user_id, inactive_batch from multiple_batch_students)
		group by student_id
    )
select u.name as student,
round((coalesce(sessions_attended_by_student,0)::decimal/total_sessions_per_student::decimal) * 100,2) as student_attendence_percentage
from total_sessions TS
left join attended_sessions ATS on ATS.student_id = TS.student_id
join users u on u.id = TS.student_id
order by 1;
