##Script from the workbook
  # updated version for tmap v4
  # install using:
  # install.packages("remotes")
  # remotes::install_github('r-tmap/tmap')
  # if you don't want to change your main computer setup, you can try out on posit.cloud
  # https://nickbearman.github.io/installing-software/r-rstudio.html#posit-cloud

# Practical 1: Spatial Analysis
# Moran’s I and LISA in R (optional exercise)

library(rgeoda)
library(sf)
library(tmap)
setwd("~/work/confident-spatial-analysis/data-user")

#read in shapefile
manchester_lsoa <- st_read("lsoa_manchester_age_imd.shp")

# Calculate Spatial Weights
queen_w <- queen_weights(manchester_lsoa)
summary(queen_w)

# To access the details of the weights: 
# e.g. list the neighbours of a specified observation:
nbrs <- get_neighbors(queen_w, idx = 1)
cat("\nNeighbors of the 1-st observation are:", nbrs)

####


lag <- spatial_lag(queen_w, manchester_lsoa['IMDscor'])
lag

imd <- manchester_lsoa$IMDscor

lag <- as.integer(unlist(lag))

plot(imd,lag)
plot(scale(imd),scale(lag))

#Calculate Moran's I value
I <- cor(imd, lag) * sd(lag) / sd(imd)

#Add to plot:
plot(scale(imd),scale(lag), main = paste0("Moran's I: ",round(I,3)))
#add line
abline(0,I, col = "red")

  ####


# Calculating Local Indicators of Spatial Association–LISA
# Local Moran
manchester_IMD <- manchester_lsoa["IMDscor"]
lisa <- local_moran(queen_w, manchester_IMD)

#Get the values of the local Moran's I
lms <- lisa_values(gda_lisa = lisa)
lms

#get the pseudo-p values of significance of local Moran computation, the green significance map
pvals <- lisa_pvalues(lisa)
pvals

#get the cluster indicators of local Moran computation, the blue-red map values
cats <- lisa_clusters(lisa, cutoff = 0.05)
cats

#labels
lbls <- lisa_labels(lisa)
lbls

table(cats)

#join labels on to the data
manchester_lsoa$lisaCats <- cats
head(manchester_lsoa)

# access colours and labels
lisa_colors <- lisa_colors(lisa)
lisa_labels <- lisa_labels(lisa)

#draw map v3
tm_shape(manchester_lsoa) +
  tm_polygons("lisaCats", palette = lisa_colors[1:5], labels = lisa_labels[1:5])

#draw map v4
tm_shape(manchester_lsoa) +
  tm_polygons(fill = "lisaCats",
              fill.scale = tm_scale_categorical(values = lisa_colors[1:5], labels = lisa_labels[1:5]))

# Practical 2: Spatial Decision Making

library(sf)
library(tmap)

#read in data
setwd("~/work/confident-spatial-analysis/data-user")
manchester_lsoa <- st_read("lsoa_manchester_age_imd.shp")

#plot data
qtm(manchester_lsoa)
head(manchester_lsoa)

#these are 2011 LSOAs. Need to wait for IMD to update to 2021 LSOAs

#map of imd v3
tm_shape(manchester_lsoa) + 
  tm_polygons("IMDscor", title = "IMD Score", palette = "Blues", style = "jenks") +
  tm_layout(legend.title.size = 0.8)

#map of imd v4
tm_shape(manchester_lsoa) +
  tm_polygons(fill = "IMDscor",
              fill.scale = tm_scale_intervals(values = "blues", n = 6, style = "jenks"),
              fill.legend = tm_legend(title = "IMD Score"))

## public transport services

# read in tramlines
tramlines <- st_read("Metrolink_Lines_Functional.shp")
qtm(tramlines)
head(tramlines)

#read in CSV with tram station locations
stations_CSV <- read.csv("TfGMMetroRailStops.csv", header = TRUE)
head(stations_CSV)
View(stations_CSV)

which(stations_CSV$NETTYP == "M")
stations_CSV[92,] 

#subset out Metrolink stations
metrolink_stations_CSV <- stations_CSV[which(stations_CSV$NETTYP == "M"),]
head(metrolink_stations_CSV)

#make as a sf layer
tram_stations <- st_as_sf(metrolink_stations_CSV, coords = c('GMGRFE', 'GMGRFN'), crs = 27700)
head(tram_stations)

#plot just tram stations v3
tm_shape(tram_stations) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred")

#plot just tram stations v4
tm_shape(tram_stations) +
  tm_dots(points.only = "ifany", fill = "darkred")

#plot tram stations and tram lines, for context v3
tm_shape(tram_stations) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(tramlines) +
  tm_lines(col = "black")

