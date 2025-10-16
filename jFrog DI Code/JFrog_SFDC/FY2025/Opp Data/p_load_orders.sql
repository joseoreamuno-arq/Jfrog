p_load_orders
s_set_running_pipeline_inbound_load_orders
SET v_running_pipeline_inbound *= v_running_pipeline
s_set_running_pipeline_load_orders
SET v_running_pipeline *= v_running_pipeline_inbound||'-> p_load_orders'
s_clear_staging_order_item
delete from staging.order_item
s_clear_staging_order_item_assignment
delete from staging.order_item_assignment
s_clear_order_item_validation_error
delete from staging.order_item_validation_error
s_clear_stg_order_item_validation_error
delete from delta.stg_order_item_validation_error

sfdc_user_dmp
Insert Into Delta (Tablename='delta.sfdc_user_dmp', Overwrite=true,unlogged=true)
    SELECT Id
    ,Username
    ,Name
    ,Email
    ,AccountId FROM SFDC(SOQL= 'Select
    Id
    ,Username
    ,Name
    ,Email
    ,AccountId
    FROM User' ,
    UserName=:v_sfdc_user, Password=:v_sfdc_passwd, Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1
    ) usr

s_load_prestage_order_item
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
    , CASE WHEN Lowercase(Approval_manager) = 'pending' THEN 'YES' ELSE Approval_manager END AS Approval_manager
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
    , ToBoolean(Qualified_Prospect) AS Qualified_Prospect
    , Security_Final_ARR_Growth
    , Security_Final_ARR_Growth_UnitTypeName
    , Cloud_Alliance_Co_Sell_Opportunity__c AS Cloud_Alliance_Co_Sell_Opportunity
    , Cloud_Alliance_Opportunity_ID__c AS Cloud_Alliance_Opportunity_ID
    , Meeting_Status
    , Final_Qualified_Product
    , Purchase_Type
    , ToBoolean(Is_Monthly_Subscription_Product) AS Is_Monthly_Subscription_Product
    , CoTerming_Type
    , SO_Number
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
    , CASE WHEN pstg.Batch_Type= 'Opportunity' AND pstg.System_Approval_Description IS NULL AND ToDecimal(pstg.Final_ARR_Growth) = 0.00 AND pstg.Stagename INN ('06-Closed Won', '06-Closed Lost') THEN true
    WHEN pstg.Batch_Type= 'Opportunity' AND pstg.System_Approval_Description = 'Expiring ARR' AND pstg.Churn_Date < :v_var_sales_data_pp_start_date AND pstg.Stagename ='06-Closed Lost' THEN true
    ELSE false END AS Removal_Flag

    FROM delta.pstg_order_item_final pstg
    LEFT JOIN delta.sfdc_opp_team_member_dump t1 ON pstg.Order_Code = t1.OPPORTUNITYID AND t1.TEAMMEMBERROLE = 'Co-Sell Cloud Alliance Lead' AND t1.role_cnt = '1'
    LEFT JOIN delta.sfdc_opp_team_member_dump t2 ON pstg.Order_Code = t2.OPPORTUNITYID AND t2.TEAMMEMBERROLE = 'Partner Manager'
    LEFT JOIN delta.sfdc_opp_team_member_dump t3 ON pstg.Order_Code = t3.OPPORTUNITYID AND t3.TEAMMEMBERROLE = 'Renewal Team'AND t3.role_cnt = '1'
    LEFT JOIN delta.sfdc_opp_team_member_dump t4 ON pstg.Order_Code = t4.OPPORTUNITYID AND t4.TEAMMEMBERROLE = 'MarketPlace Sales Lead'
    LEFT JOIN delta.pos_part_title_data_dump tl3 ON t1.Employee_ID = tl3.Employee_ID
    LEFT JOIN delta.pos_part_title_data_dump tl4 ON t2.Employee_ID = tl4.Employee_ID
    LEFT JOIN delta.pos_part_title_data_dump tl5 ON t3.Employee_ID = tl5.Employee_ID
    LEFT JOIN delta.pos_part_title_data_dump tl6 ON t4.Employee_ID = tl6.Employee_ID
    LEFT JOIN delta.sfdc_uer_dump b ON LeftSide(pstg.Business_Unit_Tier_Manager_ID,15) = LeftSide(b.id, 15)
    LEFT JOIN xactly.xc_participant part ON pstg.Employee_ID = part.Employee_ID AND Lowercase(part.Region) = Lowercase(pstg.BUSINESS_UNIT_TERRITORY)
    LEFT JOIN delta.pos_part_title_data_dump tl1 ON pstg.Employee_ID = tl1.Employee_ID
    LEFT JOIN delta.pos_part_title_data_dump tl2 ON b.emp_id = tl2.Employee_ID
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND Removal_Flag = false
    ;
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
    , Cloud_Alliance_Co_Sell_Opportunity
    , Cloud_Alliance_Opportunity_ID
    , Qualified_Prospect
    , Security_Final_ARR_Growth
    , Security_Final_ARR_Growth_UnitTypeName
    , Meeting_Status
    , Final_Qualified_Product
    , Purchase_Type
    , Is_Monthly_Subscription_Product
    , CoTerming_Type
    , SO_Number
    , Channel_Partner_Account_Owner
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
    , Cloud_Alliance_Co_Sell_Opportunity
    , Cloud_Alliance_Opportunity_ID
    , Qualified_Prospect
    , Security_Final_ARR_Growth
    , Security_Final_ARR_Growth_UnitTypeName
    , Meeting_Status
    , Final_Qualified_Product
    , Purchase_Type
    , ToBoolean(Is_Monthly_Subscription_Product) AS Is_Monthly_Subscription_Product
    , CoTerming_Type
    , SO_Number
    , Channel_Partner_Account_Owner
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
    FROM delta.prestage_order_item pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE err.created_timestamp IS null

