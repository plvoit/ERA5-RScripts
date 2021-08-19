rm(list = ls())
setwd("~/Workspace/GFZ/ERA5Global")

library(raster)
library(ncdf4)
library(sf)
library(rgdal)

# shapefile for continent outlines
world <- readOGR("coastline/ne_110m_coastline.shp")

corr <- read.csv("~/Workspace/GFZ/ERA5Global/corr_2011.csv")
corr <- round(corr,2)

# load one raster as blueprint for correlation raster

all_files <- dir("Data", full.names = TRUE, pattern = '.nc' )
ncdf_stack <- stack(all_files[1], varname = "ps")

r <- ncdf_stack[[1]]
getValues(r,720)

####Compare with stars object
test <- stars::read_ncdf(all_files[1], var="ps")
test$ps[1,1,1]
test$ps[1,2,1]


#
nc_file <- nc_open(all_files[1])
ps <- ncvar_get(nc_file,"ps")
ps <- ps[,,1]
ps <- t(as.matrix(ps))

head(ps)
plot(nc_file[[1]])
crs(r)
plot(r)

heatmap(as.matrix(corr))

##rotate matrix
rotate <- function(x) t(apply(x, 2, rev))

#new raster from csv/matrix
corr <- as.matrix(corr)
# the resulting matrix from stars_apply is turned 90 degrees, transform
corr <- t(corr)
rnew <- raster(corr, xmn=-180.125, xmx=179.875, ymn=-90.125, ymx=90.125)
crs(rnew) <- crs(r)



plot(rnew)
plot(world, add=T)


##Test
test <- matrix(c(1,2,3,1,2,3,1,2,3,1,2,3), nrow=3, ncol=4)
a <-  apply(test,1:2,function(x) 2*x)

test
a
