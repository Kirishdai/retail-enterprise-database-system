# Retail Enterprise Database System

## Overview
This project is a full-stack database application built for CSC 411/511 (Database Management Systems). It simulates a real-world retail enterprise system and provides analytical insights using SQL and a Java-based web interface.

The system integrates a relational database (MySQL), advanced SQL queries, and a lightweight Java web server to deliver interactive data analysis.

---

## Features
- Designed and implemented a normalized relational database schema
- Inserted realistic sample data to simulate retail operations
- Developed advanced SQL queries using:
  - Joins
  - Aggregations
  - Window functions
  - Common Table Expressions (CTEs)
- Built a Java JDBC-based web application to execute queries
- Created an interactive UI to display results dynamically
- Performed business analytics such as:
  - Top-selling products
  - Store performance
  - Brand comparison (Coke vs Pepsi)
  - Market basket analysis

---

## Tech Stack
- Database: MySQL
- Backend: Java (JDBC)
- Web Server: Java built-in HttpServer
- Frontend: HTML, CSS, JavaScript
- Build Tool: Maven

---

## Project Structure
```
courseproject/
├── er_diagram/
│   ├── er_diagram.drawio
│   └── er_diagram.pdf
├── sql/
│   ├── 01_schema.sql
│   ├── 02_sample_data.sql
│   └── 03_required_queries.sql
├── webapp/
│   ├── pom.xml
│   └── src/
└── README.md
```
---

## How to Run

### 1. Setup Database
Run the SQL files in order:

```sql 
01_schema.sql 
02_sample_data.sql 
03_required_queries.sql 
```
### 2. Configure Database Connection
Edit:
webapp/src/main/resources/database.properties

Update:
db.user=your_username 
db.password=your_password

---

### 3. Run the Web Application
From the webapp directory:

bash 
mvn clean package
java -cp "target/retail-enterprise-webapp-1.0-SNAPSHOT.jar:target/lib/*" edu.csc411.retail.RetailWebServer

Open in browser:
http://localhost:8080

---

## Implemented Queries

1. Top 20 selling products at each store  
2. Top 20 selling products in each state  
3. Top 5 stores with highest sales this year  
4. Count of stores where Coke outsells Pepsi  
5. Top 3 products frequently bought with milk  

---

## Key Learnings
- Practical database design and normalization
- Writing complex analytical SQL queries
- Integrating Java with MySQL using JDBC
- Building a lightweight web server without frameworks
- Structuring a full-stack academic project like an industry system

---

## Author
Krish Karki  
CSC 411/511 — Database Management Systems  
University of Southern Mississippi
