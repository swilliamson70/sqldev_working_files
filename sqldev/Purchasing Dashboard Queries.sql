/*
+ Requisition Aging Report 
+ Requisitions Complete, but not approved
            o   Would like to see next Approver(s) listed

+ Open PO Report
        o   By Fiscal Year
        o   Requestor
        o   FOAP

· Vendor Detail
    o   All related documents for a vendor

· FOIDOCH

· Report by Individual Encumbrance
*/

select * from fordchc; --- ftvdtyp
select * from all_tab_comments where upper(comments) like '%STATUS%';
select * from gcvasts;

select
    ftvdtyp_desc
    ,fordchc_doc_code
    ,fordchc_status
    ,decode(fordchc_status,
            'A','Approved',
            'P','Paid',
            'C','Completed',
            ' ')
from 
    fordchc 
    join ftvdtyp
        ON fordchc_doc_type = ftvdtyp_seq_num
where fordchc_session_id = (
                            select distinct
                                a.fordchc_session_id
                            from 
                                fordchc a
                            where
                                fordchc_doc_code = :MC_POHeaders --.PO_Number
                            )
 ;                               
--:MC_POHeaders.PO_Number
select * from ftvdtyp;

WITH w_encumberances AS(
SELECT
    fgbench_num ENCUMBRANCE_NUMBER
    ,fgbench_type ENCUMBERANCE_TYPE
--    ,DECODE(fgbench_status_ind,
--                'O','Open',
--                'C','Closed',
--                ' ') ENCUMBERANCE_STATUS
    ,fgbench_type
    ,fgbench_status_ind 
    ,fgbench_vendor_pidm VENDOR
    ,fgbench_estab_date
    ,fgbench_create_user
    ,fgbench_trans_date
    ,to_char(sysdate,'DD-MON-YYYY') CURRENT_DATE
    ,to_char(sysdate - to_date(fgbench_estab_date),'99999') DAYS_ELAPSED
    ,CASE
        WHEN (sysdate - to_date(fgbench_estab_date)) >= 5 THEN 'Y'
        ELSE 'N'
    END OVER_5_DAYS
    ,trunc(fgbench_estab_date) - trunc(fgbench_trans_date) DAYS_IN_APPROVAL
    ,trunc(fgbench_activity_date) - trunc(fgbench_estab_date) DAYS_FROM_REQ
    ,fprreqa.req_total --,ledger_encumbered_amount from function 
    --,fgbench.*
FROM
    fgbench
    JOIN(
            select fprreqa_reqh_code, sum(fprreqa_amt) req_total from FPRREQA 
            --where fprreqa_activity_date >= to_date('01-JUL-2020') 
            group by fprreqa_reqh_code
        )FPRREQA ON fgbench.fgbench_num =  fprreqa.fprreqa_reqh_code
WHERE
    to_date(fgbench_trans_date) between-- to_date('01-JUL-2020') and to_date('30-JUN-2021')
    --beginning
    to_date(
        '01-JUL-' ||
            case
                when extract(month from sysdate) >= 7 then
                    to_char(extract(year from sysdate))
                else to_char(extract(year from sysdate) -1)
            end
        )AND(
        '30-JUN-' ||
            case
                when extract(month from sysdate) >= 7 then
                    to_char(extract(year from sysdate)+1)
                else to_char(extract(year from sysdate))
            end
        )


)
;
--select w_encumberances.* from w_encumberances;
select * from FPRREQA ;--where fprreqa_appr_ind <> 'Y' ;--FPRREQA_seq_num >1 order by 4 desc;
select * from fprreqa where fprreqa_reqh_code = 'R0024739';
select * from fgbench;
SELECT
    11 line_number
    ,'In Purchasing Department Queue' label_text
    ,null measure_text
    ,null percent_text
FROM DUAL
UNION
SELECT
    12
    ,'     Number of Requisitions in Queue'
    ,(select count(*) 
    from w_encumberances
    where fgbench_type = 'R'
    and fgbench_status_ind = 'O') as Reqs_in_Queue
    ,null
FROM DUAL
UNION
SELECT
    13
    ,'     Average Number of Days Open'
    ,(select avg(days_elapsed) 
    from w_encumberances
    where fgbench_type = 'R'
    and fgbench_status_ind = 'O') as Avg_Days_Open
    ,null
FROM DUAL
UNION
SELECT
    14
    ,'     Number beyond 5 Days'
    ,(select count(days_elapsed) 
    from w_encumberances
    where fgbench_type = 'R'
    and fgbench_status_ind = 'O'
    and days_elapsed >5) as BEYOND_5
    ,null
