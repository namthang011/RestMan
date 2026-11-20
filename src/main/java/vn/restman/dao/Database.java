package vn.restman.dao;

import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.util.Properties;

/** JDBC đọc cấu hình ngoài WAR; không ghi mật khẩu vào mã nguồn. */
public final class Database {
    private Database() {}

    public static Connection open() throws SQLException {
        Properties config = new Properties();
        String configFile = System.getProperty("restman.db.config", System.getenv("RESTMAN_DB_CONFIG"));
        if (configFile != null && !configFile.isBlank()) {
            try (Reader reader = Files.newBufferedReader(Path.of(configFile))) {
                config.load(reader);
            } catch (IOException ex) {
                throw new SQLException("Cannot read RestMan database configuration", ex);
            }
        }
        String url = value("RESTMAN_DB_URL", config, "db.url",
            "jdbc:mysql://127.0.0.1:3306/restman?characterEncoding=UTF-8&connectionTimeZone=Asia/Bangkok&connectTimeout=5000&socketTimeout=10000");
        String user = value("RESTMAN_DB_USER", config, "db.user", "");
        String password = value("RESTMAN_DB_PASSWORD", config, "db.password", "");
        if (user.isBlank()) throw new SQLException("Run scripts/init-db.ps1 before starting RestMan");
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
        catch (ClassNotFoundException ex) { throw new SQLException("MySQL JDBC driver is missing", ex); }
        return DriverManager.getConnection(url, user, password);
    }

    private static String value(String env, Properties config, String key, String fallback) {
        String result = System.getenv(env);
        return result == null ? config.getProperty(key, fallback) : result;
    }

    public static DatabaseException failure(SQLException ex) {
        java.util.logging.Logger.getLogger(Database.class.getName()).log(
            java.util.logging.Level.SEVERE, "RestMan database operation failed", ex);
        return new DatabaseException(
            "Không kết nối hoặc xử lý được dữ liệu MySQL. Kiểm tra MySQL và cấu hình kết nối.", ex);
    }
}

