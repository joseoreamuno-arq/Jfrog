p_trigger_order_load
s_d2c_load_trigger_orders_main_process
set PERIOD_NAME *= :PERIOD_NAME;
set PG_NAME *= :PG_NAME;
set PARAM_EXT_TASK_ID *=:PARAM_EXT_TASK_ID;
set EXT_OBJECT_NAME *=:EXT_OBJECT_NAME;
set CUST_BUSINESS_ID *=:CUST_BUSINESS_ID;
set v_period_name *= :PERIOD_NAME;
set v_process_name *= :PG_NAME;
set v_pipeline_name *=:EXT_OBJECT_NAME;
set v_ext_task_id *=:PARAM_EXT_TASK_ID;
set v_customer_name *=:CUST_BUSINESS_NAME;
set v_podname *= PodName();
set v_shared_customer_name *= :v_customer_name || '-' ||SubString(:v_podname,11);
set v_email_from *='delta-notifications@xactlycorp.com';
set v_business_id *=:CUST_BUSINESS_ID;
set Email_Distribution_List *= :Email_Distribution_List;
set v_email_to *= :Email_Distribution_List||',delta-notifications@xactlycorp.com';
set v_email_to_error *= :v_email_to;
set v_param_processing_period *= :PERIOD_NAME;
set v_param_shared_customer_name *= :JFrog;
set v_param_email_distribution_list *= :Email_Distribution_List;

p_trig_set_vars
s_set_v_trig_pp
SET v_trig_pp *= v_param_processing_period

s_set_v_trig_pp_end_date
SET v_trig_pp_end_date *= (
    SELECT
    per.end_date
    FROM xactly.xc_period per
    WHERE per.name = :v_trig_pp
    )
s_set_v_trig_pp_start_date
SET v_trig_pp_start_date *= (
    SELECT
    per.start_date
    FROM xactly.xc_period per
    WHERE per.name = :v_trig_pp
    )
    s_set_v_load_sfdc_data_fiscal_year
    SET v_load_sfdc_data_fiscal_year *= (
    SELECT DISTINCT per.start_date AS period_name FROM xactly.xc_period per
    INNER JOIN xactly.xc_period_type type
    ON(per.period_type_id_fk = type.period_type_id)
    WHERE :v_trig_pp_start_date BETWEEN per.start_date AND per.end_date AND type.name = 'YEARLY' )

p_clear_stage_orders
    s_clear_stage_customer
    delete from staging.customer
    s_clear_stage_geography
    delete from staging.geography
    s_clear_stage_product
    delete from staging.product
    s_clear_stage_order_item
    delete from staging.order_item
    s_clear_stage_order_item_assignment
    delete from staging.order_item_assignment
    s_delete_govt_lookup_table_data
    delete from delta.govt_rep_split_lookup_table_person_dump
    p_trig_load_tmp_data
    s_Clear_load_pstg_order_item_final
    DELETE FROM delta.pstg_order_item_final;
    DELETE FROM delta.stg_order_item_assignment_final;

