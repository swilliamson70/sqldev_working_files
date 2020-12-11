select * from all_tab_comments where upper(comments) like '%REQ%' and owner like 'FI%' and table_name not like '%$%';
select * from all_col_comments where table_name = 'FPRPODA';
select * from fpbpohd where FPBPOHD_APPR_IND <> 'Y';
select * from fpbpohd where FPBPOHD_code = 'P0081328';


--       FPBPOHD.FPBPOHD_APPR_IND "ApproveInd",
--       FPBPOHD.FPBPOHD_PRINT_IND "PrintInd",
--       FPBPOHD.FPBPOHD_COMPLETE_IND "CompInd",
--       FPBPOHD.FPBPOHD_CLOSED_IND "ClosedInd"


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

--  from FIMSMGR.FPBPOHD FPBPOHD --Purchase Order Header Table
  from (
    select
        fpbpohd.*
        , row_number() over (partition by fpbpohd_code order by fpbpohd_change_seq_num desc) rn
    from
        fpbpohd
    ) FPBPOHD --Purchase Order Header Table
       JOIN SPRIDEN
            ON FPBPOHD.FPBPOHD_VEND_PIDM = SPRIDEN.SPRIDEN_PIDM
            AND spriden_change_ind is null
            AND fpbpohd.rn = 1
            and fpbpohd_code in ('P0081328','P0081649','P0081931','P0081932','P0082364')
       LEFT JOIN w_finance_crit
            ON fpbpohd.FPBPOHD_CODE = w_finance_crit.fprpoda_pohd_code

 where
      --FPBPOHD.FPBPOHD_CHANGE_SEQ_NUM is null
      UPPER(FPBPOHD.FPBPOHD_NAME) LIKE '%'||UPPER(:ED_PurchasingAgent)||'%'
      and UPPER(SPRIDEN.SPRIDEN_LAST_NAME) LIKE '%'||UPPER(:ED_Vendor)||'%'
      --and FPBPOHD.FPBPOHD_ORGN_CODE = :LB_Orgs.FTVORGN_ORGN_CODE
      and to_char(FPBPOHD_PO_DATE,'YYYYMMDD') between
                coalesce(to_char(:DT_POFrom,'YYYYMMDD'),'19000101')
            and
                coalesce(to_char(:DT_POTo,'YYYYMMDD'),'29001231')
      and(
          (:parm_cb_approvalYes = 'Y' and fpbpohd_appr_ind = 'Y' )
            or ( :parm_cb_approvalNo = 'N' and fpbpohd_appr_ind = 'N' )
      )
      and :BTN_Go_POSearch is not null

-- select * from w_finance_crit
;
select * from fgbench;
select * from FPBREQH; -- request header table

select count(fpbreqh_code) from fpbreqh; --22723
select count(distinct fpbreqh_code) from fpbreqh; --22723

select * from fprreqa; -- request accounting table
select * from fprreqd; -- request detail table
--FPBREQH_COMPLETE_IND, FPBREQH_PRINT_IND, FPBREQH_APPR_IND, FPBREQH_CLOSED_IND
select * from fprpoda;
select * from FPRPODT;

with w_finance_crit as (
    select
          fprreqa_reqh_code
          ,fprreqa_item
          ,fprreqa_seq_num
          ,fprreqa_coas_code
          ,fprreqa_acci_code
          ,fprreqa_fund_code
          ,fprreqa_orgn_code
          ,fprreqa_acct_code
          ,fprreqa_prog_code
          ,fprreqa_actv_code
          ,fprreqa_locn_code
          ,fprreqa_proj_code
          ,fprreqa_fsyr_code
          ,fprreqa_period
          ,fprreqa_amt
          ,fprreqa_pct
          
    from fprreqa
    where --fprreqa_reqh_code = 'R0010320'
        (coalesce(fprreqa_coas_code,'.') like :parm_eb_reqcoa || '%')
        and (coalesce(fprreqa_acci_code,'.') like :parm_eb_reqacci || '%')
        and (coalesce(fprreqa_fund_code,'.') like :parm_eb_reqfund || '%')
        and (coalesce(fprreqa_orgn_code,'.') like :parm_eb_reqorg || '%')
        and (coalesce(fprreqa_acct_code,'.') like :parm_eb_reqacct || '%')
        and (coalesce(fprreqa_prog_code,'.') like :parm_eb_reqprog || '%')
        and (coalesce(fprreqa_actv_code,'.') like :parm_eb_reqact || '%')
        and (coalesce(fprreqa_locn_code,'.') like :parm_eb_reqloc || '%')
        and (coalesce(fprreqa_proj_code,'.') like :parm_eb_reqproj || '%')
        and (coalesce(fprreqa_fsyr_code,'.') like :parm_eb_reqfy || '%')
)

