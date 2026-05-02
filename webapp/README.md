# CSC 411 — Retail Enterprise Web UI

Simple **Java (JDBC)** backend with an **HTML/CSS** front end. It runs the five analytical queries from `03_required_queries.sql` against your MySQL database and shows results as HTML tables.

No servlet container or heavy framework: the app uses the JDK built-in `com.sun.net.httpserver.HttpServer`.

## Prerequisites

1. **Java 17+** and **Apache Maven**
2. **MySQL 8.x** with the course database loaded **in order**:
   - `01_create_tables.sql`
   - `02_insert_sample_data.sql`
   - `03_required_queries.sql` (defines the queries you prove in SQL; the webapp embeds the same SQL text in Java)

## Configure MySQL connection

Edit **`src/main/resources/database.properties`**:

| Property       | Meaning                                           |
|----------------|---------------------------------------------------|
| `db.url`       | JDBC URL; default database `retail_enterprise`    |
| `db.user`      | MySQL username                                    |
| `db.password`  | MySQL password (replace placeholder in the file) |
| `server.port`  | HTTP port for this app (default `8080`)           |

Example:

```properties
db.url=jdbc:mysql://localhost:3306/retail_enterprise?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
db.user=root
db.password=your_actual_password
server.port=8080
```

## Build

From the **`webapp/`** directory:

```bash
cd webapp
mvn -q package
```

This compiles the project and copies dependencies into `target/lib/` for classpath runs.

## Run

**Option A — Maven Exec (easiest during development)**

```bash
cd webapp
mvn -q exec:java
```

**Option B — Java command line**

```bash
cd webapp
mvn -q package
java -cp "target/classes:target/lib/*" edu.csc411.retail.RetailWebServer
```

(On Windows CMD, use `;` instead of `:` in the classpath.)

Then open a browser: **http://localhost:8080/**

Click each button to run queries **1–5**; results appear under the buttons.

## Stop the server

Press **Ctrl+C** in the terminal where `RetailWebServer` is running.

## Project layout

```
webapp/
├── pom.xml
├── README.md
├── src/main/java/edu/csc411/retail/
│   ├── DatabaseConfig.java      # Loads database.properties
│   ├── RequiredQueries.java     # SQL strings (aligned with 03_required_queries.sql)
│   ├── QueryService.java        # JDBC → HTML table
│   ├── HtmlEscape.java
│   └── RetailWebServer.java     # HTTP server + routing
└── src/main/resources/
    ├── database.properties
    └── static/
        ├── index.html
        └── style.css
```

## Keeping queries in sync

If your instructor updates **`03_required_queries.sql`**, update the matching constants in **`RequiredQueries.java`** so the web UI and graded SQL file stay aligned. The assignment SQL files in the repo root are **not** modified by this webapp.

## Troubleshooting

| Issue              | What to check                                              |
|--------------------|------------------------------------------------------------|
| Connection refused | MySQL running? Host/port in `db.url`?                       |
| Access denied      | Set `db.password` in `database.properties` to match MySQL   |
| Unknown database   | Run `01_create_tables.sql` (creates `retail_enterprise`)   |
| Empty or wrong results | Run `02_insert_sample_data.sql`; verify data           |
| Port in use        | Change `server.port` in `database.properties`              |
