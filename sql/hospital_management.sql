CREATE DATABASE hospital_management;
USE hospital_management;
SELECT * FROM patients;
select * from billing;
select * from treatments;
select * from appointments;
select * from doctors;

-- Which insurance provider generated the highest revenue and how many patients used insurance as payment method
SELECT p.insurance_provider, round(sum(b.amount),2) AS amount, COUNT(DISTINCT p.patient_id) AS total_patients
FROM patients p
JOIN billing b
ON p.patient_id = b.patient_id
WHERE b.payment_method = "Insurance"
GROUP BY p.insurance_provider
ORDER BY amount DESC;

-- Which age category spends the most
SELECT p.age_category, round(sum(b.amount), 2) AS billing_amount
FROM patients p
JOIN billing b
ON p.patient_id = b.patient_id
GROUP BY p.age_category
ORDER BY billing_amount DESC;

-- Monthly patient registration trend
SELECT MONTHNAME(STR_TO_DATE(registration_date, '%d-%m-%y')) AS month_name, COUNT(*)
FROM patients
GROUP BY month_name;

-- which doctor handles the most patients
SELECT d.full_name AS doctor_name, COUNT(a.patient_id) AS total_patients
FROM doctors d
JOIN appointments a
ON d.doctor_id = a.doctor_id
GROUP BY d.full_name 
ORDER BY  total_patients DESC;

-- which department generates highest revenue
SELECT d.specialization, ROUND(SUM(b.amount),2) AS billing_amount
FROM doctors d
JOIN appointments a
ON d.doctor_id = a.doctor_id
JOIN billing b
ON a.patient_id = b.patient_id
GROUP BY d.specialization
ORDER BY billing_amount DESC;

-- Most common treatment type
SELECT t.treatment_type, COUNT(*) AS total_patients
FROM treatments t
JOIN billing b
ON t.treatment_id = b.treatment_id
JOIN patients p
ON p.patient_id = b.patient_id
GROUP BY t.treatment_type;

-- patient with highest billing amount
SELECT p.full_name AS patient_name, b.amount AS billing_amount
FROM patients p
JOIN billing b
ON p.patient_id = b.patient_id
ORDER BY billing_amount DESC
LIMIT 5;

-- Repeat patient count
SELECT patient_id, COUNT(*) AS visit_count
FROM appointments
GROUP BY patient_id
HAVING COUNT(*) > 1;

-- rank hospital branch with total revenue generated
SELECT d.hospital_branch, ROUND(SUM(b.amount),2) AS total_revenue,
RANK() OVER (ORDER BY ROUND(SUM(b.amount),2) DESC) AS rn
FROM doctors d
JOIN appointments a
ON d.doctor_id = a.doctor_id
JOIN billing b
ON a.patient_id = b.patient_id
GROUP BY d.hospital_branch;

-- Categorise billing amount
SELECT patient_id, amount, 
CASE 
WHEN amount > 4000 THEN 'High'
WHEN amount BETWEEN 1000 AND 4000 THEN 'Medium'
ELSE 'Low'
END AS bill_category
FROM billing;

-- which specialization has the highest pending payment
SELECT d.specialization, ROUND(SUM(b.amount),2) AS pending_payment
FROM doctors d
JOIN appointments a
ON d.doctor_id = a.doctor_id
JOIN billing b
ON b.patient_id = a.patient_id
WHERE b.payment_status = "Pending"
GROUP BY d.specialization
ORDER BY pending_payment DESC;

-- running total of paid revenue
SELECT bill_date, amount,
SUM(amount) OVER (ORDER BY bill_date) AS running_revenue
FROM billing
WHERE payment_status = "Paid";


-- Difference between appointment date and treatment date. Also categorise on the basis of delay in treatment
SELECT 
    a.patient_id,
    DATEDIFF(
        STR_TO_DATE(a.appointment_date, '%Y-%m-%d'),
        STR_TO_DATE(t.treatment_date, '%d-%m-%Y')
    ) AS treatment_delay,
    
    CASE
        WHEN DATEDIFF(
            STR_TO_DATE(a.appointment_date, '%Y-%m-%d'),
            STR_TO_DATE(t.treatment_date, '%d-%m-%Y')
        ) <= 1 THEN 'Quick Treatment'
        
        WHEN DATEDIFF(
            STR_TO_DATE(a.appointment_date, '%Y-%m-%d'),
            STR_TO_DATE(t.treatment_date, '%d-%m-%Y')
        ) <= 3 THEN 'Normal Treatment'
        
        ELSE 'Delayed Treatment'
    END AS treatment_speed
FROM appointments a
JOIN treatments t
ON a.appointment_id = t.appointment_id;

-- Which payment type generates the highest revenue
SELECT payment_method, ROUND(SUM(amount),2) AS billing_amount
FROM billing 
GROUP BY payment_method
ORDER BY billing_amount DESC;

-- Compare each patient's bill with department average
SELECT p.patient_id, p.full_name, d.specialization, b.amount AS patient_bill, 
AVG(b.amount) OVER (PARTITION BY d.specialization) AS dept_avg,
CASE WHEN b.amount > AVG(b.amount) OVER (PARTITION BY d.specialization) THEN "Above average"
WHEN b.amount < AVG(b.amount) OVER (PARTITION BY d.specialization) THEN "Below average"
ELSE "Equal to average"
END AS bill_comparison
FROM patients p
JOIN appointments a
ON p.patient_id = a.patient_id
JOIN doctors d
ON a.doctor_id = d.doctor_id
JOIN billing b
ON b.patient_id = p.patient_id;

