WITH INST_COURSES AS(
SELECT /*+ materialize */
    sorbtag.sorbtag_sbgi_code
    ,stvsbgi_desc
    ,sovsbgv_stat_code 
    ,sorbtag.ndg_eff SORBTAG_NDG_TERM_EFF
    ,sorbtag.as_eff SORBTAG_AS_TERM_EFF
    ,sorbtag.ba_eff SORBTAG_BA_TERM_EFF
    ,sorbtag.ma_eff SORBTAG_MA_TERM_EFF
    ,sorbtag.do_eff SORBTAG_DO_TERM_EFF

    ,shrtrat_program
    ,shrtrat_tlvl_code
    ,shrtrat_subj_code_trns
    ,shrtrat_crse_numb_trns
    ,shrtrat_term_code_eff
    ,shrtrat_subj_code_inst
    ,shrtrat_crse_numb_inst
    ,shrtrat_shrtatc_seqno                   
    ,shrtrat_attr_codes

FROM(
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
        )
    )SORBTAG -- list of inst with hlwk and dates 
    JOIN stvsbgi
        ON stvsbgi_code = sorbtag_sbgi_code
    JOIN sovsbgv    
        ON stvsbgi_code = sovsbgv_code
    LEFT JOIN(
            SELECT 
                shrtrat_sbgi_code
                ,shrtrat_program
                ,shrtrat_tlvl_code
                ,shrtrat_subj_code_trns
                ,shrtrat_crse_numb_trns
                ,shrtrat_term_code_eff
                ,shrtrat_subj_code_inst
                ,shrtrat_crse_numb_inst
                ,shrtrat_shrtatc_seqno                   
                ,LISTAGG(shrtrat_attr_code, ',') WITHIN GROUP (ORDER BY shrtrat_attr_code) SHRTRAT_ATTR_CODES
            FROM
                shrtrat
            GROUP BY 
                shrtrat_sbgi_code
                ,shrtrat_program
                ,shrtrat_tlvl_code
                ,shrtrat_subj_code_trns
                ,shrtrat_crse_numb_trns
                ,shrtrat_term_code_eff
                ,shrtrat_subj_code_inst
                ,shrtrat_crse_numb_inst
                ,shrtrat_shrtatc_seqno 
        ) SHRTRAT -- list of courses transfered from inst 
        ON sorbtag_sbgi_code = shrtrat_sbgi_code
        --AND sorbtag_term_code_eff = shrtrat_term_code_eff
