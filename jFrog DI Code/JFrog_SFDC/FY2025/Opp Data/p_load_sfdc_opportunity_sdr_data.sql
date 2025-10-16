p_load_sfdc_opportunity_sdr_data

Alter pipeline p_load_sfdc_opportunity_sdr_data
add step s_load_sfdc_opportunity_sdr_data_final
After s_load_sfdc_opportunity_sdr_data

Alter step s_load_sfdc_opportunity_sdr_data AS (
INSERT INTO Delta(TableName='delta.pstg_order_item_sdr_prestage', Overwrite=true,unlogged=true)
    SELECT opp.*
    , Nvl(sc.Security_Seat_Count_Agg,0) AS Security_Seats_Current_Year
    , Nvl(sc1.Security_Seat_Count_Agg,0) AS Security_Seats_Current_Year_Minus_1
    , Nvl(sc2.Security_Seat_Count_Agg,0) AS Security_Seats_Current_Year_Minus_2
    , Nvl(sc3.Security_Seat_Count_Agg,0) AS Security_Seats_Current_Year_Minus_3
    , 'QUANTITY' AS Security_Seats_Current_Year_UnitTypeName
    , 'QUANTITY' AS Security_Seats_Current_Year_Minus_1_UnitTypeName
    , 'QUANTITY' AS Security_Seats_Current_Year_Minus_2_UnitTypeName
    , 'QUANTITY' AS Security_Seats_Current_Year_Minus_3_UnitTypeName
    FROM (SELECT DISTINCT
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
    Nvl(Opportunity.ARR_Difference__c,0) AS Final_ARR_Growth,
    'USD' AS Final_ARR_Growth_UnitType,
    Opportunity.StageName AS StageName,
    Nvl(Opportunity.Related_Contracts_ARR_Formula__c,0) AS Related_Contract_ARR,
    'USD' AS Related_Contract_ARR_UnitType,
    Nvl(Opportunity.Current_ARR__c,0) AS Final_Contract_ARR,
    'USD' AS Final_Contract_ARR_UnitType,
    Reseller_Account__r.Name AS Reseller_Account,
    Opportunity.Approval_Done__c AS Approval_Done,
    Nvl(Opportunity.Renewal_Credit_Amount_ARR__c,0) AS Renewal_ARR,
    'USD' AS Renewal_ARR_UnitType,
    ToDate(Approval_Process__r.CreatedDate) AS Deal_Date,
    Opportunity.Renewal_Type__c AS Renewal_Type,
    Opportunity.Record_Type_Name__c AS Record_Type_Name,
    Opportunity.Out_of_Recovery_Period__c AS Out_of_Recovery_Period,
    Opportunity.LeadSource AS Lead_Source,
    Approval_Process__r.Description__c AS Opportunity_Description,
    Nvl(Opportunity.Previous_ARR__c,0) AS Previous_ARR,
    'USD' AS Previous_ARR_UnitType,
    --Opportunity.Consulting_Amount_Summary__c AS Consulting,
    NULL AS Consulting,
    NULL AS Consulting_UnitType,
    Opportunity.Product_Platform__c AS Product_Type,
    Approval_Process__r.Approval_Sales_Manager__c AS Approval_Manager,
    Nvl(Opportunity.Number_of_months_for_ARR__c,0) AS ARR_Number_of_months,
    'USD' AS ARR_Number_of_months_UnitType,
    NULL AS Order_Process_Date,
    Opportunity.End_User_Country__c AS End_User_Country,
    Opportunity.Shipped_to_country__c AS Shipped_to_country,
    ToDate(Approval_Process__r.CreatedDate) As Approval_Process_Created_Date,
    NULL AS Approval_Process_Role,
    Approval_Process__r.Description__c AS System_Approval_Description,
    NULL as split_amount_pct,
    Nvl(Opportunity_Contract_Unused_ARR_Amount__c,0) AS Co_Termed_Unused_ARR,
    'USD' AS Co_Termed_Unused_ARR_UnitType,
    Opportunity.Solution_Engineer__c as Opp_Solution_Engineer,
    Opportunity.Cloud_Migration__c as Opp_Cloud_Migration,
    Opportunity.Final_Number_of_Month__c as Opp_Final_Number_of_Month,
    Opportunity.Opp_Platform__c as Opp_Opp_Platform,
    CASE when (Opportunity.Solution_Engineer__c IS NOT NULL)
    THEN user.Name else NULL
    END AS Opp_Strategic_Opp_Solution_Architect_name,
    Opportunity.Solution_Engineer__c as Opp_Strategic_Opp_Solution_Architect
    , account.Business_Unit__r.Territory__c as Business_Unit_Territory
    , account.Business_Unit__r.Pod__c as Business_Unit_Pod
    , account.Business_Unit__r.Tier_Level__c as Business_Unit_Tier_Level
    , account.Business_Unit__r.Tier_Manager__r.Name as Business_Unit_Tier_Manager_Name
    , account.Business_Unit__r.Tier_Manager__c as Business_Unit_Tier_Manager_ID
    , account.Business_Unit__r.Regional_VP__r.Name as Business_Unit_Regional_VP_Name
    , account.Business_Unit__r.Pod_Manager__r.Name AS Business_Unit_Pod_Manager_Name
    , CSM__c AS Opp_CSM
    , Opportunity.Type AS Opp_Type
    , Opportunity.Owner.Name AS Opp_Owner_Name
    , Opportunity.Comp_Credit__c AS Opp_Comp_Credit
    , Opportunity.PS_Net_Amount__c AS PS_Net_Amount
    , Opportunity.JAS_Net_Amount__c as JAS_Net_Amount
    , Opportunity.Co_Sell_Program_Opportunity__c as Co_Sell_Program_Opportunity
    , Opportunity.Marketplace_Offer_ID__c as Marketplace_Offer_ID
    , Opportunity.Partner_Lead_Source__c as Partner_Lead_Source
    , Opportunity.PRM_Opportunity_Origination__c as PRM_Opportunity_Origination
    , NULL AS Cloud_Alliance_Partner
    , Nvl(Opportunity.Qualified_Prospect__c,false) as Qualified_Prospect
    , Nvl(arrb.Final_arr_growth__c,0) AS Security_Final_ARR_Growth
    , 'USD' AS Security_Final_ARR_Growth_UnitTypeName
    , Nvl(Opportunity.Security_Net_Amount__c,0) AS Security_Net_Amount
    , 'USD' AS Security_Net_Amount_UnitTypeName
    , Opportunity.Cloud_Alliance_Co_Sell_Opportunity__c AS Cloud_Alliance_Co_Sell_Opportunity__c
    , Opportunity.Cloud_Alliance_Opportunity_ID__c AS Cloud_Alliance_Opportunity_ID__c
    , Opportunity.Meeting_Status__c AS Meeting_Status
    , Opportunity.Final_Qualified_Product__c AS Final_Qualified_Product
    , Opportunity.Purchese_Type__c AS Purchase_Type
    , IF Contains(Uppercase(Opportunity.PrimaryProduct__r.Name),'MONTHLY')=true THEN true ELSE false END AS Is_Monthly_Subscription_Product
    , NULL as CoTerming_Type
    , NULL as SO_Number
    , NULL AS Recovery_Flag
    , Opportunity.Channel_Partner_Account_Owner__c AS Channel_Partner_Account_Owner
    , Channel_Partner_Name__r.Owner.Email AS Channel_Partner_Account_Owner_Email
    , Opportunity.Cloud_Alliance_Partner_multi__c AS Cloud_Alliance_Partner_Multi
    , Nvl(arrb.Total_yoy_growth_per_sub_family__c,0) AS Total_YOY_Growth
    , 'USD' AS Total_YOY_Growth_UnitTypeName
    , Nvl(arrb.Period_index__c,0) AS Period_Index
    , 'QUANTITY' AS Period_Index_UnitTypeName
    , Nvl(arrb.Related_ns_arr__c,0) AS Security_Related_Contract_Value
    , 'USD'AS Security_Related_Contract_Value_UnitTypeName
    , Nvl(arrb.Final_arr_growth__c,0)*0.75 AS Final_ARR_Growth_Quota_Credit
    , 'USD' AS Final_ARR_Growth_Quota_Credit_UnitTypeName
    , Account.Id AS Account_Id
    , Opportunity.Company_logo_status_closure__c AS Company_Logo_Status_Closure

    from SFDC(SOQL='select Id
    , Opportunity.PrimaryProduct__r.Name
    , Opportunity_Contract_Unused_ARR_Amount__c
    , Opportunity.End_User_Country__c,
    Account.Name,
    Account.Id,
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
    Opportunity.Shipped_to_country__c
    , CreatedDate
    , Opportunity.Solution_Engineer__c
    , Opportunity.Cloud_Migration__c,Opportunity.Final_Number_of_Month__c
    , Opportunity.Opp_Platform__c
    , account.Business_Unit__r.Territory__c
    , account.Business_Unit__r.Pod__c
    , account.Business_Unit__r.Tier_Level__c
    , account.Business_Unit__r.Tier_Manager__r.Name
    , account.Business_Unit__r.Tier_Manager__c
    , account.Business_Unit__r.Regional_VP__r.Name
    , account.Business_Unit__r.Pod_Manager__r.Name
    , CSM__c
    , Opportunity.Type,Opportunity.Owner.Name,Opportunity.Comp_Credit__c
    , Opportunity.PS_Net_Amount__c, Opportunity.JAS_Net_Amount__c
    , Opportunity.Co_Sell_Program_Opportunity__c
    , Opportunity.Marketplace_Offer_ID__c,
    Opportunity.Partner_Lead_Source__c,
    Opportunity.PRM_Opportunity_Origination__c,
    Opportunity.Cloud_Alliance_Partner__c,
    Opportunity.Qualified_Prospect__c,

    Opportunity.Security_Net_Amount__c,
    Opportunity.Cloud_Alliance_Co_Sell_Opportunity__c,
    Opportunity.Cloud_Alliance_Opportunity_ID__c,
    Opportunity.Meeting_Status__c,
    Opportunity.Final_Qualified_Product__c
    , Opportunity.Purchese_Type__c

    , Opportunity.Channel_Partner_Account_Owner__c
    , Opportunity.Channel_Partner_Name__r.Owner.Email
    , Opportunity.Cloud_Alliance_Partner_multi__c
    , Opportunity.Company_logo_status_closure__c

    ,(SELECT Id,Approval_Sales_Manager__c,OwnerId,Owner_EmployeeID__c,Owner.userRole.name,CreatedDate,Description__c, Ownership_Acceptance_Date_SDR__c 
        FROM Approval_Process__r)
    FROM Opportunity',
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1
    ) opp
    LEFT JOIN delta.generic_user_load user on opp.Solution_Engineer__c = user.Id
    LEFT JOIN
    (
    SELECT order_code, item_code, incentive_date FROM xactly.xc_comp_order_item coi
    JOIN (SELECT Max(Incentive_Date) AS LatestDate, Order_Code FROM xactly.xc_comp_order_item WHERE Incentive_Date < :v_var_sales_data_pp_start_date GROUP BY Order_Code) LatestOrders
    ON coi.order_code = LatestOrders.order_code AND coi.incentive_date = LatestOrders.LatestDate
    ) relorders
    on(relorders.order_code = opp.Id)
    LEFT JOIN (SELECT Opp_id__c
                    , Product_family__c
                    , Max(Period_index__c) AS Period_index__c
                    , SUM(Related_ns_arr__c) AS Related_ns_arr__c
                    , SUM(Total_yoy_growth_per_sub_family__c) AS Total_yoy_growth_per_sub_family__c
                    , SUM(Final_arr_growth__c) AS Final_arr_growth__c 
                    FROM SFDC( SOQL='SELECT Opp_id__c, Final_arr_growth__c,Product_family__c, Total_yoy_growth_per_sub_family__c, Period_index__c, Related_ns_arr__c  FROM Arr_breakdown__x WHERE Product_family__c=''Security''',
                    UserName=:v_sfdc_user,Password=:v_sfdc_passwd,Environment=:v_sfdc_env,ReadAll=false,Retries=2,RetryInterval=1)) arrb ON opp.Id=arrb.Opp_id__c
    where Approval_Process__r.Ownership_Acceptance_Date_SDR__c >= :v_var_sales_data_pp_start_date
    and Approval_Process__r.Ownership_Acceptance_Date_SDR__c <= :v_var_sales_data_pp_end_date
    and Approval_Process__r.Ownership_Acceptance_Date_SDR__c is not NULL
    AND Approval_Process__r.Description__c IN ('SDR Approval Process', '"SDR Approval Process"')) opp
    LEFT JOIN delta.sfdc_account_security_seat_count_agg sc ON opp.Account_Id = sc.Account_Id AND Year(opp.Incentive_Date)=sc.Close_Year
    LEFT JOIN delta.sfdc_account_security_seat_count_agg sc1 ON opp.Account_Id = sc1.Account_Id AND Year(SubtractTimeInterval(opp.Incentive_Date,1,'Years')) =sc1.Close_Year
    LEFT JOIN delta.sfdc_account_security_seat_count_agg sc2 ON opp.Account_Id = sc2.Account_Id AND Year(SubtractTimeInterval(opp.Incentive_Date,2,'Years'))=sc2.Close_Year
    LEFT JOIN delta.sfdc_account_security_seat_count_agg sc3 ON opp.Account_Id = sc3.Account_Id AND Year(SubtractTimeInterval(opp.Incentive_Date,3,'Years'))=sc3.Close_Year
    ;
)

