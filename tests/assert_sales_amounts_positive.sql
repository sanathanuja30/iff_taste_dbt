-- tests/assert_sales_amounts_positive.sql
-- Data Quality Test 4: Sales transaction dollar amounts must be positive.
-- A zero or negative amount likely indicates a data feed error.
-- 
-- NOTE: Zero quantity_liters is tracked separately (assert_sales_zero_quantity).
-- As of the current dataset, 22 transactions have amount_dollar = 0 - these
-- are genuine data quality failures requiring escalation to the sales ops team.
-- Action on failure: do not include zero-amount rows in revenue KPIs;
-- route to a quarantine table; alert sales ops team.

SELECT transaction_id, amount_dollar
FROM {{ ref('slv_sales_transactions') }}
WHERE amount_dollar <= 0
   OR amount_dollar IS NULL