WHERE --sorbtag_sbgi_code = '100636' -- '207661' --(rogers) '207500' 
( sorbtag_sbgi_code = '100636' and shrtrat_subj_code_trns = 'ACL' and shrtrat_crse_numb_trns = '2101')
or ( sorbtag_sbgi_code = '107585' and shrtrat_subj_code_trns = 'BIOL' and shrtrat_crse_numb_trns = '2014')
or ( sorbtag_sbgi_code = '107585' and shrtrat_subj_code_trns = 'NUR' and shrtrat_crse_numb_trns = '1011L')
or ( sorbtag_sbgi_code = '107992' and shrtrat_subj_code_trns = 'BIOL' and shrtrat_crse_numb_trns = '2061')
or ( sorbtag_sbgi_code = '108092' and shrtrat_subj_code_trns = 'MKTG' and shrtrat_crse_numb_trns = '457V')
or ( sorbtag_sbgi_code = '108092' and shrtrat_subj_code_trns = 'PRFS' and shrtrat_crse_numb_trns = '3143')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'ANTH' and shrtrat_crse_numb_trns = 'V02')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'ANTH' and shrtrat_crse_numb_trns = 'V35')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'ANTH' and shrtrat_crse_numb_trns = 'V35L')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'CHEM' and shrtrat_crse_numb_trns = 'V01B')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'CHEM' and shrtrat_crse_numb_trns = 'V01BL')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'LIB' and shrtrat_crse_numb_trns = 'V01')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'MATH' and shrtrat_crse_numb_trns = 'V02')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'MATH' and shrtrat_crse_numb_trns = 'V03')
or ( sorbtag_sbgi_code = '125028' and shrtrat_subj_code_trns = 'MATH' and shrtrat_crse_numb_trns = 'V10')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '3240')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '3303')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'ISM' and shrtrat_crse_numb_trns = '4301')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '3503')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '4061')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '4102')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '4625')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '4720')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '4801')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAN' and shrtrat_crse_numb_trns = '4900')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'MAR' and shrtrat_crse_numb_trns = '3802')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'BUL' and shrtrat_crse_numb_trns = '3310')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'ETI' and shrtrat_crse_numb_trns = '4448')
or ( sorbtag_sbgi_code = '137078' and shrtrat_subj_code_trns = 'FIN' and shrtrat_crse_numb_trns = '3403')
or ( sorbtag_sbgi_code = '155195' and shrtrat_subj_code_trns = 'AL' and shrtrat_crse_numb_trns = '226')
or ( sorbtag_sbgi_code = '160649' and shrtrat_subj_code_trns = 'SBIO' and shrtrat_crse_numb_trns = '101S')
or ( sorbtag_sbgi_code = '160649' and shrtrat_subj_code_trns = 'SHIS' and shrtrat_crse_numb_trns = '101S')
or ( sorbtag_sbgi_code = '160649' and shrtrat_subj_code_trns = 'SCOM' and shrtrat_crse_numb_trns = '201S')
or ( sorbtag_sbgi_code = '172963' and shrtrat_subj_code_trns = 'BIOL' and shrtrat_crse_numb_trns = '1106')
or ( sorbtag_sbgi_code = '172963' and shrtrat_subj_code_trns = 'BIOL' and shrtrat_crse_numb_trns = '1106')
or ( sorbtag_sbgi_code = '177117' and shrtrat_subj_code_trns = 'BUS' and shrtrat_crse_numb_trns = '212')
or ( sorbtag_sbgi_code = '177117' and shrtrat_subj_code_trns = 'EDU' and shrtrat_crse_numb_trns = '290')
or ( sorbtag_sbgi_code = '177117' and shrtrat_subj_code_trns = 'EDU' and shrtrat_crse_numb_trns = '310')
or ( sorbtag_sbgi_code = '179344' and shrtrat_subj_code_trns = 'TEC' and shrtrat_crse_numb_trns = '105')
or ( sorbtag_sbgi_code = '181312' and shrtrat_subj_code_trns = 'HLTH' and shrtrat_crse_numb_trns = '2610')
or ( sorbtag_sbgi_code = '187198' and shrtrat_subj_code_trns = 'BIO' and shrtrat_crse_numb_trns = '108')
or ( sorbtag_sbgi_code = '187198' and shrtrat_subj_code_trns = 'NURE' and shrtrat_crse_numb_trns = '130')
or ( sorbtag_sbgi_code = '187198' and shrtrat_subj_code_trns = 'NURE' and shrtrat_crse_numb_trns = '131')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'MATH' and shrtrat_crse_numb_trns = '1715')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'MATH' and shrtrat_crse_numb_trns = '1715')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'PSY' and shrtrat_crse_numb_trns = '3353')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'SOC' and shrtrat_crse_numb_trns = '3223')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'ART' and shrtrat_crse_numb_trns = '3133')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'TECH' and shrtrat_crse_numb_trns = '1212')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'TECH' and shrtrat_crse_numb_trns = '1222')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'TECH' and shrtrat_crse_numb_trns = '1230')
or ( sorbtag_sbgi_code = '207661' and shrtrat_subj_code_trns = 'POLS' and shrtrat_crse_numb_trns = '2123')
or ( sorbtag_sbgi_code = '207689' and shrtrat_subj_code_trns = 'AR' and shrtrat_crse_numb_trns = '3533')
or ( sorbtag_sbgi_code = '225308' and shrtrat_subj_code_trns = 'DEVL' and shrtrat_crse_numb_trns = '314')
or ( sorbtag_sbgi_code = '229799' and shrtrat_subj_code_trns = 'ACCT' and shrtrat_crse_numb_trns = '2401')
or ( sorbtag_sbgi_code = '229799' and shrtrat_subj_code_trns = 'DEVW' and shrtrat_crse_numb_trns = '302')
or ( sorbtag_sbgi_code = '229799' and shrtrat_subj_code_trns = 'POFT' and shrtrat_crse_numb_trns = '1429')
or ( sorbtag_sbgi_code = '234696' and shrtrat_subj_code_trns = 'BAS' and shrtrat_crse_numb_trns = '60')
or ( sorbtag_sbgi_code = '234696' and shrtrat_subj_code_trns = 'BIO' and shrtrat_crse_numb_trns = '121')
or ( sorbtag_sbgi_code = '234696' and shrtrat_subj_code_trns = 'BIO' and shrtrat_crse_numb_trns = '201')
or ( sorbtag_sbgi_code = '234696' and shrtrat_subj_code_trns = 'HO' and shrtrat_crse_numb_trns = '101')
or ( sorbtag_sbgi_code = '234696' and shrtrat_subj_code_trns = 'NA' and shrtrat_crse_numb_trns = '1')
or ( sorbtag_sbgi_code = '234696' and shrtrat_subj_code_trns = 'NUR' and shrtrat_crse_numb_trns = '10')
or ( sorbtag_sbgi_code = '234711' and shrtrat_subj_code_trns = 'BUS' and shrtrat_crse_numb_trns = '284')
or ( sorbtag_sbgi_code = '238722' and shrtrat_subj_code_trns = 'NATURE' and shrtrat_crse_numb_trns = '47057452')
or ( sorbtag_sbgi_code = '240505' and shrtrat_subj_code_trns = 'ECON' and shrtrat_crse_numb_trns = '1010')
or ( sorbtag_sbgi_code = '262031' and shrtrat_subj_code_trns = 'BIO' and shrtrat_crse_numb_trns = '240')
or ( sorbtag_sbgi_code = '420538' and shrtrat_subj_code_trns = 'LPN' and shrtrat_crse_numb_trns = '1702')
or ( sorbtag_sbgi_code = '420538' and shrtrat_subj_code_trns = 'LPN' and shrtrat_crse_numb_trns = '1802')
or ( sorbtag_sbgi_code = '420538' and shrtrat_subj_code_trns = 'LPN' and shrtrat_crse_numb_trns = '1902')
or ( sorbtag_sbgi_code = '00I013' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')
or ( sorbtag_sbgi_code = '00I039' and shrtrat_subj_code_trns = 'UNCL' and shrtrat_crse_numb_trns = '1999')





--ORDER BY 1,4
)
--select * from inst_courses;
, STUDENT_COURSES AS(
SELECT /*+ materialize */
    shrtrit_pidm
    ,spriden_id
    ,shrtrit_seq_no
    ,shrtrit_sbgi_code
    ,shrtrit_sbgi_desc
    ,shrtrit_official_trans_ind
    ,shrtram_seq_no
    ,shrtram_levl_code
    ,shrtram_attn_period
    ,shrtram_term_code_entered
    ,shrtrcr_seq_no
    ,shrtrcr_trans_course_name
    ,shrtrcr_trans_course_numbers
    ,shrtrcr_trans_credit_hours
    ,shrtrcr_trans_grade
    ,shrtrce_seq_no
    ,shrtrce_term_code_eff
    ,(
        SELECT MAX(shrtrat_term_code_eff) 
        FROM inst_courses
        WHERE shrtrit_sbgi_code = sorbtag_sbgi_code
            AND  shrtrcr_trans_course_name /*ENG*/ = shrtrat_subj_code_trns 
            AND shrtrcr_trans_course_numbers /*1113*/ = shrtrat_crse_numb_trns 
            AND shrtrce_term_code_eff /*197530*/ > shrtrat_term_code_eff /*000000 200120*/
    )inst_rec_term_eff
    ,shrtrce_levl_code
    ,shrtrce_subj_code
    ,shrtrce_crse_numb
    ,shrtrce_crse_title
    ,shrtrce_credit_hours
    ,shrtrce_grde_code
    ,shrtrce_gmod_code
    ,shrtrce_count_in_gpa_ind
    ,shrtatt.*
FROM 
    shrtrit -- list of stu with their transf inst
    JOIN spriden
        ON shrtrit_pidm = spriden_pidm
        AND spriden_change_ind IS NULL
     /*   AND shrtrit_sbgi_code in --= '207661'
            ('100636',
            '107585',
            '107992',
            '108092',
            '125028',
            '137078',
            '155195',
            '160649',
            '172963',
            '177117',
            '179344',
            '181312',
            '187198',
            '206817',
            '207661',
            '207689',
            '225308',
            '229799',
            '234696',
            '234711',
            '238722',
            '240505',
            '262031',
            '420538',
            '00I013',
            '00I039',
            '00I069',
            '00I163')
    */
    LEFT JOIN shrtram -- Attendance Period by Transfer Institution Repeating Table 
        ON shrtrit_pidm = shrtram_pidm
        AND shrtrit_seq_no = shrtram_trit_seq_no
    LEFT JOIN shrtrcr -- Transfer Course Detail Repeating Table
        ON shrtrit_pidm = shrtrcr_pidm
        AND shrtrit_seq_no = shrtrcr_trit_seq_no
        AND shrtram_seq_no = shrtrcr_tram_seq_no 
    LEFT JOIN shrtrce
        ON shrtrit_pidm = shrtrce_pidm 
        AND shrtrit_seq_no = shrtrce_trit_seq_no
        AND shrtram_seq_no = shrtrce_tram_seq_no
        AND shrtrcr_seq_no = shrtrce_trcr_seq_no
    LEFT JOIN (
        SELECT
            shrtatt_pidm
            ,shrtatt_trit_seq_no
            ,shrtatt_tram_seq_no
            ,shrtatt_trcr_seq_no
            ,shrtatt_trce_seq_no
            ,LISTAGG(shrtatt_attr_code, ',') WITHIN GROUP (ORDER BY shrtatt_attr_code) shrtatt_attr_codes
        FROM
            shrtatt
        GROUP BY
            shrtatt_pidm
            ,shrtatt_trit_seq_no
            ,shrtatt_tram_seq_no
            ,shrtatt_trcr_seq_no
            ,shrtatt_trce_seq_no
        ) SHRTATT --History Transfer Course Section Attribute Table
        ON shrtrit_pidm = shrtatt_pidm
        AND shrtrit_seq_no = shrtatt_trit_seq_no
        AND shrtram_seq_no = shrtatt_tram_seq_no
        AND shrtrcr_seq_no = shrtatt_trcr_seq_no
        AND shrtrce_seq_no = shrtatt_trce_seq_no     
--WHERE
  --  shrtram_pidm = 109775 -- 31091 --
    --and shrtram_trit_seq_no = 1 --shrtram_seq_no, shrtram_term_code_entered 1, 197530, 2, 197610
)

