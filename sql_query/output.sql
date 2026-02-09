/*

 */


SELECT
    decision, ---- The Category (Approved / Declined / Manual Review)
    decision_with_reason, -- The Detail (Why?)
    COUNT(*) as total_applications,
    ROUND(AVG(requested_limit), 2) AS avg_requested_limit, -- Average risk ($)
    SUM(requested_limit) AS total_requested_limit -- Total risk ($)

FROM decision_results
GROUP BY decision_with_reason, decision
ORDER BY decision, total_applications DESC;