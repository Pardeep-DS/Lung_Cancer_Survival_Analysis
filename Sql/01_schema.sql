USE lung_cancer_db;

# Create the tables
CREATE TABLE patients (
    patient_id     INT PRIMARY KEY,
    age            INT,
    gender         VARCHAR(10),
    country        VARCHAR(50),
    bmi            DECIMAL(5,1),
    smoking_status VARCHAR(30),
    family_history VARCHAR(5)
);

CREATE TABLE diagnoses (
    diagnosis_id      INT AUTO_INCREMENT PRIMARY KEY,
    patient_id        INT,
    diagnosis_date    DATE,
    cancer_stage      VARCHAR(20),
    cholesterol_level INT,
    survived          TINYINT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

CREATE TABLE treatments (
    treatment_id       INT AUTO_INCREMENT PRIMARY KEY,
    patient_id         INT,
    treatment_type     VARCHAR(30),
    end_treatment_date DATE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

CREATE TABLE comorbidities (
    patient_id   INT PRIMARY KEY,
    hypertension TINYINT,
    asthma       TINYINT,
    cirrhosis    TINYINT,
    other_cancer TINYINT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);
