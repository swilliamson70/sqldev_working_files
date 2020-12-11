--POs
desc FPBPOHD;
select FPBPOHD.FPBPOHD_NAME "Purchaser",
       SPRIDEN.SPRIDEN_LAST_NAME "Vendor",
       FPBPOHD.FPBPOHD_CODE "PO_Number",
       FPBPOHD.FPBPOHD_PO_DATE "PODate",
       FPBPOHD.FPBPOHD_APPR_IND "ApproveInd",
       FPBPOHD.FPBPOHD_PRINT_IND "PrintInd",
       FPBPOHD.FPBPOHD_COMPLETE_IND "CompInd",
       FPBPOHD.FPBPOHD_CLOSED_IND "ClosedInd",
       SPRIDEN.SPRIDEN_ID "VendorID",
       FPBPOHD.FPBPOHD_ORGN_CODE "Organization"
  from FIMSMGR.FPBPOHD FPBPOHD, --Purchase Order Header Table
       SATURN.SPRIDEN SPRIDEN
 where ( FPBPOHD.FPBPOHD_VEND_PIDM = SPRIDEN.SPRIDEN_PIDM )
   and ( ( FPBPOHD.FPBPOHD_CHANGE_SEQ_NUM is null
           and UPPER(FPBPOHD.FPBPOHD_NAME) LIKE '%'||UPPER(:ED_PurchasingAgent)||'%'
           and UPPER(SPRIDEN.SPRIDEN_LAST_NAME) LIKE '%'||UPPER(:ED_Vendor)||'%'
           and FPBPOHD.FPBPOHD_ORGN_CODE = :LB_Orgs.OrgCode 
           and FPBPOHD_PO_DATE between 
                coalesce(to_date(:DT_POFrom),to_date('01-JAN-1900'))
            and
                coalesce(to_date(:DT_POTo),to_date('31-DEC-2900'))
            )
        and ( spriden_change_ind is null ) )
;
select * from all_tab_comments where table_name = 'FPBPOHD';
select * from FPBPOHD;

--PO Details

select FPRPODT.FPRPODT_POHD_CODE "POCode",
       FPRPODT.FPRPODT_CHANGE_SEQ_NUM "ChgSeqNo",
       FPRPODT.FPRPODT_ACTIVITY_DATE "ActivityDate",
       FPRPODT.FPRPODT_USER_ID "UserId",
       FPRPODT.FPRPODT_ITEM "ItemNo",
       FPRPODT.FPRPODT_COMM_CODE "CommCode",
       FPRPODT.FPRPODT_COMM_DESC "CommDesc",
       FPRPODT.FPRPODT_UOMS_CODE "UnitMeasureCode",
       FPRPODT.FPRPODT_UNIT_PRICE "UnitPrice",
       FPRPODT.FPRPODT_LIQ_AMT "LiqAmt",
       FPRPODT.FPRPODT_QTY "Quantity",
       FPRPODT.FPRPODT_DISC_AMT "DiscAmt",
       FPRPODT.FPRPODT_TAX_AMT "TaxAmt",
       FPRPODT.FPRPODT_VEND_REF_NUM "VendRefNo",
       FPRPODT.FPRPODT_AGRE_CODE "AgreeCode",
       FPRPODT.FPRPODT_SUSP_IND "SuspInd",
       FPRPODT.FPRPODT_CLOSED_IND "ClosedInd",
       FPRPODT.FPRPODT_CANCEL_IND "CancelInd",
       FPRPODT.FPRPODT_CANCEL_DATE "CancelDate",
       FPRPODT.FPRPODT_TTAG_NUM "TempTagNo",
       FPRPODT.FPRPODT_TEXT_USAGE "TextUseInd",
       FPRPODT.FPRPODT_ADDL_CHRG_AMT "AddChrgAmt",
       FPRPODT.FPRPODT_CONVERT_UNIT_PRICE "ConvertUnitPrice",
       FPRPODT.FPRPODT_CONVERT_DISC_AMT "COnvertDiscAmt",
       FPRPODT.FPRPODT_CONVERT_TAX_AMT "ConvertTaxAmt",
       FPRPODT.FPRPODT_CONVERT_ADDL_CHRG_AMT "ConvertAddlChrgAmt",
       FPRPODT.FPRPODT_TGRP_CODE "TaxGroupCode",
       FPRPODT.FPRPODT_EXT_AMT "ExtendAmt",
       FPRPODT.FPRPODT_BO_REMAIN_BAL "BlankRemainBalAmt",
       FPRPODT.FPRPODT_DESC_CHGE_IND "DescChrgInd",
       FPRPODT.FPRPODT_SHIP_CODE "ShipCode",
       FPRPODT.FPRPODT_REQD_DATE
  from FIMSMGR.FPRPODT FPRPODT
 where --FPRPODT.FPRPODT_POHD_CODE = :MC_POHeaders.PO_Number
        FPRPODT.FPRPODT_CHANGE_SEQ_NUM is null
