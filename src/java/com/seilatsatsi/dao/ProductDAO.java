package com.seilatsatsi.dao;

import com.seilatsatsi.model.Product;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProductDAO {
    
    public List<Product> getAllProducts() {
        List<Product> products = new ArrayList<>();
        String sql = "SELECT * FROM products ORDER BY product_id DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductName(rs.getString("product_name"));
                product.setSupplier(rs.getString("supplier"));
                product.setSupplierPrice(rs.getBigDecimal("supplier_price"));
                product.setSellingPrice(rs.getBigDecimal("selling_price"));
                product.setCategory(rs.getString("category"));
                products.add(product);
            }
        } catch (SQLException e) {
            System.err.println("Error getting products: " + e.getMessage());
            e.printStackTrace();
        }
        return products;
    }
    
    public Product getProductById(int id) {
        String sql = "SELECT * FROM products WHERE product_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductName(rs.getString("product_name"));
                product.setSupplier(rs.getString("supplier"));
                product.setSupplierPrice(rs.getBigDecimal("supplier_price"));
                product.setSellingPrice(rs.getBigDecimal("selling_price"));
                product.setCategory(rs.getString("category"));
                return product;
            }
        } catch (SQLException e) {
            System.err.println("Error getting product: " + e.getMessage());
        }
        return null;
    }
    
    public boolean addProduct(Product product) {
        String sql = "INSERT INTO products (product_name, supplier, supplier_price, selling_price, category) " +
                     "VALUES (?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, product.getProductName());
            pstmt.setString(2, product.getSupplier());
            pstmt.setBigDecimal(3, product.getSupplierPrice());
            pstmt.setBigDecimal(4, product.getSellingPrice());
            pstmt.setString(5, product.getCategory());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error adding product: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    // ----- UPDATE PRODUCT (new) -----
    public boolean updateProduct(Product product) {
        String sql = "UPDATE products SET product_name=?, supplier=?, supplier_price=?, selling_price=?, category=? WHERE product_id=?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, product.getProductName());
            pstmt.setString(2, product.getSupplier());
            pstmt.setBigDecimal(3, product.getSupplierPrice());
            pstmt.setBigDecimal(4, product.getSellingPrice());
            pstmt.setString(5, product.getCategory());
            pstmt.setInt(6, product.getProductId());
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error updating product: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean deleteProduct(int id) {
        String sql = "DELETE FROM products WHERE product_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error deleting product: " + e.getMessage());
            return false;
        }
    }
}