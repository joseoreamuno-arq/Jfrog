p_load_sfdc_opportunity_data

Alter step s_load_sfdc_opportunity_data AS (
INSERT INTO Delta(TableName='delta.pstg_order_item_final',Overwrite=true,Unlogged=true)
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
  :v_param_processing_period AS period_name,
  Opportunity.PrimaryProduct__r.Name AS Product_name,
  Opportunity.End_User_Country__c AS Geography_name,
  Account.Name AS Customer_Name,
  '1' AS Quantity,
  --'QTY' AS Quantity_UnitType,
  Nvl(Opportunity.Amount,0) AS Amount,
  --CASE when (Opportunity.Amount IS NOT NULL) THEN 'USD'
  -- ELSE NULL
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
  Opportunity.Monthly_Validation__c AS Monthly_Validation,
  Opportunity.Churn_Date__c AS Churn_Date,
  Opportunity.ARR_Difference__c AS Final_ARR_Growth,
  CASE when (Opportunity.ARR_Difference__c IS NOT NULL) THEN 'USD'
  ELSE NULL
  END AS Final_ARR_Growth_UnitType,
  --'USD' AS Final_ARR_Growth_UnitType,
  Opportunity.StageName AS StageName,
  Opportunity.Related_Contracts_ARR_Formula__c AS Related_Contract_ARR,
  CASE when (Opportunity.Related_Contracts_ARR_Formula__c IS NOT NULL) THEN 'USD'
  ELSE NULL
  END AS Related_Contract_ARR_UnitType,
  --'USD' AS Related_Contract_ARR_UnitType,
  Opportunity.Current_ARR__c AS Final_Contract_ARR,
  CASE when (Opportunity.Current_ARR__c IS NOT NULL) THEN 'USD'
  ELSE NULL
  END AS Final_Contract_ARR_UnitType,
  --'USD' AS Final_Contract_ARR_UnitType,
  Reseller_Account__r.Name AS Reseller_Account,
  --'USD' AS Reseller_Account_UnitType,
  Opportunity.Approval_Done__c AS Approval_Done,
  Opportunity.Renewal_Credit_Amount_ARR__c AS Renewal_ARR,
  CASE when (Opportunity.Renewal_Credit_Amount_ARR__c IS NOT NULL) THEN 'USD'
  ELSE NULL
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
  ELSE NULL
  END AS Previous_ARR_UnitType,
  --'USD' AS Previous_ARR_UnitType,
  --Opportunity.Consulting_Amount_Summary__c AS Consulting,
  NULL AS Consulting,
  --CASE when (Opportunity.Consulting_Amount_Summary__c IS NOT NULL) THEN 'USD'
  --ELSE NULL
  --END AS Consulting_UnitType,
  NULL AS Consulting_UnitType,
  --'USD' AS Consulting_UnitType,
  Opportunity.Product_Platform__c AS Product_Type,
  Approval_Process__r.Approval_Sales_Manager__c AS Approval_Manager,
  Opportunity.Number_of_months_for_ARR__c AS ARR_Number_of_months,
  CASE when (Opportunity.Number_of_months_for_ARR__c IS NOT NULL) THEN 'USD'
  ELSE NULL
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
  NULL AS split_amount_pct,
  Opportunity_Contract_Unused_ARR_Amount__c AS Co_Termed_Unused_ARR,
  CASE when (Opportunity_Contract_Unused_ARR_Amount__c IS NOT NULL) THEN 'USD'
  ELSE NULL
  END AS Co_Termed_Unused_ARR_UnitType,
  Opportunity.Solution_Engineer__c AS Opp_Solution_Engineer,
  Opportunity.Cloud_Migration__c AS Opp_Cloud_Migration,
  Opportunity.Final_Number_of_Month__c AS Opp_Final_Number_of_Month,
  Opportunity.Opp_Platform__c AS Opp_Opp_Platform,
  CASE when (Opportunity.Strategic_Opportunity_Solution_Architect__c IS NOT NULL)
  THEN user.Name ELSE NULL
  END AS Opp_Strategic_Opp_Solution_Architect_name,
  Opportunity.Strategic_Opportunity_Solution_Architect__c AS Opp_Strategic_Opp_Solution_Architect,
  account.Business_Unit__r.Territory__c AS Business_Unit_Territory, account.Business_Unit__r.Pod__c AS Business_Unit_Pod, account.Business_Unit__r.Tier_Level__c AS Business_Unit_Tier_Level, account.Business_Unit__r.Tier_Manager__r.Name AS Business_Unit_Tier_Manager_Name, account.Business_Unit__r.Tier_Manager__c as
  Business_Unit_Tier_Manager_ID, account.Business_Unit__r.Regional_VP__r.Name AS Business_Unit_Regional_VP_Name, account.Business_Unit__r.Pod_Manager__r.Name Business_Unit_Pod_Manager_Name, CSM__c Opp_CSM,Opportunity.Type Opp_Type, Opportunity.Owner.Name Opp_Owner_Name,Opportunity.Comp_Credit__c Opp_Comp_Credit, Opportunity.PS_Net_Amount__c AS PS_Net_Amount, Opportunity.JAS_Net_Amount__c AS JAS_Net_Amount, Opportunity.Co_Sell_Program_Opportunity__c AS Co_Sell_Program_Opportunity, Opportunity.Marketplace_Offer_ID__c AS Marketplace_Offer_ID,
  Opportunity.Partner_Lead_Source__c AS Partner_Lead_Source,
  Opportunity.PRM_Opportunity_Origination__c AS PRM_Opportunity_Origination,
  NULL AS Cloud_Alliance_Partner,
  Opportunity.Qualified_Prospect__c AS Qualified_Prospect,
  Nvl(arrb.Final_arr_growth__c,0) AS Security_Final_ARR_Growth,
  'USD' AS Security_Final_ARR_Growth_UnitTypeName,
  Opportunity.Security_Net_Amount__c AS Security_Net_Amount,
  IF Opportunity.Security_Net_Amount__c IS NOT NULL THEN 'USD'ELSE NULL END AS Security_Net_Amount_UnitTypeName,
  Opportunity.Cloud_Alliance_Co_Sell_Opportunity__c AS Cloud_Alliance_Co_Sell_Opportunity__c,
  Opportunity.Cloud_Alliance_Opportunity_ID__c AS Cloud_Alliance_Opportunity_ID__c
  , NULL AS Meeting_Status
  , NULL AS Final_Qualified_Product
  , Opportunity.Purchese_Type__c AS Purchase_Type
  , IF Contains(Uppercase(Opportunity.PrimaryProduct__r.Name),'MONTHLY')=true THEN true ELSE false END AS Is_Monthly_Subscription_Product
  , NULL AS CoTerming_Type
  , NULL AS SO_Number
  , IF Approval_Process__r.Description__c = 'Renewal' AND relorders.order_code IS NOT NULL THEN TRUE ELSE FALSE END AS Recovery_Flag
  , Opportunity.Channel_Partner_Account_Owner__c AS Channel_Partner_Account_Owner
  , Channel_Partner_Name__r.Owner.Email AS Channel_Partner_Account_Owner_Email
  , Opportunity.Cloud_Alliance_Partner_multi__c AS Cloud_Alliance_Partner_Multi
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
  Opportunity.Cloud_Alliance_Co_Sell_Opportunity__c,
  Opportunity.Cloud_Alliance_Opportunity_ID__c,

  Opportunity.Purchese_Type__c,
  Opportunity.Channel_Partner_Account_Owner__c,
  Opportunity.Channel_Partner_Name__r.Owner.Email,
  Opportunity.Cloud_Alliance_Partner_multi__c,

  (SELECT Id,Approval_Sales_Manager__c,OwnerId,Owner.userRole.name,CreatedDate,Description__c FROM Approval_Process__r)
  from Opportunity where Opportunity.StageName in(''06-Closed Won'',''06-Closed Lost'') and CloseDate >= ' || :v_var_sales_data_pp_start_date || ' and CloseDate <= ' || :v_var_sales_data_pp_end_date,
  UserName=:v_sfdc_user,
  Password=:v_sfdc_passwd,
  Environment=:v_sfdc_env,
  ReadAll=false,
  Retries=2,
  RetryInterval=1
  ) opp
  LEFT JOIN delta.generic_user_load user on LeftSide(opp.Strategic_Opportunity_Solution_Architect__c,15) = user.Id
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
  LEFT JOIN (SELECT Opp_id__c, Product_family__c, SUM(Final_arr_growth__c) AS Final_arr_growth__c
  FROM SFDC( SOQL='SELECT Opp_id__c, Final_arr_growth__c,Product_family__c FROM Arr_breakdown__x WHERE Product_family__c=''Security''',
  UserName=:v_sfdc_user,Password=:v_sfdc_passwd,Environment=:v_sfdc_env,ReadAll=false,Retries=2,RetryInterval=1)) arrb ON opp.Id=arrb.Opp_id__c
  WHERE (Approval_Process__r.Description__c NOT INN ('SDR Approval Process', '"SDR Approval Process"'))
  AND (Approval_Process__r.Description__c NOT INN ('Passed', '"Passed"') )
  AND (Approval_Process__r.Description__c not INN ('Expiring_ARR', '"Expiring_ARR"') or Order_Code not in (select distinct order_code from xactly.xc_comp_order_item));
)

