<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="vn.restman.dao.DishDAO,vn.restman.dao.ComboDAO" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    DishDAO dishDAO = new DishDAO();
    boolean searched = request.getParameter("search") != null || request.getParameter("name") != null || request.getParameter("type") != null;
    request.setAttribute("types", dishDAO.getTypes());
    request.setAttribute("searched", searched);
    request.setAttribute("listDish", searched ? dishDAO.searchDishes(request.getParameter("name"), request.getParameter("type")) : java.util.List.of());
    request.setAttribute("listCombo", searched ? new ComboDAO().searchCombos(request.getParameter("name"), request.getParameter("type")) : java.util.List.of());
%>
<c:set var="area" value="customer"/>
<%@ include file="WEB-INF/views/shared/head.jspf" %>
<main id="main" class="container page-shell page-wide search-page">
    <a href="MainCustomerUI5.jsp" class="back-link">
        Về trang chính khách hàng
    </a>
    <h1>
        Tìm kiếm món ăn và combo
    </h1>
    <form method="get" action="SearchDishUI5.jsp" class="search-toolbar" id="searchDishForm" aria-label="Tìm kiếm món ăn và combo">
        <div class="search-name">
            <label class="visually-hidden" for="inName">
                Tên món ăn hoặc combo
            </label>
            <input id="inName" name="name" class="form-control" placeholder="Tên món ăn hoặc combo" maxlength="100" value="<c:out value='${param.name}'/>">
        </div>
        <div>
            <label for="inType" class="visually-hidden">
                Thể loại món ăn
            </label>
            <select id="inType" name="type" class="form-select">
                <option value="">
                    Tất cả thể loại
                </option>
                <c:forEach items="${types}" var="type">
                    <option value="<c:out value='${type}'/>" ${param.type == type ? 'selected' : ''}>
                        <c:out value="${type}"/>
                    </option>
                </c:forEach>
            </select>
        </div>
        <button id="subSearch" name="search" value="1" class="btn btn-primary">
            Tìm kiếm
        </button>
    </form>
    <c:choose>
        <c:when test="${searched}">
            <div class="results-heading">
                <h2>
                    Kết quả tìm kiếm
                </h2>
                <p role="status">
                    <strong>
                        ${listDish.size()}
                    </strong>
                    món ăn ·
                    <strong>
                        ${listCombo.size()}
                    </strong>
                    combo
                </p>
            </div>
            <section class="result-section" aria-labelledby="dishResultsTitle">
                <h3 id="dishResultsTitle">
                    Món ăn
                    <span class="result-count">
                        ${listDish.size()}
                    </span>
                </h3>
                <c:choose>
                    <c:when test="${not empty listDish}">
                        <div class="table-scroll" tabindex="0" role="region" aria-label="Kết quả món ăn">
                            <table id="outDishList" class="table results-table">
                                <caption class="visually-hidden">
                                    Danh sách món ăn phù hợp
                                </caption>
                                <thead>
                                    <tr>
                                        <th scope="col">
                                            Tên món ăn
                                        </th>
                                        <th scope="col">
                                            Thể loại
                                        </th>
                                        <th scope="col" class="numeric">
                                            Khoảng giá theo size (VNĐ)
                                        </th>
                                        <th scope="col">
                                            Thao tác
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach items="${listDish}" var="dish">
                                        <tr>
                                            <td class="name-cell">
                                                <div class="result-name">
                                                    <img src="${pageContext.request.contextPath}/<c:out value='${dish.image}'/>" alt="" title="Ảnh minh họa món ăn" width="64" height="48" loading="lazy" decoding="async">
                                                    <span>
                                                        <c:out value="${dish.name}"/>
                                                    </span>
                                                </div>
                                            </td>
                                            <td>
                                                <c:out value="${dish.type}"/>
                                            </td>
                                            <td class="numeric">
                                                <fmt:formatNumber value="${dish.minPrice}"/>
                                                <c:if test="${dish.minPrice != dish.maxPrice}">
                                                    –
                                                    <fmt:formatNumber value="${dish.maxPrice}"/>
                                                </c:if>
                                            </td>
                                            <td>
                                                <form method="get" action="DishDetailUI5.jsp">
                                                    <input type="hidden" name="dishId" value="${dish.id}">
                                                    <input type="hidden" name="name" value="<c:out value='${param.name}'/>">
                                                    <input type="hidden" name="type" value="<c:out value='${param.type}'/>">
                                                    <button class="btn btn-outline-success btn-sm" type="submit">
                                                        Xem chi tiết
                                                    </button>
                                                </form>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <p class="empty-state">
                            Không tìm thấy món ăn phù hợp.
                        </p>
                    </c:otherwise>
                </c:choose>
            </section>
            <section class="result-section" aria-labelledby="comboResultsTitle">
                <h3 id="comboResultsTitle">
                    Combo
                    <span class="result-count">
                        ${listCombo.size()}
                    </span>
                </h3>
                <c:choose>
                    <c:when test="${not empty listCombo}">
                        <div class="table-scroll" tabindex="0" role="region" aria-label="Kết quả combo">
                            <table id="outComboSearchList" class="table results-table">
                                <caption class="visually-hidden">
                                    Danh sách combo phù hợp
                                </caption>
                                <thead>
                                    <tr>
                                        <th scope="col">
                                            Tên combo
                                        </th>
                                        <th scope="col" class="numeric">
                                            Số món thành phần
                                        </th>
                                        <th scope="col" class="numeric">
                                            Giá bán (VNĐ)
                                        </th>
                                        <th scope="col">
                                            Thao tác
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach items="${listCombo}" var="combo">
                                        <c:set var="comboImage" value="${empty combo.img ? combo.items[0].dish.image : combo.img}"/>
                                        <tr>
                                            <td class="name-cell">
                                                <div class="result-name">
                                                    <img src="${pageContext.request.contextPath}/<c:out value='${comboImage}'/>" alt="" title="Ảnh minh họa combo" width="64" height="48" loading="lazy" decoding="async">
                                                    <span>
                                                        <c:out value="${combo.name}"/>
                                                    </span>
                                                </div>
                                            </td>
                                            <td class="numeric">
                                                ${combo.items.size()}
                                            </td>
                                            <td class="numeric">
                                                <fmt:formatNumber value="${combo.price}"/>
                                            </td>
                                            <td>
                                                <form method="get" action="ComboDetailUI5.jsp">
                                                    <input type="hidden" name="comboId" value="${combo.id}">
                                                    <input type="hidden" name="name" value="<c:out value='${param.name}'/>">
                                                    <input type="hidden" name="type" value="<c:out value='${param.type}'/>">
                                                    <button class="btn btn-outline-success btn-sm" type="submit">
                                                        Xem chi tiết combo
                                                    </button>
                                                </form>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <p class="empty-state">
                            Không tìm thấy combo phù hợp.
                        </p>
                    </c:otherwise>
                </c:choose>
            </section>
        </c:when>
        <c:otherwise>
            <p class="empty-state">
                Nhập tên hoặc chọn thể loại rồi bấm Tìm kiếm. Để trống cả hai để xem tất cả món ăn và combo.
            </p>
        </c:otherwise>
    </c:choose>
</main>
<%@ include file="WEB-INF/views/shared/footer.jspf" %>
