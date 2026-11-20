<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="vn.restman.common.ComboFlow,vn.restman.dao.ComboDAO,vn.restman.model.ComboDraft,vn.restman.model.Combo" %>
<%
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
%>
