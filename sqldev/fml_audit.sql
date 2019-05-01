select * from ptrearn;

select
	spriden_pidm pidm
	,spriden_id ee_id
	,spriden_last_name || ', ' || spriden_first_name ee_name
	,(select pebempl_empl_status from pebempl where pebempl_pidm = spriden_pidm ) emp_stat
,trunc(PERFMLA_BEGIN_DATE) fmla_begin
,trunc(PERFMLA_END_DATE) fmla_end
,(select ptvfmst_desc from ptvfmst where ptvfmst_code = perfmla_status_code) fmla_status
,(select ptvfrea_desc from ptvfrea where ptvfrea_code = PERFMLA_FREA_CODE) fmla_reason
,perfmla_med_cert_ind med_cert
,PERBFML_MAX_UNITS max_hours
,nvl(sum(PEREFML_CLAIM_UNITS),0) hours_taken
,PERBFML_MAX_UNITS - nvl(sum(PEREFML_CLAIM_UNITS),0) hours_remain
,nvl(perfmla_duration_note,' ') duration_note

from perfmla
inner join PERBFML
  on PERBFML_ID = PERFMLA_PERBFML_ID
inner join SPRIDEN
  on spriden_pidm = PERBFML_PIDM
left outer join PEREFML -- Earning table
  on perefml_perfmla_id = perfmla_id
where spriden_change_ind is null
--and (	(:parm_CB_Termed = 1 and exists(select 'd' from pebempl where pebempl_pidm = PERBFML_PIDM and pebempl_empl_status <> 'T'))
--	 or (:parm_CB_Termed <> 1)
--	 )
/*
and ((:fromDate = trunc(sysdate) and :thruDate = trunc(sysdate))
 or (:leaveDates.leave = 'beg' and
     trunc(PERFMLA_BEGIN_DATE) between :fromDate and :thruDate)
 or (:leaveDates.leave = 'end' and
     trunc(PERFMLA_END_DATE) between :fromDate and :thruDate)
	)
*/
  and (PERFMLA_BEGIN_DATE >= :fromDate 
		and PERFMLA_END_DATE <= :thruDate)
	
group by spriden_pidm ,spriden_id
,spriden_last_name || ', ' || spriden_first_name
,PERFMLA_BEGIN_DATE
,PERFMLA_END_DATE
,perfmla_status_code
,PERFMLA_FREA_CODE
,perfmla_med_cert_ind
,PERBFML_MAX_UNITS
,perfmla_duration_note
order by ee_name, fmla_begin;

select *
from perfmla --beg/end dates, medical cert, duration note
where perfmla_perbfml_id = 133
;
select * from perbfml
where perbfml_pidm = 119365;
select * from perefml;
desc perefml;
select * from all_tab_comments where table_name = 'PEREFML';
select * from all_col_comments where table_name = 'PEREFML';
select * from ptrcaln ;

select * from spriden where spriden_last_name = 'Bowling' and spriden_id = 'N00119320';

select
     perbfml_pidm pidm
    ,spriden_id id
    ,spriden_last_name || ', ' || spriden_first_name name
    ,perfmla_id
    ,perfmla_begin_date
    ,perfmla_end_date
    ,perfmla_status_code || ' - ' || ptvfmst_desc fmla_status
    ,perfmla_frea_code || ' - ' || ptvfrea_desc fmla_reason
    ,perfmla_med_cert_ind med_cert
    ,perfmla_duration_note duration_note
    ,perbfml_max_units
    ,sum(perefml_claim_units)  total_claim
    ,perbfml_max_units - sum(perefml_claim_units) remaining_units
--    ,perefml.*

from perbfml -- base table - matches fmla id (perbfml_id) to a pidm
            join perfmla on perbfml_id = perfmla_perbfml_id -- usuage (claim) table - matches fmla id (perfmla_perbfml_id)to a fmla claim (perflma_id)
            join ptvfmst on ptvfmst_code = perfmla_status_code -- for status desc
            join ptvfrea on ptvfrea_code = perfmla_frea_code -- for reason desc
            join perefml on perefml_perfmla_id = perfmla_id  -- individual charges (earnings info) against fmla claims (perfmla_id)
            join spriden on spriden_pidm = perbfml_pidm and spriden_change_ind is null

where (spriden_id = trim(:parm_EB_EmpID)  or trim(:parm_EB_EmpID) is null)
  and perfmla_begin_date >= to_date(:parm_DT_FromDate,'DD/MM/YYYY')
  and perfmla_end_date <= to_date(:parm_DT_ToDate,'DD/MM/YYYY')
        