FROM DUAL
UNION
SELECT 20,null,null,null FROM DUAL UNION
SELECT
    21
    ,'Queue Processing' label_text
    ,null measure_text
    ,null percent_text
FROM DUAL
UNION
SELECT
    22 
    ,'     Number of Requisitions Processed'
    ,(select count(*) 
    from w_encumberances
    where fgbench_type = 'R') as Reqs_Processed
    ,null Percent_text
FROM DUAL
UNION
SELECT
    23 
    ,'     Avg Days in Approval Queue'
    ,(select round(avg(days_in_approval),2)
    from w_encumberances
    where fgbench_type = 'R') as Reqs_Processed
    ,null Percent_text
FROM DUAL
UNION
SELECT
    24 
    ,'     Avg Dates from Requsition to PO'
    ,(select round(avg(days_from_req),2)
    from w_encumberances
    where fgbench_type = 'R') as Reqs_Processed
    ,null Percent_text
FROM DUAL
UNION
SELECT
    25 
    ,'     5 Days before Account Sponsor Approves'
     ,(select count(*)
    from w_encumberances
    where fgbench_type = 'R'
        and days_in_approval > 5 ) as Approval_Days_5
    ,to_char(round(
        (select count(*)
        from w_encumberances
        where fgbench_type = 'R'
            and days_in_approval > 5 )
        / -- divided by
        (select count(*) 
        from w_encumberances
        where fgbench_type = 'R'),4)
        * 100
    ,'99.99') || '%' Percent_Days_5
FROM DUAL
UNION
SELECT
    26 
    ,'     10 Days before Account Sponsor Approves'
     ,(select count(*)
    from w_encumberances
    where fgbench_type = 'R'
        and days_in_approval > 10 ) as Approval_Days_5
    ,to_char(round(
        (select count(*)
        from w_encumberances
        where fgbench_type = 'R'
            and days_in_approval > 10 )
        / -- divided by
        (select count(*) 
        from w_encumberances
        where fgbench_type = 'R'),4)
        * 100
    ,'99.99') || '%' Percent_Days_10
FROM DUAL
UNION
SELECT
    27 
    ,'     15 Days before Account Sponsor Approves'
     ,(select count(*)
    from w_encumberances
    where fgbench_type = 'R'
        and days_in_approval > 15 ) as Approval_Days_5
    ,to_char(round(
        (select count(*)
        from w_encumberances
        where fgbench_type = 'R'
            and days_in_approval > 15 )
        / -- divided by
        (select count(*) 
        from w_encumberances
        where fgbench_type = 'R'),4)
        * 100
    ,'99.99') || '%' Percent_Days_15
FROM DUAL
UNION
SELECT 30,null,null,null FROM DUAL UNION
SELECT
    31
    ,'Dollar Amounts Processed' label_text
    ,null measure_text
    ,null percent_text
FROM DUAL
UNION
SELECT
    32 
    ,'     Avg Amount Requested'
    ,(select sum(req_total)
    from w_encumberances
    where fgbench_type = 'R')
    / (select count(*)
    from w_encumberances
    where fgbench_type = 'R') measure_text
    ,null percent_text
FROM DUAL
UNION
SELECT
    33 
    ,'     Number below $5,000'
    ,(select count(*)
    from w_encumberances
    where fgbench_type = 'R'
        and req_total < 5000) measure_text
    ,null percent_text
FROM DUAL
UNION
SELECT
    34 
    ,'     Number between $5,000 and $25,000'
    ,(select count(*)
    from w_encumberances
    where fgbench_type = 'R'
        and req_total between 5000 and 25000) measure_text
    ,null percent_text
FROM DUAL
UNION
SELECT
    35 
    ,'     Number over $25,000 but less than or equal to $50,000'
    ,(select count(*)
    from w_encumberances
    where fgbench_type = 'R'
        and req_total > 25000
        and req_total < 50000) measure_text
    ,null percent_text
FROM DUAL
UNION
SELECT
    36 
    ,'     Number greater than $50,000'
    ,(select count(*)
    from w_encumberances
    where fgbench_type = 'R'
        and req_total >= 50000) measure_text
    ,null percent_text
FROM DUAL

;
--------------------------------------------------------------------------------------------------------------------------------

