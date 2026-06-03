package com.seilatsatsi.dao;

import com.seilatsatsi.model.User;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    // Authenticate user login (plain text comparison)
    public User authenticate(String username, String password) {
        User user = null;
        String sql = "SELECT * FROM users WHERE username = ? AND password = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            pstmt.setString(2, password);   // plain text comparison
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setUsername(rs.getString("username"));
                user.setPassword(rs.getString("password"));
                user.setFullName(rs.getString("full_name"));
                user.setRole(rs.getString("role"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
            }
            rs.close();
        } catch (SQLException e) {
            System.err.println("Authentication error: " + e.getMessage());
        }
        return user;
    }
    
    // Register new user – store plain text password
    public boolean registerUser(User user) {
        String sql = "INSERT INTO users (username, password, full_name, role) VALUES (?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, user.getPassword());   // plain text
            pstmt.setString(3, user.getFullName());
            pstmt.setString(4, user.getRole());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Registration error: " + e.getMessage());
            return false;
        }
    }
    
    // Check if username exists
    public boolean usernameExists(String username) {
        String sql = "SELECT COUNT(*) FROM users WHERE username = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("Check username error: " + e.getMessage());
        }
        return false;
    }
    
    // Initialize users table and default manager (plain text password)
    public void initializeDatabase() {
        String createTable = "CREATE TABLE IF NOT EXISTS users (" +
                "user_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "username VARCHAR(50) UNIQUE NOT NULL, " +
                "password VARCHAR(255) NOT NULL, " +
                "full_name VARCHAR(100) NOT NULL, " +
                "role VARCHAR(20) DEFAULT 'ASSISTANT', " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement()) {
            stmt.execute(createTable);
            System.out.println("✅ Users table verified/created.");
            
            // Insert default manager if not exists (plain text password 'manager123')
            if (!usernameExists("manager")) {
                String insertManager = "INSERT INTO users (username, password, full_name, role) " +
                                       "VALUES ('manager', 'manager123', 'System Manager', 'MANAGER')";
                stmt.execute(insertManager);
                System.out.println("✅ Default manager created (username: manager, password: manager123).");
            }
        } catch (SQLException e) {
            System.err.println("❌ Database init error: " + e.getMessage());
        }
    }
    
    // Get all users (for manager view)
    public List<User> getAllUsers() {
        List<User> users = new ArrayList<>();
        String sql = "SELECT user_id, username, full_name, role, created_at FROM users ORDER BY user_id DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setUsername(rs.getString("username"));
                user.setFullName(rs.getString("full_name"));
                user.setRole(rs.getString("role"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                users.add(user);
            }
        } catch (SQLException e) {
            System.err.println("Error getting users: " + e.getMessage());
        }
        return users;
    }
    
    // Delete user (manager only)
    public boolean deleteUser(int userId) {
        String sql = "DELETE FROM users WHERE user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Delete user error: " + e.getMessage());
            return false;
        }
    }
}