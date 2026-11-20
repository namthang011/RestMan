package vn.restman.model;

import java.util.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

/** Thuộc tính ẩn của AddComboUI: session.comboDraft.
 * Danh sách được giữ trên server; client chỉ gửi draftId và dishId của thao tác.
 */
public final class ComboDraft {
    private final String id = UUID.randomUUID().toString();
    private String name = "", price = "", description = "";
    private String startDate = "", endDate = "";
    private String img;
    public String getImg() { return img; }
    public void setImg(String img) { this.img = img; }
    private final Map<Long, ComboItem> items = new LinkedHashMap<>();
    private final Map<Long, Long> sizeChoices = new HashMap<>();

    public String getId() { return id; }
    public String getName() { return name; }
    public String getPrice() { return price; }
    public String getDescription() { return description; }
    public String getStartDate() { return startDate; }
    public String getEndDate() { return endDate; }
    public void setDates(String startDate, String endDate) {
        this.startDate = Objects.toString(startDate, "").strip();
        this.endDate = Objects.toString(endDate, "").strip();
    }
    public List<ComboItem> getItems() { return List.copyOf(items.values()); }
    public Map<Long, Long> getSizeChoices() { return Map.copyOf(sizeChoices); }
    public void setInformation(String name, String price, String description) {
        this.name = Objects.toString(name, "");
        this.price = Objects.toString(price, "");
        this.description = Objects.toString(description, "");
    }
    public void addDish(Dish dish) {
        DishSize size = dish.getDefaultDishSize();
        if (size == null) throw new IllegalArgumentException("Món ăn chưa có size để chọn.");
        addDish(dish, size.id());
    }
    public void addDish(Dish dish, long dishSizeId) {
        DishSize size = dish.getDishSizes().stream().filter(s -> s.id() == dishSizeId).findFirst()
            .orElseThrow(() -> new IllegalArgumentException("Size không thuộc món ăn đã chọn."));
        ComboItem old = items.get(dishSizeId);
        items.put(dishSizeId, new ComboItem(0, dish, size, old == null ? 1 : old.getQuantity() + 1));
        sizeChoices.put(dish.getId(), dishSizeId);
    }
    public void removeDish(long dishSizeId) { items.remove(dishSizeId); }
    public void setQuantity(long dishSizeId, int quantity) {
        ComboItem old = items.get(dishSizeId);
        if (old == null) throw new IllegalArgumentException("Món không nằm trong combo đang lập.");
        items.put(dishSizeId, new ComboItem(old.getId(), old.getDish(), old.getDishSize(), quantity));
    }
    public Combo toCombo() {
        BigDecimal amount;
        try {
            if (!price.strip().matches("[0-9]{1,15}(\\.[0-9]{1,2})?")) throw new NumberFormatException();
            amount = new BigDecimal(price.strip());
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Giá bán phải lớn hơn 0, tối đa 15 chữ số nguyên và 2 chữ số thập phân.");
        }
        try {
            LocalDate start = startDate.isEmpty() ? null : LocalDate.parse(startDate);
            LocalDate end = endDate.isEmpty() ? null : LocalDate.parse(endDate);
            if (start != null && (start.getYear() < 1000 || start.getYear() > 9999)
                || end != null && (end.getYear() < 1000 || end.getYear() > 9999))
                throw new IllegalArgumentException("Ngày phải nằm trong khoảng năm 1000 đến 9999.");
            return new Combo(0, name, amount, description, img, start, end, getItems());
        } catch (DateTimeParseException ex) {
            throw new IllegalArgumentException("Ngày bắt đầu hoặc ngày kết thúc không hợp lệ.");
        }
    }
}

