<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="WEB-INF/views/shared/head.jspf" %>
<main id="main" class="container page-shell">
    <h1>
        Hệ thống quản lý nhà hàng
    </h1>
    <p>
        Chọn chức năng:
    </p>
    <ul class="home-links">
        <li class="mb-2">
            <a href="${pageContext.request.contextPath}/MainCustomerUI5.jsp">
                Khách hàng - Tìm kiếm món ăn
            </a>
        </li>
        <li>
            <a href="${pageContext.request.contextPath}/MainStaffUI5.jsp">
                Nhân viên - Quản lý combo
            </a>
        </li>
    </ul>
</main>
<%@ include file="WEB-INF/views/shared/footer.jspf" %>
