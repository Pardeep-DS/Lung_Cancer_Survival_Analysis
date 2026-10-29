USE lung_cancer_db;

# Row counts match the source
SELECT 'staging' AS tbl, COUNT(*) AS n FROM stg_lung_cancer
UNION ALL SELECT 'patients', COUNT(*) FROM patients
UNION ALL SELECT 'diagnoses', COUNT(*) FROM diagnoses
UNION ALL SELECT 'treatments', COUNT(*) FROM treatments
UNION ALL SELECT 'comorbidities', COUNT(*) FROM comorbidities;

# Missing values
SELECT
    COUNT(*) - COUNT(p.age)              AS missing_age,
    COUNT(*) - COUNT(p.bmi)              AS missing_bmi,
    COUNT(*) - COUNT(p.country)          AS missing_country,
    COUNT(*) - COUNT(d.cholesterol_level) AS missing_cholesterol,
    COUNT(*) - COUNT(d.diagnosis_date)   AS missing_diag_date,
    COUNT(*) - COUNT(t.end_treatment_date) AS missing_end_date
FROM patients p
JOIN diagnoses d USING (patient_id)
JOIN treatments t USING (patient_id);

# Duplicates and orphans 
-- Patients with more than one diagnosis or treatment row (expect 0 rows)
SELECT patient_id, COUNT(*) FROM diagnoses GROUP BY patient_id HAVING COUNT(*) > 1;
SELECT patient_id, COUNT(*) FROM treatments GROUP BY patient_id HAVING COUNT(*) > 1;

-- Patients missing a diagnosis (expect 0)
SELECT COUNT(*) AS orphan_patients
FROM patients p
LEFT JOIN diagnoses d USING (patient_id)
WHERE d.patient_id IS NULL;

#Impossible or extreme values
SELECT
    MIN(age) AS min_age,  MAX(age) AS max_age,
    MIN(bmi) AS min_bmi,  MAX(bmi) AS max_bmi
FROM patients;

SELECT MIN(cholesterol_level) AS min_chol, MAX(cholesterol_level) AS max_chol
FROM diagnoses;

-- Count of suspicious rows
SELECT COUNT(*) AS suspicious_patients
FROM patients
WHERE age < 18 OR age > 100 OR bmi < 12 OR bmi > 60;

# Date Logic
-- Treatment ended before diagnosis (expect 0)
SELECT COUNT(*) AS bad_date_order
FROM diagnoses d
JOIN treatments t USING (patient_id)
WHERE t.end_treatment_date < d.diagnosis_date;

-- Date range and treatment duration
SELECT MIN(d.diagnosis_date) AS first_dx,
       MAX(d.diagnosis_date) AS last_dx,
       MIN(DATEDIFF(t.end_treatment_date, d.diagnosis_date)) AS min_days,
       MAX(DATEDIFF(t.end_treatment_date, d.diagnosis_date)) AS max_days,
       ROUND(AVG(DATEDIFF(t.end_treatment_date, d.diagnosis_date)), 1) AS avg_days
FROM diagnoses d
JOIN treatments t USING (patient_id);

# Category Consistency 
SELECT cancer_stage,   COUNT(*) AS n FROM diagnoses  GROUP BY cancer_stage;
SELECT smoking_status, COUNT(*) AS n FROM patients   GROUP BY smoking_status;
SELECT gender,         COUNT(*) AS n FROM patients   GROUP BY gender;
SELECT treatment_type, COUNT(*) AS n FROM treatments GROUP BY treatment_type;
SELECT family_history, COUNT(*) AS n FROM patients   GROUP BY family_history;

# Binary flags contain only 0 and 1
SELECT 'survived' AS col, survived AS val, COUNT(*) AS n FROM diagnoses GROUP BY survived
UNION ALL SELECT 'hypertension', hypertension, COUNT(*) FROM comorbidities GROUP BY hypertension
UNION ALL SELECT 'asthma',       asthma,       COUNT(*) FROM comorbidities GROUP BY asthma
UNION ALL SELECT 'cirrhosis',    cirrhosis,    COUNT(*) FROM comorbidities GROUP BY cirrhosis
UNION ALL SELECT 'other_cancer', other_cancer, COUNT(*) FROM comorbidities GROUP BY other_cancer;
