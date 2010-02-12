﻿########################################################
#####       Author: Diego Valle Jones
#####       Website: www.diegovalle.net
#####       Date Created: Sat Jan 23 21:10:55 2010
########################################################
#1. Bar chart of the homicide rate in 2008
#2. Map of the homicide rate
#3. Bar chart of the difference in homicide rate 2008-2006
#4. Map of the same
#5. Small multiples of the evolution of the murder rate 1990-2008

library(ggplot2)
library(RColorBrewer)
library(maptools)
library(classInt)
library(Cairo)
library(plotrix)

#location of the ICESI map
source("../maps-locations.r")

#############################################
#String Constansts
kyears <- 1990:2008
#############################################3

#Get rid of the full name of the states (eg: Veracruz de
#Ignacio de la Llave changes to Veracruz
cleanNames <- function(df, varname = "County"){
  df[[varname]] <- gsub("* de .*","", df[[varname]])
  df[[varname]]
}

#Read the data and clean it up
hom <- read.csv(bzfile("data/homicide-mun-2008.csv.bz2"), skip=4)
names(hom)[1:4] <- c("Code", "County", "Year.of.Murder", "Sex")
hom <- hom[grep("=CONCATENAR", hom$Code),]
hom <- hom[-grep("Extranjero", hom$County),]
hom <- hom[grep("Total", hom$Sex),]
hom$Year.of.Murder <- as.numeric(as.numeric(gsub('[[:alpha:]]', '',
                                 hom$Year.of.Murder)))
hom <- subset(hom, Year.of.Murder >= 1990)
#Get rid of the commas in the numbers: 155,000 to 155000
col2cvt <- 5:ncol(hom)
hom[ ,col2cvt] <- lapply(hom[ ,col2cvt],
                        function(x){as.numeric(gsub(",", "", x))})
hom[is.na(hom)] <- 0
hom$Tot <- apply(hom[ , col2cvt], 1, sum)

#Read the population data and merge it with the homice data to calculate the murder rate per 100,000
pop <- read.csv("../conapo-pop-estimates/conapo-states.csv")
pop$Code <- c(1:33)
hom$Code <- rep(1:32, each=19)
hom2008 <- merge(subset(hom, Year.of.Murder == 2008),
                 pop, by="Code", all.x=T)
#The per 100,000  murder rate
hom2008$Rate <- hom2008$X2008.x / hom2008$X2008.y * 100000
hom2008$County <- cleanNames(hom2008)
hom2008$County <- factor(hom2008$County)





########################################################
#Bar plot of the murder rate in 2008 by state and a map
########################################################
#Orange-Red Colors for the bars
nclr <- 4
palette <- "OrRd"
plotclr <- brewer.pal(nclr,palette)
hom2008$color <- NA

obs <- 34
index <- round(hom2008$Rate) + 1
clr.inc <- colorRampPalette(brewer.pal(8, "Reds"))
hom2008$color <- clr.inc(obs)[index]
hom2008[hom2008$Rate > 70,]$color <- "#410101"

hom2008$County <- reorder(hom2008$County, hom2008$Rate)
ggplot(data = hom2008, aes(County, Rate)) +
  geom_bar(stat = "identity", aes(fill = color)) +
  scale_y_continuous(limits = c(0, 85)) +
  coord_flip() +
  labs(x = "", y = "Homicides per 100,000") +
  opts(title = "Homicide Rate in Mexico (2008)") +
  opts(legend.position = "none") +
  scale_fill_identity(breaks = plotclr) +
  geom_text(aes(label=round(Rate, digits = 1)), hjust = -.05,
            color = "gray50") +
  geom_hline(yintercept = 12.77435165, alpha=.1, linetype=2)
dev.print(png, file = "output/2008-homicide-bars.png", width = 480, height = 480)

#########################################
#plot a map of mexico with different colors according to the homicide rate
#########################################
plotMap <- function(mexico.shp, colors, plotclr, legend="", title="") {
  plot(mexico.shp, col = colors, border="black", lwd=2)
  title(main = title)
  if (legend !="") {
    legend("topright", legend = legend,
      fill = plotclr, cex=0.8, bty="n")
  }

  par(bg = "white")
}

#We need to order the variables by name to match them with the map
mapOrder <- function(df, varname = "County.x"){
  df$County <- iconv(df[[varname]], "", "ASCII")
  #Why doesnt it work for Michoacán, I cheated and used the state
  #number as the no.match value. rrrrrrrgh!!!!!!!!!!!!!!
  df$Code <- pmatch(df$County, mexico.shp$NAME, 16)
  df.merge <- merge(data.frame(mexico.shp$NAME, Code = 1:32),
                    df, by="Code", all.x = TRUE)
  df.merge
}

mexico.shp <- readShapePoly(map.of.mexico,
                            IDvar = "NAME",
                            proj4string = CRS("+proj=longlat"))

hom2008.map <- mapOrder(hom2008, "County")
Cairo(file="output/2008-homicide-map.png", width=480, height=480)
plotMap(mexico.shp, hom2008.map$color)
dev.off()







################################################
#Bar plot of the change in homicide rate from the start of the
#drug war at the end of 2006 till 2008 and a map
###############################################
#http://learnr.wordpress.com/2009/06/01/ggplot2-positioning-of-barplot-category-labels/

