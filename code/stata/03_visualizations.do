********************************************************************************
* Do-file:      03_visualizations_fixedY_explicit_ticks.do
* Purpose:      Generate coefficient plots with specified fixed Y-axis ranges
* and explicit tick guidance, avoiding 'exact' option.
* Exports to:   PDF and PNG with identical dimensions for all plots.
* Date:         May 22, 2025
********************************************************************************

clear all
set more off
set scheme s2color

* --- 1. Define Paths ---
local project_base_path "/home/lr/Documents/HUNTER_SPRING/DEB_NONLINEAR/FINAL PROJECT/"
local figures_path "`project_base_path'FIGURES/"

capture mkdir "`figures_path'"

* --- 2. Common Settings ---
local critval = invnormal(0.975)

* --- Standard Export Dimensions for ALL PLOTS ---
local pdf_width = 7
local pdf_height = 4.2
local png_width = 1400
local png_height = 840

* --- 3. Plot for L_baa_aaa_spread ("baa") ---
clear
input str30 varname str10 model_type float x_plot_val float actual_quantile coef se
"L_baa_aaa_spread" "QReg"  1 0.25 .2176301 .0707064
"L_baa_aaa_spread" "QReg"  2 0.50 .1949009 .0765379
"L_baa_aaa_spread" "QReg"  3 0.75 .2950031 .0631350
"L_baa_aaa_spread" "OLS"   2 0.50 .2677381 .0500451
end

gen ci_low = coef - `critval' * se
gen ci_high = coef + `critval' * se

display "For L_baa_aaa_spread: Using fixed Y-axis range (0 0.5) with explicit ticks"

twoway ///
    (rarea ci_high ci_low x_plot_val if model_type=="QReg", color(maroon*0.15) lcolor(maroon*0.15) sort) ///
    (line coef x_plot_val if model_type=="QReg", lcolor(maroon) lpattern(solid) lwidth(medthick)) ///
    (scatter coef x_plot_val if model_type=="QReg", mcolor(maroon) msymbol(D) msize(2.3)) ///
    (rcap ci_low ci_high x_plot_val if model_type=="OLS", horizontal lcolor(dknavy*0.7) lwidth(vthin) lpattern(dash)) ///
    (scatter coef x_plot_val if model_type=="OLS", mcolor(dknavy) msymbol(S) msize(2.3) ///
        mlabel(coef) mlabformat(%3.3f) mlabposition(12) mlabangle(0) mlabgap(tiny) mlabcolor(black) mlabsize(vsmall)) ///
    , ///
    ytitle("Coefficient Estimate", size(tiny) margin(vsmall)) ///
    ylabel(0(0.1)0.5, angle(horizontal) labsize(tiny) grid glpattern(dot) glcolor(gs14)) /// /* Explicit ticks */
    xtitle(" ", size(tiny) margin(none)) ///
    xlabel(1 "Q25" 2 "Q50/OLS" 3 "Q75", labsize(tiny) noticks) ///
    title("Impact of Lagged Baa-Aaa Spread", size(vsmall) color(black) margin(vsmall)) ///
    subtitle("QR (Shaded 95% CI) vs. OLS", size(tiny) color(gs8)) ///
    legend(order(3 "QR Coef." 1 "QR 95% CI" 5 "OLS Coef.") pos(11) ring(0) col(1) size(tiny) region(lwidth(none) fcolor(none) margin(vsmall))) ///
    graphregion(margin(none) fcolor(white) lcolor(white)) ///
    plotregion(margin(none) fcolor(white) lcolor(black) lwidth(vvthin)) ///
    xscale(range(1 3) noline) ///
    yscale(range(0 0.5)) /// /* User specified Y-axis range, no noline */
    name(p_baa_explY, replace)

