/*
 * Programmer: Krish Karki (w10186215)
 * Course: CSC 411/511 Database Management Systems H002
 * Project: Retail Enterprise Database System
 *
 * This class is responsible for loading all database and server configuration
 * values from the database.properties file.
 *
 * It ensures that required properties such as db.url and db.user are present,
 * and throws clear errors if anything is missing so the application does not
 * fail silently.
 *
 * I used this approach so that the database URL, username, password, and server
 * port stay in one place instead of being hardcoded throughout the application,
 * making the system easier to maintain and modify.
 */

package edu.csc411.retail;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public final class DatabaseConfig {

    private final String jdbcUrl;
    private final String jdbcUser;
    private final String jdbcPassword;
    private final int serverPort;

    public DatabaseConfig() {
        Properties props = new Properties();
        try (InputStream in = DatabaseConfig.class.getClassLoader()
                .getResourceAsStream("database.properties")) {
            if (in == null) {
                throw new IllegalStateException(
                        "Missing database.properties on classpath (src/main/resources)");
            }
            props.load(in);
        } catch (IOException e) {
            throw new IllegalStateException("Could not read database.properties", e);
        }

        this.jdbcUrl = require(props, "db.url");
        this.jdbcUser = require(props, "db.user");
        if (!props.containsKey("db.password")) {
            throw new IllegalStateException(
                "database.properties must include db.password (can be empty if no password is used)"
            );
        }
        // Trim to avoid whitespace issues; empty string means no password
        this.jdbcPassword = props.getProperty("db.password", "").trim();
        this.serverPort = Integer.parseInt(
                props.getProperty("server.port", "8080").trim());
    }

    private static String require(Properties p, String key) {
        String v = p.getProperty(key);
        if (v == null || v.isBlank()) {
            throw new IllegalStateException("database.properties missing required key: " + key);
        }
        return v.trim();
    }

    public String getJdbcUrl() {
        return jdbcUrl;
    }

    public String getJdbcUser() {
        return jdbcUser;
    }

    public String getJdbcPassword() {
        return jdbcPassword;
    }

    public int getServerPort() {
        return serverPort;
    }
}
