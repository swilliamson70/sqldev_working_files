CREATE OR REPLACE PACKAGE nsu_bnr_tbx IS
/*

    This package contains procedures to process inbound TBX deduction files
    to update data in the payroll stream.

    Northeastnern State University
    23 Oct 18 - Scott Williamson - start 

*/
    PROCEDURE load_staging_table;
    -- Parses csv and loads data into staging table after looking up pidm and using pb_deduction_detail_rules.p_validate API 
    -- to validate TBX data. Loads staging table with deduction information, found pidm, and validation results
    
    PROCEDURE check_staging_table;
    -- Used to check records in staging table when they have been imported directly from TBX spreadsheet 
    -- without using load_staging_table

    PROCEDURE load_pdrdedn;
    -- Uses Banner APIs pp_deduction.p_update and .p_create to load new deduction information to Banner from staging table

    PROCEDURE mass_enddate;
    -- Updates Banner deduction records by end dating everyone with a T record in staging table

END nsu_bnr_tbx;
/


CREATE OR REPLACE PACKAGE BODY        NSU_BNR_TBX AS

/*************************************************
PROCEDURE load_staging_table
    Opens flat file (directory object and file name at top of var section) from TBX
    Parses same and inserts the information into NSU_TBX_PDRDEDN

Northeastern State Univerisity
    Nov/Dec 2018    Scott Williamson   Start -- used to load MN file after Tere did manual corrections on TBX provided CSV
    11-Dec-2019     sw                  added replace to f_get_item to remove carriage returns from last field in file
                                        (it was throwing ORA-06502, trying to fit a 2 char + chr(13) into a 2 char varchar2)

*************************************************/
  procedure load_staging_table AS

  /*
  remarks
--NSU_TBX_PDRDEDN
--  TBX_PIDM - key
--  TBX_ID
--  TBX_LNAME
--  TBX_FNAME
--  TBX_MI
--  TBX_BDCA_CODE
--  TBX_EFFECTIVE_DATE
--  TBX_ACTIVITY_DATE
--  TBX_STATUS
--  TBX_AMOUNT1
--  TBX_AMOUNT2
--  TBX_AMOUNT3
--  TBX_AMOUNT4
--  TBX_OPT_CODE1
--  TBX_OPT_CODE2
--  TBX_OPT_CODE3
--  TBX_OPT_CODE4
--  TBX_OPT_CODE5
--  TBX_ERR_CODE
--  TBX_ERR_DESC

  TBX_ID                      VARCHAR2(9)  +
  TBX_BDCA_CODE               VARCHAR2(3)  +
  TBX_EFFECTIVE_DATE          DATE         +
  TBX_ACTIVITY_DATE           DATE         +
  TBX_STATUS                  VARCHAR2(1)  +
  TBX_AMOUNT1                 NUMBER(11,2) +
  TBX_AMOUNT2                 NUMBER(11,2) +
  TBX_AMOUNT3                 NUMBER(11,2) +
  TBX_AMOUNT4                 NUMBER(11,2) +
  TBX_OPT_CODE1               VARCHAR2(2)  +
10 TBX_OPT_CODE2               VARCHAR2(2)  +
11 TBX_OPT_CODE3               VARCHAR2(2)  +
12 TBX_OPT_CODE4               VARCHAR2(2)  +
13 TBX_OPT_CODE5               VARCHAR2(2)  +
TBX_YEAR                    VARCHAR2(4)  +
TBX_PICT_CODE               VARCHAR2(2)  +
TBX_PAYNO                   VARCHAR2(3)  +
TBX_USER_APPROVE_FLAG       VARCHAR2(1)  
TBX_USER_ID                 VARCHAR2(30) 
TBX_DATA_ORIGIN             VARCHAR2(30) 

  */
  -----Var
  v_FileHandle      utl_file.file_type ;
  v_FileDir         varchar2(20) := 'U13_FINANCE';   -- /u13/PROD/finance
  --v_FileName        varchar2(20) := 'monthly_tbx1.csv'; --'dedn_export.csv';
  --v_FileName        varchar2(20) := 'tbx_test1.csv'; --'dedn_export.csv';
  --v_FileName        varchar2(30) := 'tbx_consolidated2.csv';
  --v_FileName        varchar2(30) := 'enddate_test1.csv';
  --v_FileName        varchar2(30) := 'PlanB_Biweekly.csv';
  --v_FileName        varchar2(30) := 'planb_mn_load_u.csv'; 
  v_FileName          varchar2(30) := 'biweekly_tbx_2020.csv';
  -- The original flat file is in M:\BusinessFinance\HR_Payroll\Payroll Reports for Phyllis\TBX files\TBX 2019 Wrap final files
  v_UserID          varchar2(30) := 'NSU_BNR_TBX';
  v_DataOrigin      varchar2(30) := 'TBX';

  v_line            varchar2(32767) := NULL; -- no idea max bytes of input file
  v_err_code        varchar(25);
  v_err_desc        varchar(200);
  v_linecount       number(10);
  v_loop            number(5);
  v_quote_count     number(5,1) := 0.0;
  v_quoteloop       number(5);
  v_string          varchar2(999);

-- TBX PDRDEDN flat file fields
    v_PIDM  varchar2(8); -- needs to be covered to number during insert
    v_ID varchar2(9);
    v_LNAME varchar2(60);
    v_FNAME varchar2(60);
    v_MI varchar2(60);
    v_BDCA_CODE varchar2(3);
    v_EFFECTIVE_DATE date;
    v_ACTIVITY_DATE date;
    v_STATUS varchar2(1);
    v_AMOUNT1 number(11,2);
    v_AMOUNT2 number(11,2);
    v_AMOUNT3 number(11,2);
    v_AMOUNT4 number(11,2);
    v_OPT_CODE1 varchar2(4);
    v_OPT_CODE2 varchar2(4);
    v_OPT_CODE3 varchar2(4);
    v_OPT_CODE4 varchar2(4);
    v_OPT_CODE5 varchar2(4);

