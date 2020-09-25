/*  New Year Script 
    This is based on a SQL*Plus script for the FinAid New Year 
    that was found in the Ellucian support site by Vicki Ryals
    Original Service Request 15178170 - September 2020
*/


DECLARE
    f_dat_file_OUT utl_file.file_type;
    f_line_OUT varchar2(500);
    f_dir_OUT varchar2(20) := 'U13_STUDENT';
    f_name_OUT varchar2(15) := 'nys_textout.txt';
    f_exists_OUT boolean;
    f_size_OUT number;
    f_block_size_OUT number;

    v_aidy varchar2(4) := '2122';
    v_aidy_budgeting_status varchar2(100);
    v_period_budgeting_status varchar2(100);
    
    
    --cursors
    --Report 1.1 Missing Default Aid Period
    c_robinst_aidy_code robinst.robinst_aidy_code%TYPE;
    
    CURSOR c_report1_1 IS
        SELECT
            robinst_aidy_code aidy
        FROM
            robinst
        WHERE
            robinst_aprd_code_def is null
        	and robinst_aidy_code = v_aidy;
            
    --Report 1.2. Missing Default Term or Period Code
    CURSOR c_report1_2 IS
        SELECT
            robinst_aidy_code aidy
        FROM
        	robinst
        WHERE
        	(robinst_current_term_code is null or 
          robinst_current_period is null)
        	and robinst_aidy_code = v_aidy;

    --Report 1.3 Missing Campus OPEID or Branch
    c_rorcamp_aidy_code rorcamp.rorcamp_aidy_code%TYPE;
    c_rorcamp_camp_code rorcamp.rorcamp_camp_code%TYPE;
    c_message_text varchar2(100);
    
    CURSOR c_report1_3 IS
        SELECT
            rorcamp_aidy_code aidy,
            rorcamp_camp_code camp,
            'Missing OPE ID or OPE ID Branch' mes2
        FROM
            rorcamp
        WHERE
            (rorcamp_opeid is null or
            rorcamp_opeid_branch is null) and
            rorcamp_aidy_code = v_aidy;

    --Report 1.4 Missing Pell Fund code
    CURSOR c_report1_4 IS
        SELECT 
        	rorcamp_camp_code camp,
        	rorcamp_aidy_code aidy 
        FROM 
        	rorcamp, robinst 
        WHERE 
        	rorcamp_pell_fund_code IS NULL
        	AND rorcamp_aidy_code = robinst_aidy_code 
        	AND robinst_status_ind = 'A'
        	AND robinst_aidy_code = v_aidy;

    --Report 1.5 EDE Corrections Logging
    --c_robinst_aidy_code already declared
    
    CURSOR c_report1_5 IS
        SELECT 
        	robinst_aidy_code aidy,
           	decode(robinst_pell_audit_ind,'Y','IS','IS NOT')||' enabled for EDE Correction Logging on ROAUSIO Grant EDE Options tab' mes15
        FROM 
        	robinst
        WHERE 
        	robinst_status_ind = 'A'
        	AND robinst_aidy_code = v_aidy;
            
    --Report 1.6 ROAINST Credit Hours Setup
    c_rorcrhr_levl_code rorcrhr.rorcrhr_levl_code%TYPE;
    c_message_text2 varchar2(100);
    
    CURSOR c_report1_6 IS
        SELECT 
        	DISTINCT(rorcrhr_levl_code) levl, 
        	' Level Code not in Form RORACYR for' mes2, 
        	rorcrhr_aidy_code ||' Aid Year' aidy
        FROM 
        	rorcrhr, 
        	robinst 
        WHERE 
        	rorcrhr_aidy_code = robinst_aidy_code 
        	AND robinst_status_ind = 'A'
        	AND robinst_aidy_code = v_aidy
        	AND rorcrhr_levl_code NOT IN 
        	(SELECT 
        		roracyr_levl_code 
        	FROM 
        		roracyr,
        		robinst 
        	WHERE  
        		rorcrhr_aidy_code = robinst_aidy_code 
        		AND robinst_status_ind = 'A'
        		AND robinst_aidy_code = v_aidy);

        --Report 1.7 ROAINST Credit Hours Setup
        c_stvterm_code stvterm.stvterm_code%TYPE;
        
        CURSOR c_report1_7 IS
        SELECT 
        	stvterm_code trm,
        	'Term Code is not in Form ROAINST Credit Hours tab for the' mes2, 
        	robinst_aidy_code ||' Aid Year' aidy
        FROM 
        	stvterm, robinst
        WHERE 
        	stvterm_fa_proc_yr = robinst_aidy_code  
        	AND robinst_status_ind = 'A'
        	AND robinst_aidy_code = v_aidy
        	AND stvterm_code NOT IN 
        	(SELECT 
        		rorcrhr_period
        	FROM 
        		rorcrhr, 
        		robinst
        	WHERE 
        		rorcrhr_aidy_code = robinst_aidy_code
        		AND robinst_status_ind = 'A'
        		AND robinst_aidy_code = v_aidy);

    --Report 1.8 ROAINST Default Aid Period Algo Rule
    --c_robinst_aidy_code already declared
    c_roralgo_process roralgo.roralgo_process%TYPE;
    c_roralgo_algo_code roralgo.roralgo_algo_code%TYPE;
    
    CURSOR c_report1_8 IS
        SELECT 
        	DISTINCT(robinst_aidy_code) aidy,
           ' Aid Year in ROAINST Defaults tab should be reviewed.  RORALGO Process' mes2,
           roralgo_process pro,
           'has an active rule' mes3,
           roralgo_algo_code algo
        FROM 
        	robinst, 
        	roralgo
        WHERE 
        	(robinst_aprd_algo_code_def  IS NULL 
        	AND roralgo_process = 'DAPRD' 
        	AND roralgo_active_ind = 'Y'
        	AND roralgo_aidy_code = robinst_aidy_code
        	AND robinst_status_ind = 'A'
        	AND robinst_aidy_code = v_aidy);

    --Report 1.9 Enrollment Cut Off Dates
    c_rorcrhr_period rorcrhr.rorcrhr_period%TYPE;
    
    CURSOR c_report1_9 IS
        SELECT 
        	DISTINCT(rorcrhr_period) prd, 
        	' Period in ROAINST Credit Hours tab does not exist in RPROPTS Enrollment Cut Off Rules for' mes2,
        	rorcrhr_aidy_code ||' Aid Year' aidy
        FROM 
        	rorcrhr, 
        	robinst
        WHERE 
        	rorcrhr_aidy_code = robinst_aidy_code 
        	AND robinst_status_ind = 'A'
        	AND robinst_aidy_code = v_aidy
        	AND rorcrhr_period NOT IN 
        	(SELECT 
        		rprdate_period
        	FROM 
        		rprdate, 
        		robinst
        	WHERE 
        		rprdate_aidy_code = robinst_aidy_code  
        	AND robinst_status_ind = 'A'
        	AND robinst_aidy_code = v_aidy);

    --Report 1.10 RORTPRD Default Aid Period on ROAINST Build Periods
    c_robinst_aprd_code_def robinst.robinst_aprd_code_def%TYPE;
    
    CURSOR c_report1_10 IS
        SELECT 
        	robinst_aprd_code_def arpd_def,
        	' Default Aid Period has not been setup for the ' mes2, 
        	robinst_aidy_code aidy,
        	' Aid Year in RORTPRD and must be setup for period expected information to default into RORPRST' mes3
        FROM 
        	robinst
        WHERE 
        	robinst_aidy_code = v_aidy
        	AND  robinst_status_ind = 'A'
        	AND robinst_aprd_code_def NOT IN 
        	(SELECT 
        		rortprd_aprd_code  
        	FROM 
        		rortprd, robinst 
        	WHERE 
        		rortprd_aidy_code = robinst_aidy_code 
        	AND robinst_status_ind = 'A'
        	AND robinst_aidy_code = v_aidy);

    --Report 1.11 Algo Rules Active not Validated
    --c_roralgo_process already declared
    c_roralgo_ptyp_code roralgo.roralgo_ptyp_code%TYPE;
    --c_roralgo_algo_code already declared
    c_roralgo_aidy_code roralgo.roralgo_aidy_code%TYPE;
    c_roralgo_seq_no roralgo.roralgo_seq_no%TYPE;
    
    CURSOR c_report1_11 IS
        SELECT 
                       'RORALGO Process Type ' || 
                       roralgo_process prc,
                       'Batch Posting Type ' || roralgo_ptyp_code ptyp,
                       'Rule '|| roralgo_algo_code cde,
                       'for Aid Year '|| roralgo_aidy_code aidy, 
                       'Sequence ' || roralgo_seq_no seq,
                       'is Active but not Validated' mes3
        FROM 
                       roralgo, 
                       robinst 
        WHERE 
                       roralgo_aidy_code = robinst_aidy_code  
                       AND robinst_status_ind = 'A'
                       AND robinst_aidy_code = v_aidy
                       AND roralgo_validated_ind = 'N'
                       AND roralgo_active_ind = 'Y';
                       
    --Report 2.1 Review Data Sources Rules RCRDTSR for Aid Year
    c_rcrinfr_infc_code rcrinfr.rcrinfr_infc_code%TYPE;
    c_rcrinfr_cmsc_code rcrinfr.rcrinfr_cmsc_code%TYPE;
    c_rcrinfr_parameter_set rcrinfr.rcrinfr_parameter_set%TYPE;
    c_rcrinfr_user_id rcrinfr.rcrinfr_user_id%TYPE;
    c_rcrinfr_activity_date rcrinfr.rcrinfr_activity_date%TYPE;
                
    CURSOR c_report2_1 IS
        SELECT 
        	rcrinfr_infc_code cde,
        	rcrinfr_cmsc_code cmsc,
        	rcrinfr_parameter_set st,
        	rcrinfr_user_id id,
        	rcrinfr_activity_date dte
        from 
        	rcrinfr
        where
        	rcrinfr_aidy_code = v_aidy;
    
    --Report 3.1 Review of RPRCLSS
    c_rprclss_levl_code rprclss.rprclss_levl_code%TYPE;
    c_rprclss_clas_code rprclss.rprclss_clas_code%TYPE;
    
    CURSOR c_report3_1 IS
        SELECT 
        	rprclss_levl_code lvl,
        	rprclss_clas_code clc,
        	DECODE(rprclss_finaid_class, '1','1 - 1ST Time Freshmen No Prior College'
                                       , '2','2 - Freshmen Prior College'
                                       , '3', '3 - Sophmore 2nd year UG'
                                       , '4','4 - Junior 3rd year UG'
                                       , '5','5 - Senior 4th year UG'
                                       , '6','6 - 5th year UG'
                                       , '7','7 - 1st year Grad Prof'
                                       , '8','8 - 2nd year Grad Prof'
                                       , '9','9 - 3rd year Grad Prof') cls
        FROM rprclss 
        WHERE rprclss_aidy_code = v_aidy
        ORDER BY rprclss_levl_code, rprclss_finaid_class;

    --Report 3.2 Aid Periods Review
    c_robaprd_aidy_code robaprd.robaprd_aidy_code%TYPE;
    c_robaprd_aprd_code robaprd.robaprd_aprd_code%TYPE;
    c_robaprd_full_yr_pct robaprd.robaprd_full_yr_pct%TYPE;
    c_robaprd_pell_full_yr_pct robaprd.robaprd_pell_full_yr_pct%TYPE;
    c_robaprd_grant_full_yr_pct robaprd.robaprd_grant_full_yr_pct%TYPE;
    c_robaprd_budg_dur_fm robaprd.robaprd_budg_dur_fm%TYPE;
    c_robaprd_budg_dur_im robaprd.robaprd_budg_dur_im%TYPE;
    c_robaprd_sayr_code robaprd.robaprd_sayr_code%TYPE;
    
    CURSOR c_report3_2 IS
        select 
            robaprd_aidy_code aidy,
            robaprd_aprd_code aprd,
            robaprd_full_yr_pct fullyr,
            robaprd_pell_full_yr_pct pellyr,
            robaprd_grant_full_yr_pct grantyr,
            robaprd_budg_dur_fm buddur_fm,
            robaprd_budg_dur_im buddur_im,
            robaprd_sayr_code saycode
        from 
            robaprd
        where 
        	robaprd_aidy_code = v_aidy
        order by 
        	robaprd_aprd_code;

    --Report 3.3 Aid Periods Missing Setup
    CURSOR c_report3_3 IS
        SELECT
        	robaprd_aprd_code aprd,
        	'Aid Period Not Set Up' mesg55
        FROM
        	robaprd
        WHERE
        	robaprd_aidy_code = v_aidy and
          	not exists
        		(select 
        			'x' 
        		 from 
        		 	rfrdefa
        		 where 
        		 	robaprd_aprd_code = rfrdefa_aprd_code and
        			rfrdefa_aidy_code = v_aidy and 
              		robaprd_aidy_code = rfrdefa_aidy_code)
              	 order by 
              		 robaprd_aprd_code;
                     
    --Report 3.4 Aid Period Set Up on RORTPRD 
    c_rortprd_aprd_code rortprd.rortprd_aprd_code%TYPE;
    c_rortprd_period rortprd.rortprd_period%TYPE;
    c_rortprd_start_date rortprd.rortprd_start_date%TYPE;
    c_rortprd_end_date rortprd.rortprd_end_date%TYPE;
                
    CURSOR c_report3_4 IS
        SELECT 
            rortprd_aprd_code taprd, 
            rortprd_period tprd,
            rortprd_start_date sdate,
            rortprd_end_date edate
        FROM 
            rortprd
        WHERE 
            rortprd_aidy_code = v_aidy
        ORDER BY 
            rortprd_aprd_code;

    --Report 3.5 Aid Periods not Setup
    CURSOR c_report3_5 IS
        SELECT
            robaprd_aprd_code aprd,
            'Aid Period Not Set Up' mesg35
        FROM
            robaprd
        WHERE
            robaprd_aidy_code = v_aidy and
            not exists
                (select 
                    'x' 
                 from 
                    rortprd
                 where 
                    robaprd_aprd_code = rortprd_aprd_code and
                    rortprd_aidy_code = v_aidy);

    --Report 3.6 Award and Pell Grant Percent RFRDEFA Review
    c_rfrdefa_aprd_code rfrdefa.rfrdefa_aprd_code%TYPE;
    c_rfrdefa_period rfrdefa.rfrdefa_period%TYPE;
    c_rfrdefa_award_pct rfrdefa.rfrdefa_award_pct%TYPE;
    c_rfrdefa_pell_award_pct rfrdefa.rfrdefa_pell_award_pct%TYPE;
    c_rfrdefa_memo_exp_date rfrdefa.rfrdefa_memo_exp_date%TYPE;
    
    CURSOR c_report3_6 IS
        SELECT 
        	rfrdefa_aprd_code aprd, 
          	rfrdefa_period prd,
          	rfrdefa_award_pct apct,
          	rfrdefa_pell_award_pct pellpct,
          	rfrdefa_memo_exp_date mdate
        FROM 
          	rfrdefa
        WHERE 
          	rfrdefa_aidy_code = v_aidy
        ORDER BY 
        	rfrdefa_aprd_code;

    --Report 3.7 Aid Periods Missing Grant Pct on RFRDEFA
    CURSOR c_report3_7 IS
        SELECT
        	robaprd_aprd_code aprd
        FROM
        	robaprd
        WHERE
        	robaprd_aidy_code = v_aidy and
        	exists
        		(select 
        			'x' 
        		 from 
        		 	rfrdefa
        		 where 
        		 	robaprd_aprd_code = rfrdefa_aprd_code and
        		 	rfrdefa_pell_award_pct is null and
        			rfrdefa_aidy_code = v_aidy and
              			robaprd_aidy_code = rfrdefa_aidy_code)
                 	order by 
                 		robaprd_aprd_code;

    --Report 3.8 Aid Periods with no Memo Expiration Date
    --c_rfrdefa_aprd_code already declared
    --c_rfrdefa_period already declared
    
    CURSOR c_report3_8 IS
        SELECT
        	rfrdefa_aprd_code aprd,
        	rfrdefa_period aprd
        FROM
        	rfrdefa
        WHERE 
        	rfrdefa_memo_exp_date is null and
        	exists
        		(select
        			'x'
        		 from
        		 	rfraspc
        		 where
        		 	rfrdefa_aidy_code = rfraspc_aidy_code and
        			rfraspc_appl_memo_ind <> 'N') and
        			rfrdefa_aidy_code = v_aidy;

    --Report 3.9 Aid Periods with Memo Date outside Aid Year
    -- c_rfrdefa_aprd_code already declared
    c_rfrdefa_term_code rfrdefa.rfrdefa_term_code%TYPE;
    -- c_rfrdefa_memo_exp_date already declared
                
    CURSOR c_report3_9 IS
        SELECT
        	rfrdefa_aprd_code aprd,
        	rfrdefa_term_code aterm,
        	rfrdefa_memo_exp_date mdate
        FROM
        	rfrdefa,
        	robinst
        WHERE 
        	rfrdefa_memo_exp_date is not null and
        	rfrdefa_aidy_code = robinst_aidy_code and
        	rfrdefa_memo_exp_date not between 
        	robinst_aidy_start_date and
        	robinst_aidy_end_date and
        	rfrdefa_aidy_code = v_aidy;

    --Report 3.10 Disbursement Dates and Percent RFRDEFA Review
    c_rfrdefd_aprd_code rfrdefd.rfrdefd_aprd_code%TYPE;
    c_rfrdefd_period rfrdefd.rfrdefd_period%TYPE;
    c_rfrdefd_disburse_date rfrdefd.rfrdefd_disburse_date%TYPE;
    c_rfrdefd_disburse_pct rfrdefd.rfrdefd_disburse_pct%TYPE;
                
    CURSOR c_report3_10 IS
        SELECT 
        	rfrdefd_aprd_code daprd, 
          	rfrdefd_period dprd,
          	rfrdefd_disburse_date ddate,
          	rfrdefd_disburse_pct dpct
        FROM 
          	rfrdefd
        WHERE 
          	rfrdefd_aidy_code = v_aidy
        ORDER BY 
        	rfrdefd_aprd_code;

    --Report 3.11 Aid Periods with no Disbursement Schedule
    CURSOR c_report3_11 IS
        SELECT
            rfrdefa_aprd_code aprd
        FROM
            rfrdefa
        WHERE
            rfrdefa_aidy_code = v_aidy and
            not exists
                (select 
                    'x' 
                 from 
                    rfrdefd
                 where 
                    rfrdefd_aprd_code = rfrdefa_aprd_code and
                    rfrdefd_term_code = rfrdefa_term_code and
                    rfrdefd_aidy_code = rfrdefa_aidy_code);

    --Report 3.12 Aid Periods Disbursement Dates outside Aid Year
    c_rfrdefd_term_code rfrdefd.rfrdefd_term_code%TYPE;
    
    CURSOR c_report3_12 IS
        SELECT
            rfrdefd_aprd_code aprd,
            rfrdefd_term_code aterm,
            rfrdefd_disburse_date ddate
        FROM
            rfrdefd,
            robinst
        WHERE 
            rfrdefd_disburse_date is not null and
            rfrdefd_aidy_code = robinst_aidy_code and
            rfrdefd_disburse_date not between 
            robinst_aidy_start_date and
            robinst_aidy_end_date and
            rfrdefd_aidy_code = v_aidy;

    --Report 3.13 Aid Periods Disbursement to Reschedule
    CURSOR c_report3_13 IS
        SELECT
            rfrdefd_aprd_code aprd,
            rfrdefd_term_code aterm
        FROM
            rfrdefd,
            robinst
        WHERE 
            rfrdefd_disb_sched_no_days is null and
            rfrdefd_aidy_code = robinst_aidy_code and
            robinst_resched_disb_date_ind = 'Y' and
            rfrdefd_aidy_code = v_aidy;
    
    --Report 3.14 Aid Periods with no Loan Period
    CURSOR c_report3_14 IS
        SELECT
            robaprd_aprd_code aprd 
        FROM
            robaprd
        WHERE
            robaprd_aidy_code = v_aidy and
            not exists
                (select 
                    'x' 
                 from 
                    rprlpap
                 where 
                    robaprd_aprd_code = rprlpap_aprd_code and
                    rprlpap_aidy_code = v_aidy and 
              robaprd_aidy_code = rprlpap_aidy_code);

    --Report 4.1 Tracking Requirement Codes
    c_rtvtreq_code rtvtreq.rtvtreq_code%TYPE;
    c_rtvtreq_short_desc rtvtreq.rtvtreq_short_desc%TYPE;
    c_rtvtreq_once_ind rtvtreq.rtvtreq_once_ind%TYPE;
    c_rtvtreq_pckg_ind rtvtreq.rtvtreq_pckg_ind%TYPE;
    c_rtvtreq_disb_ind rtvtreq.rtvtreq_disb_ind%TYPE;
    c_rtvtreq_memo_ind rtvtreq.rtvtreq_memo_ind%TYPE;
    
    CURSOR c_report4_1 IS
        SELECT
        	rtvtreq_code trcode,
        	rtvtreq_short_desc trdesc,
        	rtvtreq_once_ind once,
        	rtvtreq_pckg_ind pckg,
        	rtvtreq_disb_ind disb,
        	rtvtreq_memo_ind memo
        FROM
        	rtvtreq;

    --Report 4.2 Tracking Requirement Codes Descriptions
    c_rtvtreq_long_desc rtvtreq.rtvtreq_long_desc%TYPE;
    
    CURSOR c_report4_2 IS
        SELECT
        	rtvtreq_code tlrcode,
        	rtvtreq_long_desc tlrdesc
        FROM
        	rtvtreq;

    --Report 4.3 Tracking Status Codes
    c_rtvtrst_code rtvtrst.rtvtrst_code%TYPE;
    c_rtvtrst_desc rtvtrst.rtvtrst_desc%TYPE;
    c_rtvtrst_sat_ind rtvtrst.rtvtrst_sat_ind%TYPE;
    c_rtvtrst_trk_ltr_ind rtvtrst.rtvtrst_trk_ltr_ind%TYPE;
    
    CURSOR c_report4_3 IS
        SELECT
        	rtvtrst_code tstat,
        	rtvtrst_desc tsdesc,
        	rtvtrst_sat_ind sind,
        	rtvtrst_trk_ltr_ind tind
        FROM
        	rtvtrst
        ORDER BY
        	1;

    --Report 4.4 Tracking Req and Group Associations
    c_rrrgreq_aidy_code rrrgreq.rrrgreq_aidy_code%TYPE;
    c_rrrgreq_tgrp_code rrrgreq.rrrgreq_tgrp_code%TYPE;
    c_rtvtgrp_desc rtvtgrp.rtvtgrp_desc%TYPE;
    c_rrrgreq_treq_code rrrgreq.rrrgreq_treq_code%TYPE;
    --c_rtvtreq_short_desc already declared
    
    CURSOR c_report4_4 IS
        SELECT
        	rrrgreq_aidy_code taidy,
        	rrrgreq_tgrp_code tgcode,
        	rtvtgrp_desc tgcddesc,
        	rrrgreq_treq_code treqcd,
        	rtvtreq_short_desc tgdesc
        FROM
        	rrrgreq,
        	rtvtreq,
        	rtvtgrp
        WHERE 
        	rrrgreq_treq_code = rtvtreq_code and
        	rtvtgrp_code = rrrgreq_tgrp_code and
        	rrrgreq_aidy_code = v_aidy
        ORDER BY 
        	1, 2;

    --Report 4.5 Tracking Groups with no Requirements
    c_rtvtgrp_code rtvtgrp.rtvtgrp_code%TYPE;
    
    CURSOR c_report4_5 IS
        SELECT
        	rtvtgrp_code tcode,
        	rtvtgrp_desc tdesc
        FROM
        	rtvtgrp
        WHERE
        	not exists
        		(select
        			'x'
        		 from
        			rrrgreq
        		 where
        			rrrgreq_tgrp_code = rtvtgrp_code and
        			rrrgreq_aidy_code = v_aidy);

    --Report 4.6 Tracking Requirements and Messages Associated
    c_rrrtmsg_aidy_code rrrtmsg.rrrtmsg_aidy_code%TYPE;
	c_rrrtmsg_treq_code rrrtmsg.rrrtmsg_treq_code%TYPE;
    -- c_rtvtreq_short_desc already declared
	c_rrrtmsg_mesg_code rrrtmsg.rrrtmsg_mesg_code%TYPE;
	--substr(rtvmesg_mesg_desc,1,30) in c_message_text
    
    CURSOR c_report4_6 IS
        SELECT
        	rrrtmsg_aidy_code tmaidy,
        	rrrtmsg_treq_code treqcode,
        	rtvtreq_short_desc treqdesc, 
        	rrrtmsg_mesg_code tmesgcd,
        	substr(rtvmesg_mesg_desc,1,30) tmesgdesc
        FROM
        	rrrtmsg,
        	rtvtreq,
        	rtvmesg
        WHERE 
        	rrrtmsg_treq_code = rtvtreq_code and
        	rtvmesg_code = rrrtmsg_mesg_code and
        	rrrtmsg_aidy_code = v_aidy
        ORDER BY 
        	1, 2;

    --Report 4.7 Simple Tracking Rules
    c_rorgdat_grp_code rorgdat.rorgdat_grp_code%TYPE;
    c_rorgsql_sql_statement rorgsql.rorgsql_sql_statement%TYPE;
    c_rorgsql_activity_date rorgsql.rorgsql_activity_date%TYPE;
                
    CURSOR c_report4_7 IS
        SELECT 
        	rorgdat_grp_code grp,
        	rorgsql_sql_statement sql_state,
        	rorgsql_activity_date act_date
        FROM 
        	rorgsql, 
        	rorgdat 
        WHERE 
        	rorgsql_slct = rorgdat_slct 
        	and rorgdat_aidy_code = v_aidy
        	and rorgdat_type_ind = 'T'
        	and rorgdat_active_ind = 'Y'
        ORDER BY 
        	rorgdat_grp_code,
        	rorgsql_line_no;

    --Report 4.8 Expert Tracking Rules
    c_rorcmpl_sql_statement rorcmpl.rorcmpl_sql_statement%TYPE;
    c_rorcmpl_activity_date rorcmpl.rorcmpl_activity_date%TYPE;
    
    CURSOR c_report4_8 IS
        SELECT 
        	rorgdat_grp_code grp,
        	rorcmpl_sql_statement sql_statement,
        	rorcmpl_activity_date date_active
        	FROM 
        	rorcmpl, 
        	rorgdat 
        WHERE 
        	rorcmpl_slct = rorgdat_slct 
        	and rorgdat_aidy_code = v_aidy
        	and rorgdat_type_ind = 'T'
        	and rorgdat_active_ind = 'Y'
        ORDER BY 
        	rorgdat_grp_code;

    --Aid Year Budgeting Module status Selected into var in dump curors

    --Report 5.1 Budget Groups
    c_rtvbgrp_code rtvbgrp.rtvbgrp_code%TYPE;
	c_rtvbgrp_desc rtvbgrp.rtvbgrp_desc%TYPE;
	c_rtvbgrp_priority rtvbgrp.rtvbgrp_priority%TYPE;
	--rtvbgrp_active_ind in c_message_text
    
    CURSOR c_report5_1 IS
        SELECT
        	rtvbgrp_code bcode,
        	rtvbgrp_desc bdesc,
        	rtvbgrp_priority pri,
        	decode(nvl(rtvbgrp_active_ind,'N'),'N','NO','YES') act
        FROM
        	rtvbgrp
        ORDER BY
        	3,1;

    --Report 5.2 Budget Types
    c_rtvbtyp_code rtvbtyp.rtvbtyp_code%TYPE;
    c_rtvbtyp_desc rtvbtyp.rtvbtyp_desc%TYPE;
    c_rtvbtyp_default_tfc_ind rtvbtyp.rtvbtyp_default_tfc_ind%TYPE;
    c_rtvbtyp_camp_ind rtvbtyp.rtvbtyp_camp_ind%TYPE;
    c_rtvbtyp_pell_ind rtvbtyp.rtvbtyp_pell_ind%TYPE;
    c_rtvbtyp_inst_ind rtvbtyp.rtvbtyp_inst_ind%TYPE;
    c_rtvbtyp_stat_ind rtvbtyp.rtvbtyp_stat_ind%TYPE;
    c_rtvbtyp_othr_ind rtvbtyp.rtvbtyp_othr_ind%TYPE;
    
    CURSOR c_report5_2 IS
        SELECT
        	rtvbtyp_code btype,
        	rtvbtyp_desc btdesc,
        	rtvbtyp_default_tfc_ind btfc,
        	rtvbtyp_camp_ind bcamp,
        	rtvbtyp_pell_ind bpell,
        	rtvbtyp_inst_ind binst,
        	rtvbtyp_stat_ind bstat,
        	rtvbtyp_othr_ind bothr
        FROM
        	rtvbtyp
        ORDER BY
        	1;

    --Report 5.3 Budget Components
    c_rtvcomp_code rtvcomp.rtvcomp_code%TYPE;
    c_rtvcomp_desc rtvcomp.rtvcomp_desc%TYPE;
    
    CURSOR c_report5_3 IS
        SELECT
        	rtvcomp_code bcomp,
        	rtvcomp_desc bcdesc
        FROM
        	rtvcomp
        ORDER BY 
        	1;

    --Report 5.4 Simple Budget Rules Type B
    CURSOR c_report5_4 IS
        SELECT 
        	rorgdat_grp_code grp,
        	rorgsql_sql_statement sql_state,
        	rorgsql_activity_date act_date
        FROM 
        	rorgsql, 
        	rorgdat 
        WHERE 
        	rorgsql_slct = rorgdat_slct 
        	and rorgdat_aidy_code = v_aidy
        	and rorgdat_type_ind = 'B'
        	and rorgdat_active_ind = 'Y'
        ORDER BY 
        	rorgdat_grp_code,
        	rorgsql_line_no;

    --Report 5.5 Expert Budget Rules
    CURSOR c_report5_5 IS
        SELECT 
        	rorgdat_grp_code grp,
        	rorcmpl_sql_statement sql_statement,
        	rorcmpl_activity_date date_active
        FROM 
        	rorcmpl, 
        	rorgdat 
        WHERE 
        	rorcmpl_slct = rorgdat_slct 
        	and rorgdat_aidy_code = v_aidy
        	and rorgdat_type_ind = 'B'
        	and rorgdat_active_ind = 'Y'
        ORDER BY 
        	rorgdat_grp_code;

    --Period Budgeting Module status Selected into var in dump curors

    --Report 6.1 Period Budget Groups
    c_rtvpbgp_code rtvpbgp.rtvpbgp_code%TYPE;
    c_rtvpbgp_desc rtvpbgp.rtvpbgp_desc%TYPE;

    CURSOR c_report6_1 IS
        SELECT
        	rtvpbgp_code bcode,
        	rtvpbgp_desc bdesc,
        	decode(nvl(rtvpbgp_active_ind,'N'),'N','NO','YES') act
        FROM
        	rtvpbgp
        ORDER BY
        	1;

    --Report 6.2 Budget Types
    c_rtvpbtp_code rtvpbtp.rtvpbtp_code%TYPE;
	c_rtvpbtp_desc rtvpbtp.rtvpbtp_desc%TYPE;
	--rtvpbtp_active_ind in c_message_text
    
    CURSOR c_report6_2 IS
        SELECT
        	rtvpbtp_code pbtype,
        	rtvpbtp_desc btdesc,
        	decode(nvl(rtvpbtp_active_ind,'N'),'N','NO','YES') atv
        FROM
        	rtvpbtp
        ORDER BY
        	1;

    --prompt Running Report 6.3 Budget Components
    c_rtvpbcp_code rtvpbcp.rtvpbcp_code%TYPE;
    c_rtvpbcp_desc rtvpbcp.rtvpbcp_desc%TYPE;
    --rtvpbcp_active_ind is in c_message_text
    
    CURSOR c_report6_3 IS
        SELECT
        	rtvpbcp_code pbcp,
        	rtvpbcp_desc pbdesc,
        	decode(nvl(rtvpbcp_active_ind,'N'),'N','NO','YES') atvc
        FROM
        	rtvpbcp
        ORDER BY
        	1;

    --prompt Running Report 6.4 Budget Categories
    c_rtvbcat_code rtvbcat.rtvbcat_code%TYPE;
    c_rtvbcat_desc rtvbcat.rtvbcat_desc%TYPE;
    --rtvbcat_active_ind is in c_message_text
    
    CURSOR c_report6_4 IS
        SELECT
        	rtvbcat_code pcct,
        	rtvbcat_desc pcdesc,
        	decode(nvl(rtvbcat_active_ind,'N'),'N','NO','YES') ctvc
        FROM
        	rtvbcat
        ORDER BY
        	1;

    --Report 6.5 Period Budget Group Rules
    c_rbrpbgp_pbgp_code rbrpbgp.rbrpbgp_pbgp_code%TYPE;
    c_rbrpbgp_priority rbrpbgp.rbrpbgp_priority%TYPE;
    c_rbrpbgp_long_des rbrpbgp.rbrpbgp_long_desc%TYPE;
    
    CURSOR c_report6_5 IS
        SELECT
        	rbrpbgp_pbgp_code bgcode,
        	rbrpbgp_priority bgpri,
        	rbrpbgp_long_desc bgdesc
        FROM
        	rbrpbgp
        WHERE
        	rbrpbgp_aidy_code = v_aidy
        ORDER BY
        	2;

    --Report 6.6 Period Budget Type Rules
    c_rbrpbtp_pbtp_code rbrpbtp.rbrpbtp_pbtp_code%TYPE;
    c_rbrpbtp_pell_ind rbrpbtp.rbrpbtp_pell_ind%TYPE;
    c_rbrpbtp_efc_ind rbrpbtp.rbrpbtp_efc_ind%TYPE;
    c_rbrpbtp_long_desc rbrpbtp.rbrpbtp_long_desc%TYPE;
                
    CURSOR c_report6_6 IS
        SELECT
        	rbrpbtp_pbtp_code btpcode,
         	rbrpbtp_pell_ind btppell,
         	rbrpbtp_efc_ind btpefc,
         	rbrpbtp_long_desc btpdesc
        FROM
        	rbrpbtp
        WHERE
        	rbrpbtp_aidy_code = v_aidy
        ORDER BY
        	1;

    --Report 6.7 Period Budget Category Rules
    c_rbrbcat_bcat_code rbrbcat.rbrbcat_bcat_code%TYPE;
    c_rbrbcat_print_seq_no rbrbcat.rbrbcat_print_seq_no%TYPE;
    c_rbrbcat_long_desc rbrbcat.rbrbcat_long_desc%TYPE;
                
    CURSOR c_report6_7 IS
        SELECT
        	rbrbcat_bcat_code bctcode,
        	rbrbcat_print_seq_no bctpsn,
        	rbrbcat_long_desc bctdesc
        FROM
        	rbrbcat
        WHERE
        	rbrbcat_aidy_code = v_aidy
        ORDER BY
        	2;

    --Report 6.8 Period Budget Component Rules Part 1
    c_rbrpbcp_pbcp_code rbrpbcp.rbrpbcp_pbcp_code%TYPE;
    c_rbrpbcp_bcat_code rbrpbcp.rbrpbcp_bcat_code%TYPE; 
    c_rbrpbcp_default_ind rbrpbcp.rbrpbcp_default_ind%TYPE;
    c_rbrpbcp_pell_lt_half_ind rbrpbcp.rbrpbcp_pell_lt_half_ind%TYPE;
    c_rbrpbcp_direct_cost_ind rbrpbcp.rbrpbcp_direct_cost_ind%TYPE;
    c_rbrpbcp_long_desc rbrpbcp.rbrpbcp_long_desc%TYPE;
    
    CURSOR c_report6_8 IS
        SELECT
        	rbrpbcp_pbcp_code bcpcode,
        	rbrpbcp_bcat_code bcpccode,
        	rbrpbcp_default_ind bcpdlft,
        	rbrpbcp_pell_lt_half_ind bcpltht,
        	rbrpbcp_direct_cost_ind bcpdirect,
        	rbrpbcp_long_desc bcpdesc
        FROM
        	rbrpbcp
        WHERE
        	rbrpbcp_aidy_code = v_aidy
        ORDER BY
        	1;

    --Report 6.9 Period Budget Component Rules Part 2
    --c_rbrpbcp_pbcp_code already declared
    c_rbrpbcp_amt_dflt rbrpbcp.rbrpbcp_amt_dflt%TYPE;
    c_rbrpbcp_abrc_code_dflt rbrpbcp.rbrpbcp_abrc_code_dflt%TYPE;
    c_rbrpbcp_amt_pell_dflt rbrpbcp.rbrpbcp_amt_pell_dflt%TYPE;
    c_rbrpbcp_abrc_code_pell_dflt rbrpbcp.rbrpbcp_abrc_code_pell_dflt%TYPE;
    
    CURSOR c_report6_9 IS
        SELECT
        	rbrpbcp_pbcp_code bcpcode,
        	rbrpbcp_amt_dflt bcpadflt,
        	rbrpbcp_abrc_code_dflt bcpacode,
        	rbrpbcp_amt_pell_dflt bcppdflt,
        	rbrpbcp_abrc_code_pell_dflt bcppcode
        FROM
        	rbrpbcp
        WHERE
        	rbrpbcp_aidy_code = v_aidy
        ORDER BY
        	1;
    
    --Report 6.10 Period Budget Detail Rules
    c_rbrpbdr_pbgp_code rbrpbdr.rbrpbdr_pbgp_code%TYPE;
    c_rbrpbdr_pbtp_code rbrpbdr.rbrpbdr_pbtp_code%TYPE;
    c_rbrpbdr_period rbrpbdr.rbrpbdr_period%TYPE;
    c_rbrpbdr_pbcp_code rbrpbdr.rbrpbdr_pbcp_code%TYPE;
    c_rbrpbdr_amt rbrpbdr.rbrpbdr_amt%TYPE;
    c_rbrpbdr_abrc_code rbrpbdr.rbrpbdr_abrc_code%TYPE;
                
    CURSOR c_report6_10 IS
        SELECT
         	rbrpbdr_pbgp_code pbgrp,
         	rbrpbdr_pbtp_code pbtyp,
          	rbrpbdr_period pbprd,
         	rbrpbdr_pbcp_code pbcomp,
         	rbrpbdr_amt pbamt,    
         	rbrpbdr_abrc_code pbabrc
        FROM
        	rbrpbdr
        WHERE
        	rbrpbdr_aidy_code = v_aidy
        ORDER BY
         	rbrpbdr_pbgp_code,
         	rbrpbdr_pbtp_code,
          	rbrpbdr_period;

    --Report 6.11 Period Budget Group Aid Year Rules
    c_rbrpgpt_pbgp_code rbrpgpt.rbrpgpt_pbgp_code%TYPE;
    c_rbrpgpt_pbtp_code rbrpgpt.rbrpgpt_pbtp_code%TYPE;
                
    CURSOR c_report6_11 IS
        SELECT
        	rbrpgpt_pbgp_code pgcode, 
         	rbrpgpt_pbtp_code pgtype
        FROM
        	rbrpgpt
        WHERE
        	rbrpgpt_aidy_code = v_aidy
        ORDER BY
        	1;

    --Report 6.12 Pell Period Budget Group Aid Year Rules
    c_rbrpell_pbgp_code rbrpell.rbrpell_pbgp_code%TYPE;
    c_rbrpell_pbcp_code rbrpell.rbrpell_pbcp_code%TYPE;
    c_rbrpell_amt rbrpell.rbrpell_amt%TYPE;
    c_rbrpell_abrc_code rbrpell.rbrpell_abrc_code%TYPE;
    
    CURSOR c_report6_12 IS
        SELECT
         	rbrpell_pbgp_code plbgrp,
         	rbrpell_pbcp_code plbcomp,
         	rbrpell_amt plbamt,    
         	rbrpell_abrc_code plbabrc
        FROM
        	rbrpell
        WHERE
        	rbrpell_aidy_code = v_aidy
        ORDER BY
         	rbrpell_pbgp_code;

    --Report 6.13 Simple Period Budget Rules Type G
    CURSOR c_report6_13 IS
        SELECT 
        	rorgdat_grp_code grp,
        	rorgsql_sql_statement sql_state,
        	rorgsql_activity_date act_date
        FROM 
        	rorgsql, 
        	rorgdat 
        WHERE 
        	rorgsql_slct = rorgdat_slct 
        	and rorgdat_aidy_code = v_aidy
        	and rorgdat_type_ind = 'G'
        	and rorgdat_active_ind = 'Y'
        ORDER BY 
        	rorgdat_grp_code,
        	rorgsql_line_no;

    --Report 6.14 Expert Period Budget Rules Type G
    CURSOR c_report6_14 IS
        SELECT 
        	rorgdat_grp_code grp,
        	rorcmpl_sql_statement sql_statement,
        	rorcmpl_activity_date date_active
        FROM 
        	rorcmpl, 
        	rorgdat 
        WHERE 
        	rorcmpl_slct = rorgdat_slct 
        	and rorgdat_aidy_code = v_aidy
        	and rorgdat_type_ind = 'G'
        	and rorgdat_active_ind = 'Y'
        ORDER BY 
        	rorgdat_grp_code;

    --Report 7.1 Funds not set to Reduce Need or Replace EFC
    c_rfraspc_aidy_code rfraspc.rfraspc_aidy_code%TYPE;
    c_rfraspc_fund_code rfraspc.rfraspc_fund_code%TYPE;
    
    CURSOR c_report7_1 IS
        SELECT
        	rfraspc_aidy_code aidy,
        	rfraspc_fund_code fund
        FROM
        	rfraspc
        WHERE
        	nvl(rfraspc_replace_tfc_ind,'N') = 'N' and
        	nvl(rfraspc_reduce_need_ind,'N') = 'N' and
        	rfraspc_aidy_code = v_aidy;

    --Report 7.2 Active Funds with No Total Allocated Amount
    CURSOR c_report7_2 IS
        SELECT
        	rfraspc_aidy_code aidy,
        	rfraspc_fund_code fund
        FROM
        	rfraspc,
        	rfrbase
        WHERE
        	nvl(rfraspc_total_alloc_amt,0) = 0 and
        	nvl(rfrbase_active_ind,'N') = 'Y' and
        	rfraspc_fund_code = rfrbase_fund_code and
        	rfraspc_aidy_code = v_aidy;

    --Report 7.3 Active Funds with Total Allocated Greater Than Available to Offer Amount
    --c_rfraspc_aidy_code already declared
    --c_rfraspc_fund_code already declared
    c_rfraspc_total_alloc_amt rfraspc.rfraspc_total_alloc_amt%TYPE;
    c_rfraspc_avail_offer_amt rfraspc.rfraspc_avail_offer_amt%TYPE;
    
    CURSOR c_report7_3 IS
        SELECT
        	rfraspc_aidy_code aidy,
        	rfraspc_fund_code fund,
        	rfraspc_total_alloc_amt alloc,
        	rfraspc_avail_offer_amt avail
        FROM
        	rfraspc,
        	rfrbase
        WHERE
        	nvl(rfraspc_total_alloc_amt,0) > 0 and
        	nvl(rfraspc_total_alloc_amt,0) > nvl(rfraspc_avail_offer_amt,0) and
        	nvl(rfrbase_active_ind,'N') = 'Y' and
        	rfraspc_fund_code = rfrbase_fund_code and
        	rfraspc_aidy_code = v_aidy;

    --Report 7.4 Direct Loans without Loan Options record
    CURSOR c_report7_4 IS
        SELECT
            rfraspc_aidy_code aidy,
            rfraspc_fund_code fund,
            'No Record on RPRLOPT' mesg72
        FROM
            rfraspc
        WHERE
            rfraspc_aidy_code = v_aidy and
            rfraspc_direct_loan_ind in ('U','S','P','G') and
            not exists
                (select
                    'x'
                 from
                    rpblopt
                 where
                    rpblopt_fund_code = rfraspc_fund_code and
                    rpblopt_aidy_code = rfraspc_aidy_code);

    --Report 7.5 Funds with Accept Award Status not set to Accept
    --c_rfraspc_aidy_code already declared
    c_rfraspc_accept_awst_code rfraspc.rfraspc_accept_awst_code%TYPE;
    
    CURSOR c_report7_5 IS    
        SELECT
        	rfraspc_aidy_code,
        	rfraspc_accept_awst_code
        FROM
        	rfraspc
        WHERE
        	not exists
        		(select
        			'x'
        		from
        			rtvawst
        		where
        			rtvawst_code = rfraspc_accept_awst_code
        			and rtvawst_accept_ind = 'Y');

    --Report 7.6 Funds in RPRATRM not setup correctly
    c_rpratrm_fund_code rpratrm.rpratrm_fund_code%TYPE;
    
    CURSOR c_report7_6 IS 
        SELECT distinct
        	rpratrm_fund_code fund
        FROM
        	rpratrm
        WHERE	
        	rpratrm_aidy_code = v_aidy
        	and not exists
        		(select 
        			'x'
        		from
        			rfrbase,
        			rfraspc,
        			rfrdlck,
        			rtvftyp
        		where
        		 	rfrdlck_period(+) like '%'
        			and rfrdlck_fund_code (+) = rfraspc_fund_code
        			and rfrdlck_aidy_code (+) = rfraspc_aidy_code
        			and rfraspc_fund_code     = rfrbase_fund_code
        			and rfraspc_aidy_code     = v_aidy
        			and rfraspc_aidy_code	  = rpratrm_aidy_code
        			and rfrbase_fund_code     = rpratrm_fund_code
        			and rtvftyp_code          = rfrbase_ftyp_code)
        ORDER BY 1;

    --Report 7.7 Orphan Award Records
    c_rprawrd_pidm rprawrd.rprawrd_pidm%TYPE;
    c_rprawrd_aidy_code rprawrd.rprawrd_aidy_code%TYPE;
    
    CURSOR c_report7_7 IS
        SELECT
        	rprawrd_pidm spidm,
        	rprawrd_aidy_code aidy
        FROM
        	rprawrd
        WHERE
        	not exists
        		(select 'x' from spriden
        		where rprawrd_pidm = spriden_pidm
        		);

    --Report 8.1 Packaging Group Review
    c_rprgfnd_aidy_code rprgfnd.rprgfnd_aidy_code%TYPE;
    c_rprgfnd_pgrp_code rprgfnd.rprgfnd_pgrp_code%TYPE;
    c_rprgfnd_fund_code rprgfnd.rprgfnd_fund_code%TYPE;
    c_rprgfnd_priority rprgfnd.rprgfnd_priority%TYPE;
    c_rprgfnd_min_award rprgfnd.rprgfnd_min_award%TYPE;
    c_rprgfnd_max_award rprgfnd.rprgfnd_max_award%TYPE;
    c_rprgfnd_unmet_need_pct rprgfnd.rprgfnd_unmet_need_pct%TYPE;
    c_rprgfnd_tfc_ind rprgfnd.rprgfnd_tfc_ind%TYPE;
    c_rprgfnd_algr_code rprgfnd.rprgfnd_algr_code%TYPE;
                
    CURSOR c_report8_1 IS    
        SELECT 
        	rprgfnd_aidy_code aidy,
        	rprgfnd_pgrp_code pgrp,
        	rprgfnd_fund_code fund,
        	rprgfnd_priority prty,
        	rprgfnd_min_award mina,
        	rprgfnd_max_award maxa,
        	rprgfnd_unmet_need_pct pct,
        	rprgfnd_tfc_ind ind,
        	rprgfnd_algr_code alg
        FROM 
        	rprgfnd
        WHERE 
        	rprgfnd_aidy_code = v_aidy
        ORDER BY 
        	rprgfnd_pgrp_code, 
        	rprgfnd_priority;

    --Report 8.2 Simple Packaging Rules
    CURSOR c_report8_2 IS
        SELECT 
        	rorgdat_grp_code grp,
        	rorgsql_sql_statement sql_state,
        	rorgsql_activity_date act_date
        FROM 
        	rorgsql, 
        	rorgdat 
        WHERE 
        	rorgsql_slct = rorgdat_slct 
        	and rorgdat_aidy_code = v_aidy
        	and rorgdat_type_ind = 'P'
        	and rorgdat_active_ind = 'Y'
        ORDER BY 
        	rorgsql_slct,
        	rorgsql_line_no;

    --Report 8.3 Expert Packaging Rules
    CURSOR c_report8_3 IS
        SELECT 
        	rorgdat_grp_code grp,
        	rorcmpl_sql_statement sql_statement,
        	rorcmpl_activity_date date_active
        FROM 
        	rorcmpl, 
        	rorgdat 
        WHERE 
        	rorcmpl_slct = rorgdat_slct 
        	and rorgdat_aidy_code = v_aidy
        	and rorgdat_type_ind = 'B'
        	and rorgdat_active_ind = 'Y'
        ORDER BY 
        	rorgdat_grp_code, rorcmpl_slct;

