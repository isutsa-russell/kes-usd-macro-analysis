# KES/USD Macro-Econometric Analysis: Diaspora Remittances, Policy Rates and the Kenyan Shilling (2016–2023)

**Author:** Isutsa Russell  |  **Date:** October 2026  |  **Tools:** R (tidyverse, lubridate, janitor, lmtest, tseries, sandwich, car)

## Executive Summary

This report examines whether monthly diaspora remittances and the Central Bank of Kenya (CBK) policy rate help explain movements in the Kenya shilling–US dollar (KES/USD) exchange rate between November 2016 and December 2023. Three CBK datasets were cleaned and merged into a monthly panel of 86 observations, and the relationship was tested with ordinary least squares (OLS) regression in both levels and differences.

Key findings:

- A regression in levels appears very strong (R² = 0.79, both predictors significant at p < 0.001), but it is not reliable. The exchange rate, remittances and CBR are all non-stationary, and the residuals are strongly autocorrelated (Durbin-Watson = 0.60), which are the classic signs of a spurious regression.
- After first-differencing to remove the shared trend, the relationship disappears. The differenced model explains about 4% of the variation in monthly exchange-rate changes (R² = 0.04), and neither remittance growth (p = 0.30) nor changes in the CBR (p = 0.25) is statistically significant under Newey-West standard errors.
- The shilling depreciated by 51% over the sample, from about KES 102 to KES 154 per USD, while monthly remittances rose from roughly USD 144 million to USD 373 million. The two series trend together, but this co-movement does not by itself show that one drives the other.
- The results are best read as an association in trending data, not evidence of a causal effect. Part of the value of the analysis is showing why the levels result should not be taken at face value.

## Introduction and Objectives

The exchange rate is one of the most closely watched prices in an open economy. For Kenya, diaspora remittances are a major source of foreign currency, and the CBK uses its policy rate (the Central Bank Rate, CBR) as its main monetary instrument. It is therefore natural to ask whether these two variables are associated with movements in KES/USD.

The objectives of this project were to:

- Build a reproducible data pipeline that imports, cleans and merges raw CBK datasets at a monthly frequency.
- Model the exchange rate as a function of remittances and the CBR using multiple linear regression.
- Test the statistical validity of that model and, where necessary, re-specify it.
- Communicate the results and their limitations clearly.

## Data

All data come from the Central Bank of Kenya (centralbank.go.ke).

| Dataset | Frequency | Coverage in raw file | Key variable |
| --- | --- | --- | --- |
| Historical exchange rates | Daily, multiple currencies | Oct 2016 – Jan 2024 (USD) | Mean KES/USD rate |
| Diaspora remittances | Monthly | 2004 – 2026 | Total remittances (USD thousands) |
| Central Bank Rate (CBR) | On announcement (about 125 records) | Aug 2008 – Oct 2026 | Policy rate (%) |

The binding constraint is the exchange-rate file, whose US dollar series runs from 11 October 2016 to 3 January 2024. The analysis window was therefore set to complete calendar months from November 2016 to December 2023, giving 86 monthly observations. Remittances are reported as monthly totals, and the CBR is a step function that changes only when the Monetary Policy Committee acts.

## Methodology

### Data cleaning

The cleaning pipeline (script 01\_data\_cleaning.R) performs the following steps:

- Reads all files as text and parses types explicitly, which avoids problems with thousands separators and the byte-order mark at the start of the CBK files.
- Parses two date formats found in the exchange-rate file (ISO and day/month/year), filters to the US dollar series and removes duplicate daily records.
- Converts remittances from USD thousands to USD millions after stripping commas.
- Builds a complete monthly CBR series from the first announcement onward, carrying the rate in force forward through months without an announcement.
- Aggregates daily exchange rates to monthly mean, minimum and maximum, then joins the three sources on year and month.
- Runs integrity checks for duplicate months and missing values before exporting the processed data.

### Statistical modelling

The modelling script (02\_modeling.R) proceeds in four stages:

