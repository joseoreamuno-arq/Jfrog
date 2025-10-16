p_load_sfdc_opportunity_sdr_data

Alter step s_load_sfdc_opportunity_sdr_data AS (
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
  Opportunity.Cloud_Alliance_Partner__c as Cloud_Alliance_Partner
  , Nvl(Opportunity.Qualified_Prospect__c,false) as Qualified_Prospect
  , Nvl(arrb.Final_arr_growth__c,0) AS Security_Final_ARR_Growth
  , 'USD' AS Security_Final_ARR_Growth_UnitTypeName,
  Opportunity.Security_Net_Amount__c AS Security_Net_Amount,
  IF Opportunity.Security_Net_Amount__c IS NOT NULL THEN 'USD'ELSE NULL END AS Security_Net_Amount_UnitTypeName,
  Opportunity.Cloud_Alliance_Co_Sell_Opportunity__c AS Cloud_Alliance_Co_Sell_Opportunity__c
  , Opportunity.Cloud_Alliance_Opportunity_ID__c AS Cloud_Alliance_Opportunity_ID__c
  , Opportunity.Meeting_Status__c AS Meeting_Status
  , Opportunity.Final_Qualified_Product__c AS Final_Qualified_Product
  , Opportunity.Purchese_Type__c AS Purchase_Type
  , IF Contains(Uppercase(Opportunity.PrimaryProduct__r.Name),'MONTHLY')=true THEN true ELSE false END AS Is_Monthly_Subscription_Product
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
  Opportunity.Cloud_Alliance_Co_Sell_Opportunity__c,
  Opportunity.Cloud_Alliance_Opportunity_ID__c,
  Opportunity.Meeting_Status__c,
  Opportunity.Final_Qualified_Product__c,
  Opportunity.Purchese_Type__c,
  
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
  SELECT order_code, item_code, incentive_date FROM xactly.xc_comp_order_item coi
  JOIN (SELECT Max(Incentive_Date) AS LatestDate,  Order_Code FROM xactly.xc_comp_order_item WHERE Incentive_Date < :v_var_sales_data_pp_start_date GROUP BY Order_Code) LatestOrders 
  ON coi.order_code = LatestOrders.order_code AND coi.incentive_date = LatestOrders.LatestDate
  ) relorders
  on(relorders.order_code = opp.Id)
  LEFT JOIN (SELECT Opp_id__c, Product_family__c, SUM(Final_arr_growth__c) AS Final_arr_growth__c
  FROM SFDC( SOQL='SELECT Opp_id__c, Final_arr_growth__c,Product_family__c FROM Arr_breakdown__x WHERE Product_family__c=''Security''',
  UserName=:v_sfdc_user,Password=:v_sfdc_passwd,Environment=:v_sfdc_env,ReadAll=false,Retries=2,RetryInterval=1)) arrb ON opp.Id=arrb.Opp_id__c
  where Approval_Process__r.Ownership_Acceptance_Date_SDR__c >= :v_var_sales_data_pp_start_date
  and Approval_Process__r.Ownership_Acceptance_Date_SDR__c <= :v_var_sales_data_pp_end_date
  and Approval_Process__r.Ownership_Acceptance_Date_SDR__c is not null
  AND Approval_Process__r.Description__c IN ('SDR Approval Process', '"SDR Approval Process"');
)