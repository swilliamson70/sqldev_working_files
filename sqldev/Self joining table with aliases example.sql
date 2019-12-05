with w_goremal as(
    select
        goremal_pidm
        , goremal_email_address
    from
        goremal
    where
        goremal_status_ind = 'A'
        and goremal_emal_code = 'NSU'
)
    , w_relationship as(
    select 1019 as student_pidm
        , 1023 as instructor_pidm
        
    from dual
)

select student.goremal_email_address
        , instructor.goremal_email_address
    from w_relationship
        join w_goremal student 
            on w_relationship.student_pidm = student.goremal_pidm
        join w_goremal instructor
            on w_relationship.instructor_pidm = instructor.goremal_pidm
;



select * from goremal;