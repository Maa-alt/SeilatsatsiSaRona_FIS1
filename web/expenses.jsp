<%@ page import="com.seilatsatsi.dao.ExpenseDAO" %>
<%@ page import="com.seilatsatsi.model.Expense" %>
<%@ page import="com.seilatsatsi.model.User" %>
<%@ page import="java.util.List" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    boolean isManager = "MANAGER".equals(currentUser.getRole());

    ExpenseDAO expenseDAO = new ExpenseDAO();
    List<Expense> expenses = expenseDAO.getAllExpenses();
    
    // Calculate totals
    double totalExpenses = 0;
    if (expenses != null) {
        for (Expense e : expenses) {
            totalExpenses += e.getAmount().doubleValue();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seilatsatsi FIS - Expenses</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:opsz,wght@14..32,300;14..32,400;14..32,500;14..32,600;14..32,700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: url('https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?q=80&w=2070&auto=format&fit=crop') no-repeat center center fixed;
            background-size: cover;
            position: relative;
            min-height: 100vh;
        }

        body::before {
            content: "";
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.45);
            z-index: -1;
        }

        /* Sidebar */
        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            width: 260px;
            height: 100%;
            background: rgba(26, 26, 46, 0.95);
            backdrop-filter: blur(8px);
            color: white;
            z-index: 100;
            box-shadow: 2px 0 20px rgba(0,0,0,0.2);
            border-right: 1px solid rgba(255,255,255,0.1);
        }

        .sidebar-header {
            padding: 28px 20px;
            text-align: center;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }

        .sidebar-header h2 {
            font-size: 22px;
            font-weight: 600;
            letter-spacing: -0.5px;
            margin-bottom: 5px;
        }

        .sidebar-header p {
            font-size: 12px;
            opacity: 0.7;
        }

        .sidebar-menu {
            padding: 20px 0;
        }

        .menu-item {
            padding: 12px 24px;
            display: flex;
            align-items: center;
            gap: 14px;
            color: rgba(255,255,255,0.8);
            text-decoration: none;
            transition: all 0.2s ease;
            border-left: 3px solid transparent;
        }

        .menu-item:hover, .menu-item.active {
            background: rgba(255,255,255,0.1);
            color: white;
            border-left-color: #3b82f6;
        }

        .menu-item i {
            width: 22px;
            font-size: 1.2rem;
        }

        /* Main content */
        .main-content {
            margin-left: 260px;
            padding: 28px 32px;
        }

        /* Top bar */
        .top-bar {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(4px);
            border-radius: 24px;
            padding: 16px 28px;
            margin-bottom: 28px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 8px 20px rgba(0,0,0,0.08);
            border: 1px solid rgba(255,255,255,0.3);
        }

        .page-title h1 {
            font-size: 1.8rem;
            font-weight: 700;
            color: #0f172a;
            letter-spacing: -0.5px;
        }

        .page-title p {
            color: #475569;
            font-size: 0.85rem;
            margin-top: 4px;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 18px;
        }

        .user-name {
            font-weight: 600;
            color: #1e293b;
        }

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
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .logout-btn {
            background: #ef4444;
            color: white;
            padding: 8px 16px;
            border-radius: 40px;
            text-decoration: none;
            font-size: 0.85rem;
            font-weight: 500;
            transition: all 0.2s;
        }

        .logout-btn:hover {
            background: #dc2626;
            transform: translateY(-1px);
        }

        /* Stats card */
        .stats-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(4px);
            border-radius: 28px;
            padding: 20px;
            margin-bottom: 28px;
            text-align: center;
            box-shadow: 0 12px 30px rgba(0,0,0,0.1);
            border: 1px solid rgba(255,255,255,0.3);
        }

        .stats-card h3 {
            color: #475569;
            font-size: 1rem;
            font-weight: 500;
            margin-bottom: 8px;
            letter-spacing: 0.3px;
        }

        .stats-card .amount {
            font-size: 2.5rem;
            font-weight: 700;
            color: #ef4444;
        }

        /* Expenses container */
        .expenses-container {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(4px);
            border-radius: 28px;
            padding: 24px;
            box-shadow: 0 12px 30px rgba(0,0,0,0.1);
            border: 1px solid rgba(255,255,255,0.3);
        }

        .table-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            flex-wrap: wrap;
            gap: 15px;
        }

        .table-header h3 {
            font-size: 1.4rem;
            font-weight: 600;
            color: #0f172a;
        }

        .btn-add {
            background: linear-gradient(135deg, #3b82f6, #8b5cf6);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 40px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-weight: 500;
            transition: all 0.2s;
            box-shadow: 0 2px 6px rgba(0,0,0,0.1);
        }

        .btn-add:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(59,130,246,0.3);
        }

        /* Alerts */
        .alert {
            padding: 14px 20px;
            border-radius: 20px;
            margin-bottom: 24px;
            font-size: 0.9rem;
            font-weight: 500;
        }

        .alert.success {
            background: #d1fae5;
            color: #065f46;
            border-left: 4px solid #10b981;
        }

        /* Modern table */
        .modern-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            overflow: hidden;
            border-radius: 20px;
        }

        .modern-table th {
            background: #f1f5f9;
            padding: 14px 16px;
            text-align: left;
            font-weight: 600;
            color: #1e293b;
            font-size: 0.85rem;
            letter-spacing: 0.3px;
        }

        .modern-table td {
            padding: 14px 16px;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
            font-size: 0.9rem;
        }

        .modern-table tr:last-child td {
            border-bottom: none;
        }

        .modern-table tr:hover td {
            background: #f8fafc;
        }

        /* Modal */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.6);
            backdrop-filter: blur(6px);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }

        .modal-content {
            background: white;
            border-radius: 32px;
            width: 500px;
            max-width: 90%;
            padding: 28px;
            box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
        }

        .modal-header h3 {
            font-size: 1.5rem;
            font-weight: 600;
            color: #0f172a;
        }

        .close-modal {
            cursor: pointer;
            font-size: 28px;
            line-height: 1;
            color: #94a3b8;
            transition: color 0.2s;
        }

        .close-modal:hover {
            color: #ef4444;
        }

        .form-group {
            margin-bottom: 18px;
        }

        .form-group label {
            display: block;
            margin-bottom: 6px;
            font-weight: 500;
            color: #1e293b;
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 12px 14px;
            border: 1px solid #cbd5e1;
            border-radius: 16px;
            font-family: inherit;
            font-size: 0.9rem;
            transition: all 0.2s;
            background: #fff;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59,130,246,0.1);
        }

        .btn-submit {
            background: linear-gradient(135deg, #3b82f6, #8b5cf6);
            color: white;
            border: none;
            padding: 12px;
            width: 100%;
            border-radius: 40px;
            cursor: pointer;
            font-weight: 600;
            font-size: 1rem;
            margin-top: 12px;
            transition: all 0.2s;
        }

        .btn-submit:hover {
            transform: translateY(-1px);
            box-shadow: 0 8px 20px rgba(59,130,246,0.3);
        }

        @media (max-width: 768px) {
            .sidebar {
                width: 70px;
            }
            .sidebar-header h2, .sidebar-header p, .menu-item span {
                display: none;
            }
            .main-content {
                margin-left: 70px;
                padding: 16px;
            }
            .modern-table th, .modern-table td {
                padding: 10px 12px;
                font-size: 0.75rem;
            }
        }
    </style>
</head>
<body>

<div class="sidebar">
    <div class="sidebar-header">
        <h2>Seilatsatsi</h2>
        <p>Financial Information System</p>
    </div>
    <div class="sidebar-menu">
        <a href="${pageContext.request.contextPath}/dashboard" class="menu-item">
            <i class="fas fa-tachometer-alt"></i><span>Dashboard</span>
        </a>
        <a href="${pageContext.request.contextPath}/orders" class="menu-item">
            <i class="fas fa-shopping-cart"></i><span>Orders</span>
        </a>
        <a href="${pageContext.request.contextPath}/products" class="menu-item">
            <i class="fas fa-box"></i><span>Products</span>
        </a>
        <a href="${pageContext.request.contextPath}/customers" class="menu-item">
            <i class="fas fa-users"></i><span>Customers</span>
        </a>
        <a href="${pageContext.request.contextPath}/expenses" class="menu-item active">
            <i class="fas fa-money-bill-wave"></i><span>Expenses</span>
        </a>
        <a href="${pageContext.request.contextPath}/reports" class="menu-item">
            <i class="fas fa-chart-line"></i><span>Reports</span>
        </a>
        <% if (isManager) { %>
        <a href="${pageContext.request.contextPath}/register" class="menu-item">
            <i class="fas fa-user-plus"></i><span>Register User</span>
        </a>
        <% } %>
    </div>
</div>

<div class="main-content">
    <div class="top-bar">
        <div class="page-title">
            <h1>Expense Tracking</h1>
            <p>Monitor and manage all business expenses</p>
        </div>
        <div class="user-info">
            <span class="user-name"><%= currentUser.getFullName() %></span>
            <div class="avatar"><%= currentUser.getFullName().charAt(0) %></div>
            <a href="${pageContext.request.contextPath}/logout" class="logout-btn"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </div>
    </div>

    <!-- Summary Card -->
    <div class="stats-card">
        <h3>Total Expenses</h3>
        <div class="amount">M <%= String.format("%,.2f", totalExpenses) %></div>
        <p class="small-text" style="margin-top: 8px; font-size: 0.8rem;">All recorded expenses</p>
    </div>

    <div class="expenses-container">
        <div class="table-header">
            <h3><i class="fas fa-receipt"></i> Expense List</h3>
            <button class="btn-add" onclick="openAddExpenseModal()">
                <i class="fas fa-plus"></i> Add Expense
            </button>
        </div>

        <% if ("added".equals(request.getParameter("success"))) { %>
            <div class="alert success">✓ Expense added successfully!</div>
        <% } %>

        <div style="overflow-x: auto;">
            <table class="modern-table">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Category</th>
                        <th>Amount (M)</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (expenses != null && !expenses.isEmpty()) { 
                        for (Expense expense : expenses) { 
                    %>
                        <tr>
                            <td><%= expense.getExpenseDate() %></td>
                            <td><%= expense.getCategory() %></td>
                            <td>M <%= String.format("%.2f", expense.getAmount()) %></td>
                            <td><%= expense.getDescription() != null ? expense.getDescription() : "-" %></td>
                        </tr>
                    <% } 
                    } else { %>
                        <tr><td colspan="4" style="text-align:center;">No expenses recorded</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Add Expense Modal -->
<div id="addExpenseModal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h3><i class="fas fa-plus-circle"></i> Add Expense</h3>
            <span class="close-modal" onclick="closeExpenseModal()">&times;</span>
        </div>
        <form action="${pageContext.request.contextPath}/expenses" method="post">
            <div class="form-group">
                <label>Category *</label>
                <select name="category" required>
                    <option value="Rent">Rent</option>
                    <option value="Electricity">Electricity</option>
                    <option value="Internet">Internet</option>
                    <option value="Marketing">Marketing</option>
                    <option value="Salaries">Salaries</option>
                    <option value="Packaging">Packaging</option>
                    <option value="Transport">Transport</option>
                    <option value="Other">Other</option>
                </select>
            </div>
            <div class="form-group">
                <label>Amount (M) *</label>
                <input type="number" step="0.01" name="amount" required placeholder="0.00">
            </div>
            <div class="form-group">
                <label>Description</label>
                <input type="text" name="description" placeholder="Optional description">
            </div>
            <button type="submit" class="btn-submit">Save Expense</button>
        </form>
    </div>
</div>

<script>
    function openAddExpenseModal() {
        document.getElementById('addExpenseModal').style.display = 'flex';
    }
    function closeExpenseModal() {
        document.getElementById('addExpenseModal').style.display = 'none';
    }
    window.onclick = function(event) {
        if (event.target.classList.contains('modal')) {
            closeExpenseModal();
        }
    }
</script>

</body>
</html>