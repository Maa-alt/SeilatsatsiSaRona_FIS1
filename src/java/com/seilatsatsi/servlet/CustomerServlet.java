package com.seilatsatsi.servlet;

import com.seilatsatsi.dao.CustomerDAO;
import com.seilatsatsi.model.Customer;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/customers")
public class CustomerServlet extends HttpServlet {
    
    private CustomerDAO customerDAO;
    
    @Override
    public void init() {
        customerDAO = new CustomerDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        List<Customer> customers = customerDAO.getAllCustomers();
        request.setAttribute("customers", customers);
        request.getRequestDispatcher("/customers.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        Customer customer = new Customer();
        customer.setFullName(request.getParameter("fullName"));
        customer.setPhone(request.getParameter("phone"));
        customer.setEmail(request.getParameter("email"));
        customer.setAddress(request.getParameter("address"));
        
        boolean success = customerDAO.addCustomer(customer);
        
        if (success) {
            response.sendRedirect(request.getContextPath() + "/customers?success=added");
        } else {
            response.sendRedirect(request.getContextPath() + "/customers?error=add_failed");
        }
    }
}