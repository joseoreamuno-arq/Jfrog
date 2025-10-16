

call QueueIncentProcessGroup(Input=(select 'Partner Incentive Details Export' process_group_name, 'MAR-2022' period_name, '[{"Partner Incentive Details Export Pre-Processing":[{ "Email_Distribution_List": "joseoreamuno@canidium.com" }]}]' parameter_overrides));

call QueueIncentProcessGroup(Input=(select 'Load Partner Bookings Kick-Off' process_group_name, 'MAR-2022' period_name, '[{"Load Partner Bookings Kick-Off":[{ "Email_Distribution_List": "joseoreamuno@canidium.com" }]}]' parameter_overrides));

call QueueIncentProcessGroup(Input=(select 'Load Partner Residuals Kick-Off' process_group_name, 'MAR-2022' period_name, '[{"Load Partner Residuals Kick-Off":[{ "Email_Distribution_List": "joseoreamuno@canidium.com" }]}]' parameter_overrides));

call QueueIncentProcessGroup(Input=(select 'Kickoff_Create Pre-Approval Accounts Payable Extract' process_group_name, 'JAN-2022' period_name, '[{"Kickoff Create Pre-Approval Accounts Payable Extract":[{ "Email_Distribution_List": "joseoreamuno@canidium.com" }]}]' parameter_overrides));
