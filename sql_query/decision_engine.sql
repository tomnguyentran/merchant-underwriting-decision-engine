/*
    GOAL:
 */

SELECT
    -- Context Variables
    application_id,
    a.merchant_id,
    merchant_legal_name,
    merchant_dba_name,
    state,
    website_url,
    m.mcc_code,

    -- Risk Factors
    mcc.merchant_category_name,
    requested_limit,
    average_ticket_size,
    owner_credit_score,
    years_in_business,
    previous_chargeback_ratio,

    -- Decision Engine
    CASE
        -- Hard declined (Failed regulatory and restricted MCC)
        WHEN tmf_list = TRUE THEN 'Declined - TMF Listed'
        WHEN kyc_status = 'Failed' THEN 'Declined - Failed KYC'
        WHEN kyb_status = 'Failed' THEN 'Declined - Failed KYC'
        WHEN risk_category = 'Prohibited' THEN 'Declined - Prohibited MCC'

        -- Soft Decline (Financial Risk)
        WHEN owner_credit_score < 600 THEN 'Declined - Low Credit Score'
        WHEN years_in_business > 0 AND previous_chargeback_ratio > 1.0 THEN 'Declined - Excessive Chargebacks'

        -- Manual Review
        WHEN years_in_business = 0  AND requested_limit > 50000 THEN 'Manual Review - New Business Claims High Volume'
        WHEN average_ticket_size > 1500 AND risk_category = 'Low' THEN 'Manual Review - Ticket Size Anomaly'
        WHEN owner_credit_score BETWEEN 600 AND 650 THEN 'Manual Review - Borderline Credit'

        -- Approved
        ELSE 'Approved'
    END AS decision

FROM applications as a
-- Join 1: Connect applications to merchants
LEFT JOIN merchants AS m ON a.merchant_id = m.merchant_id
--Join 2: Connect merchants to mcc codes
LEFT JOIN mcc_codes AS mcc ON m.mcc_code = mcc.mcc_code


