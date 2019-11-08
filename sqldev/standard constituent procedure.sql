create or replace PROCEDURE        nsu_alumni_standard_const

/*************************************************
PROCEDURE name
    Compiles a standard list of Advancement constituents filtering for several data elements.
    To be called from an Argos datablock. Rewrite of existing Standard Constituent datablock run against ODS
    
Northeastern State Univerisity
    Nov 2019    Scott Williamson   Start
    
*************************************************/

( --Activities
  p_activity_codes      IN  VARCHAR2 -- parm_MC_ActivityCode
, p_all_activities      IN  VARCHAR2 -- parm_CB_AllActivities
, p_activity_years      IN  VARCHAR2 -- parm_lb_activity_years
, p_all_years           IN  VARCHAR2 -- cb_activity_years
, p_leadership_codes    IN  VARCHAR2 -- parm_MC_leadership
, p_all_leadership      IN  VARCHAR2 -- cb_leadership

--Degree Info
, p_degree_date_start   IN  DATE -- parm_DT_DegreeDateStart
, p_degree_date_end     IN  DATE -- parm_DT_DegreeDateEnd
, p_ignore_degree_dates IN  VARCHAR2 -- parm_CB_Ignore_Degree_Dates
, p_grad_years          IN  VARCHAR2 -- parm_LB_GradYear
, p_all_grad_years      IN  VARCHAR2 -- parm_CB_GradYears
, p_degrees             IN  VARCHAR2 -- parm_MC_Degrees
, p_all_degrees         IN  VARCHAR2 -- parm_CB_AllDegrees
, p_majors              IN  VARCHAR2 -- parm_MC_Major
, p_all_majors          IN  VARCHAR2 -- parm_CB_AllMajors

--Demographics
, p_deceased            IN  VARCHAR2 -- parm_CB_deceased
, p_veteran             IN  VARCHAR2 -- lb_veteran
, p_prim_spouse_unmarried   IN  VARCHAR2 -- parm_CB_PrimSpouse_Unmarried
, p_household_ind       IN  VARCHAR2 -- parm_LB_HouseholdInd
, p_ignore_household_ind    IN  VARCHAR2 -- parm_CB_HouseholdInd
, p_zipcodes            IN  VARCHAR2 -- parm_MC_ZipCode
, p_all_zipcodes        IN  VARCHAR2 -- parm_CB_AllZipCodes
, p_ignore_zip          IN  VARCHAR2 -- parm_CB_ignore_zip_use_state
, p_state_codes         IN  VARCHAR2 -- parm_MC_StateCode
, p_city                IN  VARCHAR2 -- parm_EB_City
, p_use_city            IN  VARCHAR2 -- parm_CB_enter_name
, p_county_codes        IN  VARCHAR2 -- parm_MC_CountryCode
, p_all_counties        IN  VARCHAR2 -- parm_CB_AllCountyCodes

--Donor Information
, p_donor_cats          IN  VARCHAR2 -- parm_MC_DonorCats
, p_all_donor_cats      IN  VARCHAR2 -- parm_CB_AllDonorCats
, p_gift_capacity       IN  VARCHAR2 -- parm_LB_GiftCapRange
, p_all_gift_capacities IN  VARCHAR2 -- parm_CB_AllGCrranges
, p_wealth_engine_desg  IN  VARCHAR2 -- parm_LB_WealthEngineDesg
, p_all_wealth_engine_desg  IN  VARCHAR2 -- parm_CB_AllWEdesignations
, p_spec_purpose_types  IN  VARCHAR2 -- parm_MC_SP_Types
, p_all_spec_purpose_types  IN  VARCHAR2 -- parm_CB_SP_Types
, p_spec_purpose_groups IN  VARCHAR2 -- parm_MC_SP_Groups
, p_all_spec_purpose_groups IN  VARCHAR2 -- parm_CB_SP_Groups
, p_exclusion_codes     IN  VARCHAR2 -- parm_MC_ExclusionCode
, p_all_exclusion_codes IN  VARCHAR2 -- parm_CB_AllExclusions
, p_mail_codes          IN  VARCHAR2 -- parm_MC_mail_codes
, p_all_mail_codes      IN  VARCHAR2 -- parm_CB_AllMailCodes

-- Gift Dates
, p_giving_start_date   IN  DATE -- parm_DT_GivingStart
, p_giving_end_date     IN  DATE -- parm_DT_GivingEnd
, p_ignore_gift_dates   IN  VARCHAR2 -- parm_DB_Ignore_Gift_Dates
) AS
  
    p_record_count            NUMBER := 0;
    
    CURSOR boris IS

        WITH /* w_lifetime_giving AS(
            SELECT DISTINCT
                person_uid
                , lifetime_giving
            FROM(   
                    SELECT 
                        CHECK_SUM.APRCHIS_PIDM PERSON_UID
                        , SUM(NVL(CHECK_SUM.APRCHIS_AMT_PLEDGED_PAID,0)) over (partition by check_sum.aprchis_pidm) 
                          + SUM(NVL(CHECK_SUM.APRCHIS_AMT_GIFT,0)) over (partition by check_sum.aprchis_pidm) 
                          - SUM(NVL(CHECK_TPP_TOTAL.AGRGMMO_3PP_TOT_AMT,0)) over (partition by check_sum.aprchis_pidm) LIFETIME_GIVING
                    FROM
                        APRCHIS CHECK_SUM
                        LEFT JOIN(
                            SELECT *
                            FROM
                                AGRGMMO
                                JOIN AGBGIFT
                                    ON AGRGMMO_PIDM = AGBGIFT_PIDM
                                    AND AGRGMMO_GIFT_NO = AGBGIFT_GIFT_NO
                                    AND AGRGMMO_PLEDGE_NO = '0000000'
                                    AND AGRGMMO_3PP_PLEDGE_NO IS NOT NULL
                                JOIN APRCHIS
                                    ON AGRGMMO_XREF_PIDM = APRCHIS_PIDM
                                    AND AGRGMMO_CAMPAIGN = APRCHIS_CAMPAIGN
                                    AND AGBGIFT_FISC_CODE = APRCHIS_FISC_CODE
                        ) CHECK_TPP_TOTAL
                            ON CHECK_SUM.APRCHIS_PIDM = CHECK_TPP_TOTAL.AGRGMMO_PIDM
                                AND CHECK_SUM.APRCHIS_CAMPAIGN = CHECK_TPP_TOTAL.APRCHIS_CAMPAIGN
                                AND CHECK_SUM.APRCHIS_FISC_CODE = CHECK_TPP_TOTAL.APRCHIS_FISC_CODE
            )

        )
--select * from w_lifetime_giving;        
        , */ w_spouse AS(
                    SELECT /*+ MATERIALIZE */
                        *
                    FROM(
                        SELECT
                            aprcsps_pidm    PERSON_UID
                            , aprcsps_sps_pidm SPOUSE_UID
                            , CASE WHEN aprcsps_sps_pidm IS NULL THEN
                                aprcsps_last_name
                                ||  ', '
                                || aprcsps_first_name
                              ELSE
                                spriden_last_name
                                ||  ', '
                                || spriden_first_name
                              END APRCSPS_SPOUSE_NAME
                            , row_number() over (partition by aprcsps_pidm order by aprcsps_pidm) rn
                                
                        FROM 
                            aprcsps
                            LEFT JOIN spriden
                                ON aprcsps_sps_pidm = spriden_pidm
                                AND spriden_change_ind IS NULL
                        WHERE 
                            aprcsps_mars_ind = 'A'
                    )
                WHERE rn = 1 -- There are duplicate records for spouses in aprcsps          
                )
--select * from w_spouse where rn > 1;

        ,  w_constituent AS(
            SELECT /*+ MATERIALIZE */ 
                apbcons_pidm        PERSON_UID
                , spriden_id        ID
                , f_format_name(apbcons_pidm,'LFMI')    NAME
                , apbcons_pref_last_name    PREF_LAST_NAME
                , apbcons_maiden_last_name  MAIDEN_LAST_NAME
                , aprcsps_spouse_name SPOUSE_NAME
                , aprcatg_donr_code PREF_DONOR_CATEGORY
                , atvdonr_desc      PREF_DONOR_CATEGORY_DESC
                , goremal_email_address EMAIL_PREFERRED_ADDRESS
              --  , w_lifetime_giving.lifetime_giving LIFE_TOTAL_GIVING
                , nvl(spbpers_dead_ind,'N') DECEASED_IND
            FROM
                apbcons 
                JOIN spriden
                    ON apbcons_pidm = spriden_pidm
                    AND spriden_change_ind IS NULL
                    and  f_format_name(apbcons_pidm,'LFMI') NOT LIKE '%DO%NOT%USE%'
                    AND apbcons_pidm NOT IN (SELECT bad_pidm FROM nsudev.nsu_alum_pidm WHERE bad_pidm = apbcons_pidm)
                    AND apbcons_pidm NOT IN (SELECT aprcatg_pidm FROM aprcatg WHERE aprcatg_pidm = apbcons_pidm AND aprcatg_donr_code = 'BAD') 
                JOIN(   SELECT spbpers_pidm, spbpers_dead_ind
                        FROM spbpers
                    )
                    ON spbpers_pidm = apbcons_pidm 
                LEFT JOIN(
                        SELECT aprcatg_pidm, aprcatg_donr_code, atvdonr_desc, row_number() OVER (PARTITION BY aprcatg_pidm ORDER BY atvdonr_rpt_seq_ind) rn
                        FROM aprcatg JOIN atvdonr ON aprcatg_donr_code = atvdonr_code
                )   ON aprcatg_pidm = apbcons_pidm
                    AND rn = 1
                LEFT JOIN (
                        SELECT  
                            goremal_pidm
                            , goremal_email_address
                            ,row_number() over (partition by goremal_pidm order by goremal_pidm) rn
                        FROM goremal
                        WHERE --goremal_pidm = 166910
                            goremal_status_ind = 'A'
                            AND goremal_preferred_ind = 'Y'
                        ) goremal
                    ON goremal_pidm = apbcons_pidm
                    AND goremal.rn = 1

                LEFT JOIN w_spouse
                    ON apbcons_pidm = w_spouse.person_uid
--                left join w_lifetime_giving
--                    on apbcons_pidm = w_lifetime_giving.person_uid
                                                
        ) --end w_constituent
