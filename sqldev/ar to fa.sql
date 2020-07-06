select spriden_id, tbraccd.* from tbraccd join spriden on tbraccd_pidm = spriden_pidm and spriden_change_ind is null
where tbraccd_term_code = 202020
and spriden_id = 'N00228786';

select * from all_tab_comments where table_name in ('TBRAPPL','TBRACCT','TBBDETC','TBRACCD','TSRTGID');
select column_name from all_col_comments where table_name = 'TBRACCD';
desc tbBDETC;

select * from tbrappl where tbrappl_pidm = 228921;
select * from tbraccd where tbraccd_pidm = 228921;
select f_format_name(228921) as name from dual;


SELECT 
    tbrappl_pidm    AS  PERSON_UID
    , spriden_id    ID
    , nsudev.f_format_name(tbrappl_pidm)    NAME
    , tbraccd_charge.tbraccd_term_code      TERM_CODE
--    , tbraccd_pay.tbraccd_term_code pay_term
    , tbrappl_pay_tran_number   PAY_TRAN_NUMBER
    , tbrappl_cpdt_tran_number  CONTRACT_PAYMENT_TRANSACTION
    , tbbdetc_pay.tbbdetc_priority      PAYMENT_PRIORITY
    , tbraccd_pay.tbraccd_detail_code   PAY_DETAIL_CODE
    , tbbdetc_pay.tbbdetc_desc  PAY_DETAIL_CODE_DESC
    , tbbdetc_pay.tbbdetc_type_ind  PAY_DETAIL_CODE_TYPE
    , tbrappl_chg_tran_number   CHARGE_TRAN_NUMBER
    , tbbdetc_charge.tbbdetc_priority   CHARGE_PRIORITY
    , tbraccd_charge.tbraccd_detail_code    CHARGE_DETAIL_CODE
    , tbbdetc_charge.tbbdetc_desc           CHARGE_DETAIL_CODE_DESC
    , tbbdetc_charge.tbbdetc_type_ind       CHARGE_DETAIL_CODE_TYPE
    , tbrappl_amount        APPLIED_AMOUNT
    , NVL(tbraccd_pay.tbraccd_effective_date,tbraccd_charge.tbraccd_effective_date) APPLIED_DATE
    , tbrappl_direct_pay_ind    DIRECT_PAY_IND
    , tbrappl_direct_pay_type   DIRECT_PAY_TYPE
    , tbrappl_inv_number_paid   INVOICE_NUMBER_PAID
    , tbrappl_reappl_ind        REAPPLICATION_IND
    , tbrappl_acct_feed_ind     ACCOUNT_POSTING_STATUS
    , tbrappl_feed_date         POSTING_DATE
    , tbrappl_feed_doc_code     POSTING_DOCUMENT
    , tbrappl_activity_date     APPL_OF_PAYMENT_ACTIVITY_DATE
FROM
    tbrappl -- Detail Application of Payment
    JOIN tbraccd tbraccd_pay -- Account Charge/Payment Detail Table
        ON tbrappl_pidm = tbraccd_pay.tbraccd_pidm
        AND tbrappl_pay_tran_number = tbraccd_pay.tbraccd_tran_number
        AND tbraccd_pay.tbraccd_term_code = 202020
    JOIN tbbdetc tbbdetc_pay
        ON tbraccd_pay.tbraccd_detail_code = tbbdetc_pay.tbbdetc_detail_code
    JOIN tbraccd tbraccd_charge -- Account Charge/Payment Detail Table
        ON tbrappl_pidm = tbraccd_charge.tbraccd_pidm
        AND tbrappl_chg_tran_number = tbraccd_charge.tbraccd_tran_number
        AND tbraccd_charge.tbraccd_term_code = 202020
    JOIN tbbdetc tbbdetc_charge
        ON tbraccd_charge.tbraccd_detail_code = tbbdetc_charge.tbbdetc_detail_code
    JOIN spriden
        ON tbrappl_pidm = spriden_pidm
        AND spriden_change_ind IS NULL
WHERE
    tbrappl_pidm = 228921
;
    
select * from all_tables where table_name like '%CONT'; -- tcont;
select * from all_col_comments where table_name = 'TBBCSTU'; --tbbcstu_stsp_key_sequence
select * from tbbcont; -- rprcont
select * from tbbdetc;
select * from tbbcont;
select * from tbbcstu
where tbbcstu_stu_pidm = 228921 and tbbcstu_term_code = 202020;

---------------------------------------

