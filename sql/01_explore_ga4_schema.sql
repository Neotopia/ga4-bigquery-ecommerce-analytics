-- ============================================================
-- FILE 01 : GA4 Schema Exploration
-- ============================================================
-- Dataset : bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Goal    : Understand the GA4 BigQuery export schema before
--           writing analytical queries.
--
-- ⚠️ Key difference vs classic SQL tables:
--   GA4 data is stored as EVENTS, not sessions or users.
--   Each row = one event. Dimensions like page URL or item name
--   are stored inside nested ARRAY<STRUCT> columns (event_params,
--   items, user_properties) — you must UNNEST them to access values.
--
-- 💡 How to run: copy the full query into BigQuery and click Run.
--    Dataset is public — no setup needed.
-- ============================================================


-- ============================================================
-- QUERY 1 — Raw event structure
-- What does a single GA4 event look like?
-- ============================================================

SELECT
  event_date,
  event_timestamp,
  event_name,

  -- User identifier (pseudonymous, no PII)
  user_pseudo_id,

  -- Traffic source of the session that triggered this event
  traffic_source.source        AS traffic_source,
  traffic_source.medium        AS traffic_medium,
  traffic_source.name          AS traffic_campaign,

  -- Geographic context
  geo.country                  AS country,
  geo.city                     AS city,

  -- Device context
  device.category              AS device_category,
  device.operating_system      AS os,

  -- event_params is an ARRAY of key-value pairs
  -- → you cannot SELECT a value directly, you must UNNEST first (see Query 2)
  event_params

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX = '20201101'   -- single day to keep the preview fast
LIMIT 10;


-- ============================================================
-- QUERY 2 — UNNEST event_params
--
-- event_params stores all event-level dimensions as an array:
--   [{ key: "page_location", value: { string_value: "https://..." } },
--    { key: "session_id",    value: { int_value: 1234567 } }, ...]
--
-- To extract a specific parameter, UNNEST the array and filter by key.
-- ============================================================

SELECT
  event_date,
  event_name,
  user_pseudo_id,

  -- Extract page URL from event_params
  (SELECT value.string_value
   FROM UNNEST(event_params)
   WHERE key = 'page_location')        AS page_location,

  -- Extract session ID (stored as int_value)
  (SELECT value.int_value
   FROM UNNEST(event_params)
   WHERE key = 'ga_session_id')        AS session_id,

  -- Extract engagement time in milliseconds
  (SELECT value.int_value
   FROM UNNEST(event_params)
   WHERE key = 'engagement_time_msec') AS engagement_time_msec

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX = '20201101'
  AND event_name = 'page_view'
LIMIT 20;