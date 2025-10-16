Incentive Details Export Kickoff
    p_incentive_details_export_kickoff

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

Create pipeline p_report_parameter_lists 

Create step s_transpose_emp_id AS (
Call WriteFile(FilePath='/ref/user_list.csv'
, Input= (SELECT IF Ucase(:v_report_eid) != 'ALL' THEN Replace(:v_report_eid,',','
') ELSE 'ALL' END AS EID FROM Empty()),
   FirstLineNames=false,
   Append=false,
   Trim=true);
  ) 
Create step s_load_employee_user_list AS (
INSERT Into Delta(TableName='delta.user_list_dmp', Overwrite=true, Unlogged=true)
    SELECT a.C1
    , Nvl(b.employee_id, c.employee_id) AS report_eid
    , Nvl(b.email, c.email) AS report_email
    , Nvl(b.role_type, c.role_type) AS report_role_type
    , Nvl(b.territory, c.territory) AS report_territory
    FROM  ReadFile(FilePath='/ref/user_list.csv' , FirstLineNames=false,  Separator=',') a 
    LEFT JOIN delta.user_employee_dmp b ON Trim(a.C1) = b.employee_id AND Ucase(a.C1)!='ALL'
    LEFT JOIN delta.user_employee_dmp c ON Ucase(a.C1)='ALL'
)

Create step s_transpose_Period AS (
Call WriteFile(FilePath='/ref/period_list.csv'
, Input= (SELECT  Replace(:Reporting_Period_Names,',','
') AS Period_Names FROM Empty()),
   FirstLineNames=false,
   Append=false,
   Trim=true);
)
 
Create step s_load_report_period_list AS (
INSERT Into Delta(TableName='delta.period_list', Overwrite=true, Unlogged=true)
    SELECT a.C1 AS Source_Period
    , p.Name AS Period_Name
    , p.start_date AS report_start_date
    , p.end_date AS report_end_date
    FROM  ReadFile(FilePath='/ref/period_list.csv' , FirstLineNames=false,  Separator=',') a 
    JOIN xactly.xc_period p ON Trim(Ucase(a.C1)) = p.Name
)

Create step s_set_report_period_range AS (
Set v_report_start_date *= SELECT MIN(report_start_date) FROM delta.period_list;
Set v_report_end_date *= SELECT  MAX(report_end_date)AS end_date FROM delta.period_list;
)

Create step s_transpose_territory AS (
Call WriteFile(FilePath='/ref/territory_list.csv'
, Input= (SELECT IF Ucase(:v_participant_territory) != 'NULL' THEN Replace(:v_participant_territory,',','
') ELSE 'NULL' END AS Territory FROM Empty()),
   FirstLineNames=false,
   Append=false,
   Trim=true);
  ) 
Create step s_load_territory_list AS (
INSERT Into Delta(TableName='delta.territory_list', Overwrite=true, Unlogged=true)
    SELECT IF a.C1 = 'NULL' THEN NULL ELSE a.C1 END AS C1
    , b.employee_id AS report_eid
    , b.email AS report_email
    , b.role_type AS report_role_type
    , b.territory AS report_territory
    FROM  ReadFile(FilePath='/ref/territory_list.csv' , FirstLineNames=false,  Separator=',') a 
    LEFT JOIN delta.user_employee_dmp b ON Trim(a.C1) = b.Territory AND b.role_type = 'INDIVIDUAL_PAYEE'
)

Create step s_merge_report_user_list AS (
INSERT Into Delta(TableName='delta.user_list', Overwrite=true, Unlogged=true)
    SELECT * FROM delta.user_list_dmp
    UNION 
    SELECT * FROM delta.territory_list
)

Create step s_log_variable_changes AS (
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
)

 p_set_v_process_variables

Create step s_set_running_pipeline_incentive_details_export_kickoff AS (
SET v_running_pipeline *= 'p_incentive_details_export_kickoff'
)
s_clear_pre_process_validation_errors
DELETE from delta.pre_process_validation_errors


s_clear_pre_process_validation_errors
DELETE from delta.pre_process_validation_errors

Create step s_user_employee_dmp AS (
INSERT Into Delta(TableName='delta.user_employee_dmp',Overwrite=true,Unlogged=true)
    SELECT part.employee_id
    , part.territory
    , usr.email
    , ro.role_Type
    , Concat(part.employee_id,'_',usr.email) AS ukey
    FROM xactly.xc_user usr
    JOIN xactly.xc_part_user_assignment up ON usr.user_id = up.user_id
    JOIN xactly.xc_participant part ON up.participant_id = part.participant_id AND :v_var_sales_data_pp_start_date BETWEEN part.effective_start_date AND part.effective_end_date
    JOIN xactly.xc_user_role ur ON usr. user_id = ur.user_id
    JOIN xactly.xc_role ro ON ur.role_id = ro.role_id 
    WHERE 1=1
    AND usr.Enabled = '1'
    UNION
    SELECT NULL AS employee_id
    , NULL AS territory
    , usr.email
    , ro.role_Type
    , Concat(usr.email) AS ukey
    FROM xactly.xc_user usr
    JOIN xactly.xc_user_role ur ON usr. user_id = ur.user_id
    JOIN xactly.xc_role ro ON ur.role_id = ro.role_id 
    WHERE 1=1 
    AND usr.Enabled = '1'
    AND ro.role_Type IN ('BUSINESS_ADMINISTRATOR', 'XACTLY')
)


Create step s_set_incentive_details_eid AS (
Set v_incentive_details_eid *= SELECT 
    GatherString( '''' ||Employee_ID||'''', ' ,' )
    FROM delta.user_employee_dmp
    WHERE 1=1
    AND (employee_Id = :v_report_eid AND Contains(:v_param_email_distribution_list,email)=true)
    OR (employee_Id = :v_report_eid AND :v_param_email_distribution_list IN ( SELECT email from delta.user_employee_dmp where role_Type IN ('BUSINESS_ADMINISTRATOR', 'XACTLY')))
    OR (:v_report_eid = 'ALL'AND :v_param_email_distribution_list IN ( SELECT email from delta.user_employee_dmp where role_Type IN ('BUSINESS_ADMINISTRATOR', 'XACTLY')))
)

Create step s_set_incentive_details_wrong_params_email AS (
Set v_email_subject *= :v_shared_customer_name||'-'|| v_process_name||' cannot start for '||:v_period_name;
Set v_email_body *= :v_shared_customer_name||'-'|| v_process_name||' cannot start for '||:v_period_name||'<br> One or More parameters are incorrect. <br> ';
)

SELECT IF Count(*)>0 THEN true ELSE false END FROM delta.user_list

Create step s_queue_incentive_details_export AS (
call QueueIncentProcessGroup(Input=(SELECT 'Incentive Details Export Process' process_group_name, :v_period_name period_name, '[{"Incentive Details Export Preprocess":[{ "Email_Distribution_List": "'||:v_email_to||'"},{ "Rep_Id": "'||:Rep_Id||'"},{ "Territory": "'||:Territory||'"},{ "Reporting_Period_Names": "'||:Reporting_Period_Names||'"},{ "Distribute": "'||:v_distibution_flag||'"}]}]' parameter_overrides));
)



