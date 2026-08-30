{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart = "day",
        start_date = "cast('2016-01-01' as date)",
        end_date= " cast('2021-01-01' as date)"
    ) }}
),

brazil_holidays as (
    
    select * from {{ ref('brazil_holidays') }}

),

dates as (

    select
        to_number(
            to_char(date_day, 'YYYYMMDD')
        ) as date_key,
        
        cast(date_day as date) as date_day,

        -- day-level attributes
        extract(day from date_day) as day_of_month,
        extract(dayofyear from date_day) as day_of_year,
        extract(dayofweek from date_day) as day_of_week,          -- Snowflake: 0=Sunday
        dayname(date_day) as day_name,

        -- ISO day of week: Monday = 1 ... Sunday = 7
        case
            when extract(dayofweek from date_day) = 0 then 7
            else extract(dayofweek from date_day)
        end as day_of_week_iso,

        case
            when extract(dayofweek from date_day) in (0, 6) then true
            else false
        end as is_weekend,

        -- week-level attributes
        extract(week from date_day) as week_of_year,
        date_trunc('week', date_day) as week_start_date,
        dateadd('day', 6, date_trunc('week', date_day)) as week_end_date,

        -- month-level attributes
        extract(month from date_day) as month_of_year,
        monthname(date_day) as month_name,
        date_trunc('month', date_day) as month_start_date,
        last_day(date_day, 'month') as month_end_date,

        -- quarter-level attributes
        extract(quarter from date_day) as quarter_of_year,
        date_trunc('quarter', date_day) as quarter_start_date,
        last_day(date_day, 'quarter') as quarter_end_date,

        -- year-level attributes
        extract(year from date_day) as year_number,
        date_trunc('year', date_day) as year_start_date,
        last_day(date_day, 'year') as year_end_date,

        -- prior year, same date (for YoY comparisons)
        dateadd('year', -1, date_day) as prior_year_date_day

    from date_spine

)

select
    dates.*,
    brazil_holidays.holiday_name,
    case when brazil_holidays.holiday_date is not null then true else false end as is_holiday
from 
    dates
    left join brazil_holidays on dates.date_day = brazil_holidays.holiday_date
order by 
    dates.date_day