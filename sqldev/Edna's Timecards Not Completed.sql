select
spriden.spriden_id
,spriden.spriden_last_name
,spriden.spriden_first_name
,spriden.spriden_mi
,(select goremal.goremal_email_address from goremal goremal where goremal.goremal_pidm = spriden.spriden_pidm
                    and goremal.goremal_emal_code = 'NSU') "EE_EMAIL"
,perjobs.perjobs_year
,perjobs.perjobs_pict_code
,perjobs.perjobs_payno
,perjobs.perjobs_seqno
,perjobs.perjobs_action_ind
,perjobs.perjobs_status_ind
,perrout.perrout_appr_posn
,(select distinct spr.spriden_id
            from spriden spr
            join nbrjobs jobs on jobs.nbrjobs_pidm = spr.spriden_pidm
                        and jobs.nbrjobs_effective_date = (select max(x1.nbrjobs_effective_date) from nbrjobs x1
                                                  where x1.nbrjobs_pidm = jobs.nbrjobs_pidm
                                                    and x1.nbrjobs_posn = jobs.nbrjobs_posn
                                                    and x1.nbrjobs_suff = jobs.nbrjobs_suff)
                        and jobs.nbrjobs_posn = perrout.perrout_appr_posn
                        and jobs.nbrjobs_status = 'A'
            where spr.spriden_change_ind is null) as "APPR_ID"
,(select distinct spr.spriden_last_name
            from spriden spr
            join nbrjobs jobs on jobs.nbrjobs_pidm = spr.spriden_pidm
                        and jobs.nbrjobs_effective_date = (select max(x1.nbrjobs_effective_date) from nbrjobs x1
                                                  where x1.nbrjobs_pidm = jobs.nbrjobs_pidm
                                                    and x1.nbrjobs_posn = jobs.nbrjobs_posn
                                                    and x1.nbrjobs_suff = jobs.nbrjobs_suff)
                        and jobs.nbrjobs_posn = perrout.perrout_appr_posn
                        and jobs.nbrjobs_status = 'A'
            where spr.spriden_change_ind is null) as "APPR_LAST_NAME"
,(select distinct spr.spriden_first_name
            from spriden spr
            join nbrjobs jobs on jobs.nbrjobs_pidm = spr.spriden_pidm
                        and jobs.nbrjobs_effective_date = (select max(x1.nbrjobs_effective_date) from nbrjobs x1
                                                  where x1.nbrjobs_pidm = jobs.nbrjobs_pidm
                                                    and x1.nbrjobs_posn = jobs.nbrjobs_posn
                                                    and x1.nbrjobs_suff = jobs.nbrjobs_suff)
                        and jobs.nbrjobs_posn = perrout.perrout_appr_posn
                        and jobs.nbrjobs_status = 'A'
            where spr.spriden_change_ind is null) as "APPR_FIRST_NAME"
,(select distinct spr.spriden_mi
            from spriden spr
            join nbrjobs jobs on jobs.nbrjobs_pidm = spr.spriden_pidm
                        and jobs.nbrjobs_effective_date = (select max(x1.nbrjobs_effective_date) from nbrjobs x1
                                                  where x1.nbrjobs_pidm = jobs.nbrjobs_pidm
                                                    and x1.nbrjobs_posn = jobs.nbrjobs_posn
                                                    and x1.nbrjobs_suff = jobs.nbrjobs_suff)
                        and jobs.nbrjobs_posn = perrout.perrout_appr_posn
                        and jobs.nbrjobs_status = 'A'
            where spr.spriden_change_ind is null) as "APPR_MI"
,(select goremal.goremal_email_address from goremal goremal where goremal.goremal_pidm = perrout.perrout_appr_pidm
                    and goremal.goremal_emal_code = 'NSU') "APPR_EMAIL"
