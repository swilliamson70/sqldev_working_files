WITH W_EMPLOYEE AS(
    SELECT
        base.nbrbjob_pidm           AS  PERSON_UID
        , spriden_id                    ID
        , spriden_last_name             LAST_NAME
        , spriden_first_name            FIRST_NAME
        , spriden_mi                    MIDDLE_NAME
        , posn.nbrbjob_posn             POSITION
        , posn.nbrbjob_suff             POSITION_SUFFIX
        , posn.nbrbjob_begin_date       POSITION_BEGIN_DATE
        , posn.nbrbjob_end_date         POSITION_END_DATE
        , posn.nbrbjob_contract_type    POSITION_CONTRACT_TYPE
    FROM(
            SELECT DISTINCT
                nbrbjob_pidm
            FROM
                nbrbjob
        )BASE
        LEFT JOIN(
            SELECT
                nbrbjob_pidm
               -- , f_format_name(nbrbjob_pidm,'LFMI') emp
                , nbrbjob_posn
                , nbrbjob_suff
                , nbrbjob_begin_date
                , nbrbjob_end_date
                , nbrbjob_contract_type
                , ROW_NUMBER() OVER (PARTITION BY nbrbjob_pidm
                                    ORDER BY CASE
                                                WHEN NVL(nbrbjob_end_date,TO_DATE('31-DEC-2999')) >= TRUNC(SYSDATE) THEN 1
                                                ELSE 2
                                             END -- sort all current assignments 1st
                                            , CASE nbrbjob_contract_type
                                                WHEN 'P' THEN 1
                                                WHEN 'S' THEN 2
                                                WHEN 'O' THEN 3
                                                ELSE 4
                                             END -- sort contract type next
                                            , nbrbjob_begin_date DESC -- then sort by most recent start
                                            ) RN
            FROM nbrbjob
        ) POSN
            ON base.nbrbjob_pidm = posn.nbrbjob_pidm
            AND posn.rn = 1
        JOIN spriden
            ON base.nbrbjob_pidm = spriden_pidm
            AND spriden_change_ind IS NULL
)
,W_ADDRESSES AS(
    SELECT
        spraddr_pidm                    AS  PERSON_UID
        , gtvsdax_internal_code_seqno       GTVSDAX_SEQNO
        , spraddr_atyp_code                 ADDRESS_TYPE
        , spraddr_seqno                     ADDRESS_TYPE_SEQNO
        , spraddr_from_date                 ADDRESS_FROM_DATE
        , spraddr_to_date                   ADDRESS_TO_DATE
        , spraddr_status_ind                ADDRESS_STATUS_IND
        , spraddr_street_line1              STREET_LINE1
        , spraddr_street_line2              STREET_LINE2
        , spraddr_street_line3              STREET_LINE3
        , spraddr_city                      CITY
        , spraddr_stat_code                 STATE_PROVINCE
        , spraddr_zip                       POSTAL_CODE
        , spraddr_cnty_code                 COUNTY
        , spraddr_natn_code                 NATION
        , ROW_NUMBER() OVER (
                PARTITION BY spraddr_pidm, gtvsdax_internal_code_seqno
                ORDER BY gtvsdax_internal_code_seqno
                    , NVL(spraddr_status_ind,'A')
                    , NVL(spraddr_to_date,TO_DATE('31-DEC-2999','DD-MON-YYYY')) desc
                ) RN
    FROM
        spraddr
        JOIN gtvsdax
            ON spraddr_pidm in (select distinct person_uid from w_employee)
            AND gtvsdax_internal_code = 'W2ADDR'
            AND gtvsdax_external_code = spraddr_atyp_code
    WHERE
        ( 
            ( :cb_MA_ExpiredAddress IS NULL
                AND(    spraddr_atyp_code = 'MA'
                        AND spraddr_status_ind IS NULL
                )
                OR(
                    :cb_MA_ExpiredAddress IS NOT NULL
                    OR spraddr_atyp_code <> 'MA'
                )
            )
        )AND
        ( 
            ( :cb_PR_ExpiredAddress IS NULL
                AND(    spraddr_atyp_code = 'PR'
                        AND spraddr_status_ind IS NULL
                )
                OR(
                    :cb_PR_ExpiredAddress IS NOT NULL
                    OR spraddr_atyp_code <> 'PR'
                )
            )
        )
        
)
select * from w_addresses where person_uid = 227763;
, W_NHRDIST AS(
    SELECT DISTINCT 
        nhrdist_pidm
        , nhrdist_year
    FROM
        nhrdist
    WHERE
        nhrdist_year BETWEEN
                            CASE
                                WHEN :dd_PayrollYear = 'Any Year' THEN
                                    '1900'
                                ELSE
                                    TO_CHAR(:dd_PayrollYear)
                            END
                        AND
                            CASE
                                WHEN :dd_PayrollYear = 'Any Year' THEN
                                    '2900'
                                ELSE
                                    TO_CHAR(:dd_PayrollYear)
                            END        
)
, W_STATE_LIST AS(
    SELECT
        stvstat_code
    FROM
        stvstat
    WHERE
        (:cb_AllStates IS NOT NULL
        OR  stvstat_code = :lb_States)
)
SELECT
        w_employee.person_uid
        , w_employee.id
        , w_employee.last_name
        , w_employee.first_name
        , w_employee.middle_name
        , w_employee.position
        , w_employee.position_suffix
        , w_employee.position_begin_date
        , w_employee.position_end_date
        , w_employee.position_contract_type
        
        --, w2_address.person_uid             AS  W2_PERSON_UID
        , w2_address.gtvsdax_seqno              W2_GTVSDAX_SEQNO
        , w2_address.address_type               W2_ADDRESS_TYPE
        , w2_address.address_type_seqno         W2_ADDRESS_TYPE_SEQNO
        , w2_address.address_from_date          W2_ADDRESS_FROM_DATE
        , w2_address.address_to_date            W2_ADDRESS_TO_DATE
        , w2_address.address_status_ind         W2_ADDRESS_STATUS_IND
        , w2_address.street_line1               W2_STREET_LINE1
        , w2_address.street_line2               W2_STREET_LINE2
        , w2_address.street_line3               W2_STREET_LINE3
        , w2_address.city                       W2_CITY
        , w2_address.state_province             W2_STATE_PROVINCE
        , w2_address.postal_code                W2_POSTAL_CODE
        , w2_address.county                     W2_COUNTY
        , w2_address.nation                     W2_NATION
