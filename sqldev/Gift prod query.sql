
WITH w_spriden AS(
                SELECT
                    spriden_pidm
                    ,spriden_id
                    ,spriden_last_name
                    ,spriden_first_name
                    ,spriden_mi
                    ,spriden_entity_ind
                FROM
                    spriden
                WHERE
                    spriden_change_ind is null
)
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
        ) -- end w_address
        
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
        , w_sprtele AS(
            SELECT /*+ MATERIALIZE */
                sprtele_pidm
                , sprtele_phone_area
                , sprtele_phone_number
                , sprtele_phone_ext
                , sprtele_intl_access
                , sprtele_primary_ind
                , sprtele_seqno
                , sprtele_status_ind
                , sprtele_tele_code
            FROM
                sprtele
            WHERE 
                sprtele_status_ind IS NULL
                AND sprtele_tele_code IN('PR','CL','B1')
        )
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
                        from w_sprtele where sprtele_status_ind is null AND sprtele_tele_code = 'PR'
                    ) where rn = 1) PR
                        ON sprtele.sprtele_pidm = pr.sprtele_pidm
                    FULL JOIN
                    (select sprtele_pidm, nvl(sprtele_phone_area||sprtele_phone_number||sprtele_phone_ext,sprtele_intl_access) phone, sprtele_primary_ind from
                        (select sprtele_pidm, sprtele_phone_area, sprtele_phone_number, sprtele_phone_ext, sprtele_intl_access, sprtele_primary_ind, sprtele_seqno, row_number() over (partition by sprtele_pidm, sprtele_tele_code order by sprtele_seqno desc) rn
                        from w_sprtele where sprtele_status_ind is null AND sprtele_tele_code = 'CL'
                    ) where rn = 1) CL
                        ON sprtele.sprtele_pidm = cl.sprtele_pidm        
                    FULL JOIN
                    (select sprtele_pidm, nvl(sprtele_phone_area||sprtele_phone_number||sprtele_phone_ext,sprtele_intl_access) phone, sprtele_primary_ind from
                        (select sprtele_pidm, sprtele_phone_area, sprtele_phone_number, sprtele_phone_ext, sprtele_intl_access, sprtele_primary_ind, sprtele_seqno, row_number() over (partition by sprtele_pidm, sprtele_tele_code order by sprtele_seqno desc) rn
                        from w_sprtele where sprtele_status_ind is null AND sprtele_tele_code = 'B1'
                    ) where rn = 1) B1
                        ON sprtele.sprtele_pidm = b1.sprtele_pidm
                )
            WHERE
                LENGTH(pr_phone_number||pr_primary_ind
                    ||cl_phone_number||cl_primary_ind
                    ||b1_phone_number||cl_primary_ind) IS NOT NULL
        ) -- end w_nsu_telephone_slot
        
        , w_goremal AS(
            SELECT  /*+ MATERIALIZE */
                goremal_pidm
                , goremal_email_address
                , goremal_activity_date
                , goremal_status_ind
                , goremal_emal_code
            FROM
                goremal
            WHERE
                goremal_status_ind = 'A'
                AND goremal_emal_code IN ('PERS','NSU','AL','BUS','OT','VEND')
        
        )
        , w_nsu_email_slot AS(
            SELECT * FROM(
                SELECT
                    goremal.goremal_pidm ENTITY_UID
                    , pers.goremal_email_address PERS_EMAIL
                    , nsu.goremal_email_address NSU_EMAIL
                    , al.goremal_email_address AL_EMAIL
                    , bus.goremal_email_address BUS_EMAIL
                    , ot.goremal_email_address OT_EMAIL
                    , vend.goremal_email_address VEND_EMAIL
                FROM
                    (select distinct goremal_pidm from goremal) GOREMAL
                    FULL JOIN
                    (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from w_goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'PERS'
                    ) where rn = 1) PERS
                        ON goremal.goremal_pidm = pers.goremal_pidm
                    FULL JOIN
                        (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from w_goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'NSU'
                    ) where rn = 1) NSU 
                        ON goremal.goremal_pidm = nsu.goremal_pidm
                    FULL JOIN
                        (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from w_goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'AL'
                    ) where rn = 1) AL
                        ON goremal.goremal_pidm = al.goremal_pidm
                    FULL JOIN
                        (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from w_goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'BUS'
                    ) where rn = 1) BUS
                        ON goremal.goremal_pidm = bus.goremal_pidm
                    FULL JOIN
                        (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from w_goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'VEND'
                    ) where rn = 1) VEND
                        ON goremal.goremal_pidm = vend.goremal_pidm
                    FULL JOIN
                        (select goremal_pidm, goremal_email_address from
                        (select goremal_pidm, goremal_email_address, goremal_activity_date, row_number() over (partition by goremal_pidm, goremal_emal_code order by goremal_activity_date desc) rn
                        from w_goremal where goremal_status_ind = 'A' AND goremal_emal_code = 'OT'
                    ) where rn = 1) OT
                        ON goremal.goremal_pidm = ot.goremal_pidm
            )        
            WHERE LENGTH(PERS_EMAIL||NSU_EMAIL||AL_EMAIL||BUS_EMAIL||OT_EMAIL||VEND_EMAIL) IS NOT NULL
        ) -- end w_nsu_email_slot
        
    , w_gift_association_details AS(
        SELECT 
            agrgasc_gift_no
            , agrgasc_pidm
            , LISTAGG(  agrgasc_assc_code
                        ||'/'||spriden_id
                    ,', ') WITHIN GROUP (order by agrgasc_assc_code)
                AS ASSOCIATION_DETAILS
        FROM
            agrgasc
            JOIN w_spriden
                ON agrgasc_assc_pidm = w_spriden.spriden_pidm
            
        GROUP BY agrgasc_gift_no,agrgasc_pidm
    ) -- end w_gift_association_details
    , w_special_groups AS(
        SELECT
            aprpros_pidm
            , LISTAGG(  aprpros_prtp_code
                        || '-' || atvprtp_desc 
                        || '/' || aprpros_prcd_code
                        || '-' || atvprcd_desc
                    ,',') WITHIN GROUP (ORDER BY aprpros_prtp_code)
                AS GROUPS_DETAILS
        FROM
            aprpros
            JOIN atvprtp
                ON aprpros_prtp_code = atvprtp_code
            JOIN atvprcd
                ON aprpros_prcd_code = atvprcd_code
        GROUP BY aprpros_pidm
    ) -- end w_special_groups
    
        ,  w_pref_donor_cat AS(
            SELECT 
                aprcatg_pidm
                , aprcatg_donr_code PREF_DONOR_CATEGORY
                , atvdonr_desc      PREF_DONOR_CATEGORY_DESC

            FROM(
                    SELECT
                        aprcatg_pidm
                        , aprcatg_donr_code
                        , atvdonr_desc, row_number() OVER (PARTITION BY aprcatg_pidm ORDER BY atvdonr_rpt_seq_ind) rn
                    FROM
                        aprcatg
                        JOIN atvdonr
                            ON aprcatg_donr_code = atvdonr_code
                )  
            WHERE rn = 1
        ) --end w_pref_donor_cat  
        
       ,   w_spouse AS(
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
                agbgift_pidm        PERSON_UID
                , spriden_id        ID
                , f_format_name(agbgift_pidm,'LFMI')    NAME
--                , apbcons_pref_last_name    PREF_LAST_NAME
--                , apbcons_maiden_last_name  MAIDEN_LAST_NAME
                , w_spouse.spouse_uid   SPOUSE_UID
--                , aprcsps_spouse_name SPOUSE_NAME
                , aprcatg_donr_code PREF_DONOR_CATEGORY
                , atvdonr_desc      PREF_DONOR_CATEGORY_DESC
--                , goremal_email_address EMAIL_PREFERRED_ADDRESS
              --  , w_lifetime_giving.lifetime_giving LIFE_TOTAL_GIVING
                , nvl(spbpers_dead_ind,'N') DECEASED_IND 
            FROM
--                apbcons 
                (select distinct agbgift_pidm from agbgift)
                JOIN spriden
                    ON agbgift_pidm = spriden_pidm
                    AND spriden_change_ind IS NULL
--                    and  f_format_name(agbgift_pidm,'LFMI') NOT LIKE '%DO%NOT%USE%'
--                    AND apbcons_pidm NOT IN (SELECT bad_pidm FROM nsudev.nsu_alum_pidm WHERE bad_pidm = apbcons_pidm)
--                    AND apbcons_pidm NOT IN (SELECT aprcatg_pidm FROM aprcatg WHERE aprcatg_pidm = apbcons_pidm AND aprcatg_donr_code = 'BAD') 
                JOIN(   SELECT spbpers_pidm, spbpers_dead_ind
                        FROM spbpers
                    )
                    ON  agbgift_pidm = spbpers_pidm 
                LEFT JOIN(
                        SELECT aprcatg_pidm, aprcatg_donr_code, atvdonr_desc, row_number() OVER (PARTITION BY aprcatg_pidm ORDER BY atvdonr_rpt_seq_ind) rn
                        FROM aprcatg JOIN atvdonr ON aprcatg_donr_code = atvdonr_code
                )   ON aprcatg_pidm = agbgift_pidm
                    AND rn = 1
--                LEFT JOIN (
--                        SELECT  
--                            goremal_pidm
--                            , goremal_email_address
--                            ,row_number() over (partition by goremal_pidm order by goremal_pidm) rn
--                        FROM goremal
--                        WHERE --goremal_pidm = 166910
--                            goremal_status_ind = 'A'
--                            AND goremal_preferred_ind = 'Y'
--                        ) goremal
--                    ON goremal_pidm = apbcons_pidm
--                    AND goremal.rn = 1

                LEFT JOIN w_spouse
                    ON agbgift_pidm = w_spouse.person_uid
--                left join w_lifetime_giving
--                    on apbcons_pidm = w_lifetime_giving.person_uid

        ) --end w_constituent
