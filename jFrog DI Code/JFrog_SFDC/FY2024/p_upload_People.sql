p_upload_People
s_set_period_name
set v_period_name *= select periodname from (incent queue)
s_period_start_date
set v_period_start_date *= select start_date from xactly.xc_period where name=:v_period_name
s_period_end_date
set v_period_end_date *= select end_date from xactly.xc_period where name=:v_period_name
p_lookup_table_dump
s_lookup_table_dump_Prorated
INSERT INTO Delta(TableName='delta.Prorated_lookup_dump',Overwrite=true,Unlogged=true)
select field, ToDate(low) as low_value, ToDate(high) as high_value, returnValue, Return_Value_Type,assignment_type_name, assignment_name, idx from(
select distinct
name AS Lookup_Table_Name,
ReplaceAll(JsonPath(data, '$.name'), '"', '') || '' as object,
ReplaceAll(JsonPath(data, '$.field'), '"', '') || '' as field,
ReplaceAll(JsonPath(data, '$.low'), '"', '') || '' as low,
ReplaceAll(JsonPath(data, '$.high'), '"', '') || '' as high,
ReplaceAll(JsonPath(data, '$.value'), '"', '') || '' as value,
returnValue,

Return_Value_Type, idx,
Assignment_Type_Name,
Assignment_Name,
effective_start_date,
effective_end_date,
Description
from Rotate(Input=( select distinct
name,
JsonPath(json_data, '$.data') as data,
CASE WHEN Data_Type = 0 THEN 'String'
WHEN Data_Type = 1 THEN 1
WHEN Data_Type = 2 THEN 2
WHEN Data_Type = 3 THEN 'Number'
ELSE Data_Type END AS Data_Type,
JsonPath(json_data, '$.returnValue') || '' as returnValue,
CASE WHEN Return_Value_Type = 0 THEN 'Amount'
WHEN Return_Value_Type = 1 THEN 'Rate'
WHEN Return_Value_Type = 2 THEN 'Rate Table Name'
WHEN Return_Value_Type = 3 THEN 'Formula Name;'
ELSE Return_Value_Type END AS Return_Value_Type,
JsonPath(json_data, '$.index') || '' as idx,
Assignment_Type,
Assignment_ID,
CASE WHEN Assignment_Type = 0 THEN 'Plan'
WHEN Assignment_Type = 1 THEN 'Position'
WHEN Assignment_Type = 2 THEN 'Title'
END AS Assignment_Type_Name,
CASE WHEN Assignment_Type = 0 THEN 'Plan'
WHEN Assignment_Type = 1 THEN position
WHEN Assignment_Type = 2 THEN title
END AS Assignment_Name,
effective_start_date,
effective_end_date,
position,
title,
Description
from Rotate(Input=( select
mdlt.name,
MDLT_ToJson(v.MDLT_TABLE_DATA) as json_data,
mdlt.Return_Value_Type,
dim.data_type,
v.Assignment_Type,
v.Assignment_ID,
pers.start_date as effective_start_date,
pere.end_date as effective_end_date,
pos.name as position,
title.name as title,
mdlt.Description
from xactly.xc_mdlt as mdlt
join xactly.xc_mdlt_version_data as v on mdlt.mdlt_id = v.mdlt_id
left join xc_mdlt_dimension dim ON dim.mdlt_version_data_id = v.mdlt_version_data_id
left join xactly.xc_period as pers on v.effective_start_period_id = pers.period_id
left join xactly.xc_period as pere on v.effective_end_period_id = pere.period_id
left join xactly.xc_position as pos on v.assignment_id = pos.position_id
left join xactly.xc_title as title on v.assignment_id = title.title_id
))
))
)
where lookup_table_name in ('Prorated OTI Table')
AND :v_period_start_date BETWEEN effective_start_date AND effective_end_date
s_delete_staging_person
delete from staging.person
s_delete_staging_person_exception
delete from staging.person_exception

