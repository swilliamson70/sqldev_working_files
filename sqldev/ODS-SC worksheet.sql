with
w_spec_purpose as
(
SELECT entity_uid, max(nvl(SPECIAL_PURPOSE_TYPE,'XXXXX')
                          || '-' || nvl(SPECIAL_PURPOSE_TYPE_DESC,'XXXXXXXXXXXXXXXXXXXXXXXXXX')
                          || '/' || nvl(SPECIAL_PURPOSE_GROUP,'XXXXX')
                          || '-' || nvl(SPECIAL_PURPOSE_GROUP_DESC,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')) keep (dense_rank first order by SPECIAL_PURPOSE_DATE desc, special_purpose_type) spec_purpose
FROM special_purpose_group
group by entity_uid
)
select * from w_spec_purpose
order by 1;


select * from mail;
select * from aprmail;