select
      '1.01.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual

union
select '1.01.000001'
      ,'Report 1.1 If Disb Load > Pckg Load'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.01.000002'
       ,'Aid Year'
       ,'Fund' 
       ,'Proration!Ind'
       ,'3/4 Time'
       ,'1/2 Time'
       ,'< 1/2 Time'
       ,'Studs With Load!Not Equal 1'    
from dual

union

select 
    '1.01.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,fund
    ,pro
    ,to_char(per2)
    ,to_char(per3)
    ,to_char(per4)
    ,to_char(stu)
from (
SELECT
	rfraspc_aidy_code aidy,
	rfraspc_fund_code fund,
	decode(rfraspc_proration_ind,'P','Prorate','D','Disb 100%','N','No Disb') pro,
	decode(rfraspc_proration_ind,'P',rfraspc_3quarter_load_pct,null) per2,
	decode(rfraspc_proration_ind,'P',rfraspc_half_load_pct,null) per3,
	decode(rfraspc_proration_ind,'P',rfraspc_less_half_load_pct,null) per4,
	decode(xpload.xload,0,'N','Y') stu
    ,rownum rn
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
		rpratrm_aidy_code = :parm_DD_AidYear
		and rpratrm_period = :parm_DD_Period
		and rpratrm_accept_amt > 0
	group by
		rpratrm_aidy_code,
		rpratrm_fund_code,
	        rpratrm_period) xpload
WHERE
	rfraspc_aidy_code = :parm_DD_AidYear
	and ((rfraspc_disburse_ind <> 'N')
	or (rfraspc_disburse_ind = 'N'
	and rfraspc_loan_process_ind = 'Y'))
	and xpload.xfund = rfraspc_fund_code
	and xpload.xaidy = rfraspc_aidy_code
)
union

select
      '1.02.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual

union
select '1.02.000001'
      ,'Report 1.2 Attending Hours by Fund'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.02.000002'
       ,'Aid Year'
       ,'Fund' 
       ,'Attend'
       ,'Days'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '1.02.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,fund
    ,attd
    ,to_char(xdays)
    ,' '
    ,' '
    ,' '
from(
SELECT
	rfraspc_aidy_code aidy,
	rfraspc_fund_code fund,
	decode(rfraspc_attending_hr_ind,'Y','Yes','No') attd,
	nvl(rfraspc_disb_no_days,0) xdays
    , rownum rn
FROM
	rfraspc
WHERE
	rfraspc_aidy_code = :parm_DD_AidYear
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
			and rpratrm_period = :parm_DD_Period)
)

union
select
      '1.03.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual

union
select '1.03.000001'
      ,'Report 1.3 Enrollment Code by Fund'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.03.000002'
       ,'Aid Year'
       ,'Fund' 
       ,'Enrollment!Code'
       ,' '
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '1.03.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,fund
    ,enrr
    ,' '
    ,' '
    ,' '
    ,' '
from(
SELECT
	rfraspc_aidy_code aidy,
	decode(rfraspc_enrr_code,null,'*****',rfraspc_enrr_code) enrr,
	rfraspc_fund_code fund
    , rownum rn
FROM
	rfraspc
WHERE
	rfraspc_aidy_code = :parm_DD_AidYear
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
			and rpratrm_period = :parm_DD_Period)
)
union

select '1.04.000000'
      , null
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual
union
select '1.04.000001'
      ,'Report 1.4 Disb Enrollment Edits for Memo'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.04.000002'
       ,'Aid Year'
       ,'Fund' 
       ,'Disb Edits!Code'
       ,' '
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '1.04.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,fund
    ,xmem
    ,' '
    ,' '
    ,' '
    ,' '
from(
SELECT
	rfraspc_aidy_code aidy,
	rfraspc_fund_code fund,
	nvl(rfraspc_use_disb_enrl_memo_ind,'N') xmem
    ,rownum rn
FROM
	rfraspc
WHERE
	rfraspc_aidy_code = :parm_DD_AidYear
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
			and rpratrm_period = :parm_DD_Period))
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
			and rpratrm_period = :parm_DD_Period)))
)
union

select
      '1.05.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual

union

select '1.05.000001'
      ,'Report 1.5 Recoup When Award Reduced!Report 1.5'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.05.000002'
       ,'Aid Year'
       ,'Fund' 
       ,'Disbursement!Ind'
       ,'Recoup when!Reduced Code'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '1.05.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,fund
    ,dind
    ,xcoup
    ,' '
    ,' '
    ,' '
