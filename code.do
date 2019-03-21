***********cleandata**************
use merged
generate RetentionCEO = 0
replace RetentionCEO =1 if CEOANN == "CEO"
generate RetentionCFO = 0 
replace RetentionCFO = 1 if CFOANN == "CFO"
drop CEOANN
drop CFOANN
drop DEFER_RPT_AS_COMP_TOT
drop DEFER_CONTRIB_CO_TOT
drop DEFER_EARNINGS_TOT
drop EXECID
drop FIRMNAME
drop SAL_PCT
generate lnTotPay = ln(TDC1)
generate lnsalary = ln(SALARY)
generate lnNonEq = ln(NONEQ_INCENT)
generate lnDefer = ln(DEFER_BALANCE_TOT+1)
generate lnTotAsset = ln(TOTALASSET)
generate ROA = NETINCOME/TOTALASSET
generate TobinQ = (TOTALASSET+(COMMONSHARESOUTSTANDING*PRICECLOSE)-COMMONEQUITY)/TOTALASSET
count if DEFER_BALANCE_TOT == 0
count if defer_balance_TOT == .
*generate group for deferred compensation(group1 is zero deferred compensation, group 2 is not)
generate groupdefer = 1 if DEFER_BALANCE_TOT == 0
replace groupdefer = 2 if DEFER_BALANCE_TOT != 0
graph twoway (scatter TobinQ RetentionCEO if groupdefer ==1)(scatter TobinQ RetentionCEO if groupdefer ==2)
distplot TobinQ, over(groupdefer)
distplot RetentionCEO, over(groupdefer)
generate DeferDummy = 0 if groupdefer == 1
replace DeferDummy =1 if groupdefer == 2
summarize DeferredCompensation RetentionCEO RetentionCFO lnTotPay lnsalary lnNonEq lnTotAsset ROA TobinQ DeferDummy
generate Qinit = 0
*drop duplicates
duplicates report MIXID YEAR
duplicates tag MIXID YEAR, gen(isdup)
drop if isdup>0
*66,170 with no deferred compensation
drop if DeferredCompensation == 0
generate lndeferred = ln(DeferredCompensation)
*panel linear regression
xtreg lndeferred RetentionCEO RetentionCFO lnTotPay lnsalary lnTotAsset ROA TobinQ lnNonEq, fe
*cross-sectional average Q
bys GVKEY: egen average_Q = mean(TobinQ) if inrange(YEAR, 2006, 2018)
distplot average_Q, over(DeferDummy)
*generate Qlow
bys MIXID: egen Qlow = min(TobinQ) if inrange(YEAR, 2006, 2018)
*generate Qinit
bys MIXID: egen min_year = min(YEAR)
bys MIXID: generate Qinit = TobinQ if (YEAR == min_year)
bys MIXID: egen Qtest = max(Qinit) if inrange(YEAR, 2006, 2018)
*Qlow is the lowest tobins Q in a CEO's tenure
*Qinit is the initial Q from the beginning of CEOs tenure
*generate industry fixed effect
gen Industry = int(SIC/100)
summarize Industry
*create lag variables
sort MIXID YEAR
by MIXID: gen lag_TobinQ = TobinQ[_n-1] if YEAR == YEAR[_n-1]+1
by MIXID: gen lag_TotAsset = lnTotAsset[_n-1] if YEAR == YEAR[_n-1]+1
by MIXID: gen lag_ROA = ROA[_n-1] if YEAR == YEAR[_n-1]+1
********************************REGRESSIONS***********************
eststo: xtreg lnTotPay Qinit  lag_TobinQ  lag_TotAsset lag_ROA 
eststo: xtreg lnTotPay Qinit  lag_TobinQ  lag_TotAsset lag_ROA i.YEAR 
eststo: xtreg lnTotPay Qinit  lag_TobinQ  lag_TotAsset lag_ROA i.Industry
eststo: xtreg lnTotPay Qinit  lag_TobinQ  lag_TotAsset lag_ROA i.YEAR i.Industry
esttab using reg4.tex

eststo: xtreg lndeferred Qinit lag_TobinQ lag_TotAsset lag_ROA
eststo: xtreg lndeferred Qinit lag_TobinQ lag_TotAsset lag_ROA i.YEAR
eststo: xtreg lndeferred Qinit lag_TobinQ lag_TotAsset lag_ROA i.Industry
eststo: xtreg lndeferred Qinit lag_TobinQ lag_TotAsset lag_ROA i.YEAR i.Industry
esttab using reg3.tex
****
*eststo: xtreg lndeferred Qinit TobinQ lag_TobinQ lnTotAsset ROA lag_TotAsset lag_ROA
*eststo: xtreg lndeferred Qinit TobinQ lag_TobinQ lnTotAsset ROA lag_TotAsset lag_ROA i.YEAR
*eststo: xtreg lndeferred Qinit TobinQ lag_TobinQ lnTotAsset ROA lag_TotAsset lag_ROA i.Industry
*eststo: xtreg lndeferred Qinit TobinQ lag_TobinQ lnTotAsset ROA lag_TotAsset lag_ROA i.YEAR i.Industry
*esttab using reg3.tex
****
eststo: xtprobit RetentionCEO Qinit ROA lag_TobinQ lag_TotAsset lag_ROA
eststo: xtprobit RetentionCEO Qinit ROA lag_TobinQ lag_TotAsset lag_ROA i.YEAR, re
eststo: xtprobit RetentionCEO Qinit ROA lnTotAsset lnTotPay TobinQ lag_TobinQ lag_TotAsset lag_ROA i.YEAR, re
eststo: xtprobit RetentionCFO Qinit ROA lnTotAsset lnTotPay TobinQ lag_TobinQ lag_TotAsset lag_ROA i.YEAR, re
esttab using reg2.tex


eststo: xtprobit RetentionCFO Qinit ROA lag_TobinQ lag_TotAsset lag_ROA i.YEAR, re
eststo: xtprobit RetentionCFO Qinit ROA lnTotAsset lnTotPay TobinQ lag_TobinQ lag_TotAsset lag_ROA i.YEAR, re
eststo: xtprobit RetentionCFO Qinit ROA lnTotAsset lnTotPay TobinQ lag_TobinQ lag_TotAsset lag_ROA i.YEAR i.Industry, re
esttab using reg2_CFO.tex







