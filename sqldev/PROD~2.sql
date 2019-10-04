--50 rows in 16.682s

WITH
     w_shrattr AS
    (
        SELECT  /*+ materialize */shrattr_pidm
            , shrattr_term_code
            , shrattr_tckn_seq_no
        FROM shrattr
        WHERE SUBSTR(shrattr_attr_code,1,2) = 'RP'
    )
     , w_shrtckn AS 
    (
        SELECT /*+ materialize */shrtckn_pidm
                    , shrtckn_term_code
                    , shrtckn_subj_code
                    , shrtckn_crse_numb
                    , shrtckn_repeat_course_ind
                    , shrtckn_crse_title
                    , shrtckn_seq_no
                    , shrtckn_crn
        FROM shrtckn
        WHERE (
                    shrtckn_repeat_course_ind         <> 'E'
                    OR shrtckn_repeat_course_ind IS NULL
                )
         AND SUBSTR(shrtckn_crse_numb,2,3) <> '000'
         AND SUBSTR(shrtckn_crse_numb,2,3) <> '999'
         AND SUBSTR(shrtckn_subj_code,1,3) <> 'UNC'
         AND NOT EXISTS (   SELECT 'X'
                            FROM w_shrattr
                            WHERE shrtckn_pidm = w_shrattr.shrattr_pidm
                             AND shrtckn_term_code = w_shrattr.shrattr_term_code
                             AND shrtckn_seq_no = w_shrattr.shrattr_tckn_seq_no
                        )
    )     
     , w_shrtckg AS
    (select * from 
        (select shrtckg_pidm
            , shrtckg_term_code
            , shrtckg_tckn_seq_no
            , shrtckg_credit_hours
            , shrtckg_grde_code_final
            , shrtckg_gmod_code
            , shrtckg_seq_no
            , row_number() over (partition by shrtckg_pidm
                                    , shrtckg_term_code
                                    , shrtckg_tckn_seq_no
                             order by shrtckg_pidm
                                    , shrtckg_term_code
                                    , shrtckg_tckn_seq_no
                                    , shrtckg_seq_no desc) as seq_row
            from shrtckg
            WHERE   shrtckg_gmod_code <> 'D'
             AND shrtckg_grde_code_final NOT IN ('W','AU','F','AW','I','N','NA','X','WF','U')             
         )
    where seq_row = 1 
    )
/*
    , w_shrdgmr AS 
    (SELECT * FROM -- add pidm pop or do everyone?
        (
        SELECT shrdgmr_pidm 
            , shrdgmr_levl_code
            , MAX(shrdgmr_term_code_grad)
        FROM shrdgmr
        WHERE shrdgmr_degs_code = 'AW'
        )
    
    )
*/    
--select * from w_shrtckg;
 			SELECT
  				'NSU' "SRCE"
  			  , s3.shrtckn_pidm "PIDM"
  			  , s3.shrtckn_term_code "TERM"
 			  , s5.shrtckl_levl_code "LVL"
  			  , s3.shrtckn_subj_code "SUBJ"
  			  , s3.shrtckn_crse_numb "CRS_NUM"
  			  , s4.shrtckg_credit_hours "CHRS"
  			  , s4.shrtckg_grde_code_final "GRADE"
  			  , s4.shrtckg_gmod_code "GMOD"
  			  , s3.shrtckn_repeat_course_ind "REP_IND"
  			  , s3.shrtckn_crse_title "TITLE"
  			  , 207263 "INST"
  			  , --NSU IPEDS Code
  				99 "ATT_PERIOD"
  			  , s3.shrtckn_seq_no "CRS_SEQ1"
  			  , s3.shrtckn_crn "CRS_SEQ2"
  			FROM w_shrtckn s3
                JOIN
                
                (SELECT shrtckg_pidm
                    , shrtckg_term_code
                    , shrtckg_tckn_seq_no
                    , shrtckg_credit_hours
                    , shrtckg_grde_code_final
                    , shrtckg_gmod_code
                    , shrtckg_seq_no
                 FROM w_shrtckg) s4
                        ON s3.shrtckn_pidm           = s4.shrtckg_pidm
                        AND s3.shrtckn_term_code  = s4.shrtckg_term_code
                        AND s3.shrtckn_seq_no     = s4.shrtckg_tckn_seq_no
                                                                                    
                JOIN

                
                shrtckl s5 on s3.shrtckn_pidm       = s5.shrtckl_pidm
                            AND s3.shrtckn_term_code  = s5.shrtckl_term_code
                            AND s3.shrtckn_seq_no     = s5.shrtckl_tckn_seq_no
                        	AND s3.shrtckn_term_code >  (
                                                            SELECT
                                                                NVL(MAX(shrdgmr_term_code_grad),'000000')
                                                            FROM
                                                                shrdgmr
                                                            WHERE
                                                                shrdgmr_pidm          = s3.shrtckn_pidm
                                                                AND shrdgmr_levl_code = s5.shrtckl_levl_code
                                                                AND shrdgmr_degs_code = 'AW'
                                                        )                            

;




  				

 