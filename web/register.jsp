<%@ page import="com.seilatsatsi.model.User" %>
<%
    // Check if user is logged in and has MANAGER role
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"MANAGER".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/dashboard");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register User - Seilatsatsi FIS</title>
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

        /* Form container */
        .form-container {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(4px);
            border-radius: 28px;
            padding: 32px;
            max-width: 500px;
            margin: 0 auto;
            box-shadow: 0 12px 30px rgba(0,0,0,0.1);
            border: 1px solid rgba(255,255,255,0.3);
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: #1e293b;
        }

        .form-group input,
        .form-group select {
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
        .form-group select:focus {
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
            margin-top: 8px;
            transition: all 0.2s;
        }

        .btn-submit:hover {
            transform: translateY(-1px);
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

        .alert-success {
            background: #d1fae5;
            color: #065f46;
            border-left: 4px solid #10b981;
        }

        .alert-error {
            background: #fee2e2;
            color: #991b1b;
            border-left: 4px solid #ef4444;
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
            .form-container {
                padding: 20px;
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
        <a href="${pageContext.request.contextPath}/register" class="menu-item active">
            <i class="fas fa-user-plus"></i><span>Register User</span>
        </a>
        <a href="${pageContext.request.contextPath}/expenses" class="menu-item">
            <i class="fas fa-money-bill-wave"></i><span>Expenses</span>
        </a>
        <a href="${pageContext.request.contextPath}/reports" class="menu-item">
            <i class="fas fa-chart-line"></i><span>Reports</span>
        </a>
    </div>
</div>

<div class="main-content">
    <div class="top-bar">
        <div class="page-title">
            <h1>Register New User</h1>
            <p>Add Manager or Assistant to the system</p>
        </div>
        <div class="user-info">
            <span class="user-name"><%= currentUser.getFullName() %></span>
            <div class="avatar"><%= currentUser.getFullName().charAt(0) %></div>
            <a href="${pageContext.request.contextPath}/logout" class="logout-btn"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </div>
    </div>

    <div class="form-container">
        <% if (request.getAttribute("success") != null) { %>
            <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getAttribute("success") %></div>
        <% } %>
        <% if (request.getAttribute("error") != null) { %>
            <div class="alert alert-error"><i class="fas fa-exclamation-triangle"></i> <%= request.getAttribute("error") %></div>
        <% } %>

        <form action="${pageContext.request.contextPath}/register" method="post">
            <div class="form-group">
                <label>Full Name *</label>
                <input type="text" name="fullName" placeholder="Enter full name" required>
            </div>
            <div class="form-group">
                <label>Username *</label>
                <input type="text" name="username" placeholder="Enter username" required>
            </div>
            <div class="form-group">
                <label>Password *</label>
                <input type="password" name="password" placeholder="Enter password" required>
            </div>
            <div class="form-group">
                <label>Role *</label>
                <select name="role" required>
                    <option value="">Select Role</option>
                    <option value="MANAGER">Manager</option>
                    <option value="ASSISTANT">Assistant</option>
                </select>
            </div>
            <button type="submit" class="btn-submit">
                <i class="fas fa-user-plus"></i> Register User
            </button>
        </form>
    </div>
</div>

</body>
</html>