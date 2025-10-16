p_trigger_order_load
p_trig_set_vars
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

Create step s_Clear_load_pstg_order_item_final AS (
DELETE FROM delta.pstg_order_item_final;
DELETE FROM delta.stg_order_item_assignment_final;
)

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
)
s_trig_pop_staging_order_item_assignment_final
insert into Delta(TableName='delta.stg_order_item_assignment_final', Overwrite=true, Unlogged=true)
    SELECT par.LAST_NAME ||','|| par.FIRST_NAME || '-' || par.EMPLOYEE_ID AS order_code
    , 'Trigger 1' || '-' || :v_trig_pp AS item_code
    , par.employee_id AS employee_id
    , '100' AS split_amount_pct
    FROM xactly.xc_position c
    JOIN xactly.xc_pos_part_assignment b ON c.position_id = b.position_id
    JOIN xactly.xc_participant par ON b.participant_id = par.participant_id
    LEFT JOIN xactly.xc_emp_status_code esc ON(esc.EMP_STATUS_CODE_ID = par.EMP_STATUS_ID)
    JOIN (SELECT name , MAX(effective_start_date) AS esd FROM xactly.xc_position GROUP BY name ) lv
    ON(lv.name = c.name AND lv.esd = c.effective_start_date)
    WHERE 1=1
    AND(xc_position.INCENT_END_DATE IS NULL OR(xc_position.INCENT_END_DATE >= :v_trig_pp_start_date))

p_Upload_Trigger_Orders