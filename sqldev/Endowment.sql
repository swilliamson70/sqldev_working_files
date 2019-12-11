select (to_char(sysdate,'YY')||(to_char(sysdate,'YY')+1)) as aidyear from dual;

SELECT * FROM adbdesg left join designation_id on adbdesg_desg = designation;
SELECT * FROM DESIGNATION_ID where entity_uid = 4200;
select * from address_current where entity_uid = 31091;
select 
    address_current.entity_uid  MAILING_UID
    , street_line1              MAILING_STREET1
    , street_line2              MAILING_STREET2
    , city                      MAILING_CITY
    , state_province            MAILING_STATE
    , postal_code               MAILING_POSTAL
    , nation                    MAILING_NATION
    , row_number() over ( partition by entity_uid
                          order by entity_uid
                          , case 
                                when address_type = 'MA' then 1
                                else 2
                            end
                         , address_seq_number desc) rn
FROM address_current
where address_type = 'MA'
and entity_uid = 163645
;

select designation_id.designation, designation_id.id, designation_id.name, designation_id.entity_uid 
    , cfml.entity_uid, cfml.salutation_type, cfml.salutation CFML_SALUTATION, cife.salutation_type, cife.salutation CIFE_SALUTATION
    , address_current.street_line1, address_current.street_line2,address_current.city,address_current.state_province,address_current.postal_code,address_current.nation
from
    designation_id
        LEFT JOIN salutation CFML
            ON designation_id.entity_uid = cfml.entity_uid
            and cfml.salutation_type = 'CFML'
        LEFT JOIN salutation CIFE
            on designation_id.entity_uid = cife.entity_uid
            and CIFE.salutation_type = 'CIFE'             
            
        LEFT JOIN ( 
                select 
                    address_current.entity_uid
                    , street_line1
                    , street_line2
                    , city
                    , state_province
                    , postal_code
                    , nation
                    , row_number() over ( partition by entity_uid
                                          order by entity_uid
                                          , case 
                                                when address_type = 'MA' then 1
                                                else 2
                                            end
                                         , address_seq_number desc) rn
                FROM address_current
                where address_type = 'MA'            
        ) address_current
            on designation_id.entity_uid = address_current.entity_uid
            and rn = 1
;

/*
Advancement.Endowment
add salutation - combined formal and combined informal (preferred?), designation_id.name, address for mail merge
salutation - entity_uid, combined formal is CFML - combined informal is CIFE

*/
WITH w_mailing_info AS(
    SELECT
        designation_id.designation  MAILING_DESIGNATION
        , designation_id.id         MAILING_ID
        , designation_id.name       MAILING_NAME
        , designation_id.entity_uid MAILING_PIDM
        , cfml.salutation           MAILING_CFML
        , cife.salutation           MAILING_CIFE
        , address_current.street_line1 MAILING_STREET1
        , address_current.street_line2 MAILING_STREET2
        , address_current.city      MAILING_CITY
        , address_current.state_province MAILING_STATE
        , address_current.postal_code MAILING_POSTAL_CODE
        , address_current.nation    MAILING_NATION
    FROM
        designation_id
            LEFT JOIN salutation CFML
                ON designation_id.entity_uid = cfml.entity_uid
                AND cfml.salutation_type = 'CFML'
            LEFT JOIN salutation CIFE
                ON designation_id.entity_uid = cife.entity_uid
                AND CIFE.salutation_type = 'CIFE'             
                
            LEFT JOIN ( 
                    SELECT 
                        address_current.entity_uid
                        , street_line1
                        , street_line2
                        , city
                        , state_province
                        , postal_code
                        , nation
                        , ROW_NUMBER() OVER ( PARTITION BY entity_uid
                                              ORDER BY entity_uid
                                              , CASE 
                                                    WHEN address_type = 'MA' THEN 1
                                                    ELSE 2
                                                END
                                             , address_seq_number DESC) RN
                    FROM address_current
                    WHERE address_type = 'MA'            
            ) ADDRESS_CURRENT
                ON designation_id.entity_uid = address_current.entity_uid
                AND rn = 1
    )

SELECT
    designation.designation
    , designation.DESIGNATION_NAME
    , w_mailing_info.MAILING_CFML
    , w_mailing_info.MAILING_CIFE
    , w_mailing_info.MAILING_STREET1
    , w_mailing_info.MAILING_STREET2
    , w_mailing_info.MAILING_CITY
    , w_mailing_info.MAILING_STATE
    , w_mailing_info.MAILING_POSTAL_CODE
    , w_mailing_info.MAILING_NATION    
    , AWARD_BY_PERSON.NAME SHOLARSHIP_AWARDED_TO
    , DESIGNATION_ID.ID_COMMENT DESIGNATION_COMMENT
    , AWARD_BY_PERSON.Aid_year
    , sum(AWARD_BY_PERSON.AWARD_PAID_AMOUNT) Award_amount
    , AWARD_BY_PERSON.FUND
    , acct.FISCAL_YEAR
    , acct.GIFT_REVENUE_SCH
    , acct.GIFT_REVENUE_PROG
    , acct.GIFT_REVENUE_CAP_PROJ
    , acct.MARKET_VALUE_END_BAL
    , acct.MARKET_VALUE_BEG_BAL
    , acct.BEGINNING_BALANCE
    , acct.INVESTMENT_INCOME
    , acct.INTEREST_INCOME
    , coalesce(nullif(acct.INCOME_TRANSFER,0),INCOME_TRANSFER2) INCOME_TRANSFER

