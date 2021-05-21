# Copyright (C) 2020 Paul Voit


rm(list = ls())
setwd("~/Workspace/GFZ/ERA5")

library(ncdf4)
library(RNetCDF)
library(raster)
library(rgdal)
library(foreach)
library(doParallel)

inp <- nc_open('AATB_specific_humidity_250.nc')
str(inp)

variables = names(inp[['var']])

# geht auch, aber dann?
raster  <- raster('AATB_specific_humidity_250.nc')
image(raster)


brick <- raster::stack(inp)
print(inp)

# get longitude and latitude
lon <- ncvar_get(inp,"longitude")
nlon <- dim(lon)
head(lon)

lat <- ncvar_get(inp,"latitude")
nlat <- dim(lat)
head(lat)

time <- ncvar_get(inp,"time")

tmp_array <- ncvar_get(inp,'q')
image(lon,lat,tmp_array[,,2,1])
image(tmp_array)
b <- stack(inp)

# Open the shapefile, it has all south america
#shp <- readOGR('./South_America.shp')

#Extracting the variables we want
xlon <- ncvar_get(inp, varid = 'longitude')
xlat <-  ncvar_get(inp, varid = 'latitude')
no   <- ncvar_get(inp, varid = 'q')  # This are the emissions

# Close the netCDF files
nc_close(inp)


# Retrieving only the sequence of lat and lon from xlat and xlong matrix
lon <- xlon[, 1]
lat <-  xlat[1, ]
no.ph <- no[, , 10]  # I only want to plot the rush hour, 7 am in local time.

# Here is the plot:
image.plot(lon, lat, no.ph,
           main = "NO emissions at 07:00",
           xlab = "Longitude",
           ylab = "Latitude",
           legend.lab = "mol/km^2/hr",
           legend.line = 2.5,
           col = rev(magma(200)))  # To get the higher emission values darker we invert it
plot(shp, add = T, border = "Black")  # To add the shapefile and paint the border 'Black'
mtext("South East Brazil")  # To put a sub-title