from(
SELECT
	rfraspc_aidy_code aidy,
	rfraspc_fund_code fund,
	decode(rfraspc_disburse_ind,'S','System','M','Manual','**') dind,
	nvl(rfraspc_recoup_ind,'N') xcoup
    , rownum rn
FROM
	rfraspc
WHERE
	rfraspc_aidy_code = :parm_DD_AidYear
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
			and rpratrm_period = :parm_DD_Period)
)
union

select
      '1.06.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '1.06.000001'
      ,'Report 1.6 Ineligible Before/After Settings by Fund'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.06.000002'
       ,'Aid Year'
       ,'Fund' 
       ,'Period'
       ,'Cut Off!Date'
       ,'Before'
       ,'After'
       ,' '    
from dual
union
select 
    '1.06.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,fund
    ,per
    ,to_char(codate)
    ,bf
    ,af
    ,' '
from(
SELECT
	rfraspc_aidy_code aidy,
	rfraspc_fund_code fund,
	substr(rprdate_period,1,10) per,
	rprdate_cut_off_date codate,
	decode(rfraspc_inel_bef_cut_date_ind,'B','Backout','P','Pmt not App','D','Disregard','Error') bf,
	decode(rfraspc_inel_aft_cut_date_ind,'B','Backout','P','Pmt not App','D','Disregard','Error') af	
    , rownum rn
FROM
	rfraspc,
	rprdate
WHERE
	rfraspc_aidy_code = :parm_DD_AidYear
	and rfraspc_disburse_ind <> 'N'
	and rfraspc_aidy_code = rprdate_aidy_code
	and rprdate_period = :parm_DD_Period
	and exists
		(select 
			'x'
		from
			rpratrm
		where
			rpratrm_accept_amt > 0
			and rpratrm_aidy_code = rfraspc_aidy_code
			and rpratrm_fund_code = rfraspc_fund_code
			and rpratrm_period = :parm_DD_Period)
)
union

select
      '1.07.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual

union
select '1.07.000001'
      ,'Report 1.7 Funds With Disbursement Locks'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.07.000002'
       ,'Aid Year'
       ,'Fund' 
       ,'Period'
       ,' '
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '1.07.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,fund
    ,period
    ,' '
    ,' '
    ,' '
    ,' '
from(
SELECT
	rfrdlck_aidy_code aidy,
	rfrdlck_fund_code fund,
	rfrdlck_period period
    , rownum rn
FROM
	rfrdlck,
	rfraspc
WHERE
	rfrdlck_aidy_code = :parm_DD_AidYear
	and rfrdlck_period = :parm_DD_Period
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
)
union

select
      '1.08.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '1.08.000001'
      ,'Report 1.8 Scheduled Disbursement Dates for Non-Loan Funds'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.08.000002'
       ,'Aid Year'
       ,'Period' 
       ,'Fund'
       ,'Scheduled!Disbursement!Date'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '1.03.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,prd
    ,fund
    ,to_char(schdate)
    ,' '
    ,' '
    ,' '
from(
SELECT distinct
	rpradsb_aidy_code aidy,
	rpradsb_period prd,
	rpradsb_fund_code fund,
	rpradsb_schedule_date schdate
    , rownum rn
FROM
	rpradsb
WHERE
	rpradsb_aidy_code = :parm_DD_AidYear
	and rpradsb_period = :parm_DD_Period
	and rpradsb_disburse_pct is not null
	and rpradsb_tran_number is null
)
union

select
      '1.09.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '1.09.000001'
      ,'Scheduled Non-Loan Disbursements Outside Period Start/End Dates'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.09.000002'
       ,'Aid Year'
       ,'Period' 
       ,'Fund'
       ,'Scheduled!Disbursement!Date'
       ,'Count'
       ,' '
       ,' '    
from dual
union
select 
    '1.09.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,prd
    ,fund
    ,to_char(schdate)
    ,to_char(xcnt,'999,999')
    ,' '
    ,' '
from(
    select source_data.*
        ,rownum rn from(
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
                rpradsb_aidy_code = :parm_DD_AidYear
                and rpradsb_period = :parm_DD_Period
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
       )source_data
    )

union

select
      '1.10.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '1.10.000001'
      ,'Report 1.10 Scheduled Disbursement Dates for Loan Funds'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.10.000002'
       ,'Aid Year'
       ,'Period' 
       ,'Fund'
       ,'Scheduled!Disbursement!Date'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '1.10.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,prd
    ,fund
    ,to_char(schdate)
    ,' '
    ,' '
    ,' '
