package vn.restman;

import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import static org.junit.jupiter.api.Assertions.*;
import vn.restman.dao.*;
import vn.restman.model.*;
import java.util.*;
import java.sql.*;
import java.math.BigDecimal;
import java.time.LocalDate;

/** Chỉ chạy trên schema kiểm thử riêng; không ghi dữ liệu vào restman thật. */
@EnabledIfEnvironmentVariable(named = "RESTMAN_TEST_DB_CONFIG", matches = ".+")
class DatabaseTest {
    @BeforeAll static void configure() throws Exception {
        System.setProperty("restman.db.config", System.getenv("RESTMAN_TEST_DB_CONFIG"));
        try (Connection connection = Database.open()) {
            if (!"restman_test".equals(connection.getCatalog()))
                throw new IllegalStateException("Integration tests require database restman_test");
        }
    }
    @AfterAll static void clearConfiguration() { System.clearProperty("restman.db.config"); }

    @Test void searchesAndMapsDatabaseRecords() {
        DishDAO dao = new DishDAO();
        assertEquals(1, dao.searchDishes("tom hum", "mon chinh").size());
        assertEquals(2, dao.searchDishes("", "Đồ uống").size());
        assertTrue(dao.searchDishes("wagyu", "Đồ uống").isEmpty());
        assertTrue(dao.searchDishes("%", "").isEmpty());
        assertTrue(dao.getDishbyId(999999).isEmpty());
    }

    @Test void searchesComboNamesAndComponentsWithTypeFilterAndLoadsDetails() {
        ComboDAO dao = new ComboDAO();
        Combo combo = dao.searchCombos("signature", "").stream().findFirst().orElseThrow();
        assertEquals("Signature Wagyu", combo.getName());
        assertEquals(combo.getId(), dao.searchCombos("wagyu", "do uong").get(0).getId());
        assertEquals("Ocean Elegance", dao.searchCombos("tom hum", "mon chinh").get(0).getName());
        assertTrue(dao.searchCombos("tom hum", "do uong").isEmpty());
        assertTrue(dao.searchCombos("does-not-exist", "").isEmpty());
        assertTrue(dao.searchCombos("%", "").isEmpty());
        Combo detail = dao.getComboById(combo.getId()).orElseThrow();
        assertEquals(4, detail.getItems().size());
        assertTrue(detail.getItems().stream().allMatch(i -> i.getQuantity() > 0 && i.getDishSize() != null));
        assertTrue(dao.getComboById(999999).isEmpty());
    }

    @Test void persistsAcrossDaoInstancesAndPreventsDuplicates() throws Exception {
        String name = "Integration " + UUID.randomUUID();
        String nameKey = name;
        try {
            Dish dish = new DishDAO().getDishbyId(1).orElseThrow();
            Combo combo = new Combo(0, name, new BigDecimal("1900000.25"), "Kiểm thử", "assets/images/steak.jpg",
                LocalDate.of(2026,11,16), LocalDate.of(2026,12,1), List.of(new ComboItem(dish, 2)));
            assertTrue(new ComboDAO().saveCombo(combo));
            Combo stored = new ComboDAO().getAllCombo().stream().filter(c -> name.equals(c.getName())).findFirst().orElseThrow();
            assertEquals(new BigDecimal("1900000.25"), stored.getPrice());
            assertEquals(combo.getStartDate(), stored.getStartDate());
            assertEquals(combo.getEndDate(), stored.getEndDate());
            assertEquals(combo.getImg(), stored.getImg());
            assertTrue(stored.getItems().get(0).getId() > 0);
            assertNotNull(stored.getItems().get(0).getDishSize());
            assertEquals(2, stored.getItems().get(0).getQuantity());
            assertThrows(IllegalArgumentException.class, () -> new ComboDAO().saveCombo(combo));
        } finally { deleteTestCombo(nameKey); }
    }

    @Test void persistsTwoSizesOfSameDishWithCorrectPriceAndRejectsForeignSize() throws Exception {
        String name = "Size test " + UUID.randomUUID();
        try {
            Dish dish = new DishDAO().getDishbyId(1).orElseThrow();
            DishSize small = dish.getDishSizes().stream().filter(s -> s.name().equals("S")).findFirst().orElseThrow();
            DishSize large = dish.getDishSizes().stream().filter(s -> s.name().equals("L")).findFirst().orElseThrow();
            ComboDraft draft = new ComboDraft();
            draft.addDish(dish, small.id()); draft.addDish(dish, large.id()); draft.addDish(dish, large.id());
            draft.setQuantity(small.id(), 3);
            draft.setInformation(name, "1000000", "");
            assertTrue(new ComboDAO().saveCombo(draft.toCombo()));
            Combo stored = new ComboDAO().searchCombos(name, "").get(0);
            assertEquals(2, stored.getItems().size());
            assertEquals(small.id(), stored.getItems().get(0).getDishSize().id());
            assertEquals(3, stored.getItems().get(0).getQuantity());
            assertEquals(new BigDecimal("1480000.00"), stored.getItems().get(0).getUnitPrice());
            assertEquals(large.id(), stored.getItems().get(1).getDishSize().id());
            assertEquals(2, stored.getItems().get(1).getQuantity());
            assertEquals(new BigDecimal("4625000.00"), stored.getItems().get(1).getSubtotal());
            DishSize foreign = new DishDAO().getDishbyId(6).orElseThrow().getDefaultDishSize();
            assertThrows(IllegalArgumentException.class, () -> draft.addDish(dish, foreign.id()));
            Combo forged = new Combo(0, name + " forged", 1000, "", List.of(new ComboItem(0, dish, foreign, 1)));
            assertThrows(DatabaseException.class, () -> new ComboDAO().saveCombo(forged));
            assertTrue(new ComboDAO().searchCombos(name + " forged", "").isEmpty());
        } finally { deleteTestCombo(name); deleteTestCombo(name + " forged"); }
    }

    @Test void failedItemInsertRollsBackComboHeader() throws Exception {
        String name = "Rollback " + UUID.randomUUID();
        String key = name;
        try {
            Dish missing = new Dish(999999, "Không tồn tại", "Món chính", 1000, "");
            Combo invalid = new Combo(0, name, 1000, "", List.of(new ComboItem(missing, 1)));
            assertThrows(DatabaseException.class, () -> new ComboDAO().saveCombo(invalid));
            try (Connection connection = Database.open();
                 PreparedStatement statement = connection.prepareStatement("SELECT COUNT(*) FROM tblCombo WHERE name = ?")) {
                statement.setString(1, key);
                try (ResultSet rows = statement.executeQuery()) { rows.next(); assertEquals(0, rows.getInt(1)); }
            }
        } finally { deleteTestCombo(key); }
    }

    private void deleteTestCombo(String key) throws Exception {
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement("DELETE FROM tblCombo WHERE name = ?")) {
            statement.setString(1, key);
            statement.executeUpdate();
        }
    }
}

