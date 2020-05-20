-- WHERE using a CASE statement

select * from stvcnty 
where substr(stvcnty_code,1,2) = :state;

-- great if you have one value, but if you want an 'All states' option... say from an Argos dropdown:

select * from stvcnty
where substr(stvcnty_code,1,2) in (
    select 'HI' return_code from dual where :state = 'HI'
    union
    select 'RI' from dual where :state = 'RI'
    union
    select distinct substr(stvcnty_code,1,2) from stvcnty where :state = 'All'
    )
;