Alter step s_load_sfdc_opportunity_sdr_data_final AS (
INSERT into Delta(TableName='delta.pstg_order_item_final', Overwrite=false, unlogged=false)
    SELECT
    Order_Code,
    item_code,
    Batch_Name,
    Batch_Type,
    period_name,
    Product_name,
    Geography_name,
    Customer_Name,
    Quantity,
    Amount,
    amount_UnitType,
    incentive_date,
    Order_Date,
    order_type,
    Discount,
    Discount_UnitType,
    Description,
    NULL AS Related_Order_Code,
    NULL AS Related_item_Code,
    Employee_id,
    split_pct,
    CloseDate,
    Monthly_Validation,
    Churn_Date,
    Final_ARR_Growth,
    Final_ARR_Growth_UnitType,
    StageName,
    Related_Contract_ARR,
    Related_Contract_ARR_UnitType,
    Final_Contract_ARR,
    Final_Contract_ARR_UnitType,
    Reseller_Account,
    --Reseller_Account_UnitType,
    Approval_Done,
    Renewal_ARR,
    Renewal_ARR_UnitType,
    Deal_Date,
    Renewal_Type,
    Record_Type_Name,
    Out_of_Recovery_Period,
    Lead_Source,
    Opportunity_Description,
    Previous_ARR,
    Previous_ARR_UnitType,
    Consulting,
    Consulting_UnitType,
    Product_Type,
    Approval_Manager,
    ARR_Number_of_months,
    ARR_Number_of_months_UnitType,
    --Downsell,
    --Downsell_UnitType,
    --Churn,
    --Churn_UnitType,
    --Opening,
    --Opening_UnitType,
    Order_Process_Date,
    End_User_Country,
    Shipped_to_country,
    Approval_Process_Created_Date,
    Approval_Process_Role,
    System_Approval_Description,
    NULL as split_amount_pct,
    Co_Termed_Unused_ARR,
    Co_Termed_Unused_ARR_UnitType,
    Opp_Solution_Engineer,
    Opp_Cloud_Migration,
    Opp_Final_Number_of_Month,
    Opp_Opp_Platform,
    Opp_Strategic_Opp_Solution_Architect_name,
    Opp_Strategic_Opp_Solution_Architect,
    Business_Unit_Territory,
    Business_Unit_Pod,
    Business_Unit_Tier_Level,
    Business_Unit_Tier_Manager_Name,
    Business_Unit_Tier_Manager_ID,
    Business_Unit_Regional_VP_Name,
    Business_Unit_Pod_Manager_Name,
    Opp_CSM,
    Opp_Type,
    Opp_Owner_Name,
    Opp_Comp_Credit,
    PS_Net_Amount,
    JAS_Net_Amount,
    Co_Sell_Program_Opportunity,
    Marketplace_Offer_ID,
    Partner_Lead_Source,
    PRM_Opportunity_Origination,
    Cloud_Alliance_Partner,
    Qualified_Prospect,
    Security_Final_ARR_Growth,
    Security_Final_ARR_Growth_UnitTypeName,
    Security_Net_Amount,
    Security_Net_Amount_UnitTypeName,
    Cloud_Alliance_Co_Sell_Opportunity__c,
    Cloud_Alliance_Opportunity_ID__c
    , Meeting_Status
    , Final_Qualified_Product
    , Purchase_Type
    , Is_Monthly_Subscription_Product
    , NULL AS CoTerming_Type
    , NULL AS SO_Number
    , NULL AS Recovery_Flag
    , Channel_Partner_Account_Owner
    , Channel_Partner_Account_Owner_Email
    , Cloud_Alliance_Partner_Multi
    , Total_YOY_Growth
    , Total_YOY_Growth_UnitTypeName
    , Period_Index
    , Period_Index_UnitTypeName
    , Security_Related_Contract_Value
    , Security_Related_Contract_Value_UnitTypeName
    , Final_ARR_Growth_Quota_Credit
    , Final_ARR_Growth_Quota_Credit_UnitTypeName
    , Security_Seats_Current_Year
    , Security_Seats_Current_Year_Minus_1
    , Security_Seats_Current_Year_Minus_2
    , Security_Seats_Current_Year_Minus_3
    , Security_Seats_Current_Year_UnitTypeName
    , Security_Seats_Current_Year_Minus_1_UnitTypeName
    , Security_Seats_Current_Year_Minus_2_UnitTypeName
    , Security_Seats_Current_Year_Minus_3_UnitTypeName
    , Company_Logo_Status_Closure
    from delta.pstg_order_item_sdr_prestage a
)