# This script generates correlation heatmaps (rolling window spearman correlation, width = 31 days)
# histograms and Wavelet coherence plots (Morlet wavelet) and saves them in the workspace

rm(list = ls())
setwd("~/Workspace/GFZ/ERA5-PressureLevels")
library(PaulsPack)
library(zoo)
library(tidyr)
library(dplyr)
library(ggplot2)
library(zyp)
library(Kendall)
library(biwavelet)

# Station to be processed
station_name = "THUL"

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

## aggregate to days
Station <-  aggregate_by_time(Station,c(2:ncol(Station)),"1 day",mean, right = T)
CR <-  aggregate_by_time(CR,c(2:ncol(CR)),"1 day",mean, right = T)
CR <-  CR[-nrow(CR),]
# same length for both dataframes
CR <- CR[CR$Date <= max(Station$Date),]

# join CRNS and ERA5-data
df  <- cbind(Station, CR[station_name])

#remove NAs
df[,c(2:ncol(df))] <- na.approx(df[,c(2:ncol(df))] )
#summary(df)
#theres some NA's left at the end. for now just fill up with mean.. The last column is always the CRNS station
df[is.na(df[,ncol(df)]),ncol(df)] <- mean(df[,ncol(df)],na.rm = T)

# rename last column 
names(df)[ncol(df)] <- paste0(station_name,"_CRNS")

# ##Check for trend
# sig <- c()
# for (i in 2:(ncol(df)-1)){
# dummy <- MannKendall(df[,i])
# sig[i-1] <- dummy$sl
# }
# 
# #Sen slope
# ##ADD timestep variable but this might mess with later operations. delete again
# df$timestep <- c(1:nrow(df))
# zyp.sen(ATHN_100_t ~ timestep, df)

## make one dataframe with the correlation results
results_cor <- list()
## moving window cross correlation
#doesn't work when the dataframe contains a POSix element. So it has to be taken out
for (i in 2:(ncol(df)-1)){
  dummy = as.data.frame(cbind(df[,i],df[,ncol(df)]))
  results_cor[[i-1]] <- rollapply(dummy,width=31, function(x) cor(x[,1],x[,2], method = "spearman"), by.column=FALSE)
  results_cor[[i-1]] <- as.data.frame(results_cor[[i-1]])
  names(results_cor[[i-1]])[1] <- names(Station)[i]
}

# list to dataframe
results_cor  <- do.call(cbind, results_cor)
results_cor$Date <- CR$Date[15:(nrow(CR)-16)] # evt. automatisieren


#There should be a dataframe with all the variables for ATHENS, Locations and date (timestep). The format for this is a bit weird.
# time step and Level need to be factors, rest numeric. Three columns: Timestep, Location, value

#results_cor$Timestep3Hour <- as.factor(c(1:nrow(results_cor)))
plot_df <- gather(results_cor, key="state",value="value", -Date) #gather is from tidyR. Some kind of aggregation. Whats the baseR equivalent??
names(plot_df) <- c("Date", "Level","Correlation")
plot_df <- plot_df[order(plot_df$Date),]
plot_df$Level <- as.factor(plot_df$Level)
row.names(plot_df) <- NULL


#create plots for all the variables
# 3 heatmaps für t,q,r
variables <-c("t","q","r")

for (i in 1:length(variables)){
  # select variable
  plot_df_var <- plot_df[grep(paste0(variables[i]),plot_df$Level),]
  plot_df_var$Level <- ordered(plot_df_var$Level, levels = c(paste0(station_name,"_1000","_",variables[i]),paste0(station_name,"_750","_",variables[i]),
                                                             paste0(station_name,"_500","_",variables[i]),paste0(station_name,"_250","_",variables[i]),
                                                             paste0(station_name,"_100","_",variables[i]),paste0(station_name,"_10","_",variables[i])))
  
  png(file = paste0(station_name,"_", variables[i],"_correlation_heatmap",".png"), bg = "white", width = 2480, height = 1748, res = 300)
  p <- ggplot(plot_df_var, aes(x=Date, y=Level, fill=Correlation))+
    scale_fill_viridis_c() +
    geom_tile() +
    labs(title = paste0(station_name,"_", variables[i])) +
    ggtitle(paste0("Correlation CRNS ~ ",station_name,"_", variables[i] ))
  print(p)
  dev.off()
}
                                                  

