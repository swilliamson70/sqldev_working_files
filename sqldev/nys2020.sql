/*  New Year Script
    This is based on a SQL*Plus script for the FinAid New Year
    that was found in the Ellucian support site by Vicki Ryals
    Original Service Request 15178170 - September 2020
    Updated with NYS2020 script
*/


DECLARE
    f_dat_file_OUT utl_file.file_type;
    f_line_OUT varchar2(1500);
    f_dir_OUT varchar2(20) := 'U13_STUDENT';
    f_name_OUT varchar2(15) := 'nys_textout.txt';
    f_exists_OUT boolean;
    f_size_OUT number;
    f_block_size_OUT number;

    v_aidy varchar2(4) := COALESCE(:parm_eb_aidy,'2122');
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
    --UPDATED with code from NYS2020 script - Nov 2020

    c_stvterm_code stvterm.stvterm_code%TYPE;
    c_message_text2 varchar2(100);

    CURSOR c_report1_6 IS
        SELECT 
            stvterm_code trm,
            ' Term Code is not in Form ROAINST Credit Hours tab for the' mes2, 
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
    
        --Report 1.7 ROAINST Default Aid Period Algo Rule
        --UPDATED with code from NYS2020 script - Nov 2020
        --c_stvterm_code already declared

    --c_robinst_aidy_code already declared
    --c_message_text already declared
    c_roralgo_process roralgo.roralgo_process%TYPE;
    --c_message_text2 already declared
    c_roralgo_algo_code roralgo.roralgo_algo_code%TYPE;

    CURSOR c_report1_7 IS 
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

    --Report 1.8 Enrollment Cut Off Dates
    --UPDATED with code from NYS2020 script - Nov 2020 
    c_rorcrhr_period rorcrhr.rorcrhr_period%TYPE;
    --c_message_text already declared 
    --c_message_text2 already declared

    CURSOR c_report1_8 IS
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


    --Report 1.9 RORTPRD Default Aid Period on ROAINST Build Periods
    c_robinst_aprd_code_def robinst.robinst_aprd_code_def%TYPE;

    CURSOR c_report1_9 IS
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



    --Report 1.10 Algo Rules Active not Validated
    --c_roralgo_process already declared
    c_roralgo_ptyp_code roralgo.roralgo_ptyp_code%TYPE;
    --c_roralgo_algo_code already declared
    c_roralgo_aidy_code roralgo.roralgo_aidy_code%TYPE;
    c_roralgo_seq_no roralgo.roralgo_seq_no%TYPE;

    CURSOR c_report1_10 IS
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
            
    --Report 6.15 Budget Component Algo Rules
    c_rbrabrc_aidy_code rbrabrc.rbrabrc_aidy_code%TYPE;
    c_rbrabrc_abrc_code rbrabrc.rbrabrc_abrc_code%TYPE;    
    c_rbrabrc_seq_no rbrabrc.rbrabrc_seq_no%TYPE;  
    c_rbrabrc_active_ind rbrabrc.rbrabrc_active_ind%TYPE;   
    c_rbrabrc_validated_ind rbrabrc.rbrabrc_validated_ind%TYPE; 
    c_rbrabrc_activity_date rbrabrc.rbrabrc_activity_date%TYPE;
    
    CURSOR c_report6_15 IS
        SELECT
            rbrabrc_aidy_code aidy,    
            rbrabrc_abrc_code alcde,    
            rbrabrc_seq_no seqno,  
            rbrabrc_active_ind act_ind,   
            rbrabrc_validated_ind val_ind, 
            rbrabrc_activity_date date_active
        FROM 
            rbrabrc
        WHERE
            rbrabrc_aidy_code = v_aidy 
        ORDER BY 2,3;           

    --Report 6.16 Budget Component Aldo SQL
    --c_rbrabrc_sql_statement rbrabrc.rbrabrc_sql_statement%TYPE;
    c_sql varchar2(1400);
    
    CURSOR c_report6_16 IS
        SELECT
            rbrabrc_aidy_code aidy,    
            rbrabrc_abrc_code alcde,    
            rbrabrc_seq_no seqno,  
            SUBSTR(TO_CHAR(rbrabrc_sql_statement),1,1400) sql_statement
        FROM 
            rbrabrc
        WHERE
            rbrabrc_aidy_code = v_aidy 
        ORDER BY 2,3;


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
               
    --Report 9.1 SAY Code Validation Review 
    c_rtvsayr_code rtvsayr.rtvsayr_code%TYPE;
    c_rtvsayr_desc rtvsayr.rtvsayr_desc%TYPE;
    c_rtvsayr_active_ind rtvsayr.rtvsayr_active_ind%TYPE;
    
    CURSOR c_report9_1 IS
        SELECT 
            rtvsayr_code scode,
            rtvsayr_desc sdesc,
            rtvsayr_active_ind aind
        FROM 
            rtvsayr
        ORDER BY 
            3 desc, 1;     
            
    --Report 9.2 SAY Start and End Dates
    c_robsayr_aidy_code robsayr.robsayr_aidy_code%TYPE;
    c_robsayr_sayr_code robsayr.robsayr_sayr_code%TYPE;
    c_robsayr_type_ind robsayr.robsayr_type_ind%TYPE;
    c_robsayr_start_date robsayr.robsayr_start_date%TYPE;
    c_robsayr_end_date robsayr.robsayr_end_date%TYPE;
        
    CURSOR c_report9_2 IS
        SELECT 
            robsayr_aidy_code saidy,
            robsayr_sayr_code scode,
            robsayr_type_ind stype,
            robsayr_start_date sdate,
            robsayr_end_date edate
        FROM 
            robsayr
        WHERE
            robsayr_aidy_code = v_aidy
        ORDER BY 
            4, 3 desc, 2;
            
    --Report 9.3 SAY Periods 
    c_rorsayr_aidy_code rorsayr.rorsayr_aidy_code%TYPE;
    --c_rortprd_aprd_code already declared
    c_rorsayr_sayr_code rorsayr.rorsayr_sayr_code%TYPE;
    c_rorsayr_period rorsayr.rorsayr_period%TYPE;
    --c_rortprd_start_date
    --c_rortprd_end_date
    
    CURSOR c_report9_3 IS
        SELECT 
            rorsayr_aidy_code saidy,
            rortprd_aprd_code saprd,
            rorsayr_sayr_code scode,
            rorsayr_period sprds,
            rortprd_start_date sdate,
            rortprd_end_date edate
        FROM 
            rorsayr,
            rortprd,
            robaprd
        WHERE
            rorsayr_aidy_code = v_aidy
          and rorsayr_aidy_code = rortprd_aidy_code
          and rorsayr_aidy_code = robaprd_aidy_code
          and rorsayr_period = rortprd_period
          and rorsayr_sayr_code = robaprd_sayr_code
          and rortprd_aprd_code = robaprd_aprd_code
        ORDER BY 
            2,5;
    
    --Report 9.4 SAY Disbursement
    c_rorsayd_aidy_code rorsayd.rorsayd_aidy_code%TYPE;
    c_rorsayd_sayr_code rorsayd.rorsayd_sayr_code%TYPE;
    c_rorsayd_period rorsayd.rorsayd_period%TYPE;
    c_rorsayd_disburse_date rorsayd.rorsayd_disburse_date%TYPE;
    c_rorsayd_disb_sched_no_days rorsayd.rorsayd_disb_sched_no_days%TYPE;
    --rorsayd_period_multi_disb_ind uses c_text_message
    
    CURSOR c_report9_4 IS
        SELECT
            rorsayd_aidy_code saidy,
            rorsayd_sayr_code scode,
            rorsayd_period sprds,
            rorsayd_disburse_date sdate,
            rorsayd_disb_sched_no_days schd,
            decode(rorsayd_period_multi_disb_ind,'Y','Y','') mdisb
        FROM 
            rorsayd
        WHERE
            rorsayd_aidy_code = v_aidy
        ORDER BY 
            2,3,4;
            
    --Report 9.5 BBAY Start and End Dates 
    c_robbbay_bbay_code robbbay.robbbay_bbay_code%TYPE;
    c_robbbay_desc robbbay.robbbay_desc%TYPE;
    c_robbbay_start_date robbbay.robbbay_start_date%TYPE;
    c_robbbay_end_date robbbay.robbbay_end_date%TYPE;
    c_robbbay_active_ind robbbay.robbbay_active_ind%TYPE;
    c_robbbay_split_ind robbbay.robbbay_split_ind%TYPE;
    c_robbbay_max_elig_ind robbbay.robbbay_max_elig_ind%TYPE;
    c_robbbay_bbtp_code robbbay.robbbay_bbtp_code%TYPE;
    c_robbbay_budg_dur robbbay.robbbay_budg_dur%TYPE;
    
    CURSOR c_report9_5 IS
        SELECT 
            robbbay_bbay_code bcode,
            robbbay_desc bdesc,
            robbbay_start_date sdate,
            robbbay_end_date edate,
            robbbay_active_ind bact,
            robbbay_split_ind bspl,
            robbbay_max_elig_ind bmax,
            robbbay_bbtp_code bbtp,
            robbbay_budg_dur bdur
        FROM 
            robbbay
        ORDER BY 
            5, 3, 1;    
            
    --Report 9.6 BBAY Periods 
    c_rorbbay_bbay_code rorbbay.rorbbay_bbay_code%TYPE;
    c_rorbbay_period rorbbay.rorbbay_period%TYPE;
    c_rorbbay_start_date rorbbay.rorbbay_start_date%TYPE;
    c_rorbbay_end_date rorbbay.rorbbay_end_date%TYPE;
    c_rorbbay_est_budget_amt rorbbay.rorbbay_est_budget_amt%TYPE;
    
    CURSOR c_report9_6 IS
        SELECT 
            rorbbay_bbay_code bcode,
            rorbbay_period bprds,
            rorbbay_start_date sdate,
            rorbbay_end_date edate,
            nvl(rorbbay_est_budget_amt,0) ebud
        FROM 
            rorbbay
        ORDER BY 
            1,2,3;
    
    --Report 9.7 BBAY Disbursement
    c_rorbayd_bbay_code rorbayd.rorbayd_bbay_code%TYPE;
    c_rorbayd_period rorbayd.rorbayd_period%TYPE;
    c_rorbayd_disburse_date rorbayd.rorbayd_disburse_date%TYPE;
    c_rorbayd_disb_sched_no_days rorbayd.rorbayd_disb_sched_no_days%TYPE;
    --rorbayd_period_multi_disb_ind uses c_message_text
    
    CURSOR c_report9_7 IS
        SELECT 
            rorbayd_bbay_code bcode,
            rorbayd_period bprds,
            rorbayd_disburse_date bdate,
            rorbayd_disb_sched_no_days schd,
            decode(rorbayd_period_multi_disb_ind,'Y','Y','') mdisb
        FROM 
            rorbayd
        ORDER BY 
            1,2,3;
    
    --Report 10.1 Pell Grant Options Report
    --c_robinst_aidy_code already declared
    c_robinst_turn_off_pell_ind robinst.robinst_turn_off_pell_ind%TYPE;
    c_robinst_pell_red_elig_ind robinst.robinst_pell_red_elig_ind%TYPE;
    c_robinst_cash_monitor_ind robinst.robinst_cash_monitor_ind%TYPE;
    c_robinst_pell_lt_half_ind robinst.robinst_pell_lt_half_ind%TYPE;
    c_robinst_just_in_time_ind robinst.robinst_just_in_time_ind%TYPE;
    c_robinst_jit_no_days robinst.robinst_jit_no_days%TYPE;
            
    CURSOR c_report10_1 IS
        SELECT 
            robinst_aidy_code 			aidyc,
            nvl(robinst_turn_off_pell_ind,'N')   	autoff,
            nvl(robinst_pell_red_elig_ind,'N') 	redelig,
            nvl(robinst_cash_monitor_ind,'N')    	cashm, 
            nvl(robinst_pell_lt_half_ind,'N')	ltht, 
            nvl(robinst_just_in_time_ind,'N')    	jit,
            nvl(robinst_jit_no_days,0)           	jdays 
        FROM 
            robinst
        WHERE
            robinst_aidy_code = v_aidy
        ORDER BY 
            1;

    --Report 10.2 Teach Options Report
    --c_robinst_aidy_code already declared
    c_robinst_treq_code_teach_entr robinst.robinst_treq_code_teach_entr%TYPE;
    c_robinst_trst_code_teach_entr robinst.robinst_trst_code_teach_entr%TYPE;

    CURSOR c_report10_2 IS
        SELECT 
            robinst_aidy_code 		aidyc,
            robinst_treq_code_teach_entr   	entinv,
            robinst_trst_code_teach_entr 	ttrst
        FROM 
            robinst
        WHERE
            robinst_aidy_code = v_aidy
        ORDER BY 
            1;
    
    --Report 10.3 EDE Options Report
    --c_robinst_aidy_code already declared	
    c_robinst_upd_tran_ind robinst.robinst_upd_tran_ind%TYPE;
    c_robinst_treq_code_sar robinst.robinst_treq_code_sar%TYPE;
    c_robinst_trst_code_sar robinst.robinst_trst_code_sar%TYPE;
    c_robinst_pell_audit_ind robinst.robinst_pell_audit_ind%TYPE;
    
    CURSOR c_report10_3 IS
        SELECT 
            robinst_aidy_code 	aidyc,
            robinst_upd_tran_ind   	uptran,
            robinst_treq_code_sar 	sarcd,
            robinst_trst_code_sar 	sarst,
            robinst_pell_audit_ind 	edecorr
        FROM 
            robinst
        WHERE
            robinst_aidy_code = v_aidy
        ORDER BY 
            1;    
    
    --Report 10.4 COD Entity ID Rules Report
    c_rorcodi_aidy_code rorcodi.rorcodi_aidy_code%TYPE;
    c_rorcodi_attending_id rorcodi.rorcodi_attending_id%TYPE;
    c_rorcodi_reporting_id rorcodi.rorcodi_reporting_id%TYPE;
    c_rorcodi_source_id rorcodi.rorcodi_source_id%TYPE;
    c_rorcodi_pell_id rorcodi.rorcodi_pell_id%TYPE;
    c_rorcodi_dl_school_code rorcodi.rorcodi_dl_school_code%TYPE;
    c_rorcodi_opeid rorcodi.rorcodi_opeid%TYPE;
    c_rorcodi_opeid_branch rorcodi.rorcodi_opeid_branch%TYPE;
    c_rorcodi_inst_default_ind rorcodi.rorcodi_inst_default_ind%TYPE;
          
    CURSOR c_report10_4 IS
        SELECT 
          rorcodi_aidy_code 		aidyc,      
          rorcodi_attending_id    	attid,  
          rorcodi_reporting_id    	repid,  
          rorcodi_source_id       	souid,  
          rorcodi_pell_id         	pelid,     
          rorcodi_dl_school_code  	dlid, 
          rorcodi_opeid           	opeid,      
          rorcodi_opeid_branch    	brid,
          rorcodi_inst_default_ind 	defind
        FROM 
            rorcodi
        WHERE
            rorcodi_aidy_code = v_aidy
        ORDER BY 
            1;    
    
    --Report 10.5 Campus Defaults Report
    --c_rorcamp_aidy_code already declared
    --c_rorcamp_camp_code already declared
    c_rorcamp_common_school_id rorcamp.rorcamp_common_school_id%TYPE;
    c_rorcamp_pell_id rorcamp.rorcamp_pell_id%TYPE;
    c_rorcamp_pell_fund_code rorcamp.rorcamp_pell_fund_code%TYPE;
    c_rorcamp_fed_school_code rorcamp.rorcamp_fed_school_code%TYPE;
    c_rorcamp_opeid rorcamp.rorcamp_opeid%TYPE;
    c_rorcamp_opeid_branch rorcamp.rorcamp_opeid_branch%TYPE;
    c_rorcamp_dl_school_code rorcamp.rorcamp_dl_school_code%TYPE;
    c_rorcamp_el_school_cde rorcamp.rorcamp_el_school_cde%TYPE;
    c_rorcamp_el_branch_cde rorcamp.rorcamp_el_branch_cde%TYPE;
    
    CURSOR c_report10_5 IS
        SELECT 
          rorcamp_aidy_code 		aidyc, 
          rorcamp_camp_code 		cmpcd,
          rorcamp_common_school_id    	attid,  
          rorcamp_pell_id    		pelid,  
          rorcamp_pell_fund_code       	pelcd,  
          rorcamp_fed_school_code       fscd,     
          rorcamp_opeid           	opeid,      
          rorcamp_opeid_branch    	brid,
          rorcamp_dl_school_code 	dlcd,
          rorcamp_el_school_cde 	elcd,
          rorcamp_el_branch_cde 	elbr
        FROM 
            rorcamp
        WHERE
            rorcamp_aidy_code = v_aidy
        ORDER BY 
            1;    
    
    --Report 11.1 Payroll Load Control
    c_rjrpayl_aidy_code rjrpayl.rjrpayl_aidy_code%TYPE;
    c_rjrpayl_year rjrpayl.rjrpayl_year%TYPE;
    c_rjrpayl_pict_code rjrpayl.rjrpayl_pict_code%TYPE;
    c_rjrpayl_payno rjrpayl.rjrpayl_payno%TYPE;
    c_rjrpayl_process_ind rjrpayl.rjrpayl_process_ind%TYPE;
    
    CURSOR c_report11_1 IS
        SELECT 
            rjrpayl_aidy_code paidy,
            rjrpayl_year pyear,
            rjrpayl_pict_code piccode,
            rjrpayl_payno payno,
            rjrpayl_process_ind pind
        FROM 
            rjrpayl
        WHERE
            rjrpayl_aidy_code = v_aidy
        ORDER BY 
            2,3,4;
    
    --Report 11.2
    c_rjrplrl_aidy_code rjrplrl.rjrplrl_aidy_code%TYPE;
    c_rjrplrl_place_cde rjrplrl.rjrplrl_place_cde%TYPE;
    c_rjrplrl_posn rjrplrl.rjrplrl_posn%TYPE;
    c_rjrplrl_posn_title rjrplrl.rjrplrl_posn_title%TYPE;
    c_rjrplrl_allocation rjrplrl.rjrplrl_allocation%TYPE;
    
    CURSOR c_report11_2 IS
        SELECT 
            rjrplrl_aidy_code paidy,
            rjrplrl_place_cde plcde,
            rjrplrl_posn posn,
            rjrplrl_posn_title ptitle,
            rjrplrl_allocation palloc
        FROM 
            rjrplrl
        WHERE
            rjrplrl_aidy_code = v_aidy
        ORDER BY 
            2,3;
    
    --Report 11.3 Placement Base Data Report
    c_rjbplbd_place_cde rjbplbd.rjbplbd_place_cde%TYPE;
    c_rjbplbd_place_desc rjbplbd.rjbplbd_place_desc%TYPE;
    c_rjbplbd_supervisor rjbplbd.rjbplbd_supervisor%TYPE;
    
    CURSOR c_report11_3 IS
        SELECT 
            rjbplbd_place_cde plcde,
            rjbplbd_place_desc pldesc,
            substr(rjbplbd_supervisor,1,40) plsup
        FROM 
            rjbplbd
        ORDER BY 
            1;

    --Report 11.4
    c_rjbjobt_code rjbjobt.rjbjobt_code%TYPE;
    c_rjbjobt_desc rjbjobt.rjbjobt_desc%TYPE;
    c_rjbjobt_hrly_pay_ind rjbjobt.rjbjobt_hrly_pay_ind%TYPE;
    c_rjbjobt_pay_range_low rjbjobt.rjbjobt_pay_range_low%TYPE;
    c_rjbjobt_pay_range_high rjbjobt.rjbjobt_pay_range_high%TYPE;
    c_rjbjobt_default_pay rjbjobt.rjbjobt_default_pay%TYPE;
    
    CURSOR c_report11_4 IS
        SELECT 
            rjbjobt_code jtcde,
            substr(rjbjobt_desc,1,21) jtdesc,
            rjbjobt_hrly_pay_ind jthpt,
            rjbjobt_pay_range_low prlow,
            rjbjobt_pay_range_high prhigh,
            rjbjobt_default_pay prdef
        FROM 
            rjbjobt
        ORDER BY 
            1;

    --Report 11.5 Job Title Requirements Report
    --c_rjbjobt_code declared already
    c_rjbjobt_requirements rjbjobt.rjbjobt_requirements%TYPE;
    
    CURSOR c_report11_5 IS
        SELECT 
            rjbjobt_code jtcde,
            rjbjobt_requirements jtreq  
        FROM 
            rjbjobt
        ORDER BY 
            1;    
    
    --Report 11.6 Student Employment Default Rules Report
    c_rjbsedr_aidy_code rjbsedr.rjbsedr_aidy_code%TYPE;
    c_rjbsedr_auth_start_date rjbsedr.rjbsedr_auth_start_date%TYPE;
    c_rjbsedr_auth_end_date rjbsedr.rjbsedr_auth_end_date%TYPE;
    c_rjbsedr_pay_start_date rjbsedr.rjbsedr_pay_start_date%TYPE;
    c_rjbsedr_pay_end_date rjbsedr.rjbsedr_pay_end_date%TYPE;
    c_rjbsedr_aust_code rjbsedr.rjbsedr_aust_code%TYPE;
    
    CURSOR c_report11_6 IS
        SELECT 
            rjbsedr_aidy_code 	aidyc,
            rjbsedr_auth_start_date auths,
            rjbsedr_auth_end_date 	authe,
            rjbsedr_pay_start_date  pays, 
            rjbsedr_pay_end_date	paye, 
            rjbsedr_aust_code	acode      
        FROM 
            rjbsedr
        WHERE
            rjbsedr_aidy_code = v_aidy
        ORDER BY 
            1;    
    
    --Report 12.1 Sport Codes Report
    c_rtvfasp_code rtvfasp.rtvfasp_code%TYPE;
    c_rtvfasp_desc rtvfasp.rtvfasp_desc%TYPE;
    c_rtvfasp_active_ind rtvfasp.rtvfasp_active_ind%TYPE;
    
    CURSOR c_report12_1 IS
        SELECT
            rtvfasp_code scode,
            rtvfasp_desc sdesc,
            rtvfasp_active_ind sind
        FROM
            rtvfasp
        ORDER BY 1;
    
    --Report 12.2 Athletic Aid Type Report
    c_rtvaatp_code rtvaatp.rtvaatp_code%TYPE;
    c_rtvaatp_desc rtvaatp.rtvaatp_desc%TYPE;
    c_rtvaatp_active_ind rtvaatp.rtvaatp_active_ind%TYPE;
    
    CURSOR c_report12_2 IS
        SELECT
            rtvaatp_code acode,
            rtvaatp_desc adesc,
            rtvaatp_active_ind aind
        FROM
            rtvaatp
        ORDER BY 1;

    --Report 12.3 Potential Athletic Grant Defaults Report
    c_rarpagd_aidy_code rarpagd.rarpagd_aidy_code%TYPE;
    c_rarpagd_in_state_amt rarpagd.rarpagd_in_state_amt%TYPE;
    c_rarpagd_out_state_amt rarpagd.rarpagd_out_state_amt%TYPE;
    
    CURSOR c_report12_3 IS
        SELECT
            rarpagd_aidy_code aidyc,
            rarpagd_in_state_amt inamt, 
            rarpagd_out_state_amt outamt
        FROM
            rarpagd
        WHERE
            rarpagd_aidy_code = v_aidy
        ORDER BY 1;    
    
    --Report 12.4 Sport Potential Athletic Grant Defaults Report
    c_rarpags_aidy_code rarpags.rarpags_aidy_code%TYPE;
    c_rarpags_fasp_code rarpags.rarpags_fasp_code%TYPE;
    c_rarpags_in_state_amt rarpags.rarpags_in_state_amt%TYPE;
    c_rarpags_out_state_amt rarpags.rarpags_out_state_amt%TYPE;
    
    CURSOR c_report12_4 IS
        SELECT
            rarpags_aidy_code aidyc,
            rarpags_fasp_code fasp,
            rarpags_in_state_amt inamt, 
            rarpags_out_state_amt outamt
        FROM
            rarpags
        WHERE
            rarpags_aidy_code = v_aidy
        ORDER BY 2;
    
    --Report 13.1 Scholarship Source Codes Report
    c_rtvssrc_code rtvssrc.rtvssrc_code%TYPE;
    c_rtvssrc_desc rtvssrc.rtvssrc_desc%TYPE;
    c_rtvssrc_active_ind rtvssrc.rtvssrc_active_ind%TYPE;
    
    CURSOR c_report13_1 IS
        SELECT 
          rtvssrc_code ssrc,
          rtvssrc_desc sdesc,
          rtvssrc_active_ind sind
        FROM
          rtvssrc
        ORDER BY 1;

    --Report 13.2 Thank You Letter Codes Report
    c_rtvtylt_code rtvtylt.rtvtylt_code%TYPE;
    c_rtvtylt_desc rtvtylt.rtvtylt_desc%TYPE;
    c_rtvtylt_active_ind rtvtylt.rtvtylt_active_ind%TYPE;
    
    CURSOR c_report13_2 IS
        SELECT 
          rtvtylt_code lcde,
          rtvtylt_desc ldesc,
          rtvtylt_active_ind lind
        FROM
          rtvtylt;
          
    --Report 13.3 Grades To Donor Codes Report
    c_rtvgrdd_code rtvgrdd.rtvgrdd_code%TYPE;
    c_rtvgrdd_desc rtvgrdd.rtvgrdd_desc%TYPE;
    c_rtvgrdd_active_ind rtvgrdd.rtvgrdd_active_ind%TYPE;
    
    CURSOR c_report13_3 IS
        SELECT 
          rtvgrdd_code gdnr,
          rtvgrdd_desc gdesc,
          rtvgrdd_active_ind gind
        FROM
          rtvgrdd;
          
    --Report 13.4 Scholarship Demographics Report 1
    c_rfrsdem_fund_code rfrsdem.rfrsdem_fund_code%TYPE;
    c_rfrsdem_multiple_donor_ind rfrsdem.rfrsdem_multiple_donor_ind%TYPE;
    c_rfrsdem_restricted_ind rfrsdem.rfrsdem_restricted_ind%TYPE;
    c_rfrsdem_tuition_waiver_ind rfrsdem.rfrsdem_tuition_waiver_ind%TYPE;
    c_rfrsdem_maximum_terms rfrsdem.rfrsdem_maximum_terms%TYPE;
    c_rfrsdem_min_enrollment rfrsdem.rfrsdem_min_enrollment%TYPE;
    
    CURSOR c_report13_4 IS
        SELECT
          rfrsdem_fund_code dfcde,
          rfrsdem_multiple_donor_ind dmdind,
          rfrsdem_restricted_ind dresind,
          rfrsdem_tuition_waiver_ind dtwind,
          rfrsdem_maximum_terms dmax,
          substr(rfrsdem_min_enrollment,1,20) dmin
        FROM
          rfrsdem
        ORDER by 1;
    
    --Report 13.5 Scholarship Demographics Report 2
    --c_rfrsdem_fund_code already declared
    c_rfrsdem_ssrc_code rfrsdem.rfrsdem_ssrc_code%TYPE;
    c_rfrsdem_dept_code rfrsdem.rfrsdem_dept_code%TYPE;
    c_rfrsdem_primary_user_name rfrsdem.rfrsdem_primary_user_name%TYPE;
    
    CURSOR c_report13_5 IS
        SELECT
          rfrsdem_fund_code dfcde,
          rfrsdem_ssrc_code dsrc,
          rfrsdem_dept_code ddept,
          rfrsdem_primary_user_name dpri
        FROM
          rfrsdem
        ORDER by 1;
        
    --Report 13.6 Scholarship Donor Demographics Report
    c_spriden_id spriden.spriden_id%TYPE;
    c_spriden_last_name spriden.spriden_last_name%TYPE;
    c_rfrdnrd_fund_code rfrdnrd.rfrdnrd_fund_code%TYPE;
    c_rfrdnrd_primary_donor_ind rfrdnrd.rfrdnrd_primary_donor_ind%TYPE;
    c_rfrdnrd_recept_invitation_in rfrdnrd.rfrdnrd_recept_invitation_ind%TYPE;
    c_rfrdnrd_donor_selection_ind rfrdnrd.rfrdnrd_donor_selection_ind%TYPE;
    c_rfrdnrd_anonymous_ind rfrdnrd.rfrdnrd_anonymous_ind%TYPE;
    c_rfrdnrd_grades rfrdnrd.rfrdnrd_grades%TYPE;
    c_rfrdnrd_letter rfrdnrd.rfrdnrd_letter%TYPE;
    
    CURSOR c_report13_6 IS
        SELECT
          spriden_id  dsid,
          substr(spriden_last_name,1,15) dlname,
          rfrdnrd_fund_code dfund,
          rfrdnrd_primary_donor_ind dpri,
          rfrdnrd_recept_invitation_ind  drinv,
          rfrdnrd_donor_selection_ind dsel,
          rfrdnrd_anonymous_ind danon,
          rfrdnrd_grades dgrds,
          rfrdnrd_letter dltr
        FROM
          rfrdnrd,
          spriden
        WHERE
          spriden_change_ind is null and
          spriden_pidm = rfrdnrd_pidm
        ORDER BY  3,2;   

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
    utl_file.put_line(f_dat_file_OUT,' FA Processing Year Term Code in STVTERM is not in the ROAINST Credit Hours tab',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Term',8) || RPAD(' ',60) || 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_6;
    LOOP
        FETCH c_report1_6
            INTO c_stvterm_code
                ,c_message_text
                ,c_message_text2; --robinst_aidy_code ||' Aid Year'
        EXIT WHEN c_report1_6%notfound;
        f_line_OUT := RPAD(c_stvterm_code,8) || RPAD(c_message_text,60) || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_6;

   --Section Header 1.7
    utl_file.put_line(f_dat_file_OUT,'Report 1.7 - ROAINST Credit Hours Setup ',FALSE);
    utl_file.put_line(f_dat_file_OUT,' Identifies Terms from STVTERM set to the Financial Aid Process Year that do not exist in the ROAINST Credit Hours tab',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_7;
    LOOP
        FETCH c_report1_7
            INTO c_robinst_aidy_code
                ,c_message_text
                ,c_roralgo_process
                ,c_message_text2 --robinst_aidy_code ||' Aid Year'
                ,c_roralgo_algo_code;
        EXIT WHEN c_report1_7%notfound;
        f_line_OUT := RPAD(c_robinst_aidy_code,9) 
                    || RPAD(c_message_text,60) 
                    || RPAD(c_roralgo_process,13)
                    || RPAD(c_message_text2,21)
                    || c_roralgo_algo_code;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_7;

   --Section Header 1.8
    utl_file.put_line(f_dat_file_OUT,'Report 1.8 - RPROPTS Enrollment Cut Off Date Rules missing Periods ',FALSE);
    utl_file.put_line(f_dat_file_OUT,' Identifies Periods in ROAINST Credit Hours tab that do not exist in RPROPTS Enrollment Cut Off Rules Page for the Aid Year',FALSE);
    utl_file.put_line(f_dat_file_OUT,' Clients who records returned with this query should also review the RPROPTS Grant Options Setup for completion prior to processing',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Period',9) || RPAD(' ',92) || 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_8;
    LOOP
        FETCH c_report1_8
            INTO c_rorcrhr_period
                ,c_message_text
                ,c_message_text2;
        EXIT WHEN c_report1_8%notfound;
        f_line_OUT := RPAD(c_rorcrhr_period,9)
                   || RPAD(c_message_text,92)
                   || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_8;

   --Section Header 1.9
    utl_file.put_line(f_dat_file_OUT,'Report 1.9 - RORTPRD Default Aid Period on ROAINST Build Periods ',FALSE);
    utl_file.put_line(f_dat_file_OUT,' Identifies a Default Aid Period in ROAINST that does not have periods associated with it RORTPRD',FALSE);
    utl_file.put_line(f_dat_file_OUT,' Prior to loading records, run this script to determine if the default aid period has been setup in RORTPRD',FALSE);
    utl_file.put_line(f_dat_file_OUT,' If it has not been setup prior to loading records, then RORPRST will not be populated with the expected period information defaults from ROAINST',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Period Default',55) || 'Aid Year';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report1_9;
    LOOP
        FETCH c_report1_9
            INTO c_robinst_aprd_code_def
                ,c_message_text
                ,c_robinst_aidy_code
                ,c_message_text2; --rorcrhr_aidy_code ||' Aid Year' aidy
        EXIT WHEN c_report1_9%notfound;
        f_line_OUT := RPAD(COALESCE(c_robinst_aprd_code_def,' '),8)
                   || RPAD(c_message_text,47)
                   || RPAD(COALESCE(c_robinst_aidy_code,' '),8)
                   || c_message_text2;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_9;

   --Section Header 1.10
    utl_file.put_line(f_dat_file_OUT,'Report 1.10 - Algo Rules Active not Validated ',FALSE);
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

    OPEN c_report1_10;
    LOOP
        FETCH c_report1_10
            INTO c_roralgo_process
                ,c_roralgo_ptyp_code
                ,c_roralgo_algo_code
                ,c_roralgo_aidy_code
                ,c_roralgo_seq_no
                ,c_message_text;
        EXIT WHEN c_report1_10%notfound;
        f_line_OUT := RPAD(c_roralgo_process,26)
                   || RPAD(c_roralgo_ptyp_code,24)
                   || RPAD(c_roralgo_algo_code,20)
                   || RPAD(c_roralgo_aidy_code,18)
                   || RPAD(c_roralgo_seq_no,15)
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report1_10;

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
    f_line_OUT := RPAD('INFC Code',31)
               || RPAD('Common Matching Code',21)
               || RPAD('Parameter Set',16)
               || RPAD('User Id',16)
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
        f_line_OUT := RPAD(c_rcrinfr_infc_code,31)
                   || RPAD(c_rcrinfr_cmsc_code,21)
                   || RPAD(c_rcrinfr_parameter_set,16)
                   || RPAD(c_rcrinfr_user_id,16)
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
                   || RPAD(COALESCE(c_rprclss_clas_code,' '),8)
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
               || RPAD(' ',7)
               || LPAD('Full',8)
               || LPAD('Pell',8)
               || LPAD('Grant',8)
               || LPAD('FM',4)
               || ' '
               || RPAD('IM',5);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid',6)
               || RPAD('Aid',7)
               || LPAD('Year',8)
               || LPAD('Year',8)
               || LPAD('Year',8)
               || LPAD('Bud',4)
               || ' '
               || RPAD('Bud',5);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',6)
               || RPAD('Period',7)
               || LPAD('Pct',8)
               || LPAD('Pct',8)
               || LPAD('Pct',8)
               || LPAD('Dur',4)
               || ' '
               || RPAD('Dur',5)
               || ' '
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
                   || RPAD(c_robaprd_aprd_code,7)
                   || LPAD(TO_CHAR(c_robaprd_full_yr_pct),8)
                   || LPAD(TO_CHAR(c_robaprd_pell_full_yr_pct),8)
                   || LPAD(TO_CHAR(c_robaprd_grant_full_yr_pct),8)
                   || LPAD(COALESCE(TO_CHAR(c_robaprd_budg_dur_fm),' '),4)
                   || ' '
                   || RPAD(COALESCE(TO_CHAR(c_robaprd_budg_dur_im),' '),5)
                   || ' '
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
               || LPAD(' ',8)
               || LPAD('Pell',8)
               || ' '
               || 'Memo';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid',8)
               || RPAD(' ',8)
               || LPAD('Award',8)
               || LPAD('Grant',8)
               || ' '
               || 'Exp';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Period',8)
               || RPAD('Period',8)
               || LPAD('Percent',8)
               || LPAD('Percent',8)
               || ' '
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
                   || LPAD(TO_CHAR(c_rfrdefa_award_pct,990.999),8)
                   || LPAD(TO_CHAR(c_rfrdefa_pell_award_pct,990.999),8)
                   || ' '
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
                   || LPAD(c_rfrdefd_disburse_pct,4);
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
    utl_file.put_line(f_dat_file_OUT,'Report 5.1 - Aid Year Budget Groups ',FALSE);
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
    utl_file.put_line(f_dat_file_OUT,'Report 5.2 - Aid Year Budget Types ',FALSE);
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
    utl_file.put_line(f_dat_file_OUT,'Report 6.10 - Period Budget Detail Rules ',FALSE);
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
    
  --Section Header 6.15
    utl_file.put_line(f_dat_file_OUT,'Report 6.15 - Budget Component Algo Rules ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Year',10)
               || RPAD('Algo Code',20)
               || RPAD('Seq',6)
               || RPAD('Active?',9)
               || RPAD('Validated?',11)
               || 'Activity Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report6_15;
    LOOP
        FETCH c_report6_15
            INTO c_rbrabrc_aidy_code
                ,c_rbrabrc_abrc_code
                ,c_rbrabrc_seq_no
                ,c_rbrabrc_active_ind
                ,c_rbrabrc_validated_ind
                ,c_rbrabrc_activity_date;
        EXIT WHEN c_report6_15%notfound;
        f_line_OUT := RPAD(c_rbrabrc_aidy_code,10)
               || RPAD(c_rbrabrc_abrc_code,20)
               || RPAD(c_rbrabrc_seq_no,6)
               || RPAD(c_rbrabrc_active_ind,9)
               || RPAD(c_rbrabrc_validated_ind,11)
               || c_rbrabrc_activity_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report6_15;

  --Section Header 6.16
    utl_file.put_line(f_dat_file_OUT,'Report 6.16 - Budget Component Algo Rules ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid Year',10)
               || RPAD('Algo Code',20)
               || RPAD('Seq',6)
               || 'Statement';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);    
    
    OPEN c_report6_16;
    LOOP
        FETCH c_report6_16
            INTO c_rbrabrc_aidy_code
                ,c_rbrabrc_abrc_code
                ,c_rbrabrc_seq_no
                ,c_sql;
        EXIT WHEN c_report6_16%notfound;
        f_line_OUT := RPAD(c_rbrabrc_aidy_code,10)
               || RPAD(c_rbrabrc_abrc_code,20)
               || RPAD(c_rbrabrc_seq_no,6)
               || c_sql;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report6_16;      

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
    utl_file.put_line(f_dat_file_OUT,'                   Packaging and Disbursement Module ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);

  --Section Header 8.1
    utl_file.put_line(f_dat_file_OUT,'Report 8.1 - Packaging Group Review ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',7) --aid
               || RPAD('Packaging',10) --pack
               || RPAD(' ',9) --fund
               || LPAD(' ',9) --prio
               || LPAD(' ',12) --min
               || LPAD(' ',12) --max
               || LPAD(' ',8) --percent
               || ' '
               || RPAD(' ',7) --efc
               || ' '; --alg
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid',7) --aid
               || RPAD('Group',10) --pack
               || RPAD('Fund',9) --fund
               || LPAD(' ',9) --prio
               || LPAD('Min',12) --min
               || LPAD('Max',12) --max
               || LPAD(' ',8) --percent
               || ' '
               || RPAD('EFC',7) --efc
               || ' '; --alg
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',7) --aid
               || RPAD('Code',10) --pack
               || RPAD('Code',9) --fund
               || LPAD('Priority',9) --prio
               || LPAD('Award',12) --min
               || LPAD('Award',12) --max
               || LPAD('Percent',8) --percent
               || ' '
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
                   || LPAD(c_rprgfnd_priority,9) --prio
                   || LPAD(c_rprgfnd_min_award,12) --min
                   || LPAD(c_rprgfnd_max_award,12) --max
                   || LPAD(c_rprgfnd_unmet_need_pct,8) --percent
                   || ' '
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


--section 9

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Direct Loan Processing Module ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);

  --Section Header 9.1
    utl_file.put_line(f_dat_file_OUT,'Report 9.1 - SAY Code Validation Review ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('SAY',16)
               || RPAD('SAY',31)
               || 'Active';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',16)
               || RPAD('Description',31)
               || 'Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);


    OPEN c_report9_1;
    LOOP
        FETCH c_report9_1
            INTO c_rtvsayr_code
                ,c_rtvsayr_desc
                ,c_rtvsayr_active_ind;
        EXIT WHEN c_report9_1%notfound;
        f_line_OUT := RPAD(c_rtvsayr_code,16)
                   || RPAD(c_rtvsayr_desc,31)
                   || c_rtvsayr_active_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report9_1;  

  --Section Header 9.2
    utl_file.put_line(f_dat_file_OUT,'Report 9.2 - SAY Start and End Dates ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',5)
               || RPAD('SAY',16)
               || RPAD('Type',5)
               || RPAD('Start',10)
               || 'End';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',5)
               || RPAD('Code',16)
               || RPAD('Ind',5)
               || RPAD('Date',10)
               || 'Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report9_2;
    LOOP
        FETCH c_report9_2
            INTO c_robsayr_aidy_code
                ,c_robsayr_sayr_code
                ,c_robsayr_type_ind
                ,c_robsayr_start_date
                ,c_robsayr_end_date;
        EXIT WHEN c_report9_2%notfound;
        f_line_OUT := RPAD(c_robsayr_aidy_code,5)
                   || RPAD(c_robsayr_sayr_code,16)
                   || RPAD(c_robsayr_type_ind,5)
                   || RPAD(c_robsayr_start_date,10)
                   || c_robsayr_end_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report9_2;
  
  --Section Header 9.3
    utl_file.put_line(f_dat_file_OUT,'Report 9.3 - SAY Periods ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',5)
               || RPAD('Aid',7)
               || RPAD('SAY',16)
               || RPAD('SAY',16)
               || RPAD('Start',10)
               || 'End';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',5)
               || RPAD('Period',7)
               || RPAD('Code',16)
               || RPAD('Period',16)
               || RPAD('Date',10)
               || 'Date';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report9_3;
    LOOP
        FETCH c_report9_3
            INTO c_rorsayr_aidy_code
                ,c_rortprd_aprd_code
                ,c_rorsayr_sayr_code
                ,c_rorsayr_period
                ,c_rortprd_start_date
                ,c_rortprd_end_date;
        EXIT WHEN c_report9_3%notfound;
        f_line_OUT := RPAD(c_rorsayr_aidy_code,5)
               || RPAD(c_rortprd_aprd_code,7)
               || RPAD(c_rorsayr_sayr_code,16)
               || RPAD(c_rorsayr_period,16)
               || RPAD(c_rortprd_start_date,10)
               || c_rortprd_end_date;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report9_3;    
  
  --Section Header 9.4
    utl_file.put_line(f_dat_file_OUT,'Report 9.4 - SAY Disbursement ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',5)
               || RPAD('SAY',16)
               || RPAD('SAY',16)
               || RPAD('Disburse',10)
               || LPAD('Schedule',9)
               || ' ' 
               || 'Multi';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',5)
               || RPAD('Code',16)
               || RPAD('Period',16)
               || RPAD('Date',10)
               || LPAD('Days',9)
               || ' '
               || 'Disb';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report9_4;
    LOOP
        FETCH c_report9_4
            INTO c_rorsayd_aidy_code
                ,c_rorsayd_sayr_code
                ,c_rorsayd_period
                ,c_rorsayd_disburse_date
                ,c_rorsayd_disb_sched_no_days
                ,c_message_text;
        EXIT WHEN c_report9_4%notfound;
        f_line_OUT := RPAD(c_rorsayd_aidy_code,5)
                   || RPAD(c_rorsayd_sayr_code,16)
                   || RPAD(c_rorsayd_period,16)
                   || RPAD(c_rorsayd_disburse_date,10)
                   || LPAD(c_rorsayd_disb_sched_no_days,9)
                   || ' '
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report9_4;  
  
  --Section Header 9.5  
    utl_file.put_line(f_dat_file_OUT,'Report 9.5 - BBAY Start and End Dates ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('BBAY',16)
               || RPAD(' ',31)
               || RPAD('Start',10)
               || RPAD('End',10)
               || RPAD('Act',4)
               || RPAD('Split',6)
               || RPAD('Max',4)
               || RPAD('BBAY',11)
               || 'Bud';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',16)
               || RPAD('Description',31)
               || RPAD('Date',10)
               || RPAD('Date',10)
               || RPAD('Ind',4)
               || RPAD('Ind',6)
               || RPAD('Ind',4)
               || RPAD('Type',11)
               || 'Dur';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report9_5;
    LOOP
        FETCH c_report9_5
            INTO c_robbbay_bbay_code
                ,c_robbbay_desc
                ,c_robbbay_start_date
                ,c_robbbay_end_date
                ,c_robbbay_active_ind
                ,c_robbbay_split_ind
                ,c_robbbay_max_elig_ind
                ,c_robbbay_bbtp_code
                ,c_robbbay_budg_dur;
        EXIT WHEN c_report9_5%notfound;
        f_line_OUT := RPAD(c_robbbay_bbay_code,16)
                   || RPAD(c_robbbay_desc,31)
                   || RPAD(c_robbbay_start_date,10)
                   || RPAD(c_robbbay_end_date,10)
                   || RPAD(c_robbbay_active_ind,4)
                   || RPAD(c_robbbay_split_ind,6)
                   || RPAD(c_robbbay_max_elig_ind,4)
                   || RPAD(c_robbbay_bbtp_code,11)
                   || c_robbbay_budg_dur;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report9_5;  

  --Section Header 9.6
    utl_file.put_line(f_dat_file_OUT,'Report 9.6 - BBAY Periods ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',16)
               || RPAD(' ',16)
               || RPAD(' ',10)
               || RPAD(' ',10)
               || LPAD('Est',12);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('BBAY',16)
               || RPAD('BBAY',16)
               || RPAD('Start',10)
               || RPAD('End',10)
               || LPAD('Budget',12);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',16)
               || RPAD('Period',16)
               || RPAD('Date',10)
               || RPAD('Date',10)
               || LPAD('Amt',12);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report9_6;
    LOOP
        FETCH c_report9_6
            INTO c_rorbbay_bbay_code
                ,c_rorbbay_period
                ,c_rorbbay_start_date
                ,c_robbbay_end_date
                ,c_rorbbay_est_budget_amt;
        EXIT WHEN c_report9_6%notfound;
        f_line_OUT := RPAD(c_rorbbay_bbay_code,16)
                   || RPAD(c_rorbbay_period,16)
                   || RPAD(c_rorbbay_start_date,10)
                   || RPAD(c_robbbay_end_date,10)
                   || LPAD(to_char(c_rorbbay_est_budget_amt,'999,999,990'),12);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report9_6;  
  
  --Section Header 9.7
    utl_file.put_line(f_dat_file_OUT,'Report 9.7 - BBAY Disbursement ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('BBAY',16)
               || RPAD('SAY',16)
               || RPAD('Disburse',10)
               || RPAD('Schedule',9)
               || 'Multi';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',16)
               || RPAD('Period',16)
               || RPAD('Date',10)
               || RPAD('Days',9)
               || 'Disb';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report9_7;
    LOOP
        FETCH c_report9_7
            INTO c_rorbayd_bbay_code
                ,c_rorbayd_period
                ,c_rorbayd_disburse_date
                ,c_rorbayd_disb_sched_no_days
                ,c_message_text;
        EXIT WHEN c_report9_7%notfound;
        f_line_OUT := RPAD(c_rorbayd_bbay_code,16)
                   || RPAD(c_rorbayd_period,16)
                   || RPAD(c_rorbayd_disburse_date,10)
                   || LPAD(c_rorbayd_disb_sched_no_days,9)
                   || c_message_text;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report9_7;
    
--section 10  

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Electronic Data Exchange Module ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);

  --Section Header 10.1
    utl_file.put_line(f_dat_file_OUT,'Report 10.1 - Pell Grant Options Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',7)
               || RPAD('Auto',6)
               || RPAD(' ',9)
               || RPAD(' ',9)
               || RPAD(' ',6)
               || RPAD(' ',6)
               || LPAD(' ',4);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid',7)
               || RPAD('Pell',6)
               || RPAD(' ',9)
               || RPAD(' ',9)
               || RPAD('Pell',6)
               || RPAD('Pell',6)
               || LPAD(' ',4);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',7)
               || RPAD('Calc',6)
               || RPAD('Reduced',9)
               || RPAD('Cash',9)
               || RPAD('LTHT',6)
               || RPAD('JIT',6)
               || LPAD('JIT',4);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',7)
               || RPAD('Off',6)
               || RPAD('Elig',9)
               || RPAD('Monitor',9)
               || RPAD('Ind',6)
               || RPAD('Ind',6)
               || LPAD('Days',4);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report10_1;
    LOOP
        FETCH c_report10_1
            INTO c_robinst_aidy_code
                ,c_robinst_turn_off_pell_ind
                ,c_robinst_pell_red_elig_ind
                ,c_robinst_cash_monitor_ind
                ,c_robinst_pell_lt_half_ind
                ,c_robinst_just_in_time_ind
                ,c_robinst_jit_no_days;                
        EXIT WHEN c_report10_1%notfound;
        f_line_OUT := RPAD(c_robinst_aidy_code,7)
                   || RPAD(c_robinst_turn_off_pell_ind,6)
                   || RPAD(c_robinst_pell_red_elig_ind,9)
                   || RPAD(c_robinst_cash_monitor_ind,9)
                   || RPAD(c_robinst_pell_lt_half_ind,6)
                   || RPAD(c_robinst_just_in_time_ind,6)
                   || LPAD(c_robinst_jit_no_days,4);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report10_1;
  
  --Section Header 10.2
    utl_file.put_line(f_dat_file_OUT,'Report 10.2 - Teach Options Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',8)
               || RPAD('Teach',8)
               || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid',8)
               || RPAD('Entr',8)
               || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',8)
               || RPAD('Intv',8)
               || 'Req';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',8)
               || RPAD('Req',8)
               || 'Stat';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);

    OPEN c_report10_2;
    LOOP
        FETCH c_report10_2
            INTO c_robinst_aidy_code
                ,c_robinst_treq_code_teach_entr
                ,c_robinst_trst_code_teach_entr;                
        EXIT WHEN c_report10_2%notfound;
        f_line_OUT := RPAD(c_robinst_aidy_code,8)
                   || RPAD(c_robinst_treq_code_teach_entr,8)
                   || c_robinst_trst_code_teach_entr;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report10_2;
    
  --Section Header 10.3
    utl_file.put_line(f_dat_file_OUT,'Report 10.3 - EDE Options Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8)
               || RPAD('Update',8)
               || RPAD('SAR',6)
               || RPAD('SAR',6)
               || 'EDE';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',8)
               || RPAD('Tran',8)
               || RPAD('Req',6)
               || RPAD('Req',6)
               || 'Corr';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',8)
               || RPAD('EFC',8)
               || RPAD('Code',6)
               || RPAD('Stat',6)
               || 'Log';

    OPEN c_report10_3;
    LOOP
        FETCH c_report10_3
            INTO c_robinst_aidy_code
                ,c_robinst_upd_tran_ind
                ,c_robinst_treq_code_sar
                ,c_robinst_trst_code_sar
                ,c_robinst_pell_audit_ind;                
        EXIT WHEN c_report10_3%notfound;
        f_line_OUT := RPAD(c_robinst_aidy_code,8)
                   || RPAD(c_robinst_upd_tran_ind,8)
                   || RPAD(c_robinst_treq_code_sar,6)
                   || RPAD(c_robinst_trst_code_sar,6)
                   || c_robinst_pell_audit_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report10_3;
  
  --Section Header 10.4
    utl_file.put_line(f_dat_file_OUT,'Report 10.4 - COD Entity ID Rules Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8)
               || RPAD(' ',10)
               || RPAD(' ',10)
               || RPAD(' ',10)
               || RPAD(' ',8)
               || RPAD('Direct',8)
               || RPAD(' ',8)
               || RPAD(' ',6)
               || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',8)
               || RPAD('Attend',10)
               || RPAD('Report',10)
               || RPAD('Source',10)
               || RPAD('Pell',8)
               || RPAD('Loan',8)
               || RPAD('OPE',8)
               || RPAD('Br',6)
               || 'Inst';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',8)
               || RPAD('ID',10)
               || RPAD('ID',10)
               || RPAD('ID',10)
               || RPAD('ID',8)
               || RPAD('ID',8)
               || RPAD('ID',8)
               || RPAD('ID',6)
               || 'Def';

    OPEN c_report10_4;
    LOOP
        FETCH c_report10_4
            INTO c_rorcodi_aidy_code
                ,c_rorcodi_attending_id
                ,c_rorcodi_reporting_id
                ,c_rorcodi_source_id
                ,c_rorcodi_pell_id
                ,c_rorcodi_dl_school_code
                ,c_rorcodi_opeid
                ,c_rorcodi_opeid_branch
                ,c_rorcodi_inst_default_ind;                
        EXIT WHEN c_report10_4%notfound;
        f_line_OUT := RPAD(c_rorcodi_aidy_code,8)
                   || RPAD(c_rorcodi_attending_id,10)
                   || RPAD(c_rorcodi_reporting_id,10)
                   || RPAD(c_rorcodi_source_id,10)
                   || RPAD(c_rorcodi_pell_id,8)
                   || RPAD(c_rorcodi_dl_school_code,8)
                   || RPAD(c_rorcodi_opeid,8)
                   || RPAD(c_rorcodi_opeid_branch,6)
                   || c_rorcodi_inst_default_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report10_4;
  
  --Section Header 10.5
    utl_file.put_line(f_dat_file_OUT,'Report 10.5 - Campus Defaults Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',8)
               || RPAD(' ',8)
               || RPAD(' ',10)
               || RPAD(' ',8)
               || RPAD('Pell',8)
               || RPAD('Federal',8)
               || RPAD(' ',8)
               || RPAD(' ',4)
               || RPAD('Direct',8)
               || RPAD(' ',8)
               || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',8)
               || RPAD('Campus',8)
               || RPAD('Attend',10)
               || RPAD('Pell',8)
               || RPAD('Fund',8)
               || RPAD('School',8)
               || RPAD('OPE',8)
               || RPAD('Br',4)
               || RPAD('Loan',8)
               || RPAD('EL',8)
               || 'EL';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',8)
               || RPAD('Code',8)
               || RPAD('ID',10)
               || RPAD('ID',8)
               || RPAD('Code',8)
               || RPAD('Code',8)
               || RPAD('ID',8)
               || RPAD('ID',4)
               || RPAD('Code',8)
               || RPAD('Code',8)
               || 'Br';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);               

    OPEN c_report10_5;
    LOOP
        FETCH c_report10_5
            INTO c_rorcamp_aidy_code
                ,c_rorcamp_camp_code
                ,c_rorcamp_common_school_id
                ,c_rorcamp_pell_id
                ,c_rorcamp_pell_fund_code
                ,c_rorcamp_fed_school_code
                ,c_rorcamp_opeid
                ,c_rorcamp_opeid_branch
                ,c_rorcamp_dl_school_code
                ,c_rorcamp_el_school_cde
                ,c_rorcamp_el_branch_cde;
        EXIT WHEN c_report10_5%notfound;
        f_line_OUT := RPAD(c_rorcamp_aidy_code,8)
                   || RPAD(c_rorcamp_camp_code,8)
                   || RPAD(c_rorcamp_common_school_id,10)
                   || RPAD(c_rorcamp_pell_id,8)
                   || RPAD(c_rorcamp_pell_fund_code,8)
                   || RPAD(c_rorcamp_fed_school_code,8)
                   || RPAD(c_rorcamp_opeid,8)
                   || RPAD(c_rorcamp_opeid_branch,4)
                   || RPAD(c_rorcamp_dl_school_code,8)
                   || RPAD(c_rorcamp_el_school_cde,8)
                   || c_rorcamp_el_branch_cde;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report10_5;  

--section 11

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Student Employment Module ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);

  --Section Header 11.1
    utl_file.put_line(f_dat_file_OUT,'Report 11.1 - Payroll Load Control ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',6)
               || RPAD('Pay',6)
               || RPAD(' ',6)
               || RPAD(' ',4)
               || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',6)
               || RPAD('ID',6)
               || RPAD('PICT',6)
               || RPAD('Pay',4)
               || 'Process';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',6)
               || RPAD('Year',6)
               || RPAD('Code',6)
               || RPAD('No',4)
               || 'Ind';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);               

    OPEN c_report11_1;
    LOOP
        FETCH c_report11_1
            INTO c_rjrpayl_aidy_code
                ,c_rjrpayl_year
                ,c_rjrpayl_pict_code
                ,c_rjrpayl_payno
                ,c_rjrpayl_process_ind;
        EXIT WHEN c_report11_1%notfound;
        f_line_OUT := RPAD(c_rjrpayl_aidy_code,6)
                   || RPAD(c_rjrpayl_year,6)
                   || RPAD(c_rjrpayl_pict_code,6)
                   || RPAD(c_rjrpayl_payno,4)
                   || c_rjrpayl_process_ind;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report11_1;    
  
  --Section Header 11.2
    utl_file.put_line(f_dat_file_OUT,'Report 11.2 - Placement Rules Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',6)
               || RPAD(' ',10)
               || RPAD(' ',7)
               || RPAD(' ',31)
               || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',6)
               || RPAD('Placement',10)
               || RPAD('Posn',7)
               || RPAD('Posn',31)
               || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',6)
               || RPAD('Code',10)
               || RPAD('Code',7)
               || RPAD('Title',31)
               || LPAD('Allocation',15);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);               

    OPEN c_report11_2;
    LOOP
        FETCH c_report11_2
            INTO c_rjrplrl_aidy_code
                ,c_rjrplrl_place_cde
                ,c_rjrplrl_posn
                ,c_rjrplrl_posn_title
                ,c_rjrplrl_allocation;
        EXIT WHEN c_report11_2%notfound;
        f_line_OUT := RPAD(c_rjrplrl_aidy_code,6)
                   || RPAD(c_rjrplrl_place_cde,10)
                   || RPAD(c_rjrplrl_posn,7)
                   || RPAD(c_rjrplrl_posn_title,31)
                   || LPAD(to_char(c_rjrplrl_allocation,'999,999,990.99'),15);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report11_2;   
  
  --Section Header 11.3
    utl_file.put_line(f_dat_file_OUT,'Report 11.3 - Placement Base Data Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Placement',10)
               || RPAD('Placement',31)
               || ' ';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',10)
               || RPAD('Description',31)
               || 'Supervisor';
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);             

    OPEN c_report11_3;
    LOOP
        FETCH c_report11_3
            INTO c_rjbplbd_place_cde
                ,c_rjbplbd_place_desc
                ,c_rjbplbd_supervisor;
        EXIT WHEN c_report11_3%notfound;
        f_line_OUT := RPAD(c_rjbplbd_place_cde,10)
               || RPAD(c_rjbplbd_place_desc,31)
               || c_rjbplbd_supervisor;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report11_3;   
  
  --Section Header 11.4
    utl_file.put_line(f_dat_file_OUT,'Report 11.4 - Job Title Base Data Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Job',7)
               || RPAD(' ',22)
               || RPAD('Hrly',5)
               || LPAD('Pay',10)
               || LPAD('Pay',10)
               || LPAD('Pay',10);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Title',7)
               || RPAD('Job Title',22)
               || RPAD('Pay',5)
               || LPAD('Range',10)
               || LPAD('Range',10)
               || LPAD('Range',10);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);             
    f_line_OUT := RPAD('Code',7)
               || RPAD('Description',22)
               || RPAD('Ind',5)
               || LPAD('Low',10)
               || LPAD('High',10)
               || LPAD('Default',10);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE); 
    
    OPEN c_report11_4;
    LOOP
        FETCH c_report11_4
            INTO c_rjbjobt_code
                ,c_rjbjobt_desc
                ,c_rjbjobt_hrly_pay_ind
                ,c_rjbjobt_pay_range_low
                ,c_rjbjobt_pay_range_high
                ,c_rjbjobt_default_pay;                
        EXIT WHEN c_report11_4%notfound;
        f_line_OUT := RPAD(c_rjbjobt_code,7)
               || RPAD(c_rjbjobt_desc,22)
               || RPAD(c_rjbjobt_hrly_pay_ind,5)
               || LPAD(to_char(c_rjbjobt_pay_range_low,'99,990.99'),10)
               || LPAD(to_char(c_rjbjobt_pay_range_high,'99,990.99'),10)               
               || LPAD(to_char(c_rjbjobt_default_pay,'99,990.99'),10);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report11_4;  
  
  --Section Header 11.5
    utl_file.put_line(f_dat_file_OUT,'Report 11.5 - Job Title Requirements Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Job',7)
               || RPAD(' ',73);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Title',7)
               || RPAD('Job Requirements',73);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);             
    
    OPEN c_report11_5;
    LOOP
        FETCH c_report11_5
            INTO c_rjbjobt_code
                ,c_rjbjobt_requirements;
        EXIT WHEN c_report11_5%notfound;
        f_line_OUT := RPAD(c_rjbjobt_code,7)              
                   || c_rjbjobt_requirements;
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report11_5;   
  
  --Section Header 11.6
    utl_file.put_line(f_dat_file_OUT,'Report 11.6 - Student Employment Default Rules Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',7)
               || RPAD('Auth',10)
               || RPAD('Auth',10)
               || RPAD('Pay',10)
               || RPAD('Pay',10)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',7)
               || RPAD('Start',10)
               || RPAD('End',10)
               || RPAD('Start',10)
               || RPAD('End',10)
               || RPAD('Auth',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',7)
               || RPAD('Date',10)
               || RPAD('Date',10)
               || RPAD('Date',10)
               || RPAD('Date',10)
               || RPAD('Status',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report11_6;
    LOOP
        FETCH c_report11_6
            INTO c_rjbsedr_aidy_code
                ,c_rjbsedr_auth_start_date
                ,c_rjbsedr_auth_end_date
                ,c_rjbsedr_pay_start_date
                ,c_rjbsedr_pay_end_date
                ,c_rjbsedr_aust_code;
        EXIT WHEN c_report11_6%notfound;
        f_line_OUT := RPAD(c_rjbsedr_aidy_code,7)
                   || RPAD(c_rjbsedr_auth_start_date,10)
                   || RPAD(c_rjbsedr_auth_end_date,10)
                   || RPAD(c_rjbsedr_pay_start_date,10)
                   || RPAD(c_rjbsedr_pay_end_date,10)
                   || RPAD(c_rjbsedr_aust_code,7);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report11_6;   

--section 12

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Athletic Module ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);

  --Section Header 12.1
    utl_file.put_line(f_dat_file_OUT,'Report 12.1 - Sport Codes Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Sport',9)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',9)
               || RPAD('Description',31)
               || RPAD('Active',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report12_1;
    LOOP
        FETCH c_report12_1
            INTO c_rtvfasp_code
                ,c_rtvfasp_desc
                ,c_rtvfasp_active_ind;
        EXIT WHEN c_report12_1%notfound;
        f_line_OUT := RPAD(c_rtvfasp_code,9)
                   || RPAD(c_rtvfasp_desc,31)
                   || RPAD(c_rtvfasp_active_ind,7);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report12_1;    
  
  --Section Header 12.2
    utl_file.put_line(f_dat_file_OUT,'Report 12.2 - Athletic Aid Type Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Athletic',13)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Aid',13)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',13)
               || RPAD('Description',31)
               || RPAD('Active',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report12_2;
    LOOP
        FETCH c_report12_2
            INTO c_rtvaatp_code
                ,c_rtvaatp_desc
                ,c_rtvaatp_active_ind;
        EXIT WHEN c_report12_2%notfound;
        f_line_OUT := RPAD(c_rtvaatp_code,13)
                   || RPAD(c_rtvaatp_desc,31)
                   || RPAD(c_rtvaatp_active_ind,7);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report12_2;   
  
  --Section Header 12.3
    utl_file.put_line(f_dat_file_OUT,'Report 12.3 - Potential Athletic Grant Defaults Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',7)
               || LPAD(' ',15)
               || LPAD(' ',15);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',7)
               || LPAD('In State',15)
               || LPAD('Out of State',15);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',7)
               || LPAD('Amount',15)
               || LPAD('Amount',15);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report12_3;
    LOOP
        FETCH c_report12_3
            INTO c_rarpagd_aidy_code
                ,c_rarpagd_in_state_amt
                ,c_rarpagd_out_state_amt;
        EXIT WHEN c_report12_3%notfound;
        f_line_OUT := RPAD(c_rarpagd_aidy_code,7)
                   || LPAD(TO_CHAR(c_rarpagd_in_state_amt,'999,999,990.99'),15)
                   || LPAD(TO_CHAR(c_rarpagd_out_state_amt,'999,999,990.99'),15);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report12_3;   
  
  --Section Header 12.4
    utl_file.put_line(f_dat_file_OUT,'Report 12.4 - Sport Potential Athletic Grant Defaults Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Aid',7)
               || RPAD(' ',9)
               || LPAD(' ',15)
               || LPAD(' ',15);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Year',7)
               || RPAD('Sport',9)
               || LPAD('In State',15)
               || LPAD('Out of State',15);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',7)
               || RPAD('Code',9)
               || LPAD('Amount',15)
               || LPAD('Amount',15);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report12_4;
    LOOP
        FETCH c_report12_4
            INTO c_rarpags_aidy_code
                ,c_rarpags_fasp_code
                ,c_rarpags_in_state_amt
                ,c_rarpags_out_state_amt;
        EXIT WHEN c_report12_4%notfound;
        f_line_OUT := RPAD(c_rarpags_aidy_code,7)
                   || RPAD(c_rarpags_fasp_code,9)
                   || LPAD(TO_CHAR(c_rarpags_in_state_amt,'999,999,990.99'),15)
                   || LPAD(TO_CHAR(c_rarpags_out_state_amt,'999,999,990.99'),15);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report12_4;    
  
--section 13

    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'                   Scholarship Module ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    utl_file.put_line(f_dat_file_OUT,'=======================================================================',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);

  --Section Header 13.1
    utl_file.put_line(f_dat_file_OUT,'Report 13.1 - Scholarship Source Codes Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Scholarship',13)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Source',13)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',13)
               || RPAD('Description',31)
               || RPAD('Active',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report13_1;
    LOOP
        FETCH c_report13_1
            INTO c_rtvssrc_code
                ,c_rtvssrc_desc
                ,c_rtvssrc_active_ind;
        EXIT WHEN c_report13_1%notfound;
        f_line_OUT := RPAD(c_rtvssrc_code,13)
                   || RPAD(c_rtvssrc_desc,31)
                   || RPAD(c_rtvssrc_active_ind,7);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report13_1;     
  
  --Section Header 13.2
    utl_file.put_line(f_dat_file_OUT,'Report 13.2 - Thank You Letter Codes Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Thank You',13)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Letter',13)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',13)
               || RPAD('Description',31)
               || RPAD('Active',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report13_2;
    LOOP
        FETCH c_report13_2
            INTO c_rtvtylt_code
                ,c_rtvtylt_desc
                ,c_rtvtylt_active_ind;
        EXIT WHEN c_report13_2%notfound;
        f_line_OUT := RPAD(c_rtvtylt_code,13)
                   || RPAD(c_rtvtylt_desc,31)
                   || RPAD(c_rtvtylt_active_ind,7);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report13_2;     
  
  --Section Header 13.3  
    utl_file.put_line(f_dat_file_OUT,'Report 13.3 - Grades To Donor Codes Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Grade To',13)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Donor',13)
               || RPAD(' ',31)
               || RPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Codes',13)
               || RPAD('Description',31)
               || RPAD('Active',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report13_3;
    LOOP
        FETCH c_report13_3
            INTO c_rtvtylt_code
                ,c_rtvtylt_desc
                ,c_rtvtylt_active_ind;
        EXIT WHEN c_report13_3%notfound;
        f_line_OUT := RPAD(c_rtvtylt_code,13)
                   || RPAD(c_rtvtylt_desc,31)
                   || RPAD(c_rtvtylt_active_ind,7);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report13_3;   
  
  --Section Header 13.4
    utl_file.put_line(f_dat_file_OUT,'Report 13.4 - Scholarship Demographics Report 1 ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',13)
               || RPAD('Multi',7)
               || RPAD(' ',11)
               || RPAD('Tuition',8)
               || LPAD(' ',8)
               || LPAD(' ',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Fund',13)
               || RPAD('Donor',7)
               || RPAD('Restricted',11)
               || RPAD('Waiver',8)
               || LPAD('Max',8)
               || LPAD('Min',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',13)
               || RPAD('Ind',7)
               || RPAD('Ind',11)
               || RPAD('Ind',8)
               || LPAD('Periods',8)
               || LPAD('Enroll',7);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report13_4;
    LOOP
        FETCH c_report13_4
            INTO c_rfrsdem_fund_code
                ,c_rfrsdem_multiple_donor_ind
                ,c_rfrsdem_restricted_ind
                ,c_rfrsdem_tuition_waiver_ind
                ,c_rfrsdem_maximum_terms
                ,c_rfrsdem_min_enrollment;
        EXIT WHEN c_report13_4%notfound;
        f_line_OUT := RPAD(c_rfrsdem_fund_code,13)
                   || RPAD(c_rfrsdem_multiple_donor_ind,7)
                   || RPAD(c_rfrsdem_restricted_ind,11)
                   || RPAD(c_rfrsdem_tuition_waiver_ind,8)
                   || LPAD(c_rfrsdem_maximum_terms,8)
                   || LPAD(c_rfrsdem_min_enrollment,7);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report13_4;    
  
  --Section Header 13.5
    utl_file.put_line(f_dat_file_OUT,'Report 13.5 - Scholarship Demographics Report 2 ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD('Fund',13)
               || RPAD('Scholarship',12)
               || RPAD(' ',8)
               || RPAD(' ',31);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('Code',13)
               || RPAD('Source',12)
               || RPAD('Dept',8)
               || RPAD('Primary User',31);
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report13_5;
    LOOP
        FETCH c_report13_5
            INTO c_rfrsdem_fund_code
                ,c_rfrsdem_ssrc_code
                ,c_rfrsdem_dept_code
                ,c_rfrsdem_primary_user_name;
        EXIT WHEN c_report13_5%notfound;
        f_line_OUT := RPAD(c_rfrsdem_fund_code,13)
                   || RPAD(c_rfrsdem_ssrc_code,12)
                   || RPAD(c_rfrsdem_dept_code,8)
                   || RPAD(c_rfrsdem_primary_user_name,31);
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report13_5;    

  --Section Header 13.6
    utl_file.put_line(f_dat_file_OUT,'Report 13.6 - Scholarship Donor Demographics Report ',FALSE);
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    f_line_OUT := '';
    f_line_OUT := RPAD(' ',13) --ID code
               || RPAD(' ',16) --Name
               || RPAD(' ',7) --Fund Code
               || RPAD(' ',5) --Primary Ind
               || RPAD('Recpt',7) --Receipt Inv Ind
               || RPAD(' ',7) --Donor
               || RPAD(' ',5) --Anon Ind
               || RPAD(' ',7) --Grade Code
               || RPAD(' ',7); --Donor Letter
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD(' ',13) --ID code
               || RPAD(' ',16) --Name
               || RPAD('Fund',7) --Fund Code
               || RPAD('Pri',5) --Primary Ind
               || RPAD('Inv',7) --Receipt Inv Ind
               || RPAD('Donor',7) --Donor
               || RPAD('Anon',5) --Anon Ind
               || RPAD('Grade',7) --Grade Code
               || RPAD('Donor',7); --Donor Letter
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    f_line_OUT := RPAD('ID Code',13) --ID code
               || RPAD('Name',16) --Name
               || RPAD('Code',7) --Fund Code
               || RPAD('Ind',5) --Primary Ind
               || RPAD('Ind',7) --Receipt Inv Ind
               || RPAD('Select',7) --Donor
               || RPAD('Ind',5) --Anon Ind
               || RPAD('Code',7) --Grade Code
               || RPAD('Ltr',7); --Donor Letter
    utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    
    OPEN c_report13_6;
    LOOP
        FETCH c_report13_6
            INTO c_spriden_id
                ,c_spriden_last_name
                ,c_rfrdnrd_fund_code
                ,c_rfrdnrd_primary_donor_ind
                ,c_rfrdnrd_recept_invitation_in
                ,c_rfrdnrd_donor_selection_ind
                ,c_rfrdnrd_anonymous_ind
                ,c_rfrdnrd_grades
                ,c_rfrdnrd_letter;
        EXIT WHEN c_report13_6%notfound;
        f_line_OUT := RPAD(c_spriden_id,13) --ID code
               || RPAD(c_spriden_last_name,16) --Name
               || RPAD(c_rfrdnrd_fund_code,7) --Fund Code
               || RPAD(c_rfrdnrd_primary_donor_ind,5) --Primary Ind
               || RPAD(c_rfrdnrd_recept_invitation_in,7) --Receipt Inv Ind
               || RPAD(c_rfrdnrd_donor_selection_ind,7) --Donor
               || RPAD(c_rfrdnrd_anonymous_ind,5) --Anon Ind
               || RPAD(c_rfrdnrd_grades,7) --Grade Code
               || RPAD(c_rfrdnrd_letter,7); --Donor Letter
        utl_file.put_line(f_dat_file_OUT,f_line_OUT,FALSE);
    END LOOP;
    utl_file.put_line(f_dat_file_OUT,'',FALSE);
    CLOSE c_report13_6;  

    --Close File
    utl_file.fclose(f_dat_file_OUT);

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE nsudev.nysoutp';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE nsudev.nysoutp(
            nysoutp_line    char(1500)
        )
        ORGANIZATION EXTERNAL (
            TYPE ORACLE_LOADER
            DEFAULT DIRECTORY U13_STUDENT
            ACCESS PARAMETERS (
                RECORDS DELIMITED BY NEWLINE
                FIELDS(nysoutp_line    char(1500))
            )
            LOCATION (''nys_textout.txt'')
        )';

    END;

END;