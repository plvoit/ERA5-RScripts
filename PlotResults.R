# Copyright (C) 2021 Paul Voit
# Extracting values from netCDF is much faster with stars than with raster package
# plotting stars objects is a bit tricky though... the projection seems to be always off
# saving a stars object as tif-raster and then plotting loading it with the raster package seems to work

rm(list = ls())
setwd("~/Workspace/GFZ/ERA5Global")

library(raster)
library(rgdal)
library(stars)

##open correlation raster
cor <- raster("cor_2011.tif")
#warning, data is flipped, flip back
cor <- flip(cor,"y")

# shapefile for continent outlines
world <- readOGR("coastline/ne_110m_coastline.shp")

#shapefile for CRNS stations
crns <- readOGR("../ERA5-PressureLevels/GIS/Stations.shp")
#select just station Jungfrauenjoch
crns <- crns[crns@data$Station == "JUNG",]

png(file = "cor_2011JUNG.png", bg = "white", width = 2480, height = 1748, res = 300)
plot(cor, main = "Correlation surface pressure ~ CRNS Jungfrauenjoch 2011")
plot(world,add = T)
plot(Jung, add = TRUE, col = "red", cex = 1, lwd = 1, pch = 4)
dev.off()