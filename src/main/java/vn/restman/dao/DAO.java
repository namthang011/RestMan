package vn.restman.dao;

import java.sql.Connection;
import java.sql.SQLException;

public abstract class DAO {
    protected Connection con;

    protected DAO() {}

    @FunctionalInterface
    protected interface SqlWork<T> {
        T run() throws SQLException;
    }

    // A shared DAO may serve several requests. Only one operation owns con at a time.
    protected final synchronized <T> T withConnection(SqlWork<T> work) {
        try (Connection opened = Database.open()) {
            con = opened;
            return work.run();
        } catch (SQLException ex) {
            throw Database.failure(ex);
        } finally {
            con = null;
        }
    }
}
