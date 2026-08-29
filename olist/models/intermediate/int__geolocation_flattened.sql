/* 
* This dataset contains duplicate records per geolocation_zip_code. Joining geolocation_zip_code to customer or seller fans out the records for all geolocations
* related to a geolocation_zip_code. This model chooses the mid-point in latitude and longitude for each geolocation_zip_code to remove duplication and stop 
* rows from fanning out when joined.
 */
with geolocation as (

    select * from {{ ref('stg__geolocation') }}

),

geolocation_flattened as (

    select
        geolocation_zip_code,
        median(geolocation_latitude) as geolocation_latitude,
        median(geolocation_longitude) as geolocation_longitude
    from
        geolocation
    group by
        all

)

select * from geolocation_flattened