graph export "`figures_path'p_baa_explY.pdf", width(`pdf_width') height(`pdf_height') replace
graph export "`figures_path'p_baa_explY.png", width(`png_width') height(`png_height') replace
di "Exported p_baa_explY (PDF and PNG)"

* --- 4. Plot for L_implied_vol ("imp") ---
clear
input str30 varname str10 model_type float x_plot_val float actual_quantile coef se
"L_implied_vol" "QReg" 1 0.25 .0195332 .0006594
"L_implied_vol" "QReg" 2 0.50 .0172033 .0009281
"L_implied_vol" "QReg" 3 0.75 .0187183 .0004731
"L_implied_vol" "OLS"  2 0.50 .0190995 .0004262
end
gen ci_low = coef - `critval' * se
gen ci_high = coef + `critval' * se

display "For L_implied_vol: Using fixed Y-axis range (0 0.5) with explicit ticks"

twoway ///
    (rarea ci_high ci_low x_plot_val if model_type=="QReg", color(maroon*0.15) lcolor(maroon*0.15) sort) ///
    (line coef x_plot_val if model_type=="QReg", lcolor(maroon) lpattern(solid) lwidth(medthick)) ///
    (scatter coef x_plot_val if model_type=="QReg", mcolor(maroon) msymbol(D) msize(2.3)) ///
    (rcap ci_low ci_high x_plot_val if model_type=="OLS", horizontal lcolor(dknavy*0.7) lwidth(vthin) lpattern(dash)) ///
    (scatter coef x_plot_val if model_type=="OLS", mcolor(dknavy) msymbol(S) msize(2.3) ///
        mlabel(coef) mlabformat(%6.4f) mlabposition(12) mlabangle(0) mlabgap(tiny) mlabcolor(black) mlabsize(vsmall)) ///
    , ///
    ytitle("Coefficient Estimate", size(tiny) margin(vsmall)) ///
    ylabel(0(0.1)0.5, angle(horizontal) labsize(tiny) grid glpattern(dot) glcolor(gs14) format(%5.4f)) /// /* Explicit ticks */
    xtitle(" ", size(tiny) margin(none)) ///
    xlabel(1 "Q25" 2 "Q50/OLS" 3 "Q75", labsize(tiny) noticks) ///
    title("Impact of Lagged Implied Volatility", size(vsmall) color(black) margin(vsmall)) ///
    subtitle("QR (Shaded 95% CI) vs. OLS", size(tiny) color(gs8)) ///
    legend(order(3 "QR Coef." 1 "QR 95% CI" 5 "OLS Coef.") pos(11) ring(0) col(1) size(tiny) region(lwidth(none) fcolor(none) margin(vsmall))) ///
    graphregion(margin(none) fcolor(white) lcolor(white)) ///
    plotregion(margin(none) fcolor(white) lcolor(black) lwidth(vvthin)) ///
    xscale(range(1 3) noline) ///
    yscale(range(0 0.5)) /// /* User specified Y-axis range, no noline */
    name(p_imp_explY, replace)
graph export "`figures_path'p_imp_explY.pdf", width(`pdf_width') height(`pdf_height') replace
graph export "`figures_path'p_imp_explY.png", width(`png_width') height(`png_height') replace
di "Exported p_imp_explY (PDF and PNG)"

* --- 5. Plot for L_neg_log_ret ("neg") ---
clear
input str30 varname str10 model_type float x_plot_val float actual_quantile coef se
"L_neg_log_ret" "QReg" 1 0.25 -3.685050 .7479351
"L_neg_log_ret" "QReg" 2 0.50 -2.922411 .6534365
"L_neg_log_ret" "QReg" 3 0.75 -1.460127 .6397796
"L_neg_log_ret" "OLS"  2 0.50 -2.568606 .5771519
end
gen ci_low = coef - `critval' * se
gen ci_high = coef + `critval' * se

display "For L_neg_log_ret: Using fixed Y-axis range (-6 0) with explicit ticks"

twoway ///
    (rarea ci_high ci_low x_plot_val if model_type=="QReg", color(maroon*0.15) lcolor(maroon*0.15) sort) ///
    (line coef x_plot_val if model_type=="QReg", lcolor(maroon) lpattern(solid) lwidth(medthick)) ///
    (scatter coef x_plot_val if model_type=="QReg", mcolor(maroon) msymbol(D) msize(2.3)) ///
    (rcap ci_low ci_high x_plot_val if model_type=="OLS", horizontal lcolor(dknavy*0.7) lwidth(vthin) lpattern(dash)) ///
    (scatter coef x_plot_val if model_type=="OLS", mcolor(dknavy) msymbol(S) msize(2.3) ///
        mlabel(coef) mlabformat(%3.2f) mlabposition(2) mlabangle(0) mlabgap(vsmall) mlabcolor(black) mlabsize(vsmall)) ///
    , ///
    ytitle("Coefficient Estimate", size(tiny) margin(vsmall)) ///
    ylabel(-6(1)0, angle(horizontal) labsize(tiny) grid glpattern(dot) glcolor(gs14)) /// /* Explicit ticks */
    xtitle(" ", size(tiny) margin(none)) ///
    xlabel(1 "Q25" 2 "Q50/OLS" 3 "Q75", labsize(tiny) noticks) ///
    title("Impact of Lagged Negative Log Returns (Leverage)", size(vsmall) color(black) margin(vsmall)) ///
    subtitle("QR (Shaded 95% CI) vs. OLS", size(tiny) color(gs8)) ///
    legend(order(3 "QR Coef." 1 "QR 95% CI" 5 "OLS Coef.") pos(11) ring(0) col(1) size(tiny) region(lwidth(none) fcolor(none) margin(vsmall))) ///
    graphregion(margin(none) fcolor(white) lcolor(white)) ///
    plotregion(margin(none) fcolor(white) lcolor(black) lwidth(vvthin)) ///
    xscale(range(1 3) noline) ///
    yscale(range(-6 0)) /// /* User specified Y-axis range, no noline */
    name(p_neg_explY, replace)
graph export "`figures_path'p_neg_explY.pdf", width(`pdf_width') height(`pdf_height') replace
graph export "`figures_path'p_neg_explY.png", width(`png_width') height(`png_height') replace
di "Exported p_neg_explY (PDF and PNG)"

* --- End of Script ---
