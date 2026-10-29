USE lung_cancer_db;

# Aggregation and joins
-- Overall survival rate by cancer stage (GROUP BY, ORDER BY, AVG)
SELECT cancer_stage,
       COUNT(*)                          AS total_patients,
       SUM(survived)                     AS survivors,
       ROUND(100 * AVG(survived), 2)     AS survival_rate_pct
FROM diagnoses
GROUP BY cancer_stage
ORDER BY cancer_stage;

-- Survival by smoking status (JOIN)
SELECT p.smoking_status,
       COUNT(*)                          AS patients,
       ROUND(100 * AVG(d.survived), 2)   AS survival_rate_pct
FROM patients p
JOIN diagnoses d USING (patient_id)
GROUP BY p.smoking_status
ORDER BY survival_rate_pct DESC;

-- Treatment effectiveness and duration (multi-table join, date functions)
SELECT t.treatment_type,
       COUNT(*)                                                   AS patients,
       ROUND(100 * AVG(d.survived), 2)                            AS survival_rate_pct,
       ROUND(AVG(DATEDIFF(t.end_treatment_date, d.diagnosis_date)), 1) AS avg_treatment_days
FROM treatments t
JOIN diagnoses d USING (patient_id)
GROUP BY t.treatment_type
ORDER BY survival_rate_pct DESC;

# Conditional logic and subqueries 
-- Survival by age group (CASE)
SELECT CASE
           WHEN p.age < 40 THEN 'Under 40'
           WHEN p.age BETWEEN 40 AND 54 THEN '40-54'
           WHEN p.age BETWEEN 55 AND 69 THEN '55-69'
           ELSE '70+'
       END AS age_group,
       COUNT(*)                        AS patients,
       ROUND(100 * AVG(d.survived), 2) AS survival_rate_pct
FROM patients p
JOIN diagnoses d USING (patient_id)
GROUP BY age_group
ORDER BY MIN(p.age);

-- Survival by BMI category (CASE)
SELECT CASE
           WHEN p.bmi < 18.5 THEN 'Underweight'
           WHEN p.bmi < 25   THEN 'Normal'
           WHEN p.bmi < 30   THEN 'Overweight'
           ELSE 'Obese'
       END AS bmi_category,
       COUNT(*)                        AS patients,
       ROUND(100 * AVG(d.survived), 2) AS survival_rate_pct
FROM patients p
JOIN diagnoses d USING (patient_id)
GROUP BY bmi_category
ORDER BY MIN(p.bmi);

-- Countries with above-average survival (subquery + HAVING)
SELECT p.country,
       COUNT(*)                        AS patients,
       ROUND(100 * AVG(d.survived), 2) AS survival_rate_pct
FROM patients p
JOIN diagnoses d USING (patient_id)
GROUP BY p.country
HAVING AVG(d.survived) > (SELECT AVG(survived) FROM diagnoses)
ORDER BY survival_rate_pct DESC;

# CTEs
-- Number of comorbidities vs survival (CTE)
WITH risk AS (
    SELECT patient_id,
           hypertension + asthma + cirrhosis + other_cancer AS condition_count
    FROM comorbidities
)
SELECT r.condition_count,
       COUNT(*)                        AS patients,
       ROUND(100 * AVG(d.survived), 2) AS survival_rate_pct
FROM risk r
JOIN diagnoses d USING (patient_id)
GROUP BY r.condition_count
ORDER BY r.condition_count;

-- Smoking status X cancer stage matrix (CASE pivot)
SELECT p.smoking_status,
       ROUND(100 * AVG(CASE WHEN d.cancer_stage = 'Stage I'   THEN d.survived END), 2) AS stage_1,
       ROUND(100 * AVG(CASE WHEN d.cancer_stage = 'Stage II'  THEN d.survived END), 2) AS stage_2,
       ROUND(100 * AVG(CASE WHEN d.cancer_stage = 'Stage III' THEN d.survived END), 2) AS stage_3,
       ROUND(100 * AVG(CASE WHEN d.cancer_stage = 'Stage IV'  THEN d.survived END), 2) AS stage_4
FROM patients p
JOIN diagnoses d USING (patient_id)
GROUP BY p.smoking_status;

# Window fumctions (the standout ones)
-- Top 5 countries by case count, with rank and share of total (RANK, SUM(), OVER)
SELECT country, cases, rnk,
       ROUND(100 * cases / SUM(cases) OVER (), 2) AS pct_of_total
FROM (
    SELECT country,
           COUNT(*) AS cases,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM patients
    GROUP BY country
) ranked
WHERE rnk <= 5;

-- Yearly trend with year-over-year change (LAG)
WITH yearly AS (
    SELECT YEAR(diagnosis_date)            AS yr,
           COUNT(*)                         AS cases,
           ROUND(100 * AVG(survived), 2)    AS survival_rate_pct
    FROM diagnoses
    GROUP BY YEAR(diagnosis_date)
)
SELECT yr, cases,
       cases - LAG(cases) OVER (ORDER BY yr)                   AS cases_change,
       survival_rate_pct,
       survival_rate_pct - LAG(survival_rate_pct) OVER (ORDER BY yr) AS survival_change
FROM yearly
ORDER BY yr;
