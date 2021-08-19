rm(list = ls())
setwd("~/Workspace/GFZ/ERA5Global")

library(raster)
library(rgdal)
library(stars)
library(ncdf4)

cor <- read.csv("~/Workspace/GFZ/ERA5Global/corr_2011.csv")

#world shape
world <- readOGR("coastline/ne_110m_coastline.shp")

#shapefile for CRNS stations
crns <- readOGR("../ERA5-PressureLevels/GIS/Stations.shp")
#select just station Jungfrauenjoch
crns <- crns[crns@data$Station == "JUNG",]

# identify the maximum (absolute correlation)
which.max(abs(cor))
test <- apply(cor,2,function(x)  which.max(x))
abs_cor <- abs(cor)
max = which(abs_cor == max(abs_cor), arr.ind = TRUE) 
max = max[1,]
cor[max]

#take the timeseries of one pressure level to extract time vector
all_files <- dir("Data", full.names = TRUE, pattern = '.nc' )

#load ncdf to extract timeseries at location of maximum correlation
ncdf_stack <- stack(all_files, varname = "ps")

max_cor_ts <- raster::extract(ncdf_stack,max)
max_cor_ts <- unname(max_cor_ts[1,])

# making a yearly cube out of the ncdf files is not possible with local computer
# cube is computed at server and the result is loaded here
cube <- read_stars("cube.tif")

# Co correlation to identified timeseries
cor_raster <- st_apply(cube, 1:2, function(x) cor(x,station$Count, method = "spearman"))

#save cor_raster as tif, load with raster package

png(file = "cocorStep1_2011JUNG.png", bg = "white", width = 2480, height = 1748, res = 300)
plot(cor_raster, main = "CoCorrelation surface pressure ~ CRNS Jungfrauenjoch 2012")
plot(world,add = T)
plot(crns, add = TRUE, col = "red", cex = 1, lwd = 1, pch = 4)
dev.off()