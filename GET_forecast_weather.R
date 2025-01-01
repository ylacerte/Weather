library(plotly)
library("RColorBrewer")
library(lubridate)
library(kableExtra)
library(httr2)
library(readr)
library(stringr)
library(tidyverse)
library(sf)
library(lubridate)
library(leaflet)

####### FORECAST #######
# https://www.weather.gov/documentation/services-web-api

GET_forecast_url <- function(point) {

  # point is a lat/lon vector  
    url <-"https://api.weather.gov/points/"
    q <- paste0(
      url,
      point[1], ",",
      point[2]
    )

    req <- request(q)
    resp <- req_perform(req)
    contents <- resp |> resp_body_json()

    forecast <- contents$properties$forecast
    forecastHourly <- contents$properties$forecastHourly
    forecastGridData <- contents$properties$forecastGridData
    observationStations <- contents$properties$observationStations

    df <- data.frame(rbind(
      c(name="forecast", url=forecast),
      c(name="forecastHourly", url=forecastHourly),
      c(name="forecastGridData", url=forecastGridData),
      c(name="observationStations", url=observationStations)
    ))
    return(df)
}    





GET_forecast_weather <- function(url) {
  req <- request(url)
  resp <- req_perform(req)
  contents <- resp |> resp_body_json()

  fcast <- data.frame()
  for ( i in 1:length(contents$properties$periods[[1]]) ) { 
    a <- attributes(contents$properties$periods[[1]][i])
    fcast <- rbind(fcast, a) 
  }
  for( i in 1:length(contents$properties$periods) ) {
    t <- contents$properties$periods[[i]]
    temp <- data.frame()
    for ( j in 1:length(t) ) {
      data <- t[j] 
      if ( j == 9 ) {
        data <- t[j]$probabilityOfPrecipitation$value
        if (is.null(data)) data <- 0
      }
      temp <- rbind(temp, value=as.character(data))
      colnames(temp) <- "value"
    }
    fcast <- cbind(fcast, temp)
  }

  forecastWeather <- fcast[c(2,3,6,7,9,10,11,13,14),]
  forecastWeather$names[2] <- "date/time"
  forecastWeather[2,c(2:ncol(forecastWeather))] <- as.character(ymd_hms(forecastWeather[2,c(2:ncol(forecastWeather))], tz="America/Denver"))

  return(forecastWeather)
}


  
GET_hourly_forecast_weather <- function(url) {
  req <- request(url)
  resp <- req_perform(req)
  contents <- resp |> resp_body_json()

  fcast <- data.frame()
  for ( i in 1:length(contents$properties$periods[[1]]) ) { 
    a <- attributes(contents$properties$periods[[1]][i])
    fcast <- rbind(fcast, a) 
  }
    
  for( i in 1:length(contents$properties$periods) ) {
    t <- contents$properties$periods[[i]]
    temp <- data.frame()
    for ( j in 1:length(t) ) {
      data <- t[j] 
      if ( j == 9 ) {
        data <- t[j]$probabilityOfPrecipitation$value
        if (is.null(data)) data <- 0
      }
      if ( j == 10 ) {
        data <- t[j]$dewpoint$value
        if (is.null(data)) data <- 0
      }
      if ( j == 11 ) {
        data <- t[j]$relativeHumidity$value
        if (is.null(data)) data <- 0
      }
      temp <- rbind(temp, value=as.character(data))
      colnames(temp) <- "value"
    }
    fcast <- cbind(fcast, temp)
  }
  hourlyForecastWeather <- fcast[c(3,6,7,9,10,11,12,13,15),]
  hourlyForecastWeather$names[1] <- "date/time"
  hourlyForecastWeather[1,c(2:ncol(hourlyForecastWeather))] <- as.character(ymd_hms(hourlyForecastWeather[1,c(2:ncol(hourlyForecastWeather))], tz="America/Denver"))

  return(hourlyForecastWeather) 
}


GET_weather_stations <- function(url) {
  req <- request(url)
  resp <- req_perform(req)
  contents <- resp |> resp_body_json()
  stations <- data.frame()
  for (i in 1:length(contents$features)) {
    df <- data.frame(id=contents$features[[i]]$id,
                     name=contents$features[[i]]$properties$name,
                     type=contents$features[[i]]$properties$`@type`,
                     lon=contents$features[[i]]$geometry$coordinates[[1]],
                     lat=contents$features[[i]]$geometry$coordinates[[2]])
    stations <- rbind(stations, df)
  }
  return(stations)
}  





loc <- function() {
  lat <- 39.48083560687681
  lon <- -105.06391035422446
  address <- "8204 Mount Kataka St, Littleton, CO 80125"
  date <- Sys.Date()
  df <- data.frame(address, lat, lon, date)
  return(df)
}

test <- function() {
  location <- loc()
  point <- c(location$lat, location$lon)
  url.list <- GET_forecast_url(point)
  url.list
  
  forecastWeather <- GET_forecast_weather(url=url.list[1,2])
  forecastWeather %>% kbl() %>% kable_styling()
  
  hourlyForecastWeather <- GET_hourly_forecast_weather(url=url.list[2,2])
  hourlyForecastWeather %>% kbl() %>% kable_styling()  
  
  stations <- GET_weather_stations(url=url.list[4,2])
  leaflet() %>% addProviderTiles("CartoDB.Positron") %>% 
    setView(lng=location$lon, lat=location$lat, zoom = 12) %>% 
    addCircles(lng=stations$lon, lat=stations$lat, 
               radius=520, color='red', 
               label=paste(stations$name, stations$type))
}
