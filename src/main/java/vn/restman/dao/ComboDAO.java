package vn.restman.dao;

import vn.restman.model.*;
import vn.restman.common.Text;
import java.sql.*;
import java.util.*;

/** Persist tblCombo and tblComboDetail in one transaction. */
public final class ComboDAO extends DAO {
    private static final ComboDAO INSTANCE = new ComboDAO();
    public static ComboDAO getInstance() { return INSTANCE; }
    public List<Combo> getAllCombo() {
        return withConnection(() -> {
            try (PreparedStatement statement = con.prepareStatement("SELECT * FROM tblCombo WHERE tblRestaurantid=1 ORDER BY id");
                 ResultSet rows = statement.executeQuery()) {
                List<Combo> result = new ArrayList<>();
                while (rows.next()) {
                    result.add(readCombo(rows));
                }
                return result;
            }
        });
    }
    public Optional<Combo> getComboById(long comboId) {
        return withConnection(() -> {
            try (PreparedStatement statement = con.prepareStatement("SELECT * FROM tblCombo WHERE id=? AND tblRestaurantid=1")) {
                statement.setLong(1, comboId);
                try (ResultSet rows = statement.executeQuery()) {
                    return rows.next() ? Optional.of(readCombo(rows)) : Optional.empty();
                }
            }
        });
    }

    /** Name matches the combo or a component dish; type applies to component dishes. */
    public List<Combo> searchCombos(String name, String type) {
        String nameKey = Text.key(name), typeKey = Text.key(type);
        return getAllCombo().stream().filter(combo -> {
            boolean comboNameMatches = Text.key(combo.getName()).contains(nameKey);
            return combo.getItems().stream().anyMatch(item ->
                (typeKey.isEmpty() || Text.key(item.getDish().getType()).equals(typeKey))
                && (comboNameMatches || Text.key(item.getDish().getName()).contains(nameKey)));
        }).toList();
    }

    private Combo readCombo(ResultSet rows) throws SQLException {
        long id = rows.getLong("id");
        List<ComboItem> items = new ArrayList<>();
        try (PreparedStatement details = con.prepareStatement(
                "SELECT cd.id AS detail_id,cd.quantity,cd.tblDishSizeid,d.* FROM tblComboDetail cd "
                + "JOIN tblDish d ON d.id=cd.tblDishid WHERE cd.tblComboid=? ORDER BY cd.id")) {
            details.setLong(1, id);
            try (ResultSet lines = details.executeQuery()) {
                while (lines.next()) {
                    Dish dish = DishDAO.readDish(lines, con);
                    long sizeId = lines.getLong("tblDishSizeid");
                    DishSize size = dish.getDishSizes().stream().filter(s -> s.id()==sizeId).findFirst()
                        .orElseThrow(() -> new SQLException("Dish size does not belong to combo dish"));
                    items.add(new ComboItem(lines.getLong("detail_id"), dish, size, lines.getInt("quantity")));
                }
            }
        }
        java.sql.Date start = rows.getDate("startDate"), end = rows.getDate("endDate");
        return new Combo(id, rows.getString("name"), rows.getBigDecimal("price"), rows.getString("description"),
            rows.getString("img"), start==null ? null : start.toLocalDate(), end==null ? null : end.toLocalDate(), items);
    }

    public boolean saveCombo(Combo combo) {
        Objects.requireNonNull(combo);
        return withConnection(() -> {
            con.setAutoCommit(false);
            try {
                // Serialize restaurant saves to check normalized duplicate names without adding a design column.
                try (PreparedStatement lock = con.prepareStatement("SELECT id FROM tblRestaurant WHERE id=1 FOR UPDATE");
                     ResultSet restaurant = lock.executeQuery()) {
                    if (!restaurant.next()) throw new SQLException("RestMan restaurant is not configured");
                }
                try (PreparedStatement names = con.prepareStatement("SELECT name FROM tblCombo WHERE tblRestaurantid=1");
                     ResultSet rows = names.executeQuery()) {
                    while (rows.next()) if (Text.key(rows.getString(1)).equals(Text.key(combo.getName())))
                        throw new IllegalArgumentException("Tên combo đã tồn tại.");
                }
                long comboId;
                try (PreparedStatement insert = con.prepareStatement(
                        "INSERT INTO tblCombo (name,price,description,img,startDate,endDate,tblRestaurantid) VALUES (?,?,?,?,?,?,1)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    insert.setString(1, combo.getName()); insert.setBigDecimal(2, combo.getPrice());
                    insert.setString(3, combo.getDescription()); insert.setString(4, combo.getImg());
                    insert.setDate(5, combo.getStartDate()==null ? null : java.sql.Date.valueOf(combo.getStartDate()));
                    insert.setDate(6, combo.getEndDate()==null ? null : java.sql.Date.valueOf(combo.getEndDate()));
                    insert.executeUpdate();
                    try (ResultSet keys = insert.getGeneratedKeys()) {
                        if (!keys.next()) throw new SQLException("Missing generated combo id");
                        comboId = keys.getLong(1);
                    }
                }
                try (PreparedStatement insert = con.prepareStatement(
                        "INSERT INTO tblComboDetail (tblDishid,tblDishSizeid,tblComboid,quantity) "
                        + "SELECT ds.tblDishid,ds.id,?,? FROM tblDishSize ds JOIN tblDish d ON d.id=ds.tblDishid "
                        + "WHERE ds.id=? AND ds.tblDishid=? AND d.tblRestaurantid=1")) {
                    for (ComboItem item : combo.getItems()) {
                        insert.setLong(1, comboId); insert.setInt(2, item.getQuantity());
                        insert.setLong(3, item.getDishSize()==null ? -1 : item.getDishSize().id());
                        insert.setLong(4, item.getDish().getId());
                        if (insert.executeUpdate()!=1) throw new SQLException("Dish or dish size no longer exists");
                    }
                }
                con.commit();
                return true;
            } catch (SQLException | RuntimeException ex) {
                try { con.rollback(); } catch (SQLException rollback) { ex.addSuppressed(rollback); }
                throw ex;
            }
        });
    }
}