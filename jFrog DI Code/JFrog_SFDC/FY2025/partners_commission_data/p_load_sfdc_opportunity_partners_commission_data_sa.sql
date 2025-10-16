p_load_sfdc_opportunity_partners_commission_data_sa

Create step s_d2c_load_osfdc_opportunity_partners_commission_data AS (
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

s_set_sfdc_credentials
set v_sfdc_user *= 'xactlyintegrationuserjfrog@jfrog.com';
set v_sfdc_passwd *= '1234asdfz7HJ4SIFpUN3JaITEwtUYw5Hj';

s_sfdc_user_dump
INSERT into Delta(TableName='delta.sfdc_uer_dump', Overwrite=true, Unlogged=true)
    select Id,Name, employeeid__c emp_id
    FROM SFDC(SOQL='select Id,Name, employeeid__c
    from User where employeeid__c <> null',
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1)

s_tmp_pos_part_title_data_dump
INSERT into Delta(TableName='delta.pos_part_title_data_dump', Overwrite=true, Unlogged=true)
    select a.name position_name,c.employee_id,d.title_name from xactly.xc_position a join xactly.xc_pos_part_assignment b on a.position_id = b.position_id
    join xactly.xc_participant c on b.participant_id = c.participant_id
    join xactly.xc_pos_title_assignment d on a.position_id = d.position_id
    where :v_var_sales_data_pp_end_date between a.effective_start_date and a.effective_end_date

s_sfdc_opp_team_member_dump
INSERT into Delta(TableName='delta.sfdc_opp_team_member_dump1', Overwrite=true, Unlogged=true)
    select Id,Name,OpportunityId,TeamMemberRole,TItle,UserId ,User.employeeid__c as employee_id FROM SFDC(SOQL='select Id,Name,OpportunityId,TeamMemberRole,TItle,UserId,User.employeeid__c from OpportunityTeamMember ',
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=true,
    Retries=2,
    RetryInterval=1
    ) where TeamMemberRole in ('Co-Sell Cloud Alliance Lead','Partner Manager','Renewal Team','MarketPlace Sales Lead')

s_sfdc_opp_team_member_count_dump
INSERT into Delta(TableName='delta.sfdc_opp_team_member_count_dump', Overwrite=true, Unlogged=true)
    select OpportunityId,TeamMemberRole,count(*) as role_cnt FROM SFDC(SOQL='select Id,Name,OpportunityId,TeamMemberRole,TItle,UserId,User.employeeid__c from OpportunityTeamMember ',
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=true,
    Retries=2,
    RetryInterval=1
    ) where TeamMemberRole in ('Co-Sell Cloud Alliance Lead','Partner Manager','Renewal Team','MarketPlace Sales Lead')

s_sfdc_opp_team_member_dump_final
INSERT into Delta(TableName='delta.sfdc_opp_team_member_dump', Overwrite=true, Unlogged=true)
    select a.*, b.role_cnt from delta.sfdc_opp_team_member_dump1 a join delta.sfdc_opp_team_member_count_dump b on a.OpportunityId = b.OpportunityId and a.TeamMemberRole = b.TeamMemberRole

Create step s_clear_pstg_order_item_final AS ( Delete From delta.pstg_order_item_final; )

s_load_sfdc_opportunity_partners_commission_data
INSERT INTO Delta(TableName='delta.pstg_order_item_final', Overwrite=false, unlogged=false)
    SELECT DISTINCT
    Id AS Order_Code,
    Nvl(Opportunity.PrimaryProduct__r.Name || '_Partner Commission_' || Opportunity.CloseDate, 'No Product_' || 'Opportunity_' || Opportunity.CloseDate) AS item_code,
    'Partner Commission_'||:v_param_processing_period AS Batch_Name,
    'Partner Commission' AS Batch_Type,
    :v_param_processing_period as period_name,
    Opportunity.PrimaryProduct__r.Name AS Product_name,
    Opportunity.End_User_Country__c AS Geography_name,
    Account.Name AS Customer_Name,
    '1' AS Quantity,
    Nvl(Opportunity_SBQQ__PrimaryQuote__r_Total_Partners_Commission__c,0) AS Amount,
    'USD' AS amount_UnitType,
    ToDate(Opportunity_CloseDate) AS incentive_date,
    null AS Order_Date,
    'Partner Commission' AS order_type,
    NULL AS Discount,
    NULL AS Discount_UnitType,
    Opportunity.Name AS Description,
    null AS Related_Order_Code,
    null AS Related_item_Code,
    CASE
        WHEN JFrog_Subsidiary__c = 'JFrog SAS' THEN 'Partner_SAS_001'
        WHEN JFrog_Subsidiary__c = 'JFrog LTD' THEN 'Partner_Ltd_001'
        WHEN JFrog_Subsidiary__c = 'JFrog China' THEN 'Partner_China_001'
        ELSE 'Partner_Inc_001'
    END AS Employee_id,
    '100' AS split_pct,
    Opportunity.CloseDate AS CloseDate,
    Opportunity.Monthly_Validation__c as Monthly_Validation,
    Opportunity.Churn_Date__c AS Churn_Date,
    Opportunity.ARR_Difference__c AS Final_ARR_Growth,
    CASE when (Opportunity.ARR_Difference__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Final_ARR_Growth_UnitType,
    Opportunity.StageName AS StageName,
    Opportunity.Related_Contracts_ARR_Formula__c AS Related_Contract_ARR,
    CASE when (Opportunity.Related_Contracts_ARR_Formula__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Related_Contract_ARR_UnitType,
    Opportunity.Current_ARR__c AS Final_Contract_ARR,
    CASE when (Opportunity.Current_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Final_Contract_ARR_UnitType,
    Reseller_Account__r.Name AS Reseller_Account,
    Opportunity.Approval_Done__c AS Approval_Done,
    Opportunity.Renewal_Credit_Amount_ARR__c AS Renewal_ARR,
    CASE when (Opportunity.Renewal_Credit_Amount_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Renewal_ARR_UnitType,
    null AS Deal_Date,
    Opportunity.Renewal_Type__c AS Renewal_Type,
    Opportunity.Record_Type_Name__c AS Record_Type_Name,
    Opportunity.Out_of_Recovery_Period__c AS Out_of_Recovery_Period,
    Opportunity.LeadSource AS Lead_Source,
    null AS Opportunity_Description,
    Opportunity.Previous_ARR__c AS Previous_ARR,
    CASE when (Opportunity.Previous_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Previous_ARR_UnitType,
    --Opportunity.Consulting_Amount_Summary__c AS Consulting,
    null AS Consulting,
    /*CASE when (Opportunity.Consulting_Amount_Summary__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Consulting_UnitType,*/
    null AS Consulting_UnitType,
    Opportunity.Product_Platform__c AS Product_Type,
    null AS Approval_Manager,
    Opportunity.Number_of_months_for_ARR__c AS ARR_Number_of_months,
    CASE when (Opportunity.Number_of_months_for_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS ARR_Number_of_months_UnitType,
    NULL AS Order_Process_Date,
    Opportunity.End_User_Country__c AS End_User_Country,
    Opportunity.Shipped_to_country__c AS Shipped_to_country,
    null As Approval_Process_Created_Date,
    null AS Approval_Process_Role,
    null AS System_Approval_Description,
    NULL as split_amount_pct,
    Opportunity_Contract_Unused_ARR_Amount__c AS Co_Termed_Unused_ARR,
    CASE when (Opportunity_Contract_Unused_ARR_Amount__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Co_Termed_Unused_ARR_UnitType,
    Opportunity.Solution_Engineer__c as Opp_Solution_Engineer,
    Opportunity.Cloud_Migration__c as Opp_Cloud_Migration,
    Opportunity.Final_Number_of_Month__c as Opp_Final_Number_of_Month,
    Opportunity.Opp_Platform__c as Opp_Opp_Platform,
    null AS Opp_Strategic_Opp_Solution_Architect_name,
    Opportunity.Strategic_Opportunity_Solution_Architect__c as Opp_Strategic_Opp_Solution_Architect,
    account.Business_Unit__r.Territory__c as Business_Unit_Territory, account.Business_Unit__r.Pod__c as Business_Unit_Pod,
    account.Business_Unit__r.Tier_Level__c as Business_Unit_Tier_Level,
    account.Business_Unit__r.Tier_Manager__r.Name as Business_Unit_Tier_Manager_Name, account.Business_Unit__r.Tier_Manager__c as
    Business_Unit_Tier_Manager_ID, account.Business_Unit__r.Regional_VP__r.Name as Business_Unit_Regional_VP_Name,
    account.Business_Unit__r.Pod_Manager__r.Name Business_Unit_Pod_Manager_Name, CSM__c Opp_CSM,Opportunity.Type Opp_Type,
    Opportunity.Owner.Name Opp_Owner_Name,Opportunity.Comp_Credit__c Opp_Comp_Credit, Opportunity.PS_Net_Amount__c as PS_Net_Amount,
    Opportunity.JAS_Net_Amount__c as JAS_Net_Amount, Opportunity.Co_Sell_Program_Opportunity__c as Co_Sell_Program_Opportunity,
    Opportunity.Marketplace_Offer_ID__c as Marketplace_Offer_ID,
    Opportunity.Partner_Lead_Source__c as Partner_Lead_Source,
    Opportunity.PRM_Opportunity_Origination__c as PRM_Opportunity_Origination,
    Opportunity.Cloud_Alliance_Partner__c as Cloud_Alliance_Partner
    , Nvl(Opportunity.Qualified_Prospect__c,false) as Qualified_Prospect
    , 0 AS Security_Final_ARR_Growth
    , 'USD' AS Security_Final_ARR_Growth_UnitTypeName,
    Opportunity.Security_Net_Amount__c AS Security_Net_Amount,
    IF Opportunity.Security_Net_Amount__c IS NOT NULL THEN 'USD'ELSE NULL END AS Security_Net_Amount_UnitTypeName,
    Opportunity.Cloud_Alliance_Co_Sell_Opportunity__c AS Cloud_Alliance_Co_Sell_Opportunity__c
    , Opportunity.Cloud_Alliance_Opportunity_ID__c AS Cloud_Alliance_Opportunity_ID__c
    , Opportunity.Meeting_Status__c AS Meeting_Status
    , Opportunity.Final_Qualified_Product__c AS Final_Qualified_Product
    , Opportunity.Purchese_Type__c AS Purchase_Type
    , IF Contains(Uppercase(Opportunity.PrimaryProduct__r.Name),'MONTHLY')=true THEN true ELSE false END AS Is_Monthly_Subscription_Product
    , Opportunity_CoTerming_Type__c as CoTerming_Type
    , Opportunity_Netsuite_Order_Number__c as SO_Number
    --, JFrog_Subsidiary_Original__c
    --, Subsidiary_Manual__c
    --, Shipping_Country__r_Subsidiary__c
    --select *
    from SFDC(SOQL='select Id,
    Opportunity.Netsuite_Order_Number__c,
    Opportunity.SBQQ__PrimaryQuote__r.Total_Partners_Commission__c,
    Opportunity.PrimaryProduct__r.Name,
    Opportunity_Contract_Unused_ARR_Amount__c,
    Opportunity.End_User_Country__c,
    Account.Name,
    Opportunity.Amount,
    Opportunity.Name,
    Opportunity.CloseDate,
    Opportunity.Monthly_Validation__c,
    Opportunity.Churn_Date__c,
    Opportunity.ARR_Difference__c,
    Opportunity.StageName,
    Opportunity.Related_Contracts_ARR_Formula__c,
    Opportunity.Current_ARR__c,
    Opportunity.Reseller_Account__c,
    Reseller_Account__r.Name,
    Opportunity.Approval_Done__c,
    Opportunity.Renewal_Credit_Amount_ARR__c,
    Opportunity.Renewal_Type__c,
    Opportunity.Record_Type_Name__c,
    Opportunity.Out_of_Recovery_Period__c,
    Opportunity.LeadSource,
    Opportunity.Description,
    Opportunity.Previous_ARR__c,
    Opportunity.Product_Platform__c,
    Opportunity.Number_of_months_for_ARR__c,
    Opportunity.Shipped_to_country__c,
    CreatedDate, Opportunity.Solution_Engineer__c,Opportunity.Cloud_Migration__c,Opportunity.Final_Number_of_Month__c,Opportunity.Opp_Platform__c,
    Opportunity.Strategic_Opportunity_Solution_Architect__c,
    account.Business_Unit__r.Territory__c, account.Business_Unit__r.Pod__c, account.Business_Unit__r.Tier_Level__c,
    account.Business_Unit__r.Tier_Manager__r.Name, account.Business_Unit__r.Tier_Manager__c, account.Business_Unit__r.Regional_VP__r.Name,
    account.Business_Unit__r.Pod_Manager__r.Name, CSM__c,Opportunity.Type,Opportunity.Owner.Name,Opportunity.Comp_Credit__c,
    Opportunity.PS_Net_Amount__c, Opportunity.JAS_Net_Amount__c,Opportunity.Co_Sell_Program_Opportunity__c, Opportunity.Marketplace_Offer_ID__c,
    Opportunity.Partner_Lead_Source__c,
    Opportunity.PRM_Opportunity_Origination__c,
    Opportunity.Cloud_Alliance_Partner__c,
    Opportunity.Qualified_Prospect__c,

    Opportunity.Security_Net_Amount__c,
    Opportunity.Cloud_Alliance_Co_Sell_Opportunity__c,
    Opportunity.Cloud_Alliance_Opportunity_ID__c,
    Opportunity.Meeting_Status__c,
    Opportunity.Final_Qualified_Product__c,
    Opportunity.Purchese_Type__c,
    Opportunity.CoTerming_Type__c,
    Subsidiary_Manual__c,
    JFrog_Subsidiary__c,
    Shipping_Country__r.Subsidiary__c
    from Opportunity where
    SBQQ__PrimaryQuote__r.Total_Partners_Commission__c != 0 and StageName = ''06-Closed Won'' and Co_Sell_Program_Opportunity__c = true and CloseDate >= '|| :v_var_sales_data_pp_start_date || ' and CloseDate <= ' || :v_var_sales_data_pp_end_date,
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1
    ) opp


p_load_orders