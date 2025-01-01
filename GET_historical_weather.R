# 1. set up a bounding box around Douglas County, CO
# 2. use web service to get all the weather stations inside the bounding box
# 3. select a suitable weather station
# 4. use web service to get historical data 


library(httr2)
library(readr)
library(stringr)
library(tidyverse)
library(sf)

# bounding box, Douglas County, CO
dest <- "C:\\Users\\ylace\\OneDrive\\Desktop\\STUFF\\Weather\\counties\\tl_2021_us_county.shp"
FN <- st_read(dest)
FN <- st_transform(FN, crs = 4326)
DC.CO <- FN[which(FN$NAME == "Douglas" & FN$STATEFP == "08"),]
BB <- st_bbox(DC.CO)
st.BB <- st_as_sfc(BB)
FB <- as.numeric(BB)


#  StnMeta web services
url <- "https://data.rcc-acis.org/StnMeta"
q <- paste0(
  url,
  "?bbox=", FB[1],",",FB[2],",",FB[3], ",",FB[4],  # WSEN
  "&output=csv"
)
req <- request(q)
resp <- req_perform(req)
resp_content_type(resp)    # csv
resp_encoding(resp)        # UTF-8
stations <- resp |> resp_body_string() |> read_csv(col_names = FALSE)
colnames(stations) <- c("station", "name", "state", "longitude", "latitude", "elevation")
stations$longitude <- as.numeric(stations$longitude)
stations$latitude <- as.numeric(stations$latitude)
KASSLER <- stations[which(stations$station == "054452"),]




# StnData web services
#  station 054452 KASSLER   

elements <- data.frame(rbind(
  c(name="maxt",	code=1, 	desc="Maximum temperature (°F)"),
  c(name="mint",	code=2, 	desc="Minimum temperature (°F)"),
  c(name="pcpn",	code=4, 	desc="Precipitation (inches)"),
  c(name="snow",	code=10,	desc="Snowfall (inches)"),
  c(name="snwd",	code=11,	desc="Snow depth (inches)")
))


url <- "https://data.rcc-acis.org/StnData"
q <- paste0(
  url,
  "?sid=", "054452",
  "&sdate=", "2024-01-01",
  "&edate=", Sys.Date() ,
  "&elems=", "1,2,4,10,11",
  "&output=", "csv"
)
req <- request(q)
resp <- req_perform(req)
resp_content_type(resp)    # csv
resp_encoding(resp)        # UTF-8
contents <- resp |> resp_body_string() |> read_csv()
data <- data.frame()
for ( i in 1:nrow(contents) ) {
  temp <- str_split_fixed(contents[i,1], ",", 6)
  data <- rbind(data, temp)
}
colnames(data) <- c("date", "maxt", "mint", "pcpn", "snow", "sndw")
data$date <- as.Date(data$date)
data$maxt <- as.numeric(data$maxt)
data$mint <- as.numeric(data$mint)
data$pcpn <- as.numeric(data$pcpn)
data$snow <- as.numeric(data$snow)
data$sndw <- as.numeric(data$sndw)

historicalWeather <- data