WITH W_AUTH_EXMPT AS(
    SELECT --contract authorizations 
        tbbcstu_stu_pidm            PIDM
        , 'CONT'                    TYPE
        , tbbcstu_contract_priority PRIORITY
        , spriden_id                CONTRACT_ID
        , TO_CHAR(tbbcstu_contract_number)  CONT_EXMPT_NUMBER
        , tbbcstu_term_code         TERM_CODE
        , tbbcstu_del_ind           DEL_IND
        , tbbcstu_auth_number       AUTH_NUMBER
        , tbbcstu_auth_ind          AUTH_IND
        , tbbcstu_student_cont_roll_ind ROLL_IND
        , tbbcstu_term_code_expiration  TERM_CODE_EXP
        , tbbcstu_sponsor_ref_number    SPONSOR_REF
        , tbbcstu_max_student_amount    MAX_STUDENT_AMT
        , tbbcstu_stsp_key_sequence     STUDY_PATH_SEQNO
        , tbbcont_desc                  DESCRIPTION
        , tbbcont_detail_pay_code       DETAIL_PAY_CODE
        , tbbcont_detail_chg_code       DETAIL_CHG_CODE
        , tbbcont_contract_roll_ind     CONT_ROLL_IND
        , tbbcont_student_cont_roll_ind CONT_STU_ROLL_IND
        , tbbcont_term_code_expiration  CONT_TERM_CODE_EXP
    FROM 
        tbbcstu
        JOIN tbbcont
            ON tbbcstu_contract_pidm = tbbcont_pidm 
            AND tbbcstu_term_code = tbbcont_term_code
            AND tbbcstu_contract_number = tbbcont_contract_number
        JOIN spriden
            ON tbbcstu_contract_pidm = spriden_pidm
            AND spriden_change_ind IS NULL
    WHERE 
        tbbcstu_term_code = :term_code
    
    UNION
    
    SELECT -- Exemptions
        tbbestu_pidm                    AS  PIDM
        , 'EXMPT'                           TYPE
        , tbbestu_exemption_priority        PRIORITY
        , NULL                              CONTRACT_PIDM                
        , tbbestu_exemption_code            CONT_EXMPT_NUMBER
        , tbbestu_term_code                 TERM_CODE
        , tbbestu_del_ind                   DEL_IND
        , NULL                              AUTH_NUMBER
        , NULL                              AUTH_IND
        , tbbestu_student_expt_roll_ind     ROLL_IND
        , tbbestu_term_code_expiration      TERM_CODE_EXP
        , NULL                              SPONSOR_REF
        , tbbestu_max_student_amount        MAX_STUDENT_AMT
        , tbbestu_stsp_key_sequence         STUDY_PATH_SEQNO
        , tbbexpt_desc                      DESCRIPTION
        , tbbexpt_detail_code               DETAIL_PAY_CODE
        , NULL                              DETAIL_CHG_CODE
        , tbbexpt_exemption_roll_ind        EXMPT_ROLL_IND
        , tbbexpt_student_expt_roll_ind     EXMPT_STU_ROLL_IND
        , tbbexpt_term_code_expiration      EXMPT_TERM_CODE_EXP
    FROM
        tbbestu
        JOIN tbbexpt 
            ON tbbestu_exemption_code = tbbexpt_exemption_code
            AND tbbestu_term_code = tbbexpt_term_code
    WHERE
        tbbestu_term_code = :term_code
)
, W_PAYMENTS_APPLIED AS(
    SELECT 
        tbrappl_pidm                        AS  PERSON_UID
        , spriden_id                            ID
        , nsudev.f_format_name(tbrappl_pidm)    NAME
        , tbraccd_charge.tbraccd_term_code      TERM_CODE
        , tbrappl_pay_tran_number               PAY_TRAN_NUMBER
        , tbrappl_cpdt_tran_number              CONTRACT_PAYMENT_TRANSACTION
        , tbbdetc_pay.tbbdetc_priority          PAYMENT_PRIORITY
        , tbraccd_pay.tbraccd_detail_code       PAY_DETAIL_CODE
        , tbbdetc_pay.tbbdetc_desc              PAY_DETAIL_CODE_DESC
        , tbbdetc_pay.tbbdetc_type_ind          PAY_DETAIL_CODE_TYPE
        , tbrappl_chg_tran_number               CHARGE_TRAN_NUMBER
        , tbbdetc_charge.tbbdetc_priority       CHARGE_PRIORITY
        , tbraccd_charge.tbraccd_detail_code    CHARGE_DETAIL_CODE
        , tbbdetc_charge.tbbdetc_desc           CHARGE_DETAIL_CODE_DESC
        , tbbdetc_charge.tbbdetc_type_ind       CHARGE_DETAIL_CODE_TYPE
        , tbrappl_amount                        APPLIED_AMOUNT
        , NVL(tbraccd_pay.tbraccd_effective_date,tbraccd_charge.tbraccd_effective_date) APPLIED_DATE
        , tbrappl_direct_pay_ind                DIRECT_PAY_IND
        , tbrappl_direct_pay_type               DIRECT_PAY_TYPE
        , tbrappl_inv_number_paid               INVOICE_NUMBER_PAID
        , tbrappl_reappl_ind                    REAPPLICATION_IND
        , tbrappl_acct_feed_ind                 ACCOUNT_POSTING_STATUS
        , tbrappl_feed_date                     POSTING_DATE
        , tbrappl_feed_doc_code                 POSTING_DOCUMENT
        , tbrappl_activity_date                 APPL_OF_PAYMENT_ACTIVITY_DATE
    FROM
        tbrappl -- Detail Application of Payment
        JOIN tbraccd tbraccd_pay -- Account Charge/Payment Detail Table
            ON tbrappl_pidm = tbraccd_pay.tbraccd_pidm
            AND tbrappl_pay_tran_number = tbraccd_pay.tbraccd_tran_number
            AND tbraccd_pay.tbraccd_term_code = 202020
        JOIN tbbdetc tbbdetc_pay
            ON tbraccd_pay.tbraccd_detail_code = tbbdetc_pay.tbbdetc_detail_code
        JOIN tbraccd tbraccd_charge -- Account Charge/Payment Detail Table
            ON tbrappl_pidm = tbraccd_charge.tbraccd_pidm
            AND tbrappl_chg_tran_number = tbraccd_charge.tbraccd_tran_number
            AND tbraccd_charge.tbraccd_term_code = 202020
        JOIN tbbdetc tbbdetc_charge
            ON tbraccd_charge.tbraccd_detail_code = tbbdetc_charge.tbbdetc_detail_code
        JOIN spriden
            ON tbrappl_pidm = spriden_pidm
            AND spriden_change_ind IS NULL
    WHERE
        tbrappl_pidm IN(
                            SELECT DISTINCT
                                pidm
                            FROM
                                w_auth_exmpt
        )
)
SELECT 
    w_auth_exmpt.pidm
    , w_payments_applied.id STUDENT_ID
    , w_payments_applied.name STUDENT_NAME
    , w_auth_exmpt.type
    , w_auth_exmpt.priority
    , w_auth_exmpt.contract_id
    , w_auth_exmpt.cont_exmpt_number
    , w_auth_exmpt.term_code
    , w_auth_exmpt.del_ind
    , w_auth_exmpt.auth_number
    , w_auth_exmpt.auth_ind
    , w_auth_exmpt.roll_ind
    , w_auth_exmpt.term_code_exp
    , w_auth_exmpt.sponsor_ref

    , w_auth_exmpt.study_path_seqno
    , w_auth_exmpt.description
    , w_auth_exmpt.detail_pay_code
    , w_auth_exmpt.detail_chg_code
    , w_auth_exmpt.cont_roll_ind
    , w_auth_exmpt.cont_stu_roll_ind
    , w_auth_exmpt.cont_term_code_exp
    , w_auth_exmpt.max_student_amt
    
    , w_payments_applied.pay_tran_number
    , w_payments_applied.contract_payment_transaction
    , w_payments_applied.payment_priority
    , w_payments_applied.pay_detail_code
    , w_payments_applied.pay_detail_code_desc
    , w_payments_applied.pay_detail_code_type
    , w_payments_applied.charge_tran_number
    , w_payments_applied.charge_priority
    , w_payments_applied.charge_detail_code
    , w_payments_applied.charge_detail_code_desc
    , w_payments_applied.charge_detail_code_type
    , w_payments_applied.applied_amount
    , w_payments_applied.applied_date
    , w_payments_applied.direct_pay_ind
    , w_payments_applied.direct_pay_type
    , w_payments_applied.invoice_number_paid
    , w_payments_applied.reapplication_ind
    , w_payments_applied.account_posting_status
    , w_payments_applied.posting_date
    , w_payments_applied.posting_document
    , w_payments_applied.appl_of_payment_activity_date
    
FROM
    w_auth_exmpt
    LEFT JOIN w_payments_applied
        ON w_auth_exmpt.pidm = w_payments_applied.person_uid
        AND  w_auth_exmpt.term_code = w_payments_applied.term_code
        AND  w_auth_exmpt.detail_pay_code = w_payments_applied.pay_detail_code
WHERE
    w_auth_exmpt.pidm = 228921
    ; --;
desc TBBEXPT;
