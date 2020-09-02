library(zoo)
library(ggplot2)
library(dplyr)

sp <- read.csv("./datasets/sp500 returns.csv")
sp <- sp[-1,1:3]
colnames(sp) <- c("Date", "GrossReturn", "PriceReturn")
sp <- data.frame(Year = as.integer(substr(sp$Date,1,4)),
                 Month = as.integer(substr(sp$Date,5,6)),
                 GrossReturn = sp$GrossReturn,
                 PriceReturn = sp$PriceReturn)
sp$Time <- as.yearmon(paste0(sp$Month, '/', sp$Year), format = '%m/%Y')

Cal_Port <- function(return, con = 500){
  n <- length(return)
  r <- 0
  portfolio <- c()
  for (i in 1:n){
    r <- (con+r)*(1+return[i])
    portfolio[i] <- r
  }
  return(portfolio)
}

Sim_Port <- function(return, year, iter = 100000, simfun){
  port <- list()
  for (i in 1:iter){
    re <- simfun(return, year = year)
    port[[i]] <- Cal_Port(re)
  }
  dp <- data.frame(matrix(unlist(port),nrow = iter, ncol=year*12,byrow = T))
  colnames(dp) <- paste0("month ", 1:(year*12))
  return(dp)
}

# port <- Sim_Port(sp$GrossReturn, 40)

# Cal_Ending <- function(port, year){
#   iter <- length(port)
#   e <- c()
#   for (i in 1:iter){
#     p <- port[[i]]
#     e[i] <- p[year*12]
#   }
#   return(e)
# }

# ending <- Cal_Ending(LNport, 40)

Cal_Quan <- function(dp, year){
  s <- data.frame(sapply(dp,sort))
  t <- (1:(year*12))/12
  iter <- nrow(dp)
  plotdata <- data.frame()
  for (per in c(0.9,0.75,0.5,0.25,0.1,0.01)){
    plotdata <- rbind(plotdata, data.frame(Time = t,
                                           Portfolio = as.vector(t(s[per*iter,1:(year*12)])), 
                                           Percentile = paste0(per*100, "% Percentile")))
  }
  # plotdata <- rbind(plotdata, data.frame(Time = t,
  #                                        Portfolio = as.vector(t(s[1,1:(year*12)])), 
  #                                        Percentile = "Min"))
  return(plotdata)
}

# plotdata <- Cal_Quan(port, ending, 40)

Sim_Plot <- function(dp, year){
  # ending <- Cal_Ending(port, year)
  plotdata <- Cal_Quan(dp, year)
  
  ggplot() +
    geom_line(data=plotdata, aes(x = Time, y = Portfolio, color = Percentile)) +
    geom_hline(yintercept = 1000000, linetype="dashed") +
    theme_bw() +
    labs(x = "Time in Years", y = "Portfolio Value")
}

Table_Quan <- function(dp, year = c(20,25,30,35,40)){
  p <- data.frame()
  s <- data.frame(sapply(dp,sort))
  for (y in year){
    t <- (1:(y*12))/12
    iter <- nrow(dp)
    pt <- data.frame(Portfolio = s[iter,y*12],
                     Percentile = "Max")
    for (per in c(0.99,0.9,0.75,0.5,0.25,0.1,0.01)){
      pt <- rbind(pt, data.frame(Portfolio = s[per*iter,y*12], 
                                       Percentile = paste0(per*100, "% Percentile")))
    }
    pt <- rbind(pt, data.frame(Portfolio = s[1,y*12],
                                     Percentile = "Min"))
    
    rownames(pt) <- pt$Percentile
    pt <- pt[1]
    colnames(pt) <- paste0(y, "-Year Portfolio")
    p <- rbind(p, t(pt))
  }
  t(p)
}


# Simple Bootstraping

Spl_Boot <- function(return, year = 40){
  n <- year * 12
  r <- sample(return,n,replace=TRUE)
  return(r)
}

# LogNormal

LN_Sim <- function(return, year = 40){
  n <- length(return)
  R_i <- log(return + 1)
  R_bar <- mean(R_i)
  s2 <- sum((R_i-R_bar)^2)/(n-1)
  sigma <- sqrt(s2)
  mu <- R_bar+s2/2
  Z <- rnorm(year*12)
  r <- exp((mu-1/2*sigma^2)+sigma*Z) - 1
  return(r)
}

# port <- Sim_Port(sp$GrossReturn, 40, simfun = Spl_Boot)
# LNport <- Sim_Port(sp$GrossReturn, 40, simfun = LN_Sim)

Tab_Years <- function(dp, year){
  s <- data.frame(sapply(dp,sort))
  t <- (1:(year*12))/12
  iter <- nrow(dp)
  plotdata <- data.frame(t(as.vector(t(s[iter,1:(year*12)]))))
  q <- c(0.99,0.9,0.75,0.5,0.25,0.1,0.01)
  for (per in q){
    plotdata <- rbind(plotdata, as.vector(t(s[per*iter,1:(year*12)])))
  }
  
  tab <- data.frame()
  for (i in seq_along(c(0,q))){
    m <- sum(plotdata[i,]<1000000)+1
    invest <- m*500
    y <- (m)/12
    if (y>40){
      y <- NA
      invest <- NA
    }
    tab <- rbind(tab,cbind(y,invest))
  }
  colnames(tab) <- c('Years to reach $1m', 'Money have invested($)')
  rownames(tab) <- c('Max',paste0(q, "% percentile"))
  
  return(tab)
}

# write.csv(t(plotdata), file="./datasets/LNsimulation.csv")

# dp <- data.frame(matrix(unlist(port[1:10000]),10000,480,byrow = T))
# colnames(dp) <- paste0("month ", 1:480)
# dl <- data.frame(matrix(unlist(LNport[1:10000]),10000,480,byrow = T))
# colnames(dl) <- paste0("month ", 1:480)
# 
# write.csv(dp, file="./datasets/BSsimulation10k.csv", row.names = F)
# write.csv(dl, file="./datasets/LNsimulation10k.csv", row.names = F)



