p_holdout_splits_load_process

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

p_set_v_process_variables
    s_register_incent_user
    incent credential (Username=:v_param_incent_user_name, Password=:v_param_incent_pw)
    s_set_v_sfdc_user_name
    SET v_sfdc_user *= v_param_sfdc_user_name
    s_set_v_sfdc_pw
    SET v_sfdc_passwd *= v_param_sfdc_pw
    s_set_v_shared_customer_name
    SET v_shared_customer_name *= v_param_shared_customer_name
    s_set_v_daily_process_incent_period
    SET v_daily_process_incent_period *=SELECT Name FROM xactly.xc_period per JOIN (SELECT MIN(START_DATE) SD FROM xactly.xc_period per JOIN xactly.xc_period_type pertyp ON per.PERIOD_TYPE_ID_FK=pertyp.PERIOD_TYPE_ID WHERE per.IS_OPEN = 1 AND pertyp.Name='MONTHLY') MinStart ON MinStart.SD = per.START_DATE JOIN xactly.xc_period_type pertyp ON per.PERIOD_TYPE_ID_FK=pertyp.PERIOD_TYPE_ID AND pertyp.Name='MONTHLY'
    s_set_v_var_sales_data_pp_unfinalized
    SET v_var_sales_data_pp_unfinalized *= (
    SELECT
    CASE
    WHEN count(*) = 0 THEN TRUE
    ELSE FALSE
    End as unfin
    FROM (
    SELECT
    per.name
    , count(*) as ct
    FROM xactly.xc_period per
    JOIN xactly.xc_finalize_business_group fin
    ON (per.PERIOD_ID = fin.PERIOD_ID)
    JOIN xactly.xc_finalize_payment fp
    ON (fp.finalize_id = fin.finalize_id
    AND fp.finalize_type <> 'Preview')
    WHERE per.name = :v_param_processing_period
    ) bg
    )
    s_set_v_var_sales_data_pp_start_date
    SET v_var_sales_data_pp_start_date *= (
    SELECT
    per.start_date
    FROM xactly.xc_period per
    WHERE per.name = :v_param_processing_period)
    s_set_v_var_sales_data_pp_end_date
    SET v_var_sales_data_pp_end_date *= (
    SELECT
    per.end_date
    FROM xactly.xc_period per
    WHERE per.name = :v_param_processing_period)
    s_set_v_var_sales_data_pp_start_date
    SET v_var_sales_data_pp_start_date *= (
    SELECT
    per.start_date
    FROM xactly.xc_period per
    WHERE per.name = :v_param_processing_period)
    s_set_v_var_sales_data_pp_end_date
    SET v_var_sales_data_pp_end_date *= (
    SELECT
    per.end_date
    FROM xactly.xc_period per
    WHERE per.name = :v_param_processing_period)
    s_set_env_var
    set v_sfdc_env *= v_param_sfdc_env

