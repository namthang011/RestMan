# Database RestMan theo tài liệu thiết kế

Nguồn chuẩn là file Word `22B23DCCN755 da sua UC va scenario.docx` trong thư mục này, hình sơ đồ CSDL ở trang 2 và sơ đồ lớp hai module. Chỉ triển khai phần dữ liệu phục vụ tìm món ăn và thêm combo, không tạo bảng cho nghiệp vụ khác. Không dùng bản đề xuất cũ trong RestMan-analysis để quyết định cấu trúc.

## Các file SQL

| File | Vai trò |
| --- | --- |
| design-schema.sql | Tạo 6 bảng cho hai module, theo khóa chính, khóa ngoại và kiểu dữ liệu trong sơ đồ |
| restman.sql | 12 món, 3 combo mẫu và kích cỡ tiêu chuẩn cho cài đặt mới |
| migrate-to-design.sql | Chuyển dữ liệu từ dish/combo/combo_item |
| keep-two-modules.sql | Xóa bảng ngoài phạm vi và bảng cũ, chỉ sau khi sao lưu và kiểm tra chuyển dữ liệu |
| dish-sizes.sql | Bổ sung S/M/L cho mỗi món, lần lượt 80%/100%/125% giá gốc; giữ ID của size cũ |

Chỉ giữ 6 bảng:

| Bảng | Lý do giữ |
| --- | --- |
| tblRestaurant | Khóa ngoại nhà hàng của món ăn và combo |
| tblDish | Dữ liệu tìm kiếm và chi tiết món |
| tblSize | Danh mục kích cỡ |
| tblDishSize | Kích cỡ của từng món; được chi tiết combo tham chiếu |
| tblCombo | Thông tin combo, ảnh và thời hạn |
| tblComboDetail | Món, kích cỡ và số lượng trong combo |


## Nâng cấp DB đang dùng

Dừng RestMan/Tomcat trước. Tại thư mục RestMan:

```powershell
$env:JAVA_HOME='C:\Program Files\Java\jdk-17'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
mvn -o clean verify
.\scripts\upgrade-db.ps1
```

Nhập mật khẩu MySQL root trực tiếp tại lời nhắc trong terminal. Script không ghi lại mật khẩu root, không đổi tài khoản ứng dụng. Mặc định MySQL cổng 3306; có thể truyền -Port và -AdminUser.

Script sao lưu toàn bộ DB bằng mysqldump vào `.runtime/backups`, tạo bảng mới, chuyển dữ liệu trong transaction và kiểm tra tên/giá/mô tả/ảnh/số lượng; sau đó mới xóa bảng ngoài phạm vi và các bảng cũ. Nếu mô tả cũ dài hơn 255 hoặc ID vượt INT, SQL strict mode báo lỗi, không cắt dữ liệu. Sau thành công script copy WAR mới sang `.runtime/tomcat/webapps` và ghi `.runtime/design-db-port3306-upgraded.txt`.

Sau nâng cấp, DB chỉ còn đúng 6 bảng. Ba bảng dish/combo/combo_item được xóa sau khi dữ liệu đã chuyển và xác minh; bản sao lưu đầy đủ được giữ trong `.runtime/backups`. Không chạy riêng file cleanup trước khi hoàn tất các bước này.

Script hỗ trợ DB cũ ba bảng, DB đã có 19 bảng và trường hợp chạy lại sau khi đã thu gọn. Nếu chỉ còn một phần các bảng cũ, script dừng để tránh suy đoán dữ liệu. Tài khoản ứng dụng vẫn có quyền DML trên restman.*; không cần cấp quyền quản trị cho web.


## Cài mới

Chạy `.\scripts\init-db.ps1` khi chưa có `.runtime/db.properties`. Script đọc design-schema.sql rồi restman.sql, tạo tài khoản ứng dụng riêng. Thêm -IncludeTests để tạo restman_test. Nếu đã có cấu hình, dùng upgrade-db.ps1 thay vì khởi tạo lại dữ liệu mẫu.

