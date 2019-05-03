select DISTINCT
       PERJOBS.PERJOBS_PIDM,
       SPRIDEN.SPRIDEN_ID as "Emp_ID",
       SPRIDEN.SPRIDEN_LAST_NAME as "Emp_Last_Name",
       SPRIDEN.SPRIDEN_FIRST_NAME as "Emp_First_Name",
       SPRIDEN.SPRIDEN_MI as "Emp_MI",
        (select goremal_email_address from GENERAL.goremal where goremal_pidm = PERJOBS.PERJOBS_PIDM
                   and goremal_emal_code = 'NSU'
                   and goremal_status_ind = 'A'
                    and goremal_activity_date = (select max(x1.goremal_activity_date) from goremal x1
                                      where x1.goremal_pidm = goremal.goremal_pidm
                                        and x1.goremal_emal_code = goremal.goremal_emal_code
                                        and x1.goremal_emal_code = 'NSU')) as "Emp_Email_Addr",

       PERJOBS.PERJOBS_YEAR as "Year",
       PERJOBS.PERJOBS_PICT_CODE as "Payroll_ID",
       PERJOBS.PERJOBS_PAYNO as "Payroll_Number",
       PERJOBS.PERJOBS_POSN as "Emp_Posn",
       PERJOBS.PERJOBS_SUFF as "Emp_Suff",
       PERJOBS.PERJOBS_JOB_TITLE as "Emp_Job_Title",
       PERJOBS.PERJOBS_ECLS_CODE as "Emp_ECLS_Code",
       PERJOBS.PERJOBS_ORGN_CODE_TS as "Emp_Org_Code",
       PERJOBS.PERJOBS_STATUS_IND as "Emp_Status_Ind",
       PERJOBS.PERJOBS_ACAT_CODE as "Emp_Leave_Type",
       PERJOBS.PERJOBS_LCAT_CODE as "Emp_Leave_Cat",
       PERJOBS.PERJOBS_SEQNO as "Leave_Seqno",
       CASE
          WHEN NBBPOSN.NBBPOSN_POSN_REPORTS IS NOT NULL
           THEN 'Y'
           ELSE 'N'
       END as "Approver_on_POSN",
       CASE
          WHEN NBRRJQE.NBRRJQE_APPR_PIDM IS NOT NULL
                    AND NBRRJQE.NBRRJQE_POSN = PERJOBS.PERJOBS_POSN
                    AND NBRRJQE.NBRRJQE_ACAT_CODE = 'LEAVE'
                    AND NBRRJQE.NBRRJQE_ACTIVITY_DATE = (SELECT MAX(NBRRJ2.NBRRJQE_ACTIVITY_DATE) FROM POSNCTL.NBRRJQE NBRRJ2
                                              WHERE NBRRJ2.NBRRJQE_PIDM = NBRRJQE.NBRRJQE_PIDM
                                                AND NBRRJ2.NBRRJQE_POSN = NBRRJQE.NBRRJQE_POSN
                                                AND NBRRJ2.NBRRJQE_ACAT_CODE = NBRRJQE.NBRRJQE_ACAT_CODE)
              THEN NBRRJQE.NBRRJQE_APPR_POSN
          ELSE NBBPOSN.NBBPOSN_POSN_REPORTS
       END as "Appr_Posn",
       CASE
       WHEN NBRRJQE.NBRRJQE_APPR_PIDM IS NOT NULL
                    AND NBRRJQE.NBRRJQE_POSN = PERJOBS.PERJOBS_POSN
                    AND NBRRJQE.NBRRJQE_ACAT_CODE = 'LEAVE'
                    AND NBRRJQE.NBRRJQE_ACTIVITY_DATE = (SELECT MAX(NBRRJ2.NBRRJQE_ACTIVITY_DATE) FROM POSNCTL.NBRRJQE NBRRJ2
                                              WHERE NBRRJ2.NBRRJQE_PIDM = NBRRJQE.NBRRJQE_PIDM
                                                AND NBRRJ2.NBRRJQE_POSN = NBRRJQE.NBRRJQE_POSN
                                                AND NBRRJ2.NBRRJQE_ACAT_CODE = NBRRJQE.NBRRJQE_ACAT_CODE)
              THEN NBRRJQE.NBRRJQE_APPR_PIDM
       ELSE (SELECT DISTINCT t1.NBRBJOB_PIDM FROM NBRBJOB t1
                        WHERE t1.NBRBJOB_POSN = NBBPOSN.NBBPOSN_POSN_REPORTS
                          AND (t1.NBRBJOB_END_DATE IS NULL OR t1.NBRBJOB_END_DATE >= SYSDATE)
                          )
       END as "Appr_Pidm",
       CASE
          WHEN NBRRJQE.NBRRJQE_APPR_PIDM IS NOT NULL
                    AND NBRRJQE.NBRRJQE_POSN = PERJOBS.PERJOBS_POSN
                    AND NBRRJQE.NBRRJQE_ACAT_CODE = 'LEAVE'
                    AND NBRRJQE.NBRRJQE_ACTIVITY_DATE = (SELECT MAX(NBRRJ2.NBRRJQE_ACTIVITY_DATE) FROM POSNCTL.NBRRJQE NBRRJ2
                                              WHERE NBRRJ2.NBRRJQE_PIDM = NBRRJQE.NBRRJQE_PIDM
                                                AND NBRRJ2.NBRRJQE_POSN = NBRRJQE.NBRRJQE_POSN
                                                AND NBRRJ2.NBRRJQE_ACAT_CODE = NBRRJQE.NBRRJQE_ACAT_CODE)
              THEN (select x2.SPRIDEN_ID from SPRIDEN x2
                        where x2.SPRIDEN_PIDM = NBRRJQE.NBRRJQE_APPR_PIDM
                        and x2.SPRIDEN_CHANGE_IND is null)
              ELSE (select x1.SPRIDEN_ID from SPRIDEN x1
                        where x1.SPRIDEN_PIDM = (SELECT DISTINCT t1.NBRBJOB_PIDM FROM NBRBJOB t1
                                          WHERE t1.NBRBJOB_POSN = NBBPOSN.NBBPOSN_POSN_REPORTS
                                          AND (t1.NBRBJOB_END_DATE IS NULL OR t1.NBRBJOB_END_DATE >= SYSDATE))
                   and x1.SPRIDEN_CHANGE_IND is null)
       END as "Appr_ID",
       CASE
          WHEN NBRRJQE.NBRRJQE_APPR_PIDM IS NOT NULL
                    AND NBRRJQE.NBRRJQE_POSN = PERJOBS.PERJOBS_POSN
                    AND NBRRJQE.NBRRJQE_ACAT_CODE = 'LEAVE'
                    AND NBRRJQE.NBRRJQE_ACTIVITY_DATE = (SELECT MAX(NBRRJ2.NBRRJQE_ACTIVITY_DATE) FROM POSNCTL.NBRRJQE NBRRJ2
                                              WHERE NBRRJ2.NBRRJQE_PIDM = NBRRJQE.NBRRJQE_PIDM
                                                AND NBRRJ2.NBRRJQE_POSN = NBRRJQE.NBRRJQE_POSN
                                                AND NBRRJ2.NBRRJQE_ACAT_CODE = NBRRJQE.NBRRJQE_ACAT_CODE)
              THEN (select x2.SPRIDEN_FIRST_NAME from SPRIDEN x2
                          where x2.SPRIDEN_PIDM = NBRRJQE.NBRRJQE_APPR_PIDM
                            and x2.SPRIDEN_CHANGE_IND is null)
              ELSE (select x1.SPRIDEN_FIRST_NAME from SPRIDEN x1
                          where x1.SPRIDEN_PIDM = (SELECT DISTINCT t1.NBRBJOB_PIDM FROM NBRBJOB t1
                                      WHERE t1.NBRBJOB_POSN = NBBPOSN.NBBPOSN_POSN_REPORTS
                                      AND (t1.NBRBJOB_END_DATE IS NULL OR t1.NBRBJOB_END_DATE >= SYSDATE))
                                            and x1.SPRIDEN_CHANGE_IND is null)
       END as "Appr_FName",
       CASE
           WHEN NBRRJQE.NBRRJQE_APPR_PIDM IS NOT NULL
                    AND NBRRJQE.NBRRJQE_POSN = PERJOBS.PERJOBS_POSN
                    AND NBRRJQE.NBRRJQE_ACAT_CODE = 'LEAVE'
                    AND NBRRJQE.NBRRJQE_ACTIVITY_DATE = (SELECT MAX(NBRRJ2.NBRRJQE_ACTIVITY_DATE) FROM POSNCTL.NBRRJQE NBRRJ2
                                              WHERE NBRRJ2.NBRRJQE_PIDM = NBRRJQE.NBRRJQE_PIDM
                                                AND NBRRJ2.NBRRJQE_POSN = NBRRJQE.NBRRJQE_POSN
                                                AND NBRRJ2.NBRRJQE_ACAT_CODE = NBRRJQE.NBRRJQE_ACAT_CODE)
              THEN (select x2.SPRIDEN_MI from SPRIDEN x2
                          where x2.SPRIDEN_PIDM = NBRRJQE.NBRRJQE_APPR_PIDM
                            and x2.SPRIDEN_CHANGE_IND is null)
              ELSE (select x1.SPRIDEN_MI from SPRIDEN x1
                          where x1.SPRIDEN_PIDM = (SELECT DISTINCT t1.NBRBJOB_PIDM FROM NBRBJOB t1
                                      WHERE t1.NBRBJOB_POSN = NBBPOSN.NBBPOSN_POSN_REPORTS
                                      AND (t1.NBRBJOB_END_DATE IS NULL OR t1.NBRBJOB_END_DATE >= SYSDATE))
                                            and x1.SPRIDEN_CHANGE_IND is null)
       END as "Appr_MI",
       CASE
           WHEN NBRRJQE.NBRRJQE_APPR_PIDM IS NOT NULL
                    AND NBRRJQE.NBRRJQE_POSN = PERJOBS.PERJOBS_POSN
                    AND NBRRJQE.NBRRJQE_ACAT_CODE = 'LEAVE'
                    AND NBRRJQE.NBRRJQE_ACTIVITY_DATE = (SELECT MAX(NBRRJ2.NBRRJQE_ACTIVITY_DATE) FROM POSNCTL.NBRRJQE NBRRJ2
                                              WHERE NBRRJ2.NBRRJQE_PIDM = NBRRJQE.NBRRJQE_PIDM
                                                AND NBRRJ2.NBRRJQE_POSN = NBRRJQE.NBRRJQE_POSN
                                                AND NBRRJ2.NBRRJQE_ACAT_CODE = NBRRJQE.NBRRJQE_ACAT_CODE)
              THEN (select x2.SPRIDEN_LAST_NAME from SPRIDEN x2
                          where x2.SPRIDEN_PIDM = NBRRJQE.NBRRJQE_APPR_PIDM
                            and x2.SPRIDEN_CHANGE_IND is null)
              ELSE (select x1.SPRIDEN_LAST_NAME from SPRIDEN x1
                          where x1.SPRIDEN_PIDM = (SELECT DISTINCT t1.NBRBJOB_PIDM FROM NBRBJOB t1
                                      WHERE t1.NBRBJOB_POSN = NBBPOSN.NBBPOSN_POSN_REPORTS
                                      AND (t1.NBRBJOB_END_DATE IS NULL OR t1.NBRBJOB_END_DATE >= SYSDATE))
                                            and x1.SPRIDEN_CHANGE_IND is null)
       END as "Appr_LName",

      CASE
          WHEN NBRRJQE.NBRRJQE_APPR_PIDM IS NOT NULL
                    AND NBRRJQE.NBRRJQE_POSN = PERJOBS.PERJOBS_POSN
                    AND NBRRJQE.NBRRJQE_ACAT_CODE = 'LEAVE'
                    AND NBRRJQE.NBRRJQE_ACTIVITY_DATE = (SELECT MAX(NBRRJ2.NBRRJQE_ACTIVITY_DATE) FROM POSNCTL.NBRRJQE NBRRJ2
                                              WHERE NBRRJ2.NBRRJQE_PIDM = NBRRJQE.NBRRJQE_PIDM
                                                AND NBRRJ2.NBRRJQE_POSN = NBRRJQE.NBRRJQE_POSN
                                                AND NBRRJ2.NBRRJQE_ACAT_CODE = NBRRJQE.NBRRJQE_ACAT_CODE)
            THEN (select goremal_email_address from GENERAL.goremal where goremal_pidm = NBRRJQE.NBRRJQE_APPR_PIDM
                   and goremal_emal_code = 'NSU'
                   and goremal_status_ind = 'A'
                   and goremal_activity_date = (select max(x1.goremal_activity_date) from goremal x1
                                      where x1.goremal_pidm = goremal.goremal_pidm
                                        and x1.goremal_emal_code = goremal.goremal_emal_code
                                        and x1.goremal_emal_code = 'NSU'))
            ELSE (select goremal_email_address from GENERAL.goremal where goremal_pidm = (SELECT DISTINCT t1.NBRBJOB_PIDM FROM NBRBJOB t1
                        WHERE t1.NBRBJOB_POSN = NBBPOSN.NBBPOSN_POSN_REPORTS
                          AND (t1.NBRBJOB_END_DATE IS NULL OR t1.NBRBJOB_END_DATE >= SYSDATE))
                   and goremal_emal_code = 'NSU'
                   and goremal_status_ind = 'A'
                   and goremal_activity_date = (select max(x1.goremal_activity_date) from goremal x1
                                      where x1.goremal_pidm = goremal.goremal_pidm
                                        and x1.goremal_emal_code = goremal.goremal_emal_code
                                        and x1.goremal_emal_code = 'NSU'))
       END as "Appr_Email_Addr",

       PERHOUR.PERHOUR_HRS as "Leave_Hrs",
       PERHOUR.PERHOUR_TIME_ENTRY_DATE as "Leave_Date",
       decode(PERHOUR.PERHOUR_EARN_CODE,'205','Pers','251',
              'Pers','265','Pers','255','Pers','200','Vac','250',
              'Vac','260','Vac','261','Vac','266','Vac') as "Leave_Code",
 
  vp_org.financial_manager_id        vp_id,
  vp_org.financial_manager_name      vp_name     
