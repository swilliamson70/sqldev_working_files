
select 
    org
    ,l2_org
    ,ftvorgn_coas_code
    ,ftvorgn_fmgr_code_pidm
    ,f_format_name(ftvorgn_fmgr_code_pidm,'LFMI') name
from (
        select distinct
            level2.ftvorgn_orgn_code org
            , substr(SYS_CONNECT_BY_PATH(level2.ftvorgn_orgn_code, '-'),2,6) AS l2_org
        from ftvorgn level2
        where level2.ftvorgn_eff_date = (select
                                            max(orgn.ftvorgn_eff_date)
                                        from ftvorgn orgn 
                                        where 
                                            orgn.ftvorgn_orgn_code = level2.ftvorgn_orgn_code 
                                            and orgn.ftvorgn_coas_code = level2.ftvorgn_coas_code)
        start with level2.ftvorgn_orgn_code_pred = 'L10000'
        connect by prior level2.ftvorgn_orgn_code = level2.ftvorgn_orgn_code_pred
    ) level2 
        left join ftvorgn 
            on l2_org = ftvorgn_orgn_code
            and ftvorgn.ftvorgn_eff_date = (select 
                                                max(orgn.ftvorgn_eff_date) 
                                            from ftvorgn orgn 
                                            where
                                                orgn.ftvorgn_orgn_code = ftvorgn.ftvorgn_orgn_code 
                                                and orgn.ftvorgn_coas_code = ftvorgn.ftvorgn_coas_code)
;
