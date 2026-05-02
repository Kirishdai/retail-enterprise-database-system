package edu.csc411.retail;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;

/*
 * Programmer: Krish Karki (w10186215)
 * Course: CSC 411/511 Database Management Systems H002
 * Project: Retail Enterprise Database System
 *
 * This class is responsible for executing the required SQL queries using JDBC
 * and converting the results into an HTML table format for display in the web UI.
 *
 * I used this class to separate database query execution from the web server logic,
 * making the code more organized and easier to maintain.
 */

public final class QueryService {

    private final DatabaseConfig config;

    public QueryService(DatabaseConfig config) {
        this.config = config;
    }

    /*
     * Executes one of the five required analytical queries based on the query number (1-5),
     * and returns the result formatted as an HTML table.
     */
    public String runQueryAsHtmlTable(int queryNumber) throws SQLException {
        try {
            // Load MySQL JDBC driver explicitly to ensure compatibility across environments
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC driver class not found", e);
        }
        String sql = RequiredQueries.sqlForQueryNumber(queryNumber);
        try (
                Connection conn = DriverManager.getConnection(
                        config.getJdbcUrl(),
                        config.getJdbcUser(),
                        config.getJdbcPassword());
                Statement st = conn.createStatement();
                ResultSet rs = st.executeQuery(sql)) {
            return resultSetToHtmlTable(rs);
        }
    }

    /**
     * Builds &lt;table&gt; markup with header row from {@link ResultSetMetaData}.
     */
    private static String resultSetToHtmlTable(ResultSet rs) throws SQLException {
        ResultSetMetaData md = rs.getMetaData();
        int colCount = md.getColumnCount();
        StringBuilder sb = new StringBuilder(4096);
        sb.append("<table class=\"results\"><thead><tr>");
        for (int c = 1; c <= colCount; c++) {
            sb.append("<th scope=\"col\">")
                    .append(HtmlEscape.escape(md.getColumnLabel(c)))
                    .append("</th>");
        }
        sb.append("</tr></thead><tbody>");
        boolean any = false;
        while (rs.next()) {
            any = true;
            sb.append("<tr>");
            for (int c = 1; c <= colCount; c++) {
                Object val = rs.getObject(c);
                String cell = val == null ? "" : String.valueOf(val);
                sb.append("<td>").append(HtmlEscape.escape(cell)).append("</td>");
            }
            sb.append("</tr>");
        }
        if (!any) {
            sb.append("<tr><td colspan=\"")
                    .append(colCount)
                    .append("\" class=\"empty\">No rows returned.</td></tr>");
        }
        sb.append("</tbody></table>");
        return sb.toString();
    }
}