select
    fpbreqh_orgn_code "Organization"
    ,fpbreqh_name "Requestor"
    ,SPRIDEN.SPRIDEN_ID "VendorID"
    ,SPRIDEN.SPRIDEN_LAST_NAME "Vendor"
    ,fpbreqh_code "Req_Number"
    ,to_char(fpbreqh_reqh_date,'MM/DD/YYYY') Req_Date
    ,fprreqa_amt "Approval_Amt"
    ,fprreqa_pct "Approval_Pct"
    ,fprreqa_coas_code "COA"
    ,fprreqa_acci_code "Acct_Index"
    ,fprreqa_fund_code "Fund"
    ,fprreqa_orgn_code "Org"
    ,fprreqa_acct_code "Acct"
    ,fprreqa_prog_code "Prog"
    ,fprreqa_actv_code "Act"
    ,fprreqa_locn_code "Loc"
    ,fprreqa_proj_code "Proj"
    ,fpbreqh_appr_ind "ApproveInd"
    ,fpbreqh_print_ind "PrintInd"
    ,fpbreqh_complete_ind "CompInd"
    ,fpbreqh_closed_ind "ClosedInd"
    
  from 
    fpbreqh --Requestition Header Table
       JOIN SPRIDEN
            ON fpbreqh_vend_pidm = spriden_pidm
            AND spriden_change_ind is null
       LEFT JOIN w_finance_crit
            ON fpbreqh_code = w_finance_crit.fprreqa_reqh_code

 where
      UPPER(fpbreqh_name) LIKE '%'||UPPER(:parm_eb_requestor)||'%'
      and UPPER(SPRIDEN.SPRIDEN_LAST_NAME) LIKE '%'||UPPER(:parm_eb_vendor)||'%'
      and to_char(fpbreqh_reqh_date,'YYYYMMDD') between
                coalesce(to_char(:parm_dt_reqfrom,'YYYYMMDD'),'19000101')
            and
                coalesce(to_char(:parm_dt_reqto,'YYYYMMDD'),'29001231')
      and(
          (:parm_cb_reqapprovalYes = 'Y' and fpbreqh_appr_ind = 'Y' )
            or ( :parm_cb_reqapprovalNo = 'N' and fpbreqh_appr_ind = 'N' )
      )
            and(
          (:parm_cb_reqprintYes = 'Y' and fpbreqh_print_ind = 'Y' )
            or ( :parm_cb_reqprintNo = 'N' and fpbreqh_print_ind is null )
      )
            and(
          (:parm_cb_reqcompleteYes = 'Y' and fpbreqh_complete_ind = 'Y' )
            or ( :parm_cb_reqcompleteNo = 'N' and fpbreqh_complete_ind = 'N' )
      )
            and(
          (:parm_cb_reqclosedYes = 'Y' and fpbreqh_closed_ind = 'Y' )
            or ( :parm_cb_reqclosedNo = 'N' and fpbreqh_closed_ind is null )
      )
      and :BTN_Go_ReqSearch is not null

-- select * from w_finance_crit
;
select-- FPRPODT.FPRPODT_POHD_CODE 
FPRREQD_REQH_CODE "POCode",
       --FPRPODT.FPRPODT_CHANGE_SEQ_NUM "ChgSeqNo",
       
       --FPRPODT.FPRPODT_ACTIVITY_DATE 
FPRREQD_ACTIVITY_DATE "ActivityDate",
       --FPRPODT.FPRPODT_USER_ID
FPRREQD_USER_ID "UserId",
       --FPRPODT.FPRPODT_ITEM
FPRREQD_ITEM "ItemNo",       
       --FPRPODT.FPRPODT_COMM_CODE
FPRREQD_COMM_CODE "CommCode",       
       --FPRPODT.FPRPODT_COMM_DESC
