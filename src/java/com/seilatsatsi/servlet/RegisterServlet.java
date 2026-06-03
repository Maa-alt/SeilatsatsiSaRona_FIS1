package com.seilatsatsi.servlet;

import com.seilatsatsi.dao.UserDAO;
import com.seilatsatsi.model.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    private UserDAO userDAO;

    @Override
    public void init() {
        userDAO = new UserDAO();
        // Initialize database and create default manager if needed
        userDAO.initializeDatabase();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        User currentUser = (User) session.getAttribute("user");
        if (currentUser == null || !"MANAGER".equals(currentUser.getRole())) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }
        request.getRequestDispatcher("/register.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        User currentUser = (User) session.getAttribute("user");
        if (currentUser == null || !"MANAGER".equals(currentUser.getRole())) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String fullName = request.getParameter("fullName");
        String role = request.getParameter("role");

        // Validation
        if (username == null || username.trim().isEmpty()) {
            request.setAttribute("error", "Username is required!");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }
        if (password == null || password.trim().isEmpty()) {
            request.setAttribute("error", "Password is required!");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }
        if (fullName == null || fullName.trim().isEmpty()) {
            request.setAttribute("error", "Full name is required!");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }
        if (role == null || role.trim().isEmpty()) {
            role = "ASSISTANT";
        }

        if (userDAO.usernameExists(username)) {
            request.setAttribute("error", "Username already exists!");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        User newUser = new User();
        newUser.setUsername(username);
        newUser.setPassword(password);
        newUser.setFullName(fullName);
        newUser.setRole(role);

        if (userDAO.registerUser(newUser)) {
            request.setAttribute("success", "User registered successfully!");
        } else {
            request.setAttribute("error", "Registration failed. Please try again.");
        }
        request.getRequestDispatcher("/register.jsp").forward(request, response);
    }
}