-- select * from w_constituent;

/*        , w_annual_gifts AS(
            select coalesce(gift_pidm,aux_pidm,soft_pidm) ENTITY_UID
                , coalesce(gift_year,aux_year,soft_year) YEAR
                , nvl(gift_amt,0) GIFT_AMT
                , nvl(aux_amt,0) AUX_AMT
                , nvl(soft_amt,0) SOFT_AMT
            from (
                select
                    --agbgift.*
                     agbgift_pidm gift_pidm
                    , extract(year from AGBGIFT_GIFT_DATE) gift_year
                    , nvl(agrgdes_amt,0) gift_amt
                    , aux_pidm
                    , aux_year
                    , aux_amt
                    , soft_pidm
                    , soft_year
                    , soft_amt
                from
                    agbgift 
                    join agrgdes
                        on agbgift_pidm = agrgdes_pidm
                        and agbgift_gift_no = agrgdes_gift_no
                
                full join (
                    select 
                        agrgaux_pidm aux_pidm
                        , extract(year from AGRGAUX_AUXL_VALUE_DATE) aux_year
                        , nvl(AGRGAUX_DCPR_VALUE,0) aux_amt
                    from
                        AGRGAUX
               )    on agbgift_pidm = aux_pidm
                    and extract(year from AGBGIFT_GIFT_DATE) = aux_year
        
                full join (
                    select 
                        agrgmmo_pidm soft_pidm
                        , extract(year from AGBGIFT_GIFT_DATE) soft_year
                        , nvl(AGRGMMO_CREDIT,0) soft_amt
                    from 
                        agbgift
                        join agrgmmo
                            on agbgift_pidm = agrgmmo_pidm
                            and agbgift_gift_no = agrgmmo_gift_no
                )   on agbgift_pidm = soft_pidm --agrgmmo_pidm
                    and extract(year from AGBGIFT_GIFT_DATE) = soft_year
            ) -- end of from

        ) -- end w_annual_gifts

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
                        , SUM(  CASE WHEN w_annual_gifts.year = EXTRACT(YEAR FROM sysdate) THEN nvl(w_annual_gifts.gift_amt,0) ELSE 0 END) 
                            OVER (PARTITION BY w_annual_gifts.entity_uid) ANNUAL_GIFT_AMOUNT
                        , SUM(nvl(w_annual_gifts.gift_amt,0)) OVER (PARTITION BY w_annual_gifts.entity_uid) LIFETIME_GIFT_AMOUNT
                    FROM
                        w_constituent -- plus w_annual_gifts
                        JOIN w_annual_gifts
                            ON w_constituent.person_uid = w_annual_gifts.entity_uid
                            --AND w_annual_gifts.gift_year = EXTRACT(YEAR FROM SYSDATE)
            ) DONOR_GIFTS
                LEFT JOIN(  SELECT
                                w_constituent.person_uid PERSON_UID
                                , SUM(  CASE WHEN w_annual_gifts.year = EXTRACT(YEAR FROM sysdate) THEN NVL(w_annual_gifts.gift_amt,0) ELSE 0 END)
                                    OVER (PARTITION BY w_annual_gifts.entity_uid) ANNUAL_GIFT_AMOUNT
                                , SUM(NVL(w_annual_gifts.gift_amt,0)) OVER (PARTITION BY w_annual_gifts.entity_uid) LIFETIME_GIFT_AMOUNT
                            FROM
                                w_constituent
                                JOIN w_spouse
                                    ON w_constituent.person_uid = w_spouse.person_uid
                                JOIN w_annual_gifts
                                    ON w_spouse.spouse_uid = w_annual_gifts.entity_uid
                                    --AND w_annual_gifts.gift_year = EXTRACT(YEAR FROM SYSDATE)
                    ) SPOUSE_GIFTS ON donor_gifts.person_uid = spouse_gifts.person_uid

            ) -- and w_household_giving 
*/
        , w_giving_history AS(
            SELECT
                person_uid
                ,spouse_uid
                ,nvl((select sum(nvl(agrgdes_amt,0))
                from agbgift join agrgdes on agbgift_pidm = agrgdes_pidm and agbgift_gift_no = agrgdes_gift_no 
                where agbgift_pidm = w_constituent.person_uid
                ),0) -- person_lifetime
                +
                nvl((select sum(nvl(agrgdes_amt,0))
                from agbgift join agrgdes on agbgift_pidm = agrgdes_pidm and agbgift_gift_no = agrgdes_gift_no 
                where agbgift_pidm = w_constituent.spouse_uid
                ),0) -- spouse_lifetime
                as LIFETIME_HH_GIVING
                
                ,nvl((select sum(nvl(agrgdes_amt,0))
                from agbgift join agrgdes on agbgift_pidm = agrgdes_pidm and agbgift_gift_no = agrgdes_gift_no 
                where agbgift_pidm = w_constituent.person_uid
                and extract(year from agbgift_gift_date) = extract(year from sysdate)
                ),0) -- person_annual 
                +
                nvl((select sum(nvl(agrgdes_amt,0))
                from agbgift join agrgdes on agbgift_pidm = agrgdes_pidm and agbgift_gift_no = agrgdes_gift_no 
                where agbgift_pidm = w_constituent.spouse_uid
                and extract(year from agbgift_gift_date) = extract(year from sysdate)
                ),0) -- spouse_annual
                as ANNUAL_HH_GIVING
                
                ,nvl((select sum(nvl(agrgdes_amt,0))
                from agbgift join agrgdes on agbgift_pidm = agrgdes_pidm and agbgift_gift_no = agrgdes_gift_no 
                where agbgift_pidm = w_constituent.person_uid
                and extract(year from agbgift_gift_date) = extract(year from sysdate) -1
                ),0) 
                +
                nvl((select sum(nvl(agrgdes_amt,0))
                from agbgift join agrgdes on agbgift_pidm = agrgdes_pidm and agbgift_gift_no = agrgdes_gift_no 
                where agbgift_pidm = w_constituent.spouse_uid
                and extract(year from agbgift_gift_date) = extract(year from sysdate) -1
                ),0) 
                as PREV_YR_ANNUAL_HH_GIVING
                
                ,nvl((select sum(nvl(agrgaux_dcpr_value,0))
                from agrgaux
                where agrgaux_pidm = w_constituent.person_uid
                and extract(year from agrgaux_auxl_value_date) = extract(year from sysdate) -1
                ),0) 
                +
                nvl((select sum(nvl(agrgaux_dcpr_value,0))
                from agrgaux
                where agrgaux_pidm = w_constituent.spouse_uid
                and extract(year from agrgaux_auxl_value_date) = extract(year from sysdate) -1
                ),0) 
                as PREV_YR_ANNUAL_HH_AUX_GIVING
                
                ,nvl((select sum(nvl(agrgmmo_credit,0))
                from agbgift join agrgmmo on agbgift_pidm = agrgmmo_pidm and agbgift_gift_no = agrgmmo_gift_no
                where agbgift_pidm = w_constituent.person_uid
                and extract(year from agbgift_gift_date) = extract(year from sysdate) -1
                ),0) 
                +
                nvl((select sum(nvl(agrgmmo_credit,0))
                from agbgift join agrgmmo on agbgift_pidm = agrgmmo_pidm and agbgift_gift_no = agrgmmo_gift_no
                where agbgift_pidm = w_constituent.spouse_uid
                and extract(year from agbgift_gift_date) = extract(year from sysdate) -1
                ),0) 
                as PREV_YR_ANNUAL_HH_SOFT_GIVING
                
                ,nvl((select sum(nvl(agrgdes_amt,0))
                from agbgift join agrgdes on agbgift_pidm = agrgdes_pidm and agbgift_gift_no = agrgdes_gift_no 
                where agbgift_pidm = w_constituent.person_uid
                and agbgift_gift_code in ('GC','GK','PR')
                and agrgdes_campaign = 'LTW'
                and agbgift_gift_date between :parm_DT_Gift_Start and :parm_DT_Gift_End
                ),0) -- person_annual 
                +
                nvl((select sum(nvl(agrgdes_amt,0))
                from agbgift join agrgdes on agbgift_pidm = agrgdes_pidm and agbgift_gift_no = agrgdes_gift_no 
                where agbgift_pidm = w_constituent.spouse_uid
                and agbgift_gift_code in ('GC','GK','PR')
                and agrgdes_campaign = 'LTW'
                and agbgift_gift_date between :parm_DT_Gift_Start and :parm_DT_Gift_End
                ),0) -- spouse_annual
                as HH_GIK

                
            
            FROM w_constituent        
        )   -- end w_giving_history
            
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
        
        , w_ytd AS(
            SELECT
                entity_uid
                , SUM(CASE WHEN year_pos = 1 THEN tots END) YTD
                , SUM(CASE WHEN year_pos = 2 THEN tots END) YTD_1
                , SUM(CASE WHEN year_pos = 3 THEN tots END) YTD_2
                , SUM(CASE WHEN year_pos = 4 THEN tots END) YTD_3
                , SUM(CASE WHEN year_pos = 5 THEN tots END) YTD_4
                , SUM(CASE WHEN year_pos = 6 THEN tots END) YTD_5
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
                CONNECT BY LEVEL <= 6
            )
            ON year = gift_date
        GROUP BY entity_uid
        ) -- end w_ytd
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
                WHERE AGBGIFT_FISC_CODE <= TO_CHAR(TO_DATE(:parm_DT_Gift_End), 'YYYY')
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
                WHERE AGBGIFT_FISC_CODE <= TO_CHAR(TO_DATE(:parm_DT_Gift_End), 'YYYY')
                CONNECT BY PRIOR spriden_pidm = spriden_pidm
                    AND PRIOR agbgift_fisc_code = agbgift_fisc_code -1
            )
            GROUP BY spriden_pidm
        ) -- end w_recent_cons_years;
        , w_total_years AS(
            SELECT
                agbgift_pidm PERSON_UID
                , COUNT(DISTINCT agbgift_fisc_code) TOTAL_NUMBER_OF_YEARS_GIVEN
            FROM agbgift
            GROUP BY agbgift_pidm
        )
            
    , w_gift AS(
    SELECT 
        agbgift_pidm            ENTITY_UID
        , w_constituent.id      ID
        , w_constituent.name    NAME
        , w_constituent.deceased_ind    DECEASED_STATUS
        , w_address.spraddr_street_line1    STREET_LINE1
        , w_address.spraddr_street_line2    STREET_LINE2
        , w_address.spraddr_city            CITY
        , w_address.spraddr_stat_code       STATE
        , w_address.spraddr_zip             ZIP_CODE
        , w_address.spraddr_atyp_code       ADDRESS_TYPE
        , apbcons_pref_clas PREFER_CLASS_YEAR
        , agbgift_gift_date GIFT_DATE
        , '"'||agrgdes_gift_no||'"' GIFT_NUMBER
        , agrgsol_solc_code SOLICITATION_TYPE
        , agbgift_pgve_code GIFT_VEHICLE
        , atvpgve_desc      GIFT_VEHICLE_DESC
        , agbgift_gift_code GIFT_TYPE
        , agbgift_gcls_code GIFT_CLASS
        , agbgift_gcls_code_2   GIFT_CLASS2
        , agbgift_gcls_code_3   GIFT_CLASS3
        , NVL2(agbgift_comment, '"'||agbgift_comment||'"', agbgift_comment) GIFT_COMMENT
        , afbcamp_name  CAMPAIGN_NAME
        , agrgdes_desg  DESIGNATION 
        , adbdesg_name  DESIGNATION_NAME
        , agrgdes_amt   GIFT_AMOUNT
        , TRIM(TO_CHAR(agrgaux_dcpr_value, '999999990.99')) AUXILIARY_VALUE
        , NVL(agrgaux_deduct_for_taxes,'N') DEDUCT_FOR_TAXES_IND        

        , nvl(w_SALUTATION.CIFE,w_SALUTATION.SIFE)  PREFERRED_FULL_w_SALUTATION
        , nvl(w_SALUTATION.CIFL,w_SALUTATION.SIFL)  PREFERRED_SHORT_w_SALUTATION
        , w_SALUTATION.SIFE SIFE
        , w_SALUTATION.SIFL SIFL

        , w_nsu_telephone_slot.pr_phone_number  PR_PHONE_NUMBER
        , w_nsu_telephone_slot.pr_primary_ind   PR_PRIMARY_IND
        , w_nsu_telephone_slot.cl_phone_number  CL_PHONE_NUMBER
        , w_nsu_telephone_slot.cl_primary_ind   CL_PRIMARY_IND
        , w_nsu_telephone_slot.b1_phone_number  B1_PHONE_NUMBER
        , w_nsu_telephone_slot.b1_primary_ind   B1_PRIMARY_IND  

        , w_nsu_email_slot.pers_email   PERS_EMAIL
        , w_nsu_email_slot.nsu_email    NSU_EMAIL
        , w_nsu_email_slot.al_email     AL_EMAIL
        , w_nsu_email_slot.bus_email    BUS_EMAIL
        , w_nsu_email_slot.vend_email   VEND_EMAIL
        , w_nsu_email_slot.ot_email     OT_EMAIL
        , gift_memo_details
        , w_gift_association_details.association_details GIFT_ASSOC_ENTITY_DTLS
        , w_special_groups.groups_details   SPECIAL_PURPOSE_INFO
        , '"'||agrgdes_pledge_no||'"'   PLEDGE_NUMBER
        --, w_pref_donor_cat.pref_donor_category  DONOR_CATEGORY
        , w_constituent.pref_donor_category
        --, w_pref_donor_cat.pref_donor_category_desc DONOR_CATEGORY_DES
        , w_constituent.pref_donor_category_desc
        
--       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'LIFETIME') "LIFETIME_HH_GIVING",
        , TRIM(TO_CHAR(NVL(w_giving_history.lifetime_hh_giving,0), '999999990.99')) LIFETIME_HH_GIVING
        