Alter step s_load_pstg_order_item_final AS (
insert into Delta(TableName='delta.pstg_order_item_final', Overwrite=false)
    (
    order_code,
    item_code,
    batch_name,
    batch_type,
    employee_id,
    split_amount_pct,
    period_name,
    product_name,
    geography_name,
    customer_name,
    quantity,
    amount,
    amount_UnitType,
    incentive_date,
    order_date,
    order_type,
    discount,
    description,
    related_order_code,
    related_item_code
    )
    SELECT DISTINCT
    par.LAST_NAME ||','|| par.FIRST_NAME || '-' || par.EMPLOYEE_ID AS order_code
    , 'Trigger 1' || '-' || :v_trig_pp AS item_code
    , 'Trigger 1_' || :v_trig_pp || '_'|| (((SeqNum()-1)/20000)+1) AS batch_name
    , 'Trigger 1' AS batch_type
    , par.employee_id as employee_id
    , '100' as split_amount_pct
    , :v_trig_pp AS period_name
    , NULL AS product_name
    , NULL AS geography_name
    , NULL AS customer_name
    , NULL AS quantity
    , 0 AS amount
    , 'QUANTITY' AS amount_UnitType
    , case when c.INCENT_END_DATE is null then :v_trig_pp_end_date
    when c.INCENT_END_DATE between :v_trig_pp_start_date and :v_trig_pp_end_date then c.INCENT_END_DATE
    else :v_trig_pp_end_date end AS incentive_date
    , :v_load_sfdc_data_fiscal_year AS order_date
    , 'Trigger 1' AS order_type
    , NULL AS discount
    , NULL AS description
    , NULL AS related_order_code
    , NULL AS related_item_code
    FROM xactly.xc_position c join xactly.xc_pos_part_assignment b on c.position_id = b.position_id
    join xactly.xc_participant par on b.participant_id = par.participant_id
    left JOIN xactly.xc_emp_status_code esc
    ON (esc.EMP_STATUS_CODE_ID = par.EMP_STATUS_ID)
    JOIN (
    SELECT
    name
    , MAX(effective_start_date) AS esd
    FROM xactly.xc_position
    GROUP BY
    name
    ) lv
    ON (lv.name = c.name
    AND lv.esd = c.effective_start_date)
    WHERE (xc_position.INCENT_END_DATE IS NULL OR (xc_position.INCENT_END_DATE >= :v_trig_pp_start_date))

    union

    SELECT DISTINCT
    par.LAST_NAME ||','|| par.FIRST_NAME || '-' || par.EMPLOYEE_ID AS order_code
    , 'Trigger 2' || '-' || :v_trig_pp AS item_code
    , 'Trigger 2_' || :v_trig_pp || '_'|| (((SeqNum()-1)/20000)+1) AS batch_name
    , 'Trigger 2' AS batch_type
    , par.employee_id as employee_id
    , '100' as split_amount_pct
    , :v_trig_pp AS period_name
    , NULL AS product_name
    , NULL AS geography_name
    , NULL AS customer_name
    , NULL AS quantity
    , 0 AS amount
    , 'QUANTITY' AS amount_UnitType
    , case when c.INCENT_END_DATE is null then :v_trig_pp_end_date
    when c.INCENT_END_DATE between :v_trig_pp_start_date and :v_trig_pp_end_date then c.INCENT_END_DATE
    else :v_trig_pp_end_date end AS incentive_date
    , :v_load_sfdc_data_fiscal_year AS order_date
    , 'Trigger 2' AS order_type
    , NULL AS discount
    , NULL AS description
    , NULL AS related_order_code
    , NULL AS related_item_code
    FROM xactly.xc_position c join xactly.xc_pos_part_assignment b on c.position_id = b.position_id
    join xactly.xc_participant par on b.participant_id = par.participant_id
    left JOIN xactly.xc_emp_status_code esc
    ON (esc.EMP_STATUS_CODE_ID = par.EMP_STATUS_ID)
    JOIN (
    SELECT
    name
    , MAX(effective_start_date) AS esd
    FROM xactly.xc_position
    GROUP BY
    name
    ) lv
    ON (lv.name = c.name
    AND lv.esd = c.effective_start_date)
    WHERE (xc_position.INCENT_END_DATE IS NULL OR (xc_position.INCENT_END_DATE >= :v_trig_pp_start_date))

    union

    SELECT DISTINCT
    par.LAST_NAME ||','|| par.FIRST_NAME || '-' || par.EMPLOYEE_ID AS order_code
    , 'Trigger 3' || '-' || :v_trig_pp AS item_code
    , 'Trigger 3_' || :v_trig_pp || '_'|| (((SeqNum()-1)/20000)+1) AS batch_name
    , 'Trigger 3' AS batch_type
    , par.employee_id as employee_id
    , '100' as split_amount_pct
    , :v_trig_pp AS period_name
    , NULL AS product_name
    , NULL AS geography_name
    , NULL AS customer_name
    , NULL AS quantity
    , 0 AS amount
    , 'QUANTITY' AS amount_UnitType
    , case when c.INCENT_END_DATE is null then :v_trig_pp_end_date
    when c.INCENT_END_DATE between :v_trig_pp_start_date and :v_trig_pp_end_date then c.INCENT_END_DATE
    else :v_trig_pp_end_date end AS incentive_date
    , :v_load_sfdc_data_fiscal_year AS order_date
    , 'Trigger 3' AS order_type
    , NULL AS discount
    , NULL AS description
    , NULL AS related_order_code
    , NULL AS related_item_code
    FROM xactly.xc_position c join xactly.xc_pos_part_assignment b on c.position_id = b.position_id
    join xactly.xc_participant par on b.participant_id = par.participant_id
    left JOIN xactly.xc_emp_status_code esc
    ON (esc.EMP_STATUS_CODE_ID = par.EMP_STATUS_ID)
    JOIN (
    SELECT
    name
    , MAX(effective_start_date) AS esd
    FROM xactly.xc_position
    GROUP BY
    name
    ) lv
    ON (lv.name = c.name
    AND lv.esd = c.effective_start_date)
    WHERE (xc_position.INCENT_END_DATE IS NULL OR (xc_position.INCENT_END_DATE >= :v_trig_pp_start_date))
)