from(
    SELECT distinct
        rlrdldd_aidy_code aidy,
        rlrdldd_period prd,
        rlrdldd_fund_code fund,
        rlrdldd_sched_date schdate
        ,rownum rn
    FROM
        rlrdldd
    WHERE
        rlrdldd_aidy_code = :parm_DD_AidYear
        and rlrdldd_period = :parm_DD_Period
        and rlrdldd_seq_no = 1
        and rlrdldd_ar_tran_number is null
)
union

select
      '1.11.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '1.11.000001'
      ,'Report 1.11 Scheduled Loan Disbursements Outside Loan Period Start/End Dates'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '1.11.000002'
       ,'Aid Year'
       ,'Period' 
       ,'Fund'
       ,'Scheduled!Disbursement!Date'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '1.11.'|| trim(to_char(rn+2,'000000')) rn
    ,aidy
    ,prd
    ,fund
    ,to_char(schdate)
    ,' '
    ,' '
    ,' '
from(
    select source_data.*
        ,rownum rn
    from (
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
            rlrdldd_aidy_code = :parm_DD_AidYear
            and rlrdldd_period = :parm_DD_Period
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
    )SOURCE_DATA
)

union

select
      '2.01.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '2.01.000001'
      ,'Report 2.1 Identify Orphan RPRATRM Records'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '2.01.000002'
       ,'ID'
       ,'Fund' 
       ,' '
       ,' '
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '2.01.'|| trim(to_char(rn+2,'000000')) rn
    ,stu
    ,fnd
    ,' '
    ,' '
    ,' '
    ,' '
    ,' '
from(
    select source_data.*
        ,rownum rn
    from (
            SELECT 
                spriden_id stu,  
                rpratrm_fund_code fnd 
            FROM 	spriden,
                rpratrm   
            WHERE 
                spriden_pidm = rpratrm_pidm           
                and spriden_change_ind is null 
                and rpratrm_period = :parm_DD_Period
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
                and rprawrd_aidy_code = :parm_DD_AidYear
        )SOURCE_DATA
    )
union

select
      '2.02.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '2.02.000001'
      ,'Report 2.2 Orphan Memo Records'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '2.02.000002'
       ,'ID'
       ,'Fund' 
       ,' '
       ,' '
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '2.02.'|| trim(to_char(rn+2,'000000')) rn
    ,stu
    ,fnd
    ,' '
    ,' '
    ,' '
    ,' '
    ,' '
from( 
    select source_data.*
        , rownum rn
    from (
            SELECT  
                spriden_id stu,  
                rfrbase_fund_code fnd
            FROM 
                spriden, 
                tbrmemo, 
                rfrbase 
            WHERE 
                tbrmemo_detail_code = rfrbase_detail_code 
                and spriden_pidm = tbrmemo_pidm 
                and spriden_change_ind is null 
                and tbrmemo_period = :parm_DD_Period
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
                and rpratrm_period = :parm_DD_Period
        )SOURCE_DATA
    )
union

select
      '2.03.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '2.03.000001'
      ,'Report 2.3 Loan Fund or Disburse Manually/System and No Detail Code'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '2.03.000002'
       ,'Fund'
       ,'Loan Process' 
       ,'Disburse'
       ,'Detail Code'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '2.03.'|| trim(to_char(rn+2,'000000')) rn
    ,fund
    ,lnpr
    ,disb
    ,dtcd
    ,' '
    ,' '
    ,' '
from(
    SELECT 
        rfraspc_fund_code fund, 
        rfraspc_loan_process_ind lnpr, 
        rfraspc_disburse_ind disb, 
        rfrbase_detail_code dtcd
        ,rownum rn
    FROM 
        rfraspc, 
        rfrbase
    WHERE 
        rfraspc_aidy_code = :parm_DD_AidYear
        and (rfraspc_loan_process_ind = 'Y'
        or rfraspc_disburse_ind in ('M','S'))
        and rfraspc_fund_code = rfrbase_fund_code
        and rfrbase_detail_code is null
)
union

select
      '2.04.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '2.04.000001'
      ,'Report 2.4 Loan Fund or Disburse Manually/System and Inactive Detail Code'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '2.04.000002'
       ,'Aid Year'
       ,'Fund' 
       ,'Enrollment!Code'
       ,' '
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '2.04.'|| trim(to_char(rn+2,'000000')) rn
    ,fnd
    ,lnpr
    ,disb
    ,dtcd
    ,dtcin
    ,' '
    ,' '
