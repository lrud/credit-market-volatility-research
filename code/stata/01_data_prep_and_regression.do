********************************************************************************
* Do-file:    data_prep_and_regs.do
* Purpose:    Analyze credit stress impact on asset volatility (LogVol_20d).
* Implements panel data prep, model selection, and quantile regression.
* Based on:   Caporin et al. (2016) volatility proxy, Fixed Effects framework.
* Date:       May 21, 2025
********************************************************************************
log using "/home/lr/Documents/HUNTER_SPRING/DEB_NONLINEAR/FINAL PROJECT/REGS.smcl", replace 
clear all             // Clear all data and settings from memory
set more off          // Prevent Stata from pausing output

* --- 1. Setup and Data Import ---
ssc install asrol, replace // Install 'asrol' command for rolling statistics if not present

local data_path "/home/lr/Documents/HUNTER_SPRING/DEB_NONLINEAR/FINAL PROJECT/DATA/"
local filename "bitcoin_dataset_clean.csv"

import delimited "`data_path'`filename'", clear // Import the raw CSV data

* --- 2. Data Cleaning and Log Volatility Generation ---
// Convert string date to Stata's daily date format, then rename and set as time variable.
gen date_stata = daily(date, "YMD")
format date_stata %td
drop date
rename date_stata date
sort date
tsset date

// Calculate daily log returns for Bitcoin and NASDAQ
gen btc_log_ret = ln(btc_price / L.btc_price)
gen nasdaq_log_ret = ln(nasdaq_close / L.nasdaq_close)

// Calculate 20-day rolling standard deviation of log returns (raw volatility proxy)
asrol btc_log_ret, stat(sd) window(date 20) gen(btc_vol_raw_20d)
asrol nasdaq_log_ret, stat(sd) window(date 20) gen(nasdaq_vol_raw_20d)

// Calculate Log-Volatility (LogVol_20d) as per Caporin et al. (2016) approximation
// (Logarithm of annualized 20-day rolling SD, annualized with sqrt(252) as per paper)
gen btc_logvol_20d = ln(btc_vol_raw_20d * sqrt(252))
gen nasdaq_logvol_20d = ln(nasdaq_vol_raw_20d * sqrt(252))

* --- 3. Prepare Data for Panel Regression (Reshape to Long Format) ---
// Rename price variables for consistent reshaping to a single 'close_price' variable
rename btc_price btc_close_price
rename nasdaq_close nasdaq_close_price

// Rename LogVol_20d and LogReturn variables for consistent reshaping
rename btc_logvol_20d logvol_20d_btc
rename nasdaq_logvol_20d logvol_20d_nasdaq
rename btc_log_ret log_ret_btc
rename nasdaq_log_ret log_ret_nasdaq
rename btc_close_price close_price_btc
rename nasdaq_close_price close_price_nasdaq

// Create a unified implied volatility variable for Bitcoin and NASDAQ (VXN for NASDAQ, DVOL_BTC for Bitcoin)
gen implied_vol_btc = dvol_btc
gen implied_vol_nasdaq = vxn
drop dvol_btc vxn // Drop original asset-specific implied vol variables

// Reshape the dataset from wide to long format for panel analysis
reshape long logvol_20d log_ret close_price implied_vol, i(date) j(asset_id) string

// Convert string asset_id to a numeric ID for panel (xt) commands
encode asset_id, gen(asset_numeric_id)

// Declare the dataset as panel data
xtset asset_numeric_id date

* --- 4. Generate Lagged Explanatory Variables & Leverage Term ---
// These are lagged one period (daily) to mitigate endogeneity, as per proposal
gen L_baa_aaa_spread = L.baa_aaa_spread
gen L_treasury_10y_3m_spread = L.treasury_10y_3m_spread
gen L_implied_vol = L.implied_vol

// Generate lagged negative log returns (leverage effect proxy)
gen L_log_ret = L.log_ret
gen L_neg_log_ret = L_log_ret * (L_log_ret < 0)

* --- 5. Model Estimation and Selection ---
// Estimate Fixed Effects (FE) model
xtreg logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret, fe
estimates store fe_model // Store FE results for comparison

// Estimate Pooled OLS model
regress logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret
estimates store ols_model // Store OLS results for comparison

// Estimate Random Effects (RE) model
xtreg logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret, re
estimates store re_model // Store RE results for comparison

// Perform model selection tests
// Breusch-Pagan LM test (Random Effects vs. Pooled OLS)
// Null: Variance of random effects is zero (Pooled OLS is preferred)
xttest0

// Hausman Test (Fixed Effects vs. Random Effects)
// Null: Random Effects is consistent (RE preferred if not rejected, FE if rejected)
hausman fe_model re_model

// Based on the output of xttest0 and the FE F-test (all u_i=0), Pooled OLS is indicated as the most appropriate model.
// (Typically: if xttest0 p-value > 0.05, choose Pooled OLS. If p-value < 0.05, then use Hausman.
// In your case, xttest0 p-value = 1.0000, strongly favoring Pooled OLS).

// Final chosen model with robust standard errors (good practice for panel data)
regress logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret, vce(robust)

* --- 6. Innovation: Quantile Regression to Explore Volatility Regimes ---
// Explore relationship across low, medium, and high volatility regimes.
// This is done via Symmetric Quantile Regression (SQReg) for efficiency.
// We'll estimate effects at the 25th, 50th (median), and 75th percentiles of LogVol_20d.
sqreg logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret, quantiles(25 50 75)

// Note: For SQReg, robust standard errors are automatically calculated.
// Interpretation will focus on how the coefficients differ across quantiles.

local processed_data_path "/home/lr/Documents/HUNTER_SPRING/DEB_NONLINEAR/FINAL PROJECT/DATA/"
// Ensure this directory exists, or Stata will error. You might need to create it manually first.
// Or, save it in the same directory as your raw data if preferred.

// Save the current dataset
compress // Optional: reduces file size
save "`processed_data_path'bitcoin_nasdaq_panel_analysis_ready.dta", replace
di "Analysis-ready dataset saved as bitcoin_nasdaq_panel_analysis_ready.dta"

log close
