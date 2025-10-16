i_incentive_details_export

p_incentive_details_export_write_process
SELECT DISTINCT CE.Report_Separator as v_Report_Separator FROM delta.Incentive_Details_Export CE WHERE CE.Report_Separator IS NOT NULL
