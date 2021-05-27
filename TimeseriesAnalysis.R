rm(list = ls())
setwd("~/Workspace/GFZ/ERA5-PressureLevels")
library(PaulsPack)
library(zoo)
library(tidyr)
library(dplyr)
library(ggplot2)



station_name = "ATHN"

#load ERA5 data
Station <- read.csv(paste0(station_name,".txt"))
Station$Date <- as.POSIXct(Station$Date)

#load CosmicRay-Data
CR <- read.csv("Station_JUNG_ATHENS_NEWK_OULU_andOthers_01012011-01012021.txt", sep = ";", skip = 35, header = T, na.strings = " null")
CR$Date <- as.POSIXct(CR$Date)

# there are some weird white spaces in some cells. Delete
CR[,2:ncol(CR)] <- lapply(CR[,2:ncol(CR)], function(x) as.numeric(gsub(" ","",x)))


#plot(Station$Station_100_t~Station$Date, type = "l")
#plot(CR$Station~CR$Date, type = "l")

#add extra line (copy first line) for aggregation starting at 00:00
Station <- rbind(Station[1,],Station)
Station[1,1] <- as.POSIXct("2011-01-01 00:00:00")
Station$Date <- as.POSIXct(Station$Date)

# aggregate Timeseries to every three hours (mean)
# !! careful, CRNS data with timestamp 09:00 descibres mean from 09:00-12:00, for this reason set right = F

Station <- aggregate_by_time(Station,c(2:ncol(Station)),"3 hour",mean, right = F)

# same length for both dataframes
CR <- CR[CR$Date <= max(Station$Date),]

## moving window cross correlation


# join CRNS and ERA5-data
df  <- cbind(Station, CR[station_name])

#remove NAs
df[,c(2:ncol(df))] <- na.approx(df[,c(2:ncol(df))] )
summary(df)
#theres some NA's left at the end. for now just fill up with mean.. The last column is always the CRNS station
df[is.na(df[,ncol(df)]),ncol(df)] <- mean(df[,ncol(df)],na.rm = T)

# rename last column 
names(df)[ncol(df)] <- paste0(station_name,"_CRNS")

## make one dataframe with the correlation results
results_cor <- list()
## moving window cross correlation
#doesn't work when the dataframe contains a POSix element. So it has to be taken out
for (i in 2:(ncol(df)-1)){
  dummy = as.data.frame(cbind(df[,i],df[,ncol(df)]))
  results_cor[[i-1]] <- rollapply(dummy,width=30, function(x) cor(x[,1],x[,2], method = "spearman"), by.column=FALSE)
  results_cor[[i-1]] <- as.data.frame(results_cor[[i-1]])
  names(results_cor[[i-1]])[1] <- names(Station)[i]
}

# list to dataframe
results_cor  <- do.call(cbind, results_cor)
results_cor$Date <- CR$Date[15:(nrow(CR)-15)]


#There should be a dataframe with all the variables for ATHENS, Locations and date (timestep). The format for this is a bit weird.
# time step and Level need to be factors, rest numeric. Three columns: Timestep, Location, value

#results_cor$Timestep3Hour <- as.factor(c(1:nrow(results_cor)))
plot_df <- gather(results_cor, key="state",value="value", -Date) #gather is from tidyR. Some kind of aggregation. Whats the baseR equivalent??
names(plot_df) <- c("Date", "Level","Correlation")
plot_df <- plot_df[order(plot_df$Date),]
plot_df$Level <- as.factor(plot_df$Level)
row.names(plot_df) <- NULL

## plot heatmap
p <- ggplot(plot_df, aes(x=Date, y=Level, fill=Correlation))+
  scale_fill_viridis_c() +
  #scale_x_continuous(name="Year", limits=c(0, 2020)) +
  geom_tile() 
 #+ scale_color_gradient(low="blue", high="red")
print(p)

#plot correlation for each level
for(i in 1:(ncol(results_cor)-1)){
  plot(results_cor[,i]~results_cor$Date, type = "l", main = paste0("Corr. CRNS ~ ", colnames(results_cor)[i]))
}

summary(results_cor)

##detrend??


## Wavelet
# install.packages("biwavelet")
library(biwavelet)

# date to timestep
CR$Timestep <- c(1:nrow(CR))
Station$Timestep <- c(1:nrow(Station))

#remove missing values from CR
CR[,2:ncol(CR)] <- na.approx(CR[,2:ncol(CR)])
CR[is.na(CR$Station),2] <- mean(CR$Station, na.rm = T)
summary(CR)

# Cross Wavelet
wv.cx <- xwt(CR[,c(10,2)],Station[,c(17,2)],mother = "morlet")
plot(wv.cx)

# Wavelet coherence
wv.coh <- wtc(CR[c(1:2000),c(10,2)],Station[c(1:2000),c(17,2)],mother = "morlet")
plot(wv.coh,plot.cb=F, plot.phase=T,main="CRNS vs. t_100")

save.image("Wavelet.RData")
load("Wavelet.RData")


