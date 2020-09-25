/*  Back to School Script 
    This is based on a SQL*Plus script for the FinAid New Year 
    that was found in the Ellucian support site by Vicki Ryals
    Original Service Request 15178170 - September 2020
*/

DECLARE
    f_dat_file_OUT utl_file.file_type;
    f_line_OUT varchar2(500);
    f_dir_OUT varchar2(20) := 'U13_STUDENT';
    f_name_OUT varchar2(15) := 'bts_textout.txt';
    f_exists_OUT boolean;
    f_size_OUT number;
    f_block_size_OUT number;

    v_aidy varchar2(4) := '2021';
    v_period varchar2(15) := '202130';
    c_message_text varchar2(100);
    c_message_text2 varchar2(100);
    c_message_text3 varchar2(100);
    
    --cursors
    --Report 1.1 If Disb Load > Pckg Load
    c_rfraspc_aidy_code rfraspc.rfraspc_aidy_code%TYPE;
    c_rfraspc_fund_code rfraspc.rfraspc_fund_code%TYPE;
    --pro uses c_message_text    
    c_rfraspc_3quarter_load_pct rfraspc.rfraspc_3quarter_load_pct%TYPE;
    c_rfraspc_half_load_pct rfraspc.rfraspc_half_load_pct%TYPE;
    c_rfraspc_less_half_load_pct rfraspc.rfraspc_less_half_load_pct%TYPE;
    --stu used c_message_text2
    
    CURSOR c_report1_1 IS
        SELECT
            rfraspc_aidy_code aidy,
            rfraspc_fund_code fund,
            decode(rfraspc_proration_ind,'P','Prorate','D','Disb 100%','N','No Disb') pro,
            decode(rfraspc_proration_ind,'P',rfraspc_3quarter_load_pct,null) per2,
            decode(rfraspc_proration_ind,'P',rfraspc_half_load_pct,null) per3,
            decode(rfraspc_proration_ind,'P',rfraspc_less_half_load_pct,null) per4,
            decode(xpload.xload,0,'N','Y') stu
        FROM
            rfraspc,
            (select
                rpratrm_aidy_code xaidy,
                rpratrm_fund_code xfund,
                rpratrm_period xper,
                sum(decode(rpratrm_pckg_load_ind,'1',0,1)) xload
            from
                rpratrm
            where	
                rpratrm_aidy_code = v_aidy
                and rpratrm_period = v_period
                and rpratrm_accept_amt > 0
            group by 
                rpratrm_aidy_code,
                rpratrm_fund_code,
                    rpratrm_period) xpload
        WHERE
            rfraspc_aidy_code = v_aidy
            and ((rfraspc_disburse_ind <> 'N')
            or (rfraspc_disburse_ind = 'N'
            and rfraspc_loan_process_ind = 'Y'))
            and xpload.xfund = rfraspc_fund_code
            and xpload.xaidy = rfraspc_aidy_code
        ORDER BY 3,2;
        
    --Report 1.2 Attending Hours by Fund
    --c_rfraspc_aidy_code already defined
    --c_rfraspc_fund_code already defined
    --attd uses c_message_text
    --xdays uses c_message_text2
    
    CURSOR c_report1_2 IS
        SELECT
            rfraspc_aidy_code aidy,
            rfraspc_fund_code fund,
            decode(rfraspc_attending_hr_ind,'Y','Yes','No') attd,
            nvl(rfraspc_disb_no_days,0) xdays
        FROM
            rfraspc
        WHERE
            rfraspc_aidy_code = v_aidy
            and ((rfraspc_disburse_ind <> 'N')
            or (rfraspc_disburse_ind = 'N'
            and rfraspc_loan_process_ind = 'Y'))
            and exists
                (select 
                    'x'
                from
                    rpratrm
                where
                    rpratrm_accept_amt > 0
                    and rpratrm_aidy_code = rfraspc_aidy_code
                    and rpratrm_fund_code = rfraspc_fund_code
                    and rpratrm_period = v_period)
        ORDER BY 2,3;
        
    --Report 1.3 Enrollment Code by Fund
    --c_rfraspc_aidy_code already defined
    --enrr uses c_text_message
    --c_rfraspc_fund_code already defined
    
    CURSOR c_report1_3 IS
        SELECT
            rfraspc_aidy_code aidy,
            decode(rfraspc_enrr_code,null,'*****',rfraspc_enrr_code) enrr,
            rfraspc_fund_code fund
        FROM
            rfraspc
        WHERE
            rfraspc_aidy_code = v_aidy
            and ((rfraspc_disburse_ind <> 'N')
            or (rfraspc_disburse_ind = 'N'
            and rfraspc_loan_process_ind = 'Y'))
            and exists
                (select 
                    'x'
                from
                    rpratrm
                where
                    rpratrm_accept_amt > 0
                    and rpratrm_aidy_code = rfraspc_aidy_code
                    and rpratrm_fund_code = rfraspc_fund_code
                    and rpratrm_period = v_period)
        ORDER BY 2,3;
        
    --Report 1.4 Disb Enrollment Edits for Memo
    --c_rfraspc_aidy_code aidy already defined
    --c_rfraspc_fund_code already defined
    --rfraspc_use_disb_enrl_memo_ind uses c_message_text
    
    CURSOR c_report1_4 IS
        SELECT
            rfraspc_aidy_code aidy,
            rfraspc_fund_code fund,
            nvl(rfraspc_use_disb_enrl_memo_ind,'N') xmem
        FROM
            rfraspc
        WHERE
            rfraspc_aidy_code = v_aidy
            and ((rfraspc_disburse_ind <> 'N')
            or (rfraspc_disburse_ind = 'N'
            and rfraspc_loan_process_ind = 'Y'))
            and ((rfraspc_appl_memo_ind = 'A'
            and exists
                (select 
                    'x'
                from
                    rpratrm
                where
                    rpratrm_accept_amt > 0
                    and rpratrm_aidy_code = rfraspc_aidy_code
                    and rpratrm_fund_code = rfraspc_fund_code
                    and rpratrm_period = v_period))
            or (rfraspc_appl_memo_ind = 'O'
            and exists
                (select 
                    'x'
                from
                    rpratrm
                where
                    rpratrm_accept_amt is null 
                    and rpratrm_offer_amt >0
                    and rpratrm_aidy_code = rfraspc_aidy_code
                    and rpratrm_fund_code = rfraspc_fund_code
                    and rpratrm_period = v_period)))
        ORDER BY 2,3;    
        
    --Report 1.5 Recoup When Award Reduced
    --c_rfraspc_aidy_code already defined
    --c_rfraspc_fund_code already defined
    --rfraspc_disburse_ind uses c_message_text
    c_rfraspc_recoup_ind rfraspc.rfraspc_recoup_ind%TYPE;
    
    CURSOR c_report1_5 IS
        SELECT
            rfraspc_aidy_code aidy,
            rfraspc_fund_code fund,
            decode(rfraspc_disburse_ind,'S','System','M','Manual','**') dind,
            nvl(rfraspc_recoup_ind,'N') xcoup
        FROM
            rfraspc
        WHERE
            rfraspc_aidy_code = v_aidy
            and rfraspc_disburse_ind <> 'N'
            and exists
                (select 
                    'x'
                from
                    rpratrm
                where
                    rpratrm_accept_amt > 0
                    and rpratrm_aidy_code = rfraspc_aidy_code
                    and rpratrm_fund_code = rfraspc_fund_code
                    and rpratrm_period = v_period)
        ORDER BY 2,3;
        
    --Report 1.6 Ineligible Before/After Settings by Fund
    --c_rfraspc_aidy_code already defined
    --c_rfraspc_fund_code already defined
    c_rprdate_period rprdate.rprdate_period%TYPE;
    c_rprdate_cut_off_date rprdate.rprdate_cut_off_date%TYPE;
    --rfraspc_inel_bef_cut_date_ind uses c_message_text
    --rfraspc_inel_aft_cut_date_ind uses c_message_text2
    
    CURSOR c_report1_6 IS
        SELECT
            rfraspc_aidy_code aidy,
            rfraspc_fund_code fund,
            substr(rprdate_period,1,10) per,
            rprdate_cut_off_date codate,
            decode(rfraspc_inel_bef_cut_date_ind,'B','Backout','P','Pmt not App','D','Disregard','Error') bf,
            decode(rfraspc_inel_aft_cut_date_ind,'B','Backout','P','Pmt not App','D','Disregard','Error') af	
        FROM
            rfraspc,
            rprdate
        WHERE
            rfraspc_aidy_code = v_aidy
            and rfraspc_disburse_ind <> 'N'
            and rfraspc_aidy_code = rprdate_aidy_code
            and rprdate_period = v_period
            and exists
                (select 
                    'x'
                from
                    rpratrm
                where
                    rpratrm_accept_amt > 0
                    and rpratrm_aidy_code = rfraspc_aidy_code
                    and rpratrm_fund_code = rfraspc_fund_code
                    and rpratrm_period = v_period)
        ORDER BY 2,3;
        
    --Report 1.7 Funds With Disbursement Locks
    c_rfrdlck_aidy_code rfrdlck.rfrdlck_aidy_code%TYPE;
    c_rfrdlck_fund_code rfrdlck.rfrdlck_fund_code%TYPE;
    c_rfrdlck_period rfrdlck.rfrdlck_period%TYPE;
    
    CURSOR c_report1_7 IS
        SELECT
            rfrdlck_aidy_code aidy,
            rfrdlck_fund_code fund,
            rfrdlck_period period
        FROM
            rfrdlck,
            rfraspc
        WHERE
            rfrdlck_aidy_code = v_aidy
            and rfrdlck_period = v_period
            and rfraspc_aidy_code = rfrdlck_aidy_code
            and rfraspc_fund_code = rfrdlck_fund_code
            and ((rfraspc_disburse_ind <> 'N')
            or (rfraspc_disburse_ind = 'N'
            and rfraspc_loan_process_ind = 'Y'))
            and exists
                (select 
                    'x'
                from
                    rpratrm
                where
                    rpratrm_accept_amt > 0
                    and rpratrm_aidy_code = rfrdlck_aidy_code
                    and rpratrm_fund_code = rfrdlck_fund_code
                    and rpratrm_period = rfrdlck_period)
        ORDER BY 2;    

    --Report 1.8 Scheduled Disbursement Dates for Non-Loan Funds
    c_rpradsb_aidy_code rpradsb.rpradsb_aidy_code%TYPE;
    c_rpradsb_period rpradsb.rpradsb_period%TYPE;
    c_rpradsb_fund_code rpradsb.rpradsb_fund_code%TYPE;
    c_rpradsb_schedule_date rpradsb.rpradsb_schedule_date%TYPE;
    
    CURSOR c_report1_8 IS
        SELECT distinct
            rpradsb_aidy_code aidy,
            rpradsb_period prd,
            rpradsb_fund_code fund,
            rpradsb_schedule_date schdate
        FROM
            rpradsb
        WHERE
            rpradsb_aidy_code = v_aidy
            and rpradsb_period = v_period
            and rpradsb_disburse_pct is not null
            and rpradsb_tran_number is null
        ORDER BY 2,3,4;
        
    --Report 1.9 Scheduled Non-Loan Disbursements Outside Period Start/End Dates
    --c_rpradsb_aidy_code already defined
    --c_rpradsb_period already defined
    --c_rpradsb_fund_code already defined
    --c_rpradsb_schedule_date already defined
    --xcnt uses c_message_text
    
    CURSOR c_report1_9 IS
        SELECT 
            rpradsb_aidy_code aidy,
            rpradsb_period prd,
            rpradsb_fund_code fund,
            rpradsb_schedule_date schdate,
            count(*) xcnt
        FROM
            rpradsb,
            robprds
        WHERE
            rpradsb_aidy_code = v_aidy
            and rpradsb_period = v_period
            and robprds_aidy_code = rpradsb_aidy_code
            and robprds_period = rpradsb_period
            and rpradsb_disburse_pct is not null
            and rpradsb_tran_number is null
            and rpradsb_schedule_date not between (robprds_start_date - 10) and robprds_end_date
        group by 
            rpradsb_aidy_code,
            rpradsb_period,
            rpradsb_fund_code,
            rpradsb_schedule_date
        ORDER BY 2,3,4;
        
    --Report 1.10 Scheduled Disbursement Dates for Loan Funds
    c_rlrdldd_aidy_code rlrdldd.rlrdldd_aidy_code%TYPE;
    c_rlrdldd_period rlrdldd.rlrdldd_period%TYPE;
    c_rlrdldd_fund_code rlrdldd.rlrdldd_fund_code%TYPE;
    c_rlrdldd_sched_date rlrdldd.rlrdldd_sched_date%TYPE;
    
    CURSOR c_report1_10 IS
        SELECT distinct
            rlrdldd_aidy_code aidy,
            rlrdldd_period prd,
            rlrdldd_fund_code fund,
            rlrdldd_sched_date schdate
        FROM
            rlrdldd
        WHERE
            rlrdldd_aidy_code = v_aidy
            and rlrdldd_period = v_period
            and rlrdldd_seq_no = 1
            and rlrdldd_ar_tran_number is null
        ORDER BY 2,3,4;
        
    --Report 1.11 Scheduled Loan Disbursements Outside Loan Period Start/End Dates
    --c_rlrdldd_aidy_code already defined
    --c_rlrdldd_period already defined
    --c_rlrdldd_fund_code already defined
    --c_rlrdldd_sched_date already defined
    --count uses c_message_text
    
    CURSOR c_report1_11 IS
        SELECT 
            rlrdldd_aidy_code aidy,
            rlrdldd_period prd,
            rlrdldd_fund_code fund,
            rlrdldd_sched_date schdate,
            count(*)
        FROM
            rlrdldd,
            rlrdlor
        WHERE
            rlrdldd_aidy_code = v_aidy
            and rlrdldd_period = v_period
            and rlrdldd_seq_no = 1
            and rlrdldd_gross_amt > 0
            and rlrdldd_ar_tran_number is null
            and rlrdlor_aidy_code = rlrdldd_aidy_code
            and rlrdlor_pidm = rlrdldd_pidm
            and rlrdlor_fund_code = rlrdldd_fund_code
            and rlrdlor_loan_no = rlrdldd_loan_no
            and rlrdldd_sched_date not between (rlrdlor_award_start_date - 10) and rlrdlor_award_end_date
        group by 
            rlrdldd_aidy_code,
            rlrdldd_period,
            rlrdldd_fund_code,
            rlrdldd_sched_date
        ORDER BY 2,3,4;
    
    --Report 2.1 Identify Orphan RPRATRM Records
    c_spriden_id spriden.spriden_id%TYPE;
    c_rpratrm_fund_code rpratrm.rpratrm_fund_code%TYPE;
    
    CURSOR c_report2_1 IS
        SELECT 
            spriden_id stu,  
            rpratrm_fund_code fnd 
        FROM 	spriden,
            rpratrm   
        WHERE 
            spriden_pidm = rpratrm_pidm           
            and spriden_change_ind is null 
            and rpratrm_period = v_period                     
        MINUS 
        SELECT 
            spriden_id,  
            rprawrd_fund_code 
        FROM 
            spriden,
            rprawrd 
        WHERE 
            spriden_pidm = rprawrd_pidm           
            and spriden_change_ind is null 
            and rprawrd_aidy_code = v_aidy;    
    
    --Running Report 2.2 Orphan Memo Records
    --c_spriden_id already defined
    c_rfrbase_fund_code rfrbase.rfrbase_fund_code%TYPE;
    
    CURSOR c_report2_2 IS
        SELECT  
            spriden_id st,  
            rfrbase_fund_code fnd
        FROM 
            spriden, 
            tbrmemo, 
            rfrbase 
        WHERE 
            tbrmemo_detail_code = rfrbase_detail_code 
            and spriden_pidm = tbrmemo_pidm 
            and spriden_change_ind is null 
            and tbrmemo_period = v_period 
            and tbrmemo_srce_code = 'F' 
        MINUS
        SELECT 
            spriden_id,  
            rpratrm_fund_code
        FROM 
            spriden, 
            rpratrm 
        WHERE 
            spriden_pidm = rpratrm_pidm 
            and spriden_change_ind is null 
            and rpratrm_period = v_period;          

    --Report 2.3 Loan Fund or Disburse Manually/System and No Detail Code
    --c_rfraspc_fund_code already defined
    c_rfraspc_loan_process_ind rfraspc.rfraspc_loan_process_ind%TYPE;
    c_rfraspc_disburse_ind rfraspc.rfraspc_disburse_ind%TYPE;
    c_rfrbase_detail_code rfrbase.rfrbase_detail_code%TYPE;
    
    CURSOR c_report2_3 IS
        SELECT 
            rfraspc_fund_code fund, 
            rfraspc_loan_process_ind lnpr, 
            rfraspc_disburse_ind disb, 
            rfrbase_detail_code dtcd
        FROM 
            rfraspc, 
            rfrbase
        WHERE 
            rfraspc_aidy_code = v_aidy
            and (rfraspc_loan_process_ind = 'Y'
            or rfraspc_disburse_ind in ('M','S'))
            and rfraspc_fund_code = rfrbase_fund_code
            and rfrbase_detail_code is null
        ORDER BY 
            rfraspc_fund_code asc;

    --Report 2.4 Loan Fund or Disburse Manually/System and Inactive Detail Code
    --c_rfraspc_fund_code already defined
    --c_rfraspc_loan_process_ind already defined
    --c_rfraspc_disburse_ind already defined
    --c_rfrbase_detail_code already defined
    c_tbbdetc_detc_active_ind tbbdetc.tbbdetc_detc_active_ind%TYPE;
    
    CURSOR c_report2_4 IS
        SELECT 
            rfraspc_fund_code fnd, 
            rfraspc_loan_process_ind lnpr, 
            rfraspc_disburse_ind disb, 
            rfrbase_detail_code dtcd, 
            tbbdetc_detc_active_ind dtcin
        FROM 
            rfraspc, 
            rfrbase, 
            tbbdetc
        WHERE 
            (rfraspc_aidy_code = v_aidy
            and (rfraspc_loan_process_ind = 'Y'
            or rfraspc_disburse_ind in ('M','S'))
            and rfraspc_fund_code = rfrbase_fund_code
            and tbbdetc_detail_code = rfrbase_detail_code
            and tbbdetc_detc_active_ind <> 'Y');
    
    --Report 2.5 Work Study Fund Code Review
    --c_rfraspc_fund_code already defined
    --c_rfraspc_disburse_ind already defined
    --c_rfrbase_detail_code already defined
    --c_tbbdetc_detc_active_ind already defined
    
    CURSOR c_report2_5 IS
        SELECT 
            rfraspc_fund_code fnd, 
            rfraspc_disburse_ind disb, 
            rfrbase_detail_code dtcd, 
            tbbdetc_detc_active_ind dtcin
        FROM 
          rfraspc, 
            rfrbase,
          tbbdetc
          WHERE 
            rfraspc_aidy_code = v_aidy
            and rfraspc_fund_code = rfrbase_fund_code
          and rfrbase_ftyp_code  =
                       (SELECT rtvftyp_code
                        FROM  rtvftyp
                        WHERE rtvftyp_code = rfrbase_ftyp_code
                        AND   rtvftyp_atyp_ind = 'W')
          and tbbdetc_detail_code(+) = rfrbase_detail_code; 
    
    --Report 2.6 If Selected for Verification but is Not Complete
    --c_rfraspc_fund_code already defined
    --ind uses c_message_text
    --src uses c_message_text2
    --fsrc uses c_message_text3
    
    CURSOR c_report2_6 IS
        SELECT 
            rfraspc_fund_code fnd, 
            decode (rfraspc_sel_ver_inc_ind,'Y','Yes Allow Disbursement', 'W','Inc with W Status Allow') ind,
          rfrbase_fsrc_code ||', '|| rtvfsrc_desc src,
          decode (rtvfsrc_ind,'O','Other','F','Federal','I','Institutional','S','State') fsrc 
        FROM 
          rfraspc, 
          rfrbase,
          rtvfsrc
            WHERE 
            rfraspc_aidy_code = v_aidy
            and rfraspc_sel_ver_inc_ind <> 'N'
          and rfraspc_fund_code = rfrbase_fund_code
          and rfrbase_fsrc_code = rtvfsrc_code
          order by  rfraspc_fund_code asc;
    
    --Report 2.7 Override General Tracking Requirement
    --c_rfraspc_fund_code already defined
    c_rfraspc_override_ind rfraspc.rfraspc_override_ind%TYPE;
    --src uses c_message_text
    --fsrc uses c_message_text2
    
    CURSOR c_report2_7 IS
        SELECT 
            rfraspc_fund_code fnd, 
            rfraspc_override_ind ovr,
            rfrbase_fsrc_code ||', '|| rtvfsrc_desc src,
          decode (rtvfsrc_ind,'O','Other','F','Federal','I','Institutional','S','State') fsrc 
        FROM 
          rfraspc, 
          rfrbase,
          rtvfsrc
            WHERE 
            rfraspc_aidy_code = v_aidy
            and rfraspc_override_ind = 'Y'
          and rfraspc_fund_code = rfrbase_fund_code
          and rfrbase_fsrc_code = rtvfsrc_code
          order by  rfraspc_fund_code asc;    
    
