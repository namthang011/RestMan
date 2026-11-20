package vn.restman.common;

import jakarta.servlet.http.*;
import vn.restman.dao.DishDAO;
import vn.restman.model.ComboDraft;
import java.util.*;

/** Xử lý sự kiện của AddComboUI5.jsp; chỉ doSaveCombo5.jsp được phép gọi saveCombo. */
public final class ComboFlow {
    private ComboFlow() {}
    public static String csrf(HttpSession session) {
        if (session.getAttribute("csrf") == null) session.setAttribute("csrf", UUID.randomUUID().toString());
        return (String) session.getAttribute("csrf");
    }
    public static boolean validToken(HttpServletRequest request) {
        Object token = request.getSession().getAttribute("csrf");
        try { return token != null && token.equals(request.getParameter("csrf")); }
        catch (IllegalStateException ex) { return false; }
    }
    public static ComboDraft getDraft(HttpSession session) {
        return (ComboDraft) session.getAttribute("comboDraft");
    }
    public static ComboDraft openDraft(HttpSession session) {
        ComboDraft draft = getDraft(session);
        if (draft == null) { draft = new ComboDraft(); session.setAttribute("comboDraft", draft); }
        return draft;
    }
    public static ComboDraft requireDraft(HttpServletRequest request) {
        ComboDraft draft = getDraft(request.getSession());
        if (draft == null || !draft.getId().equals(request.getParameter("draftId")))
            throw new IllegalArgumentException("Bản nháp đã kết thúc hoặc hết hạn. Hãy mở lại Thêm combo mới.");
        return draft;
    }
    public static void readInformation(HttpServletRequest request, ComboDraft draft) {
        draft.setInformation(request.getParameter("name"), request.getParameter("price"), request.getParameter("description"));
        draft.setDates(request.getParameter("startDate"), request.getParameter("endDate"));
        String image=ComboImages.receive(request);
        if (image!=null) draft.setImg(image);
    }
    public static void edit(HttpServletRequest request, ComboDraft draft) {
        String action = Objects.toString(request.getParameter("action"), "");
        switch (action) {
            case "search" -> { }
            case "add" -> {
                long id = Long.parseLong(request.getParameter("dishId"));
                var dish = new DishDAO().getDishbyId(id).orElseThrow(
                    () -> new IllegalArgumentException("Món ăn không tồn tại."));
                long dishSizeId = Long.parseLong(request.getParameter("dishSize_" + id));
                draft.addDish(dish, dishSizeId);
            }
            case "remove" -> draft.removeDish(Long.parseLong(request.getParameter("dishSizeId")));
            case "quantity" -> draft.setQuantity(Long.parseLong(request.getParameter("dishSizeId")),
                Integer.parseInt(request.getParameter("quantity_" + request.getParameter("dishSizeId"))));
            default -> throw new IllegalArgumentException("Thao tác không hợp lệ.");
        }
    }
}