--11-24
        --, ma_address.person_uid                 MA_PERSON_UID
        , ma_address.gtvsdax_seqno              MA_GTVSDAX_SEQNO
        , ma_address.address_type               MA_ADDRESS_TYPE
        , ma_address.address_type_seqno         MA_ADDRESS_TYPE_SEQNO
        , ma_address.address_from_date          MA_ADDRESS_FROM_DATE
        , ma_address.address_to_date            MA_ADDRESS_TO_DATE
        , ma_address.address_status_ind         MA_ADDRESS_STATUS_IND
        , ma_address.street_line1               MA_STREET_LINE1
        , ma_address.street_line2               MA_STREET_LINE2
        , ma_address.street_line3               MA_STREET_LINE3
        , ma_address.city                       MA_CITY
        , ma_address.state_province             MA_STATE_PROVINCE
        , ma_address.postal_code                MA_POSTAL_CODE
        , ma_address.county                     MA_COUNTY
        , ma_address.nation                     MA_NATION
-- 25-38
        --, pr_address.person_uid                 PR_PERSON_UID
        , pr_address.gtvsdax_seqno              PR_GTVSDAX_SEQNO
        , pr_address.address_type               PR_ADDRESS_TYPE
        , pr_address.address_type_seqno         PR_ADDRESS_TYPE_SEQNO
        , pr_address.address_from_date          PR_ADDRESS_FROM_DATE
        , pr_address.address_to_date            PR_ADDRESS_TO_DATE
        , pr_address.address_status_ind         PR_ADDRESS_STATUS_IND
        , pr_address.street_line1               PR_STREET_LINE1
        , pr_address.street_line2               PR_STREET_LINE2
        , pr_address.street_line3               PR_STREET_LINE3
        , pr_address.city                       PR_CITY
        , pr_address.state_province             PR_STATE_PROVINCE
        , pr_address.postal_code                PR_POSTAL_CODE
        , pr_address.county                     PR_COUNTY
        , pr_address.nation                     PR_NATION
