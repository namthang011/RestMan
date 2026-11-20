# RestMan — Toàn bộ hàm xử lý, element và luồng dữ liệu

Ngày đối chiếu mã nguồn: 16/11/2026. Phạm vi: RestMan/src/main; 10 JSP ở thư mục chính, 1 JSP báo lỗi, 2 JSP fragment, các lớp Java và 2 file JavaScript. Không thay đổi chức năng ứng dụng trong lần xuất này.

## 1. Cách đọc

- Tài liệu mô tả code hiện tại, chưa phải MVC tách Controller riêng. JSP đang nhận request, gọi DAO và dựng giao diện.
- request.getParameter() đọc tham số URL/form; DAO chạy SQL; Model chứa kết quả; request.setAttribute() đưa dữ liệu vào phạm vi request; JSTL/EL dựng HTML.
- DAO hiện tạo các Model như Dish/Combo bằng constructor; không phải gán bằng setter như ví dụ minh họa tổng quát trước đó. Combo và Dish có nhiều thuộc tính final, không có setter; ComboDraft có thể cập nhật.
- Java trong JSP là khối scriptlet, không phải các hàm doGet/doPost do dự án tự khai báo.
- Bảng element ghi từng thẻ mở HTML theo dòng nguồn, gồm cả thẻ bố cục, form, input, nút và vùng hiển thị. Vòng lặp sinh nhiều element khi chạy; các nhánh điều kiện không xuất hiện cùng lúc.
- id dùng định danh element; name dùng làm tên tham số gửi lên server. Thẻ JSTL chạy trên server, không trở thành element DOM.
- Header/footer dùng chung được thống kê riêng; các trang include chúng nhận thêm element tương ứng.
- Đây là đối chiếu tĩnh từ nguồn; chưa chạy kiểm thử giao diện/database trong lần xuất tài liệu.

## 2. Tổng quan trang

| File | Chức năng |
|---|---|
| index5.jsp | Trang chủ |
| MainCustomerUI5.jsp | Trang chính khách hàng |
| MainStaffUI5.jsp | Trang chính nhân viên |
| SearchDishUI5.jsp | Tìm món và combo |
| DishDetailUI5.jsp | Chi tiết món |
| ComboListUI5.jsp | Danh sách combo |
| ComboDetailUI5.jsp | Chi tiết combo |
| AddComboUI5.jsp | Thêm combo/chỉnh bản nháp |
| doSaveCombo5.jsp | Endpoint lưu/hủy |
| ComboImage5.jsp | Endpoint phục vụ ảnh |
| WEB-INF/views/shared/database-error5.jsp | Trang lỗi database |

## 3. Luồng dữ liệu chung

### Đọc dữ liệu

1. Trình duyệt gửi GET với bộ lọc hoặc ID.
2. JSP nhận request và đọc tham số.
3. JSP gọi DAO; DAO mở JDBC, chạy SELECT và đọc ResultSet.
4. DAO gọi constructor Model; trả Optional hoặc List về JSP.
5. JSP đặt dữ liệu vào request; JSTL/EL tạo HTML.
6. Trình duyệt nhận HTML và tải CSS/JS/ảnh.

### Tạo combo

1. AddComboUI5.jsp mở ComboDraft trong session.
2. POST tìm/thêm/xóa/cập nhật sửa bản nháp, chưa INSERT combo.
3. Ảnh có thể được ghi ra đĩa trong readInformation() ở một POST trước khi lưu combo cuối cùng.
4. Nút lưu POST đến doSaveCombo5.jsp; kiểm tra token,bản nháp,dữ liệu.
5. toCombo() tạo Model; saveCombo() ghi combo và chi tiết trong cùng transaction.
6. Thành công commit, xóa nháp và redirect; lỗi transaction rollback, đưa thông báo về form.

| Phạm vi | Dữ liệu | Thời gian tồn tại |
|---|---|---|
| Request parameter | dishId,comboId,name,action; file dùng getPart() | Một yêu cầu từ URL/form |
| Request attribute | dish,combo,listDish,error,renderOnly | Qua forward; không tự giữ qua redirect |
| Session | csrf,comboDraft,comboSearchName,comboSearchType,comboSearched,success | Qua nhiều request cùng session; timeout không hoạt động 30 phút |
| JSTL | area,back,comboImage,referenceTotal | Biến khi render, không mặc định là request attribute |
| Database | tblDish,tblDishSize,tblSize,tblCombo,tblComboDetail,tblRestaurant | Lưu dữ liệu nghiệp vụ |
| Đĩa server | uploads/combo/<UUID>.png hoặc .jpg | Bytes ảnh upload |

## 4.1. index5.jsp — Trang chủ

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | Không có tham số nghiệp vụ; không gọi DAO. |
| Element nghiệp vụ | Tiêu đề, danh sách liên kết Khách hàng và Nhân viên. |

### Luồng xử lý

GET / → welcome-file index5.jsp → include header/footer → người dùng chọn MainCustomerUI5.jsp hoặc MainStaffUI5.jsp.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 4 | main | main | — | — | class=container page-shell |
| 5 | h1 | — | — | Hệ thống quản lý nhà hàng | — |
| 8 | p | — | — | Chọn chức năng: | — |
| 11 | ul | — | — | — | class=home-links |
| 12 | li | — | — | — | class=mb-2 |
| 13 | a | — | — | Khách hàng - Tìm kiếm món ăn | href=${pageContext.request.contextPath}/MainCustomerUI5.jsp |
| 17 | li | — | — | — | — |
| 18 | a | — | — | Nhân viên - Quản lý combo | href=${pageContext.request.contextPath}/MainStaffUI5.jsp |

### Toàn bộ mã Java xử lý trong JSP

Không có scriptlet nghiệp vụ; xử lý hiển thị bằng HTML/include/JSTL.

## 4.2. MainCustomerUI5.jsp — Trang chính khách hàng

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | Không gọi DAO. c:set đặt area=customer. |
| Element nghiệp vụ | Liên kết #subSearchDish. |

### Luồng xử lý

GET trang → đánh dấu menu customer → nhấn liên kết → GET SearchDishUI5.jsp.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 5 | main | main | — | — | class=container page-shell |
| 6 | h1 | — | — | Trang chính khách hàng | — |
| 9 | p | — | — | Tra cứu món ăn, combo và danh sách món thành phần. | — |
| 12 | a | subSearchDish | — | Tìm kiếm món ăn và combo | class=btn btn-primary; href=SearchDishUI5.jsp |

Thẻ server: `c:set` (1 vị trí).

### Toàn bộ mã Java xử lý trong JSP

Không có scriptlet nghiệp vụ; xử lý hiển thị bằng HTML/include/JSTL.

## 4.3. MainStaffUI5.jsp — Trang chính nhân viên

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | Không gọi DAO. c:set đặt area=staff. |
| Element nghiệp vụ | Liên kết #subManageCombo. |

### Luồng xử lý

GET trang → đánh dấu menu staff → nhấn Quản lý combo → GET ComboListUI5.jsp.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 5 | main | main | — | — | class=container page-shell |
| 6 | h1 | — | — | Trang chính nhân viên quản lý | — |
| 9 | a | subManageCombo | — | Quản lý combo | class=btn btn-primary; href=ComboListUI5.jsp |

Thẻ server: `c:set` (1 vị trí).

### Toàn bộ mã Java xử lý trong JSP

Không có scriptlet nghiệp vụ; xử lý hiển thị bằng HTML/include/JSTL.

## 4.4. SearchDishUI5.jsp — Tìm món và combo

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | GET name,type,search. Có bất kỳ tham số nào trong ba tham số thì searched=true. Luôn gọi DishDAO.getTypes(); có tìm kiếm mới gọi searchDishes(name,type), ComboDAO.searchCombos(name,type). Request: types,searched,listDish,listCombo. |
| Element nghiệp vụ | Form #searchDishForm; input #inName/name=name; select #inType/name=type; nút #subSearch/name=search/value=1; bảng #outDishList, #outComboSearchList; các form chi tiết có hidden dishId hoặc comboId cùng name,type. |

### Luồng xử lý

