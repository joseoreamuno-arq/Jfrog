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