-- select * from w_constituent;
        , w_annual_gifts AS(
        -- Returns total of gift by pidm, calendar year, and previous years from sysdate (now = 1, last year =2, etc)
                SELECT
                    entity_uid  ENTITY_UID
                    , gift_date GIFT_YEAR
                    , YEAR_POS  YEAR_POS -- sysyear = 1 
                    , sum(tots) GIFT_AMOUNT
                    
                FROM(
                    SELECT
                        agbgift_pidm ENTITY_UID
                        , to_char(agbgift_gift_date,'YYYY') GIFT_DATE
                        , sum(nvl(agrgdes_amt,0)) TOTS
                    FROM
                        agbgift
                        LEFT JOIN agrgdes
                            ON agbgift_pidm = agrgdes_pidm
                            AND agbgift_gift_no = agrgdes_gift_no
                    --where agbgift_pidm = 6782
                    GROUP BY
                        agbgift_pidm
                        , to_char(agbgift_gift_date,'YYYY')
        
                    UNION
                    SELECT
                        agrgaux_pidm ENTITY_UID
                        , TO_CHAR(agrgaux_auxl_value_date,'YYYY') GIFT_DATE
                        , SUM(NVL(agrgaux_dcpr_value,0))*-1 TOTS
                    FROM
                        agrgaux
                    --where agrgaux_pidm = 6782 -- 6782	ytd 190	1 2520	2 2520	3 2520	4 420	life 9180
                    GROUP BY
                        agrgaux_pidm
                        , TO_CHAR(agrgaux_auxl_value_date,'YYYY')
                )
                LEFT JOIN(
                            SELECT
                               TO_CHAR(SYSDATE,'YYYY')-LEVEL+1 YEAR
                               , LEVEL YEAR_POS
                            FROM 
                                DUAL
                            CONNECT BY LEVEL <= 150
                )
                    ON year = gift_date
          --  GROUP BY entity_uid  
            GROUP BY entity_uid
                    , gift_date
                    , YEAR_POS                
        ) 
---select * from w_annual_gifts order by 1;
        , w_household_giving AS(
            SELECT DISTINCT
                donor_gifts.person_uid  PERSON_UID
                , donor_gifts.annual_gift_amount ANNUAL_DONOR_GIVING
                , spouse_gifts.annual_gift_amount ANNUAL_SPOUSE_GIVING
                , nvl(donor_gifts.annual_gift_amount,0)
                    + nvl(spouse_gifts.annual_gift_amount,0) ANNUAL_HOUSEHOLD_GIVING
                , donor_gifts.lifetime_gift_amount LIFETIME_DONOR_GIVING
                , spouse_gifts.lifetime_gift_amount LIFETIME_SPOUSE_GIVING
                , nvl(donor_gifts.lifetime_gift_amount,0)
                    + nvl(spouse_gifts.lifetime_gift_amount,0) LIFETIME_HOUSEHOLD_GIVING
                
            FROM(   SELECT
                        w_constituent.person_uid PERSON_UID
                        , SUM(  CASE WHEN w_annual_gifts.year_pos = 1 THEN nvl(w_annual_gifts.gift_amount,0) ELSE 0 END) 
                            OVER (PARTITION BY w_annual_gifts.entity_uid) ANNUAL_GIFT_AMOUNT
                        , SUM(nvl(w_annual_gifts.gift_amount,0)) OVER (PARTITION BY w_annual_gifts.entity_uid) LIFETIME_GIFT_AMOUNT
                    FROM
                        w_constituent -- plus w_annual_gifts
                        JOIN w_annual_gifts
                            ON w_constituent.person_uid = w_annual_gifts.entity_uid
                            --AND w_annual_gifts.gift_year = EXTRACT(YEAR FROM SYSDATE)
            ) DONOR_GIFTS
                LEFT JOIN(  SELECT
                                w_constituent.person_uid PERSON_UID
                                , SUM(  CASE WHEN w_annual_gifts.year_pos = 1 THEN NVL(w_annual_gifts.gift_amount,0) ELSE 0 END)
                                    OVER (PARTITION BY w_annual_gifts.entity_uid) ANNUAL_GIFT_AMOUNT
                                , SUM(NVL(w_annual_gifts.gift_amount,0)) OVER (PARTITION BY w_annual_gifts.entity_uid) LIFETIME_GIFT_AMOUNT
                            FROM
                                w_constituent
                                JOIN w_spouse
                                    ON w_constituent.person_uid = w_spouse.person_uid
                                JOIN w_annual_gifts
                                    ON w_spouse.spouse_uid = w_annual_gifts.entity_uid
                                    --AND w_annual_gifts.gift_year = EXTRACT(YEAR FROM SYSDATE)
                    ) SPOUSE_GIFTS ON donor_gifts.person_uid = spouse_gifts.person_uid
                  
            )
