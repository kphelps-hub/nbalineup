#!/usr/bin/env python
# coding: utf-8

# In[228]:


import os
import glob
import pandas as pd

#create a dictionary to hold data frames
df_dict = {}

output_file = 'combined/lineup_data.csv'

for season_type in ['Regular Season', 'Playoffs']:
    
    #get csv files to read
    folder_path = season_type
    csv_files = glob.glob(os.path.join(folder_path,'*.csv'))
    
    # Initialize an empty list to hold df's
    df_list = []
    
    #loop over csv files
    for csv_file in csv_files:
        
        df = pd.read_csv(csv_file)
        
        #create columns for season
        season_name = csv_file.split("_")[2]
        season_strt_yr = int(season_name.split("-")[0])
        season_end_yr = int(season_strt_yr +1)
        df['SeasonName'] = season_name
        df['SeasonStrtYr'] = season_strt_yr
        df['SeasonEndYr'] = season_end_yr
        df['SeasonType'] = season_type
        
        #append dfs in a list
        df_list.append(df)
    
    #group together with pd.concat for better performance
    df_dict[season_type] = pd.concat(df_list, ignore_index=True)

all_data = pd.concat([df_dict['Regular Season'],df_dict['Playoffs']], ignore_index=True)

# Update the column order
cols = all_data.columns
season_col = ['SeasonName','SeasonStrtYr','SeasonEndYr','SeasonType']
new_order = list(cols[0:6]) + season_col
new_order = new_order + [col for col in cols if col not in new_order]
all_data = all_data[new_order]

#Split Name into 5 fields
all_data[['PlayerOne','PlayerTwo','PlayerThree','PlayerFour','PlayerFive']] = all_data['Name'].str.split(', ', expand=True)

all_data.to_csv(output_file, index = False)

