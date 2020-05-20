select * from ssbsect;

select * from scbcrse;

select get_term_for_ar(trunc(sysdate)) from dual;

select max(scbcrse_title)keep(dense_rank last order by SCBCRSE_EFF_TERM) COURSE_NAME
from scbcrse 
where scbcrse_crse_numb = SSBSECT_CRSE_NUMB 
and SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE and SCBCRSE_EFF_TERM <= SSBSECT_TERM_CODE;

select * from (select scbcrse_subj_code, scbcrse_crse_numb,count(scbcrse_eff_term) over (partition by scbcrse_subj_code||scbcrse_crse_numb) cn
from scbcrse)
where cn>1
;

SELECT 
    scbcrse_subj_code
    , scbcrse_crse_numb
    , scbcrse_eff_term
    , scbcrse_coll_code
    , scbcrse_dept_code
    , scbcrse_title
    , scbcrse_credit_hr_low
    , row_number() OVER (PARTITION BY scbcrse_subj_code||scbcrse_crse_numb ORDER BY scbcrse_eff_term DESC) RN
FROM 
    scbcrse;
select * from all_col_comments where table_name = 'SCBCRSE';
select * from stvcoll;
select * from stvdept;
select * from stvcamp;
select * from stvterm;

select * from all_tab_comments where table_name = 'SFRSTCR';
select * from all_col_comments where table_name = 'SFRSTCR';
-- SFRSTCR_ERROR_FLAG: This field identifies an error associated with the registration of this CRN.  
-- Valid values are F=Fatal, D=Do not count in enrollment, L=WaitListed, O=Override, W=Warning, X=Delete (used only by SFRSTCR POSTUPDATE DB trigger).
select * from sfrstcr where sfrstcr_error_flag = 'D';
select * from stvrsts;
select distinct sfrstcr_crn, count(sfrstcr_pidm) over (partition by sfrstcr_crn) enrollment
from sfrstcr
where sfrstcr_term_code = 202030
and sfrstcr_error_flag not in ('D','L');
select * from sfrstcr where sfrstcr_term_code = 202030 and sfrstcr_crn = 30002 ;--and nvl(sfrstcr_error_flag,'-') not in ('D','L');

select * from sirasgn;
select * from sfrthst where sfrthst_term_code = 202030; --SFRTHST_TMST_CODE 
select * from all_tab_comments where comments like '%Student%Time%'; --= 'SFRTHST';
select * from SFRSTSH; --Student Centric Time Status History Table. empty
select * from SFRSTST; --Student Centric Time Status Table empty
select * from SFRSTSL; --Student Centric Time Status Levels table empty
select * from STVTREQ; --Student Time Requirement Validation Table empty
select * from SFRTHST; --Student Enrollment Time Status History Table
select sgbstdn_pidm,count(*) from sgbstdn group by sgbstdn_pidm; --sgbstdn_full_part_ind;
select * from sgbstdn where sgbstdn_pidm = 1018;
select sgbstdn_pidm, sgbstdn_full_part_ind,sgbstdn_term_code_eff, row_number() over (partition by sgbstdn_pidm order by sgbstdn_term_code_eff desc) rn
from sgbstdn 
where sgbstdn_term_code_eff <= 202130 and sgbstdn_full_part_ind is not null;
select * from SFRTHST; --Student Enrollment Time Status History Table
select * from stvtmst;

select * from SFRTHST;
select sfrthst_pidm, sfrthst_tmst_code,sfrthst_term_code, sfrthst_tmst_date, row_number() over (partition by sfrthst_pidm order by sfrthst_tmst_date desc) rn
from sfrthst;
select sfrthst_pidm
from sfrthst;

select * from sfrstcr where sfrstcr_term_code = 202030 and sfrstcr_crn = 30852;

select * from spriden where spriden_pidm = 215583; -- lear  N00215449
select * from sfrstcr where sfrstcr_term_code = 202030 and sfrstcr_pidm = 215583; 
select * from spriden where spriden_id = 'N00207673'; --207807
select * from sfrstcr where sfrstcr_term_code = 202030 and sfrstcr_pidm = 207807; 
select sum(sfrstcr_credit_hr) from sfrstcr where sfrstcr_term_code = 202030 and sfrstcr_pidm = 215583; 