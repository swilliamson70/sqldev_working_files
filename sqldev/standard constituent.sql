CREATE OR REPLACE VIEW nsudev.nsu_standard_const_view AS 

    WITH w_constituent AS(
        SELECT
            person_uid,
            id,
            name,
            pref_last_name,
            maiden_last_name,
            spouse_name,
            pref_donor_category,
            pref_donor_category_desc,
            email_preferred_address,
            life_total_giving,
            deceased_ind
        FROM
            constituent
    )
     
    ,w_nsu_exclusion_slot AS(
        SELECT
            entity_uid,
            nph,
            noc,
            nmc,
            nem,
            nam,
            ndn,
            nak,
            ntp,
            ams
        FROM
            nsu_exclusion_slot
    )
    
    , w_annual_giving_slot AS(
        SELECT
            entity_uid,
            total_pledge_payments1,
            fiscal_year1,
            total_giving1
        FROM
            annual_giving_slot
    )
    
    , w_advancement_rating_slot AS(
        SELECT
            entity_uid,
            rating_type1,
            rating_amount1,
            rating1,
            rating_level1,
            rating_type2,
            rating_amount2,
            rating2,
            rating_level2,
            rating_type3,
            rating_amount3,
            rating3,
            rating_level3
        FROM
            advancement_rating_slot
    )
    
    , w_nsu_email_slot AS(
        SELECT
            entity_uid,
            pers_email,
            nsu_email,
            al_email,
            bus_email
        FROM
            nsu_email_slot
    )
    
    , w_nsu_telephone_slot AS(
        SELECT
            entity_uid,
             pr_phone_number,
             pr_primary_ind,
             cl_phone_number,
             cl_primary_ind,
             b1_phone_number,
             b1_primary_ind
        FROM
            nsu_telephone_slot
    )
    
    , w_relationship AS(
        SELECT
            entity_uid,
            relation_source,
            relation_source_desc,
            household_ind,
            combined_mailing_priority,
            combined_mailing_priority_desc,
            related_id
        FROM
            relationship
    )
    
    , w_degree_slot AS(
        SELECT
            person_uid,
            institution_ind,
            degree_1,
            degree_desc_1,
            degree_2,
            degree_desc_2,
            degree_3,
            degree_desc_3,
            academic_year_1,
            academic_year_2,
            academic_year_3,
            major1_1,
            major1_desc_1,
            major1_2,
            major1_desc_2,
            major1_3,
            major1_desc_3,
            degree_date_1,
            degree_date_2,
            degree_date_3
        FROM
            degree_slot
    )
    
    , w_spbpers AS(
        SELECT
            spbpers_pidm,
            spbpers_birth_date,
            spbpers_dead_ind,
            spbpers_vera_ind
        FROM
            spbpers
    )
    
    , w_apbghis AS(
        SELECT
            apbghis_pidm,
            apbghis_total_no_gifts,
            apbghis_high_gift_amt,
            apbghis_last_gift_date
        FROM
            apbghis
    )
    
    , w_amrstaf AS(
        SELECT
            amrstaf_pidm,
            amrstaf_iden_code
        FROM 
            amrstaf
        WHERE
            amrstaf_primary_ind = 'Y'
    )
    
    , w_guriden AS(
        SELECT
            guriden_iden_code,
            guriden_desc
        FROM
            guriden
    )

    ,w_recent_membership AS(
        SELECT
            aarmemb_pidm entity_uid,
            max(AARMEMB_AMST_CODE) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_status,
            max(aarmemb_amct_code) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_category,
            max(AARMEMB_EXP_DATE) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) expiration_date,
            max(AARMEMB_MEMB_NO) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_number
        FROM
            aarmemb
        GROUP BY
            aarmemb_pidm
    )
    
    , w_won_membership AS(
        select
            aarmemb_pidm entity_uid,
            max(AARMEMB_AMST_CODE) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_status,
            max(aarmemb_amct_code) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_category,
            max(AARMEMB_EXP_DATE) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) expiration_date,
            max(AARMEMB_MEMB_NO) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_number
        from
            aarmemb
        where
            aarmemb_membership = 'WON'
        group by
            aarmemb_pidm
    )
    
    ,w_fan_membership AS(
        select
            aarmemb_pidm entity_uid,
            max(AARMEMB_AMST_CODE) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_status,
            max(aarmemb_amct_code) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_category,
            max(AARMEMB_EXP_DATE) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) expiration_date,
            max(AARMEMB_MEMB_NO) keep (dense_rank first order by decode(AARMEMB_AMST_CODE,'A',1,'I',3) asc 
                                                                , AARMEMB_ENTRY_DATE desc
                                                                , AARMEMB_MEMB_NO desc) membership_number
        from
            aarmemb
        where
            aarmemb_membership = 'FAN'
        group by 
            aarmemb_pidm
    )
    
    , w_salutation AS(
        select *
        from(
                SELECT
                    ENTITY_UID,
                    SALUTATION_TYPE,
                    SALUTATION
                FROM salutation
            )
            pivot(
                    max(SALUTATION) for SALUTATION_TYPE in ('CIFE' CIFE,'SIFE' SIFE,'CIFL' CIFL,'SIFL' SIFL)
                 )
    )
    
    ,w_ytd AS(
        select /*+ MATERIALIZE */ 
            entity_uid,
            sum(case when year_pos = 1 then tots end) ytd,
            sum(case when year_pos = 2 then tots end) ytd_1,
            sum(case when year_pos = 3 then tots end) ytd_2,
            sum(case when year_pos = 4 then tots end) ytd_3,
            sum(case when year_pos = 5 then tots end) ytd_4,
            sum(tots) lifetime
        from(
                SELECT
                    entity_uid,
                    to_char(gift_date, 'YYYY') gift_date,
                    sum(nvl(gift_amount,0)) tots
                FROM
                    gift
                group by
                    entity_uid,
                    to_char(gift_date, 'YYYY')
                union
                SELECT
                    entity_uid,
                    to_char(VALUE_DATE, 'YYYY') gift_date,
                    sum(nvl(AUXILIARY_VALUE,0))*-1
                FROM
                    gift_auxiliary
                group by 
                    entity_uid,
                    to_char(VALUE_DATE, 'YYYY')
        ) left join(
                        select
                            to_char(sysdate,'YYYY')-level+1 year,
                            level year_pos
                        from
                            dual
                        connect by level <= 5
           ) on year = gift_date
        group by entity_uid
    )
    
    , w_jfsgd AS(
        select
            entity_uid,
            rating
        from
            advancement_rating
        where
            rating_type = 'JFSGD'
    )
    
    , w_employment AS(
        select
            person_uid,
            max(employer_name) keep (dense_rank first order by orderby asc) employer_name,
            max(position_title) keep (dense_rank first order by orderby asc) position_title
        from(
                SELECT
                    person_uid,
                    employer_name,
                    position_title,
                    1 orderby
                FROM
                    current_employment
                where
                    employment_order = 1
                union
                SELECT
                    person_uid,
                    max(employer_name) keep (dense_rank first order by employment_order desc) employer_name,
                    max(position_title) keep (dense_rank first order by employment_order desc) position_title,
                    2 orderby
                FROM
                    employment_history
                group by 
                    person_uid
        )
        group by person_uid
    )
    
    , w_address AS(
        SELECT
            spraddr_pidm,
            max(spraddr_street_line1) keep (dense_rank first order by decode(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) asc
                                                                    , spraddr_seqno desc) spraddr_street_line1,
            max(spraddr_street_line2) keep (dense_rank first order by decode(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) asc
                                                                    , spraddr_seqno desc) spraddr_street_line2,
            max(spraddr_city) keep (dense_rank first order by decode(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) asc
                                                                    , spraddr_seqno desc) spraddr_city,
            max(spraddr_stat_code) keep (dense_rank first order by decode(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) asc
                                                                    , spraddr_seqno desc) spraddr_stat_code,
            max(spraddr_zip) keep (dense_rank first order by decode(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) asc
                                                                    , spraddr_seqno desc) spraddr_zip,
            max(spraddr_cnty_code) keep (dense_rank first order by decode(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) asc
                                                                    , spraddr_seqno desc) spraddr_cnty_code,
            max(spraddr_natn_code) keep (dense_rank first order by decode(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) asc
                                                                    , spraddr_seqno desc) spraddr_natn_code,
            max(spraddr_atyp_code) keep (dense_rank first order by decode(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) asc
                                                                    , spraddr_seqno desc) spraddr_atyp_code
        FROM
            spraddr
        where
            sysdate between spraddr_from_date and nvl(spraddr_to_date, sysdate +1)
            and spraddr_status_ind is null
        group by
            spraddr_pidm
    )
    
    , w_long_years_given AS(
        select /*+ MATERIALIZE */ 
            spriden_pidm,
            max(l) recent_consecutive_years
        from(
                select distinct 
                    spriden_pidm,
                    agbgift.AGBGIFT_FISC_CODE,
                    level l
                from
                    agbgift
                    join spriden on spriden_pidm = agbgift_pidm
                        and spriden_change_ind is null
                --where AGBGIFT_FISC_CODE <= extract(year from to_date(:parm_DT_GivingEnd)) --to_char(:parm_DT_GivingEnd, 'YYYY')
                connect by prior spriden_pidm = spriden_pidm
                    and prior agbgift_fisc_code = agbgift_fisc_code -1 )
                group by spriden_pidm
         )

    , w_recent_cons_years AS(
        select /*+ MATERIALIZE */ 
            spriden_pidm, 
            max(l) keep (dense_rank first order by agbgift_fisc_code desc) recent_consecutive_years
        from(
                select distinct
                    spriden_pidm,
                    agbgift.AGBGIFT_FISC_CODE,
                    level l
                from
                    agbgift
                    join spriden on spriden_pidm = agbgift_pidm
                    and spriden_change_ind is null
                --where AGBGIFT_FISC_CODE <= extract(year from to_date(:parm_DT_GivingEnd)) --to_char(:parm_DT_GivingEnd, 'YYYY')
                connect by prior spriden_pidm = spriden_pidm
                    and prior agbgift_fisc_code = agbgift_fisc_code -1 )
                group by spriden_pidm
    )
    
    , w_range_tot_gift AS(
        select
            entity_uid,
            trim(to_char(sum(nvl(gift.gift_amount,0)), '999999990.99')) gift_amt
        from
            gift
        --where gift_date between :parm_DT_GivingStart and :parm_DT_GivingEnd
        group by entity_uid
    )
    
    , w_range_tot_aux AS(
        select
            entity_uid,
            trim(to_char(sum(nvl(gift_auxiliary.auxiliary_value,0)), '999999990.99')) gift_amt
        from
            gift_auxiliary
        --where value_date between :parm_DT_GivingStart and :parm_DT_GivingEnd
        group by entity_uid
    )

    , w_spec_purpose AS(
        SELECT 
            entity_uid, 
                max(nvl(SPECIAL_PURPOSE_TYPE,'XXXXX')
                          || '-' || nvl(SPECIAL_PURPOSE_TYPE_DESC,'XXXXXXXXXXXXXXXXXXXXXXXXXX')
                          || '/' || nvl(SPECIAL_PURPOSE_GROUP,'XXXXX')
                          || '-' || nvl(SPECIAL_PURPOSE_GROUP_DESC,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')) keep (dense_rank first order by SPECIAL_PURPOSE_DATE desc, special_purpose_type) spec_purpose
        FROM
            special_purpose_group
        group by entity_uid
    )


SELECT
    w_CONSTITUENT.PERSON_UID,
    w_CONSTITUENT.ID,
    w_CONSTITUENT.NAME,
    w_CONSTITUENT.PREF_LAST_NAME,
    w_CONSTITUENT.MAIDEN_LAST_NAME,
    w_CONSTITUENT.SPOUSE_NAME,
    --w_relationship.related_id related_id,
    --w_relationship.related_combined_name,
    w_CONSTITUENT.PREF_DONOR_CATEGORY,
    w_CONSTITUENT.PREF_DONOR_CATEGORY_DESC,
    w_CONSTITUENT.EMAIL_PREFERRED_ADDRESS,
    w_address.spraddr_street_line1 "STREET_LINE1",
    w_address.spraddr_street_line2 "STREET_LINE2",
    w_address.spraddr_city "CITY",
    w_address.spraddr_stat_code "STATE_PROVINCE",
    w_address.spraddr_zip "POSTAL_CODE",
    w_address.spraddr_cnty_code "COUNTY",
    w_address.spraddr_natn_code "NATION",
    w_address.spraddr_atyp_code "ADDRESS_TYPE",
    w_NSU_EXCLUSION_SLOT.NPH,
    w_NSU_EXCLUSION_SLOT.NOC,
    w_NSU_EXCLUSION_SLOT.NMC,
    w_NSU_EXCLUSION_SLOT.NEM,
    w_NSU_EXCLUSION_SLOT.NAM,
    w_NSU_EXCLUSION_SLOT.NDN,
    w_NSU_EXCLUSION_SLOT.NAK,
    w_NSU_EXCLUSION_SLOT.NTP,
    w_NSU_EXCLUSION_SLOT.AMS,
    nvl(w_SALUTATION.CIFE,w_SALUTATION.SIFE) PREFERRED_FULL_w_SALUTATION,
    nvl(w_SALUTATION.CIFL,w_SALUTATION.SIFL) PREFERRED_SHORT_w_SALUTATION,
    w_SALUTATION.SIFE SIFE,
    w_SALUTATION.SIFL SIFL,
    w_ADVANCEMENT_RATING_SLOT.RATING_TYPE1,
    w_ADVANCEMENT_RATING_SLOT.RATING_AMOUNT1,
    w_ADVANCEMENT_RATING_SLOT.RATING1,
    w_ADVANCEMENT_RATING_SLOT.RATING_LEVEL1,
    w_ADVANCEMENT_RATING_SLOT.RATING_TYPE2,
    w_ADVANCEMENT_RATING_SLOT.RATING_AMOUNT2,
    w_ADVANCEMENT_RATING_SLOT.RATING2,
    w_ADVANCEMENT_RATING_SLOT.RATING_LEVEL2,
    w_ADVANCEMENT_RATING_SLOT.RATING_TYPE3,
    w_ADVANCEMENT_RATING_SLOT.RATING_AMOUNT3,
    w_ADVANCEMENT_RATING_SLOT.RATING3,
    w_ADVANCEMENT_RATING_SLOT.RATING_LEVEL3,
    w_recent_membership.membership_category "MEMBERSHIP_CATEGORY",
    w_recent_membership.membership_status "MEMBERSHIP_NAME",
    w_recent_membership.membership_number "MEMBERSHIP_NUMBER",
    w_recent_membership.expiration_date "EXPIRATION_DATE",
    w_won_membership.membership_category "W_WON_MEMBERSHIP_NAME",
    w_won_membership.membership_status "W_WON_MEMBERSHIP_STATUS",
    w_won_membership.membership_number "W_WON_MEMBERSHIP_NUMBER",
    w_won_membership.expiration_date "WON_EXPIRATION_DATE",
    w_fan_membership.membership_category "W_FAN_MEMBERSHIP_NAME",
    w_fan_membership.membership_status "W_FAN_MEMBERSHIP_STATUS",
    w_fan_membership.membership_number "W_FAN_MEMBERSHIP_NUMBER",
    w_fan_membership.expiration_date "FAN_EXPIRATION_DATE",
    w_NSU_EMAIL_SLOT.PERS_EMAIL,
    w_NSU_EMAIL_SLOT.NSU_EMAIL,
    w_NSU_EMAIL_SLOT.AL_EMAIL,
    w_NSU_EMAIL_SLOT.BUS_EMAIL,
    w_NSU_TELEPHONE_SLOT.PR_PHONE_NUMBER,
    w_NSU_TELEPHONE_SLOT.PR_PRIMARY_IND,
    w_NSU_TELEPHONE_SLOT.CL_PHONE_NUMBER,
    w_NSU_TELEPHONE_SLOT.CL_PRIMARY_IND,
    w_NSU_TELEPHONE_SLOT.B1_PHONE_NUMBER,
    w_NSU_TELEPHONE_SLOT.B1_PRIMARY_IND,
    trim(to_char(nvl(w_ANNUAL_GIVING_SLOT.TOTAL_PLEDGE_PAYMENTS1,0), '999999990.99')) "TOTAL_PLEDGE_PAYMENTS1",
    trim(to_char(nvl(w_CONSTITUENT.LIFE_TOTAL_GIVING,0), '999999990.99')) "LIFE_TOTAL_GIVING",
    trim(to_char(nvl(w_ytd.lifetime,0), '999999990.99')) "LIFE_TOTAL_GIVING_AUX",
    w_ANNUAL_GIVING_SLOT.FISCAL_YEAR1,
    trim(to_char(nvl(w_ANNUAL_GIVING_SLOT.TOTAL_GIVING1,0), '999999990.99')) "TOTAL_GIVING1",
    NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(w_CONSTITUENT.PERSON_UID, 'ANNUAL') "ANNUAL_HOUSEHOLD_GIVING",
    NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(w_CONSTITUENT.PERSON_UID, 'LIFETIME') "LIFETIME_HOUSEHOLD_GIVING",
    w_RELATIONSHIP.RELATION_SOURCE,
    w_RELATIONSHIP.RELATION_SOURCE_DESC,
    w_RELATIONSHIP.COMBINED_MAILING_PRIORITY,
    w_RELATIONSHIP.COMBINED_MAILING_PRIORITY_DESC,
    w_RELATIONSHIP.HOUSEHOLD_IND,
    w_relationship.related_id RELATED_ID,
    w_range_tot_gift.gift_amt "DATE_RANGE_TOTAL_GIVING",
    w_range_tot_aux.gift_amt "DATE_RANGE_TOTAL_AUX_AMT",
    w_DEGREE_SLOT.DEGREE_DATE_1,
    w_DEGREE_SLOT.DEGREE_1,
    w_DEGREE_SLOT.DEGREE_DESC_1,
    w_DEGREE_SLOT.ACADEMIC_YEAR_1,
    w_DEGREE_SLOT.MAJOR1_1,
    w_DEGREE_SLOT.MAJOR1_DESC_1,
    w_DEGREE_SLOT.DEGREE_DATE_2,
    w_DEGREE_SLOT.DEGREE_2,
    w_DEGREE_SLOT.DEGREE_DESC_2,
    w_DEGREE_SLOT.ACADEMIC_YEAR_2,
    w_DEGREE_SLOT.MAJOR1_2,
    w_DEGREE_SLOT.MAJOR1_DESC_2,
    w_DEGREE_SLOT.DEGREE_DATE_3,
    w_DEGREE_SLOT.DEGREE_3,
    w_DEGREE_SLOT.DEGREE_DESC_3,
    w_DEGREE_SLOT.ACADEMIC_YEAR_3,
    w_DEGREE_SLOT.MAJOR1_3,
    w_DEGREE_SLOT.MAJOR1_DESC_3,
    w_spec_purpose.entity_uid "SPEC_PURPOSE_TYPE_GROUP",
    w_apbghis.apbghis_total_no_gifts total_no_gifts,
    w_apbghis.apbghis_high_gift_amt high_gift_amt,
    w_apbghis.apbghis_last_gift_date last_gift_date,
    w_CONSTITUENT.DECEASED_IND,
    w_spbpers.SPBPERS_BIRTH_DATE date_of_birth,
    w_JFSGD.rating JFSG_estimated_capacity,
    nvl(w_ytd.ytd_1,0) "DED_AMT_w_YTD_1",
    nvl(w_ytd.ytd_2,0) "DED_AMT_w_YTD_2",
    nvl(w_ytd.ytd_3,0) "DED_AMT_w_YTD_3",
    nvl(w_ytd.ytd_4,0) "DED_AMT_w_YTD_4",
    w_employment.employer_name employer,
    w_employment.position_title position,
    nvl2(SPBPERS_VERA_IND, 'Y','N') Veteran_ind,
    w_guriden.guriden_desc,
    w_long_years_given.recent_consecutive_years longest_cons_years_given,
    w_recent_cons_years.recent_consecutive_years recent_consecutive_years
    -- (select max(l) recent_consecutive_years from ( select distinct spriden_pidm, agbgift.AGBGIFT_FISC_CODE, level l from agbgift join spriden on spriden_pidm = agbgift_pidm and spriden_change_ind is null where AGBGIFT_FISC_CODE <= to_char(:parm_DT_GivingEnd, 'YYYY') connect by prior spriden_pidm = spriden_pidm and prior agbgift_fisc_code = agbgift_fisc_code -1 ) group by spriden_pidm having spriden_pidm = w_CONSTITUENT.PERSON_UID) longest_cons_years_given,
    -- (select max(l) keep (dense_rank first order by agbgift_fisc_code desc) recent_consecutive_years from ( select distinct spriden_pidm, agbgift.AGBGIFT_FISC_CODE, level l from agbgift join spriden on spriden_pidm = agbgift_pidm and spriden_change_ind is null where AGBGIFT_FISC_CODE <= to_char(:parm_DT_GivingEnd, 'YYYY') connect by prior spriden_pidm = spriden_pidm and prior agbgift_fisc_code = agbgift_fisc_code -1 ) group by spriden_pidm having spriden_pidm = w_CONSTITUENT.PERSON_UID) recent_consecutive_years

FROM
    w_CONSTITUENT,
    w_NSU_EXCLUSION_SLOT,
    w_ANNUAL_GIVING_SLOT,
    w_ADVANCEMENT_RATING_SLOT,
    w_NSU_EMAIL_SLOT,
    w_NSU_TELEPHONE_SLOT,
    w_RELATIONSHIP,
    w_DEGREE_SLOT,
    w_SPBPERS,
    w_APBGHIS,
    w_amrstaf,
    w_GURIDEN,
    w_recent_membership,
    w_won_membership,
    w_fan_membership,
    w_SALUTATION,
    w_ytd,
    w_JFSGD,
    w_employment,
    w_address,
    w_long_years_given,
    w_recent_cons_years,
    w_range_tot_gift,
    w_range_tot_aux,
    w_spec_purpose

WHERE
    w_CONSTITUENT.name not like '%DO%NOT%USE%' and
    w_CONSTITUENT.PERSON_UID not in (select distinct s2.entity_uid from donor_category s2 where s2.entity_uid = w_CONSTITUENT.PERSON_UID and s2.donor_category = 'BAD') and
    w_CONSTITUENT.PERSON_UID not in (SELECT bad_pidm FROM nsudev.nsu_alum_pidm where bad_pidm = w_CONSTITUENT.PERSON_UID) and
    (
        ( w_CONSTITUENT.PERSON_UID = w_NSU_EXCLUSION_SLOT.ENTITY_UID (+)
         and w_CONSTITUENT.PERSON_UID = w_ANNUAL_GIVING_SLOT.ENTITY_UID (+)
         and w_CONSTITUENT.PERSON_UID = w_ADVANCEMENT_RATING_SLOT.ENTITY_UID (+)
         and w_CONSTITUENT.PERSON_UID = w_NSU_EMAIL_SLOT.ENTITY_UID (+)
         and w_CONSTITUENT.PERSON_UID = w_NSU_TELEPHONE_SLOT.ENTITY_UID (+)
         and w_CONSTITUENT.PERSON_UID = w_RELATIONSHIP.ENTITY_UID (+)
         and w_CONSTITUENT.PERSON_UID = w_DEGREE_SLOT.PERSON_UID (+)
         and w_CONSTITUENT.person_uid = w_apbghis.apbghis_pidm (+)
         and w_CONSTITUENT.person_uid = w_spbpers.spbpers_pidm (+)
         and w_CONSTITUENT.person_uid = w_amrstaf.amrstaf_pidm (+)
         and w_amrstaf.amrstaf_iden_code = w_guriden.guriden_iden_code (+)
         and w_CONSTITUENT.PERSON_UID = w_recent_membership.entity_uid (+)
         and w_CONSTITUENT.PERSON_UID = w_won_membership.entity_uid (+)
         and w_CONSTITUENT.PERSON_UID = w_fan_membership.entity_uid (+)
         and w_CONSTITUENT.PERSON_UID = w_SALUTATION.ENTITY_UID (+)
         and w_CONSTITUENT.PERSON_UID = w_ytd.entity_uid (+)
         and w_CONSTITUENT.PERSON_UID = w_JFSGD.entity_uid (+)
         and w_CONSTITUENT.PERSON_UID = w_employment.person_uid (+)
         and w_CONSTITUENT.PERSON_UID = w_address.spraddr_pidm (+)
         and w_CONSTITUENT.PERSON_UID = w_long_years_given.spriden_pidm (+)
         and w_CONSTITUENT.PERSON_UID = w_recent_cons_years.spriden_pidm (+)
         and w_CONSTITUENT.PERSON_UID = w_range_tot_gift.entity_uid (+)
         and w_CONSTITUENT.PERSON_UID = w_range_tot_aux.entity_uid (+)
         and w_CONSTITUENT.PERSON_UID = w_spec_purpose.entity_uid (+)
      )
and   ( --w_CONSTITUENT.DECEASED_IND = 'N' and
            'SX' = w_RELATIONSHIP.RELATION_SOURCE (+)
      and   'Y' = w_DEGREE_SLOT.INSTITUTION_IND (+)
      )
    );
    
-------------------------------------------    
    
      and   (     :cb_leadership = 1
            or    (     exists   (  select 'X' "calc1"
                                    from apracld
                                    where    apracld_lead_code = :parm_MC_leadership -- !REF :parm_MC_leadership.STVLEAD_CODE
                                       and   apracld_pidm = w_CONSTITUENT.PERSON_UID
                                 )
                  and   :cb_leadership = 0
                  )
            )
            
      and   (  :parm_CB_AllZipCodes = 1
            or (     :parm_CB_ignore_zip_use_state = 1
               and   substr(w_address.spraddr_stat_code,1,2) = :parm_MC_State_Code -- !REF :parm_MC_StateCode.State
               )
            or substr(w_address.spraddr_zip,1,5) = :parm_MC_ZipCode -- !REF :parm_MC_ZipCode.ZipCode
            )
      and   (  :parm_CB_enter_name = 1
            or    upper(w_address.spraddr_city) = upper(:parm_EB_City)
            )
      and   (  :parm_CB_AllActivies = 1
            or exists ( select 'X' "calc1"
                      from apracyr
                     where apracyr_actc_code = :parm_MC_ActivityCode -- !REF :parm_MC_ActivityCode.ActivityCode
                           and (( :cb_Activity_Years = 0 and apracyr_year = :param_lb_activity_years) -- !REF :param_lb_activity_years.APRACYR_YEAR)
                           or :cb_Activity_Years = 1)
                           and apracyr_pidm =w_CONSTITUENT.PERSON_UID )
            or exists ( select 'X' "calc1"
                      from apracty
                     where apracty_actc_code = :parm_MC_ActivityCode -- !REF :parm_MC_ActivityCode.ActivityCode
                           and apracty_pidm =w_CONSTITUENT.PERSON_UID ) )
         and ( :parm_CB_AllGCranges = 1
           or w_ADVANCEMENT_RATING_SLOT.RATING_AMOUNT1 = :parm_LB_GiftCapRange ) -- !REF :parm_LB_GiftCapRange.Code )
         and ( :parm_CB_AllWEdesignations = 1
           or w_ADVANCEMENT_RATING_SLOT.RATING_LEVEL2 = :parm_LB_WealthEngineDesg ) -- !REF :parm_LB_WealthEngineDesg.Main )
         and ( :parm_CB_AllExclusions = 1
           or w_NSU_EXCLUSION_SLOT.NPH = :parm_MC_ExclusionCode -- !REF :parm_MC_ExclusionCode.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NOC = :parm_MC_ExclusionCode -- !REF :parm_MC_ExclusionCode.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NMC = :parm_MC_ExclusionCode -- !REF :parm_MC_ExclusionCode.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NEM = :parm_MC_ExclusionCode -- !REF :parm_MC_ExclusionCode.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NAM = :parm_MC_ExclusionCode -- !REF :parm_MC_ExclusionCode.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NDN = :parm_MC_ExclusionCode -- !REF :parm_MC_ExclusionCode.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NAK = :parm_MC_ExclusionCode -- !REF :parm_MC_ExclusionCode.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NTP = :parm_MC_ExclusionCode -- !REF :parm_MC_ExclusionCode.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.AMS = :parm_MC_ExclusionCode ) -- !REF :parm_MC_ExclusionCode.ExclusionCode )
         and ( :parm_CB_HouseholdInd = 1
           or w_RELATIONSHIP.HOUSEHOLD_IND = :parm_LB_HouseholdInd ) -- !REF:parm_LB_HouseholdInd.Main )
         and ( :parm_CB_AllCountyCodes = 1
           or w_address.spraddr_cnty_code = :parm_MC_CountyCode ) -- !REF :parm_MC_CountyCode.CountyCode )
         and ( :parm_CB_AllDegrees = 1
           or w_DEGREE_SLOT.DEGREE_1 = :parm_MC_Degrees -- !REF :parm_MC_Degrees.DegreeCode
           or w_DEGREE_SLOT.DEGREE_2 = :parm_MC_Degrees -- !REF :parm_MC_Degrees.DegreeCode
           or w_DEGREE_SLOT.DEGREE_3 = :parm_MC_Degrees ) -- !REF :parm_MC_Degrees.DegreeCode )
         and ( :parm_CB_GradYears = 1
           or w_DEGREE_SLOT.ACADEMIC_YEAR_1 = :parm_LB_GradYear -- !REF :parm_LB_GradYear.AbbrevInd
           or w_DEGREE_SLOT.ACADEMIC_YEAR_2 = :parm_LB_GradYear -- !REF :parm_LB_GradYear.AbbrevInd
           or w_DEGREE_SLOT.ACADEMIC_YEAR_3 = :parm_LB_GradYear ) -- !REF :parm_LB_GradYear.AbbrevInd )
         and ( :parm_CB_AllMajors = 1
           or w_DEGREE_SLOT.MAJOR1_1 = :parm_MC_Major -- !REF :parm_MC_Major.MajorCode
           or w_DEGREE_SLOT.MAJOR1_2 = :parm_MC_Major -- !REF :parm_MC_Major.MajorCode
           or w_DEGREE_SLOT.MAJOR1_3 = :parm_MC_Major ) -- !REF :parm_MC_Major.MajorCode )
         and ( :parm_CB_Ignore_Degree_Dates = 1
           or w_DEGREE_SLOT.DEGREE_DATE_1 between :parm_DT_DegreeDateStart and :parm_DT_DegreeDateEnd
           or w_DEGREE_SLOT.DEGREE_DATE_2 between :parm_DT_DegreeDateStart and :parm_DT_DegreeDateEnd
           or w_DEGREE_SLOT.DEGREE_DATE_3 between :parm_DT_DegreeDateStart and :parm_DT_DegreeDateEnd )
         and ( ( :parm_CB_AllDonorCats = 1 )
           or exists ( select 'x' "calc1"
                      from ODSMGR.DONOR_CATEGORY DONOR_CATEGORY
                     where DONOR_CATEGORY.ENTITY_UID = w_CONSTITUENT.PERSON_UID
                           and DONOR_CATEGORY.DONOR_CATEGORY in ('ALGR','ALND','ALUM','STDN') ) )   -- !REF test group                 
