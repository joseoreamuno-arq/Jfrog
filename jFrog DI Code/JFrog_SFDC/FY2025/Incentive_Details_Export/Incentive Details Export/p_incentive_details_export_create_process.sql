Incentive Details Export Process
p_incentive_details_export_create_process

Create step s_set_incentive_details_eid AS (
Set v_incentive_details_eid *= Select 
    GatherString( '''' ||Employee_ID||'''', ' ,' )
    FROM delta.user_employee_dmp
    WHERE 1=1
    AND (employee_Id = :v_report_eid AND Contains(:v_param_email_distribution_list,email)=true)
    OR (employee_Id = :v_report_eid AND :v_param_email_distribution_list IN ( Select email from delta.user_employee_dmp where role_type IN ('BUSINESS_ADMINISTRATOR', 'XACTLY')))
    OR (:v_report_eid = 'ALL'AND :v_param_email_distribution_list IN ( Select email from delta.user_employee_dmp where role_type IN ('BUSINESS_ADMINISTRATOR', 'XACTLY')))
)

Create pipeline p_read_incentive_details_report_source

Create step s_delta_commission_dmp AS (
INSERT Into Delta(TableName='delta.commission_dmp', Overwrite=true, Unlogged=true)
    SELECT com.* 
    , crt.name AS Credit_Type_Name 
    , IF crt.Name ='Weighted NNARR Annual OTI' THEN 'Quarterly Bonus'
        ELSE Replace(Replace(Replace(crt.Name,' -Comm Credit','' ), '-Comm Credit','' ),'-Quota Credit','') END AS ARR_Type
    FROM xactly.xc_commission com
    JOIN xactly.xc_credit_type crt ON com.credit_type_id =crt.credit_type_id
    WHERE 1=1 
    AND com.Amount IS NOT NULL 
    AND com.Credit_Name IS NOT NULL
    AND com.Incentive_Date BETWEEN :v_report_start_date AND :v_report_end_date
)

Create step s_delta_credit_dmp AS (
INSERT Into Delta(TableName='delta.credit_dmp', Overwrite=true, Unlogged=true)
    SELECT cre.*
    -- , crt.Name AS Credit_Type_Name 
    FROM xactly.xc_credit cre
    -- JOIN xactly.xc_credit_type crt ON cre.credit_type_id =crt.credit_type_id
    WHERE 1=1 
    AND cre.Incentive_Date BETWEEN :v_report_start_date AND :v_report_end_date
    AND (Contains(cre.Name,'- Actual')=true OR Contains(cre.Name,'- Quota Credit')=true)
)

Create step s_delta_order_item_dmp AS (
INSERT Into Delta(TableName='delta.order_item_dmp', Overwrite=true, Unlogged=true)
    SELECT coi.comp_order_item_id AS order_item_id
    , coi.Order_Code
    , coi.Item_Code
    , coi.Close_Date
    , coi.Churn_Date
    , coi.Amount
    FROM xactly.xc_comp_order_item coi
    WHERE 1=1 
    AND coi.Incentive_Date BETWEEN :v_report_start_date AND :v_report_end_date
)

Create step s_delta_participant_dmp AS (
INSERT Into Delta(TableName='delta.participant_dmp', Overwrite=true, Unlogged=true)
    SELECT par.Participant_ID
    , par.Name AS Participant_Name
    , par.employee_Id
    , par.effective_start_date
    , par.effective_end_date
    , LookupUnitTypeNameById(par.PAYMENT_CUR_UNIT_TYPE_ID) AS Personal_Currency
    FROM xactly.xc_participant par
    WHERE 1=1 
    AND :v_report_start_date BETWEEN par.effective_start_date AND par.effective_end_date
    AND par.employee_id IN (SELECT DISTINCT report_eid FROM delta.user_list)
)

Create step s_sfdc_opportunity_dmp AS (
Insert Into Delta(TableName='delta.Opportunity_dmp', Overwrite=true,Unlogged=true)
    SELECT  ID AS Opportunity_Id
    , Name AS Opportunity_Name
    , CloseDate AS Close_Date 
    , Churn_Date__c AS Churn_Date
    FROM SFDC(
    SOQL='SELECT ID
    , Name
    , CloseDate
    , Churn_Date__c
    FROM Opportunity
    WHERE (CloseDate >= ' || :v_report_start_date || ' and CloseDate <= ' || :v_report_end_date||')
    OR (Churn_Date__c >= '||:v_report_start_date||' AND Churn_Date__c <= '||:v_report_end_date||')',
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1)
)

Create step s_delta_payment_dmp AS (
Insert Into Delta(TableName='delta.payment_dmp',Overwrite=true,Unlogged=true)
SELECT * 
FROM xactly.xc_payment pay
WHERE 1=1 
AND Contains(pay.Earning_group_name,'Draw')=true
AND pay.Incentive_Date BETWEEN :v_report_start_date AND :v_report_end_date 
)


SELECT da.*
, d.name
, :v_report_start_date 
, :v_report_end_date 
FROM xactly.xc_draw_assignment da
JOIN xactly.xc_draw d ON da.draw_Id = d.draw_Id 

WHERE 1=1 
--AND da.Finalized_Date BETWEEN :v_report_start_date AND :v_report_end_date 
AND da.Person_name ='Kristina Cohen (3256)'

Create pipeline p_incentive_details_export_row_transform

Alter step s_delta_commission_details_export_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_prestage',Unlogged=true,Overwrite=true)
    SELECT DISTINCT
    'header_Id' AS header_Id
    , Concat(com.Participant_Name) AS Report_Separator
    -- , Concat(com.Period_Name, '_', com.Participant_Name) AS Report_Separator
    , '00' AS Row
    , com.Period_Name
    -- , ToString(coi.Account_ID) AS Account_ID
    , com.Participant_Name AS Name
    , :v_param_shared_customer_name AS Company
    , par.Personal_Currency AS Personal_Currency
    , ToString(com.Incentive_Date) AS Incentive_Date
    , com.Customer_Name AS Account_Name
    , com.Product_Name AS Product
    , ToString(coi.Close_Date) AS Opportunity_Close_Date
    , ToString(coi.Churn_Date) AS Opportuniity_Churn_Date
    , com.Order_Code AS Opportunity_Id
    , sfdc.Opportunity_Name AS Opportunity_Name 
    , com.Item_Code AS Order_Item_Code
    , ToString(coi.Amount) AS Item_Amount
    , FormatDateTime(com.Incentive_Date, 'MMM-yyyy') AS Incentive_Month

    , com.ARR_Type AS ARR_Type
    , CASE WHEN Contains(com.ARR_Type,'Manual adjustment')=true THEN NULL
        WHEN Contains(com.ARR_Type,'Quarterly Bonus')=true THEN NULL
        ELSE FormatNumber(Round(Nvl(crarr.Amount,com.credit_amount),1,'UP'),'#,##0.0') END AS SFDC_Value
    
    , CASE WHEN Contains(com.ARR_Type,'Manual adjustment')=true THEN NULL
        WHEN Contains(com.ARR_Type,'Quarterly Bonus')=true THEN NULL
        ELSE FormatNumber(Round(com.credit_amount,1,'UP'),'#,##0.0') END AS Commission_Credit
    
    , CASE WHEN Contains(com.ARR_Type,'Manual adjustment')=true THEN NULL
        WHEN Contains(com.ARR_Type,'Quarterly Bonus')=true THEN NULL
        ELSE FormatNumber(Round(Nvl(crqc.Amount,com.credit_amount),1,'UP'),'#,##0.0') END AS Quota_Credit 

    , ToString(Round(com.rate_amount,2))||'%' AS Commission_Rate 
    , LookupUnitTypeNameById(com.AMOUNT_UNIT_TYPE_ID) AS Commission_Currency
    , ToString(FormatNumber(Round(com.Amount,2,'UP'),'#,##0.00')) AS Commission_Amount
    , usr.email
    , com.Commission_Id
    , com.Incentive_Date
    FROM delta.commission_dmp com
    JOIN delta.participant_dmp par ON par.Participant_Name = com.Participant_Name
    JOIN delta.order_item_dmp coi ON com.order_item_id = coi.order_item_id
    JOIN delta.user_employee_dmp usr ON par.employee_id = usr.employee_id
    LEFT JOIN delta.credit_dmp crarr ON com.order_item_id = crarr.order_item_id AND com.eff_participant_id = crarr.eff_participant_id AND Contains(crarr.Name,'- Actual')=true AND Replace(com.Credit_Name,'- Comm Credit','')=Replace(crarr.Name,'- Actual','')
    LEFT JOIN delta.credit_dmp crqc ON com.order_item_id = crqc.order_item_id AND com.eff_participant_id = crqc.eff_participant_id AND Contains(crqc.Name,'- Quota Credit')=true AND Replace(com.Credit_Name,'- Comm Credit','')=Replace(crqc.Name,'- Quota Credit','')
    LEFT JOIN delta.Opportunity_dmp sfdc ON com.order_code = sfdc.Opportunity_Id

    WHERE 1=1
    -- AND com.Incentive_Date BETWEEN :v_report_start_date AND :v_report_end_date
    --AND par.employee_id IN (SELECT DISTINCT report_eid FROM delta.user_list)
    -- AND (com.Amount IS NOT NULL AND com.Credit_Name IS NOT NULL)
    ORDER BY com.Participant_Name, com.Incentive_Date
) 

