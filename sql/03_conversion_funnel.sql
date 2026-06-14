-- ============================================================
-- FILE 03 : Conversion Funnel Analysis
-- ============================================================
-- Dataset : bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Goal    : Reconstruct the user journey from first visit to
--           conversion and identify where users drop off.
--
-- Business context :
--   In a neobank, the funnel is typically:
--     Landing page → Product page → Sign-up start → KYC → Account opened
--   In this GA4 e-commerce dataset, the equivalent is:
--     session_start → view_item → add_to_cart → begin_checkout → purchase
--   The SQL patterns are identical — only the event names change.
--
-- 💡 How to run: copy the full query into BigQuery and click Run.
-- ============================================================


-- ============================================================
-- QUERY 1 — Overall funnel: volume and drop-off at each step
--
-- Business question: how many users complete each funnel step,
-- and where is the biggest drop-off?
-- ============================================================

SELECT
  COUNT(DISTINCT CASE WHEN event_name = 'session_start'  THEN user_pseudo_id END) AS step_1_sessions,
  COUNT(DISTINCT CASE WHEN event_name = 'view_item'       THEN user_pseudo_id END) AS step_2_view_item,
  COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart'     THEN user_pseudo_id END) AS step_3_add_to_cart,
  COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout'  THEN user_pseudo_id END) AS step_4_checkout,
  COUNT(DISTINCT CASE WHEN event_name = 'purchase'        THEN user_pseudo_id END) AS step_5_purchase,

  -- Conversion rates step by step
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END)
    / COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN user_pseudo_id END) * 100,
    1
  ) AS pct_to_view_item,

  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END), 0) * 100,
    1
  ) AS pct_view_to_cart,

  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_pseudo_id END), 0) * 100,
    1
  ) AS pct_cart_to_checkout,

  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN user_pseudo_id END), 0) * 100,
    1
  ) AS pct_checkout_to_purchase,

  -- End-to-end conversion rate: sessions → purchases
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END)
    / COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN user_pseudo_id END) * 100,
    2
  ) AS overall_conversion_rate_pct

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';