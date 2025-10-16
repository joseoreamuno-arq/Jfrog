create step if not exists s_set_period AS(
INSERT INTO Delta(TableName='delta.period', Overwrite=true)
	SELECT 
	Nvl(iq.PeriodName,:Period) AS name,
	FormatDateTime(per.start_date,'yyyy-MM-dd') AS start_date,
	FormatDateTime(per.end_date,'yyyy-MM-dd') AS end_date,
	per.parent_period_id
	FROM (incent queue) iq
	FULL JOIN xactly.xc_period per ON Nvl(iq.PeriodName,:Period) = per.name
	WHERE per.name = Nvl(iq.PeriodName,:Period) LIMIT 1
	);

create step if not exists s_set_period_variables AS (
SET v_Period_Name*=SELECT name FROM delta.period;
SET Period *= SELECT name FROM delta.period;
SET v_start_date *= SELECT start_date FROM delta.period;
SET v_end_date *= SELECT end_date FROM delta.period;
SET v_parent_period_id *= SELECT parent_period_id FROM delta.period;
SET v_year *= SELECT RightSide(name, 4) FROM delta.period;
SET v_datekey *= FormatDateTime(WithZOffset(ToZonedDateTime(Now()),'-04:00'), 'yyyy-MM-dd');
);

create pipeline if not exists p_set_period;

alter pipeline if exists p_set_period 
	add step  s_set_period;

alter pipeline if exists p_set_period 
	add step  s_set_period_variables;
	
alter pipeline if exists p_set_period 
	add step  s_set_shared_get_now_gmt_4;
	
create step if not exists s_set_shared_get_now_gmt_4 as (
set v_now_gmt_4*= FormatDateTime(WithZOffset(ToZonedDateTime(Now()),'-04:00'), 'yyyy-MM-dd HH:mm:ss O')
); 