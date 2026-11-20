package vn.restman.dao;

import vn.restman.model.*;
import vn.restman.common.Text;
import java.sql.*;
import java.util.*;

public final class DishDAO extends DAO {
    public List<Dish> searchDishes(String name, String type) {
        // Search keys stay in Java; the design has no name_key/type_key columns.
        String nameKey = Text.key(name), typeKey = Text.key(type);
        return withConnection(() -> {
            try (PreparedStatement statement = con.prepareStatement("SELECT * FROM tblDish WHERE tblRestaurantid=1 ORDER BY id");
                 ResultSet rows = statement.executeQuery()) {
                List<Dish> dishes = new ArrayList<>();
                while (rows.next()) {
                    if (Text.key(rows.getString("name")).contains(nameKey)
                        && (typeKey.isEmpty() || Text.key(rows.getString("type")).equals(typeKey)))
                        dishes.add(readDish(rows, con));
                }
                return dishes;
            }
        });
    }
    public Optional<Dish> getDishbyId(long dishId) {
        return withConnection(() -> {
            try (PreparedStatement statement = con.prepareStatement("SELECT * FROM tblDish WHERE id=? AND tblRestaurantid=1")) {
                statement.setLong(1, dishId);
                try (ResultSet rows = statement.executeQuery()) {
                    return rows.next() ? Optional.of(readDish(rows, con)) : Optional.empty();
                }
            }
        });
    }
    public List<String> getTypes() {
        return withConnection(() -> {
            try (PreparedStatement statement = con.prepareStatement("SELECT type FROM tblDish WHERE tblRestaurantid=1 GROUP BY type ORDER BY MIN(id)");
                 ResultSet rows = statement.executeQuery()) {
                List<String> types = new ArrayList<>();
                while (rows.next()) types.add(rows.getString("type"));
                return types;
            }
        });
    }
    static Dish readDish(ResultSet rows, Connection connection) throws SQLException {
        long id = rows.getLong("id");
        List<DishSize> sizes = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT ds.id,ds.tblSizeid,s.name,ds.pricePercentage FROM tblDishSize ds JOIN tblSize s ON s.id=ds.tblSizeid "
                + "WHERE ds.tblDishid=? ORDER BY ds.pricePercentage,ds.id")) {
            statement.setLong(1, id);
            try (ResultSet options = statement.executeQuery()) {
                while (options.next()) sizes.add(new DishSize(options.getLong("id"), options.getLong("tblSizeid"),
                    options.getString("name"), options.getBigDecimal("pricePercentage")));
            }
        }
        return new Dish(id, rows.getString("name"), rows.getString("type"), rows.getBigDecimal("basePrice"),
            rows.getString("description"), rows.getString("img"), sizes);
    }
}
