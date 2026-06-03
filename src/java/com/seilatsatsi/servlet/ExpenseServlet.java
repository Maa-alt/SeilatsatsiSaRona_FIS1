package com.seilatsatsi.servlet;

import com.seilatsatsi.dao.ExpenseDAO;
import com.seilatsatsi.model.Expense;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/expenses")
public class ExpenseServlet extends HttpServlet {
    
    private ExpenseDAO expenseDAO;
    
    @Override
    public void init() {
        expenseDAO = new ExpenseDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        List<Expense> expenses = expenseDAO.getAllExpenses();
        request.setAttribute("expenses", expenses);
        request.getRequestDispatcher("/expenses.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        Expense expense = new Expense();
        expense.setCategory(request.getParameter("category"));
        expense.setAmount(new BigDecimal(request.getParameter("amount")));
        expense.setDescription(request.getParameter("description"));
        
        boolean success = expenseDAO.addExpense(expense);
        
        if (success) {
            response.sendRedirect(request.getContextPath() + "/expenses?success=added");
        } else {
            response.sendRedirect(request.getContextPath() + "/expenses?error=add_failed");
        }
    }
}