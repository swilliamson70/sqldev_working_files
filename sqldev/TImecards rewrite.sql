select 
    ee_spriden.spriden_id               ee_id
    ,ee_spriden.spriden_last_name       ee_last_name
    ,ee_spriden.spriden_first_name      ee_first_name
    ,ee_spriden.spriden_mi              ee_mi
    ,ee_goremal.goremal_email_address   ee_email
    ,perjobs.perjobs_year
    ,perjobs.perjobs_pict_code
    ,perjobs.perjobs_payno
    ,perjobs.perjobs_seqno
    ,perjobs.perjobs_action_ind
    ,perjobs.perjobs_status_ind
    ,perrout.perrout_appr_posn
    ,appr_spriden.spriden_id            appr_id
    ,appr_spriden.spriden_last_name     appr_last_name
    ,appr_spriden.spriden_first_name    appr_first_name
    ,appr_spriden.spriden_mi            appr_mi
    ,appr_goremal.goremal_email_address appr_email

from perjobs join spriden ee_spriden on perjobs_pidm = ee_spriden.spriden_pidm and ee_spriden.spriden_change_ind is null
             join goremal ee_goremal on ee_spriden.spriden_pidm = ee_goremal.goremal_pidm and ee_goremal.goremal_emal_code = 'NSU'
             join perrout on perrout_jobs_seqno = perjobs_seqno and perrout_appr_seqno = 1
    ,spriden appr_spriden join goremal appr_goremal on appr_spriden.spriden_change_ind is null and appr_spriden.spriden_pidm = appr_goremal.goremal_pidm and appr_goremal.goremal_emal_code = 'NSU'

where perjobs_year = extract(year from sysdate)
  and perjobs_pict_code = 'BW'
  and perjobs_payno = (select payno
                       from (select ptrcaln_payno payno, row_number() over (partition by ptrcaln_year, ptrcaln_pict_code order by ptrcaln_payno desc) rn
                             from ptrcaln
                             where ptrcaln_year = extract(year from sysdate)
                               and ptrcaln_pict_code = 'BW'
                               and ptrcaln_end_date <= trunc(sysdate)
                             )
                       where rn = 1)
  and appr_spriden.spriden_pidm = perrout_appr_pidm
;
 
select * from perjobs
where perjobs_pidm = 31091; 
select  from ptrcaln;
select * from perrout where perrout_jobs_seqno = 187544;
select * from all_tab_comments where table_name = 'PERROUT';
                       select payno
                       from (select ptrcaln_payno payno, row_number() over (partition by ptrcaln_year, ptrcaln_pict_code order by ptrcaln_payno desc) rn
                             from ptrcaln
                             where ptrcaln_year = extract(year from sysdate)
                               and ptrcaln_pict_code = 'BW'
                               and ptrcaln_end_date <= trunc(sysdate)
                            )
                          
                       where rn = 1;
                       
select * from nbrjobs where nbrjobs_posn = 'X99684';

select * from employee_position
where position_contract_type = 'P' and position_status = 'A' and effective_end_date >= sysdate;

select * from organization_hierarchy
where ;