declare
    v_go number;
    y varchar2(1);

begin

    v_go := :Button1;

begin
    dbms_output.put_line('before inside 1');
    if v_go is not null then
    --nsudev.nsu_vendor_import(upper(:$User.Name));
        select 'x' into y from dual;
        dbms_output.put_line('top inside 1');
        RAISE_APPLICATION_ERROR(-20001, 'problem (really this: ' || sqlcode || ' ' || sqlerrm || ')' );
        dbms_output.put_line('top2 inside 1');
    else
        dbms_output.put_line('bottom inside 1');
    
    end if;
    dbms_output.put_line('after inside 1');
    exception
        when others then
            dbms_output.put_line('error msg: ' || sqlcode || ' / ' || sqlerrm);
    
end;
dbms_output.put_line('outside 1');
exception
    when others then
        raise_application_error(-20002, 'big problem');
        dbms_output.put_line(sqlerrm);


end;