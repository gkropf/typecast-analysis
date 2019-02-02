library(ggplot2)
library(RColorBrewer)
library(classInt)



# Actor we wish to create profile overview for, and the score we want to measure them against.
actor = "Owen Wilson"
measure = 'gross'

# Read in data file.
file_name = paste("cleandata/",gsub(" ","",actor),".csv",sep="")
data_types = c("character",rep("numeric",4),"character",rep("numeric",2),"NULL")
actor_data=read.csv(file_name, sep=',', colClasses=data_types,header=TRUE)
n=dim(actor_data)[1]
m=dim(actor_data)[2]


# Get list of all genres in actors filmography.
genre_levels = c()
for (i in 1:n){
temp=actor_data[i,6]
temp=gsub("\\[","c(",temp)
temp=gsub("\\]",")",temp)
temp=eval(parse(text=temp))
genre_levels = union(genre_levels, temp)
}

# Use preset genre_levels so that comparisons between actors have same organization.
genre_levels = c("Action", "Adventure", "Thriller","Horror","Mystery", "Fantasy", "Sci-Fi", "Comedy", "Drama", "Romance", "Western")
p=length(genre_levels) 

# Now create indicator variables for each genre.
genre_ind = matrix(0, nrow=n, ncol=p)
for (i in 1:n){
for (j in 1:p){
if (grepl(genre_levels[j], actor_data[i,'genres'])){
  genre_ind[i,j]=1
}
}
}


# Plot network graph with at most lim1 movie titles and lim2 genres.
actor_graph = ggplot()
lim1=50
lim2=10
lim3=max(na.omit(actor_data[measure]))

num_film_nodes = min(lim1,n)
num_genre_nodes = min(lim2,p)

# Create consistent color pallete and factors
cols = brewer.pal(num_genre_nodes, "BrBG")
col_fact = factor(cols)

# Plot black nodes for each film title.
film_x = seq(from = 1, to = 1, length.out = num_film_nodes)
film_y = seq(from = 0, to = lim3, length.out = num_film_nodes)
film_data=as.data.frame(cbind(film_x,film_y))
actor_graph = actor_graph + geom_point(data=film_data,aes(x=film_x, y=film_y), color='black')

# Plot colored nodes for each genre.
genre_x = seq(from = 2, to = 2, length.out = num_genre_nodes)
genre_y = seq(from = 0, to = lim3, length.out = num_genre_nodes)
genre_data=as.data.frame(cbind(genre_x,genre_y))
actor_graph = actor_graph + geom_point(data=genre_data, aes(x=genre_x, y=genre_y, color=col_fact))

# Bin score values and get transformed position values.
#h=.1
#sep=(1-h)/6
#m=actor_data[,measure]
#x=as.numeric(unlist(classIntervals(na.omit(m), 5, style='quantile')[2]))
#m_cat = cut(m, x, labels=c("Very Poor","Poor","Average","Good","Very Good"))
#for (i in 2:num_film_nodes){
#c_max=max(na.omit(m)[na.omit(m_cat)==m_cat[i]])
#c_min=max(na.omit(m)[na.omit(m_cat)==m_cat[i]])
#c_num=sum(na.omit(m_cat)==m_cat[i])
#}
h=.5
nbin=5
bin_size=as.integer(round(length(na.omit(actor_data[,measure]))/5))
m=sort(actor_data[,measure])
measure_cat=actor_data[,measure]

for (i in 1:num_film_nodes){
num_lessthan=as.integer(sum(na.omit(m)<m[i]))
skip_amount=(num_lessthan%/%bin_size)*(1-h)/6
curr_val=(num_small%%bin_size)
measure_cat[i]=skip_amount+curr_val
print(c(skip_amount,curr_val))
}
plot(sort(na.omit(measure_cat)),0*na.omit(measure_cat))





# Now for each film title, plot all its connections to genre and film rating.
# This is achieved by creating genre groups.
max_num_rows = num_genre_nodes*(2*num_film_nodes+1)
group_data = as.data.frame(matrix(1, nrow=0, ncol=4))
group_data[,4] = factor(group_data[,4])
levels(group_data[,4])=levels(col_fact)
colnames(group_data) = c("x","y","pair","gen_col")

curr_row=1
pair=1
for (j in 1:num_genre_nodes){
for (i in 1:num_film_nodes){
if (genre_ind[i,j]>0){

d1=data.frame("x"=1, "y"=film_y[i], "pair"=pair, "gen_col"=col_fact[j])
d2=data.frame("x"=2,"y"=genre_y[j],"pair"=pair, "gen_col"=col_fact[j])

d3=data.frame("x"=3,"y"=actor_data[i,measure], "pair"=pair+1, "gen_col"=col_fact[j])
d4=data.frame("x"=2,"y"=genre_y[j],"pair"=pair+1, "gen_col"=col_fact[j])
group_data=rbind(group_data,d1,d2,d3,d4)

curr_row=curr_row+4
pair=pair+2
}
}
}

# Now plot group with color coding
actor_graph = actor_graph + geom_line(data=group_data, aes(x=x, y=y, group=pair, color=gen_col))

# Add genre labels
x=rep(2,num_genre_nodes)
y=genre_y+.07*(genre_y[2]-genre_y[1])
gen_lab_data = data.frame("x"=x, "y"=y, "labs"=genre_levels[1:num_genre_nodes])
p = geom_label(data=gen_lab_data, aes(x=x, y=y, label=labs), fill="grey88", alpha=.75)
actor_graph = actor_graph + p

# Add movie labels
x=rep(1-.4,num_film_nodes)
y=film_y
gen_lab_data = data.frame("x"=x, "y"=y, "labs"=actor_data[1:num_film_nodes,'title'])
p=annotate("text", x=x, y=film_y, label=actor_data[1:num_film_nodes,'title'], hjust=0)
actor_graph = actor_graph + p



# Print final graph.
actor_graph = actor_graph+theme(legend.position="none", axis.title.x=element_blank(),
                                axis.text.x=element_blank(),
                                axis.ticks.x=element_blank())
actor_graph+scale_y_continuous(position="right")+labs(y="Score")













