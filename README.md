# Weather
Two weather apps:

1. World.Rmd (and GET_world_weather.R) uses Open-Meteo.com, which provides an open-source weather API.
   The app requires entry of a place that can be geocoded. Open-Meteo provides a geo-coding API.

2. Local.RMD (and GET_historical_weather.R, GET_forecast_weather.R) uses www.weather.gov's API to get weather data within the US.
   You can get local weather by clicking on the provided map (map provided via the leaflet package).
