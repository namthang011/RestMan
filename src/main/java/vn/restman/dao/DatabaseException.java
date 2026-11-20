package vn.restman.dao;

/** Lỗi lưu trữ được hiển thị gọn; chi tiết JDBC giữ trong log máy chủ. */
public final class DatabaseException extends RuntimeException {
    public DatabaseException(String message, Throwable cause) { super(message, cause); }
}

