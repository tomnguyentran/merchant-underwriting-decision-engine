/*
    GOAL: Automate the merchant underwriting process to save time on manually reviewing applications.

    LOGIC:
    1. Join the application table with merchant and mcc codes to expand the dataset.
    2. Apply the decision logic to determine the final status of the application
        a. Hard decline: Failed regulatory and restricted MCC
        b. Soft decline: Financial risk
        c. Manual review: Anomalies & Borderline Cases
        d. Approve: No factors
    3. Return the final decision and reason for the merchant underwriting decision
    4. Creates a reusable View (decision_results) for reporting.
 */

CREATE VIEW decision_results AS

WITH decision_engine AS (
    SELECT
        -- Context Variables
        a.application_id,
        a.merchant_id,
        m.merchant_legal_name,
        m.merchant_dba_name,
        m.state,
        m.website_url,
        m.mcc_code,

        -- Risk Factors
        mcc.merchant_category_name,
        mcc.risk_category,
        a.requested_limit,
        a.average_ticket_size,
        a.owner_credit_score,
        a.years_in_business,
        a.previous_chargeback_ratio,

        -- Decision Engine
        CASE
            -- Hard declined (Failed regulatory and restricted MCC)
            WHEN a.tmf_list = TRUE THEN 'Declined - TMF Listed'
            WHEN a.kyc_status = 'Failed' THEN 'Declined - Failed KYC'
            WHEN a.kyb_status = 'Failed' THEN 'Declined - Failed KYB'
            WHEN mcc.risk_category = 'Prohibited' THEN 'Declined - Prohibited MCC'

            -- Soft Decline (Financial Risk)
            WHEN a.owner_credit_score < 600 THEN 'Declined - Low Credit Score'
            WHEN a.years_in_business > 0 AND a.previous_chargeback_ratio > 1.0 THEN 'Declined - Excessive Chargebacks'

            -- Manual Review
            WHEN a.years_in_business = 0  AND a.requested_limit > 50000 THEN 'Manual Review - New Business Claims High Volume'
            WHEN a.average_ticket_size > 1500 AND mcc.risk_category = 'Low' THEN 'Manual Review - Ticket Size Anomaly'
            WHEN a.owner_credit_score BETWEEN 600 AND 650 THEN 'Manual Review - Borderline Credit'

            -- Approved
            ELSE 'Approved'
        END AS decision_with_reason

    FROM applications as a
    -- Join 1: Connect applications to merchants
    LEFT JOIN merchants AS m ON a.merchant_id = m.merchant_id
    --Join 2: Connect merchants to mcc codes
    LEFT JOIN mcc_codes AS mcc ON m.mcc_code = mcc.mcc_code
)

-- Separate the reason from the decision_with_reason column
SELECT *,
    CASE
        WHEN decision_with_reason LIKE 'Approved%' THEN 'Approved'
        WHEN decision_with_reason LIKE '%Review%' THEN 'Manual Review'
        ELSE 'Declined'
    END AS decision
FROM decision_engine;



