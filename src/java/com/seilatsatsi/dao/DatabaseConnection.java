package com.seilatsatsi.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    private static Connection connection = null;
    
    // === AIVEN CLOUD MySQL DATABASE ===
    private static final String URL = "jdbc:mysql://mysql-2bb4ee1f-mpeoanemaapesa89-5f41.h.aivencloud.com:26541/defaultdb?useSSL=true&requireSSL=true&serverTimezone=UTC";
    private static final String USERNAME = "root";
    private static final String PASSWORD = "123456";
    
    public static Connection getConnection() {
        try {
            if (connection == null || connection.isClosed()) {
                Class.forName("com.mysql.cj.jdbc.Driver");
                connection = DriverManager.getConnection(URL, USERNAME, PASSWORD);
                System.out.println("✅ Connected to Aiven Cloud MySQL successfully!");
            }
            return connection;
        } catch (ClassNotFoundException e) {
            System.err.println("❌ MySQL Driver not found!");
            e.printStackTrace();
            return null;
        } catch (SQLException e) {
            System.err.println("❌ Cloud Database connection failed: " + e.getMessage());
            return null;
        }
    }
    
    public static void closeConnection() {
        try {
            if (connection != null && !connection.isClosed()) {
                connection.close();
                System.out.println("Database connection closed.");
            }
        } catch (SQLException e) {
            System.err.println("Error closing connection: " + e.getMessage());
        }
    }
    
    public static boolean testConnection() {
        try {
            Connection conn = getConnection();
            if (conn != null && !conn.isClosed()) {
                System.out.println("✅ Aiven Cloud connection test PASSED!");
                return true;
            }
        } catch (SQLException e) {
            System.err.println("❌ Connection test FAILED: " + e.getMessage());
        }
        return false;
    }
}