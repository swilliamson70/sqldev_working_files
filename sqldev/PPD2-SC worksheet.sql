WITH w_constituent AS(
    SELECT
        apbcons_pidm        PERSON_UID
        , spriden_id        ID
        , f_format_name(apbcons_pidm,'LFMI')    NAME
        , apbcons_pref_last_name    PREF_LAST_NAME
        , apbcons_maiden_last_name  MAIDEN_LAST_NAME
        , (SELECT
                aprcsps_last_name || 
                CASE WHEN aprcsps_sps_pidm IS NULL THEN ', '
                    ELSE NULL
                END ||
                aprcsps_first_name || 
                CASE WHEN aprcsps_sps_pidm IS NOT NULL THEN F_FORMAT_NAME(aprcsps_sps_pidm,'LFMI')
                    ELSE NULL
                END
            FROM aprcsps
            WHERE aprcsps_pidm = apbcons_pidm
                AND aprcsps_mars_ind = 'A'
        ) AS SPOUSE_NAME
        , aprcatg_donr_code PREF_DONOR_CATEGORY
        , atvdonr_desc      PREF_DONOR_CATEGORY_DESC
        , goremal_email_address EMAIL_PREFERRED_ADDRESS
        , nsu_alumni_ods_func.f_life_total_giving(apbcons_pidm) LIFE_TOTAL_GIVING
        , nvl(spbpers_dead_ind,'N') DECEASED_IND
    FROM
        apbcons 
        JOIN spriden
            ON apbcons_pidm = spriden_pidm
            AND spriden_change_ind IS NULL
        JOIN spbpers
            ON spbpers_pidm = apbcons_pidm 
        LEFT JOIN(
                SELECT aprcatg_pidm, aprcatg_donr_code, atvdonr_desc, row_number() OVER (PARTITION BY aprcatg_pidm ORDER BY atvdonr_rpt_seq_ind) rn
                FROM aprcatg JOIN atvdonr ON aprcatg_donr_code = atvdonr_code
        )   ON aprcatg_pidm = apbcons_pidm
            AND rn = 1
        LEFT JOIN goremal
            ON goremal_pidm = apbcons_pidm
            AND goremal_status_ind = 'A'
            AND goremal_preferred_ind = 'Y'
    WHERE
        f_format_name(apbcons_pidm,'LFMI') NOT LIKE '%DO%NOT%USE%'
        AND apbcons_pidm NOT IN (SELECT bad_pidm FROM nsudev.nsu_alum_pidm WHERE bad_pidm = apbcons_pidm)
        AND apbcons_pidm NOT IN (SELECT aprcatg_pidm FROM aprcatg WHERE aprcatg_pidm = apbcons_pidm)
        
)
/* w_CONSTITUENT.name not like '%DO%NOT%USE%' and
 w_CONSTITUENT.PERSON_UID not in (select distinct s2.entity_uid from donor_category s2 where s2.entity_uid = w_CONSTITUENT.PERSON_UID and s2.donor_category = 'BAD') and
 w_CONSTITUENT.PERSON_UID not in (SELECT bad_pidm FROM nsudev.nsu_alum_pidm where bad_pidm = w_CONSTITUENT.PERSON_UID)
---------------------------------
select * from w_constituent
order by 1;

select * from apbcons ;
select * from aprcsps;
select aprcsps_last_name || case when aprcsps_sps_pidm is null then ', ' else null end 
    || aprcsps_first_name || case when aprcsps_sps_pidm is not null then f_format_name(aprcsps_sps_pidm,'LFMI') end
from aprcsps where aprcsps_pidm = 1096; --26301;
select to_char(aprcatg_activity_date,'YYYY-MON-DD HH24:MM:SS'), aprcatg.* from aprcatg where aprcatg_pidm = 1356;
select * from atvdonr;
select * from goremal;
select * from spbpers; 
select * from all_tab_comments where table_name = 'APRCHIS';
------------------------------------*/
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
)
--select * from w_nsu_exclusion_slot