--Opportunity 
Alter step s_holdover_split_opportunity_dmp AS (
INSERT INTO Delta(TableName='delta.holdover_split_dmp',Overwrite=true)
    SELECT 
    Opportunity.Id AS opp_Id
    , Opportunity.Name AS Opp_Name
    , Opportunity.StageName AS StageName
    , OpportunityTeamMember.Name AS name
    , User.employeeid__c AS Employee_id 
    , User.Sales_Tier__c AS Tier
    , TeamMemberRole AS Role
    , Users_manager__r.Name AS Manager_Name
    , Users_manager__r.employeeid__c AS Manager_employee_id
    , Penalty_Percentage__c
    , Split_Percentage__c
    , Split_percentage_exact__c
    , Opportunity.ARR_Difference__c AS Final_ARR_Growth
    , Opportunity.CloseDate AS Order_Date
    , Opportunity.Churn_Date__c AS Churn_Date
    , Account__r.Name AS Customer_Name
    , Opportunity.Owner.Name AS Owner_Name
    , Opportunity.Owner.employeeid__c Owner_Employee_Id
    , CurrencyIsoCode
    , Opportunity.Related_Contracts_ARR_Formula__c AS Related_Contracts_ARR

    FROM SFDC(SOQL=
    'SELECT Opportunity.Id
    , Opportunity.Name
    , Opportunity.StageName
    , OpportunityTeamMember.Name
    , User.employeeid__c
    , TeamMemberRole
    , Users_manager__r.Name
    , Users_manager__r.employeeid__c
    , User.Sales_Tier__c
    , Penalty_Percentage__c
    , Split_Percentage__c
    , Split_percentage_exact__c
    , Opportunity.ARR_Difference__c
    , Opportunity.CloseDate
    , Opportunity.Churn_Date__c
    , Account__r.Name
    , Opportunity.Owner.Name
    , Opportunity.Owner.employeeid__c
    , CurrencyIsoCode
    , Opportunity.Related_Contracts_ARR_Formula__c 
    FROM OpportunityTeamMember 
    WHERE Opportunity.IsClosed = true
        AND Opportunity.Is_Test_Account__c = false
        AND Opportunity.Last_assignment_date__c <> NULL
        AND (Opportunity.IsWon = true OR (Opportunity.StageName Like ''%Closed%'' and Opportunity.Record_Type_Name__c = ''Renewal'' AND Opportunity.Churn_Date__c > ' ||SubtractTimeInterval(:v_var_sales_data_pp_end_date,1,'MONTHS')||'))
        AND ((TeamMemberRole = ''Former Owner'' AND Split_Percentage__c > 0 AND Opportunity.ARR_Difference__c<>0) 
            OR (TeamMemberRole=''Former Owner'' AND Opportunity.Related_Contracts_ARR_Formula__c >0  AND Penalty_Percentage__c > 0) OR TeamMemberRole = ''Owner'')
        AND ((Opportunity.CloseDate >= ' || :v_var_sales_data_pp_start_date || ' and Opportunity.CloseDate <= ' || :v_var_sales_data_pp_end_date||' ) 
            OR (Opportunity.Churn_Date__c >= ' || :v_var_sales_data_pp_start_date || ' and Opportunity.Churn_Date__c <= ' || :v_var_sales_data_pp_end_date|| ' and Opportunity.CloseDate >= Opportunity.Churn_Date__c ))',
    CredentialName = 'sfdc_cred',
    ReadAll=false,
    Retries=2,
    RetryInterval=1)
)


Create step s_holdover_split_participant_hierarchy_dmp AS (
Insert Into Delta(TableName='delta.participant_hierarchy',Overwrite=true,Unlogged=true)
    SELECT
    ppe.participant_name as part_name
    , SubString(ppe.Participant_Name, IndexOf(ppe.Participant_Name, '(') +1 , IndexOf(ppe.Participant_Name, ')')) AS part_employee_id
    , part.termination_date
    , ppm.participant_name AS mgr_name
    , SubString(ppm.Participant_Name, IndexOf(ppm.Participant_Name, '(') +1 , IndexOf(ppm.Participant_Name, ')')) AS mgr_employee_id
    FROM xc_pos_hierarchy h
    JOIN xc_pos_hierarchy_type ht ON h.POS_HIERARCHY_TYPE_ID = ht.POS_HIERARCHY_TYPE_ID 
    JOIN xc_pos_part_assignment ppe ON h.TO_POS_ID = ppe.POSITION_ID
    JOIN (SELECT part.name
        , part.employee_id
        , part.termination_date 
        , partm.participant_id AS master_participant_id
        FROM xactly.xc_participant part 
        JOIN xactly.xc_participant partm ON part.employee_id = partm.employee_id AND partm.is_master = '1'
        WHERE 1=1 
        AND :v_var_sales_data_pp_start_date BETWEEN part.effective_start_date AND part.effective_end_date) part ON ppe.participant_id = part.master_participant_id
    JOIN xc_pos_part_assignment ppm ON h.FROM_POS_ID = ppm.POSITION_ID
    WHERE 1=1 
    AND :v_var_sales_data_pp_start_date BETWEEN ht.effective_start_date AND ht.effective_end_date
)

Create step s_holdover_split_opportunity_approval_process_dmp AS (
INSERT INTO Delta(TableName='delta.holdover_split_approval_process_dmp',Overwrite=true)
    SELECT 
    Opportunity__c
    ,Id
    ,Approval_Sales_Manager__c
    ,OwnerId
    ,Owner.userRole.name
    ,ToDate(CreatedDate) AS CreatedDate
    ,Description__c 
    FROM SFDC(SOQL='
    SELECT Opportunity__c
    , id
    , Approval_Sales_Manager__c
    , OwnerId
    , Owner.userRole.name
    , CreatedDate
    , Description__c
    FROM Approval_Process__c
    WHERE Description__c NOT IN (''SDR Approval Process'')
    AND Approval_Sales_Manager__c <> ''No''
    AND ((Opportunity__r.CloseDate >= '|| :v_var_sales_data_pp_start_date ||' AND Opportunity__r.CloseDate <= '|| :v_var_sales_data_pp_end_date||')
        OR (Opportunity__r.Churn_Date__c >= '|| :v_var_sales_data_pp_start_date ||' and Opportunity__r.Churn_Date__c <= '|| :v_var_sales_data_pp_end_date||' AND Opportunity__r.CloseDate > '|| :v_var_sales_data_pp_end_date||'))',
    CredentialName = 'sfdc_cred',
    ReadAll=false,
    Retries=2,
    RetryInterval=1)
    WHERE 1=1
    AND Opportunity__c IN (SELECT DISTINCT order_code FROM xactly.xc_order_stage)
)

