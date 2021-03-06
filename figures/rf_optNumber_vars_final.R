#!/bin/R

#this script executes random forest

library(randomForest)
library("e1071");

args = commandArgs(trailingOnly=TRUE); #accept arguments, first = data file (needs to be oriented s.t. rows are patients and columns are features, including 1 col for labels) second file is list of cluster ranking

### Read Data / Preprocess ###
data = read.table(args[1], header = T, row.names = 1); #use for tsv output from calculateClusterMeans.R script

data = t(data); #transpose data (flip rows and cols)

response = substr(rownames(data),1,3);
data = cbind.data.frame(data,response);

#data = transform(data, "2" = as.numeric("2"), "14" = as.numeric("14"), "18" = as.numeric("18"), "34" = as.numeric("34"), "43" = as.numeric("43"), "51" = as.numeric("51"), "73" = as.numeric("73"), "86" = as.numeric("86"), "88" = as.numeric("88"), "91" = as.numeric("91"), "93" = as.numeric("93"), "97" = as.numeric("97"), "99" = as.numeric("99"), "105" = as.numeric("105"), "107" = as.numeric("107"), "112" = as.numeric("112"), "124" = as.numeric("124"), "137" = as.numeric("137"), "138" = as.numeric("138"), "140" = as.numeric("140"), "141" = as.numeric("141"), "149" = as.numeric("149"), "152" = as.numeric("152"), "171" = as.numeric("171"), "172" = as.numeric("172"), "179" = as.numeric("179"), "189" = as.numeric("189") );

#read in cluster ranking
modules = scan(file=args[2], what="list")
modules = gsub("X", "", modules)
#demo
#modules = colnames(data);

start = 15;
stop = 15;
increment = 1;
size = ((stop - start)/ increment) + 1;
#size = 15;
results = matrix(rep(0,size*3),nrow=size,ncol=3);
#results = matrix(rep(0,size*4),nrow=size,ncol=4);
accuracies = matrix(rep(0,200),nrow=200,ncol=1);
#demo
#for(i in 1:start) { data[,i] = as.numeric(as.character(data[,i])); }
#data$age_at_diagnosis = as.numeric(as.character(data$age_at_diagnosis));
#demo
iterations = 200;
n = 0;
for (i in seq(start,stop,increment)) { #increment by 1 selecting i features each time
#commetted for mtry
	n = n + 1;
	features = modules[1:i];
	features = c(features, "response");
	mean_acc = 0;	
#for(k in 16:30) {
	#mtry
	#n = n + 1;
	#mean_acc = 0;
	data_new = data[names(data) %in% features];
                random_vec = sample(2, nrow(data_new), replace = T, prob = c(0.75,0.25)) #creates a vector length of data, randomly assigning 75% values 1 and 25% values 2
                training = data_new[random_vec==1,]; #select 75% of data for training
                testing = data_new[random_vec==2,]; #select 25% of data for testing
                names(training) = make.names(names(training)); #convert feature names to be legal
                names(testing) = make.names(names(testing));

	#optimal = tune.svm(response~., data = training, tunecontrol=tune.control(sampling='boot', nboot=10), kernel='radial', cost = seq(1,110,10), gamma = seq(.01,.1,.01) );
        #opt_gamma = as.numeric(optimal$best.parameters[1]);
	#print(opt_gamma);
	#q();
        #opt_cost = as.numeric(optimal$best.parameters[2]);
	for(j in seq(1,iterations,1)) {
		data_new = data[names(data) %in% features];
		random_vec = sample(2, nrow(data_new), replace = T, prob = c(0.75,0.25)) #creates a vector length of data, randomly assigning 75% values 1 and 25% values 2
		training = data_new[random_vec==1,]; #select 75% of data for training
		testing = data_new[random_vec==2,]; #select 25% of data for testing
		names(training) = make.names(names(training)); #convert feature names to be legal
		names(testing) = make.names(names(testing));
		#set.seed(1);
		#opt_mtry = tuneRF(data_new[,names(data_new) != "response"], data_new$response, stepFactor = 1.5, improve = 0, ntree=10000, trace=TRUE);
		#print(opt_mtry);
		#q();
		#best_mtry = tuneRF(training[,names(training) != "response"], training$response, ntreeTry = 500, stepFactor = 2, improve = 0);

		#svm
	        random_forest = svm(training$response ~ ., data=training, type = 'C'); #, cost=opt_cost, gamma=opt_gamma);

		#random_forest = randomForest(training$response ~ ., data = training, ntree = 10000, importance = T, mtry=4);
		pred_response = predict(random_forest, testing, type = "response" );
		accuracy = sum(pred_response == testing$response)/nrow(testing);
		mean_acc = mean_acc + accuracy;
		accuracies[j,] = accuracy;
		print(accuracy);
	}
	sdev = sd(accuracies);
	mean_acc = mean_acc / iterations;
	results[n,] = c(i,mean_acc,sdev); #insert into df (divide by 5 because increment by 5)
#mtry
#}

}
print(args[2]);
#print just the run with num vars that had best accuracy
tail(results[order(results[,2]),],1)
print(results);
pdf(paste("RF_Opt_Features_",iterations,"x_",args[2],".pdf",sep=""));
plot(results, xlab="Number of Features", ylab="Mean Accuracy", main="Gem Random Forest Accuracy by Number of Features");
dev.off();