-- bdca rules for pre-validation validation
    cursor c_ptrbdca is
        select  ptrbdca_code
                ,ptrbdca_amt1_ind  -- each holds code in (R,N,O,S) for Req'd, Not entered, Optional, System Gen
                ,ptrbdca_amt2_ind
                ,ptrbdca_amt3_ind
                ,ptrbdca_amt4_ind
                ,ptrbdca_option1_ind
                ,ptrbdca_option2_ind
                ,ptrbdca_option3_ind
                ,ptrbdca_option4_ind
                ,ptrbdca_option5_ind
        from ptrbdca;

  -----PROC echo
    PROCEDURE echo(p_msg IN VARCHAR2)
    IS
        BEGIN
            dbms_output.put_line(p_msg);
    END echo;
  -----
  -----PROC file open
    PROCEDURE initialize_filehandle 
    --U13_ALUMNI_CONTACT | /u13/PROD/sync/alumni/to_banner/contact - PROD directory object 
    --U13_FINANCE |	/u13/PROD/finance - PrePROD directory object
    IS
        BEGIN
            IF utl_file.is_open(v_FileHandle) then 
                utl_file.fclose(v_FileHandle);
            end if;

            --echo('file open proc');
            v_FileHandle := utl_file.fopen(v_FileDir,v_FileName, 'R', 32767);
            --echo('file open proc2');
    END initialize_filehandle;
  -----
  -----PROC file close
    PROCEDURE destroy_filehandle 
    IS
        BEGIN
            utl_file.fclose(v_FileHandle);
            v_FileHandle := null;
    END destroy_filehandle;
  -----
  ----- PROC validate record against Banner BDCA rules
    PROCEDURE get_validation_code(  p_pidm in varchar2,
                                    p_bdca_code in varchar2,
                                    p_effective_date in date,
                                    p_status in varchar2,
                                    p_amount1 in out number,
                                    p_amount2 in out number,
                                    p_amount3 in out number,
                                    p_amount4 in out number,
                                    p_opt_code1 in out varchar2,
                                    p_opt_code2 in out varchar2,
                                    p_opt_code3 in out varchar2,
                                    p_opt_code4 in out varchar2,
                                    p_opt_code5 in out varchar2,

                                    p_err_code out varchar2,
                                    p_err_desc out varchar2)

    IS
      p_amount1_rule  varchar2(1);
      p_amount2_rule  varchar2(1);
      p_amount3_rule  varchar2(1);
      p_amount4_rule  varchar2(1);
      p_option1_rule  varchar2(1);
      p_option2_rule  varchar2(1);
      p_option3_rule  varchar2(1);
      p_option4_rule  varchar2(1);
      p_option5_rule  varchar2(1);

      BEGIN
        -- need to null out zero amounts from tbx before validation if field is flagged No Entry ('N')

        select  ptrbdca_amt1_ind
                ,ptrbdca_amt2_ind
                ,ptrbdca_amt3_ind
                ,ptrbdca_amt4_ind
                ,ptrbdca_option1_ind
                ,ptrbdca_option2_ind
                ,ptrbdca_option3_ind
                ,ptrbdca_option4_ind
                ,ptrbdca_option5_ind
            into
                p_amount1_rule
                ,p_amount2_rule
                ,p_amount3_rule
                ,p_amount4_rule
                ,p_option1_rule
                ,p_option2_rule
                ,p_option3_rule
                ,p_option4_rule
                ,p_option5_rule
            from ptrbdca 
            where ptrbdca_code = p_bdca_code;

        -- if indicator says there's not supposed to be anything there, and if amount is 0 then null it, otherwise let it through
        if p_amount1_rule in ('N','S') then --No entry/Sys gen
            --and p_amount1 = 0 then 
                p_amount1 := null;
        end if;
        if p_amount2_rule in ('N','S') then --No entry/Sys gen
            --and p_amount2 = 0 then 
                p_amount2 := null;
        end if;
        if p_amount3_rule in ('N','S') then --No entry/Sys gen
            --and p_amount3 = 0 then 
                p_amount3 := null;
        end if;
        if p_amount4_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_amount4 := null;
        end if;
        if p_option1_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code1 := null;
        end if;            
        if p_option2_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code2 := null;
        end if;            
        if p_option3_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code3 := null;
        end if;            
        if p_option4_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code4 := null;
        end if;            
        if p_option5_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code5 := null;
        end if;            

        -- TBX didn't include plan for opt out codes (H97, H98, H99)
        if p_bdca_code in ('H97','H98','H99') then
            p_opt_code1 := nvl(p_opt_code1,'10');
        end if;

        pb_deduction_detail_rules.p_validate( p_pidm,
                                              p_bdca_code,
                                              p_effective_date,
                                              p_status,
                                              null, -- ref no
                                              p_amount1,
                                              p_amount2,
                                              p_amount3,
                                              p_amount4,
                                              p_opt_code1,
                                              p_opt_code2,
                                              p_opt_code3,
                                              p_opt_code4,
                                              p_opt_code5,
                                              null, -- coverage date
                                              null, -- bdcl code
                                              'N', --w4 name change ind
                                              null, --p_w4_signed_pidm
                                              null, --p_w4_signed_date
                                              'N', --p_lockin_letter_status
                                              null, --p_lockin_letter_date
                                              null, --p_lockin_fsta_fil_st
                                              null, --p_lockin_withhold_allow
                                              null, --p_comment
                                              null, --p_comment_date
                                              null, --p_comment_user_id
                                              v_UserID, --p_user_id
                                              v_DataOrigin, --p_data_origin
                                              null, --p_brea_code
                                              null, --p_event_date
                                              null  --p_1042s_limit_ben_cde
                                              );

        if SQLCODE = 0 then                                       
                p_err_code := '0';
                p_err_desc := null;
        end if;

        exception
            when others then
                p_err_code := to_char(SQLCODE);
                p_err_desc := substr(sqlerrm,1,200);

    END get_validation_code;  
  -----  
  -----FUNC get start of data element in string
    FUNCTION f_item_start(p_line in varchar2, p_itemno in number)
        RETURN NUMBER
    IS
        p_item_position number;

        BEGIN
        --INSTR( string, substring [, start_position [, th_appearance ] ] )
            if p_itemno = 1 then p_item_position := 1;
                else p_item_position := instr(p_line, ',' ,1, p_itemno-1) +1;
            end if;

        RETURN p_item_position;

    END f_item_start;
  -----
  -----FUNC get data element length in string
    FUNCTION f_item_length(p_line in varchar2, p_itemno in number)
        RETURN NUMBER
    IS
        p_item_length number;
        p_start number;
        p_end number;
        p_item_less_one number;
        p_line2 varchar2(2000);

        BEGIN
            if p_itemno = 1 then 
                p_item_length := instr(p_line, ',' ,1) -1;
                --echo('first');
            else
                p_item_length := instr(p_line||',' , ',' ,1 ,p_itemno) - (instr(p_line||',' , ',' ,1, p_itemno-1)+1);
            end if;

        RETURN p_item_length;

    END f_item_length;
  -----    
  ----- function to get data element from line buffer
    FUNCTION f_get_item(p_line in varchar, p_itemno in number)
        RETURN VARCHAR2
    IS
        p_item varchar(32767); -- length of buffer jtbs

        BEGIN

            if p_line is null or length(p_line) < 1 then
                p_item := null;
            else
                p_item := substr(p_line,f_item_start(p_line,p_itemno),f_item_length(p_line,p_itemno));
            end if;

            --Get rid of extraneous carriage returns
            p_item := replace(p_item,chr(13));

        RETURN p_item;

    END f_get_item;
  -----
  -----
    FUNCTION f_get_pidm(p_id in varchar2)
        RETURN VARCHAR2
    IS
        p_pidm number(8);
        spriden_count number(8);

        BEGIN
            select count(*) into p_pidm from spriden where spriden_id = p_id and spriden_change_ind is null;
--            echo('checking pidm');

            if p_pidm > 0 then
                select spriden_pidm into p_pidm from spriden where spriden_id = p_id and spriden_change_ind is null;
            end if;

            --echo(spriden_count || ' ' || p_pidm);
--            exception
--                when NO_DATA_FOUND then
--                    p_pidm := 0;

        RETURN p_pidm;

    END f_get_pidm;

  -----    


