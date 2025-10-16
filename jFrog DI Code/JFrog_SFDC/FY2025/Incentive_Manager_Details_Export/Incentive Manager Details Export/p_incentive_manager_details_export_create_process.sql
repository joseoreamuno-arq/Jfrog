Manager Incentive Details Export Process

p_incentive_details_export_manager_create_process

Create step s_set_incentive_details_eid AS (
Set v_incentive_details_eid *= Select 
    GatherString( '''' ||employee_id||'''', ' ,' )
    FROM delta.user_empluyee_dmp
    WHERE 1=1
    AND (employee_id = :v_report_eid AND Contains(:v_param_email_distribution_list,email)=true)
    OR (employee_id = :v_report_eid AND :v_param_email_distribution_list IN ( Select email from delta.user_empluyee_dmp where role_Type IN ('BUSINESS_ADMINISTRATOR', 'XACTLY')))
    OR (:v_report_eid = 'ALL'AND :v_param_email_distribution_list IN ( Select email from delta.user_empluyee_dmp where role_Type IN ('BUSINESS_ADMINISTRATOR', 'XACTLY')))
)

Create pipeline p_read_incentive_details_manager_report_source
/*Start Here*/
Create step s_delta_hierarchy AS (
Insert Into Delta(TableName='delta.hierarchy_dmp',Overwrite=true, Unlogged=true)
    SELECT
    '0' AS Header
    --Manager
    , h.from_pos_id AS manager_pos_id
    , h.from_pos_name AS manager_pos_name
    , ppam.Participant_Name AS manager_part_name
    , parm.employee_id AS manager_employee_id

    --Sub
    , h.to_pos_id AS sub_pos_id
    , h.to_pos_name AS sub_pos_name
    , ppas.Participant_Name AS sub_part_name
    , pars.employee_id AS sub_employee_id
    
    , ht.pos_hierarchy_type_name
    , ht.pos_hierarchy_type_disp_name
    , ht.descr
    , ht.effective_start_date
    , ht.effective_end_date

    FROM xactly.xc_pos_hierarchy h
    JOIN xactly.xc_pos_hierarchy_type ht ON h.pos_hierarchy_type_id = ht.pos_hierarchy_type_id
    
    JOIN xactly.xc_pos_part_assignment ppam ON h.from_pos_id = ppam.position_id
    JOIN xactly.xc_participant parm ON ppam.participant_id = parm.participant_id
    
    JOIN xactly.xc_pos_part_assignment ppas ON h.to_pos_id = ppas.position_id
    JOIN xactly.xc_participant pars ON ppas.participant_id = pars.participant_id
    WHERE 1=1
    AND :v_var_sales_data_pp_start_date BETWEEN ht.effective_start_date AND ht.effective_end_date
)

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
/*End Here*/

Create pipeline p_incentive_details_export_manager_row_transform
/*Start Here*/
Alter step s_delta_commission_details_export_manager_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_prestage',Unlogged=true,Overwrite=true)
    SELECT DISTINCT
    'header_Id' AS header_Id
    , Concat(parm.Name) AS Report_Separator
    , '00' AS Row
    , com.Period_Name
    , parm.Name AS Manager_Name
    , com.Participant_Name AS Name
    , :v_param_shared_customer_name AS Company
    , LookupUnitTypeNameById(par.native_cur_unit_type_id) AS Personal_Currency
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
    FROM delta.commission_dmp com
    JOIN xactly.xc_participant par ON par.Participant_ID = com.eff_participant_id
    JOIN xactly.xc_participant parm ON com.mgr_eff_part_id = parm.participant_id
    JOIN delta.order_item_dmp coi ON com.order_item_id = coi.order_item_id
    JOIN delta.user_employee_dmp usr ON par.employee_id = usr.employee_id
    LEFT JOIN delta.credit_dmp crarr ON com.order_item_id = crarr.order_item_id AND com.eff_participant_id = crarr.eff_participant_id AND Contains(crarr.Name,'- Actual')=true AND Replace(com.Credit_Name,'- Comm Credit','')=Replace(crarr.Name,'- Actual','')
    LEFT JOIN delta.credit_dmp crqc ON com.order_item_id = crqc.order_item_id AND com.eff_participant_id = crqc.eff_participant_id AND Contains(crqc.Name,'- Quota Credit')=true AND Replace(com.Credit_Name,'- Comm Credit','')=Replace(crqc.Name,'- Quota Credit','')
    LEFT JOIN delta.Opportunity_dmp sfdc ON com.order_code = sfdc.Opportunity_Id

    WHERE 1=1
    -- AND com.Incentive_Date BETWEEN :v_report_start_date AND :v_report_end_date
    --AND par.employee_id IN (SELECT DISTINCT report_eid FROM delta.user_list)
    AND (ToDecimal(Nvl(com.Amount,0.00)) <>0.00)
    -- ORDER BY parm.Name, com.Participant_Name, com.Incentive_Date
) 