s_current_hr
INSERT INTO Delta(TableName='delta.current_hr',Overwrite=true,Unlogged=true)
    SELECT DISTINCT
    pospart.participant_name
    , pospart.position_name
    , postitle.title_name
    , pospart.position_id
    , pospart.participant_id

    , part2.PARTICIPANT_ID AS part2_participant_id
    , part2.EFFECTIVE_START_DATE AS part2_eff_start_date
    , part2.EFFECTIVE_END_DATE AS part2_eff_end_date
    , part2.NAME AS part2_name
    , part2.DESCR AS part2_descr
    , part2.REGION
    , part2.PARTICIPANT_TYPE
    , part2.PREFIX
    , part2.FIRST_NAME
    , part2.MIDDLE_NAME
    , part2.LAST_NAME
    , part2.EMPLOYEE_ID
    , part2.SALARY
    , part2.SALARY_UNIT_TYPE_ID
    , part2.HIRE_DATE
    , part2.TERMINATION_DATE
    , part2.PERSONAL_TARGET
    , part2.PR_TARGET_UNIT_TYPE_ID
    , part2.NATIVE_CUR_UNIT_TYPE_ID
    , part2.USER_ID
    , part2.Payment_Frequency
    , part2.Territory
    , part2.Team
    , part2.Role
    , part2.Department
    , part2.Termination_Month
    , part2.Term_Month
    , part2.Pod
    , part2.Tier
    , part2.Person_Name
    , part2.Sub_Territory
    , part2.Segment
    , part2.Cloud_SMB_Annual_OTE
    , part2.Churn_Logo_OTI
    , part2.SQL_Conversion_OTI
    , part2.Number_of_SQL_OTI
    , part2.DemGen_Number_of_New_Logo_OTI
    , Nvl(part2.Custom_Hire_Date, part2.Hire_Date) AS Custom_Hire_Date
    , part2.Cloud_SMB_Annual_OTE_UnitTypeId
    , part2.Churn_Logo_OTI_UnitTypeId
    , part2.SQL_Conversion_OTI_UnitTypeId
    , part2.Number_of_SQL_OTI_UnitTypeId
    , part2.DemGen_Number_of_New_Logo_OTI_UnitTypeId
    , part2.PAYMENT_CUR_UNIT_TYPE_ID
    , part2.SOURCE_ID
    , part2.EMP_STATUS_ID

    , part2.Billable_Hours_OTI
    , part2.PS_Revenue_OTI
    , part2.JAS_Pipelline_OTI_Quarterly
    , part2.JAS_NNARR_OTI_Quarterly
    , part2.Billable_Hours_OTI_UnitTypeId
    , part2.PS_Revenue_OTI_UnitTypeId
    , part2.JAS_Pipelline_OTI_Quarterly_UnitTypeId
    , part2.JAS_NNARR_OTI_Quarterly_UnitTypeId
    , part2.OBJ_BONUS_TARGET
    , part2.OBJ_BONUS_TARGET_UNITTYPE_ID
    , part2.OBJ_PAYMENT_CAP_PERCENT
    , part2.IS_OBJ_ACTIVE
    , part2.PRORATED_SALARY
    , part2.PRORATED_PERSONAL_TARGET
    , part2.VERSION_REASON_ID
    , part2.VERSION_SUB_REASON_ID
    , pos2.POSITION_ID AS pos2_position_id

    , pos2.NAME AS pos2_position_name

    , pos2.INCENT_ST_DATE
    , pos2.INCENT_END_DATE

    , pos2.TITLE_ID
    , pos2.POS_GROUP_ID
    , pos2.PARENT_RECORD_ID
    , pos2.PARENT_POSITION_ID
    , pos2.PARTICIPANT_ID AS pos2_participant_id

    , pos2.MASTER_POSITION_ID
    , pos2.BUSINESS_GROUP_ID AS pos2_business_group_id
    , pos2.CREDIT_START_DATE
    , pos2.CREDIT_END_DATE
    , usr.email
    FROM xc_participant part_mast
    JOIN xc_participant part2 ON part_mast.is_master = 1 AND part_mast.employee_id = part2.employee_id AND ToDate(:v_period_start_date) <= part2.effective_end_date AND ToDate(:v_period_end_date) >= part2.effective_start_date
    LEFT JOIN xc_pos_part_assignment pospart ON part_mast.participant_id = pospart.participant_id
    JOIN xc_position pos2 ON pospart.position_id = pos2.position_id AND ToDate(:v_period_start_date) <= pos2.effective_end_date AND ToDate(:v_period_end_date) >= pos2.effective_start_date
    LEFT JOIN xc_position pos_mast ON pos_mast.is_master = 1 AND pos2.position_id = pos_mast.position_id
    LEFT JOIN xc_pos_title_assignment postitle ON pos2.position_id = postitle.position_id
    JOIN xactly.xc_part_user_assignment up ON part2.participant_id = up.participant_id
    JOIN xactly.xc_user usr ON up.USER_ID = usr.USER_ID
    WHERE 1=1;

