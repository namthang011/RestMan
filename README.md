# RestMan — JSP + MySQL theo kịch bản

Đối chiếu kịch bản trong “22B23DCCN755 da sua UC va scenario.docx”:

- Khách hàng: `MainCustomerUI5.jsp → SearchDishUI5.jsp → DishDetailUI5.jsp`.
- Nhân viên: `MainStaffUI5.jsp → ComboListUI5.jsp → AddComboUI5.jsp → doSaveCombo5.jsp`.
- JSP gọi DAO đúng tên phương thức trong kịch bản. Không có lớp Servlet tự viết; truy cập trực tiếp các trang JSP.
- Tất cả thực thể ở `vn.restman.model`; DAO ở `vn.restman.dao`.

## Cập nhật giao diện và tìm kiếm combo

Form tạo combo có ô chọn ảnh PNG/JPEG tối đa 5 MB và xem trước trước khi gửi. Ảnh được nhận qua multipart trong JSP, kiểm tra nội dung ảnh và lưu tên UUID ở `.runtime/uploads/combo`, ngoài WAR. ComboDraft giữ đường dẫn qua các lần tìm/thêm/bỏ món; xác nhận lưu mới ghi vào `tblCombo.img`. ComboImage5.jsp phục vụ file ảnh, đường dẫn được dùng ở tìm kiếm và chi tiết combo; ảnh không mất khi triển khai lại WAR. Không cần thêm bảng/cột hay lớp Servlet tự viết. `web.xml` chỉ khai báo multipart cho hai trang JSP.

Kiểm thử upload: đặt RESTMAN_SMOKE_BASE tới Tomcat dùng DB thử và chạy `python scripts/smoke-combo-image.py` (tạo một combo thử). Khi chuyển máy, sao chép cả `.runtime/uploads/combo` cùng DB; bản sao lưu DB chỉ chứa đường dẫn ảnh.

Theo yêu cầu bổ sung: giao diện chỉ giữ chức năng tìm món/combo và quản lý combo, không có mục Xem thực đơn. Khu vực kết quả được mở rộng tối đa 1440px; bộ lọc, danh sách món lẻ, danh sách combo và form tạo combo được phân chia thành các phần riêng.

Chữ căn trái, số và ô nhập số căn phải. Đơn vị tiền đặt tại tiêu đề cột (VNĐ), không lặp trong từng ô. ComboListUI5.jsp mở ComboDetailUI5.jsp để xem danh sách món, kích cỡ, số lượng, đơn giá và thành tiền tham khảo. Giá combo vẫn là giá bán riêng.

SearchDishUI5.jsp trả cả món lẻ và combo. ComboDAO.searchCombos(name,type) khớp tên combo hoặc tên món thành phần; bộ lọc thể loại áp dụng lên món thành phần tương ứng. ComboDetailUI5.jsp dùng comboId, giữ name/type khi quay lại tìm kiếm; from=staff chỉ chọn đường quay về danh sách nhân viên. Đây là phần mở rộng theo yêu cầu mới, không đổi cấu trúc 6 bảng.

## Luồng và element

| Trang | Element / sự kiện | Dữ liệu và xử lý |
| --- | --- | --- |
| MainCustomerUI5 | subSearchDish | Mở SearchDishUI5 |
| SearchDishUI5 | inName, inType, subSearch, outDishList, outComboSearchList | DishDAO.searchDishes(name, type) và ComboDAO.searchCombos(name,type); truyền dishId hoặc comboId |
| DishDetailUI5 | outName, outType, outPrice, outDescription, subBack | DishDAO.getDishbyId(dishId); quay lại giữ bộ lọc |
| MainStaffUI | subManageCombo | Mở ComboListUI |
| ComboListUI | outComboList, subAddCombo | ComboDAO.getAllCombo(); mở AddComboUI |
| ComboDetailUI | comboTitle, outComboDetails, subBack | ComboDAO.getComboById(comboId); hiển thị món, kích cỡ, số lượng và giá tham khảo; quay lại đúng nơi mở |
| AddComboUI | inDishName, inDishType, subSearch, outDishList | Tìm và thêm món vào bản nháp |
| AddComboUI | dishSize_<dishId>, outComboItems, cập nhật số lượng, bỏ món | Chọn size từ DB; mỗi dòng nhận diện bằng dishSizeId; chưa lưu ComboDAO |
| AddComboUI | inComboName, inPrice, inDescription, subSaveCombo | POST sang doSaveCombo5.jsp |
| doSaveCombo | xử lý POST, không có màn hình nhập riêng | Draft.toCombo() đóng gói trước; ComboDAO.saveCombo(combo); thành công chuyển về danh sách |

