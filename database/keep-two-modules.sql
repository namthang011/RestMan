-- Run only after a full backup and successful legacy-data migration/verification.
-- Drop child tables first, keeping foreign key checks enabled.
USE restman;
DROP TABLE IF EXISTS tblBill;
DROP TABLE IF EXISTS tblDishOrder;
DROP TABLE IF EXISTS tblComboOrder;
DROP TABLE IF EXISTS tblOrderTable;
DROP TABLE IF EXISTS tblOrder;
DROP TABLE IF EXISTS tblReservationDetail;
DROP TABLE IF EXISTS tblReservation;
DROP TABLE IF EXISTS tblTable;
DROP TABLE IF EXISTS tblImportItem;
DROP TABLE IF EXISTS tblImportBill;
DROP TABLE IF EXISTS tblSupplier;
DROP TABLE IF EXISTS tblIngredient;
DROP TABLE IF EXISTS tblUser;
-- The old data has been copied into tblDish/tblCombo/tblComboDetail and verified.
DROP TABLE IF EXISTS combo_item;
DROP TABLE IF EXISTS combo;
DROP TABLE IF EXISTS dish;
