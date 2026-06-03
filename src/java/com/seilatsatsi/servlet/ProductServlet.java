package com.seilatsatsi.servlet;

import com.seilatsatsi.dao.ProductDAO;
import com.seilatsatsi.model.Product;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/products")
public class ProductServlet extends HttpServlet {
    
    private ProductDAO productDAO;
    
    @Override
    public void init() {
        productDAO = new ProductDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        List<Product> products = productDAO.getAllProducts();
        request.setAttribute("products", products);
        request.getRequestDispatcher("/products.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("add".equals(action)) {
            Product product = new Product();
            product.setProductName(request.getParameter("productName"));
            product.setSupplier(request.getParameter("supplier"));
            product.setSupplierPrice(new BigDecimal(request.getParameter("supplierPrice")));
            product.setSellingPrice(new BigDecimal(request.getParameter("sellingPrice")));
            product.setCategory(request.getParameter("category"));
            
            boolean success = productDAO.addProduct(product);
            
            if (success) {
                response.sendRedirect(request.getContextPath() + "/products?success=added");
            } else {
                response.sendRedirect(request.getContextPath() + "/products?error=add_failed");
            }
        } 
        else if ("update".equals(action)) {
            int productId = Integer.parseInt(request.getParameter("productId"));
            String productName = request.getParameter("productName");
            String supplier = request.getParameter("supplier");
            BigDecimal supplierPrice = new BigDecimal(request.getParameter("supplierPrice"));
            BigDecimal sellingPrice = new BigDecimal(request.getParameter("sellingPrice"));
            String category = request.getParameter("category");
            
            Product product = new Product();
            product.setProductId(productId);
            product.setProductName(productName);
            product.setSupplier(supplier);
            product.setSupplierPrice(supplierPrice);
            product.setSellingPrice(sellingPrice);
            product.setCategory(category);
            
            boolean success = productDAO.updateProduct(product);
            
            if (success) {
                response.sendRedirect(request.getContextPath() + "/products?success=updated");
            } else {
                response.sendRedirect(request.getContextPath() + "/products?error=update_failed");
            }
        }
        else if ("delete".equals(action)) {
            int productId = Integer.parseInt(request.getParameter("productId"));
            boolean success = productDAO.deleteProduct(productId);
            
            if (success) {
                response.sendRedirect(request.getContextPath() + "/products?success=deleted");
            } else {
                response.sendRedirect(request.getContextPath() + "/products?error=delete_failed");
            }
        }
    }
}