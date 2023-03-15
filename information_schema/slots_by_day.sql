-- This query will show the aggregate average slot usage of all jobs for each day in the specified timeframe.

-- Change this value to change how far in the past the query will search
DECLARE interval_in_days INT64 DEFAULT 7;

DECLARE time_period INT64;
SET time_period = (1000*60*60*24);  -- Number of milliseconds in a day

BEGIN
    WITH src AS (
      SELECT
        SAFE_DIVIDE(SUM(total_slot_ms), time_period) AS slotUsage,
        DATETIME_TRUNC(creation_time,
          DAY) AS creationTime
      FROM
        `<project-name>`.`<dataset-region>`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
      WHERE
        creation_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL interval_in_days DAY)
        AND CURRENT_TIMESTAMP()
        AND total_slot_ms IS NOT NULL
      GROUP BY
        creationTime),
  timeSeries AS(
    SELECT
      *
    FROM
      UNNEST(generate_timestamp_array(DATETIME_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL interval_in_days DAY), DAY),
          DATETIME_TRUNC(CURRENT_TIMESTAMP(), DAY),
          INTERVAL 1 DAY)) AS timeInterval
  ),
  joined AS (
      SELECT
        COALESCE(src.slotUsage, 0) as slotUsage,
        timeInterval
      FROM
        src RIGHT OUTER JOIN timeSeries
          ON creationTime = timeInterval)

SELECT
  *
FROM
  joined
ORDER BY
  timeInterval ASC;
END