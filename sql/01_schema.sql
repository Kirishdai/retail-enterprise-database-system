-- ============================================================================
-- Programmer: Krish Karki (w10186215)
-- Course: CSC 411/511 Database Management Systems H002
-- Project: Retail Enterprise Database System
-- File: 01_schema.sql
--
-- Description:
-- This file creates the full MySQL relational schema for my retail enterprise
-- project. The database is designed to support multiple stores, products,
-- vendors, customers, sales transactions, inventory, reorders, and shipments.
--
-- Notes:
-- - Composite primary keys are used in associative tables such as INVENTORY,
--   SALE_ITEM, VENDOR_PRODUCT, REORDER_LINE, and SHIPMENT_ITEM.
-- - SALE.customer_id is nullable so that anonymous customer transactions can
--   still be recorded.
-- - Indexes and constraints are included to keep the database consistent and
--   support the required analytical queries.
-- ============================================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS retail_enterprise
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE retail_enterprise;

DROP TABLE IF EXISTS shipment_item;
DROP TABLE IF EXISTS shipment;
DROP TABLE IF EXISTS reorder_line;
DROP TABLE IF EXISTS stock_reorder;
DROP TABLE IF EXISTS sale_item;
DROP TABLE IF EXISTS sale;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS vendor_product;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS vendor;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS retail_store;
DROP TABLE IF EXISTS brand;
DROP TABLE IF EXISTS product_type;

-- Product catalog section:
-- These tables store product brands, product categories, and actual products.
-- PRODUCT_TYPE is self-referencing so categories can have parent-child hierarchy.

CREATE TABLE brand (
  brand_id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  brand_name     VARCHAR(120) NOT NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (brand_id),
  UNIQUE KEY uq_brand_name (brand_name)
) ENGINE=InnoDB;

