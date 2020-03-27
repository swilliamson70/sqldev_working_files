--courses.csv - current term
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
    rownum                              AS RECORDNUMBER
    , stvcamp_desc                          CAMPUS
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN 
            'Extended Learning'
        ELSE
            stvcoll_desc
      END                                   SCHOOL
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN 
            'Organizational Leadership'
        ELSE
            stvdept_desc
      END                                   INSTITUTIONDEPARTMENT
    , ssbsect_term_code                     TERM
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN
            'ORGL'
        ELSE scbcrse_dept_code
      END                                   DEPARTMENT
    , scbcrse_crse_numb                     COURSE
    , ssbsect_seq_numb                      SECTION
    , stvcamp_desc                          CAMPUSTITLE
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN 
            'Extended Learning'
        ELSE
            stvcoll_desc
      END                                   SCHOOLTITLE
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN 
            'Organizational Leadership'
        ELSE
            stvdept_desc
      END                                   INSTITUIONDEPARTMENTTITLE    
    , scbcrse_title                         COURSETITLE
    , TRIM(ssbsect_subj_code) 
        || ' '
        || TRIM(scbcrse_crse_numb)          INSTITUIONCOURSECODE
    , TRIM(ssbsect_subj_code) 
        || ' '
        || TRIM(scbcrse_crse_numb)
        || ' '
        || TRIM(ssbsect_seq_numb)           INSTITUIONCLASSCODE
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN
            'ORGL'
        ELSE scbcrse_dept_code
      END                                   INSTITUTIONSUBJECTCODES
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN 
            'Organizational Leadership'
        ELSE
            stvdept_desc
      END                                   INSTITUTIONSUBJECTSTITLE
    , ssbsect_crn                           CRN
    , stvterm_desc                          TERMTITLE
    , 'Semester'                            TERMTYPE  
    , TO_CHAR(stvterm_start_date,'yyyy-MM-DD')      TERMSTARTDATE
    , TO_CHAR(stvterm_end_date,'yyyy-MM-DD')        TERMENDDATE
    , TO_CHAR(ssbsect_ptrm_start_date,'yyyy-MM-DD') SECTIONSTARTDATE
    , TO_CHAR(ssbsect_ptrm_end_date,'yyyy-MM-DD')   SECTIONENDDATE
    , null                                  CLASSGROUPID
    , enrollment                            ESTIMATEDENROLLMENT    
FROM
    ssbsect
    JOIN stvcamp
        ON ssbsect_camp_code = stvcamp_code
    JOIN stvterm
        ON ssbsect_term_code = stvterm_code
    JOIN(
        SELECT DISTINCT 
            sfrstcr_crn
            , COUNT(sfrstcr_pidm) OVER (PARTITION BY sfrstcr_crn) ENROLLMENT
        FROM sfrstcr
        WHERE sfrstcr_term_code = NSUDEV.GET_TERM_FOR_AR(TRUNC(SYSDATE))
        AND NVL(sfrstcr_error_flag,'A') NOT IN ('D','L') --no Deletes, Wait Listeds
    ) ON ssbsect_crn = sfrstcr_crn
    JOIN(
        SELECT 
            scbcrse_subj_code
            , scbcrse_crse_numb
            , scbcrse_eff_term
            , scbcrse_coll_code
            , stvcoll_desc
            , scbcrse_dept_code
            , stvdept_desc
            , scbcrse_title
            , scbcrse_credit_hr_low
            , row_number() OVER (PARTITION BY scbcrse_subj_code||scbcrse_crse_numb ORDER BY scbcrse_eff_term DESC) RN
        FROM 
            scbcrse
            JOIN stvcoll
                ON scbcrse_coll_code = stvcoll_code
            JOIN stvdept
                ON scbcrse_dept_code = stvdept_code) SCBCRSE
        ON scbcrse_crse_numb = ssbsect_crse_numb 
        AND ssbsect_subj_code = scbcrse_subj_code
        AND rn = 1
