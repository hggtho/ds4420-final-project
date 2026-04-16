## Import necessary libraries

library(ggplot2)  # For visualization
library(dplyr) # For data aggregation
library(lubridate)
library(brms) # For Bayesian ML

## Load the data set: 

crime <- read.csv("CrimeData.csv", stringsAsFactors = T)

# Preview the data, only show first 5 columns
head(crime[, 1:5])

# Sort by DATE.OCC, TIME.OCCM and Date.Rptd in ascending order (oldest first)
crime <- crime[order(crime$DATE.OCC, crime$TIME.OCC, crime$Date.Rptd), ]

# Preview the data, only show first 5 columns
head(crime[, 1:5])

# Add new column for a cleaner date
crime$Date_Clean <- as.Date(crime$DATE.OCC, format = "%m/%d/%Y")

# Aggregate crimes by date
daily_crimes <- crime %>%
  mutate(Date = as.Date(Date_Clean)) %>%
  group_by(Date) %>%
  summarise(Count = n())

head(daily_crimes)

## Visualize Time Series

ggplot(daily_crimes, aes(x = Date, y = Count)) +
  geom_line() +
  ggtitle('Number of Crimes in Los Angeles over time') +
  xlab('Date') +
  ylab('Number of Crimes') +
  theme_minimal()

# Filter for years 2020-2024
daily_crimes_cleaned <- daily_crimes %>%
  filter(Date >= "2020-03-01" & Date <= "2024-03-01")

# Plot 2020-2024
ggplot(daily_crimes_cleaned, aes(x = Date, y = Count)) +
  geom_line() +
  ggtitle('Number of Crimes in Los Angeles over time') +
  xlab('Date') +
  ylab('Number of Crimes') +
  theme_minimal()

## Create new dataframe: 
# Use only relevant features: Year, Month, Day of Week, Day of Year, 
# Weekened or not, and Week of Year
crimes <- daily_crimes_cleaned %>%
  mutate(
    Year = year(Date),
    Month = month(Date),
    DayOfWeek = wday(Date),
    DayOfYear = yday(Date),
    IsWeekend = ifelse(DayOfWeek %in% c(1, 7), 1, 0),
    WeekOfYear = week(Date)
  )

# We will use data from 2020 to 2023 to predict number of crimes for 2024. 

# Split: Train = 2020-2023, Test = 2024
train_data <- crimes %>% filter(Year < 2024)
test_data <- crimes %>% filter(Year == 2024)

# Define priors
crime_priors <- c(
  prior(normal(5.5, 0.5), class = "Intercept"),  # log(~250 crimes/day)
  prior(normal(0, 0.3), class = "b")              # Weak effect priors
)

# We use Poisson distribution here because the number of crimes 
# happened every day is independent from each other 
# and are counted in non-negative integers 
model <- brm(
  Count ~ DayOfWeek + Month + IsWeekend + WeekOfYear,
  family = poisson(),
  data = train_data,
  prior = crime_priors,
  chains = 4,
  iter = 2000,
  warmup = 180
)

# Check model summary
summary(model)

plot(model)

# Point predictions (posterior mean)
predictions_mean <- predict(model, newdata = test_data)[, "Estimate"]

# Full posterior predictive distribution
predictions_full <- posterior_predict(model, newdata = test_data)

# Get credible intervals
pred_intervals <- predictive_interval(model, newdata = test_data, prob = 0.95)

# Add to test data
test_data <- test_data %>%
  mutate(
    Predicted_Mean = predictions_mean,
    Lower_95 = pred_intervals[, 1],
    Upper_95 = pred_intervals[, 2]
  )

# View predictions
head(test_data[, c("Date", "Count", "Predicted_Mean", "Lower_95", "Upper_95")])

# Create the plot
ggplot(test_data, aes(x = Date)) +
  # Actual values 
  geom_line(aes(y = Count, color = "Actual"), size = 1) +
  # Predicted values 
  geom_line(aes(y = Predicted_Mean, color = "Predicted"), 
          size = 1) +
  # Colors
  scale_color_manual(
    name = "",
    values = c("Actual" = "steelblue", "Predicted" = "orange"),
    labels = c("Actual Daily Crime Count", "Predicted Daily Crime Count")
  ) +
  # Labels
  labs(title = "Bayesian Model Predictions for 2024",
       x = "Year-Month",
       y = "Number of Crimes") +
  # Theme
  theme_minimal() +
  theme(
    legend.position = c(0.25, 0.85),  # Position legend inside plot
    legend.background = element_rect(fill = "white", color = "gray"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
  ) +
  # Format x-axis as Year-Month
  scale_x_date(date_labels = "%Y-%m", date_breaks = "1 month")

# ================ Predicted number of crimes by Area ================

## Aggregate the data by date and area
crime_by_area <- crime %>%
  mutate(
    Date = as.Date(Date_Clean),
    Year = year(Date)
  ) %>%
  filter(Year >= 2020 & Year <= 2024) %>%
  group_by(Date, AREA.NAME) %>%
  summarise(Count = n(), .groups = "drop") %>%
  mutate(
    DayOfWeek = factor(wday(Date, label = TRUE)),
    Month = factor(month(Date, label = TRUE)),
    MonthNum = month(Date),
    IsWeekend = ifelse(wday(Date) %in% c(1, 7), 1, 0),
    Year = year(Date)
  )

# Split: Train = 2020-2023, Test = 2024
train <- crime_by_area %>% filter(Year < 2024)
test <- crime_by_area %>% filter(Year == 2024)

# Check unique areas
print("Areas in data:\n")
print(unique(crime_by_area$AREA.NAME))

# Define priors
area_prior <- c(
  prior(normal(5, 1), class = "Intercept"),   
  prior(normal(0, 5), class = "b")
)

# We use negative poisson models 
model_area <- brm(
  Count ~ DayOfWeek + MonthNum + AREA.NAME,
  family = poisson(),
  data = train,
  prior = area_prior,
  chains = 4,
  iter = 1000,
  warmup = 180
)
summary(model_area)
plot(model_area)


# Predict for specific area and time
# Example: Hollywood in February 2024
predictions_specific <- test %>%
  filter(AREA.NAME == "Hollywood", month(Date) == 2)

preds <- predict(model_area, newdata = predictions_specific)
predictions_specific$Predicted <- preds[, "Estimate"]

print(predictions_specific)

# See the mean of predicted number of crime
mean(predictions_specific$Predicted)

# See the mean of true number of crime
mean(predictions_specific$Count)
