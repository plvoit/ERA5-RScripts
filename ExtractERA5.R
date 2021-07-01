# This script takes the files provided by DownloadERA5.py and processes them into a csv-file
# Just set the station name for the station to be processed
# The resulting csv-file is the input for the script TimeseriesAnalysis.R
# Copyright (C) 2020 Paul Voit

rm(list = ls())
setwd("~/Workspace/GFZ/ERA5-PressureLevels")

library(ncdf4)
library(raster)
library(rgdal)
library(foreach)
library(doParallel)
library(PaulsPack)

#station to extract
# PUT STATION NAME HERE
station_name <- "THUL"


#"10",
vars <- c('t','r','q')
p_levels <-  c("10","100","250","500","750","1000")

# load shapefile of stations for extraction
stations <- readOGR("GIS/Stations.shp")

# function for data extraction
extract_ncdf <- function(raster){
  r.vals <- raster::extract(raster, station)
  r.mean <- sapply(r.vals, FUN=mean)
  return(r.mean)
}

#create dataframe to store results for one station in
#check how the timestamp is recorded in these NetCDF-Files
#ncfile <- nc_open(all_files[[1]])
#print(ncfile)
##you can see: units: hours since 1900-01-01 00:00:0.0

#take the timeseries of one pressure level to extract time vector
all_files <- dir("Data", full.names = TRUE, pattern = paste0(p_levels[1],'.nc' ))

### find the right dates, dates in the netcdf files are given by hours since 01.01.1800
time_vectors <-  list()
for (i in 1:length(all_files)){
  ncfile <- nc_open(all_files[[i]])
  time_string <- ncvar_get(ncfile, "time")
  time_string <- as.POSIXct(time_string*3600,origin = "1900-01-01" ) # conversion found on stackoverflow, seems to work
  time_vectors[[i]] <- time_string
}

# Put all the vectors into one
time_joined <- Reduce(c,time_vectors)

#create dataframe with Date column. All the results from extraction will be
# cbinded to this dataframe
DF <- data.frame("Date" = time_joined)

ptm_all <- proc.time() 

for( i in 1:length(p_levels)){
## create a list of all netcdf files in folder (one for each year). Select pressure level
  all_files <- dir("Data", full.names = TRUE, pattern = paste0(p_levels[i],'.nc' ))
  all_files_short <- dir("Data",pattern = paste0(p_levels[i],'.nc' ))

  #file <- nc_open(all_files[1])
  #print(file)

  ## select right variable here, probably with varname
  ## stack all the netcdf files into one raster stack. One raster per timestep (day)
  for (j in 1:length(vars)){
    ptm <- proc.time() 
    ncdf_stack <- stack(all_files, varname = vars[j])
    proc.time()-ptm

    #subset shape for just one station
    station <- stations[stations@data$Station == station_name,]
    

    # extract raster values at station location
    # timestep. Create dataframe with one column for every feature
    # Using parallelization saves a lot of time 

    #ptm <- proc.time()           #start timer for code block
    registerDoParallel(3)
    result_list <- foreach(dat=as.list(ncdf_stack)) %dopar% extract_ncdf(dat)   # this is the parallelization bit
    stopImplicitCluster()
    #proc.time()-ptm                #end timer for code block

    ## bind all the rows together
    DF_mean <- as.data.frame(do.call(rbind, result_list))

    colnames(DF_mean) <- paste0(station@data$Station,'_',p_levels[i],'_',vars[j])
    DF <- cbind(DF,DF_mean)
  } #var loop
} # pressure level loop
  
proc.time()-ptm_all  

#save for later use
write.csv(DF, file = paste0(station_name,".txt"), row.names = FALSE)



