package com.seilatsatsi.servlet;

import com.seilatsatsi.dao.OrderDAO;
import com.seilatsatsi.dao.ProductDAO;
import com.seilatsatsi.dao.CustomerDAO;
import com.seilatsatsi.model.Order;
import com.seilatsatsi.model.Product;
import com.seilatsatsi.model.Customer;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/orders")
public class OrderServlet extends HttpServlet {

    private OrderDAO orderDAO;
    private ProductDAO productDAO;
    private CustomerDAO customerDAO;

    @Override
    public void init() {
        orderDAO = new OrderDAO();
        productDAO = new ProductDAO();
        customerDAO = new CustomerDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");

        if ("create".equals(action)) {
            List<Product> products = productDAO.getAllProducts();
            List<Customer> customers = customerDAO.getAllCustomers();
            request.setAttribute("products", products);
            request.setAttribute("customers", customers);
            request.getRequestDispatcher("/order-form.jsp").forward(request, response);
        } else {
            List<Order> orders = orderDAO.getAllOrders();
            request.setAttribute("orders", orders);
            request.getRequestDispatcher("/orders.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");

        if ("create".equals(action)) {
            int customerId = Integer.parseInt(request.getParameter("customerId"));
            int productId = Integer.parseInt(request.getParameter("productId"));
            int quantity = Integer.parseInt(request.getParameter("quantity"));
            BigDecimal deliveryFee = new BigDecimal(request.getParameter("deliveryFee"));
            String paymentMethod = request.getParameter("paymentMethod");

            Product product = productDAO.getProductById(productId);

            BigDecimal totalCustomerPrice = product.getSellingPrice()
                    .multiply(BigDecimal.valueOf(quantity))
                    .add(deliveryFee);
            BigDecimal totalSupplierCost = product.getSupplierPrice()
                    .multiply(BigDecimal.valueOf(quantity));

            Order order = new Order();
            order.setCustomerId(customerId);
            order.setProductId(productId);
            order.setQuantity(quantity);
            order.setTotalCustomerPrice(totalCustomerPrice);
            order.setTotalSupplierCost(totalSupplierCost);
            order.setDeliveryFee(deliveryFee);
            order.setPaymentStatus("Cash".equals(paymentMethod) ? "paid" : "pending");

            boolean success = orderDAO.createOrder(order);
            if (success) {
                response.sendRedirect(request.getContextPath() + "/orders?success=created");
            } else {
                response.sendRedirect(request.getContextPath() + "/orders?error=create_failed");
            }
        }
        else if ("updateOrderStatus".equals(action)) {
            int orderId = Integer.parseInt(request.getParameter("orderId"));
            String orderStatus = request.getParameter("orderStatus");
            boolean success = orderDAO.updateOrderStatus(orderId, orderStatus);
            if (success) {
                response.sendRedirect(request.getContextPath() + "/orders?success=status_updated");
            } else {
                response.sendRedirect(request.getContextPath() + "/orders?error=status_update_failed");
            }
        }
        else if ("updatePaymentStatus".equals(action)) {
            int orderId = Integer.parseInt(request.getParameter("orderId"));
            String paymentStatus = request.getParameter("paymentStatus");
            boolean success = orderDAO.updatePaymentStatus(orderId, paymentStatus);
            if (success) {
                response.sendRedirect(request.getContextPath() + "/orders?success=payment_updated");
            } else {
                response.sendRedirect(request.getContextPath() + "/orders?error=payment_update_failed");
            }
        }
    }
}