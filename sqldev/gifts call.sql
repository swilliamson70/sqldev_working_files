begin
    nsu_bnr_alumni.gifts(
                        to_date('01-JAN-2011'), --p_start_date   in  date,
                        to_date('01-DEC-2019'), --p_end_date      in  date,
                        '1',  --p_ignore_dates  in  varchar2,
                        
                        11, --p_range_low in number
                        49, --p_range_high in number
                        '1', --p_ignore_rage in varchar2

                        'All,', --    p_designations  in  varchar2,
                        'All,', --'LTW,AVGEN,', --    p_campaigns     in  varchar2,
                        '0', --    p_include_deceased  in  varchar2,
                        '1', --    p_prim_spouse_unmarried in  varchar2, *
                        'All,', --'ATHLETICS,SHOWGRAD19,', --    p_solicitation_types    in  varchar2, *col N
                        'All,', --'ANON,HONR,', --    p_class_types   in  varchar2, * col R-T
                        null, --'in honor of', --    p_comment       in  varchar2, * col U
                        null, --'N00118367', --null, --    p_associated_id in  varchar2, *col AT
                        null, --'N00053339', --null, --    p_id            in  varchar2,
                        'All,', -- 'ALND,EMPC,', --'All,', --    p_donor_cats    in  varchar2, *col AW
                        'NOC,NEM,NDN,', -- All,', --    p_exclusion_codes   in  varchar2,

                        'gifts_test3', --p_file_name     in  varchar2,
                        1); --p_include_parms in  varchar2)
end;