-- Create step s_holdover_split_credit_type_dmp AS (
-- INSERT INTO Delta(TableName='delta.holdover_split_credit', Overwrite=true)
--     SELECT DISTINCT 
--     b.Order_Code
--     -- , b.participant_Name
--     -- , SubString(b.Participant_Name, IndexOf(b.Participant_name, '(')+1, IndexOf(b.Participant_name, ')')) AS Employee_ID
--     , LeftSide(c.Name, IndexOf(c.Name, '-')) AS CreditTypeName
--     FROM delta.holdover_split_dmp a
--     JOIN xactly.xc_commission b ON a.opp_Id = b.Order_Code -- AND a.employee_id = SubString(b.Participant_Name, IndexOf(b.Participant_name, '(')+1, IndexOf(b.Participant_name, ')'))
--     JOIN xactly.xc_credit_type c ON b.CREDIT_TYPE_ID = c.CREDIT_TYPE_ID
--     WHERE 1=1 
--      AND c.Name INN ('Closed Lost ARR-Comm Credit','Upsell ARR-Comm Credit','Recovery ARR-Comm Credit')
-- )

Create step s_holdover_split_transform AS (
Insert Into Delta(TableName='delta.holdover_split_transform',Overwrite=true,Unlogged=true)
    SELECT 
    a.opp_Id
    , a.Opp_Name
    , a.Role
    , a.Name
    , a.employee_id
    , a.Manager_Name
    , a.Manager_Employee_id
    , a.Customer_Name
    , c.Split_Percentage__c
    , c.Penalty_percentage__c

    ,  CASE WHEN a.Churn_Date IS NOT NULL AND StageName = '06-Closed Won' AND a.Churn_Date < :v_var_sales_data_pp_start_date THEN 'Recovery ARR'
        WHEN a.Churn_Date IS NOT NULL  AND a.Churn_Date BETWEEN :v_var_sales_data_pp_start_date AND :v_var_sales_data_pp_end_date
            AND ((a.StageName IN ('06-Closed Won', '06-Closed Lost') AND a.Order_Date > :v_var_sales_data_pp_end_date) OR a.StageName NOT IN ('06-Closed Won', '06-Closed Lost') )  
            THEN 'Expiring ARR'
        WHEN a.StageName = '06-Closed Lost' THEN 'Closed Lost ARR'
        WHEN a.Final_ARR_Growth >0 THEN 'Upsell ARR'
        ELSE 'Downsell ARR' END AS ARR_Credit_Type
    , a.Order_Date
    , a.Tier
    , a.CurrencyIsoCode

    , CASE WHEN ARR_Credit_Type IN ('Recovery ARR','Closed Lost ARR') THEN Nvl(c.Penalty_percentage__c,0) 
        WHEN ARR_Credit_Type IN ('Expiring ARR') THEN Nvl((c.Penalty_percentage__c)*-1,0) 
        ELSE Nvl(c.Split_Percentage__c,0) END AS Holdout_PCT

    , IF ARR_Credit_Type IN ('Recovery ARR','Expiring ARR') THEN a.Related_Contracts_ARR ELSE a.Final_ARR_Growth END AS Final_ARR_Growth

    FROM delta.holdover_split_dmp a
    JOIN (SELECT opp_id, Penalty_percentage__c, Split_Percentage__c FROM holdover_split_dmp WHERE Role = 'Former Owner') c ON a.opp_id = c.opp_id
    JOIN holdover_split_approval_process_dmp b ON a.opp_Id = b.Opportunity__c
)


Create step s_set_batch_seq_num AS (
set v_batch_count *= select Count(Batch_Name)+1 from xc_user_batch Where Batch_Name Like '%Manual ADJ%' AND LookupPeriodNameById(Period_ID) = :v_period_name
)

