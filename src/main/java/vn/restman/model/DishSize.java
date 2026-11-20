package vn.restman.model;

import java.math.BigDecimal;
import java.math.RoundingMode;

/** A size option persisted in tblDishSize and tblSize. */
public record DishSize(long id, long sizeId, String name, BigDecimal pricePercentage) {
    public DishSize {
        if (pricePercentage == null || pricePercentage.signum() <= 0)
            throw new IllegalArgumentException("Tỷ lệ giá theo size phải lớn hơn 0.");
    }
    public long getId() { return id; }
    public String getName() { return name; }
    public BigDecimal getPricePercentage() { return pricePercentage; }
    public BigDecimal priceFor(BigDecimal basePrice) {
        return basePrice.multiply(pricePercentage).movePointLeft(2).setScale(2, RoundingMode.HALF_UP);
    }
}
