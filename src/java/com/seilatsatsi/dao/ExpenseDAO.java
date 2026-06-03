package com.seilatsatsi.dao;

import com.seilatsatsi.model.Expense;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ExpenseDAO {
    
    public List<Expense> getAllExpenses() {
        List<Expense> expenses = new ArrayList<>();
        String sql = "SELECT expense_id, expense_date, category, amount, description " +
                     "FROM expenses ORDER BY expense_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Expense expense = new Expense();
                expense.setExpenseId(rs.getInt("expense_id"));
                expense.setExpenseDate(rs.getDate("expense_date"));
                expense.setCategory(rs.getString("category"));
                expense.setAmount(rs.getBigDecimal("amount"));
                expense.setDescription(rs.getString("description"));
                expenses.add(expense);
            }
        } catch (SQLException e) {
            System.err.println("Error getting expenses: " + e.getMessage());
            e.printStackTrace();
        }
        return expenses;
    }
    
    public boolean addExpense(Expense expense) {
        String sql = "INSERT INTO expenses (category, amount, description) VALUES (?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, expense.getCategory());
            pstmt.setBigDecimal(2, expense.getAmount());
            pstmt.setString(3, expense.getDescription());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error adding expense: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
}