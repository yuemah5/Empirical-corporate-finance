/******************************************************************************
YUE MA, FIN591 HW5 W2019
 *****************************************************************************/
 
*clean data
clear

use data2

merge m:1 gvkey datadate using data1

destring SICS1, replace
destring sic_2, replace
destring sic_3, replace
destring gvkey, replace

gen year = year(datadate)

* Based on Berger and Ofek(1995)
* select target firms 
drop if SICS1 >= 6000 & SICS1 <= 6999
* Drop if sales are less than $20m
drop if sale < 20
* Drop if there is no underlying segment data
drop if _merge == 1
* Drop if total capital is missing
gen actual_capital = mcap + dltt + dlc
drop if actual_capital == .
* Drop if the summed sales from the segments is different by more than 1%
gen perc_diff = abs((totsales - sale) / sale)
drop if perc_diff > 0.01
* Drop if the firm doesn't report 4 digit sic code for any segment
sort gvkey year
by gvkey year: gen sic_exist = 1 if SICS1 != .
by gvkey year: replace sic_exist = sum(sic_exist)
by gvkey year: replace sic_exist = sic_exist[_N]
keep if sic_exist == nseg

gen dummy = 0
replace dummy = 1 if nseg > 1

* Generate the used sic observations.
* use the finest cut of sic such that at least 5 observations exist
gen nvals = 1 if SICS1 != . & dummy == 0
by year SICS1, sort: replace nvals = sum(nvals)
by year SICS1: replace nvals = nvals[_N]
replace nvals = 0 if nvals == .
gen selected_sic = SICS1 if nvals >=5

drop nvals
gen nvals = 1 if sic_3 != . & dummy == 0 & selected_sic == .
by year sic_3, sort: replace nvals = sum(nvals) if selected_sic == .
by year sic_3: replace nvals = nvals[_N] if selected_sic == .
replace nvals = 0 if nvals == .
replace selected_sic = sic_3 if nvals >=5

drop nvals
gen nvals = 1 if sic_2 != . & dummy == 0 & selected_sic == .
by year sic_2, sort: replace nvals = sum(nvals) if selected_sic == .
by year sic_2: replace nvals = nvals[_N] if selected_sic == .
replace nvals = 0 if nvals == .
replace selected_sic = sic_2 if nvals >=5


*excess value

gen segment_sales = actual / sales
gen segment_sales_single  = segment_sales if dummy == 0
egen median_ind_sales = median(segment_sales_single), by (selected_sic year)
egen median_ind_sales_2 = median(segment_sales_single), by (sic_2 year)
egen median_ind_sales_3 = median(segment_sales_single), by (sic_3 year)
egen median_ind_sales_4 = median(segment_sales_single), by (SICS1 year)
gen imputed_sales_by_segment = sales*median_ind_sales
gen imputed_sales_by_segment_2 = sales* median_ind_sales_2
gen imputed_sales_by_segment_3 = sales* median_ind_sales_3
gen imputed_sales_by_segment_4 = sales* median_ind_sales_4
egen imputed_sales = sum(imputed_sales_by_segment), by (gvkey year)
egen imputed_sales_2 = sum(imputed_sales_by_segment_2), by (gvkey year)
egen imputed_sales_3 = sum(imputed_sales_by_segment_3), by (gvkey year)
egen imputed_sales_4 = sum(imputed_sales_by_segment_4), by (gvkey year)
gen excess_value_sales = ln(actual_cap / imputed_sales)
gen excess_value_sales_2 = ln(actual_cap / imputed_sales_2)
gen excess_value_sales_3 = ln(actual_cap / imputed_sales_3)
gen excess_value_sales_4 = ln(actual_cap / imputed_sales_4)

