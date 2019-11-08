            SELECT DISTINCT
                donor_gifts.person_uid  PERSON_UID
                , donor_gifts.annual_gift_amount ANNUAL_DONOR_GIVING
                , spouse_gifts.annual_gift_amount ANNUAL_SPOUSE_GIVING
                , donor_gifts.annual_gift_amount  
                    + spouse_gifts.annual_gift_amount ANNUAL_HOUSEHOLD_GIVING
                , donor_gifts.lifetime_gift_amount LIFETIME_DONOR_GIVING
                , spouse_gifts.lifetime_gift_amount LIFETIME_SPOUSE_GIVING
                , donor_gifts.lifetime_gift_amount
                    + spouse_gifts.lifetime_gift_amount LIFETIME_HOUSEHOLD_GIVING
                
            FROM(   SELECT
                        w_constituent.person_uid PERSON_UID
                        , SUM(  CASE WHEN w_annual_gifts.year_pos = 1 THEN nvl(w_annual_gifts.gift_amount,0) ELSE 0 END) 
                            OVER (PARTITION BY w_annual_gifts.entity_uid) ANNUAL_GIFT_AMOUNT
                        , SUM(nvl(w_annual_gifts.gift_amount,0)) OVER (PARTITION BY w_annual_gifts.entity_uid) LIFETIME_GIFT_AMOUNT
                    FROM
                        w_constituent -- plus w_annual_gifts
                        JOIN w_annual_gifts
                            ON w_constituent.person_uid = w_annual_gifts.entity_uid
                            --AND w_annual_gifts.gift_year = EXTRACT(YEAR FROM SYSDATE)
            ) DONOR_GIFTS
                LEFT JOIN(  SELECT
                                w_constituent.person_uid PERSON_UID
                                , SUM(  CASE WHEN w_annual_gifts.year_pos = 1 THEN NVL(w_annual_gifts.gift_amount,0) ELSE 0 END)
                                    OVER (PARTITION BY w_annual_gifts.entity_uid) ANNUAL_GIFT_AMOUNT
                                , SUM(NVL(w_annual_gifts.gift_amount,0)) OVER (PARTITION BY w_annual_gifts.entity_uid) LIFETIME_GIFT_AMOUNT
                            FROM
                                w_constituent
                                JOIN w_spouse
                                    ON w_constituent.person_uid = w_spouse.person_uid
                                JOIN w_annual_gifts
                                    ON w_spouse.spouse_uid = w_annual_gifts.entity_uid
                                    --AND w_annual_gifts.gift_year = EXTRACT(YEAR FROM SYSDATE)
                    ) SPOUSE_GIFTS ON donor_gifts.person_uid = spouse_gifts.person_uid
            