, w_annual_giving_slot AS(
    SELECT 
        aprchis_pidm ENTITY_UID
        , NSU_ALUMNI_ODS_FUNC.F_GET_TOT_PLEDGE_PAYMENT_YEAR(aprchis_pidm,EXTRACT(YEAR FROM sysdate)) TOTAL_PLEDGE_PAYMENTS1
        , aprchis_fisc_code FISCAL_YEAR1
        , NSU_ALUMNI_ODS_FUNC.F_GET_TOT_GIVING_YEAR(aprchis_pidm,EXTRACT(YEAR FROM sysdate)) TOTAL_GIVING1
        
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
)
--select * from w_annual_giving_slot
--select * from aprchis where aprchis_pidm = 52417;

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
)
--select * from w_advancement_rating_slot
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
)
--select * from w_nsu_email_slot
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
)
--select * from w_nsu_telephone_slot

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
)
--select * from w_relationship;

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
)

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
)
--select * from w_degree_history;
--select * from w_degree_slot
, w_spbpers AS(
    SELECT
        spbpers_pidm
        , spbpers_birth_date
        , spbpers_dead_ind
        , spbpers_vera_ind
        /*Veteran Category: 
            (NULL) Not a Veteran, 
            (B) Protected veteran choosing not to self-identify the classification, 
            (O) Active Wartime or Campaign Badge Veteran, 
            (V) Not a Protected Veteran
        */
    FROM
        spbpers
    WHERE
        spbpers_pidm IN (SELECT person_uid FROM w_constituent)
)
--select * from w_spbpers
, w_apbghis AS(
    SELECT
       apbghis_pidm
       , apbghis_total_no_gifts
       , apbghis_high_gift_amt
       , apbghis_last_gift_date
    FROM
        apbghis 
)
--select * from w_apbghis;
, w_amrstaf AS(
    SELECT
        amrstaf_pidm
        , amrstaf_iden_code
    FROM
        amrstaf
    WHERE
        AMRSTAF_PRIMARY_IND = 'Y'
) 
--select * from w_amrstaf
, w_guriden AS(
    SELECT
        guriden_iden_code
        , guriden_desc
    FROM
        guriden
)
--select * from w_guriden
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
)
--select * from w_recent_membership
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
)
--select * from w_won_membership
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
)
--select * from w_fan_membership
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
)
--select * from w_salutation
, w_ytd AS(
    SELECT/*+ MATERIALIZE */ 
        entity_uid
        , SUM(CASE WHEN year_pos = 1 THEN tots END) YTD
        , SUM(CASE WHEN year_pos = 2 THEN tots END) YTD_1
        , SUM(CASE WHEN year_pos = 3 THEN tots END) ytd_2
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
)

--select * from w_ytd
, w_jfsgd AS(
    SELECT
        amrexrt_pidm ENTITY_UID,
        amrexrt_ext_value RATING
    FROM
        amrexrt -- advancement_rating
    WHERE
        amrexrt_exrs_code = 'JFSGD'
)
--select * from w_jfsgd
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
)
--select * from w_employment;
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
)
--select * from w_address;
, w_long_years_given AS(
    SELECT /*+ MATERIALIZE */ 
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
        WHERE AGBGIFT_FISC_CODE <= TO_CHAR(TO_DATE(:parm_DT_GivingEnd), 'YYYY')
        CONNECT BY PRIOR spriden_pidm = spriden_pidm
            AND PRIOR agbgift_fisc_code = agbgift_fisc_code -1
    )
    GROUP BY spriden_pidm
)
--select * from w_long_years_given;
, w_recent_cons_years AS(
    SELECT /*+ MATERIALIZE */ 
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
        WHERE AGBGIFT_FISC_CODE <= TO_CHAR(TO_DATE(:parm_DT_GivingEnd), 'YYYY')
        CONNECT BY PRIOR spriden_pidm = spriden_pidm
            AND PRIOR agbgift_fisc_code = agbgift_fisc_code -1
    )
    GROUP BY spriden_pidm
)
--select * from w_recent_cons_years;
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
        agbgift_gift_date BETWEEN :parm_DT_GivingStart AND :parm_DT_GivingEnd
    GROUP BY
        agbgift_pidm
)
--select * from w_range_tot_gift;
, w_range_tot_aux AS(
    SELECT
        agrgaux_pidm ENTITY_UID
        , TRIM(TO_CHAR(SUM(NVL(agrgaux_dcpr_value,0)),'999999990.99')) GIFT_AMT
    FROM
        agrgaux
    WHERE
        agrgaux_auxl_value_date BETWEEN :parm_DT_GivingStart AND :parm_DT_GivingEnd
    GROUP BY
        agrgaux_pidm
)
--select * from w_range_tot_aux
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
)
--select * from w_spec_purpose
--order by 1;