s_load_people_dump_PRORATED_PERSONAL_TARGET_Position
insert into Delta(TableName='delta.prestage_upload_people',Overwrite=true,Unlogged=true)
--Position Lookup Table Assignment
    select distinct
    'Position' as assignment_type
    ,hr.position_name
    ,hr.title_name
    ,case when hr.HIRE_DATE between pr.LOW_VALUE and pr.HIGH_VALUE
    then Nvl(pr.RETURNVALUE,1)
    else 0
    end as PRORATED_PERSONAL_TARGET_MULTIPLIER
    ,pr.idx,
    'save version' as action
    ,hr.employee_id
    ,hr.part2_eff_start_date AS effective_start_date
    ,hr.part2_DESCR as DESCR
    ,hr.prefix,hr.first_name
    ,hr.middle_name
    ,hr.last_name
    ,hr.region
    ,LookupEmployeeStatusNameById(hr.EMP_STATUS_ID) as employee_status
    ,hr.hire_date,hr.termination_date,hr.personal_target
    ,LookupUnitTypeNameById(hr.PR_TARGET_UNIT_TYPE_ID) as personal_currency
    ,hr.salary
    ,LookupUnitTypeNameById(hr.SALARY_UNIT_TYPE_ID) as salary_currency
    ,LookupUnitTypeNameById(hr.PAYMENT_CUR_UNIT_TYPE_ID) as payment_currency
    ,hr.EMAIL as email_address
    ,LookupBusinessGroupNameById(hr.pos2_BUSINESS_GROUP_ID) as business_group
    ,hr.prorated_salary


    ,case when hr.HIRE_DATE between pr.LOW_VALUE and pr.HIGH_VALUE
    then (Nvl(pr.RETURNVALUE,1) * hr.personal_target)/100
    else hr.personal_target
    end as PRORATED_PERSONAL_TARGET
    ,hr.Payment_Frequency
    ,hr.Territory
    ,hr.Team
    ,hr.Role
    ,hr.Department
    ,hr.Termination_Month
    ,hr.Term_Month
    ,hr.Pod
    ,hr.Tier
    ,hr.Person_Name
    ,hr.Cloud_SMB_Annual_OTE
    ,hr.Churn_Logo_OTI
    ,hr.SQL_Conversion_OTI
    ,hr.Number_of_SQL_OTI
    ,hr.DemGen_Number_of_New_Logo_OTI


    ,LookupUnitTypeNameById(hr.Cloud_SMB_Annual_OTE_UnitTypeId) as Cloud_SMB_Annual_OTE_UnitTypeName
    ,LookupUnitTypeNameById(hr.Churn_Logo_OTI_UnitTypeId) as Churn_Logo_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.SQL_Conversion_OTI_UnitTypeId) as SQL_Conversion_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.Number_of_SQL_OTI_UnitTypeId) as Number_of_SQL_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.DemGen_Number_of_New_Logo_OTI_UnitTypeId) as DemGen_Number_of_New_Logo_OTI_UnitTypeName

    ,hr.Billable_Hours_OTI
    ,hr.PS_Revenue_OTI
    ,LookupUnitTypeNameById(hr.Billable_Hours_OTI_UnitTypeId) as Billable_Hours_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.PS_Revenue_OTI_UnitTypeId) as PS_Revenue_OTI_UnitTypeName
    ,hr.Hire_Date as Custom_Hire_Date

    from delta.current_hr hr
    join delta.Prorated_lookup_dump pr on hr.hire_Date >=pr.LOW_VALUE and hr.hire_Date <= pr.HIGH_VALUE AND (pr.assignment_type_name = 'Position' AND pr.assignment_name = hr.position_name)

