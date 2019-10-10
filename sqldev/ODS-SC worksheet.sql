with
w_range_tot_gift as
(
select
   entity_uid,
   trim(to_char(sum(nvl(gift.gift_amount,0)), '999999990.99')) gift_amt
from gift
where gift_date between :parm_DT_GivingStart and :parm_DT_GivingEnd
group by entity_uid
)

select * from w_range_tot_gift;