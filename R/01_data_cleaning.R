# -----------------------------------------------------------------------------

# Project : Multi-Year KES/USD Macroeconomics Analysis(Data Cleaning Pipeline)
# Author : Isutsa Russell
# Purpose : Import, clean, standardize dates, and merge CBK economic indicators

# -----------------------------------------------------------------------------


# Loading Libraries

library(tidyverse)
library(lubridate)
library(janitor)

# Loading Raw Datasets from CBK 

raw_hist         <- read_csv("data/raw/historical_data.csv", col_names = FALSE,
                             col_types = cols(.default = col_character()))
raw_diaspora     <- read_csv("data/raw/Diaspora Remittances.csv",
                             col_types = cols(.default = col_character()))
raw_cbr          <- read_csv("data/raw/Central Bank Rate (CBR) .csv",
                             col_types = cols(Date = col_character(), Rate = col_double()))

# Data Wrangling & Data Parsing

# Cleaning Exchange Rates & Filtering for US Dollar

# A. Clean Daily Exchange Rates & Filter for US Dollar
usd_daily <- raw_hist |>
  rename(date_str = X1, currency = X2, mean_rate = X3, buy_rate = X4, sell_rate = X5) |>
  filter(date_str != "Date" & !is.na(date_str)) |>
  mutate(
    currency = str_squish(str_to_upper(currency)),
    date = as_date(parse_date_time(date_str, orders = c("ymd", "dmy"))),
    mean_rate = as.numeric(mean_rate)
  ) |>
  filter(!is.na(date) & currency == "US DOLLAR") |>
  rename(usd_rate = mean_rate) |>
  select(date, usd_rate) |>
  # Removing duplicate daily records and keeping only complete months (Nov 2016 - Dec 2023)
  distinct(date, usd_rate) |>
  filter(date >= as_date("2016-11-01") & date < as_date("2024-01-01")) |>
  arrange(date)

# Cleaning Monthly Diaspora Remittances

diaspora_monthly <- raw_diaspora |>
  clean_names() |>
  rename(remittances_usd_thousands = total_remittances_usd_000) |>
  mutate(
    year = as.integer(year),
    month = as.integer(month),
    #Stripping commas from character strings and converting to numeric float
    
    remittances_usd_thousands = as.numeric(gsub(",", "", remittances_usd_thousands)),
    remittances_usd_millions = remittances_usd_thousands / 1000
  ) |>
  select(year, month, remittances_usd_millions)

# Cleaning CBR Exchange Rates

cbr_monthly <- raw_cbr |>
  clean_names() |>
  mutate(date = dmy(date)) |>
  rename(cbr_rate = rate) |>
  arrange(date) |>
  mutate(
    year = year(date),
    month = month(date)
  ) |>
  group_by(year, month) |>
  summarise(
    cbr_rate = last(cbr_rate), # Take the final announced policy rate of the month
    .groups = "drop"
  ) |>
  # Filling months without an announcement with the rate still in force
  mutate(period = make_date(year, month, 1)) |>
  complete(period = seq(min(period), max(period), by = "month")) |>
  fill(cbr_rate, .direction = "down") |>
  mutate(
    year = year(period),
    month = month(period)
  ) |>
  select(year, month, cbr_rate)

#Aligning(Daily to Monthly)

usd_monthly <- usd_daily |>
  mutate(
    year = year(date),
    month = month(date)
  ) |>
  group_by(year, month) |>
  summarise(
    avg_usd_rate = mean(usd_rate, na.rm = TRUE),
    min_usd_rate = min(usd_rate, na.rm = TRUE),
    max_usd_rate = max(usd_rate, na.rm = TRUE),
    .groups = "drop"
  )

#Joining Monthly USD Rates with Monthly Diaspora Remittances

master_monthly <- usd_monthly |>
  left_join(diaspora_monthly, by = c("year", "month")) |>
  left_join(cbr_monthly, by = c("year", "month")) |>
  arrange(year, month)

# Checking for Duplicate Months and Missing Values

stopifnot(!anyDuplicated(master_monthly[c("year", "month")]))
master_monthly |> summarise(across(everything(), ~ sum(is.na(.x)))) |> print()

# Exporting Processed Data

write_csv(master_monthly, "data/processed/master_monthly_fx.csv")
write_csv(usd_daily, "data/processed/usd_daily_clean.csv")

# Print a success message on the console

cat(" Data Cleaning Pipeline Executed Succesfully!\n")