Chạy SQL thủ công: thực hiện design-schema.sql trước; chỉ dùng restman.sql cho cài mới. Với DB cũ, dùng upgrade-db.ps1 để thực hiện đúng thứ tự sao lưu, migration, xác minh rồi cleanup thay cho seed.

## Ánh xạ hai module

| Trước | Theo tài liệu |
| --- | --- |
| dish.price / dish.dish_type / dish.image | tblDish.basePrice / type / img |
| combo | tblCombo, có img/startDate/endDate/tblRestaurantid |
| combo_item khóa ghép | tblComboDetail có id riêng, quantity và ba khóa ngoại |
| Không có kích cỡ | tblSize và tblDishSize với pricePercentage |
| Không có nhà hàng | tblRestaurant, dữ liệu hiện có được gán nhà hàng RestMan id=1 |

Khi chuyển dữ liệu, mỗi món có kích cỡ M 100%; sau đó bổ sung S 80% và L 125% bằng dish-sizes.sql. Size Tiêu chuẩn cũ được đổi tên M nhưng giữ ID. Dữ liệu cũ không có thời hạn/ảnh combo nên để NULL, không tự đặt ngày. Form bổ sung ngày bắt đầu/kết thúc tùy chọn và giữ chúng qua các lần tìm món. DAO lưu giá bằng BigDecimal/setBigDecimal, không dùng float/double. Khi thêm món vào combo phải chọn tblDishSize cụ thể; cùng một món khác size là hai dòng độc lập. Trang chi tiết món cho chọn size để xem giá, không hiển thị bảng giá riêng. Chưa xây dựng màn hình quản trị kích cỡ hay các nghiệp vụ ngoài hai module.

## Những điểm cần giải thích khi đối chiếu sơ đồ

- INTEGER(10) trong hình được cài là INT; (10) là độ rộng hiển thị, không phải 10 chữ số được lưu.
- pricePercentage=100 được hiểu là 100% giá gốc cho kích cỡ tiêu chuẩn.
- Bổ sung CHECK giá dương, số lượng hợp lệ, cặp ngày hợp lệ và UNIQUE thành phần combo để bảo vệ dữ liệu; không bổ sung cột tìm kiếm ngoài sơ đồ. Chuẩn hóa tên tiếng Việt được xử lý trong Java.

## Kiểm tra

```sql
USE restman;
SHOW TABLES;
SELECT id,name,type,basePrice,img FROM tblDish;
SELECT id,name,price,startDate,endDate FROM tblCombo;
SELECT cd.id,c.name AS combo,d.name AS dish,s.name AS size,cd.quantity
FROM tblComboDetail cd JOIN tblCombo c ON c.id=cd.tblComboid
JOIN tblDish d ON d.id=cd.tblDishid JOIN tblDishSize ds ON ds.id=cd.tblDishSizeid
JOIN tblSize s ON s.id=ds.tblSizeid ORDER BY c.id,cd.id;
```

Kiểm thử Java tích hợp chỉ chạy khi RESTMAN_TEST_DB_CONFIG trỏ tới schema restman_test. Kiểm thử HTTP dùng scripts/smoke.py và tạo một combo; chạy trên DB thử trước. Không trỏ các kiểm thử ghi dữ liệu vào DB đang dùng.

## Khôi phục

Dừng Tomcat, dùng MySQL client/Workbench đăng nhập bằng tài khoản quản trị và thực thi file sao lưu đã tạo trước nâng cấp. Bản dump chứa thông tin tạo lại bảng và dữ liệu cũ; thao tác phục hồi có thể ghi đè dữ liệu. Khôi phục WAR phiên bản cũ nếu muốn quay về DAO dùng ba bảng cũ. Không chia sẻ bản sao lưu nếu chứa dữ liệu thật.