BEGIN --main
    echo('begin');
    dbms_output.enable(null);
    initialize_filehandle;

    utl_file.get_line(v_FileHandle,v_line);    -- Read headers and go on
    v_linecount := 0;
    echo(v_line);

    if utl_file.is_open(v_FileHandle) then 
        loop 
            begin
                utl_file.get_line(v_FileHandle,v_line);
                v_linecount := v_linecount +  1;
                dbms_output.put_line('Line In:'||v_linecount || ':' || v_line);

                if v_line is null then 
                    dbms_output.put_line('File is empty');
                    exit;                    
                end if;

   -- main
        --clean line buffer - 
                --echo(v_line);

                -- Find all commas inside double quote pairs and replace with asterisks
                v_quote_count := 0;
                for v_loop in 1 .. length(v_line)-1 loop
                    --echo('char ' || v_loop || ' ' || substr(v_line,v_loop,1));
                --find me a double quote
                    --echo(substr(v_line,v_loop,1));
                    if substr(v_line,v_loop,1) = chr(34) then
                        v_quote_count := v_quote_count + 1;
                        --echo('quote ' || v_quote_count || ' hi ' ||  mod(v_quote_count,2)  );
                        -- is this a leading quote mark (odd numbered) or closing quote mark (even numbered)?
                        if mod(v_quote_count,2) = 1 then
                            --echo('odd - looking inside for a comma or close');
                            --look for a comma before the next (even numbered) d-quote and subsitute something safe to replace in a minute...
                            for v_quoteloop in v_loop + 1 .. length(v_line) loop
                                if substr(v_line,v_quoteloop,1) =  chr(34) then -- we've found the close quote
                                    --echo('close');
                                    exit;
                                elsif substr(v_line,v_quoteloop,1) = ',' then
                                    --echo('comma');
                                    v_line := regexp_replace(v_line, ',' ,'*', v_quoteloop, 1);
                                    --v_line := substr(v_line,1,v_quoteloop - 1) || substr(v_line,v_quoteloop +1,length(v_line));
                                end if;
                            end loop;
                        end if;    
                    end if;
                end loop;
                --echo(v_line);
                v_line := replace(v_line,chr(34)); -- loose the d-quotes
                v_line := replace(v_line,'*'); -- loose the stars
                echo('final ' || v_line);

                -- get data elements
                -- local f_get_pidm = if ID DNE, returns '0' as PIDM
                v_PIDM := f_get_pidm(substr(v_line,1,f_item_length(v_line,1)));
                --echo('pidm ' || v_PIDM);

                v_ID := f_get_item(v_line,1);
                --echo('id ' || v_ID);

                v_BDCA_CODE := f_get_item(v_line,2);
                --echo('bdca ' || v_BDCA_CODE);

                v_EFFECTIVE_DATE := to_date(f_get_item(v_line,3),'MM/DD/YYYY');
                --echo('eff ' || v_effective_date);

                v_ACTIVITY_DATE := trunc(sysdate);
                --echo('act ' || v_ACTIVITY_DATE);

                v_STATUS := f_get_item(v_line,4);
                --echo('status ' || v_STATUS);
                --v_string := f_get_item(v_line,4);
                --v_string := 'v_string:'||v_string||' len:'||length(trim(f_get_item(v_line,4))) || 'ascii:';
                --for i in 1 .. length(f_get_item(v_line,4)) loop
                --        v_string := v_string || ascii(substr(f_get_item(v_line,4),i,1)) || ' ';
                --end loop;
                --echo(v_string);

                --echo(f_get_item(v_line,5));
                v_AMOUNT1 := to_number(f_get_item(v_line,5));
                --echo('amt1 ' || v_AMOUNT1);

                v_AMOUNT2 := to_number(f_get_item(v_line,6));
                --echo('amt2 ' || v_AMOUNT2);

                v_AMOUNT3 := to_number(f_get_item(v_line,7));
                --echo('amt3 ' || v_AMOUNT3);

                v_AMOUNT4 := to_number(f_get_item(v_line,8));
                --echo('amt4 ' || v_AMOUNT4);

                --echo(f_get_item(v_line,9) );
                --v_string := f_get_item(v_line,9);
                --v_string := 'v_string:'||v_string||' len:'||length(trim(f_get_item(v_line,9))) || 'ascii:';
                --for i in 1 .. length(f_get_item(v_line,9)) loop
                --        v_string := v_string || ascii(substr(f_get_item(v_line,9),i,1)) || ' ';
                --end loop;
                --echo(v_string);
                v_OPT_CODE1 := f_get_item(v_line,9);
                --echo('opt1 ' || v_OPT_CODE1);

                --echo(f_get_item(v_line,10));
                v_OPT_CODE2 := f_get_item(v_line,10);
                --echo('opt2 ' || v_OPT_CODE2);

                v_OPT_CODE3 := f_get_item(v_line,11);
                --echo('opt3 ' || v_OPT_CODE3);

                v_OPT_CODE4 := f_get_item(v_line,12);
                --echo('opt4 ' || v_OPT_CODE4);

                v_OPT_CODE5 := f_get_item(v_line,13);  
                --echo('opt5 ' || v_OPT_CODE5);

                if v_pidm > 0 then 
                    get_validation_code(v_PIDM,
                                        v_BDCA_CODE,
                                        v_EFFECTIVE_DATE,
                                        v_STATUS,
                                        v_AMOUNT1,
                                        v_AMOUNT2,
                                        v_AMOUNT3,
                                        v_AMOUNT4,
                                        v_OPT_CODE1,
                                        v_OPT_CODE2,
                                        v_OPT_CODE3,
                                        v_OPT_CODE4,
                                        v_OPT_CODE5, 
                                        v_err_code,    -- Returns err_code and err_desc 
                                        v_err_desc);
                else
                    v_err_code := '-1';
                    v_err_desc := 'Bad Banner ID from TBX';
                end if;

                echo('at insert - pidm:'||
                     v_PIDM || ' id:' ||
                     v_ID || ' bdca:' ||
                     v_BDCA_CODE || ' eff:' ||
                     v_EFFECTIVE_DATE || ' stat:' ||
                     v_STATUS || ' amt1:' ||
                     v_AMOUNT1 || ' amt2:' ||
                     v_AMOUNT2 || ' amt3:' ||
                     v_AMOUNT3 || ' amt4:' ||
                     v_AMOUNT4 || ' opt1:' ||
                     v_OPT_CODE1 || ' opt2:' ||
                     v_OPT_CODE2 || ' opt3:' ||
                     v_OPT_CODE3 || ' opt4:' ||
                     v_OPT_CODE4 || ' opt5:' ||
                     v_OPT_CODE5 || ' err:' ||
                     v_err_code  || '::' || 
                     v_err_desc);                

                insert into NSU_TBX_PDRDEDN (
                    TBX_ID,
                    TBX_BDCA_CODE,
                    TBX_EFFECTIVE_DATE,
                    TBX_ACTIVITY_DATE,
                    TBX_STATUS,
                    TBX_AMOUNT1,
                    TBX_AMOUNT2,
                    TBX_AMOUNT3,
                    TBX_AMOUNT4,
                    TBX_OPT_CODE1,
                    TBX_OPT_CODE2,
                    TBX_OPT_CODE3,
                    TBX_OPT_CODE4,
                    TBX_OPT_CODE5,                
                    TBX_YEAR,
                    TBX_PICT_CODE,
                    TBX_PAYNO,
                    TBX_USER_APPROVE_FLAG,
                    TBX_USER_ID,
                    TBX_DATA_ORIGIN,
                    TBX_LOAD_DATE,
                    TBX_DEDN_DATE,
                    TBX_PIDM,
                    TBX_ERR_CODE,
                    TBX_ERR_DESC

                ) VALUES (
                    v_ID,   --ID
                    v_BDCA_CODE, 
                    v_EFFECTIVE_DATE,
                    v_ACTIVITY_DATE,
                    v_STATUS,
                    v_AMOUNT1,
                    v_AMOUNT2,
                    v_AMOUNT3,
                    v_AMOUNT4,
                    v_OPT_CODE1,
                    v_OPT_CODE2,
                    v_OPT_CODE3,
                    v_OPT_CODE4,
                    v_OPT_CODE5,                
                    null, -- YEAR
                    null, --PICT_CODE
                    null, --PAYNO
                    null, --USER_APPROVE_FLAG
                    v_UserID,
                    v_DataOrigin,
                    trunc(sysdate), --
                    null,
                    v_PIDM,
                    v_err_code,
                    v_err_desc
                  );

                --COMMIT;  
               -- echo('Status: ' || SQLCODE || ' ' || SQLERRM);

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        echo('No Data Found');
                        EXIT;
                    WHEN OTHERS THEN
                        echo('Post Insert Status: ' || SQLCODE || ' ' || SQLERRM);

            end;
        end loop;
        echo('end loop' || 'Error: '|| SQLCODE || ':' || SQLERRM);

    end if;

    destroy_filehandle;    

  EXCEPTION
    WHEN OTHERS THEN
        echo('Error: '|| SQLCODE || ':' || SQLERRM) ;
        utl_file.fclose_all;

  END load_staging_table;

