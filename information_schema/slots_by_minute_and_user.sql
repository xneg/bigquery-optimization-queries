-- This query will show the slot usage of all jobs for each minute in the interval for each user

-- Change this value to change how far in the past the query will search
DECLARE interval_in_days INT64 DEFAULT 7;

DECLARE time_period INT64;
SET time_period = (1000*60);  -- Number of milliseconds in a minute

BEGIN
    WITH src AS (
      SELECT
        user_email AS user,
        SAFE_DIVIDE(SUM(total_slot_ms), time_period) AS slotUsage,
        DATETIME_TRUNC(creation_time, MINUTE) AS creationTime
      FROM
        `<project-name>`.`<dataset-region>`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
      WHERE
        creation_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL interval_in_days DAY)
        AND CURRENT_TIMESTAMP()
        AND total_slot_ms IS NOT NULL
      GROUP BY
        user_email, creationTime),
    timeSeries AS(
      SELECT
        *
      FROM
        UNNEST(generate_timestamp_array(DATETIME_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL interval_in_days DAY), MINUTE),
            DATETIME_TRUNC(CURRENT_TIMESTAMP(), MINUTE),
            INTERVAL 1 MINUTE)) AS timeInterval
    ),
    joined AS (
      SELECT
        user,
        COALESCE(slotUsage, 0) as slotUsage,
        timeInterval
      FROM
        src RIGHT OUTER JOIN timeSeries
          ON creationTime = timeInterval)

SELECT
  slotUsage,
  user,
  timeInterval
FROM
  joined
ORDER BY
  timeInterval ASC;
END