--       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'ANNUAL') "ANNUAL_HH_GIVING",
        , TRIM(TO_CHAR(NVL(w_giving_history.annual_hh_giving,0), '999999990.99')) ANNUAL_HH_GIVING

--       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'ANNUAL-1') "PREV_YR_ANNUAL_HH_GIVING",
        , TRIM(TO_CHAR(NVL(w_giving_history.prev_yr_annual_hh_giving,0), '999999990.99')) PREV_YR_ANNUAL_HH_GIVING
        
--       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'ANNUAL-1_AUX') "PREV_YR_ANNUAL_HH_AUX_GIVING",
        , TRIM(TO_CHAR(NVL(w_giving_history.prev_yr_annual_hh_aux_giving,0), '999999990.99')) PREV_YR_ANNUAL_HH_AUX_GIVING
        
--       NSUDEV.NSU_GET_HOUSEHOLD_GIVING_TOTAL(GIFT.ENTITY_UID, 'ANNUAL-1_SOFT') "PREV_YR_ANNUAL_HH_SOFT_GIVING",
        , TRIM(TO_CHAR(NVL(w_giving_history.prev_yr_annual_hh_soft_giving,0), '999999990.99')) PREV_YR_ANNUAL_HH_SOFT_GIVING
        
        , TRIM(TO_CHAR(NVL(w_giving_history.hh_gik,0), '999999990.99')) HH_GIK

        , w_relationship.relation_source    RELATION_SOURCE
        , w_relationship.relation_source_desc   RELATION_SOURCE_DESC
        , w_relationship.combined_mailing_priority  COMBINED_MAILING_PRIORITY
        , w_relationship.combined_mailing_priority_desc COMBINED_MAILING_PRIORITY_DESC	
        
        , w_nsu_exclusion_slot.nph NPH
        , w_nsu_exclusion_slot.noc NOC
        , w_nsu_exclusion_slot.nmc NMC
        , w_nsu_exclusion_slot.nem NEM
        , w_nsu_exclusion_slot.nam NAM
        , w_nsu_exclusion_slot.ndn NDN
        , w_nsu_exclusion_slot.nak NAK
        , w_nsu_exclusion_slot.ntp NTP
        , w_nsu_exclusion_slot.ams AMS
        
        , prospect_info.prospect_status PROSPECT_STATUS
        , prospect_info.prospect_status_desc PROSPECT_STATUS_DESC
        , prospect_info.prospect_amount  PROSPECT_AMOUNT
        
        , jfsgd_rating.rating   JFSG_ESTIMATED_CAPACITY	
        
        , nvl(w_ytd.ytd,0) ded_amt_ytd
        , nvl(w_ytd.ytd_1,0) DED_AMT_YTD_1
        , nvl(w_ytd.ytd_2,0) DED_AMT_YTD_2
        , nvl(w_ytd.ytd_3,0) DED_AMT_YTD_3
        , nvl(w_ytd.ytd_4,0) DED_AMT_YTD_4
        , nvl(w_ytd.ytd_5,0) DED_AMT_YTD_5

        , w_total_years.total_number_of_years_given TOTAL_NUMBER_OF_YEARS_GIVEN
        , w_long_years_given.recent_consecutive_years LONGEST_CONS_YEARS_GIVEN
        , w_recent_cons_years.recent_consecutive_years RECENT_CONSECUTIVE_YEARS
        
    FROM
        agbgift
        LEFT JOIN w_constituent
            ON agbgift_pidm = w_constituent.person_uid
        
        LEFT JOIN atvpgve
            ON agbgift_pgve_code = atvpgve_code
            
        JOIN agrgdes
            ON agbgift_pidm = agrgdes_pidm
            AND agbgift_gift_no = agrgdes_gift_no
            
        JOIN afbcamp
            ON agrgdes_campaign = afbcamp_campaign
        JOIN adbdesg
            ON agrgdes_desg = adbdesg_desg
        LEFT JOIN agrgaux
            ON agbgift_pidm = agrgaux_pidm
            AND agbgift_gift_no = agrgaux_gift_no
