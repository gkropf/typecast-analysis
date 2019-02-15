library(ggplot2)
library(RColorBrewer)
library(classInt)
library(png)



# Actor we wish to create profile overview for, and the score we want to measure them against.
plot_filmography = function(actor, measure="gross"){
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
actor_graph = actor_graph+theme(plot.margin=grid::unit(c(0,0,0,0), "mm"))
h=4.5
w=2.5*h
ggsave("tmp.png", plot = actor_graph, width=w, height=h, dpi=300, units="in")

 
# Add picture of actor to the figure. We want to avoid using magick as it is not a common packge
# of most R users.

# Set parameters
spacing=.09
perc1=.7
perc2=.2
w=w/.8

# Read in image
img_actor = readPNG(paste("cleandata/",gsub(" ","",actor),".png",sep=""))
img_graph = readPNG("tmp.png")

# Create Plot.
png(paste("output/",gsub(" ","",actor),".png",sep=""), width=w+3*spacing, height=h+2*spacing, units="in", res=200)

par(mar=c(0,0,0,0))
plot(NA, xlim=c(0,w+3*spacing), ylim=c(0,h+2*spacing), xaxt="n", yaxt="n", bty="n", axes=0, xaxs='i', yaxs='i')

# Add border
black_image = array(c(0,0,0), dim=c(1,1,3))
white_image = array(c(1,1,1), dim=c(1,1,3))
boarder_w = .2*spacing
rasterImage(black_image, 0, 0, w+3*spacing, h+2*spacing)
rasterImage(white_image, boarder_w, boarder_w, w+3*spacing-boarder_w, h+2*spacing-boarder_w)

# Add actors photo
x_start=spacing
x_end=perc2*w
y_start=h+spacing-perc1*h
y_end=h+spacing
rasterImage(img_actor,x_start,y_start,x_end,y_end)

# Add genre network plot
x_start=w*perc2+spacing
x_end=w+2*spacing
y_start=spacing
y_end=h+spacing
rasterImage(img_graph,x_start,y_start,x_end,y_end)


# Add descriptive text
text(bquote(underline(bold(.(actor)))),x=.5*perc2*w+spacing, y=.94*(1-perc1)*h, font=1, cex=1.2)

tot_rev = round(sum(na.omit(actor_data[,'gross']))/(10**9),2)
lab=paste("Gross Box Office: ",toString(tot_rev)," billion over ",toString(n)," films.",sep="")
text(lab,x=.5*perc2*w+.5*spacing, y=.7*(1-perc1)*h, font=3, cex=.8)

main_genre = which(colSums(genre_ind)==max(colSums(genre_ind)))
lab=paste("Main film genre is ",tolower(genre_levels[main_genre]),".","")
text(lab,x=.5*perc2*w+.5*spacing, y=.45*(1-perc1)*h, font=3, cex=.8)

num_out = n-max(colSums(genre_ind))
lab = paste("Starred in ",num_out," films outside of main genre.","")
text(lab,x=.5*perc2*w+.5*spacing, y=.30*(1-perc1)*h, font=3, cex=.8)
dev.off()
actor_graph
}






