CREATE TABLE product_type (
  product_type_id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  parent_product_type_id BIGINT UNSIGNED DEFAULT NULL,
  type_name             VARCHAR(160) NOT NULL,
  description           VARCHAR(500) DEFAULT NULL,
  PRIMARY KEY (product_type_id),
  UNIQUE KEY uq_product_type_name_parent (parent_product_type_id, type_name),
  CONSTRAINT fk_product_type_parent
    FOREIGN KEY (parent_product_type_id) REFERENCES product_type (product_type_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE product (
  product_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  brand_id        BIGINT UNSIGNED NOT NULL,
  product_type_id BIGINT UNSIGNED NOT NULL,
  sku             VARCHAR(64) NOT NULL,
  upc             VARCHAR(30) DEFAULT NULL,
  product_name    VARCHAR(255) NOT NULL,
  description     TEXT DEFAULT NULL,
  list_price      DECIMAL(12, 2) NOT NULL,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id),
  UNIQUE KEY uq_product_sku (sku),
  UNIQUE KEY uq_product_upc (upc),
  KEY idx_product_brand (brand_id),
  KEY idx_product_type (product_type_id),
  CONSTRAINT fk_product_brand
    FOREIGN KEY (brand_id) REFERENCES brand (brand_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_product_product_type
    FOREIGN KEY (product_type_id) REFERENCES product_type (product_type_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_product_list_price_positive CHECK (list_price > 0)
) ENGINE=InnoDB;

-- Vendor supply section:
-- Vendors can supply many products, and each product can be supplied by many
-- vendors. VENDOR_PRODUCT is the associative table for this many-to-many relationship.

CREATE TABLE vendor (
  vendor_id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_name   VARCHAR(200) NOT NULL,
  contact_name  VARCHAR(120) DEFAULT NULL,
  email         VARCHAR(255) DEFAULT NULL,
  phone         VARCHAR(40) DEFAULT NULL,
  address       VARCHAR(150) DEFAULT NULL,
  state         VARCHAR(30) DEFAULT NULL,
  payment_terms VARCHAR(80) DEFAULT NULL,
  PRIMARY KEY (vendor_id),
  UNIQUE KEY uq_vendor_name (vendor_name),
  KEY idx_vendor_email (email)
) ENGINE=InnoDB;

CREATE TABLE vendor_product (
  vendor_id           BIGINT UNSIGNED NOT NULL,
  product_id          BIGINT UNSIGNED NOT NULL,
  supplier_sku        VARCHAR(64) DEFAULT NULL,
  unit_cost           DECIMAL(12, 2) NOT NULL,
  minimum_order_qty   INT UNSIGNED NOT NULL DEFAULT 1,
  lead_time_days      SMALLINT UNSIGNED DEFAULT NULL,
  is_primary_supplier TINYINT(1) NOT NULL DEFAULT 0,
  effective_from      DATE NOT NULL,
  effective_to        DATE DEFAULT NULL,
  PRIMARY KEY (vendor_id, product_id),
  KEY idx_vendor_product_product (product_id),
  CONSTRAINT fk_vendor_product_vendor
    FOREIGN KEY (vendor_id) REFERENCES vendor (vendor_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_vendor_product_product
    FOREIGN KEY (product_id) REFERENCES product (product_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chk_vendor_product_unit_cost_positive CHECK (unit_cost > 0),
  CONSTRAINT chk_vendor_product_min_order_positive CHECK (minimum_order_qty > 0),
  CONSTRAINT chk_vendor_product_lead_time_nonneg CHECK (lead_time_days IS NULL OR lead_time_days >= 0),
  CONSTRAINT chk_vendor_product_effective_dates CHECK (
    effective_to IS NULL OR effective_to >= effective_from
  )
) ENGINE=InnoDB;

-- Store and inventory section:
-- Each store carries many products, and each product can appear in many stores.
-- INVENTORY tracks store-specific stock levels, sale prices, and reorder settings.

CREATE TABLE retail_store (
  store_id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_code        VARCHAR(32) NOT NULL,
  store_name        VARCHAR(160) NOT NULL,
  address_line1     VARCHAR(200) NOT NULL,
  address_line2     VARCHAR(200) DEFAULT NULL,
  city              VARCHAR(100) NOT NULL,
  state             VARCHAR(30) NOT NULL,
  region            VARCHAR(100) DEFAULT NULL,
  postal_code       VARCHAR(20) DEFAULT NULL,
  country_code      CHAR(2) NOT NULL DEFAULT 'US',
  phone             VARCHAR(40) DEFAULT NULL,
  opened_on         DATE DEFAULT NULL,
  PRIMARY KEY (store_id),
  UNIQUE KEY uq_store_code (store_code),
  KEY idx_store_city (city),
  KEY idx_store_country (country_code),
  KEY idx_store_state (state)
) ENGINE=InnoDB;

CREATE TABLE inventory (
  store_id    BIGINT UNSIGNED NOT NULL,
  product_id  BIGINT UNSIGNED NOT NULL,
  qty_on_hand INT NOT NULL DEFAULT 0,
  sale_price DECIMAL(12, 2) NOT NULL,
  reorder_qty INT UNSIGNED NOT NULL DEFAULT 0,
  reorder_point INT UNSIGNED DEFAULT NULL,
  bin_location VARCHAR(40) DEFAULT NULL,
  last_count_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (store_id, product_id),
  KEY idx_inventory_product (product_id),
  CONSTRAINT fk_inventory_store
    FOREIGN KEY (store_id) REFERENCES retail_store (store_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_inventory_product
    FOREIGN KEY (product_id) REFERENCES product (product_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chk_inventory_qty_on_hand_nonneg CHECK (qty_on_hand >= 0),
  CONSTRAINT chk_inventory_reorder_point_nonneg CHECK (
    reorder_point IS NULL OR reorder_point >= 0
  ),
  CONSTRAINT chk_inventory_sale_price_positive CHECK (sale_price > 0),
  CONSTRAINT chk_inventory_reorder_qty_nonneg CHECK (reorder_qty >= 0)
) ENGINE=InnoDB;

-- Customer section:
-- This table supports both loyalty and non-loyalty customers. Some sales may
-- still be anonymous, so customer_id is nullable in the SALE table.

CREATE TABLE customer (
  customer_id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email                    VARCHAR(255) DEFAULT NULL,
  phone                    VARCHAR(40) DEFAULT NULL,
  first_name               VARCHAR(80) DEFAULT NULL,
  last_name                VARCHAR(80) DEFAULT NULL,
  is_loyalty_member        TINYINT(1) NOT NULL DEFAULT 0,
  loyalty_member_since     DATE DEFAULT NULL,
  loyalty_points_balance   INT NOT NULL DEFAULT 0,
  created_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_id),
  UNIQUE KEY uq_customer_email (email),
  KEY idx_customer_loyalty (is_loyalty_member),
  CONSTRAINT chk_customer_loyalty_consistency CHECK (
    (is_loyalty_member = 0 AND loyalty_member_since IS NULL)
    OR (is_loyalty_member = 1)
  ),
  CONSTRAINT chk_customer_loyalty_points_nonneg CHECK (loyalty_points_balance >= 0)
) ENGINE=InnoDB;

-- Sales and market basket section:
-- SALE stores the transaction header, while SALE_ITEM stores the products inside
-- each transaction. This design supports market basket analysis.

CREATE TABLE sale (
  sale_id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_id         BIGINT UNSIGNED NOT NULL,
  customer_id      BIGINT UNSIGNED DEFAULT NULL,
  sale_datetime    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  register_id      VARCHAR(32) DEFAULT NULL,
  cashier_id       VARCHAR(32) DEFAULT NULL,
  subtotal_amount  DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
  tax_amount       DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
  total_amount     DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
  transaction_status ENUM('completed','voided','refunded') NOT NULL DEFAULT 'completed',
  PRIMARY KEY (sale_id),
  KEY idx_sale_store (store_id),
  KEY idx_sale_customer (customer_id),
  KEY idx_sale_datetime (sale_datetime),
  KEY idx_sale_store_datetime (store_id, sale_datetime),
  CONSTRAINT fk_sale_store
    FOREIGN KEY (store_id) REFERENCES retail_store (store_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sale_customer
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_sale_subtotal_nonneg CHECK (subtotal_amount >= 0),
  CONSTRAINT chk_sale_tax_nonneg CHECK (tax_amount >= 0),
  CONSTRAINT chk_sale_total_nonneg CHECK (total_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE sale_item (
  sale_id       BIGINT UNSIGNED NOT NULL,
  product_id    BIGINT UNSIGNED NOT NULL,
  line_no       SMALLINT UNSIGNED NOT NULL,
  quantity      INT NOT NULL,
  unit_price    DECIMAL(12, 2) NOT NULL,
  discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  line_total    DECIMAL(14, 2) NOT NULL,
  PRIMARY KEY (sale_id, product_id),
  UNIQUE KEY uq_sale_item_line (sale_id, line_no),
  KEY idx_sale_item_product (product_id),
  CONSTRAINT fk_sale_item_sale
    FOREIGN KEY (sale_id) REFERENCES sale (sale_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sale_item_product
    FOREIGN KEY (product_id) REFERENCES product (product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_sale_item_quantity_positive CHECK (quantity > 0),
  CONSTRAINT chk_sale_item_unit_price_positive CHECK (unit_price > 0),
  CONSTRAINT chk_sale_item_discount_nonneg CHECK (discount_amount >= 0),
  CONSTRAINT chk_sale_item_line_total_nonneg CHECK (line_total >= 0)
) ENGINE=InnoDB;

-- Reorder and shipment section:
-- These tables track purchase orders sent to vendors and the shipments received
-- from those vendors. The table name stock_reorder is used to avoid confusion
-- with SQL wording around REORDER.

CREATE TABLE stock_reorder (
  reorder_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_id        BIGINT UNSIGNED NOT NULL,
  vendor_id       BIGINT UNSIGNED NOT NULL,
  reorder_reference VARCHAR(64) DEFAULT NULL,
  ordered_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  expected_date   DATE DEFAULT NULL,
  reorder_status  ENUM('draft','submitted','partially_received','received','cancelled')
                  NOT NULL DEFAULT 'draft',
  notes           VARCHAR(500) DEFAULT NULL,
  PRIMARY KEY (reorder_id),
  UNIQUE KEY uq_stock_reorder_reference (reorder_reference),
  KEY idx_stock_reorder_store (store_id),
  KEY idx_stock_reorder_vendor (vendor_id),
  KEY idx_stock_reorder_ordered_at (ordered_at),
  CONSTRAINT fk_stock_reorder_store
    FOREIGN KEY (store_id) REFERENCES retail_store (store_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_stock_reorder_vendor
    FOREIGN KEY (vendor_id) REFERENCES vendor (vendor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE reorder_line (
  reorder_id    BIGINT UNSIGNED NOT NULL,
  product_id    BIGINT UNSIGNED NOT NULL,
  quantity_ordered INT NOT NULL,
  unit_cost     DECIMAL(12, 2) NOT NULL,
  quantity_received INT NOT NULL DEFAULT 0,
  PRIMARY KEY (reorder_id, product_id),
  KEY idx_reorder_line_product (product_id),
  CONSTRAINT fk_reorder_line_reorder
    FOREIGN KEY (reorder_id) REFERENCES stock_reorder (reorder_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_reorder_line_product
    FOREIGN KEY (product_id) REFERENCES product (product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_reorder_line_qty_ordered_positive CHECK (quantity_ordered > 0),
  CONSTRAINT chk_reorder_line_unit_cost_positive CHECK (unit_cost > 0),
  CONSTRAINT chk_reorder_line_qty_received_nonneg CHECK (quantity_received >= 0)
) ENGINE=InnoDB;

CREATE TABLE shipment (
  shipment_id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reorder_id        BIGINT UNSIGNED NOT NULL,
  vendor_id         BIGINT UNSIGNED NOT NULL,
  shipped_at        DATETIME(3) DEFAULT NULL,
  received_at       DATETIME(3) DEFAULT NULL,
  carrier           VARCHAR(80) DEFAULT NULL,
  tracking_number   VARCHAR(120) DEFAULT NULL,
  shipment_status   ENUM('pending','in_transit','delivered','cancelled')
                    NOT NULL DEFAULT 'pending',
  PRIMARY KEY (shipment_id),
  KEY idx_shipment_reorder (reorder_id),
  KEY idx_shipment_vendor (vendor_id),
  KEY idx_shipment_shipped_at (shipped_at),
  CONSTRAINT fk_shipment_reorder
    FOREIGN KEY (reorder_id) REFERENCES stock_reorder (reorder_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_shipment_vendor
    FOREIGN KEY (vendor_id) REFERENCES vendor (vendor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE shipment_item (
  shipment_id      BIGINT UNSIGNED NOT NULL,
  product_id       BIGINT UNSIGNED NOT NULL,
  quantity_shipped INT NOT NULL,
  quantity_received INT NOT NULL DEFAULT 0,
  item_condition VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (shipment_id, product_id),
  KEY idx_shipment_item_product (product_id),
  CONSTRAINT fk_shipment_item_shipment
    FOREIGN KEY (shipment_id) REFERENCES shipment (shipment_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_shipment_item_product
    FOREIGN KEY (product_id) REFERENCES product (product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_shipment_item_qty_shipped_nonneg CHECK (quantity_shipped >= 0),
  CONSTRAINT chk_shipment_item_qty_received_nonneg CHECK (quantity_received >= 0)
) ENGINE=InnoDB;