FROM(
    select * 
    from adbdesg
    where substr(ADBDESG_FUND_CODE,1,1) = 'E'
    ) adbdesg
    left join designation
        on designation.designation = adbdesg_desg
    left join DESIGNATION_FINAID_FUND
        on DESIGNATION_FINAID_FUND.designation = adbdesg_desg
    left JOIN AWARD_BY_PERSON
        ON AWARD_BY_PERSON.FUND = DESIGNATION_FINAID_FUND.FINANCIAL_AID_FUND
        AND AWARD_BY_PERSON.AWARD_ACCEPT_IND = 'Y'
        and award_by_person.aid_year = :lbYear
        and  AWARD_BY_PERSON.NAME not like '%DO%NOT%USE%'
        and AWARD_BY_PERSON.PERSON_UID not in
            (   select distinct s2.entity_uid
                from donor_category s2
                where s2.entity_uid = AWARD_BY_PERSON.PERSON_UID
                and s2.donor_category = 'BAD'
            )
        and AWARD_BY_PERSON.PERSON_UID not in
            (   SELECT bad_pidm 
                FROM nsudev.nsu_alum_pidm 
                where bad_pidm = AWARD_BY_PERSON.PERSON_UID
            )
    
    left JOIN(
        select * 
        from DESIGNATION_ID di 
        where di.entity_uid = ( select max(di2.entity_uid) 
                                from designation_id di2 
                                where di2.designation = di.designation)
    )designation_id
        ON DESIGNATION_FINAID_FUND.DESIGNATION = DESIGNATION_ID.DESIGNATION
    left JOIN designation_accounting desg_acct
        ON desg_acct.DESIGNATION = DESIGNATION_FINAID_FUND.DESIGNATION
    left JOIN(
        select *
        from(
                SELECT substr(fund, 2) FUND
                , fiscal_year
                ,  substr(fund,1,1) || ACCOUNT ACCOUNT
                , sum(case debit_credit_ind
           -- if it needs to be reverted, remove abs
                        when '+' then -abs(transaction_amount)
                        when '-' then abs(transaction_amount)
                        when 'C' then -transaction_amount
                        when 'D' then transaction_amount
                   end
                   * decode(normal_balance, 'D', 1, 'C', -1)
                    )   AMOUNT
                FROM TRANSACTION_HISTORY 
                WHERE
                    CHART_OF_ACCOUNTS = 'F' 
                    AND FUND NOT LIKE 'S%' 
                    AND ACCOUNT IN ('320045', '410110', '410111', '410112', '430100', '595004', '891000','420100', '101999', '595002')
                    --AND (FUND LIKE 'E%' OR debit_credit_ind = 'C')
                GROUP BY ACCOUNT, FUND, fiscal_year
            )
            PIVOT(
                MAX(AMOUNT)
                FOR ACCOUNT IN (
                    'E410110' GIFT_REVENUE_SCH,
                    'E410111' GIFT_REVENUE_PROG,
                    'E410112' GIFT_REVENUE_CAP_PROJ,
                    'M101999' MARKET_VALUE_END_BAL,
                    'M320045' MARKET_VALUE_BEG_BAL,
                    'E320045' BEGINNING_BALANCE,
                    'E430100' INVESTMENT_INCOME,
                    'E420100' INTEREST_INCOME,
                    'E595004' INCOME_TRANSFER,
                    'E595002' INCOME_TRANSFER2
                )
            )
        ) acct
        ON substr(adbdesg.ADBDESG_FUND_CODE,2) = acct.fund
        and substr(fiscal_year,3,2) = substr( :lbYear ,1,2)
    LEFT JOIN w_mailing_info 
        ON adbdesg_desg = w_mailing_info.mailing_designation
    --where :btnQuery is not null

GROUP BY
    designation.designation,
    designation.DESIGNATION_NAME,
    w_mailing_info.MAILING_CFML,
    w_mailing_info.MAILING_CIFE,
    w_mailing_info.MAILING_STREET1,
    w_mailing_info.MAILING_STREET2,
    w_mailing_info.MAILING_CITY,
    w_mailing_info.MAILING_STATE,
    w_mailing_info.MAILING_POSTAL_CODE,
    w_mailing_info.MAILING_NATION,
    AWARD_BY_PERSON.NAME,
    DESIGNATION_ID.ID_COMMENT,
    AWARD_BY_PERSON.Aid_year,
    AWARD_BY_PERSON.FUND,
    acct.FISCAL_YEAR,
    acct.GIFT_REVENUE_SCH,
    acct.GIFT_REVENUE_PROG,
    acct.GIFT_REVENUE_CAP_PROJ,
    acct.MARKET_VALUE_END_BAL,
    acct.MARKET_VALUE_BEG_BAL,
    acct.BEGINNING_BALANCE,
    acct.INVESTMENT_INCOME,
    acct.INCOME_TRANSFER,
    acct.INTEREST_INCOME,
    INCOME_TRANSFER2
;