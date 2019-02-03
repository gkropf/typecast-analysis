library(ggplot2)
library(RColorBrewer)
library(classInt)
library(png)



# Actor we wish to create profile overview for, and the score we want to measure them against.
actor = "Tom Cruise"
measure = 'gross'
raw_score = FALSE

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
#
#
# Plot network graph with at most lim1 movie titles and lim2 genres.
#
#
actor_graph = ggplot()
lim1=44
lim2=10

num_film_nodes = min(lim1,n)
num_genre_nodes = min(lim2,p)

# Bin score values and get categorical variable
if (raw_score){
scaled_pos = actor_data[,measure]
lim3=max(na.omit(actor_data[measure]))
} else {

used_area=.5
padding=.05
blank_area=1-used_area-padding
nbin=5
num_valid=length(na.omit(actor_data[1:lim1,measure]))
num_per_bin=as.integer(ceiling(num_valid/nbin))

# This double order trick gives the relative placement of each number in the vector.
#actor_data[,measure]=order(actor_data[,measure])
m=order(order(actor_data[1:lim1,measure]))
scaled_pos = rep(NA,num_film_nodes)
for (i in 1:num_film_nodes){
if (m[i]<=num_valid){
category = (m[i]-1)%/%num_per_bin
position = (m[i]-1)%%num_per_bin
scaled_pos[i]=category*(used_area/nbin+blank_area/(nbin-1))+position*used_area/(nbin*(num_per_bin-1))+padding/2
}
}
lim3=1
}





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

d3=data.frame("x"=3,"y"=scaled_pos[i], "pair"=pair+1, "gen_col"=col_fact[j])
d4=data.frame("x"=2,"y"=genre_y[j],"pair"=pair+1, "gen_col"=col_fact[j])
group_data=rbind(group_data,d1,d2,d3,d4)

curr_row=curr_row+4
pair=pair+2
}
}
}

# Now plot group with color coding.
actor_graph = actor_graph + geom_line(data=group_data, aes(x=x, y=y, group=pair, color=gen_col))

# Add genre labels.
x=rep(2,num_genre_nodes)
y=genre_y+.07*(genre_y[2]-genre_y[1])
gen_lab_data = data.frame("x"=x, "y"=y, "labs"=genre_levels[1:num_genre_nodes])
p = geom_label(data=gen_lab_data, aes(x=x, y=y, label=labs), fill="grey88", alpha=.75)
actor_graph = actor_graph + p



# Add score rectangles if user did not wish to use raw scores.
if (!raw_score){
x1=rep(3,nbin)-.06
x2=rep(3,nbin)+.20
y1=padding/2+seq(0,nbin-1)*(used_area/nbin+blank_area/(nbin-1))-used_area/(nbin*(num_per_bin-1))
y2=y1+used_area/nbin+2*used_area/(nbin*(num_per_bin-1))
rect_data = data.frame(x1,x2,y1,y2)
p  = geom_rect(data=rect_data, aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2),fill="grey88", alpha=.85)
actor_graph = actor_graph+p
}

# Add score labels.
x=(x1+x2)/2
y=(y1+y2)/2
m=sort(actor_data[,measure])

score_lvls=c("Very Low\n","Low\n","Average\n","High\n","Very High\n")
left_bin = round(m[1+seq(0,nbin-1)*num_per_bin]/(10**6),0)
right_bin = round(m[pmin(seq(1,nbin)*num_per_bin,num_valid)]/(10**6),0)
for (i in 1:nbin){
score_lvls[i]=paste(score_lvls[i],toString(left_bin[i]), "-", toString(right_bin[i]), "m", sep="")
}

lab_data = data.frame("x"=x, "y"=y, "labs"=score_lvls)
p = geom_text(data=lab_data, aes(x=x, y=y, label=labs))
actor_graph = actor_graph + p


# Save network graph.
actor_graph = actor_graph+theme(legend.position="none", axis.title.x=element_blank(),
                                axis.text.x=element_blank(),
                                axis.ticks.x=element_blank(),
                                axis.text.y=element_blank(),
                                axis.ticks.y=element_blank(),
                                axis.title.y=element_blank())
h=4.5
ggsave("tmp.png", plot = actor_graph, width=2.2*h, height=h, dpi=120, units="in")



# Add picture of actor.
#img = image_read("cleandata/OwenWilson.png")






# Add movie labels
#x=rep(1-.4,num_film_nodes)
#y=film_y
#gen_lab_data = data.frame("x"=x, "y"=y, "labs"=actor_data[1:num_film_nodes,'title'])
#p=annotate("text", x=x, y=film_y, label=actor_data[1:num_film_nodes,'title'], hjust=0)
#actor_graph = actor_graph + p
