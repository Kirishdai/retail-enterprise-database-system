package edu.csc411.retail;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/*
 * Programmer: Krish Karki (w10186215)
 * Course: CSC 411/511 Database Management Systems H002
 * Project: Retail Enterprise Database System
 *
 * This class is the main entry point for the web application. It starts a small
 * local HTTP server, serves the static HTML/CSS files, and handles requests to
 * run the five required analytical queries.
 *
 * I used Java's built-in HttpServer so the project can run locally without
 * needing Tomcat or another external web server.
 */

public final class RetailWebServer {

    private static final Pattern API_QUERY = Pattern.compile("^/api/(\\d+)/?$");

    public static void main(String[] args) throws IOException {
        DatabaseConfig dbConfig = new DatabaseConfig();
        QueryService queryService = new QueryService(dbConfig);

        int port = dbConfig.getServerPort();
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/", exchange -> handle(exchange, queryService));
        server.setExecutor(null);
        server.start();

        System.out.println("Retail Enterprise web UI: http://localhost:" + port + "/");
        System.out.println("Ensure MySQL is running and database.properties is configured.");
    }

    private static void handle(HttpExchange exchange, QueryService queryService) throws IOException {
        if (!"GET".equalsIgnoreCase(exchange.getRequestMethod())) {
            send(exchange, 405, "text/plain; charset=UTF-8", "Method not allowed".getBytes(StandardCharsets.UTF_8));
            return;
        }

        String path = exchange.getRequestURI().getPath();
        if (path == null) {
            path = "/";
        }

        Matcher api = API_QUERY.matcher(path);
        if (api.matches()) {
            int q = Integer.parseInt(api.group(1));
            if (q < 1 || q > 5) {
                send(exchange, 404, "text/plain; charset=UTF-8", "Unknown query".getBytes(StandardCharsets.UTF_8));
                return;
            }
            try {
                String html = queryService.runQueryAsHtmlTable(q);
                String wrapped = "<section class=\"query-output\">" + html + "</section>";
                send(exchange, 200, "text/html; charset=UTF-8", wrapped.getBytes(StandardCharsets.UTF_8));
            } catch (SQLException e) {
                e.printStackTrace();
                String msg = "<p class=\"error\">Database error: " + HtmlEscape.escape(e.getMessage()) + "</p>";
                send(exchange, 500, "text/html; charset=UTF-8", msg.getBytes(StandardCharsets.UTF_8));
            }
            return;
        }

        String resource;
        if ("/".equals(path)) {
            resource = "static/index.html";
        } else if ("/index.html".equals(path)) {
            resource = "static/index.html";
        } else if ("/style.css".equals(path)) {
            resource = "static/style.css";
        } else {
            send(exchange, 404, "text/plain; charset=UTF-8", "Not found".getBytes(StandardCharsets.UTF_8));
            return;
        }

        byte[] body = readClasspathResource(resource);
        if (body == null) {
            send(exchange, 404, "text/plain; charset=UTF-8", "Missing resource".getBytes(StandardCharsets.UTF_8));
            return;
        }
        String type = resource.endsWith(".css")
                ? "text/css; charset=UTF-8"
                : "text/html; charset=UTF-8";
        send(exchange, 200, type, body);
    }

    private static byte[] readClasspathResource(String classpathRelative) {
        try (InputStream in = RetailWebServer.class.getClassLoader().getResourceAsStream(classpathRelative)) {
            if (in == null) {
                return null;
            }
            return in.readAllBytes();
        } catch (IOException e) {
            return null;
        }
    }

    private static void send(HttpExchange exchange, int status, String contentType, byte[] body)
            throws IOException {
        exchange.getResponseHeaders().set("Content-Type", contentType);
        exchange.sendResponseHeaders(status, body.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(body);
        }
    }
}