# #plot correlation for each level
# for(i in 1:(ncol(results_cor)-1)){
#   plot(results_cor[,i]~results_cor$Date, type = "l", main = paste0("Corr. CRNS ~ ", colnames(results_cor)[i]))
# }

# summary(results_cor)
# length(results_cor$ATHN_1000_t[results_cor$ATHN_1000_t < 0])
# length(results_cor$ATHN_1000_t[results_cor$ATHN_1000_t > 0])


### CHECK AND add main title
# plot the histogram for the correlations
for (i in 1:(ncol(results_cor)-1)){
  png(file = paste0(colnames(results_cor)[i], "_Histogram_correlation.png"), bg = "white", width = 2480, height = 1748, res = 300)
  hist(results_cor[,i], breaks = 70, main = paste0("Histogram of correlation ", colnames(results_cor)[i]), xlab = "Spearman correlation")
  dev.off()
}

## Wavelet
# install.packages("biwavelet")

# date to timestep
CR$Timestep <- c(1:nrow(CR))
Station$Timestep <- c(1:nrow(Station))

#remove missing values from CR
CR[,2:ncol(CR)] <- na.approx(CR[,2:ncol(CR)])
CR[is.na(CR$Station),2] <- mean(CR$Station, na.rm = T)


# # Cross Wavelet
# wv.cx <- xwt(CR[,c(10,2)],Station[,c(17,14)],mother = "morlet")
# plot(wv.cx)
i=1
windows()
#Wavelet Coherence plots for all variables and pressure levels 10,100,1000
for(i in 1:length(variables)){
  # Wavelet coherence
  wv.coh <- wtc(CR[,c(10,grep(station_name,colnames(CR)))],Station[,c(grep("Timestep",colnames(Station)),grep(paste0(station_name,"_100_", variables[i]),colnames(Station)))],mother = "morlet")
  png(file = paste0(station_name,"_", variables[i],"_100","_Wavelet",".png"), bg = "white", width = 2480, height = 1748, res = 300)
  plot(wv.coh,plot.cb=F, plot.phase=T,
       main=paste0("Wavelet Coherence CRNS ", station_name, " ~ ", variables[i],"_100"), xaxt = "n")
  axis(1, at = seq(0,3653, 365), labels = c("2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021"))
  abline(h = log2(365), lwd = 3, col = "white", lty = 2)
  dev.off()
  
  wv.coh <- wtc(CR[,c(10,grep(station_name,colnames(CR)))],Station[,c(grep("Timestep",colnames(Station)),grep(paste0(station_name,"_1000_", variables[i]),colnames(Station)))],mother = "morlet")
  png(file = paste0(station_name,"_", variables[i],"_1000","_Wavelet",".png"), bg = "white", width = 2480, height = 1748, res = 300)
  plot(wv.coh,plot.cb=F, plot.phase=T,main=paste0("Wavelet Coherence CRNS ", station_name, " ~ ", variables[i],"_1000"),xaxt = "n")
  axis(1, at = seq(0,3653, 365), labels = c("2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021"))
  abline(h = log2(365), lwd = 3, col = "white", lty = 2)
  dev.off()
  
  wv.coh <- wtc(CR[,c(10,grep(station_name,colnames(CR)))],Station[,c(grep("Timestep",colnames(Station)),grep(paste0(station_name,"_10_", variables[i]),colnames(Station)))],mother = "morlet")
  png(file = paste0(station_name,"_", variables[i],"_10","_Wavelet",".png"), bg = "white", width = 2480, height = 1748, res = 300)
  plot(wv.coh,plot.cb=F, plot.phase=T,main=paste0("Wavelet Coherence CRNS ", station_name, " ~ ", variables[i],"_10"),xaxt = "n")
  axis(1, at = seq(0,3653, 365), labels = c("2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021"))
  abline(h = log2(365), lwd = 3, col = "white", lty = 2)
  dev.off()

}
#save.image("Wavelet.RData")
#load("Wavelet.RData")

#periode rausfinden bei maximum

# maximum <- as.data.frame(wv.coh$power.corr)
# plot(maximum[1,], type = "l")

# # Daniel
# -trends?


# with in-phase
# pointing right, anti-phase
# pointing left, and BMI leading AO
# by 90° pointing straight down).
