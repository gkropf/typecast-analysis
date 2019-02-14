# typecast-analysis
This project is designed to illustrate how typec

![alt text](output/OwenWilson.png "")
![alt text](output/TomCruise.png "")

## Usage
To recreate the results shown above for any actor; first download the repository zip file, extract it, and then navigate your terminal to the main folder. The data can then be gathered from Wikipedia and IMDB using the included python script. Simply open a python terminal and execute the following commands:
````
from RetrieveData import *
get_raw_data('Tom Cruise')
clean_data('Tom Cruise')
````
This will create a file in the *cleandata* folder that is appropriately formatted for our plotting function. To then produce the extended bipartite filmography graph, open an R terminal and execute the following commands:
````
source('CreateProfile.r')
plot_filmography('Tom Cruise')
````