select inst_courses.*
,'--'
,student_courses.*
--shrtram_levl_code, shrtram_attn_period, shrtram_term_code_entered, shrtrcr_seq_no, shrtrcr_trans_course_name, shrtrcr_trans_course_numbers, shrtrcr_trans_credit_hours, shrtrcr_trans_grade, shrtrce_seq_no, shrtrce_term_code_eff, shrtrce_levl_code, shrtrce_subj_code, shrtrce_crse_numb, shrtrce_crse_title, shrtrce_credit_hours, shrtrce_grde_code, shrtrce_gmod_code, shrtrce_count_in_gpa_ind, shrtatt_pidm, shrtatt_trit_seq_no, shrtatt_tram_seq_no, shrtatt_trcr_seq_no, shrtatt_trce_seq_no, shrtatt_attr_codes
--from student_courses
--where spriden_id = 'N00232609'  ;


from inst_courses 


 left join student_courses
    ON inst_courses.sorbtag_sbgi_code = student_courses.shrtrit_sbgi_code
        --and inst_courses.SORBTAG_SBGI_CODE = '125028'
    AND trim(inst_courses.shrtrat_subj_code_trns) = trim(student_courses.shrtrcr_trans_course_name)
    AND trim(inst_courses.shrtrat_crse_numb_trns) = trim(student_courses.shrtrcr_trans_course_numbers)
    AND trim(inst_courses.shrtrat_subj_code_inst) = trim(student_courses.shrtrce_subj_code)
    AND trim(inst_courses.shrtrat_crse_numb_inst) = trim(student_courses.shrtrce_crse_numb)
    AND trim(inst_courses.shrtrat_term_code_eff) = trim(student_courses.inst_rec_term_eff)

--where spriden_id = 'N00232609' --student_courses.shrtrit_pidm = 109775   
--inst_courses.sorbtag_sbgi_code = '207661'
order by sorbtag_sbgi_code,SHRTRAT_SUBJ_CODE_TRNS, SHRTRAT_CRSE_NUMB_TRNS, SHRTRAT_TERM_CODE_EFF, spriden_id;

select * from all_tab_comments where table_name = 'SHRTATT';
select * from shrtrce;