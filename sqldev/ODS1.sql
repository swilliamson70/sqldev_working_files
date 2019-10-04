create global temporary table nsudev.nsu_gtt_table (id number, description varchar2(20) )
on commit delete rows;

create table nsu_nongtt_table (id number, description varchar2(20) );  

select tablespace_name, username, bytes, max_bytes
from dba_ts_quotas
where tablespace_name = 'USERS'
and username = 'NSUDEV';

create global temporary table alumni.nsu_gtt_table (id number, description varchar2(20) )
on commit delete rows;

create table nsu_nongtt_table (id number, description varchar2(20) );  

select * from dba_ts_quotas;

reate global temporary table nsudev.nsu_gtt_table (id number, description varchar2(20) )
on commit delete rows;

create table nsu_nongtt_table (id number, description varchar2(20) );  

select tablespace_name, username, bytes, max_bytes
from dba_ts_quotas
where tablespace_name = 'USERS'
and username = 'NSUDEV';