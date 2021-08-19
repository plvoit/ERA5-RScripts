# Copyright (C) 2020 Paul Voit
# script to run on a server with enough RAM
# Joining of monthly NetCDF to one yearly cube then calculation the correlation
# of each raster cell to the station data from Jungfrauenjoch

rm(list = ls())

library(stars)

#take the timeseries of one pressure level to extract time vector
all_files <- dir("Data", full.names = TRUE, pattern = '.nc' )

#load station data
station <- read.table("Station_JUNG_01012010-01012021_DailyResolution.txt", header=F, skip = 25, check.names = F, sep = ";")
names(station) <- c("Date","Count")
station$Date <- as.POSIXct(station$Date, tz = "UTC")
station <- station[station$Date >= "2011-01-01" & station$Date < "2012-01-01",]


file_list <- list()
for (i in 1:length(all_files)){
  dummy <- stars::read_ncdf(all_files[i])
  file_list[[i]] <- dummy
}

cube <- Reduce(c,file_list)

cor_raster <- st_apply(part1, 1:2, function(x) cor(x,station$Count, method = "spearman"))

write.csv(test$ps,"corr_2011.csv", sep = "\t", row.names = F)
