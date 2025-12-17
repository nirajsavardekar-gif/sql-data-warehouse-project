/* 
========================================================================================
DDL Script: Create Gold Views
========================================================================================
Script Purpose:
	This script creates views for the Gold layer in the data warehouse.
	The Gold layer represents the final dimension and fact table (Star Schema)

	Each view perfroms transformations and combines data from the Silver layer
	to produce a clear, enriched, and business-ready dataset.

Usage:
	- These views can be queried directly for analytics and reporting

========================================================================================
*/

-- =====================================================================================
-- Create Dimension : Gold.dim_customers
--======================================================================================

If Object_ID('Gold.dim_customers','V') Is not null
   Drop View Gold.dim_customers;
GO


CREATE VIEW Gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER (Order by cst_id) AS customer_key, 
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.CNTRY as country,
	ci.cst_material_status as marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr  -- CRM is the master for gender info
	Else Coalesce (ca.GEN, 'n/a')
	END As gender,
	ca.BDATE as birthdate,
	ci.cst_create_data as create_date
FROM Silver.crm_cust_info ci
LEFT JOIN Silver.erp_CUST_AZ12 ca
ON  ci.cst_key = ca.CID
LEFT JOIN Silver.erp_LOC_A101 la
ON ci.cst_key = la.CID
GO

--========================================================================================
-- Create Dimensions: Gold.dim_products
--========================================================================================
If Object_ID('Gold.dim_products','V') Is not null
   Drop View Gold.dim_products;
GO

CREATE VIEW Gold.dim_products AS
SELECT 
	ROW_NUMBER () OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prdt_nm as product_name,
	pn.cat_id as category_id,
	pc.CAT as category,
	pc.SUBCAT as subcategory,
	pc.maintenance,
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date	
FROM Silver.crm_prd_info pn
Left Join silver.erp_PX_CAT_G1V2 pc
ON pn.cat_id = pc.ID
WHERE prd_end_dt IS NULL  -- Filter out all	historic data
GO

--========================================================================================
-- Create Dimensions: Gold.fact_sales
--========================================================================================
If Object_ID('Gold.fact_sales','V') Is not null
   Drop View Gold.fact_sales;
GO

CREATE VIEW Gold.fact_sales AS
Select 
	sd.sls_ord_num as order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt as order_date,
	sd.sls_ship_dt as shipping_date,
	sd.sls_due_dt as due_date,
	sd.sls_sales as sales_amount,
	sd.sls_quantity as quantity,
	sd.sls_price as price
From Silver.crm_sales_details sd
Left Join Gold.dim_products pr 
ON sd.sls_prd_key = pr.product_number
Left Join Gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id
GO
