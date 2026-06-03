package com.seilatsatsi.model;

import java.math.BigDecimal;

public class Product {
    private int productId;
    private String productName;
    private String supplier;
    private BigDecimal supplierPrice;
    private BigDecimal sellingPrice;
    private String category;
    
    public Product() {}
    
    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }
    
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    
    public String getSupplier() { return supplier; }
    public void setSupplier(String supplier) { this.supplier = supplier; }
    
    public BigDecimal getSupplierPrice() { return supplierPrice; }
    public void setSupplierPrice(BigDecimal supplierPrice) { this.supplierPrice = supplierPrice; }
    
    public BigDecimal getSellingPrice() { return sellingPrice; }
    public void setSellingPrice(BigDecimal sellingPrice) { this.sellingPrice = sellingPrice; }
    
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    
    public BigDecimal getProfit() {
        return sellingPrice.subtract(supplierPrice);
    }
}