select distinct shrtckg_pidm
                    , shrtckg_term_code
                    , shrtckg_tckn_seq_no
                    , shrtckg_credit_hours
                    , shrtckg_grde_code_final
                    , shrtckg_gmod_code
from shrtckg where shrtckg_pidm = 31091 and shrtckg_term_code = 201430
group by shrtckg_pidm                    , shrtckg_term_code
                    , shrtckg_tckn_seq_no
                    , shrtckg_credit_hours
                    , shrtckg_grde_code_final, shrtckg_gmod_code

;

SELECT shrtckg_pidm
                    , shrtckg_term_code
                    , shrtckg_tckn_seq_no
                    , shrtckg_credit_hours
                    , shrtckg_grde_code_final
                    , shrtckg_gmod_code
                    --, shrtckg_seq_no
--                    , LAST_VALUE(shrtckg_seq_no) OVER (PARTITION BY shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no order by shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no, shrtckg_seq_no
--                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as highest_seq
                    , MAX(shrtckg_seq_no) KEEP (DENSE_RANK LAST ORDER BY shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no, shrtckg_seq_no)
                        OVER (PARTITION BY shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no) as highest_seq
                 FROM shrtckg
                 WHERE shrtckg_gmod_code <> 'D'
                    AND shrtckg_grde_code_final NOT IN ('W','AU','F','AW','I','N','NA','X','WF','U')
and shrtckg_pidm = 31091 and shrtckg_term_code = 201430
;

with w_cal as (select * from ptrcaln)
    ,w_2019 as (select * from w_cal where w_cal.ptrcaln_year = 2019)
select * from w_2019;


select * from shrtckg;