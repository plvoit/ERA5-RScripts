#this script is just a messy collection of stars, netcdf and raster handling
# there seems to be a bug with plotting stars objects as they have the wrong projection
# saving an object as .tif and opening it with raster() works fine
# Copyright (C) 2021 Paul Voit
### this script doesn't work on my local PC due to limited RAM
## CorrGlobalServer.R runs on the HPC server
rm(list = ls())
setwd("~/Workspace/GFZ/ERA5Global")

library(ncdf4)
library(raster)
library(rgdal)
library(foreach)
library(doParallel)
library(stars)
library(RNetCDF)

#take the timeseries of one pressure level to extract time vector
all_files <- dir("Data", full.names = TRUE, pattern = '.nc' )

#load station data
station <- read.table("~/Workspace/GFZ/ERA5Global/Station_JUNG_01012010-01012021_DailyResolution.txt", header=F, skip = 25, check.names = F, sep = ";")
names(station) <- c("Date","Count")
station$Date <- as.POSIXct(station$Date, tz = "UTC")

station <- station[station$Date >= "2011-01-01" & station$Date < "2012-01-01",]

###get projection from netcdf
nc_file <- stack(all_files[1])
coordsys <- crs(nc_file[[1]])

plot(nc_file[[1]])
plot(world, add = T)
plot(crns, add = T)

test <- stars::read_stars(all_files[1])
test <- st_transform(test,st_crs(4326))
plot(test[,,,1])
plot(world, add = T)

file_list <- list()
for (i in 1:length(all_files)){
  dummy <- stars::read_ncdf(all_files[i])
  file_list[[i]] <- dummy
}

# from this part on the local RAM is not enough
part1 <- Reduce(c, file_list[c(1:6)])
part2 <- Reduce(c, file_list[c(7:12)])

station <- station[1:181,]

ptm <- proc.time()  
test <- st_apply(part1, 1:2, function(x) cor(x,station$Count, method = "spearman"))
proc.time()-ptm

plot(test, )

#test <- st_transform(test,st_crs(4326))

# shapefile for continent outlines
world <- readOGR("coastline/ne_110m_coastline.shp")

#shapefile for CRNS stations
crns <- readOGR("../ERA5-PressureLevels/GIS/Stations.shp")

plot(test)

crs(test) <- crs(world)
crs(world)

test

plot(test[,,,1])
plot(crns, add = T, col = "red")
plot(world,add = T, col = "red")
plot(test[,,,1], add = T)
newTest <- st_as_sf(test)
plot(newTest)
###check how this star apply works
cor(part1$ps[1,1,],station$Count, method = "spearman")
cor(part1$ps[1,2,],station$Count, method = "spearman")
cor(part1$ps[1,3,],station$Count, method = "spearman")

plot(dummy$ps[[1]])

write.csv(test$ps,"TestPart1_2011.csv", sep = "\t", row.names = F)

r <- as.raster(test)
write_stars(test,"cor_2011.tif")

r <- as.raster(test)

plot(dummy)
plot(dummy[,,,1])
############# OLD
#### This approach was to slow

rm(list = ls())
setwd("~/Workspace/GFZ/ERA5Global")

library(ncdf4)
library(raster)
library(rgdal)
library(foreach)
library(doParallel)
library(stars)
library(RNetCDF)
#take the timeseries of one pressure level to extract time vector
all_files <- dir("Data", full.names = TRUE, pattern = '.nc' )

# # get info from netcdf about variable names, date format etc..
ncfile <- nc_open(all_files[[1]])
print(ncfile)

#load station data
station <- read.table("~/Workspace/GFZ/ERA5Global/Station_JUNG_01012010-01012021_DailyResolution.txt", header=F, skip = 25, check.names = F, sep = ";")
names(station) <- c("Date","Count")
station$Date <- as.POSIXct(station$Date, tz = "UTC")

station <- station[station$Date >= "2011-01-01" & station$Date < "2013-01-01",]

ncdf_stack <- stack(all_files, varname = "ps")

# Raster with same dimension to put the correlation values ino
cor_raster <- ncdf_stack[[1]]

# get correlation to station for each cell
for (rows in 1:ncdf_stack@nrows){
  for (cols in 1:ncdf_stack@ncols){
    series <- raster::extract(ncdf_stack, c(rows,cols))
    series <- unname(series[1,])
    cor_raster[rows,cols] <-  cor(station$Count, series, method="spearman")
  }
}
#################
cor <- read_stars("cor_2011.tif")
plot(cor, nbreaks = 100, col = )

ncfile <- stack(ncfile)
cor <- st_transform(cor, st_crs(4326))
plot(cor)
