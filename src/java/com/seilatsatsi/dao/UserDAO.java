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
            pstmt.setString(2, password);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setPassword(rs.getString("password"));
                user.setFullName(rs.getString("full_name"));
                user.setRole(rs.getString("role"));
                user.setPhone(rs.getString("phone"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                user.setLastLogin(rs.getTimestamp("last_login"));
            }
            rs.close();
        } catch (SQLException e) {
            System.err.println("Authentication error: " + e.getMessage());
        }
        return user;
    }
    
    // Login user (alias for authenticate)
    public User loginUser(String username, String password) {
        return authenticate(username, password);
    }
    
    // Register new user - allows any user to register (including ADMIN)
    public boolean registerUser(User user) {
        String sql = "INSERT INTO users (username, email, password, full_name, role, phone) VALUES (?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, user.getEmail());
            pstmt.setString(3, user.getPassword());
            pstmt.setString(4, user.getFullName());
            pstmt.setString(5, user.getRole());
            pstmt.setString(6, user.getPhone());
            
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
    
    // Check if email exists
    public boolean emailExists(String email) {
        String sql = "SELECT COUNT(*) FROM users WHERE email = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, email);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("Check email error: " + e.getMessage());
        }
        return false;
    }
    
    // Initialize users table (without creating default admin - users register themselves)
    public void initializeDatabase() {
        String createTable = "CREATE TABLE IF NOT EXISTS users (" +
                "user_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "username VARCHAR(50) UNIQUE NOT NULL, " +
                "email VARCHAR(100) UNIQUE NOT NULL, " +
                "password VARCHAR(255) NOT NULL, " +
                "full_name VARCHAR(100) NOT NULL, " +
                "role VARCHAR(20) DEFAULT 'USER', " +
                "phone VARCHAR(20), " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "last_login TIMESTAMP NULL)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement()) {
            stmt.execute(createTable);
            System.out.println("✅ Users table verified/created.");
            // No default admin - users register themselves
        } catch (SQLException e) {
            System.err.println("❌ Database init error: " + e.getMessage());
        }
    }
    
    // Update last login time
    public void updateLastLogin(int userId) {
        String sql = "UPDATE users SET last_login = ? WHERE user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setTimestamp(1, new Timestamp(System.currentTimeMillis()));
            pstmt.setInt(2, userId);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("Update last login error: " + e.getMessage());
        }
    }
    
    // Get user by ID
    public User getUserById(int userId) {
        User user = null;
        String sql = "SELECT * FROM users WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setPassword(rs.getString("password"));
                user.setFullName(rs.getString("full_name"));
                user.setRole(rs.getString("role"));
                user.setPhone(rs.getString("phone"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                user.setLastLogin(rs.getTimestamp("last_login"));
            }
            rs.close();
        } catch (SQLException e) {
            System.err.println("Get user by ID error: " + e.getMessage());
        }
        return user;
    }
    
    // Get all users (for admin view)
    public List<User> getAllUsers() {
        List<User> users = new ArrayList<>();
        String sql = "SELECT user_id, username, email, full_name, role, phone, created_at, last_login FROM users ORDER BY user_id DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setFullName(rs.getString("full_name"));
                user.setRole(rs.getString("role"));
                user.setPhone(rs.getString("phone"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                user.setLastLogin(rs.getTimestamp("last_login"));
                users.add(user);
            }
        } catch (SQLException e) {
            System.err.println("Error getting users: " + e.getMessage());
        }
        return users;
    }
    
    // Delete user (admin only)
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
    
    // Update user role (admin only)
    public boolean updateUserRole(int userId, String role) {
        String sql = "UPDATE users SET role = ? WHERE user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, role);
            pstmt.setInt(2, userId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Update user role error: " + e.getMessage());
            return false;
        }
    }
}