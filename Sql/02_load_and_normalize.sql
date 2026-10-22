USE lung_cancer_db;

# Fill them from the staging table
INSERT INTO patients (patient_id, age, gender, country, bmi, smoking_status, family_history)
SELECT id, age, gender, country, bmi, smoking_status, family_history
FROM stg_lung_cancer;

INSERT INTO diagnoses (patient_id, diagnosis_date, cancer_stage, cholesterol_level, survived)
SELECT id, diagnosis_date, cancer_stage, cholesterol_level, survived
FROM stg_lung_cancer;

INSERT INTO treatments (patient_id, treatment_type, end_treatment_date)
SELECT id, treatment_type, end_treatment_date
FROM stg_lung_cancer;

INSERT INTO comorbidities (patient_id, hypertension, asthma, cirrhosis, other_cancer)
SELECT id, hypertension, asthma, cirrhosis, other_cancer
FROM stg_lung_cancer;

# To Verify records
SELECT 'patients' AS tbl, COUNT(*) AS n FROM patients
UNION ALL SELECT 'diagnoses', COUNT(*) FROM diagnoses
UNION ALL SELECT 'treatments', COUNT(*) FROM treatments
UNION ALL SELECT 'comorbidities', COUNT(*) FROM comorbidities;

SELECT p.patient_id, p.age, d.cancer_stage, t.treatment_type, d.survived
FROM patients p
JOIN diagnoses d USING (patient_id)
JOIN treatments t USING (patient_id)
LIMIT 10;