--                           and DONOR_CATEGORY.DONOR_CATEGORY = :parm_MC_DonorCats ) ) -- !REF :parm_MC_DonorCats.DonorCatCode ) )
         and ( ( :parm_CB_SP_Types = 1 )
           or exists ( select 'x' "calc1"
                      from ODSMGR.SPECIAL_PURPOSE_GROUP SPECIAL_PURPOSE_GROUP
                     where SPECIAL_PURPOSE_GROUP.ENTITY_UID = w_CONSTITUENT.PERSON_UID
                           and SPECIAL_PURPOSE_GROUP.SPECIAL_PURPOSE_TYPE = :parm_MC_SP_Types ) ) -- !REF :parm_MC_SP_Types.SpecialPurCode ) )
         and ( ( :parm_CB_SP_Groups = 1 )
           or exists ( select 'x' "calc1"
                      from ODSMGR.SPECIAL_PURPOSE_GROUP SPECIAL_PURPOSE_GROUP
                     where SPECIAL_PURPOSE_GROUP.ENTITY_UID = w_CONSTITUENT.PERSON_UID
                           and SPECIAL_PURPOSE_GROUP.SPECIAL_PURPOSE_GROUP = :parm_MC_SP_Groups ) ) -- !REF :parm_MC_SP_Groups.SpecialPurCode ) )
         and ( ( :parm_CB_PrimSpouse_Unmarried = 1 )
           or ( w_RELATIONSHIP.RELATION_SOURCE = 'SX'
             and w_RELATIONSHIP.COMBINED_MAILING_PRIORITY = 'P' )
           or not exists ( select 'x' "calc1"
                          from ODSMGR.RELATIONSHIP RELATIONSHIP1
                         where RELATIONSHIP1.ENTITY_UID = w_CONSTITUENT.PERSON_UID
                               and RELATIONSHIP1.RELATION_SOURCE = 'SX'
                               and RELATIONSHIP1.RELATED_CROSS_REFERENCE = 'SP1' ) )
         and ( ( :parm_CB_AllMailCodes = 1 )
           or exists ( select 'x' "calc1"
                      from ODSMGR.MAIL MAIL
                     where MAIL.ENTITY_UID = w_CONSTITUENT.PERSON_UID
                           and MAIL.MAIL = :parm_MC_mail_codes ) ) -- !REF :parm_MC_mail_codes.MailCode ) )
         and ((:parm_CB_deceased = 1) or nvl(w_spbpers.SPBPERS_DEAD_IND,'N') = 'N')
         )
         and (nvl2(SPBPERS_VERA_IND, 'Y','N') = :lb_veteran or :lb_veteran = 'All')
         and ((:parm_CB_Ignore_Gift_Dates = 1) or exists     (  select 'x'
                                                               from gift g2
                                                               where g2.entity_uid = w_CONSTITUENT.PERSON_UID
                                                               and g2.GIFT_DATE between :parm_DT_GivingStart and :parm_DT_GivingEnd))


        -- and rownum <= :parm_ED_rownum
   )
--         and :parm_BT_ViewQV is not null
;