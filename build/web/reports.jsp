<%@ page import="com.seilatsatsi.dao.OrderDAO" %>
<%@ page import="com.seilatsatsi.dao.ProductDAO" %>
<%@ page import="com.seilatsatsi.dao.ExpenseDAO" %>
<%@ page import="com.seilatsatsi.model.Order" %>
<%@ page import="com.seilatsatsi.model.Product" %>
<%@ page import="com.seilatsatsi.model.Expense" %>
<%@ page import="com.seilatsatsi.model.User" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check login
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    boolean isManager = "MANAGER".equals(currentUser.getRole());

    // Initialize DAOs
    OrderDAO orderDAO = new OrderDAO();
    ProductDAO productDAO = new ProductDAO();
    ExpenseDAO expenseDAO = new ExpenseDAO();
    
    // Get data
    List<Order> allOrders = orderDAO.getAllOrders();
    List<Product> allProducts = productDAO.getAllProducts();
    List<Expense> allExpenses = expenseDAO.getAllExpenses();
    OrderDAO.DashboardStats stats = orderDAO.getDashboardStats();
    
    // Calculate monthly profit data (last 6 months)
    Map<String, Double> monthlyProfit = new LinkedHashMap<>();
    Map<String, Integer> monthlyOrders = new LinkedHashMap<>();
    
    Calendar cal = Calendar.getInstance();
    SimpleDateFormat monthFormat = new SimpleDateFormat("MMM yyyy");
    
    for (int i = 5; i >= 0; i--) {
        cal.setTime(new java.util.Date());
        cal.add(Calendar.MONTH, -i);
        String monthKey = monthFormat.format(cal.getTime());
        monthlyProfit.put(monthKey, 0.0);
        monthlyOrders.put(monthKey, 0);
    }
    
    double totalProfit = 0;
    if (allOrders != null) {
        for (Order order : allOrders) {
            if (order.getProfit() != null) {
                totalProfit += order.getProfit().doubleValue();
                if (order.getOrderDate() != null) {
                    String orderMonth = monthFormat.format(order.getOrderDate());
                    if (monthlyProfit.containsKey(orderMonth)) {
                        monthlyProfit.put(orderMonth, monthlyProfit.get(orderMonth) + order.getProfit().doubleValue());
                        monthlyOrders.put(orderMonth, monthlyOrders.get(orderMonth) + 1);
                    }
                }
            }
        }
    }
    
    // Supplier profit breakdown
    double sheinProfit = 0, temuProfit = 0;
    if (allOrders != null && allProducts != null) {
        for (Order order : allOrders) {
            for (Product product : allProducts) {
                if (order.getProductId() == product.getProductId() && order.getProfit() != null) {
                    if ("SHEIN".equals(product.getSupplier())) {
                        sheinProfit += order.getProfit().doubleValue();
                    } else if ("TEMU".equals(product.getSupplier())) {
                        temuProfit += order.getProfit().doubleValue();
                    }
                    break;
                }
            }
        }
    }
    
    // Total expenses & by category
    double totalExpenses = 0;
    Map<String, Double> expensesByCategory = new HashMap<>();
    if (allExpenses != null) {
        for (Expense expense : allExpenses) {
            if (expense.getAmount() != null) {
                totalExpenses += expense.getAmount().doubleValue();
                String category = expense.getCategory();
                expensesByCategory.put(category, expensesByCategory.getOrDefault(category, 0.0) + expense.getAmount().doubleValue());
            }
        }
    }
    
    double netProfit = stats.totalProfit != null ? stats.totalProfit.doubleValue() - totalExpenses : -totalExpenses;
    
    // Top selling products
    Map<String, Integer> productSales = new HashMap<>();
    if (allOrders != null) {
        for (Order order : allOrders) {
            String productName = order.getProductName();
            productSales.put(productName, productSales.getOrDefault(productName, 0) + order.getQuantity());
        }
    }
    List<Map.Entry<String, Integer>> topProducts = new ArrayList<>(productSales.entrySet());
    topProducts.sort((a, b) -> b.getValue().compareTo(a.getValue()));
    topProducts = topProducts.subList(0, Math.min(5, topProducts.size()));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Seilatsatsi FIS - Reports</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:opsz,wght@14..32,300;14..32,400;14..32,500;14..32,600;14..32,700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        /* Your existing CSS – unchanged */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #eef2f5 100%);
            color: #1e293b;
            min-height: 100vh;
        }
        /* Sidebar etc. – same as your current dashboard */
        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            width: 250px;
            height: 100%;
            background: linear-gradient(145deg, #0b1120 0%, #111827 100%);
            color: #e2e8f0;
            z-index: 100;
            display: flex;
            flex-direction: column;
            box-shadow: 4px 0 20px rgba(0,0,0,0.2);
            border-right: 1px solid rgba(255,255,255,0.08);
        }
        .sidebar-header {
            padding: 28px 20px;
            text-align: center;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        .sidebar-header h2 {
            font-size: 1.5rem;
            font-weight: 700;
            background: linear-gradient(135deg, #a5b4fc, #818cf8);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }
        .sidebar-header p { font-size: 0.7rem; opacity: 0.6; margin-top: 4px; }
        .sidebar-menu { flex: 1; padding: 0 16px; }
        .menu-item {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 10px 16px;
            margin: 4px 0;
            border-radius: 12px;
            color: #cbd5e1;
            text-decoration: none;
            transition: all 0.2s;
            font-weight: 500;
            font-size: 0.9rem;
        }
        .menu-item i { width: 24px; text-align: center; }
        .menu-item:hover, .menu-item.active { background: rgba(255,255,255,0.08); color: white; transform: translateX(4px); }
        .sidebar-footer {
            padding: 20px 16px;
            border-top: 1px solid rgba(255,255,255,0.08);
        }
        .user-profile {
            display: flex;
            align-items: center;
            gap: 12px;
            background: rgba(255,255,255,0.05);
            border-radius: 40px;
            padding: 8px 12px;
        }
        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            overflow: hidden;
        }
        .user-avatar img { width: 100%; height: 100%; object-fit: cover; }
        .user-info { flex: 1; }
        .user-name { font-weight: 600; font-size: 0.85rem; color: white; }
        .user-role { font-size: 0.7rem; opacity: 0.7; }
        .logout-icon { color: #f87171; text-decoration: none; }
        .main-content { margin-left: 250px; padding: 28px 32px; }
        .top-bar {
            background: rgba(255,255,255,0.8);
            backdrop-filter: blur(8px);
            border-radius: 32px;
            padding: 16px 28px;
            margin-bottom: 28px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.05);
            border: 1px solid rgba(255,255,255,0.5);
        }
        .page-title h1 { font-size: 1.8rem; font-weight: 700; background: linear-gradient(135deg, #1e293b, #3b82f6); -webkit-background-clip: text; background-clip: text; color: transparent; }
        .user-info { display: flex; align-items: center; gap: 20px; }
        .avatar {
            width: 44px; height: 44px;
            background: linear-gradient(135deg, #3b82f6, #8b5cf6);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        .logout-btn {
            background: #ef4444;
            color: white;
            padding: 8px 18px;
            border-radius: 40px;
            text-decoration: none;
            font-size: 0.85rem;
            font-weight: 500;
            transition: 0.2s;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 20px;
            margin-bottom: 28px;
        }
        .stat-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(4px);
            border-radius: 24px;
            padding: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: transform 0.2s;
            border: 1px solid rgba(255,255,255,0.3);
        }
        .stat-info h3 { font-size: 0.85rem; font-weight: 500; color: #5b6e8c; margin-bottom: 6px; }
        .stat-number { font-size: 1.8rem; font-weight: 700; color: #0f172a; }
        .stat-icon { width: 50px; height: 50px; background: rgba(59,130,246,0.1); border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 1.6rem; color: #3b82f6; }
        .charts-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 24px;
            margin-bottom: 28px;
        }
        .chart-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(4px);
            border-radius: 24px;
            padding: 20px;
            border: 1px solid rgba(255,255,255,0.3);
        }
        .chart-title { font-weight: 600; font-size: 1.1rem; margin-bottom: 18px; color: #0f172a; border-left: 4px solid #3b82f6; padding-left: 12px; }
        canvas { max-height: 280px; width: 100%; }
        .report-table-container {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(4px);
            border-radius: 24px;
            padding: 20px;
            margin-bottom: 28px;
            border: 1px solid rgba(255,255,255,0.3);
        }
        .table-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 15px;
        }
        .table-header h3 { font-size: 1.2rem; font-weight: 600; color: #0f172a; border-left: 4px solid #3b82f6; padding-left: 12px; }
        .btn-export {
            background: linear-gradient(135deg, #10b981, #059669);
            color: white;
            border: none;
            padding: 8px 18px;
            border-radius: 40px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-weight: 500;
            transition: 0.2s;
        }
        .btn-export:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(16,185,129,0.3); }
        .btn-secondary {
            background: #6c757d;
            color: white;
            border: none;
            padding: 8px 18px;
            border-radius: 40px;
            cursor: pointer;
            font-size: 0.8rem;
            font-weight: 500;
        }
        .btn-group { display: flex; gap: 12px; }
        .modern-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            border-radius: 20px;
            overflow: hidden;
        }
        .modern-table th {
            background: #f1f5f9;
            padding: 14px 16px;
            text-align: left;
            font-weight: 600;
            color: #1e293b;
        }
        .modern-table td {
            padding: 12px 16px;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
        }
        .modern-table tr:last-child td { border-bottom: none; }
        .profit-positive { color: #10b981; font-weight: 600; }
        .profit-negative { color: #ef4444; font-weight: 600; }
        @media (max-width: 768px) {
            .sidebar { width: 70px; }
            .sidebar-header h2, .sidebar-header p, .menu-item span, .sidebar-footer { display: none; }
            .main-content { margin-left: 70px; padding: 16px; }
        }
    </style>
</head>
<body>
<div class="sidebar">
    <div class="sidebar-header"><h2>Seilatsatsi</h2><p>FIS</p></div>
    <div class="sidebar-menu">
        <a href="${pageContext.request.contextPath}/dashboard" class="menu-item"><i class="fas fa-tachometer-alt"></i><span>Dashboard</span></a>
        <a href="${pageContext.request.contextPath}/orders" class="menu-item"><i class="fas fa-shopping-cart"></i><span>Orders</span></a>
        <a href="${pageContext.request.contextPath}/products" class="menu-item"><i class="fas fa-box"></i><span>Products</span></a>
        <a href="${pageContext.request.contextPath}/customers" class="menu-item"><i class="fas fa-users"></i><span>Customers</span></a>
        <a href="${pageContext.request.contextPath}/expenses" class="menu-item"><i class="fas fa-money-bill-wave"></i><span>Expenses</span></a>
        <a href="${pageContext.request.contextPath}/reports" class="menu-item active"><i class="fas fa-chart-line"></i><span>Reports</span></a>
        <% if (isManager) { %>
        <a href="${pageContext.request.contextPath}/register" class="menu-item"><i class="fas fa-user-plus"></i><span>Register</span></a>
        <% } %>
    </div>
    <div class="sidebar-footer">
        <div class="user-profile">
            <div class="user-avatar"><img src="https://ui-avatars.com/api/?background=3b82f6&color=fff&rounded=true&size=40&name=<%= currentUser.getFullName() %>" alt="avatar"></div>
            <div class="user-info">
                <div class="user-name"><%= currentUser.getFullName() %></div>
                <div class="user-role"><%= currentUser.getRole() %></div>
            </div>
            <a href="${pageContext.request.contextPath}/logout" class="logout-icon"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</div>

<div class="main-content">
    <div class="top-bar">
        <div class="page-title">
            <h1>Financial Reports & Analytics</h1>
            <p>Comprehensive analysis of your business performance</p>
        </div>
        <div class="user-info">
            <span class="user-name"><%= currentUser.getFullName() %></span>
            <div class="avatar"><%= currentUser.getFullName().charAt(0) %></div>
            <a href="${pageContext.request.contextPath}/logout" class="logout-btn"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </div>
    </div>

    <!-- Summary Stats -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-info">
                <h3>Total Revenue</h3>
                <div class="stat-number">M <%= String.format("%,.2f", stats.totalRevenue != null ? stats.totalRevenue : 0) %></div>
            </div>
            <div class="stat-icon"><i class="fas fa-chart-line"></i></div>
        </div>
        <div class="stat-card">
            <div class="stat-info">
                <h3>Total Expenses</h3>
                <div class="stat-number">M <%= String.format("%,.2f", totalExpenses) %></div>
            </div>
            <div class="stat-icon"><i class="fas fa-receipt"></i></div>
        </div>
        <div class="stat-card">
            <div class="stat-info">
                <h3>Gross Profit</h3>
                <div class="stat-number profit-positive">M <%= String.format("%,.2f", stats.totalProfit != null ? stats.totalProfit : 0) %></div>
            </div>
            <div class="stat-icon"><i class="fas fa-coins"></i></div>
        </div>
        <div class="stat-card">
            <div class="stat-info">
                <h3>Net Profit</h3>
                <div class="stat-number <%= netProfit >= 0 ? "profit-positive" : "profit-negative" %>">M <%= String.format("%,.2f", netProfit) %></div>
            </div>
            <div class="stat-icon"><i class="fas fa-chart-pie"></i></div>
        </div>
    </div>

    <!-- Charts -->
    <div class="charts-row">
        <div class="chart-card">
            <div class="chart-title"><i class="fas fa-chart-bar"></i> Monthly Profit Trend (Last 6 Months)</div>
            <canvas id="profitChart"></canvas>
        </div>
        <div class="chart-card">
            <div class="chart-title"><i class="fas fa-chart-pie"></i> Profit by Supplier</div>
            <canvas id="supplierChart"></canvas>
        </div>
    </div>
    <div class="charts-row">
        <div class="chart-card">
            <div class="chart-title"><i class="fas fa-chart-pie"></i> Expenses by Category</div>
            <canvas id="expenseChart"></canvas>
        </div>
        <div class="chart-card">
            <div class="chart-title"><i class="fas fa-chart-bar"></i> Top Selling Products</div>
            <canvas id="topProductsChart"></canvas>
        </div>
    </div>

    <!-- Detailed Reports -->
    <div class="report-table-container">
        <div class="table-header">
            <h3><i class="fas fa-calendar-alt"></i> Monthly Financial Summary</h3>
            <div class="btn-group">
                <button class="btn-export" onclick="exportToCSV()"><i class="fas fa-download"></i> Export CSV</button>
                <button class="btn-secondary" onclick="printReport()"><i class="fas fa-print"></i> Print</button>
            </div>
        </div>
        <div style="overflow-x: auto;">
            <table class="modern-table" id="monthlyTable">
                <thead>
                    <tr><th>Month</th><th>Orders</th><th>Profit (M)</th><th>Avg Profit/Order (M)</th></tr>
                </thead>
                <tbody>
                    <% for (Map.Entry<String, Double> entry : monthlyProfit.entrySet()) { 
                        String month = entry.getKey();
                        double profit = entry.getValue();
                        int orderCount = monthlyOrders.get(month);
                        double avgProfit = orderCount > 0 ? profit / orderCount : 0;
                    %>
                    <tr>
                        <td><%= month %></td>
                        <td><%= orderCount %></td>
                        <td class="<%= profit >= 0 ? "profit-positive" : "profit-negative" %>">M <%= String.format("%,.2f", profit) %></td>
                        <td>M <%= String.format("%,.2f", avgProfit) %></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <div class="report-table-container">
        <div class="table-header">
            <h3><i class="fas fa-tags"></i> Expense Breakdown by Category</h3>
        </div>
        <div style="overflow-x: auto;">
            <table class="modern-table">
                <thead><tr><th>Category</th><th>Amount (M)</th><th>Percentage</th></tr></thead>
                <tbody>
                    <% for (Map.Entry<String, Double> entry : expensesByCategory.entrySet()) { 
                        double percentage = totalExpenses > 0 ? (entry.getValue() / totalExpenses) * 100 : 0;
                    %>
                    <tr>
                        <td><%= entry.getKey() %></td>
                        <td>M <%= String.format("%,.2f", entry.getValue()) %></td>
                        <td><%= String.format("%.1f", percentage) %>%</td>
                    </tr>
                    <% } if (expensesByCategory.isEmpty()) { %>
                    <tr><td colspan="3">No expense data available</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <div class="report-table-container">
        <div class="table-header">
            <h3><i class="fas fa-chart-simple"></i> Top 5 Best Selling Products</h3>
        </div>
        <div style="overflow-x: auto;">
            <table class="modern-table">
                <thead><tr><th>Product Name</th><th>Units Sold</th><th>Revenue (M)</th><th>Profit (M)</th></tr></thead>
                <tbody>
                    <% for (Map.Entry<String, Integer> entry : topProducts) { 
                        double revenue = 0;
                        double profit = 0;
                        for (Order order : allOrders) {
                            if (entry.getKey().equals(order.getProductName())) {
                                if (order.getTotalCustomerPrice() != null) revenue += order.getTotalCustomerPrice().doubleValue();
                                if (order.getProfit() != null) profit += order.getProfit().doubleValue();
                            }
                        }
                    %>
                    <tr>
                        <td><%= entry.getKey() %></td>
                        <td><%= entry.getValue() %></td>
                        <td>M <%= String.format("%,.2f", revenue) %></td>
                        <td class="profit-positive">M <%= String.format("%,.2f", profit) %></td>
                    </tr>
                    <% } if (topProducts.isEmpty()) { %>
                    <tr><td colspan="4">No product sales data available</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
</div>

<script>
    // Monthly Profit Chart
    new Chart(document.getElementById('profitChart'), {
        type: 'bar',
        data: {
            labels: [<% for (String month : monthlyProfit.keySet()) { %>'<%= month %>',<% } %>],
            datasets: [{
                label: 'Profit (M)',
                data: [<% for (Double profit : monthlyProfit.values()) { %><%= profit %>,<% } %>],
                backgroundColor: 'rgba(59,130,246,0.7)',
                borderColor: '#3b82f6',
                borderRadius: 8
            }]
        }
    });
    new Chart(document.getElementById('supplierChart'), {
        type: 'doughnut',
        data: { labels: ['SHEIN', 'TEMU'], datasets: [{ data: [<%= sheinProfit %>, <%= temuProfit %>], backgroundColor: ['#3b82f6', '#8b5cf6'] }] }
    });
    new Chart(document.getElementById('expenseChart'), {
        type: 'pie',
        data: {
            labels: [<% for (String cat : expensesByCategory.keySet()) { %>'<%= cat %>',<% } %>],
            datasets: [{ data: [<% for (Double amt : expensesByCategory.values()) { %><%= amt %>,<% } %>], backgroundColor: ['#3b82f6', '#f97316', '#8b5cf6', '#10b981', '#ef4444', '#f59e0b'] }]
        }
    });
    new Chart(document.getElementById('topProductsChart'), {
        type: 'bar',
        data: {
            labels: [<% for (Map.Entry<String, Integer> entry : topProducts) { %>'<%= entry.getKey() %>',<% } %>],
            datasets: [{ label: 'Units Sold', data: [<% for (Map.Entry<String, Integer> entry : topProducts) { %><%= entry.getValue() %>,<% } %>], backgroundColor: '#8b5cf6', borderRadius: 8 }]
        },
        options: { indexAxis: 'y' }
    });

    // ***** CORRECTED CSV EXPORT FUNCTION *****
    function exportToCSV() {
        // Get the monthly table rows
        const rows = document.querySelectorAll('#monthlyTable tbody tr');
        let csvContent = "Month,Orders,Profit (M),Avg Profit/Order (M)\n";
        
        rows.forEach(row => {
            const cells = row.querySelectorAll('td');
            if (cells.length >= 4) {
                const month = cells[0].innerText.trim();
                const orders = cells[1].innerText.trim();
                let profit = cells[2].innerText.trim().replace('M ', '');
                let avg = cells[3].innerText.trim().replace('M ', '');
                csvContent += `${month},${orders},${profit},${avg}\n`;
            }
        });
        
        // Create a Blob with UTF-8 BOM for Excel compatibility
        const blob = new Blob(["\uFEFF" + csvContent], { type: "text/csv;charset=utf-8;" });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.href = url;
        link.setAttribute("download", "seilatsatsi_financial_report.csv");
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    }

    function printReport() { window.print(); }
</script>
</body>
</html>