Mở lần đầu → tải thể loại, chưa truy vấn danh sách kết quả. Submit GET cùng trang → chuẩn hóa tên/loại bằng Text.key → DAO đọc database và lọc trong Java → trả List<Model> → JSTL hiển thị số dòng và hai bảng hoặc thông báo rỗng. Xem món chuyển DishDetailUI5.jsp?dishId=...; xem combo chuyển ComboDetailUI5.jsp?comboId=...; giữ name,type. Ảnh combo dùng img hoặc ảnh món đầu tiên.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 14 | main | main | — | — | class=container page-shell page-wide search-page |
| 15 | a | — | — | Về trang chính khách hàng | href=MainCustomerUI5.jsp; class=back-link |
| 18 | h1 | — | — | Tìm kiếm món ăn và combo | — |
| 21 | form | searchDishForm | — | — | method=get; action=SearchDishUI5.jsp; class=search-toolbar; aria-label=Tìm kiếm món ăn và combo |
| 22 | div | — | — | — | class=search-name |
| 23 | label | — | — | Tên món ăn hoặc combo | class=visually-hidden; for=inName |
| 26 | input | inName | name | — | class=form-control; placeholder=Tên món ăn hoặc combo; maxlength=100; value=<c:out value='${param.name}'/> |
| 28 | div | — | — | — | — |
| 29 | label | — | — | Thể loại món ăn | for=inType; class=visually-hidden |
| 32 | select | inType | type | — | class=form-select |
| 33 | option | — | — | Tất cả thể loại | value= |
| 37 | option | — | — | — | value=<c:out value='${type}'/> |
| 43 | button | subSearch | search | Tìm kiếm | value=1; class=btn btn-primary |
| 49 | div | — | — | — | class=results-heading |
| 50 | h2 | — | — | Kết quả tìm kiếm | — |
| 53 | p | — | — | — | role=status |
| 54 | strong | — | — | ${listDish.size()} | — |
| 58 | strong | — | — | ${listCombo.size()} | — |
| 64 | section | — | — | — | class=result-section; aria-labelledby=dishResultsTitle |
| 65 | h3 | dishResultsTitle | — | Món ăn | — |
| 67 | span | — | — | ${listDish.size()} | class=result-count |
| 73 | div | — | — | — | class=table-scroll; tabindex=0; role=region; aria-label=Kết quả món ăn |
| 74 | table | outDishList | — | — | class=table results-table |
| 75 | caption | — | — | Danh sách món ăn phù hợp | class=visually-hidden |
| 78 | thead | — | — | — | — |
| 79 | tr | — | — | — | — |
| 80 | th | — | — | Tên món ăn | scope=col |
| 83 | th | — | — | Thể loại | scope=col |
| 86 | th | — | — | Khoảng giá theo size (VNĐ) | scope=col; class=numeric |
| 89 | th | — | — | Thao tác | scope=col |
| 94 | tbody | — | — | — | — |
| 96 | tr | — | — | — | — |
| 97 | td | — | — | — | class=name-cell |
| 98 | div | — | — | — | class=result-name |
| 99 | img | — | — | — | src=${pageContext.request.contextPath}/<c:out value='${dish.image}'/>; alt=; title=Ảnh minh họa món ăn; width=64; height=48; loading=lazy; decoding=async |
| 100 | span | — | — | — | — |
| 105 | td | — | — | — | — |
| 108 | td | — | — | — | class=numeric |
| 115 | td | — | — | — | — |
| 116 | form | — | — | — | method=get; action=DishDetailUI5.jsp |
| 117 | input | — | dishId | — | type=hidden; value=${dish.id} |
| 118 | input | — | name | — | type=hidden; value=<c:out value='${param.name}'/> |
| 119 | input | — | type | — | type=hidden; value=<c:out value='${param.type}'/> |
| 120 | button | — | — | Xem chi tiết | class=btn btn-outline-success btn-sm; type=submit |
| 132 | p | — | — | Không tìm thấy món ăn phù hợp. | class=empty-state |
| 138 | section | — | — | — | class=result-section; aria-labelledby=comboResultsTitle |
| 139 | h3 | comboResultsTitle | — | Combo | — |
| 141 | span | — | — | ${listCombo.size()} | class=result-count |
| 147 | div | — | — | — | class=table-scroll; tabindex=0; role=region; aria-label=Kết quả combo |
| 148 | table | outComboSearchList | — | — | class=table results-table |
| 149 | caption | — | — | Danh sách combo phù hợp | class=visually-hidden |
| 152 | thead | — | — | — | — |
| 153 | tr | — | — | — | — |
| 154 | th | — | — | Tên combo | scope=col |
| 157 | th | — | — | Số món thành phần | scope=col; class=numeric |
| 160 | th | — | — | Giá bán (VNĐ) | scope=col; class=numeric |
| 163 | th | — | — | Thao tác | scope=col |
| 168 | tbody | — | — | — | — |
| 171 | tr | — | — | — | — |
| 172 | td | — | — | — | class=name-cell |
| 173 | div | — | — | — | class=result-name |
| 174 | img | — | — | — | src=${pageContext.request.contextPath}/<c:out value='${comboImage}'/>; alt=; title=Ảnh minh họa combo; width=64; height=48; loading=lazy; decoding=async |
| 175 | span | — | — | — | — |
| 180 | td | — | — | ${combo.items.size()} | class=numeric |
| 183 | td | — | — | — | class=numeric |
| 186 | td | — | — | — | — |
| 187 | form | — | — | — | method=get; action=ComboDetailUI5.jsp |
| 188 | input | — | comboId | — | type=hidden; value=${combo.id} |
| 189 | input | — | name | — | type=hidden; value=<c:out value='${param.name}'/> |
| 190 | input | — | type | — | type=hidden; value=<c:out value='${param.type}'/> |
| 191 | button | — | — | Xem chi tiết combo | class=btn btn-outline-success btn-sm; type=submit |
| 203 | p | — | — | Không tìm thấy combo phù hợp. | class=empty-state |
| 211 | p | — | — | Nhập tên hoặc chọn thể loại rồi bấm Tìm kiếm. Để trống cả hai để xem tất cả món ăn và combo. | class=empty-state |

Thẻ server: `c:set` (2 vị trí), `c:forEach` (3 vị trí), `c:out` (4 vị trí), `c:choose` (3 vị trí), `c:when` (3 vị trí), `fmt:formatNumber` (3 vị trí), `c:if` (1 vị trí), `c:otherwise` (3 vị trí).

### Toàn bộ mã Java xử lý trong JSP

Dòng 4:

```java
DishDAO dishDAO = new DishDAO();
    boolean searched = request.getParameter("search") != null || request.getParameter("name") != null || request.getParameter("type") != null;
    request.setAttribute("types", dishDAO.getTypes());
    request.setAttribute("searched", searched);
    request.setAttribute("listDish", searched ? dishDAO.searchDishes(request.getParameter("name"), request.getParameter("type")) : java.util.List.of());
    request.setAttribute("listCombo", searched ? new ComboDAO().searchCombos(request.getParameter("name"), request.getParameter("type")) : java.util.List.of());
```

## 4.5. DishDetailUI5.jsp — Chi tiết món

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | GET dishId,dishSizeId tùy chọn,name,type. Gọi DishDAO.getDishbyId(), Dish.getDefaultDishSize(), getSizePrices(). Request: dish,selectedSize,sizeError khi lỗi. |
| Element nghiệp vụ | Ảnh; #outName,#outType,#outDescription,#currentSizeName,#outPrice; select #dishSizeId/name=dishSizeId; hidden dishId,name,type; #subBack. |

### Luồng xử lý

Đọc ID → DAO đọc món và size → không có món/sai ID: HTTP 404. Có món: lấy size từ request hoặc mặc định tỷ lệ 100%, nếu thiếu thì size đầu tiên. Size sai/không thuộc món: HTTP 400 và sizeError. Render giá. JS change đọc data-price/data-size để cập nhật giá/tên và history.replaceState, bình thường không gửi request. Nếu thiếu vùng giá/tên thì requestSubmit(). Tắt JS hoàn toàn không có handler tự submit; form hiện không có nút submit riêng. Quay lại giữ bộ lọc và search=1.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 25 | main | main | — | — | class=container page-shell dish-detail-page |
| 31 | a | subBack | — | Quay lại kết quả tìm kiếm | class=back-link; href=<c:out value='${back}'/> |
| 36 | article | — | — | — | class=detail-layout |
| 37 | div | — | — | — | class=detail-image |
| 38 | img | — | — | — | src=${pageContext.request.contextPath}/<c:out value='${dish.image}'/>; alt=Hình minh họa món ăn |
| 40 | div | — | — | — | class=detail-content |
| 41 | h1 | outName | — | — | — |
| 44 | p | outType | — | Thể loại: | — |
| 48 | p | outDescription | — | — | — |
| 52 | p | — | — | — | class=alert alert-danger; role=alert |
| 57 | p | — | — | Giá size | class=detail-price-label |
| 59 | span | currentSizeName | — | — | — |
| 64 | p | outPrice | — | — | class=numeric price; aria-live=polite |
| 68 | form | — | — | — | method=get; action=DishDetailUI5.jsp; class=size-price-form |
| 69 | input | — | dishId | — | type=hidden; value=${dish.id} |
| 70 | input | — | name | — | type=hidden; value=<c:out value='${param.name}'/> |
| 71 | input | — | type | — | type=hidden; value=<c:out value='${param.type}'/> |
| 72 | div | — | — | — | — |
| 73 | label | — | — | Chọn kích cỡ | for=dishSizeId; class=form-label |
| 76 | select | dishSizeId | dishSizeId | — | class=form-select size-select |
| 79 | option | — | — | — | value=${size.id}; data-price=<c:out value='${sizePrice}'/>; data-size=<c:out value='${size.name}'/> |
| 93 | h1 | — | — | Không tìm thấy món ăn | — |
| 96 | p | — | — | Mã món ăn không hợp lệ hoặc món ăn không còn tồn tại. | — |
| 102 | script | — | — | — | src=${pageContext.request.contextPath}/assets/dish-detail.js?v=1 |

Thẻ server: `c:set` (1 vị trí), `c:url` (1 vị trí), `c:param` (3 vị trí), `c:choose` (1 vị trí), `c:when` (1 vị trí), `c:out` (7 vị trí), `c:if` (2 vị trí), `fmt:formatNumber` (2 vị trí), `c:forEach` (1 vị trí), `c:otherwise` (1 vị trí).

### Toàn bộ mã Java xử lý trong JSP

Dòng 4:

```java
Dish dish = null;
    try { dish = new DishDAO().getDishbyId(Long.parseLong(request.getParameter("dishId"))).orElse(null); }
    catch (NumberFormatException ex) { /* Invalid dish ID is a 404. */ }
    request.setAttribute("dish", dish);
    if (dish == null) response.setStatus(404);
    else {
        try {
            String selected = request.getParameter("dishSizeId");
            long sizeId = selected == null ? (dish.getDefaultDishSize() == null ? -1 : dish.getDefaultDishSize().id()) : Long.parseLong(selected);
            DishSizePrice price = dish.getSizePrices().stream().filter(size -> size.id() == sizeId).findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Size không thuộc món ăn đang xem."));
            request.setAttribute("selectedSize", price);
        } catch (IllegalArgumentException ex) {
            response.setStatus(400);
            request.setAttribute("sizeError", "Vui lòng chọn size hợp lệ của món ăn này.");
        }
    }
```

## 4.6. ComboListUI5.jsp — Danh sách combo

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | ComboDAO.getInstance().getAllCombo(). Request: listCombo,success. Lấy session.success rồi xóa để thông báo hiện một lần. |
| Element nghiệp vụ | Nút liên kết #subAddCombo; bảng #outComboList: mã,tên,giá,thời hạn,số dòng thành phần,chi tiết; thông báo thành công hoặc rỗng. |

### Luồng xử lý

GET → DAO đọc combo nhà hàng 1, đọc chi tiết món/size → List<Combo> → request → bảng. Thêm combo đến AddComboUI5.jsp. Xem chi tiết đến ComboDetailUI5.jsp?comboId=...&from=staff.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 8 | main | main | — | — | class=container page-shell page-wide |
| 9 | a | — | — | Về trang chính nhân viên | class=back-link; href=MainStaffUI5.jsp |
| 12 | div | — | — | — | class=staff-heading |
| 13 | h1 | — | — | Danh sách combo | — |
| 16 | a | subAddCombo | — | Thêm combo mới | class=btn btn-primary; href=AddComboUI5.jsp |
| 21 | p | — | — | — | class=alert alert-success; role=status |
| 25 | section | — | — | — | class=section-panel; aria-labelledby=comboListTitle |
| 26 | h2 | comboListTitle | — | Các combo đã lưu | — |
| 29 | div | — | — | — | class=table-scroll; tabindex=0; role=region; aria-label=Danh sách combo |
| 30 | table | outComboList | — | — | class=table |
| 31 | thead | — | — | — | — |
| 32 | tr | — | — | — | — |
| 33 | th | — | — | Mã | scope=col; class=numeric |
| 36 | th | — | — | Tên combo | scope=col |
| 39 | th | — | — | Giá bán (VNĐ) | scope=col; class=numeric |
| 42 | th | — | — | Thời hạn | scope=col |
| 45 | th | — | — | Số món thành phần | scope=col; class=numeric |
| 48 | th | — | — | Thao tác | scope=col |
| 53 | tbody | — | — | — | — |
| 55 | tr | — | — | — | — |
| 56 | td | — | — | ${combo.id} | class=numeric |
| 59 | td | — | — | — | class=name-cell |
| 62 | td | — | — | — | class=numeric |
| 65 | td | — | — | — | — |
| 77 | td | — | — | ${combo.items.size()} | class=numeric |
| 80 | td | — | — | — | — |
| 85 | a | — | — | Xem chi tiết | class=btn btn-outline-success btn-sm; href=<c:out value='${detail}'/> |
| 95 | p | — | — | Chưa có combo. Chọn Thêm combo mới để bắt đầu. | class=empty-state |

