with prev_semester as
(
               SELECT
                  stvterm_code
               FROM
                  stvterm
               WHERE
                     stvterm_code < '202010' --:listbox1.stvterm_code
                  AND
                     stvterm_code NOT LIKE '%5'
                  AND (
                     (
                           '202010' LIKE '%20' --:listbox1.stvterm_code 
                        AND
                           ROWNUM <= 2
                     ) OR (
                           '202010' NOT LIKE '%20'-- :listbox1.stvterm_code 
                        AND
                           ROWNUM = 1
                     )
                  )
               ORDER BY stvterm_code DESC
)



select spriden_pidm,
       spriden.spriden_id as ID,
       spriden.spriden_first_name as First_Name,
       spriden.spriden_mi as Middle_Name,
       spriden.spriden_last_name as Last_Name,
       sr_begin_of_term.SHRTTRM_ASTD_CODE_END_OF_TERM Academic_standing_code_begin,
       sr_stvastd.stvastd_desc academic_standing_start,
       su_end_of_term.SHRTTRM_ASTD_CODE_END_OF_TERM ACAD_Stand_Code_END,
       su_stvastd.stvastd_desc academic_standing_end,
--       sgbstdn_astd_code as Academic_standing_code_begin,
--       shrttrm.shrttrm_astd_date_end_of_term as ACAD_Stand_Code_END,
--       stvastd.stvastd_desc as academic_standing_end,
       primary_addr.spraddr_street_line1 as Permanent_Strt1,
       primary_addr.spraddr_street_line2 as Permanent_Strt2,
       primary_addr.spraddr_city as Permanent_City,
       primary_addr.spraddr_stat_code as Permanent_State,
       primary_addr.spraddr_zip as Permanent_Zip,
       mailing_addr.spraddr_street_line1 as Mailing_Strt1,
       mailing_addr.spraddr_street_line2 as Mailing_Strt2,
       mailing_addr.spraddr_city as Mailing_City,
       mailing_addr.spraddr_stat_code as Mailing_State,
       mailing_addr.spraddr_zip as Mailing_Zip,               --202030
       goremal.goremal_email_address as Email,
       shrlgpa.shrlgpa_hours_earned as Overall_Hrs_Earned,
       shrlgpa.shrlgpa_gpa as Over_All_GPA,
       shrtgpa.shrtgpa_hours_earned as Term_Hrs_Earned,
       shrtgpa.shrtgpa_gpa as Term_GPA,
       
       case when substr(current_term.term, -2, 2) = '10' or  substr(current_term.term, -2, 2) = '20' then
            (select distinct 'Y' from sfrstcr where sfrstcr_rsts_code 
                in ('RW', 'RE') and sfrstcr_term_code = current_term.term + 10
                                and sfrstcr_pidm = spriden_pidm)
            when substr(current_term.term, -2, 2) = '30' 
                then (select distinct 'Y' from sfrstcr where sfrstcr_rsts_code 
                in ('RW', 'RE') and sfrstcr_term_code = (substr(current_term.term, 1, 4) + 1) || '10' and sfrstcr_pidm = spriden_pidm)
                --current_term.term + 10
                  --              
       end as enrnext,
       
--       case when substr(current_term.term, -2, 2) = '30' then (select distinct 'Y' from sfrstcr where sfrstcr_rsts_code in ('RW', 'RE')
--       and sfrstcr_term_code in (select * from (select stvterm_code from stvterm
--       where stvterm_code > current_term.term and stvterm_code not like '%5' order by stvterm_code ) where rownum < 3)) end enrnext2,
       
       case when substr(current_term.term, -2, 2) = '10' 
            then (select distinct 'Y' from sfrstcr where sfrstcr_rsts_code 
                in ('RW', 'RE') and sfrstcr_term_code = current_term.term + 20
                                and sfrstcr_pidm = spriden_pidm)
                                
            when substr(current_term.term, -2, 2) = '20' 
                then (select distinct 'Y' from sfrstcr where sfrstcr_rsts_code 
                    in ('RW', 'RE') and sfrstcr_term_code = (substr(current_term.term, 1, 4) + 1) || '10' 
                                and sfrstcr_pidm = spriden_pidm)
                                
            when substr(current_term.term, -2, 2) = '30' 
                then (select distinct 'Y' from sfrstcr where sfrstcr_rsts_code 
                    in ('RW', 'RE') and sfrstcr_term_code = (substr(current_term.term, 1, 4) + 1) || '20' 
                                and sfrstcr_pidm = spriden_pidm) end enrnext2,
       
       case when spbpers.SPBPERS_CITZ_CODE = 'NR' then 'International' when  sgrsprt_term_code is not null then 'Athlete' end int_ath,
       Primary_advisor,
       adv_email

       