--        JOIN w_spriden
--            ON agbgift_pidm = w_spriden.spriden_pidm
    
--        JOIN(
--                SELECT 
--                    spbpers_pidm
--                    ,NVL(spbpers_dead_ind,'N') spbpers_dead_ind
--                FROM
--                    spbpers
--        ) ON agbgift_pidm = spbpers_pidm
        
        JOIN w_address
            ON agbgift_pidm = w_address.spraddr_pidm
        
        LEFT JOIN w_NSU_TELEPHONE_SLOT
            ON agbgift_pidm = w_nsu_telephone_slot.entity_uid

        LEFT JOIN w_NSU_EMAIL_SLOT
            ON agbgift_pidm = w_nsu_email_slot.entity_uid
                    
        LEFT JOIN(
                SELECT 
                    apbcons_pidm
                    ,apbcons_pref_clas
                FROM
                    apbcons
        ) ON agbgift_pidm = apbcons_pidm

        LEFT JOIN w_salutation
            ON agbgift_pidm = w_salutation.entity_uid
    
        LEFT JOIN(
                SELECT
                    agrgsol_pidm
                    , agrgsol_gift_no
                    , agrgsol_solc_code
                FROM
                    agrgsol
        ) ON agbgift_pidm = agrgsol_pidm
            AND agbgift_gift_no = agrgsol_gift_no
            
        LEFT JOIN(
            SELECT
                agrgmmo_pidm
                , agrgmmo_gift_no
                , spriden_id
                || '-'
                || TRIM(spriden_last_name)
                || ','
                || TRIM(spriden_first_name)
                || TRIM(' ' || TRIM(spriden_mi))
                || ' = $'
                || trim(to_char(agrgmmo_credit,'999,999.00'))
                    AS GIFT_MEMO_DETAILS
            FROM 
                agrgmmo
                JOIN w_spriden
                    ON agrgmmo_xref_pidm = w_spriden.spriden_pidm
        ) ON agbgift_pidm = agrgmmo_pidm
            AND agbgift_gift_no = agrgmmo_gift_no
        LEFT JOIN w_gift_association_details 
            ON agbgift_pidm = agrgasc_pidm
            AND agrgasc_gift_no = agbgift_gift_no
        LEFT JOIN w_special_groups
            ON agbgift_pidm = aprpros_pidm
