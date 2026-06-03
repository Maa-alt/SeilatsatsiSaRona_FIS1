package com.seilatsatsi.servlet;

import com.seilatsatsi.dao.OrderDAO;
import com.seilatsatsi.model.Order;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {
    
    private OrderDAO orderDAO;
    
    @Override
    public void init() {
        orderDAO = new OrderDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        OrderDAO.DashboardStats stats = orderDAO.getDashboardStats();
        List<Order> recentOrders = orderDAO.getRecentOrders();
        
        request.setAttribute("stats", stats);
        request.setAttribute("recentOrders", recentOrders);
        
        request.getRequestDispatcher("/dashboard.jsp").forward(request, response);
    }
}