hom2008 <- merge(subset(hom, Year.of.Murder == 2008),
                 pop, by="Code", all.x=T)
hom2008$Rate2008 <- hom2008$X2008.x / hom2008$X2008.y * 100000
hom2006 <- merge(subset(hom, Year.of.Murder == 2006),
                 pop, by="Code", all.x=T)
hom2006$Rate2006 <- hom2006$X2006.x / hom2006$X2006.y * 100000
hom.diff <- merge(hom2008,hom2006, by ="Code")
hom.diff$Diff <- hom.diff$Rate2008 - hom.diff$Rate2006

clr.inc <- colorRampPalette(brewer.pal(5, "Oranges"))
clr.dec <- colorRampPalette(brewer.pal(5, "Greens"))
hom.diff$color <- NA
#I (heart) R
obs <- abs(round(range(hom.diff$Diff)[2])) + 1
index <- abs(round(hom.diff[hom.diff$Diff >= 0, ]$Diff)) + 1
hom.diff[hom.diff$Diff >= 0, ]$color <- clr.inc(obs)[index]
index <- abs(round(hom.diff[hom.diff$Diff < 0, ]$Diff)) + 1
hom.diff[hom.diff$Diff < 0, ]$color <- clr.dec(obs)[index]

hom.diff$hjust <- ifelse(hom.diff$Diff > 0, 1.1, -.1)
hom.diff$text.pos <- ifelse(hom.diff$Diff > 0, -.05, 1)
hom.diff$County.x <- cleanNames(hom.diff, "County.x")
hom.diff$County.x <- factor(hom.diff$County.x)
hom.diff$County.x <- reorder(hom.diff$County.x, hom.diff$Diff)
ggplot(hom.diff, aes(x=County.x, y=Diff, label=County.x,
                      hjust = hjust)) +
  geom_text(aes(y = 0, size=3)) +
  geom_bar(stat = "identity",aes(fill = color)) +
  scale_y_continuous(limits = c(-18, 65)) +
  coord_flip() +
  labs(x = "", y = "Change in Rate per 100,000") +
  scale_x_discrete(breaks = NA) +
  opts(legend.position = "none")+
  opts(title="Change in Mexican Homicide Rates (2006-2008)")+
  scale_fill_identity(breaks=plotclr) +
  geom_text(aes(label=round(Diff, digits = 1), hjust = text.pos),
            color="gray50") +
  geom_hline(yintercept = 12.77435165- 9.919495802, alpha=.1, , linetype=2)

dev.print(png, file="output/2006-2008-change-homicide.png", width=480, height=480)

#plot a map of mexico with different colors according to the
#change in homicide rate
#We need to order the variables by name to match them with the map
hom.diff.map <- mapOrder(hom.diff)
Cairo(file="output/2006-2008-change-homicide-map.png", width=480, height=480)
plotMap(mexico.shp, hom.diff.map$color)
dev.off()







####################################################
#Small Multiples Plot of Murders by State
####################################################
#The yearly homicide rate in Mexico
historic <- read.csv("../accidents-homicides-suicides/output/homicide.csv")
homicideMX <- historic$rate
total.hom <- data.frame(rate=homicideMX, years=kyears)

mpop <- melt(pop, id=c("Code", "State"))
mpop$variable <- as.numeric(substring(mpop$variable, 2))
mpop$Year.of.Murder <- mpop$variable
hom.mpop <- merge(hom, mpop, by=c("Code","Year.of.Murder"))
hom.mpop$Rate <- hom.mpop$Tot / hom.mpop$value * 100000
hom.mpop$County <- cleanNames(hom.mpop,)
hom.mpop$County <- factor(hom.mpop$County)

#k-means clustering to order the plot
t <- cast(hom.mpop[,c(26:27,29)], State ~ variable)
nclusters <- 8
cl <- kmeans(t[,2:ncol(t)], nclusters)
t$Cluster <- cl$cluster
t <- merge(ddply(t, .(Cluster), function(df) mean(df$"2008")),
      t, by = "Cluster")
t <- t[,c(1,2,3)]
hom.mpop <- merge(hom.mpop, t, by = "State")
hom.mpop$County <- reorder(hom.mpop$County, -hom.mpop$V1)

#This is how you get anti-aliasing in R
#Cairo(file="output/1990-2008-homicide-small-multiples.png", type="png", width=960, height=600)
p <- qplot(hom.mpop$Year.of.Murder, hom.mpop$Rate,
           geom = "line", size = 1,
           color = factor(hom.mpop$Cluster)) +
     opts(legend.position = "none")
p + facet_wrap(~ hom.mpop$County, as.table = TRUE,
               scale="free_y") +
    labs(x = "", y = "Homicide Rate") +
    opts(title = "Mexican homicide rates 1990-2008, compared to the national average and grouped by similarity") +
    scale_x_continuous(breaks = c(1990, 2000, 2008),
                       labels = c("90", "00", "08")) +
    theme_bw() +
    geom_line(data = total.hom, aes(years, rate),
              color="gray70", linetype = 2, size =.5) +
    opts(legend.position = "none")
    #scale_colour_manual(values = rep(c("#c76353","#a42c1e"),
     #                   nclusters))
     #    strip.background = theme_rect(fill = c("red", "blue")))
#dev.off()

#The graph for Chihuahua looks similar to the hockey stick
#of global temperatures
#Coincidence? or is it a goverment conspiracy