from PAYROLL.PERJOBS PERJOBS JOIN PAYROLL.PTRCALN PTRCALN ON PERJOBS.PERJOBS_YEAR = PTRCALN.PTRCALN_YEAR
                                                          AND PERJOBS.PERJOBS_PICT_CODE = PTRCALN.PTRCALN_PICT_CODE
                                                          AND PERJOBS.PERJOBS_PAYNO = PTRCALN.PTRCALN_PAYNO
                             JOIN PAYROLL.PERHOUR PERHOUR ON PERJOBS.PERJOBS_SEQNO = PERHOUR.PERHOUR_JOBS_SEQNO
                             JOIN POSNCTL.NBBPOSN NBBPOSN ON PERJOBS.PERJOBS_POSN = NBBPOSN.NBBPOSN_POSN
                             JOIN SATURN.SPRIDEN SPRIDEN  ON PERJOBS.PERJOBS_PIDM = SPRIDEN.SPRIDEN_PIDM
                                            AND SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                             JOIN POSNCTL.NBRBJOB NBRBJOB ON PERJOBS.PERJOBS_PIDM = NBRBJOB.NBRBJOB_PIDM
                                            AND NBRBJOB.NBRBJOB_POSN = PERJOBS.PERJOBS_POSN
                                            AND NBRBJOB.NBRBJOB_SUFF = PERJOBS.PERJOBS_SUFF
                                            AND NBRBJOB.NBRBJOB_CONTRACT_TYPE = 'P'
                                            AND (NBRBJOB.NBRBJOB_END_DATE IS NULL OR NBRBJOB.NBRBJOB_END_DATE > SYSDATE)
                             LEFT OUTER JOIN POSNCTL.NBRRJQE NBRRJQE ON PERJOBS.PERJOBS_PIDM = NBRRJQE.NBRRJQE_PIDM