,(select /* employee_position.person_uid
        ,employee_position.id,employee_position.name
        ,employee_position.home_organization
        ,home_org_code
        ,home_org_desc
        ,org_lvl2
        ,org_lvl2_desc
        ,org_lvl2_mgr_id
        ,org_lvl2_mgr_name
        ,l2_coa
        ,l2_org_code
        ,l2_org_desc
        ,l2_org
        ,l2_desc*/
        l2_mgr_id
        --,l2_mgr_name

        from employee_position join (select chart_of_accounts home_coa ,organization_code home_org_code ,organization_desc home_org_desc ,organization_level_2 org_lvl2 ,organization_desc_2 org_lvl2_desc ,financial_manager_id org_lvl2_mgr_id ,financial_manager_name org_lvl2_mgr_name from organization_hierarchy where organization_status_2 = 'A')
                on employee_position.timesheet_organization = home_org_code and employee_position.person_uid = spriden.spriden_pidm
              join (select chart_of_accounts l2_coa ,organization_code l2_org_code ,organization_desc l2_org_desc ,organization_level_2 l2_org ,organization_desc_2 l2_desc ,financial_manager_id l2_mgr_id ,financial_manager_name l2_mgr_name from organization_hierarchy where organization_status_2 = 'A')
                on org_lvl2 = l2_org_code and home_coa = l2_coa
                where employee_position.position_contract_type = 'P'
                and employee_position.position_status = 'A'
                and  employee_position.effective_end_date >= sysdate) as "VP_ID",
        (select /*employee_position.person_uid
         ,employee_position.id,employee_position.name
        ,employee_position.home_organization
        ,home_org_code
        ,home_org_desc
        ,org_lvl2
        ,org_lvl2_desc
        ,org_lvl2_mgr_id
        ,org_lvl2_mgr_name
        ,l2_coa
        ,l2_org_code
        ,l2_org_desc
        ,l2_org
        ,l2_desc
        ,l2_mgr_id*/
        l2_mgr_name
             from employee_position join (select chart_of_accounts home_coa ,organization_code home_org_code ,organization_desc home_org_desc ,organization_level_2 org_lvl2 ,organization_desc_2 org_lvl2_desc ,financial_manager_id org_lvl2_mgr_id ,financial_manager_name org_lvl2_mgr_name from organization_hierarchy where organization_status_2 = 'A')
                on employee_position.timesheet_organization = home_org_code and employee_position.person_uid = spriden.spriden_pidm
              join (select chart_of_accounts l2_coa ,organization_code l2_org_code ,organization_desc l2_org_desc ,organization_level_2 l2_org ,organization_desc_2 l2_desc ,financial_manager_id l2_mgr_id ,financial_manager_name l2_mgr_name from organization_hierarchy where organization_status_2 = 'A')
                on org_lvl2 = l2_org_code and home_coa = l2_coa
                where employee_position.position_contract_type = 'P'
                and employee_position.position_status = 'A'
                and  employee_position.effective_end_date >= sysdate) as "VP_Name",
    (select /* employee_position.person_uid
        ,employee_position.id,employee_position.name
        ,employee_position.home_organization
        ,home_org_code
        ,home_org_desc
        ,org_lvl2
        ,org_lvl2_desc
        ,org_lvl2_mgr_id
        ,org_lvl2_mgr_name
        ,l2_coa
        ,l2_org_code
        ,l2_org_desc
        ,l2_org
        ,l2_desc
        ,l2_mgr_id
        ,l2_mgr_name*/
      case (select goremal_email_address from goremal where goremal_pidm = (select x1.spriden_pidm from spriden x1
                                                              where x1.spriden_id = l2_mgr_id
                                                                and x1.spriden_change_ind is null)
                                                   and goremal_emal_code = 'NSU')
         when 'turner@nsuok.edu'
         then 'loguel@nsuok.edu'
         else
         (select goremal_email_address from goremal where goremal_pidm = (select x1.spriden_pidm from spriden x1
                                                              where x1.spriden_id = l2_mgr_id
                                                                and x1.spriden_change_ind is null)
                                                   and goremal_emal_code = 'NSU')
         end
        from employee_position join (select chart_of_accounts home_coa ,organization_code home_org_code ,organization_desc home_org_desc ,organization_level_2 org_lvl2 ,organization_desc_2 org_lvl2_desc ,financial_manager_id org_lvl2_mgr_id ,financial_manager_name org_lvl2_mgr_name from organization_hierarchy where organization_status_2 = 'A')
                on employee_position.timesheet_organization = home_org_code and employee_position.person_uid = spriden.spriden_pidm
              join (select chart_of_accounts l2_coa ,organization_code l2_org_code ,organization_desc l2_org_desc ,organization_level_2 l2_org ,organization_desc_2 l2_desc ,financial_manager_id l2_mgr_id ,financial_manager_name l2_mgr_name from organization_hierarchy where organization_status_2 = 'A')
                on org_lvl2 = l2_org_code and home_coa = l2_coa
              where employee_position.position_contract_type = 'P'
                and employee_position.position_status = 'A'
                and  employee_position.effective_end_date >= sysdate) as "VP_Email"
 --'shadee@nsuok.edu' email from dual) as "VP_Email"
from perjobs perjobs
join spriden spriden on spriden.spriden_pidm = perjobs.perjobs_pidm and spriden.spriden_change_ind is null
join perrout perrout on perrout.perrout_jobs_seqno = perjobs.perjobs_seqno and perrout.perrout_appr_seqno = 1

where perjobs.perjobs_year = to_char(sysdate,'YYYY')
      and perjobs.perjobs_payno = (select ptrcaln.ptrcaln_payno from ptrcaln ptrcaln where ptrcaln.ptrcaln_year = perjobs.perjobs_year
                                        and ptrcaln.ptrcaln_pict_code = 'BW'
              and  ptrcaln_end_date = (select max(x1.ptrcaln_end_date) from ptrcaln x1
                                      where x1.ptrcaln_year = ptrcaln.ptrcaln_year
                                        and x1.ptrcaln_pict_code = ptrcaln.ptrcaln_pict_code
                                         and ptrcaln_end_date <= sysdate))
      and perjobs.perjobs_action_ind = 'T'
      and perjobs.perjobs_status_ind = 'C' --not in ('C','A')
order by "VP_Name",spriden.spriden_last_name, spriden.spriden_first_name, spriden.spriden_mi
;