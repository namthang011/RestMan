package vn.restman;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import vn.restman.common.Text;
import vn.restman.model.*;
import java.util.List;
import java.math.BigDecimal;

class FlowTest {
    private Dish wagyu() { return new Dish(1, "Thăn bò Wagyu", "Món chính", new BigDecimal("1850000"), "", null,
        List.of(new DishSize(101, 2, "S", new BigDecimal("80")), new DishSize(1, 1, "M", new BigDecimal("100")), new DishSize(102, 3, "L", new BigDecimal("125")))); }
    private Dish drink() { return new Dish(6, "Mocktail", "Đồ uống", new BigDecimal("180000"), "", null,
        List.of(new DishSize(6, 1, "M", new BigDecimal("100")))); }

    @Test void normalizesVietnameseForDatabaseSearchAndUniqueName() {
        assertEquals("do uong", Text.key("  ĐỒ UỐNG  "));
        assertEquals("tom hum", Text.key("Tôm hùm"));
    }

    @Test void draftKeepsSelectionAndIndependentSellingPrice() {
        ComboDraft draft = new ComboDraft();
        draft.addDish(wagyu());
        draft.addDish(drink());
        draft.addDish(drink());
        assertEquals(2, draft.getItems().size());
        assertEquals(2, draft.getItems().get(1).getQuantity());
        draft.setInformation("Bữa tối", "1900000", "Mô tả");
        draft.setImg("ComboImage5.jsp?file=11111111-1111-1111-1111-111111111111.png");
        Combo combo = draft.toCombo();
        assertEquals(draft.getImg(), combo.getImg());
        assertEquals(0, new BigDecimal("1900000").compareTo(combo.getPrice()));
        assertEquals(0, new BigDecimal("2210000").compareTo(combo.getReferenceTotal()));
        assertThrows(UnsupportedOperationException.class, () -> draft.getItems().clear());
    }

    @Test void invalidInformationDoesNotDiscardSelectedDishes() {
        ComboDraft draft = new ComboDraft();
        draft.setInformation("", "100000", "");
        assertThrows(IllegalArgumentException.class, draft::toCombo);
        draft.addDish(wagyu());
        for (String price : new String[]{"", "-1", "0", "1.555", "abc", "9999999999999999"}) {
            draft.setInformation("Thử", price, "");
            assertThrows(IllegalArgumentException.class, draft::toCombo);
        }
        draft.setInformation("Thử", "99000", "");
        assertEquals(0, new BigDecimal("99000").compareTo(draft.toCombo().getPrice()));
        assertThrows(IllegalArgumentException.class, () -> draft.setQuantity(1, 0));
        assertEquals(1, draft.getItems().get(0).getQuantity());
        assertThrows(IllegalArgumentException.class, () -> new Combo(0, "Tên", 1, "", List.of()));
    }

    @Test void decimalPriceAndDatesSurviveDraftValidation() {
        ComboDraft draft = new ComboDraft();
        draft.addDish(wagyu());
        draft.setInformation("Có thời hạn", "99000.25", "");
        draft.setDates("2026-11-16", "2026-12-01");
        assertEquals(new BigDecimal("99000.25"), draft.toCombo().getPrice());
        assertEquals("2026-11-16", draft.toCombo().getStartDate().toString());
        draft.setDates("2026-12-01", "2026-11-16");
        assertThrows(IllegalArgumentException.class, draft::toCombo);
        assertEquals(1, draft.getItems().size());
        draft.setDates("2026-11-16", "");
        assertThrows(IllegalArgumentException.class, draft::toCombo);
        draft.setDates("2026-02-30", "2026-12-01");
        assertThrows(IllegalArgumentException.class, draft::toCombo);
        draft.setDates("", "");
        assertNull(draft.toCombo().getStartDate());
    }

    @Test void componentPricesUseSelectedSizeAndDisplayedUnitPrice() {
        DishSize size = new DishSize(10, 2, "Lớn", new BigDecimal("125.00"));
        Dish dish = new Dish(1, "Món thử", "Món chính", new BigDecimal("100.01"), "", null, List.of(size));
        ComboItem item = new ComboItem(1, dish, size, 3);
        assertEquals(new BigDecimal("125.01"), item.getUnitPrice());
        assertEquals(new BigDecimal("375.03"), item.getSubtotal());
    }

    @Test void draftSeparatesSizesAndKeepsSizeWhenChangingQuantityOrRemoving() {
        Dish dish = wagyu();
        ComboDraft draft = new ComboDraft();
        draft.addDish(dish, 101);
        draft.addDish(dish, 102);
        draft.addDish(dish, 102);
        assertEquals(2, draft.getItems().size());
        assertEquals(2, draft.getItems().get(1).getQuantity());
        assertEquals(new BigDecimal("1480000.00"), draft.getItems().get(0).getUnitPrice());
        assertEquals(new BigDecimal("2312500.00"), draft.getItems().get(1).getUnitPrice());
        draft.setQuantity(101, 3);
        assertEquals("S", draft.getItems().get(0).getDishSize().name());
        assertEquals(new BigDecimal("4440000.00"), draft.getItems().get(0).getSubtotal());
        assertThrows(IllegalArgumentException.class, () -> draft.addDish(dish, 6));
        assertEquals(2, draft.getItems().size());
        draft.removeDish(101);
        assertEquals(1, draft.getItems().size());
        assertEquals("L", draft.getItems().get(0).getDishSize().name());
        assertEquals(new BigDecimal("1480000.00"), dish.getMinPrice());
        assertEquals(new BigDecimal("2312500.00"), dish.getMaxPrice());
        assertEquals("M", dish.getDefaultDishSize().name());
    }
}