BEGIN <<main>>
    --Open File
    utl_file.fgetattr(f_dir_OUT,f_name_OUT,f_exists_OUT,f_size_OUT,f_block_size_OUT);
    IF f_exists_OUT THEN
        utl_file.fremove(f_dir_OUT,f_name_OUT);
    END IF;
    f_dat_file_OUT := utl_file.fopen(f_dir_OUT,f_name_OUT,'W');
    
    --Dump Cursors
    --Report headers
    utl_file.put_line(f_dat_file_OUT,'FinAid: Back To School Script',FALSE);
    utl_file.put_line(f_dat_file_OUT,'Run Time: '||to_char(sysdate,'DD-MON-YYYY HH24:MI'),FALSE);
    utl_file.put_line(f_dat_file_OUT,':',FALSE);
    utl_file.put_line(f_dat_file_OUT,'Aid Year Entered:        '||v_aidy,FALSE);
    utl_file.put_line(f_dat_file_OUT,'Period Entered:          '||v_period,FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    
    --Section Header 1.1
    utl_file.put_line(f_dat_file_OUT,'Report 1.1 - If Disb Load > Pckg Load ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',8)
                || RPAD('Proration',10)
                || RPAD(' ',9)
                || RPAD(' ',9)
                || RPAD(' ',11)
                || 'Studs With Load';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Fund',8)
                || RPAD('Ind',10)
                || RPAD('3/4 Time',9)
                || RPAD('1/2 Time',9)
                || RPAD('< 1/2 Time',11)
                || 'Not Equal 1';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_1;
    LOOP
        FETCH c_report1_1 
            INTO c_rfraspc_aidy_code
                ,c_rfraspc_fund_code
                ,c_message_text                
                ,c_rfraspc_3quarter_load_pct
                ,c_rfraspc_half_load_pct
                ,c_rfraspc_less_half_load_pct
                ,c_message_text2;
        EXIT WHEN c_report1_1%notfound;
        f_line_OUT := RPAD(c_rfraspc_aidy_code,10)
                || RPAD(c_rfraspc_fund_code,8)
                || RPAD(c_message_text,10)
                || RPAD(c_rfraspc_3quarter_load_pct,9)
                || RPAD(c_rfraspc_half_load_pct,9)
                || RPAD(c_rfraspc_less_half_load_pct,11)
                || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_1;    

    --Section Header 1.2
    utl_file.put_line(f_dat_file_OUT,'Report 1.2 - Attending Hours by Fund ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Fund',15)
                || RPAD(' ',10)
                || 'Studs With Load';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_2;
    LOOP
        FETCH c_report1_2
            INTO c_rfraspc_aidy_code
                ,c_rfraspc_fund_code
                ,c_message_text
                ,c_message_text2;
        EXIT WHEN c_report1_2%notfound;
        f_line_OUT := RPAD(c_rfraspc_aidy_code,10)
                || RPAD(c_rfraspc_fund_code,15)
                || RPAD(c_message_text,10)
                || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_2;    

    --Section Header 1.3
    utl_file.put_line(f_dat_file_OUT,'Report 1.3 - Enrollment Code by Fund ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || 'Enrollment';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Fund',15)
                || 'Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_3;
    LOOP
        FETCH c_report1_3
            INTO c_rfraspc_aidy_code
                ,c_message_text
                ,c_rfraspc_fund_code;
        EXIT WHEN c_report1_3%notfound;
        f_line_OUT := RPAD(c_rfraspc_aidy_code,10)
                || RPAD(c_message_text,15)
                || c_rfraspc_fund_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_3;   

    --Section Header 1.4
    utl_file.put_line(f_dat_file_OUT,'Report 1.4 - Disb Enrollment Edits for Memo ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || 'Disb Edits';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Fund',15)
                || 'Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_4;
    LOOP
        FETCH c_report1_4
            INTO c_rfraspc_aidy_code
                ,c_rfraspc_fund_code
                ,c_message_text;
        EXIT WHEN c_report1_4%notfound;
        f_line_OUT := RPAD(c_rfraspc_aidy_code,10)
                || RPAD(c_rfraspc_fund_code,15)
                || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_4;

    --Section Header 1.5
    utl_file.put_line(f_dat_file_OUT,'Report 1.5 - Recoup When Award Reduced ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD('Disbursement',15)                
                || 'Recoup when';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Fund',15)
                || RPAD('Ind',15)                
                || 'Reduced Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_5;
    LOOP
        FETCH c_report1_5
            INTO c_rfraspc_aidy_code
                ,c_rfraspc_fund_code
                ,c_message_text
                ,c_rfraspc_recoup_ind;
        EXIT WHEN c_report1_5%notfound;
        f_line_OUT := RPAD(c_rfraspc_aidy_code,10)
                || RPAD(c_rfraspc_fund_code,15)
                || RPAD(c_message_text,15)                
                || c_rfraspc_recoup_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_5;
    
    --Section Header 1.6
    utl_file.put_line(f_dat_file_OUT,'Report 1.6 - Ineligible Before/After Settings by Fund ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',11)                
                || RPAD('Cut Off',10)
                || RPAD(' ',12)   
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Fund',15)
                || RPAD('Period',11)
                || RPAD('Date',10)
                || RPAD('Before',12)                  
                || 'After';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_6;
    LOOP
        FETCH c_report1_6
            INTO c_rfraspc_aidy_code
                ,c_rfraspc_fund_code
                ,c_rprdate_period
                ,c_rprdate_cut_off_date
                ,c_message_text
                ,c_message_text2;
        EXIT WHEN c_report1_6%notfound;
        f_line_OUT := RPAD(c_rfraspc_aidy_code,10)
                || RPAD(c_rfraspc_fund_code,15)
                || RPAD(c_rprdate_period,11)
                || RPAD(c_rprdate_cut_off_date,10)
                || RPAD(c_message_text,12)                  
                || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_6;    

    --Section Header 1.7
    utl_file.put_line(f_dat_file_OUT,'Report 1.7 - Funds With Disbursement Locks ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Fund',30)
                || RPAD('Period',20);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_7;
    LOOP
        FETCH c_report1_7
            INTO c_rfrdlck_aidy_code
                ,c_rfrdlck_fund_code
                ,c_rfrdlck_period;
        EXIT WHEN c_report1_7%notfound;
        f_line_OUT := RPAD(c_rfrdlck_aidy_code,10)
                || RPAD(c_rfrdlck_fund_code,30)
                || RPAD(c_rfrdlck_period,20);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_7;  

    --Section Header 1.8
    utl_file.put_line(f_dat_file_OUT,'Report 1.8 - Scheduled Disbursement Dates for Non-Loan Funds ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',10)
                || 'Scheduled';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',10)
                || 'Disbursement';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Period',15)
                || RPAD('Fund',10)
                || 'Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_8;
    LOOP
        FETCH c_report1_8
            INTO c_rpradsb_aidy_code
                ,c_rpradsb_period
                ,c_rpradsb_fund_code
                ,c_rpradsb_schedule_date;
        EXIT WHEN c_report1_8%notfound;
        f_line_OUT := RPAD(c_rpradsb_aidy_code,10)
                || RPAD(c_rpradsb_period,15)
                || RPAD(c_rpradsb_fund_code,10)
                || c_rpradsb_schedule_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_8;  

    --Section Header 1.9
    utl_file.put_line(f_dat_file_OUT,'Report 1.9 - Scheduled Non-Loan Disbursements Outside Period Start/End Dates ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',10)
                || RPAD('Scheduled',12)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',10)
                || RPAD('Disbursement',12)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Period',15)
                || RPAD('Fund',10)
                || RPAD('Date',12)
                || 'Count';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_9;
    LOOP
        FETCH c_report1_9
            INTO c_rpradsb_aidy_code
                ,c_rpradsb_period
                ,c_rpradsb_fund_code
                ,c_rpradsb_schedule_date
                ,c_message_text;
        EXIT WHEN c_report1_9%notfound;
        f_line_OUT := RPAD('c_rpradsb_aidy_code',10)
                || RPAD('c_rpradsb_period',15)
                || RPAD('c_rpradsb_fund_code',10)
                || RPAD('c_rpradsb_schedule_date',12)
                || 'c_message_text';
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_9;  

    --Section Header 1.10
    utl_file.put_line(f_dat_file_OUT,'Report 1.10 - Scheduled Disbursement Dates for Loan Funds ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',10)
                || 'Scheduled';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',10)
                || 'Disbursement';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Period',15)
                || RPAD('Fund',10)
                || 'Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_10;
    LOOP
        FETCH c_report1_10
            INTO c_rlrdldd_aidy_code
                ,c_rlrdldd_period
                ,c_rlrdldd_fund_code
                ,c_rlrdldd_sched_date;
        EXIT WHEN c_report1_10%notfound;
        f_line_OUT := RPAD(c_rlrdldd_aidy_code,10)
                || RPAD(c_rlrdldd_period,15)
                || RPAD(c_rlrdldd_fund_code,10)
                || c_rlrdldd_sched_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_10;  

    --Section Header 1.11
    utl_file.put_line(f_dat_file_OUT,'Report 1.11 - Scheduled Loan Disbursements Outside Loan Period Start/End Dates ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',10)
                || RPAD('Scheduled',12)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',15)
                || RPAD(' ',10)
                || RPAD('Disbursement',12)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid Year',10)
                || RPAD('Period',15)
                || RPAD('Fund',10)
                || RPAD('Date',12)
                || 'Count';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_11;
    LOOP
        FETCH c_report1_11
            INTO c_rlrdldd_aidy_code
                ,c_rlrdldd_period
                ,c_rlrdldd_fund_code
                ,c_rlrdldd_sched_date
                ,c_message_text;
        EXIT WHEN c_report1_11%notfound;
        f_line_OUT := RPAD(c_rlrdldd_aidy_code,10)
                || RPAD(c_rlrdldd_period,15)
                || RPAD(c_rlrdldd_fund_code,10)
                || RPAD(c_rlrdldd_sched_date,12)
                || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_11;  

    --Section Header 2.1
    utl_file.put_line(f_dat_file_OUT,'Report 2.1 - Identify Orphan RPRATRM Records ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('ID',10)
                || 'Fund';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report2_1;
    LOOP
        FETCH c_report2_1
            INTO c_spriden_id
                ,c_rpratrm_fund_code;
        EXIT WHEN c_report2_1%notfound;
        f_line_OUT := RPAD(c_spriden_id,10)
                || c_rpratrm_fund_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report2_1; 

    --Section Header 2.2
    utl_file.put_line(f_dat_file_OUT,'Report 2.2 - Orphan Memo Records ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('ID',10)
                || 'Fund';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report2_2;
    LOOP
        FETCH c_report2_2
            INTO c_spriden_id
                ,c_rfrbase_fund_code;
        EXIT WHEN c_report2_2%notfound;
        f_line_OUT := RPAD(c_spriden_id,10)
                || c_rfrbase_fund_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report2_2; 

    --Section Header 2.3
    utl_file.put_line(f_dat_file_OUT,'Report 2.3 - Loan Fund or Disburse Manually/System and No Detail Code ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Fund',10)
                || RPAD('Loan Process',15)
                || RPAD('Disburse',10)
                || 'Detail Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report2_3;
    LOOP
        FETCH c_report2_3
            INTO c_rfraspc_fund_code
                ,c_rfraspc_loan_process_ind
                ,c_rfraspc_disburse_ind
                ,c_rfrbase_detail_code;
        EXIT WHEN c_report2_3%notfound;
        f_line_OUT := RPAD(c_rfraspc_fund_code,10)
                    || RPAD(c_rfraspc_loan_process_ind,15)
                    || RPAD(c_rfraspc_disburse_ind,10)
                    || c_rfrbase_detail_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report2_3; 

    --Section Header 2.4
    utl_file.put_line(f_dat_file_OUT,'Report 2.4 - Loan Fund or Disburse Manually/System and Inactive Detail Code ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Fund',10)
                || RPAD('Loan Process',15)
                || RPAD('Disburse',10)
                || RPAD('Detail Code',15)
                || 'Active Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report2_4;
    LOOP
        FETCH c_report2_4
            INTO c_rfraspc_fund_code
                ,c_rfraspc_loan_process_ind
                ,c_rfraspc_disburse_ind
                ,c_rfrbase_detail_code
                ,c_tbbdetc_detc_active_ind;
        EXIT WHEN c_report2_4%notfound;
        f_line_OUT := RPAD(c_rfraspc_fund_code,10)
                    || RPAD(c_rfraspc_loan_process_ind,15)
                    || RPAD(c_rfraspc_disburse_ind,10)
                    || RPAD(c_rfrbase_detail_code,15)
                    || c_tbbdetc_detc_active_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report2_4; 

    --Section Header 2.5
    utl_file.put_line(f_dat_file_OUT,'Report 2.5 - Work Study Fund Code Review ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Fund',10)
                || RPAD('Disburse',10)
                || RPAD('Detail Code',15)
                || 'Active Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report2_5;
    LOOP
        FETCH c_report2_5
            INTO c_rfraspc_fund_code
                ,c_rfraspc_disburse_ind
                ,c_rfrbase_detail_code
                ,c_tbbdetc_detc_active_ind;
                
        EXIT WHEN c_report2_5%notfound;
        f_line_OUT := RPAD(c_rfraspc_fund_code,10)
                    || RPAD(c_rfraspc_disburse_ind,15)
                    || RPAD(c_rfrbase_detail_code,10)
                    || c_tbbdetc_detc_active_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report2_5; 

    --Section Header 2.6
    utl_file.put_line(f_dat_file_OUT,'Report 2.6 - If Selected for Verification but is Not Complete ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',30)
                || RPAD('Federal',20)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',30)
                || RPAD('Source',20)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',30)
                || RPAD('Code',20)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Fund',10)
                || RPAD('Verification is not Complete',30)
                || RPAD('Description',20)
                || 'Fund Source Code Indicator';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);    
    
    OPEN c_report2_6;
    LOOP
        FETCH c_report2_6
            INTO c_rfraspc_fund_code
                ,c_message_text
                ,c_message_text2
                ,c_message_text3;
        EXIT WHEN c_report2_6%notfound;
        f_line_OUT := RPAD(c_rfraspc_fund_code,10)
                || RPAD(c_message_text,30)
                || RPAD(c_message_text2,20)
                || c_message_text3;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report2_6; 
 
    --Section Header 2.7
    utl_file.put_line(f_dat_file_OUT,'Report 2.7 - Override General Tracking Requirement ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',19)
                || RPAD('Federal',25)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',19)
                || RPAD('Source',25)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',10)
                || RPAD(' ',19)
                || RPAD('Code',25)
                || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Fund',10)
                || RPAD('Override Track Req',19)
                || RPAD('Description',25)
                || 'Fund Source Code Indicator';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    
    OPEN c_report2_7;
    LOOP
        FETCH c_report2_7
            INTO c_rfraspc_fund_code
                ,c_rfraspc_override_ind
                ,c_message_text
                ,c_message_text2;
        EXIT WHEN c_report2_7%notfound;
        f_line_OUT := RPAD(c_rfraspc_fund_code,10)
                    || RPAD(c_rfraspc_override_ind,19)
                    || RPAD(c_message_text,25)
                    || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report2_7; 
    
    --Close File
    utl_file.fclose(f_dat_file_OUT);

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE nsudev.btsoutp';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE nsudev.btsoutp(
            btsoutp_line    char(500)
        )
        ORGANIZATION EXTERNAL (
            TYPE ORACLE_LOADER
            DEFAULT DIRECTORY U13_STUDENT
            ACCESS PARAMETERS (
                RECORDS DELIMITED BY NEWLINE
                FIELDS(btsoutp_line    char(500))
            )
            LOCATION (''bts_textout.txt'')
        )';
        
    END;

END;