Alter step s_trig_pop_staging_order_item_assignment_final AS (
insert into Delta(TableName='delta.stg_order_item_assignment_final', Overwrite=true, Unlogged=true)
    SELECT DISTINCT
    par.LAST_NAME ||','|| par.FIRST_NAME || '-' || par.EMPLOYEE_ID as order_code
    , 'Trigger 1' || '-' || :v_trig_pp as item_code
    , par.employee_id as employee_id
    , '100' as split_amount_pct
    FROM xactly.xc_position c join xactly.xc_pos_part_assignment b on c.position_id = b.position_id
    join xactly.xc_participant par on b.participant_id = par.participant_id
    left JOIN xactly.xc_emp_status_code esc
    ON (esc.EMP_STATUS_CODE_ID = par.EMP_STATUS_ID)
    JOIN (SELECT
    name
    , MAX(effective_start_date) AS esd
    FROM xactly.xc_position
    GROUP BY
    name
    ) lv
    ON (lv.name = c.name
    AND lv.esd = c.effective_start_date)
    WHERE (xc_position.INCENT_END_DATE IS NULL OR (xc_position.INCENT_END_DATE >= :v_trig_pp_start_date))

    union

    SELECT DISTINCT
    par.LAST_NAME ||','|| par.FIRST_NAME || '-' || par.EMPLOYEE_ID as order_code
    , 'Trigger 2' || '-' || :v_trig_pp as item_code
    , par.employee_id as employee_id
    , '100' as split_amount_pct
    FROM xactly.xc_position c join xactly.xc_pos_part_assignment b on c.position_id = b.position_id
    join xactly.xc_participant par on b.participant_id = par.participant_id
    left JOIN xactly.xc_emp_status_code esc
    ON (esc.EMP_STATUS_CODE_ID = par.EMP_STATUS_ID)
    JOIN (SELECT
    name
    , MAX(effective_start_date) AS esd
    FROM xactly.xc_position
    GROUP BY
    name
    ) lv
    ON (lv.name = c.name
    AND lv.esd = c.effective_start_date)
    WHERE (xc_position.INCENT_END_DATE IS NULL OR (xc_position.INCENT_END_DATE >= :v_trig_pp_start_date))
    
    union

    SELECT DISTINCT
    par.LAST_NAME ||','|| par.FIRST_NAME || '-' || par.EMPLOYEE_ID as order_code
    , 'Trigger 3' || '-' || :v_trig_pp as item_code
    , par.employee_id as employee_id
    , '100' as split_amount_pct
    FROM xactly.xc_position c join xactly.xc_pos_part_assignment b on c.position_id = b.position_id
    join xactly.xc_participant par on b.participant_id = par.participant_id
    left JOIN xactly.xc_emp_status_code esc
    ON (esc.EMP_STATUS_CODE_ID = par.EMP_STATUS_ID)
    JOIN (SELECT
    name
    , MAX(effective_start_date) AS esd
    FROM xactly.xc_position
    GROUP BY
    name
    ) lv
    ON (lv.name = c.name
    AND lv.esd = c.effective_start_date)
    WHERE (xc_position.INCENT_END_DATE IS NULL OR (xc_position.INCENT_END_DATE >= :v_trig_pp_start_date))
)

p_Upload_Trigger_Orders
s_set_running_pipeline_inbound_load_orders
SET v_running_pipeline_inbound *= v_running_pipeline
s_set_running_pipeline_load_orders
SET v_running_pipeline *= v_running_pipeline_inbound||'-> p_load_orders'
s_clear_stg_order_item_validation_error
delete from delta.stg_order_item_validation_error
 p_Shared_Clear_Staging_Tables

s_load_Trigger_prestage_order_item
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

s_load_Trigger_Staging_Order_Item
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

s_load_Trigger_staging_order_item_assignment
Insert Into staging.order_item_assignment (order_code, item_code, employee_id, split_amount_pct)
SELECT DISTINCT order_code,item_code, employee_id,split_amount_pct FROM prestage_order_item;
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
s_incent_upload_orders
Incent synchronous upload orders
s_set_running_pipeline_pipeline_outbound
SET v_running_pipeline *= v_running_pipeline_inbound