gen segment_assets = actual / ias
gen segment_assets_single = segment_assets if dummy == 0
egen median_ind_assets = median(segment_assets_single), by(selected_sic year)
egen median_ind_assets_2 = median(segment_assets_single), by (sic_2 year)
egen median_ind_assets_3 = median(segment_assets_single), by (sic_3 year)
egen median_ind_assets_4 = median(segment_assets_single), by (SICS1 year)
gen imputed_assets_by_segment = sales*median_ind_assets
gen imputed_assets_by_segment_2 = sales*median_ind_assets_2
gen imputed_assets_by_segment_3 = sales*median_ind_assets_3
gen imputed_assets_by_segment_4 = sales*median_ind_assets_4
egen imputed_assets = sum(imputed_assets_by_segment), by(gvkey year)
egen imputed_assets_2 = sum(imputed_assets_by_segment_2), by (gvkey year)
egen imputed_assets_3 = sum(imputed_assets_by_segment_3), by (gvkey year)
egen imputed_assets_4 = sum(imputed_assets_by_segment_4), by (gvkey year)
gen excess_value_assets = ln(actual / imputed_assets)
gen excess_value_assets_2 = ln(actual / imputed_assets_2)
gen excess_value_assets_3 = ln(actual / imputed_assets_3)
gen excess_value_assets_4 = ln(actual / imputed_assets_4)

save full_set, replace

* Trim data down to firm-year observations
duplicates drop gvkey year, force

* Calculate control variables
gen assets = ln(at)
gen capsale_mul = capx / sale
gen ebitsale_mul = ebit / sale

* Run cross sectional regressions
* The 2,3,4 digit level ones will be robustness and the focus is on the 
* BO ones
xtset gvkey year

xtreg excess_value_sales dummy assets capsale_mul ebitsale_mul, fe
est store Coeff
outreg2 [Coeff] using "ps6_p1.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append

xtreg excess_value_assets dummy assets capsale_mul ebitsale_mul, fe
est store Coeff
outreg2 [Coeff] using "ps6_p1.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append

xtreg excess_value_sales_2 dummy assets capsale_mul ebitsale_mul, fe
est store Coeff
outreg2 [Coeff] using "ps6_p1_robust.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append
xtreg excess_value_sales_3 dummy assets capsale_mul ebitsale_mul, fe
est store Coeff
outreg2 [Coeff] using "ps6_p1_robust.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append
xtreg excess_value_sales_4 dummy assets capsale_mul ebitsale_mul, fe
est store Coeff
outreg2 [Coeff] using "ps6_p1_robust.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append

xtreg excess_value_assets_2 dummy assets capsale_mul ebitsale_mul, fe
est store Coeff
outreg2 [Coeff] using "ps6_p1_robust.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append
xtreg excess_value_assets_3 dummy assets capsale_mul ebitsale_mul, fe
est store Coeff
outreg2 [Coeff] using "ps6_p1_robust.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append
xtreg excess_value_assets_4 dummy assets capsale_mul ebitsale_mul, fe
est store Coeff
outreg2 [Coeff] using "ps6_p1_robust.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append

save part_1, replace

* PART TWO

clear

use part_1

* IV - number of diversified firms as a fraction of total firms in a given industry
egen num_diversified = sum(dummy), by(selected_sic)
gen one = 1
egen num_total = sum(one), by(selected_sic)
gen iv1 = num_diversified / num_total

* Generate the second IV - percentage of sales accounted for by the
* diversified firms
egen total_sales = sum(sale), by (selected_sic)
replace total_sales = total_sales - sale
egen diversified_sales = sum(sale) if dummy == 1, by (selected_sic)
egen median_div_sales = median(diversified_sales), by(selected_sic)
replace median_div_sales = 0 if median_div_sales == .
gen iv2 = median_div_sales / total_sales

reg dummy iv1 assets capsale_mul ebitsale_mul
est store c0

reg dummy iv2 assets capsale_mul ebitsale_mul
est store c00

ivreg excess_value_sales assets capsale_mul ebitsale_mul (dummy = iv1 iv2)
est store Coeff
outreg2 [Coeff] using "ps6_p2.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append

ivreg excess_value_assets assets capsale_mul ebitsale_mul (dummy = iv1 iv2)
est store Coeff
outreg2 [Coeff] using "ps6_p2.xls" , stats(coef se) alpha(0.001, 0.01, 0.05) append
