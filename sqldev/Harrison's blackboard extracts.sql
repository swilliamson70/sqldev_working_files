--courses---
WITH terms as
(
select * from
(select * from stvterm where sysdate <= STVTERM_END_DATE and substr(stvterm_code,-1,1) = '0' order by 1)
where rownum <3
)
select
      ssbsect_crn||'.'||SSBSECT_TERM_CODE  EXTERNAL_COURSE_KEY,
      ssbsect_crn||'.'||SSBSECT_TERM_CODE  COURSE_ID,
      SSBSECT_SUBJ_CODE||'.'||SSBSECT_CRSE_NUMB || ': ' ||(select max(scbcrse_title)keep(dense_rank last order by SCBCRSE_EFF_TERM) COURSE_NAME from scbcrse where scbcrse_crse_numb = SSBSECT_CRSE_NUMB and SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE and SCBCRSE_EFF_TERM <= SSBSECT_TERM_CODE)  COURSE_NAME ,
      ssbsect_term_code TERM_KEY,
      'N' AVAILABLE_IND,
      CASE  WHEN ssbsect_ssts_code <> 'C'
      THEN 'ENABLED'
      ELSE 'DISABLED' END AS ROW_STATUS,
      'TERM' as DURATION,
      'N' as ALLOW_GUEST_IND,
      CASE WHEN ssbsect_subj_code = 'UNIV' AND ssbsect_crse_numb = '1003'
      THEN 'Template-UNIV-1003_Fall_2018'
      else 'Template-2018' END  as Template_Course_Key
from ssbsect
JOIN terms ON stvterm_code = SSBSECT_TERM_CODE
;
--enrollments---
WITH terms as
(
select * from
(select * from stvterm where sysdate <= STVTERM_END_DATE and substr(stvterm_code,-1,1) = '0' order by 1)
where rownum <4
)
SELECT
        SFRSTCA_CRN || '.' || SFRSTCA_TERM_CODE EXTERNAL_COURSE_KEY,
        IP_ELEARN_ENROLLMENT.f_get_person_id(SFRSTCA_PIDM) EXTERNAL_PERSON_KEY,
        'Student' ROLE,
        case
                when SFRSTCA_ERROR_FLAG = 'D' and SFRSTCA_RSTS_CODE <> 'AU'
                then 'N'
                when SFRSTCA_RSTS_CODE in ('RE','RW','AU')
                then 'Y'
                else 'N'
                end as AVAILABLE_IND,
        case
                when SFRSTCA_ERROR_FLAG = 'D' and SFRSTCA_RSTS_CODE <> 'AU'
                then 'Disabled'
                when SFRSTCA_RSTS_CODE in ('RE','RW','AU')
                then 'Enabled'
                else 'Disabled'
                end as ROW_STATUS
from SFRSTCA sfr1
join terms on stvterm_code = sfrstca_term_code
where SFRSTCA_SEQ_NUMBER = (SELECT max(sfrstca_seq_number) keep (DENSE_RANK FIRST ORDER BY sfrstca_seq_number desc) FROM sfrstca sfr2
                                 where sfr2.SFRSTCA_PIDM = sfr1.SFRSTCA_PIDM
                                 and sfr2.SFRSTCA_TERM_CODE = sfr1.SFRSTCA_TERM_CODE
                                 and sfr2.SFRSTCA_CRN = sfr1.SFRSTCA_CRN
                                 and sfr2.SFRSTCA_SOURCE_CDE = sfr1.SFRSTCA_SOURCE_CDE)-- :tb_Term
and SFRSTCA_SOURCE_CDE = 'BASE'
and nvl(SFRSTCA_ERROR_FLAG,'A') not in ('F','L')
--Union in Faculty Instrucors
UNION
select
SIRASGN_CRN || '.' || SIRASGN_TERM_CODE EXTERNAL_COURSE_KEY,
GOBSRID_SOURCED_ID EXTERNAL_PERSON_KEY,
      'Instructor' as ROLE,
'Y' AVAILABLE_IND,
'enabled' as ROW_STATUS
from sirasgn
join gobsrid
on sirasgn_PIDM = gobsrid_pidm
join terms on stvterm_code = sirasgn_term_code
;