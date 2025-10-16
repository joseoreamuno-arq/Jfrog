Incentive Details Export Process
Manager Incentive Details Export Preprocess
p_incentive_details_export_manager_pre_process

s_d2c_load_orders_pre_process
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

Create Step s_incentive_details_params AS (
Set v_report_eid *= :Rep_Id;
Set v_Reporting_Period_Names *= SELECT name FROM xactly.xc_period WHERE (Ucase(Name) = Ucase(:Reporting_Period_Names) OR Name = :v_period_name);
Set v_distibution_flag *= :Distribute;
Set v_participant_territory *= :Territory;
)

s_log_variable_changes
INSERT Into Delta(TableName='delta.process_variables', Overwrite=false)
SELECT
PERIODNAME
, PGNAME
, REGIONID
, PARAMS
, :Email_Distribution_List
, :v_email_to
, :Rep_Id
, :v_report_eid
, :Reporting_Period_Names
, :v_Reporting_Period_Names
, Now() AS Created_Date
FROM (Incent Queue)

Alter step s_set_incentive_details_process_start_email AS (
Set v_email_subject *= :v_shared_customer_name||'-'|| :v_process_name||' has started for '||:v_period_name;
Set v_email_body *= :v_shared_customer_name||'-'|| :v_process_name||' has started for '||:v_period_name||'<br> For the following Employee(s): '||:Rep_Id||' . <br> ';
)

s_sen`d_generic_email
Send email e_genereic_email