Create step s_delta_commission_details_export_dupe AS (
Insert Into Delta(TableName='delta.Incentive_Details_Export_Dupe',Overwrite=true,Unlogged=true)
    Select Opportunity_Id, Order_Item_Code, ARR_Type, name, 
    Count(Opportunity_Id) as counter  from delta.Incentive_Details_Export_prestage
    Having counter >1;
Insert Into Delta(TableName='delta.Incentive_Details_Export_Clean',Overwrite=true,Unlogged=true)
    SELECT a.Name
    , a.Opportunity_Id
    , a.Order_Item_Code
    , a.ARR_Type
    , Max(a.Commission_Id) AS Commission_Id
    FROM delta.Incentive_Details_Export_prestage a 
    JOIN delta.Incentive_Details_Export_Dupe b ON a.Opportunity_Id = b.Opportunity_Id AND a.Order_Item_Code = b.Order_Item_Code AND a.ARR_Type = b.ARR_Type AND a.name = b.name;
)

0066900001fDA72AAG

Alter step s_delta_commission_details_export_stage AS (
Insert Into Delta(TableName='delta.Incentive_Details_Export', Overwrite=true, Unlogged=true)
    SELECT a.header_Id
    , a.Report_Separator
    , a.Row
    , a.Period_Name
    , a.Name
    , a.Company
    , a.Personal_Currency
    , a.Incentive_Date
    , a.Account_Name
    , a.Product
    , a.Opportunity_Close_Date
    , a.Opportuniity_Churn_Date
    , a.Opportunity_Id
    , a.Opportunity_Name
    , a.Order_Item_Code
    , a.Item_Amount
    , a.Incentive_Month
    , a.ARR_Type
    , IF b.Opportunity_Id IS NULL THEN a.SFDC_Value ELSE NULL END AS SFDC_Value
    , IF b.Opportunity_Id IS NULL THEN a.Commission_Credit ELSE NULL END AS Commission_Credit
    , IF b.Opportunity_Id IS NULL THEN a.Quota_Credit ELSE NULL END AS Quota_Credit
    , a.Commission_Rate
    , a.Commission_Currency
    , a.Commission_Amount
    , a.email
    FROM delta.Incentive_Details_Export_prestage a 
    -- LEFT JOIN delta.Incentive_Details_Export_Clean b ON a.Opportunity_Id = b.Opportunity_Id AND a.Order_Item_Code = b.Order_Item_Code AND a.ARR_Type = b.ARR_Type AND a.name = b.name AND a.Commission_Rate = b.Commission_Rate
    LEFT JOIN delta.Incentive_Details_Export_Clean b ON a.Commission_Id = b.Commission_Id
    WHERE 1=1 
    -- AND a.Opportunity_Id = '0066900001fDA72AAG'
)

