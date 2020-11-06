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
WHERE sorbtag_sbgi_code = '207661' -- '207500' 
--ORDER BY 1,4
)

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
    ,shrtatt_attr_codes
    --,shrtatt.*
FROM 
    shrtrit -- list of stu with their transf inst
    JOIN spriden
        ON shrtrit_pidm = spriden_pidm
        AND spriden_change_ind IS NULL
        AND shrtrit_sbgi_code = '207661'
    JOIN shrtram -- Attendance Period by Transfer Institution Repeating Table 
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
        ) SHRTATT
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
--from student_courses;
from inst_courses 
left join student_courses
    ON inst_courses.sorbtag_sbgi_code = student_courses.shrtrit_sbgi_code
    AND inst_courses.shrtrat_subj_code_trns = student_courses.shrtrcr_trans_course_name
    AND inst_courses.shrtrat_crse_numb_trns = student_courses.shrtrcr_trans_course_numbers
    AND inst_courses.shrtrat_term_code_eff = student_courses.inst_rec_term_eff

where --student_courses.shrtrit_pidm = 109775   
inst_courses.sorbtag_sbgi_code = '207661'
order by SHRTRAT_SUBJ_CODE_TRNS, SHRTRAT_CRSE_NUMB_TRNS, SHRTRAT_TERM_CODE_EFF; --

--        SELECT MAX(shrtrat_term_code_eff) 
--        FROM inst_courses
--        WHERE /*shrtrit_sbgi_code = */ sorbtag_sbgi_code = '207661'
--            AND  /*shrtrcr_trans_course_name */ shrtrat_subj_code_trns ='ENG' -- = 
--            AND /*shrtrcr_trans_course_numbers */ shrtrat_crse_numb_trns = '1113'
--            AND 197530 > shrtrat_term_code_eff -- 000000 200120
; --

------------

SELECT 
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
                shrtrat SHRTRAT
--            WHERE 
--                shrtrat_activity_date = (
--                    SELECT MAX(d.shrtrat_activity_date)
--                    FROM shrtrat d
--                    WHERE shrtrat.shrtrat_sbgi_code = d.shrtrat_sbgi_code
--                        AND shrtrat.shrtrat_subj_code_trns = d.shrtrat_subj_code_trns
--                        AND shrtrat.shrtrat_crse_numb_trns = d.shrtrat_crse_numb_trns
--                    )
                    
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
WHERE sorbtag_sbgi_code = '207661' -- '207500' 
ORDER BY SHRTRAT_SUBJ_CODE_TRNS, SHRTRAT_CRSE_NUMB_TRNS;

select * from shrtrat where shrtrat_sbgi_code = '207661' and shrtrat_subj_code_trns = 'ENG' and shrtrat_crse_numb_trns = 1113;