Thẻ server: `c:set` (1 vị trí), `c:if` (2 vị trí), `c:out` (4 vị trí), `c:forEach` (1 vị trí), `fmt:formatNumber` (1 vị trí), `c:choose` (1 vị trí), `c:when` (1 vị trí), `c:otherwise` (1 vị trí), `c:url` (1 vị trí), `c:param` (2 vị trí).

### Toàn bộ mã Java xử lý trong JSP

Dòng 4:

```java
request.setAttribute("listCombo", ComboDAO.getInstance().getAllCombo());
   request.setAttribute("success", session.getAttribute("success")); session.removeAttribute("success");
```

## 4.7. ComboDetailUI5.jsp — Chi tiết combo

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | GET comboId,from,name,type. from đúng staff thì staffView=true. id>0 mới gọi ComboDAO.getComboById(). Request: combo,staffView. |
| Element nghiệp vụ | Ảnh combo; #comboTitle; giá bán,thời hạn; #outDescription khi có; #componentsTitle; bảng #outComboDetails; #subBack. |

### Luồng xử lý

Nhận ID → DAO dựng Combo cùng items → không có/sai mã: HTTP 404. Có combo: render thông tin; vòng lặp items hiển thị ảnh,tên,loại,size,đơn giá,số lượng,thành tiền. getReferenceTotal() cộng subtotal. Giá bán riêng không bằng bắt buộc tổng tham khảo. Back về ComboListUI5.jsp nếu from=staff, ngược lại về kết quả tìm kiếm giữ bộ lọc.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 15 | main | main | — | — | class=container page-shell page-wide combo-detail-page |
| 28 | a | subBack | — | ${staffView ? 'Về danh sách combo' : 'Quay lại kết quả tìm kiếm'} | class=back-link; href=<c:out value='${back}'/> |
| 33 | section | — | — | — | class=section-panel combo-overview; aria-labelledby=comboTitle |
| 35 | div | — | — | — | class=combo-visual |
| 36 | img | — | — | — | src=${pageContext.request.contextPath}/<c:out value='${comboImage}'/>; alt=Ảnh minh họa combo |
| 38 | div | — | — | — | class=combo-summary |
| 39 | p | — | — | Chi tiết combo | class=section-label |
| 42 | h1 | comboTitle | — | — | — |
| 45 | dl | — | — | — | class=detail-facts |
| 46 | div | — | — | — | — |
| 47 | dt | — | — | Giá bán (VNĐ) | — |
| 50 | dd | — | — | — | class=numeric price |
| 54 | div | — | — | — | — |
| 55 | dt | — | — | Thời hạn | — |
| 58 | dd | — | — | — | — |
| 73 | h2 | — | — | Mô tả | — |
| 76 | p | outDescription | — | — | — |
| 82 | section | — | — | — | class=section-panel; aria-labelledby=componentsTitle |
| 83 | h2 | componentsTitle | — | Các món trong combo | — |
| 86 | div | — | — | — | class=table-scroll; tabindex=0; role=region; aria-label=Danh sách món trong combo |
| 87 | table | outComboDetails | — | — | class=table |
| 88 | caption | — | — | Thành phần combo và giá món tham khảo | class=visually-hidden |
| 91 | thead | — | — | — | — |
| 92 | tr | — | — | — | — |
| 93 | th | — | — | Tên món ăn | scope=col |
| 96 | th | — | — | Thể loại | scope=col |
| 99 | th | — | — | Kích cỡ | scope=col |
| 102 | th | — | — | Đơn giá (VNĐ) | scope=col; class=numeric |
| 105 | th | — | — | Số lượng | scope=col; class=numeric |
| 108 | th | — | — | Thành tiền (VNĐ) | scope=col; class=numeric |
| 113 | tbody | — | — | — | — |
| 115 | tr | — | — | — | — |
| 116 | td | — | — | — | class=name-cell |
| 117 | div | — | — | — | class=result-name |
| 118 | img | — | — | — | src=${pageContext.request.contextPath}/<c:out value='${item.dish.image}'/>; alt=; width=64; height=48; loading=lazy |
| 119 | span | — | — | — | — |
| 124 | td | — | — | — | — |
| 127 | td | — | — | — | — |
| 128 | span | — | — | — | class=combo-size |
| 132 | td | — | — | — | class=numeric |
| 135 | td | — | — | ${item.quantity} | class=numeric |
| 138 | td | — | — | — | class=numeric |
| 144 | tfoot | — | — | — | — |
| 145 | tr | — | — | — | — |
| 146 | th | — | — | Tổng giá món tham khảo (VNĐ) | scope=row; colspan=5 |
| 149 | td | — | — | — | class=numeric |
| 156 | p | — | — | Giá các món chỉ để tham khảo. Giá bán combo là mức giá riêng ở phần thông tin phía trên. | class=small |
| 162 | h1 | — | — | Không tìm thấy combo | — |
| 165 | p | — | — | Mã combo không hợp lệ hoặc combo không còn tồn tại. | — |

Thẻ server: `c:set` (2 vị trí), `c:choose` (3 vị trí), `c:when` (3 vị trí), `c:url` (2 vị trí), `c:otherwise` (3 vị trí), `c:param` (3 vị trí), `c:out` (7 vị trí), `fmt:formatNumber` (4 vị trí), `c:if` (1 vị trí), `c:forEach` (1 vị trí).

### Toàn bộ mã Java xử lý trong JSP

Dòng 4:

```java
boolean staff = "staff".equals(request.getParameter("from"));
    request.setAttribute("staffView", staff);
    try {
        long comboId = Long.parseLong(request.getParameter("comboId"));
        request.setAttribute("combo", comboId > 0 ? new ComboDAO().getComboById(comboId).orElse(null) : null);
    } catch (NumberFormatException ex) { request.setAttribute("combo", null); }
    if (request.getAttribute("combo") == null) response.setStatus(404);
```

## 4.8. AddComboUI5.jsp — Thêm combo/chỉnh bản nháp

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | GET mở trang. POST multipart nhận csrf,draftId,dishName,dishType,name,price,description,startDate,endDate,comboImage và action/dishId/dishSizeId/size/số lượng. Gọi ComboFlow.csrf/validToken/requireDraft/readInformation/edit/openDraft; DishDAO.getTypes/searchDishes; nhánh add gọi getDishbyId. |
| Element nghiệp vụ | Form #editor; hidden draftId,csrf; #inDishName,#inDishType,#subSearch; #outDishList với select dishSize-<dishId>; #outComboItems với input quantity-<sizeId>; #comboImage,#comboImagePreview; #inComboName,#inPrice,#inStartDate,#inEndDate,#inDescription; #subSaveCombo và nút hủy. |

### Luồng xử lý

Khóa synchronized(session). GET tạo token nếu thiếu, mở/tạo draft, đọc bộ lọc và tải thể loại; chỉ tải món nếu comboSearched=true. POST nếu không renderOnly: CSRF sai trả 403; kiểm tra draftId; đọc thông tin/ngày/ảnh; phân nhánh action; lưu bộ lọc vào session và comboSearched=true; redirect GET cùng trang. IllegalArgumentException → request.error rồi render lại. Forward từ trang lưu có renderOnly=true thì chỉ render, không chạy lại action.

### Từng nút gọi hàm nào?

| Thao tác | Gửi đến | Hàm | Kết quả |
|---|---|---|---|
| #subSearch | POST AddComboUI5.jsp; action=search | ComboFlow.edit: nhánh search không sửa items | Lưu bộ lọc, tải lại món |
| Thêm món | POST AddComboUI5.jsp?action=add; dishId; dishSize_<dishId> | DishDAO.getDishbyId → ComboDraft.addDish(dish,sizeId) | Cùng size tăng quantity; khác size thêm dòng |
| Cập nhật | POST AddComboUI5.jsp?action=quantity; dishSizeId; quantity_<sizeId> | ComboDraft.setQuantity → new ComboItem | Chỉ cập nhật dòng được bấm |
| Bỏ món | POST AddComboUI5.jsp?action=remove; dishSizeId | ComboDraft.removeDish | Xóa dòng khỏi bản nháp |
| Chọn ảnh | Sự kiện change trên #comboImage | combo-image.js handler | Preview cục bộ, chưa gửi HTTP |
| #subSaveCombo | POST doSaveCombo5.jsp; action=save | readInformation → toCombo → saveCombo | Ghi DB |
| Hủy | POST doSaveCombo5.jsp; action=cancel | requireDraft; session.removeAttribute | Xóa bản nháp, không ghi DB |

