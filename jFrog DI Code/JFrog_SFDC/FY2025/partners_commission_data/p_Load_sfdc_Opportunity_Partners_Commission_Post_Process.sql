p_Load_sfdc_Opportunity_Partners_Commission_Post_Process

Create step s_d2c_load_Partners_Commission_Post_Process AS (
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
)

Create Step s_subject_body_process_complete AS (
SET v_email_subject *='The '||:v_process_name||' process has completed successfully for the ' || :v_param_processing_period || ' period on '|| CurDateTime()
SET v_email_body *='The '||:v_process_name||' process has completed successfully for the ' || :v_param_processing_period || ' period.'
)


s_send_email_daily_process_completed_p_order_load1
send email e_daily_order_data_process_complete
