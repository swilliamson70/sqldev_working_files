--desc GOTCMME;
--select * from spriden where spriden_last_name = 'Coyote'; --2076 Wyle E Coyote
--select * from spraddr where spraddr_pidm = 2076;
declare
    -- Code to identify the source of data input into the common matching process. VARCHAR2(20) Required
    v_cmsc_code         gorcmsr.gorcmsr_cmsc_code%TYPE := 'PERSON';
    --Overall result of the common matching process.
    -- M if a match was found, S if multiple possible matches were found , otherwise N for new. VARCHAR2(1) Required
    v_match_status_out  gotcmrt.gotcmrt_result_ind%TYPE;
    -- Internal identification number of the matching entity. NUMBER(8)
    v_match_pidm_out    gotcmrt.gotcmrt_pidm%TYPE;

begin

/** Procedure to insert a record in the global temporary table used as input into the common matching process.
* @param p_last_name  Last name of person or non-person name to match. VARCHAR2(60) Required
* @param p_entity_cde  Identifies whether the record is for a person or non-person. Valid values:  P - person, C - non-person, B - both. VARCHAR2(1) Required
* @param p_first_name  First name of person to match. VARCHAR2(15)
* @param p_mi  Middle name of person to match. VARCHAR2(15)
* @param p_id  Identification number of person or non-person to match. VARCHAR2(9)
* @param p_street_line1  First line of the address to match. VARCHAR2(30)
* @param p_city  City of the address to match. VARCHAR2(20)
* @param p_stat_code  State of the address to match. VARCHAR2(3)
* @param p_zip  Zip code of the address to match. VARCHAR2(10)
* @param p_natn_code  Nation/Country of the address to match. VARCHAR2(5)
* @param p_cnty_code  County of the address to match. VARCHAR2(5)
* @param p_phone_area  Telephone number area code to match. VARCHAR2(3)
* @param p_phone_number  Telephone number to match. VARCHAR2(7)
* @param p_ssn  Social Security Number, Social Insurance Number or Tax Identification Number to match. VARCHAR2(9)
* @param p_birth_day  Day of birth to match. VARCHAR2(2)
* @param p_birth_mon  Month of birth to match. VARCHAR2(2)
* @param p_birth_year  Year of birth to match. VARCHAR2(4)
* @param p_sex  Gender to match. M - Male, F - Female, N - Unknown VARCHAR2(1)
* @param p_email_address  The e-mail address to match. VARCHAR2(90)
* @param p_addid_code Additional Identification Type Code.VARCHAR2(4)
* @param p_addid Additional Identification Code VARCHAR2(50)
*/
    gp_common_matching.p_insert_gotcmme(
         p_last_name => 'Williamson'
        ,p_first_name => 'Scott'
        --,p_ssn => '111111111'
        ,p_entity_cde => 'P');

--PROCEDURE p_common_matching ( p_cmsc_code         IN   gorcmsr.gorcmsr_cmsc_code%TYPE,
--                              p_match_status_out  OUT  gotcmrt.gotcmrt_result_ind%TYPE,
--                              p_match_pidm_out    OUT  gotcmrt.gotcmrt_pidm%TYPE )

    gp_common_matching.p_common_matching( v_cmsc_code,v_match_status_out, v_match_pidm_out);
    dbms_output.put_line(v_cmsc_code ||','|| v_match_status_out ||','|| v_match_pidm_out);
    
end;
--select * from gotcmme;