Các nút tìm/thêm/cập nhật/xóa/hủy dùng formnovalidate; nút lưu dùng validation HTML và server. Với add/remove/quantity, action lấy từ query string trong formaction. Các thao tác POST qua AddComboUI đều đọc thông tin/ngày/ảnh trước khi phân nhánh edit và sau thành công đều đặt comboSearched=true. Session lưu comboDraft,csrf,comboSearchName,comboSearchType,comboSearched; request dùng draft,dishName,dishType,types,listDish,error và renderOnly khi forward.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 37 | main | main | — | — | class=container page-shell page-wide combo-editor |
| 38 | a | — | — | Về danh sách combo | class=back-link; href=ComboListUI5.jsp |
| 41 | h1 | — | — | Thêm combo mới | — |
| 44 | p | — | — | Tìm món, chọn size theo giá hiển thị, rồi nhập thông tin và xác nhận lưu combo. | — |
| 48 | div | outError | — | — | class=alert alert-danger; role=alert |
| 52 | form | editor | — | — | method=post; action=AddComboUI5.jsp; enctype=multipart/form-data |
| 54 | input | — | draftId | — | type=hidden; value=${draft.id} |
| 55 | input | — | csrf | — | type=hidden; value=${sessionScope.csrf} |
| 56 | section | — | — | — | class=card p-4 mb-4 |
| 57 | h2 | — | — | 1. Tìm món ăn | — |
| 60 | div | — | — | — | class=row g-3 |
| 61 | div | — | — | — | class=col-md-6 |
| 62 | label | — | — | Tên món ăn | for=inDishName; class=form-label |
| 65 | input | inDishName | dishName | — | maxlength=100; class=form-control; value=<c:out value='${dishName}'/> |
| 67 | div | — | — | — | class=col-md-4 |
| 68 | label | — | — | Thể loại | for=inDishType; class=form-label |
| 71 | select | inDishType | dishType | — | class=form-select |
| 72 | option | — | — | Tất cả thể loại | value= |
| 76 | option | — | — | — | value=<c:out value='${type}'/> |
| 82 | div | — | — | — | class=col-md-2 d-flex align-items-end |
| 83 | button | subSearch | action | Tìm kiếm | value=search; class=btn btn-primary |
| 88 | p | — | — | Nhập tên hoặc chọn thể loại. Có thể kết hợp cả hai điều kiện. | class=small mt-2 |
| 91 | div | — | — | — | class=table-scroll; tabindex=0; role=region; aria-label=Bảng dữ liệu |
| 92 | table | outDishList | — | — | class=table |
| 93 | thead | — | — | — | — |
| 94 | tr | — | — | — | — |
| 95 | th | — | — | Món ăn | — |
| 98 | th | — | — | Thể loại | — |
| 101 | th | — | — | Kích cỡ — Giá (VNĐ) | — |
| 104 | th | — | — | Chọn | — |
| 109 | tbody | — | — | — | — |
| 111 | tr | — | — | — | — |
| 112 | td | — | — | — | — |
| 115 | td | — | — | — | — |
| 118 | td | — | — | — | — |
| 119 | label | — | — | Chọn size | class=visually-hidden; for=dishSize-${dish.id} |
| 123 | select | dishSize-${dish.id} | dishSize_${dish.id} | — | class=form-select size-select |
| 125 | option | — | — | — | value=${size.id} |
| 133 | td | — | — | — | — |
| 135 | button | — | dishId | Thêm món | class=btn btn-outline-success btn-sm; value=${dish.id}; formaction=AddComboUI5.jsp?action=add |
| 145 | p | — | — | Không tìm thấy món ăn phù hợp. | role=status |
| 150 | p | — | — | Nhấn Tìm kiếm để lấy danh sách món ăn. | — |
| 155 | section | — | — | — | class=card p-4 mb-4 |
| 156 | h2 | — | — | 2. Danh sách món đã chọn | — |
| 159 | div | — | — | — | class=table-scroll; tabindex=0; role=region; aria-label=Bảng dữ liệu |
| 160 | table | outComboItems | — | — | class=table |
| 161 | thead | — | — | — | — |
| 162 | tr | — | — | — | — |
| 163 | th | — | — | Món ăn | — |
| 166 | th | — | — | Kích cỡ | — |
| 169 | th | — | — | Đơn giá (VNĐ) | class=numeric |
| 172 | th | — | — | Số lượng | class=numeric |
| 175 | th | — | — | Thành tiền (VNĐ) | class=numeric |
| 178 | th | — | — | Thao tác | — |
| 183 | tbody | — | — | — | — |
| 186 | tr | — | — | — | — |
| 187 | td | — | — | — | — |
| 190 | td | — | — | — | — |
| 193 | td | — | — | — | class=numeric |
| 196 | td | — | — | — | class=numeric quantity-cell |
| 197 | label | — | — | Số lượng | class=visually-hidden; for=quantity-${item.dishSize.id} |
| 201 | input | quantity-${item.dishSize.id} | quantity_${item.dishSize.id} | — | type=number; min=1; max=999; value=${item.quantity}; class=form-control quantity-input |
| 202 | button | — | dishSizeId | Cập nhật | value=${item.dishSize.id}; formaction=AddComboUI5.jsp?action=quantity; class=btn btn-link btn-sm |
| 206 | td | — | — | — | class=numeric |
| 209 | td | — | — | — | — |
| 210 | button | — | dishSizeId | Bỏ món | class=btn btn-outline-danger btn-sm; value=${item.dishSize.id}; formaction=AddComboUI5.jsp?action=remove |
| 221 | p | — | — | Chưa chọn món nào. | — |
| 225 | p | — | — | Tổng giá món tham khảo (VNĐ): | — |
| 227 | strong | — | — | — | — |
| 231 | p | — | — | Có thể tìm tiếp mà vẫn giữ các món đã chọn. Chọn lại cùng món và cùng size sẽ tăng số lượng. Cùng món khác size được giữ thành hai dòng riêng. | class=small |
| 235 | section | — | — | — | class=card p-4 mb-4 |
| 236 | h2 | — | — | 3. Thông tin combo | — |
| 239 | label | — | — | Ảnh combo | for=comboImage; class=form-label |
| 242 | input | comboImage | comboImage | — | type=file; accept=image/png,image/jpeg; class=form-control mb-2 |
| 243 | p | — | — | Chọn ảnh PNG hoặc JPEG, tối đa 5 MB. | class=small |
| 246 | img | comboImagePreview | — | — | src=${empty draft.img ? '' : pageContext.request.contextPath.concat('/').concat(draft.img)}; alt=Ảnh combo đã chọn; style=max-width:260px;max-height:180px;object-fit:cover;border-radius:8px;margin-bottom:16px |
| 247 | label | — | — | Tên combo * | for=inComboName; class=form-label |
| 250 | input | inComboName | name | — | maxlength=100; class=form-control mb-3; value=<c:out value='${draft.name}'/> |
| 251 | label | — | — | Giá bán combo (VNĐ) * | for=inPrice; class=form-label |
| 254 | input | inPrice | price | — | type=number; min=0.01; max=999999999999999.99; step=0.01; class=form-control mb-2; value=<c:out value='${draft.price}'/> |
| 255 | p | — | — | Nhập giá bán của combo. Tổng giá món chỉ để tham khảo. | class=small |
| 258 | div | — | — | — | class=row g-3 mb-3 |
| 259 | div | — | — | — | class=col-md-6 |
| 260 | label | — | — | Ngày bắt đầu | for=inStartDate; class=form-label |
| 263 | input | inStartDate | startDate | — | type=date; min=1000-01-01; max=9999-12-31; class=form-control; value=<c:out value='${draft.startDate}'/> |
| 265 | div | — | — | — | class=col-md-6 |
| 266 | label | — | — | Ngày kết thúc | for=inEndDate; class=form-label |
| 269 | input | inEndDate | endDate | — | type=date; min=1000-01-01; max=9999-12-31; class=form-control; value=<c:out value='${draft.endDate}'/> |
| 272 | p | — | — | Có thể bỏ trống cả hai ngày. Nếu đặt thời hạn, nhập đủ ngày bắt đầu và ngày kết thúc. | class=small |
| 275 | label | — | — | Mô tả | for=inDescription; class=form-label |
| 278 | textarea | inDescription | description | — | maxlength=255; class=form-control mb-3 |
| 279 | button | subSaveCombo | action | Xác nhận lưu combo | class=btn btn-primary; formaction=doSaveCombo5.jsp; value=save |
| 282 | button | — | action | Hủy bản nháp | class=btn btn-outline-danger; formaction=doSaveCombo5.jsp; value=cancel |
| 288 | script | — | — | — | src=${pageContext.request.contextPath}/assets/combo-image.js?v=1 |

Thẻ server: `c:set` (3 vị trí), `c:if` (4 vị trí), `c:out` (10 vị trí), `c:forEach` (4 vị trí), `fmt:formatNumber` (4 vị trí).

### Toàn bộ mã Java xử lý trong JSP

Dòng 4:

```java
// Ẩn trên server: comboDraft: ComboDraft, items: List<ComboItem>, listDish: List<Dish>.
    // HTML chỉ truyền draftId/csrf/dishId; không serialize toàn bộ entity hoặc tin giá món từ client.
    synchronized (session) {
        ComboFlow.csrf(session);
        if ("POST".equals(request.getMethod()) && !Boolean.TRUE.equals(request.getAttribute("renderOnly"))) {
            if (!ComboFlow.validToken(request)) { response.sendError(403); return; }
            try {
                ComboDraft draft = ComboFlow.requireDraft(request);
                ComboFlow.readInformation(request, draft);
                ComboFlow.edit(request, draft);
                session.setAttribute("comboSearchName", java.util.Objects.toString(request.getParameter("dishName"), ""));
                session.setAttribute("comboSearchType", java.util.Objects.toString(request.getParameter("dishType"), ""));
                session.setAttribute("comboSearched", true);
                response.sendRedirect(request.getContextPath() + "/AddComboUI5.jsp");
                return;
            } catch (IllegalArgumentException ex) {
                request.setAttribute("error", ex instanceof NumberFormatException ? "Mã món hoặc số lượng không hợp lệ." : ex.getMessage());
            }
        }
        request.setAttribute("draft", ComboFlow.openDraft(session));
        DishDAO dishDAO = new DishDAO();
        String dishName = java.util.Objects.toString(session.getAttribute("comboSearchName"), "");
        String dishType = java.util.Objects.toString(session.getAttribute("comboSearchType"), "");
        request.setAttribute("dishName", dishName);
        request.setAttribute("dishType", dishType);
        request.setAttribute("types", dishDAO.getTypes());
        request.setAttribute("listDish", Boolean.TRUE.equals(session.getAttribute("comboSearched")) ?
            dishDAO.searchDishes(dishName, dishType) : java.util.List.of());
    }
```

## 4.9. doSaveCombo5.jsp — Endpoint lưu/hủy

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | Chỉ POST. csrf,draftId,action=save hoặc cancel; save nhận thông tin/ảnh. Không có UI. ComboFlow.validToken/requireDraft/readInformation; ComboDraft.toCombo; ComboDAO.getInstance().saveCombo. |
| Element nghiệp vụ | Không có HTML riêng. Nút gọi endpoint ở AddComboUI5.jsp. |

### Luồng xử lý

Không POST → 405 với Allow: POST. CSRF sai → 403. Khóa session, kiểm tra draft. cancel → xóa nháp/bộ lọc và redirect danh sách, không ghi DB. save → đọc thông tin → toCombo() kiểm tra và tạo Model → DAO transaction INSERT combo+chi tiết. Thành công xóa nháp/bộ lọc, đặt session.success, redirect ComboListUI5.jsp. IllegalArgumentException hoặc DatabaseException → đặt error,renderOnly=true; forward về AddComboUI5.jsp; giữ bản nháp hợp lệ.

### Toàn bộ element HTML trong file (không bao gồm include)

Không có HTML riêng; đây là endpoint xử lý/trả dữ liệu.

### Toàn bộ mã Java xử lý trong JSP

Dòng 3:

```java
// Trang xử lý theo scenario 28–34. Chỉ POST; đóng gói Combo trước khi gọi saveCombo.
    if (!"POST".equals(request.getMethod())) { response.setHeader("Allow", "POST"); response.sendError(405); return; }
    if (!ComboFlow.validToken(request)) { response.sendError(403); return; }
    synchronized (session) {
        try {
            ComboDraft draft = ComboFlow.requireDraft(request);
            String action = request.getParameter("action");
            if ("cancel".equals(action)) {
                session.removeAttribute("comboDraft"); session.removeAttribute("comboSearched");
                session.removeAttribute("comboSearchName"); session.removeAttribute("comboSearchType");
                response.sendRedirect(request.getContextPath() + "/ComboListUI5.jsp"); return;
            }
            if (!"save".equals(action)) throw new IllegalArgumentException("Thao tác không hợp lệ.");
            ComboFlow.readInformation(request, draft);
            Combo combo = draft.toCombo();
            boolean saved = ComboDAO.getInstance().saveCombo(combo);
            if (!saved) throw new IllegalArgumentException("Chưa lưu được combo. Vui lòng thử lại.");
            session.removeAttribute("comboDraft"); session.removeAttribute("comboSearched");
            session.removeAttribute("comboSearchName"); session.removeAttribute("comboSearchType");
            session.setAttribute("success", "Thêm combo “" + combo.getName() + "” thành công!");
            response.sendRedirect(request.getContextPath() + "/ComboListUI5.jsp");
            return;
        } catch (IllegalArgumentException | vn.restman.dao.DatabaseException ex) {
            // Không tạo bản nháp mới từ POST cũ; bản nháp hợp lệ được giữ khi validation lỗi.
            request.setAttribute("error", ex.getMessage());
            // Chỉ hiển thị lại form lỗi, không xử lý lại sự kiện POST.
            request.setAttribute("renderOnly", true);
            request.getRequestDispatcher("/AddComboUI5.jsp").forward(request, response);
        }
    }
```

