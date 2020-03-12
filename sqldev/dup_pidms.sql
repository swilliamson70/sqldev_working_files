DECLARE
    p_sec                 VARCHAR2(1) := 'Y';
    v_pidm                NUMBER := 31091; --p_pidm;
    v_id                  VARCHAR2(10):= NULL;
    v_owner               VARCHAR2(20):= NULL;
    v_email               VARCHAR2(60):= NULL;
    v_ssn                 VARCHAR2(20):= NULL;
    v_dob                 DATE := NULL;
    v_can_delete          VARCHAR2(1):= 'Y';
    v_loop_count          NUMBER := 0;
    v_loop_count_found    NUMBER := 0;
    v_loop_count_records  NUMBER := 0;
    v_file                utl_file.file_type;
    v_sql_file            utl_file.file_type;
    v_creator             VARCHAR2(10):= NULL;
    v_create_date         DATE := NULL;
    CURSOR c0 IS
    SELECT DISTINCT
        owner
    FROM
        all_objects
    ORDER BY
        owner;

    PROCEDURE echo(
        p_line IN VARCHAR2
    )IS
    BEGIN
        dbms_output.put_line(p_line);
        utl_file.put_line(
            v_file,
            p_line
        );
    END;

    PROCEDURE list_tables(
        p_name  IN  VARCHAR2,
        p_pidm  IN  NUMBER
    )IS

        v_sql    VARCHAR2(1024):= NULL;
        v_count  NUMBER := 0;
        CURSOR c1(
            p_owner VARCHAR2
        )IS
        SELECT
            t1.owner,
            t1.table_name,
            t1.column_name
        FROM
            all_tab_columns  t1,
            all_tables       t2                              -- all_tables works the same as all_objects
        WHERE
            substr(
                t1.column_name,9
            )LIKE '%PIDM%' -- FIXME
            AND t1.owner = p_owner
            AND t1.owner = t2.owner
            AND t1.table_name = t2.table_name
        --and t2.object_type = 'TABLE'
            AND t1.data_type = 'NUMBER'
        ORDER BY
            1,
            2,
            3;

    BEGIN
    --dbms_output.put_line('----');
    --dbms_output.put_line('Owner: '||p_name);
    --dbms_output.put_line('--');
        FOR r IN c1(p_name)LOOP
            v_loop_count := v_loop_count + 1;
            v_sql := 'SELECT COUNT(*) FROM '
                     || r.table_name
                     || ' WHERE '
                     || r.column_name
                     || ' = '
                     || p_pidm;
      --dbms_output.put_line(v_sql);
      --continue;

            BEGIN
                EXECUTE IMMEDIATE v_sql
                INTO v_count;
            EXCEPTION
                WHEN OTHERS THEN
        --dbms_output.put_line('exc: '||sqlerrm);
                    v_count := 0;
            END;
            IF v_count > 0 THEN
                v_loop_count_found := v_loop_count_found + 1;
                v_loop_count_records := v_loop_count_records + v_count;
                echo(p_name
                     || chr(9)
                     || r.table_name
                     || chr(9)
                     || r.column_name
                     || chr(9)
                     || v_count);
        -- dump records

                v_sql := 'SELECT * FROM '
                         || p_name
                         || '.'
                         || r.table_name
                         || ' WHERE '
                         || r.column_name
                         || ' = '
                         || p_pidm;

                utl_file.put_line(
                    v_sql_file,
                    v_sql
                    || '; -- '
                    || v_count
                );
        -- generate csv:
                nsudev.nsu_csv.dump_select_to_csv(
                    v_sql,
                    'U13_STUDENT',
                               'dup_sql__'
                               || p_name
                               || '-'
                               || r.table_name
                               || '-'
                               || r.column_name
                               || '__'
                               || v_id
                               || '.csv'
                );

                IF p_name IN(
                    'FAISMGR',
                    'FIMSMGR',
                    'PAYROLL',
                    'TAISMGR'
                )THEN -- FIXME right list of bad owners in terms of mass delete
                    v_can_delete := 'N';
                END IF;

            END IF;

        END LOOP;
    END list_tables;

