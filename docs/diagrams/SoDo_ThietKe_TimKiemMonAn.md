# Sơ đồ thiết kế module tìm kiếm món ăn — bản sửa

Đối chiếu trực tiếp mã nguồn RestMan/src/main ngày 17/11/2026. Giữ kiến trúc JSP gọi DAO hiện tại; không thêm Servlet hoặc thay đổi code.

## Những chỗ sửa so với ảnh gốc

| Ảnh gốc | Bản sửa theo code |
|---|---|
| MainCustomerUI.jsp, SearchDishUI.jsp, DishDetailUI.jsp | MainCustomerUI5.jsp, SearchDishUI5.jsp, DishDetailUI5.jsp |
| subTimKiem, outDishList1, dsMonAn, q, category | Dùng ID thật: subSearchDish, subSearch, outDishList; dữ liệu listDish; tham số name/type |
| findById / getType | getDishbyId / getTypes (giữ chính xác chữ hoa/thường trong code) |
| DishDAO kế thừa DAO có con | Không có lớp DAO cơ sở trong code hiện tại; DishDAO gọi Database.open() |
| Chỉ trang tìm gọi DishDAO | Cả trang tìm và trang chi tiết đều gọi DishDAO |
| Dish5, giá float, id integer | Dish, giá BigDecimal, id long |
| dishSize là một đối tượng | dishSizes là List<DishSize>; thêm DishSizePrice để hiển thị giá |
| Thiếu chọn size | Thêm dishSizeId, selectedSize, outPrice, currentSizeName và sizeError |

## Quan hệ và ý nghĩa

- MainCustomerUI5.jsp → SearchDishUI5.jsp: liên kết GET mở tìm kiếm.
- SearchDishUI5.jsp → DishDetailUI5.jsp: GET dishId, name, type.
- DishDetailUI5.jsp → SearchDishUI5.jsp: quay lại với search=1 và bộ lọc name/type.
- Search gọi getTypes() và searchDishes(name,type). Đầu vào chưa có tham số tìm kiếm thì chưa tải listDish.
- Detail gọi getDishbyId(dishId). ID không hợp lệ/không tồn tại trả trạng thái 404; size sai trả 400.
- DishDAO gọi Database.open() bằng dependency, không kế thừa Database.
- DAO tạo DishSize trong readDish(), rồi tạo Dish bằng constructor, trả kết quả về JSP.
- Dish giữ danh sách DishSize (0..*). getSizePrices() tính và tạo DishSizePrice; không phải bảng dữ liệu riêng.
- priceFor() = basePrice × pricePercentage / 100; BigDecimal, làm tròn HALF_UP đến 2 số.
- Đổi size ở trình duyệt: dish-detail.js đọc data-price/data-size đã được JSP render và cập nhật URL bằng replaceState; bình thường không truy vấn DB lại.

## Phạm vi và quy ước

Sơ đồ là thiết kế cho nhánh món ăn tương ứng ảnh người dùng, không vẽ toàn bộ nhánh combo. Thực tế SearchDishUI5.jsp còn gọi ComboDAO.searchCombos() và render outComboSearchList, liên kết ComboDetailUI5.jsp.

Các dòng trong hộp JSP trộn element (Input/Select/Table/Link), tham số request và đối tượng render theo quy ước sơ đồ giao diện. Không hiểu chúng là toàn bộ field thật của servlet JSP. Một số element không có id như nút Xem chi tiết được mô tả trong luồng, không đặt ID giả. Các getter/constructor thông thường của Model và phương thức Database nội bộ được lược để sơ đồ gọn.

Không phải sơ đồ MVC tách Controller riêng. Đây là cấu trúc JSP + DAO đúng với code hiện tại.

## Tệp

- PNG: chèn vào Word/slide.
- SVG: ảnh vector để phóng to.
- DRAWIO: mở tại diagrams.net để sửa từng hộp, thuộc tính và mũi tên.
