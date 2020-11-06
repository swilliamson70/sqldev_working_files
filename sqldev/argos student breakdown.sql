SELECT
  spriden_pidm as NSU_USE_PIDM,
  spriden_first_name || ' ' || spriden_last_name fullName,
  sobptrm_term_code as termCode,
  sobptrm_ptrm_code as subTermCode,
  stvterm_desc,
  spriden_id as studentId,
  GOBINTL_SPON_CODE,
  GOBINTL_FOREIGN_SSN,
  scbcrse_subj_Code || ' ' || scbcrse_crse_numb as courseSubjectCode,
  scbcrse_title as courseSubjectDesc,
  ssbsect_crn as courseNumber,
  sfrstcr_bill_hr as billableHours,
  sfrrgfe_per_cred_charge as creditHourCost,
  sfrrgfe_min_charge,
  ((sfrstcr_bill_hr * sfrrgfe_per_cred_charge) + sfrrgfe_min_charge) costs,
      -- FEES
        sfrrgfe_detl_code as feeTypeCode,
        tbbdetc_desc as feeDesc,
        stvschd_desc as schedule_type
--select*
from
spriden
join sgbstdn
  on sgbstdn_pidm = spriden_pidm
join sfrstcr
  on spriden_pidm = sfrstcr_pidm
join stvterm
  on stvterm_code = sfrstcr_term_code
join ssbsect
  on ssbsect_term_code = sfrstcr_term_code
  and ssbsect_crn = sfrstcr_crn
  and ssbsect_ptrm_code = sfrstcr_ptrm_code
join stvschd
  on stvschd_code = ssbsect_schd_code
join
(
  select * from scbcrse where SCBCRSE_EFF_TERM = ( select max(s2.SCBCRSE_EFF_TERM) from scbcrse s2 where s2.scbcrse_subj_code = scbcrse.scbcrse_subj_code and s2.scbcrse_crse_numb = scbcrse.scbcrse_crse_numb)
) scbcrse
  on scbcrse_subj_code = ssbsect_subj_code
  and scbcrse_crse_numb = ssbsect_crse_numb


join sobptrm
  on sobptrm.SOBPTRM_TERM_CODE = sfrstcr.sfrstcr_term_code
  and sobptrm.SOBPTRM_PTRM_CODE = sfrstcr.SFRSTCR_PTRM_CODE

left join
( select * from ssrattr union select null,null,null,null,null,null,null,null,null from dual )ssrattr
  on (ssrattr_term_code = sobptrm_term_code
  and ssrattr_crn = sfrstcr.SFRSTCR_CRN
  and length(ssrattr_attr_code) = 4
  and substr(ssrattr_attr_code,1,2) <> 'RP')
  or ssrattr_term_code is null

left join sfrrgfe
on
(
 (sfrrgfe_type = 'ATTR'
                AND sfrrgfe_attr_code_crse = ssrattr.ssrattr_attr_code
                AND (sfrrgfe_resd_code is null
                    OR sfrrgfe_resd_code = sgbstdn_resd_code )
                )

or (SFRRGFE_TYPE = 'STUDENT' and sfrrgfe.SFRRGFE_DETL_CODE <> 'FGLE'
and (sfrrgfe.SFRRGFE_PTRM_CODE = sobptrm.SOBPTRM_PTRM_CODE
or sfrrgfe.SFRRGFE_DETL_CODE = 'FM' || substr(stvterm.STVTERM_FA_PROC_YR,3,2))
and ssrattr.SSRATTR_ATTR_CODE is null)
or (SFRRGFE_TYPE = 'LEVEL'
and sfrrgfe.SFRRGFE_LEVL_CODE_CRSE = sfrstcr.SFRSTCR_LEVL_CODE
and (SFRRGFE_SCHD_CODE = ssbsect.SSBSECT_SCHD_CODE or SFRRGFE_SCHD_CODE is null)
and (sfrrgfe.SFRRGFE_RESD_CODE = sgbstdn.SGBSTDN_RESD_CODE or sfrrgfe.SFRRGFE_RESD_CODE is null)
and (sfrrgfe.SFRRGFE_RATE_CODE = sgbstdn.SGBSTDN_RATE_CODE or sfrrgfe.SFRRGFE_RATE_CODE is null)
and ssrattr.SSRATTR_ATTR_CODE is null
)
)
and sfrrgfe_term_code = sobptrm_term_code

join tbbdetc
on tbbdetc_detail_code = SFRRGFE_DETL_CODE
left join gobintl
on gobintl_pidm = spriden_pidm

where
  spriden_change_ind is null
  and upper(spriden_last_name) not like '%DO%NOT%USE%'
  and sgbstdn.SGBSTDN_TERM_CODE_EFF = (select max(s2.sgbstdn_term_code_eff) from sgbstdn s2 where s2.sgbstdn_pidm = sgbstdn.sgbstdn_pidm)
  and spriden_id = :Edit1
  and sfrstcr_term_code = :lbTerm.STVTERM_CODE
union
select spriden_pidm, null, tbraccd_term_code, null, null,spriden_id, null, null, null, null, null, null, null, tbraccd_amount, tbraccd_amount, tbraccd_detail_code, tbbdetc_desc, null
from spriden join tbraccd on tbraccd_pidm = spriden_pidm join tbbdetc on tbbdetc_detail_code = tbraccd_detail_code
where spriden_last_name not like '%DO%NOT%USE%' and spriden_change_ind is null
and tbraccd_detail_code = 'FGLE' and spriden_id = :Edit1
and tbraccd_term_code = :lbTerm.STVTERM_CODE
--$addfilter

--$beginorder


--$endorder
