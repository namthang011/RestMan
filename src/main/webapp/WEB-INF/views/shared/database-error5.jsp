<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ include file="head.jspf" %>
<main id="main" class="container page-shell">
    <h1>
        Chưa truy cập được cơ sở dữ liệu
    </h1>
    <p>
        Vui lòng kiểm tra MySQL đang chạy và đã khởi tạo database RestMan.
    </p>
    <a class="btn btn-primary" href="${pageContext.request.contextPath}/">
        Về trang chủ
    </a>
</main>
<%@ include file="footer.jspf" %>
