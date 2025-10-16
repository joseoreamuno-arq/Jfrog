p_holdout_splits_load_postprocess

s_d2c_daily_process_post_process
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

Set v_holdout_splits_load_validation_errors *= '/logs/Holdout_Splits_Load/'||:v_period_name||'/Holdout_Splits_Load_Validation_Errors_'||Today()||'.csv'

Create step s_write_holdout_splits_load_validation_errors AS (
call WriteFile(FilePath=:v_holdout_splits_load_validation_errors,
   Input=(SELECT 
    LeftSide(Order_Code, 18) AS Opportunity_Id
    , Customer_Name 
    , Amount 
    , 'Opportunity Not Correctly Offset' AS Reason
    FROM delta.prestage_holdout_split
    WHERE Order_Code IN 
    (SELECT Order_Code 
    , SUM(Amount) AS AMT
    FROM delta.prestage_holdout_split
    Having AMT <> 0)),
   FirstLineNames=true,
   Separator=',',
   Quote='"',
   Append=false,
   Trim=true);
)

s_subject_body_process_complete
SET v_email_subject *='The '||:v_process_name||' process has completed successfully for the ' || :v_param_processing_period || ' period on '|| CurDateTime()
SET v_email_body *='The '||:v_process_name||' process has completed successfully for the ' || :v_param_processing_period || ' period.'

Create step s_create_email_holdout_splits_load_complete AS (
create email if not exists e_holdout_splits_load_complete as
("From"=:v_email_from
,"To"=:v_email_to
, "Body"=:v_generic_email_body
, "BodyType"='html'
, "Subject"=:v_email_subject
, "Attachment1" = :v_holdout_splits_load_validation_errors
)
)

Create step s_send_holdout_splits_load_complete_email AS (
Send email e_holdout_splits_load_complete
)