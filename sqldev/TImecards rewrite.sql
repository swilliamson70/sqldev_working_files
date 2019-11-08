SELECT 
    ee_spriden.spriden_id               ee_id
    ,ee_spriden.spriden_last_name       ee_last_name
    ,ee_spriden.spriden_first_name      ee_first_name
    ,ee_spriden.spriden_mi              ee_mi
    ,ee_goremal.goremal_email_address   ee_email
    ,perjobs.perjobs_orgn_code_ts       ee_org
    ,perjobs.perjobs_year
    ,perjobs.perjobs_pict_code
    ,perjobs.perjobs_payno
    ,perjobs.perjobs_seqno
    ,perjobs.perjobs_action_ind
    ,perjobs.perjobs_status_ind
    ,perrout.perrout_appr_posn
    ,appr_spriden.spriden_id            appr_id
    ,appr_spriden.spriden_last_name     appr_last_name
    ,appr_spriden.spriden_first_name    appr_first_name
    ,appr_spriden.spriden_mi            appr_mi
    ,appr_goremal.goremal_email_address appr_email
    ,vp_org.financial_manager_id        vp_id
    ,vp_org.financial_manager_name      vp_name
    ,CASE
        WHEN vp_org.financial_manager_uid = 131297 -- Steven Turner N00131182
            THEN 'loguel@nsuok.edu'
        WHEN appr_spriden.spriden_pidm = vp_org.financial_manager_uid -- if you don't want vp direct reports going to that vp
            THEN 'loguel@nsuok.edu'
        ELSE
            vp_goremal.goremal_email_address
    END                                 vp_email

FROM    
    perjobs
    JOIN spriden ee_spriden 
        ON perjobs_pidm = ee_spriden.spriden_pidm 
        AND ee_spriden.spriden_change_ind IS NULL
             JOIN goremal ee_goremal 
                ON ee_spriden.spriden_pidm = ee_goremal.goremal_pidm 
                AND ee_goremal.goremal_emal_code = 'NSU'
             JOIN perrout 
                ON perrout_jobs_seqno = perjobs_seqno 
                AND perrout_appr_seqno = 1
    ,spriden appr_spriden
        JOIN goremal appr_goremal
            ON appr_spriden.spriden_change_ind IS NULL 
            AND appr_spriden.spriden_pidm = appr_goremal.goremal_pidm 
            AND appr_goremal.goremal_emal_code = 'NSU'
    ,organization_hierarchy vp_org 
        JOIN goremal vp_goremal 
            ON vp_org.financial_manager_uid = vp_goremal.goremal_pidm 
            AND vp_goremal.goremal_emal_code = 'NSU'

WHERE 
    perjobs_year = EXTRACT(YEAR FROM sysdate)
    AND perjobs_pict_code = 'BW'
    AND perjobs_payno = (   SELECT payno
                            FROM(   SELECT 
                                        ptrcaln_payno payno
                                        , row_number() OVER (PARTITION BY ptrcaln_year, ptrcaln_pict_code ORDER BY ptrcaln_payno desc) rn
                                    FROM 
                                        ptrcaln
                                    WHERE 
                                        ptrcaln_year = EXTRACT(YEAR FROM SYSDATE)
                                        AND ptrcaln_pict_code = 'BW'
                               AND ptrcaln_end_date <= TRUNC(SYSDATE)
                             )
                       WHERE rn = 1
                    )
  AND appr_spriden.spriden_pidm = perrout_appr_pidm
  AND vp_org.organization_code = (  SELECT 
                                        organization_level_2
                                    FROM 
                                        organization_hierarchy
                                    WHERE 
                                        organization_code =  perjobs_orgn_code_ts
                                        AND chart_of_accounts = perjobs_coas_code_ts) 
  AND vp_org.chart_of_accounts = perjobs_coas_code_ts
  
  AND perjobs.perjobs_action_ind = 'T'
  AND perjobs.perjobs_status_ind NOT IN ('C','A')

ORDER BY vp_org.financial_manager_name
        ,ee_spriden.spriden_last_name
        ,ee_spriden.spriden_first_name
        ,ee_spriden.spriden_mi 
;
 
SELECT * FROM perjobs
WHERE perjobs_pidm = 31091; 
SELECT  FROM ptrcaln;
SELECT * FROM perrout WHERE perrout_jobs_seqno = 187544;
SELECT * FROM all_tab_comments WHERE table_name = 'PERROUT';
                       SELECT payno
                       FROM (SELECT ptrcaln_payno payno, row_number() over (partition by ptrcaln_year, ptrcaln_pict_code order by ptrcaln_payno desc) rn
                             FROM ptrcaln
                             WHERE ptrcaln_year = extract(year FROM sysdate)
                               AND ptrcaln_pict_code = 'BW'
                               AND ptrcaln_end_date <= trunc(sysdate)
                            )
                          
                       WHERE rn = 1;
                       
SELECT * FROM nbrjobs WHERE nbrjobs_posn = 'X99684';

SELECT * FROM employee_position
WHERE position_contract_type = 'P' AND position_status = 'A' AND effective_end_date >= sysdate;

SELECT vp_org.organization_level_2,vp_org.financial_manager_uid,vp_org.financial_manager_name FROM organization_hierarchy vp_org
WHERE  organization_code =  (SELECT organization_level_2 FROM organization_hierarchy
        WHERE organization_code = 'T60101') 
  AND chart_of_accounts = 'A' --perjobs_coas_code_ts
;
SELECT * FROM organization_hierarchy;