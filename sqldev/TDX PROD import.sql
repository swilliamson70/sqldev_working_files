--employees
-----------------------------FORMATTED----------------------------------------------
WITH employees
AS (
	SELECT DISTINCT 'USER' AS "User_TYPE"
		, gobtpac.GOBTPAC_EXTERNAL_USER || '@nsuok.edu' Username
		, 'TeamDynamix' AS "Authentication_Provider"
		, gobtpac.GOBTPAC_EXTERNAL_USER AS "Authentication_Username"
		, 'Client' AS "Security_Role"
		, CASE
			WHEN spriden.spriden_pidm = 91290 --Mike Franke
				THEN 'Mike'
			ELSE spriden.SPRIDEN_FIRST_NAME
			END AS "First_Name"
		, spriden.SPRIDEN_LAST_NAME AS "Last_Name"
		, CASE
			WHEN spriden.spriden_pidm = 91290 --Mike Franke
				THEN ''
			ELSE spriden.SPRIDEN_MI
			END AS "Middle_Name"
		, 'Northeastern State University' AS "Organization"
		, CASE
			WHEN pebempl_ECLS_CODE = 90
				OR pebempl_ECLS_CODE = 92
				THEN 'Retired'
			ELSE replace(nbrjobs.NBRJOBS_DESC,',','')
			END AS "Title"
		, CASE
			WHEN pebempl_ECLS_CODE = 90
				OR pebempl_ECLS_CODE = 92
				THEN 'Retired'
			ELSE FTVORGN_TITLE
			END AS "Acct_Dept"
		, spriden.SPRIDEN_ID AS "Organizational_ID"
		, '' AS "Alternate_ID"
		, CASE
			WHEN pebempl_ECLS_CODE = 90
				OR pebempl_ECLS_CODE = 92
				THEN 'FALSE'
			ELSE 'TRUE'
			END AS "Is_Employee"
		, gobtpac.GOBTPAC_EXTERNAL_USER || '@nsuok.edu' AS "Primary_Email"
		, gobtpac.GOBTPAC_EXTERNAL_USER || '@nsuok.edu' AS "Alert_Email"
		, '' AS "Work_Phone"
		, '' AS "Work_Postal_Code"
		, '4' AS "Time_Zone_ID"
		, CASE
			WHEN pebempl_ECLS_CODE = 90
				OR pebempl_ECLS_CODE = 92
				THEN NULL
			WHEN nbrjobs2.nbrjobs_status = 'T'
				THEN NULL
                        WHEN FTVORGN_TITLE = 'IT Client Services' and pebempl_ecls_code in (80,81,82,85,83)
                                THEN (SELECT gobtpac_external_user || '@nsuok.edu'
                                		FROM GOBTPAC
                                		JOIN nbrjobs ON nbrjobs_pidm = gobtpac_pidm
                                		WHERE nbrjobs_posn = 'N99835'
                                			AND nbrjobs_status <> 'T'
                                			AND nbrjobs_effective_date =(SELECT MAX(x1.nbrjobs_effective_date)
																		 FROM nbrjobs x1
																		 WHERE x1.nbrjobs_pidm = nbrjobs.nbrjobs_pidm
                              											 AND x1.nbrjobs_posn = nbrjobs.nbrjobs_posn
                             				 							 AND x1.nbrjobs_suff = nbrjobs.nbrjobs_suff
                             				 							AND x1.nbrjobs_effective_date <= SYSDATE)
                             		  )--'hulbert@nsuok.edu'
                        WHEN nbbposn_posn_reports is null and gobtpac3.gobtpac_external_user is null
                                THEN NULL
                        WHEN nbbposn_posn_reports is null
                                THEN gobtpac3.gobtpac_external_user || '@nsuok.edu'
			ELSE gobtpac2.gobtpac_external_user  || '@nsuok.edu'
			END AS "Reports_To_Username"
		, 'TRUE' AS "HasTDKnowledgeBase"
		, 'TRUE' AS "HasTDNews"
		, 'TRUE' AS "HasTDRequests"
		, 'TRUE' AS "HasTDTicketRequests"
                , CASE
			WHEN pebempl_ECLS_CODE in( 90,92,80,81,82,85,83)
				THEN 'FALSE'
			ELSE 'TRUE'
			END AS "HasTDProjectRequest"
                , CASE
			WHEN pebempl_ECLS_CODE in( 90,92,80,81,82,85,83)
				THEN 'FALSE'
			ELSE 'TRUE'
			END AS "HasTDProjects"
	FROM pebempl
	INNER JOIN gobtpac
		ON gobtpac_pidm = pebempl_pidm
	INNER JOIN spriden
		ON spriden_pidm = pebempl_pidm --	INNER JOIN spriden
			--		ON spriden_pidm = nbrjobs_supervisor_pidm		will be needed for reports to
	INNER JOIN nbrbjob
		ON nbrbjob_pidm = pebempl_pidm
	INNER JOIN nbrjobs
		ON nbrjobs_pidm = pebempl_pidm
			AND nbrjobs_suff = nbrbjob_suff
			AND nbrjobs_posn = nbrbjob_posn
	INNER JOIN ptrecls
		ON ptrecls_code = nbrjobs_ecls_code
	INNER JOIN ftvorgn f1
		ON ftvorgn_orgn_code = nbrjobs_orgn_code_ts
		--adding reports to stuff nbbposn and a join with spriden for the reports to.
	LEFT JOIN NBBPOSN
		ON nbbposn_posn = nbrjobs_posn
	LEFT JOIN nbrjobs nbrjobs2
		ON nbbposn_posn_reports = nbrjobs2.nbrjobs_posn
	LEFT JOIN gobtpac gobtpac2
	ON nbrjobs2.nbrjobs_pidm = gobtpac2.gobtpac_pidm
 	LEFT JOIN nbrrjqe
		ON nbrrjqe_pidm = nbrjobs.nbrjobs_pidm
                        AND nbrjobs.nbrjobs_suff = nbrrjqe_suff
			AND nbrjobs.nbrjobs_posn = nbrrjqe_posn
	LEFT JOIN gobtpac gobtpac3
		ON nbrrjqe_appr_pidm = gobtpac3.gobtpac_pidm
	WHERE nbrjobs.nbrjobs_effective_date = (
			SELECT MAX(x1.nbrjobs_effective_date)
			FROM nbrjobs x1
			WHERE x1.nbrjobs_pidm = nbrjobs.nbrjobs_pidm
                              AND x1.nbrjobs_posn = nbrjobs.nbrjobs_posn
                              AND x1.nbrjobs_suff = nbrjobs.nbrjobs_suff
                              AND x1.nbrjobs_effective_date <= SYSDATE
			)
		AND nbrjobs.nbrjobs_status <> 'T'
		AND spriden_change_ind IS NULL
		AND (
			pebempl_empl_status = 'A'
			OR pebempl_ecls_code IN (
				90
				, 92
				)
			)
		AND (
			pebempl_last_work_date IS NULL
			OR pebempl_last_work_date > SYSDATE
			OR (
				pebempl_ecls_code IN (
					90
					, 92
					)
				AND pebempl_last_work_date = (
					SELECT MAX(pebempl_last_work_date)
					FROM pebempl p2
					WHERE p2.pebempl_pidm = pebempl.pebempl_pidm
					)
				)
			)
		AND (
			nbrjobs.nbrjobs_status = 'A'
			OR pebempl_ecls_code IN (
				90
				, 92
				)
			)
		AND nbrbjob_contract_type = 'P'
		AND pebempl_ecls_code IN (
			10
			, 14
			, 20
			, 21
			, 22
			, 25
			, 30
			, 32
			, 34
			, 34
			, 35
			, 36
			, 70
			, 71
			, 72
			, 73
			, 80
			, 81
			, 82
			, 82
			, 83
			, 84
			, 85
			, 90
			, 92
			)
		AND f1.ftvorgn_eff_date = (
			SELECT MAX(f2.ftvorgn_eff_date)
			FROM ftvorgn f2
			WHERE f2.ftvorgn_orgn_code = f1.ftvorgn_orgn_code
			)
		AND (nbrjobs2.nbrjobs_effective_date = (
			SELECT MAX(x1.nbrjobs_effective_date)
			FROM nbrjobs x1
			WHERE --x1.nbrjobs_pidm = nbrjobs2.nbrjobs_pidm
                               x1.nbrjobs_posn = nbrjobs2.nbrjobs_posn
                              AND x1.nbrjobs_suff = nbrjobs2.nbrjobs_suff
                              AND x1.nbrjobs_effective_date <= SYSDATE
                             -- AND x1.nbrjobs_status <> 'T'
                              AND x1.nbrjobs_suff = '00'
			) OR nbbposn_posn_reports IS NULL)
		--This line for testing only. Uncomment to get down to one employee
		AND spriden_pidm = 170394 --56357

	)
