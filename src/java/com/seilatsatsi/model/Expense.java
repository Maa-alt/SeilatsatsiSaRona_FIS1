package com.seilatsatsi.model;

import java.math.BigDecimal;
import java.sql.Date;

public class Expense {
    private int expenseId;
    private Date expenseDate;
    private String category;
    private BigDecimal amount;
    private String description;
    
    public Expense() {}
    
    public int getExpenseId() { return expenseId; }
    public void setExpenseId(int expenseId) { this.expenseId = expenseId; }
    
    public Date getExpenseDate() { return expenseDate; }
    public void setExpenseDate(Date expenseDate) { this.expenseDate = expenseDate; }
    
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}