----select * from w_household_giving order by 1;

        , w_nsu_exclusion_slot AS(
            SELECT entity_uid
                , NPH
                , NOC
                , NMC
                , NEM
                , NAM
                , NDN
                , NAK
                , NTP
                , AMS
            FROM(
                SELECT
                    aprexcl_pidm ENTITY_UID
                    , aprexcl_excl_code
                FROM
                    aprexcl
                WHERE
                    aprexcl_date <= TRUNC(Sysdate)
                    AND (aprexcl_end_date < TRUNC(sysdate) 
                        OR aprexcl_end_date IS NULL)
            )
            PIVOT(
                MAX(aprexcl_excl_code)
                FOR aprexcl_excl_code
                IN(  'NPH' NPH
                    ,'NOC' NOC
                    ,'NMC' NMC
                    ,'NEM' NEM
                    ,'NAM' NAM
                    ,'NDN' NDN
                    ,'NAK' NAK
                    ,'NTP' NTP
                    ,'AMS' AMS  )
            ) PivotTable
            ORDER BY 1
        ) -- end w_nsu_exclusion_slot

        , w_annual_giving_slot AS(
            SELECT 
                aprchis_pidm ENTITY_UID
                , BANINST1.NSU_ALUMNI_ODS_FUNC.F_GET_TOT_PLEDGE_PAYMENT_YEAR(aprchis_pidm,EXTRACT(YEAR FROM sysdate)) TOTAL_PLEDGE_PAYMENTS1
                , aprchis_fisc_code FISCAL_YEAR1
                , BANINST1.NSU_ALUMNI_ODS_FUNC.F_GET_TOT_GIVING_YEAR(aprchis_pidm,EXTRACT(YEAR FROM sysdate)) TOTAL_GIVING1
                
            FROM(
                SELECT distinct aprchis_pidm 
                FROM aprchis
                WHERE(  to_number(aprchis_fisc_code) >= EXTRACT(YEAR FROM sysdate)-4
                        OR aprchis_fisc_code is null)
           ) A LEFT JOIN(
                SELECT DISTINCT 
                    aprchis_pidm check_pidm
                    , aprchis_fisc_code
                FROM aprchis
                WHERE aprchis_fisc_code = EXTRACT(YEAR FROM sysdate)
                    OR aprchis_fisc_code is null
            ) B
                ON a.aprchis_pidm = b.check_pidm
        ) --end w_annual_giving_slot


       
        , w_advancement_rating_slot AS(
            SELECT
                entity_uid
                , rating_type1
                , rating_amount1
                , rating1
                , rating_level1
                , rating_type2
                , rating_amount2
                , rating2
                , rating_level2
                -- all type 3 info is null in orig CTE, would have to look at ODS rules to see what's pulling into the slot table
                , NULL rating_type3   
                , NULL rating_amount3 
                , NULL rating3
                , NULL rating_level3
            FROM(
                SELECT
                    nvl(wegif.amrexrt_pidm, p2g.amrexrt_pidm) ENTITY_UID
                    , wegif.amrexrt_exrs_code RATING_TYPE1
                    , wegif.amrexrt_ext_score RATING_AMOUNT1
                    , wegif.amrexrt_ext_value RATING1
                    , wegif.amrexrt_ext_level RATING_LEVEL1
                    , p2g.amrexrt_exrs_code RATING_TYPE2
                    , p2g.amrexrt_ext_score RATING_AMOUNT2
                    , p2g.amrexrt_ext_value RATING2
                    , p2g.amrexrt_ext_level RATING_LEVEL2
                FROM
                    (SELECT * FROM amrexrt WHERE amrexrt_exrs_code = 'WEGIF') WEGIF           
                        FULL JOIN (SELECT * FROM amrexrt WHERE amrexrt_exrs_code = 'P2G') P2G
                            ON wegif.amrexrt_pidm = p2g.amrexrt_pidm
            )
        ) -- end w_advancement_rating_slot
       
        , w_nsu_email_slot as(
            SELECT * FROM(
                SELECT
                    goremal.goremal_pidm ENTITY_UID
                    , pers.goremal_email_address PERS_EMAIL
                    , nsu.goremal_email_address NSU_EMAIL
                    , al.goremal_email_address AL_EMAIL
                    , bus.goremal_email_address BUS_EMAIL
                FROM
                    (select distinct goremal_pidm from goremal) GOREMAL
                    FULL JOIN
                    (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'PERS'
                    ) where rn = 1) PERS
                        ON goremal.goremal_pidm = pers.goremal_pidm
                    FULL JOIN
                        (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'NSU'
                    ) where rn = 1) NSU 
                        ON goremal.goremal_pidm = nsu.goremal_pidm
                    FULL JOIN
                        (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'AL'
                    ) where rn = 1) AL
                        ON goremal.goremal_pidm = al.goremal_pidm
                    FULL JOIN
                        (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'BUS'
                    ) where rn = 1) BUS
                        ON goremal.goremal_pidm = bus.goremal_pidm
            )        
            WHERE LENGTH(PERS_EMAIL||NSU_EMAIL||AL_EMAIL||BUS_EMAIL) IS NOT NULL
        ) -- end w_nsu_email_slot

        , w_nsu_telephone_slot AS(
            SELECT * FROM(
                SELECT
                    sprtele.sprtele_pidm ENTITY_UID
                    , pr.phone PR_PHONE_NUMBER
                    , pr.sprtele_primary_ind PR_PRIMARY_IND
                    , cl.phone CL_PHONE_NUMBER
                    , cl.sprtele_primary_ind CL_PRIMARY_IND
                    , b1.phone B1_PHONE_NUMBER
                    , b1.sprtele_primary_ind B1_PRIMARY_IND
                FROM
                    (select distinct sprtele_pidm from sprtele) SPRTELE
                    FULL JOIN
                    (select sprtele_pidm, nvl(sprtele_phone_area||sprtele_phone_number||sprtele_phone_ext,sprtele_intl_access) phone, sprtele_primary_ind from
                        (select sprtele_pidm, sprtele_phone_area, sprtele_phone_number, sprtele_phone_ext, sprtele_intl_access, sprtele_primary_ind, sprtele_seqno, row_number() over (partition by sprtele_pidm, sprtele_tele_code order by sprtele_seqno desc) rn
                        from sprtele where sprtele_status_ind is null AND sprtele_tele_code = 'PR'
                    ) where rn = 1) PR
                        ON sprtele.sprtele_pidm = pr.sprtele_pidm
                    FULL JOIN
                    (select sprtele_pidm, nvl(sprtele_phone_area||sprtele_phone_number||sprtele_phone_ext,sprtele_intl_access) phone, sprtele_primary_ind from
                        (select sprtele_pidm, sprtele_phone_area, sprtele_phone_number, sprtele_phone_ext, sprtele_intl_access, sprtele_primary_ind, sprtele_seqno, row_number() over (partition by sprtele_pidm, sprtele_tele_code order by sprtele_seqno desc) rn
                        from sprtele where sprtele_status_ind is null AND sprtele_tele_code = 'CL'
                    ) where rn = 1) CL
                        ON sprtele.sprtele_pidm = cl.sprtele_pidm        
                    FULL JOIN
                    (select sprtele_pidm, nvl(sprtele_phone_area||sprtele_phone_number||sprtele_phone_ext,sprtele_intl_access) phone, sprtele_primary_ind from
                        (select sprtele_pidm, sprtele_phone_area, sprtele_phone_number, sprtele_phone_ext, sprtele_intl_access, sprtele_primary_ind, sprtele_seqno, row_number() over (partition by sprtele_pidm, sprtele_tele_code order by sprtele_seqno desc) rn
                        from sprtele where sprtele_status_ind is null AND sprtele_tele_code = 'B1'
                    ) where rn = 1) B1
                        ON sprtele.sprtele_pidm = b1.sprtele_pidm
                )
            WHERE
                LENGTH(pr_phone_number||pr_primary_ind
                    ||cl_phone_number||cl_primary_ind
                    ||b1_phone_number||cl_primary_ind) IS NOT NULL
        ) -- end w_nsu_telephone_slot
    
        , w_xref_xclusion AS(
        -- used to make w_relationship faster
            SELECT aprchld_pidm||aprchld_xref_code||aprchld_chld_pidm
            FROM aprchld
            WHERE aprchld_xref_code IS NOT NULL
            UNION
            SELECT aprcsps_pidm||aprcsps_xref_code||aprcsps_sps_pidm
            FROM aprcsps
            WHERE aprcsps_xref_code IS NOT NULL
        )        
        , w_relationship AS(
            SELECT
                aprchld_pidm ENTITY_UID
                , aprxref_xref_code RELATION_SOURCE_CODE
                , nvl2(aprchld_xref_code,'CX','C') RELATION_SOURCE
                , nvl2(aprchld_xref_code,'Child/Cross Reference','Child') RELATION_SOURCE_DESC
                , aprxref_household_ind HOUSEHOLD_IND
                , aprxref_cm_pri_ind COMBINED_MAILING_PRIORITY
                , DECODE(aprxref_cm_pri_ind,'P','PRIMARY','S','SECONDARY') COMBINED_MAILING_PRIORITY_DESC
                , spriden_id RELATED_ID
            FROM
                aprchld
                LEFT JOIN(
                        SELECT
                            aprxref_pidm
                            , aprxref_xref_pidm
                            , aprxref_xref_code
                            , aprxref_household_ind
                            , aprxref_cm_pri_ind
                            , spriden_id
                        FROM
                            aprxref
                            LEFT JOIN spriden
                                ON aprxref_xref_pidm = spriden_pidm
                                AND spriden_change_ind is null
                )   ON aprchld_pidm = aprxref_pidm
                    AND aprchld_xref_code = aprxref_xref_code
                    AND aprchld_chld_pidm = aprxref_xref_pidm
            UNION ALL
            SELECT
                aprcsps_pidm ENTITY_UID
                , aprxref_xref_code RELATION_SOURCE_CODE
                , nvl2(aprcsps_xref_code,'SX','S') RELATION_SOURCE
                , nvl2(aprcsps_xref_code,'Spouse/Cross Reference','Spouse') RELATION_SOURCE_DESC
                , aprxref_household_ind HOUSEHOLD_IND
                , aprxref_cm_pri_ind COMBINED_MAILING_PRIORITY
                , DECODE(aprxref_cm_pri_ind,'P','PRIMARY','S','SECONDARY') COMBINED_MAILING_PRIORITY_DESC
                , spriden_id RELATED_ID
            FROM
                aprcsps
                LEFT JOIN(
                        SELECT
                            aprxref_pidm
                            , aprxref_xref_pidm
                            , aprxref_xref_code
                            , aprxref_household_ind
                            , aprxref_cm_pri_ind
                            , spriden_id
                        FROM
                            aprxref
                            LEFT JOIN spriden
                                ON aprxref_xref_pidm = spriden_pidm
                                AND spriden_change_ind is null
                )   ON aprcsps_mars_ind = 'A'
                    AND aprcsps_pidm = aprxref_pidm
                    AND aprcsps_xref_code = aprxref_xref_code
                    AND aprcsps_sps_pidm = aprxref_xref_pidm
            UNION ALL
            SELECT
                aprxref_pidm ENTITY_UID
                , aprxref_xref_code RELATION_SOURCE_CODE
                , 'X' RELATION_SOURCE
                , 'Cross Reference' RELATION_SOURCE_DESC
                , aprxref_xref_code --aprxref_household_ind HOUSEHOLD_IND
                , aprxref_cm_pri_ind COMBINED_MAILING_PRIORITY
                , DECODE(aprxref_cm_pri_ind,'P','PRIMARY','S','SECONDARY') COMBINED_MAILING_PRIORITY_DESC
                , spriden_id RELATED_ID
            FROM(
                    SELECT
                        aprxref_pidm
                        , aprxref_xref_code
                        , aprxref_household_ind
                        , aprxref_cm_pri_ind
                        , spriden_id
                    FROM(
                            SELECT * FROM aprxref
                            WHERE 
                                aprxref_pidm||aprxref_xref_code||aprxref_xref_pidm NOT IN(  SELECT * FROM w_xref_xclusion)
                        )
                        JOIN spriden
                            ON aprxref_xref_pidm = spriden_pidm
                            AND spriden_change_ind IS NULL
            )     
        ) -- end w_relationship
   
        , w_degree_history AS(
            SELECT * FROM (    
                SELECT 
                    pidm
                    , nsu_ind
                    , rn seqno
                    , degree
                    , degree_desc
                    , academic_year
                    , major
                    , major_desc
                    , degree_date
    
                FROM(
                    SELECT  
                        apradeg_pidm pidm
                        , 'Y' NSU_IND
                        , apradeg_degc_code degree
                        , stvdegc_desc degree_desc
                        , apradeg_acyr_code academic_year
                        , apramaj_majr_code major
                        , stvmajr_desc major_desc
                        , apradeg_date degree_date
                        , row_number() OVER (PARTITION BY apradeg_pidm ORDER BY
                                NVL(apradeg_date,'01-JAN-1900') DESC,
                                CASE SUBSTR(apradeg_degc_code,1,1)
                                    WHEN 'P' THEN 1
                                    WHEN 'J' THEN 1
                                    WHEN 'D' THEN 1
                                    WHEN 'M' THEN 2
                                    WHEN 'B' THEN 3
                                    WHEN 'A' THEN 4
                                    WHEN 'C' THEN 5
                                    ELSE 9 
                                END) RN
                    FROM
                        (apradeg JOIN stvdegc ON apradeg_degc_code = stvdegc_code)
                        LEFT JOIN
                        (apramaj JOIN stvmajr ON apramaj_majr_code = stvmajr_code)
                            ON apradeg_pidm = apramaj_pidm
                            AND apradeg_seq_no = apramaj_adeg_seq_no
                    WHERE apradeg_sbgi_code = '207263' -- NSU college code
                    --and apradeg_pidm in( 66613,85539)
                )
    
                UNION
    
                SELECT 
                    pidm
                    , nsu_ind
                    , rn seqno
                    , degree
                    , degree_desc
                    , academic_year
                    , major
                    , major_desc
                    , degree_date
    
                FROM(
                    SELECT  
                        apradeg_pidm PIDM
                        , 'N' NSU_IND
                        , apradeg_degc_code DEGREE
                        , stvdegc_desc DEGREE_DESC
                        , apradeg_acyr_code ACADEMIC_YEAR
                        , apramaj_majr_code MAJOR
                        , stvmajr_desc MAJOR_DESC
                        , apradeg_date DEGREE_DATE
                        , ROW_NUMBER() OVER (PARTITION BY apradeg_pidm ORDER BY
                                NVL(apradeg_date,'01-JAN-1900') DESC,
                                CASE SUBSTR(apradeg_degc_code,1,1)
                                    WHEN 'P' THEN 1
                                    WHEN 'J' THEN 1
                                    WHEN 'D' THEN 1
                                    WHEN 'M' THEN 2
                                    WHEN 'B' THEN 3
                                    WHEN 'A' THEN 4
                                    WHEN 'C' THEN 5
                                    ELSE 9 
                                END) RN         
                    FROM (apradeg JOIN stvdegc ON apradeg_degc_code = stvdegc_code)
                         LEFT JOIN
                         (apramaj JOIN stvmajr ON apramaj_majr_code = stvmajr_code)
                            ON apradeg_pidm = apramaj_pidm
                            AND apradeg_seq_no = apramaj_adeg_seq_no
                    WHERE apradeg_sbgi_code <> '207263'
                    --and apradeg_pidm in (66613,85539)
                    )
            ) WHERE seqno < 4
            --and pidm = 85539
        ) -- end w_degree_history
    
        , w_degree_slot AS(
            SELECT
                d1.pidm PERSON_UID
                , d1.nsu_ind INSTITUTION_IND
                , d1.degree DEGREE_1
                , d1.degree_desc DEGREE_DESC_1
                , d2.degree DEGREE_2
                , d2.degree_desc DEGREE_DESC_2
                , d3.degree DEGREE_3
                , d3.degree_desc DEGREE_DESC_3
                , d1.academic_year ACADEMIC_YEAR_1
                , d2.academic_year ACADEMIC_YEAR_2
                , d3.academic_year ACADEMIC_YEAR_3
                , d1.major MAJOR_1
                , d1.major_desc MAJOR_DESC_1
                , d2.major MAJOR_2
                , d2.major_desc MAJOR_DESC_2
                , d3.major MAJOR_3
                , d3.major_desc MAJOR_DESC_3
                , d1.degree_date DEGREE_DATE_1
                , d2.degree_date DEGREE_DATE_2
                , d3.degree_date DEGREE_DATE_3
            FROM
                w_degree_history d1
                LEFT JOIN w_degree_history d2
                    ON d1.pidm = d2.pidm
                    AND d1.nsu_ind = 'Y'
                    AND d2.nsu_ind = 'Y'
                    AND d1.seqno = 1
                    AND d2.seqno = 2
                LEFT JOIN w_degree_history d3
                    ON d1.pidm = d3.pidm
                    AND d1.nsu_ind = 'Y'
                    AND d3.nsu_ind = 'Y'
                    AND d1.seqno = 1
                    AND d1.seqno = 3
            WHERE d1.nsu_ind = 'Y'
                AND d1.seqno = 1
    
            UNION
    
            SELECT
                d1.pidm PERSON_UID
                , d1.nsu_ind INSTITUTION_IND
                , d1.degree DEGREE_1
                , d1.degree_desc DEGREE_DESC_1
                , d2.degree DEGREE_2
                , d2.degree_desc DEGREE_DESC_2
                , d3.degree DEGREE_3
                , d3.degree_desc DEGREE_DESC_3
                , d1.academic_year ACADEMIC_YEAR_1
                , d2.academic_year ACADEMIC_YEAR_2
                , d3.academic_year ACADEMIC_YEAR_3
                , d1.major MAJOR_1
                , d1.major_desc MAJOR_DESC_1
                , d2.major MAJOR_2
                , d2.major_desc MAJOR_DESC_2
                , d3.major MAJOR_3
                , d3.major_desc MAJOR_DESC_3
                , d1.degree_date DEGREE_DATE_1
                , d2.degree_date DEGREE_DATE_2
                , d3.degree_date DEGREE_DATE_3
            FROM
                w_degree_history d1
                LEFT JOIN w_degree_history d2
                    ON d1.pidm = d2.pidm
                    AND d1.nsu_ind = 'N'
                    AND d2.nsu_ind = 'N'
                    AND d1.seqno = 1
                    AND d2.seqno = 2
                LEFT JOIN w_degree_history d3
                    ON d1.pidm = d3.pidm
                    AND d1.nsu_ind = 'N'
                    AND d3.nsu_ind = 'N'
                    AND d1.seqno = 1
                    AND d3.seqno = 3
            WHERE d1.nsu_ind = 'N'
                AND d1.seqno = 1
        ) -- end w_degree_slot;
   
        , w_spbpers AS(
            SELECT
                spbpers_pidm
                , spbpers_birth_date
                , spbpers_dead_ind
                , spbpers_vera_ind
--                Veteran Category: 
--                    (NULL) Not a Veteran, 
--                    (B) Protected veteran choosing not to self-identify the classification, 
--                    (O) Active Wartime or Campaign Badge Veteran, 
--                    (V) Not a Protected Veteran
                
            FROM
                spbpers
            WHERE
                spbpers_pidm IN (SELECT person_uid FROM w_constituent)
        ) -- end w_spbpers
   
        , w_apbghis AS(
            SELECT
               apbghis_pidm
               , apbghis_total_no_gifts
               , apbghis_high_gift_amt
               , apbghis_last_gift_date
            FROM
                apbghis 
        ) -- end w_apbghis;
   
        , w_amrstaf AS(
            SELECT
                amrstaf_pidm
                , amrstaf_iden_code
            FROM
                amrstaf
            WHERE
                AMRSTAF_PRIMARY_IND = 'Y'
        ) -- end w_amrstaf
    
        , w_guriden AS(
            SELECT
                guriden_iden_code
                , guriden_desc
            FROM
                guriden
        ) -- end w_guriden
   
        , w_recent_membership AS(
            SELECT
                aarmemb_pidm ENTITY_UID,
                MAX(aarmemb_amst_code) KEEP (DENSE_RANK FIRST ORDER BY DECODE(aarmemb_amst_code,'A',1,'I',3) ASC ,aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_STATUS,
                MAX(aarmemb_amct_code) KEEP (DENSE_RANK FIRST ORDER BY DECODE(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_CATEGORY,
                MAX(aarmemb_exp_date) KEEP (DENSE_RANK FIRST ORDER BY DECODE(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) EXPIRATION_DATE,
                MAX(aarmemb_memb_no) KEEP (DENSE_RANK FIRST ORDER BY DECODE(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_NUMBER
            FROM
                aarmemb
            GROUP BY 
                aarmemb_pidm
        ) -- end w_recent_membership
    
        , w_won_membership AS(
            SELECT
                aarmemb_pidm ENTITY_UID,
                MAX(aarmemb_amst_code) KEEP (DENSE_RANK FIRST ORDER BY DECODE(aarmemb_amst_code,'A',1,'I',3) ASC ,aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_STATUS,
                MAX(aarmemb_amct_code) KEEP (DENSE_RANK FIRST ORDER BY DECODE(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_CATEGORY,
                MAX(aarmemb_exp_date) KEEP (DENSE_RANK FIRST ORDER BY DECODE(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) EXPIRATION_DATE,
                MAX(aarmemb_memb_no) KEEP (DENSE_RANK FIRST ORDER BY DECODE(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_NUMBER
            FROM
                aarmemb
            WHERE
                aarmemb_membership = 'WON'
            GROUP BY
                aarmemb_pidm
        ) -- end w_won_membership
    
        , w_fan_membership AS(
            SELECT
                aarmemb_pidm entity_uid,
                MAX(aarmemb_amst_code) KEEP (DENSE_RANK FIRST ORDER BY decode(aarmemb_amst_code,'A',1,'I',3) ASC ,aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_STATUS,
                MAX(aarmemb_amct_code) KEEP (DENSE_RANK FIRST ORDER BY decode(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_CATEGORY,
                MAX(aarmemb_exp_date) KEEP (DENSE_RANK FIRST ORDER BY decode(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) EXPIRATION_DATE,
                MAX(aarmemb_memb_no) KEEP (DENSE_RANK FIRST ORDER BY decode(aarmemb_amst_code,'A',1,'I',3) ASC , aarmemb_entry_date DESC, aarmemb_memb_no DESC) MEMBERSHIP_NUMBER
            FROM 
                aarmemb
            WHERE 
                aarmemb_membership = 'FAN'
            GROUP BY 
                aarmemb_pidm
        ) -- end w_fan_membership
    
        , w_salutation AS(
        SELECT * FROM(
            SELECT
                aprsalu_pidm Entity_Uid
                , aprsalu_salu_code
                , aprsalu_salutation
            FROM
                aprsalu
            )
            PIVOT
            (
            MAX(aprsalu_salutation)
            FOR aprsalu_salu_code
            IN ('CIFE' CIFE,'SIFE' SIFE,'CIFL' CIFL,'SIFL' SIFL)
            )
        ) -- end w_salutation
        
        , w_ytd AS(
            SELECT
                entity_uid
                , SUM(CASE WHEN year_pos = 1 THEN tots END) YTD
                , SUM(CASE WHEN year_pos = 2 THEN tots END) YTD_1
                , SUM(CASE WHEN year_pos = 3 THEN tots END) YTD_2
                , SUM(CASE WHEN year_pos = 4 THEN tots END) YTD_3
                , SUM(CASE WHEN year_pos = 5 THEN tots END) YTD_4
                , SUM(tots) LIFETIME
            FROM(
                SELECT
                    agbgift_pidm ENTITY_UID
                    , to_char(agbgift_gift_date,'YYYY') GIFT_DATE
                    , sum(nvl(agrgdes_amt,0)) TOTS
                FROM
                    agbgift
                    LEFT JOIN agrgdes
                        ON agbgift_pidm = agrgdes_pidm
                        AND agbgift_gift_no = agrgdes_gift_no
                GROUP BY
                    agbgift_pidm
                    , to_char(agbgift_gift_date,'YYYY')
    
            UNION
            SELECT
                agrgaux_pidm ENTITY_UID
                , TO_CHAR(agrgaux_auxl_value_date,'YYYY') GIFT_DATE
                , SUM(NVL(agrgaux_dcpr_value,0))*-1 TOTS
            FROM
                agrgaux
            GROUP BY
                agrgaux_pidm
                , TO_CHAR(agrgaux_auxl_value_date,'YYYY')
            )
            LEFT JOIN(
                SELECT
                   TO_CHAR(SYSDATE,'YYYY')-LEVEL+1 YEAR
                   , LEVEL YEAR_POS
                FROM 
                    DUAL
                CONNECT BY LEVEL <= 5
            )
            ON year = gift_date
        GROUP BY entity_uid
        ) -- end w_ytd
   
        , w_jfsgd AS(
            SELECT
                amrexrt_pidm ENTITY_UID,
                amrexrt_ext_value RATING
            FROM
                amrexrt -- advancement_rating
            WHERE
                amrexrt_exrs_code = 'JFSGD'
        ) -- end w_jfsgd
    
        , w_employment AS(
            SELECT 
                person_uid
                , employer_name
                , position_title
            FROM(
                SELECT
                    aprehis_pidm PERSON_UID
                    , nvl2( aprehis_empr_name -- if not null then 1 else 2
                            ,aprehis_empr_name
                            ,nvl2(aprehis_empr_pidm,f_format_name(aprehis_empr_pidm,'LFMI'),null)
                        ) EMPLOYER_NAME
                    , aprehis_empl_position POSITION_TITLE
                    --, aprehis.*
                    , row_number() over (partition by aprehis_pidm order by aprehis_pidm,nvl(aprehis_from_date,aprehis_to_date) desc, aprehis_seq_no desc) rn
                FROM
                    aprehis
            )
            WHERE rn = 1
        ) -- end w_employment;
    
        , w_address AS(
            SELECT
                spraddr_pidm,
                MAX(spraddr_street_line1) KEEP (DENSE_RANK FIRST ORDER BY DECODE(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) ASC, spraddr_seqno DESC) spraddr_street_line1,
                MAX(spraddr_street_line2) KEEP (DENSE_RANK FIRST ORDER BY DECODE(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) ASC, spraddr_seqno DESC) spraddr_street_line2,
                MAX(spraddr_city) KEEP (DENSE_RANK FIRST ORDER BY DECODE(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) ASC, spraddr_seqno DESC) spraddr_city,
                MAX(spraddr_stat_code) KEEP (DENSE_RANK FIRST ORDER BY DECODE(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) ASC, spraddr_seqno DESC) spraddr_stat_code,
                MAX(spraddr_zip) KEEP (DENSE_RANK FIRST ORDER BY DECODE(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) ASC, spraddr_seqno DESC) spraddr_zip,
                MAX(spraddr_cnty_code) KEEP (DENSE_RANK FIRST ORDER BY DECODE(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) ASC, spraddr_seqno DESC) spraddr_cnty_code,
                MAX(spraddr_natn_code) KEEP (DENSE_RANK FIRST ORDER BY DECODE(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) ASC, spraddr_seqno DESC) spraddr_natn_code,
                MAX(spraddr_atyp_code) KEEP (DENSE_RANK FIRST ORDER BY DECODE(spraddr_atyp_code,'MA',1,'PR',2,'BU',3,'BD',4,5) ASC, spraddr_seqno DESC) spraddr_atyp_code
            FROM
                spraddr
            WHERE
                sysdate BETWEEN spraddr_from_date AND nvl(spraddr_to_date, sysdate +1)
                AND spraddr_status_ind IS NULL
            GROUP BY
                spraddr_pidm
        ) -- end w_address;
   
        , w_long_years_given AS(
            SELECT 
                spriden_pidm
                , MAX(l) RECENT_CONSECUTIVE_YEARS
            FROM(
                SELECT DISTINCT 
                    spriden_pidm
                    , agbgift.AGBGIFT_FISC_CODE
                    , level L
                FROM
                    agbgift
                    JOIN spriden
                        ON spriden_pidm = agbgift_pidm
                        AND spriden_change_ind IS NULL
                WHERE AGBGIFT_FISC_CODE <= TO_CHAR(TO_DATE(p_giving_end_date), 'YYYY')
                CONNECT BY PRIOR spriden_pidm = spriden_pidm
                    AND PRIOR agbgift_fisc_code = agbgift_fisc_code -1
            )
            GROUP BY spriden_pidm
        ) -- end w_long_years_given;
    
        , w_recent_cons_years AS(
            SELECT 
                spriden_pidm
                , MAX(l) KEEP (DENSE_RANK FIRST ORDER BY agbgift_fisc_code DESC) RECENT_CONSECUTIVE_YEARS
            FROM(
                SELECT DISTINCT
                    spriden_pidm
                    , agbgift.agbgift_fisc_code
                    , level L
                FROM
                    agbgift
                    JOIN spriden
                        ON spriden_pidm = agbgift_pidm
                        AND spriden_change_ind IS NULL
                WHERE AGBGIFT_FISC_CODE <= TO_CHAR(TO_DATE(p_giving_end_date), 'YYYY')
                CONNECT BY PRIOR spriden_pidm = spriden_pidm
                    AND PRIOR agbgift_fisc_code = agbgift_fisc_code -1
            )
            GROUP BY spriden_pidm
        ) -- end w_recent_cons_years;
    
        , w_range_tot_gift AS(
            SELECT
                agbgift_pidm ENTITY_UID
                , TRIM(TO_CHAR(SUM(NVL(agrgdes_amt,0)), '999999990.99')) GIFT_AMT
            FROM
                agbgift
                LEFT JOIN agrgdes
                    ON agbgift_pidm = agrgdes_pidm
                    AND agbgift_gift_no = agrgdes_gift_no
            WHERE
                agbgift_gift_date BETWEEN p_giving_start_date AND p_giving_end_date
            GROUP BY
                agbgift_pidm
        ) -- end w_range_tot_gift;
    
        , w_range_tot_aux AS(
            SELECT
                agrgaux_pidm ENTITY_UID
                , TRIM(TO_CHAR(SUM(NVL(agrgaux_dcpr_value,0)),'999999990.99')) GIFT_AMT
            FROM
                agrgaux
            WHERE
                agrgaux_auxl_value_date BETWEEN p_giving_start_date AND p_giving_end_date
            GROUP BY
                agrgaux_pidm
        ) -- end w_range_tot_aux
    
        , w_spec_purpose AS(
            SELECT
                entity_uid
                , NVL(special_purpose_type,'XXXXX')
                    || '-' || NVL(special_purpose_type_desc,'XXXXXXXXXXXXXXXXXXXXXXXXXX')
                    || '/' || NVL(special_purpose_group,'XXXXX')
                    || '-' || NVL(special_purpose_group_desc,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
            FROM(
                SELECT
                    aprpros_pidm ENTITY_UID
                    , aprpros_prtp_code SPECIAL_PURPOSE_TYPE
                    , atvprtp_desc SPECIAL_PURPOSE_TYPE_DESC
                    , aprpros_prcd_code SPECIAL_PURPOSE_GROUP
                    , atvprcd_desc SPECIAL_PURPOSE_GROUP_DESC
                    , ROW_NUMBER() OVER (PARTITION BY aprpros_pidm ORDER BY aprpros_date desc) RN
                FROM
                    aprpros
                    JOIN atvprtp
                        ON aprpros_prtp_code = atvprtp_code
                    JOIN atvprcd
                        ON aprpros_prcd_code = atvprcd_code
            )
    
            WHERE
                rn = 1
        ) -- end w_spec_purpose    
---

        SELECT 
            w_constituent.person_uid 
            , w_CONSTITUENT.ID
            , w_CONSTITUENT.NAME
            , w_CONSTITUENT.PREF_LAST_NAME
            , w_CONSTITUENT.MAIDEN_LAST_NAME
            , w_CONSTITUENT.SPOUSE_NAME
            , w_relationship.related_id related_id
            , w_CONSTITUENT.PREF_DONOR_CATEGORY
            , w_CONSTITUENT.PREF_DONOR_CATEGORY_DESC
            , w_CONSTITUENT.EMAIL_PREFERRED_ADDRESS
            
            , w_address.spraddr_street_line1 "STREET_LINE1"
            , w_address.spraddr_street_line2 "STREET_LINE2"
            , w_address.spraddr_city "CITY"
            , w_address.spraddr_stat_code "STATE_PROVINCE"
            , w_address.spraddr_zip "POSTAL_CODE"
            , w_address.spraddr_cnty_code "COUNTY"
            , w_address.spraddr_natn_code "NATION"
            , w_address.spraddr_atyp_code "ADDRESS_TYPE"

            , w_nsu_exclusion_slot.nph
            , w_nsu_exclusion_slot.noc
            , w_nsu_exclusion_slot.nmc
            , w_nsu_exclusion_slot.nem
            , w_nsu_exclusion_slot.nam
            , w_nsu_exclusion_slot.ndn
            , w_nsu_exclusion_slot.nak
            , w_nsu_exclusion_slot.ntp
            , w_nsu_exclusion_slot.ams

            , nvl(w_SALUTATION.CIFE,w_SALUTATION.SIFE) PREFERRED_FULL_w_SALUTATION
            , nvl(w_SALUTATION.CIFL,w_SALUTATION.SIFL) PREFERRED_SHORT_w_SALUTATION
            , w_SALUTATION.SIFE SIFE
            , w_SALUTATION.SIFL SIFL
            
            , w_advancement_rating_slot.rating_type1
            , w_advancement_rating_slot.rating_amount1
            , w_advancement_rating_slot.rating1
            , w_advancement_rating_slot.rating_level1
            , w_advancement_rating_slot.rating_type2
            , w_advancement_rating_slot.rating_amount2
            , w_advancement_rating_slot.rating2
            , w_advancement_rating_slot.rating_level2
            , w_advancement_rating_slot.rating_type3
            , w_advancement_rating_slot.rating_amount3
            , w_advancement_rating_slot.rating3
            , w_advancement_rating_slot.rating_level3
            
            , w_recent_membership.membership_category Membership_Name
            , w_recent_membership.membership_status Membership_Status
            , w_recent_membership.membership_number membership_number
            , w_recent_membership.expiration_date expiration_date
            , w_won_membership.membership_category w_WON_Membership_name
            , w_won_membership.membership_status w_WON_Membership_status
            , w_won_membership.membership_number w_WON_membership_number
            , w_won_membership.expiration_date WON_expiration_date
            , w_fan_membership.membership_category w_FAN_Membership_name
            , w_fan_membership.membership_status w_FAN_Membership_status
            , w_fan_membership.membership_number w_FAN_membership_number
            , w_fan_membership.expiration_date FAN_expiration_date

            , w_nsu_email_slot.pers_email
            , w_nsu_email_slot.nsu_email
            , w_nsu_email_slot.al_email
            , w_nsu_email_slot.bus_email
            , w_nsu_telephone_slot.pr_phone_number
            , w_nsu_telephone_slot.pr_primary_ind
            , w_nsu_telephone_slot.cl_phone_number
            , w_nsu_telephone_slot.cl_primary_ind
            , w_nsu_telephone_slot.b1_phone_number
            , w_nsu_telephone_slot.b1_primary_ind
            
-->> consolidate giving_slot with household_giving            
            , TRIM(TO_CHAR(NVL(w_annual_giving_slot.total_pledge_payments1,0), '999999990.99')) TOTAL_PLEDGE_PAYMENTS1
--            --trim(to_char(nvl(w_CONSTITUENT.LIFE_TOTAL_GIVING,0), '999999990.99')) "LIFE_TOTAL_GIVING",
            , TRIM(TO_CHAR(NVL(w_household_giving.lifetime_donor_giving,0),'999999990.99')) LIFE_TOTAL_GIVING
            , TRIM(TO_CHAR(NVL(w_ytd.lifetime,0), '999999990.99')) LIFE_TOTAL_GIVING_AUX
            , w_annual_giving_slot.fiscal_year1
            , TRIM(TO_CHAR(NVL(w_annual_giving_slot.total_giving1,0), '999999990.99')) TOTAL_GIVING1
--            --, NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(w_constituent.person_uid, 'ANNUAL') "ANNUAL_HOUSEHOLD_GIVING"
            , TRIM(TO_CHAR(NVL(w_household_giving.annual_household_giving,0), '999999990.99')) ANNUAL_HOUSEHOLD_GIVING
--            --, NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(w_constituent.person_uid, 'LIFETIME') "LIFETIME_HOUSEHOLD_GIVING"
            , TRIM(TO_CHAR(NVL(w_household_giving.lifetime_household_giving,0), '999999990.99')) LIFETIME_HOUSEHOLD_GIVING
            
            , w_relationship.relation_source
            , w_relationship.relation_source_desc
            , w_relationship.combined_mailing_priority
            , w_relationship.combined_mailing_priority_desc
            , w_relationship.household_ind
            , TRIM(TO_CHAR(NVL(w_range_tot_gift.gift_amt,0), '999999990.99')) DATE_RANGE_TOTAL_GIVING
            , TRIM(TO_CHAR(NVL(w_range_tot_aux.gift_amt,0), '999999990.99')) DATE_RANGE_TOTAL_AUX_AMT
            , w_degree_slot.degree_1
            , w_degree_slot.degree_desc_1
            , w_degree_slot.academic_year_1
            , w_degree_slot.major_1
            , w_degree_slot.major_desc_1
            , w_degree_slot.degree_2
            , w_degree_slot.degree_desc_2
            , w_degree_slot.academic_year_2
            , w_degree_slot.major_2
            , w_degree_slot.major_desc_2
            , w_degree_slot.degree_3
            , w_degree_slot.degree_desc_3
            , w_degree_slot.academic_year_3 
            , w_degree_slot.major_3
            , w_degree_slot.major_desc_3
            , w_spec_purpose.entity_uid SPEC_PURPOSE_TYPE_GROUP
            , w_apbghis.apbghis_total_no_gifts total_no_gifts
            , w_apbghis.apbghis_high_gift_amt high_gift_amt
            , w_apbghis.apbghis_last_gift_date last_gift_date
            , w_CONSTITUENT.DECEASED_IND
            , w_spbpers.SPBPERS_BIRTH_DATE date_of_birth
            , w_JFSGD.rating JFSG_estimated_capacity

            , nvl(w_ytd.ytd_1,0) DED_AMT_w_YTD_1
            , nvl(w_ytd.ytd_2,0) DED_AMT_w_YTD_2
            , nvl(w_ytd.ytd_3,0) DED_AMT_w_YTD_3
            , nvl(w_ytd.ytd_4,0) DED_AMT_w_YTD_4
            
            , w_employment.employer_name employer
            , w_employment.position_title position
            , nvl2(SPBPERS_VERA_IND, 'Y','N') Veteran_ind
            , w_guriden.guriden_desc
            , w_long_years_given.recent_consecutive_years longest_cons_years_given
            , w_recent_cons_years.recent_consecutive_years recent_consecutive_years

        FROM
            w_constituent
                LEFT JOIN w_nsu_exclusion_slot
                    ON w_constituent.person_uid = w_nsu_exclusion_slot.entity_uid
                LEFT JOIN w_annual_giving_slot
                    ON w_constituent.person_uid = w_annual_giving_slot.entity_uid
                LEFT JOIN w_ADVANCEMENT_RATING_SLOT
                    ON w_constituent.person_uid = w_advancement_rating_slot.entity_uid
                LEFT JOIN w_NSU_EMAIL_SLOT
                    ON w_constituent.person_uid = w_nsu_email_slot.entity_uid
                LEFT JOIN w_NSU_TELEPHONE_SLOT
                    ON w_constituent.person_uid = w_nsu_telephone_slot.entity_uid
                LEFT JOIN w_RELATIONSHIP
                    ON w_constituent.person_uid = w_relationship.entity_uid
                    AND w_relationship.relation_source = 'SX'
                LEFT JOIN w_household_giving
                    ON w_constituent.person_uid = w_household_giving.person_uid
                LEFT JOIN w_degree_slot
                    ON w_constituent.person_uid = w_degree_slot.person_uid
                    AND w_degree_slot.institution_ind = 'Y'
                LEFT JOIN w_spbpers
                    ON w_constituent.person_uid = w_spbpers.spbpers_pidm
                LEFT JOIN w_apbghis
                    ON w_constituent.person_uid = w_apbghis.apbghis_pidm
                LEFT JOIN w_amrstaf
                    ON w_constituent.person_uid = w_amrstaf.amrstaf_pidm
                LEFT JOIN  w_guriden
                    ON w_amrstaf.amrstaf_iden_code = w_guriden.guriden_iden_code
                LEFT JOIN w_recent_membership
                    ON w_constituent.person_uid = w_recent_membership.entity_uid
                LEFT JOIN w_won_membership
                    ON w_constituent.person_uid = w_won_membership.entity_uid
                LEFT JOIN w_fan_membership
                    ON w_constituent.person_uid = w_fan_membership.entity_uid
                LEFT JOIN w_salutation
                    ON w_constituent.person_uid = w_salutation.entity_uid
                LEFT JOIN w_ytd
                    ON w_constituent.person_uid = w_ytd.entity_uid
                LEFT JOIN w_jfsgd
                    ON w_constituent.person_uid = w_jfsgd.entity_uid
                LEFT JOIN w_employment
                    ON w_constituent.person_uid = w_employment.person_uid
                LEFT JOIN w_address
                    ON w_constituent.person_uid = w_address.spraddr_pidm
                LEFT JOIN w_long_years_given
                    ON w_constituent.person_uid = w_long_years_given.spriden_pidm
                LEFT JOIN w_recent_cons_years
                    ON w_constituent.person_uid = w_recent_cons_years.spriden_pidm
                LEFT JOIN w_range_tot_gift
                    ON w_constituent.person_uid = w_range_tot_gift.entity_uid
                LEFT JOIN w_range_tot_aux
                    ON w_constituent.person_uid = w_range_tot_aux.entity_uid
                LEFT JOIN w_spec_purpose
                    ON w_constituent.person_uid = w_spec_purpose.entity_uid

        WHERE(
                (   p_all_exclusion_codes = 1
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.NPH||',') > 0
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.NOC||',') > 0
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.NMC||',') > 0
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.NEM||',') > 0
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.NAM||',') > 0
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.NDN||',') > 0
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.NAK||',') > 0
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.NTP||',') > 0
                    OR instr(p_exclusion_codes, w_NSU_EXCLUSION_SLOT.AMS||',') > 0
                )
                -----
                and(
                        (p_all_mail_codes = 1
                    )
                    or exists(  select 'x' "calc1"
                                FROM aprmail
                                WHERE aprmail_pidm = w_constituent.person_uid
                                    and instr(p_mail_codes,aprmail_mail_code||',') > 0 
                    )
                )
                -----
                and(
                        (p_all_donor_cats = 1
                    )
                    or exists(  select 'x' "calc1"
                                FROM aprcatg DONOR_CATEGORY
                                WHERE donor_category.aprcatg_pidm = w_constituent.person_uid
                                    AND instr(p_donor_cats, donor_category.aprcatg_donr_code||',') >0
                    )
                )
                -----
                and(
                        (p_ignore_gift_dates = 1
                    ) or exists(    select 'x'
                                FROM agbgift
                                WHERE agbgift_pidm = w_constituent.person_uid
                                    AND agbgift_gift_date BETWEEN p_giving_start_date AND p_giving_end_date
                    )
                )
                -----
                and(
                        (p_all_spec_purpose_types  = 1
                    )
                    or exists(  select 'x' "calc1"
                                FROM aprpros SPECIAL_PURPOSE_GROUP
                                WHERE special_purpose_group.aprpros_pidm = w_constituent.person_uid
                                    AND instr(p_spec_purpose_types, special_purpose_group.aprpros_prtp_code||',') >0
                    )
                )
                -----                                  
                and(
                        (p_all_spec_purpose_groups = 1
                    )
                    or exists(  select 'x' "calc1"
                                FROM aprpros SPECIAL_PURPOSE_GROUP
                                WHERE special_purpose_group.aprpros_pidm = w_constituent.person_uid
                                    AND instr(p_spec_purpose_groups, special_purpose_group.aprpros_prcd_code||',') >0
                    )
                )                
                -----
                and(    p_all_gift_capacities = 1
                        or instr(p_gift_capacity, w_ADVANCEMENT_RATING_SLOT.RATING_AMOUNT1||',') > 0
                )
                -----
                and(    p_all_wealth_engine_desg = 1
                        or instr(p_wealth_engine_desg, w_ADVANCEMENT_RATING_SLOT.RATING_LEVEL2||',') > 0
                )                
                -----
                and(    p_ignore_household_ind = 1
                        or instr(p_household_ind, w_RELATIONSHIP.HOUSEHOLD_IND||',') > 0                
                )
                -----
                and(
                        ( p_prim_spouse_unmarried = 1                      
                        ) AND(  (w_RELATIONSHIP.RELATION_SOURCE = 'SX'
                                    AND w_RELATIONSHIP.COMBINED_MAILING_PRIORITY = 'P'
                                ) OR    NOT EXISTS( SELECT 'x' "calc1"
                                                    FROM w_relationship RELATIONSHIP1
                                                    WHERE relationship1.entity_uid = w_constituent.person_uid
                                                        AND relationship1.relation_source = 'SX'
                                                        AND relationship1.relation_source_code = 'SP1' -- current spouse
                                        )
                        )
                )
                -----
                and(
                        (p_deceased = 1
                    ) or NVL(w_spbpers.spbpers_dead_ind,'N') = 'N'
                )
                -----
                and(
                    p_all_leadership = 1
                    or( exists( select 'X' "calc1"
                                from apracld
                                where   instr(p_leadership_codes, apracld_lead_code||',') > 0  -- if code||, in code list passed in,...
                                        and   apracld_pidm = w_CONSTITUENT.PERSON_UID
                        )
                        and p_all_leadership = 0                
                    )
                )
                -----
                and(    p_all_zipcodes = 1
                        or( p_ignore_zip = 1
                            and instr(p_state_codes, substr(w_address.spraddr_stat_code,1,2)||',') > 0 
                        )
                    or instr(p_zipcodes, substr(w_address.spraddr_zip,1,5)||',') >0 
                )
                -----
                and(    p_all_counties = 1
                        or instr(p_county_codes, w_address.spraddr_cnty_code||',') > 0
                )
                -----                
                and(    p_use_city = 1
                        or    upper(w_address.spraddr_city) = upper(p_city)
                )
                -----
                and(
                        nvl2(SPBPERS_VERA_IND, 'Y','N') = p_veteran 
                        or p_veteran = 'All'
                )
                ----                
                and( -- Activity codes will come in as a csv string ending with a comma   
                        p_all_activities = 1
                        or  exists( select 'X' "calc1"
                                    from apracyr
                                    where instr(p_activity_codes, apracyr_actc_code||',') > 0 
                                    and(    (   p_all_years = 0
                                                and instr(p_activity_years, apracyr_year||',') > 0
                                        )
                                    or p_all_years = 1
                                    )
                        and apracyr_pidm =w_constituent.person_uid
                            )   
                        or exists(  select 'X' "calc1"
                                    from apracty
                                    where instr(p_activity_codes, apracty_actc_code||',') > 0 
                                        and apracty_pidm =w_constituent.person_uid 
                            )
                )
                -----
                and(    p_all_degrees = 1
                        or instr(p_degrees, w_DEGREE_SLOT.DEGREE_1||',') >0
                        or instr(p_degrees, w_DEGREE_SLOT.DEGREE_2||',') >0
                        or instr(p_degrees, w_DEGREE_SLOT.DEGREE_3||',') >0
                )
                -----
                and(    p_all_grad_years = 1
                        or instr(p_grad_years, w_DEGREE_SLOT.ACADEMIC_YEAR_1||',') >0
                        or instr(p_grad_years, w_DEGREE_SLOT.ACADEMIC_YEAR_2||',') >0
                        or instr(p_grad_years, w_DEGREE_SLOT.ACADEMIC_YEAR_3||',') >0
                )
                -----
                and(    p_all_majors = 1
                        or instr(p_majors, w_DEGREE_SLOT.MAJOR_1||',') >0
                        or instr(p_majors, w_DEGREE_SLOT.MAJOR_2||',') >0
                        or instr(p_majors, w_DEGREE_SLOT.MAJOR_3||',') >0
                )
                -----
                and(    p_ignore_degree_dates = 1
                        or w_DEGREE_SLOT.DEGREE_DATE_1 between p_degree_date_start and p_degree_date_end
                        or w_DEGREE_SLOT.DEGREE_DATE_2 between p_degree_date_start and p_degree_date_end
                        or w_DEGREE_SLOT.DEGREE_DATE_3 between p_degree_date_start and p_degree_date_end
                )
                -----
                
        ) -- end WHERE
; -- end cursor boris

    earn_rec boris%rowtype;
    
    fhandle utl_file.file_type;
    
BEGIN
    DBMS_OUTPUT.put_line('start '||systimestamp);
    
    fhandle := utl_file.fopen(
                'U13_PROD'          
                ,'Standard Constituent ' || to_char(sysdate,'YYYY-MM-DD HH24MMSS') || '.csv'
                ,'W',
                32767
            );
    
    utl_file.put_line(fhandle,
--DBMS_OUTPUT.put_line(
            'PERSON_UID' 
            || ',' || 'ID'
            || ',' || 'NAME'
            || ',' || 'PREF_LAST_NAME'
            || ',' || 'MAIDEN_LAST_NAME'
            --|| ',' || 'SPOUSE_NAME'
            || ',' || 'RELATED_ID'
            || ',' || 'PREF_DONOR_CATEGORY'
            || ',' || 'PREF_DONOR_CATEGORY_DESC'
            || ',' || 'EMAIL_PREFERRED_ADDRESS'
            || ',' || 'STREET_LINE1'
            || ',' || 'STREET_LINE2'
            || ',' || 'CITY'
            || ',' || 'STATE_PROVINCE'
            || ',' || 'POSTAL_CODE'
            || ',' || 'COUNTY'
            || ',' || 'NATION'
            || ',' || 'ADDRESS_TYPE'
            || ',' || 'NPH'
            || ',' || 'NOC'
            || ',' || 'NMC'
            || ',' || 'NEM'
            || ',' || 'NAM'
            || ',' || 'NDN'
            || ',' || 'NAK'
            || ',' || 'NTP'
            || ',' || 'AMS'
            || ',' || 'PREFERRED_FULL_W_SALUTATION'
            || ',' || 'PREFERRED_SHORT_W_SALUTATION'
            || ',' || 'SIFE'
            || ',' || 'SIFL'
            || ',' || 'RATING_TYPE1'
            || ',' || 'RATING_AMOUNT1'
            || ',' || 'RATING1'
            || ',' || 'RATING_LEVEL1'
            || ',' || 'RATING_TYPE2'
            || ',' || 'RATING_AMOUNT2'
            || ',' || 'RATING2'
            || ',' || 'RATING_LEVEL2'
            || ',' || 'RATING_TYPE3'
            || ',' || 'RATING_AMOUNT3'
            || ',' || 'RATING3'
            || ',' || 'RATING_LEVEL3'
            || ',' || 'MEMBERSHIP_NAME'
            || ',' || 'MEMBERSHIP_STATUS'
            || ',' || 'MEMBERSHIP_NUMBER'
            || ',' || 'EXPIRATION_DATE'
            || ',' || 'WON_Membership_name'
            || ',' || 'WON_MEMBERSHIP_STATUS'
            || ',' || 'WON_MEMBERSHIP_NUMBER'
            || ',' || 'WON_expiration_date'
            || ',' || 'FAN_MEMBERSHIP_NAME'
            || ',' || 'FAN_MEMBERSHIP_STATUS'
            || ',' || 'FAN_membership_number'
            || ',' || 'FAN_EXPIRATION_DATE'
            || ',' || 'PERS_EMAIL'
            || ',' || 'NSU_EMAIL'
            || ',' || 'AL_EMAIL'
            || ',' || 'BUS_EMAIL'
            || ',' || 'PR_PHONE_NUMBER'
            || ',' || 'PR_PRIMARY_IND'
            || ',' || 'CL_PHONE_NUMBER'
            || ',' || 'CL_PRIMARY_IND'
            || ',' || 'B1_PHONE_NUMBER'
            || ',' || 'B1_PRIMARY_IND'
            || ',' || 'TOTAL_PLEDGE_PAYMENTS1'
            || ',' || 'LIFE_TOTAL_GIVING'
            || ',' || 'LIFE_TOTAL_GIVING_AUX'
            || ',' || 'FISCAL_YEAR1'
            || ',' || 'TOTAL_GIVING1'
            || ',' || 'ANNUAL_HOUSEHOLD_GIVING'
            || ',' || 'LIFETIME_HOUSEHOLD_GIVING'
            || ',' || 'RELATION_SOURCE'
            || ',' || 'RELATION_SOURCE_DESC'
            || ',' || 'COMBINED_MAILING_PRIORITY'
            || ',' || 'COMBINED_MAILING_PRIORITY_DESC'
            || ',' || 'HOUSEHOLD_IND'
            || ',' || 'DATE_RANGE_TOTAL_GIVING'
            || ',' || 'DATE_RANGE_TOTAL_AUX_AMT'
            || ',' || 'DEGREE_1'
            || ',' || 'DEGREE_DESC_1'
            || ',' || 'ACADEMIC_YEAR_1'
            || ',' || 'MAJOR_1'
            || ',' || 'MAJOR_DESC_1'
            || ',' || 'DEGREE_2'
            || ',' || 'DEGREE_DESC_2'
            || ',' || 'ACADEMIC_YEAR_2'
            || ',' || 'MAJOR_2'
            || ',' || 'MAJOR_DESC_2'
            || ',' || 'DEGREE_3'
            || ',' || 'DEGREE_DESC_3'
            || ',' || 'ACADEMIC_YEAR_3' 
            || ',' || 'MAJOR_3'
            || ',' || 'MAJOR_DESC_3'
            || ',' || 'SPEC_PURPOSE_TYPE_GROUP'
            || ',' || 'TOTAL_NO_GIFTS'
            || ',' || 'HIGH_GIFT_AMT'
            || ',' || 'LAST_GIFT_DATE'
            || ',' || 'DECEASED_IND'
            || ',' || 'DATE_OF_BIRTH'
            || ',' || 'JFSG_ESTIMATED_CAPACITY'
            || ',' || 'DED_AMT_W_YTD_1'
            || ',' || 'DED_AMT_W_YTD_2'
            || ',' || 'DED_AMT_W_YTD_3'
            || ',' || 'DED_AMT_W_YTD_4'
            || ',' || 'EMPLOYER'
            || ',' || 'POSITION'
            || ',' || 'VETERAN_IND'
            || ',' || 'GURIDEN_DESC'
            || ',' || 'LONGEST_CONS_YEARS_GIVEN'
            || ',' || 'RECENT_CONSECUTIVE_YEARS'
            );
            
    FOR earn_rec
    IN boris
    LOOP
--        DBMS_OUTPUT.put_line(earn_rec.person_uid);
--        utl_file.put_line(fhandle,'rec: ' || p_record_count);
--        dbms_output.put_line('rec: ' || p_record_count);
--        'All work and no play makes Jack a dull boy.'
--DBMS_OUTPUT.put_line(
        UTL_FILE.PUT_LINE(fhandle,
            earn_rec.PERSON_UID
            || ',' || earn_rec.ID
            || ',' || CHR(34) || earn_rec.NAME || CHR(34)
            || ',' || CHR(34) || earn_rec.PREF_LAST_NAME || CHR(34) 
            || ',' || CHR(34) || earn_rec.MAIDEN_LAST_NAME || CHR(34) 
            --|| ',' || CHR(34) || earn_rec.SPOUSE_NAME || CHR(34) 
            || ',' || earn_rec.related_id
            || ',' || CHR(34)  || earn_rec.PREF_DONOR_CATEGORY || CHR(34) 
            || ',' || CHR(34)  || earn_rec.PREF_DONOR_CATEGORY_DESC || CHR(34) 
            || ',' || CHR(34)  || earn_rec.EMAIL_PREFERRED_ADDRESS || CHR(34) 
            || ',' || CHR(34)  || earn_rec.STREET_LINE1 || CHR(34) 
            || ',' || CHR(34)  || earn_rec.STREET_LINE2 || CHR(34) 
            || ',' || CHR(34)  || earn_rec.CITY || CHR(34) 
            || ',' || CHR(34)  || earn_rec.STATE_PROVINCE || CHR(34) 
            || ',' || CHR(34)  || earn_rec.POSTAL_CODE || CHR(34) 
            || ',' || CHR(34)  || earn_rec.COUNTY || CHR(34) 
            || ',' || CHR(34)  || earn_rec.NATION || CHR(34) 
            || ',' || earn_rec.ADDRESS_TYPE
            || ',' || earn_rec.nph
            || ',' || earn_rec.noc
            || ',' || earn_rec.nmc
            || ',' || earn_rec.nem
            || ',' || earn_rec.nam
            || ',' || earn_rec.ndn
            || ',' || earn_rec.nak
            || ',' || earn_rec.ntp
            || ',' || earn_rec.ams
            || ',' || CHR(34) || earn_rec.PREFERRED_FULL_w_SALUTATION || CHR(34)
            || ',' || CHR(34) || earn_rec.PREFERRED_SHORT_w_SALUTATION || CHR(34)
            || ',' || CHR(34) || earn_rec.SIFE || CHR(34)
            || ',' || CHR(34) || earn_rec.SIFL || CHR(34)
            || ',' || earn_rec.rating_type1
            || ',' || earn_rec.rating_amount1
            || ',' || earn_rec.rating1
            || ',' || earn_rec.rating_level1
            || ',' || earn_rec.rating_type2
            || ',' || earn_rec.rating_amount2
            || ',' || earn_rec.rating2
            || ',' || earn_rec.rating_level2
            || ',' || earn_rec.rating_type3
            || ',' || earn_rec.rating_amount3
            || ',' || earn_rec.rating3
            || ',' || earn_rec.rating_level3
            || ',' || earn_rec.Membership_Name
            || ',' || earn_rec.Membership_Status
            || ',' || earn_rec.membership_number
            || ',' || earn_rec.expiration_date
            || ',' || earn_rec.w_WON_Membership_name
            || ',' || earn_rec.w_WON_Membership_status
            || ',' || earn_rec.w_WON_membership_number
            || ',' || earn_rec.WON_expiration_date
            || ',' || earn_rec.w_FAN_Membership_name
            || ',' || earn_rec.w_FAN_Membership_status
            || ',' || earn_rec.w_FAN_membership_number
            || ',' || earn_rec.FAN_expiration_date
            || ',' || earn_rec.pers_email
            || ',' || earn_rec.nsu_email
            || ',' || earn_rec.al_email
            || ',' || earn_rec.bus_email
            || ',' || earn_rec.pr_phone_number
            || ',' || earn_rec.pr_primary_ind
            || ',' || earn_rec.cl_phone_number
            || ',' || earn_rec.cl_primary_ind
            || ',' || earn_rec.b1_phone_number
            || ',' || earn_rec.b1_primary_ind
            || ',' || earn_rec.TOTAL_PLEDGE_PAYMENTS1
            || ',' || earn_rec.LIFE_TOTAL_GIVING
            || ',' || earn_rec.LIFE_TOTAL_GIVING_AUX
            || ',' || earn_rec.fiscal_year1
            || ',' || earn_rec.TOTAL_GIVING1
            || ',' || earn_rec.ANNUAL_HOUSEHOLD_GIVING
            || ',' || earn_rec.LIFETIME_HOUSEHOLD_GIVING            
            || ',' || earn_rec.relation_source
            || ',' || earn_rec.relation_source_desc
            || ',' || earn_rec.combined_mailing_priority
            || ',' || earn_rec.combined_mailing_priority_desc
            || ',' || earn_rec.household_ind
            || ',' || earn_rec.DATE_RANGE_TOTAL_GIVING
            || ',' || earn_rec.DATE_RANGE_TOTAL_AUX_AMT
            || ',' || earn_rec.degree_1
            || ',' || CHR(34) || earn_rec.degree_desc_1 || CHR(34) 
            || ',' || earn_rec.academic_year_1
            || ',' || CHR(34) || earn_rec.major_1 || CHR(34) 
            || ',' || CHR(34) || earn_rec.major_desc_1 || CHR(34) 
            || ',' || earn_rec.degree_2
            || ',' || CHR(34) || earn_rec.degree_desc_2 || CHR(34) 
            || ',' || earn_rec.academic_year_2
            || ',' || CHR(34) || earn_rec.major_2 || CHR(34) 
            || ',' || CHR(34) || earn_rec.major_desc_2|| CHR(34) 
            || ',' || earn_rec.degree_3
            || ',' || CHR(34) || earn_rec.degree_desc_3 || CHR(34) 
            || ',' || earn_rec.academic_year_3 
            || ',' || CHR(34) || earn_rec.major_3 || CHR(34) 
            || ',' || CHR(34) || earn_rec.major_desc_3 || CHR(34) 
            || ',' || earn_rec.SPEC_PURPOSE_TYPE_GROUP
            || ',' || earn_rec.total_no_gifts
            || ',' || earn_rec.high_gift_amt
            || ',' || earn_rec.last_gift_date
            || ',' || earn_rec.DECEASED_IND
            || ',' || earn_rec.date_of_birth
            || ',' || earn_rec.JFSG_estimated_capacity
            || ',' || earn_rec.DED_AMT_w_YTD_1
            || ',' || earn_rec.DED_AMT_w_YTD_2
            || ',' || earn_rec.DED_AMT_w_YTD_3
            || ',' || earn_rec.DED_AMT_w_YTD_4
            || ',' || CHR(34) || earn_rec.employer || CHR(34) 
            || ',' || CHR(34) || earn_rec.position || CHR(34) 
            || ',' || earn_rec.Veteran_ind
            || ',' || earn_rec.guriden_desc
            || ',' || earn_rec.longest_cons_years_given
            || ',' || earn_rec.recent_consecutive_years
--              , TRUE -- autoflush
              );
                
        p_record_count := p_record_count + 1;
        
--        IF MOD(p_record_count,10) = 0 THEN
--            utl_file.fflush(fhandle);
--        END IF;
        
    END LOOP;
    
  --  DBMS_OUTPUT.put_line('end '|| p_record_count || ' ' ||systimestamp);
    --utl_file.put(fhandle, 'end '|| p_record_count || ' ' ||systimestamp);
    
--    utl_file.fflush(fhandle);
    utl_file.fclose(fhandle);
    exception
        when others then
            dbms_output.put_line('ERROR: ' || SQLCODE 
                      || ' - ' || SQLERRM);
  --          raise;
END;        