Tên ID element là quy ước triển khai trong code. Bảng này mô tả code đã làm; cần kiểm tra riêng nhãn/thuộc tính chi tiết nằm trong hình sơ đồ của tài liệu nếu yêu cầu khớp từng ký tự.

## Thuộc tính ẩn

“Thuộc tính ẩn” gồm cả biến/đối tượng của trang trên server, không chỉ input type=hidden.

| Dữ liệu | Nơi giữ | Mục đích |
| --- | --- | --- |
| listDish: List<Dish> | request | Kết quả tìm kiếm |
| dishId | hidden input của dòng tìm kiếm; value của nút thêm/bỏ | Định danh món được chọn, không dùng STT |
| dish: Dish | request trang chi tiết | Đối tượng DAO trả về |
| listCombo: List<Combo> | request | Danh sách combo từ getAllCombo() |
| comboDraft: ComboDraft | session | Tên, giá bán, mô tả và List<ComboItem> qua nhiều lần tìm |
| draftId | hidden input | Phát hiện gửi lại bản nháp đã lưu/hủy/hết hạn |
| csrf | session + hidden input | Kiểm tra POST |
| comboSearchName, comboSearchType, comboSearched | session | Giữ bộ lọc và trạng thái đã tìm ở form combo |
| name, type | hidden input khi mở chi tiết | Quay lại đúng bộ lọc khách hàng |
| success | session, lấy ra một lần | Thông báo lưu thành công |

Không truyền toàn bộ entity qua HTML. Giá món lấy từ DishDAO; giá bán combo là ô nhập riêng. Search/add/remove/update giữ thông tin combo phía server, hoạt động khi tắt JavaScript. Nhấn Enter trong trường tìm thực hiện nút Tìm kiếm mặc định.

## Model và quy tắc

- Dish: id, name, type, price, description, image; dùng chung cả hai module.
- ComboItem: dish, dishSize, quantity; mỗi cặp món + size là một dòng; chọn lại đúng cặp sẽ tăng số lượng. Số lượng 1-999 là quy tắc demo.
- Combo: id, name, price, description, items. price là giá bán nhập tay; referenceTotal chỉ tham khảo.
- ComboDraft: trạng thái đang soạn, chỉ chuyển thành Combo hoàn chỉnh trước khi lưu.
- Mỗi session dùng chung một bản nháp giữa các tab. Mở lại form tiếp tục bản nháp; Hủy bản nháp xóa trạng thái.
- Tìm tên không dấu, thể loại; cả hai có giá trị thì kết hợp AND. Chưa nhấn tìm thì chưa lấy danh sách kết quả.
- Tên combo 1–100 ký tự, mô tả tối đa 255; giá DECIMAL(18,2), nhập tối đa 15 chữ số nguyên và 2 chữ số thập phân; ít nhất một món; không trùng tên.
- Chỉ nút Xác nhận lưu combo ghi dữ liệu; không bắt thêm checkbox ngoài kịch bản. Refresh sau lưu không tạo bản ghi mới.
- Theo sơ đồ trong tài liệu gốc đã chép vào database: combo có startDate/endDate. Có thể để trống cả hai; nếu nhập thì phải đủ hai ngày và ngày bắt đầu không sau ngày kết thúc.

## Cập nhật DB theo tài liệu gốc

Bổ sung kích cỡ: `database/dish-sizes.sql` tạo dữ liệu mẫu S = 80%, M = 100%, L = 125% giá gốc cho từng món. `scripts/update-dish-sizes.ps1` sao lưu tblSize/tblDishSize rồi áp dụng bằng tài khoản ứng dụng, không cần mật khẩu root. Size Tiêu chuẩn được đổi tên M nhưng giữ ID để các combo cũ không đổi tham chiếu. Chạy lại script không ghi đè tỷ lệ đã chỉnh riêng.

DishDetailUI5.jsp bố trí ảnh và thông tin cạnh nhau, chọn size cập nhật giá ngay bằng JavaScript, không có nút xem giá; URL vẫn giữ size đã chọn và bộ lọc; không hiển thị bảng giá theo kích cỡ. Bộ lọc được giữ khi quay lại. Kết quả tìm món hiển thị khoảng giá từ size rẻ nhất đến đắt nhất. AddComboUI5.jsp có dropdown ghi rõ size và giá, giữ lần chọn gần nhất, cho phép thêm hai size của cùng một món; thêm/bỏ/cập nhật số lượng dùng dishSizeId. Giá tính bằng BigDecimal: basePrice × pricePercentage / 100, làm tròn 2 chữ số thập phân theo HALF_UP. ComboDAO lưu đúng tblDishSizeid trong tblComboDetail và kiểm tra size thuộc món tương ứng. Bộ dữ liệu vẫn chỉ có 6 bảng.