select w_CONSTITUENT.PERSON_UID,
       w_CONSTITUENT.ID,
       w_CONSTITUENT.NAME,
       w_CONSTITUENT.PREF_LAST_NAME,
       w_CONSTITUENT.MAIDEN_LAST_NAME,
       w_CONSTITUENT.SPOUSE_NAME,
       w_relationship.related_id related_id,
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
       w_recent_membership.membership_category "Membership_name",
       w_recent_membership.membership_status "Membership_name",
       w_recent_membership.membership_number "membership_number",
       w_recent_membership.expiration_date "expiration_date",
       w_won_membership.membership_category "w_WON_Membership_name",
       w_won_membership.membership_status "w_WON_Membership_status",
       w_won_membership.membership_number "w_WON_membership_number",
       w_won_membership.expiration_date "WON_expiration_date",
       w_fan_membership.membership_category "w_FAN_Membership_name",
       w_fan_membership.membership_status "w_FAN_Membership_status",
       w_fan_membership.membership_number "w_FAN_membership_number",
       w_fan_membership.expiration_date "FAN_expiration_date",
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
       w_relationship.related_id related_id,
       w_range_tot_gift.gift_amt "DATE_RANGE_TOTAL_GIVING",
       w_range_tot_aux.gift_amt "DATE_RANGE_TOTAL_AUX_AMT",
       w_DEGREE_SLOT.DEGREE_1,
       w_DEGREE_SLOT.DEGREE_DESC_1,
       w_DEGREE_SLOT.ACADEMIC_YEAR_1,
       w_DEGREE_SLOT.MAJOR_1,
       w_DEGREE_SLOT.MAJOR_DESC_1,
       w_DEGREE_SLOT.DEGREE_2,
       w_DEGREE_SLOT.DEGREE_DESC_2,
       w_DEGREE_SLOT.ACADEMIC_YEAR_2,
       w_DEGREE_SLOT.MAJOR_2,
       w_DEGREE_SLOT.MAJOR_DESC_2,
       w_DEGREE_SLOT.DEGREE_3,
       w_DEGREE_SLOT.DEGREE_DESC_3,
       w_DEGREE_SLOT.ACADEMIC_YEAR_3,
       w_DEGREE_SLOT.MAJOR_3,
       w_DEGREE_SLOT.MAJOR_DESC_3,
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

  from
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

 where 
 --w_CONSTITUENT.name not like '%DO%NOT%USE%' and
 --w_CONSTITUENT.PERSON_UID not in (select distinct s2.entity_uid from donor_category s2 where s2.entity_uid = w_CONSTITUENT.PERSON_UID and s2.donor_category = 'BAD') and
 --w_CONSTITUENT.PERSON_UID not in (SELECT bad_pidm FROM nsudev.nsu_alum_pidm where bad_pidm = w_CONSTITUENT.PERSON_UID) and
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
      and   (     :cb_leadership = 1
            or    (     exists   (  select 'X' "calc1"
                                    from apracld
                                    where    apracld_lead_code = :parm_MC_leadership--.STVLEAD_CODE
                                       and   apracld_pidm = w_CONSTITUENT.PERSON_UID
                                 )
                  and   :cb_leadership = 0
                  )
            )
