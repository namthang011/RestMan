-- S/M/L sample pricing, for both modules. No table/column changes.
-- Apply only after backing up tblSize and tblDishSize. Re-running preserves custom percentages.
USE restman;
SET NAMES utf8mb4;
START TRANSACTION;
-- Keep the existing size ID: old combo details continue referencing the same 100% size.
UPDATE tblSize legacy LEFT JOIN tblSize medium ON medium.name='M'
 SET legacy.name='M' WHERE legacy.name='Tiêu chuẩn' AND medium.id IS NULL;
INSERT INTO tblSize (name) SELECT 'S' WHERE NOT EXISTS (SELECT 1 FROM tblSize WHERE name='S');
INSERT INTO tblSize (name) SELECT 'M' WHERE NOT EXISTS (SELECT 1 FROM tblSize WHERE name='M');
INSERT INTO tblSize (name) SELECT 'L' WHERE NOT EXISTS (SELECT 1 FROM tblSize WHERE name='L');
INSERT INTO tblDishSize (tblDishid,tblSizeid,pricePercentage)
 SELECT d.id,s.id,CASE s.name WHEN 'S' THEN 80 WHEN 'M' THEN 100 WHEN 'L' THEN 125 END
 FROM tblDish d JOIN tblSize s ON s.name IN ('S','M','L')
 WHERE d.tblRestaurantid=1 AND NOT EXISTS (
 SELECT 1 FROM tblDishSize ds WHERE ds.tblDishid=d.id AND ds.tblSizeid=s.id);
COMMIT;