## 4.10. ComboImage5.jsp — Endpoint phục vụ ảnh

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | Tham số file; Files và ComboImages.directory(); không gọi DAO. |
| Element nghiệp vụ | Không có HTML; trả bytes ảnh hoặc HTTP 404. |

### Luồng xử lý

Kiểm tra tên bằng regex [a-f0-9-]{36}\.(png|jpg) → kiểm tra file tồn tại trong thư mục upload → đặt Content-Type, nosniff, Cache-Control public/max-age=31536000/immutable và Content-Length → xóa buffer JSP, copy bytes vào output stream. HEAD không ghi body. Database chỉ lưu URL tương đối, không chứa bytes ảnh.

### Toàn bộ element HTML trong file (không bao gồm include)

Không có HTML riêng; đây là endpoint xử lý/trả dữ liệu.

### Toàn bộ mã Java xử lý trong JSP

Dòng 2:

```java
String file=request.getParameter("file");
    if (file==null || !file.matches("[a-f0-9-]{36}\\.(png|jpg)")) { response.sendError(404); return; }
    Path image=ComboImages.directory().resolve(file);
    if (!Files.isRegularFile(image)) { response.sendError(404); return; }
    response.setContentType(file.endsWith(".png") ? "image/png" : "image/jpeg");
    response.setHeader("X-Content-Type-Options","nosniff");
    response.setHeader("Cache-Control","public, max-age=31536000, immutable");
    response.setContentLengthLong(Files.size(image));
    out.clear();
    pageContext.pushBody();
    if (!"HEAD".equals(request.getMethod())) Files.copy(image,response.getOutputStream());
```

## 4.11. WEB-INF/views/shared/database-error5.jsp — Trang lỗi database

| Mục | Chi tiết |
|---|---|
| Đầu vào, hàm và dữ liệu | isErrorPage=true; cấu hình error-page khi DatabaseException chưa được bắt. Không gọi DAO. |
| Element nghiệp vụ | Tiêu đề lỗi, hướng dẫn kiểm tra MySQL, liên kết về trang chủ. |

### Luồng xử lý

DAO có SQLException → Database.failure ghi log và trả DatabaseException → nếu không bắt cục bộ thì container chuyển trang lỗi. doSaveCombo5.jsp đã bắt DatabaseException và forward lại form nên nhánh đó không đi qua trang lỗi chung.

### Toàn bộ element HTML trong file (không bao gồm include)

| Dòng | Thẻ | id | name | Chữ ngay sau thẻ | Thuộc tính |
|---|---|---|---|---|---|
| 3 | main | main | — | — | class=container page-shell |
| 4 | h1 | — | — | Chưa truy cập được cơ sở dữ liệu | — |
| 7 | p | — | — | Vui lòng kiểm tra MySQL đang chạy và đã khởi tạo database RestMan. | — |
| 10 | a | — | — | Về trang chủ | class=btn btn-primary; href=${pageContext.request.contextPath}/ |

### Toàn bộ mã Java xử lý trong JSP

Không có scriptlet nghiệp vụ; xử lý hiển thị bằng HTML/include/JSTL.

## 5. Header và footer dùng chung

### head.jspf

Header: khai báo JSTL core/fmt và locale vi_VN; nạp Bootstrap/app.css; link bỏ qua đến #main; logo về trang chủ; link khách hàng/nhân viên đánh dấu theo area.

| Dòng | Thẻ | Khai báo |
|---|---|---|
| 4 | fmt:setLocale | <fmt:setLocale value="vi_VN"/> |
| 6 | html | <html lang="vi"> |
| 7 | head | <head> |
| 8 | meta | <meta charset="UTF-8"> |
| 9 | meta | <meta name="viewport" content="width=device-width, initial-scale=1"> |
| 10 | title | <title> |
| 13 | link | <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/bootstrap.min.css"> |
| 14 | link | <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css?v=10"> |
| 16 | body | <body> |
| 17 | a | <a class="skip-link" href="#main"> |
| 20 | header | <header class="site-header"> |
| 21 | nav | <nav class="container site-nav" aria-label="Điều hướng chính"> |
| 22 | a | <a class="brand" href="${pageContext.request.contextPath}/"> |
| 25 | div | <div class="nav-links"> |
| 26 | a | <a class="${area == 'customer' ? 'is-active' : ''}" href="${pageContext.request.contextPath}/MainCustomerUI5.jsp"> |
| 29 | a | <a class="${area == 'staff' ? 'is-active' : ''}" href="${pageContext.request.contextPath}/MainStaffUI5.jsp"> |

```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="vi_VN"/>
<!doctype html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>
            RestMan - Quản lý nhà hàng
        </title>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/bootstrap.min.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css?v=10">
    </head>
    <body>
        <a class="skip-link" href="#main">
            Đến nội dung chính
        </a>
        <header class="site-header">
            <nav class="container site-nav" aria-label="Điều hướng chính">
                <a class="brand" href="${pageContext.request.contextPath}/">
                    RestMan
                </a>
                <div class="nav-links">
                    <a class="${area == 'customer' ? 'is-active' : ''}" href="${pageContext.request.contextPath}/MainCustomerUI5.jsp">
                        Khách hàng
                    </a>
                    <a class="${area == 'staff' ? 'is-active' : ''}" href="${pageContext.request.contextPath}/MainStaffUI5.jsp">
                        Nhân viên
                    </a>
                </div>
            </nav>
        </header>
```

### footer.jspf

Footer hiển thị tên hệ thống và đóng body/html; không gọi DAO.

| Dòng | Thẻ | Khai báo |
|---|---|---|
| 2 | footer | <footer class="site-footer"> |
| 3 | div | <div class="container"> |

```jsp
<%@ page pageEncoding="UTF-8" %>
<footer class="site-footer">
    <div class="container">
        RestMan - Quản lý nhà hàng
    </div>
</footer>
</body>
</html>
```

## 6. Danh mục hàm xử lý và chức năng

| Hàm/nhóm hàm | Nhiệm vụ |
|---|---|
| ComboFlow.csrf | Tạo token UUID trong session nếu thiếu |
| ComboFlow.validToken | So csrf trong request và session; IllegalStateException → false |
| ComboFlow.getDraft/openDraft | Lấy nháp; openDraft tạo nếu chưa có |
| ComboFlow.requireDraft | Kiểm tra nháp tồn tại và draftId khớp |
| ComboFlow.readInformation | setInformation,setDates,ComboImages.receive; có ảnh mới thì setImg |
| ComboFlow.edit | Nhánh search/add/remove/quantity; action khác báo lỗi |
| ComboImages.directory | Cha của catalina.base rồi resolve uploads/combo |
| ComboImages.receive | Đọc Part comboImage, kiểm tra nội dung, lưu UUID, trả URL; không file trả null |
| Text.key | strip, NFD, bỏ dấu kết hợp, đổi đ/Đ và lower-case |
| DishDAO.searchDishes | SELECT nhà hàng 1 rồi lọc tên chứa từ khóa/loại khớp bằng Java |
| DishDAO.getDishbyId | Đúng tên hàm trong code có by viết thường; tìm theo id và nhà hàng 1; Optional<Dish> |
| DishDAO.getTypes | GROUP BY type; ORDER BY MIN(id) |
| DishDAO.readDish | JOIN size, tạo DishSize và Dish bằng constructor |
| ComboDAO.getInstance | Trả instance dùng chung; vài JSP vẫn dùng new ComboDAO |
| ComboDAO.getAllCombo/getComboById | Đọc combo nhà hàng 1 và dựng chi tiết |
| ComboDAO.searchCombos | Tên combo hoặc tên món thành phần khớp; loại áp dụng lên thành phần, anyMatch yêu cầu có item thỏa |
| ComboDAO.readCombo | JOIN chi tiết/món, gọi readDish, xác nhận size thuộc món, tạo ComboItem và Combo |
| ComboDAO.saveCombo | Khóa nhà hàng, kiểm tra trùng tên, INSERT hai bảng trong transaction |
| Database.open/value/failure | Đọc cấu hình/biến môi trường, mở JDBC; ưu tiên env; ghi log và tạo DatabaseException |
| ComboDraft.setInformation/setDates/setImg | Cập nhật trường bản nháp |
| ComboDraft.addDish (2 overload) | Dùng size mặc định hoặc size được chọn; gộp theo dishSizeId |
| ComboDraft.removeDish/setQuantity | Xóa dòng hoặc tạo ComboItem mới với quantity |
| ComboDraft.toCombo | Parse giá/ngày; kiểm tra; tạo Combo hoàn chỉnh |
| Combo.getReferenceTotal | Cộng item.getSubtotal |
| ComboItem.getUnitPrice/getSubtotal | Tính đơn giá theo size và thành tiền quantity×unitPrice |
| Dish.getSizePrices/getDefaultDishSize/getMinPrice/getMaxPrice | Tạo dữ liệu giá size; chọn mặc định tỷ lệ 100% hoặc đầu tiên; tìm min/max |
| DishSize.priceFor | basePrice×pricePercentage/100; làm tròn 2 số HALF_UP |
| Getter của các Model | Đọc thuộc tính cho Java/JSP EL; đầy đủ trong phụ lục mã nguồn |

### Transaction saveCombo()

1. Database.open; setAutoCommit(false).
2. SELECT id FROM tblRestaurant WHERE id=1 FOR UPDATE.
3. Đọc tên combo của nhà hàng, so Text.key; trùng báo lỗi.
4. INSERT tblCombo(name,price,description,img,startDate,endDate,tblRestaurantid), lấy generated key.
5. INSERT tblComboDetail(tblDishid,tblDishSizeid,tblComboid,quantity) bằng INSERT…SELECT kiểm tra size thuộc món/nhà hàng; mỗi dòng phải chèn đúng 1 bản ghi.
6. commit nếu thành công. SQLException hoặc RuntimeException trong transaction → rollback, ném lại; SQLException chuyển DatabaseException.

Giá tham khảo chi tiết được tính từ giá món/tỷ lệ size khi đọc; INSERT chi tiết không lưu riêng giá tham khảo theo dòng.

### Quy tắc kiểm tra dữ liệu

