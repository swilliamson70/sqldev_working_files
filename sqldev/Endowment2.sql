select * from adrdids where adrdids_desg = 'SCH0012';
select f_format_name(138188,'LFMI') desgname from dual; -- Cooper, Bertie
select * from designation_id where designation = 'SCH0012';
select * from designation_id where designation = 'SCH0384';
select * from AOBORGN where aoborgn_pidm = 150739;

select * from salutation where entity_uid = 150739 ;
select * from spriden where spriden_id = 'N00154926'; -- 150739 Burl Overmon


WITH w_mailing_info AS(
    SELECT
        designation_id.designation  MAILING_DESIGNATION
        , designation_id.id         MAILING_ID
        , designation_id.name       MAILING_NAME
        , designation_id.entity_uid MAILING_PIDM
        , coalesce(cfml.salutation,sfml.salutation,aoborgn_business) MAILING_CFML
        , coalesce(cife.salutation,sife.salutation) MAILING_CIFE
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
            LEFT JOIN salutation SFML
                ON designation_id.entity_uid = sfml.entity_uid
                AND sfml.salutation_type = 'SFML'
            LEFT JOIN salutation SIFE
                ON designation_id.entity_uid = sife.entity_uid
                AND sife.salutation_type = 'SIFE'
            LEFT JOIN aoborgn
                 ON designation_id.entity_uid = aoborgn_pidm

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
select * from w_mailing_info;    