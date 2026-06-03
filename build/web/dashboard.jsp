<%@ page import="java.sql.*, java.util.*, java.text.*, com.seilatsatsi.model.*, com.seilatsatsi.dao.*" %>
<%@ page import="com.seilatsatsi.dao.OrderDAO" %>
<%@ page import="com.seilatsatsi.dao.ProductDAO" %>
<%@ page import="com.seilatsatsi.dao.CustomerDAO" %>
<%@ page import="com.seilatsatsi.dao.ExpenseDAO" %>
<%@ page import="com.seilatsatsi.model.User" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // ---------- CHECK LOGIN ----------
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    boolean isManager = "MANAGER".equals(currentUser.getRole());
    String userFullName = currentUser.getFullName();
    String userInitial = userFullName.substring(0, 1).toUpperCase();

    // ---------- DAO INSTANCES ----------
    OrderDAO orderDAO = new OrderDAO();
    ProductDAO productDAO = new ProductDAO();
    CustomerDAO customerDAO = new CustomerDAO();
    ExpenseDAO expenseDAO = new ExpenseDAO();
    OrderDAO.DashboardStats stats = orderDAO.getDashboardStats();

    // ---------- BASIC SUMMARIES ----------
    int totalOrders = stats.totalOrders;
    double totalRevenue = stats.totalRevenue != null ? stats.totalRevenue.doubleValue() : 0;
    double totalProfit = stats.totalProfit != null ? stats.totalProfit.doubleValue() : 0;
    int pendingOrders = stats.pendingOrders;

    int deliveredOrders = 0;
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM orders WHERE order_status = 'delivered'")) {
        if (rs.next()) deliveredOrders = rs.getInt(1);
    } catch (Exception e) { e.printStackTrace(); }

    double totalExpenses = 0;
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery("SELECT SUM(amount) FROM expenses")) {
        if (rs.next()) totalExpenses = rs.getDouble(1);
    } catch (Exception e) { e.printStackTrace(); }

    double netProfit = totalRevenue - totalExpenses;
    double profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
    double expenseToRevenueRatio = totalRevenue > 0 ? (totalExpenses / totalRevenue) * 100 : 0;

    double revenueGrowthRate = 0;
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement()) {
        ResultSet rs = stmt.executeQuery(
            "SELECT SUM(total_customer_price) as current, " +
            "(SELECT SUM(total_customer_price) FROM orders WHERE MONTH(order_date) = MONTH(CURDATE() - INTERVAL 1 MONTH)) as prev " +
            "FROM orders WHERE MONTH(order_date) = MONTH(CURDATE())");
        if (rs.next()) {
            double current = rs.getDouble("current");
            double prev = rs.getDouble("prev");
            revenueGrowthRate = prev != 0 ? ((current - prev) / prev) * 100 : 0;
        }
    } catch (Exception e) { e.printStackTrace(); }

    double initialInvestment = 20900;
    double roi = initialInvestment > 0 ? (netProfit / initialInvestment) * 100 : 0;

    // ---------- VARIANCE ANALYSIS ----------
    double budgetedRevenue = 0, actualRevenue = 0, revenueVariancePercent = 0;
    double budgetedExpense = 0, actualExpense = 0, expenseVariancePercent = 0;
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement()) {
        ResultSet rs = stmt.executeQuery("SELECT SUM(total_customer_price) FROM orders WHERE MONTH(order_date) = MONTH(CURDATE())");
        if (rs.next()) actualRevenue = rs.getDouble(1);
        try {
            rs = stmt.executeQuery("SELECT revenue_budget FROM budgets WHERE MONTH(month) = MONTH(CURDATE())");
            if (rs.next()) budgetedRevenue = rs.getDouble(1);
        } catch (SQLException ex) { }
        revenueVariancePercent = budgetedRevenue != 0 ? ((actualRevenue - budgetedRevenue) / budgetedRevenue) * 100 : 0;
        
        rs = stmt.executeQuery("SELECT SUM(amount) FROM expenses WHERE MONTH(expense_date) = MONTH(CURDATE())");
        if (rs.next()) actualExpense = rs.getDouble(1);
        try {
            rs = stmt.executeQuery("SELECT expense_budget FROM budgets WHERE MONTH(month) = MONTH(CURDATE())");
            if (rs.next()) budgetedExpense = rs.getDouble(1);
        } catch (SQLException ex) { }
        expenseVariancePercent = budgetedExpense != 0 ? ((actualExpense - budgetedExpense) / budgetedExpense) * 100 : 0;
    } catch (Exception e) { e.printStackTrace(); }

    // ---------- TOP 5 CUSTOMERS ----------
    List<Map<String, Object>> topCustomers = new ArrayList<>();
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery(
             "SELECT c.full_name, SUM(o.total_customer_price) as spent, COUNT(o.order_id) as orders " +
             "FROM customers c JOIN orders o ON c.customer_id = o.customer_id " +
             "GROUP BY c.customer_id ORDER BY spent DESC LIMIT 5")) {
        while (rs.next()) {
            Map<String, Object> cust = new HashMap<>();
            cust.put("name", rs.getString("full_name"));
            cust.put("spent", rs.getDouble("spent"));
            cust.put("orders", rs.getInt("orders"));
            topCustomers.add(cust);
        }
    } catch (Exception e) { e.printStackTrace(); }
    double topCustomerContribution = 0;
    if (!topCustomers.isEmpty() && totalRevenue > 0) {
        topCustomerContribution = ((Double) topCustomers.get(0).get("spent") / totalRevenue) * 100;
    }

    // New vs Returning Customers
    int newCustomers = 0, returningCustomers = 0, totalCustomers = 0;
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement()) {
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM customers");
        if (rs.next()) totalCustomers = rs.getInt(1);
        rs = stmt.executeQuery("SELECT COUNT(DISTINCT customer_id) FROM orders GROUP BY customer_id HAVING COUNT(*) = 1");
        newCustomers = rs.last() ? rs.getRow() : 0;
        rs = stmt.executeQuery("SELECT COUNT(DISTINCT customer_id) FROM orders GROUP BY customer_id HAVING COUNT(*) > 1");
        returningCustomers = rs.last() ? rs.getRow() : 0;
    } catch (Exception e) { e.printStackTrace(); }

    // ---------- PRODUCT ANALYSIS ----------
    List<Map<String, Object>> bestProducts = new ArrayList<>();
    List<Map<String, Object>> worstProducts = new ArrayList<>();
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement()) {
        ResultSet rs = stmt.executeQuery(
            "SELECT p.product_name, SUM(o.total_customer_price) as revenue " +
            "FROM orders o JOIN products p ON o.product_id = p.product_id " +
            "GROUP BY p.product_id ORDER BY revenue DESC LIMIT 5");
        while (rs.next()) {
            Map<String, Object> prod = new HashMap<>();
            prod.put("name", rs.getString("product_name"));
            prod.put("revenue", rs.getDouble("revenue"));
            bestProducts.add(prod);
        }
        rs = stmt.executeQuery(
            "SELECT p.product_name, SUM(o.total_customer_price) as revenue " +
            "FROM orders o JOIN products p ON o.product_id = p.product_id " +
            "GROUP BY p.product_id ORDER BY revenue ASC LIMIT 5");
        while (rs.next()) {
            Map<String, Object> prod = new HashMap<>();
            prod.put("name", rs.getString("product_name"));
            prod.put("revenue", rs.getDouble("revenue"));
            worstProducts.add(prod);
        }
    } catch (Exception e) { e.printStackTrace(); }

    // ---------- EXPENSE BREAKDOWN ----------
    Map<String, Double> expenseCategories = new LinkedHashMap<>();
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery("SELECT category, SUM(amount) as total FROM expenses GROUP BY category ORDER BY total DESC")) {
        while (rs.next()) {
            expenseCategories.put(rs.getString("category"), rs.getDouble("total"));
        }
    } catch (Exception e) { e.printStackTrace(); }

    // ---------- SEASONAL ANALYSIS ----------
    Map<String, Double> seasonalRevenue = new LinkedHashMap<>();
    SimpleDateFormat monthYearFormat = new SimpleDateFormat("MMM yyyy");
    Calendar cal = Calendar.getInstance();
    for (int i = 11; i >= 0; i--) {
        cal.setTime(new java.util.Date());
        cal.add(Calendar.MONTH, -i);
        seasonalRevenue.put(monthYearFormat.format(cal.getTime()), 0.0);
    }
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery(
             "SELECT DATE_FORMAT(order_date, '%b %Y') as month, SUM(total_customer_price) as rev " +
             "FROM orders WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) " +
             "GROUP BY month ORDER BY MIN(order_date)")) {
        while (rs.next()) {
            String month = rs.getString("month");
            double rev = rs.getDouble("rev");
            if (seasonalRevenue.containsKey(month)) seasonalRevenue.put(month, rev);
        }
    } catch (Exception e) { e.printStackTrace(); }

    // ---------- CASH FLOW ----------
    Map<String, Double[]> cashFlow = new LinkedHashMap<>();
    for (int i = 5; i >= 0; i--) {
        cal.setTime(new java.util.Date());
        cal.add(Calendar.MONTH, -i);
        cashFlow.put(monthYearFormat.format(cal.getTime()), new Double[]{0.0, 0.0, 0.0});
    }
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement()) {
        ResultSet rs = stmt.executeQuery(
            "SELECT DATE_FORMAT(order_date, '%b %Y') as month, SUM(total_customer_price) as inflow " +
            "FROM orders WHERE payment_status = 'paid' AND order_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
            "GROUP BY month ORDER BY MIN(order_date)");
        while (rs.next()) {
            String month = rs.getString("month");
            double inflow = rs.getDouble("inflow");
            if (cashFlow.containsKey(month)) cashFlow.get(month)[0] = inflow;
        }
        rs = stmt.executeQuery(
            "SELECT DATE_FORMAT(expense_date, '%b %Y') as month, SUM(amount) as outflow " +
            "FROM expenses WHERE expense_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
            "GROUP BY month ORDER BY MIN(expense_date)");
        while (rs.next()) {
            String month = rs.getString("month");
            double outflow = rs.getDouble("outflow");
            if (cashFlow.containsKey(month)) cashFlow.get(month)[1] = outflow;
        }
    } catch (Exception e) { e.printStackTrace(); }
    int positiveCashFlowMonths = 0;
    for (Double[] cf : cashFlow.values()) {
        cf[2] = cf[0] - cf[1];
        if (cf[2] > 0) positiveCashFlowMonths++;
    }
    Double lastNetCash = cashFlow.isEmpty() ? 0.0 : cashFlow.values().stream().skip(cashFlow.size() - 1).findFirst().orElse(new Double[]{0.0,0.0,0.0})[2];
    boolean lowCashReserve = lastNetCash < 5000;

    // ---------- PROFIT TREND ----------
    Map<String, Double> monthlyProfitTrend = new LinkedHashMap<>();
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery(
             "SELECT DATE_FORMAT(order_date, '%b %Y') as month, SUM(profit) as profit " +
             "FROM orders WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
             "GROUP BY month ORDER BY MIN(order_date)")) {
        while (rs.next()) {
            monthlyProfitTrend.put(rs.getString("month"), rs.getDouble("profit"));
        }
    } catch (Exception e) { e.printStackTrace(); }
    List<Double> profitValues = new ArrayList<>(monthlyProfitTrend.values());
    boolean profitDeclining = profitValues.size() >= 2 && profitValues.get(profitValues.size()-1) < profitValues.get(profitValues.size()-2);

    // ---------- FORECAST ----------
    double monthlyForecast = 0;
    List<String> monthsOrder = new ArrayList<>(seasonalRevenue.keySet());
    if (monthsOrder.size() >= 3) {
        List<Double> last3Revenues = new ArrayList<>();
        for (int i = monthsOrder.size() - 3; i < monthsOrder.size(); i++) {
            last3Revenues.add(seasonalRevenue.get(monthsOrder.get(i)));
        }
        monthlyForecast = last3Revenues.stream().mapToDouble(Double::doubleValue).average().orElse(0);
    }

    double weeklyForecast = 0;
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement()) {
        ResultSet rs = stmt.executeQuery(
            "SELECT SUM(total_customer_price) as week_rev FROM orders " +
            "WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 4 WEEK) " +
            "GROUP BY WEEK(order_date)");
        List<Double> weeklyRevenues = new ArrayList<>();
        while (rs.next()) weeklyRevenues.add(rs.getDouble("week_rev"));
        if (!weeklyRevenues.isEmpty()) {
            weeklyForecast = weeklyRevenues.stream().mapToDouble(Double::doubleValue).average().orElse(0);
        }
    } catch (Exception e) { e.printStackTrace(); }

    double yearlyForecast = 0;
    if (!seasonalRevenue.isEmpty()) {
        List<Double> last6Months = new ArrayList<>(seasonalRevenue.values());
        if (last6Months.size() >= 6) {
            last6Months = last6Months.subList(last6Months.size()-6, last6Months.size());
        }
        double avgMonthly = last6Months.stream().mapToDouble(Double::doubleValue).average().orElse(0);
        yearlyForecast = avgMonthly * 12;
    }

    int overduePayments = 0;
    try (Connection conn = com.seilatsatsi.dao.DatabaseConnection.getConnection();
         Statement stmt = conn.createStatement()) {
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM orders WHERE payment_status = 'pending' AND order_date <= DATE_SUB(CURDATE(), INTERVAL 7 DAY)");
        if (rs.next()) overduePayments = rs.getInt(1);
    } catch (Exception e) { e.printStackTrace(); }

    List<Order> recentOrders = orderDAO.getRecentOrders();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Seilatsatsi FIS – Advanced Analytics Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:opsz,wght@14..32,400;14..32,500;14..32,600;14..32,700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        /* ---------- GLOBAL ---------- */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #eef2f5 100%);
            color: #1e293b;
            min-height: 100vh;
        }

        /* ---------- SOPHISTICATED SIDEBAR ---------- */
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
            transition: width 0.2s ease;
            border-right: 1px solid rgba(255,255,255,0.08);
        }

        .sidebar-header {
            padding: 28px 20px;
            text-align: center;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            margin-bottom: 20px;
        }

        .sidebar-header h2 {
            font-size: 1.5rem;
            font-weight: 700;
            background: linear-gradient(135deg, #a5b4fc, #818cf8);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            letter-spacing: -0.3px;
        }

        .sidebar-header p {
            font-size: 0.7rem;
            opacity: 0.6;
            margin-top: 4px;
        }

        .sidebar-menu {
            flex: 1;
            padding: 0 16px;
        }

        .menu-item {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 10px 16px;
            margin: 4px 0;
            border-radius: 12px;
            color: #cbd5e1;
            text-decoration: none;
            transition: all 0.2s ease;
            font-weight: 500;
            font-size: 0.9rem;
        }

        .menu-item i {
            width: 24px;
            font-size: 1.1rem;
            text-align: center;
        }

        .menu-item:hover {
            background: rgba(255,255,255,0.08);
            color: white;
            transform: translateX(4px);
        }

        .menu-item.active {
            background: linear-gradient(95deg, rgba(59,130,246,0.2), rgba(139,92,246,0.1));
            color: white;
            border-left: 3px solid #3b82f6;
        }

        .sidebar-footer {
            padding: 20px 16px;
            border-top: 1px solid rgba(255,255,255,0.08);
            margin-top: auto;
        }

        .user-profile {
            display: flex;
            align-items: center;
            gap: 12px;
            background: rgba(255,255,255,0.05);
            border-radius: 40px;
            padding: 8px 12px;
            transition: 0.2s;
        }

        .user-avatar img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .user-info {
            flex: 1;
        }

        .user-name {
            font-weight: 600;
            font-size: 0.85rem;
            color: white;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .user-role {
            font-size: 0.7rem;
            opacity: 0.7;
        }

        .logout-icon {
            color: #f87171;
            font-size: 1rem;
            transition: 0.2s;
            text-decoration: none;
        }

        .main-content {
            margin-left: 250px;
            padding: 28px 32px;
        }

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

        .page-title h1 {
            font-size: 1.8rem;
            font-weight: 700;
            background: linear-gradient(135deg, #1e293b, #3b82f6);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 20px;
        }
        .user-name { font-weight: 600; color: #1e293b; }
        .avatar {
            width: 44px;
            height: 44px;
            background: linear-gradient(135deg, #3b82f6, #8b5cf6);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 1.2rem;
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
        .logout-btn:hover { background: #dc2626; transform: translateY(-2px); }

        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 24px;
            margin-bottom: 32px;
        }
        .kpi-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(8px);
            border-radius: 28px;
            padding: 20px;
            text-align: center;
            transition: all 0.3s;
            border: 1px solid rgba(255,255,255,0.5);
            box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05);
        }
        .kpi-card:hover { transform: translateY(-5px); background: white; }
        .kpi-value { font-size: 2.2rem; font-weight: 700; color: #0f172a; }
        .kpi-label { font-size: 0.8rem; text-transform: uppercase; font-weight: 600; color: #5b6e8c; margin-top: 8px; }
        .positive { color: #10b981; }
        .negative { color: #ef4444; }
        .risk-card { border-left: 4px solid #ef4444; background: rgba(254,226,226,0.9); }

        .projection-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 20px;
            margin-bottom: 32px;
        }
        .proj-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 24px;
            padding: 20px;
            text-align: center;
            transition: transform 0.2s;
            box-shadow: 0 10px 15px -5px rgba(0,0,0,0.1);
        }
        .proj-card:hover { transform: translateY(-4px); }
        .proj-label { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 1px; opacity: 0.9; }
        .proj-value { font-size: 1.8rem; font-weight: 700; margin: 8px 0; }
        .proj-note { font-size: 0.7rem; opacity: 0.8; }

        .row { display: flex; flex-wrap: wrap; gap: 24px; margin-bottom: 32px; }
        .col { flex: 1; min-width: 300px; }
        .chart-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(8px);
            border-radius: 28px;
            padding: 20px;
            transition: all 0.2s;
            border: 1px solid rgba(255,255,255,0.5);
            box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05);
        }
        .chart-card:hover { transform: translateY(-3px); }
        .chart-title {
            font-weight: 600;
            font-size: 1.1rem;
            margin-bottom: 18px;
            display: flex;
            align-items: center;
            gap: 8px;
            border-left: 4px solid #3b82f6;
            padding-left: 12px;
        }
        canvas { max-height: 280px; width: 100%; }

        .table-wrapper {
            overflow-x: auto;
            border-radius: 20px;
            background: white;
            border: 1px solid #e2e8f0;
        }
        table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
        th { background: #f1f5f9; padding: 14px 16px; text-align: left; font-weight: 600; color: #1e293b; }
        td { padding: 12px 16px; border-bottom: 1px solid #e2e8f0; color: #334155; }
        tr:last-child td { border-bottom: none; }
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 40px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        .stats-inline {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            margin-top: 16px;
        }
        .stat-item {
            background: #f8fafc;
            padding: 12px;
            border-radius: 20px;
            flex: 1;
            text-align: center;
        }
        .stat-number { font-size: 1.4rem; font-weight: 700; }
        .small-text { font-size: 0.8rem; color: #475569; margin-top: 8px; }
        .warning-badge {
            background: #fef3c7;
            color: #d97706;
            padding: 4px 12px;
            border-radius: 40px;
            font-size: 0.75rem;
            font-weight: 600;
            display: inline-block;
        }
        /* Product tables alignment */
        .product-table {
            width: 100%;
            table-layout: fixed;
        }
        .product-table th:first-child, .product-table td:first-child {
            width: 70%;
        }
        .product-table th:last-child, .product-table td:last-child {
            width: 30%;
        }
        @media (max-width: 768px) {
            .sidebar { width: 70px; }
            .sidebar-header h2, .sidebar-header p, .menu-item span, .sidebar-footer { display: none; }
            .main-content { margin-left: 70px; padding: 16px; }
        }
    </style>
</head>
<body>

<!-- SIDEBAR (same) -->
<div class="sidebar">
    <div class="sidebar-header"><h2>Seilatsatsi</h2><p>Financial Intelligence</p></div>
    <div class="sidebar-menu">
        <a href="${pageContext.request.contextPath}/dashboard" class="menu-item active"><i class="fas fa-tachometer-alt"></i><span>Dashboard</span></a>
        <a href="${pageContext.request.contextPath}/orders" class="menu-item"><i class="fas fa-shopping-cart"></i><span>Orders</span></a>
        <a href="${pageContext.request.contextPath}/products" class="menu-item"><i class="fas fa-box"></i><span>Products</span></a>
        <a href="${pageContext.request.contextPath}/customers" class="menu-item"><i class="fas fa-users"></i><span>Customers</span></a>
        <a href="${pageContext.request.contextPath}/expenses" class="menu-item"><i class="fas fa-money-bill-wave"></i><span>Expenses</span></a>
        <a href="${pageContext.request.contextPath}/reports" class="menu-item"><i class="fas fa-chart-line"></i><span>Reports</span></a>
        <a href="${pageContext.request.contextPath}/support" class="menu-item"><i class="fas fa-headset"></i><span>Support</span></a>
        <% if (isManager) { %>
        <a href="${pageContext.request.contextPath}/register" class="menu-item"><i class="fas fa-user-plus"></i><span>Register User</span></a>
        <% } %>
    </div>
    <div class="sidebar-footer">
        <div class="user-profile">
            <div class="user-avatar"><img src="${pageContext.request.contextPath}/images/avatar.png" alt="avatar" onerror="this.src='https://ui-avatars.com/api/?background=3b82f6&color=fff&rounded=true&size=40&name=<%= userFullName %>'"></div>
            <div class="user-info"><div class="user-name"><%= userFullName %></div><div class="user-role"><%= currentUser.getRole() %></div></div>
            <a href="${pageContext.request.contextPath}/logout" class="logout-icon" title="Logout"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</div>

<div class="main-content">
    <div class="top-bar">
        <div class="page-title"><h1>📊 Advanced Analytics Dashboard</h1><p>Welcome, <%= userFullName %> – Financial Intelligence & Risk Monitoring</p></div>
        <div class="user-info"><span class="user-name"><%= userFullName %></span><div class="avatar"><%= userInitial %></div><a href="${pageContext.request.contextPath}/logout" class="logout-btn"><i class="fas fa-sign-out-alt"></i> Logout</a></div>
    </div>

    <!-- KPI Dashboard -->
    <div class="kpi-grid">
        <div class="kpi-card"><div class="kpi-value"><%= String.format("%.1f", profitMargin) %>%</div><div class="kpi-label">Profit Margin</div><div class="small-text">Target >20%</div></div>
        <div class="kpi-card"><div class="kpi-value"><%= String.format("%.1f", expenseToRevenueRatio) %>%</div><div class="kpi-label">Expense/Revenue Ratio</div><div class="small-text"><%= expenseToRevenueRatio > 70 ? "⚠️ High" : "Good" %></div></div>
        <div class="kpi-card"><div class="kpi-value"><%= String.format("%.1f", revenueGrowthRate) %>%</div><div class="kpi-label">Revenue Growth (MoM)</div><div class="small-text <%= revenueGrowthRate >= 0 ? "positive" : "negative" %>"><%= revenueGrowthRate >= 0 ? "↑ Up" : "↓ Down" %> vs last month</div></div>
        <div class="kpi-card"><div class="kpi-value"><%= String.format("%.1f", roi) %>%</div><div class="kpi-label">Return on Investment (ROI)</div><div class="small-text">Based on initial M20,900</div></div>
        <div class="kpi-card risk-card"><div class="kpi-value"><%= overduePayments %></div><div class="kpi-label">Overdue Payments</div><div class="small-text"><%= overduePayments > 0 ? "⚠️ Action required" : "✅ All current" %></div></div>
    </div>

    <!-- Projection Cards -->
    <div class="projection-grid">
        <div class="proj-card"><div class="proj-label"><i class="fas fa-calendar-week"></i> Weekly Revenue Forecast</div><div class="proj-value">M <%= String.format("%,.0f", weeklyForecast) %></div><div class="proj-note">Based on average of last 4 weeks</div></div>
        <div class="proj-card"><div class="proj-label"><i class="fas fa-calendar-alt"></i> Monthly Revenue Forecast</div><div class="proj-value">M <%= String.format("%,.0f", monthlyForecast) %></div><div class="proj-note">3‑month moving average</div></div>
        <div class="proj-card"><div class="proj-label"><i class="fas fa-calendar-year"></i> Annual Revenue Projection</div><div class="proj-value">M <%= String.format("%,.0f", yearlyForecast) %></div><div class="proj-note">Annualised from last 6 months</div></div>
    </div>

    <!-- Variance Analysis -->
    <div class="row">
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-chart-line" style="color:#3b82f6"></i> Variance Analysis – Revenue</div><div class="stats-inline"><div class="stat-item"><span class="stat-number">M <%= String.format("%,.0f", budgetedRevenue) %></span><br>Budgeted</div><div class="stat-item"><span class="stat-number">M <%= String.format("%,.0f", actualRevenue) %></span><br>Actual</div><div class="stat-item"><span class="stat-number <%= revenueVariancePercent >= 0 ? "positive" : "negative" %>"><%= String.format("%+.1f", revenueVariancePercent) %>%</span><br>Variance</div></div><div class="small-text"><%= revenueVariancePercent >= 0 ? "✅ Revenue exceeded budget. Great performance!" : "⚠️ Revenue below budget. Investigate sales slowdown." %></div></div></div>
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-chart-line" style="color:#ef4444"></i> Variance Analysis – Expenses</div><div class="stats-inline"><div class="stat-item"><span class="stat-number">M <%= String.format("%,.0f", budgetedExpense) %></span><br>Budgeted</div><div class="stat-item"><span class="stat-number">M <%= String.format("%,.0f", actualExpense) %></span><br>Actual</div><div class="stat-item"><span class="stat-number <%= expenseVariancePercent <= 0 ? "positive" : "negative" %>"><%= String.format("%+.1f", expenseVariancePercent) %>%</span><br>Variance</div></div><div class="small-text"><%= expenseVariancePercent <= 0 ? "✅ Expenses are under control." : "⚠️ Expenses exceeded budget. Review cost drivers." %></div></div></div>
    </div>

    <!-- Customer Analysis -->
    <div class="row">
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-users"></i> Top 5 Customers by Spending</div><div class="table-wrapper"><table><thead><tr><th>Customer</th><th>Spent (M)</th><th>Orders</th><th>% of Revenue</th></tr></thead><tbody><% for (Map<String, Object> cust : topCustomers) { double percent = (Double)cust.get("spent")/totalRevenue*100; %><tr><td><%= cust.get("name") %></td><td>M <%= String.format("%,.2f", cust.get("spent")) %></td><td><%= cust.get("orders") %></td><td><%= String.format("%.1f", percent) %>%</td></tr><% } if(topCustomers.isEmpty()){ %><tr><td colspan="4">No customer data</td></tr><% } %></tbody></table></div><div class="small-text">Top customer contributes <strong><%= String.format("%.1f", topCustomerContribution) %>%</strong> of total revenue.</div></div></div>
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-chart-pie"></i> New vs Returning Customers</div><canvas id="customerPieChart" style="max-height: 220px;"></canvas><div class="small-text">Returning customers: <strong><%= returningCustomers %></strong> – retention rate <%= totalCustomers > 0 ? String.format("%.1f", (double)returningCustomers/totalCustomers*100) : "0" %>%.</div></div></div>
    </div>

    <!-- Product Analysis (corrected tables aligned) -->
    <div class="row">
        <div class="col">
            <div class="chart-card">
                <div class="chart-title"><i class="fas fa-trophy" style="color:#f59e0b"></i> Best‑Selling Products (Top 5)</div>
                <div class="table-wrapper">
                    <table class="product-table">
                        <colgroup><col style="width:70%"><col style="width:30%"></colgroup>
                        <thead><tr><th>Product</th><th>Revenue (M)</th></tr></thead>
                        <tbody>
                            <% for (Map<String, Object> p : bestProducts) { %>
                                <tr><td><%= p.get("name") %></td><td>M <%= String.format("%,.2f", p.get("revenue")) %></td></tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="col">
            <div class="chart-card">
                <div class="chart-title"><i class="fas fa-exclamation-triangle" style="color:#ef4444"></i> Underperforming Products</div>
                <div class="table-wrapper">
                    <table class="product-table">
                        <colgroup><col style="width:70%"><col style="width:30%"></colgroup>
                        <thead><tr><th>Product</th><th>Revenue (M)</th></tr></thead>
                        <tbody>
                            <% for (Map<String, Object> p : worstProducts) { %>
                                <tr><td><%= p.get("name") %></td><td class="profit-negative">M <%= String.format("%,.2f", p.get("revenue")) %></td></tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Expense & Seasonal -->
    <div class="row">
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-chart-pie"></i> Expense Breakdown by Category</div><canvas id="expensePieChart"></canvas><div class="small-text">Largest category: <strong><%= expenseCategories.entrySet().stream().max(Map.Entry.comparingByValue()).map(e -> e.getKey()).orElse("none") %></strong> – focus cost control here.</div></div></div>
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-calendar-alt"></i> Seasonal Revenue (Last 12 months)</div><canvas id="seasonalChart"></canvas><div class="small-text">Peak month: <strong><%= seasonalRevenue.entrySet().stream().max(Map.Entry.comparingByValue()).map(e -> e.getKey()).orElse("N/A") %></strong>. Plan inventory accordingly.</div></div></div>
    </div>

    <!-- Cash Flow & Profit Forecast -->
    <div class="row">
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-money-bill-wave"></i> Cash Flow (Last 6 months)</div><canvas id="cashFlowChart"></canvas><div class="small-text">Positive cash flow in <strong><%= positiveCashFlowMonths %></strong> of last 6 months. <%= positiveCashFlowMonths >= 4 ? "✅ Healthy liquidity." : "⚠️ Monitor cash closely." %></div></div></div>
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-chart-line"></i> Profit Trend & Forecast</div><canvas id="profitForecastChart"></canvas><div class="small-text">Forecasted next month revenue: <strong>M <%= String.format("%,.0f", monthlyForecast) %></strong> (3‑month moving average).</div></div></div>
    </div>

    <!-- Risk Dashboard & Profit Trend -->
    <div class="row">
        <div class="col"><div class="chart-card risk-card"><div class="chart-title"><i class="fas fa-exclamation-triangle"></i> Risk Dashboard</div><div class="stats-inline"><div class="stat-item"><span class="stat-number"><%= overduePayments %></span><br>Overdue Payments</div><div class="stat-item"><span class="stat-number"><%= lowCashReserve ? "< M5,000" : "> M5,000" %></span><br>Cash Reserve (last month)</div><div class="stat-item"><span class="stat-number"><%= profitDeclining ? "Declining" : "Stable/Increasing" %></span><br>Profit Trend</div></div><div class="small-text"><% if (overduePayments > 0) { %><span class="warning-badge"><i class="fas fa-flag"></i> Overdue payments need follow‑up.</span> <% } %><% if (lowCashReserve) { %><span class="warning-badge"><i class="fas fa-chart-line"></i> Cash reserve low – reduce discretionary spending.</span> <% } %><% if (profitDeclining) { %><span class="warning-badge"><i class="fas fa-chart-line"></i> Profit trend declining – analyse margins.</span> <% } %></div></div></div>
        <div class="col"><div class="chart-card"><div class="chart-title"><i class="fas fa-chart-line"></i> Monthly Profit Trend (Last 6 months)</div><canvas id="profitTrendChart"></canvas></div></div>
    </div>

    <!-- Recent Orders -->
    <div class="chart-card"><div class="chart-title"><i class="fas fa-table-list"></i> Recent Orders</div><div class="table-wrapper"><table><thead><tr><th>ID</th><th>Customer</th><th>Product</th><th>Amount (M)</th><th>Status</th></tr></thead><tbody><% for (Order order : recentOrders) { %><tr><td><%= order.getOrderId() %></td><td><%= order.getCustomerName() %></td><td><%= order.getProductName() %></td><td>M <%= order.getTotalCustomerPrice() %></td><td><span class="badge" style="background:<%= "delivered".equals(order.getOrderStatus()) ? "#dcfce7" : "#fff3cd" %>"><%= order.getOrderStatus() %></span></td></tr><% } %></tbody></table></div></div>
</div>

<script>
    const customerPieData = [<%= newCustomers %>, <%= returningCustomers %>];
    const expenseLabels = [<% for (String cat : expenseCategories.keySet()) { %>'<%= cat %>',<% } %>];
    const expenseValues = [<% for (Double v : expenseCategories.values()) { %><%= v %>,<% } %>];
    const seasonalLabels = [<% for (String m : seasonalRevenue.keySet()) { %>'<%= m %>',<% } %>];
    const seasonalData = [<% for (Double v : seasonalRevenue.values()) { %><%= v %>,<% } %>];
    const cashFlowLabels = [<% for (String m : cashFlow.keySet()) { %>'<%= m %>',<% } %>];
    const inflowData = [<% for (Double[] arr : cashFlow.values()) { %><%= arr[0] %>,<% } %>];
    const outflowData = [<% for (Double[] arr : cashFlow.values()) { %><%= arr[1] %>,<% } %>];
    const profitTrendLabels = [<% for (String m : monthlyProfitTrend.keySet()) { %>'<%= m %>',<% } %>];
    const profitTrendData = [<% for (Double v : monthlyProfitTrend.values()) { %><%= v %>,<% } %>];
    const monthlyForecastValue = <%= monthlyForecast %>;
    const extendedLabels = [...profitTrendLabels, 'Forecast Next Month'];
    const extendedData = [...profitTrendData, monthlyForecastValue];

    new Chart(document.getElementById('customerPieChart'), { type: 'pie', data: { labels: ['New Customers', 'Returning Customers'], datasets: [{ data: customerPieData, backgroundColor: ['#3b82f6', '#f97316'] }] } });
    new Chart(document.getElementById('expensePieChart'), { type: 'pie', data: { labels: expenseLabels, datasets: [{ data: expenseValues, backgroundColor: ['#3b82f6', '#f97316', '#8b5cf6', '#10b981', '#ef4444', '#f59e0b'] }] } });
    new Chart(document.getElementById('seasonalChart'), { type: 'line', data: { labels: seasonalLabels, datasets: [{ label: 'Revenue (M)', data: seasonalData, borderColor: '#3b82f6', fill: false, tension: 0.2 }] } });
    new Chart(document.getElementById('cashFlowChart'), { type: 'bar', data: { labels: cashFlowLabels, datasets: [{ label: 'Cash Inflow', data: inflowData, backgroundColor: '#10b981' }, { label: 'Cash Outflow', data: outflowData, backgroundColor: '#ef4444' }] } });
    new Chart(document.getElementById('profitTrendChart'), { type: 'line', data: { labels: profitTrendLabels, datasets: [{ label: 'Profit (M)', data: profitTrendData, borderColor: '#8b5cf6', fill: false }] } });
    new Chart(document.getElementById('profitForecastChart'), { type: 'line', data: { labels: extendedLabels, datasets: [{ label: 'Profit (M) & Forecast', data: extendedData, borderColor: '#3b82f6', borderDash: [5, 5], pointBackgroundColor: '#3b82f6' }] } });
</script>

</body>
</html>