| Dữ liệu | Điều kiện |
|---|---|
| Tên combo | Không rỗng, strip không quá 100 ký tự; trùng tên sau chuẩn hóa bị từ chối |
| Giá | ComboDraft: 1–15 số nguyên, tối đa 2 số thập phân; Combo yêu cầu >0. HTML max=999999999999999.99 |
| Mô tả | Tối đa 255 ký tự |
| Ngày | Cả hai rỗng hoặc đủ hai; năm 1000–9999; bắt đầu không sau kết thúc |
| Thành phần | Ít nhất một dòng; size thuộc món; quantity=1–999 |
| Ảnh client | MIME PNG/JPEG; tối đa 5 MiB; chỉ kiểm tra sơ bộ |
| Ảnh server | ImageIO xác nhận PNG/JPEG và đọc thử; 5 MiB; tối đa 20.000.000 pixel |
| Multipart | max-file-size=5242880; max-request-size=7340032; threshold=0 |
| Token/bản nháp | csrf khớp session; draftId khớp bản nháp server |

## 7. JavaScript và sự kiện

| File | Sự kiện/hàm | Luồng |
|---|---|---|
| combo-image.js | IIFE và change | Lấy comboImage/preview; thiếu thì dừng. Lưu src ban đầu. change thu hồi URL tạm cũ, kiểm tra file; lỗi reset input,alert,khôi phục ảnh; hợp lệ tạo object URL và đổi hidden. Không tự upload. |
| dish-detail.js | IIFE và change | Lấy select; thiếu thì dừng. change đọc selectedOptions[0]; thiếu option thì dừng; thiếu outPrice/currentSizeName thì requestSubmit; còn lại đổi textContent từ dataset và replaceState URL. Không tính giá số thực ở client. |

## 8. Các điểm cần trình bày chính xác

- from=staff và area chỉ chọn giao diện/điều hướng; các trang khảo sát không có đoạn xác thực/phân quyền người dùng tương ứng.
- Số món thành phần đang là items.size(): số dòng món/size, không phải tổng quantity.
- Chọn ảnh chỉ tạo preview; POST gọi readInformation mới ghi ảnh ra đĩa. Hủy nháp hiện không xóa các ảnh đã ghi trước đó.
- SQL lấy dữ liệu nhà hàng id=1; tìm tên không dấu nằm trong Java, không phải SQL LIKE.
- Request và getter/setter không thay DAO. Getter có thể tính toán, ví dụ subtotal/referenceTotal/sizePrices.
- Forward giữ request/error; redirect tạo request mới. success vì thế đi qua session rồi bị xóa sau khi đọc.
- web.xml khai báo JSP endpoint multipart bằng servlet mapping; dự án không có class Controller Servlet riêng, nhưng Tomcat vẫn biên dịch JSP thành Servlet.

## 9. Phụ lục toàn bộ mã hàm Java/JavaScript

Giữ nguyên nguồn của tất cả 13 lớp Java và 2 file JavaScript để bao gồm đầy đủ constructor, overload, getter, accessor record và các hàm hỗ trợ. Java scriptlet của mỗi JSP đã xuất ở mục 4. Dòng nguồn tương ứng snapshot lúc tạo tài liệu.

### src/main/java/vn/restman/common/ComboFlow.java

```java
package vn.restman.common;

import jakarta.servlet.http.*;
import vn.restman.dao.DishDAO;
import vn.restman.model.ComboDraft;
import java.util.*;

/** Xử lý sự kiện của AddComboUI5.jsp; chỉ doSaveCombo5.jsp được phép gọi saveCombo. */
public final class ComboFlow {
    private ComboFlow() {}
    public static String csrf(HttpSession session) {
        if (session.getAttribute("csrf") == null) session.setAttribute("csrf", UUID.randomUUID().toString());
        return (String) session.getAttribute("csrf");
    }
    public static boolean validToken(HttpServletRequest request) {
        Object token = request.getSession().getAttribute("csrf");
        try { return token != null && token.equals(request.getParameter("csrf")); }
        catch (IllegalStateException ex) { return false; }
    }
    public static ComboDraft getDraft(HttpSession session) {
        return (ComboDraft) session.getAttribute("comboDraft");
    }
    public static ComboDraft openDraft(HttpSession session) {
        ComboDraft draft = getDraft(session);
        if (draft == null) { draft = new ComboDraft(); session.setAttribute("comboDraft", draft); }
        return draft;
    }
    public static ComboDraft requireDraft(HttpServletRequest request) {
        ComboDraft draft = getDraft(request.getSession());
        if (draft == null || !draft.getId().equals(request.getParameter("draftId")))
            throw new IllegalArgumentException("Bản nháp đã kết thúc hoặc hết hạn. Hãy mở lại Thêm combo mới.");
        return draft;
    }
    public static void readInformation(HttpServletRequest request, ComboDraft draft) {
        draft.setInformation(request.getParameter("name"), request.getParameter("price"), request.getParameter("description"));
        draft.setDates(request.getParameter("startDate"), request.getParameter("endDate"));
        String image=ComboImages.receive(request);
        if (image!=null) draft.setImg(image);
    }
    public static void edit(HttpServletRequest request, ComboDraft draft) {
        String action = Objects.toString(request.getParameter("action"), "");
        switch (action) {
            case "search" -> { }
            case "add" -> {
                long id = Long.parseLong(request.getParameter("dishId"));
                var dish = new DishDAO().getDishbyId(id).orElseThrow(
                    () -> new IllegalArgumentException("Món ăn không tồn tại."));
                long dishSizeId = Long.parseLong(request.getParameter("dishSize_" + id));
                draft.addDish(dish, dishSizeId);
            }
            case "remove" -> draft.removeDish(Long.parseLong(request.getParameter("dishSizeId")));
            case "quantity" -> draft.setQuantity(Long.parseLong(request.getParameter("dishSizeId")),
                Integer.parseInt(request.getParameter("quantity_" + request.getParameter("dishSizeId"))));
            default -> throw new IllegalArgumentException("Thao tác không hợp lệ.");
        }
    }
}
```

### src/main/java/vn/restman/common/ComboImages.java

```java
package vn.restman.common;

import jakarta.servlet.http.*;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.ImageInputStream;

public final class ComboImages {
    private ComboImages() {}
    public static Path directory() {
        return Path.of(System.getProperty("catalina.base")).toAbsolutePath().getParent().resolve("uploads/combo");
    }
    public static String receive(HttpServletRequest request) {
        if (request.getContentType()==null || !request.getContentType().toLowerCase(Locale.ROOT).startsWith("multipart/form-data")) return null;
        try {
            Part part = request.getPart("comboImage");
            if (part==null || part.getSize()==0) return null;
            if (part.getSize()>5*1024*1024) throw new IllegalArgumentException("Ảnh tối đa 5 MB.");
            String extension;
            try (ImageInputStream input=ImageIO.createImageInputStream(part.getInputStream())) {
                var readers=ImageIO.getImageReaders(input);
                if (!readers.hasNext()) throw new IllegalArgumentException("Vui lòng chọn ảnh PNG hoặc JPEG hợp lệ.");
                ImageReader reader=readers.next();
                try {
                    reader.setInput(input);
                    String format=reader.getFormatName().toLowerCase(Locale.ROOT);
                    if (!format.equals("png") && !format.equals("jpeg")) throw new IllegalArgumentException("Chỉ hỗ trợ PNG và JPEG.");
                    if ((long)reader.getWidth(0)*reader.getHeight(0)>20000000) throw new IllegalArgumentException("Ảnh có độ phân giải quá lớn.");
                    reader.read(0); // Verify actual image content, not the supplied filename or MIME type.
                    extension=format.equals("png") ? ".png" : ".jpg";
                } finally { reader.dispose(); }
            }
            Files.createDirectories(directory());
            String name=UUID.randomUUID().toString()+extension;
            try (InputStream input=part.getInputStream()) { Files.copy(input,directory().resolve(name)); }
            return "ComboImage5.jsp?file="+name;
        } catch (IllegalArgumentException ex) { throw ex; }
        catch (Exception ex) { throw new IllegalArgumentException("Không tải được ảnh. Chọn PNG/JPEG tối đa 5 MB."); }
    }
}
```

### src/main/java/vn/restman/common/Text.java

```java
package vn.restman.common;
import java.text.Normalizer;
import java.util.Locale;
public final class Text {
 private Text() {}
 public static String key(String value) { return Normalizer.normalize(value == null ? "" : value.strip(), Normalizer.Form.NFD).replaceAll("\\p{M}", "").replace('đ','d').replace('Đ','D').toLowerCase(Locale.ROOT); }
}
```

### src/main/java/vn/restman/dao/ComboDAO.java

