declare
  v_activity_codes            VARCHAR2(5000); -- parm_MC_ActivityCode
  v_all_activities            VARCHAR2(10) := 1; -- parm_CB_AllActivities
  v_activity_years            VARCHAR2(5000); -- parm_lb_activity_years
  v_all_years                 VARCHAR2(10) := 1; -- cb_activity_years
  v_leadership_codes          VARCHAR2(5000); -- parm_MC_leadership
  v_all_leadership            VARCHAR2(10) := 1; -- cb_leadership

--Degree Info 
  v_degree_date_start         DATE; -- parm_DT_DegreeDateStart
  v_degree_date_end           DATE; -- parm_DT_DegreeDateEnd
  v_ignore_degree_dates       VARCHAR2(10) := 1; -- parm_CB_Ignore_Degree_Dates
  -- these are the academic years not the years in which people graduated
  v_grad_years                VARCHAR2(5000); -- parm_LB_GradYear
  v_all_grad_years            VARCHAR2(10) := 1;-- parm_CB_GradYears

  v_degrees                   VARCHAR2(5000); -- parm_MC_Degrees
  v_all_degrees               VARCHAR2(10) := 1; -- parm_CB_AllDegrees
  
  v_majors                    VARCHAR2(5000); -- parm_MC_Major
  v_all_majors                VARCHAR2(10) := 1; -- parm_CB_AllMajors

--Demographics
  v_deceased                  VARCHAR2(10) := 0; -- parm_CB_deceased - Include Deceased?
  
  v_veteran                   VARCHAR2(10) := 'All'; -- lb_veteran (All, Y, N)
  
  v_prim_spouse_unmarried     VARCHAR2(10) := 1; -- parm_CB_PrimSpouse_Unmarried
  
  v_household_ind             VARCHAR2(10) := 'All'; -- parm_LB_HouseholdInd (All, Y,N)
  --p_ignore_household_ind    VARCHAR2(10) := '1'; -- parm_CB_HouseholdInd - made redundant
  
  v_zipcodes                  VARCHAR2(5000); -- parm_MC_ZipCode
  v_all_zipcodes              VARCHAR2(10) := 1; -- parm_CB_AllZipCodes
  
  v_ignore_zip_use_state      VARCHAR2(10); -- parm_CB_ignore_zip_use_state
  v_state_codes               VARCHAR2(5000) := 'All'; -- parm_MC_StateCode
  
  v_city                      VARCHAR2(60); -- parm_EB_City
  v_use_city                  VARCHAR2(10) := 1; -- parm_CB_enter_name - 0 if use city is overriding state/zip/county
  v_county_codes              VARCHAR2(5000); -- parm_MC_CountryCode
  v_all_counties              VARCHAR2(10) := 1; -- parm_CB_AllCountyCodes

--Donor Information
  v_donor_cats                VARCHAR2(5000); -- parm_MC_DonorCats
  v_all_donor_cats            VARCHAR2(10) := 1; -- parm_CB_AllDonorCats
  
  v_gift_capacity             VARCHAR2(60); -- parm_LB_GiftCapRange -- advancement_rating_slot type1
  v_all_gift_capacities       VARCHAR2(10) := 1; -- parm_CB_AllGCrranges
  
  v_wealth_engine_desg        VARCHAR2(60); -- parm_LB_WealthEngineDesg -- advancement_rating_slot type2
  v_all_wealth_engine_desg    VARCHAR2(10) := 1; -- parm_CB_AllWEdesignations
  
  v_spec_purpose_types        VARCHAR2(500); -- parm_MC_SP_Types
  v_all_spec_purpose_types    VARCHAR2(10) := 1; -- parm_CB_SP_Types
  
  v_spec_purpose_groups       VARCHAR2(500); -- parm_MC_SP_Groups
  v_all_spec_purpose_groups   VARCHAR2(10) := 1; -- parm_CB_SP_Groups
  
  v_exclusion_codes           VARCHAR2(500); -- parm_MC_ExclusionCode
  v_all_exclusion_codes       VARCHAR2(10) := 1; -- parm_CB_AllExclusions
  
  v_mail_codes                VARCHAR2(500); -- parm_MC_mail_codes
  v_all_mail_codes            VARCHAR2(10) := 1; -- parm_CB_AllMailCodes

-- Gift Dates
  v_giving_start_date         DATE; -- parm_DT_GivingStart
  v_giving_end_date           DATE; -- parm_DT_GivingEnd
  v_ignore_gift_dates         VARCHAR2(10) := 1; -- parm_CB_Ignore_Gift_Dates

-- File Name
  v_file_name                 VARCHAR2(30);
  v_include_parameters        VARCHAR2(10) := 1;
    
begin
    nsu_alumni_standard_const(
  v_activity_codes,
  v_all_activities,
  v_activity_years,
  v_all_years,
  v_leadership_codes,
  v_all_leadership,

--Degree Info
  v_degree_date_start,
  v_degree_date_end,
  v_ignore_degree_dates,
  v_grad_years,
  v_all_grad_years,
  v_degrees,
  v_all_degrees,
  v_majors,
  v_all_majors,

--Demographics
  v_deceased,
  v_veteran,
  v_prim_spouse_unmarried,
  v_household_ind,
  --v_ignore_household_ind,
  v_zipcodes,
  v_all_zipcodes,
  v_ignore_zip_use_state,
  v_state_codes,
  v_city,
  v_use_city,
  v_county_codes,
  v_all_counties,

--Donor Information
  v_donor_cats,
  v_all_donor_cats,
  v_gift_capacity,
  v_all_gift_capacities,
  v_wealth_engine_desg,
  v_all_wealth_engine_desg,
  v_spec_purpose_types,
  v_all_spec_purpose_types,
  v_spec_purpose_groups,
  v_all_spec_purpose_groups,
  v_exclusion_codes,
  v_all_exclusion_codes,
  v_mail_codes,
  v_all_mail_codes,

-- Gift Dates
  v_giving_start_date,
  v_giving_end_date,
  v_ignore_gift_dates,
  v_file_name,
  v_include_parameters
    );
end;