BEGIN <<main>>
    --Open File
    utl_file.fgetattr(f_dir_OUT,f_name_OUT,f_exists_OUT,f_size_OUT,f_block_size_OUT);
    IF f_exists_OUT THEN
        utl_file.fremove(f_dir_OUT,f_name_OUT);
    END IF;
    f_dat_file_OUT := utl_file.fopen(f_dir_OUT,f_name_OUT,'W');
    
    --Dump Cursors
    --Report headers
    utl_file.put_line(f_dat_file_OUT,'FinAid: New Year Script',FALSE);
    utl_file.put_line(f_dat_file_OUT,'Run Time: '||to_char(sysdate,'DD-MON-YYYY HH24:MI'),FALSE);
    utl_file.put_line(f_dat_file_OUT,':',FALSE);
    utl_file.put_line(f_dat_file_OUT,'Aid Year Entered:        '||v_aidy,FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Common Functions Module',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    
    --Section Header 1.1
    utl_file.put_line(f_dat_file_OUT,'Report 1.1 - Missing Default Aid Period ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report1_1;
    LOOP
        FETCH c_report1_1 
            INTO c_robinst_aidy_code;
        EXIT WHEN c_report1_1%notfound;
        f_line_OUT := c_robinst_aidy_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_1;    
    
   --Section Header 1.2
    utl_file.put_line(f_dat_file_OUT,'Report 1.2 - Missing Default Term Code ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_2;
    LOOP
        FETCH c_report1_2
            INTO c_robinst_aidy_code;
        EXIT WHEN c_report1_2%notfound;
        f_line_OUT := c_robinst_aidy_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_2;

   --Section Header 1.3
    utl_file.put_line(f_dat_file_OUT,'Report 1.3 - Missing Campus OPEID ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Year',10) || RPAD('Campus Code',12) || 'Message';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_3;
    LOOP
        FETCH c_report1_3
            INTO c_rorcamp_aidy_code 
                ,c_rorcamp_camp_code
                ,c_message_text;
        EXIT WHEN c_report1_3%notfound;
        f_line_OUT := RPAD(c_rorcamp_aidy_code,10) || RPAD(c_rorcamp_camp_code,12) || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_3;

   --Section Header 1.4
    utl_file.put_line(f_dat_file_OUT,'Report 1.4 - Missing Pell Fund code ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' Identifies Aid Year and Campus Code missing Pell Fund Code on ROAUSIO',FALSE);
    utl_file.put_line(f_dat_file_OUT,' Campus Codes that represent graduate or non-Pell eligible programs/majors should not have the Pell fund code',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Campus Code',12) || RPAD('Aid Year',10);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_4;
    LOOP
        FETCH c_report1_4
            INTO c_rorcamp_camp_code
                ,c_rorcamp_aidy_code;
        EXIT WHEN c_report1_4%notfound;
        f_line_OUT := RPAD(c_rorcamp_camp_code,12) || RPAD(c_rorcamp_aidy_code,10);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_4;
    
   --Section Header 1.5
    utl_file.put_line(f_dat_file_OUT,'Report 1.5 - EDE Corrections Logging ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' Identifies Aid Year where EDE Correction Logging on ROAUSIO Grant and EDE Options tab is not checked',FALSE);
    utl_file.put_line(f_dat_file_OUT,' Turn on when processing EDE corrections in Banner to log with RLRLOGG and extract with REBCDxx',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Year',10) || 'Message';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_5;
    LOOP
        FETCH c_report1_5
            INTO c_robinst_aidy_code
                ,c_message_text;
        EXIT WHEN c_report1_5%notfound;
        f_line_OUT := RPAD(c_robinst_aidy_code,10) || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_5;
    
   --Section Header 1.6
    utl_file.put_line(f_dat_file_OUT,'Report 1.6 - ROAINST Credit Hours Setup ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' Identifies Level Codes on the ROAINST Credit Hours tab that do not exist in RORACYR for the Aid Year',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Level',6) || RPAD('Message',38) || 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_6;
    LOOP
        FETCH c_report1_6
            INTO c_rorcrhr_levl_code
                ,c_message_text
                ,c_message_text2; --rorcrhr_levl_code ||' Aid Year'
        EXIT WHEN c_report1_6%notfound;
        f_line_OUT := RPAD(c_robinst_aidy_code,10) || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_6;

   --Section Header 1.7
    utl_file.put_line(f_dat_file_OUT,'Report 1.7 - ROAINST Credit Hours Setup ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' Identifies Terms from STVTERM set to the Financial Aid Process Year that do not exist in the ROAINST Credit Hours tab',FALSE); 
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Term',7) || RPAD('Message',60) || 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);    

    OPEN c_report1_7;
    LOOP
        FETCH c_report1_7
            INTO c_stvterm_code
                ,c_message_text
                ,c_message_text2; --robinst_aidy_code ||' Aid Year'
        EXIT WHEN c_report1_7%notfound;
        f_line_OUT := RPAD(c_stvterm_code,7) || RPAD(c_message_text,60) || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_7;

   --Section Header 1.8
    utl_file.put_line(f_dat_file_OUT,'Report 1.8 - ROAINST Default Aid Period Algo Rule ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' Identifies the ROAINST Aid Year Code when a Default APRD Algo Rule is active for the same year in RORALGO',FALSE); 
    utl_file.put_line(f_dat_file_OUT,' Determine if you want to populate the Default Aid Period Rule Code prior to loading EDE/ISIR, CSS records',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Year',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);    

    OPEN c_report1_8;
    LOOP
        FETCH c_report1_8
            INTO c_robinst_aidy_code
                ,c_message_text
                ,c_roralgo_process
                ,c_message_text2 --robinst_aidy_code ||' Aid Year'
                ,c_roralgo_algo_code;
        EXIT WHEN c_report1_8%notfound;
        f_line_OUT := RPAD(c_robinst_aidy_code,8) 
                   || RPAD(c_message_text,70) 
                   || RPAD(c_roralgo_process,12)
                   || RPAD(c_message_text2,20)
                   || c_roralgo_algo_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_8;
    
   --Section Header 1.9
    utl_file.put_line(f_dat_file_OUT,'Report 1.9 - Enrollment Cut Off Dates ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' Identifies Periods in ROAINST Credit Hours tab that do not exist in RPROPTS Enrollment Cut Off Rules Page for the Aid Year',FALSE); 
    utl_file.put_line(f_dat_file_OUT,' Clients who records returned with this query should also review the RPROPTS Grant Options Setup for completion prior to processing',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Period',8) || RPAD('Message',91) || 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);    
    
    OPEN c_report1_9;
    LOOP
        FETCH c_report1_9
            INTO c_rorcrhr_period
                ,c_message_text
                ,c_message_text2; --rorcrhr_aidy_code ||' Aid Year' aidy
        EXIT WHEN c_report1_9%notfound;
        f_line_OUT := RPAD(c_rorcrhr_period,8) 
                   || RPAD(c_message_text,91) 
                   || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_9;

   --Section Header 1.10
    utl_file.put_line(f_dat_file_OUT,'Report 1.10 - RORTPRD Default Aid Period on ROAINST Build Periods ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' Identifies a Default Aid Period in ROAINST that does not have periods associated with it RORTPRD',FALSE); 
    utl_file.put_line(f_dat_file_OUT,' Prior to loading records, run this script to determine if the default aid period has been setup in RORTPRD',FALSE);
    utl_file.put_line(f_dat_file_OUT,' If it has not been setup prior to loading records, then RORPRST will not be populated with the expected period information defaults from ROAINST',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Period Default',55) || 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);   

    OPEN c_report1_10;
    LOOP
        FETCH c_report1_10
            INTO c_robinst_aprd_code_def
                ,c_message_text
                ,c_robinst_aidy_code
                ,c_message_text2; --rorcrhr_aidy_code ||' Aid Year' aidy
        EXIT WHEN c_report1_10%notfound;
        f_line_OUT := RPAD(COALESCE(c_robinst_aprd_code_def,' '),8) 
                   || RPAD(c_message_text,47) 
                   || RPAD(COALESCE(c_robinst_aidy_code,' '),8)
                   || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_10;

   --Section Header 1.11
    utl_file.put_line(f_dat_file_OUT,'Report 1.11 - Algo Rules Active not Validated ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' Identifies Active Algo rules in RORALGO that have not been validated',FALSE); 
    utl_file.put_line(f_dat_file_OUT,' Prior to Packaging, run this script to identify any algorithmic rules that are active but not validated',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Process Type',26) 
               || RPAD('Batch Posting Type',24)
               || RPAD('Rule Code',20)
               || RPAD('Aid Year',18)
               || RPAD('Sequence',15)
               || 'Message';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  

    OPEN c_report1_11;
    LOOP
        FETCH c_report1_11
            INTO c_roralgo_process
                ,c_roralgo_ptyp_code
                ,c_roralgo_algo_code
                ,c_roralgo_aidy_code
                ,c_roralgo_seq_no
                ,c_message_text;
        EXIT WHEN c_report1_11%notfound;
        f_line_OUT := RPAD(c_roralgo_process,26) 
                   || RPAD(c_roralgo_ptyp_code,24) 
                   || RPAD(c_roralgo_algo_code,20)
                   || RPAD(c_roralgo_aidy_code,18)
                   || RPAD(c_roralgo_seq_no,15)
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_11;

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Data Management Module',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    
   --Section Header 2.1
    utl_file.put_line(f_dat_file_OUT,'Report 2.1 - Review Data Sources Rules RCRDTSR for Aid Year ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('INFC Code',30) 
               || RPAD('Common Matching Code',20)
               || RPAD('Parameter Set',15)
               || RPAD('User Id',15)
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  
    
    OPEN c_report2_1;
    LOOP
        FETCH c_report2_1
            INTO c_rcrinfr_infc_code
                ,c_rcrinfr_cmsc_code
                ,c_rcrinfr_parameter_set
                ,c_rcrinfr_user_id 
                ,c_rcrinfr_activity_date;
        EXIT WHEN c_report2_1%notfound;
        f_line_OUT := RPAD(c_rcrinfr_infc_code,30) 
                   || RPAD(c_rcrinfr_cmsc_code,20) 
                   || RPAD(c_rcrinfr_parameter_set,15)
                   || RPAD(c_rcrinfr_user_id,15)
                   || c_rcrinfr_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report2_1;

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Need Analysis Module',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);

   --Section Header 3.1
    utl_file.put_line(f_dat_file_OUT,'Report 3.1 - Review of RPRCLSS ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Student',8) 
               || RPAD('Student',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  
    f_line_OUT := RPAD('System',8) 
               || RPAD('System',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  
    f_line_OUT := RPAD('Level',8) 
               || RPAD('Class',8)
               || 'Financial Aid Class';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  

    OPEN c_report3_1;
    LOOP
        FETCH c_report3_1
            INTO c_rprclss_levl_code
                ,c_rprclss_clas_code
                ,c_message_text;
        EXIT WHEN c_report3_1%notfound;
        f_line_OUT := RPAD(c_rprclss_levl_code,8) 
                   || RPAD(c_rprclss_clas_code,8) 
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_1;

   --Section Header 3.2
    utl_file.put_line(f_dat_file_OUT,'Report 3.2 - Aid Periods Review ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',6) 
               || RPAD(' ',6)
               || RPAD('Full',7)
               || RPAD('Pell',7)
               || RPAD('Grant',7)
               || RPAD('FM',3)
               || RPAD('IM',4);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  
    f_line_OUT := RPAD('Aid',6) 
               || RPAD('Aid',6)
               || RPAD('Year',7)
               || RPAD('Year',7)
               || RPAD('Year',7)
               || RPAD('Bud',3)
               || RPAD('Bud',4);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  
    f_line_OUT := RPAD('Year',6) 
               || RPAD('Period',6)
               || RPAD('Pct',7)
               || RPAD('Pct',7)
               || RPAD('Pct',7)
               || RPAD('Dur',3)
               || RPAD('Dur',4)
               || 'SAY Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report3_2;
    LOOP
        FETCH c_report3_2
            INTO c_robaprd_aidy_code
                ,c_robaprd_aprd_code
                ,c_robaprd_full_yr_pct
                ,c_robaprd_pell_full_yr_pct
                ,c_robaprd_grant_full_yr_pct
                ,c_robaprd_budg_dur_fm
                ,c_robaprd_budg_dur_im
                ,c_robaprd_sayr_code;
        EXIT WHEN c_report3_2%notfound;
        f_line_OUT := RPAD(c_robaprd_aidy_code,6) 
                   || RPAD(c_robaprd_aprd_code,6)
                   || RPAD(c_robaprd_full_yr_pct,7)
                   || RPAD(c_robaprd_pell_full_yr_pct,7)
                   || RPAD(c_robaprd_grant_full_yr_pct,7)
                   || RPAD(c_robaprd_budg_dur_fm,3)
                   || RPAD(c_robaprd_budg_dur_im,4)
                   || c_robaprd_sayr_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_2;

   --Section Header 3.3
    utl_file.put_line(f_dat_file_OUT,'Report 3.3 - Aid Periods Missing Setup ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',8) 
               || 'Comments';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report3_3;
    LOOP
        FETCH c_report3_3
            INTO c_robaprd_aprd_code
                ,c_message_text;
        EXIT WHEN c_report3_3%notfound;
        f_line_OUT := RPAD(c_robaprd_aprd_code,8)
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_3;

   --Section Header 3.4
    utl_file.put_line(f_dat_file_OUT,'Report 3.4 - Aid Period Set Up on RORTPRD ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8)
               || RPAD(' ',8)
               || RPAD('Start',10)
               || 'End';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',8)
               || RPAD('Period',8)
               || RPAD('Date',10)
               || 'Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report3_4;
    LOOP
        FETCH c_report3_4
            INTO c_rortprd_aprd_code
                ,c_rortprd_period
                ,c_rortprd_start_date
                ,c_rortprd_end_date;
        EXIT WHEN c_report3_4%notfound;
        f_line_OUT := RPAD(c_rortprd_aprd_code,8)
                   || RPAD(c_rortprd_period,8)
                   || RPAD(c_rortprd_start_date,10)
                   || c_rortprd_end_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_4;

   --Section Header 3.5
    utl_file.put_line(f_dat_file_OUT,'Report 3.5 - Aid Periods not Setup ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',8)
               || 'Comments';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);    

    OPEN c_report3_5;
    LOOP
        FETCH c_report3_5
            INTO c_robaprd_aprd_code
                ,c_message_text;
        EXIT WHEN c_report3_5%notfound;
    f_line_OUT := RPAD(c_robaprd_aprd_code,8)
               || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_5;

   --Section Header 3.6
    utl_file.put_line(f_dat_file_OUT,'Report 3.6 - Award and Pell Grant Percent RFRDEFA Review ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',8)
               || RPAD(' ',8)
               || RPAD(' ',8)
               || RPAD('Pell',8)
               || 'Memo';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid',8)
               || RPAD(' ',8)
               || RPAD('Award',8)
               || RPAD('Grant',8)
               || 'Exp';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  
    f_line_OUT := RPAD('Period',8)
               || RPAD('Period',8)
               || RPAD('Percent',8)
               || RPAD('Percent',8)
               || 'Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  

    OPEN c_report3_6;
    LOOP
        FETCH c_report3_6
            INTO c_rfrdefa_aprd_code
                ,c_rfrdefa_period
                ,c_rfrdefa_award_pct
                ,c_rfrdefa_pell_award_pct
                ,c_rfrdefa_memo_exp_date;
        EXIT WHEN c_report3_6%notfound;
        f_line_OUT := RPAD(c_rfrdefa_aprd_code,8)
                   || RPAD(c_rfrdefa_period,8)
                   || RPAD(c_rfrdefa_award_pct,8)
                   || RPAD(c_rfrdefa_pell_award_pct,8)
                   || RPAD(c_rfrdefa_memo_exp_date,8);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_6;

   --Section Header 3.7
    utl_file.put_line(f_dat_file_OUT,'Report 3.7 - Aid Periods Missing Grant Pct on RFRDEFA ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report3_7;
    LOOP
        FETCH c_report3_7
            INTO c_robaprd_aprd_code;
        EXIT WHEN c_report3_7%notfound;
        f_line_OUT := RPAD(c_robaprd_aprd_code,8);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_7;
    
   --Section Header 3.8
    utl_file.put_line(f_dat_file_OUT,'Report 3.8 - Aid Periods with no Memo Expiration Date ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',8) 
               || 'Period';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report3_8;
    LOOP
        FETCH c_report3_8
            INTO c_rfrdefa_aprd_code 
                ,c_rfrdefa_period;
        EXIT WHEN c_report3_8%notfound;
        f_line_OUT := RPAD(c_rfrdefa_aprd_code ,8)
                   || c_rfrdefa_period;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE); 
    CLOSE c_report3_8;

   --Section Header 3.9
    utl_file.put_line(f_dat_file_OUT,'Report 3.9 - Aid Periods with Memo Date outside Aid Year ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',7)
               || RPAD('Term Code',10)
               || 'Memo Exp Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report3_9;
    LOOP
        FETCH c_report3_9
            INTO c_rfrdefa_aprd_code
                ,c_rfrdefa_term_code
                ,c_rfrdefa_memo_exp_date;
        EXIT WHEN c_report3_9%notfound;
        f_line_OUT := RPAD(c_rfrdefa_aprd_code,8)
                   || RPAD(c_rfrdefa_term_code,7)
                   || c_rfrdefa_memo_exp_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_9;

   --Section Header 3.10
    utl_file.put_line(f_dat_file_OUT,'Report 3.10 - Disbursement Dates and Percent RFRDEFA Review ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8)
               || RPAD(' ',8)
               || RPAD('Disburse',10)
               || RPAD('Disburse',10);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',8)
               || RPAD('Period',8)
               || RPAD('Date',10)
               || RPAD('Percent',10);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report3_10;
    LOOP
        FETCH c_report3_10
            INTO c_rfrdefd_aprd_code
                ,c_rfrdefd_period
                ,c_rfrdefd_disburse_date
                ,c_rfrdefd_disburse_pct;
        EXIT WHEN c_report3_10%notfound;
        f_line_OUT := RPAD(c_rfrdefd_aprd_code,8)
                   || RPAD(c_rfrdefd_period,8)
                   || RPAD(c_rfrdefd_disburse_date,10)
                   || c_rfrdefd_disburse_pct;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_10;

   --Section Header 3.11
    utl_file.put_line(f_dat_file_OUT,'Report 3.11 - Aid Periods with no Disbursement Schedule ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Aid Period';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report3_11;
    LOOP
        FETCH c_report3_11
            INTO c_rfrdefa_aprd_code;
        EXIT WHEN c_report3_11%notfound;
        f_line_OUT := c_rfrdefa_aprd_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_11;

   --Section Header 3.12
    utl_file.put_line(f_dat_file_OUT,'Report 3.12 - Aid Periods Disbursement Dates outside Aid Year ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',7)
               || RPAD('Term Code',10)
               || 'Disburse Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report3_12;
    LOOP
        FETCH c_report3_12
            INTO c_rfrdefd_aprd_code
                ,c_rfrdefd_term_code
                ,c_rfrdefd_disburse_date;
        EXIT WHEN c_report3_12%notfound;
        f_line_OUT := RPAD(c_rfrdefd_aprd_code,7)
                   || RPAD(c_rfrdefd_term_code,10)
                   || c_rfrdefd_disburse_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_12;

   --Section Header 3.13
    utl_file.put_line(f_dat_file_OUT,'Report 3.13 - Aid Periods Disbursement to Reschedule ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',8)
               || 'Term Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report3_13;
    LOOP
        FETCH c_report3_13
            INTO c_rfrdefd_aprd_code
                ,c_rfrdefd_term_code;
        EXIT WHEN c_report3_13%notfound;
        f_line_OUT := RPAD(c_rfrdefd_aprd_code,8)
                   || c_rfrdefd_term_code;
            utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_13;
    
   --Section Header 3.14
    utl_file.put_line(f_dat_file_OUT,'Report 3.14 - Aid Periods with no Loan Period ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Aid Period';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report3_14;
    LOOP
        FETCH c_report3_14
            INTO c_robaprd_aprd_code;
        EXIT WHEN c_report3_14%notfound;
    f_line_OUT := c_robaprd_aprd_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report3_14;
   
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Requirements Tracking Module',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    
   --Section Header 4.1
    utl_file.put_line(f_dat_file_OUT,'Report 4.1 - Tracking Requirement Codes ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Track',8)
               || 'Track';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Req',8)
               || RPAD('Short',21)
               || RPAD('Once',5)
               || RPAD('Pckg',5)
               || RPAD('Disb',5)
               || 'Memo';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',8)
               || RPAD('Desc',21)
               || RPAD('Ind',5)
               || RPAD('Ind',5)
               || RPAD('Ind',5)
               || 'Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report4_1;
    LOOP
        FETCH c_report4_1
            INTO c_rtvtreq_code
                ,c_rtvtreq_short_desc
                ,c_rtvtreq_once_ind
                ,c_rtvtreq_pckg_ind
                ,c_rtvtreq_disb_ind
                ,c_rtvtreq_memo_ind;
        EXIT WHEN c_report4_1%notfound;
        f_line_OUT := RPAD(c_rtvtreq_code,8)
                   || RPAD(c_rtvtreq_short_desc,21)
                   || RPAD(c_rtvtreq_once_ind,5)
                   || RPAD(c_rtvtreq_pckg_ind,5)
                   || RPAD(c_rtvtreq_disb_ind,5)
                   || c_rtvtreq_memo_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report4_1;

   --Section Header 4.2
    utl_file.put_line(f_dat_file_OUT,'Report 4.2 - Tracking Requirement Codes Descriptions ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Track',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Req',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Codes',7) 
               || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report4_2;
    LOOP
        FETCH c_report4_2
            INTO c_rtvtreq_code
                ,c_rtvtreq_long_desc;
        EXIT WHEN c_report4_2%notfound;
    f_line_OUT := RPAD(c_rtvtreq_code,7)
               || c_rtvtreq_long_desc;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report4_2;

   --Section Header 4.3
    utl_file.put_line(f_dat_file_OUT,'Report 4.3 - Tracking Status Codes ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Tracking',9)
                || RPAD(' ',31)
                || RPAD(' ',4)
                || 'Trk';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Status',9)
                || RPAD(' ',31)
                || RPAD('Sat',4)
                || 'Ltr';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Codes',9)
                || RPAD('Description',31)
                || RPAD('Ind',4)
                || 'Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report4_3;
    LOOP
        FETCH c_report4_3
            INTO c_rtvtrst_code 
                ,c_rtvtrst_desc 
                ,c_rtvtrst_sat_ind 
                ,c_rtvtrst_trk_ltr_ind;
        EXIT WHEN c_report4_3%notfound;
        f_line_OUT := RPAD(c_rtvtrst_code,9)
                    || RPAD(c_rtvtrst_desc,31)
                    || RPAD(c_rtvtrst_sat_ind,4)
                    || c_rtvtrst_trk_ltr_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report4_3;

   --Section Header 4.4
    utl_file.put_line(f_dat_file_OUT,'Report 4.4 - Tracking Req and Group Associations ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',5)
                || RPAD('Trking',9)
                || RPAD('Group',30)
                || RPAD('Rgmt',6)
                || 'Requirement';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',5)
                || RPAD('Group',9)
                || RPAD('Description',30)
                || RPAD('Code',6)
                || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report4_4;
    LOOP
        FETCH c_report4_4
            INTO c_rrrgreq_aidy_code
                ,c_rrrgreq_tgrp_code
                ,c_rtvtgrp_desc
                ,c_rrrgreq_treq_code
                ,c_rtvtreq_short_desc;
        EXIT WHEN c_report4_4%notfound;
        f_line_OUT := RPAD(c_rrrgreq_aidy_code,5)
                    || RPAD(c_rrrgreq_tgrp_code,9)
                    || RPAD(c_rtvtgrp_desc,30)
                    || RPAD(c_rrrgreq_treq_code,6)
                    || c_rtvtreq_short_desc;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report4_4;
    
   --Section Header 4.5
    utl_file.put_line(f_dat_file_OUT,'Report 4.5 - Tracking Groups with no Requirements ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Tracking',10);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Group',10) 
               || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report4_5;
    LOOP
        FETCH c_report4_5
            INTO c_rtvtgrp_code
                ,c_rtvtgrp_desc;
        EXIT WHEN c_report4_5%notfound;
    f_line_OUT := RPAD(c_rtvtgrp_code,10)
               || c_rtvtgrp_desc;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report4_5;

   --Section Header 4.6
    utl_file.put_line(f_dat_file_OUT,'Report 4.6 - Tracking Requirements and Messages Associated ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',5)
                || RPAD('Rgmt',7)
                || RPAD('Rgmt',20)
                || RPAD('Mesg',6)
                || 'Message';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',5)
                || RPAD('Code',7)
                || RPAD('Description',20)
                || RPAD('Code',6)
                || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report4_6;
    LOOP
        FETCH c_report4_6
            INTO c_rrrtmsg_aidy_code
                ,c_rrrtmsg_treq_code
                ,c_rtvtreq_short_desc
                ,c_rrrtmsg_mesg_code 
                ,c_message_text;
        EXIT WHEN c_report4_6%notfound;
        f_line_OUT := RPAD(c_rrrtmsg_aidy_code,5)
                    || RPAD(c_rrrtmsg_treq_code,7)
                    || RPAD(c_rtvtreq_short_desc,20)
                    || RPAD(c_rrrtmsg_mesg_code ,6)
                    || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report4_6;

   --Section Header 4.7
    utl_file.put_line(f_dat_file_OUT,'Report 4.7 - Simple Tracking Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Group',6) 
               || RPAD('Simple Statement',78) 
               || 'Activity Dates';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report4_7;
    LOOP
        FETCH c_report4_7
            INTO c_rorgdat_grp_code
                ,c_rorgsql_sql_statement
                ,c_rorgsql_activity_date;
        EXIT WHEN c_report4_7%notfound;
        f_line_OUT := RPAD(c_rorgdat_grp_code,6) 
                   || RPAD(c_rorgsql_sql_statement,78) 
                   || c_rorgsql_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report4_7;

   --Section Header 4.8
    utl_file.put_line(f_dat_file_OUT,'Report 4.8 - Expert Tracking Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Group',6) 
               || RPAD('Statement',110) 
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report4_8;
    LOOP
        FETCH c_report4_8
            INTO c_rorgdat_grp_code
                ,c_rorcmpl_sql_statement 
                ,c_rorcmpl_activity_date;
        EXIT WHEN c_report4_8%notfound;
        f_line_OUT := RPAD(c_rorgdat_grp_code,6) 
                    || RPAD(c_rorcmpl_sql_statement,110) 
                    || c_rorcmpl_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE); 
    CLOSE c_report4_8;

--section 5

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Aid Year Budgeting Module',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
   
    SELECT
        decode(robinst_period_budget_enabled,
                'Y','AID YEAR BUDGETING IS NOT BEING USED',
                    'AID YEAR BUDGETING IS BEING USED') Status
    INTO
        v_aidy_budgeting_status
    FROM
        robinst
    WHERE
        robinst_aidy_code = v_aidy;
    utl_file.put_line(f_dat_file_OUT,v_aidy_budgeting_status,FALSE);
    utl_file.put_line(f_dat_file_OUT,' ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'Run RBRBCMP from GJAPCTL to review Aid Year Budget Set Up ',FALSE);
    utl_file.put_line(f_dat_file_OUT,' ',FALSE);

   --Section Header 5.1
    utl_file.put_line(f_dat_file_OUT,'Report 5.1 - Budget Groups ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Budget',9);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Group',9) 
               || RPAD('Description',31) 
               || RPAD('Priority',9) 
               || 'Active?';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report5_1;
    LOOP
        FETCH c_report5_1
            INTO c_rtvbgrp_code
                ,c_rtvbgrp_desc
                ,c_rtvbgrp_priority
                ,c_message_text;
        EXIT WHEN c_report5_1%notfound;
        f_line_OUT := RPAD(c_rtvbgrp_code,9) 
                    || RPAD(c_rtvbgrp_desc,31) 
                    || RPAD(c_rtvbgrp_priority,9)
                    || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report5_1;

   --Section Header 5.2
    utl_file.put_line(f_dat_file_OUT,'Report 5.2 - Budget Types ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Budget',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Type',7) 
               || RPAD(' ',30)
               || RPAD('TFC',4)
               || RPAD('Camp',5)
               || RPAD('Pell',5)
               || RPAD('Inst',5)
               || RPAD('State',6)
               || 'Other';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',7) 
               || RPAD('Description',30)
               || RPAD('Ind',4)
               || RPAD('Ind',5)
               || RPAD('Ind',5)
               || RPAD('Ind',5)
               || RPAD('Ind',6)
               || 'Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report5_2;
    LOOP
        FETCH c_report5_2
            INTO c_rtvbtyp_code
                ,c_rtvbtyp_desc
                ,c_rtvbtyp_default_tfc_ind
                ,c_rtvbtyp_camp_ind
                ,c_rtvbtyp_pell_ind
                ,c_rtvbtyp_inst_ind
                ,c_rtvbtyp_stat_ind
                ,c_rtvbtyp_othr_ind;
        EXIT WHEN c_report5_2%notfound;
        f_line_OUT := RPAD(c_rtvbtyp_code,7) 
                   || RPAD(c_rtvbtyp_desc,30)
                   || RPAD(c_rtvbtyp_default_tfc_ind,4)
                   || RPAD(c_rtvbtyp_camp_ind,5)
                   || RPAD(c_rtvbtyp_pell_ind,5)
                   || RPAD(c_rtvbtyp_inst_ind,5)
                   || RPAD(c_rtvbtyp_stat_ind,6)
                   || c_rtvbtyp_othr_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report5_2;

   --Section Header 5.3
    utl_file.put_line(f_dat_file_OUT,'Report 5.3 - Budget Components ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Budget';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Component',10) 
               || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report5_3;
    LOOP
        FETCH c_report5_3
            INTO c_rtvcomp_code
                ,c_rtvcomp_desc;
        EXIT WHEN c_report5_3%notfound;
        f_line_OUT := RPAD(c_rtvcomp_code,10) 
                    || c_rtvcomp_desc;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report5_3;

   --Section Header 5.4
    utl_file.put_line(f_dat_file_OUT,'Report 5.4 - Simple Budget Rules Type B ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Group',6) 
               || RPAD('Simple Statement',78)  
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report5_4;
    LOOP
        FETCH c_report5_4
            INTO c_rorgdat_grp_code
                ,c_rorgsql_sql_statement
                ,c_rorgsql_activity_date;
        EXIT WHEN c_report5_4%notfound;
        f_line_OUT := RPAD(c_rorgdat_grp_code,6) 
                    || RPAD(c_rorgsql_sql_statement,78)  
                    || c_rorgsql_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report5_4;

   --Section Header 5.5
    utl_file.put_line(f_dat_file_OUT,'Report 5.5 - Expert Budget Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Group',6) 
               || RPAD('Statememt',110) 
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report5_5;
    LOOP
        FETCH c_report5_5
            INTO c_rorgdat_grp_code
                ,c_rorcmpl_sql_statement
                ,c_rorcmpl_activity_date;
        EXIT WHEN c_report5_5%notfound;
        f_line_OUT := RPAD(c_rorgdat_grp_code,6) 
                   || RPAD(c_rorcmpl_sql_statement,110) 
                   || c_rorcmpl_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report5_5;

--section 6

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Period Budgeting Module',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
  
    SELECT
    	decode(robinst_period_budget_enabled,
                'Y','PERIOD BUDGETING IS ENABLED On The Defaults Tab of ROAINST',
                    'PERIOD BUDGETING IS NOT ENABLED On The Defaults Tab of ROAINST') Status
    INTO
        v_period_budgeting_status
    FROM
    	robinst
    WHERE
    	robinst_aidy_code = v_aidy;
    utl_file.put_line(f_dat_file_OUT,v_period_budgeting_status,FALSE);

  --Section Header 6.1
    utl_file.put_line(f_dat_file_OUT,'Report 6.1 - Period Budget Groups ',FALSE);
    utl_file.put_line(f_dat_file_OUT,' RTVPBGP ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Budget',9);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Group',9) 
               || RPAD('Description',31) 
               || 'Active?';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_1;
    LOOP
        FETCH c_report6_1
            INTO c_rtvpbgp_code
                ,c_rtvpbgp_desc
                ,c_message_text;
        EXIT WHEN c_report6_1%notfound;
        f_line_OUT := RPAD(c_rtvpbgp_code,9) 
                    || RPAD(c_rtvpbgp_desc,31)
                    || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report6_1;

  --Section Header 6.2
    utl_file.put_line(f_dat_file_OUT,'Report 6.2 - Budget Types ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RTVPBTP',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Budget';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Type',7) 
               || RPAD(' ',31) 
               || 'Active';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',7) 
               || RPAD('Description',31) 
               || 'Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_2;
    LOOP
        FETCH c_report6_2
            INTO c_rtvpbtp_code
                ,c_rtvpbtp_desc
                ,c_message_text;
        EXIT WHEN c_report6_2%notfound;
        f_line_OUT := RPAD(c_rtvpbtp_code,7) 
                    || RPAD(c_rtvpbtp_desc,31) 
                    || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_2;


  --Section Header 6.3
    utl_file.put_line(f_dat_file_OUT,'Report 6.3 - Budget Components ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RTVPBCP',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Budget';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Component',10) 
               || RPAD(' ',31) 
               || 'Active';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',10) 
               || RPAD('Description',31) 
               || 'Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_3;
    LOOP
        FETCH c_report6_3
            INTO c_rtvpbcp_code
                ,c_rtvpbcp_desc
                ,c_message_text;
        EXIT WHEN c_report6_3%notfound;
        f_line_OUT := RPAD(c_rtvpbcp_code,10) 
                   || RPAD(c_rtvpbcp_desc,31) 
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_3;
    
  --Section Header 6.4
    utl_file.put_line(f_dat_file_OUT,'Report 6.4 - Budget Categories ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RTVBCAT',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Budget';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Category',10) 
               || RPAD(' ',31) 
               || 'Active';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',10) 
               || RPAD('Description',31) 
               || 'Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_4;
    LOOP
        FETCH c_report6_4
            INTO c_rtvbcat_code
                ,c_rtvbcat_desc
                ,c_message_text;
        EXIT WHEN c_report6_4%notfound;
        f_line_OUT := RPAD(c_rtvbcat_code,10) 
                   || RPAD(c_rtvbcat_desc,31) 
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report6_4;

  --Section Header 6.5
    utl_file.put_line(f_dat_file_OUT,'Report 6.5 - Period Budget Group Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RBRPBYR',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Period';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := 'Budget';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Group',10) 
               || RPAD(' ',9) 
               || 'Long';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',10) 
               || RPAD('Priority',9) 
               || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    
    OPEN c_report6_5;
    LOOP
        FETCH c_report6_5
            INTO c_rbrpbgp_pbgp_code
                ,c_rbrpbgp_priority
                ,c_rbrpbgp_long_des;
        EXIT WHEN c_report6_5%notfound;
        f_line_OUT := RPAD(c_rbrpbgp_pbgp_code,10) 
                   || RPAD(c_rbrpbgp_priority,9) 
                   || c_rbrpbgp_long_des;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_5;

  --Section Header 6.6
    utl_file.put_line(f_dat_file_OUT,'Report 6.6 - Period Budget Type Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RBRPBYR',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Period';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Budget',10)
               || RPAD('Pell',5) 
               || RPAD('EFC',4)
               || 'Long';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Type Code',10) 
               || RPAD('Ind',5) 
               || RPAD('Ind',4) 
               || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  

    OPEN c_report6_6;
    LOOP
        FETCH c_report6_6
            INTO c_rbrpbtp_pbtp_code 
                ,c_rbrpbtp_pell_ind
                ,c_rbrpbtp_efc_ind
                ,c_rbrpbtp_long_desc;
        EXIT WHEN c_report6_6%notfound;
        f_line_OUT := RPAD(c_rbrpbtp_pbtp_code,10) 
                   || RPAD(c_rbrpbtp_pell_ind,5) 
                   || RPAD(c_rbrpbtp_efc_ind,4) 
                   || c_rbrpbtp_long_desc;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_6;

  --Section Header 6.7
    utl_file.put_line(f_dat_file_OUT,'Report 6.7 - Period Budget Category Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RBRPBYR',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Period',9);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Budget',9);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Category',9)
               || RPAD('Print',7)
               || 'Long';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',9) 
               || RPAD('Seq No',7) 
               || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_7;
    LOOP
        FETCH c_report6_7
            INTO c_rbrbcat_bcat_code
                ,c_rbrbcat_print_seq_no
                ,c_rbrbcat_long_desc;
        EXIT WHEN c_report6_7%notfound;
        f_line_OUT := RPAD(c_rbrbcat_bcat_code,9) 
                   || RPAD(c_rbrbcat_print_seq_no,7) 
                   || c_rbrbcat_long_desc;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_7;

  --Section Header 6.8
    utl_file.put_line(f_dat_file_OUT,'Report 6.8 - Period Budget Component Rules Part 1 ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RBRPBYR - Budget Components Tab',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Period',10) 
               || 'Period';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Budget',10) 
               || RPAD('Budget',9) 
               || RPAD(' ',8) 
               || RPAD('Pell',5)
               || RPAD('Direct',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Component',10) 
               || RPAD('Category',9) 
               || RPAD('Default',8) 
               || RPAD('LTHT',5)
               || RPAD('Cost',7)
               || 'Long';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',10) 
               || RPAD('Code',9) 
               || RPAD('Ind',8) 
               || RPAD('Ind',5)
               || RPAD('Ind',7)
               || 'Description';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    
    OPEN c_report6_8;
    LOOP
        FETCH c_report6_8
            INTO c_rbrpbcp_pbcp_code
                ,c_rbrpbcp_bcat_code
                ,c_rbrpbcp_default_ind
                ,c_rbrpbcp_pell_lt_half_ind
                ,c_rbrpbcp_direct_cost_ind
                ,c_rbrpbcp_long_desc;
        EXIT WHEN c_report6_8%notfound;
        f_line_OUT := RPAD(c_rbrpbcp_pbcp_code,10) 
               || RPAD(c_rbrpbcp_bcat_code,9) 
               || RPAD(c_rbrpbcp_default_ind,8) 
               || RPAD(c_rbrpbcp_pell_lt_half_ind,5)
               || RPAD(c_rbrpbcp_direct_cost_ind,7)
               || c_rbrpbcp_long_desc;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_8;

  --Section Header 6.9
    utl_file.put_line(f_dat_file_OUT,'Report 6.9 - Period Budget Component Rules Part 2 ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RBRPBYR - Budget Components Tab',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Period',10) 
               || RPAD(' ',12) 
               || RPAD(' ',30) 
               || RPAD(' ',12)
               || 'Pell';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Budget',10) 
               || RPAD(' ',12) 
               || RPAD('Default',30) 
               || RPAD('Pell',12)
               || 'Default';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Component',10) 
               || RPAD('Default',12) 
               || RPAD('Algorithmic',30) 
               || RPAD('Default',12)
               || 'Default';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',10) 
               || RPAD('Amount',12) 
               || RPAD('Code',30) 
               || RPAD('Amount',12)
               || 'Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report6_9;
    LOOP
        FETCH c_report6_9
            INTO c_rbrpbcp_pbcp_code 
                ,c_rbrpbcp_amt_dflt
                ,c_rbrpbcp_abrc_code_dflt
                ,c_rbrpbcp_amt_pell_dflt
                ,c_rbrpbcp_abrc_code_pell_dflt;
        EXIT WHEN c_report6_9%notfound;
        f_line_OUT := RPAD(c_rbrpbcp_pbcp_code,10) 
                   || RPAD(c_rbrpbcp_amt_dflt,12) 
                   || RPAD(c_rbrpbcp_abrc_code_dflt,30) 
                   || RPAD(c_rbrpbcp_amt_pell_dflt,12)
                   || c_rbrpbcp_abrc_code_pell_dflt;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_9;

  --Section Header 6.10
    utl_file.put_line(f_dat_file_OUT,'Report 6.10 - Budget Groups ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Period',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Budget',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Group',7) 
               || RPAD('Type',5) 
               || RPAD('Period',15) 
               || RPAD('Comp',5) 
               || RPAD(' ',12) 
               || 'Algorithmic';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',7) 
               || RPAD('Code',5) 
               || RPAD('Code',15) 
               || RPAD('Code',5) 
               || RPAD('Amount',12) 
               || 'Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_10;
    LOOP
        FETCH c_report6_10
            INTO c_rbrpbdr_pbgp_code
                ,c_rbrpbdr_pbtp_code
                ,c_rbrpbdr_period
                ,c_rbrpbdr_pbcp_code
                ,c_rbrpbdr_amt
                ,c_rbrpbdr_abrc_code;
        EXIT WHEN c_report6_10%notfound;
        f_line_OUT := RPAD(c_rbrpbdr_pbgp_code,7) 
                   || RPAD(c_rbrpbdr_pbtp_code,5) 
                   || RPAD(c_rbrpbdr_period,15) 
                   || RPAD(c_rbrpbdr_pbcp_code,5) 
                   || RPAD(c_rbrpbdr_amt,12) 
                   || c_rbrpbdr_abrc_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_10;

  --Section Header 6.11
    utl_file.put_line(f_dat_file_OUT,'Report 6.11 - Period Budget Group Aid Year Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RBRPBGR',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Period';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := 'Budget';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := 'Group';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',7) 
               || 'Type';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_11;
    LOOP
        FETCH c_report6_11
            INTO c_rbrpgpt_pbgp_code
                ,c_rbrpgpt_pbtp_code;
        EXIT WHEN c_report6_11%notfound;
        f_line_OUT := RPAD(c_rbrpgpt_pbgp_code,7) 
                    || c_rbrpgpt_pbtp_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_11;

  --Section Header 6.12
    utl_file.put_line(f_dat_file_OUT,'Report 6.12 - Pell Period Budget Group Aid Year Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RBRPBGR',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Period',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Pell',5);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Group',7) 
               || RPAD('Comp',5) 
               || RPAD(' ',12) 
               || 'Algorithmic';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Code',7) 
               || RPAD('Code',5) 
               || RPAD('Amount',12) 
               || 'Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  

    OPEN c_report6_12;
    LOOP
        FETCH c_report6_12
            INTO c_rbrpell_pbgp_code 
                ,c_rbrpell_pbcp_code
                ,c_rbrpell_amt
                ,c_rbrpell_abrc_code;
        EXIT WHEN c_report6_12%notfound;
        f_line_OUT := RPAD(c_rbrpell_pbgp_code,7) 
                   || RPAD(c_rbrpell_pbcp_code,5) 
                   || RPAD(c_rbrpell_amt,12) 
                   || c_rbrpell_abrc_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_12;

  --Section Header 6.13
    utl_file.put_line(f_dat_file_OUT,'Report 6.13 - Simple Period Budget Rules Type G ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RORRULE',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Group',6) 
               || RPAD('Simple Statement',78) 
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_13;
    LOOP
        FETCH c_report6_13
            INTO c_rorgdat_grp_code 
                ,c_rorgsql_sql_statement
                ,c_rorgsql_activity_date;
        EXIT WHEN c_report6_13%notfound;
        f_line_OUT := RPAD(c_rorgdat_grp_code,6) 
                   || RPAD(c_rorgsql_sql_statement,78) 
                   || c_rorgsql_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_13;

  --Section Header 6.14
    utl_file.put_line(f_dat_file_OUT,'Report 6.14 - Expert Period Budget Rules Type G ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RORRULE',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Group',6) 
               || RPAD('Statement',100) 
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report6_14;
    LOOP
        FETCH c_report6_14
            INTO c_rorgdat_grp_code 
                ,c_rorcmpl_sql_statement
                ,c_rorcmpl_activity_date;
        EXIT WHEN c_report6_14%notfound;
        f_line_OUT := RPAD(c_rorgdat_grp_code,6) 
                   || RPAD(c_rorcmpl_sql_statement,100) 
                   || c_rorcmpl_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report6_14;

--section 7

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Funds Management Module',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'Run RFRFUND from GJAPCTL to review fund set up',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  

--7.1
  --Section Header 7.1
    utl_file.put_line(f_dat_file_OUT,'Report 7.1 - Funds not set to Reduce Need or Replace EFC ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RORRULE',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT :=RPAD('Aid',7) 
               || 'Fund';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Year',7) 
               || 'Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report7_1;
    LOOP
        FETCH c_report7_1
            INTO c_rfraspc_aidy_code
                ,c_rfraspc_fund_code;
        EXIT WHEN c_report7_1%notfound;
        f_line_OUT := RPAD(c_rfraspc_aidy_code,10) 
                   || c_rfraspc_fund_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report7_1;

  --Section Header 7.2
    utl_file.put_line(f_dat_file_OUT,'Report 7.2 - Active Funds with No Total Allocated Amount ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT :=RPAD('Aid',7) 
               || 'Fund';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Year',7) 
               || 'Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  

    OPEN c_report7_2;
    LOOP
        FETCH c_report7_2
            INTO c_rfraspc_aidy_code
                ,c_rfraspc_fund_code;
        EXIT WHEN c_report7_2%notfound;
        f_line_OUT := RPAD(c_rfraspc_aidy_code,7) 
                   || c_rfraspc_fund_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report7_2;
    
  --Section Header 7.3
    utl_file.put_line(f_dat_file_OUT,'Report 7.3 - Active Funds with Total Allocated Greater Than Available to Offer Amount ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT :=RPAD('Aid',7) 
               || RPAD('Fund',6)
               || RPAD('Total',16)
               || 'Available';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT :=RPAD('Year',7) 
               || RPAD('Code',6)
               || RPAD('Allocation',16)
               || 'To Offer';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);  

    OPEN c_report7_3;
    LOOP
        FETCH c_report7_3
            INTO c_rfraspc_aidy_code 
                ,c_rfraspc_fund_code
                ,c_rfraspc_total_alloc_amt
                ,c_rfraspc_avail_offer_amt;
        EXIT WHEN c_report7_3%notfound;
        f_line_OUT :=RPAD(c_rfraspc_aidy_code,7) 
                   || RPAD(c_rfraspc_fund_code,6)
                   || RPAD(c_rfraspc_total_alloc_amt,16)
                   || c_rfraspc_avail_offer_amt;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report7_3;
    
  --Section Header 7.4
    utl_file.put_line(f_dat_file_OUT,'Report 7.4 - Direct Loan Funds Without Loan Options Record ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,' RPRLOPT',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT :=RPAD('Aid',7) 
               || RPAD('Fund',6);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT :=RPAD('Year',7) 
               || RPAD('Code',6)
               || 'Comments';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report7_4;
    LOOP
        FETCH c_report7_4
            INTO c_rfraspc_aidy_code 
                ,c_rfraspc_fund_code
                ,c_message_text;
        EXIT WHEN c_report7_4%notfound;
        f_line_OUT :=RPAD(c_rfraspc_aidy_code,7) 
                   || RPAD(c_rfraspc_fund_code,6)
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report7_4;
    
  --Section Header 7.5
    utl_file.put_line(f_dat_file_OUT,'Report 7.5 - Funds with Accept Award Status not set to Accept ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT :=RPAD('Aid',7) 
               || RPAD('Accept',6);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT :=RPAD('Year',7) 
               || RPAD('Code',6);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report7_5;
    LOOP
        FETCH c_report7_5
            INTO c_rfraspc_aidy_code
                ,c_rfraspc_accept_awst_code;
        EXIT WHEN c_report7_5%notfound;
        f_line_OUT :=RPAD(c_rfraspc_aidy_code,7) 
                   || RPAD(c_rfraspc_accept_awst_code,6);   
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report7_5;

  --Section Header 7.6
    utl_file.put_line(f_dat_file_OUT,'Report 7.6 - Funds in RPRATRM not setup correctly ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Accept Code';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report7_6;
    LOOP
        FETCH c_report7_6
            INTO c_rpratrm_fund_code;
        EXIT WHEN c_report7_6%notfound;
        f_line_OUT := c_rpratrm_fund_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report7_6;
    
  --Section Header 7.7
    utl_file.put_line(f_dat_file_OUT,'Report 7.7 - Orphan Award Records ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('PIDM',10) 
               || 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report7_7;
    LOOP
        FETCH c_report7_7
            INTO c_rprawrd_pidm
                ,c_rprawrd_aidy_code;
        EXIT WHEN c_report7_7%notfound;
        f_line_OUT := RPAD(c_rprawrd_pidm,10)  
                   || c_rprawrd_aidy_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report7_7;

--section 8

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Packaging Group Review ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
  
--8.1
  --Section Header 8.1
    utl_file.put_line(f_dat_file_OUT,'Report 8.1 - Packaging Group Review ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',7) --aid
               || RPAD('Packaging',10) --pack
               || RPAD(' ',9) --fund
               || RPAD(' ',9) --prio
               || RPAD(' ',12) --min
               || RPAD(' ',12) --max
               || RPAD(' ',8) --percent
               || RPAD(' ',7) --efc
               || ' '; --alg
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Aid',7) --aid
               || RPAD('Group',10) --pack
               || RPAD('Fund',9) --fund
               || RPAD(' ',9) --prio
               || RPAD('Min',12) --min
               || RPAD('Max',12) --max
               || RPAD(' ',8) --percent
               || RPAD('EFC',7) --efc
               || ' '; --alg
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    f_line_OUT := RPAD('Year',7) --aid
               || RPAD('Code',10) --pack
               || RPAD('Code',9) --fund
               || RPAD('Priority',9) --prio
               || RPAD('Award',12) --min
               || RPAD('Award',12) --max
               || RPAD('Percent',8) --percent
               || RPAD('Method',7) --efc
               || 'Alogorithmic Rule'; --alg
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    
    OPEN c_report8_1;
    LOOP
        FETCH c_report8_1
            INTO c_rprgfnd_aidy_code
                ,c_rprgfnd_pgrp_code
                ,c_rprgfnd_fund_code
                ,c_rprgfnd_priority
                ,c_rprgfnd_min_award
                ,c_rprgfnd_max_award
                ,c_rprgfnd_unmet_need_pct
                ,c_rprgfnd_tfc_ind
                ,c_rprgfnd_algr_code;
        EXIT WHEN c_report8_1%notfound;
        f_line_OUT := RPAD(c_rprgfnd_aidy_code,7) --aid
                   || RPAD(c_rprgfnd_pgrp_code,10) --pack
                   || RPAD(c_rprgfnd_fund_code,9) --fund
                   || RPAD(c_rprgfnd_priority,9) --prio
                   || RPAD(c_rprgfnd_min_award,12) --min
                   || RPAD(c_rprgfnd_max_award,12) --max
                   || RPAD(c_rprgfnd_unmet_need_pct,8) --percent
                   || RPAD(c_rprgfnd_tfc_ind,7) --efc
                   || c_rprgfnd_algr_code; --alg
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report8_1;
    
  --Section Header 8.2
    utl_file.put_line(f_dat_file_OUT,'Report 8.2 - Simple Packaging Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Group',6) 
               || RPAD('Simple Statement',78) 
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report8_2;
    LOOP
        FETCH c_report8_2
            INTO c_rorgdat_grp_code
                ,c_rorgsql_sql_statement
                ,c_rorgsql_activity_date;
        EXIT WHEN c_report8_2%notfound;
        f_line_OUT := RPAD(c_rorgdat_grp_code,6) 
                   || RPAD(c_rorgsql_sql_statement,100) 
                   || c_rorgsql_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report8_2;
    
  --Section Header 8.3
    utl_file.put_line(f_dat_file_OUT,'Report 8.3 - Expert Packaging Rules ',FALSE);   
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Group',6) 
               || RPAD('Statement',100) 
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 

    OPEN c_report8_3;
    LOOP
        FETCH c_report8_3
            INTO c_rorgdat_grp_code
                ,c_rorcmpl_sql_statement
                ,c_rorcmpl_activity_date;
        EXIT WHEN c_report8_3%notfound;
        f_line_OUT := RPAD(c_rorgdat_grp_code,6) 
                   || RPAD(c_rorcmpl_sql_statement,100) 
                   || c_rorcmpl_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);  
    CLOSE c_report8_3;
    
    --Close File
    utl_file.fclose(f_dat_file_OUT);

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE nysoutp';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE nsudev.nysoutp(
            nysoutp_line    char(500)
        )
        ORGANIZATION EXTERNAL (
            TYPE ORACLE_LOADER
            DEFAULT DIRECTORY U13_STUDENT
            ACCESS PARAMETERS (
                RECORDS DELIMITED BY NEWLINE
                FIELDS(nysoutp_line    char(500))
            )
            LOCATION (''nys_textout.txt'')
        )';
        
    END;
    
END;

