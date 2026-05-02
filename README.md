# Retail Enterprise Database Project

## Student
Krish Karki

## Course
CSC 411 / 511

---

## Overview
This project implements a retail enterprise database system that supports multiple stores, products, vendors, customers, and sales.

The system includes:
- ER Diagram
- Relational Schema (MySQL)
- Sample Data
- Required SQL Queries
- Java JDBC Web Application

---

## Project Structure

courseproject/
├── er_diagram/
├── sql/
├── webapp/
├── results/
├── report/
├── README.md

---

## How to Run

1. Create Database

mysql -u root -p < sql/retail_enterprise_schema.sql

2. Insert Data

mysql -u root -p < sql/02_insert_sample_data.sql

3. Run Web Application

cd webapp
mvn clean package
mvn exec:java

Open browser:
http://localhost:8080/

---

## Queries Implemented

1. Top 20 selling products per store  
2. Top 20 selling products per state  
3. Top 5 stores with highest sales  
4. Coke vs Pepsi comparison  
5. Products bought together with milk  

---

## Notes

- INVENTORY and SALE_ITEM use composite primary keys  
- SALE.customer_id is nullable to allow anonymous customers  
- The web UI is used to demonstrate query results  

---

## Technologies Used

- MySQL  
- Java (JDBC)  
- Maven  
- HTML / CSS  
- draw.io  