-------------------------------------------------------
/*************************************************
PROCEDURE check_staging_table
    Performs a pidm lookup and validity check on emp/deduction from staging table 
    Only used if TBX data has been imported directly into the staging table with SQLDev rather than using load_staging_table

Northeastern State Univerisity
    18-Dec-2019 Scott Williamson    Start - problems with moving file prompted manual load of staging table from
                                    TBX spreadsheet - needed to fill in pidm and check TBX provided data
*************************************************/
  procedure check_staging_table AS

  /*
  remarks
--NSU_TBX_PDRDEDN
--  TBX_PIDM - key
--  TBX_ID
--  TBX_LNAME
--  TBX_FNAME
--  TBX_MI
--  TBX_BDCA_CODE
--  TBX_EFFECTIVE_DATE
--  TBX_ACTIVITY_DATE
--  TBX_STATUS
--  TBX_AMOUNT1
--  TBX_AMOUNT2
--  TBX_AMOUNT3
--  TBX_AMOUNT4
--  TBX_OPT_CODE1
--  TBX_OPT_CODE2
--  TBX_OPT_CODE3
--  TBX_OPT_CODE4
--  TBX_OPT_CODE5
--  TBX_ERR_CODE
--  TBX_ERR_DESC

  TBX_ID                      VARCHAR2(9)  +
  TBX_BDCA_CODE               VARCHAR2(3)  +
  TBX_EFFECTIVE_DATE          DATE         +
  TBX_ACTIVITY_DATE           DATE         +
  TBX_STATUS                  VARCHAR2(1)  +
  TBX_AMOUNT1                 NUMBER(11,2) +
  TBX_AMOUNT2                 NUMBER(11,2) +
  TBX_AMOUNT3                 NUMBER(11,2) +
  TBX_AMOUNT4                 NUMBER(11,2) +
  TBX_OPT_CODE1               VARCHAR2(2)  +
10 TBX_OPT_CODE2               VARCHAR2(2)  +
11 TBX_OPT_CODE3               VARCHAR2(2)  +
12 TBX_OPT_CODE4               VARCHAR2(2)  +
13 TBX_OPT_CODE5               VARCHAR2(2)  +
TBX_YEAR                    VARCHAR2(4)  +
TBX_PICT_CODE               VARCHAR2(2)  +
TBX_PAYNO                   VARCHAR2(3)  +
TBX_USER_APPROVE_FLAG       VARCHAR2(1)  
TBX_USER_ID                 VARCHAR2(30) 
TBX_DATA_ORIGIN             VARCHAR2(30) 

  */
  -----Var
  v_UserID          varchar2(30) := 'check_staging_table';
  v_DataOrigin      varchar2(30) := null;

--  v_line            varchar2(32767) := NULL; -- no idea max bytes of input file
  v_err_code        varchar(25);
  v_err_desc        varchar(200);
  v_linecount       number(10);
  v_loop            number(5);
--  v_quote_count     number(5,1) := 0.0;
--  v_quoteloop       number(5);
--  v_string          varchar2(999);

-- TBX PDRDEDN flat file fields
    v_PIDM  spriden.spriden_pidm%TYPE; --varchar2(8); -- needs to be covered to number during insert
    v_ID spriden.spriden_id%TYPE; --varchar2(9);
    v_LNAME varchar2(60);
    v_FNAME varchar2(60);
    v_MI varchar2(60);
    v_BDCA_CODE varchar2(3);
    v_EFFECTIVE_DATE date;
    v_ACTIVITY_DATE date;
    v_STATUS varchar2(1);
    v_AMOUNT1 number(11,2);
    v_AMOUNT2 number(11,2);
    v_AMOUNT3 number(11,2);
    v_AMOUNT4 number(11,2);
    v_OPT_CODE1 varchar2(4);
    v_OPT_CODE2 varchar2(4);
    v_OPT_CODE3 varchar2(4);
    v_OPT_CODE4 varchar2(4);
    v_OPT_CODE5 varchar2(4);

-- nsu_tbx_pdrdedn
    cursor c_stage is
        select
            TBX_ID
            , TBX_BDCA_CODE
            , TBX_EFFECTIVE_DATE
            , TBX_ACTIVITY_DATE
            , TBX_STATUS
            , TBX_AMOUNT1
            , TBX_AMOUNT2
            , TBX_AMOUNT3
            , TBX_AMOUNT4
            , TBX_OPT_CODE1
            , TBX_OPT_CODE2
            , TBX_OPT_CODE3
            , TBX_OPT_CODE4
            , TBX_OPT_CODE5
        from
            shadee.nsu_tbx_pdrdedn
        ;--where rownum < 2;

