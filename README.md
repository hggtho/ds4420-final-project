Final Project for DS 4420 class - Northeastern University
# Analyzing Crime Patterns and Forecasting Trends
Crime forecasting has become increasingly important for police resource allocation and public safety planning. Traditional statistical approaches have evolved alongside machine learning methods, offering various tools for predicting crime patterns across space and time.


## Project Description
This project analyzes crime data from 2020 to 2024 in Los Angeles to identify patterns, trends, and factors associated with criminal activity.
The goal is to provide insights into how crime evolves over time and to demonstrate and anticipate crime patterns.

## Project Overview

This project analyzes crime data from 2020 to 2024 to identify patterns and trends in criminal activity.
The project will explore how crime changes over time and across offense types using data visualization and statistical analysis.

**Two main modeling approaches:**
1. Time series modeling (manually in Python):
   - Getting ACF and PACF plots to determine the number of lags we will use in later steps.
   - Analyzing past trends from 2020-2023 and forecasting future crime numbers in 2024.

3. Bayesian Modeling (brms package in R):
  - Analyzing past trends from 2020-2023 and forecasting future crime numbers in 2024.
  - Applying Bayesian linear regression to predict the mean number of crimes for a specific area. 

## Data

We use a dataset that includes crime incidents in the City of Los Angeles from 2020 to 2025. However, the initial file is really huge, so we have to clean it up (removing irrelevant columns and missing rows) to reduce the dataset size before uploading to git.

Source: data.gov