--39-52

FROM
    w_employee
    LEFT JOIN(
        SELECT
            PERSON_UID
            , GTVSDAX_SEQNO
            , ADDRESS_TYPE
            , ADDRESS_TYPE_SEQNO
            , ADDRESS_FROM_DATE
            , ADDRESS_TO_DATE
            , ADDRESS_STATUS_IND
            , STREET_LINE1
            , STREET_LINE2
            , STREET_LINE3
            , CITY
            , STATE_PROVINCE
            , POSTAL_CODE
            , COUNTY
            , NATION
            , ROW_NUMBER() OVER (PARTITION BY PERSON_UID ORDER BY GTVSDAX_SEQNO,ADDRESS_TYPE_SEQNO) RN
        FROM
            w_addresses
        WHERE
            address_from_date <= TRUNC(SYSDATE)
            AND (address_to_date >= TRUNC(SYSDATE)
                OR address_to_date IS NULL)
            AND address_status_ind IS NULL
        ) W2_ADDRESS
        ON w_employee.person_uid = w2_address.person_uid
        AND w2_address.rn = 1

    LEFT JOIN(
        SELECT
            PERSON_UID
            , GTVSDAX_SEQNO
            , ADDRESS_TYPE
            , ADDRESS_TYPE_SEQNO
            , ADDRESS_FROM_DATE
            , ADDRESS_TO_DATE
            , ADDRESS_STATUS_IND
            , STREET_LINE1
            , STREET_LINE2
            , STREET_LINE3
            , CITY
            , STATE_PROVINCE
            , POSTAL_CODE
            , COUNTY
            , NATION
            , RN

        FROM
            w_addresses) MA_ADDRESS
        ON w_employee.person_uid = ma_address.person_uid
        AND ma_address.address_type = 'MA'
        AND ma_address.rn = 1

    LEFT JOIN(
        SELECT
            PERSON_UID
            , GTVSDAX_SEQNO
            , ADDRESS_TYPE
            , ADDRESS_TYPE_SEQNO
            , ADDRESS_FROM_DATE
            , ADDRESS_TO_DATE
            , ADDRESS_STATUS_IND
            , STREET_LINE1
            , STREET_LINE2
            , STREET_LINE3
            , CITY
            , STATE_PROVINCE
            , POSTAL_CODE
            , COUNTY
            , NATION
            , RN
        FROM
            w_addresses) PR_ADDRESS
        ON w_employee.person_uid = pr_address.person_uid
        AND pr_address.address_type = 'PR'
        AND pr_address.rn = 1
WHERE
    (
        (:cb_CurrentEmployees = 1
            AND NVL(w_employee.position_end_date,TO_DATE('31-DEC-2999')) >= TRUNC(SYSDATE)
        )OR :cb_CurrentEmployees is null
    )
    AND
    (
        EXISTS(
               SELECT
                   nhrdist_pidm
               FROM
                   w_nhrdist
               WHERE
                   nhrdist_pidm = w_employee.person_uid
             )
    )
    AND
    ( -- country codes - US
        (:cb_CountryUS IS NOT NULL 
            AND w2_address.nation = 'US')
        OR(:cb_CountryNonUS IS NOT NULL
            AND w2_address.nation <> 'US')
        OR(:cb_CountryNulls IS NOT NULL
            AND w2_address.nation IS NULL)
    )
    AND
    ( -- state codes
        (:cb_AllStates IS NOT NULL)
        OR(:cb_AllStates IS NULL 
            AND w2_address.state_province IN(   SELECT
                                                    stvstat_code
                                                FROM
                                                    w_state_list
                                            )       
        )
    )
order by w2_address.nation        
;
    



--NHRDIST_PIDM
select 1 as x from dual 
where 
    exists (
select * from nhrdist where nhrdist_pidm = 31091
and nhrdist_year between case when :year = 'Any' then '1900' else :year end 
                 and case when :year = 'Any' then '2900' else :year end
);

SELECT
    'Any Year' YEAR
FROM
    dual
UNION
SELECT DISTINCT
    ptrcaln_year
FROM
    ptrcaln
ORDER BY 1 DESC
;