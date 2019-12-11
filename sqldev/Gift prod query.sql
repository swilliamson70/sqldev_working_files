select * from gift;

select * from agbgift;

WITH w_gift AS(
    SELECT
        agbgift_pidm        ENTITY_UID
        , agbgift_gift_no   ID
        , TRIM(spriden_last_name)
        || ', '
        || TRIM(spriden_first_name)
        || ' '
        || TRIM(spriden_mi)
            AS NAME
        ,spbpers_dead_ind   DECEASED_STATUS
    FROM
        agbgift
        JOIN(
                SELECT
                    spriden_pidm
                    ,spriden_last_name
                    ,spriden_first_name
                    ,spriden_mi
                    ,spriden_entity_ind
                FROM
                    spriden
                WHERE
                    spriden_change_ind is null
            ) ON agbgift_pidm = spriden_pidm
        JOIN(
                SELECT 
                    spbpers_pidm
                    ,NVL(spbpers_dead_ind,'N') spbpers_dead_ind
                FROM
                    spbpers
        ) ON agbgift_pidm = spbpers_pidm
--GIFT.ENTITY_UID,
--       GIFT.ID,
--       GIFT.NAME,
--       nvl(GIFT.DECEASED_STATUS,'N') "DECEASED_STATUS",
--       GIFT.PREFER_CLASS_YEAR,
--       GIFT.GIFT_DATE "GIFT_DATE",
--       GIFT.GIFT_NUMBER,
--       GIFT.SOLICITATION_TYPE,
--       GIFT.GIFT_VEHICLE,
--       GIFT.GIFT_VEHICLE_DESC,
--       GIFT.GIFT_TYPE,
--       GIFT.GIFT_CLASS,
--       GIFT.GIFT_CLASS2,
--       GIFT.GIFT_CLASS3,
--       nvl2(GIFT.GIFT_COMMENT,GIFT.GIFT_COMMENT,'"'||GIFT.GIFT_COMMENT||'"') gift_comment,
--       GIFT.CAMPAIGN_NAME "CAMPAIGN_NAME",
--       GIFT.DESIGNATION designation,
--       GIFT.DESIGNATION_NAME "DESIGNATION_NAME",
--       GIFT.GIFT_AMOUNT "GIFT_AMOUNT",
)
select *

