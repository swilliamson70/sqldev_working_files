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
        
)

/*---------------------------------
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
            goremal.goremal_pidm ENTITY_ID
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
--select * from w_relationship

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
select 1 from dual
)
select * from w_range_tot_gift;
--w_range_tot_aux
order by 1;
select * from all_col_comments where table_name = 'SPBPERS';