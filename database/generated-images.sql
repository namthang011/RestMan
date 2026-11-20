-- AI-generated menu illustrations. PNG assets live under assets/images/generated.
-- Only image paths are changed; no prices, sizes, names or combo details are modified.
USE restman;
SET NAMES utf8mb4;
START TRANSACTION;
UPDATE tblDish SET img='assets/images/generated/dish-1.png' WHERE id=1 AND name='Thăn bò Wagyu áp chảo' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-2.png' WHERE id=2 AND name='Tôm hùm nướng bơ tỏi' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-3.png' WHERE id=3 AND name='Gan ngỗng áp chảo' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-4.png' WHERE id=4 AND name='Salad burrata cà chua heirloom' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-5.png' WHERE id=5 AND name='Bánh chocolate fondant' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-6.png' WHERE id=6 AND name='Mocktail lựu hương thảo' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-7.png' WHERE id=7 AND name='Ức vịt sốt cam' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-8.png' WHERE id=8 AND name='Trà hoa nhài thượng hạng' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-9.png' WHERE id=9 AND name='Sò điệp Hokkaido áp chảo' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-10.png' WHERE id=10 AND name='Súp nấm truffle' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-11.png' WHERE id=11 AND name='Crème brûlée vanilla' AND tblRestaurantid=1;
UPDATE tblDish SET img='assets/images/generated/dish-12.png' WHERE id=12 AND name='Cá tuyết nướng miso' AND tblRestaurantid=1;
UPDATE tblCombo SET img='assets/images/generated/combo-1.png' WHERE id=1 AND name='Signature Wagyu' AND tblRestaurantid=1;
UPDATE tblCombo SET img='assets/images/generated/combo-2.png' WHERE id=2 AND name='Ocean Elegance' AND tblRestaurantid=1;
UPDATE tblCombo SET img='assets/images/generated/combo-3.png' WHERE id=3 AND name='French Gourmet' AND tblRestaurantid=1;
COMMIT;