- **Levels model.** OLS of the average monthly exchange rate on remittances (USD millions) and the CBR, as an exploratory baseline.
- **Diagnostics.** Durbin-Watson test and residual autocorrelation function for serial correlation, and variance inflation factors for multicollinearity.
- **Stationarity.** Augmented Dickey-Fuller (ADF) tests (tseries::adf.test, which includes a constant and linear trend) on each series in levels and first differences.
- **Differenced model.** OLS of the monthly log change in the exchange rate on the log change in remittances and the change in the CBR, with Newey-West heteroskedasticity and autocorrelation consistent standard errors (3 lags).

## Results

### Descriptive statistics

| Variable | Mean | Std. dev. | Min | Max |
| --- | --- | --- | --- | --- |
| Average KES/USD rate | 111.28 | 13.36 | 100.23 | 154.09 |
| Remittances (USD millions per month) | 264.83 | 67.87 | 138.60 | 378.05 |
| Central Bank Rate (%) | 8.64 | 1.32 | 7.00 | 12.50 |

The exchange rate moved within a narrow range for most of the period (about KES 100–113 per USD through 2021), then depreciated sharply in 2022 and 2023, ending the sample at KES 154.09 in December 2023. Remittances rose steadily, peaking at USD 378 million in July 2023. The CBR was changed in 12 of the 86 months and ended the sample at 12.50%. In levels, the exchange rate is strongly correlated with remittances (r = 0.72) and weakly with the CBR (r = 0.26).

&#91;image: Average monthly KES/USD exchange rate, November 2016 to December 2023\]

*Figure 1. Average monthly KES/USD exchange rate. The rate is broadly flat until 2020 and accelerates from 2022.*

### Levels regression

| Term | Coefficient | Std. error | p-value |
| --- | --- | --- | --- |
| Intercept | 16.64 | 6.13 | 0.008 |
| Remittances (USD millions) | 0.177 | 0.010 | < 0.001 |
| CBR (percentage points) | 5.534 | 0.536 | < 0.001 |

The model reports R² = 0.792 (adjusted 0.787), a residual standard error of KES 6.17 and a significant overall F-test. Taken at face value, each additional USD 100 million of monthly remittances is associated with a KES 17.7 higher exchange rate, and each percentage point on the CBR with a KES 5.5 higher rate. Both signs run opposite to the usual intuition that more foreign-currency inflow and tighter policy should support the shilling, which is itself a warning that the model is picking up a common trend.

The diagnostics confirm this. The Durbin-Watson statistic of 0.60 is far below 2, indicating strong positive autocorrelation, so the reported standard errors and p-values are not trustworthy. Variance inflation factors are 1.11 for both predictors, so multicollinearity is not the issue.

&#91;image: Diaspora remittances against the KES/USD exchange rate in levels\]

*Figure 2. Remittances against the exchange rate, in levels. The fitted line slopes upward, but both series trend over time, so this is not evidence of a relationship.*

### Stationarity tests

| Series | ADF p-value (levels) | ADF p-value (first difference) |
| --- | --- | --- |
| Average KES/USD rate | 0.99 | 0.09 |
| Remittances | 0.37 | 0.01 |
| CBR | 0.99 | 0.14 |

None of the three series rejects a unit root in levels, so each is non-stationary. After first differencing, remittances are clearly stationary (p = 0.01, the lower limit tseries reports). The exchange rate is borderline: its differenced series rejects a unit root at the 10% level (p = 0.09) but not at 5%, a pattern that would fit the faster depreciation in 2022–2023, although this was not tested separately. The CBR does not pass at 5% (p = 0.14), which is expected for a step function that is unchanged in most months, so the test has little power on it. These p-values come from tseries::adf.test, which includes a constant and a linear trend, and values beyond 0.01 and 0.99 are reported as those limits. Regressing non-stationary series on each other without cointegration produces spurious results, which motivates the differenced specification below. The borderline result for the exchange rate is a reason to treat that model with some caution.

### Differenced model

