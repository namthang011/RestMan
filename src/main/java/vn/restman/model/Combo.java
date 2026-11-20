package vn.restman.model;

import java.util.List;
import java.math.BigDecimal;
import java.time.LocalDate;

/** Combo hoàn chỉnh được đóng gói TRƯỚC khi gọi DAO. Giá bán khác tổng giá tham khảo. */
public final class Combo {
    private final long id;
    private final BigDecimal price;
    private final LocalDate startDate, endDate;
    private final String img;
    private final String name, description;
    private final List<ComboItem> items;

    public Combo(long id, String name, long price, String description, List<ComboItem> items) {
        this(id, name, BigDecimal.valueOf(price), description, null, null, null, items);
    }
    public Combo(long id, String name, BigDecimal price, String description,
                 String img, LocalDate startDate, LocalDate endDate, List<ComboItem> items) {
        if (name == null || name.isBlank() || name.strip().length() > 100)
            throw new IllegalArgumentException("Tên combo phải có từ 1 đến 100 ký tự.");
        if (price == null || price.signum() <= 0 || price.scale() > 2 || price.precision() - price.scale() > 16)
            throw new IllegalArgumentException("Giá bán phải lớn hơn 0, tối đa 2 chữ số thập phân.");
        if (description != null && description.length() > 255)
            throw new IllegalArgumentException("Mô tả tối đa 255 ký tự.");
        if ((startDate == null) != (endDate == null) || startDate != null && startDate.isAfter(endDate))
            throw new IllegalArgumentException("Nhập cả hai ngày; ngày bắt đầu không được sau ngày kết thúc.");
        if (items == null || items.isEmpty()) throw new IllegalArgumentException("Vui lòng chọn ít nhất một món.");
        this.id = id; this.name = name.strip(); this.price = price;
        this.description = description == null ? "" : description.strip();
        this.img = img;
        this.startDate = startDate; this.endDate = endDate;
        this.items = List.copyOf(items);
    }
    public long getId() { return id; }
    public String getName() { return name; }
    public BigDecimal getPrice() { return price; }
    public String getImg() { return img; }
    public LocalDate getStartDate() { return startDate; }
    public LocalDate getEndDate() { return endDate; }
    public String getDescription() { return description; }
    public List<ComboItem> getItems() { return items; }
    public BigDecimal getReferenceTotal() { return items.stream().map(ComboItem::getSubtotal).reduce(BigDecimal.ZERO, BigDecimal::add); }
}

