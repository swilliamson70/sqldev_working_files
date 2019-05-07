SELECT
    perjobs_pidm                        
    ,ee_spriden.spriden_id              emp_id
    ,ee_spriden.spriden_last_name       emp_last_name
    ,ee_spriden.spriden_first_name      emp_first_name
    ,ee_spriden.spriden_mi              emp_mi
    ,ee_goremal.goremal_email_address   emp_email_addr
    ,perjobs_year                       year
    ,perjobs_pict_code                  payroll_id
    ,perjobs_payno                      payroll_number
    ,perjobs_posn                       emp_posn
    ,perjobs_suff                       emp_suff
    ,nbrbjob_contract_type              emp_contract_type
    ,perjobs_job_title                  emp_job_title
    ,perjobs_ecls_code                  emp_ecls_code
    ,perjobs_orgn_code_ts               emp_org_code
    ,perjobs_status_ind                 emp_status_ind
    ,perjobs_acat_code                  emp_leave_type
    ,perjobs_lcat_code                  emp_leave_cat
    ,perjobs_seqno                      leave_seqno
     
    ,ovrd_info.spriden_id               rjqe_appr
    ,appr_info.spriden_id               posn_approver
    
    ,nvl2(ovrd_info.spriden_id,ovrd_info.spriden_id,appr_info.spriden_id) appr_id
    ,nvl2(ovrd_info.spriden_id,ovrd_info.spriden_last_name,appr_info.spriden_last_name) appr_last_name
    ,nvl2(ovrd_info.spriden_id,ovrd_info.spriden_first_name,appr_info.spriden_first_name) appr_first_name
    ,nvl2(ovrd_info.spriden_id,ovrd_info.spriden_mi,appr_info.spriden_mi) appr_mi
    ,nvl2(ovrd_info.spriden_id,ovrd_info.goremal_email_address,appr_info.goremal_email_address) appr_email

    ,perhour_hrs                        leave_hrs
    ,perhour_time_entry_date            leave_date
    ,case
        when perhour_earn_code in ('205','251','255','265') then 'Pers'
        when perhour_earn_code in ('200','250','260','261','266') then'Vac'
     end                                leave_code     
     
    ,vp_org.financial_manager_id        vp_id
    ,vp_org.financial_manager_name      vp_name
    ,case
        when vp_org.financial_manager_uid = 131297 -- Steven Turner N00131182
            then 'loguel@nsuok.edu'
        when appr_info.spriden_pidm = vp_org.financial_manager_uid -- if you don't want vp direct reports going to that vp
            then 'loguel@nsuok.edu'
        else
            vp_goremal.goremal_email_address
    end                                 vp_email

from 
    perjobs join ptrcaln on perjobs_year = ptrcaln_year and perjobs_year = extract(year from add_months(sysdate,-1))
                         and perjobs_pict_code = ptrcaln_pict_code and perjobs_pict_code = 'MN'
                         and perjobs_payno = ptrcaln_payno
                         and perjobs_acat_code = 'LEAVE'
                         and perjobs_status_ind in ('P','I','R')
                         and add_months(sysdate,-1) between ptrcaln_start_date and ptrcaln_end_date
            left join perhour on perjobs_seqno = perhour_jobs_seqno
            join spriden ee_spriden on perjobs_pidm = ee_spriden.spriden_pidm and ee_spriden.spriden_change_ind is null
            join goremal ee_goremal on perjobs_pidm = ee_goremal.goremal_pidm and ee_goremal.goremal_emal_code = 'NSU'
            join nbbposn on perjobs_posn = nbbposn_posn           
            left join (select *
                       from spriden join goremal on spriden_pidm = goremal_pidm
                                                 and spriden_change_ind is null
                                                 and goremal_emal_code = 'NSU') appr_info on appr_info.spriden_pidm = (select nbrbjob_pidm
                                                                                                                       from (select nbrbjob_pidm
                                                                                                                                    ,nbrbjob_end_date
                                                                                                                                    ,row_number() over (partition by nbrbjob_posn order by nbrbjob_begin_date desc) rn
                                                                                                                             from nbrbjob
                                                                                                                             where nbrbjob_posn = nbbposn_posn_reports
                                                                                                                               and (nbrbjob_end_date <= ptrcaln_end_date or nbrbjob_end_date is null)) 
                                                                                                                       where rn= 1)
            join nbrbjob on perjobs_pidm = nbrbjob_pidm
                         and nbrbjob_posn = perjobs_posn
                         and nbrbjob_suff = perjobs_suff
                         --and nbrbjob_contract_type = 'P'
            left join (select *
                       from (select nbrrjqe_pidm
                                    ,nbrrjqe_posn
                                    ,nbrrjqe_suff
                                    ,nbrrjqe_appr_pidm
                                    ,nbrrjqe_appr_seq_no
                                    ,row_number() over (partition by nbrrjqe_pidm,nbrrjqe_posn order by nbrrjqe_appr_seq_no) rn
                             from nbrrjqe
                             where nbrrjqe_acat_code = 'LEAVE') 
                            join spriden on spriden_pidm = nbrrjqe_appr_pidm and spriden_change_ind is null
                            join goremal on goremal_pidm = spriden_pidm and goremal_emal_code = 'NSU'
                        where rn = 1) ovrd_info on nbrrjqe_pidm = perjobs_pidm
                                                and nbrrjqe_posn = perjobs_posn
                                                and nbrrjqe_suff = perjobs_suff
            ,organization_hierarchy vp_org join goremal vp_goremal on vp_org.financial_manager_uid = vp_goremal.goremal_pidm and vp_goremal.goremal_emal_code = 'NSU'
where
    vp_org.organization_code =    (select organization_level_2 from organization_hierarchy
                                    where organization_code =  perjobs_orgn_code_ts
                                      and chart_of_accounts = perjobs_coas_code_ts) 
    and vp_org.chart_of_accounts = perjobs_coas_code_ts
order by PERJOBS.PERJOBS_YEAR,
          ee_SPRIDEN.SPRIDEN_LAST_NAME,
          ee_SPRIDEN.SPRIDEN_FIRST_NAME,
          ee_SPRIDEN.SPRIDEN_MI,
          PERJOBS.PERJOBS_PICT_CODE,
          PERJOBS.PERJOBS_PAYNO;