| Term | Coefficient | Newey-West std. error | p-value |
| --- | --- | --- | --- |
| Intercept | 0.0048 | 0.0015 | 0.003 |
| Change in log remittances | -0.0102 | 0.0098 | 0.302 |
| Change in CBR | 0.0058 | 0.0050 | 0.251 |

The model has 85 observations, R² = 0.041 (adjusted 0.018) and an overall F-test p-value of 0.18. Neither explanatory variable is significant. The only significant term is the intercept: the shilling lost on average about 0.5% of its value per month over the sample (the mean monthly log change is 0.0049, with a standard deviation of 0.0097), a drift that remittances and the policy rate do not account for. The Durbin-Watson statistic of 0.90 shows some autocorrelation remains, which is why robust standard errors are reported.

&#91;image: Monthly log changes in remittances against monthly log changes in the exchange rate\]

*Figure 3. Monthly log changes in remittances against monthly log changes in the exchange rate. The fitted line is almost flat, matching the non-significant coefficient.*

## Discussion

The contrast between the two models is the central result. In levels, remittances and the CBR appear to explain nearly 80% of the variation in the exchange rate. Once the shared upward trend is removed, they explain almost none of the month-to-month movement. The levels fit therefore reflects time, not a structural relationship: remittances grew steadily while the shilling depreciated, and any trending series would show a similar fit.

This does not mean remittances and monetary policy are irrelevant to the exchange rate. It means that, at monthly frequency and in this sample, changes in these two variables do not predict changes in the exchange rate in a statistically detectable way. Several explanations are plausible and consistent with the data: effects may operate with a lag rather than within the same month, the CBR changes too rarely in this window (12 changes in 86 months) to identify an effect, and the exchange rate is likely driven by factors outside the model, such as import demand, global dollar strength and external debt payments.

## Limitations

- **Small sample.** 86 monthly observations (85 after differencing) limit statistical power and the complexity of models that can be estimated.
- **Omitted variables.** The model excludes inflation, import and export values, foreign-exchange reserves, oil prices, interest-rate differentials with the United States and other known drivers of the exchange rate.
- **Simultaneity.** The CBK may adjust the CBR in response to exchange-rate pressure, so the policy rate is not strictly exogenous.
- **Timing.** Both models use contemporaneous values. Policy and remittance effects, if present, are likely to work with a delay.
- **Coverage.** The exchange-rate data end in January 2024 although remittances and CBR data extend to 2026, so recent developments are not captured.
- **Structural change.** The sharp depreciation in 2022–2023 suggests a possible regime shift that a single linear model does not allow for.
- **Measurement.** Monthly averaging smooths daily volatility, and remittances are measured in US dollars, not shillings.

## Conclusions and Further Work

This project built a reproducible pipeline from raw CBK files to a modelling-ready monthly dataset, and applied standard time-series diagnostics to a regression that initially looked convincing. The levels model is a textbook case of spurious regression, and the properly specified differenced model finds no significant short-run link between remittances, the CBR and the exchange rate.

Natural extensions are to:

- Obtain exchange-rate data beyond January 2024 to use the full remittance and CBR history.
- Test for cointegration (Engle-Granger or Johansen) and, if present, estimate an error-correction model or an ARDL specification with lagged regressors.
- Add lagged CBR terms and control variables such as inflation, reserves and trade flows.
- Test for structural breaks around 2022–2023.
- Evaluate out-of-sample forecast accuracy against a simple random-walk benchmark.

## Appendix: Reproducibility

The project is organised as follows, and the scripts are run in order from the project root:

- data/raw: the three original CBK files.
- 01\_data\_cleaning.R: cleans and merges the data and writes data/processed/master\_monthly\_fx.csv and usd\_daily\_clean.csv.
- 02\_modeling.R: fits the models, prints diagnostics and saves the figures to outputs/figures.

Figures produced: the average monthly exchange-rate trend, the levels scatter of remittances against the exchange rate, and the scatter of monthly log changes. The ADF p-values come from tseries::adf.test in R, which includes a constant and a linear trend; other software uses different specifications and lag lengths and can give different p-values.