s_load_people_dump_PRORATED_PERSONAL_TARGET_Title
insert into Delta(TableName='delta.prestage_upload_people',Overwrite=false,Unlogged=true)
--Title Lookup Table Assignment
    select distinct
    'Title' as assignment_type
    ,hr.position_name
    ,hr.title_name
    ,case when hr.HIRE_DATE between pr.LOW_VALUE and pr.HIGH_VALUE
    then Nvl(pr.RETURNVALUE,1)
    else 0
    end as PRORATED_PERSONAL_TARGET_MULTIPLIER
    ,pr.idx,
    'save version' as action
    ,hr.employee_id
    ,hr.part2_eff_start_date AS effective_start_date
    ,hr.part2_DESCR as DESCR
    ,hr.prefix,hr.first_name
    ,hr.middle_name
    ,hr.last_name
    ,hr.region
    ,LookupEmployeeStatusNameById(hr.EMP_STATUS_ID) as employee_status
    ,hr.hire_date,hr.termination_date,hr.personal_target
    ,LookupUnitTypeNameById(hr.PR_TARGET_UNIT_TYPE_ID) as personal_currency
    ,hr.salary
    ,LookupUnitTypeNameById(hr.SALARY_UNIT_TYPE_ID) as salary_currency
    ,LookupUnitTypeNameById(hr.PAYMENT_CUR_UNIT_TYPE_ID) as payment_currency
    ,hr.EMAIL as email_address
    ,LookupBusinessGroupNameById(hr.pos2_BUSINESS_GROUP_ID) as business_group
    ,hr.prorated_salary


    ,case when hr.HIRE_DATE between pr.LOW_VALUE and pr.HIGH_VALUE
    then (Nvl(pr.RETURNVALUE,1) * hr.personal_target)/100
    else hr.personal_target
    end as PRORATED_PERSONAL_TARGET
    ,hr.Payment_Frequency
    ,hr.Territory
    ,hr.Team
    ,hr.Role
    ,hr.Department
    ,hr.Termination_Month
    ,hr.Term_Month
    ,hr.Pod
    ,hr.Tier
    ,hr.Person_Name
    ,hr.Cloud_SMB_Annual_OTE
    ,hr.Churn_Logo_OTI
    ,hr.SQL_Conversion_OTI
    ,hr.Number_of_SQL_OTI
    ,hr.DemGen_Number_of_New_Logo_OTI


    ,LookupUnitTypeNameById(hr.Cloud_SMB_Annual_OTE_UnitTypeId) as Cloud_SMB_Annual_OTE_UnitTypeName
    ,LookupUnitTypeNameById(hr.Churn_Logo_OTI_UnitTypeId) as Churn_Logo_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.SQL_Conversion_OTI_UnitTypeId) as SQL_Conversion_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.Number_of_SQL_OTI_UnitTypeId) as Number_of_SQL_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.DemGen_Number_of_New_Logo_OTI_UnitTypeId) as DemGen_Number_of_New_Logo_OTI_UnitTypeName

    ,hr.Billable_Hours_OTI
    ,hr.PS_Revenue_OTI
    ,LookupUnitTypeNameById(hr.Billable_Hours_OTI_UnitTypeId) as Billable_Hours_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.PS_Revenue_OTI_UnitTypeId) as PS_Revenue_OTI_UnitTypeName
    ,hr.Hire_Date as Custom_Hire_Date

    from delta.current_hr hr
    join delta.Prorated_lookup_dump pr on hr.hire_Date >=pr.LOW_VALUE and hr.hire_Date <= pr.HIGH_VALUE AND (pr.assignment_type_name = 'Title' AND pr.assignment_name = hr.title_name)
    left join delta.prestage_upload_people pre_stage on hr.employee_id = pre_stage.employee_id
    where pre_stage.employee_id is null