;
select * from all_tab_comments where table_name = 'FPRPODT'; --Purchase Order Detail GOODS Table
select * from all_tab_comments where table_name like 'FPR%';

select * from FPRREQD;
select * from FPRPODA;

-- ODS Spreadsheet - Req aging 


SELECT
    encumbrance.encumbrance_number, -- FGBENCH_NUM
    encumbrance.encumbrance_type, --FGBENCH_TYPE --Filter 
    encumbrance.encumbrance_type_desc, --	SELECT SUBSTR(VALUE_DESCRIPTION,1,255) FROM MGT_VALIDATION WHERE TABLE_NAME = 'ENCUMBRANCE_TYPE' AND VALUE = ENCUMBRANCE_TYPE
    encumbrance.encumbrance_desc, --FGBENCH_DESC
    encumbrance.encumbrance_source, --DECODE(FGBENCH_SOURCE_IND)
    encumbrance.hr_encumbrance_ind, --CASE WHEN ENCUMBRANCE_NUMBER
    encumbrance.change_number, --FGBENCH_DOC_CHANGE_NUM
    encumbrance.change_desc, --FGBENCH_CHANGE_DESC
    encumbrance.encumbrance_status, --DECODE(FGBENCH_STATUS_IND) --Filter
    encumbrance.complete_ind, -- DECODE(FGBENCH_STATUS)
    encumbrance.amount, --FGBENCH_DOC_AMT

    encumbrance.transaction_date, --FGBENCH_TRANS_DATE
    encumbrance.established_date, --FGBENCH_ESTAB_DATE
    encumbrance.vendor_uid, --FGBENCH_VENDOR_PIDM
    encumbrance.vendor_id, --MGKFUNC.F_GET_PERSON_INFO
    encumbrance.vendor_name, --MGKFUNC.F_GET_PERSON_INFO
    encumbrance.document_reference_number, --FGBENCH_DOC_REF_NUM
    encumbrance.approval_ind,--FGBENCH_APPR_IND
    encumbrance.text_ind, --FGBENCH_TEXT_IND
    encumbrance.deferred_edit_ind, --NVL(FGBENCH_EDIT_DEFERRAL,'N')
    encumbrance.nsf_on_off_ind, --NVL(FGBENCH_NSF_ON_OFF_IND,'N')
    encumbrance.ledger_encumbered_amount, --MFKFUNC.F_GET_LEDGER_ENCUMBERED_AMOUNT
    encumbrance.ledger_remaining_balance, --MFKFUNC.F_GET_LEDGER_REMAINING_BALANCE
    encumbrance.encumbrance_user_id, --FGBENCH_USER_ID
    encumbrance.encumbrance_activity_date, --FGBENCH_ACTIVITY_DATE
    encumbrance.encumbrance_data_origin, --FGBENCH_DATA_ORIGIN
    encumbrance.encumbrance_create_date, --FGBENCH_CREATE_DATE
    encumbrance.encumbrance_create_user, --FGBENCH_CREATE_USER
    encumbrance.encumbrance_create_source, --FGBENCH_CREATE_SOURCE
    encumbrance.multi_source, --NA
    encumbrance.multi_source_desc, --NA
    encumbrance.process_group, --NA
    encumbrance.administrative_group --NA
FROM
    odsmgr.encumbrance encumbrance

