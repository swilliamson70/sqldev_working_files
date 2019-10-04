select * from all_tab_comments where table_name = 'SPRHOLD'; --Person Related Holds Repeating Table
select * from all_tab_comments where table_name = 'SORTEST'; --Student Test Score Repeating Table
select * from all_tab_comments where table_name = 'SHRTCKN'; --Institutional Course Term Maintenance Repeating Table
select * from all_tab_comments where table_name = 'SHRTCKG'; --Institutional Courses Grade Repeating Table
select * from all_tab_comments where table_name = 'SHRTRCE'; --Transfer Course Equivalent Repeating Table
select * from all_col_comments where table_name = 'SPRHOLD'; -- validation stvhldd
select * from all_col_comments where table_name = 'SORTEST'; -- validation stvtesc
select * from all_col_comments where table_name = 'SHRTCKN'; -- student <-> course
select * from sortest;

--    cursor c_def is 
    select
        spriden_id,
        spriden_first_name,
        spriden_last_name ,
        sprhold_pidm,
        sprhold_hldd_code ,
        sprhold.rowid this_row,
        to_char(sprhold_from_date,'DD-MON-YYYY') hold_start,
        to_char(sprhold_to_date,'DD-MON-YYYY') hold_end,
        decode(sprhold_hldd_code, '13','ENGA','62','ENGA','14','MTHA','15','MTHA','63','MTHA','16','REDA','64','REDA','17','SCIA','18','SCIA',null) resolve_code,
        decode(sprhold_hldd_code, '13','A01','62','A01','14','A02','15','A02','63','A02','16','A03','64','A03','17','A04','18','A04',null) act_code,
        decode(sprhold_hldd_code, '13','S11','62','S11','14','S12','15','S12','63','S12','16','S11','64','S11',null) sat_code,
        decode(sprhold_hldd_code, '13','CPTE','62','CPTE','14','CPTM','15','CPTM','63','CPTM','16','CPTR','64','CPTR',null) cpt_code,
        decode(sprhold_hldd_code, '13','CPTW','62','CPTW','14','NSM1','15','NSM1','63','NSM1','16','ANGR','64','ANGR',null) new_cpt_code,
        decode(sprhold_hldd_code, '13','ENGL0123','62','ENGL0123','14','MATH0123','15','MATH0133','63','MATH0123','16','ENGL0113','64','ENGL0113',null) course_code, 
        sprhold_user
    from  spriden,
          sprhold
    where 
         sprhold_hldd_code in ( '13','62','14','15','63','16','64','17','18' ) 
     and (sprhold_to_date is null or sprhold_to_date > sysdate)
     and sprhold_pidm = spriden_pidm
     and spriden_change_ind is null order by sprhold_pidm, sprhold_hldd_code
  ;
  
      select 
    spriden_id,
    spriden_first_name,
    spriden_last_name ,
    sp1.sprhold_pidm,
    sp1.sprhold_hldd_code ,
    sp1.rowid this_row,
    to_char(sp1.sprhold_from_date,'DD-MON-YYYY') hold_start,
    to_char(sp1.sprhold_to_date,'DD-MON-YYYY') hold_end,
    sp1.sprhold_user
    from
    spriden,
    sprhold sp1
    where
    sp1.sprhold_hldd_code in ( '17','18' ) 
    and sp1.sprhold_pidm = spriden_pidm
    and spriden_change_ind is null
    and   (sp1.sprhold_to_date is null or sp1.sprhold_to_date > sysdate)
    and sp1.sprhold_pidm not in 
    (select actDef.sprhold_pidm
     from
          (select sp2.sprhold_pidm, count(sp2.sprhold_pidm) cnt
           from sprhold sp2
           where 
                sp2.sprhold_hldd_code in ( '13','62','14','15','63','16','64' )  
                and (sp2.sprhold_to_date is null or sp2.sprhold_to_date > sysdate )
                group by sp2.sprhold_pidm
              having count(sp2.sprhold_pidm) > 0
           ) actDef
      )
    ;

select mynumber from (
select '64' mynumber from dual)
where mynumber not in('16','64');

/*************************************************
FUNCTION name
    brief desc of what this does and how    
*************************************************/

