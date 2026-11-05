USE lung_cancer_db;

# Create views
-- View 1: one flat table of everything 
CREATE OR REPLACE VIEW vw_patient_full AS
SELECT p.patient_id, p.age, p.gender, p.country, p.bmi,
       p.smoking_status, p.family_history,
       d.diagnosis_date, d.cancer_stage, d.cholesterol_level, d.survived,
       c.hypertension, c.asthma, c.cirrhosis, c.other_cancer,
       t.treatment_type, t.end_treatment_date,
       DATEDIFF(t.end_treatment_date, d.diagnosis_date) AS treatment_days
FROM patients p
JOIN diagnoses d     USING (patient_id)
JOIN comorbidities c USING (patient_id)
JOIN treatments t    USING (patient_id);

-- View 2: The ML Dataset
CREATE OR REPLACE VIEW ml_dataset AS
SELECT age, gender, bmi, smoking_status, family_history,
       cancer_stage, cholesterol_level,
       hypertension, asthma, cirrhosis, other_cancer,
       treatment_type, treatment_days, survived
FROM vw_patient_full;

-- View 3: A summary view for dashboard
CREATE OR REPLACE VIEW vw_survival_summary AS
SELECT cancer_stage, smoking_status, treatment_type,
       COUNT(*)                        AS patients,
       ROUND(100 * AVG(survived), 2)   AS survival_rate_pct
FROM vw_patient_full
GROUP BY cancer_stage, smoking_status, treatment_type;

-- Test them
SELECT * FROM ml_dataset LIMIT 10;
SELECT * FROM vw_survival_summary ORDER BY patients DESC LIMIT 10;

# Measure performance BEFORE adding indexes
-- Test 1: filter by country
EXPLAIN ANALYZE
SELECT COUNT(*) FROM patients WHERE country = 'France';

-- Test 2: survival by stage (the Q1 query)
EXPLAIN ANALYZE
SELECT cancer_stage, ROUND(100 * AVG(survived), 2) AS survival_rate_pct
FROM diagnoses
GROUP BY cancer_stage;

-- Test 3: date range filter
EXPLAIN ANALYZE
SELECT COUNT(*) FROM diagnoses
WHERE diagnosis_date BETWEEN '2016-01-01' AND '2016-12-31';

# Create the indexes
CREATE INDEX idx_patients_country  ON patients(country);
CREATE INDEX idx_diag_date         ON diagnoses(diagnosis_date);
CREATE INDEX idx_diag_stage_surv   ON diagnoses(cancer_stage, survived);
CREATE INDEX idx_treat_type        ON treatments(treatment_type);

SHOW INDEX FROM diagnoses;
SHOW INDEX FROM patients;

-- Optional extra: a stored procedure 
DELIMITER //
CREATE PROCEDURE sp_survival_by_country(IN p_country VARCHAR(50))
BEGIN
    SELECT cancer_stage,
           COUNT(*)                        AS patients,
           ROUND(100 * AVG(survived), 2)   AS survival_rate_pct
    FROM vw_patient_full
    WHERE country = p_country
    GROUP BY cancer_stage
    ORDER BY cancer_stage;
END //
DELIMITER ;

CALL sp_survival_by_country('France');