select
      FPBPOHD.FPBPOHD_ORGN_CODE "Organization",
      FPBPOHD.FPBPOHD_NAME "Purchaser",
       SPRIDEN.SPRIDEN_ID "VendorID",
       SPRIDEN.SPRIDEN_LAST_NAME "Vendor",
       FPBPOHD.FPBPOHD_CODE "PO_Number",
       to_char(FPBPOHD.FPBPOHD_PO_DATE,'MM/DD/YYYY') "PODate",
       FPBPOHD.FPBPOHD_APPR_IND "ApproveInd",
       FPBPOHD.FPBPOHD_PRINT_IND "PrintInd",
       FPBPOHD.FPBPOHD_COMPLETE_IND "CompInd",
       FPBPOHD.FPBPOHD_CLOSED_IND "ClosedInd"

  from FIMSMGR.FPBPOHD FPBPOHD --Purchase Order Header Table
       JOIN SPRIDEN
            ON FPBPOHD.FPBPOHD_VEND_PIDM = SPRIDEN.SPRIDEN_PIDM
            AND spriden_change_ind is null

 where
      FPBPOHD.FPBPOHD_CHANGE_SEQ_NUM is null
      and UPPER(FPBPOHD.FPBPOHD_NAME) LIKE '%'||UPPER(:ED_PurchasingAgent)||'%'
      and UPPER(SPRIDEN.SPRIDEN_LAST_NAME) LIKE '%'||UPPER(:ED_Vendor)||'%'
      and FPBPOHD.FPBPOHD_ORGN_CODE = :LB_Orgs.FTVORGN_ORGN_CODE
      and to_char(FPBPOHD_PO_DATE,'YYYYMMDD') between
                coalesce(to_char(:DT_POFrom,'YYYYMMDD'),'19000101')
            and
                coalesce(to_char(:DT_POTo,'YYYYMMDD'),'29001231')
      --and :BTN_Go_POSearch is not null
;      
select * from FPBPOHD;
select * from all_col_comments where table_name = 'FPBPOHD';
select * from(
select 
--    fprpoda_pohd_code
--    ,fprpoda_change_seq_num
    fprpoda.*
    
    from fprpoda
    where  fprpoda_activity_date > to_date('01-JUL-2020')
    );
    
select 
    fprpoda_pohd_code
    ,foap_string
    ,count(*) over (partition by fprpoda_pohd_code) foap_count
from(
select distinct
--    fprpoda_pohd_code
--    ,fprpoda_change_seq_num
    fprpoda_pohd_code
    ,fprpoda_coas_code || fprpoda_fund_code || fprpoda_orgn_code || fprpoda_acct_code || fprpoda_prog_code || fprpoda_actv_code || fprpoda_locn_code foap_string
    
    from fprpoda
    where  fprpoda_activity_date > to_date('01-JUL-2020')   
)
--P0082002
;    
select * from fpbpohd;
select sum(fprpoda_amt) from fprpoda where fprpoda_pohd_code = 'P0082002'; --46000 matches ods.encumbrance
select * from fprpoda ;--where fprpoda_pohd_code = 'P0060012';
select * from all_col_comments where table_name = 'FPRPODA';
select distinct * from (
    select 
        fprpoda_pohd_code
        ,fprpoda_change_seq_num
        ,fprpoda_item
        ,fprpoda_seq_num
        ,fprpoda_coas_code
        ,fprpoda_acci_code
        ,fprpoda_fund_code
        ,fprpoda_orgn_code
        ,fprpoda_acct_code
        ,fprpoda_prog_code
        ,fprpoda_actv_code
        ,fprpoda_locn_code
        ,fprpoda_proj_code
        ,fprpoda_fsyr_code
        ,fprpoda_period
        ,row_number() over (partition by fprpoda_pohd_code, fprpoda_item, fprpoda_seq_num order by coalesce(fprpoda_change_seq_num,-1) desc) rn
    from fprpoda
    --where fprpoda_pohd_code = 'P0060012'
    ) where 
        rn = 1
        and (coalesce(fprpoda_coas_code,'.') like :parm_ED_COA || '%')
        and (coalesce(fprpoda_acci_code,'.') like :parm_ED_ACCI || '%')
        and (coalesce(fprpoda_fund_code,'.') like :parm_ED_FUND || '%')
        and (coalesce(fprpoda_orgn_code,'.') like :parm_ED_ORG || '%')
        and (coalesce(fprpoda_acct_code,'.') like :parm_ED_ACCT || '%')
        and (coalesce(fprpoda_prog_code,'.') like :parm_ED_PROG || '%')
        and (coalesce(fprpoda_actv_code,'.') like :parm_ED_ACT || '%')
        and (coalesce(fprpoda_locn_code,'.') like :parm_ED_LOC || '%')
        and (coalesce(fprpoda_proj_code,'.') like :parm_ED_PROJ || '%')
        and (coalesce(fprpoda_fsyr_code,'.') like :parm_ED_FSYR || '%')