Alter step s_holdover_split_prestage AS (
INSERT INTO Delta(TableName='delta.prestage_holdout_split',Overwrite=true,Unlogged=true)
    SELECT DISTINCT a.opp_id||'_'||MonthName(ToDate(a.Order_Date))||'_Holdout_ADJ_ADJ' AS Order_Code
    , IF a.Employee_id iS NOT NULL THEN Concat(a.Name,'_',:v_period_name,'_',a.ARR_Credit_Type ) 
        ELSE Concat(a.Manager_Name,'_',:v_period_name,'_',a.ARR_Credit_Type ) END AS Item_Code 
    , 'Holdout ADJ_'||:v_period_name AS Batch_Name
    , 'Holdout Opportunity Adjustments' AS batch_type_name
    , NULL AS Product_name
    , NULL AS Geography_name
    , a.Customer_Name AS Customer_Name
    , NULL AS Quantity
    , IF a.Role = 'Owner' THEN (a.Final_ARR_Growth*(a.Holdout_PCT/100))*-1
        ELSE a.Final_ARR_Growth*(a.Holdout_PCT/100) END AS Amount 
    , a.CurrencyIsoCode AS amount_unit_type_name
    , :v_var_sales_data_pp_end_date AS Incentive_Date
    , a.Order_Date AS Order_Date
    , a.ARR_Credit_Type AS order_type_name
    , MonthName(ToDate(a.Order_Date))||' Holdout ADJ' AS Description

    -- Custom Fields
    , 'Quota Credit' AS Comp_Credit
    , 0 AS Co_Termed_Unused_ARR
    , 'USD' AS Co_Termed_Unused_ARR_UnitTypeName
    -- Assignments
    , IF ph.termination_date < :v_var_sales_data_pp_start_date then ph.mgr_employee_id ELSE Nvl(a.Employee_id, a.Manager_Employee_id) END AS Employee_ids
    , 100 AS split_amount_pct
    FROM delta.holdover_split_transform a
    LEFT JOIN delta.participant_hierarchy ph ON a.employee_id = ph.part_employee_id
    WHERE 1=1
    AND a.Tier !='Public Sector'
    AND IsValidEmployeeId(Employee_ids) = true
)

p_clear_stage_orders

Create step s_holdover_split_order_stage AS (
Insert Into staging.Order_item(
    order_code
    , item_code
    , source_id
    , amount
    , amount_unit_type_name
    , discount
    , quantity
    , incentive_date
    , order_date
    , order_type_name
    , batch_name
    , batch_type_name
    , period_name
    , product_name
    , customer_name
    , geography_name
    , related_order_code
    , related_item_code
    , description
    , Comp_Credit
    , Co_Termed_Unused_ARR
    , Co_Termed_Unused_ARR_UnitTypeName)
    SELECT order_code
    , item_code
    , NULL AS source_id
    , amount
    , amount_unit_type_name
    , NULL AS discount
    , quantity
    , incentive_date
    , order_date
    , order_type_name
    , batch_name
    , batch_type_name
    , :v_period_name AS period_name
    , product_name
    , customer_name
    , geography_name
    , NULL AS related_order_code
    , NULL AS related_item_code
    , description
    , Comp_Credit
    , Co_Termed_Unused_ARR
    , Co_Termed_Unused_ARR_UnitTypeName
    FROM delta.prestage_holdout_split
)

Create step s_holdover_split_assignment_stage AS (
Insert Into Staging.Order_item_Assignment
    (Order_Code, Item_Code, Employee_id, split_amount_pct)
    SELECT Order_Code, Item_Code, Employee_ids AS employee_id, split_amount_pct FROM delta.prestage_holdout_split
)

s_incent_create_batches
incent synchronous create batches

s_sleep_ten
sleep 10

p_populate_staging_c_g_p

s_clear_stg_order_item_validation_error
delete from delta.stg_order_item_validation_error
s_incent_validate_orders
incent synchronous validate orders
s_load_stg_order_item_validation_error
INSERT Into delta.stg_order_item_validation_error
    SELECT * FROM staging.order_item_validation_error
 p_Shared_Clear_Invalid_Stage_Orders

s_incent_upload_orders
Incent synchronous upload orders



SubString(xcoia.Participant_Name, IndexOf(xcoia.Participant_name, '(')+1, IndexOf(xcoia.Participant_name, ')')) AS employee_id