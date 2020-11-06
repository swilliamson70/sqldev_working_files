SELECT *
FROM 
    stvsbgi -- list of institutions
WHERE 
    stvsbgi_desc like 'Rogers%' -- 207661
;
SELECT *
FROM 
SOVSBGV
;

SELECT * 
/*
_sbgi_code 207661
_term_code_eff 000000
_hlwk_code AS - Highest Degree Level Offered -- stvhlwk (as, associate, ba, bachelor, do, doctorate, ma, masters, ndg, non-degree granting)
_acpr_code CA - Acceptance Practice
_cald_code SSEM	- Calendar Type and Multipier
_taau_code REG - Acceptance Authority
_reported_by DegreeeWorks
_reported_info 
_activity_date 30-SEP-13
*/
FROM 
    sorbtag -- list of inst with hlwk and dates -- Transfer Articulation General Data - entered on SOABGTA
WHERE 
    sorbtag_sbgi_code = '207661'
;

SELECT 
    sorbtag_sbgi_code
    ,ndg_eff
    ,as_eff
    ,ba_eff
    ,ma_eff
    ,do_eff
FROM(
    SELECT DISTINCT
        sorbtag_sbgi_code   
        ,sorbtag_hlwk_code
        ,sorbtag_term_code_eff    
    FROM(
        SELECT 
            l.sorbtag_sbgi_code
            ,l.sorbtag_hlwk_code
            ,MIN(l.sorbtag_term_code_eff) OVER (PARTITION BY l.sorbtag_sbgi_code, l.sorbtag_hlwk_code) SORBTAG_TERM_CODE_EFF
            ,r.sorbtag_acpr_code
            ,r.sorbtag_cald_code
            ,r.sorbtag_taau_code
        FROM
            sorbtag l 
            JOIN sorbtag r
                ON l.sorbtag_sbgi_code = r.sorbtag_sbgi_code
                AND l.sorbtag_hlwk_code = r.sorbtag_hlwk_code
                AND l.sorbtag_term_code_eff = r.sorbtag_term_code_eff
        )
    ) T PIVOT(
            MIN(sorbtag_term_code_eff)
            FOR(sorbtag_hlwk_code)
            IN ('NDG' NDG_EFF,'AS' AS_EFF,'BA' BA_EFF,'MA' MA_EFF,'DO' DO_EFF)
    ) sorbtag
    
where sorbtag_sbgi_code = '207661';
SELECT *
FROM
    shrtrat -- list of courses transfered from inst --Transfer Articulation Course Attribute Repeating Table
WHERE
    shrtrat_sbgi_code = '207661'
    AND shrtrat_term_code_eff = '000000';
select * from stvhlwk;

SELECT *
FROM 
    shrtrit -- list of stu with their transf inst
WHERE
    shrtrit_sbgi_code = '207661' -- pidm = 109775 shrtrit_seq_no 1
;
    
SELECT *
FROM
    shrtram -- Attendance Period by Transfer Institution Repeating Table 
WHERE
    shrtram_pidm = 109775
    and shrtram_trit_seq_no = 1 --shrtram_seq_no, shrtram_term_code_entered 1, 197530, 2, 197610
;

SELECT *
FROM
    shrtrcr
WHERE
    shrtrcr_pidm = 109775
    and shrtrcr_trit_seq_no = 1
    and shrtrcr_tram_seq_no = 1 -- shrtrct_trans_course_name, _trans_course_numbers, _credit_hours, trans_grade, trans_grade_mode, levl_code, term_code
; -- _seq_no 1,2 ENG 1113, MICR 2124 

SELECT *
FROM
    shrtrce
WHERE
    shrtrce_pidm = 109775
    AND shrtrce_trit_seq_no = 1
    AND shrtrce_tram_seq_no = 1 -- _seq_no, trcr_seq_no, subj_code 1,1,engl 1113, 1,2, lgcy 2000
;

