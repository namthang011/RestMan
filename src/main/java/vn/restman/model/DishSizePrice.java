package vn.restman.model;

import java.math.BigDecimal;

/** Display data computed from tblDish.basePrice and tblDishSize.pricePercentage. */
public record DishSizePrice(long id, String name, BigDecimal pricePercentage, BigDecimal price) {
    public long getId() { return id; }
    public String getName() { return name; }
    public BigDecimal getPricePercentage() { return pricePercentage; }
    public BigDecimal getPrice() { return price; }
}
