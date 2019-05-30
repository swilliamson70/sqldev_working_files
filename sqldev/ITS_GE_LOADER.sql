/**************************
ITS_GE_LOADER
Loads SGRSATT with new Gen Ed code based on criteria provided by Janet Kelley

Scott Williamson
2019-05-30

**************************/

DECLARE
    fileHandler UTL_FILE.FILE_TYPE;
    
    c_sorlcur_pidm              sorlcur.sorlcur_pidm%TYPE;
    --c_sorlcur_term_code_admit   sorlcur.sorlcur_term_code_admit%TYPE;
    c_sgrsatt_pidm              sgrsatt.sgrsatt_pidm%TYPE;
    c_sgrsatt_term_code_eff     sgrsatt.sgrsatt_term_code_eff%TYPE;
    c_sgrsatt_atts_code         sgrsatt.sgrsatt_atts_code%TYPE;
    c_spriden_id                spriden.spriden_id%TYPE;
    c_spriden_first_name        spriden.spriden_first_name%TYPE;
    c_spriden_last_name         spriden.spriden_last_name%TYPE;
    c_spriden_mi                spriden.spriden_mi%TYPE;
    c_attrib_row_count          number;
    c_ge0x_row_count            number;
    c_recent_term               sgrsatt.sgrsatt_term_code_eff%TYPE;
    
    CURSOR c_students IS
        SELECT sorlcur_pidm
            --,sorlcur_term_code_admit
            ,sgrsatt_pidm
            ,sgrsatt_term_code_eff
            ,sgrsatt_atts_code
            ,SUM(CASE
                    WHEN sgrsatt_atts_code IS NULL THEN 0
                    ELSE 1
                 END) OVER (PARTITION BY sorlcur_pidm) attrib_row_count
            ,COUNT(CASE
                    WHEN sgrsatt_atts_code IN('GE01','GE02') THEN 1
                   END) OVER (PARTITION BY sorlcur_pidm) ge0x_row_count
            ,MAX(sgrsatt_term_code_eff) OVER (PARTITION BY sorlcur_pidm) recent_term            
            ,spriden_id
            ,spriden_first_name
            ,spriden_last_name
            ,spriden_mi
    
    FROM  (SELECT DISTINCT sorlcur_pidm
            ,sorlcur_term_code_admit
            FROM sorlcur
            WHERE sorlcur_term_code_admit BETWEEN '201810' AND '202010'
          ) LEFT JOIN sgrsatt ON sorlcur_pidm = sgrsatt_pidm
            JOIN spriden ON sorlcur_pidm = spriden_pidm
                         AND spriden_change_ind is null
    ORDER BY spriden_last_name, spriden_first_name, spriden_mi;
                         
    v_last_pidm                 sorlcur.sorlcur_pidm%TYPE := null;
    v_loop_counter              number := 1;
        
BEGIN <<main>>
    fileHandler := UTL_FILE.FOPEN('U13_STUDENT', 'sgrsatt_file.txt', 'W');
    
    --dbms_output.put_line('spriden_id,' ||
    utl_file.put_line(fileHandler,'spriden_id,' ||
                         'spriden_last_name,' ||
                         'spriden_first_name,' ||
                         'spriden_mi,' ||
                         'sorlcur_pidm,' ||
                         'sgrsatt_term_code_eff,' ||
                         'sgrsatt_atts_code,' ||
                         'attrib_row_count,' ||
                         'ge0x_row_count,' ||
                         'recent_term,'||
                         'action_needed');
    OPEN c_students;
    LOOP
        FETCH c_students INTO c_sorlcur_pidm 
                              --,c_sorlcur_term_code_admit
                              ,c_sgrsatt_pidm
                              ,c_sgrsatt_term_code_eff
                              ,c_sgrsatt_atts_code
                              ,c_attrib_row_count
                              ,c_ge0x_row_count
                              ,c_recent_term
                              ,c_spriden_id
                              ,c_spriden_first_name
                              ,c_spriden_last_name
                              ,c_spriden_mi;
            EXIT WHEN c_students%notfound;
            
            IF v_last_pidm = c_sorlcur_pidm THEN
                v_loop_counter := 2;
            ELSE 
                v_loop_counter := 1;
            END IF;
            
            IF c_ge0x_row_count > 0 THEN
            
                --dbms_output.put_line(c_spriden_id || ',' ||
                utl_file.put_line(fileHandler,c_spriden_id || ',' ||
                                 c_spriden_last_name || ',' ||
                                 c_spriden_first_name || ',' ||
                                 c_spriden_mi || ',' ||
                                 c_sorlcur_pidm || ',' ||
                                 --c_sorlcur_term_code_admit || ',' ||
                                 c_sgrsatt_term_code_eff  || ',' ||
                                 c_sgrsatt_atts_code  || ',' ||
                                 c_attrib_row_count  || ',' ||
                                 c_ge0x_row_count  || ',' ||
                                 c_recent_term  || ',' ||
                                 'Has GE0x code - skip person');
            ELSE
                --dbms_output.put_line(c_spriden_id || ',' ||
                utl_file.put(fileHandler,c_spriden_id || ',' ||
                                 c_spriden_last_name || ',' ||
                                 c_spriden_first_name || ',' ||
                                 c_spriden_mi || ',' ||
                                 c_sorlcur_pidm || ',' ||
                                 --c_sorlcur_term_code_admit || ',' ||
                                 c_sgrsatt_term_code_eff  || ',' ||
                                 c_sgrsatt_atts_code  || ',' ||
                                 c_attrib_row_count  || ',' ||
                                 c_ge0x_row_count  || ',' ||
                                 c_recent_term  || ',');
                IF v_loop_counter = 1 THEN
                        utl_file.put_line (fileHandler,
                                 'Insert Record into SGRSATT Values:' ||
                                 ' PIDM:' || c_sorlcur_pidm ||
                                 '| SGRSATT_TERM_CODE:' ||
                                    CASE WHEN c_attrib_row_count > 0 THEN c_recent_term
                                         ELSE '202010'
                                    END ||
                                 '| SGRSATT_ATTS_CODE: GE03' ||
                                 '| SGRSATT_ACTIVITY_DATE: (sysdate) ' || TRUNC(SYSDATE) ||
                                 '| SGRSATT_STSP_KEY_SEQUENCE: null' ||
                                 '| SGRSATT_USER_ID: ITS_GE_LOADER-(sysdate)'|| TO_CHAR(SYSDATE,'YYYYMMDD') 
                                 );
                ELSE 
                        utl_file.put_line(fileHandler,'No action - new record already inserted');
                END IF;
            END IF;
            
            v_last_pidm := c_sorlcur_pidm;
            
    END LOOP;
    CLOSE c_students;
    UTL_FILE.FCLOSE(fileHandler);
    EXCEPTION
        WHEN utl_file.invalid_path THEN
            raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');
END;