-- bdca rules for pre-validation validation
    cursor c_ptrbdca is
        select  ptrbdca_code
                ,ptrbdca_amt1_ind  -- each holds code in (R,N,O,S) for Req'd, Not entered, Optional, System Gen
                ,ptrbdca_amt2_ind
                ,ptrbdca_amt3_ind
                ,ptrbdca_amt4_ind
                ,ptrbdca_option1_ind
                ,ptrbdca_option2_ind
                ,ptrbdca_option3_ind
                ,ptrbdca_option4_ind
                ,ptrbdca_option5_ind
        from ptrbdca;

  -----PROC echo
    PROCEDURE echo(p_msg IN VARCHAR2)
    IS
        BEGIN
            dbms_output.put_line(p_msg);
    END echo;
  ----- PROC validate record against Banner BDCA rules
    PROCEDURE get_validation_code(  p_pidm in number, --varchar2,
                                    p_bdca_code in varchar2,
                                    p_effective_date in date,
                                    p_status in varchar2,
                                    p_amount1 in out number,
                                    p_amount2 in out number,
                                    p_amount3 in out number,
                                    p_amount4 in out number,
                                    p_opt_code1 in out varchar2,
                                    p_opt_code2 in out varchar2,
                                    p_opt_code3 in out varchar2,
                                    p_opt_code4 in out varchar2,
                                    p_opt_code5 in out varchar2,

                                    p_err_code out varchar2,
                                    p_err_desc out varchar2)

    IS
      p_amount1_rule  varchar2(1);
      p_amount2_rule  varchar2(1);
      p_amount3_rule  varchar2(1);
      p_amount4_rule  varchar2(1);
      p_option1_rule  varchar2(1);
      p_option2_rule  varchar2(1);
      p_option3_rule  varchar2(1);
      p_option4_rule  varchar2(1);
      p_option5_rule  varchar2(1);

      BEGIN
        -- need to null out zero amounts from tbx before validation if field is flagged No Entry ('N')
    --echo('top of get_validation_code');

        select  ptrbdca_amt1_ind
                ,ptrbdca_amt2_ind
                ,ptrbdca_amt3_ind
                ,ptrbdca_amt4_ind
                ,ptrbdca_option1_ind
                ,ptrbdca_option2_ind
                ,ptrbdca_option3_ind
                ,ptrbdca_option4_ind
                ,ptrbdca_option5_ind
            into
                p_amount1_rule
                ,p_amount2_rule
                ,p_amount3_rule
                ,p_amount4_rule
                ,p_option1_rule
                ,p_option2_rule
                ,p_option3_rule
                ,p_option4_rule
                ,p_option5_rule
            from ptrbdca 
            where ptrbdca_code = p_bdca_code;

        -- if indicator says there's not supposed to be anything there, and if amount is 0 then null it, otherwise let it through
        if p_amount1_rule in ('N','S') then --No entry/Sys gen
            --and p_amount1 = 0 then 
                p_amount1 := null;
        end if;
        if p_amount2_rule in ('N','S') then --No entry/Sys gen
            --and p_amount2 = 0 then 
                p_amount2 := null;
        end if;
        if p_amount3_rule in ('N','S') then --No entry/Sys gen
            --and p_amount3 = 0 then 
                p_amount3 := null;
        end if;
        if p_amount4_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_amount4 := null;
        end if;
        if p_option1_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code1 := null;
        end if;            
        if p_option2_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code2 := null;
        end if;            
        if p_option3_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code3 := null;
        end if;            
        if p_option4_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code4 := null;
        end if;            
        if p_option5_rule in ('N','S') then --No entry/Sys gen
            --and p_amount4 = 0 then 
                p_opt_code5 := null;
        end if;            

        -- TBX didn't include plan for opt out codes (H97, H98, H99)
        if p_bdca_code in ('H97','H98','H99') then
            p_opt_code1 := nvl(p_opt_code1,'10');
        end if;

        pb_deduction_detail_rules.p_validate( p_pidm,
                                              p_bdca_code,
                                              p_effective_date,
                                              p_status,
                                              null, -- ref no
                                              p_amount1,
                                              p_amount2,
                                              p_amount3,
                                              p_amount4,
                                              null, -- p_amount5 new 2019
                                              null, -- p_amount6 new 2019
                                              p_opt_code1,
                                              p_opt_code2,
                                              p_opt_code3,
                                              p_opt_code4,
                                              p_opt_code5,
                                              null, -- coverage date
                                              null, -- bdcl code
                                              'N', --w4 name change ind
                                              null, --p_w4_signed_pidm
                                              null, --p_w4_signed_date
                                              'N', --p_lockin_letter_status
                                              null, --p_lockin_letter_date
                                              null, --p_lockin_fsta_fil_st
                                              null, --p_lockin_withhold_allow
                                              null, --p_comment
                                              null, --p_comment_date
                                              null, --p_comment_user_id
                                              v_UserID, --p_user_id
                                              v_DataOrigin, --p_data_origin
                                              null, --p_brea_code
                                              null, --p_event_date
                                              null  --p_1042s_limit_ben_cde
                                              );

        if SQLCODE = 0 then                                       
                p_err_code := '0';
                p_err_desc := null;
        end if;

        exception
            when others then
                p_err_code := to_char(SQLCODE);
                p_err_desc := substr(sqlerrm,1,200);

    END get_validation_code;  
  -----  
  -----FUNC get start of data element in string
    FUNCTION f_item_start(p_line in varchar2, p_itemno in number)
        RETURN NUMBER
    IS
        p_item_position number;

        BEGIN
        --INSTR( string, substring [, start_position [, th_appearance ] ] )
            if p_itemno = 1 then p_item_position := 1;
                else p_item_position := instr(p_line, ',' ,1, p_itemno-1) +1;
            end if;

        RETURN p_item_position;

    END f_item_start;
  -----
  -----FUNC get data element length in string
    FUNCTION f_item_length(p_line in varchar2, p_itemno in number)
        RETURN NUMBER
    IS
        p_item_length number;
        p_start number;
        p_end number;
        p_item_less_one number;
        p_line2 varchar2(2000);

        BEGIN
            if p_itemno = 1 then 
                p_item_length := instr(p_line, ',' ,1) -1;
                --echo('first');
            else
                p_item_length := instr(p_line||',' , ',' ,1 ,p_itemno) - (instr(p_line||',' , ',' ,1, p_itemno-1)+1);
            end if;

        RETURN p_item_length;

    END f_item_length;
  -----    
  ----- function to get data element from line buffer
    FUNCTION f_get_item(p_line in varchar, p_itemno in number)
        RETURN VARCHAR2
    IS
        p_item varchar(32767); -- length of buffer jtbs

        BEGIN

            if p_line is null or length(p_line) < 1 then
                p_item := null;
            else
                p_item := substr(p_line,f_item_start(p_line,p_itemno),f_item_length(p_line,p_itemno));
            end if;

            --Get rid of extraneous carriage returns
            p_item := replace(p_item,chr(13));

        RETURN p_item;

    END f_get_item;
  -----
  -----
    FUNCTION f_get_pidm(p_id in varchar2)
        RETURN VARCHAR2
    IS
        p_pidm number(8);
        spriden_count number(8);

        BEGIN
            select count(*) into p_pidm from spriden where spriden_id = p_id and spriden_change_ind is null;
--            echo('checking pidm');

            if p_pidm > 0 then
                select spriden_pidm into p_pidm from spriden where spriden_id = p_id and spriden_change_ind is null;
            end if;

            --echo(spriden_count || ' ' || p_pidm);
--            exception
--                when NO_DATA_FOUND then
--                    p_pidm := 0;

        RETURN p_pidm;

    END f_get_pidm;

  -----    


