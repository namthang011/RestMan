<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="area" value="customer"/>
<%@ include file="WEB-INF/views/shared/head.jspf" %>
<main id="main" class="container page-shell">
    <h1>
        Trang chính khách hàng
    </h1>
    <p>
        Tra cứu món ăn, combo và danh sách món thành phần.
    </p>
    <a id="subSearchDish" class="btn btn-primary" href="SearchDishUI5.jsp">
        Tìm kiếm món ăn và combo
    </a>
</main>
<%@ include file="WEB-INF/views/shared/footer.jspf" %>
