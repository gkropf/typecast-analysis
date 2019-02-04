import imdb
import wikipedia as wp
import wptools
import pandas as pd
import urllib.request
ia = imdb.IMDb()
wp.set_rate_limiting(True)


def get_raw_data(actor_name):

    # Search for actor's name and take first result.
    actor_ID = ia.search_person(actor_name)[0].personID

    # Retrieve actors list of works.
    actor_obj = ia.get_person(actor_ID, 'main')
    all_films = actor_obj['filmography'][0]['actor']

    # Iterate through every movie/film tile and collect relevent data.
    all_entries = []
    for i in range(0, len(all_films)):

        print('Processing film ('+str(i)+str(' of ')+str(len(all_films))+')')
        print(all_films[i]['title'])
        film_ID = all_films[i].movieID
        film_obj = ia.get_movie(film_ID, ['main', 'critic reviews'])

        # Check the the movie is not currently in production.
        if 'year' in film_obj:
            if int(film_obj['year']) < 2019:
                pass
            else:
                continue
        else:
            continue

        # Store relevent details.
        curr_entry = dict()
        for el in ['title', 'year', 'rating', 'votes', 'metascore', 'genres', 'plot outline']:
            if el in film_obj:
                curr_entry[el] = film_obj[el]
            else:
                curr_entry[el] = 'Nan'

        # The film revenue data is not parsed by imdbpy, thus we will use wikipedia to
        # get revenue data. Additionally, the 'starring' section of the wikipedia infobox
        # on films will give us a double check that the actor actually portrayed a major
        # character in the film.

        film_wp = wp.search(' '.join([curr_entry['title'], str(curr_entry['year']), 'film']))
        if len(film_wp) > 0:
            film_wp = film_wp[0]
        else:
            continue
        cpage = wptools.page(film_wp)
        cpage.get_parse()
        infobox = cpage.data['infobox']

        # Now that page is loaded, add box office stats. Remove commas in dollar amounts
        # to prevent misreading later when csvs are imported.
        if infobox is not None:
            pass
        else:
            continue

        if 'budget' in infobox:
            curr_entry['budget'] = infobox['budget'].replace(",", "")
        else:
            curr_entry['budget'] = 'Nan'

        if 'gross' in infobox:
            curr_entry['gross'] = infobox['gross'].replace(",", "")
        else:
            curr_entry['gross'] = 'Nan'

        # Finally, add entry if actor portrayed main character in the film.
        if 'starring' in infobox:
            if actor_name in infobox['starring']:
                all_entries.append(curr_entry)

    df = pd.DataFrame(all_entries)
    df = df[['title', 'year', 'rating', 'votes', 'metascore', 'genres', 'budget', 'gross', 'plot outline']]
    df.to_csv('rawdata/'+actor_name.replace(" ", "")+".csv", index=None)
    return


def clean_data(actor_name):

    # Read data into pandas data frame.
    df = pd.read_csv('rawdata/'+actor_name.replace(" ","")+".csv", sep=",")

    # Remove dollar signs and million/billion text.
    budget = [x.replace("$","").replace("million","").replace("billion","") for x in df['budget']]
    gross = [x.replace("$","").replace("million","").replace("billion","") for x in df['gross']]
    n = len(gross)

    # Convert budget into numeric by using appropriate multiplier.
    if_million = [(10**6) if 'million' in x else 1 for x in df['budget']]
    if_billion = [(10**9) if 'billion' in x else 1 for x in df['budget']]
    budget = [if_million[i] * if_billion[i] * float(budget[i]) for i in range(n)]

    # Convert budget into numeric by using appropriate multiplier
    if_million = [(10 ** 6) if 'million' in x else 1 for x in df['gross']]
    if_billion = [(10 ** 9) if 'billion' in x else 1 for x in df['gross']]
    gross = [if_million[i] * if_billion[i] * float(gross[i]) for i in range(n)]

    # Update date frame and save to cleaned data folder.
    df['budget']=budget
    df['gross']=gross
    df.to_csv('cleandata/'+actor_name.replace(" ", "")+".csv", sep=",", header=True, index=None)
    return


def get_photo(actor_name):
    pic_url = wp.page(actor+' filmography').images[1]
    urllib.request.urlretrieve(pic_url,actor.replace(" ",""))


