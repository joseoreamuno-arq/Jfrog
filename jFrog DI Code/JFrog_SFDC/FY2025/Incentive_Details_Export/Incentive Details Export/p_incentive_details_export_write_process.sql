p_incentive_details_export_write_process
s_incentive_details_report_file_path
s_incentive_details_write_report

Create step s_incentive_details_report_file_path as (
SET v_report_file_path *= Concat('/Outbound/Incentive_Details_',Today(),'/Incentive_Details_',v_Report_Separator,'_',Today(),'.csv');
)

Create step s_incentive_details_write_report as (
call WriteFile(FilePath=:v_report_file_path,
    Input=(SELECT C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16
    FROM delta.Incentive_Details_Export_rpt WHERE Report_Separator =:v_Report_Separator order by Row ASC),
FirstLineNames=false,
Separator=',',
Quote='"',
Append=false,
Trim=true);
)