p_incentive_details_export_row_create

--Row 01
Create step s_delta_Incentive_Details_Export_row_01_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=True,Unlogged=true)
    SELECT DISTINCT
    CE.Report_Separator
    , 01 AS Row
    , 'Report Name:' AS C1
    , 'Incentive Details From: '||:v_report_start_date||' to '||:v_report_end_date AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16

    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
)

--Row 02
Create step s_delta_Incentive_Details_Export_row_02_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false,Unlogged=true)
    SELECT DISTINCT
    CE.Report_Separator
    , 02 AS Row
        , 'Report Date:' AS C1
        , ToString(FormatDateTime(CurDateTime(),'yyyy-MM-dd HH:mm')) AS C2
        , '' AS C3
        , '' AS C4
        , '' AS C5
        , '' AS C6  
        , '' AS C7
        , '' AS C8
        , '' AS C9
        , '' AS C10
        , '' AS C11
        , '' AS C12
        , '' AS C13
        , '' AS C14
        , '' AS C15
        , '' AS C16

        FROM delta.Incentive_Details_Export CE
        WHERE CE.Row = '00'
)

--Row 04
Create step s_delta_Incentive_Details_Export_row_04_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 04 AS Row
    , 'Name' AS C1
    , Nvl(CE.Name,'') AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
)

--Row 05
Create step s_delta_Incentive_Details_Export_row_05_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 05 AS Row
    , 'Company' AS C1
    , Nvl(CE.Company) AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
)

