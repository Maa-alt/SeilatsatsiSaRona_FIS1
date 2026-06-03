package com.seilatsatsi.model;

import java.math.BigDecimal;
import java.sql.Date;

public class Order {
    private int orderId;
    private int customerId;
    private String customerName;
    private int productId;
    private String productName;
    private int quantity;
    private BigDecimal totalCustomerPrice;
    private BigDecimal totalSupplierCost;
    private BigDecimal profit;
    private String paymentStatus;
    private String orderStatus;
    private BigDecimal deliveryFee;
    private Date orderDate;
    
    // Constructors
    public Order() {}
    
    // Getters and Setters
    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }
    
    public int getCustomerId() { return customerId; }
    public void setCustomerId(int customerId) { this.customerId = customerId; }
    
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    
    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }
    
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    
    public BigDecimal getTotalCustomerPrice() { return totalCustomerPrice; }
    public void setTotalCustomerPrice(BigDecimal totalCustomerPrice) { this.totalCustomerPrice = totalCustomerPrice; }
    
    public BigDecimal getTotalSupplierCost() { return totalSupplierCost; }
    public void setTotalSupplierCost(BigDecimal totalSupplierCost) { this.totalSupplierCost = totalSupplierCost; }
    
    public BigDecimal getProfit() { return profit; }
    public void setProfit(BigDecimal profit) { this.profit = profit; }
    
    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }
    
    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }
    
    public BigDecimal getDeliveryFee() { return deliveryFee; }
    public void setDeliveryFee(BigDecimal deliveryFee) { this.deliveryFee = deliveryFee; }
    
    public Date getOrderDate() { return orderDate; }
    public void setOrderDate(Date orderDate) { this.orderDate = orderDate; }
}