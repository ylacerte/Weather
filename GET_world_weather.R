library(httr2)
library(plotly)
library(splines)
library(lubridate)


get_forecast <- function(pt) {
    url <- "https://api.open-meteo.com/v1/forecast"

    daily <- paste0("temperature_2m_max", ",",
                    "temperature_2m_min", ",",
                    "precipitation_probability_max")
    hourly <- paste0("temperature_2m", ",",
                     "relative_humidity_2m", ",",
                     "precipitation_probability")
    
    req <- request(url)
    resp <- req |>
      req_url_query(`latitude` = pt[1], 
                    `longitude` = pt[2],
                    'daily' = daily,
                    'hourly' = hourly,
                    'minutely_15' = "temperature_2m") |>
      req_perform()
    
    json.resp <- resp_body_json(resp)
    
# there is a difference between input and output coordinates
#    print(paste("forecast input ", pt[1], pt[2])) 
#    print(paste("forecast return", json.resp$latitude, json.resp$longitude)) 
    
    d <- json.resp$daily
    df <- data.frame(cbind(date=unlist(d$time), 
                min=unlist(d$temperature_2m_min),
                max=unlist(d$temperature_2m_max),
                rain=unlist(d$precipitation_probability_max)))
    df$date <- as.Date(df$date)
    
    h <- json.resp$hourly
    hf <- data.frame(cbind(date=unlist(h$time), 
                           temp=unlist(h$temperature_2m),
                           humi=unlist(h$relative_humidity_2m)))
hf$date <- ymd_hm(hf$date)
    
    m <- json.resp$minutely_15
    mf <- data.frame(cbind(date=unlist(m$time), 
                           temp=unlist(m$temperature_2m)))
    mf$date <- ymd_hm(mf$date)
    
    return(list(daily=df, hourly=hf, minutely=mf))
    
}

lat <- 39.48185186130604
lng <- -105.06455547102169
pt <- c(lat,lng)
out <- get_forecast(pt)
str(out$daily)
str(out$hourly)
str(out$hourly)


get_historical_data <- function(pt) {
  
  url <- "https://historical-forecast-api.open-meteo.com/v1/forecast"

  daily <- paste0("temperature_2m_max",       ",",
                  "temperature_2m_min",            ",",
                  "precipitation_probability_max")
  
  req <- request(url)
  resp <- req |>
    req_url_query(`latitude` = pt[1], 
                  `longitude` = pt[2],
                  `start_date`= Sys.Date()-365,     #"2023-01-01",
                  `end_date`= Sys.Date(),           #"2023-12-31",
                  `daily` = daily) |>
    req_perform()
  
  json.resp <- resp_body_json(resp)
  
  d <- json.resp$daily
  df <- data.frame(cbind(date=unlist(d$time), 
              min=unlist(d$temperature_2m_min),
              max=unlist(d$temperature_2m_max)))

  return(df)
}

#lat <- 39.48185186130604
#lng <- -105.06455547102169
#pt <- c(lat,lng)
#out <- get_historical_data(pt)








geocode_city <- function(city) {

  print("local weather for")   ;    print(city)
  if (city$name == "" ) return(NULL)
  
  url <- "https://geocoding-api.open-meteo.com/v1/search"
  req <- request(url)
  
  resp <- req |>
    req_url_query(`name` = city$name,
                  `count` = 100,
                  `language`= "en",
                  `format`= "json"  ) |>
    req_perform()
  
  geocode <- resp_body_json(resp)
  
  res <- data.frame()
  for ( k in 1:length(geocode$results) ) {
    d <- geocode$results[[k]]
    if ( is.null(d$admin1) ) {
      temp <- data.frame(id=k, name=d$name, 
                         admin="NA", 
                         country=d$country, 
                         lat=d$latitude, 
                         lng=d$longitude)
    } else {
      temp <- data.frame(id=k, name=d$name, 
                         admin=d$admin1, 
                         country=d$country, 
                         lat=d$latitude, 
                         lng=d$longitude)
    }
    res <- rbind(res, temp)
  }

    if (nrow(res) == 0 ) { return(NULL) }           # city not on file
    if (nrow(res) >=  1 ) {                         # query returned one or more cities
      cc <- which((res$name  == city$name) & 
                    (res$admin == city$state) & 
                    (res$country == city$country)) 
      
      if (length(cc) == 1 ) { return(res[cc,])     # good answer ...
      } else { return(res) }                       # query returned more than one city
    }
}

#city <- data.frame(name="littleton", state="", country="USA")
#city <- data.frame(name="littleton", state="", country="United States")
#city <- data.frame(name="Littleton", state="", country="United States")
#city <- data.frame(name="Littleton", state="Colorado", country="United States")
#L <- geocode_city(city=city)
#L

