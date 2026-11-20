package vn.restman.model;
import java.math.BigDecimal;
import java.util.List;

/** Thực thể món ăn dùng chung cho cả hai module. */
public final class Dish {
    private final long id;
    private final String name, type, description, image;
    private final BigDecimal price;
    private final List<DishSize> dishSizes;

    public Dish(long id, String name, String type, long price, String description) {
        this(id, name, type, price, description, null);
    }

    public Dish(long id, String name, String type, long price, String description, String image) {
        this(id, name, type, BigDecimal.valueOf(price), description, image, List.of());
    }
    public Dish(long id, String name, String type, BigDecimal price, String description, String image, List<DishSize> dishSizes) {
        this.id = id; this.name = name; this.type = type;
        this.price = price; this.description = description;
        this.dishSizes = List.copyOf(dishSizes);
        this.image = image != null && !image.isBlank() ? image : "assets/images/" + (type.equals("Tráng miệng") ? "dessert" :
            type.equals("Đồ uống") ? "drink" : type.equals("Khai vị") || type.equals("Súp") ?
            "salad" : id == 2 || id == 12 ? "seafood" : "steak") + ".jpg";
    }
    public long getId() { return id; }
    public String getName() { return name; }
    public String getType() { return type; }
    public String getCategory() { return type; }
    public BigDecimal getPrice() { return price; }
    public BigDecimal getBasePrice() { return price; }
    public String getImg() { return image; }
    public List<DishSize> getDishSizes() { return dishSizes; }
    public List<DishSizePrice> getSizePrices() {
        return dishSizes.stream().map(size -> new DishSizePrice(size.id(), size.name(), size.pricePercentage(), size.priceFor(price))).toList();
    }
    public DishSize getDefaultDishSize() {
        return dishSizes.stream().filter(size -> size.pricePercentage().compareTo(new BigDecimal("100")) == 0)
            .findFirst().orElse(dishSizes.isEmpty() ? null : dishSizes.get(0));
    }
    public BigDecimal getMinPrice() { return getSizePrices().stream().map(DishSizePrice::price).min(BigDecimal::compareTo).orElse(price); }
    public BigDecimal getMaxPrice() { return getSizePrices().stream().map(DishSizePrice::price).max(BigDecimal::compareTo).orElse(price); }
    public String getDescription() { return description; }
    public String getImage() { return image; }
}