group by perbfml_pidm
	,spriden_id
	,spriden_last_name || ', ' || spriden_first_name
        ,perbfml_max_units
        ,perfmla_id
        ,perfmla_begin_date
        ,perfmla_end_date
        ,perfmla_status_code || ' - ' || ptvfmst_desc
        ,perfmla_frea_code || ' - ' || ptvfrea_desc
        ,perfmla_med_cert_ind
        ,perfmla_duration_note
order by 3,4
;
            
 select case when trim(:parm_EB_EmpID) is null then 'NULL'
       else trim(:parm_EB_EmpID) end as EmpID from Dual;           

select * from perefml where perefml_perfmla_id = 347;     
select * from ptrearn order by 1;
select
        perefml_perfmla_id
        ,perefml_id
        ,perefml_earn_code earn_code
        ,perefml_claim_units claim_units
        ,perefml_pay_history_ind pay_hist_ind
        ,perefml_earn_end_date
        --payroll
        ,ptrcaln_pict_code || '-' || ptrcaln_payno payroll
        ,perefml_activity_date
        ,perefml_user_id
from perefml join ptrcaln on perefml_earn_end_date = ptrcaln_end_date and ptrcaln_pict_code <> 'BW'
;

desc ptrcaln;
select * from ptrcaln where ptrcaln_pict_code <> 'RT';
select ptrcaln_year || ptrcaln_pict_code || to_char(ptrcaln_payno) ppd,ptrcaln_start_date,ptrcaln_end_date, lag(ptrcaln_year || ptrcaln_pict_code || to_char(ptrcaln_payno),1) over (PARTITION BY ptrcaln_pict_code ORDER BY ptrcaln_start_date) as begin_ppd
from ptrcaln
where ptrcaln_start_date >= to_date('7/11/2016','mm/dd/yyyy') 
  and ptrcaln_end_date <= to_date('4/25/2019','mm/dd/yyyy')
  and ptrcaln_pict_code = 'MN'
order by ptrcaln_start_date;

select *
from perjobs join ptrcaln on perjobs_year = ptrcaln_year and perjobs_pict_code = ptrcaln_pict_code and perjobs_payno = ptrcaln_payno
where perjobs_pidm = 119322
;

select * from perhour where perhour_jobs_seqno = 123315;
select * from perhour where perhour_jobs_seqno = 184529;

with jobs_caln_cte as (
     select *
     from perjobs join ptrcaln on perjobs_year = ptrcaln_year and perjobs_pict_code = ptrcaln_pict_code and perjobs_payno = ptrcaln_payno
     where perjobs_pidm = :MultiColumn1PIDM
     )
--select * from jobs_caln_cte;
select * from perhour
where perhour_jobs_seqno in (
      select a.perjobs_seqno from jobs_caln_cte a
      where a.ptrcaln_start_date >= nvl( 
                                        (select max(b.ptrcaln_start_date)
                                        from jobs_caln_cte b
                                        where b.ptrcaln_start_date <= to_date('01/01/2016','dd/mm/yyyy') )
                                        ,to_date('01/01/1900','mm/dd/yyyy'))
                                        )
;        
select * from perhour where perhour_jobs_seqno=123315;        


with jobs_caln_cte as (
     select *
     from perjobs join ptrcaln on perjobs_year = ptrcaln_year and perjobs_pict_code = ptrcaln_pict_code and perjobs_payno = ptrcaln_payno
     where perjobs_pidm = :MultiColumn1PIDM
     )
--select * from jobs_caln_cte;
select *
from jobs_caln_cte join perhour on jobs_caln_cte.perjobs_seqno = perhour_jobs_seqno

where ptrcaln_start_date >= nvl( 
                                    (select max(b.ptrcaln_start_date)
                                     from jobs_caln_cte b
                                     where b.ptrcaln_start_date <= to_date('01/01/2017','dd/mm/yyyy') )
                                ,to_date('01/01/1900','mm/dd/yyyy') )
;

select * from perleav;

select * from perleav;

select * from all_tab_comments where comments like '%Leave%';
select * from all_tab_comments where table_name = 'PERHOUR';

select * 
from perlvtk;

select perlhis_pidm
       ,perlhis_leav_code
       ,perlhis_activity_date
       ,perlhis_begin_balance
       ,perlhis_accrued
       ,perlhis_taken
       ,perlhis_change_reason
from perlhis join spriden on perlhis_pidm = spriden_pidm and spriden_change_ind is null
where  perlhis_pidm = :MultiColumn1.PIDM
  and trunc(perlhis_activity_date) >= :MultiColumn1.PERFMLA_BEGIN_DATE
  and trunc(perlhis_activity_date) <= :MultiColumn1.PERFMLA_END_DATE
order by perlhis_activity_date, case perlhis_leav_code when 'PERS' then 1 when 'COMP' then 2 when 'VACA' then 3 end;

