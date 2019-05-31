with ten_pays_cte as (
    select id  from employee where id in (
        'N00012037'
        ,'N00118512'
        ,'N00118535'
        ,'N00119514'
        ,'N00119831'
        ,'N00013082'
        ,'N00118336'
        ,'N00120096'
        ,'N00119715'
        ,'N00118381'
        ,'N00119657'
        ,'N00066373'
        ,'N00119087'
    )
)

select 
        person_detail.tax_id                        Employee_SSN--Employee SSN - A

        ,employee.id                                EID--EID - B

        ,person_detail.name_prefix                  Prefix -- C
        
--        ,case when pdrbene_seq_no = 1 or pdrbene_seq_no is null then person_detail.first_name
--                else coalesce(pdrbene_bene_first_name, spriden_first_name)
--         end as                                     First--First
        ,person_detail.first_name                   First -- D
         
--        ,case when pdrbene_seq_no = 1 or pdrbene_seq_no is null then person_detail.middle_initial
--                else coalesce(pdrbene_bene_mi,spriden_mi)
--         end as                                     MI--MI
        ,person_detail.middle_initial               MI -- MI - E

--        ,case when pdrbene_seq_no = 1 or pdrbene_seq_no is null then person_detail.last_name
--                else coalesce(pdrbene_bene_last_name, spriden_last_name)        
--         end as                                     Last--Last
        ,person_detail.last_name                    Last -- Last - F

--        ,case when pdrbene_seq_no = 1 or pdrbene_seq_no is null then person_detail.name_suffix
--                else spbpers_name_suffix
--         end as                                     Suffix--Suffix
        ,person_detail.name_suffix                  Suffix -- Suffix - G

--        ,case when pdrbene_seq_no = 1 or pdrbene_seq_no is null then null
--              else pdrbene_seq_no - 1 
--         end as                                     Dependent_Number--Dependent Number

--        ,case when pdrbene_seq_no = 1 or pdrbene_seq_no is null then null 
--              else coalesce(pdrbene_ssn, spbpers_ssn)
--         end as                                     Dependent_SSN

--        ,decode(pdrbene_brel_code, 'C', 'C',    --Child -> Child
--                                   'H', 'S',    --Husband -> Spouse
--                                   'M', 'S',    --Spouse -> Spouse
--                                   'O', 'D',    --Other -> Domestic Partner
--                                   'P', 'P',    --Parent -> Parent
--                                   'S', 'E',    --Self -> E
--                                   null, 'E',
--                                    --'T', ' ',    --Trust no code
--                                   'W', 'S',    --Wife -> Spouse
--                                   'NA') as Relationship--Relationship

--        ,case when pdrbene_seq_no = 1 or pdrbene_seq_no is null then person_detail.birth_date
--              else coalesce(pdrbene_birth_date, spbpers_birth_date)
--         end as                                     DOB--DOB
        ,person_detail.birth_date                   DOB -- DOB - H
         
--        ,case when pdrbene_seq_no = 1 or pdrbene_seq_no is null then person_detail.gender
--              else coalesce(pdrbene_sex_ind, spbpers_sex)
--         end as                                     Sex--Sex
        ,person_detail.gender                       Sex -- Sex - I
         
--        ,null                                       Disabled--Disabled
        ,person_detail.marital_status               Marital_Status -- Marital Status - J

        ,person_address.nation                      Country -- K
        
        ,person_address.street_line1                Address1--Address 1 -- L
        ,person_address.street_line2                Address2--Address 2 -- M
        ,person_address.city                        City--City -- N
        ,person_address.state_province              State--State -- O
        ,person_address.postal_code                 Zip--Zip -- P
        
        ,phones.home_phone                          Home_Phone -- Q
        ,phones.mobile_phone                        Mobile_Phone -- R
        ,phones.work_phone                          Work_Phone -- S
        
        ,internet_address_current.internet_address  Email -- T
        ,person_detail.email_preferred_address      Personal_Email--Personal Email -- u
        
--        ,case payroll_document.payroll_identifier when 'MN' then 12 else 26 end as Payroll_Frequency --Payroll Frequency
        ,case when employee.id in (select * from ten_pays_cte) then 10
                else nbrjobs_pays
         end as Payroll_Frequency
         
--        ,case payroll_document.payroll_identifier when 'MN' then 12 else 26 end as Deduction_Frequency --Deduction Frequency
        ,case when employee.id in (select * from ten_pays_cte) then 10
               when nbrjobs_pays = 12 then 12
               when nbrjobs_pays = 26 then 24
         end as Deduction_Frequency
         
        ,employee_position.annual_salary            Gross_Salary--Gross Salary
        
        ,null                                       Location_Number
        ,case substr(employee.home_organization,1,1) when 'B' then 'Broken Arrow'
                                                     when 'M' then 'Muskogee'
                                                     else 'Tahlequah'
                                                    end as Location --Location                                                    

    -- values are "President", "VP, Finance, Provost", "All Others", "Retirees", "Part Time" as of 10/2018
