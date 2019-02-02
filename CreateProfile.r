
# Actor we wish to create profile overview for.
actor = "Owen Wilson"

# Read in data file.
file_name = paste("CleanData/",gsub(" ","",actor),".csv",sep="")
data_types = c("character",rep("numeric",4),"character",rep("numeric",2),"NULL")
actor_raw=read.csv(file_name, sep=',', colClasses=data_types,header=TRUE)
n=dim(actor_raw)[1]
m=dim(actor_raw)[2]

# Get list of all genres in actors filmography.
genre_levels = c()
for (i in 1:n){
temp=actor_raw[i,6]
temp=gsub("\\[","c(",temp)
temp=gsub("\\]",")",temp)
temp=eval(parse(text=temp))
genre_levels = union(genre_levels, temp)
}
p=length(genre_levels)

# Now create indicator variables for each genre.
genre_ind = as.data.frame(matrix(0, nrow=n, ncol=p))
colnames(genre_ind)=genre_levels
for (i in 1:n){
for (j in 1:p){
if (grepl(genre_levels[j], actor_raw[i,6])){
  genre_ind[i,j]=1
}
}
}







