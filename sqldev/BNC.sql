--courses.csv - historical
/*fields
 1 recordNumber
 2 campus
 3 school
 4 institutionDepartment
 5 term
 6 department
 7 course
 8 section
 9 campusTitle
10 schoolTitle
11 instituionDepartmentTitle
12 courseTitle
13 InstituionCourseCode
14 instituionClassCode
15 institutionSubjectCodes
16 institutionSubjectsTitle
17 crn
18 termTitle
19 termType
20 termStartDate
21 termEndDate
22 sectionStartDate
23 sectionEndDate
24 classGroupId
25 estimatedEnrollment
*/

SELECT -- bnc courses
    rownum              AS  recordNumber
    , camp_desc             campus
    -- per Julie - ORGL was never changed in Banner when it was moved from B&T
    , CASE
        WHEN subj_code = 'ORGL' THEN 
            'Extended Learning'
        ELSE
            coll_desc
      END school
    , CASE
        WHEN subj_code = 'ORGL' THEN 
            'Organizational Leadership'
        ELSE
            dept_desc
      END institutionDepartment
    , term_code_key         term
    , CASE
        WHEN subj_code = 'ORGL' THEN
            'ORGL'
        ELSE dept_code
      END department
    , crse_number           course
    , seq_number_key        section
    , camp_desc             campusTitle
    , CASE
        WHEN subj_code = 'ORGL' THEN 
            'Extended Learning'
        ELSE
            coll_desc
      END schoolTitle
    , CASE
        WHEN subj_code = 'ORGL' THEN 
            'Organizational Leadership'
        ELSE
            dept_desc
      END instituionDepartmentTitle
    , title                 courseTitle
    , TRIM(subj_code) 
        || ' '
        || TRIM(crse_number)    InstituionCourseCode
    , TRIM(subj_code) 
        || ' '
        || TRIM(crse_number)
        || ' '
        || TRIM(seq_number_key) instituionClassCode
    , subj_code             institutionSubjectCodes
    , subj_desc             institutionSubjectsTitle
    , crn_key               crn
    , term_desc             termTitle
    , 'Semester'            termType
    , TO_CHAR(stvterm_start_date,'yyyy-MM-DD')  termStartDate
    , TO_CHAR(stvterm_end_date,'yyyy-MM-DD')    termEndDate
    , TO_CHAR(ptrm_start_date,'yyyy-MM-DD')     sectionStartDate
    , TO_CHAR(ptrm_end_date,'yyyy-MM-DD')       sectionEndDate
    , null                  classGroupId
    , actual_enrollment     estimatedEnrollment

FROM
    nsuodsmgr.as_catalog_schedule
    JOIN stvterm
        ON as_catalog_schedule.term_code_key = stvterm.stvterm_code
WHERE
    active_section_ind = 'Y'
    AND term_code_key BETWEEN 201910 AND 202030
;
---------------------------------------------------------------------------------------

--enrollements.csv
/*fields
 1 recordNumber
 2 campus
 3 school
 4 institutionDepartment
 5 term
 6 department
 7 course
 8 section
 9 email
10 firstName
11 middleName
12 lastName
13 userRole
14 sisUserid
15 includedinCourseFee
16 studentFullPartTimeStatus
17 creditHours
*/

SELECT -- bnc enrollments
    rownum              AS  recordNumber --Field 1
    , camp_desc             campus --2
    , CASE
        WHEN subj_code = 'ORGL' THEN 
            'Extended Learning'
        ELSE
            coll_desc
      END              school --3
    , CASE
        WHEN subj_code = 'ORGL' THEN 
            'Organizational Leadership'
        ELSE
            dept_desc
      END institutionDepartment --4
    , term_code_key         term --5
    , CASE
        WHEN subj_code = 'ORGL' THEN
            'ORGL'
        ELSE subj_code --dept_code
      END department --6
    , crse_number           course --7
    , seq_number_key        section --8
    , goremal_email_address email --9
    , spriden_first_name    firstName --10 
    , spriden_mi            middleName --11 
    , spriden_last_name     lastName --12 
    , role                  userRole --13 
    , spriden_id            sisUserid --14 
    , CASE
        WHEN role = 'TEACHER' THEN
            null
        ELSE
            'N'
        END as includedinCourseFee --15 
    , time_status           studentFullPartTimeStatus --16 
    , substr(crse_number,4,1)   creditHours --17 

FROM
    nsuodsmgr.as_catalog_schedule  
    
    LEFT JOIN(
        SELECT
            role
            , person_uid
            , academic_period
            , course_reference_number
            , spriden_id
            , spriden_last_name
            , spriden_first_name
            , spriden_mi
            , goremal_email_address
            , time_status
        FROM(
            SELECT
                'TEACHER' as ROLE
                , instructional_assignment.person_uid
                , instructional_assignment.academic_period
                , instructional_assignment.course_reference_number
                , null time_status
            FROM
                instructional_assignment
/* The Student Data will not be included in the History upload
            UNION
            SELECT
                'STUDENT' as ROLE
                , student_course.person_uid
                , student_course.academic_period
                , student_course.course_reference_number
                , academic_study_extended.time_status
            FROM
                (   SELECT
                        person_uid
                        , academic_period
                        , course_reference_number
                    FROM
                        student_course
                    WHERE
                        registration_status not in ('OW','DD','DW','OD','WL')
                ) student_course
                JOIN(
                    SELECT
                        academic_study_extended.person_uid
                        , academic_study_extended.academic_period
                        ,  CASE
                            WHEN academic_study_extended.current_time_status = 'FT' THEN
                                'F'
                            ELSE
                                'P'
                        END time_status
                        
                    FROM
                        academic_study_extended) academic_study_extended
                    ON student_course.person_uid = academic_study_extended.person_uid
                    AND student_course.academic_period = academic_study_extended.academic_period
*/
            )
            JOIN(
                SELECT
                    spriden_pidm
                    , spriden_id
                    , spriden_last_name
                    , spriden_first_name
                    , spriden_mi
                FROM
                    spriden
                WHERE 
                    spriden_change_ind is null)
                ON person_uid = spriden_pidm
            JOIN(
                SELECT 
                    goremal_pidm
                    , goremal_email_address
                FROM
                    goremal
                WHERE
                    goremal_emal_code = 'NSU')
                ON person_uid = goremal_pidm
        ) ON term_code_key = academic_period
        AND crn_key = course_reference_number 
WHERE
    active_section_ind = 'Y'
    AND term_code_key BETWEEN 201910 AND 202030
;
