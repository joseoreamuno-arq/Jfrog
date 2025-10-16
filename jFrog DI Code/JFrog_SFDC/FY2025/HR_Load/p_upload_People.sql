p_upload_People

Set v_period_name_manual *='JUN-2025'

s_set_period_name
set v_period_name *= select Nvl(periodname,:v_period_name_manual) from (incent queue)

s_period_start_date
set v_period_start_date *= select start_date from xactly.xc_period where name=:v_period_name
s_period_end_date
set v_period_end_date *= select end_date from xactly.xc_period where name=:v_period_name

Create step s_sfdc_user_dmp AS (
Insert Into Delta(TableName='delta.sfdc_user_dmp',Overwrite=true,Unlogged=true)
    SELECT
    Id
    , Username
    , Name
    , CompanyName
    , Division
    , Department
    , Email
    , employeeID__c
    FROM SFDC( SOQL='select Id
    , Username
    , Name
    , CompanyName
    , Division
    , Department
    , Email
    , employeeID__c
    FROM User',
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1)
)

Create step s_sfdc_incent_map AS (
Insert Into Delta(TableName='delta.sfdc_incent_map',Overwrite=true,Unlogged=true)
    SELECT 
    u.user_id 
    , u.email
    , up.participant_id
    , up.participant_name
    , Concat(par.first_name,' ',par.last_name) as incent_name
    , par.employee_id
    , su.name AS sfdc_name
    FROM xactly.xc_user u
    JOIN xactly.xc_part_user_assignment up ON u.user_id = up.user_id
    JOIN xactly.xc_participant par ON up.participant_id = par.participant_id AND :v_period_start_date BETWEEN par.effective_start_date AND par.effective_end_date
    LEFT JOIN delta.sfdc_user_dmp su ON u.email = su.email
    WHERE 1=1 
    AND u.Is_Active = '1'
)

p_lookup_table_dump

Create step s_lookup_table_dump_Person_Based_Prorated AS (
INSERT INTO Delta(TableName='delta.Person_Based_Prorated_lookup_dump',Overwrite=true,Unlogged=true)
    SELECT mdlt.Person_Name
    , mdlt.Rate
    , par.participant_id
    , par.employee_id

    FROM 
    (SELECT DISTINCT
        Trim(RemoveChars(value ,'"')) AS Person_Name
        , returnValue as Rate

            FROM
            (
                SELECT
                    Trim(JsonPath(Worker,'$.name'))        AS name
                , Trim(JsonPath(Worker,'$.field'))       AS field
                , Trim(JsonPath(Worker,'$.value'))       AS value

                --   , Trim(JsonPath(Worker,'$.version'))     AS version
                , Trim(JsonPath(Worker,'$.returnValue')) AS returnValue
                FROM
                    (call Expand(Input=
                    (
                        SELECT
                            ToJson(Worker) AS Worker
                        FROM
                            (
                                select
                                        Concat(Replace(Replace(SubString(Worker,IndexOf(Worker,'['),(IndexOf(Worker,',"index'))),'}]',''),'},{',','),'}]') as Worker
                                from
                                    ( call Expand(Input=
                                    (
                                        select
                                            ToJson(Worker) as Worker
                                        from
                                            (
                                                SELECT
                                                    MDLT_ToJson(MDLT_TABLE_DATA) as Worker
                                                FROM xactly.xc_mdlt_version_data mvd
                                                JOIN xactly.xc_period pers ON mvd.effective_start_period_id = pers.period_id
                                                JOIN xactly.xc_period perf ON mvd.effective_end_period_id = perf.period_id
                                                WHERE 1=1
                                                AND mdlt_id =(SELECT mdlt_id FROM xc_mdlt WHERE name ='Person Based Prorated OTI Table')
                                                AND :v_period_start_date BETWEEN pers.start_date AND perf.end_date
                                            )
                                    )
                                    ) )
                            )
                    )
                    ) )
            )) mdlt
    -- JOIN xactly.xc_participant par ON mdlt.Person_Name = par.First_Name||' '||par.last_name AND :v_period_start_date BETWEEN par.effective_start_date AND par.effective_end_date
    JOIN xactly.xc_participant par ON mdlt.Person_Name = par.employee_id AND :v_period_start_date BETWEEN par.effective_start_date AND par.effective_end_date
)
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

Create step s_load_people_dump_PRORATED_PERSONAL_TARGET_Person AS (
insert into Delta(TableName='delta.prestage_upload_people',Overwrite=true,Unlogged=true)
--Person Lookup Table Assignment
    select distinct
    'Person' as assignment_type
    , hr.position_name
    , hr.title_name
    , Nvl(pr.Rate,100) AS PRORATED_PERSONAL_TARGET_MULTIPLIER
    ,'save version' as action
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

    , (Nvl(pr.Rate,100) * hr.personal_target)/100 AS PRORATED_PERSONAL_TARGET
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
    LEFT JOIN delta.Person_Based_Prorated_lookup_dump pr ON hr.part2_participant_id = pr.participant_id
)

/*
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
*/

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
