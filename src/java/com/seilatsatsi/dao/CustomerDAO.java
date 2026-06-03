package com.seilatsatsi.dao;

import com.seilatsatsi.model.Customer;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CustomerDAO {
    
    public List<Customer> getAllCustomers() {
        List<Customer> customers = new ArrayList<>();
        String sql = "SELECT c.*, COUNT(o.order_id) as total_orders " +
                     "FROM customers c " +
                     "LEFT JOIN orders o ON c.customer_id = o.customer_id " +
                     "GROUP BY c.customer_id " +
                     "ORDER BY c.customer_id DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Customer customer = new Customer();
                customer.setCustomerId(rs.getInt("customer_id"));
                customer.setFullName(rs.getString("full_name"));
                customer.setPhone(rs.getString("phone"));
                customer.setEmail(rs.getString("email"));
                customer.setAddress(rs.getString("address"));
                customer.setRegistrationDate(rs.getDate("registration_date"));
                customer.setTotalOrders(rs.getInt("total_orders"));
                customers.add(customer);
            }
        } catch (SQLException e) {
            System.err.println("Error getting customers: " + e.getMessage());
            e.printStackTrace();
        }
        return customers;
    }
    
    public boolean addCustomer(Customer customer) {
        String sql = "INSERT INTO customers (full_name, phone, email, address) VALUES (?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, customer.getFullName());
            pstmt.setString(2, customer.getPhone());
            pstmt.setString(3, customer.getEmail());
            pstmt.setString(4, customer.getAddress());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error adding customer: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
}