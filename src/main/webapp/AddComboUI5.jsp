<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="vn.restman.common.ComboFlow,vn.restman.dao.DishDAO,vn.restman.model.ComboDraft" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
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
%>
<c:set var="area" value="staff"/>
<%@ include file="WEB-INF/views/shared/head.jspf" %>
<main id="main" class="container page-shell page-wide combo-editor">
    <a class="back-link" href="ComboListUI5.jsp">
        Về danh sách combo
    </a>
    <h1>
        Thêm combo mới
    </h1>
    <p>
        Tìm món, chọn size theo giá hiển thị, rồi nhập thông tin và xác nhận lưu combo.
    </p>
    <c:if test="${not empty error}">
        <div id="outError" class="alert alert-danger" role="alert">
            <c:out value="${error}"/>
        </div>
    </c:if>
    <form id="editor" method="post" action="AddComboUI5.jsp" enctype="multipart/form-data">
        <%-- Thuộc tính ẩn trên HTML: định danh bản nháp và token; danh sách thật nằm trong session. --%>
        <input type="hidden" name="draftId" value="${draft.id}">
        <input type="hidden" name="csrf" value="${sessionScope.csrf}">
        <section class="card p-4 mb-4">
            <h2>
                1. Tìm món ăn
            </h2>
            <div class="row g-3">
                <div class="col-md-6">
                    <label for="inDishName" class="form-label">
                        Tên món ăn
                    </label>
                    <input id="inDishName" name="dishName" maxlength="100" class="form-control" value="<c:out value='${dishName}'/>">
                </div>
                <div class="col-md-4">
                    <label for="inDishType" class="form-label">
                        Thể loại
                    </label>
                    <select id="inDishType" name="dishType" class="form-select">
                        <option value="">
                            Tất cả thể loại
                        </option>
                        <c:forEach items="${types}" var="type">
                            <option value="<c:out value='${type}'/>" ${dishType == type ? 'selected' : ''}>
                                <c:out value="${type}"/>
                            </option>
                        </c:forEach>
                    </select>
                </div>
                <div class="col-md-2 d-flex align-items-end">
                    <button id="subSearch" name="action" value="search" class="btn btn-primary" formnovalidate>
                        Tìm kiếm
                    </button>
                </div>
            </div>
            <p class="small mt-2">
                Nhập tên hoặc chọn thể loại. Có thể kết hợp cả hai điều kiện.
            </p>
            <div class="table-scroll" tabindex="0" role="region" aria-label="Bảng dữ liệu">
                <table class="table" id="outDishList">
                    <thead>
                        <tr>
                            <th>
                                Món ăn
                            </th>
                            <th>
                                Thể loại
                            </th>
                            <th>
                                Kích cỡ — Giá (VNĐ)
                            </th>
                            <th>
                                Chọn
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach items="${listDish}" var="dish">
                            <tr>
                                <td>
                                    <c:out value="${dish.name}"/>
                                </td>
                                <td>
                                    <c:out value="${dish.type}"/>
                                </td>
                                <td>
                                    <label class="visually-hidden" for="dishSize-${dish.id}">
                                        Chọn size
                                        <c:out value="${dish.name}"/>
                                    </label>
                                    <select id="dishSize-${dish.id}" name="dishSize_${dish.id}" class="form-select size-select">
                                        <c:forEach items="${dish.sizePrices}" var="size">
                                            <option value="${size.id}" ${(empty draft.sizeChoices[dish.id] and dish.defaultDishSize.id == size.id) or draft.sizeChoices[dish.id] == size.id ? 'selected' : ''}>
                                                <c:out value="${size.name}"/>
                                                —
                                                <fmt:formatNumber value="${size.price}"/>
                                            </option>
                                        </c:forEach>
                                    </select>
                                </td>
                                <td>
                                    <%-- dishId là ID ẩn gắn với nút dòng; không dùng số thứ tự dòng làm khóa. --%>
                                    <button class="btn btn-outline-success btn-sm" name="dishId" value="${dish.id}" formaction="AddComboUI5.jsp?action=add" ${empty dish.sizePrices ? 'disabled' : ''} formnovalidate>
                                        Thêm món
                                    </button>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
            <c:if test="${sessionScope.comboSearched and empty listDish}">
                <p role="status">
                    Không tìm thấy món ăn phù hợp.
                </p>
            </c:if>
            <c:if test="${not sessionScope.comboSearched}">
                <p>
                    Nhấn Tìm kiếm để lấy danh sách món ăn.
                </p>
            </c:if>
        </section>
        <section class="card p-4 mb-4">
            <h2>
                2. Danh sách món đã chọn
            </h2>
            <div class="table-scroll" tabindex="0" role="region" aria-label="Bảng dữ liệu">
                <table class="table" id="outComboItems">
                    <thead>
                        <tr>
                            <th>
                                Món ăn
                            </th>
                            <th>
                                Kích cỡ
                            </th>
                            <th class="numeric">
                                Đơn giá (VNĐ)
                            </th>
                            <th class="numeric">
                                Số lượng
                            </th>
                            <th class="numeric">
                                Thành tiền (VNĐ)
                            </th>
                            <th>
                                Thao tác
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:set var="referenceTotal" value="0"/>
                        <c:forEach items="${draft.items}" var="item">
                            <tr>
                                <td>
                                    <c:out value="${item.dish.name}"/>
                                </td>
                                <td>
                                    <c:out value="${item.dishSize.name}"/>
                                </td>
                                <td class="numeric">
                                    <fmt:formatNumber value="${item.unitPrice}"/>
                                </td>
                                <td class="numeric quantity-cell">
                                    <label class="visually-hidden" for="quantity-${item.dishSize.id}">
                                        Số lượng
                                        <c:out value="${item.dish.name}"/>
                                    </label>
                                    <input id="quantity-${item.dishSize.id}" name="quantity_${item.dishSize.id}" type="number" min="1" max="999" value="${item.quantity}" class="form-control quantity-input">
                                    <button name="dishSizeId" value="${item.dishSize.id}" formaction="AddComboUI5.jsp?action=quantity" class="btn btn-link btn-sm" formnovalidate>
                                        Cập nhật
                                    </button>
                                </td>
                                <td class="numeric">
                                    <fmt:formatNumber value="${item.subtotal}"/>
                                </td>
                                <td>
                                    <button class="btn btn-outline-danger btn-sm" name="dishSizeId" value="${item.dishSize.id}" formaction="AddComboUI5.jsp?action=remove" formnovalidate>
                                        Bỏ món
                                    </button>
                                </td>
                            </tr>
                            <c:set var="referenceTotal" value="${referenceTotal + item.subtotal}"/>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
            <c:if test="${empty draft.items}">
                <p>
                    Chưa chọn món nào.
                </p>
            </c:if>
            <p>
                Tổng giá món tham khảo (VNĐ):
                <strong>
                    <fmt:formatNumber value="${referenceTotal}"/>
                </strong>
            </p>
            <p class="small">
                Có thể tìm tiếp mà vẫn giữ các món đã chọn. Chọn lại cùng món và cùng size sẽ tăng số lượng. Cùng món khác size được giữ thành hai dòng riêng.
            </p>
        </section>
        <section class="card p-4 mb-4">
            <h2>
                3. Thông tin combo
            </h2>
            <label for="comboImage" class="form-label">
                Ảnh combo
            </label>
            <input id="comboImage" name="comboImage" type="file" accept="image/png,image/jpeg" class="form-control mb-2">
            <p class="small">
                Chọn ảnh PNG hoặc JPEG, tối đa 5 MB.
            </p>
            <img id="comboImagePreview" src="${empty draft.img ? '' : pageContext.request.contextPath.concat('/').concat(draft.img)}" alt="Ảnh combo đã chọn" style="max-width:260px;max-height:180px;object-fit:cover;border-radius:8px;margin-bottom:16px" ${empty draft.img ? 'hidden' : ''}>
            <label for="inComboName" class="form-label">
                Tên combo *
            </label>
            <input id="inComboName" name="name" required maxlength="100" class="form-control mb-3" value="<c:out value='${draft.name}'/>">
            <label for="inPrice" class="form-label">
                Giá bán combo (VNĐ) *
            </label>
            <input id="inPrice" name="price" type="number" min="0.01" max="999999999999999.99" step="0.01" required class="form-control mb-2" value="<c:out value='${draft.price}'/>">
            <p class="small">
                Nhập giá bán của combo. Tổng giá món chỉ để tham khảo.
            </p>
            <div class="row g-3 mb-3">
                <div class="col-md-6">
                    <label for="inStartDate" class="form-label">
                        Ngày bắt đầu
                    </label>
                    <input id="inStartDate" name="startDate" type="date" min="1000-01-01" max="9999-12-31" class="form-control" value="<c:out value='${draft.startDate}'/>">
                </div>
                <div class="col-md-6">
                    <label for="inEndDate" class="form-label">
                        Ngày kết thúc
                    </label>
                    <input id="inEndDate" name="endDate" type="date" min="1000-01-01" max="9999-12-31" class="form-control" value="<c:out value='${draft.endDate}'/>">
                </div>
            </div>
            <p class="small">
                Có thể bỏ trống cả hai ngày. Nếu đặt thời hạn, nhập đủ ngày bắt đầu và ngày kết thúc.
            </p>
            <label for="inDescription" class="form-label">
                Mô tả
            </label>
            <textarea id="inDescription" name="description" maxlength="255" class="form-control mb-3"><c:out value="${draft.description}"/></textarea>
            <button id="subSaveCombo" class="btn btn-primary" formaction="doSaveCombo5.jsp" name="action" value="save">
                Xác nhận lưu combo
            </button>
            <button class="btn btn-outline-danger" formaction="doSaveCombo5.jsp" name="action" value="cancel" formnovalidate>
                Hủy bản nháp
            </button>
        </section>
    </form>
</main>
<script src="${pageContext.request.contextPath}/assets/combo-image.js?v=1"></script>
<%@ include file="WEB-INF/views/shared/footer.jspf" %>
