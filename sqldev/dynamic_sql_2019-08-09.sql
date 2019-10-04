DECLARE
    v_sql       VARCHAR2(32767) := null; --'CREATE OR REPLACE VIEW v_stu_val_codes AS SELECT ';
    v_lcount    NUMBER          := 0;
    v_table     VARCHAR2(7);
    

        
    PROCEDURE p_find_code (f_vcode in varchar2, f_table out varchar2)
    IS 
        f_sql       varchar2(100)   := null;
        f_result    varchar2(7)     := null;
        f_cursor_name       integer;
        f_rows_processed    integer;
        p_col1      varchar2(30);
        
            CURSOR c_stvs IS
        SELECT * FROM
        (
            SELECT atc.table_name
                , atc.owner
                , atc.comments
            FROM all_tab_comments atc
            WHERE atc.table_name LIKE 'S_V%' 
             AND LENGTH(atc.table_name) = 7
             AND exists (select acc.column_name from all_col_comments acc
                         where atc.table_name = acc.table_name and substr(acc.column_name,9,4) in ('CODE'))
            --and atc.table_name in ('STVCAMP','STVCNTY')
        );
        
    BEGIN      
        
        
        for r_stv in c_stvs loop
            f_sql := 'select ' || r_stv.table_name || '_CODE FROM ' || r_stv.table_name
                    || ' WHERE ' || r_stv.table_name || '_CODE LIKE ' || chr(39)||f_vcode|| '%' || chr(39);
        
        f_cursor_name := dbms_sql.open_cursor;
            dbms_sql.parse(f_cursor_name,f_sql,dbms_sql.NATIVE); 
            dbms_sql.define_column(f_cursor_name, 1, p_col1);
            f_rows_processed := dbms_sql.execute(f_cursor_name);
           
            if dbms_sql.fetch_rows(f_cursor_name) >0 then
                dbms_sql.column_value(f_cursor_name,1,p_col1);
                dbms_output.put_line(p_col1 || ' in ' || r_stv.table_name || ' : ' || r_stv.comments);
            end if;

--            if f_result <> null then
--                f_table := r_stv.table_name;
--                exit;
--            end if;    

            dbms_sql.close_cursor(f_cursor_name);
        end loop;
        
--EXCEPTION
--  WHEN OTHERS THEN
--    IF dbms_sql.is_open(f_cursor_name) THEN
--      dbms_sql.close_cursor(f_cursor_name);
--    END IF;   
    
END p_find_code;
--    
BEGIN
     p_find_code('0',v_table);
END;



--/*
--    FOR r_stvs IN c_stvs LOOP
--        v_lcount := v_lcount + 1;
----    select table_name, owner
----         , stvcamp_code, stvcamp_desc
----    from all_tab_comments join stvcamp on all_tab_comments.table_name = 'STVCAMP' 
----        IF v_lcount > 1 THEN
----            v_sql := v_sql || ' UNION SELECT ';
----        END IF;
--        
--        v_sql := v_sql || 'table_name, owner, comments, '
--                || r_stvs.table_name || '_code, '
--                || r_stvs.table_name || '_desc FROM all_tab_comments JOIN '
--                || r_stvs.table_name || ' ON all_tab_comments.table_name = '
--                || chr(39) || r_stvs.table_name || chr(39) || ' '
--                ;
--        
--        dbms_output.put_line(v_lcount || ':' 
--                            ||r_stvs.table_name
--                            || ' ' || r_stvs.owner
--                     --       || ' ' || r_stvs.column_name
--                            );
--        dbms_output.put_line(v_sql);
--                            
--    
--
--    END LOOP;
--    
--   -- EXECUTE IMMEDIATE v_sql;
--            
--END;