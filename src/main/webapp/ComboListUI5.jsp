<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="vn.restman.dao.ComboDAO" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<% request.setAttribute("listCombo", ComboDAO.getInstance().getAllCombo());
   request.setAttribute("success", session.getAttribute("success")); session.removeAttribute("success"); %>
<c:set var="area" value="staff"/>
<%@ include file="WEB-INF/views/shared/head.jspf" %>
<main id="main" class="container page-shell page-wide">
    <a class="back-link" href="MainStaffUI5.jsp">
        Về trang chính nhân viên
    </a>
    <div class="staff-heading">
        <h1>
            Danh sách combo
        </h1>
        <a id="subAddCombo" class="btn btn-primary" href="AddComboUI5.jsp">
            Thêm combo mới
        </a>
    </div>
    <c:if test="${not empty success}">
        <p class="alert alert-success" role="status">
            <c:out value="${success}"/>
        </p>
    </c:if>
    <section class="section-panel" aria-labelledby="comboListTitle">
        <h2 id="comboListTitle">
            Các combo đã lưu
        </h2>
        <div class="table-scroll" tabindex="0" role="region" aria-label="Danh sách combo">
            <table id="outComboList" class="table">
                <thead>
                    <tr>
                        <th scope="col" class="numeric">
                            Mã
                        </th>
                        <th scope="col">
                            Tên combo
                        </th>
                        <th scope="col" class="numeric">
                            Giá bán (VNĐ)
                        </th>
                        <th scope="col">
                            Thời hạn
                        </th>
                        <th scope="col" class="numeric">
                            Số món thành phần
                        </th>
                        <th scope="col">
                            Thao tác
                        </th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach items="${listCombo}" var="combo">
                        <tr>
                            <td class="numeric">
                                ${combo.id}
                            </td>
                            <td class="name-cell">
                                <c:out value="${combo.name}"/>
                            </td>
                            <td class="numeric">
                                <fmt:formatNumber value="${combo.price}"/>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${not empty combo.startDate}">
                                        <c:out value="${combo.startDate}"/>
                                        –
                                        <c:out value="${combo.endDate}"/>
                                    </c:when>
                                    <c:otherwise>
                                        Không giới hạn
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td class="numeric">
                                ${combo.items.size()}
                            </td>
                            <td>
                                <c:url var="detail" value="/ComboDetailUI5.jsp">
                                    <c:param name="comboId" value="${combo.id}"/>
                                    <c:param name="from" value="staff"/>
                                </c:url>
                                <a class="btn btn-outline-success btn-sm" href="<c:out value='${detail}'/>">
                                    Xem chi tiết
                                </a>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </div>
        <c:if test="${empty listCombo}">
            <p class="empty-state">
                Chưa có combo. Chọn Thêm combo mới để bắt đầu.
            </p>
        </c:if>
    </section>
</main>
<%@ include file="WEB-INF/views/shared/footer.jspf" %>