Alter step s_delta_commission_details_export_manager_dupe AS (
Insert Into Delta(TableName='delta.Incentive_Details_export_manager_dupe',Overwrite=true,Unlogged=true)
    Select Opportunity_Id, Order_Item_Code, ARR_Type, name, 
    Count(Opportunity_Id) as counter  from delta.Incentive_Details_export_manager_prestage
    Having counter >1;
Insert Into Delta(TableName='delta.Incentive_Details_Export_Manager_Clean',Overwrite=true,Unlogged=true)
    SELECT a.Name
    , a.Opportunity_Id
    , a.Order_Item_Code
    , a.ARR_Type
    , Max(a.Commission_Id) AS Commission_Id
    FROM delta.Incentive_Details_export_manager_prestage a 
    JOIN delta.Incentive_Details_export_manager_dupe b ON a.Opportunity_Id = b.Opportunity_Id AND a.Order_Item_Code = b.Order_Item_Code AND a.ARR_Type = b.ARR_Type AND a.name = b.name;
)

Alter step s_delta_commission_details_export_manager_stage AS (
Insert Into Delta(TableName='delta.Incentive_Details_Export_Manager', Overwrite=true, Unlogged=true)
    SELECT a.header_Id
    , a.Report_Separator
    , a.Row
    , a.Period_Name
    , a.Manager_Name
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
    FROM delta.Incentive_Details_export_manager_prestage a 
    LEFT JOIN delta.Incentive_Details_Export_Manager_Clean b ON a.Commission_Id = b.Commission_Id
    WHERE 1=1 
    -- AND a.Opportunity_Id = '0066900001fDA72AAG'
)

/*End Here*/

p_incentive_details_export_manager_row_create

--Row 01
Create step s_delta_Incentive_Details_export_manager_row_01_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=True,Unlogged=true)
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

    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
)

--Row 02
Create step s_delta_Incentive_Details_export_manager_row_02_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false,Unlogged=true)
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

    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
)

--Row 04
Create step s_delta_Incentive_Details_export_manager_row_04_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 04 AS Row
    , 'Name' AS C1
    , Nvl(CE.Manager_Name,'') AS C2
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

    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
)

--Row 05
Create step s_delta_Incentive_Details_export_manager_row_05_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false)
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

    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
)

--Row 06
Create step s_delta_Incentive_Details_export_manager_row_06_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 06 AS Row
    , 'Personal Currency' AS C1
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
    
    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
)

--Row 07
Create step s_delta_Incentive_Details_export_manager_row_07_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false)
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

    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
)

--Row 11
Create step s_delta_Incentive_Details_export_manager_row_11_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 11 AS Row
    , 'Name' AS C1
    , 'Opportunity ID' AS C2
    , 'Opportuity Name' AS C3
    , 'Account Name' AS C4
    , 'Product' AS C5
    , 'Opportunity Close Date' AS C6
    , 'Opportunity Churn Date' AS C7
    , 'Incentive Month' AS C8
    , 'ARR Type' AS C9
    , 'SFDC Value' AS C10
    , 'Commission Credit' AS C11
    , 'Quota Credit' AS C12
    , 'Commission Rate' AS C13
    , 'Currency' AS C14
    , 'Commission' AS C15
    , '' AS C16

    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
)

--Row 12
Create step s_delta_Incentive_Details_export_manager_row_12_insert  as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false)
    SELECT DISTINCT
    CE.Report_Separator
    , 12 AS Row
    , CE.Name AS C1
    , CE.Opportunity_Id AS C2
    , CE.Opportunity_Name AS C3
    , CE.Account_Name AS C4
    , CE.Product AS C5
    , CE.Opportunity_Close_Date AS C6
    , CE.Opportuniity_Churn_Date AS C7
    , CE.Incentive_Month AS C8
    , CE.ARR_Type AS C9
    , CE.SFDC_Value AS C10
    , CE.Commission_Credit AS C11
    , CE.Quota_Credit AS C12
    , CE.Commission_Rate AS C13
    , CE.Commission_Currency AS C14
    , CE.Commission_Amount AS C15
    , NULL AS C16

    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
    ORDER BY CE.Name
)

--Row 999999
Create step s_delta_Incentive_Details_export_manager_row_999999_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false)
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
    , '' AS C9
    , ToString(FormatNumber(Round(Sum(ToNumber(CE.SFDC_Value, 'en_US')),0),'#,##0')) AS C10
    , ToString(FormatNumber(Round(Sum(ToNumber(CE.Commission_Credit, 'en_US')),0),'#,##0')) AS C11
    , ToString(FormatNumber(Round(Sum(ToNumber(CE.Quota_Credit, 'en_US')),0),'#,##0')) AS C12
    , '' AS C13
    , '' AS C14
    , ToString(FormatNumber(Round(Sum(ToNumber(CE.Commission_Amount, 'en_US')),2),'#,##0.00')) AS C15
    , '' AS C16

    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
    group by CE.Report_Separator
)

Alter step s_delta_Incentive_Details_export_manager_blank_lines_insert as (
INSERT INTO Delta(TableName='delta.Incentive_Details_export_manager_rpt',Overwrite=false)
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
    FROM delta.Incentive_Details_Export_Manager CE
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
    FROM delta.Incentive_Details_Export_Manager CE
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
    FROM delta.Incentive_Details_Export_Manager CE
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
    FROM delta.Incentive_Details_Export_Manager CE
    WHERE CE.Row = '00'
)

create step s_delta_Incentive_Details_export_manager_iterator as (
invoke iterator i_incentive_details_export_manager)

create step s_delta_Incentive_Details_export_manager_Distribute_iterator as (
invoke iterator i_incentive_details_export_manager_distribute)

SELECT IF Ucase(:v_distibution_flag)='YES' THEN false ELSE true END  FROM Empty()






