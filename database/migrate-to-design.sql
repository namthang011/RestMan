-- Run AFTER design-schema.sql, inside the same restman database.
-- This migration leaves the legacy tables untouched until verification.
-- upgrade-db.ps1 then runs keep-two-modules.sql after a full backup.
-- Fail rather than truncate values from legacy descriptions/IDs.
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
START TRANSACTION;
INSERT INTO tblRestaurant (id,name,address,phone,email,description)
 SELECT 1,'RestMan','','','','' WHERE NOT EXISTS (SELECT 1 FROM tblRestaurant WHERE id=1);
INSERT INTO tblSize (name) SELECT 'M' WHERE NOT EXISTS (SELECT 1 FROM tblSize WHERE name='M');
INSERT INTO tblDish (id,tblRestaurantid,name,type,basePrice,description,img)
 SELECT d.id,1,d.name,d.dish_type,d.price,d.description,d.image FROM dish d
 WHERE NOT EXISTS (SELECT 1 FROM tblDish n WHERE n.id=d.id);
INSERT INTO tblDishSize (tblDishid,tblSizeid,pricePercentage)
 SELECT d.id,s.id,100 FROM tblDish d JOIN tblSize s ON s.name='M'
 WHERE NOT EXISTS (SELECT 1 FROM tblDishSize ds WHERE ds.tblDishid=d.id AND ds.tblSizeid=s.id);
INSERT INTO tblCombo (id,name,price,description,img,startDate,endDate,tblRestaurantid)
 SELECT c.id,c.name,c.price,c.description,NULL,NULL,NULL,1 FROM combo c
 WHERE NOT EXISTS (SELECT 1 FROM tblCombo n WHERE n.id=c.id);
INSERT INTO tblComboDetail (tblDishid,tblDishSizeid,tblComboid,quantity)
 SELECT ci.dish_id,ds.id,ci.combo_id,ci.quantity FROM combo_item ci
 JOIN tblDishSize ds ON ds.tblDishid=ci.dish_id JOIN tblSize s ON s.id=ds.tblSizeid AND s.name='M'
 WHERE NOT EXISTS (SELECT 1 FROM tblComboDetail cd WHERE cd.tblComboid=ci.combo_id
 AND cd.tblDishid=ci.dish_id AND cd.tblDishSizeid=ds.id)
 ORDER BY ci.combo_id,ci.sort_order;
COMMIT;