and   (  :parm_CB_AllZipCodes = 1
            or (     :parm_CB_ignore_zip_use_state = 1
               and   substr(w_address.spraddr_stat_code,1,2) = :parm_MC_StateCode--.State
               )
            or substr(w_address.spraddr_zip,1,5) = :parm_MC_ZipCode--.ZipCode
            )
            
      and   (  :parm_CB_enter_name = 1
            or    upper(w_address.spraddr_city) = upper(:parm_EB_City)
            )

      and   (  :parm_CB_AllActivies = 1
            or exists ( select 'X' "calc1"
                      from apracyr
                     where apracyr_actc_code = :parm_MC_ActivityCode--.ActivityCode
                           and (( :cb_Activity_Years = 0 and apracyr_year = :param_lb_activity_years)--.APRACYR_YEAR)
                           or :cb_Activity_Years = 1)
                           and apracyr_pidm =w_CONSTITUENT.PERSON_UID )
            or exists ( select 'X' "calc1"
                      from apracty
                     where apracty_actc_code = :parm_MC_ActivityCode--.ActivityCode
                           and apracty_pidm =w_CONSTITUENT.PERSON_UID ) )

         and ( :parm_CB_AllGCranges = 1
           or w_ADVANCEMENT_RATING_SLOT.RATING_AMOUNT1 = :parm_LB_GiftCapRange)--.Code )
         and ( :parm_CB_AllWEdesignations = 1
           or w_ADVANCEMENT_RATING_SLOT.RATING_LEVEL2 = :parm_LB_WealthEngineDesg)--.Main )
         and ( :parm_CB_AllExclusions = 1
           or w_NSU_EXCLUSION_SLOT.NPH = :parm_MC_ExclusionCode--.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NOC = :parm_MC_ExclusionCode--.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NMC = :parm_MC_ExclusionCode--.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NEM = :parm_MC_ExclusionCode--.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NAM = :parm_MC_ExclusionCode--.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NDN = :parm_MC_ExclusionCode--.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NAK = :parm_MC_ExclusionCode--.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.NTP = :parm_MC_ExclusionCode--.ExclusionCode
           or w_NSU_EXCLUSION_SLOT.AMS = :parm_MC_ExclusionCode)--.ExclusionCode )
         and ( :parm_CB_HouseholdInd = 1
           or w_RELATIONSHIP.HOUSEHOLD_IND = :parm_LB_HouseholdInd)--.Main )
         and ( :parm_CB_AllCountyCodes = 1
           or w_address.spraddr_cnty_code = :parm_MC_CountyCode)--.CountyCode )
         and ( :parm_CB_AllDegrees = 1
           or w_DEGREE_SLOT.DEGREE_1 = :parm_MC_Degrees--.DegreeCode
           or w_DEGREE_SLOT.DEGREE_2 = :parm_MC_Degrees--.DegreeCode
           or w_DEGREE_SLOT.DEGREE_3 = :parm_MC_Degrees)--.DegreeCode )
         and ( :parm_CB_GradYears = 1
           or w_DEGREE_SLOT.ACADEMIC_YEAR_1 = :parm_LB_GradYear--.AbbrevInd
           or w_DEGREE_SLOT.ACADEMIC_YEAR_2 = :parm_LB_GradYear--.AbbrevInd
           or w_DEGREE_SLOT.ACADEMIC_YEAR_3 = :parm_LB_GradYear)--.AbbrevInd )
         and ( :parm_CB_AllMajors = 1
           or w_DEGREE_SLOT.MAJOR_1 = :parm_MC_Major--.MajorCode
           or w_DEGREE_SLOT.MAJOR_2 = :parm_MC_Major--.MajorCode
           or w_DEGREE_SLOT.MAJOR_3 = :parm_MC_Major)--.MajorCode )
         and ( :parm_CB_Ignore_Degree_Dates = 1
           or w_DEGREE_SLOT.DEGREE_DATE_1 between :parm_DT_DegreeDateStart and :parm_DT_DegreeDateEnd
           or w_DEGREE_SLOT.DEGREE_DATE_2 between :parm_DT_DegreeDateStart and :parm_DT_DegreeDateEnd
           or w_DEGREE_SLOT.DEGREE_DATE_3 between :parm_DT_DegreeDateStart and :parm_DT_DegreeDateEnd )
         and ( ( :parm_CB_AllDonorCats = 1 )
         
           or exists ( select 'x' "calc1"
                        FROM aprcatg DONOR_CATEGORY
                        WHERE donor_category.aprcatg_pidm = w_constituent.person_uid
                            AND donor_category.aprcatg_donr_code = :parm_MC_DonorCats) ) --.DonorCatCode ) )
                      
