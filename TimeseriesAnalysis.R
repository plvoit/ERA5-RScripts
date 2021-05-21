rm(list = ls())
setwd("~/Workspace/GFZ/ERA5")

#load ERA5 data
ATHN <- read.csv("~/Workspace/GFZ/ERA5/ATHN.txt")
ATHN$Date <- as.POSIXct(ATHN$Date)

#load CosmicRay-Data
CR <- read.csv("Station_JUNG_ATHENS_NEWK_OULU_andOthers_01012011-01012021.txt", sep = ";", skip = 35, header = T, na.strings = " null")
CR$Date <- as.POSIXct(CR$Date)

# there are some weird white spaces in some cells. Delete
CR[,2:ncol(CR)] <- lapply(CR[,2:ncol(CR)], function(x) as.numeric(gsub(" ","",x)))


plot(ATHN$ATHN_100_t~ATHN$Date, type = "l")
plot(CR$ATHN~CR$Date, type = "l")


## moving window cross correlation

library(astrochron)
mwCor(dat,cols=NULL,win=NULL,conv=1,cormethod=1,output=T,pl=1,genplot=T,verbose=T)