WHERE ( encumbrance.transaction_date >= to_date('01-JUL-2020') ) --'2020-07-01 00:00:00'))
;
select fprreqa_reqh_code, sum(fprreqa_amt) from FPRREQA 
where fprreqa_activity_date >= to_date('01-JUL-2020') 
group by fprreqa_reqh_code;
select * from FPRREQA;
_pohd_code
, fprpoda
select fprpoda_pohd_code, sum(fprpoda_amt) from (
select fprpoda_item
, last_value(fprpoda_amt) over (partition by fprpoda_pohd_code, fprpoda_item, fprpoda_change_seq_num
                                order by fprpoda_pohd_code, fprpoda_item, fprpoda_change_seq_num) fprpoda_amt
from FPRPODA
where fprpoda_activity_date >= to_date('01-JUL-2020') 
) group by fprpoda_pohd_code
order by 1;


select --beginning 
    '01-JUL-' ||
        case 
            when extract(month from sysdate) >= 7 then 
                to_char(extract(year from sysdate))
            else to_char(extract(year from sysdate) -1)
        end fyear_beginning
from dual;

select --end
    '30-JUN-' || 
        case
            when extract(month from sysdate) >= 7 then
                to_char(extract(year from sysdate)+1)
            else to_char(extract(year from sysdate))
        end fyear_end
from dual;
SELECT
    fgbench_num ENCUMBRANCE_NUMBER
    ,fgbench_type ENCUMBERANCE_TYPE
    ,DECODE(fgbench_status_ind,
                'O','Open',
                'C','Closed',
                ' ') ENCUMBERANCE_STATUS
                
    ,fgbench_vendor_pidm VENDOR
    ,spriden_id VENDOR_ID
    ,spriden_last_name VENDOR_NAME
    ,fgbench_estab_date
    ,fgbench_create_user
    ,to_char(sysdate,'DD-MON-YYYY') CURRENT_DATE
    ,to_char(sysdate - to_date(fgbench_estab_date),'99999') DAYS_ELAPSED
    ,CASE
        WHEN (sysdate - to_date(fgbench_estab_date)) >= 5 THEN 'Y'
        ELSE 'N'
    END OVER_5_DAYS
        
    --,fgbench.*
FROM 
    fgbench
    JOIN spriden
        ON fgbench_vendor_pidm = spriden_pidm
        AND spriden_change_ind is null
WHERE 1=1
--    to_date(fgbench_trans_date) between-- to_date('01-JUL-2020') and to_date('30-JUN-2021')   
--    --beginning 
--    to_date(
--        '01-JUL-' ||
--            case 
--                when extract(month from sysdate) >= 7 then 
--                    to_char(extract(year from sysdate))
--                else to_char(extract(year from sysdate) -1)
--            end
--        )AND(
--        '30-JUN-' || 
--            case
--                when extract(month from sysdate) >= 7 then
--                    to_char(extract(year from sysdate)+1)
--                else to_char(extract(year from sysdate))
--            end
--        )
--
    --AND fgbench_type = 'R'
    AND fgbench_status_ind = 'O'
;
select * from all_tab_comments where table_name like 'F%' and lower(comments) like '%encumbrance%';
select * from MGT_VALIDATION WHERE TABLE_NAME = 'ENCUMBRANCE_TYPE';

select distinct FPBPOHD.FPBPOHD_ORGN_CODE "OrgCode"
  from FIMSMGR.FPBPOHD FPBPOHD
 order by FPBPOHD.FPBPOHD_ORGN_CODE;
 
 select * from organization_hierarchy;
/*select distinct FPBPOHD.FPBPOHD_ORGN_CODE "OrgCode"
  from FIMSMGR.FPBPOHD FPBPOHD
 order by FPBPOHD.FPBPOHD_ORGN_CODE
*/
 select
     ftvorgn_orgn_code || ' - ' || ftvorgn_title ftvorgn_title
     ,ftvorgn_orgn_code
 from(
     select
     ftvorgn_orgn_code
     ,ftvorgn_title
     ,row_number() over (partition by ftvorgn_coas_code, ftvorgn_orgn_code order by ftvorgn_eff_date desc) rn
     from ftvorgn
     where
     ftvorgn_status_ind = 'A'
 ) join (
    select distinct 
        fpbpohd_orgn_code 
    from fpbpohd
    order by 1
) on ftvorgn_orgn_code = fpbpohd_orgn_code
    and rn = 1;
    
    
    
select
    ftvorgn_orgn_code || ' - ' || ftvorgn_title ftvorgn_title
     ,ftvorgn_orgn_code
