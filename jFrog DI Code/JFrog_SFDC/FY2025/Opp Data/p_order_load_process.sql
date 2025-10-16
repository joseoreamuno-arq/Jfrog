p_order_load_process
s_d2c_load_orders_main_process
set PERIOD_NAME *= :PERIOD_NAME;
set PG_NAME *= :PG_NAME;
set PARAM_EXT_TASK_ID *=:PARAM_EXT_TASK_ID;
set EXT_OBJECT_NAME *=:EXT_OBJECT_NAME;
set CUST_BUSINESS_ID *=:CUST_BUSINESS_ID;
set v_period_name *= :PERIOD_NAME;
set v_process_name *= :PG_NAME;
set v_pipeline_name *=:EXT_OBJECT_NAME;
set v_ext_task_id *=:PARAM_EXT_TASK_ID;
set v_customer_name *=:CUST_BUSINESS_NAME;
set v_podname *= PodName();
set v_shared_customer_name *= :v_customer_name || '-' ||SubString(:v_podname,11);
set v_email_from *='delta-notifications@xactlycorp.com';
set v_business_id *=:CUST_BUSINESS_ID;
set Email_Distribution_List *= :Email_Distribution_List;
set v_email_to *= :Email_Distribution_List||',delta-notifications@xactlycorp.com';
set v_email_to_error *= :v_email_to;
set v_param_processing_period *= :PERIOD_NAME;
set v_param_shared_customer_name *= :JFrog;
set v_param_email_distribution_list *= :Email_Distribution_List;

s_set_sfdc_credentials
set v_sfdc_user *= 'xactlyintegrationuserjfrog@jfrog.com';
set v_sfdc_passwd *= 'VybL68p6PGN9ALdbj!_-HAuQgFmrq47JMdoNI3CffwxrV';

s_sfdc_user_dump
INSERT into Delta(TableName='delta.sfdc_uer_dump', Overwrite=true, Unlogged=true)
    select Id,Name, employeeid__c emp_id
    FROM SFDC(SOQL='select Id,Name, employeeid__c
    from User where employeeid__c <> null',
    CredentialName = 'sfdc_cred',
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1)

s_tmp_pos_part_title_data_dump
INSERT into Delta(TableName='delta.pos_part_title_data_dump', Overwrite=true, Unlogged=true)
select a.name position_name,c.employee_id,d.title_name from xactly.xc_position a join xactly.xc_pos_part_assignment b on a.position_id = b.position_id
join xactly.xc_participant c on b.participant_id = c.participant_id
join xactly.xc_pos_title_assignment d on a.position_id = d.position_id
where :v_var_sales_data_pp_end_date between a.effective_start_date and a.effective_end_date

s_sfdc_opp_team_member_dump
INSERT into Delta(TableName='delta.sfdc_opp_team_member_dump1', Overwrite=true, Unlogged=true)
    SELECT Id
    , Name
    , OpportunityId
    , TeamMemberRole
    , TItle
    , UserId
    , User.employeeid__c AS employee_id
    FROM SFDC(SOQL='
    SELECT Id
    , Name
    , OpportunityId
    , TeamMemberRole
    , TItle
    , UserId
    , User.employeeid__c
    FROM OpportunityTeamMember',
    CredentialName = 'sfdc_cred',
    Environment=:v_sfdc_env,
    ReadAll=true,
    Retries=2,
    RetryInterval=1
    ) 
    WHERE 1=1 
    AND (TeamMemberRole in ('Co-Sell Cloud Alliance Lead','Partner Manager','Renewal Team','MarketPlace Sales Lead')OR (TeamMemberRole = 'Specialist Solution Engineer'AND UserId = '005w0000006AFwoAAG'))

s_sfdc_opp_team_member_count_dump
INSERT into Delta(TableName='delta.sfdc_opp_team_member_count_dump', Overwrite=true, Unlogged=true)
    SELECT OpportunityId
    , TeamMemberRole
    , count(*) AS role_cnt
    FROM SFDC(SOQL='
    select Id
    ,Name
    ,OpportunityId
    ,TeamMemberRole
    ,Title
    ,UserId
    ,User.employeeid__c 
    from OpportunityTeamMember',
    CredentialName = 'sfdc_cred',
    Environment=:v_sfdc_env,
    ReadAll=true,
    Retries=2,
    RetryInterval=1
    ) 
    WHERE 1=1 
    AND (TeamMemberRole in ('Co-Sell Cloud Alliance Lead','Partner Manager','Renewal Team','MarketPlace Sales Lead')OR (TeamMemberRole = 'Specialist Solution Engineer'AND UserId = '005w0000006AFwoAAG'))

s_sfdc_opp_team_member_dump_final
INSERT into Delta(TableName='delta.sfdc_opp_team_member_dump', Overwrite=true, Unlogged=true)
select a.*, b.role_cnt from delta.sfdc_opp_team_member_dump1 a 
join delta.sfdc_opp_team_member_count_dump b on a.OpportunityId = b.OpportunityId and a.TeamMemberRole = b.TeamMemberRole

s_generic_user_load
INSERT into Delta(TableName='delta.generic_user_load', Overwrite=true, Unlogged=true)
    select Left(Id,15) as Id, Name
    FROM SFDC(SOQL='select Id, Name from User ',
    UserName=:v_sfdc_user,
    Password=:v_sfdc_passwd,
    Environment=:v_sfdc_env,
    ReadAll=false,
    Retries=2,
    RetryInterval=1
    )

 p_govt_lookup_data_dump
 p_load_sfdc_opportunity_data
 p_load_sfdc_opportunity_churn_data
 p_load_sfdc_opportunity_sdr_data
 p_load_orders