BEGIN --main
--    echo('begin');
    dbms_output.enable(null);

    for i in c_stage
        loop 
            begin
   -- main
        -- get data elements
        -->>>> load from cursor
                --echo('loading values');
                -- local f_get_pidm = if ID DNE, returns '0' as PIDM
                --v_PIDM := f_get_pidm(substr(v_line,1,f_item_length(v_line,1)));
                --assume pidm is missing
                v_PIDM := f_get_pidm(i.tbx_id);
--                echo('pidm ' || v_PIDM);
                
                --v_ID := f_get_item(v_line,1);
                v_ID := i.tbx_id;
--                echo('id ' || v_ID);

                --v_BDCA_CODE := f_get_item(v_line,2);
--                echo(i.tbx_bdca_code);
--                for l in 1..length(i.tbx_bdca_code) loop
--                    echo(ascii(substr(i.tbx_bdca_code,l,1)));
--                end loop;
                
                v_BDCA_CODE := to_char(i.tbx_bdca_code);
--                echo('bdca ' || v_BDCA_CODE);

                --v_EFFECTIVE_DATE := to_date(f_get_item(v_line,3),'MM/DD/YYYY');
                v_EFFECTIVE_DATE := to_date(i.tbx_effective_date);
--                echo('eff ' || v_effective_date);

                v_ACTIVITY_DATE := trunc(sysdate);
--                echo('act ' || v_ACTIVITY_DATE);

                --v_STATUS := f_get_item(v_line,4);
                v_STATUS := i.tbx_status;
--                echo('status ' || v_STATUS);
                --v_string := f_get_item(v_line,4);
                --v_string := 'v_string:'||v_string||' len:'||length(trim(f_get_item(v_line,4))) || 'ascii:';
                --for i in 1 .. length(f_get_item(v_line,4)) loop
                --        v_string := v_string || ascii(substr(f_get_item(v_line,4),i,1)) || ' ';
                --end loop;
                --echo(v_string);

                --echo(f_get_item(v_line,5));
                --v_AMOUNT1 := to_number(f_get_item(v_line,5));
                v_AMOUNT1 := to_number(i.tbx_amount1);
--                echo('amt1 ' || v_AMOUNT1);

                --v_AMOUNT2 := to_number(f_get_item(v_line,6));
                v_AMOUNT2 := to_number(i.tbx_amount2);
                --echo('amt2 ' || v_AMOUNT2);

                --v_AMOUNT3 := to_number(f_get_item(v_line,7));
                v_AMOUNT3 := to_number(i.tbx_amount3);
                --echo('amt3 ' || v_AMOUNT3);

                --v_AMOUNT4 := to_number(f_get_item(v_line,8));
                v_AMOUNT4 := to_number(i.tbx_amount4);
                --echo('amt4 ' || v_AMOUNT4);

                --echo(f_get_item(v_line,9) );
                --v_string := f_get_item(v_line,9);
                --v_string := 'v_string:'||v_string||' len:'||length(trim(f_get_item(v_line,9))) || 'ascii:';
                --for i in 1 .. length(f_get_item(v_line,9)) loop
                --        v_string := v_string || ascii(substr(f_get_item(v_line,9),i,1)) || ' ';
                --end loop;
                --echo(v_string);
                --v_OPT_CODE1 := f_get_item(v_line,9);
                v_OPT_CODE1 := i.tbx_opt_code1;
                --echo('opt1 ' || v_OPT_CODE1);

                --echo(f_get_item(v_line,10));
                --v_OPT_CODE2 := f_get_item(v_line,10);
                v_OPT_CODE2 := i.tbx_opt_code2;
                --echo('opt2 ' || v_OPT_CODE2);

                --v_OPT_CODE3 := f_get_item(v_line,11);
                v_OPT_CODE3 := i.tbx_opt_code3;
                --echo('opt3 ' || v_OPT_CODE3);

                --v_OPT_CODE4 := f_get_item(v_line,12);
                v_OPT_CODE4 := i.tbx_opt_code4;
                --echo('opt4 ' || v_OPT_CODE4);

                --v_OPT_CODE5 := f_get_item(v_line,13);  
                v_OPT_CODE5 := i.tbx_opt_code5;
                --echo('opt5 ' || v_OPT_CODE5);

                if v_pidm > 0 then 
                    --echo('validating');
                    get_validation_code(v_PIDM,
                                        v_BDCA_CODE,
                                        v_EFFECTIVE_DATE,
                                        v_STATUS,
                                        v_AMOUNT1,
                                        v_AMOUNT2,
                                        v_AMOUNT3,
                                        v_AMOUNT4,
                                        v_OPT_CODE1,
                                        v_OPT_CODE2,
                                        v_OPT_CODE3,
                                        v_OPT_CODE4,
                                        v_OPT_CODE5, 
                                        v_err_code,    -- Returns err_code and err_desc 
                                        v_err_desc);
                    v_err_code := SQLCODE;
                    v_err_desc := 'ValCk:'||substr(SQLERRM,1,194);

                else
                    v_err_code := '-1';
                    v_err_desc := 'Bad Banner ID from TBX';
                end if;

                echo('at update - '
                    ||'pidm:'||v_PIDM
                    || ' id:' ||v_ID 
                    || ' bdca:' ||v_BDCA_CODE 
                    || ' eff:' ||v_EFFECTIVE_DATE 
                    || ' stat:' ||v_STATUS
                    || ' amt1:' ||v_AMOUNT1
                    || ' amt2:' ||v_AMOUNT2
                    || ' amt3:' ||v_AMOUNT3
                    || ' amt4:' ||v_AMOUNT4 
                    || ' opt1:' ||v_OPT_CODE1
                    || ' opt2:' ||v_OPT_CODE2
                    || ' opt3:' ||v_OPT_CODE3
                    || ' opt4:' ||v_OPT_CODE4
                    || ' opt5:' ||v_OPT_CODE5
                    || ' err:' ||v_err_code
                    || '::' ||v_err_desc);                

                update shadee.NSU_TBX_PDRDEDN 
                    SET
                        TBX_ID = v_ID,
                        TBX_BDCA_CODE = v_BDCA_CODE,
                        TBX_EFFECTIVE_DATE = v_EFFECTIVE_DATE,
                        TBX_ACTIVITY_DATE = v_ACTIVITY_DATE,
                        TBX_STATUS = v_STATUS,
                        TBX_AMOUNT1 = v_AMOUNT1,
                        TBX_AMOUNT2 = v_AMOUNT2,
                        TBX_AMOUNT3 = v_AMOUNT3,
                        TBX_AMOUNT4 = v_AMOUNT4,
                        -- need to add amount5 and 6
                        TBX_OPT_CODE1 = v_OPT_CODE1,
                        TBX_OPT_CODE2 = v_OPT_CODE2,
                        TBX_OPT_CODE3 = v_OPT_CODE3,
                        TBX_OPT_CODE4 = v_OPT_CODE4,
                        TBX_OPT_CODE5 = v_OPT_CODE5,                
                        TBX_YEAR = null,
                        TBX_PICT_CODE = null,
                        TBX_PAYNO = null,
                        TBX_USER_APPROVE_FLAG = null,
                        TBX_USER_ID = 'check_staging_table', --v_UserID,
                        TBX_DATA_ORIGIN = v_DataOrigin,
                        TBX_LOAD_DATE = null, 
                        TBX_DEDN_DATE = null,
                        TBX_PIDM = v_PIDM,
                        TBX_ERR_CODE = v_err_code,
                        TBX_ERR_DESC = v_err_desc
                    WHERE
                            tbx_pidm = v_PIDM
                        AND tbx_bdca_code = v_BDCA_CODE
                        AND trunc(tbx_effective_date) = v_EFFECTIVE_DATE;

                --COMMIT;  
               -- echo('Status: ' || SQLCODE || ' ' || SQLERRM);

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        echo('No Data Found');
                        EXIT;
                    WHEN OTHERS THEN
                        echo('Post Insert Status: ' || SQLCODE || ' ' || SQLERRM);

            end;
            echo('bottom of loop' || 'Error: '|| SQLCODE || ':' || SQLERRM);
        end loop;
        

    --end if;

    --destroy_filehandle;    
  COMMIT;  
  EXCEPTION
    WHEN OTHERS THEN
        echo('Error: '|| SQLCODE || ':' || SQLERRM) ;
