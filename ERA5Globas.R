# This script takes the files provided by DownloadERA5.py and processes them into a csv-file
# Just set the station name for the station to be processed
# The resulting csv-file is the input for the script TimeseriesAnalysis.R
# Copyright (C) 2020 Paul Voit

rm(list = ls())
setwd("~/Workspace/GFZ/ERA5Global")

library(ncdf4)
library(raster)
library(rgdal)
library(foreach)
library(doParallel)
library(PaulsPack)
library(stars)


#take the timeseries of one pressure level to extract time vector
all_files <- dir("Data", full.names = TRUE, pattern = '.nc' )

ncfile <- nc_open(all_files[[1]])
print(ncfile)


test <- read_ncdf(all_files[[1]],var='sp')
          

