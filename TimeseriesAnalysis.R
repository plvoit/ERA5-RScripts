rm(list = ls())
setwd("~/Workspace/GFZ/ERA5-PressureLevels")

#load ERA5 data
ATHN <- read.csv("~/Workspace/GFZ/ERA5-PressureLevels/ATHN.txt")
ATHN$Date <- as.POSIXct(ATHN$Date)

#load CosmicRay-Data
CR <- read.csv("Station_JUNG_ATHENS_NEWK_OULU_andOthers_01012011-01012021.txt", sep = ";", skip = 35, header = T, na.strings = " null")
CR$Date <- as.POSIXct(CR$Date)

# there are some weird white spaces in some cells. Delete
CR[,2:ncol(CR)] <- lapply(CR[,2:ncol(CR)], function(x) as.numeric(gsub(" ","",x)))


#plot(ATHN$ATHN_100_t~ATHN$Date, type = "l")
#plot(CR$ATHN~CR$Date, type = "l")

#add extra line (copy first line) for aggregation starting at 00:00
ATHN <- rbind(ATHN[1,],ATHN)
ATHN[1,1] <- as.POSIXct("2011-01-01 00:00:00")
ATHN$Date <- as.POSIXct(ATHN$Date)

# aggregate Timeseries to every three hours (mean)
# !! careful, CRNS data with timestamp 09:00 descibres mean from 09:00-12:00, for this reason set right = F
library(PaulsPack)
ATHN <- aggregate_by_time(ATHN,c(2:ncol(ATHN)),"3 hour",mean, right = F)

#aggregate_by_time changes type of date to "factor" and colname to "Group1. Should be fixed
names(ATHN)[1] <- "Date"
ATHN$Date <- as.POSIXct(ATHN$Date)

# same length for both dataframes
CR <- CR[CR$Date <= max(ATHN$Date)]

## moving window cross correlation

library(astrochron)
mwCor(dat,cols=NULL,win=NULL,conv=1,cormethod=1,output=T,pl=1,genplot=T,verbose=T)
