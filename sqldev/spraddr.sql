select trunc(sysdate) - spraddr_from_date as longago from spraddr where spraddr_pidm = 31091;
select round(months_between(trunc(sysdate),spraddr_from_date)/12,2) as "longago" from spraddr where spraddr_pidm = 31091
and round(months_between(trunc(sysdate),spraddr_from_date)/12,2) > 4;
select rowid,spraddr.* from spraddr where rowid = 'AAARanAAGAAADfzAAA';
select spraddr_atyp_code,spraddr_seqno,spraddr_from_date,spraddr_to_date from spraddr 
where (spraddr_to_date is null 
  or spraddr_to_date >= sysdate)
  and spraddr_from_date <= sysdate
  and rowid = 'AAARanAAQAACLdHAAF'
  ;
select extract(year from spraddr_to_date) from spraddr
where rowid = 'AAARanAAQAACLdHAAF'
;
SELECT  spraddr_atyp_code
,spraddr_seqno
,spraddr_from_date
,spraddr_to_date from spraddr 
WHERE (spraddr_to_date IS NULL 
  OR spraddr_to_date >= SYSDATE)
  AND spraddr_from_date <= SYSDATE
   and rowid = 'AAARanAAQAACLdHAAF';

