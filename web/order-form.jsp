<%@ page import="com.seilatsatsi.dao.ProductDAO" %>
<%@ page import="com.seilatsatsi.dao.CustomerDAO" %>
<%@ page import="com.seilatsatsi.model.Product" %>
<%@ page import="com.seilatsatsi.model.Customer" %>
<%@ page import="java.util.List" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    ProductDAO productDAO = new ProductDAO();
    CustomerDAO customerDAO = new CustomerDAO();
    List<Product> products = productDAO.getAllProducts();
    List<Customer> customers = customerDAO.getAllCustomers();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seilatsatsi FIS - New Order</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Poppins', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .sidebar { position: fixed; left: 0; top: 0; width: 260px; height: 100%; background: linear-gradient(180deg, #1a1a2e 0%, #16213e 100%); color: white; z-index: 100; }
        .sidebar-header { padding: 25px 20px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1); }
        .sidebar-header h2 { font-size: 20px; }
        .sidebar-header p { font-size: 12px; opacity: 0.7; }
        .sidebar-menu { padding: 20px 0; }
        .menu-item { padding: 12px 25px; display: flex; align-items: center; gap: 12px; color: rgba(255,255,255,0.8); transition: all 0.3s; text-decoration: none; }
        .menu-item:hover, .menu-item.active { background: rgba(255,255,255,0.1); color: white; border-left: 3px solid #667eea; }
        .menu-item i { width: 20px; }
        .main-content { margin-left: 260px; padding: 20px; }
        .top-bar { background: white; border-radius: 15px; padding: 15px 25px; margin-bottom: 25px; display: flex; justify-content: space-between; align-items: center; }
        .page-title h1 { font-size: 24px; color: #333; }
        .user-info { display: flex; align-items: center; gap: 15px; }
        .avatar { width: 40px; height: 40px; background: linear-gradient(135deg, #667eea, #764ba2); border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; }
        .form-container { background: white; border-radius: 15px; padding: 30px; max-width: 600px; margin: 0 auto; }
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; margin-bottom: 8px; font-weight: 500; color: #555; }
        .form-group input, .form-group select { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px; font-family: inherit; font-size: 14px; }
        .form-group input:focus, .form-group select:focus { outline: none; border-color: #667eea; }
        .form-actions { display: flex; gap: 15px; margin-top: 25px; }
        .btn-submit, .btn-cancel { padding: 12px 25px; border-radius: 8px; cursor: pointer; font-weight: 600; text-decoration: none; text-align: center; flex: 1; border: none; }
        .btn-submit { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .btn-cancel { background: #6c757d; color: white; display: inline-block; text-align: center; }
        .total-amount { font-size: 18px; font-weight: bold; color: #28a745; background: #e8f5e9; padding: 10px; border-radius: 8px; text-align: center; }
    </style>
</head>
<body>
    <div class="sidebar">
        <div class="sidebar-header"><h2>🛍️ Seilatsatsi</h2><p>FIS</p></div>
        <div class="sidebar-menu">
            <a href="${pageContext.request.contextPath}/dashboard" class="menu-item"><i class="fas fa-tachometer-alt"></i><span>Dashboard</span></a>
            <a href="${pageContext.request.contextPath}/orders" class="menu-item active"><i class="fas fa-shopping-cart"></i><span>Orders</span></a>
            <a href="${pageContext.request.contextPath}/products" class="menu-item"><i class="fas fa-box"></i><span>Products</span></a>
            <a href="${pageContext.request.contextPath}/customers" class="menu-item"><i class="fas fa-users"></i><span>Customers</span></a>
            <a href="${pageContext.request.contextPath}/expenses" class="menu-item"><i class="fas fa-money-bill-wave"></i><span>Expenses</span></a>
        </div>
    </div>

    <div class="main-content">
        <div class="top-bar">
            <div class="page-title"><h1>Create New Order</h1></div>
            <div class="user-info"><span class="user-name">Admin</span><div class="avatar">A</div></div>
        </div>

        <div class="form-container">
            <form action="${pageContext.request.contextPath}/orders" method="post" class="order-form" onsubmit="return validateForm()">
                <input type="hidden" name="action" value="create">
                
                <div class="form-group">
                    <label>Customer *</label>
                    <select name="customerId" id="customerId" required>
                        <option value="">Select Customer</option>
                        <% for (Customer customer : customers) { %>
                            <option value="<%= customer.getCustomerId() %>"><%= customer.getFullName() %> - <%= customer.getPhone() %></option>
                        <% } %>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Product *</label>
                    <select name="productId" id="productId" required onchange="calculateTotal()">
                        <option value="">Select Product</option>
                        <% for (Product product : products) { %>
                            <option value="<%= product.getProductId() %>" data-price="<%= product.getSellingPrice() %>">
                                <%= product.getProductName() %> - M <%= product.getSellingPrice() %> (<%= product.getSupplier() %>)
                            </option>
                        <% } %>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Quantity *</label>
                    <input type="number" name="quantity" id="quantity" value="1" min="1" required onchange="calculateTotal()">
                </div>
                
                <div class="form-group">
                    <label>Delivery Fee (M)</label>
                    <input type="number" name="deliveryFee" id="deliveryFee" value="0" step="10" onchange="calculateTotal()">
                </div>
                
                <div class="form-group">
                    <label>Payment Method *</label>
                    <select name="paymentMethod" required>
                        <option value="Cash">Cash</option>
                        <option value="Bank Transfer">Bank Transfer</option>
                        <option value="Mobile Money">Mobile Money</option>
                        <option value="COD">Cash on Delivery</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Total Amount</label>
                    <div class="total-amount" id="totalAmountDisplay">M 0.00</div>
                    <input type="hidden" name="totalAmount" id="totalAmountHidden">
                </div>
                
                <div class="form-actions">
                    <button type="submit" class="btn-submit">Create Order</button>
                    <a href="${pageContext.request.contextPath}/orders" class="btn-cancel">Cancel</a>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        function calculateTotal() {
            var select = document.getElementById('productId');
            var selectedOption = select.options[select.selectedIndex];
            var price = selectedOption.getAttribute('data-price');
            var quantity = document.getElementById('quantity').value;
            var deliveryFee = document.getElementById('deliveryFee').value;
            
            if (price && quantity && !isNaN(price) && !isNaN(quantity)) {
                var total = (parseFloat(price) * parseInt(quantity)) + parseFloat(deliveryFee || 0);
                document.getElementById('totalAmountDisplay').innerHTML = 'M ' + total.toFixed(2);
                document.getElementById('totalAmountHidden').value = total;
            } else {
                document.getElementById('totalAmountDisplay').innerHTML = 'M 0.00';
                document.getElementById('totalAmountHidden').value = 0;
            }
        }
        
        function validateForm() {
            var customer = document.getElementById('customerId').value;
            var product = document.getElementById('productId').value;
            if (!customer || !product) {
                alert('Please select both customer and product!');
                return false;
            }
            return true;
        }
        
        // Calculate on page load
        document.addEventListener('DOMContentLoaded', function() {
            calculateTotal();
        });
    </script>
</body>
</html>