/*
GIFT.ENTITY_UID,
       GIFT.ID,
       GIFT.NAME,
       nvl(GIFT.DECEASED_STATUS,'N') "DECEASED_STATUS",
       nsudev.f_addr_slot_alum(GIFT.ENTITY_UID,'street1') "Street_line1",
       nsudev.f_addr_slot_alum(GIFT.ENTITY_UID,'street2') "Street_line2",
       nsudev.f_addr_slot_alum(GIFT.ENTITY_UID,'city') "City",
       nsudev.f_addr_slot_alum(GIFT.ENTITY_UID,'state') "State",
       nsudev.f_addr_slot_alum(GIFT.ENTITY_UID,'zip') "Zip_Code",
       nsudev.f_addr_slot_alum(GIFT.ENTITY_UID,'type') "ADDRESS_TYPE",
       GIFT.PREFER_CLASS_YEAR,
       GIFT.GIFT_DATE "GIFT_DATE",
       GIFT.GIFT_NUMBER,
       GIFT.SOLICITATION_TYPE,
       GIFT.GIFT_VEHICLE,
       GIFT.GIFT_VEHICLE_DESC,
       GIFT.GIFT_TYPE,
       GIFT.GIFT_CLASS,
       GIFT.GIFT_CLASS2,
       GIFT.GIFT_CLASS3,
       nvl2(GIFT.GIFT_COMMENT,GIFT.GIFT_COMMENT,'"'||GIFT.GIFT_COMMENT||'"') gift_comment,
       GIFT.CAMPAIGN_NAME "CAMPAIGN_NAME",
       GIFT.DESIGNATION designation,
       GIFT.DESIGNATION_NAME "DESIGNATION_NAME",
       GIFT.GIFT_AMOUNT "GIFT_AMOUNT",
        trim(to_char(GIFT_AUXILIARY.AUXILIARY_VALUE, '999999990.99')) "AUXILIARY_VALUE",
       GIFT_AUXILIARY.DEDUCT_FOR_TAXES_IND,
       case
           when GIFT.ENTITY_IND  = 'P' then
                nvl((select SALUTATION.SALUTATION
                     from SALUTATION SALUTATION
                     where SALUTATION.ENTITY_UID = GIFT.ENTITY_UID
                     and SALUTATION.SALUTATION_TYPE ='CIFE'), (select SALUTATION.SALUTATION
                                                               from SALUTATION SALUTATION
                                                               where SALUTATION.ENTITY_UID = GIFT.ENTITY_UID
                                                               and SALUTATION.SALUTATION_TYPE ='SIFE'))
           else (select aoborgn_business
                 from aoborgn
                 where aoborgn_pidm = GIFT.ENTITY_UID)
       end "PREFERRED_FULL_SALUTATION",
       case
           when GIFT.ENTITY_IND  = 'P' then
                nvl((select SALUTATION.SALUTATION
                     from SALUTATION SALUTATION
                     where SALUTATION.ENTITY_UID = GIFT.ENTITY_UID
                     and SALUTATION.SALUTATION_TYPE ='CIFL'), (select SALUTATION.SALUTATION
                                                               from SALUTATION SALUTATION
                                                               where SALUTATION.ENTITY_UID = GIFT.ENTITY_UID
                                                               and SALUTATION.SALUTATION_TYPE ='SIFL'))
           else nvl((select aorcont_first_name || ' ' || aorcont_last_name
                     from aorcont
                     where aorcont_pidm = GIFT.ENTITY_UID
                       and aorcont_primary_ind = 1),(select aorcont_first_name || ' ' || aorcont_last_name
                                                     from aorcont
                                                     where aorcont_pidm = GIFT.ENTITY_UID
                                                       and aorcont_seq_no = 1))
       end "PREFERRED_SHORT_SALUTATION",
       (select SALUTATION.SALUTATION
        from SALUTATION SALUTATION
        where SALUTATION.ENTITY_UID = GIFT.ENTITY_UID
          and SALUTATION.SALUTATION_TYPE ='SIFE') "SIFE",
       (select SALUTATION.SALUTATION
        from SALUTATION SALUTATION
        where SALUTATION.ENTITY_UID = GIFT.ENTITY_UID
          and SALUTATION.SALUTATION_TYPE ='SIFL') "SIFL",
       NSU_TELEPHONE_SLOT.PR_PHONE_NUMBER,
       NSU_TELEPHONE_SLOT.PR_ADDRESS_TYPE,
       NSU_TELEPHONE_SLOT.PR_PRIMARY_IND,
       NSU_TELEPHONE_SLOT.CL_PHONE_NUMBER,
       NSU_TELEPHONE_SLOT.CL_ADDRESS_TYPE,
       NSU_TELEPHONE_SLOT.CL_PRIMARY_IND,
       NSU_TELEPHONE_SLOT.B1_PHONE_NUMBER,
       NSU_TELEPHONE_SLOT.B1_ADDRESS_TYPE,
       NSU_TELEPHONE_SLOT.B1_PRIMARY_IND,
       NSU_EMAIL_SLOT.PERS_EMAIL,
       NSU_EMAIL_SLOT.NSU_EMAIL,
       NSU_EMAIL_SLOT.AL_EMAIL,
       NSU_EMAIL_SLOT.BUS_EMAIL,
       NSU_EMAIL_SLOT.VEND_EMAIL,
       NSU_EMAIL_SLOT.OT_EMAIL,
       NSUDEV.NSU_GET_GIFT_MEMO_ID_NM_AMT(GIFT.GIFT_NUMBER) "GIFT_MEMO_DETAILS",
       NSUDEV.NSU_GET_GIFT_ASSOC_ENTITY_DTLS(GIFT.GIFT_NUMBER) "GIFT_ASSOC_ENTITY_DTLS",
       NSUDEV.NSU_GET_SPECIAL_PURPOSE_GROUP(GIFT.ENTITY_UID) "SPECIAL_PURPOSE_INFO",
       GIFT.PLEDGE_NUMBER,
       coalesce(CONSTITUENT.PREF_DONOR_CATEGORY, catg.donr_code) donor_category,
       coalesce(CONSTITUENT.PREF_DONOR_CATEGORY_DESC, catg.donr_desc) donor_category_desc,
       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'LIFETIME') "LIFETIME_HH_GIVING",
       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'ANNUAL') "ANNUAL_HH_GIVING",
       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'ANNUAL-1') "PREV_YR_ANNUAL_HH_GIVING",
       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'ANNUAL-1_AUX') "PREV_YR_ANNUAL_HH_AUX_GIVING",
       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'ANNUAL-1_SOFT') "PREV_YR_ANNUAL_HH_SOFT_GIVING",

       GIK.summ "HH_GIK",

       RELATIONSHIP.RELATION_SOURCE,
       RELATIONSHIP.RELATION_SOURCE_DESC,
       RELATIONSHIP.COMBINED_MAILING_PRIORITY,
       RELATIONSHIP.COMBINED_MAILING_PRIORITY_DESC,
       NSU_EXCLUSION_SLOT.NPH,
       NSU_EXCLUSION_SLOT.NOC,
       NSU_EXCLUSION_SLOT.NMC,
       NSU_EXCLUSION_SLOT.NEM,
       NSU_EXCLUSION_SLOT.NAM,
       NSU_EXCLUSION_SLOT.NDN,
       NSU_EXCLUSION_SLOT.NAK,
       NSU_EXCLUSION_SLOT.NTP,
       NSU_EXCLUSION_SLOT.AMS,
       prospect.prospect_status,
       prospect.prospect_status_desc,
       prospect.prospect_amount,
       (select rating from advancement_rating where rating_type = 'JFSGD' and advancement_rating.entity_uid = constituent.person_uid) JFSG_estimated_capacity,
       (nvl((select sum(gift.gift_amount)
             from gift
             where gift.entity_uid = CONSTITUENT.PERSON_UID
             and ( :parm_CB_Designations = 1
           or GIFT.DESIGNATION = :parm_MC_designation.VALUE )
               and to_char(gift.gift_date, 'YYYY') = to_char(sysdate, 'YYYY')-2),0)
             -
        nvl((select sum(gift_auxiliary.auxiliary_value)
             from gift_auxiliary
             where gift_auxiliary.entity_uid = CONSTITUENT.PERSON_UID
             and ( :parm_CB_Designations = 1
           or GIFT.DESIGNATION = :parm_MC_designation.VALUE )
               and to_char(gift_auxiliary.value_date, 'YYYY') = to_char(sysdate, 'YYYY')-2),0)) "DED_AMT_YTD_1",

       (nvl((select sum(gift.gift_amount)
             from gift
             where gift.entity_uid = CONSTITUENT.PERSON_UID
             and ( :parm_CB_Designations = 1
           or GIFT.DESIGNATION = :parm_MC_designation.VALUE )
               and to_char(gift.gift_date, 'YYYY') = to_char(sysdate, 'YYYY')-3),0)
             -
        nvl((select sum(gift_auxiliary.auxiliary_value)
             from gift_auxiliary
             where gift_auxiliary.entity_uid = CONSTITUENT.PERSON_UID
             and ( :parm_CB_Designations = 1
           or GIFT.DESIGNATION = :parm_MC_designation.VALUE )
               and to_char(gift_auxiliary.value_date, 'YYYY') = to_char(sysdate, 'YYYY')-3),0)) "DED_AMT_YTD_2",

         (nvl((select sum(gift.gift_amount)
             from gift
             where gift.entity_uid = CONSTITUENT.PERSON_UID
             and ( :parm_CB_Designations = 1
           or GIFT.DESIGNATION = :parm_MC_designation.VALUE )
               and to_char(gift.gift_date, 'YYYY') = to_char(sysdate, 'YYYY')-4),0)
             -
        nvl((select sum(gift_auxiliary.auxiliary_value)
             from gift_auxiliary
             where gift_auxiliary.entity_uid = CONSTITUENT.PERSON_UID
             and ( :parm_CB_Designations = 1
           or GIFT.DESIGNATION = :parm_MC_designation.VALUE )
               and to_char(gift_auxiliary.value_date, 'YYYY') = to_char(sysdate, 'YYYY')-4),0)) "DED_AMT_YTD_3",

       (nvl((select sum(gift.gift_amount)
             from gift
             where gift.entity_uid = CONSTITUENT.PERSON_UID
               and ( :parm_CB_Designations = 1
               or GIFT.DESIGNATION = :parm_MC_designation.VALUE )
               and to_char(gift.gift_date, 'YYYY') = to_char(sysdate, 'YYYY')-5),0)
             -
        nvl((select sum(gift_auxiliary.auxiliary_value)
             from gift_auxiliary
             where gift_auxiliary.entity_uid = CONSTITUENT.PERSON_UID
             and ( :parm_CB_Designations = 1
                  or GIFT.DESIGNATION = :parm_MC_designation.VALUE )
               and to_char(gift_auxiliary.value_date, 'YYYY') = to_char(sysdate, 'YYYY')-5),0)) "DED_AMT_YTD_4",
(select count(distinct gif1.fiscal_year) from gift gif1 where gif1.entity_uid = gift.entity_uid) total_number_of_years_given,
(select max(l) consecutive_giving_years from ( select distinct spriden_id, agbgift.AGBGIFT_FISC_CODE, level l from agbgift join spriden on spriden_pidm = agbgift_pidm and spriden_change_ind is null where AGBGIFT_FISC_CODE < to_char(:parm_DT_Gift_End, 'YYYY') connect by prior spriden_id = spriden_id and prior agbgift_fisc_code = agbgift_fisc_code -1 ) group by spriden_id having spriden_id = gift.id) longest_cons_years_given,
(select max(l) keep (dense_rank first order by agbgift_fisc_code desc) recent_consecutive_years from ( select distinct spriden_id, agbgift.AGBGIFT_FISC_CODE, level l from agbgift join spriden on spriden_pidm = agbgift_pidm and spriden_change_ind is null where AGBGIFT_FISC_CODE <= to_char(:parm_DT_Gift_End, 'YYYY') connect by prior spriden_id = spriden_id and prior agbgift_fisc_code = agbgift_fisc_code -1 ) group by spriden_id having spriden_id = gift.id) recent_consecutive_years
*/


from w_gift;