--        utl_file.fclose_all;

  END check_staging_table;

-------------------------------------------------------


/*************************************************
PROCEDURE LOAD_PDRDEDN
    Takes records from NSU_TBX_PDRDEDN and calls pp_deduction.p_update or .p_create to update
    employee deduction enrollment information in Banner

Northeastern State Univerisity
    Nov/Dec 2018    Scott Williamson    Start -- used to load 2018 Open Enrollment information from TBX
    18-Dec-2019     sw                  Added AMOUNT5, AMOUNT6 to API calls 
                                        - need to check to see if TBX is providing them in future (not in 2019 file)

*************************************************/
  procedure load_pdrdedn AS

  --vars
    v_base_rowid varchar2(18);
    v_detail_rowid varchar2(18);
    v_action_flag varchar2(1);
    v_error_code varchar2(10);
    v_error_msg varchar2(200);

  --cursors
    cursor c_tbx is
        select *
        from shadee.nsu_tbx_pdrdedn
        where tbx_dedn_date is null 
          and (tbx_err_code is null or tbx_err_code = 0)
          ;--and rownum <= 20;
--          and tbx_id in 
--(
--select tbx_id from (
--    select unique tbx_id from nsu_tbx_pdrdedn_bw where tbx_id like 'N0%'
--    ) where rownum < (select count (distinct tbx_id) from nsu_tbx_pdrdedn_bw)/2
--);

  -----PROC echo
    PROCEDURE echo(p_msg IN VARCHAR2)
    IS
        BEGIN
            dbms_output.put_line(p_msg);
    END echo;
  -----          
    BEGIN
        dbms_output.enable(null);
        echo('Starting');
        for r_main in c_tbx loop
            echo(r_main.tbx_id || ':' || r_main.tbx_bdca_code);
            --check for existing record, if exists - update, if not create
            if pp_deduction.f_exists(r_main.tbx_pidm,
                                     r_main.tbx_bdca_code) = 'Y' then                     
                --update
                v_action_flag := 'U';
                --r_main.tbx_err_desc := 'Update Attempt';
                echo('Update Attempt');
                begin
                    pp_deduction.p_update(p_pidm => r_main.tbx_pidm,                       --pdrbded fields
                                      p_bdca_code => r_main.tbx_bdca_code,
                                      p_effective_date => r_main.tbx_effective_date,
                                      p_add_repl_ind => null, 
                                      p_add_repl_empl => null,
                                      p_add_repl_empr => null,
                                      p_add_repl_tax_base => null,
                                      p_arr_status => null,
                                      p_arr_balance => null,
                                      p_bond_balance => null,
                                      p_arr_recover_max => null,
                                      p_add_repl_pict_code => null,
                                      p_status => r_main.tbx_status,                    --pdrdedn fields
                                      p_ref_no => null,
                                      p_amount1 => r_main.tbx_amount1,
                                      p_amount2 => r_main.tbx_amount2,
                                      p_amount3 => r_main.tbx_amount3,
                                      p_amount4 => r_main.tbx_amount4,
                                      p_amount5 => null,
                                      p_amount6 => null,
                                      p_opt_code1 => r_main.tbx_opt_code1,
                                      p_opt_code2 => r_main.tbx_opt_code2,
                                      p_opt_code3 => r_main.tbx_opt_code3,
                                      p_opt_code4 => r_main.tbx_opt_code4,
                                      p_opt_code5 => r_main.tbx_opt_code5,
                                      p_coverage_date => to_date('01-JAN-2020','DD-MON-YYYY'), -- 1st of month following adj svc date or life event date
                                      p_bdcl_code => null,
                                      p_w4_name_change_ind => 'N',
                                      p_w4_signed_pidm => null,
                                      p_w4_signed_date => null,
                                      p_lockin_letter_status => 'N',
                                      p_lockin_letter_date => null,
                                      p_lockin_fsta_fil_st => null,
                                      p_lockin_withhold_allow => null,
                                      p_comment => null,
                                      p_comment_date => null,
                                      p_comment_user_id => null,
                                      p_user_id => 'NSU_BNR_TBX',
                                      p_data_origin => 'TBX_File',
                                      p_brea_code => null, 
                                      p_event_date => null,
                                      p_1042s_limit_ben_cde => null);
        

                                            r_main.tbx_err_code := SQLCODE;                          
                                            r_main.tbx_err_desc := SQLERRM;
                                            echo('Update status: '||r_main.tbx_err_code||' '||r_main.tbx_err_desc);

                                      exception
                                        when others then 
                                            r_main.tbx_err_code := SQLCODE;                          
                                            r_main.tbx_err_desc := SQLERRM;
                                            echo('Update err: '||r_main.tbx_err_code||' '||r_main.tbx_err_desc);

                  end;

            else
                begin
                --create
                                v_action_flag := 'C';
                                --r_main.tbx_err_desc := 'Create Attempt';
                                 echo('Create Attempt');
                                pp_deduction.p_create(p_pidm => r_main.tbx_pidm,                       --pdrbded fields
                                      p_bdca_code => r_main.tbx_bdca_code,
                                      p_begin_date => r_main.tbx_effective_date,
                                      p_add_repl_ind => null, 
                                      p_add_repl_empl => null,
                                      p_add_repl_empr => null,
                                      p_add_repl_tax_base => null,
                                      p_arr_status => null,
                                      p_arr_balance => null,
                                      p_bond_balance => null,
                                      p_arr_recover_max => null,
                                      p_add_repl_pict_code => null,
                                      p_status => r_main.tbx_status,                    --pdrdedn fields
                                      p_ref_no => null,
                                      p_amount1 => r_main.tbx_amount1,
                                      p_amount2 => r_main.tbx_amount2,
                                      p_amount3 => r_main.tbx_amount3,
                                      p_amount4 => r_main.tbx_amount4,
                                      p_amount5 => null,
                                      p_amount6 => null,
                                      p_opt_code1 => r_main.tbx_opt_code1,
                                      p_opt_code2 => r_main.tbx_opt_code2,
                                      p_opt_code3 => r_main.tbx_opt_code3,
                                      p_opt_code4 => r_main.tbx_opt_code4,
                                      p_opt_code5 => r_main.tbx_opt_code5,
                                      p_coverage_date => to_date('01-JAN-2020','DD-MON-YYYY'),
                                      p_bdcl_code => null,
                                      p_w4_name_change_ind => 'N',
                                      p_w4_signed_pidm => null,
                                      p_w4_signed_date => null,
                                      p_lockin_letter_status => 'N',
                                      p_lockin_letter_date => null,
                                      p_lockin_fsta_fil_st => null,
                                      p_lockin_withhold_allow => null,
                                      p_comment => null,
                                      p_comment_date => null,
                                      p_comment_user_id => null,
                                      p_user_id => 'NSU_BNR_TBX',
                                      p_data_origin => 'TBX_File',
                                      p_brea_code => null, 
                                      p_event_date => null,
                                      p_1042s_limit_ben_cde => null,
                                      p_base_rowid_out => v_base_rowid,
                                      p_detail_rowid_out => v_detail_rowid);

                                      exception
                                        when others then 
                                            r_main.tbx_err_code := SQLCODE;                          
                                            r_main.tbx_err_desc := SQLERRM;
                                             echo('Create err: '||r_main.tbx_err_code||' '||r_main.tbx_err_desc);

                  end;

            end if;

            -- update dedn load date field in tbx table            
            v_error_code := r_main.tbx_err_code;
            v_error_msg  := r_main.tbx_err_desc;
            if r_main.tbx_err_code = 0 then
                if v_action_flag = 'U' then
                    v_error_msg := 'Update successful';
                else
                    v_error_msg := 'Create successful';
                end if;
            end if;
            echo('Error check before ST Update: '||v_error_code||' '||v_error_msg);

            update shadee.nsu_tbx_pdrdedn
                set tbx_dedn_date = trunc(sysdate),
                    tbx_user_id = 'LOAD_PDRDEDN',
                    tbx_err_code = v_error_code,
                    tbx_err_desc = v_error_msg
                where r_main.tbx_id = nsu_tbx_pdrdedn.tbx_id
                  and r_main.tbx_bdca_code = nsu_tbx_pdrdedn.tbx_bdca_code
                  and r_main.tbx_effective_date = nsu_tbx_pdrdedn.tbx_effective_date;