#plot tram stations and tram lines, for context v4
tm_shape(tram_stations) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(tramlines) +
  tm_lines(col = "black")

#plot tram stations and LSOAs v3
tm_shape(tram_stations) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_borders()

#plot tram stations and LSOAs v4
tm_shape(tram_stations) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_borders()

## IMD of Tram Stations Catchment Areas

#spatial join
stations_in_LSOA <- st_join(tram_stations, manchester_lsoa)

#view the data
View(stations_in_LSOA)

#count stations in LSOA
library(dplyr)
stations_in_LSOA_count <- count(as_tibble(stations_in_LSOA), NAME)

View(stations_in_LSOA_count)

which(manchester_lsoa$NAME == "Manchester 054C")

#example of LSOA with one tram station in v3
tm_shape(manchester_lsoa[918,]) +
  tm_borders() +
  tm_shape(tram_stations) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_borders() +
  tm_shape(tramlines) +
  tm_lines(col = "black")

#example of LSOA with one tram station in v4
tm_shape(manchester_lsoa[918,]) +
  tm_borders() +
  tm_shape(tram_stations) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_borders() +
  tm_shape(tramlines) +
  tm_lines(col = "black")

#example of LSOA with more than one tram station in v3
tm_shape(manchester_lsoa[1643,]) +
  tm_borders() +
  tm_shape(tram_stations) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_borders() +
  tm_shape(tramlines) +
  tm_lines(col = "black")

#example of LSOA with more than one tram station in v4
tm_shape(manchester_lsoa[1643,]) +
  tm_borders() +
  tm_shape(tram_stations) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_borders() +
  tm_shape(tramlines) +
  tm_lines(col = "black")

## Showing Most and Least Deprived Stations
stations_in_LSOA <- stations_in_LSOA[order(stations_in_LSOA$IMDscor, decreasing = TRUE), ]

#plot stations v3
tm_shape(stations_in_LSOA) +
  tm_dots(stations_in_LSOA, size = 0.1, shape = 19, col = "darkred")

#plot stations v4
tm_shape(stations_in_LSOA) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred")

#show top / bottom stations v3
tm_shape(stations_in_LSOA) +
  tm_dots(size = 0.1, shape = 19, col = "darkred") +
  tm_shape(stations_in_LSOA[1:10,]) +
  tm_dots(size = 0.1, shape = 19, col = "red") +
  tm_shape(stations_in_LSOA[89:99,]) +
  tm_dots(size = 0.1, shape = 19, col = "blue")

#show top / bottom stations v4
tm_shape(stations_in_LSOA) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(stations_in_LSOA[1:10,]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "red") +
  tm_shape(stations_in_LSOA[89:99,]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "blue")

#most deprived
stations_in_LSOA[1,]
#least deprived
stations_in_LSOA[99,]

#tram stop buffers example
#which index do we need?
which(tram_stations$RSTNAM == "St Werburgh's Road")
which(tram_stations$RSTNAM == "Chorlton")
which(tram_stations$RSTNAM == "Withington")
#map them v3
tm_shape(tram_stations[c(84,19,94),]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa) + 
  tm_polygons("IMDscor", title = "IMD Score", palette = "Blues", style = "jenks") +
  tm_shape(tram_stations[84,]) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "red") +
    tm_shape(tramlines) +
  tm_lines(col = "black")

