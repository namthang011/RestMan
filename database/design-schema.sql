-- Two modules: dish search and combo creation. Names/types follow the source document.
CREATE DATABASE IF NOT EXISTS restman CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE restman;
SET NAMES utf8mb4;
CREATE TABLE IF NOT EXISTS tblRestaurant (
 id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(10) NOT NULL, address VARCHAR(255) NOT NULL,
 phone VARCHAR(255) NOT NULL, email VARCHAR(100) NOT NULL, description VARCHAR(255) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS tblSize (
 id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS tblDish (
 id INT AUTO_INCREMENT PRIMARY KEY, tblRestaurantid INT NOT NULL, name VARCHAR(100) NOT NULL,
 type VARCHAR(50) NOT NULL, basePrice DECIMAL(18,2) NOT NULL, description VARCHAR(255), img VARCHAR(255),
 FOREIGN KEY (tblRestaurantid) REFERENCES tblRestaurant(id),
 CONSTRAINT chk_design_dish_price CHECK (basePrice > 0)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS tblDishSize (
 id INT AUTO_INCREMENT PRIMARY KEY, pricePercentage DECIMAL(7,2), tblDishid INT NOT NULL,
 tblSizeid INT NOT NULL, UNIQUE KEY uq_dish_size (tblDishid,tblSizeid),
 FOREIGN KEY (tblDishid) REFERENCES tblDish(id), FOREIGN KEY (tblSizeid) REFERENCES tblSize(id),
 CONSTRAINT chk_design_size_percentage CHECK (pricePercentage > 0)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS tblCombo (
 id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), price DECIMAL(18,2), description VARCHAR(255),
 img VARCHAR(255), startDate DATE, endDate DATE, tblRestaurantid INT NOT NULL,
 FOREIGN KEY (tblRestaurantid) REFERENCES tblRestaurant(id),
 CONSTRAINT chk_design_combo_price CHECK (price > 0),
 CONSTRAINT chk_design_combo_dates CHECK ((startDate IS NULL AND endDate IS NULL) OR
 (startDate IS NOT NULL AND endDate IS NOT NULL AND startDate <= endDate))
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS tblComboDetail (
 id INT AUTO_INCREMENT PRIMARY KEY, tblDishid INT NOT NULL, tblDishSizeid INT NOT NULL,
 tblComboid INT NOT NULL, quantity INT NOT NULL,
 FOREIGN KEY (tblDishid) REFERENCES tblDish(id), FOREIGN KEY (tblDishSizeid) REFERENCES tblDishSize(id),
 FOREIGN KEY (tblComboid) REFERENCES tblCombo(id) ON DELETE CASCADE,
 UNIQUE KEY uq_combo_dish_size (tblComboid,tblDishid,tblDishSizeid),
 CONSTRAINT chk_design_combo_quantity CHECK (quantity BETWEEN 1 AND 999)
) ENGINE=InnoDB;
