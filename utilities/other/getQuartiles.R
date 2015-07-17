data <- read.table("data", header=FALSE, sep="\t")

quantile(mydata, probs=c(0.25,0.5,0.75))
mydata
