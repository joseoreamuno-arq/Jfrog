i_incentive_details_export_distribute

p_incentive_details_export_distribute_process
SELECT DISTINCT CE.Report_Separator as v_Report_Separator, CE.email AS v_distribute_email FROM delta.Incentive_Details_Export CE WHERE CE.Report_Separator IS NOT NULL
 