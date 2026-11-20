<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="vn.restman.dao.ComboDAO" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    boolean staff = "staff".equals(request.getParameter("from"));
    request.setAttribute("staffView", staff);
    try {
        long comboId = Long.parseLong(request.getParameter("comboId"));
        request.setAttribute("combo", comboId > 0 ? new ComboDAO().getComboById(comboId).orElse(null) : null);
    } catch (NumberFormatException ex) { request.setAttribute("combo", null); }
    if (request.getAttribute("combo") == null) response.setStatus(404);
%>
<c:set var="area" value="${staffView ? 'staff' : 'customer'}"/>
<%@ include file="WEB-INF/views/shared/head.jspf" %>
<main id="main" class="container page-shell page-wide combo-detail-page">
    <c:choose>
        <c:when test="${staffView}">
            <c:url var="back" value="/ComboListUI5.jsp"/>
        </c:when>
        <c:otherwise>
            <c:url var="back" value="/SearchDishUI5.jsp">
                <c:param name="search" value="1"/>
                <c:param name="name" value="${param.name}"/>
                <c:param name="type" value="${param.type}"/>
            </c:url>
        </c:otherwise>
    </c:choose>
    <a id="subBack" class="back-link" href="<c:out value='${back}'/>">
        ${staffView ? 'Về danh sách combo' : 'Quay lại kết quả tìm kiếm'}
    </a>
    <c:choose>
        <c:when test="${not empty combo}">
            <section class="section-panel combo-overview" aria-labelledby="comboTitle">
                <c:set var="comboImage" value="${empty combo.img ? combo.items[0].dish.image : combo.img}"/>
                <div class="combo-visual">
                    <img src="${pageContext.request.contextPath}/<c:out value='${comboImage}'/>" alt="Ảnh minh họa combo">
                </div>
                <div class="combo-summary">
                    <p class="section-label">
                        Chi tiết combo
                    </p>
                    <h1 id="comboTitle">
                        <c:out value="${combo.name}"/>
                    </h1>
                    <dl class="detail-facts">
                        <div>
                            <dt>
                                Giá bán (VNĐ)
                            </dt>
                            <dd class="numeric price">
                                <fmt:formatNumber value="${combo.price}"/>
                            </dd>
                        </div>
                        <div>
                            <dt>
                                Thời hạn
                            </dt>
                            <dd>
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
                            </dd>
                        </div>
                    </dl>
                    <c:if test="${not empty combo.description}">
                        <h2>
                            Mô tả
                        </h2>
                        <p id="outDescription">
                            <c:out value="${combo.description}"/>
                        </p>
                    </c:if>
                </div>
            </section>
            <section class="section-panel" aria-labelledby="componentsTitle">
                <h2 id="componentsTitle">
                    Các món trong combo
                </h2>
                <div class="table-scroll" tabindex="0" role="region" aria-label="Danh sách món trong combo">
                    <table class="table" id="outComboDetails">
                        <caption class="visually-hidden">
                            Thành phần combo và giá món tham khảo
                        </caption>
                        <thead>
                            <tr>
                                <th scope="col">
                                    Tên món ăn
                                </th>
                                <th scope="col">
                                    Thể loại
                                </th>
                                <th scope="col">
                                    Kích cỡ
                                </th>
                                <th scope="col" class="numeric">
                                    Đơn giá (VNĐ)
                                </th>
                                <th scope="col" class="numeric">
                                    Số lượng
                                </th>
                                <th scope="col" class="numeric">
                                    Thành tiền (VNĐ)
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach items="${combo.items}" var="item">
                                <tr>
                                    <td class="name-cell">
                                        <div class="result-name">
                                            <img src="${pageContext.request.contextPath}/<c:out value='${item.dish.image}'/>" alt="" width="64" height="48" loading="lazy">
                                            <span>
                                                <c:out value="${item.dish.name}"/>
                                            </span>
                                        </div>
                                    </td>
                                    <td>
                                        <c:out value="${item.dish.type}"/>
                                    </td>
                                    <td>
                                        <span class="combo-size">
                                            <c:out value="${item.dishSize.name}"/>
                                        </span>
                                    </td>
                                    <td class="numeric">
                                        <fmt:formatNumber value="${item.unitPrice}"/>
                                    </td>
                                    <td class="numeric">
                                        ${item.quantity}
                                    </td>
                                    <td class="numeric">
                                        <fmt:formatNumber value="${item.subtotal}"/>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                        <tfoot>
                            <tr>
                                <th scope="row" colspan="5">
                                    Tổng giá món tham khảo (VNĐ)
                                </th>
                                <td class="numeric">
                                    <fmt:formatNumber value="${combo.referenceTotal}"/>
                                </td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
                <p class="small">
                    Giá các món chỉ để tham khảo. Giá bán combo là mức giá riêng ở phần thông tin phía trên.
                </p>
            </section>
        </c:when>
        <c:otherwise>
            <h1>
                Không tìm thấy combo
            </h1>
            <p>
                Mã combo không hợp lệ hoặc combo không còn tồn tại.
            </p>
        </c:otherwise>
    </c:choose>
</main>
<%@ include file="WEB-INF/views/shared/footer.jspf" %>
