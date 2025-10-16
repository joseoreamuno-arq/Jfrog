p_Upload_Trigger_Orders
s_set_running_pipeline_inbound_load_orders
SET v_running_pipeline_inbound *= v_running_pipeline
s_set_running_pipeline_load_orders
SET v_running_pipeline *= v_running_pipeline_inbound||'-> p_load_orders'

s_clear_stg_order_item_validation_error
delete from delta.stg_order_item_validation_error

p_Shared_Clear_Staging_Tables

Create step s_load_Trigger_prestage_order_item AS (
Insert Into Delta (Tablename='delta.prestage_order_item', Overwrite=true)
    SELECT distinct pstg.Order_Code
    , pstg.Item_Code
    , pstg.Batch_Name
    , pstg.Batch_Type
    , pstg.period_name
    , pstg.Product_Name
    , pstg.Geography_Name
    , pstg.Customer_Name
    , pstg.Quantity
    , pstg.Amount
    , pstg.Monthly_Validation
    , pstg.Amount_UnitType
    , pstg.Incentive_Date
    , pstg.Order_Date
    , pstg.Order_Type AS order_type_name
    , pstg.Discount
    , pstg.Description
    , pstg.Related_Order_Code
    , pstg.Related_Item_Code
    , pstga.employee_id
    , pstga.split_amount_pct
    FROM delta.pstg_order_item_final pstg 
    JOIN stg_order_item_assignment_final pstga ON pstg.Order_Code = pstga.Order_Code AND pstg.Item_Code = pstga.Item_Code;
)

Create step s_load_Trigger_Staging_Order_Item AS (
INSERT INTO staging.order_item
    ( Order_Code
    , Item_Code
    , Batch_Name
    , Batch_Type_Name
    , period_name
    , Product_Name
    , Geography_Name
    , Customer_Name
    , Quantity
    , Amount
    , Monthly_Validation
    , amount_unit_type_name
    , Incentive_Date
    , Order_Date
    , order_type_name
    , Discount
    , Description
    , Related_Order_Code
    , Related_Item_Code
    )
    SELECT DISTINCT Order_Code
    , Item_Code
    , Batch_Name
    , Batch_type as Batch_Type_Name
    , period_name
    , Product_Name
    , Geography_Name
    , Customer_Name
    , Quantity
    , Amount
    , Monthly_Validation
    , Amount_UnitType AS amount_unit_type_name
    , Incentive_Date
    , Order_Date
    , order_type_name
    , Discount
    , Description
    , Related_Order_Code
    , Related_Item_Code

    FROM delta.prestage_order_item;
)

Create step s_load_Trigger_staging_order_item_assignment AS (
Insert Into staging.order_item_assignment (order_code, item_code, employee_id, split_amount_pct)
SELECT DISTINCT order_code,item_code, employee_id,split_amount_pct FROM prestage_order_item;
)

s_incent_create_batches
incent synchronous create batches

s_sleep_ten
sleep 10

s_incent_validate_orders
incent synchronous validate orders

s_load_stg_order_item_validation_error
INSERT Into delta.stg_order_item_validation_error
SELECT * FROM staging.order_item_validation_error

p_Shared_Clear_Invalid_Stage_Orders

Create step s_delete_invalid_stage_order_item AS (
insert into Delta(TableName='delta.tmp_valid_order_item', Overwrite=true,Unlogged=true)
SELECT DISTINCT oi.*
FROM staging.order_item oi
LEFT JOIN staging.order_item_assignment oia ON oia.order_code = oi.order_code and oia.item_code = oi.item_code
LEFT JOIN staging.order_item_validation_error oive ON oi.order_code = oive.order_code AND oi.item_code = oive.item_code AND (oive.Error_ID <> '9012' OR (oive.Error_ID = '9012' AND oive.Error_Field_Value = oia.employee_ID))
WHERE oive.order_code IS NULL and oive.item_code IS NULL
)

Create step s_delete_invalid_stage_order_item_assignment AS (
INSERT INTO Delta(TableName='delta.tmp_valid_order_item_assignment',Overwrite=true,Unlogged=true)
SELECT DISTINCT oia.*
FROM staging.order_item_assignment oia
LEFT JOIN staging.order_item_validation_error oive ON oia.order_code = oive.order_code AND oia.item_code = oive.item_code AND
((oive.Error_ID = '9012' AND oive.Error_Field_Value = oia.employee_ID) OR oive.Error_ID <> '9012')
WHERE oive.order_code IS NULL and oive.item_code IS NULL
)
p_Shared_Clear_Staging_Tables

Create step s_restore_valid_stage_order_item AS (
insert into staging.order_item
select * from delta.tmp_valid_order_item where order_code is not null and item_code is not null;
)

Create step s_restore_valid_stage_order_item_assignment AS (
insert into staging.order_item_assignment
select * from delta.tmp_valid_order_item_assignment where order_code is not null and item_code is not null;
)

s_incent_upload_orders
Incent synchronous upload orders

s_set_running_pipeline_pipeline_outbound
SET v_running_pipeline *= v_running_pipeline_inbound


/**************************************p_Shared_Clear_Staging_Tables**************************/
Create pipeline p_Shared_Clear_Staging_Tables

s_clear_staging_order_item
delete from staging.order_item
s_clear_staging_order_item_assignment
delete from staging.order_item_assignment
s_clear_order_item_validation_error
delete from staging.order_item_validation_error
s_clear_stage_customer
delete from staging.customer
s_clear_stage_geography
delete from staging.geography
s_clear_stage_product
delete from staging.product

