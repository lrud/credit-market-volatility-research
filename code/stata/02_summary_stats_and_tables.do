********************************************************************************
* Do-file:     02_summary_stats_and_tables.do
* Purpose:     Generate summary statistics and formatted regression tables (LaTeX output).
* Uses the analysis-ready dataset from 01_data_prep_and_regression.do
* Date:        May 22, 2025
********************************************************************************
log using "/home/lr/Documents/HUNTER_SPRING/DEB_NONLINEAR/FINAL PROJECT/TABLES.smcl", replace
clear all
set more off

* --- 1. Define Paths and Load Processed Data ---
local project_base_path "/home/lr/Documents/HUNTER_SPRING/DEB_NONLINEAR/FINAL PROJECT/"
local data_path "`project_base_path'DATA/"
local tables_path "`project_base_path'TABLES/"
local analysis_file "bitcoin_nasdaq_panel_analysis_ready.dta"

capture mkdir "`tables_path'"
// log using "`project_base_path'PROJECT_02_summarytables.smcl", replace // Log commented out

use "`data_path'`analysis_file'", clear

* --- 2. Generate Descriptive Statistics Tables ---
summarize logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret
tabstat logvol_20d L_implied_vol L_neg_log_ret, by(asset_id) stats(n mean sd min max) format(%9.3f) columns(stats)
xtsum logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret

* --- 3. Re-run Models for Regression Table Generation ---
regress logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret, vce(robust)
estimates store final_ols_robust_tab

sqreg logvol_20d L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret, quantiles(25 50 75)
estimates store qreg_model_tab

* --- 4. Generate Formatted Regression Tables as .tex files ---
// Make sure 'estout' package is installed: ssc install estout, replace

esttab final_ols_robust_tab using "`tables_path'Table_OLS_Log_Volatility.tex", ///
    replace booktabs ///
    b(%9.3f) se(%9.3f) ///
    title("Pooled OLS Regression of Log Volatility (Robust SEs)") ///
    keep(L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret _cons) ///
    stats(r2_a N, fmt(%9.3f %9.0gc) labels("Adj. R-squared" "Observations")) ///
    starlevels(* 0.10 ** 0.05 *** 0.001) ///
    mgroups("Log Volatility (20-day)", pattern(1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    nonumbers nodepvars nomtitles ///
    addnote("Standard errors in parentheses. Data source: bitcoin\_dataset\_clean.csv. Variables are lagged one period.")

// Table for the Quantile Regression model
estimates restore qreg_model_tab // Ensure estimates are active for this esttab call
esttab qreg_model_tab using "`tables_path'Table_Quantile_Regression_Log_Volatility.tex", ///
    replace booktabs unstack ///
    b(%9.3f) se(%9.3f) ///
    title("Quantile Regression of Log Volatility") ///
    keep(L_baa_aaa_spread L_treasury_10y_3m_spread L_implied_vol L_neg_log_ret _cons) ///
    stats(N r2_p_q1 r2_p_q2 r2_p_q3, /// // Using correct scalar names from ereturn list
          fmt(%9.0gc %9.3f %9.3f %9.3f) ///
          labels("Observations" "Pseudo R-sq (Q25)" "Pseudo R-sq (Q50)" "Pseudo R-sq (Q75)") ///
          nostar) ///
    starlevels(* 0.10 ** 0.05 *** 0.001) ///
    mtitles("25th Quantile" "50th Quantile (Median)" "75th Quantile") ///
    nonumbers ///
    addnote("Standard errors in parentheses. Data source: bitcoin\_dataset\_clean.csv. Variables are lagged one period.")

* --- End of Script ---
log close // Log commented out