--Row 06
Create step s_delta_Incentive_Details_Export_row_06_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 06 AS Row
    , 'Personal_Currency' AS C1
    , Nvl(CE.Personal_Currency,'') AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
)

--Row 07
Create step s_delta_Incentive_Details_Export_row_07_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 07 AS Row
    , '' AS C1
    , '' AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
)

--Row 11
Alter step s_delta_Incentive_Details_Export_row_11_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 11 AS Row
    , 'Opportunity ID' AS C1
    , 'Opportuity Name' AS C2
    , 'Account Name' AS C3
    , 'Product' AS C4
    , 'Opportunity Close Date' AS C5
    , 'Opportunity Churn Date' AS C6
    , 'Incentive Month' AS C7
    , 'ARR Type' AS C8
    , 'SFDC Value' AS C9
    , 'Commission Credit' AS C10
    , 'Quota Credit' AS C11
    , 'Commission Rate' AS C12
    , 'Currency' AS C13
    , 'Commission' AS C14
    , '' AS C15
    , '' AS C16
    
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
)

--Row 12
Create step s_delta_Incentive_Details_Export_row_12_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 12 AS Row
    , CE.Opportunity_Id AS C1
    , CE.Opportunity_Name AS C2
    , CE.Account_Name AS C3
    , CE.Product AS C4
    , CE.Opportunity_Close_Date AS C5
    , CE.Opportuniity_Churn_Date AS C6
    , CE.Incentive_Month AS C7
    , IF Contains(CE.ARR_Type,'ARR')=false THEN CE.ARR_Type||' ARR' ELSE CE.ARR_Type END AS C8
    , CE.SFDC_Value AS C9
    , CE.Commission_Credit AS C10
    , CE.Quota_Credit AS C11
    , CE.Commission_Rate AS C12
    , CE.Commission_Currency AS C13
    , CE.Commission_Amount AS C14
    , NULL AS C15
    , NULL AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
)

--Row 999999
Alter  step s_delta_Incentive_Details_Export_row_999999_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 999999 AS Row
    , 'Total:' AS C1
    , '' AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6
    , '' AS C7
    , '' AS C8
    , ToString(FormatNumber(Round(Sum(ToNumber(CE.SFDC_Value, 'en_US')),1),'#,##0.0')) AS C9
    , ToString(FormatNumber(Round(Sum(ToNumber(CE.Commission_Credit, 'en_US')),1),'#,##0.0')) AS C10
    , ToString(FormatNumber(Round(Sum(ToNumber(CE.Quota_Credit, 'en_US')),1),'#,##0.0')) AS C11
    , '' AS C12
    , '' AS C13
    , ToString(FormatNumber(Round(Sum(ToNumber(CE.Commission_Amount, 'en_US')),2),'#,##0.00')) AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
    group by CE.Report_Separator
)

Alter step s_delta_Incentive_Details_Export_blank_lines_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_Export_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 03 AS Row
    , '' AS C1
    , '' AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
    UNION
    SELECT DISTINCT
    CE.Report_Separator
    , 08 AS Row
    , '' AS C1
    , '' AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
    UNION 
    SELECT DISTINCT
    CE.Report_Separator
    , 09 AS Row
    , '' AS C1
    , '' AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
    UNION
    SELECT DISTINCT
    CE.Report_Separator
    , 999998 AS Row
    , '' AS C1
    , '' AS C2
    , '' AS C3
    , '' AS C4
    , '' AS C5
    , '' AS C6  
    , '' AS C7
    , '' AS C8
    , '' AS C9
    , '' AS C10
    , '' AS C11
    , '' AS C12
    , '' AS C13
    , '' AS C14
    , '' AS C15
    , '' AS C16
    FROM delta.Incentive_Details_Export CE
    WHERE CE.Row = '00'
)


create step s_delta_Incentive_Details_Export_iterator as (
invoke iterator i_incentive_details_export)

create step s_delta_Incentive_Details_Export_Distribute_iterator as (
invoke iterator i_incentive_details_export_distribute)

SELECT IF Ucase(:v_distibution_flag)='YES' THEN false ELSE true END  FROM Empty()


Alter step s_incentive_details_write_report AS (
call WriteFile(FilePath=:v_report_file_path,
    Input=(SELECT C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16
    FROM delta.Incentive_Details_Export_rpt WHERE Report_Separator =: v_Report_Separator order by Row ASC),
FirstLineNames=false,
Separator=',',
Quote='"',
Append=false,
Trim=true);
)




