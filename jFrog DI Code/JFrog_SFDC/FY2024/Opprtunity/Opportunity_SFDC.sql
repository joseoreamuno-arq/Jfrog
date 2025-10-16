p_load_sfdc_opportunity_data

Create step s_load_sfdc_opportunity_data AS (
INSERT into Delta(TableName='delta.pstg_order_item_arr_breakdown', Overwrite=true, Unlogged=true)
    SELECT Opp_id__c
    , Final_arr_growth__c
    ,Product_family__c
    FROM  SFDC( SOQL='SELECT Opp_id__c,  Final_arr_growth__c,Product_family__c FROM Arr_breakdown__x',
    UserName=:v_sfdc_user,Password=:v_sfdc_passwd,Environment=:v_sfdc_env,ReadAll=false,Retries=2,RetryInterval=1);
)

s_generic_user_load

s_load_staging_order_item
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
, Close_Date
, Churn_Date
, Final_ARR_Growth
, Final_ARR_Growth_UnitTypeName
, StageName
, Related_contract_ARR
, Related_contract_ARR_UnitTypeName
, Final_contract_ARR
, Final_contract_ARR_UnitTypeName
, Reseller_account
, Approval_Done
, Renewal_ARR
, Renewal_ARR_UnitTypeName
, Deal_date
, Renewal_type
, Record_type_name
, Out_of_Recovery_Period
, Lead_Source
, Approval_Description
, Previous_ARR
, Previous_ARR_UnitTypeName
, Consulting
, Consulting_UnitTypeName
, Product_Type
, Approval_manager
, ARR_number_of_months
, ARR_number_of_months_UnitTypeName
, Order_Process_Date
, End_User_Country
, Shipped_to_Country
, Approval_Process_Created_Date
, Approval_Process_Role
, Co_Termed_Unused_ARR
, Co_Termed_Unused_ARR_UnitTypeName
, Strategic_Solution_Architect_Name
, Strategic_Solution_Architect
, Cloud_Migration
, Final_Number_of_Month
, Final_Number_of_Month_UnitTypeName
, Opp_Platform
, CSM_Opportunity
, Territory
, Pod
, Tier_Level
, Regional_VP
, Pod_Manager
, Tier_Manager
, Is_Enterprise_Plus_Product
, Opportunity_Owner
, Opportunity_Owner_Title
, Tier_Manager_Title
, Comp_Credit
, PS_Net_Amount
, JAS_Net_Amount
, PS_Net_Amount_UnitTypeName
, JAS_Net_Amount_UnitTypeName
, Co_Sell_Program_Opportunity
, Co_Sell_Cloud_Alliance_Lead
, Partner_Manager
, Renewal_Team
, MarketPlace_Sales_Lead
, Co_Sell_Cloud_Alliance_Lead_Role
, Partner_Manager_Role
, Renewal_Team_Role
, MarketPlace_Sales_Lead_Role
, Marketplace_Offer_ID
, Partner_Lead_Source
, PRM_Opportunity_Origination
, Cloud_Alliance_Partner
, Security_Net_Amount
, Security_Net_Amount_UnitTypeName
,Qualified_Prospect
,Security_Final_ARR_Growth
, Security_Final_ARR_Growth_UnitTypeName
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
, CloseDate AS Close_Date
, Churn_Date
, Final_ARR_Growth
, Final_ARR_Growth_UnitType AS Final_ARR_Growth_UnitTypeName
, StageName
, Related_contract_ARR
, Related_contract_ARR_UnitType AS Related_contract_ARR_UnitTypeName
, Final_contract_ARR
, Final_contract_ARR_UnitType AS Final_contract_ARR_UnitTypeName
, Reseller_account
, Approval_Done
, Renewal_ARR
, Renewal_ARR_UnitType AS Renewal_ARR_UnitTypeName
, Deal_date
, Renewal_type
, Record_type_name
, Out_of_Recovery_Period
, Lead_Source
, System_Approval_Description AS Approval_Description
, Previous_ARR
, Previous_ARR_UnitType AS Previous_ARR_UnitTypeName
, Consulting
, Consulting_UnitType AS Consulting_UnitTypeName
, Product_Type
, Approval_manager
, ARR_number_of_months
, ARR_number_of_months_UnitType AS ARR_number_of_months_UnitTypeName
, Order_Process_Date
, End_User_Country
, Shipped_to_Country
, Approval_Process_Created_Date
, Approval_Process_Role
, Co_Termed_Unused_ARR
, Co_Termed_Unused_ARR_UnitType AS Co_Termed_Unused_ARR_UnitTypeName
, Strategic_Solution_Architect_Name
, Strategic_Solution_Architect
, Cloud_Migration
, Final_Number_of_Month
, Final_Number_of_Month_UnitTypeName
, Opp_Platform
, CSM_Opportunity
, Territory
, Pod
, Tier_Level
, Regional_VP
, Pod_Manager
, Tier_Manager
, Is_Enterprise_Plus_Product
, Opportunity_Owner
, Opportunity_Owner_Title
, Tier_Manager_Title
, Comp_Credit
, PS_Net_Amount
, JAS_Net_Amount
, PS_Net_Amount_UnitTypeName
, JAS_Net_Amount_UnitTypeName
, Co_Sell_Program_Opportunity
, Co_Sell_Cloud_Alliance_Lead
, Partner_Manager
, Renewal_Team
, MarketPlace_Sales_Lead
, Co_Sell_Cloud_Alliance_Lead_Role
, Partner_Manager_Role
, Renewal_Team_Role
, MarketPlace_Sales_Lead_Role
, Marketplace_Offer_ID
, Partner_Lead_Source
, PRM_Opportunity_Origination
, Cloud_Alliance_Partner
, Security_Net_Amount
, Security_Net_Amount_UnitTypeName
,Qualified_Prospect
,Security_Final_ARR_Growth
, Security_Final_ARR_Growth_UnitTypeName
FROM delta.prestage_order_item pstg
LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
WHERE err.created_timestamp IS null

