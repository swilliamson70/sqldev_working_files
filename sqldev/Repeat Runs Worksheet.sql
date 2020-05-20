select * from all_tab_comments where table_name in ('SHRTCKN', 'SHRTCKG', 'SHRTCKL', 'SHRTRCE', 'SHRATTR', 'SHRDGMR', 'SHRTATT');

select * from shrtrce;

SELECT -- AC1
    'shrtckn/shrtckl/shrtckg' /*'NSU'*/ SRCE -- source
    , shrtckn_pidm      PIDM
    , shrtckn_term_code TERM
    , shrtckl_levl_code LVL
    , shrtckn_subj_code SUBJ
	, shrtckn_crse_numb CRS_NUM
	, shrtckg_credit_hours "CHRS"
    , shrtckg_grde_code_final "GRADE"
	, shrtckg_gmod_code "GMOD"
	, shrtckn_repeat_course_ind "REP_IND"
	, shrtckn_crse_title "TITLE"
	, 207263 "INST"
	, --NSU IPEDS Code
        99 "ATT_PERIOD"
				  
	, shrtckn_seq_no "CRS_SEQ1"
	, shrtckn_crn "CRS_SEQ2"

FROM
    shrtckn -- Institutional Course Term Maintenance Repeating Table [pidm,termcode,seq,crn,subj,crse]
        JOIN shrtckl -- Institutional Course Maintenance Level Applied Repeating Table [pidm,termcode,tckn_seq,levl(is this person taking UG or GR),prim_lvl_ind(is this their curr class levl),
            ON shrtckn_pidm = shrtckl_pidm
            AND shrtckn_term_code = shrtckl_term_code
            AND shrtckn_seq_no = shrtckl_tckn_seq_no
            AND shrtckl_levl_code = 'GR'
        JOIN(  -- Institutional Courses Grade Repeating Table [pidm,termcode,tcknseq(seq# of the course associated with the grade),seqno(seq# of the grade),grade,gmod_code(grading mode),credithours,gchg_code(grade change reason)]
            SELECT 
                shrtckg_pidm
                , shrtckg_term_code
                , shrtckg_tckn_seq_no
                , shrtckg_credit_hours 
                , shrtckg_grde_code_final 
                , shrtckg_gmod_code
                , shrtckg_seq_no
                , row_number() OVER (PARTITION BY shrtckg_pidm,shrtckg_term_code,shrtckg_tckn_seq_no ORDER BY shrtckg_seq_no DESC) rn
            FROM 
                shrtckg
            WHERE
                shrtckg_gmod_code <> 'D'
                AND shrtckg_grde_code_final NOT IN ('W' ,'AU' ,'F' ,'AW' ,'I' ,'N' ,'NA' ,'X' ,'WF' ,'U')
            ) 
            ON rn = 1
            AND shrtckn_pidm = shrtckg_pidm
			AND shrtckn_term_code = shrtckg_term_code
			AND shrtckn_seq_no = shrtckg_tckn_seq_no
--WHERE
    --shrtckn_pidm = 203241
;            
--	UNION
            SELECT
                'shrtrce' /*'XFER'*/ "SRCE"
                , shrtrce_pidm "PIDM"
                , shrtrce_term_code_eff "TERM"
                , shrtrce_levl_code "LVL"
                , shrtrce_subj_code "SUBJ"
                , shrtrce_crse_numb "CRS_NUM"
                , shrtrce_credit_hours "CHRS"
                , shrtrce_grde_code "GRADE"
                , shrtrce_gmod_code "GMOD"
                , shrtrce_repeat_course "REP_IND"
                , shrtrce_crse_title "TITLE"
                , shrtrce_trit_seq_no "INST"
                , shrtrce_tram_seq_no "ATT_PERIOD"
                , shrtrce_trcr_seq_no "CRS_SEQ1"
                , TO_CHAR(shrtrce_seq_no) "CRS_SEQ2"

            FROM
                shrtrce
 
            WHERE
                shrtrce_levl_code = 'GR'
                AND shrtrce_gmod_code <> 'D'
                AND shrtrce_grde_code NOT IN ('W' ,'AU' ,'F' ,'AW' ,'I' ,'N' ,'NA' ,'X' ,'WF' ,'U')
                
                AND(
                    shrtrce_repeat_course <> 'E'
                    OR shrtrce_repeat_course IS NULL
                )
            ;
                
                
            AND NOT EXISTS
                (
                    SELECT
                        'X'
                    FROM
                        shrtatt
                    WHERE
                        s2.shrtrce_pidm                   = shrtatt_pidm
                        AND s2.shrtrce_trit_seq_no        = shrtatt_trit_seq_no
                        AND s2.shrtrce_tram_seq_no        = shrtatt_tram_seq_no
                        AND s2.shrtrce_trcr_seq_no        = shrtatt_trcr_seq_no
                        AND s2.shrtrce_seq_no             = shrtatt_trce_seq_no
                        AND SUBSTR(shrtatt_attr_code,1,2) = 'RP'
                )
    ;
select * from shrtrce where shrtrce_levl_code = 'GR';
select * from shrdgmr;
select * from shrtatt;--where shrtatt_attr_code like 'RP%'
order by shrtatt_attr_code;
select * from shrtatt;
select * from all_col_comments where table_name = 'SHRTATT';
select distinct table_name from all_tab_comments where table_name like 'STV%';--and table_name not like '%_%' ;--and comments like '';
select * from stvattr; -- shrtatt

select * from shrtckg;

select * from nsudev.dw_eqiv; -- in banner nsu course that changed prefix or course number

select * from nsudev.dw_mexc; -- mutually exclusive