  	SELECT
  		ac1.SRCE
  	  , ac1.PIDM
  	  , ac1.TERM
  	  , ac1.LVL
  	  , ac1.SUBJ
  	  , ac1.CRS_NUM
  	  , ac1.GRADE
--  	  , shrgrde_numeric_value GRD_WT
  	  , ac1.GMOD
  	  , ac1.chrs
  	  , ac1.REP_IND
--  	  , ar.ctr
--  	  , (
--  			SELECT
--  				MAX(shrdgmr_term_code_grad)
--  			FROM
--  				shrdgmr
--  			WHERE
--  				shrdgmr_pidm          = ac1.pidm
--  				AND shrdgmr_levl_code = ac1.lvl
--  				AND shrdgmr_degs_code = 'AW'
--  		)
--  		deg_term
--  	  , spriden_id
--  	  , NVL(
--  			 (
--  				 SELECT DISTINCT
--  					 'Y'
--  				 FROM
--  					 scbcrse
--  				 WHERE
--  					 scbcrse_subj_code     = ac1.SUBJ
--  					 AND scbcrse_crse_numb = ac1.CRS_NUM
--  			)
--  			,'N') InBanner
  	  , ac1.TITLE
  	  , ac1.INST
  	  , ac1.ATT_PERIOD
  	  , ac1.CRS_SEQ1
  	  , ac1.CRS_SEQ2
  	  ,
  		(
  			CASE
  				WHEN SUBSTR(ac1.CRS_NUM,LENGTH(ac1.CRS_NUM),1) = TO_CHAR(ac1.chrs)
  					THEN '1'
  					ELSE '0'
  			END
  		)
  		chrs_eqiv
  	FROM
  		(
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
  			FROM
  				shrtckn s3
  			  , shrtckg s4
  			  , shrtckl s5
  			WHERE
  				s3.shrtckn_pidm           = s4.shrtckg_pidm
  				AND s3.shrtckn_term_code  = s4.shrtckg_term_code
  				AND s3.shrtckn_seq_no     = s4.shrtckg_tckn_seq_no
  				AND s3.shrtckn_pidm       = s5.shrtckl_pidm
  				AND s3.shrtckn_term_code  = s5.shrtckl_term_code
  				AND s3.shrtckn_seq_no     = s5.shrtckl_tckn_seq_no
  				AND s4.shrtckg_gmod_code <> 'D'
  				AND s4.shrtckg_grde_code_final NOT IN ('W','AU','F','AW','I','N','NA','X','WF','U')
  				AND s4.shrtckg_seq_no =
  				(
  					SELECT
  						MAX(sm.shrtckg_seq_no)
  					FROM
  						shrtckg sm
  					WHERE
  						s4.shrtckg_pidm            = sm.shrtckg_pidm
  						AND s4.shrtckg_term_code   = sm.shrtckg_term_code
  						AND s4.shrtckg_tckn_seq_no = sm.shrtckg_tckn_seq_no
  				)
  				AND
  				(
  					s3.shrtckn_repeat_course_ind         <> 'E'
  					OR s3.shrtckn_repeat_course_ind IS NULL
  				)
  				AND SUBSTR(s3.shrtckn_crse_numb,2,3) <> '000'
  				AND SUBSTR(s3.shrtckn_crse_numb,2,3) <> '999'
  				AND SUBSTR(s3.shrtckn_subj_code,1,3) <> 'UNC'
  				AND s3.shrtckn_term_code              >
  				(
  					SELECT
  						NVL(MAX(shrdgmr_term_code_grad),'000000')
  					FROM
  						shrdgmr
  					WHERE
  						shrdgmr_pidm          = s3.shrtckn_pidm
  						AND shrdgmr_levl_code = s5.shrtckl_levl_code
  						AND shrdgmr_degs_code = 'AW'
  				)
  				AND NOT EXISTS
  				(
  					SELECT
  						'X'
  					FROM
  						shrattr
  					WHERE
  						s3.shrtckn_pidm                   = shrattr_pidm
  						AND s3.shrtckn_term_code          = shrattr_term_code
  						AND s3.shrtckn_seq_no             = shrattr_tckn_seq_no
  						AND SUBSTR(shrattr_attr_code,1,2) = 'RP'
  				)
  			UNION
  			SELECT
  				'XFER' "SRCE"
  			  , s2.shrtrce_pidm "PIDM"
  			  , s2.shrtrce_term_code_eff "TERM"
  			  , s2.shrtrce_levl_code "LVL"
  			  , s2.shrtrce_subj_code "SUBJ"
  			  , s2.shrtrce_crse_numb "CRS_NUM"
  			  , s2.shrtrce_credit_hours "CHRS"
  			  , s2.shrtrce_grde_code "GRADE"
  			  , s2.shrtrce_gmod_code "GMOD"
  			  , s2.shrtrce_repeat_course "REP_IND"
  			  , s2.shrtrce_crse_title "TITLE"
  			  , s2.shrtrce_trit_seq_no "INST"
  			  , s2.shrtrce_tram_seq_no "ATT_PERIOD"
  			  , s2.shrtrce_trcr_seq_no "CRS_SEQ1"
  			  , TO_CHAR(s2.shrtrce_seq_no) "CRS_SEQ2"
  			FROM
  				shrtrce s2
  			WHERE
  				SUBSTR(s2.shrtrce_crse_numb,2,3)     <> '000'
  				AND SUBSTR(s2.shrtrce_crse_numb,2,3) <> '999'
  				AND SUBSTR(s2.shrtrce_subj_code,1,3) <> 'UNC'
  				AND s2.shrtrce_gmod_code             <> 'D'
  				AND s2.shrtrce_grde_code NOT IN ('W','AU','F','AW','I','N','NA','X','WF','U')
  				AND
  				(
  					s2.shrtrce_repeat_course         <> 'E'
  					OR s2.shrtrce_repeat_course IS NULL
  				)
  				AND s2.shrtrce_term_code_eff >
  				(
  					SELECT
  						NVL(MAX(shrdgmr_term_code_grad),'000000')
  					FROM
  						shrdgmr
  					WHERE
  						shrdgmr_pidm          = s2.shrtrce_pidm
  						AND shrdgmr_levl_code = s2.shrtrce_levl_code
  						AND shrdgmr_degs_code = 'AW'
  				)
  				AND NOT EXISTS
  				(
  					SELECT
  						'X'
  					FROM
  						shrtatt
  					WHERE
  						s2.shrtrce_pidm                   = shrtatt_pidm
  						AND s2.shrtrce_trit_seq_no        = shrtatt_trit_seq_no
  						AND s2.shrtrce_tram_seq_no        = shrtatt_tram_seq_no
  						AND s2.shrtrce_trcr_seq_no        = shrtatt_trcr_seq_no
  						AND s2.shrtrce_seq_no             = shrtatt_trce_seq_no
  						AND SUBSTR(shrtatt_attr_code,1,2) = 'RP'
  				)
  		)
          		ac1
;