package com.seilatsatsi.dao;

import com.seilatsatsi.model.Order;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class OrderDAO {

    // Get all orders with customer and product details
    public List<Order> getAllOrders() {
        List<Order> orders = new ArrayList<>();
        String sql = "SELECT o.order_id, o.customer_id, c.full_name as customer_name, " +
                     "o.product_id, p.product_name, o.quantity, o.total_customer_price, " +
                     "o.total_supplier_cost, o.profit, o.payment_status, o.order_status, " +
                     "o.delivery_fee, o.order_date " +
                     "FROM orders o " +
                     "INNER JOIN customers c ON o.customer_id = c.customer_id " +
                     "INNER JOIN products p ON o.product_id = p.product_id " +
                     "ORDER BY o.order_date DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                orders.add(extractOrderFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return orders;
    }

    // Get recent orders (last 10)
    public List<Order> getRecentOrders() {
        List<Order> orders = new ArrayList<>();
        String sql = "SELECT o.order_id, o.customer_id, c.full_name as customer_name, " +
                     "o.product_id, p.product_name, o.quantity, o.total_customer_price, " +
                     "o.total_supplier_cost, o.profit, o.payment_status, o.order_status, " +
                     "o.delivery_fee, o.order_date " +
                     "FROM orders o " +
                     "INNER JOIN customers c ON o.customer_id = c.customer_id " +
                     "INNER JOIN products p ON o.product_id = p.product_id " +
                     "ORDER BY o.order_date DESC LIMIT 10";

        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                orders.add(extractOrderFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return orders;
    }

    // Create new order
    public boolean createOrder(Order order) {
        String sql = "INSERT INTO orders (customer_id, product_id, quantity, " +
                     "total_customer_price, total_supplier_cost, delivery_fee, payment_status) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setInt(1, order.getCustomerId());
            pstmt.setInt(2, order.getProductId());
            pstmt.setInt(3, order.getQuantity());
            pstmt.setBigDecimal(4, order.getTotalCustomerPrice());
            pstmt.setBigDecimal(5, order.getTotalSupplierCost());
            pstmt.setBigDecimal(6, order.getDeliveryFee());
            pstmt.setString(7, order.getPaymentStatus());

            int affectedRows = pstmt.executeUpdate();
            if (affectedRows > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    int orderId = rs.getInt(1);
                    recordTransaction(orderId, order.getTotalCustomerPrice(), order.getPaymentStatus());
                }
                rs.close();
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // Update order status (ordered, shipped, delivered, cancelled)
    public boolean updateOrderStatus(int orderId, String status) {
        String sql = "UPDATE orders SET order_status = ? WHERE order_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, status);
            pstmt.setInt(2, orderId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error updating order status: " + e.getMessage());
            return false;
        }
    }

    // Update payment status (pending, paid, cod)
    public boolean updatePaymentStatus(int orderId, String paymentStatus) {
        String sql = "UPDATE orders SET payment_status = ? WHERE order_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, paymentStatus);
            pstmt.setInt(2, orderId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error updating payment status: " + e.getMessage());
            return false;
        }
    }

    // Get dashboard statistics
    public DashboardStats getDashboardStats() {
        DashboardStats stats = new DashboardStats();
        String sql = "SELECT " +
                     "COUNT(*) as total_orders, " +
                     "COALESCE(SUM(total_customer_price), 0) as total_revenue, " +
                     "COALESCE(SUM(profit), 0) as total_profit, " +
                     "SUM(CASE WHEN order_status = 'ordered' THEN 1 ELSE 0 END) as pending_orders " +
                     "FROM orders";

        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                stats.totalOrders = rs.getInt("total_orders");
                stats.totalRevenue = rs.getBigDecimal("total_revenue");
                stats.totalProfit = rs.getBigDecimal("total_profit");
                stats.pendingOrders = rs.getInt("pending_orders");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return stats;
    }

    // Private helper to record transaction in the transactions table
    private void recordTransaction(int orderId, BigDecimal amount, String paymentMethod) {
        String sql = "INSERT INTO transactions (order_id, amount, transaction_type, payment_method) " +
                     "VALUES (?, ?, 'customer_payment', ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, orderId);
            pstmt.setBigDecimal(2, amount);
            pstmt.setString(3, paymentMethod.toLowerCase());
            pstmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("Error recording transaction: " + e.getMessage());
        }
    }

    // Extract Order object from ResultSet
    private Order extractOrderFromResultSet(ResultSet rs) throws SQLException {
        Order order = new Order();
        order.setOrderId(rs.getInt("order_id"));
        order.setCustomerId(rs.getInt("customer_id"));
        order.setCustomerName(rs.getString("customer_name"));
        order.setProductId(rs.getInt("product_id"));
        order.setProductName(rs.getString("product_name"));
        order.setQuantity(rs.getInt("quantity"));
        order.setTotalCustomerPrice(rs.getBigDecimal("total_customer_price"));
        order.setTotalSupplierCost(rs.getBigDecimal("total_supplier_cost"));
        order.setProfit(rs.getBigDecimal("profit"));
        order.setPaymentStatus(rs.getString("payment_status"));
        order.setOrderStatus(rs.getString("order_status"));
        order.setDeliveryFee(rs.getBigDecimal("delivery_fee"));
        order.setOrderDate(rs.getDate("order_date"));
        return order;
    }

    // Inner class for dashboard statistics
    public static class DashboardStats {
        public int totalOrders = 0;
        public BigDecimal totalRevenue = BigDecimal.ZERO;
        public BigDecimal totalProfit = BigDecimal.ZERO;
        public int pendingOrders = 0;
    }
}