--------------------------------------------------------------------------------------------------------------------------------

Alter step s_load_prestage_order_item AS (
Insert Into Delta (Tablename='delta.prestage_order_item', Overwrite=true,unlogged=true)
    SELECT DISTINCT Order_Code
    , Item_Code
    , Batch_Name
    , Batch_Type
    , period_name
    , Product_Name
    , Geography_Name
    , Customer_Name
    , Quantity
    , Amount
    , Monthly_Validation
    , Amount_UnitType
    , Incentive_Date
    , Order_Date
    , CASE WHEN Opp_Type = 'Consulting' THEN 'Consulting' ELSE Order_Type END AS order_type_name
    , Discount
    , Description
    , Related_Order_Code
    , Related_Item_Code
    , CloseDate
    , Churn_Date
    , Final_ARR_Growth
    , Final_ARR_Growth_UnitType
    , StageName
    , Related_contract_ARR
    , Related_contract_ARR_UnitType
    , Final_contract_ARR
    , Final_contract_ARR_UnitType
    , Reseller_account
    , Approval_Done
    , Renewal_ARR
    , Renewal_ARR_UnitType
    , Deal_date
    , Renewal_type
    , Record_type_name
    , Out_of_Recovery_Period
    , Lead_Source
    , System_Approval_Description
    , Previous_ARR
    , Previous_ARR_UnitType
    , Consulting
    , Consulting_UnitType
    , Product_Type
    , Approval_manager
    , ARR_number_of_months
    , ARR_number_of_months_UnitType
    , Order_Process_Date
    , End_User_Country
    , Shipped_to_Country
    , Approval_Process_Created_Date
    , Approval_Process_Role
    , Co_Termed_Unused_ARR
    , Co_Termed_Unused_ARR_UnitType
    , Opp_Strategic_Opp_Solution_Architect_name AS Strategic_Solution_Architect_Name
    , pstg.Opp_Strategic_Opp_Solution_Architect AS Strategic_Solution_Architect
    , pstg.Opp_Cloud_Migration AS Cloud_Migration
    , Nvl(pstg.Opp_Final_Number_of_Month, 0) AS Final_Number_of_Month
    , 'QUANTITY' AS Final_Number_of_Month_UnitTypeName
    , pstg.Opp_Opp_Platform AS Opp_Platform
    , pstg.Opp_CSM AS CSM_Opportunity
    , pstg.Business_Unit_Territory AS Territory
    , pstg.Business_Unit_Pod AS Pod
    , pstg.Business_Unit_Tier_Level AS Tier_Level
    , pstg.Business_Unit_Regional_VP_Name AS Regional_VP
    , pstg.Business_Unit_Pod_Manager_Name AS Pod_Manager
    , pstg.Business_Unit_Tier_Manager_Name AS Tier_Manager
    , CASE WHEN Product_name like '%Enterprise+%' THEN 'True'ELSE 'False' END AS Is_Enterprise_Plus_Product
    , pstg.Opp_Owner_Name AS Opportunity_Owner
    , tl1.title_name AS Opportunity_Owner_Title
    , tl2.title_name AS Tier_Manager_Title
    , Opp_Comp_Credit AS Comp_Credit
    , Nvl(pstg.PS_Net_Amount, 0) AS PS_Net_Amount
    , Nvl(pstg.JAS_Net_Amount, 0) AS JAS_Net_Amount
    , 'USD' AS PS_Net_Amount_UnitTypeName
    , 'USD' AS JAS_Net_Amount_UnitTypeName
    , pstg.Co_Sell_Program_Opportunity AS Co_Sell_Program_Opportunity
    , t1.name AS Co_Sell_Cloud_Alliance_Lead
    , Max(t2.name) AS Partner_Manager
    , t3.name AS Renewal_Team
    , t4.name AS MarketPlace_Sales_Lead
    , tl3.title_name AS Co_Sell_Cloud_Alliance_Lead_Role
    , Max(tl4.title_name) AS Partner_Manager_Role
    , tl5.title_name AS Renewal_Team_Role
    , tl6.title_name AS MarketPlace_Sales_Lead_Role
    , Marketplace_Offer_ID
    , Partner_Lead_Source
    , PRM_Opportunity_Origination
    , Cloud_Alliance_Partner
    , Security_Net_Amount
    , Security_Net_Amount_UnitTypeName
    ,Qualified_Prospect
    ,Security_Final_ARR_Growth
    , Security_Final_ARR_Growth_UnitTypeName
    FROM delta.pstg_order_item_final pstg 
    LEFT JOIN delta.sfdc_opp_team_member_dump t1 ON pstg.Order_Code = t1.OPPORTUNITYID AND t1.TEAMMEMBERROLE = 'Co-Sell Cloud Alliance Lead' AND t1.role_cnt = '1' 
    LEFT JOIN delta.sfdc_opp_team_member_dump t2 ON pstg.Order_Code = t2.OPPORTUNITYID AND t2.TEAMMEMBERROLE = 'Partner Manager' 
    LEFT JOIN delta.sfdc_opp_team_member_dump t3 ON pstg.Order_Code = t3.OPPORTUNITYID AND t3.TEAMMEMBERROLE = 'Renewal Team'AND t3.role_cnt = '1'
    LEFT JOIN delta.sfdc_opp_team_member_dump t4 ON pstg.Order_Code = t4.OPPORTUNITYID AND t4.TEAMMEMBERROLE = 'MarketPlace Sales Lead' 
    LEFT JOIN delta.pos_part_title_data_dump tl3 ON t1.employee_id = tl3.employee_id 
    LEFT JOIN delta.pos_part_title_data_dump tl4 ON t2.employee_id = tl4.employee_id 
    LEFT JOIN delta.pos_part_title_data_dump tl5 ON t3.employee_id = tl5.employee_id 
    LEFT JOIN delta.pos_part_title_data_dump tl6 ON t4.employee_id = tl6.employee_id 
    LEFT JOIN delta.sfdc_uer_dump b ON LeftSide(pstg.Business_Unit_Tier_Manager_ID,15) = LeftSide(b.id, 15) 
    LEFT JOIN xactly.xc_participant part ON pstg.employee_id = part.employee_id AND Lowercase(part.Region) = Lowercase(pstg.BUSINESS_UNIT_TERRITORY) 
    LEFT JOIN delta.pos_part_title_data_dump tl1 ON pstg.employee_id = tl1.employee_id 
    LEFT JOIN delta.pos_part_title_data_dump tl2 ON b.emp_id = tl2.employee_id 
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
)
---------------------------------------------------------------------------------------------------
Alter step s_load_sfdc_opportunity_data AS (
INSERT INTO Delta(TableName='delta.pstg_order_item_final', Overwrite=true, Unlogged=true)
    SELECT
    Opportunity.Id AS Order_Code,
    --Opportunity.PrimaryProduct__r.Name || '_Opportunity_' || Opportunity.CloseDate AS item_code,
    Nvl(Opportunity.PrimaryProduct__r.Name || '_Opportunity_' || Opportunity.CloseDate, 'No Product_' || 'Opportunity_' || Opportunity.CloseDate) AS item_code,
    --Year(ToDate(Opportunity.CloseDate)) || '_0' || Month(ToDate(Opportunity.CloseDate)) || '_Opportunity' AS Batch_Name,
    CASE
    WHEN (Month(ToDate(Opportunity.CloseDate)) = '10' or Month(ToDate(Opportunity.CloseDate)) = '11' or Month(ToDate(Opportunity.CloseDate)) = '12')
    THEN Year(ToDate(Opportunity.CloseDate)) || '_' || Month(ToDate(Opportunity.CloseDate)) || '_Opportunity'
    ELSE
    Year(ToDate(Opportunity.CloseDate)) || '_0' || Month(ToDate(Opportunity.CloseDate)) || '_Opportunity'
    END AS Batch_Name,
    'Opportunity' AS Batch_Type,
    :v_param_processing_period as period_name,
    Opportunity.PrimaryProduct__r.Name AS Product_name,
    Opportunity.End_User_Country__c AS Geography_name,
    Account.Name AS Customer_Name,
    '1' AS Quantity,
    --'QTY' AS Quantity_UnitType,
    Nvl(Opportunity.Amount,0) AS Amount,
    --CASE when (Opportunity.Amount IS NOT NULL) THEN 'USD'
    -- else NULL
    -- END AS amount_UnitType,
    'USD' AS amount_UnitType,
    ToDate(Opportunity.CloseDate) AS incentive_date,
    ToDate(Approval_Process__r.CreatedDate) AS Order_Date,
    'Opportunity' AS order_type,
    NULL AS Discount,
    NULL AS Discount_UnitType,
    Opportunity.Name AS Description,
    relorders.order_code AS Related_Order_Code,
    relorders.item_code AS Related_item_Code,
    Owner.employeeid__c AS Employee_id,
    '100' AS split_pct,
    Opportunity.CloseDate AS CloseDate,
    Opportunity.Monthly_Validation__c as Monthly_Validation,
    Opportunity.Churn_Date__c AS Churn_Date,
    Opportunity.ARR_Difference__c AS Final_ARR_Growth,
    CASE when (Opportunity.ARR_Difference__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Final_ARR_Growth_UnitType,
    --'USD' AS Final_ARR_Growth_UnitType,
    Opportunity.StageName AS StageName,
    Opportunity.Related_Contracts_ARR_Formula__c AS Related_Contract_ARR,
    CASE when (Opportunity.Related_Contracts_ARR_Formula__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Related_Contract_ARR_UnitType,
    --'USD' AS Related_Contract_ARR_UnitType,
    Opportunity.Current_ARR__c AS Final_Contract_ARR,
    CASE when (Opportunity.Current_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Final_Contract_ARR_UnitType,
    --'USD' AS Final_Contract_ARR_UnitType,
    Reseller_Account__r.Name AS Reseller_Account,
    --'USD' AS Reseller_Account_UnitType,
    Opportunity.Approval_Done__c AS Approval_Done,
    Opportunity.Renewal_Credit_Amount_ARR__c AS Renewal_ARR,
    CASE when (Opportunity.Renewal_Credit_Amount_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Renewal_ARR_UnitType,
    --'USD' AS Renewal_ARR_UnitType,
    ToDate(Approval_Process__r.CreatedDate) AS Deal_Date,
    Opportunity.Renewal_Type__c AS Renewal_Type,
    Opportunity.Record_Type_Name__c AS Record_Type_Name,
    Opportunity.Out_of_Recovery_Period__c AS Out_of_Recovery_Period,
    Opportunity.LeadSource AS Lead_Source,
    Approval_Process__r.Description__c AS Opportunity_Description,
    Opportunity.Previous_ARR__c AS Previous_ARR,
    CASE when (Opportunity.Previous_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Previous_ARR_UnitType,
    --'USD' AS Previous_ARR_UnitType,
    Opportunity.Consulting_Amount_Summary__c AS Consulting,
    CASE when (Opportunity.Consulting_Amount_Summary__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Consulting_UnitType,
    --'USD' AS Consulting_UnitType,
    Opportunity.Product_Platform__c AS Product_Type,
    Approval_Process__r.Approval_Sales_Manager__c AS Approval_Manager,
    Opportunity.Number_of_months_for_ARR__c AS ARR_Number_of_months,
    CASE when (Opportunity.Number_of_months_for_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS ARR_Number_of_months_UnitType,
    --'USD' AS ARR_Number_of_months_UnitType,
    --'1' AS Downsell,
    --'USD' AS Downsell_UnitType,
    --'1' AS Churn,
    --'USD' AS Churn_UnitType,
    --'1' As Opening,
    --'USD' AS Opening_UnitType,
    --'Order amount' Order_amount,
    NULL AS Order_Process_Date,
    Opportunity.End_User_Country__c AS End_User_Country,
    Opportunity.Shipped_to_country__c AS Shipped_to_country,
    ToDate(Approval_Process__r.CreatedDate) As Approval_Process_Created_Date,
    Owner.userRole.name AS Approval_Process_Role,
    Approval_Process__r.Description__c AS System_Approval_Description,
    NULL as split_amount_pct,
    Opportunity_Contract_Unused_ARR_Amount__c AS Co_Termed_Unused_ARR,
    CASE when (Opportunity_Contract_Unused_ARR_Amount__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Co_Termed_Unused_ARR_UnitType,
    Opportunity.Solution_Engineer__c as Opp_Solution_Engineer,
    Opportunity.Cloud_Migration__c as Opp_Cloud_Migration,
    Opportunity.Final_Number_of_Month__c as Opp_Final_Number_of_Month,
    Opportunity.Opp_Platform__c as Opp_Opp_Platform,
    CASE when (Opportunity.Strategic_Opportunity_Solution_Architect__c IS NOT NULL)
    THEN user.Name else NULL
    END AS Opp_Strategic_Opp_Solution_Architect_name,
    Opportunity.Strategic_Opportunity_Solution_Architect__c as Opp_Strategic_Opp_Solution_Architect,
    account.Business_Unit__r.Territory__c as Business_Unit_Territory, account.Business_Unit__r.Pod__c as Business_Unit_Pod, account.Business_Unit__r.Tier_Level__c as Business_Unit_Tier_Level, account.Business_Unit__r.Tier_Manager__r.Name as Business_Unit_Tier_Manager_Name, account.Business_Unit__r.Tier_Manager__c as
    Business_Unit_Tier_Manager_ID, account.Business_Unit__r.Regional_VP__r.Name as Business_Unit_Regional_VP_Name, account.Business_Unit__r.Pod_Manager__r.Name Business_Unit_Pod_Manager_Name, CSM__c Opp_CSM,Opportunity.Type Opp_Type, Opportunity.Owner.Name Opp_Owner_Name,Opportunity.Comp_Credit__c Opp_Comp_Credit, Opportunity.PS_Net_Amount__c as PS_Net_Amount, Opportunity.JAS_Net_Amount__c as JAS_Net_Amount, Opportunity.Co_Sell_Program_Opportunity__c as Co_Sell_Program_Opportunity, Opportunity.Marketplace_Offer_ID__c as Marketplace_Offer_ID,
    Opportunity.Partner_Lead_Source__c as Partner_Lead_Source,
    Opportunity.PRM_Opportunity_Origination__c as PRM_Opportunity_Origination,
    Opportunity.Cloud_Alliance_Partner__c as Cloud_Alliance_Partner,
    Opportunity.Qualified_Prospect__c as Qualified_Prospect,
    arrb.Final_arr_growth__c as Security_Final_ARR_Growth,
    IF arrb.Final_arr_growth__c IS NOT NULL THEN 'USD' ELSE NULL END AS Security_Final_ARR_Growth_UnitTypeName,
    Opportunity.Security_Net_Amount__c AS Security_Net_Amount,
    IF Opportunity.Security_Net_Amount__c IS NOT NULL THEN 'USD'ELSE NULL END AS Security_Net_Amount_UnitTypeName
    
    from SFDC(SOQL='select Id,

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
    Opportunity.Consulting_Amount_Summary__c,
    Opportunity.Product_Platform__c,
    Opportunity.Number_of_months_for_ARR__c,
    Opportunity.Shipped_to_country__c,
    Owner.employeeid__c,
    CreatedDate,Opportunity.Solution_Engineer__c,Opportunity.Cloud_Migration__c,Opportunity.Final_Number_of_Month__c,Opportunity.Opp_Platform__c, Opportunity.Strategic_Opportunity_Solution_Architect__c,
    account.Business_Unit__r.Territory__c, account.Business_Unit__r.Pod__c, account.Business_Unit__r.Tier_Level__c, account.Business_Unit__r.Tier_Manager__r.Name, account.Business_Unit__r.Tier_Manager__c, account.Business_Unit__r.Regional_VP__r.Name, account.Business_Unit__r.Pod_Manager__r.Name, CSM__c, Opportunity.Type, Opportunity.Owner.Name,
    Opportunity.Comp_Credit__c, Opportunity.PS_Net_Amount__c, Opportunity.JAS_Net_Amount__c, Opportunity.Co_Sell_Program_Opportunity__c,
    Opportunity.Marketplace_Offer_ID__c,
    Opportunity.Partner_Lead_Source__c,
    Opportunity.PRM_Opportunity_Origination__c,
    Opportunity.Cloud_Alliance_Partner__c,
    Opportunity.Qualified_Prospect__c,

    Opportunity.Security_Net_Amount__c,
    (SELECT Id,Approval_Sales_Manager__c,OwnerId,Owner.userRole.name,CreatedDate,Description__c FROM Approval_Process__r)
    from Opportunity where Opportunity.StageName in(''06-Closed Won'',''06-Closed Lost'') and CloseDate >= ' || :v_var_sales_data_pp_start_date || ' and CloseDate <= ' || :v_var_sales_data_pp_end_date,
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1
    ) opp
    LEFT JOIN delta.generic_user_load usr on LeftSide(opp.Solution_Engineer__c,15) = usr.Id
    LEFT JOIN
    (
    SELECT order_code,
    item_code,
    incentive_date
    FROM xactly.xc_comp_order_item coi
    JOIN
    (SELECT Max(Incentive_Date) AS LatestDate,
    Order_Code
    FROM xactly.xc_comp_order_item
    WHERE Incentive_Date < :v_var_sales_data_pp_start_date GROUP BY Order_Code) LatestOrders
    ON coi.order_code = LatestOrders.order_code
    AND coi.incentive_date = LatestOrders.LatestDate
    ) relorders
    on(relorders.order_code = opp.Id)
    LEFT JOIN (SELECT Opp_id__c, Final_arr_growth__c, Product_family__c
        FROM  SFDC( SOQL='SELECT Opp_id__c,  Final_arr_growth__c,Product_family__c FROM Arr_breakdown__x WHERE Product_family__c=''Security''',
        UserName=:v_sfdc_user,Password=:v_sfdc_passwd,Environment=:v_sfdc_env,ReadAll=false,Retries=2,RetryInterval=1)) arrb ON opp.Id=arrb.Opp_id__c 
    WHERE (Approval_Process__r.Description__c NOT IN ('SDR Approval Process', '"SDR Approval Process"'))
    AND (Approval_Process__r.Description__c NOT IN ('Passed', '"Passed"') )
    and (Approval_Process__r.Description__c not IN ('Expiring_ARR', '"Expiring_ARR"') or Order_Code not in (select distinct order_code from xactly.xc_comp_order_item));
)
------------------------------------------------------------------------------------------------------

ALter Step s_load_sfdc_opportunity_sdr_data AS (
INSERT INTO Delta(TableName='delta.pstg_order_item_final', Overwrite=false, unlogged=false)
    SELECT DISTINCT
    Opportunity.Id AS Order_Code,
    Nvl(Opportunity.PrimaryProduct__r.Name || '_SDR_' || ToDate(Approval_Process__r.Ownership_Acceptance_Date_SDR__c), 'No Product_' || 'SDR_' || ToDate(Approval_Process__r.Ownership_Acceptance_Date_SDR__c)) AS item_code,
    CASE
    WHEN Month(Approval_Process__r.Ownership_Acceptance_Date_SDR__c) >= 10
    THEN Year(Approval_Process__r.Ownership_Acceptance_Date_SDR__c) || '_' || Month(Approval_Process__r.Ownership_Acceptance_Date_SDR__c) || '_SDR'
    ELSE
    Year(Approval_Process__r.Ownership_Acceptance_Date_SDR__c) || '_0' || Month(Approval_Process__r.Ownership_Acceptance_Date_SDR__c) || '_SDR'
    END AS Batch_Name,
    'Opportunity SDR' AS Batch_Type,
    :v_param_processing_period as period_name,
    Opportunity.PrimaryProduct__r.Name AS Product_name,
    Opportunity.End_User_Country__c AS Geography_name,
    Account.Name AS Customer_Name,
    '1' AS Quantity,
    Nvl(Opportunity.Amount,0) AS Amount,
    'USD' AS amount_UnitType,
    ToDate(Approval_Process__r.Ownership_Acceptance_Date_SDR__c) AS incentive_date,
    ToDate(Approval_Process__r.CreatedDate) AS Order_Date,
    'Opportunity SDR' AS order_type,
    NULL AS Discount,
    NULL AS Discount_UnitType,
    Opportunity.Name AS Description,
    relorders.order_code AS Related_Order_Code,
    relorders.item_code AS Related_item_Code,
    Approval_Process__r.Owner_EmployeeID__c AS Employee_id,
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
    ToDate(Approval_Process__r.CreatedDate) AS Deal_Date,
    Opportunity.Renewal_Type__c AS Renewal_Type,
    Opportunity.Record_Type_Name__c AS Record_Type_Name,
    Opportunity.Out_of_Recovery_Period__c AS Out_of_Recovery_Period,
    Opportunity.LeadSource AS Lead_Source,
    Approval_Process__r.Description__c AS Opportunity_Description,
    Opportunity.Previous_ARR__c AS Previous_ARR,
    CASE when (Opportunity.Previous_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Previous_ARR_UnitType,
    Opportunity.Consulting_Amount_Summary__c AS Consulting,
    CASE when (Opportunity.Consulting_Amount_Summary__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Consulting_UnitType,
    Opportunity.Product_Platform__c AS Product_Type,
    Approval_Process__r.Approval_Sales_Manager__c AS Approval_Manager,
    Opportunity.Number_of_months_for_ARR__c AS ARR_Number_of_months,
    CASE when (Opportunity.Number_of_months_for_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS ARR_Number_of_months_UnitType,
    NULL AS Order_Process_Date,
    Opportunity.End_User_Country__c AS End_User_Country,
    Opportunity.Shipped_to_country__c AS Shipped_to_country,
    ToDate(Approval_Process__r.CreatedDate) As Approval_Process_Created_Date,
    null AS Approval_Process_Role,
    Approval_Process__r.Description__c AS System_Approval_Description,
    NULL as split_amount_pct,
    Opportunity_Contract_Unused_ARR_Amount__c AS Co_Termed_Unused_ARR,
    CASE when (Opportunity_Contract_Unused_ARR_Amount__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Co_Termed_Unused_ARR_UnitType,
    Opportunity.Solution_Engineer__c as Opp_Solution_Engineer,
    Opportunity.Cloud_Migration__c as Opp_Cloud_Migration,
    Opportunity.Final_Number_of_Month__c as Opp_Final_Number_of_Month,
    Opportunity.Opp_Platform__c as Opp_Opp_Platform,
    CASE when (Opportunity.Strategic_Opportunity_Solution_Architect__c IS NOT NULL)
    THEN user.Name else NULL
    END AS Opp_Strategic_Opp_Solution_Architect_name,
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
    Opportunity.Cloud_Alliance_Partner__c as Cloud_Alliance_Partner,
    Opportunity.Qualified_Prospect__c as Qualified_Prospect,
    arrb.Final_arr_growth__c AS Security_Final_ARR_Growth,
    IF arrb.Final_arr_growth__c IS NULL THEN NULL ELSE 'USD' END AS Security_Final_ARR_Growth_UnitTypeName,
    Opportunity.Security_Net_Amount__c AS Security_Net_Amount,
    IF Opportunity.Security_Net_Amount__c IS NOT NULL THEN 'USD'ELSE NULL END AS Security_Net_Amount_UnitTypeName
    from SFDC(SOQL='select Id,
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
    Opportunity.Consulting_Amount_Summary__c,
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
    (SELECT Id,Approval_Sales_Manager__c,OwnerId,Owner_EmployeeID__c,Owner.userRole.name,CreatedDate,Description__c,
    Ownership_Acceptance_Date_SDR__c FROM Approval_Process__r)
    from Opportunity',
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1
    ) opp
    LEFT JOIN delta.generic_user_load user on opp.Strategic_Opportunity_Solution_Architect__c = user.Id
    LEFT JOIN
    (
    SELECT order_code,
    item_code,
    incentive_date
    FROM xactly.xc_comp_order_item coi
    JOIN
    (SELECT Max(Incentive_Date) AS LatestDate,
    Order_Code
    FROM xactly.xc_comp_order_item
    WHERE Incentive_Date < :v_var_sales_data_pp_start_date GROUP BY Order_Code) LatestOrders
    ON coi.order_code = LatestOrders.order_code
    AND coi.incentive_date = LatestOrders.LatestDate
    ) relorders
    on(relorders.order_code = opp.Id)
    LEFT JOIN (SELECT Opp_id__c, Final_arr_growth__c, Product_family__c
        FROM  SFDC( SOQL='SELECT Opp_id__c,  Final_arr_growth__c,Product_family__c FROM Arr_breakdown__x WHERE Product_family__c=''Security''',
        UserName=:v_sfdc_user,Password=:v_sfdc_passwd,Environment=:v_sfdc_env,ReadAll=false,Retries=2,RetryInterval=1)) arrb ON opp.Id=arrb.Opp_id__c 
    where Approval_Process__r.Ownership_Acceptance_Date_SDR__c >= :v_var_sales_data_pp_start_date
    and Approval_Process__r.Ownership_Acceptance_Date_SDR__c <= :v_var_sales_data_pp_end_date
    and Approval_Process__r.Ownership_Acceptance_Date_SDR__c is not null
    AND Approval_Process__r.Description__c IN ('SDR Approval Process', '"SDR Approval Process"')
)

------------------------------------------------------------------------------------------------------

Alter step s_load_sfdc_opportunity_churn_data_prestage AS (
INSERT into Delta(TableName='delta.pstg_order_item_churn_prestage', Overwrite=true, Unlogged=true)
    SELECT opp.* FROM
    (SELECT
    Opportunity.Id AS Order_Code,
    Opportunity.Monthly_Validation__c as Monthly_Validation,
    Nvl(Opportunity.PrimaryProduct__r.Name || '_Churn_' || Opportunity.Churn_Date__c, 'No Product_' || 'Churn_' || Opportunity.Churn_Date__c) AS item_code,
    'Opportunity Churn' AS Batch_Type,
    CASE
    WHEN (Month(ToDate(Opportunity.Churn_Date__c)) = '10' or Month(ToDate(Opportunity.Churn_Date__c)) = '11' or Month(ToDate(Opportunity.Churn_Date__c)) = '12')
    THEN Year(ToDate(Opportunity.Churn_Date__c)) || '_' || Month(ToDate(Opportunity.Churn_Date__c)) || '_Churn'
    ELSE
    Year(ToDate(Opportunity.Churn_Date__c)) || '_0' || Month(ToDate(Opportunity.Churn_Date__c)) || '_Churn'
    END AS Batch_Name,
    :v_param_processing_period as period_name,
    Opportunity.PrimaryProduct__r.Name AS Product_name,
    Opportunity.End_User_Country__c AS Geography_name,
    Account.Name AS Customer_Name,
    '1' AS Quantity,
    Nvl(Opportunity.Amount,0) AS Amount,
    'USD' AS amount_UnitType,
    ToDate(Opportunity.Churn_Date__c) AS incentive_date,
    ToDate(Approval_Process__r.CreatedDate) AS Order_Date,
    'Opportunity Churn' AS order_type,
    NULL AS Discount,
    NULL AS Discount_UnitType,
    Opportunity.Name AS Description,
    Owner.employeeid__c AS Employee_id,
    '100' AS split_pct,
    ToDate(Opportunity.CloseDate) AS CloseDate,
    ToDate(Opportunity.Churn_Date__c) AS Churn_Date,
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
    ToDate(Approval_Process__r.CreatedDate) AS Deal_Date,
    Opportunity.Renewal_Type__c AS Renewal_Type,
    Opportunity.Record_Type_Name__c AS Record_Type_Name,
    Opportunity.Out_of_Recovery_Period__c AS Out_of_Recovery_Period,
    Opportunity.LeadSource AS Lead_Source,
    Approval_Process__r.Description__c AS Opportunity_Description,
    Opportunity.Previous_ARR__c AS Previous_ARR,
    CASE when (Opportunity.Previous_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Previous_ARR_UnitType,
    Opportunity.Consulting_Amount_Summary__c AS Consulting,
    CASE when (Opportunity.Consulting_Amount_Summary__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Consulting_UnitType,
    Opportunity.Product_Platform__c AS Product_Type,
    Approval_Process__r.Approval_Sales_Manager__c AS Approval_Manager,
    Opportunity.Number_of_months_for_ARR__c AS ARR_Number_of_months,
    CASE when (Opportunity.Number_of_months_for_ARR__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS ARR_Number_of_months_UnitType,
    NULL AS Order_Process_Date,
    Opportunity.End_User_Country__c AS End_User_Country,
    Opportunity.Shipped_to_country__c AS Shipped_to_country,
    ToDate(Approval_Process__r.CreatedDate) As Approval_Process_Created_Date,
    Owner.userRole.name AS Approval_Process_Role,
    Approval_Process__r.Description__c AS System_Approval_Description,
    Opportunity_Contract_Unused_ARR_Amount__c AS Co_Termed_Unused_ARR,
    CASE when (Opportunity_Contract_Unused_ARR_Amount__c IS NOT NULL) THEN 'USD'
    else NULL
    END AS Co_Termed_Unused_ARR_UnitType,
    Opportunity.Solution_Engineer__c as Opp_Solution_Engineer,
    Opportunity.Cloud_Migration__c as Opp_Cloud_Migration,
    Opportunity.Final_Number_of_Month__c as Opp_Final_Number_of_Month,
    Opportunity.Opp_Platform__c as Opp_Opp_Platform,
    CASE when (Opportunity.Strategic_Opportunity_Solution_Architect__c IS NOT NULL) THEN user.Name
    else NULL
    END AS Opp_Strategic_Opp_Solution_Architect_name,
    Opportunity.Strategic_Opportunity_Solution_Architect__c as Opp_Strategic_Opp_Solution_Architect,
    account.Business_Unit__r.Territory__c as Business_Unit_Territory, account.Business_Unit__r.Pod__c as Business_Unit_Pod, account.Business_Unit__r.Tier_Level__c as Business_Unit_Tier_Level, account.Business_Unit__r.Tier_Manager__r.Name as Business_Unit_Tier_Manager_Name, account.Business_Unit__r.Tier_Manager__c as
    Business_Unit_Tier_Manager_ID , account.Business_Unit__r.Regional_VP__r.Name as Business_Unit_Regional_VP_Name, account.Business_Unit__r.Pod_Manager__r.Name Business_Unit_Pod_Manager_Name, CSM__c Opp_CSM,Opportunity.Type Opp_Type, Opportunity.Owner.Name Opp_Owner_Name,Opportunity.Comp_Credit__c Opp_Comp_Credit, Opportunity.PS_Net_Amount__c as PS_Net_Amount, Opportunity.JAS_Net_Amount__c as JAS_Net_Amount, Opportunity.Co_Sell_Program_Opportunity__c as Co_Sell_Program_Opportunity, Opportunity.Marketplace_Offer_ID__c as Marketplace_Offer_ID,
    Opportunity.Partner_Lead_Source__c as Partner_Lead_Source,
    Opportunity.PRM_Opportunity_Origination__c as PRM_Opportunity_Origination,
    Opportunity.Cloud_Alliance_Partner__c as Cloud_Alliance_Partner,
    null as Qualified_Prospect,
    arrb.Final_arr_growth__c AS Security_Final_ARR_Growth,
    IF arrb.Final_arr_growth__c IS NULL THEN NULL ELSE 'USD' END AS Security_Final_ARR_Growth_UnitTypeName,
    Opportunity.Security_Net_Amount__c AS Security_Net_Amount,
    IF Opportunity.Security_Net_Amount__c IS NOT NULL THEN 'USD'ELSE NULL END AS Security_Net_Amount_UnitTypeName
    FROM SFDC(SOQL='select Id,
        Opportunity.Monthly_Validation__c,
        Opportunity.PrimaryProduct__r.Name,
        Opportunity_Contract_Unused_ARR_Amount__c,
        Opportunity.End_User_Country__c,
        Account.Name,
        Opportunity.Amount,
        Opportunity.Name,
        Opportunity.CloseDate,
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
        Opportunity.Consulting_Amount_Summary__c,
        Opportunity.Product_Platform__c,
        Opportunity.Number_of_months_for_ARR__c,
        Opportunity.Shipped_to_country__c,
        Owner.employeeid__c,
        CreatedDate,Opportunity.Solution_Engineer__c,Opportunity.Cloud_Migration__c,Opportunity.Final_Number_of_Month__c,Opportunity.Opp_Platform__c, Opportunity.Strategic_Opportunity_Solution_Architect__c,
        account.Business_Unit__r.Territory__c, account.Business_Unit__r.Pod__c, account.Business_Unit__r.Tier_Level__c, account.Business_Unit__r.Tier_Manager__r.Name, account.Business_Unit__r.Tier_Manager__c, account.Business_Unit__r.Regional_VP__r.Name, account.Business_Unit__r.Pod_Manager__r.Name, CSM__c, Opportunity.Type,Opportunity.Owner.Name,Opportunity.Comp_Credit__c, Opportunity.PS_Net_Amount__c , Opportunity.JAS_Net_Amount__c , Opportunity.Co_Sell_Program_Opportunity__c, Opportunity.Marketplace_Offer_ID__c,
        Opportunity.Partner_Lead_Source__c,
        Opportunity.PRM_Opportunity_Origination__c,
        Opportunity.Cloud_Alliance_Partner__c,
        Opportunity.Qualified_Prospect__c,

        Opportunity.Security_Net_Amount__c,
        (SELECT Id,Approval_Sales_Manager__c,OwnerId,Owner.userRole.name,CreatedDate,Description__c FROM Approval_Process__r where Description__c <> ''SDR Approval Process'' order by CreatedDate asc )
        from Opportunity where Opportunity.Churn_Date__c >= '||:v_var_sales_data_pp_start_date ||'AND Opportunity.Churn_Date__c <= '||:v_var_sales_data_pp_end_date ||' AND (Opportunity.StageName not in(''06-Closed Won'',''06-Closed Lost'') OR Opportunity.CloseDate >= ' || :v_var_sales_data_pp_end_date || ')',
        UserName=:v_sfdc_user,
        Password=:v_sfdc_passwd,
        Environment=:v_sfdc_env,
        ReadAll=false,
        Retries=2,
        RetryInterval=1
    )opp
    LEFT JOIN delta.generic_user_load user on LeftSide(opp.Strategic_Opportunity_Solution_Architect__c,15) = user.Id
        LEFT JOIN (SELECT Opp_id__c, Final_arr_growth__c, Product_family__c
        FROM  SFDC( SOQL='SELECT Opp_id__c,  Final_arr_growth__c,Product_family__c FROM Arr_breakdown__x WHERE Product_family__c=''Security''',
        UserName=:v_sfdc_user,Password=:v_sfdc_passwd,Environment=:v_sfdc_env,ReadAll=false,Retries=2,RetryInterval=1)) arrb ON opp.Id=arrb.Opp_id__c 
        ) opp
    WHERE opp.order_code NOT IN (SELECT order_code FROM delta.pstg_order_item_final)
    AND opp.order_code NOT in (select order_code, Incentive_Date from xactly.xc_comp_order_item WHERE Incentive_Date < :v_var_sales_data_pp_start_date and item_code like '%Churn%' GROUP BY Order_Code, Incentive_Date)
)

