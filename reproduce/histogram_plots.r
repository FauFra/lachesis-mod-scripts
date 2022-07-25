## First specify the packages of interest
packages = c("ggplot2", "dplyr",
             "hablar")

## Now load or install&load all
for (i in packages){
  if(! i %in% installed.packages()){  
      install.packages(i, dependencies = TRUE)
  }
  suppressMessages(library(i, character.only=TRUE))
}

options(dplyr.summarise.inform = FALSE)


THRESHOLD_LOWER <- 0
THRESHOLD_UPPER <- -1

args <- commandArgs(trailingOnly = TRUE)
if(length(args) < 1){
  print("Argument to pass: path_data.csv (REQUIRED) | threshold_rate lower bound (OPTIONAL) | threshold_rate upper bound (OPTIONAL)")
  q(save="no", status=1, runLast= TRUE)
}

PATH <- args[[1]]
DATA_FILE <-paste0(PATH,"/data.csv")

if(length(args) > 1){
  THRESHOLD_LOWER <- args[[2]]
}

if(length(args) > 2){
  THRESHOLD_UPPER <- args[[3]]
}


# df <- read.csv(file = "/home/fausto/FLINK_RT/pdf/data.csv", header=FALSE )
df <- read.csv(file = DATA_FILE, header=FALSE )
colnames(df) <- c("n", "metric","variant", "rep", "rate", "value")


df <- split(df, df$metric)

print_pdf <- function(x, title, path, y_label){
  filter <- c("") #Add here variants to hide
  
  data <- x %>% group_by(rate,variant) %>% summarise(max = max(value), min = min(value), value = mean(value)) 
  data <- data %>% convert(chr(variant))
  data <- data %>% convert(chr(rate))
  data <- data[!(data$variant %in% filter),]

  print(title)
  print(data)

  variant <- unique(data$variant)
  rate <- c(data$rate)
  value <- c(data$value)
  min <- c(data$min)
  max <- c(data$max)

  data <- data.frame(rate,variant,value)
  
  ggplot(data, aes(fill=variant, y=value, x=rate, ymax=max+0.1)) + 
    geom_bar(position="dodge", stat="identity", colour='black')+
  geom_text(
    aes(y=max, x=rate, label = sprintf("%1.2f",value), group = variant),
    position = position_dodge(width = 1),
    vjust = -1, size = 5
  ) + 
  labs(title=title, fill="Variant", y=y_label, x="Rate (t/s)")+
  theme(plot.title = element_text(hjust = 0.5, size=19, face='bold')) + 
  geom_errorbar(aes(ymin=min, ymax=max), width=.2, position=position_dodge(.9))+
  theme(text = element_text(size = 20), legend.position="bottom", legend.title= element_blank()) +
  guides(fill=guide_legend(nrow=2,byrow=TRUE))


  ggsave(filename=paste0(title,"-histogram.pdf"), path=path, width=8)
  ggsave(filename=paste0(title,"-histogram.png"), path=path, width=8)

}

aux <- na.omit(df$latency)
aux <- aux[aux$rate >= THRESHOLD_LOWER,]
if(THRESHOLD_UPPER != -1){
  aux <- aux[aux$rate <= THRESHOLD_UPPER,]
}
print_pdf(aux, "Latency", PATH, "Latency (secs)")

aux <- na.omit(df$'end-latency')
aux <- aux[aux$rate >= THRESHOLD_LOWER,]
if(THRESHOLD_UPPER != -1){
  aux <- aux[aux$rate <= THRESHOLD_UPPER,]
}
print_pdf(aux, "End-to-end latency", PATH, "Latency (secs)")

aux <- na.omit(df$throughput)
aux <- aux[aux$rate >= THRESHOLD_LOWER,]
if(THRESHOLD_UPPER != -1){
  aux <- aux[aux$rate <= THRESHOLD_UPPER,]
}
print_pdf(aux, "Throughput", PATH, "Througput (t/s)")