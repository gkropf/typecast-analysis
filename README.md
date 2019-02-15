# typecast-analysis
The goal of this project was to create instant snapshots of actor's entire filmographies that illustrate how varied their roles have been, how successful their roles from each genre have been, and how well their films have performed at box offices overall. A kind of extended bipartite graph was ultimately chosen so as to avoid complex legends created by overlaid bar plots or various other means of displaying multidimensional data. 

*This was largely a personal endeavor to settle family arguments over who are the most versatile actors. And learn the advanced features of ggplot2 in the process.*



## Examples
For Tom Cruise, we can see that most of his films are from the thriller/adventure/action genres with a modest amount of films from the romance and drama genres. He has largely ignored films focused in comedy, sci-fi, fantasy, mystery, and horror. Additionally, we can see that every one of his highest performing films (458-791m) are from the thriller/adventure/action genres. And, every one of his worst performing films is from the romance, drama, or comedy genres. While Tom Cruise has attempted to branch out, his fans seem to only enjoy his distinct portrayal of the charming and quick-thinking protagonist characterized by his classic portrayal of Maverick in Top Gun.

![alt text](output/TomCruise.png "")



Owen Wilson is one actor who is oft described as simply playing himself in most films. This is perfectly captured in the illustration below where we can see that while many of his movies span multiple genres, 40 out of 47 of his films are centered in comedy.

![alt text](output/OwenWilson.png "")

## Usage
To recreate the results shown above, for any actor, download the repository zip file, extract it, and then navigate your terminal to the main folder. The data can then be gathered from Wikipedia and IMDB using the included python script. Simply open a python terminal and execute the following commands:
````
from RetrieveData import *
get_raw_data('Tom Cruise')
clean_data('Tom Cruise')
get_photo('Tom Cruise')
````
This will create a file in the *cleandata* folder that is appropriately formatted for our plotting function. To then produce the extended bipartite filmography graph, open an R terminal and execute the following commands:
````
source('CreateProfile.r')
plot_filmography('Tom Cruise')
````
### Known Bugs
The infobox data that is collected from Wikipedia's web pages can often contain odd formatting characters, this will cause the *clean_data* command to fail. I am working on expanding the *clean_data* function's ability to handle edge cases so that the user will not have to do any formatting corrections themselves. For now, it is advisable to check the outputted file from *get_raw_data* (located at rawdata/actorname.csv) and delete misaligned rows before executing the *clean_data* command. 