--                      from ODSMGR.DONOR_CATEGORY DONOR_CATEGORY
--                     where DONOR_CATEGORY.ENTITY_UID = w_CONSTITUENT.PERSON_UID
--                           and DONOR_CATEGORY.DONOR_CATEGORY = :parm_MC_DonorCats.DonorCatCode ) )
         
         and ( ( :parm_CB_SP_Types = 1 )
           or exists ( select 'x' "calc1"
                        FROM aprpros SPECIAL_PURPOSE_GROUP
                        WHERE special_purpose_group.aprpros_pidm = w_constituent.person_uid
                            AND special_purpose_group.aprpros_prtp_code = :parm_MC_SP_Types) ) --.SpecialPurCode ) )
                            
--                      from ODSMGR.SPECIAL_PURPOSE_GROUP SPECIAL_PURPOSE_GROUP
--                     where SPECIAL_PURPOSE_GROUP.ENTITY_UID = w_CONSTITUENT.PERSON_UID
--                           and SPECIAL_PURPOSE_GROUP.SPECIAL_PURPOSE_TYPE = :parm_MC_SP_Types.SpecialPurCode ) )
                           
         and ( ( :parm_CB_SP_Groups = 1 )
           or exists ( select 'x' "calc1"
                        FROM aprpros SPECIAL_PURPOSE_GROUP
                        WHERE special_purpose_group.aprpros_pidm = w_constituent.person_uid
                            AND special_purpose_group.aprpros_prcd_code = :parm_MC_SP_Groups) ) --.SpecialPurCode ) )
                            
--                      from ODSMGR.SPECIAL_PURPOSE_GROUP SPECIAL_PURPOSE_GROUP
--                     where SPECIAL_PURPOSE_GROUP.ENTITY_UID = w_CONSTITUENT.PERSON_UID
--                           and SPECIAL_PURPOSE_GROUP.SPECIAL_PURPOSE_GROUP = :parm_MC_SP_Groups.SpecialPurCode ) )
                           
         and ( ( :parm_CB_PrimSpouse_Unmarried = 1 )
           or ( w_RELATIONSHIP.RELATION_SOURCE = 'SX'
             and w_RELATIONSHIP.COMBINED_MAILING_PRIORITY = 'P' )
           or not exists ( select 'x' "calc1"
                            FROM w_relationship RELATIONSHIP1
                            WHERE relationship1.entity_uid = w_constituent.person_uid
                                AND relationship1.relation_source = 'SX'
                                AND relationship1.relation_source_code = 'SP1' ) )
                                
--                          from ODSMGR.RELATIONSHIP RELATIONSHIP1
--                         where RELATIONSHIP1.ENTITY_UID = w_CONSTITUENT.PERSON_UID
--                               and RELATIONSHIP1.RELATION_SOURCE = 'SX'
--                               and RELATIONSHIP1.RELATED_CROSS_REFERENCE = 'SP1' ) )

         and ( ( :parm_CB_AllMailCodes = 1 )
           or exists ( select 'x' "calc1"
                        FROM aprmail
                        WHERE aprmail_pidm = w_constituent.person_uid
                            and aprmail_mail_code = :parm_MB_mail_codes) ) --.MailCode ) )
                            
--                      from ODSMGR.MAIL MAIL
--                     where MAIL.ENTITY_UID = w_CONSTITUENT.PERSON_UID
--                           and MAIL.MAIL = :parm_MC_mail_codes.MailCode ) )
                           
         and ((:parm_CB_deceased = 1) or nvl(w_spbpers.SPBPERS_DEAD_IND,'N') = 'N')
         )
         and (nvl2(SPBPERS_VERA_IND, 'Y','N') = :lb_veteran or :lb_veteran = 'All')
         and ((:parm_CB_Ignore_Gift_Dates = 1) 
                or exists ( select 'x'
                            FROM agbgift
                            WHERE agbgift_pidm = w_constituent.person_uid
                                AND agbgift_gift_date BETWEEN :parm_DT_GivingStart AND :parm_DT_GivingEnd))
                                
--                                                               from gift g2
--                                                               where g2.entity_uid = w_CONSTITUENT.PERSON_UID
--                                                               and g2.GIFT_DATE between :parm_DT_GivingStart and :parm_DT_GivingEnd))


        -- and rownum <= :parm_ED_rownum
   )
         --and :parm_BT_ViewQV is not null
