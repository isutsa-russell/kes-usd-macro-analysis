# ----------------------------------------------------------------------------------

# Project : KES/USD Macro-Econometric Analysis & Modeling
# Author : Isutsa Russell
# Purpose : Load processed monthly data, run summary statistics, fit OLS regression,
#          and generate publication-grade ggplot2 visualizations.

# ----------------------------------------------------------------------------------

# Loading Required Libraries

library(tidyverse)
library(lubridate)
library(lmtest)
library(tseries)
library(sandwich)
library(car)

# Creating Output Folder if it Does Not Exist

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Loading Processed Master Dataset from 01_data_cleaning.R

master_macro <- read_csv("data/processed/master_monthly_fx.csv")

# Exploring Summary Statistics

summary(master_macro)

# Preparing Clean Data for Modeling(Drop rows with missing values)

model_data <- master_macro |>
  arrange(year, month) |>
  drop_na(avg_usd_rate, remittances_usd_millions, cbr_rate)

# Print on the console a success message :)

cat("Total complete observations available for regression model:", nrow(model_data), "\n")

# Fitting a Multiple Linear Regression Model (OLS)

# Objective Was to Model how Exchange Rates are driven by Remittances and Central Bank Rates

fx_regression <- lm(avg_usd_rate ~ remittances_usd_millions + cbr_rate, data = model_data)

# Viewing Statistical Model Summary (Coefficients, R-squared, p-values)

summary(fx_regression)

# Checking Residual Autocorrelation and Multicollinearity of the Levels Model

dwtest(fx_regression)
acf(residuals(fx_regression), main = "ACF of Levels Model Residuals")
vif(fx_regression)

# Testing Stationarity of Each Series (ADF p-values in Levels and First Differences)

series_list <- list(
  avg_usd_rate = model_data$avg_usd_rate,
  remittances_usd_millions = model_data$remittances_usd_millions,
  cbr_rate = model_data$cbr_rate
)

adf_table <- imap_dfr(series_list, ~ tibble(
  variable = .y,
  level_p_value = suppressWarnings(adf.test(.x)$p.value),
  diff_p_value = suppressWarnings(adf.test(diff(.x))$p.value)
))

print(adf_table)

# Fitting the Differenced Model (Log Changes) to Avoid Spurious Regression

diff_data <- model_data |>
  mutate(
    date = make_date(year, month, 1),
    d_log_fx = c(NA, diff(log(avg_usd_rate))),
    d_log_remit = c(NA, diff(log(remittances_usd_millions))),
    d_cbr = c(NA, diff(cbr_rate))
  ) |>
  drop_na(d_log_fx, d_log_remit, d_cbr)

fx_diff <- lm(d_log_fx ~ d_log_remit + d_cbr, data = diff_data)

# Viewing Differenced Model Summary with Newey-West Robust Standard Errors

summary(fx_diff)
coeftest(fx_diff, vcov = NeweyWest(fx_diff, lag = 3, prewhite = FALSE))

# Generating Visualizations using ggplot2

# Time Series of the Average Monthly Exchange Rate

p_trend <- model_data |>
  mutate(date = make_date(year, month, 1)) |>
  ggplot(aes(x = date, y = avg_usd_rate)) +
  geom_line(color = "#1f77b4", linewidth = 0.9) +
  theme_minimal() +
  labs(
    title = "Average Monthly KES/USD Exchange Rate",
    subtitle = "Multi-Year Monthly Macroeconomic Analysis",
    x = NULL,
    y = "Average Monthly KES/USD Exchange Rate",
    caption = "Source: Central Bank of Kenya(centralbank.go.ke)"
  )

# Levels Relationship (Exploratory: Both Series Trend Upward)

p_levels <- ggplot(model_data, aes(x = remittances_usd_millions, y = avg_usd_rate)) +
  geom_point(color = "#1f77b4", size = 2.5, alpha = 0.7) +
  geom_smooth(method = "lm", color = "darkred", se = TRUE, linetype = "dashed") +
  theme_minimal() +
  labs(
    title = "Diaspora Remittances and KES/USD Exchange Rate (Levels)",
    subtitle = "Exploratory Association: Both Series Trend Upward Over Time",
    x = "Monthly Diaspora Remittances (USD Millions)",
    y = "Average Monthly KES/USD Exchange Rate",
    caption = "Source: Central Bank of Kenya(centralbank.go.ke)"
  )

# Changes Relationship (Monthly Log Changes After Differencing)

p_diff <- ggplot(diff_data, aes(x = d_log_remit, y = d_log_fx)) +
  geom_point(color = "#1f77b4", size = 2.5, alpha = 0.7) +
  geom_smooth(method = "lm", color = "darkred", se = TRUE, linetype = "dashed") +
  theme_minimal() +
  labs(
    title = "Monthly Changes in Remittances and KES/USD Exchange Rate",
    subtitle = "Log Differences Remove the Common Trend",
    x = "Monthly Change in Log Diaspora Remittances",
    y = "Monthly Change in Log KES/USD Exchange Rate",
    caption = "Source: Central Bank of Kenya(centralbank.go.ke)"
  )

# Saving Visualizations Output

ggsave("outputs/figures/exchange_rate_trend.png", plot = p_trend, width = 8, height = 5, dpi = 300)
ggsave("outputs/figures/remittances_vs_exchange_rate.png", plot = p_levels, width = 8, height = 5, dpi = 300)
ggsave("outputs/figures/remittances_vs_exchange_rate_changes.png", plot = p_diff, width = 8, height = 5, dpi = 300)

# Saving Residual ACF Plot

png("outputs/figures/levels_residual_acf.png", width = 8, height = 5, units = "in", res = 300)
acf(residuals(fx_regression), main = "ACF of Levels Model Residuals")
invisible(dev.off())

# Print on the console another success message :) :)

cat(" Script 2 Executed Successfully: Model Fitted and Chart Saved!\n")