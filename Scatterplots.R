rm(list = ls())
setwd("~/Workspace/GFZ/ERA5-PressureLevels")

library(PaulsPack)
library(zoo)

stations <-  c("AATB", "ATHN", "INVK", "JUNG",  "NAIN", "NANM", "SOPO", "THUL")

levels <- c("10", "100", "1000")

rollmean <- TRUE
window_size <- 31 

for (i in 1:length(levels)){
  par(mfrow=c(2,2))
  for (j in 1: length(stations)){
    # Station to be processed
    station_name = stations[j]
    
    #load ERA5 data
    Station <- read.csv(paste0(station_name,".txt"))
    Station$Date <- as.POSIXct(Station$Date)
    
    #load CosmicRay-Data
    CR <- read.csv("Station_JUNG_ATHENS_NEWK_OULU_andOthers_01012011-01012021.txt", sep = ";", skip = 35, header = T, na.strings = " null")
    CR$Date <- as.POSIXct(CR$Date)
    
    # there are some weird white spaces in some cells. Delete
    CR[,2:ncol(CR)] <- lapply(CR[,2:ncol(CR)], function(x) as.numeric(gsub(" ","",x)))
    
    
    #add extra line (copy first line) for aggregation starting at 00:00
    Station <- rbind(Station[1,],Station)
    Station[1,1] <- as.POSIXct("2011-01-01 00:00:00")
    Station$Date <- as.POSIXct(Station$Date)
    
    # aggregate Timeseries to every three hours (mean)
    # !! careful, CRNS data with timestamp 09:00 descibres mean from 09:00-12:00, for this reason set right = F
    
    Station <- aggregate_by_time(Station,c(2:ncol(Station)),"3 hour",mean, right = F)
    
    ## aggregate to days
    Station <-  aggregate_by_time(Station,c(2:ncol(Station)),"1 day",mean, right = T)
    CR <-  aggregate_by_time(CR,c(2:ncol(CR)),"1 day",mean, right = T)
    CR <-  CR[-nrow(CR),]
    # same length for both dataframes
    CR <- CR[CR$Date <= max(Station$Date),]
    
    if(rollmean){
      dummy <- rollmean(CR[station_name],window_size)
      # because of the window size result of row mean is shorter. Station has to be adjusted
      Station <- Station[-c(seq(1,0.5*(window_size-1),1)),]
      Station <- Station[-c(seq((nrow(Station) + 1)-0.5*(window_size-1),nrow(Station),1)),]
      df  <- cbind(Station, dummy)
      
    }

    if(!rollmean){
    # join CRNS and ERA5-data
    df  <- cbind(Station, CR[station_name])
    }
    
    #remove NAs
    df[,c(2:ncol(df))] <- na.approx(df[,c(2:ncol(df))] )
    #summary(df)
    #theres some NA's left at the end. for now just fill up with mean.. The last column is always the CRNS station
    df[is.na(df[,ncol(df)]),ncol(df)] <- mean(df[,ncol(df)],na.rm = T)
    
    # rename last column 
    names(df)[ncol(df)] <- paste0(station_name,"_CRNS")
    
    
    # Intensitäten zu plotten (geteilt durch Mittelwert)
    ERA5t <- df[,grep(paste0(station_name, "_", levels[i],"_t"), colnames(df))]/mean(df[,grep(paste0(station_name, "_", levels[i],"_t"), colnames(df))])
    CRNS <- df[,grep(paste0(station_name, "_CRNS"), colnames(df))]/ mean(df[,grep(paste0(station_name, "_CRNS"), colnames(df))])
    
    reg <-  lm(ERA5t~CRNS)
    
    Rsquare <- summary(reg)$r.squared
    
    mylabel = bquote(italic(R)^2 == .(round(Rsquare, 3)))
    
    plot(ERA5t~CRNS, ylab = "dT intensity", xlab = "CRNS intensity",main = paste0(station_name, "_", levels[i]), cex.main = 0.8)
    text(min(CRNS)+0.02,max(ERA5t) - 0.02, labels = mylabel)
    
    }
}


