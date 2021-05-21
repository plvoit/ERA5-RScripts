## This process helps a lot to speed up the data extraction.
rm(list = ls())
setwd("~/Workspace/GFZ/ERA5")

library(ncdf4)

nc <- nc_open('Athens_100.nc')
nc <- nc_open('Athens1121_100.nc')
# this one has hours since 1900 as timestamp

time_string <- ncvar_get(nc, "time")
#time_string <- as.POSIXct(time_string*24,origin = "1900-01-01" )
head(time_string)

#to seconds
#time_string <- time_string * 60 *60
time_string <- as.POSIXct(time_string * 3600,origin = "1900-01-01" )
head(time_string)
tail(time_string)
print(nc)

#convert seconds since 1970 to POSIX
mydates = structure(time_string,class=c('POSIXt','POSIXct'))
head(mydates)
