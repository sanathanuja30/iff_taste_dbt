-- tests/assert_sales_zero_quantity_warning.sql
-- Data Quality Warning: 475 transactions have quantity_liters = 0 but a non-zero dollar amount.
-- This is an anomaly (sold nothing but charged for it) that should be investigated.
-- This test documents the issue for stakeholder awareness.
-- 
-- Unlike assert_sales_amounts_positive, this test is flagged as a WARNING (not a blocker)
-- because the transactions may represent service fees, minimum charges, or other non-volume charges.
-- Action: report count to data steward; annotate in dashboard tooltips.

SELECT transaction_id, amount_dollar, quantity_liters
FROM {{ ref('slv_sales_transactions') }}
WHERE quantity_liters = 0 AND amount_dollar > 0