```java
package vn.restman.dao;

import vn.restman.model.*;
import vn.restman.common.Text;
import java.sql.*;
import java.util.*;

/** Persist tblCombo and tblComboDetail in one transaction. */
public final class ComboDAO {
    private static final ComboDAO INSTANCE = new ComboDAO();
    public static ComboDAO getInstance() { return INSTANCE; }
    public List<Combo> getAllCombo() {
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement("SELECT * FROM tblCombo WHERE tblRestaurantid=1 ORDER BY id");
             ResultSet rows = statement.executeQuery()) {
            List<Combo> result = new ArrayList<>();
            while (rows.next()) {
                result.add(readCombo(rows, connection));
            }
            return result;
        } catch (SQLException ex) { throw Database.failure(ex); }
    }
    public Optional<Combo> getComboById(long comboId) {
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement("SELECT * FROM tblCombo WHERE id=? AND tblRestaurantid=1")) {
            statement.setLong(1, comboId);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next() ? Optional.of(readCombo(rows, connection)) : Optional.empty();
            }
        } catch (SQLException ex) { throw Database.failure(ex); }
    }

    /** Name matches the combo or a component dish; type applies to component dishes. */
    public List<Combo> searchCombos(String name, String type) {
        String nameKey = Text.key(name), typeKey = Text.key(type);
        return getAllCombo().stream().filter(combo -> {
            boolean comboNameMatches = Text.key(combo.getName()).contains(nameKey);
            return combo.getItems().stream().anyMatch(item ->
                (typeKey.isEmpty() || Text.key(item.getDish().getType()).equals(typeKey))
                && (comboNameMatches || Text.key(item.getDish().getName()).contains(nameKey)));
        }).toList();
    }

    private Combo readCombo(ResultSet rows, Connection connection) throws SQLException {
        long id = rows.getLong("id");
        List<ComboItem> items = new ArrayList<>();
        try (PreparedStatement details = connection.prepareStatement(
                "SELECT cd.id AS detail_id,cd.quantity,cd.tblDishSizeid,d.* FROM tblComboDetail cd "
                + "JOIN tblDish d ON d.id=cd.tblDishid WHERE cd.tblComboid=? ORDER BY cd.id")) {
            details.setLong(1, id);
            try (ResultSet lines = details.executeQuery()) {
                while (lines.next()) {
                    Dish dish = DishDAO.readDish(lines, connection);
                    long sizeId = lines.getLong("tblDishSizeid");
                    DishSize size = dish.getDishSizes().stream().filter(s -> s.id()==sizeId).findFirst()
                        .orElseThrow(() -> new SQLException("Dish size does not belong to combo dish"));
                    items.add(new ComboItem(lines.getLong("detail_id"), dish, size, lines.getInt("quantity")));
                }
            }
        }
        java.sql.Date start = rows.getDate("startDate"), end = rows.getDate("endDate");
        return new Combo(id, rows.getString("name"), rows.getBigDecimal("price"), rows.getString("description"),
            rows.getString("img"), start==null ? null : start.toLocalDate(), end==null ? null : end.toLocalDate(), items);
    }

    public boolean saveCombo(Combo combo) {
        Objects.requireNonNull(combo);
        try (Connection connection = Database.open()) {
            connection.setAutoCommit(false);
            try {
                // Serialize restaurant saves to check normalized duplicate names without adding a design column.
                try (PreparedStatement lock = connection.prepareStatement("SELECT id FROM tblRestaurant WHERE id=1 FOR UPDATE");
                     ResultSet restaurant = lock.executeQuery()) {
                    if (!restaurant.next()) throw new SQLException("RestMan restaurant is not configured");
                }
                try (PreparedStatement names = connection.prepareStatement("SELECT name FROM tblCombo WHERE tblRestaurantid=1");
                     ResultSet rows = names.executeQuery()) {
                    while (rows.next()) if (Text.key(rows.getString(1)).equals(Text.key(combo.getName())))
                        throw new IllegalArgumentException("Tên combo đã tồn tại.");
                }
                long comboId;
                try (PreparedStatement insert = connection.prepareStatement(
                        "INSERT INTO tblCombo (name,price,description,img,startDate,endDate,tblRestaurantid) VALUES (?,?,?,?,?,?,1)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    insert.setString(1, combo.getName()); insert.setBigDecimal(2, combo.getPrice());
                    insert.setString(3, combo.getDescription()); insert.setString(4, combo.getImg());
                    insert.setDate(5, combo.getStartDate()==null ? null : java.sql.Date.valueOf(combo.getStartDate()));
                    insert.setDate(6, combo.getEndDate()==null ? null : java.sql.Date.valueOf(combo.getEndDate()));
                    insert.executeUpdate();
                    try (ResultSet keys = insert.getGeneratedKeys()) {
                        if (!keys.next()) throw new SQLException("Missing generated combo id");
                        comboId = keys.getLong(1);
                    }
                }
                try (PreparedStatement insert = connection.prepareStatement(
                        "INSERT INTO tblComboDetail (tblDishid,tblDishSizeid,tblComboid,quantity) "
                        + "SELECT ds.tblDishid,ds.id,?,? FROM tblDishSize ds JOIN tblDish d ON d.id=ds.tblDishid "
                        + "WHERE ds.id=? AND ds.tblDishid=? AND d.tblRestaurantid=1")) {
                    for (ComboItem item : combo.getItems()) {
                        insert.setLong(1, comboId); insert.setInt(2, item.getQuantity());
                        insert.setLong(3, item.getDishSize()==null ? -1 : item.getDishSize().id());
                        insert.setLong(4, item.getDish().getId());
                        if (insert.executeUpdate()!=1) throw new SQLException("Dish or dish size no longer exists");
                    }
                }
                connection.commit();
                return true;
            } catch (SQLException | RuntimeException ex) {
                try { connection.rollback(); } catch (SQLException rollback) { ex.addSuppressed(rollback); }
                throw ex;
            }
        } catch (SQLException ex) { throw Database.failure(ex); }
    }
}
```

### src/main/java/vn/restman/dao/Database.java

```java
package vn.restman.dao;

import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.util.Properties;

/** JDBC đọc cấu hình ngoài WAR; không ghi mật khẩu vào mã nguồn. */
public final class Database {
    private Database() {}

    public static Connection open() throws SQLException {
        Properties config = new Properties();
        String configFile = System.getProperty("restman.db.config", System.getenv("RESTMAN_DB_CONFIG"));
        if (configFile != null && !configFile.isBlank()) {
            try (Reader reader = Files.newBufferedReader(Path.of(configFile))) {
                config.load(reader);
            } catch (IOException ex) {
                throw new SQLException("Cannot read RestMan database configuration", ex);
            }
        }
        String url = value("RESTMAN_DB_URL", config, "db.url",
            "jdbc:mysql://127.0.0.1:3306/restman?characterEncoding=UTF-8&connectionTimeZone=Asia/Bangkok&connectTimeout=5000&socketTimeout=10000");
        String user = value("RESTMAN_DB_USER", config, "db.user", "");
        String password = value("RESTMAN_DB_PASSWORD", config, "db.password", "");
        if (user.isBlank()) throw new SQLException("Run scripts/init-db.ps1 before starting RestMan");
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
        catch (ClassNotFoundException ex) { throw new SQLException("MySQL JDBC driver is missing", ex); }
        return DriverManager.getConnection(url, user, password);
    }

    private static String value(String env, Properties config, String key, String fallback) {
        String result = System.getenv(env);
        return result == null ? config.getProperty(key, fallback) : result;
    }

    public static DatabaseException failure(SQLException ex) {
        java.util.logging.Logger.getLogger(Database.class.getName()).log(
            java.util.logging.Level.SEVERE, "RestMan database operation failed", ex);
        return new DatabaseException(
            "Không kết nối hoặc xử lý được dữ liệu MySQL. Kiểm tra MySQL và cấu hình kết nối.", ex);
    }
}
```

### src/main/java/vn/restman/dao/DatabaseException.java

```java
package vn.restman.dao;

/** Lỗi lưu trữ được hiển thị gọn; chi tiết JDBC giữ trong log máy chủ. */
public final class DatabaseException extends RuntimeException {
    public DatabaseException(String message, Throwable cause) { super(message, cause); }
}
```

### src/main/java/vn/restman/dao/DishDAO.java

```java
package vn.restman.dao;

import vn.restman.model.*;
import vn.restman.common.Text;
import java.sql.*;
import java.util.*;

public final class DishDAO {
    public List<Dish> searchDishes(String name, String type) {
        // Search keys stay in Java; the design has no name_key/type_key columns.
        String nameKey = Text.key(name), typeKey = Text.key(type);
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement("SELECT * FROM tblDish WHERE tblRestaurantid=1 ORDER BY id");
             ResultSet rows = statement.executeQuery()) {
            List<Dish> dishes = new ArrayList<>();
            while (rows.next()) {
                if (Text.key(rows.getString("name")).contains(nameKey)
                    && (typeKey.isEmpty() || Text.key(rows.getString("type")).equals(typeKey)))
                    dishes.add(readDish(rows, connection));
            }
            return dishes;
        } catch (SQLException ex) { throw Database.failure(ex); }
    }
    public Optional<Dish> getDishbyId(long dishId) {
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement("SELECT * FROM tblDish WHERE id=? AND tblRestaurantid=1")) {
            statement.setLong(1, dishId);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next() ? Optional.of(readDish(rows, connection)) : Optional.empty();
            }
        } catch (SQLException ex) { throw Database.failure(ex); }
    }
    public List<String> getTypes() {
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement("SELECT type FROM tblDish WHERE tblRestaurantid=1 GROUP BY type ORDER BY MIN(id)");
             ResultSet rows = statement.executeQuery()) {
            List<String> types = new ArrayList<>();
            while (rows.next()) types.add(rows.getString("type"));
            return types;
        } catch (SQLException ex) { throw Database.failure(ex); }
    }
    static Dish readDish(ResultSet rows, Connection connection) throws SQLException {
        long id = rows.getLong("id");
        List<DishSize> sizes = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT ds.id,ds.tblSizeid,s.name,ds.pricePercentage FROM tblDishSize ds JOIN tblSize s ON s.id=ds.tblSizeid "
                + "WHERE ds.tblDishid=? ORDER BY ds.pricePercentage,ds.id")) {
            statement.setLong(1, id);
            try (ResultSet options = statement.executeQuery()) {
                while (options.next()) sizes.add(new DishSize(options.getLong("id"), options.getLong("tblSizeid"),
                    options.getString("name"), options.getBigDecimal("pricePercentage")));
            }
        }
        return new Dish(id, rows.getString("name"), rows.getString("type"), rows.getBigDecimal("basePrice"),
            rows.getString("description"), rows.getString("img"), sizes);
    }
}
```

### src/main/java/vn/restman/model/Combo.java

```java
package vn.restman.model;

import java.util.List;
import java.math.BigDecimal;
import java.time.LocalDate;

/** Combo hoàn chỉnh được đóng gói TRƯỚC khi gọi DAO. Giá bán khác tổng giá tham khảo. */
public final class Combo {
    private final long id;
    private final BigDecimal price;
    private final LocalDate startDate, endDate;
    private final String img;
    private final String name, description;
    private final List<ComboItem> items;

    public Combo(long id, String name, long price, String description, List<ComboItem> items) {
        this(id, name, BigDecimal.valueOf(price), description, null, null, null, items);
    }
    public Combo(long id, String name, BigDecimal price, String description,
                 String img, LocalDate startDate, LocalDate endDate, List<ComboItem> items) {
        if (name == null || name.isBlank() || name.strip().length() > 100)
            throw new IllegalArgumentException("Tên combo phải có từ 1 đến 100 ký tự.");
        if (price == null || price.signum() <= 0 || price.scale() > 2 || price.precision() - price.scale() > 16)
            throw new IllegalArgumentException("Giá bán phải lớn hơn 0, tối đa 2 chữ số thập phân.");
        if (description != null && description.length() > 255)
            throw new IllegalArgumentException("Mô tả tối đa 255 ký tự.");
        if ((startDate == null) != (endDate == null) || startDate != null && startDate.isAfter(endDate))
            throw new IllegalArgumentException("Nhập cả hai ngày; ngày bắt đầu không được sau ngày kết thúc.");
        if (items == null || items.isEmpty()) throw new IllegalArgumentException("Vui lòng chọn ít nhất một món.");
        this.id = id; this.name = name.strip(); this.price = price;
        this.description = description == null ? "" : description.strip();
        this.img = img;
        this.startDate = startDate; this.endDate = endDate;
        this.items = List.copyOf(items);
    }
    public long getId() { return id; }
    public String getName() { return name; }
    public BigDecimal getPrice() { return price; }
    public String getImg() { return img; }
    public LocalDate getStartDate() { return startDate; }
    public LocalDate getEndDate() { return endDate; }
    public String getDescription() { return description; }
    public List<ComboItem> getItems() { return items; }
    public BigDecimal getReferenceTotal() { return items.stream().map(ComboItem::getSubtotal).reduce(BigDecimal.ZERO, BigDecimal::add); }
}
```

### src/main/java/vn/restman/model/ComboDraft.java