,spriden appr_spriden join goremal appr_goremal on appr_spriden.spriden_change_ind is null and appr_spriden.spriden_pidm = appr_goremal.goremal_pidm and appr_goremal.goremal_emal_code = 'NSU'
,organization_hierarchy vp_org join goremal vp_goremal on vp_org.financial_manager_uid = vp_goremal.goremal_pidm and vp_goremal.goremal_emal_code = 'NSU'

where ( PERJOBS.PERJOBS_YEAR = to_number(to_char(add_months(sysdate,-1),'YYYY'))
         and PERJOBS.PERJOBS_ACAT_CODE = 'LEAVE'
         and PERJOBS.PERJOBS_PICT_CODE = 'MN'
         and PERJOBS.PERJOBS_STATUS_IND in ('P','I','R')
         and ( PERJOBS.PERJOBS_PAYNO = (select ptrcaln_payno from ptrcaln where ptrcaln_pict_code = 'MN'
              and ptrcaln_year = to_number(to_char(add_months(sysdate,-1),'YYYY'))
              and  to_date(to_char(add_months(sysdate,-1),'dd-mon-yyyy')) between ptrcaln_start_date and ptrcaln_end_date))
              )


  order by PERJOBS.PERJOBS_YEAR,
          SPRIDEN.SPRIDEN_LAST_NAME,
          SPRIDEN.SPRIDEN_FIRST_NAME,
          SPRIDEN.SPRIDEN_MI,
          PERJOBS.PERJOBS_PICT_CODE,
          PERJOBS.PERJOBS_PAYNO;