s_load_staging_order_item_assignment
Insert Into staging.order_item_assignment (order_code, item_code, Employee_ID, split_amount_pct)
    SELECT distinct order_code , item_code , Employee_ID , split_amount_pct FROM (
    SELECT order_code AS order_code
    , item_code AS item_code
    , pstg.Employee_ID AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err
    ON err.order_code = pstg.order_code
    AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , b.emp_id AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_uer_dump b
    ON LeftSide(pstg.Business_Unit_Tier_Manager_ID,15) = LeftSide(b.id, 15)
    JOIN xactly.xc_participant part
    ON pstg.Employee_ID = part.Employee_ID
    AND Lowercase(part.Region) = Lowercase(pstg.BUSINESS_UNIT_TERRITORY)
    JOIN delta.pos_part_title_data_dump title ON title.Employee_ID = b.emp_id AND title.title_name IN ('Hybrid APAC CS Tier Mger', 'Hybrid CS Tier Mger')
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , b.emp_id AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_uer_dump b ON LeftSide(pstg.Opp_Solution_Engineer,15) = LeftSide(b.id, 15)
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , t3.Employee_ID AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_opp_team_member_dump t3 ON pstg.Order_Code = t3.OPPORTUNITYID AND t3.TEAMMEMBERROLE = 'Renewal Team'
    JOIN delta.pos_part_title_data_dump title1 ON t3.Employee_ID = title1.Employee_ID AND(title1.title_name = 'CSM' OR title1.title_name LIKE 'AMER CSM%')
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2525' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT pstg.order_code AS order_code
    , pstg.item_code AS item_code
    , CASE WHEN pstg.Cloud_Alliance_Partner_Multi IN ('Azure') THEN '1159'
    WHEN pstg.Cloud_Alliance_Partner_Multi = 'AWS' THEN '2444'
    WHEN pstg.Cloud_Alliance_Partner IN ('Azure') THEN '1159'
    WHEN pstg.Cloud_Alliance_Partner = 'AWS' THEN '2444'
    END AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'AWS') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS'))
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2045' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'GCP', 'AWS') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'GCP', 'AWS'))
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2378' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi = 'AWS' OR pstg.Cloud_Alliance_Partner = 'AWS')
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2760' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi = 'GCP' OR pstg.Cloud_Alliance_Partner = 'GCP')
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '1762' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity'
    --Churn
    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2525' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT pstg.order_code AS order_code
    , pstg.item_code AS item_code
    , CASE WHEN pstg.Cloud_Alliance_Partner_Multi INN ('Azure') THEN '1159'
    WHEN pstg.Cloud_Alliance_Partner_Multi = 'AWS' THEN '2444'
    WHEN pstg.Cloud_Alliance_Partner IN ('Azure') THEN '1159'
    WHEN pstg.Cloud_Alliance_Partner = 'AWS' THEN '2444'
    END AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2045' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'GCP', 'AWS') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'GCP', 'AWS'))
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2378' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi = 'AWS'OR pstg.Cloud_Alliance_Partner = 'AWS')
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2760' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi = 'GCP'OR pstg.Cloud_Alliance_Partner = 'GCP')
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '1762' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT DISTINCT order_code AS order_code
    , item_code AS item_code
    , SubString(pua.participant_Name, IndexOf(pua.participant_Name, '(') +1 , IndexOf(pua.participant_Name, ')')) AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_user_dmp usr ON pstg.Channel_Partner_Account_Owner = usr.Name
    JOIN xactly.xc_User xusr ON usr.Email = xusr.Email
    JOIN xc_part_user_assignment pua on xusr.User_Id = pua.User_Id
    LEFT JOIN delta.pos_part_title_data_dump title2 ON SubString(pua.participant_Name, IndexOf(pua.participant_Name, '(') +1 , IndexOf(pua.participant_Name, ')')) =title2.Employee_ID AND title2.title_name IN ('Channel Leader', 'Channel Mger', 'Channel Rep_GOV' , 'Channel Rep', 'PDR', 'Channel Mger_APAC', 'Channel Rep_APAC')
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION

    SELECT order_code AS order_code
    , item_code AS item_code
    , b.emp_id AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_uer_dump b ON LeftSide(pstg.Opp_Strategic_Opp_Solution_Architect,15) = LeftSide(b.id, 15)
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    )

