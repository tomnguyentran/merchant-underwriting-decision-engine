/*
    GOAL:
 */

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
        WHEN a.kyb_status = 'Failed' THEN 'Declined - Failed KYC'
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
    END AS decision

FROM applications as a
-- Join 1: Connect applications to merchants
LEFT JOIN merchants AS m ON a.merchant_id = m.merchant_id
--Join 2: Connect merchants to mcc codes
LEFT JOIN mcc_codes AS mcc ON m.mcc_code = mcc.mcc_code