from(
    SELECT 
        rfraspc_fund_code fnd, 
        rfraspc_loan_process_ind lnpr, 
        rfraspc_disburse_ind disb, 
        rfrbase_detail_code dtcd, 
        tbbdetc_detc_active_ind dtcin
        ,rownum rn
    FROM 
        rfraspc, 
        rfrbase, 
        tbbdetc
    WHERE 
        (rfraspc_aidy_code = :parm_DD_AidYear
        and (rfraspc_loan_process_ind = 'Y'
        or rfraspc_disburse_ind in ('M','S'))
        and rfraspc_fund_code = rfrbase_fund_code
        and tbbdetc_detail_code = rfrbase_detail_code
        and tbbdetc_detc_active_ind <> 'Y')
)
union

select
      '2.05.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual

union
select '2.05.000001'
      ,'Report 2.5 Work Study Fund Code Review'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '2.05.000002'
       ,'Fund'
       ,'Disburse' 
       ,'Detail Code'
       ,'Active Ind'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '2.05.'|| trim(to_char(rn+2,'000000')) rn
    ,fnd
    ,disb
    ,dtcd
    ,dtcin
    ,' '
    ,' '
    ,' '
from(
    SELECT 
        rfraspc_fund_code fnd, 
        rfraspc_disburse_ind disb, 
        rfrbase_detail_code dtcd, 
        tbbdetc_detc_active_ind dtcin
        ,rownum rn
    FROM 
      rfraspc, 
        rfrbase,
      tbbdetc
      WHERE 
        rfraspc_aidy_code = :parm_DD_AidYear
        and rfraspc_fund_code = rfrbase_fund_code
      and rfrbase_ftyp_code  =
                   (SELECT rtvftyp_code
                    FROM  rtvftyp
                    WHERE rtvftyp_code = rfrbase_ftyp_code
                    AND   rtvftyp_atyp_ind = 'W')
      and tbbdetc_detail_code(+) = rfrbase_detail_code 
)
union

select
      '2.06.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '2.06.000001'
      ,'Report 2.6 If Selected for Verification but is Not Complete'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '2.06.000002'
       ,'Fund'
       ,'Verification is not Complete' 
       ,'Federal!Source!Code!Description'
       ,'Fund Source Code Indicator'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '2.06.'|| trim(to_char(rn+2,'000000')) rn
    ,fnd
    ,ind
    ,src
    ,fsrc
    ,' '
    ,' '
    ,' '
from(
    SELECT 
        rfraspc_fund_code fnd, 
        decode (rfraspc_sel_ver_inc_ind,'Y','Yes Allow Disbursement', 'W','Inc with W Status Allow') ind,
        rfrbase_fsrc_code ||', '|| rtvfsrc_desc src,
        decode (rtvfsrc_ind,'O','Other','F','Federal','I','Institutional','S','State') fsrc 
        ,rownum rn
    FROM 
      rfraspc, 
      rfrbase,
      rtvfsrc
        WHERE 
        rfraspc_aidy_code = :parm_DD_AidYear
        and rfraspc_sel_ver_inc_ind <> 'N'
      and rfraspc_fund_code = rfrbase_fund_code
      and rfrbase_fsrc_code = rtvfsrc_code
  )

union

select
      '2.07.000000' as seqno
      , ' ' as B
      , ' ' as C
      , ' ' as D
      , ' ' as E
      , ' ' as F
      , ' ' as G
      , ' ' as H
      --, ' ' as I
from dual
union
select '2.07.000001'
      ,'Report 2.7 Override General Tracking Requirement'
      , null as c
      , null as d
      , null as e
      , null as f
      , null as g
      , null as h
      --, null as i
from dual

union
select '2.07.000002'
       ,'Fund'
       ,'Override Track Req' 
       ,'Federal!Source!Code!Description'
       ,'Fund Source Code Indicator'
       ,' '
       ,' '
       ,' '    
from dual
union
select 
    '2.07.'|| trim(to_char(rn+2,'000000')) rn
    ,fnd
    ,ovr
    ,src
    ,fsrc
    ,' '
    ,' '
    ,' '
from(
    SELECT 
        rfraspc_fund_code fnd, 
        rfraspc_override_ind ovr,
        rfrbase_fsrc_code ||', '|| rtvfsrc_desc src,
        decode (rtvfsrc_ind,'O','Other','F','Federal','I','Institutional','S','State') fsrc 
        ,rownum rn
    FROM 
      rfraspc, 
      rfrbase,
      rtvfsrc
        WHERE 
        rfraspc_aidy_code = :parm_DD_AidYear
        and rfraspc_override_ind = 'Y'
      and rfraspc_fund_code = rfrbase_fund_code
      and rfrbase_fsrc_code = rtvfsrc_code
)
;