s_incent_create_batches
incent synchronous create batches
s_sleep_ten
sleep 10

s_incent_validate_orders
incent synchronous validate orders

s_load_stg_order_item_validation_error
INSERT Into delta.stg_order_item_validation_error
    SELECT * FROM staging.order_item_validation_error

s_clear_staging_order_item
delete from staging.order_item
s_clear_staging_order_item_assignment
delete from staging.order_item_assignment

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
    , Cloud_Alliance_Co_Sell_Opportunity
    , Cloud_Alliance_Opportunity_ID
    , Qualified_Prospect
    , Security_Final_ARR_Growth
    , Security_Final_ARR_Growth_UnitTypeName
    , Meeting_Status
    , Final_Qualified_Product
    , Purchase_Type
    , Is_Monthly_Subscription_Product
    , CoTerming_Type
    , SO_Number
    , Channel_Partner_Account_Owner
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
    , Cloud_Alliance_Co_Sell_Opportunity
    , Cloud_Alliance_Opportunity_ID
    , Qualified_Prospect
    , Security_Final_ARR_Growth
    , Security_Final_ARR_Growth_UnitTypeName
    , Meeting_Status
    , Final_Qualified_Product
    , Purchase_Type
    , ToBoolean(Is_Monthly_Subscription_Product) AS Is_Monthly_Subscription_Product
    , CoTerming_Type
    , SO_Number
    , Channel_Partner_Account_Owner
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
    FROM delta.prestage_order_item pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE err.created_timestamp IS null

