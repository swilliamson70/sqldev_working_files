        with w_degree_history AS(
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
        ) 
select * from w_degree_slot;
where (
    --p_all_majors = 1
                         instr(:p_majors, NVL(w_DEGREE_SLOT.MAJOR_1,'ZZ9')||',') >0
                        or instr(:p_majors, NVL(w_DEGREE_SLOT.MAJOR_2,'ZZ9')||',') >0
                        or instr(:p_majors, NVL(w_DEGREE_SLOT.MAJOR_3,'ZZ9')||',') >0
);
select STVMAJR.STVMAJR_CODE "MajorCode",
       STVMAJR.STVMAJR_DESC "MajorDesc"
  from STVMAJR;
select STVSTAT.STVSTAT_CODE
       , STVSTAT.STVSTAT_DESC
     from STVSTAT
  order by case
    when stvstat_code in ('AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','MD','MA','MI','MN','MS','MO','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY') then 1
    when stvstat_code in ('VI','PR','AS','GU','AA','AE','AP') then 2
    else 3 end 
    ,1;
select * from spraddr;

select *
  from SATURN.STVCNTY STVCNTY;
select * from all_tab_comments where table_name like '%ZIP%';
select gtvzipc_code, count(gtvzipc_cnty_code) over (partition by gtvzipc_code) counties
, count(gtvzipc_stat_code) over (partition by gtvzipc_code) states
from gtvzipc;
select * from gtvzipc; where gtvzipc_code = '02861';
select * from aprmail;
SELECT aprmail_pidm ENTITY_UID
                                , LISTAGG(aprmail_mail_code,',') WITHIN GROUP( ORDER BY aprmail_mail_code) MAIL_CODES
                            FROM aprmail
                            GROUP BY aprmail_pidm;
select * from agbgift;
    