;
fprpoda_change_seq_num, fprpoda_item, fprpoda_seq_num, 

fprpoda_coas_code, fprpoda_acci_code, fprpoda_fund_code, fprpoda_orgn_code, fprpoda_acct_code, fprpoda_prog_code, fprpoda_actv_code, fprpoda_locn_code, fprpoda_proj_code
fprpoda_fsyr_code, fprpoda_period,
;
select fpbpohd.FPBPOHD_CODE from fpbpohd;
select * from ftvfsyr;

with w_finance_crit as (
     select distinct fprpoda_pohd_code from (
            select
                  fprpoda_pohd_code
                  ,fprpoda_change_seq_num
                  ,fprpoda_item
                  ,fprpoda_seq_num
                  ,fprpoda_coas_code
                  ,fprpoda_acci_code
                  ,fprpoda_fund_code
                  ,fprpoda_orgn_code
                  ,fprpoda_acct_code
                  ,fprpoda_prog_code
                  ,fprpoda_actv_code
                  ,fprpoda_locn_code
                  ,fprpoda_proj_code
                  ,fprpoda_fsyr_code
                  ,fprpoda_period
                  ,row_number() over (partition by fprpoda_pohd_code, fprpoda_item, fprpoda_seq_num order by coalesce(fprpoda_change_seq_num,-1) desc) rn
            from fprpoda
    --where fprpoda_pohd_code = 'P0060012'
    ) where
        rn = 1
        and (coalesce(fprpoda_coas_code,'.') like :parm_ED_COA || '%')
        and (coalesce(fprpoda_acci_code,'.') like :parm_ED_ACCI || '%')
        and (coalesce(fprpoda_fund_code,'.') like :parm_ED_FUND || '%')
        and (coalesce(fprpoda_orgn_code,'.') like :parm_ED_ORG || '%')
        and (coalesce(fprpoda_acct_code,'.') like :parm_ED_ACCT || '%')
        and (coalesce(fprpoda_prog_code,'.') like :parm_ED_PROG || '%')
        and (coalesce(fprpoda_actv_code,'.') like :parm_ED_ACT || '%')
        and (coalesce(fprpoda_locn_code,'.') like :parm_ED_LOC || '%')
        and (coalesce(fprpoda_proj_code,'.') like :parm_ED_PROJ || '%')
        and (coalesce(fprpoda_fsyr_code,'.') like :parm_ED_FSYR || '%')
)

select
      FPBPOHD.FPBPOHD_ORGN_CODE "Organization",
      FPBPOHD.FPBPOHD_NAME "Purchaser",
       SPRIDEN.SPRIDEN_ID "VendorID",
       SPRIDEN.SPRIDEN_LAST_NAME "Vendor",
       FPBPOHD.FPBPOHD_CODE "PO_Number",
       to_char(FPBPOHD.FPBPOHD_PO_DATE,'MM/DD/YYYY') "PODate",
       FPBPOHD.FPBPOHD_APPR_IND "ApproveInd",
       FPBPOHD.FPBPOHD_PRINT_IND "PrintInd",
       FPBPOHD.FPBPOHD_COMPLETE_IND "CompInd",
       FPBPOHD.FPBPOHD_CLOSED_IND "ClosedInd"

  from FIMSMGR.FPBPOHD FPBPOHD --Purchase Order Header Table
       JOIN SPRIDEN
            ON FPBPOHD.FPBPOHD_VEND_PIDM = SPRIDEN.SPRIDEN_PIDM
            AND spriden_change_ind is null
       JOIN w_finance_crit
            ON fpbpohd.FPBPOHD_CODE = w_finance_crit.fprpoda_pohd_code

 where
      FPBPOHD.FPBPOHD_CHANGE_SEQ_NUM is null
      and UPPER(FPBPOHD.FPBPOHD_NAME) LIKE '%'||UPPER(:ED_PurchasingAgent)||'%'
      and UPPER(SPRIDEN.SPRIDEN_LAST_NAME) LIKE '%'||UPPER(:ED_Vendor)||'%'
      --and FPBPOHD.FPBPOHD_ORGN_CODE = :LB_Orgs.FTVORGN_ORGN_CODE
      and to_char(FPBPOHD_PO_DATE,'YYYYMMDD') between
                coalesce(to_char(:DT_POFrom,'YYYYMMDD'),'19000101')
            and
                coalesce(to_char(:DT_POTo,'YYYYMMDD'),'29001231')
      and :BTN_Go_POSearch is not null
    ;