```java
package vn.restman.model;

import java.util.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

/** Thuộc tính ẩn của AddComboUI: session.comboDraft.
 * Danh sách được giữ trên server; client chỉ gửi draftId và dishId của thao tác.
 */
public final class ComboDraft {
    private final String id = UUID.randomUUID().toString();
    private String name = "", price = "", description = "";
    private String startDate = "", endDate = "";
    private String img;
    public String getImg() { return img; }
    public void setImg(String img) { this.img = img; }
    private final Map<Long, ComboItem> items = new LinkedHashMap<>();
    private final Map<Long, Long> sizeChoices = new HashMap<>();

    public String getId() { return id; }
    public String getName() { return name; }
    public String getPrice() { return price; }
    public String getDescription() { return description; }
    public String getStartDate() { return startDate; }
    public String getEndDate() { return endDate; }
    public void setDates(String startDate, String endDate) {
        this.startDate = Objects.toString(startDate, "").strip();
        this.endDate = Objects.toString(endDate, "").strip();
    }
    public List<ComboItem> getItems() { return List.copyOf(items.values()); }
    public Map<Long, Long> getSizeChoices() { return Map.copyOf(sizeChoices); }
    public void setInformation(String name, String price, String description) {
        this.name = Objects.toString(name, "");
        this.price = Objects.toString(price, "");
        this.description = Objects.toString(description, "");
    }
    public void addDish(Dish dish) {
        DishSize size = dish.getDefaultDishSize();
        if (size == null) throw new IllegalArgumentException("Món ăn chưa có size để chọn.");
        addDish(dish, size.id());
    }
    public void addDish(Dish dish, long dishSizeId) {
        DishSize size = dish.getDishSizes().stream().filter(s -> s.id() == dishSizeId).findFirst()
            .orElseThrow(() -> new IllegalArgumentException("Size không thuộc món ăn đã chọn."));
        ComboItem old = items.get(dishSizeId);
        items.put(dishSizeId, new ComboItem(0, dish, size, old == null ? 1 : old.getQuantity() + 1));
        sizeChoices.put(dish.getId(), dishSizeId);
    }
    public void removeDish(long dishSizeId) { items.remove(dishSizeId); }
    public void setQuantity(long dishSizeId, int quantity) {
        ComboItem old = items.get(dishSizeId);
        if (old == null) throw new IllegalArgumentException("Món không nằm trong combo đang lập.");
        items.put(dishSizeId, new ComboItem(old.getId(), old.getDish(), old.getDishSize(), quantity));
    }
    public Combo toCombo() {
        BigDecimal amount;
        try {
            if (!price.strip().matches("[0-9]{1,15}(\\.[0-9]{1,2})?")) throw new NumberFormatException();
            amount = new BigDecimal(price.strip());
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Giá bán phải lớn hơn 0, tối đa 15 chữ số nguyên và 2 chữ số thập phân.");
        }
        try {
            LocalDate start = startDate.isEmpty() ? null : LocalDate.parse(startDate);
            LocalDate end = endDate.isEmpty() ? null : LocalDate.parse(endDate);
            if (start != null && (start.getYear() < 1000 || start.getYear() > 9999)
                || end != null && (end.getYear() < 1000 || end.getYear() > 9999))
                throw new IllegalArgumentException("Ngày phải nằm trong khoảng năm 1000 đến 9999.");
            return new Combo(0, name, amount, description, img, start, end, getItems());
        } catch (DateTimeParseException ex) {
            throw new IllegalArgumentException("Ngày bắt đầu hoặc ngày kết thúc không hợp lệ.");
        }
    }
}
```

### src/main/java/vn/restman/model/ComboItem.java

```java
package vn.restman.model;

import java.util.Objects;
import java.math.BigDecimal;
import java.math.RoundingMode;

/** Một dòng món đã chọn; đóng gói đối tượng Dish, không chỉ lưu tên hiển thị. */
public final class ComboItem {
    private final Dish dish;
    private final int quantity;
    private final long id;
    private final DishSize dishSize;

    public ComboItem(Dish dish, int quantity) {
        this(0, dish, dish.getDefaultDishSize(), quantity);
    }
    public ComboItem(long id, Dish dish, DishSize dishSize, int quantity) {
        this.dish = Objects.requireNonNull(dish);
        if (quantity < 1 || quantity > 999) throw new IllegalArgumentException("Số lượng phải từ 1 đến 999.");
        this.quantity = quantity;
        this.id = id; this.dishSize = dishSize;
    }
    public Dish getDish() { return dish; }
    public int getQuantity() { return quantity; }
    public long getId() { return id; }
    public DishSize getDishSize() { return dishSize; }
    public BigDecimal getUnitPrice() {
        return dishSize == null ? dish.getPrice().setScale(2, RoundingMode.HALF_UP) : dishSize.priceFor(dish.getPrice());
    }
    public BigDecimal getSubtotal() {
        return getUnitPrice().multiply(BigDecimal.valueOf(quantity));
    }
}
```

### src/main/java/vn/restman/model/Dish.java

```java
package vn.restman.model;
import java.math.BigDecimal;
import java.util.List;

/** Thực thể món ăn dùng chung cho cả hai module. */
public final class Dish {
    private final long id;
    private final String name, type, description, image;
    private final BigDecimal price;
    private final List<DishSize> dishSizes;

    public Dish(long id, String name, String type, long price, String description) {
        this(id, name, type, price, description, null);
    }

    public Dish(long id, String name, String type, long price, String description, String image) {
        this(id, name, type, BigDecimal.valueOf(price), description, image, List.of());
    }
    public Dish(long id, String name, String type, BigDecimal price, String description, String image, List<DishSize> dishSizes) {
        this.id = id; this.name = name; this.type = type;
        this.price = price; this.description = description;
        this.dishSizes = List.copyOf(dishSizes);
        this.image = image != null && !image.isBlank() ? image : "assets/images/" + (type.equals("Tráng miệng") ? "dessert" :
            type.equals("Đồ uống") ? "drink" : type.equals("Khai vị") || type.equals("Súp") ?
            "salad" : id == 2 || id == 12 ? "seafood" : "steak") + ".jpg";
    }
    public long getId() { return id; }
    public String getName() { return name; }
    public String getType() { return type; }
    public String getCategory() { return type; }
    public BigDecimal getPrice() { return price; }
    public BigDecimal getBasePrice() { return price; }
    public String getImg() { return image; }
    public List<DishSize> getDishSizes() { return dishSizes; }
    public List<DishSizePrice> getSizePrices() {
        return dishSizes.stream().map(size -> new DishSizePrice(size.id(), size.name(), size.pricePercentage(), size.priceFor(price))).toList();
    }
    public DishSize getDefaultDishSize() {
        return dishSizes.stream().filter(size -> size.pricePercentage().compareTo(new BigDecimal("100")) == 0)
            .findFirst().orElse(dishSizes.isEmpty() ? null : dishSizes.get(0));
    }
    public BigDecimal getMinPrice() { return getSizePrices().stream().map(DishSizePrice::price).min(BigDecimal::compareTo).orElse(price); }
    public BigDecimal getMaxPrice() { return getSizePrices().stream().map(DishSizePrice::price).max(BigDecimal::compareTo).orElse(price); }
    public String getDescription() { return description; }
    public String getImage() { return image; }
}
```

### src/main/java/vn/restman/model/DishSize.java

```java
package vn.restman.model;

import java.math.BigDecimal;
import java.math.RoundingMode;

/** A size option persisted in tblDishSize and tblSize. */
public record DishSize(long id, long sizeId, String name, BigDecimal pricePercentage) {
    public DishSize {
        if (pricePercentage == null || pricePercentage.signum() <= 0)
            throw new IllegalArgumentException("Tỷ lệ giá theo size phải lớn hơn 0.");
    }
    public long getId() { return id; }
    public String getName() { return name; }
    public BigDecimal getPricePercentage() { return pricePercentage; }
    public BigDecimal priceFor(BigDecimal basePrice) {
        return basePrice.multiply(pricePercentage).movePointLeft(2).setScale(2, RoundingMode.HALF_UP);
    }
}
```

### src/main/java/vn/restman/model/DishSizePrice.java

```java
package vn.restman.model;

import java.math.BigDecimal;

/** Display data computed from tblDish.basePrice and tblDishSize.pricePercentage. */
public record DishSizePrice(long id, String name, BigDecimal pricePercentage, BigDecimal price) {
    public long getId() { return id; }
    public String getName() { return name; }
    public BigDecimal getPricePercentage() { return pricePercentage; }
    public BigDecimal getPrice() { return price; }
}
```

### src/main/webapp/assets/combo-image.js

```javascript
(() => {
    const input=document.getElementById('comboImage');
    const preview=document.getElementById('comboImagePreview');
    if (!input || !preview) return;
    const previous=preview.getAttribute('src');
    let temporary;
    input.addEventListener('change', () => {
        if (temporary) URL.revokeObjectURL(temporary);
        const file=input.files[0];
        if (file && (file.size>5*1024*1024 || !['image/png','image/jpeg'].includes(file.type))) {
            input.value=''; alert('Chọn ảnh PNG hoặc JPEG tối đa 5 MB.');
            preview.src=previous; preview.hidden=!previous; return;
        }
        preview.src=file ? (temporary=URL.createObjectURL(file)) : previous;
        preview.hidden=!file && !previous;
    });
})();
```

### src/main/webapp/assets/dish-detail.js

```javascript
(() => {
    const select = document.getElementById('dishSizeId');
    if (!select) return;
    select.addEventListener('change', () => {
        const option = select.selectedOptions[0];
        if (!option) return;
        const price = document.getElementById('outPrice');
        const name = document.getElementById('currentSizeName');
        if (!price || !name) {
            select.form.requestSubmit();
            return;
        }
        // Use the exact formatted database price rendered by JSP; no floating-point calculation.
        price.textContent = option.dataset.price;
        name.textContent = option.dataset.size;
        const url = new URL(window.location.href);
        url.searchParams.set('dishSizeId', option.value);
        window.history.replaceState(null, '', url);
    });
})();
```

## 10. Cấu hình request và lỗi — web.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="https://jakarta.ee/xml/ns/jakartaee" version="6.0">
    <display-name>RestMan</display-name>
    <servlet><servlet-name>comboEditor</servlet-name><jsp-file>/AddComboUI5.jsp</jsp-file><multipart-config><max-file-size>5242880</max-file-size><max-request-size>7340032</max-request-size><file-size-threshold>0</file-size-threshold></multipart-config></servlet>
    <servlet><servlet-name>comboSave</servlet-name><jsp-file>/doSaveCombo5.jsp</jsp-file><multipart-config><max-file-size>5242880</max-file-size><max-request-size>7340032</max-request-size><file-size-threshold>0</file-size-threshold></multipart-config></servlet>
    <servlet-mapping><servlet-name>comboEditor</servlet-name><url-pattern>/AddComboUI5.jsp</url-pattern></servlet-mapping>
    <servlet-mapping><servlet-name>comboSave</servlet-name><url-pattern>/doSaveCombo5.jsp</url-pattern></servlet-mapping>
    <session-config>
        <session-timeout>30</session-timeout>
        <cookie-config><http-only>true</http-only></cookie-config>
    </session-config>
    <welcome-file-list><welcome-file>index5.jsp</welcome-file></welcome-file-list>
    <request-character-encoding>UTF-8</request-character-encoding>
    <error-page>
        <exception-type>vn.restman.dao.DatabaseException</exception-type>
        <location>/WEB-INF/views/shared/database-error5.jsp</location>
    </error-page>
    <response-character-encoding>UTF-8</response-character-encoding>
</web-app>
```
