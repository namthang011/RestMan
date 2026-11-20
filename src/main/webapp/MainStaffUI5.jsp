<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="area" value="staff"/>
<%@ include file="WEB-INF/views/shared/head.jspf" %>
<main id="main" class="container page-shell">
    <h1>
        Trang chính nhân viên quản lý
    </h1>
    <a id="subManageCombo" class="btn btn-primary" href="ComboListUI5.jsp">
        Quản lý combo
    </a>
</main>
<%@ include file="WEB-INF/views/shared/footer.jspf" %>
