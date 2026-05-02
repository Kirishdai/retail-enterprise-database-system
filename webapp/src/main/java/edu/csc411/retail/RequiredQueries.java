package edu.csc411.retail;

/*
 * Programmer: Krish Karki (w10186215)
 * Course: CSC 411/511 Database Management Systems H002
 * Project: Retail Enterprise Database System
 *
 * This class stores the SQL queries required for the project. Each query
 * matches the corresponding query from 03_required_queries.sql and is used
 * by the web application to retrieve and display results.
 *
 * I kept the SQL queries in a separate class so they remain organized and
 * consistent with the assignment requirements.
 */

public final class RequiredQueries {

    private RequiredQueries() {}

    /** Query 1 — Top 20 selling products at each store (by total quantity sold). */
    public static final String QUERY_1_TOP_PRODUCTS_PER_STORE = """
            WITH store_product_qty AS (
              SELECT
                rs.store_id,
                rs.store_code,
                rs.store_name,
                p.product_id,
                p.product_name,
                SUM(si.quantity) AS total_qty_sold
              FROM sale s
              INNER JOIN sale_item si ON s.sale_id = si.sale_id
              INNER JOIN product p ON si.product_id = p.product_id
              INNER JOIN retail_store rs ON s.store_id = rs.store_id
              WHERE s.transaction_status = 'completed'
              GROUP BY rs.store_id, rs.store_code, rs.store_name, p.product_id, p.product_name
            ),
            ranked_by_store AS (
              SELECT
                store_id,
                store_code,
                store_name,
                product_id,
                product_name,
                total_qty_sold,
                ROW_NUMBER() OVER (
                  PARTITION BY store_id
                  ORDER BY total_qty_sold DESC, product_id ASC
                ) AS rn
              FROM store_product_qty
            )
            SELECT
              store_id,
              store_code,
              store_name,
              product_id,
              product_name,
              total_qty_sold
            FROM ranked_by_store
            WHERE rn <= 20
            ORDER BY store_id, total_qty_sold DESC, product_id
            """;

    /** Query 2 — Top 20 selling products in each state (by total quantity sold). */
    public static final String QUERY_2_TOP_PRODUCTS_PER_STATE = """
            WITH state_product_qty AS (
              SELECT
                rs.state,
                p.product_id,
                p.product_name,
                SUM(si.quantity) AS total_qty_sold
              FROM sale s
              INNER JOIN sale_item si ON s.sale_id = si.sale_id
              INNER JOIN product p ON si.product_id = p.product_id
              INNER JOIN retail_store rs ON s.store_id = rs.store_id
              WHERE s.transaction_status = 'completed'
              GROUP BY rs.state, p.product_id, p.product_name
            ),
            ranked_by_state AS (
              SELECT
                state,
                product_id,
                product_name,
                total_qty_sold,
                ROW_NUMBER() OVER (
                  PARTITION BY state
                  ORDER BY total_qty_sold DESC, product_id ASC
                ) AS rn
              FROM state_product_qty
            )
            SELECT
              state,
              product_id,
              product_name,
              total_qty_sold
            FROM ranked_by_state
            WHERE rn <= 20
            ORDER BY state, total_qty_sold DESC, product_id
            """;

    /** Query 3 — Top 5 stores with the highest total sales this year. */
    public static final String QUERY_3_TOP_STORES_THIS_YEAR = """
            SELECT
              rs.store_id,
              rs.store_code,
              rs.store_name,
              rs.city,
              rs.state,
              SUM(s.total_amount) AS total_sales_amount,
              COUNT(*) AS transaction_count
            FROM sale s
            INNER JOIN retail_store rs ON s.store_id = rs.store_id
            WHERE s.transaction_status = 'completed'
              AND YEAR(s.sale_datetime) = YEAR(CURDATE())
            GROUP BY rs.store_id, rs.store_code, rs.store_name, rs.city, rs.state
            ORDER BY total_sales_amount DESC
            LIMIT 5
            """;

    /** Query 4 — Count of stores where Coca-Cola brand outsells Pepsi brand (by total units sold). */
    public static final String QUERY_4_COKE_VS_PEPSI_STORE_COUNT = """
        WITH cola_qty_by_store AS (
        SELECT
          rs.store_id,
          rs.store_name,
          SUM(CASE WHEN b.brand_name LIKE '%Coca%' THEN si.quantity ELSE 0 END) AS coke_qty,
          SUM(CASE WHEN b.brand_name LIKE '%Pepsi%' THEN si.quantity ELSE 0 END) AS pepsi_qty
        FROM sale s
        JOIN sale_item si ON s.sale_id = si.sale_id
        JOIN product p ON si.product_id = p.product_id
        JOIN brand b ON p.brand_id = b.brand_id
        JOIN retail_store rs ON s.store_id = rs.store_id
        WHERE s.transaction_status = 'completed'
        GROUP BY rs.store_id, rs.store_name
      )
      SELECT COUNT(*) AS store_count_coke_outsells_pepsi
      FROM cola_qty_by_store
      WHERE coke_qty > pepsi_qty
      """;

    /** Query 5 — Top 3 products most frequently bought together with Milk. */
    public static final String QUERY_5_TOP_WITH_MILK = """
        WITH milk_sales AS (
          SELECT DISTINCT si.sale_id
          FROM sale_item si
          JOIN product p ON si.product_id = p.product_id
          JOIN product_type pt ON p.product_type_id = pt.product_type_id
          WHERE LOWER(p.product_name) LIKE '%milk%'
            OR LOWER(pt.type_name) LIKE '%milk%'
        )
        SELECT
          p.product_id,
          p.product_name,
          b.brand_name,
          SUM(si.quantity) AS total_quantity_bought_with_milk,
          COUNT(DISTINCT si.sale_id) AS number_of_baskets
        FROM sale_item si
        JOIN product p ON si.product_id = p.product_id
        JOIN brand b ON p.brand_id = b.brand_id
        JOIN milk_sales ms ON si.sale_id = ms.sale_id
        WHERE LOWER(p.product_name) NOT LIKE '%milk%'
        GROUP BY p.product_id, p.product_name, b.brand_name
        ORDER BY total_quantity_bought_with_milk DESC, number_of_baskets DESC
        LIMIT 3
        """;

    public static String sqlForQueryNumber(int n) {
        return switch (n) {
            case 1 -> QUERY_1_TOP_PRODUCTS_PER_STORE;
            case 2 -> QUERY_2_TOP_PRODUCTS_PER_STATE;
            case 3 -> QUERY_3_TOP_STORES_THIS_YEAR;
            case 4 -> QUERY_4_COKE_VS_PEPSI_STORE_COUNT;
            case 5 -> QUERY_5_TOP_WITH_MILK;
            default -> throw new IllegalArgumentException("Unknown query id: " + n);
        };
    }
}