s_load_people_dump_PRORATED_PERSONAL_TARGET_Plan
insert into Delta(TableName='delta.prestage_upload_people',Overwrite=false,Unlogged=true)
--Plan Lookup Table Assignment
    select distinct
    'Plan' as assignment_type
    ,hr.position_name
    ,hr.title_name
    ,case when hr.HIRE_DATE between pr.LOW_VALUE and pr.HIGH_VALUE
    then Nvl(pr.RETURNVALUE,1)
    else 0
    end as PRORATED_PERSONAL_TARGET_MULTIPLIER
    ,pr.idx,
    'save version' as action
    ,hr.employee_id
    ,hr.part2_eff_start_date AS effective_start_date
    ,hr.part2_DESCR as DESCR
    ,hr.prefix,hr.first_name
    ,hr.middle_name
    ,hr.last_name
    ,hr.region
    ,LookupEmployeeStatusNameById(hr.EMP_STATUS_ID) as employee_status
    ,hr.hire_date,hr.termination_date,hr.personal_target
    ,LookupUnitTypeNameById(hr.PR_TARGET_UNIT_TYPE_ID) as personal_currency
    ,hr.salary
    ,LookupUnitTypeNameById(hr.SALARY_UNIT_TYPE_ID) as salary_currency
    ,LookupUnitTypeNameById(hr.PAYMENT_CUR_UNIT_TYPE_ID) as payment_currency
    ,hr.EMAIL as email_address
    ,LookupBusinessGroupNameById(hr.pos2_BUSINESS_GROUP_ID) as business_group
    ,hr.prorated_salary


    ,case when hr.HIRE_DATE between pr.LOW_VALUE and pr.HIGH_VALUE
    then (Nvl(pr.RETURNVALUE,1) * hr.personal_target)/100
    else hr.personal_target
    end as PRORATED_PERSONAL_TARGET
    ,hr.Payment_Frequency
    ,hr.Territory
    ,hr.Team
    ,hr.Role
    ,hr.Department
    ,hr.Termination_Month
    ,hr.Term_Month
    ,hr.Pod
    ,hr.Tier
    ,hr.Person_Name
    ,hr.Cloud_SMB_Annual_OTE
    ,hr.Churn_Logo_OTI
    ,hr.SQL_Conversion_OTI
    ,hr.Number_of_SQL_OTI
    ,hr.DemGen_Number_of_New_Logo_OTI

    ,LookupUnitTypeNameById(hr.Cloud_SMB_Annual_OTE_UnitTypeId) as Cloud_SMB_Annual_OTE_UnitTypeName
    ,LookupUnitTypeNameById(hr.Churn_Logo_OTI_UnitTypeId) as Churn_Logo_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.SQL_Conversion_OTI_UnitTypeId) as SQL_Conversion_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.Number_of_SQL_OTI_UnitTypeId) as Number_of_SQL_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.DemGen_Number_of_New_Logo_OTI_UnitTypeId) as DemGen_Number_of_New_Logo_OTI_UnitTypeName

    ,hr.Billable_Hours_OTI
    ,hr.PS_Revenue_OTI
    ,LookupUnitTypeNameById(hr.Billable_Hours_OTI_UnitTypeId) as Billable_Hours_OTI_UnitTypeName
    ,LookupUnitTypeNameById(hr.PS_Revenue_OTI_UnitTypeId) as PS_Revenue_OTI_UnitTypeName
    ,hr.Hire_Date as Custom_Hire_Date

    from delta.current_hr hr
    join delta.Prorated_lookup_dump pr on hr.hire_Date >=pr.LOW_VALUE and hr.hire_Date <= pr.HIGH_VALUE AND (pr.assignment_type_name = 'Plan' AND pr.assignment_name != hr.title_name AND pr.assignment_name != hr.position_name)
    left join delta.prestage_upload_people pre_stage on hr.employee_id = pre_stage.employee_id
    where pre_stage.employee_id is null