SELECT *
FROM employees
;
---------------------students--------------------------------------------

UNION

SELECT 'USER' AS "User_TYPE"
	, gobtpac.GOBTPAC_EXTERNAL_USER || '@nsuok.edu' Username
	, 'TeamDynamix' AS "Authentication_Provider"
	, gobtpac.GOBTPAC_EXTERNAL_USER AS "Authentication_Username"
	, 'Client' AS "Security_Role"
	, spriden.SPRIDEN_FIRST_NAME AS "First_Name"
	, spriden.SPRIDEN_LAST_NAME AS "Last_Name"
	, spriden.SPRIDEN_MI AS "Middle_Name"
	, 'Northeastern State University' AS "Organization"
	, 'Student' AS "Title"
	, '' AS "Acct_Dept"
	, spriden.SPRIDEN_ID AS "Organizational_ID"
	, '' AS "Alternate ID"
	, 'FALSE' AS "Is Employee"
	, gobtpac.GOBTPAC_EXTERNAL_USER || '@nsuok.edu' AS "Primary_Email"
	, gobtpac.GOBTPAC_EXTERNAL_USER || '@nsuok.edu' AS "Alert_Email"
	, '' AS "Work_Phone"
	, '' AS "Work Postal_Code"
	, '4' AS "Time_Zone_ID"
	, NULL AS "Reports_To_Username"
	, 'TRUE' AS "HasTDKnowledgeBase"
	, 'TRUE' AS "HasTDNews"
	, 'TRUE' AS "HasTDRequests"
	, 'TRUE' AS "HasTDTicketRequests"
        , NULL as HasTDProjectRequest
        , NULL as HasTDProjects