--        ,case when employee.employee_class = 10 then 'Executive'
--              when employee.employee_class = 14 then 'Directors/Deans'
--              when employee.employee_class like '3%' then 'Faculty'
--              when employee.employee_class = 90 then 'Retired PB'
--              else 'Staff'
        ,case when employee.employee_class = 10 then 'President'
              when employee.employee_class = 14 then 'VP, Finance, Provost'
              --when employee.employee_class like '3%' then 'Faculty'
              when employee.employee_class = 90 then 'Retirees'
              when employee.benefit_category = 'R1' then 'Retirees'
              when employee.full_or_part_time_ind <> 'F' then 'Part Time'
              else 'All Others'
        end as Job_Class --Job Class
/*        
--        ,payroll_document.payroll_identifier        Pay_Group --Pay Group
        ,case when employee.id in (select id from ten_pays_cte) then 'NSU 10'
              when nbrjobs_pays = 12 then 'NSU 12'
              when nbrjobs_pays = 26 then 'NSU 26'
         end as Pay_Group --Pay Group

        ,employee.home_organization_desc            Department--Department
        ,null                                       Hours_per_Week--Hours Per Week
        ,employee.adjusted_service_date             Hire_date--Hire date
        ,case employee.employee_status
            when 'A' then case when employee.leave_of_absence_reason is null then
                                                                                 case employee.employee_class
                                                                                     when '90' then 'PR'
                                                                                     else 'A'
                                                                                 end
                            else 'L'               
                          end
--            when 'T' then 'T'
            else employee.employee_status        
         end as                                     Status--Status 
        ,employee.last_work_date                    Termination_date--Termination date

        ,pdrdedn_bdca_code                          Plan_Name--Plan name
        ,ptrbdca_long_desc                          Product_Name--Product name
--        ,pdrdedn_opt_code1
        ,decode(pdrdedn_opt_code1,          10, 'EO', --empl only
                                            20, 'ES', --empl + spouse
                                            30, 'E1C', -- empl + child
                                            40, 'EC', --empl + children
                                            50, 'FA'  --empl + fam
                                            ,pdrdedn_opt_code1
                ) as                                Coverage_Tier--Coverage Tier

        ,null                                       Benefit_Amount--Benefit Amount
        ,null                                       Benefit_Frequency--Benefit Frequency
        ,case employee_status when 'A' then
            to_char((select ptrcaln_check_date from ptrcaln
                     where ptrcaln_year = 2019
                        and ptrcaln_pict_code = employee_position.pay_code
                        and ptrcaln_payno = 1),'DD-MON-YY') 
            else '0' 
         end as                                     Deduction_End_Date--Deduction End Date

        ,to_date('31-DEC-18','DD-MON-YY')           Termination_Date--Termination Date - actually coverage end date 
        ,case nbrjobs_pays when 12 then 12 else 24 end as Deduction_Frequency--Deduction Frequency
        ,(select ptrbdpl_amt1 from 
            (select ptrbdpl_bdca_code, ptrbdpl_code, ptrbdpl_amt1, row_number() over (partition by ptrbdpl_bdca_code,ptrbdpl_code order by ptrbdpl_effective_date desc) as rn from ptrbdpl)
            where ptrbdpl_bdca_code = pdrdedn_bdca_code
            and ptrbdpl_code = pdrdedn_opt_code1
            and rn = 1 
         ) as                                       EE_Cost--EE Cost
        ,case employee.benefit_category when 'EX' then 'S' else 'H' end as Pay_Type--Pay Type
        ,decode(employee.benefit_category, 'EX', 40,
                                           'NE', 40,
                                           'NO', 35,
                                           'PT', 35,
                                           'R1', 0,
                                           'TX', 35) Regualar_Hours--Regular Hours
        ,0                                          PTO_Hours--PTO Hours
        ,0                                          Overtime_Hours--Overtime Hours
        ,0                                          Holiday_Hours--Holiday Hours
        ,0                                          Qualified_Leave_Hours--Qualified Leave Hours
        ,0                                          Non_Qualified_Leave_Hours--Non-Qualified Leave Hours
        ,round(employee_position.annual_salary / employee_position.number_of_pays,2) Period_Regular_Earnings--Period Regular Earnings
        ,0                                          "Period_Non-regular_Earnings"--Period Non-regular earnings
-------------
*/
--;
--select * from pebempl where pebempl_pidm = 31091;
--select * from nbrjobs where nbrjobs_pidm = 31091;
--select nbrjobs_pidm,nbrjobs_posn,nbrjobs_suff, nbrjobs_pays, row_number() over (partition by nbrjobs_pidm order by nbrjobs_suff asc,nbrjobs_effective_date desc) jobs_rn
--                  from nbrjobs where nbrjobs_pidm = 31091;
--
--select pebempl_pidm,
--        nbrjobs_posn,nbrjobs_suff,jobs_rn
--        --pdrbcov_bdca_code