select * from perlhis where perlhis_pidm = 120081;
select * from perleav where perleav_pidm = 31091;
select *
from perhour join perjobs on perhour_jobs_seqno = perjobs_seqno
        join ptrcaln on perjobs_year = ptrcaln_year and perjobs_pict_code = ptrcaln_pict_code and perjobs_payno = ptrcaln_payno
where perjobs_pidm = 31091;
select * from ptrcaln;
select max(a.ptrcaln_start_date) from ptrcaln a where a.ptrcaln_pict_code = 'MN' and ptrcaln_start_date <= :MultiColumn1;

     select ptrcaln_year, ptrcaln_pict_code, ptrcaln_payno,ptrcaln_start_date
            ,ptrcaln_end_date
            ,lag(ptrcaln_start_date,1) over (partition by ptrcaln_pict_code order by ptrcaln_year, ptrcaln_pict_code, ptrcaln_payno) as prev_start_date
     from ptrcaln;


select perjobs_pidm
        ,perhour_jobs_seqno
        ,ptrcaln_start_date
        ,ptrcaln_end_date
        ,perjobs_year || '-' || perjobs_pict_code || '-' || perjobs_payno payroll
        ,perhour_earn_code
        ,sum(perhour_hrs) hours_total
from perhour join perjobs on perhour_jobs_seqno = perjobs_seqno
        join ptrcaln on perjobs_year = ptrcaln_year and perjobs_pict_code = ptrcaln_pict_code and perjobs_payno = ptrcaln_payno
where perjobs_pidm = 31091
group by perjobs_pidm
        ,perhour_jobs_seqno
        ,ptrcaln_start_date
        ,ptrcaln_end_date
        ,perjobs_year || '-' || perjobs_pict_code || '-' || perjobs_payno 
        ,perhour_earn_code
order by ptrcaln_end_date
;

select * from phrearn where phrearn_pidm = 31091;
select * from ptrearn order by 1;

with ptrcaln_lag_cte as (
     select ptrcaln_year
            ,ptrcaln_pict_code
            ,ptrcaln_payno
            ,ptrcaln_start_date
            ,ptrcaln_end_date
            ,nvl(lag(ptrcaln_start_date,1) over (partition by ptrcaln_pict_code order by ptrcaln_year, ptrcaln_pict_code, ptrcaln_payno),ptrcaln_start_date) as prev_start_date
     from ptrcaln
     )
--select * from ptrcaln_lag_cte;     
select perjobs_pidm
        ,perhour_jobs_seqno
        ,ptrcaln_start_date
        ,ptrcaln_end_date
        ,perjobs_year || '-' || perjobs_pict_code || '-' || perjobs_payno payroll
        ,perhour_earn_code
        ,sum(perhour_hrs) hours_total
from perhour join perjobs on perhour_jobs_seqno = perjobs_seqno
        join ptrcaln on perjobs_year = ptrcaln_year and perjobs_pict_code = ptrcaln_pict_code and perjobs_payno = ptrcaln_payno
where perjobs_pidm = :MultiColumn1PIDM
  and ptrcaln_start_date = (select min(ptrcaln_lag_cte.prev_start_date) from ptrcaln_lag_cte where :PERFMFLA_BEGIN_DATE > ptrcaln_lag_cte.ptrcaln_start_date)
  --and ptrcaln_start_date = (select max(a.ptrcaln_start_date) from ptrcaln a where a.ptrcaln_pict_code = perjobs_pict_code and a.ptrcaln_start_date <= :MultiColumn1.PERFMLA_BEGIN_DATE)
/*  and ptrcaln_start_date = (select prev_start_date
                            from (select prev_start_date,rownum() as myrow
                                  from ptrcaln_lag_cte a
                                  where a.ptrcaln_pict_code = perjobs_pict_code
                                    and a.ptrcaln_start_date > :MultiColumn1.PERFMLA_BEGIN_DATE)
                             where myrow = 1)
                             */
group by perjobs_pidm
        ,perhour_jobs_seqno
        ,ptrcaln_start_date
        ,ptrcaln_end_date
        ,perjobs_year || '-' || perjobs_pict_code || '-' || perjobs_payno
        ,perhour_earn_code
order by ptrcaln_end_date;

select * from perlhis where perlhis_pidm = 12081;
select  perjobs_pidm
        ,perlvtk_jobs_seqno
        ,ptrcaln_start_date
        ,ptrcaln_end_date
        ,ptrcaln_year || '-' || ptrcaln_pict_code || '-' || ptrcaln_payno payroll
        ,perlvtk_leav_code
        ,perlvtk_hrs
from perlvtk join perjobs on perlvtk_jobs_seqno = perjobs_seqno
             join ptrcaln on perjobs_year = ptrcaln_year
                          and perjobs_pict_code = ptrcaln_pict_code
                          and perjobs_payno = ptrcaln_payno;