WHERE
    ssbsect_term_code = NSUDEV.GET_TERM_FOR_AR(TRUNC(SYSDATE))    
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
    rownum                              AS  RECORDNUMBER --Field 1
    , stvcamp_desc                          CAMPUS --2
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN 
            'Extended Learning'
        ELSE
            stvcoll_desc
      END                                   SCHOOL --3
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN 
            'Organizational Leadership'
        ELSE
            stvdept_desc
      END                                   INSTITUTIONDEPARTMENT --4
    , classes.term_code                     TERM --5
    --, classes.crn
    , CASE
        WHEN ssbsect_subj_code = 'ORGL' THEN
            'ORGL'
        ELSE ssbsect_subj_code --dept_code
      END                                   DEPARTMENT --6
    , ssbsect_crse_numb                     COURSE --7
    , ssbsect_seq_numb                      SECTION --8
    , goremal_email_address                 EMAIL --9
    , spriden_first_name                    FIRSTNAME --10 
    , spriden_mi                            MIDDLENAME --11 
    , spriden_last_name                     LASTNAME --12 
    , role                                  USERROLE --13 
    , spriden_id                            SISUSERID --14 
    , CASE
        WHEN role = 'TEACHER' THEN
            null
        ELSE
            'N'
        END                                 INCLUDEDINCOURSEFEE --15 
    , CASE
        WHEN SUBSTR(classes.term_code,5,2) = '10' AND classes.hours < 6 THEN
            'P'
        WHEN SUBSTR(classes.term_code,5,2) <> '10' AND classes.hours < 12 THEN
            'P'
        ELSE
            'F'
        END                                 STUDENTFULLPARTTIMESTATUS
    , scbcrse_credit_hr_low                 CREDITHOURS --17 
FROM(
    SELECT
        sfrstcr_term_code   TERM_CODE
        , sfrstcr_crn       CRN
        , sfrstcr_pidm      PIDM
        , 'STUDENT'         ROLE
        , SUM(sfrstcr_credit_hr) OVER (PARTITION BY sfrstcr_pidm) HOURS
    FROM
        sfrstcr
        LEFT JOIN(
            SELECT 
                sfrthst_pidm
                , sfrthst_tmst_code
                , sfrthst_term_code
                , sfrthst_tmst_date
                , row_number() OVER (PARTITION BY sfrthst_pidm ORDER BY sfrthst_tmst_date DESC) rn
            FROM
                sfrthst
        ) 
            ON sfrstcr_pidm = sfrthst_pidm
            AND rn = 1
    WHERE
        sfrstcr_term_code = NSUDEV.GET_TERM_FOR_AR(TRUNC(SYSDATE))
        AND NVL(sfrstcr_error_flag,'A') NOT IN ('D','L') --no Deletes, Wait Listeds 
    UNION
    SELECT
        sirasgn_term_code
        , sirasgn_crn
        , sirasgn_pidm
        , 'TEACHER'
        , null
    FROM
        sirasgn
    WHERE
        sirasgn_term_code = NSUDEV.GET_TERM_FOR_AR(TRUNC(SYSDATE)) 
    )CLASSES
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
            spriden_change_ind is null
    )
        ON classes.pidm = spriden_pidm  
    JOIN(
        SELECT 
            goremal_pidm
            , goremal_email_address
        FROM
            goremal
        WHERE
            goremal_emal_code = 'NSU'
    )
        ON classes.pidm = goremal_pidm
    JOIN(
        SELECT
            ssbsect_term_code
            , ssbsect_crn
            , ssbsect_subj_code
            , ssbsect_crse_numb
            , ssbsect_seq_numb
            , ssbsect_camp_code
            , stvcamp_desc
        FROM
            ssbsect
            JOIN stvcamp
                ON ssbsect_camp_code = stvcamp_code
        WHERE
            ssbsect_term_code = NSUDEV.GET_TERM_FOR_AR(TRUNC(SYSDATE)) 
        )
            ON classes.term_code = ssbsect_term_code
            AND classes.crn = ssbsect_crn
        JOIN(
            SELECT 
                scbcrse_subj_code
                , scbcrse_crse_numb
                , scbcrse_eff_term
                , scbcrse_coll_code
                , stvcoll_desc
                , scbcrse_dept_code
                , stvdept_desc
                , scbcrse_title
                , scbcrse_credit_hr_low
                , row_number() OVER (PARTITION BY scbcrse_subj_code||scbcrse_crse_numb ORDER BY scbcrse_eff_term DESC) RN
            FROM 
                scbcrse
                JOIN stvcoll
                    ON scbcrse_coll_code = stvcoll_code
                JOIN stvdept
                    ON scbcrse_dept_code = stvdept_code
        ) SCBCRSE
            ON  ssbsect_crse_numb = scbcrse_crse_numb
            AND ssbsect_subj_code = scbcrse_subj_code
            AND rn = 1

WHERE
    classes.term_code = NSUDEV.GET_TERM_FOR_AR(TRUNC(SYSDATE))
ORDER BY 6,7,8,13,12,10
--ORDER BY 7,8,9,14,13,11 -- with crn added
;