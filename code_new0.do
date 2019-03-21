use NEW0
*generate Qlow
bys MIXID: egen Qlow = min(TobinQ) if inrange(YEAR, 2006, 2018)
*generate Qinit
bys MIXID: egen min_year = min(YEAR)
bys MIXID: generate Qinit = TobinQ if (YEAR == min_year)
bys MIXID: egen Qtest = max(Qinit) if inrange(YEAR, 2006, 2018)
drop Qinit
rename Qtest Qinit
*plot Qinit with DeferredCompensation
set scheme s2color
distplot Qinit, over(DeferDummy),graphregion(color(white))
sort DeferDummy
by DeferDummy: summarize Qinit
sort MIXID YEAR
by MIXID: gen lag_TobinQ = TobinQ[_n-1] if YEAR == YEAR[_n-1]+1
by MIXID: gen lag_TotAsset = lnTotAsset[_n-1] if YEAR == YEAR[_n-1]+1
by MIXID: gen lag_ROA = ROA[_n-1] if YEAR == YEAR[_n-1]+1
*****************REGRESSION*******************
eststo: xtprobit DeferDummy Qinit lag_ROA lag_TotAsset lag_TobinQ, re
eststo: margins, dydx(*)


esttab using reg1.tex
*by MIXID: egen group_Retention_CEO = mean(RetentionCEO)