Alter step s_load_opp_clean_pstg_order_item_dump AS (
INSERT into Delta(TableName='delta.opp_clean_pstg_order_item', Overwrite=true, Unlogged=true)
  SELECT DISTINCT Order_Code
  , item_code
  , Batch_Name
  , Batch_Type
  , period_name
  , Product_name
  , Geography_name
  , Customer_Name
  , Quantity
  , Amount
  , amount_UnitType
  , incentive_date
  , IF System_Approval_Description = 'New Business' THEN Nvl(b.Order_Date, a.Order_Date) ELSE a.Order_Date END AS Order_Date
  , order_type
  , Discount
  , Discount_UnitType
  , Description
  , Related_Order_Code
  , Related_item_Code
  , Employee_id
  , split_pct
  , CloseDate
  , Monthly_Validation
  , Churn_Date
  , Final_ARR_Growth
  , Final_ARR_Growth_UnitType
  , StageName
  , Related_Contract_ARR
  , Related_Contract_ARR_UnitType
  , Final_Contract_ARR
  , Final_Contract_ARR_UnitType
  , Reseller_Account
  , Approval_Done
  , Renewal_ARR
  , Renewal_ARR_UnitType
  , IF System_Approval_Description = 'New Business' THEN Nvl(b.Deal_Date, a.Deal_Date) ELSE a.Deal_Date END AS Deal_Date
  , Renewal_Type
  , Record_Type_Name
  , Out_of_Recovery_Period
  , Lead_Source
  , Opportunity_Description
  , Previous_ARR
  , Previous_ARR_UnitType
  , Consulting
  , Consulting_UnitType
  , Product_Type
  , Approval_Manager
  , ARR_Number_of_months
  , ARR_Number_of_months_UnitType
  , Order_Process_Date
  , End_User_Country
  , Shipped_to_country
  , IF System_Approval_Description = 'New Business' THEN Nvl(b.Approval_Process_Created_Date, a.Approval_Process_Created_Date) ELSE a.Approval_Process_Created_Date END AS Approval_Process_Created_Date
  , Approval_Process_Role
  , System_Approval_Description
  , split_amount_pct
  , Co_Termed_Unused_ARR
  , Co_Termed_Unused_ARR_UnitType
  , Opp_Solution_Engineer
  , Opp_Cloud_Migration
  , Opp_Final_Number_of_Month
  , Opp_Opp_Platform
  , Opp_Strategic_Opp_Solution_Architect_name
  , Opp_Strategic_Opp_Solution_Architect
  , Business_Unit_Territory
  , Business_Unit_Pod
  , Business_Unit_Tier_Level
  , Business_Unit_Tier_Manager_Name
  , Business_Unit_Tier_Manager_ID
  , Business_Unit_Regional_VP_Name
  , Business_Unit_Pod_Manager_Name
  , Opp_CSM
  , Opp_Type
  , Opp_Owner_Name
  , Opp_Comp_Credit
  , PS_Net_Amount
  , JAS_Net_Amount
  , Co_Sell_Program_Opportunity
  , Marketplace_Offer_ID
  , Partner_Lead_Source
  , PRM_Opportunity_Origination
  , Cloud_Alliance_Partner
  , Qualified_Prospect
  , Security_Final_ARR_Growth
  , Security_Final_ARR_Growth_UnitTypeName
  , Security_Net_Amount
  , Security_Net_Amount_UnitTypeName
  , Cloud_Alliance_Co_Sell_Opportunity__c
  , Cloud_Alliance_Opportunity_ID__c
  , Meeting_Status
  , Final_Qualified_Product
  , Purchase_Type
  , Is_Monthly_Subscription_Product
  , CoTerming_Type
  , SO_Number
  , Recovery_Flag
  , Channel_Partner_Account_Owner
  , Channel_Partner_Account_Owner_Email
  , Cloud_Alliance_Partner_Multi
  FROM delta.pstg_order_item_final a
  LEFT JOIN (SELECT Order_Code, Item_Code, System_Approval_Description, Max(Order_Date) AS Order_Date, Max(Deal_Date) AS Deal_Date, Max(Approval_Process_Created_Date) AS Approval_Process_Created_Date FROM delta.pstg_order_item_final) b
  ON a.order_code = b.order_code AND a.item_code = b.item_code AND System_Approval_Description = 'New Business'
)

Alter step s_delete_opp_expiring_arr_pstg_order_item AS (
delete from delta.opp_clean_pstg_order_item where order_code in (
select order_code from delta.opp_clean_pstg_order_item having count(*)>1
) and Opportunity_Description = 'Expiring ARR';

INSERT INTO Delta(TableName='delta.pstg_order_item_final',Overwrite=true,Unlogged=true)
SELECT DISTINCT * FROM  delta.opp_clean_pstg_order_item;
)