s_load_staging_order_item_assignment
Insert Into staging.order_item_assignment (order_code, item_code, Employee_ID, split_amount_pct)
    SELECT distinct order_code , item_code , Employee_ID , split_amount_pct FROM (
    SELECT order_code AS order_code
    , item_code AS item_code
    , pstg.Employee_ID AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err
    ON err.order_code = pstg.order_code
    AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , b.emp_id AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_uer_dump b
    ON LeftSide(pstg.Business_Unit_Tier_Manager_ID,15) = LeftSide(b.id, 15)
    JOIN xactly.xc_participant part
    ON pstg.Employee_ID = part.Employee_ID
    AND Lowercase(part.Region) = Lowercase(pstg.BUSINESS_UNIT_TERRITORY)
    JOIN delta.pos_part_title_data_dump title ON title.Employee_ID = b.emp_id AND title.title_name IN ('Hybrid APAC CS Tier Mger', 'Hybrid CS Tier Mger')
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , b.emp_id AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_uer_dump b ON LeftSide(pstg.Opp_Solution_Engineer,15) = LeftSide(b.id, 15)
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , t3.Employee_ID AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_opp_team_member_dump t3 ON pstg.Order_Code = t3.OPPORTUNITYID AND t3.TEAMMEMBERROLE = 'Renewal Team'
    JOIN delta.pos_part_title_data_dump title1 ON t3.Employee_ID = title1.Employee_ID AND(title1.title_name = 'CSM' OR title1.title_name LIKE 'AMER CSM%')
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2525' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT pstg.order_code AS order_code
    , pstg.item_code AS item_code
    , CASE WHEN pstg.Cloud_Alliance_Partner_Multi IN ('Azure') THEN '1159'
    WHEN pstg.Cloud_Alliance_Partner_Multi = 'AWS' THEN '2444'
    WHEN pstg.Cloud_Alliance_Partner IN ('Azure') THEN '1159'
    WHEN pstg.Cloud_Alliance_Partner = 'AWS' THEN '2444'
    END AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'AWS') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS'))
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2045' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'GCP', 'AWS') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'GCP', 'AWS'))
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2378' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi = 'AWS' OR pstg.Cloud_Alliance_Partner = 'AWS')
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2760' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi = 'GCP' OR pstg.Cloud_Alliance_Partner = 'GCP')
    AND pstg.BATCH_TYPE = 'Opportunity'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '1762' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity'
    --Churn
    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2525' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT pstg.order_code AS order_code
    , pstg.item_code AS item_code
    , CASE WHEN pstg.Cloud_Alliance_Partner_Multi INN ('Azure') THEN '1159'
    WHEN pstg.Cloud_Alliance_Partner_Multi = 'AWS' THEN '2444'
    WHEN pstg.Cloud_Alliance_Partner IN ('Azure') THEN '1159'
    WHEN pstg.Cloud_Alliance_Partner = 'AWS' THEN '2444'
    END AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2045' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi INN ('Azure', 'GCP', 'AWS') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'GCP', 'AWS'))
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2378' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi = 'AWS'OR pstg.Cloud_Alliance_Partner = 'AWS')
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '2760' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner_Multi = 'GCP'OR pstg.Cloud_Alliance_Partner = 'GCP')
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT order_code AS order_code
    , item_code AS item_code
    , '1762' AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    AND (pstg.Cloud_Alliance_Partner INN ('Azure', 'AWS', 'GCP') OR pstg.Cloud_Alliance_Partner IN ('Azure', 'AWS', 'GCP'))
    AND pstg.BATCH_TYPE = 'Opportunity Churn'

    UNION
    SELECT DISTINCT order_code AS order_code
    , item_code AS item_code
    , SubString(pua.participant_Name, IndexOf(pua.participant_Name, '(') +1 , IndexOf(pua.participant_Name, ')')) AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_user_dmp usr ON pstg.Channel_Partner_Account_Owner = usr.Name
    JOIN xactly.xc_User xusr ON usr.Email = xusr.Email
    JOIN xc_part_user_assignment pua on xusr.User_Id = pua.User_Id
    LEFT JOIN delta.pos_part_title_data_dump title2 ON SubString(pua.participant_Name, IndexOf(pua.participant_Name, '(') +1 , IndexOf(pua.participant_Name, ')')) =title2.Employee_ID AND title2.title_name IN ('Channel Leader', 'Channel Mger', 'Channel Rep_GOV' , 'Channel Rep', 'PDR', 'Channel Mger_APAC', 'Channel Rep_APAC')
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null

    UNION

    SELECT order_code AS order_code
    , item_code AS item_code
    , b.emp_id AS Employee_ID
    , '100' AS split_amount_pct
    FROM delta.pstg_order_item_final pstg
    JOIN delta.sfdc_uer_dump b ON LeftSide(pstg.Opp_Strategic_Opp_Solution_Architect,15) = LeftSide(b.id, 15)
    LEFT JOIN staging.order_item_validation_error err ON err.order_code = pstg.order_code AND err.item_code = pstg.item_code
    WHERE 1=1
    AND err.created_timestamp IS null
    )
 p_populate_staging_c_g_p

s_clear_order_item_validation_error
delete from staging.order_item_validation_error

s_incent_create_batches
incent synchronous create batches

s_incent_upload_orders
Incent synchronous upload orders

s_set_running_pipeline_pipeline_outbound
SET v_running_pipeline *= v_running_pipeline_inbound
