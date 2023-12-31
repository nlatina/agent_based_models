## ----setup, include=FALSE-------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(data.table)
library(pheatmap)
library(magick)
library(RColorBrewer)
library(scales)
library(Matrix)
library(tidyverse)


## ----define functions-----------------------------------------------------------------------------------------------------------------
mat <- function(df, nx, ny)  {
    ## Tally up the frequencies
    dt <- data.table(df, key=c("x", "y"))
    xyN <- dt[, .N, by=key(dt)]
    ## Place counts in matrix in their respective i/j x/y row/column
    as.matrix(with(xyN, sparseMatrix(i=x,j=y,x=N,dims=c(nx,ny))))
}


move<-function() sample(1:5, 1)
ment<-data.frame(matrix(c(1,0,0,
                          2,1,0,
                          3,0,1,
                          4,-1,0,
                          5,0,-1), byrow=T, nrow=5)) # matrix with information regarding possible movements
colnames(ment)<-c("State", "delta X", "delta Y")

life<-function() runif(1, min = 0.8, max = 1.0)



K<-20 # carrying capacity

n<-50 # size of world (an n x n square)




gif<-function(fps, title="gif"){
  ## list file names and read in
imgs <- list.files("/Users/nicklatina/Desktop/ca_output", full.names = T)
imgs<-imgs[order(imgs)]
img_list <- lapply(imgs, image_read)

## join the images together
img_joined <- image_join(img_list)

## animate at 2 frames per second
img_animated <- image_animate(img_joined, fps = fps)

## view animated image
#img_animated

## save to disk
image_write(image = img_animated,
            path = paste("/Users/nicklatina/Desktop/",title,".gif", sep=""))
}


## ----CA-------------------------------------------------------------------------------------------------------------------------------


steps<-50

ledger<-data.frame(matrix(c(1,25,25,1,1), nrow=1))
colnames(ledger) = c("ID", "x", "y", "move" ,"life")
ledger<-rbind(ledger, c(max(ledger$ID)+1,22,17,2,0.7))

M<-0
L<-0
i<-1
for(z in 1:steps){
  store<-c()
for (i in which(is.na(ledger[,2]) == F)){
 ledger[i,"move"]<-move() # create values that will instruct moving/life cycle behaviors for each agent
  ledger[i,"life"]<-life()
  
  dv<-sample(1:3,1)
  if(dv == 1){ #life cycle

    if(ledger[i,"life"] < 0.0){
      ledger[i,2:5]<-NA # kill agent, while retaining ID
    } else {
      noob<-ledger[i,] # create daughter agent
      noob[2:3]<-noob[2:3]+ment[which(ment[,1] == noob[[4]]), 2:3] # place daughter agent in one of 5 cells
      noob[[1]]<-max(rbind(ledger,store)[,1])+1 # give daughter agent a new ID
      store<-rbind(store,noob) # store daughter agent; will be added to ledger after every agent in this timestep is updated
    } 
    }else { # movement

      ledger[i,2:3]<-ledger[i,2:3]+ment[which(ment[,1] == ledger[i,4]), 2:3] # move agent
    } } 
  
  # add daughter agents to ledger
  ledger<-rbind(ledger,store) 
  
  # any agent that tries to cross boundaries gets killed
   ledger[which((ledger[,2] >= n)),2:5]<-NA
   ledger[which((ledger[,3] >= n)),2:5]<-NA
  ledger[which((ledger[,2] < 1)),2:5]<-NA
   ledger[which((ledger[,3] < 1)),2:5]<-NA
   
                                                 ### Carrying Cpacity #####
   # create subset of ledger that only contains living agents
df<-data.frame(x=ledger[,"x"], y=ledger[,"y"]) %>% .[which(is.na(.[,1]) == F),] 

    # Tally up the frequencies
    dt <- data.table(df, key=c("x", "y"))
    xyN <- dt[, .N, by=key(dt)]

    # figure out which grid spaces have >K agents, and randomly kill off until pop = K
    TooBig<-xyN[which(xyN[,"N"] > K ),1:2]
    if(nrow(TooBig) > 1){
    for( v in 1:nrow(TooBig)){
      xx<-as.numeric(TooBig[v,1]) ; yy<-as.numeric(TooBig[v,2])
      dv<-ledger[which(ledger[,2] == xx),]
      dv<-dv[which(dv[,3] == yy),] %>%
      slice_sample(., n=(nrow(dv)-K))
      ledger[dv$ID,2:5]<-NA
    }} else{
    }
  
    xyN <- dt[, .N, by=key(dt)]
    
    ## Place counts in matrix in their respective i/j x/y row/column
    ts<-as.matrix(with(xyN, sparseMatrix(i=x,j=y,x=N,dims=c(n,n))))
    

# graphing
  jpeg(filename=paste("/Users/nicklatina/Desktop/ca_output/",z+1000,".jpeg", sep=""))

  breaksList = seq(0,25, by = 1)
  color<-colorRampPalette(c("#810E36","#D0002D", "#E0421F","#FFBA08", "#ffffff"))(length(breaksList))
  color[[1]]<-c("#000000")

pheatmap(ts+1,
         color = color, border_color=NA,
         breaks = breaksList,
         cluster_rows=FALSE, cluster_cols=FALSE)

  dev.off()
}

gif(10,"CA")


 #show_col(color, labels=F)

length(which(is.na(ledger[,2]) == T))/nrow(ledger) # dead cells

 