from 
    -- get all active employees join to "highest ranking" latest job (not all primary jobs are coded 00
    pebempl join (select nbrjobs_pidm,nbrjobs_posn,nbrjobs_suff, nbrjobs_pays, row_number() over (partition by nbrjobs_pidm order by nbrjobs_suff asc,nbrjobs_effective_date desc) jobs_rn
                  from nbrjobs) 
            on nbrjobs_pidm = pebempl_pidm and pebempl_empl_status = 'A'            
    ,employee -- for employee info
    ,person_detail -- for demographic info 
    ,person_address
	-- get deduction/benefit information with beneficiary/dependent info 
--    ,(select *
--      from pdrbded
--            join pdrdedn
--                on pdrbded_pidm = pdrdedn_pidm and pdrbded_bdca_code = pdrdedn_bdca_code and pdrdedn_status = 'A'
--            left outer join pdrbcov 
--                on pdrdedn_pidm = pdrbcov_pidm and pdrdedn_bdca_code = pdrbcov_bdca_code
--            left outer join pdrbene
--                on pdrbcov_pidm = pdrbene_pidm and pdrbcov_bene_seq_no = pdrbene_seq_no
--            left join spriden 
--                on pdrbene_bene_pidm = spriden_pidm and spriden_change_ind is null
--            left join spbpers
--                on spriden_pidm = spbpers_pidm
--     
--       where pdrbded_begin_date < sysdate and (pdrbded_end_date is null or pdrbded_end_date > sysdate)
--         and pdrdedn_effective_date = (select max(a.pdrdedn_effective_date) from pdrdedn a where pdrbded_pidm = a.pdrdedn_pidm and pdrbded_bdca_code = a.pdrdedn_bdca_code)
--     ) 
--    ,ptrbdca -- for deduction code description
    ,employee_position -- salary info

--;   select a entity_uid, home_phone, mobile_phone, work_phone from  
    ,(select a entity_uid, home_phone, mobile_phone, work_phone from
        (select entity_uid a,phone_number_combined home_phone from telephone_current where phone_type = 'PR') -- Permanent
        left join
        (select entity_uid b,phone_number_combined mobile_phone from telephone_current where phone_type = 'CL') -- Cell
        on a = b left join
        (   (select entity_uid c,phone_number_combined work_phone from telephone_current where phone_type = 'CT' ) --Campus Tahlequah
                union
            (select entity_uid c,phone_number_combined work_phone from telephone_current where phone_type = 'CM' ) --Campus Muskogee
                union
            (select entity_uid c,phone_number_combined work_phone from telephone_current where phone_type = 'CB' ) --Campus BA
        ) on a = c 
     ) phones
     ,internet_address_current

where jobs_rn = 1

  and employee.person_uid = pebempl_pidm
  and employee.employee_class not in (80,81,82,85,90,99) -- students, retirees, volunteers

  and pebempl_pidm = person_detail.person_uid

  and employee.person_uid = person_address.person_uid -- for address
  and person_address.address_rule = 'W2ADDR'

--  and pdrdedn_pidm = employee.person_uid -- for deduction costs
  --and pdrdedn_bdca_code = pdrbcov_bdca_code
  --and pdrdedn_effective_date = (select max(a.pdrdedn_effective_date) from pdrdedn a where a.pdrdedn_pidm = pdrdedn.pdrdedn_pidm and a.pdrdedn_bdca_code = pdrdedn.pdrdedn_bdca_code)
--  and substr(pdrdedn_bdca_code,1,1) in ('G','H','L','S') and pdrdedn_bdca_code not like 'L6%' and pdrdedn_bdca_code not like 'H9%'

--  and ptrbdca_code = pdrdedn_bdca_code

  and employee_position.person_uid = employee.person_uid -- for salary
  and employee_position.position = employee.position
  and employee_position.job_suffix = employee.job_suffix
  and employee_position.effective_start_date = (select max(a.effective_start_date) from employee_position a
                                                where a.person_uid = employee.person_uid
                                                  and a.position = employee.position
                                                  and a.job_suffix = employee.job_suffix)                                                  

  and phones.entity_uid = pebempl_pidm
  and internet_address_current.entity_uid = employee.person_uid
  and internet_address_current.internet_address_type = 'NSU'

and pebempl_pidm = 31091 --44770 --31091 --118769 --119501 --112773 --64581 --112773 -- 31091
--and pdrbded_bdca_code = 'H04'
--order by employee.name,pdrdedn_bdca_code;