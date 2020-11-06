select * from shrtckn; --pidm term_code seq_no crn
select * from shrtckg; --pidm term_code tckn_seq_no, seq_no, grde_code_final
select * from shrtckl; --pidm term_code tckn_seq_no, levl_code

/*s3.shrtckn_pidm           = s4.shrtckg_pidm
AND s3.shrtckn_term_code  = s4.shrtckg_term_code
AND s3.shrtckn_seq_no     = s4.shrtckg_tckn_seq_no
AND s3.shrtckn_pidm       = s5.shrtckl_pidm
AND s3.shrtckn_term_code  = s5.shrtckl_term_code
AND s3.shrtckn_seq_no     = s5.shrtckl_tckn_seq_no
AND s4.shrtckg_gmod_code <> 'D'
AND s4.shrtckg_grde_code_final NOT IN ('W' ,'AU' ,'F' ,'AW' ,'I' ,'N' ,'NA' ,'X' ,'WF' ,'U')
AND s4.shrtckg_seq_no =
(
    SELECT
        MAX(sm.shrtckg_seq_no)
    FROM
        shrtckg sm
    WHERE
        s4.shrtckg_pidm            = sm.shrtckg_pidm
        AND s4.shrtckg_term_code   = sm.shrtckg_term_code
        AND s4.shrtckg_tckn_seq_no = sm.shrtckg_tckn_seq_no
)
AND
(
    s3.shrtckn_repeat_course_ind         <> 'E'
    OR s3.shrtckn_repeat_course_ind IS NULL
)
AND SUBSTR(s3.shrtckn_crse_numb,2,3) <> '000'
AND SUBSTR(s3.shrtckn_crse_numb,2,3) <> '999'
AND SUBSTR(s3.shrtckn_subj_code,1,3) <> 'UNC'
AND s3.shrtckn_term_code              >
(
    SELECT
        NVL(MAX(shrdgmr_term_code_grad),'000000')
    FROM
        shrdgmr
    WHERE
        shrdgmr_pidm          = s3.shrtckn_pidm
        AND shrdgmr_levl_code = s5.shrtckl_levl_code
        AND shrdgmr_degs_code = 'AW'
)
AND NOT EXISTS
(
    SELECT
        'X'
    FROM
        shrattr
    WHERE
        s3.shrtckn_pidm                   = shrattr_pidm
        AND s3.shrtckn_term_code          = shrattr_term_code
        AND s3.shrtckn_seq_no             = shrattr_tckn_seq_no
        AND SUBSTR(shrattr_attr_code,1,2) = 'RP'
)
*/