FPRREQD_COMM_DESC "CommDesc",       
       --FPRPODT.FPRPODT_UOMS_CODE
FPRREQD_UOMS_CODE "UnitMeasureCode",       
       --FPRPODT.FPRPODT_UNIT_PRICE
FPRREQD_UNIT_PRICE "UnitPrice",       
       --FPRPODT.FPRPODT_LIQ_AMT "LiqAmt",
       
       --FPRPODT.FPRPODT_QTY
FPRREQD_QTY  "Quantity",
FPRREQD_AMT "Amt",
       --FPRPODT.FPRPODT_DISC_AMT 
FPRREQD_DISC_AMT "DiscAmt",      
       --FPRPODT.FPRPODT_TAX_AMT
FPRREQD_TAX_AMT "TaxAmt",      
       --FPRPODT.FPRPODT_VEND_REF_NUM "VendRefNo",
       
       --FPRPODT.FPRPODT_AGRE_CODE
FPRREQD_AGRE_CODE "AgreeCode",       
       --FPRPODT.FPRPODT_SUSP_IND 
FPRREQD_SUSP_IND "SuspInd",      
       --FPRPODT.FPRPODT_CLOSED_IND 
FPRREQD_CLOSED_IND "ClosedInd",      
       --FPRPODT.FPRPODT_CANCEL_IND 
FPRREQD_CANCEL_IND "CancelInd",      
       --FPRPODT.FPRPODT_CANCEL_DATE 
FPRREQD_CANCEL_DATE "CancelDate",  
--
FPRREQD_COMPLETE_IND,
       --FPRPODT.FPRPODT_TTAG_NUM "TempTagNo",
       
       --FPRPODT.FPRPODT_TEXT_USAGE 
FPRREQD_TEXT_USAGE "TextUseInd",      
       --FPRPODT.FPRPODT_ADDL_CHRG_AMT "AddChrgAmt",
       
       --FPRPODT.FPRPODT_CONVERT_UNIT_PRICE 
FPRREQD_CONVERTED_UNIT_PRICE "ConvertUnitPrice",      
       --FPRPODT.FPRPODT_CONVERT_DISC_AMT 
FPRREQD_CONVERT_DISC_AMT "ConvertDiscAmt",
--
FPRREQD_DISC_AMT,       
       --FPRPODT.FPRPODT_CONVERT_TAX_AMT 
FPRREQD_CONVERT_TAX_AMT "ConvertTaxAmt",
--
FPRREQD_TAX_AMT,       
       --FPRPODT.FPRPODT_CONVERT_ADDL_CHRG_AMT
FPRREQD_CONVERT_ADDL_CHRG_AMT "ConvertAddlChrgAmt",
--
FPRREQD_ADDL_CHRG_AMT,       
       --FPRPODT.FPRPODT_TGRP_CODE
FPRREQD_TGRP_CODE "TaxGroupCode",       
       --FPRPODT.FPRPODT_EXT_AMT "ExtendAmt",
       
       --FPRPODT.FPRPODT_BO_REMAIN_BAL "BlankRemainBalAmt",
       
       --FPRPODT.FPRPODT_DESC_CHGE_IND
FPRREQD_DESC_CHGE_IND "DescChrgInd",       
       --FPRPODT.FPRPODT_SHIP_CODE
FPRREQD_SHIP_CODE "ShipCode",
       --FPRPODT.FPRPODT_REQD_DATE
FPRREQD_REQD_DATE

--, FPRREQD_COAS_CODE, FPRREQD_ORGN_CODE, FPRREQD_BUYR_CODE, FPRREQD_VEND_PIDM, FPRREQD_VEND_REF_NUM
--, FPRREQD_PROJ_CODE, FPRREQD_POHD_CODE, FPRREQD_POHD_ITEM, FPRREQD_BIDS_CODE, 
--, FPRREQD_POST_DATE, FPRREQD_ATYP_CODE, FPRREQD_ATYP_SEQ_NUM, FPRREQD_RECOMM_VEND_NAME
--, FPRREQD_CURR_CODE

       
  from FPRREQD
-- where FPRPODT.FPRPODT_POHD_CODE = :MC_POHeaders.PO_Number
--       and FPRPODT.FPRPODT_CHANGE_SEQ_NUM is null