from   spriden

    left join(  select * from spraddr 
                where 
                    spraddr_atyp_code = 'PR'  
                    and spraddr_seqno = (select max(g3.spraddr_seqno)
                                        from spraddr g3 
                                        where g3.spraddr_pidm = spraddr.spraddr_pidm 
                                            and g3.spraddr_atyp_code = spraddr.spraddr_atyp_code 
                                            and sysdate between g3.spraddr_from_date and nvl(g3.spraddr_to_date, sysdate + 1) 
                                            and g3.spraddr_status_ind is null)) primary_addr 
        on spriden_pidm = primary_addr.spraddr_pidm


    left join(  select * from spraddr 
                where 
                    spraddr_atyp_code = 'MA'  
                    and spraddr_seqno = (   select max(g3.spraddr_seqno)
                                            from spraddr g3
                                            where
                                                g3.spraddr_pidm = spraddr.spraddr_pidm 
                                                and g3.spraddr_atyp_code = spraddr.spraddr_atyp_code 
                                                and sysdate between g3.spraddr_from_date and nvl(g3.spraddr_to_date, sysdate + 1) 
                                                and g3.spraddr_status_ind is null)
                                        ) mailing_addr 
        on spriden_pidm = mailing_addr.spraddr_pidm


    left join goremal -- student email
        on spriden_pidm = goremal_pidm
        and goremal_emal_code = 'NSU' 
        and goremal_status_ind = 'A' 
--        and goremal_activity_date = (   select max(g2.goremal_activity_date) 
--                                        from goremal g2 
--                                        where g2.goremal_pidm = goremal.goremal_pidm 
--                                            and g2.goremal_status_ind = goremal.goremal_status_ind 
--                                            and g2.goremal_emal_code = goremal.goremal_emal_code)


    left join(  SELECT * FROM shrlgpa 
                where shrlgpa_gpa_type_ind = 'O' 
                    and shrlgpa_levl_code = (   select max(s1.shrlgpa_levl_code) keep (dense_rank first order by decode(s1.shrlgpa_levl_code,'PR', 3,'GR',2,'UG',1, 0) desc) 
                                                from shrlgpa s1
                                                where s1.shrlgpa_pidm = shrlgpa.shrlgpa_pidm 
                                                    and s1.shrlgpa_gpa_type_ind = shrlgpa.shrlgpa_gpa_type_ind)) shrlgpa
        on spriden_pidm = shrlgpa_pidm

    left join(  select stvterm_code term 
                from stvterm 
                where stvterm_code not like '%5') current_term
           on term = '202010' --:listbox1.stvterm_code

    left join(  select * from shrtgpa 
                where shrtgpa_gpa_type_ind = 'I' 
                    and shrtgpa_levl_code = (   select max(s1.shrtgpa_levl_code) keep (dense_rank first order by decode(s1.shrtgpa_levl_code,'PR', 3,'GR',2,'UG',1, 0) desc)
                                                from shrtgpa s1 
                                                where s1.shrtgpa_pidm = shrtgpa.shrtgpa_pidm
                                                    and s1.shrtgpa_gpa_type_ind = shrtgpa.shrtgpa_gpa_type_ind)) shrtgpa
        on spriden_pidm = shrtgpa_pidm 
        and shrtgpa_term_code = current_term.term

