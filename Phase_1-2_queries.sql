-- EU Ownership Experience — Warranty KPI Dashboard

CREATE DATABASE IF NOT EXISTS kia_warranty_db;
USE kia_warranty_db;
 
DROP TABLE IF EXISTS vehicle_warranty;
 
 -- PHASE 1.   # Schema creation & data load
 
CREATE TABLE vehicle_warranty (
    Vehicle_Model        VARCHAR(50),
    Mileage              DECIMAL(10,2),
    Maintenance_History  VARCHAR(20),
    Reported_Issues      INT,
    Vehicle_Age          DECIMAL(5,2),
    Fuel_Type            VARCHAR(20),
    Transmission_Type    VARCHAR(20),
    Engine_Size          DECIMAL(8,2),
    Odometer_Reading     DECIMAL(10,2),
    Last_Service_Date    DATE,
    Warranty_Expiry_Date DATE,
    Owner_Type           VARCHAR(20),
    Insurance_Premium    DECIMAL(10,2),
    Service_History      INT,
    Accident_History     INT,
    Fuel_Efficiency      DECIMAL(6,2),
    Tire_Condition       VARCHAR(20),
    Brake_Condition      VARCHAR(20),
    Battery_Status       VARCHAR(20),
    Need_Maintenance     TINYINT(1)
);

USE kia_warranty_db;

-- Droped 7 columns that we don't need
ALTER TABLE vehicle_warranty
    DROP COLUMN Transmission_Type,
    DROP COLUMN Engine_Size,
    DROP COLUMN Insurance_Premium,
    DROP COLUMN Service_History,
    DROP COLUMN Tire_Condition,
    DROP COLUMN Brake_Condition,
    DROP COLUMN Battery_Status;

 -- final structure
DESCRIBE vehicle_warranty;

-- Confirm rows 
SELECT COUNT(*) AS total_rows FROM vehicle_warranty;




--  Phase 2: KPI SQL Queries. # 8 KPI queries across 3 teams
-- ============================================================
-- EU Ownership Experience — Warranty KPI Dashboard
--  Database : kia_warranty_db
--  Table    : vehicle_warranty
--  Teams    : Warranty | Service Marketing | BI
-- ============================================================

USE kia_warranty_db;


-- ============================================================
--  TEAM: BI
--  KPI : Top-level summary — overall health of the dataset
--  USE : KPI cards at the top of the Tableau dashboard
-- ============================================================

SELECT
    COUNT(*)                                            AS Total_Vehicles,
    SUM(Need_Maintenance)                               AS Vehicles_Need_Maintenance,
    ROUND(SUM(Need_Maintenance) * 100.0 / COUNT(*), 1) AS Maintenance_Rate_Pct,
    ROUND(AVG(Reported_Issues), 2)                     AS Avg_Reported_Issues,
    ROUND(AVG(Vehicle_Age), 2)                         AS Avg_Vehicle_Age_Yrs,
    ROUND(AVG(Fuel_Efficiency), 2)                     AS Avg_Fuel_Efficiency_KPL,
    SUM(Accident_History)                              AS Total_Accidents
FROM vehicle_warranty;


-- ============================================================
--  TEAM: Warranty
--  KPI : Claims volume and issue rate by vehicle model
--  USE : Bar chart — which model generates the most issues
-- ============================================================

SELECT
    Vehicle_Model,
    COUNT(*)                                            AS Total_Vehicles,
    SUM(Reported_Issues)                               AS Total_Reported_Issues,
    ROUND(AVG(Reported_Issues), 2)                     AS Avg_Issues_Per_Vehicle,
    SUM(Need_Maintenance)                              AS Vehicles_Need_Maintenance,
    ROUND(SUM(Need_Maintenance) * 100.0 / COUNT(*), 1) AS Maintenance_Rate_Pct
FROM vehicle_warranty
GROUP BY Vehicle_Model
ORDER BY Total_Reported_Issues DESC;


-- ============================================================
--  TEAM: Warranty
--  KPI : Warranty expiry status — active vs expired
--  USE : KPI card + pie chart in Tableau
-- ============================================================

SELECT
    CASE
        WHEN Warranty_Expiry_Date >= CURDATE() THEN 'Active'
        WHEN Warranty_Expiry_Date <  CURDATE() THEN 'Expired'
        ELSE 'Unknown'
    END                                                AS Warranty_Status,
    COUNT(*)                                           AS Total_Vehicles,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS Percentage