#map them v4
tm_shape(tram_stations[c(84,19,94),]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_polygons(fill = "IMDscor",
              fill.scale = tm_scale_intervals(values = "blues", style = "jenks"),
              fill.legend = tm_legend(title = "IMD Score")) +
  tm_shape(tram_stations[84,]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "red") +
  tm_shape(tramlines) +
  tm_lines(col = "black")

#plot the tram stations
qtm(tram_stations)
#calculate the buffer (distance is 1200 meters)
tram_stations_1200_buffer <- st_buffer(tram_stations, 1200)
#plot the buffer
qtm(tram_stations_1200_buffer)

which(tram_stations_1200_buffer$RSTNAM == "St Werburgh's Road")
#to add to our earlier example v3
tm_shape(tram_stations_1200_buffer[84,]) +
  tm_polygons(alpha=0) +
  tm_shape(tram_stations[c(84,19,94),]) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(manchester_lsoa) + 
  tm_polygons("IMDscor", title = "IMD Score", palette = "Blues", style = "jenks") +
  tm_shape(tram_stations_1200_buffer[84,]) +
  tm_polygons(alpha=0.3) +
  tm_shape(tramlines) +
  tm_lines(col = "black") +
  tm_shape(tram_stations) +
  tm_dots(tram_stations, size = 0.2, shape = 19, col = "black") +
  tm_shape(tram_stations[84,]) +
  tm_dots(tram_stations, size = 0.2, shape = 19, col = "red")

#to add to our earlier example v4
tm_shape(tram_stations_1200_buffer[84,]) +
  tm_polygons(fill_alpha=0) + 
  tm_shape(tram_stations[c(84,19,94),]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_polygons(fill = "IMDscor",
              fill.scale = tm_scale_intervals(values = "blues", style = "jenks"),
              fill.legend = tm_legend(title = "IMD Score")) +
  tm_shape(tram_stations_1200_buffer[84,]) +
  tm_polygons(fill_alpha=0.3) + 
  tm_shape(tramlines) +
  tm_lines(fill = "black") +
  tm_shape(tram_stations) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "black") + 
  tm_shape(tram_stations[84,]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "red") 


 # buffer experiment v3
tram_stations_buffer <- st_buffer(tram_stations, 600)
tm_shape(tram_stations_buffer[c(84,19,94),]) +
  tm_polygons(alpha=0) +
  tm_shape(tram_stations[c(84,19,94),]) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(manchester_lsoa) + 
  tm_polygons("IMDscor", title = "IMD Score", palette = "Blues", style = "jenks") +
  tm_shape(tram_stations_buffer) +
  tm_polygons(alpha=0.3) +
  tm_shape(tramlines) +
  tm_lines(col = "black") +
  tm_shape(tram_stations) +
  tm_dots(tram_stations, size = 0.2, shape = 19, col = "black") +
  tm_shape(tram_stations[84,]) +
  tm_dots(tram_stations, size = 0.2, shape = 19, col = "red")

# buffer experiment v4
tram_stations_buffer <- st_buffer(tram_stations, 600)
tm_shape(tram_stations_buffer[c(84,19,94),]) +
  tm_polygons(fill_alpha=0) + 
  tm_shape(tram_stations[c(84,19,94),]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_polygons(fill = "IMDscor",
              fill.scale = tm_scale_intervals(values = "blues", style = "jenks"),
              fill.legend = tm_legend(title = "IMD Score")) +
  tm_shape(tram_stations_buffer) +
  tm_polygons(fill_alpha=0.3) + 
  tm_shape(tramlines) +
  tm_lines(fill = "black") +
  tm_shape(tram_stations) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "black") + 
  tm_shape(tram_stations[84,]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "red") 

#buffer
tram_stations_buffer <- st_buffer(tram_stations, 600)

#point in polygon
#convert polygons to points
manchester_lsoa_points <- st_centroid(manchester_lsoa)
#plot points and LSOA v3
tm_shape(manchester_lsoa) +
  tm_borders(col = "red") +
  tm_shape(manchester_lsoa_points) +
  tm_dots(manchester_lsoa_points, size = 0.1, shape = 19, col = "darkred")

#plot points and LSOA v4
tm_shape(manchester_lsoa) +
  tm_borders(col = "red") +
  tm_shape(manchester_lsoa_points) +
  tm_dots(points.only = "ifany", size = 0.3, fill = "darkred") 


head(manchester_lsoa_points)

#map of four station buffers with LSOA points in it v3
tm_shape(tram_stations_buffer[c(84,19,94),]) +
  tm_polygons(alpha=0) +
  tm_shape(tram_stations[c(84,19,94),]) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(manchester_lsoa) + 
  tm_polygons("IMDscor", title = "IMD Score", palette = "Blues", style = "jenks") +
  tm_shape(manchester_lsoa_points) +
  tm_dots(manchester_lsoa_points, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(tram_stations_buffer) +
  tm_polygons(alpha=0.3) +
  tm_shape(tramlines) +
  tm_lines(col = "black") +
  tm_shape(tram_stations) +
  tm_dots(tram_stations, size = 0.2, shape = 19, col = "black") +
  tm_shape(tram_stations[84,]) +
  tm_dots(tram_stations, size = 0.2, shape = 19, col = "red")

#map of four station buffers with LSOA points in it v4
tm_shape(tram_stations_buffer[c(84,19,94),]) +
  tm_polygons(fill_alpha=0) + 
  tm_shape(tram_stations[c(84,19,94),]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa) +
  tm_polygons(fill = "IMDscor",
              fill.scale = tm_scale_intervals(values = "blues", style = "jenks"),
              fill.legend = tm_legend(title = "IMD Score")) +
  tm_shape(manchester_lsoa_points) +
  tm_dots(points.only = "ifany", size = 0.3, fill = "darkred") +
  tm_shape(tram_stations_buffer) +
  tm_polygons(fill_alpha=0.3) + 
  tm_shape(tramlines) +
  tm_lines(fill = "black") +
  tm_shape(tram_stations) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "black") + 
  tm_shape(tram_stations[84,]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "red") 


#simpler map v3
tm_shape(tram_stations_buffer[c(84),]) +
  tm_polygons(alpha=0) +
  tm_shape(manchester_lsoa) + 
  tm_polygons() +
  tm_shape(tram_stations[c(84),]) +
  tm_dots(tram_stations, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(manchester_lsoa_points) +
  tm_dots(manchester_lsoa_points, size = 0.1, shape = 19, col = "darkgreen") +
  tm_shape(tram_stations_buffer[c(84),]) +
  tm_polygons(alpha=0)

#simpler map v4
tm_shape(tram_stations_buffer[c(84),]) +
  tm_polygons(fill_alpha=0) +
  tm_shape(manchester_lsoa) + 
  tm_polygons() + 
  tm_shape(tram_stations[c(84),]) +
  tm_dots(points.only = "ifany", size = 0.4, fill = "darkred") +
  tm_shape(manchester_lsoa_points) +
  tm_dots(points.only = "ifany", size = 0.3, fill = "darkgreen") +
  tm_shape(tram_stations_buffer) +
  tm_polygons(fill_alpha=0)

#st_join is a left join
#join each station to the LSOAs within the buffer
tram_stations_IMD <- st_join(tram_stations_buffer, manchester_lsoa_points)
View(tram_stations_IMD)
     
#group by Station, take average IMDscore.
station_LSOA_IMD <- tram_stations_IMD %>% group_by(RSTNAM) %>% summarise(mean(IMDscor))
#view the average IMD score for each station
View(station_LSOA_IMD)
qtm(station_LSOA_IMD)

#still buffers (of each station), so convert to points (centroids)
station_LSOA_IMD_pt <- st_centroid(station_LSOA_IMD)
qtm(station_LSOA_IMD_pt)

#map with IMD score v3
tm_shape(station_LSOA_IMD) +
  tm_polygons("mean(IMDscor)", title = "IMD Score", palette = "Blues", style = "jenks") +
  tm_shape(station_LSOA_IMD_pt) +
  tm_dots(station_LSOA_IMD_pt, size = 0.1, shape = 19, col = "darkred")

#map with IMD score v4
tm_shape(station_LSOA_IMD) +
  tm_polygons(fill = "mean(IMDscor)",
              fill.scale = tm_scale_intervals(values = "blues", style = "jenks"),
              fill.legend = tm_legend(title = "IMD Score")) +
  tm_shape(station_LSOA_IMD_pt) +
  tm_dots(points.only = "ifany", size = 0.2, fill = "darkred")

#reorder, most deprived at the top
station_LSOA_IMD_pt_ordered <- station_LSOA_IMD_pt[order(station_LSOA_IMD_pt$`mean(IMDscor)`, 
                                                         decreasing = TRUE), ]

head(station_LSOA_IMD_pt_ordered)

#plot map of average IMD score by station (top 10 in Red, bottom 10 in Blue) v3
tm_shape(station_LSOA_IMD) +
  tm_polygons("mean(IMDscor)", title = "IMD Score", palette = "Blues", style = "jenks") +
  tm_shape(station_LSOA_IMD_pt_ordered) +
  tm_dots(station_LSOA_IMD_pt_ordered, size = 0.1, shape = 19, col = "darkred") +
  tm_shape(station_LSOA_IMD_pt_ordered[1:10,]) +
  tm_dots(station_LSOA_IMD_pt_ordered[1:10,], size = 0.1, shape = 19, col = "red") +
  tm_shape(station_LSOA_IMD_pt_ordered[89:99,]) +
  tm_dots(station_LSOA_IMD_pt_ordered[89:99,], size = 0.1, shape = 19, col = "blue") 

#plot map of average IMD score by station (top 10 in Red, bottom 10 in Blue) v4
tm_shape(station_LSOA_IMD) +
  tm_polygons(fill = "mean(IMDscor)",
              fill.scale = tm_scale_intervals(values = "blues", style = "jenks"),
              fill.legend = tm_legend(title = "IMD Score")) +
  tm_shape(station_LSOA_IMD_pt_ordered) +
  tm_dots(points.only = "ifany", size = 0.2, fill = "darkred") +
  tm_shape(station_LSOA_IMD_pt_ordered[1:10,]) +
  tm_dots(points.only = "ifany", size = 0.2, fill = "red") +
  tm_shape(station_LSOA_IMD_pt_ordered[89:99,]) +
  tm_dots(points.only = "ifany", size = 0.2, fill = "blue")

## Polygon Polygon Overlay (optional exercise)
# see st_intersection_code.R