s_load_people_dump_PRORATED_PERSONAL_TARGET
insert into staging.person (action,employee_id,effective_start_date,description,prefix,first_name,middle_name,last_name,region,employee_status,hire_date,termination_date,personal_target, personal_currency,salary,salary_currency,payment_currency,email_address,business_group,prorated_salary,prorated_personal_target,Payment_Frequency,Territory,Team,Role,Department,Termination_Month,Term_Month,Pod,Tier,Person_Name,Cloud_SMB_Annual_OTE,Churn_Logo_OTI,SQL_Conversion_OTI,Number_of_SQL_OTI,DemGen_Number_of_New_Logo_OTI,Cloud_SMB_Annual_OTE_UnitTypeName,Churn_Logo_OTI_UnitTypeName,SQL_Conversion_OTI_UnitTypeName,Number_of_SQL_OTI_UnitTypeName,DemGen_Number_of_New_Logo_OTI_UnitTypeName,Billable_Hours_OTI,PS_Revenue_OTI,Billable_Hours_OTI_UnitTypeName,PS_Revenue_OTI_UnitTypeName,Custom_Hire_Date)
    select
    action
    ,employee_id
    ,effective_start_date
    ,DESCR as description
    ,prefix
    ,first_name
    ,middle_name
    ,last_name
    ,region
    ,employee_status
    ,hire_date
    ,termination_date
    ,personal_target
    ,personal_currency
    ,salary
    ,salary_currency
    ,payment_currency
    ,email_address
    ,business_group
    ,prorated_salary

    ,PRORATED_PERSONAL_TARGET
    ,Payment_Frequency
    ,Territory
    ,Team
    ,Role
    ,Department
    ,Termination_Month
    ,Term_Month
    ,Pod
    ,Tier
    ,Person_Name
    ,Cloud_SMB_Annual_OTE
    ,Churn_Logo_OTI
    ,SQL_Conversion_OTI
    ,Number_of_SQL_OTI
    ,DemGen_Number_of_New_Logo_OTI

    ,Cloud_SMB_Annual_OTE_UnitTypeName
    ,Churn_Logo_OTI_UnitTypeName
    ,SQL_Conversion_OTI_UnitTypeName
    ,Number_of_SQL_OTI_UnitTypeName
    ,DemGen_Number_of_New_Logo_OTI_UnitTypeName

    ,Billable_Hours_OTI
    ,PS_Revenue_OTI
    ,Billable_Hours_OTI_UnitTypeName
    ,PS_Revenue_OTI_UnitTypeName
    ,Custom_Hire_Date
    from delta.prestage_upload_people

s_write_generic_people_error
Call WriteFile(FilePath='/Error_logs/Generic_People_error_log.csv/',
    Input=(Select Employee_id,Concat(first_name,' ',last_name) as Name,exception_message
    from staging.person_exception),
    FirstLineNames=true,
    Separator=',',
    Quote='"',
    Trim=true)

s_incent_upload_people
incent upload people