from(
     select
     ftvorgn_orgn_code
     ,ftvorgn_title
     ,row_number() over (partition by ftvorgn_coas_code, ftvorgn_orgn_code order by ftvorgn_eff_date desc) rn
     from ftvorgn
     where
     ftvorgn_status_ind = 'A'
     and exists(
               select 1 x
               from fpbpohd
               where
                    ftvorgn_orgn_code = fpbpohd_orgn_code
                    and FPBPOHD.FPBPOHD_CHANGE_SEQ_NUM is null
                    and UPPER(FPBPOHD.FPBPOHD_NAME) LIKE '%'||UPPER(:ED_PurchasingAgent)||'%'
                    and UPPER(  (select SPRIDEN_LAST_NAME 
                                from spriden 
                                where spriden_id = fpbpohd_vend_pidm 
                                and spriden_change_ind is null)
                            ) LIKE '%'||UPPER(:ED_Vendor)||'%'
--                    and FPBPOHD_PO_DATE between
--                        coalesce(to_date(:DT_POFrom),to_date('01-JAN-1900'))
--                        and
--                        coalesce(to_date(:DT_POTo),to_date('31-DEC-2900'))
       )
/*
 ) join (
    select distinct
        fpbpohd_orgn_code
    from fpbpohd
    where
         FPBPOHD.FPBPOHD_CHANGE_SEQ_NUM is null
         and UPPER(FPBPOHD.FPBPOHD_NAME) LIKE '%'||UPPER(:ED_PurchasingAgent)||'%'
         --and UPPER((select SPRIDEN_LAST_NAME from spriden where spriden_id = fpbpohd_vend_pidm and spriden_change_ind is null)) LIKE '%'||UPPER(:ED_Vendor)||'%'
         and FPBPOHD_PO_DATE between
              coalesce(to_date(:DT_POFrom),to_date('01-JAN-1900'))
            and
              coalesce(to_date(:DT_POTo),to_date('31-DEC-2900'))

    order by 1
) on ftvorgn_orgn_code = fpbpohd_orgn_code
    and
 */
)
where rn = 1    ;

select * from all_tab_comments where upper(comments) like '%REQUES%'; --table_name = 'FPRREQA';
select * from all_col_comments where table_name = 'FPBREQH';
select fprreqa_reqh_code from FPRREQA ;
--FPBREQH_ATYP_CODE	ACCOUNT TYPE CODE:  Classifies an account type i.e., asset, liabilities,        control, fund balance, revenue, and labor expenses are used for reporting       purposes.
select * from fpbreqh;

select 
    fpbreqh_code
    
    , fpbreqh_activity_date
    , fpbreqh_user_id
    , fpbreqh_reqh_date
    , fpbreqh_trans_date
    , fpbreqh_name
    , fpbreqh_phone_area
    , fpbreqh_phone_num
    , fpbreqh_phone_ext
    , fpbreqh_vend_pidm
    , fpbreqh_atyp_code
    , fpbreqh_atyp_seq_num
    , fpbreqh_coas_code
    , fpbreqh_orgn_code
    , fpbreqh_reqd_date
    , fpbreqh_complete_ind
    , fpbreqh_print_ind
    , fpbreqh_encumb_ind
    , fpbreqh_susp_ind
    , fpbreqh_cancel_ind
    , fpbreqh_cancel_date
    , fpbreqh_post_date
    , fpbreqh_appr_ind
    , fpbreqh_text_ind
    , fpbreqh_edit_defer_ind
    , fpbreqh_recomm_vend_name
    , fpbreqh_curr_code
    , fpbreqh_nsf_on_off_ind
    , fpbreqh_single_acctg_ind
    , fpbreqh_closed_ind
    , fpbreqh_ship_code
    , fpbreqh_rqst_type_ind
    , fpbreqh_inventory_req_ind
    , fpbreqh_crsn_code
    , fpbreqh_delivery_comment
    , fpbreqh_email_addr
    , fpbreqh_fax_area
    , fpbreqh_fax_number
    , fpbreqh_fax_ext
    , fpbreqh_attention_to
    , fpbreqh_vendor_contact
    , fpbreqh_disc_code
    , fpbreqh_vend_email_addr
    , fpbreqh_copied_from
    , fpbreqh_tgrp_code
    , fpbreqh_req_print_date
    , fpbreqh_closed_date
from fpbreqh
;


