<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="vn.restman.dao.DishDAO,vn.restman.model.Dish,vn.restman.model.DishSizePrice" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
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
%>
<c:set var="area" value="customer"/>
<%@ include file="WEB-INF/views/shared/head.jspf" %>
<main id="main" class="container page-shell dish-detail-page">
    <c:url var="back" value="/SearchDishUI5.jsp">
        <c:param name="search" value="1"/>
        <c:param name="name" value="${param.name}"/>
        <c:param name="type" value="${param.type}"/>
    </c:url>
    <a id="subBack" class="back-link" href="<c:out value='${back}'/>">
        Quay lại kết quả tìm kiếm
    </a>
    <c:choose>
        <c:when test="${not empty dish}">
            <article class="detail-layout">
                <div class="detail-image">
                    <img src="${pageContext.request.contextPath}/<c:out value='${dish.image}'/>" alt="Hình minh họa món ăn">
                </div>
                <div class="detail-content">
                    <h1 id="outName">
                        <c:out value="${dish.name}"/>
                    </h1>
                    <p id="outType">
                        Thể loại:
                        <c:out value="${dish.type}"/>
                    </p>
                    <p id="outDescription">
                        <c:out value="${dish.description}"/>
                    </p>
                    <c:if test="${not empty sizeError}">
                        <p class="alert alert-danger" role="alert">
                            <c:out value="${sizeError}"/>
                        </p>
                    </c:if>
                    <c:if test="${not empty selectedSize}">
                        <p class="detail-price-label">
                            Giá size
                            <span id="currentSizeName">
                                <c:out value="${selectedSize.name}"/>
                            </span>
                            (VNĐ)
                        </p>
                        <p id="outPrice" class="numeric price" aria-live="polite">
                            <fmt:formatNumber value="${selectedSize.price}"/>
                        </p>
                    </c:if>
                    <form method="get" action="DishDetailUI5.jsp" class="size-price-form">
                        <input type="hidden" name="dishId" value="${dish.id}">
                        <input type="hidden" name="name" value="<c:out value='${param.name}'/>">
                        <input type="hidden" name="type" value="<c:out value='${param.type}'/>">
                        <div>
                            <label for="dishSizeId" class="form-label">
                                Chọn kích cỡ
                            </label>
                            <select id="dishSizeId" name="dishSizeId" class="form-select size-select">
                                <c:forEach items="${dish.sizePrices}" var="size">
                                    <fmt:formatNumber value="${size.price}" var="sizePrice"/>
                                    <option value="${size.id}" data-price="<c:out value='${sizePrice}'/>" data-size="<c:out value='${size.name}'/>" ${selectedSize.id == size.id ? 'selected' : ''}>
                                        <c:out value="${size.name}"/>
                                        —
                                        <c:out value="${sizePrice}"/>
                                        VNĐ
                                    </option>
                                </c:forEach>
                            </select>
                        </div>
                    </form>
                </div>
            </article>
        </c:when>
        <c:otherwise>
            <h1>
                Không tìm thấy món ăn
            </h1>
            <p>
                Mã món ăn không hợp lệ hoặc món ăn không còn tồn tại.
            </p>
        </c:otherwise>
    </c:choose>
</main>
<script src="${pageContext.request.contextPath}/assets/dish-detail.js?v=1"></script>
<%@ include file="WEB-INF/views/shared/footer.jspf" %>