FROM gobtpac
INNER JOIN spriden
	ON spriden_pidm = gobtpac_pidm
WHERE (
		EXISTS (
			SELECT 'x'
			FROM sarappd
			INNER JOIN stvterm
				ON stvterm_code = SARAPPD_TERM_CODE_ENTRY
			WHERE sarappd_pidm = gobtpac_pidm
				AND (
					(
						SYSDATE BETWEEN (stvterm_start_date)
							AND (stvterm_end_date)
						OR stvterm_start_date > SYSDATE
						)
					)
			)
		OR EXISTS (
			SELECT 'x'
			FROM sfrstcr
			WHERE gobtpac_pidm = sfrstcr_pidm
				AND sfrstcr_term_code >= (
					SELECT MAX(stvterm_code) - 300
					FROM stvterm
					WHERE stvterm_code NOT LIKE '%5'
						AND SYSDATE >= stvterm_start_date
					)
				AND SFRSTCR_RSTS_CODE IN (
					SELECT STVRSTS_CODE
					FROM STVRSTS
					WHERE STVRSTS_INCL_SECT_ENRL = 'Y'
					)
			)
		)
	AND spriden_change_ind IS NULL
	AND SPRIDEN_ID NOT IN (
		SELECT "Organizational_ID"
		FROM employees
		)