Kiểm thử size: `RESTMAN_SMOKE_BASE` trỏ tới Tomcat/DB thử rồi chạy `python scripts/smoke-sizes.py` (tạo một combo thử). Không chạy kiểm thử ghi dữ liệu vào DB đang dùng.

Tài liệu chuẩn: `database/22B23DCCN755 da sua UC va scenario.docx`, hình cơ sở dữ liệu (image3 trong DOCX). Phạm vi triển khai chỉ giữ 6 bảng `tbl...` liên quan tới hai module; DAO đã chuyển sang `tblDish`, `tblCombo`, `tblComboDetail`, `tblDishSize`, `tblSize`, `tblRestaurant`. Java dùng BigDecimal cho giá, LocalDate cho thời hạn. Các getter price/image được giữ để JSP hiện tại hoạt động.

Với DB cũ đã có dữ liệu: dừng Tomcat, chạy `scripts/upgrade-db.ps1` và nhập mật khẩu quản trị trong terminal. Script sao lưu toàn bộ DB vào `.runtime/backups`, tạo cấu trúc mới, chuyển/kiểm tra dữ liệu, xóa các bảng ngoài phạm vi sau khi kiểm tra dữ liệu và copy WAR đã build vào runtime. Khởi động lại bằng `scripts/run.ps1` sau khi nâng cấp thành công. Xem `database/README.md` về các điểm đặc biệt trong sơ đồ và khôi phục.

## Chạy

JDK 17, Maven, Tomcat 10.1 và MySQL 8.0.16+. Khởi tạo trước khi chạy web:

```powershell
.\scripts\init-db.ps1
```

Nhập mật khẩu root khi script hỏi trực tiếp trong terminal. Script tạo database restman, 12 món ăn, 3 combo mẫu, tài khoản ứng dụng riêng và file .runtime/db.properties. Không đưa file mật khẩu này vào mã nguồn. Xem [database/README.md](database/README.md).

Build và chạy:

```powershell
$env:JAVA_HOME='C:\Program Files\Java\jdk-17'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
mvn clean verify
.\scripts\run.ps1 -TomcatHome 'C:\Tools\apache-tomcat-10.1.61-windows-x64\apache-tomcat-10.1.61'
```

Nếu runtime chưa tồn tại, chạy scripts/deploy.ps1 trước theo cùng TomcatHome.
Khi cập nhật: dừng Tomcat, copy target/restman.war vào .runtime/tomcat/webapps/restman.war, rồi chạy lại.

Mở http://localhost:8081/restman/ hoặc hai trang MainCustomerUI5.jsp/MainStaffUI5.jsp.
Unit test: mvn -o clean verify. Integration test: dùng schema restman_test theo design-schema.sql và restman.sql, đặt RESTMAN_TEST_DB_CONFIG tới file cấu hình test; không dùng DB thật. Kiểm tra HTTP: python scripts/smoke.py (tạo combo demo); RESTMAN_SMOKE_BASE cho phép chọn địa chỉ Tomcat kiểm thử.

## Giới hạn cần biết khi trình bày

DAO dùng JDBC/MySQL; dữ liệu combo lưu bền vững. saveCombo dùng transaction: lưu cả combo và các món rồi commit; nếu một bước lỗi thì rollback. Cấu hình kết nối nằm ngoài WAR, do scripts/run.ps1 nạp qua RESTMAN_DB_CONFIG. Không thêm đăng nhập/phân quyền ngoài hai module. Giao diện đơn giản: nền sáng, menu gọn, form và bảng rõ ràng; nút chính xanh đậm, nút thêm/xem xanh nhạt và nút bỏ/hủy viền đỏ; ảnh món chỉ hiển thị nhỏ ở trang chi tiết. Các tài liệu cũ trong RestMan-analysis/RestMan-report chưa được cập nhật theo lần sửa code này.

JSP xử lý sự kiện và gọi DAO; ComboFlow chỉ là lớp tiện ích Java, không phải Servlet. UTF-8 cấu hình trong WEB-INF/web.xml. Dependency jakarta.servlet-api vẫn cần để biên dịch các tiện ích dùng request/session của JSP.
#   R e s t M a n  
 