--                  and r_main.tbx_activity_date = nsu_tbx_pdrdedn.tbx_activity_date
--                  and r_main.tbx_data_origin = nsu_tbx_pdrdedn.tbx_data_origin
--                  and r_main.tbx_load_date = nsu_tbx_pdrdedn.tbx_load_date;

            echo('Stage Table Update Status: '|| SQLCODE || ':' || SQLERRM);

        end loop;
        echo('end loop');
        commit;
        exception when others then  echo('Error: '|| SQLCODE || ':' || SQLERRM);  

  end load_pdrdedn;

-------------------------------------------------------
/*************************************************
PROCEDURE MASS_ENDDATE
    Procedure to update deduction records by end dating all T records in nsu_tbx_pdrdedn table

Northeastern State Univerisity
    Nov/Dec 2018    Scott Willilamson   Start - used to end date 2019 benefits from TBX info from 2018 Open Enrollment

*************************************************/
    procedure mass_enddate as

    --vars
    v_error_code varchar2(10);
    v_error_msg varchar2(200);    

    --cursors
    cursor c_tbx is -- get all T records that haven't been pushed into Banner
        select *
        from nsu_tbx_pdrdedn
        where tbx_dedn_date is null 
          and (tbx_err_code is null or tbx_err_code = 0)
          and tbx_status = 'T';

    --Internal procedures          
    -----PROC echo
    PROCEDURE echo(p_msg IN VARCHAR2)
    IS
        BEGIN
            dbms_output.put_line(p_msg);
    END echo;

    --Main
    begin
        dbms_output.enable(null);
        echo('Starting');

        for r_main in c_tbx loop

            --push to banner - update deduction code with T record

            begin
                pp_deduction.p_update(p_pidm => r_main.tbx_pidm,                       --pdrbded fields
                                      p_bdca_code => r_main.tbx_bdca_code,
                                      p_effective_date => r_main.tbx_effective_date,
                                      p_add_repl_ind => null, 
                                      p_add_repl_empl => null,
                                      p_add_repl_empr => null,
                                      p_add_repl_tax_base => null,
                                      p_arr_status => null,
                                      p_arr_balance => null,
                                      p_bond_balance => null,
                                      p_arr_recover_max => null,
                                      p_add_repl_pict_code => null,
                                      p_status => r_main.tbx_status,                    --pdrdedn fields
                                      p_ref_no => null,
                                      p_amount1 => r_main.tbx_amount1,
                                      p_amount2 => r_main.tbx_amount2,
                                      p_amount3 => r_main.tbx_amount3,
                                      p_amount4 => r_main.tbx_amount4,
                                      p_opt_code1 => r_main.tbx_opt_code1,
                                      p_opt_code2 => r_main.tbx_opt_code2,
                                      p_opt_code3 => r_main.tbx_opt_code3,
                                      p_opt_code4 => r_main.tbx_opt_code4,
                                      p_opt_code5 => r_main.tbx_opt_code5,
                                      p_coverage_date => null, 
                                      p_bdcl_code => null,
                                      p_w4_name_change_ind => 'N',
                                      p_w4_signed_pidm => null,
                                      p_w4_signed_date => null,
                                      p_lockin_letter_status => 'N',
                                      p_lockin_letter_date => null,
                                      p_lockin_fsta_fil_st => null,
                                      p_lockin_withhold_allow => null,
                                      p_comment => null,
                                      p_comment_date => null,
                                      p_comment_user_id => null,
                                      p_user_id => 'TestLoad',
                                      p_data_origin => 'TBX_File',
                                      p_brea_code => null, 
                                      p_event_date => null,
                                      p_1042s_limit_ben_cde => null);

                                      exception
                                        when others then 
                                            r_main.tbx_err_code := SQLCODE;                          
                                            r_main.tbx_err_desc := SQLERRM;

            end;


            --update push date and status to tbx table            
            v_error_code := r_main.tbx_err_code;
            v_error_msg  := r_main.tbx_err_desc;
            if r_main.tbx_err_code = 0 then
                v_error_msg := 'End date successful';
            end if; -- error msg will already be set if failed

            update nsu_tbx_pdrdedn
                set tbx_dedn_date = trunc(sysdate),
                    tbx_err_code = v_error_code,
                    tbx_err_desc = v_error_msg
                where r_main.tbx_id = nsu_tbx_pdrdedn.tbx_id
                  and r_main.tbx_bdca_code = nsu_tbx_pdrdedn.tbx_bdca_code
                  and r_main.tbx_activity_date = nsu_tbx_pdrdedn.tbx_activity_date
                  and r_main.tbx_data_origin = nsu_tbx_pdrdedn.tbx_data_origin
                  and r_main.tbx_load_date = nsu_tbx_pdrdedn.tbx_load_date;            

        end loop;
        echo('end loop');
        exception when others then  echo('Error: '|| SQLCODE || ':' || SQLERRM);          

    end mass_enddate;


END NSU_BNR_TBX;
/