--        LEFT JOIN w_pref_donor_cat
--            ON agbgift_pidm = w_pref_donor_cat.aprcatg_pidm
        LEFT JOIN w_giving_history
            ON agbgift_pidm = w_giving_history.person_uid
            
        LEFT JOIN w_RELATIONSHIP
            ON agbgift_pidm = w_relationship.entity_uid
            AND w_relationship.relation_source = 'SX'

        LEFT JOIN w_nsu_exclusion_slot
            ON agbgift_pidm = w_nsu_exclusion_slot.entity_uid

        LEFT JOIN ( SELECT
                        amrinfo_pidm
                        , amrinfo_status  PROSPECT_STATUS
                        , atvprst_desc  PROSPECT_STATUS_DESC
                        , amrinfo_prosp_rate    PROSPECT_AMOUNT
                    FROM
                        amrinfo
                        JOIN atvprst
                            ON amrinfo_status = atvprst_code
            ) PROSPECT_INFO ON agbgift_pidm = amrinfo_pidm
        
        LEFT JOIN ( SELECT
                        amrexrt_pidm
                        , amrexrt_ext_value RATING
                    FROM
                        amrexrt -- advancement_rating
                    WHERE
                        amrexrt_exrs_code = 'JFSGD' 
            ) JFSGD_RATING ON agbgift_pidm = amrexrt_pidm
        LEFT JOIN w_ytd
            ON agbgift_pidm = w_ytd.entity_uid
            
        LEFT JOIN w_total_years
            ON agbgift_pidm = w_total_years.person_uid
            
        LEFT JOIN w_long_years_given
            ON agbgift_pidm = w_long_years_given.spriden_pidm
            
        LEFT JOIN w_recent_cons_years
            ON agbgift_pidm = w_recent_cons_years.spriden_pidm

)
select *
from w_gift;
where entity_uid in (142290,166264,91625,119693)  ---,149463);
and gift_number like '%0120377%';
