/*
    GOAL: Quantify the financial impact of the decision results.

    LOGIC:
    1. Group applications by their final decision and specific decline reason.
    2. Risk Metrics:
        a. total_applications: Measures operational volume.
        b. avg_requested_limit: Identifies if high risk applications seek larger limits.
        c. total_requested_limit: Total potential liability.
    3. Produce a high table summary to visualize the approval rate and financial impact.
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