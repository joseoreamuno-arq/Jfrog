
call QueueIncentProcessGroup(Input=(select 'Kickoff_Load_Orders' process_group_name, :Period period_name, '[{"Kickoff_Load_Orders":[{ "Email_Distribution_List": "joseoreamuno@canidium.com" }]}]' parameter_overrides));

call QueueIncentProcessGroup(Input=(select 'Kickoff_Daily_Process' process_group_name, 'SEP-2024' period_name, '[{"Kickoff_Daily_Process":[{ "Email_Distribution_List": "joseoreamuno@canidium.com" }]}]' parameter_overrides));

SELECT
QualifiedApiName,Label
FROM SFDC( SOQL='select QualifiedApiName, Label FROM EntityDefinition 
 WHERE Label LIKE ''%ARR %''
ORDER BY QualifiedApiName LIMIT 1000',
  UserName=:v_sfdc_user,
Password=:v_sfdc_passwd,
Environment=:v_sfdc_env,
ReadAll=false,
Retries=2,
RetryInterval=1)


SELECT
QualifiedApiName,Label,DataType,Scale
FROM SFDC( SOQL='select QualifiedApiName,Label,DataType,Scale FROM FieldDefinition 
WHERE (EntityDefinition.QualifiedApiName = ''Arr_breakdown__x'') 
          LIMIT 2000',
  UserName=:v_sfdc_user,
Password=:v_sfdc_passwd,
Environment=:v_sfdc_env,
ReadAll=false,
Retries=2,
RetryInterval=1)


SELECT
QualifiedApiName,Label,DataType,Scale
FROM SFDC( SOQL='select QualifiedApiName,Label,DataType,Scale FROM FieldDefinition 
WHERE (EntityDefinition.QualifiedApiName = ''SBQQ__Quote__c'') 
          LIMIT 2000',
  UserName=:v_sfdc_user,
Password=:v_sfdc_passwd,
Environment=:v_sfdc_env,
ReadAll=false,
Retries=2,
RetryInterval=1)
Where Label LIKE '%GB%'


SELECT
QualifiedApiName,Label
FROM SFDC( SOQL='select QualifiedApiName, Label FROM EntityDefinition 
 WHERE Label LIKE ''%Quote%''
ORDER BY QualifiedApiName LIMIT 1000',
UserName=:v_sfdc_user,
Password=:v_sfdc_passwd,
Environment=:v_sfdc_env,
ReadAll=false,
Retries=2,
RetryInterval=1)


v_sfdc_user = 'xactlyintegrationuserjfrog@jfrog.com'

v_sfdc_passwd = 'VybL68p6PGN9ALdbj!_-HAuQgFmrq47JMdoNI3CffwxrV'


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
    , Approval_Process__r.Description__c 
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
    ,(SELECT Id,Approval_Sales_Manager__c,OwnerId,Owner.userRole.name,CreatedDate,Description__c FROM Approval_Process__r)
    FROM OpportunityTeamMember 
    WHERE Opportunity.IsClosed = true 
              AND (Opportunity.IsWon = true OR (Opportunity.StageName Like ''%Closed%'' and Opportunity.Record_Type_Name__c = ''Renewal'' AND Opportunity.Churn_Date__c > ' ||SubtractTimeInterval(ToDate('2025-07-31'),1,'MONTHS')||'))
              AND Opportunity.Is_Test_Account__c = false
              AND Opportunity.Last_assignment_date__c <> NULL
              AND ((TeamMemberRole = ''Former Owner'' AND Split_Percentage__c > 0 AND Opportunity.ARR_Difference__c<>0) OR (TeamMemberRole=''Former Owner'' AND Opportunity.Related_Contracts_ARR_Formula__c >0  AND Penalty_Percentage__c > 0) OR TeamMemberRole = ''Owner'')
    AND Opportunity.CloseDate >= ' || ToDate('2025-07-01') || ' and Opportunity.CloseDate <= ' || ToDate('2025-07-31'),
    CredentialName = 'sfdc_cred',
    ReadAll=false,
    Retries=2,
    RetryInterval=1)


SELECT * 
FROM SFDC(SOQL='
SELECT Id,Approval_Sales_Manager__c,OwnerId,Owner.userRole.name,CreatedDate,Description__c FROM Approval_Process__r',
    CredentialName = 'sfdc_cred',
    ReadAll=false,
    Retries=2,
    RetryInterval=1)