FROM vehicle_warranty
GROUP BY Warranty_Status
ORDER BY Total_Vehicles DESC;


-- ============================================================
--  TEAM: Warranty
--  KPI : Issue rate by vehicle age Group
--  USE : Line/bar trend chart — does issue rate grow with age?
-- ============================================================

SELECT
    CASE
        WHEN Vehicle_Age < 1 THEN '1 - Under 1 yr'
        WHEN Vehicle_Age < 2 THEN '2 - 1 to 2 yrs'
        WHEN Vehicle_Age < 3 THEN '3 - 2 to 3 yrs'
        WHEN Vehicle_Age < 5 THEN '4 - 3 to 5 yrs'
        WHEN Vehicle_Age < 8 THEN '5 - 5 to 8 yrs'
        ELSE                      '6 - Over 8 yrs'
    END                                                AS Age_Group,
    COUNT(*)                                           AS Total_Vehicles,
    ROUND(AVG(Reported_Issues), 2)                     AS Avg_Reported_Issues,
    ROUND(SUM(Need_Maintenance) * 100.0 / COUNT(*), 1) AS Maintenance_Rate_Pct,
    ROUND(AVG(Mileage), 0)                             AS Avg_Mileage
FROM vehicle_warranty
GROUP BY Age_Group
ORDER BY Age_Group;


-- ============================================================
--  TEAM: Warranty
--  KPI : Maintenance history quality by vehicle model
--  USE : Heatmap in Tableau — Good / Average / Poor per model
-- ============================================================

SELECT
    Vehicle_Model,
    Maintenance_History,
    COUNT(*)                                           AS Total_Vehicles,
    ROUND(AVG(Reported_Issues), 2)                     AS Avg_Reported_Issues,
    ROUND(SUM(Need_Maintenance) * 100.0 / COUNT(*), 1) AS Maintenance_Rate_Pct
FROM vehicle_warranty
GROUP BY Vehicle_Model, Maintenance_History
ORDER BY Vehicle_Model, Maintenance_History;


-- ============================================================
--  TEAM: Service Marketing
--  KPI : Monthly service activity trend
--  USE : Time-series line chart in Tableau
-- ============================================================

SELECT
    DATE_FORMAT(Last_Service_Date, '%Y-%m')            AS Service_Month,
    COUNT(*)                                           AS Total_Vehicles_Serviced,
    ROUND(AVG(Reported_Issues), 2)                     AS Avg_Issues_At_Service,
    SUM(Need_Maintenance)                              AS Still_Need_Maintenance
FROM vehicle_warranty
WHERE Last_Service_Date IS NOT NULL
GROUP BY Service_Month
ORDER BY Service_Month;


-- ============================================================
--  TEAM: Service Marketing
--  KPI : Performance breakdown by fuel type
--  USE : Clustered bar chart — EV vs Petrol vs Diesel comparison
-- ============================================================

SELECT
    Fuel_Type,
    COUNT(*)                                           AS Total_Vehicles,
    ROUND(AVG(Fuel_Efficiency), 2)                     AS Avg_Fuel_Efficiency_KPL,
    ROUND(AVG(Reported_Issues), 2)                     AS Avg_Reported_Issues,
    ROUND(AVG(Mileage), 0)                             AS Avg_Mileage,
    ROUND(SUM(Need_Maintenance) * 100.0 / COUNT(*), 1) AS Maintenance_Rate_Pct
FROM vehicle_warranty
GROUP BY Fuel_Type
ORDER BY Total_Vehicles DESC;


-- ============================================================
--  TEAM: Service Marketing
--  KPI : Owner type segmentation
--  USE : Filter + bar chart — First / Second / Third owner
-- ============================================================

SELECT
    Owner_Type,
    COUNT(*)                                           AS Total_Vehicles,
    ROUND(AVG(Vehicle_Age), 2)                         AS Avg_Vehicle_Age_Yrs,
    ROUND(AVG(Mileage), 0)                             AS Avg_Mileage,
    ROUND(AVG(Reported_Issues), 2)                     AS Avg_Reported_Issues,
    SUM(Accident_History)                              AS Total_Accidents,
    ROUND(SUM(Need_Maintenance) * 100.0 / COUNT(*), 1) AS Maintenance_Rate_Pct
FROM vehicle_warranty
GROUP BY Owner_Type
ORDER BY Owner_Type;