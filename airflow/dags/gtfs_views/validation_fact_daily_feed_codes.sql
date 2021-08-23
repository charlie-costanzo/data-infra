---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.validation_fact_daily_feed_codes"
dependencies:
  - validation_fact_daily_feed_notices

---

-- This view counts daily validation notices per feed and code

WITH

-- one row per individual code violation, within a feed, per day (where data exists)
daily_validation_notices AS (
    SELECT * FROM `views.validation_fact_daily_feed_notices`
),

-- Daily feeds crossed against codes. This is the full dimension table for our
-- result, so we RIGHT JOIN it in below to ensure we have feed x code, even
-- when n_notices is 0
date_range AS (
    SELECT DISTINCT date FROM daily_validation_notices
),
unique_codes AS (
    SELECT DISTINCT code FROM daily_validation_notices
),
daily_feed_cross_codes AS (
    SELECT
        t1.feed_key
        , t1.calitp_feed_id   -- for final LAG below, removed from final table
        , t2.date AS date
        , t3.code
    FROM `views.gtfs_schedule_dim_feeds` t1
    JOIN date_range t2
      ON t1.calitp_extracted_at <= t2.date
          AND t1.calitp_deleted_at > t2.date
    CROSS JOIN unique_codes t3
),

-- combine tables to get entries for each level of date, feed on date, code
final_counts AS (
    SELECT
        feed_key
        , calitp_feed_id
        , date
        , code
        , COUNT(*) AS n_notices
    FROM daily_validation_notices
    RIGHT JOIN daily_feed_cross_codes USING (feed_key, code, date)
    GROUP BY 1, 2, 3, 4
),
final_count_lagged AS (
    SELECT
      * EXCEPT (n_notices, calitp_feed_id)
      , LAG (n_notices)
            OVER (PARTITION BY calitp_feed_id, code ORDER BY date)
        AS prev_n_notices
      ,COALESCE(n_notices, 0) as n_notices
    FROM final_counts

  )

SELECT
  * EXCEPT(prev_n_notices)
  , n_notices - prev_n_notices AS diff_n_notices
FROM final_count_lagged