--join   sgbstdn on sgbstdn_pidm = spriden_pidm
    left join(  select distinct 
                    sgrsprt_pidm
                    , sgrsprt_term_code
                from sgrsprt) 
        on sgrsprt_pidm = spriden_pidm 
        and sgrsprt_term_code = current_term.term

    left join spbpers
        on spbpers_pidm = spriden_pidm

    left join shrttrm 
        on spriden_pidm = shrttrm_pidm 
        and shrttrm_term_code = current_term.term

    left join stvastd 
        on stvastd_code = shrttrm_astd_code_end_of_term

   LEFT JOIN (
      SELECT
         shrttrm_pidm
         , MAX(SHRTTRM_ASTD_CODE_END_OF_TERM) KEEP(DENSE_RANK FIRST ORDER BY shrttrm_term_code) SHRTTRM_ASTD_CODE_END_OF_TERM
         , MAX(shrttrm_astd_date_end_of_term) KEEP(DENSE_RANK FIRST ORDER BY shrttrm_term_code) shrttrm_astd_date_end_of_term
         , MAX(shrttrm_term_code) shrttrm_term_code
      FROM
         shrttrm
      WHERE
         shrttrm_term_code = '202010' --:listbox1.stvterm_code
      GROUP BY
         shrttrm_pidm
   ) su_end_of_term 
        ON su_end_of_term.shrttrm_pidm = spriden_pidm
                
   LEFT JOIN stvastd su_stvastd 
        ON su_stvastd.stvastd_code = su_end_of_term.shrttrm_astd_code_end_of_term

   LEFT JOIN (
      SELECT
         shrttrm_pidm
         , MAX(SHRTTRM_ASTD_CODE_END_OF_TERM) KEEP(DENSE_RANK FIRST ORDER BY shrttrm_term_code) SHRTTRM_ASTD_CODE_END_OF_TERM
         , MAX(shrttrm_astd_date_end_of_term) KEEP(DENSE_RANK FIRST ORDER BY shrttrm_term_code) shrttrm_astd_date_end_of_term
         , MAX(shrttrm_term_code) shrttrm_term_code
      FROM
         shrttrm
      WHERE
         shrttrm_term_code < '202010' --:listbox1.stvterm_code
      GROUP BY
         shrttrm_pidm
   ) sr_begin_of_term 
        ON sr_begin_of_term.shrttrm_pidm = spriden_pidm

   LEFT JOIN stvastd sr_stvastd 
        ON sr_stvastd.stvastd_code = sr_begin_of_term.shrttrm_astd_code_end_of_term


    left join(  select sgradvr_pidm
                    , spriden_first_name
                    || ' ' 
                    || spriden_last_name as Primary_advisor
                    , goremal_email_address as adv_email

                from sgradvr
                    left join spriden 
                        on sgradvr_advr_pidm = spriden_pidm 
                        and spriden_change_ind is null 
                        and upper(spriden_last_name) not like '%DO%NOT%USE%'
                    left join goremal 
                        on spriden_pidm = goremal_pidm
                where sgradvr_prim_ind = 'Y' 
                and sgradvr_term_code_eff = (   select max(g5.sgradvr_term_code_eff) 
                                                from sgradvr g5
                                                where g5.sgradvr_term_code_eff <= ( select min(stvterm_code) term 
                                                                                    from stvterm 
                                                                                    where stvterm_code not like '%5' 
                                                                                    and sysdate <= stvterm_end_date)
                                                and g5.sgradvr_pidm = sgradvr.sgradvr_pidm) 
                and goremal_emal_code = 'NSU' 
                and goremal_status_ind = 'A' 
                and goremal_activity_date = (   select max(g2.goremal_activity_date) 
                                                from goremal g2 
                                                where g2.goremal_pidm = goremal.goremal_pidm 
                                                and g2.goremal_status_ind = goremal.goremal_status_ind 
                                                and g2.goremal_emal_code = goremal.goremal_emal_code)) advisor
                        on spriden_pidm = sgradvr_pidm
                        
where 
    spriden_change_ind is null and upper(spriden_last_name) not like '%DO%NOT%USE%'
    and spriden_id = 'N00212579'
--    and goremal_emal_code = 'NSU' 
--    and goremal_status_ind = 'A' 
--    and goremal_activity_date = (   select max(g2.goremal_activity_date) 
--                                    from goremal g2 
--                                    where   g2.goremal_pidm = goremal.goremal_pidm 
--                                        and g2.goremal_status_ind = goremal.goremal_status_ind 
--                                        and g2.goremal_emal_code = goremal.goremal_emal_code)

and
   (  su_end_of_term.SHRTTRM_ASTD_CODE_END_OF_TERM = 'SU'
      or
         (  sr_begin_of_term.SHRTTRM_ASTD_CODE_END_OF_TERM = 'SR'
            AND
            sr_begin_of_term.shrttrm_term_code in (select * from prev_semester)
         )
   )       
;

select * from spriden where spriden_id = 'N00212579'; -- 212713 pidm
select * from goremal where goremal_pidm = 212713;