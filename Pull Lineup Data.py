#!/usr/bin/env python
# coding: utf-8

# In[1]:


#Pulling data from pbpstats.com. 
#More information can be found: https://api.pbpstats.com/

#load packages

import requests
import pandas as pd
import numpy as np
import time


# In[5]:


#get players and ID's
players_response = requests.get("https://api.pbpstats.com/get-all-players-for-league/nba")
players = players_response.json()


# In[17]:


#print list of players to csv
player_id,player_name = zip(*players['players'].items())
df = pd.DataFrame({'Player_Id': player_id, 'Player_Name': player_name})
df.to_csv("players.csv", index=False)


# In[123]:


#get the list of teams
teams_response = requests.get("https://api.pbpstats.com/get-teams/nba")
teams = teams_response.json()

#set up parameters for seasons. Data only goes back to 2000-2001
seasons = []
year_range = list(range(2000,2023))
for year in year_range:
    start_year = str(year)
    end_year = str(year+1)
    single_season = start_year + "-" + end_year[-2:]
    seasons.append(single_season)
    
seasonTypes = ["Regular Season","Playoffs"]


# In[124]:


#Pulling the data. Can only pull 500 rows at a time, so subdivide by team and year

url = "https://api.pbpstats.com/get-totals/nba"
for season in seasons:
    for seasonType in seasonTypes:
        yearly_lineup_data = []
        print("Pulling data for",seasonType,season)
        for team in teams["teams"]:
            teamId = str(team["id"])
            params = {"Season": season,
                      "SeasonType": seasonType,
                      "Type": "Lineup",
                      "TeamId": teamId
                     }
            response = requests.get(url, params=params)
            response_json = response.json()
            lineup_stats = response_json["multi_row_table_data"]
            if len(lineup_stats)>=500:
                print("Exceeded limit for",team["text"],season,seasonType)
            yearly_lineup_data.extend(lineup_stats)
            lag = np.random.uniform(low=5,high=10)
            time.sleep(lag)
        df = pd.DataFrame(yearly_lineup_data)
        filepath = "lineup_data_" + season + "_" + seasonType + ".csv"
        df.to_csv(filepath, index=False)
        print("Succesfully completed writing",filepath)


# In[ ]:


#now want to get player positions from NBA.com. 


