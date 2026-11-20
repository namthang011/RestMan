package vn.restman.model;

import java.util.Objects;
import java.math.BigDecimal;
import java.math.RoundingMode;

/** Một dòng món đã chọn; đóng gói đối tượng Dish, không chỉ lưu tên hiển thị. */
public final class ComboItem {
    private final Dish dish;
    private final int quantity;
    private final long id;
    private final DishSize dishSize;

    public ComboItem(Dish dish, int quantity) {
        this(0, dish, dish.getDefaultDishSize(), quantity);
    }
    public ComboItem(long id, Dish dish, DishSize dishSize, int quantity) {
        this.dish = Objects.requireNonNull(dish);
        if (quantity < 1 || quantity > 999) throw new IllegalArgumentException("Số lượng phải từ 1 đến 999.");
        this.quantity = quantity;
        this.id = id; this.dishSize = dishSize;
    }
    public Dish getDish() { return dish; }
    public int getQuantity() { return quantity; }
    public long getId() { return id; }
    public DishSize getDishSize() { return dishSize; }
    public BigDecimal getUnitPrice() {
        return dishSize == null ? dish.getPrice().setScale(2, RoundingMode.HALF_UP) : dishSize.priceFor(dish.getPrice());
    }
    public BigDecimal getSubtotal() {
        return getUnitPrice().multiply(BigDecimal.valueOf(quantity));
    }
}