BEGIN
    BEGIN
        SELECT
            spriden_id
        INTO v_id
        FROM
            spriden
        WHERE
                spriden_pidm = v_pidm
            AND spriden_change_ind IS NULL;

    EXCEPTION
        WHEN OTHERS THEN
            v_id := NULL;
    END;

    BEGIN
        SELECT
            goremal_email_address
        INTO v_email
        FROM
            goremal
        WHERE
                goremal_pidm = v_pidm
            AND goremal_emal_code = 'NSU';

    EXCEPTION
        WHEN OTHERS THEN
            v_email := NULL;
    END;

    BEGIN
        SELECT
            spbpers_birth_date,
            spbpers_ssn
        INTO
            v_dob,
            v_ssn
        FROM
            spbpers
        WHERE
            spbpers_pidm = v_pidm;

    EXCEPTION
        WHEN OTHERS THEN
            v_dob := NULL;
            v_ssn := NULL;
    END;

    IF v_ssn = '999999999' THEN
        BEGIN
            SELECT
                goradid_additional_id
            INTO v_ssn
            FROM
                goradid
            WHERE
                    goradid_pidm = v_pidm
                AND goradid_adid_code = 'XSSN';

        EXCEPTION
            WHEN OTHERS THEN
                v_ssn := NULL;
        END;
    END IF;

    BEGIN
        SELECT
            spriden_create_user,
            spriden_create_date
        INTO
            v_creator,
            v_create_date
        FROM
            spriden
        WHERE
                spriden_pidm = v_pidm
            AND spriden_change_ind IS NULL;

    EXCEPTION
        WHEN OTHERS THEN
            v_creator := NULL;
            v_create_date := NULL;
    END;

    v_file := utl_file.fopen(
        'U13_STUDENT',
        'dup_count_tables_'
        || v_id
        || '.dat',
               'W'
    );

    v_sql_file := utl_file.fopen(
        'U13_STUDENT',
        'dup_sql_tables_'
        || v_id
        || '.sql',
               'W'
    );
--utl_file.fremove('U13_STUDENT','dup_sql_tables_'||v_id||'.csv');

    echo(to_char(
        sysdate,
        'DD-MON-YYYY HH24:MI:SS'
    ));
    echo('ID: ' || v_id);
    echo('PIDM: ' || v_pidm);
    echo('Name: ' || f_format_name(
        v_pidm,
        'LFMI'
    ));
    echo('email: ' || v_email);
    IF p_sec = 'N' THEN
        echo('SSN: ' || v_ssn);
        echo('DOB: ' || to_char(
            v_dob,
            'DD-MON-YYYY HH24:MI:SS'
        ));
    END IF;

    echo('CREATOR: '
         || v_creator
         || ' '
         || to_char(
        v_create_date,
        'DD-MON-YYYY HH24:MI:SS'
    ));

    echo('Owner'
         || chr(9)
         || 'Table'
         || chr(9)
         || 'Count');

    echo('-----'
         || chr(9)
         || '-----'
         || chr(9)
         || '-----');

    utl_file.put_line(
        v_sql_file,
        'SET LINESIZE 32000;'
    );
    utl_file.put_line(
        v_sql_file,
        'SET PAGESIZE 40000;'
    );
    utl_file.put_line(
        v_sql_file,
        'SET LONG 50000;'
    );
--utl_file.put_line(v_sql_file,'SPOOL output.txt');
    FOR r IN c0 LOOP
        list_tables(
            r.owner,
            v_pidm
        );
    END LOOP;
--echo('### can delete: '||v_can_delete||' ###');
    echo('loop_count: ' || v_loop_count);
    echo('loop_count_found: ' || v_loop_count_found);
    echo('loop_count_records: ' || v_loop_count_records);
    utl_file.put_line(
        v_sql_file,
        'exit;'
    );
    utl_file.fclose(v_file);
    utl_file.fclose(v_sql_file);
END;