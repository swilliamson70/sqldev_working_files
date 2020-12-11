delete from shrtatt
where 
    SHRTATT_PIDM||SHRTATT_TRIT_SEQ_NO||SHRTATT_TRAM_SEQ_NO|| SHRTATT_TRCR_SEQ_NO|| SHRTATT_TRCE_SEQ_NO||SHRTATT_ATTR_CODE
 in
(select 
    to_char(SHRTATT_PIDM)
    || to_char(SHRTATT_TRIT_SEQ_NO)
    || to_char(SHRTATT_TRAM_SEQ_NO)
    || to_char(SHRTATT_TRCR_SEQ_NO)
    || to_char(SHRTATT_TRCE_SEQ_NO)
    ||trim(SHRTATT_ATTR_CODE)
from (  
    select
        shrtatt_pidm
        , spriden_id
        , shrtatt_trit_seq_no
        , shrtatt_tram_seq_no
        , shrtatt_trcr_seq_no
        , shrtatt_trce_seq_no
    
        , shrtrit_seq_no    
        , shrtatt_attr_code
        , shrtrit_sbgi_code
        , sovsbgv_desc
        , sovsbgv_stat_code
        , (
            select distinct first_value(sorbtag_hlwk_code) 
                over (partition by sorbtag_sbgi_code
                      order by sorbtag_sbgi_code,sorbtag_term_code_eff desc) 
            from sorbtag
            where sorbtag_sbgi_code = shrtrit_sbgi_code
                and sorbtag_term_code_eff <= shrtram_term_code_entered
        ) hlwk_code
    
        , shrtram_trit_seq_no
        , shrtram_seq_no
        , shrtram_levl_code
        , shrtram_attn_period
        , shrtram_term_code_entered
    
        , shrtrcr_trit_seq_no
        , shrtrcr_tram_seq_no
        , shrtrcr_seq_no
        , shrtrcr_trans_course_name
        , shrtrcr_trans_course_numbers
        , shrtrcr_term_code
        , shrtrcr_tcrse_title
    
        , shrtrce_trit_seq_no
        , shrtrce_tram_seq_no
        , shrtrce_seq_no
        , shrtrce_trcr_seq_no
        , shrtrce_term_code_eff
    
        , shrtrce_levl_code 
    
    --select *  
    from
        shrtatt -- transfer attribs
        join spriden
            on shrtatt_pidm = spriden_pidm
            and spriden_change_ind is null
            and shrtatt_pidm = 1292
        
        join shrtrit -- transfer institution
            on shrtatt_pidm = shrtrit_pidm
            and shrtatt_trit_seq_no = shrtrit_seq_no
            and shrtatt_attr_code in ('UDIV','YR4')
    
        join shrtram -- transfer admit
            on shrtatt_pidm = shrtram_pidm
            and shrtrit_seq_no = shrtram_trit_seq_no
            and shrtatt_tram_seq_no = shrtram_seq_no
    
        join shrtrcr -- transfer courses
            on shrtatt_pidm = shrtrcr_pidm
            and shrtrit_seq_no = shrtrcr_trit_seq_no
            and shrtram_seq_no = shrtrcr_tram_seq_no
            and shrtatt_trcr_seq_no = shrtrcr_seq_no 
    
        join shrtrce -- transfer equiv
            on shrtatt_pidm = shrtrce_pidm
            and shrtatt_trce_seq_no = shrtrce_seq_no      
            and shrtrit_seq_no = shrtrce_trit_seq_no
            and shrtram_seq_no = shrtrce_tram_seq_no 
            and shrtrcr_seq_no = shrtrce_trcr_seq_no
        
        join sovsbgv
            on sovsbgv_code = shrtrit_sbgi_code 
    )

where hlwk_code in ('AS','NDG')
)
;
