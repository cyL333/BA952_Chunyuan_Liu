 ***** Preprocess the data *****
 use "C:\Users\lcyhk\Desktop\raw data\Annual.dta", clear
 destring gvkey, replace
 sort gvkey fyear
 xtset gvkey fyear
 drop indfmt consol popsrc datafmt curcd
 
 * Has line of credit {0,1}
 * lineofcredit was included in Professor Sufi's dataset
 
 ***** Firm characteristics for the full sample *****
 * Book debt/assets = (short-term debt + long-term debt) / assets
 gen bd = (dlc + dltt) / at
 
 * EBITDA / (assets - cash)
 * Lagged
 gen EBITDA_assetmcash = oibdp / (at - che)
 gen cflcl1 = l.EBITDA_assetmcash
 
 * Tangible assets/(assets − cash)
 * Lagged
 gen  tang_assetmcash = ppent / (at - che)
 gen tanglcl1 = l.tang_assetmcash
 
 * Net worth, cash adjusted
 * Lagged
 gen networth = (at-che-lt) / (at - che)
 gen nwlcl1 = l.networth
 
 * Assets − cash
 * Lagged
 gen assetmcash = at - che
 gen asslcl1 = l.assetmcash
 
 * Market-to-book, cash adjusted
 * Lagged
 gen bookvalue_equity = at - lt - pstkl + txditc
 gen marketvalue_equity = csho * prcc_f
 gen markettobook_ratio = (at - bookvalue_equity + marketvalue_equity - che) / (at - che)
 gen mblcl1 = l.markettobook_ratio
 
 * Sort two datasets
 gen yeara = fyear
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\Annual_done.dta", 
 clear
 
 use "C:\Users\lcyhk\Desktop\raw data\sufi_rfs_linesofcredit.dta"
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\sufi_sorted.dta"
 clear 
 
 ***** Industry sales volatility *****
 use "C:\Users\lcyhk\Desktop\raw data\Quarter.dta", clear
 destring gvkey, replace
 drop indfmt consol popsrc datafmt curcdq

 * Create a new variable 'qdate' and set data structure for panel analysis
 gen quarter = yq(fyearq, fqtr)
 xtset gvkey quarter

 * Calculate std of quarterly differencesin sales
 gen saleq_dif = saleq - l.saleq
 egen saleq_dif_std = sd(saleq_dif), by(gvkey fyearq)

 * Scaled by average assets over the year
 egen avg_assets = mean(atq), by(gvkey fyearq)
 gen scaled_std = saleq_dif_std / avg_assets
 keep if inrange(fyear, 1996, 2003)
 
 * Obtain the median across all 3-digit SIC industries
 tostring sic, replace
 gen sic_3 = substr(sic,1,3)
 egen q_salesvol = median(scaled_std), by(sic_3 fyearq)

 duplicates drop gvkey fyearq, force
 gen yeara = fyear
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\sales_done.dta"

 ***** Cash-flow volatility *****
 * Preprocessing data
 use "C:\Users\lcyhk\Desktop\raw data\cf_volatility.dta", clear
 destring gvkey, replace
 sort gvkey fyear
 xtset gvkey fyear
 drop indfmt consol popsrc datafmt curcd costat
 
 * Calculate EBITDA annual change and non-cash assets
 gen oibdp_dif = oibdp - l.oibdp
 gen noncash_at = at - che
 
 * Calculate std of EBITDA change and average non-cash assets over a lagged four-year period
 ssc install rangestat
 rangestat (sd) std_four_change = oibdp_dif, interval(fyear -3 0) by(gvkey)
 rangestat (mean) mean_four_at = noncash_at, interval(fyear -3 0) by(gvkey)
 
 * Calculate cash flow volatility
 gen cf_vol = std_four_change / mean_four_at
 drop if fyear < 1996 | fyear > 2003
 gen yeara = fyear
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\cf_vol_done.dta"
 
 * Not in an S&P index {0,1}
 use "C:\Users\lcyhk\Desktop\raw data\SPMIM_data.dta", clear
 sort gvkey fyear
 gen spmim_true = 0
 replace spmim_true = 1 if spmim == .
 duplicates drop gvkey fyear, force
 gen yeara = fyear
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\SPMIM_data_done.dta"
 
*************************************************************************************
 * Merge all datasets
 use "C:\Users\lcyhk\Desktop\Processed_data\Annual_done.dta"
 merge gvkey yeara using C:\Users\lcyhk\Desktop\Processed_data\sufi_sorted.dta
 table _merge
 keep if _merge == 3
 drop _merge
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\1Annual_merged.dta"
 
 use "C:\Users\lcyhk\Desktop\Processed_data\1Annual_merged.dta"
 merge gvkey yeara using C:\Users\lcyhk\Desktop\Processed_data\sales_done.dta
 table _merge
 keep if _merge == 3"
 drop _merge
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\2sales_merged.dta"
 
 use "C:\Users\lcyhk\Desktop\Processed_data\2sales_merged.dta"
 merge gvkey yeara using C:\Users\lcyhk\Desktop\Processed_data\cf_vol_done.dta
 table _merge
 keep if _merge == 3
 drop _merge
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\3cf_vol_merged.dta"
 
 use "C:\Users\lcyhk\Desktop\Processed_data\SPMIM_data_done.dta"
 sort gvkey yeara
 merge gvkey yeara using C:\Users\lcyhk\Desktop\Processed_data\3cf_vol_merged.dta
 table _merge
 keep if _merge == 3
 drop _merge
 drop fyearq fqtr datacqtr datafqtr atq dlttq ltq oibdpq ppentq saleq prccq saleq_dif avg_assets scaled_std sic_3 oibdp_dif noncash_at
 save "C:\Users\lcyhk\Desktop\Processed_data\4not_s&p_merged.dta"
 *************************************************************************************
 * Traded over the counter {0,1}
 use "C:\Users\lcyhk\Desktop\Processed_data\4not_s&p_merged.dta", clear
 gen trdOTC = 0
 replace trdOTC = 1 if exchg == 19 
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\trdOTC_done.dta" 
 
 * Firm age (years since IPO)
 use "C:\Users\lcyhk\Desktop\raw data\Firm age.dta", clear
 destring gvkey, replace
 sort gvkey fyear
 drop indfmt consol popsrc datafmt curcd costat
 
 * Generate a new variable to record the first year for each gvkey
  bysort gvkey: egen min_fyear = min(fyear)
 
 * Calculate firm age for each gvkey
 keep if fyear >= 1996 & fyear <= 2003
 gen firmage = fyear - min_fyear + 3
 gen yeara = fyear
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\Firm age_done.dta"
*************************************************************************************
 * Merge the remaining datasets
 use "C:\Users\lcyhk\Desktop\Processed_data\4not_s&p_merged.dta"
 sort gvkey yeara
 merge gvkey yeara using C:\Users\lcyhk\Desktop\Processed_data\trdOTC_done.dta
 table _merge
 keep if _merge == 3
 drop _merge
 sort gvkey yeara
 save "C:\Users\lcyhk\Desktop\Processed_data\5trdOTC_merged.dta"
 
 use "C:\Users\lcyhk\Desktop\Processed_data\Firm age_done.dta", clear
 sort gvkey yeara
 merge gvkey yeara using C:\Users\lcyhk\Desktop\Processed_data\5trdOTC_merged.dta
 table _merge
 keep if _merge == 3
 drop _merge
 * tabstat firmage, s(mean p50 sd n) col(stat) f(%7.3f)
 save "C:\Users\lcyhk\Desktop\Processed_data\6firmage_merged.dta"
 
*************************************************************************************
 ***** Line of credit variables *****
 use "C:\Users\lcyhk\Desktop\Processed_data\6firmage_merged.dta", clear
 * Has line of credit {0,1}
 * Included in Professor Sufi's dataset
 
 * Total line of credit/assets
 gen ra_linetot = linetot / at
 
 * Unused line of credit/assets
 gen ra_lineun = lineun / at
 
 * Used line of credit/assets
 gen ra_line = line / at
 
 * Total line/(total line + cash)
 gen liq_linetot = linetot / (linetot + che)
 
 * Unused line/(unused line + cash)
 gen liq_lineun = lineun / (lineun + che)
 
 * Violation of financial covenant {0,1}
 * Included in Professor Sufi's dataset
 gen firmage1 = firmage - 5
 
 save "C:\Users\lcyhk\Desktop\Processed_data\7Table_1.dta"
 *************************************************************************************
 ***** Winsorize at 5th and 95th percentile *****
 use "C:\Users\lcyhk\Desktop\Processed_data\7Table_1.dta", clear
 ssc install winsor
 ssc install winsor2
 
 local FinVar cflcl1 tanglcl1 nwlcl1 mblcl1 cf_vol
foreach x in `FinVar'{
	winsor `x', p(0.05) gen(`x'Winsor)
}
 save "C:\Users\lcyhk\Desktop\Processed_data\7Table_1_winsor.dta"

 *************************************************************************************
 ***** Table 1 *****
 tabstat lineofcredit bd cflcl1Winsor tanglcl1Winsor nwlcl1Winsor asslcl1 mblcl1Winsor q_salesvol cf_volWinsor spmim_true trdOTC firmage, s(mean p50 sd n) col(stat) f(%7.3f)
 
 tabstat lineofcredit_rs ra_linetot ra_lineun ra_line liq_linetot liq_lineun def bd cflcl1Winsor tanglcl1Winsor nwlcl1Winsor asslcl1 mblcl1Winsor q_salesvol cf_volWinsor spmim_true trdOTC firmage1 if randomsample==1, s(mean p50 sd n) col(stat) f(%7.3f) 
 *************************************************************************************
 ***** Table 3 *****
 use "C:\Users\lcyhk\Desktop\Processed_data\7Table_1_winsor.dta", clear
 sort gvkey fyear
 
 * Ln(assets - cash)_t-1
 gen lasslcl1 = ln(asslcl1)
 * Industry sales volatility_t-1
 gen q_salesvol1 = l.q_salesvol
 * Cash-flow volatility_t-1
 gen cf_vol1 = l.cf_vol
 * Ln(Firm age (years since IPO))_t-1
 gen lagfirmage = l.firmage
 gen lfirmage = ln(lagfirmage)
 * Regressions use 1-digit industry indicator variables
 gen sic_1d = substr(sic,1,1)
 destring sic_1d, replace
 
 * Winsorize
 local FinVar lasslcl1 q_salesvol1 cf_vol1 lfirmage
foreach x in `FinVar'{
	winsor `x', p(0.10) gen(`x'Winsor)
}
 
 * Regression
 xi: dprobit lineofcredit i.yeara i.sic_1d cflcl1Winsor tanglcl1Winsor lasslcl1Winsor nwlcl1Winsor mblcl1Winsor q_salesvol1Winsor cf_vol1Winsor spmim_true exch lfirmageWinsor, vce(cluster gvkey)
  outreg2 using "C:\Users\lcyhk\Desktop\Processed_data\Table3_part1", replace
 
 xi: dprobit lineofcredit_rs i.yeara i.sic_1d cflcl1Winsor tanglcl1Winsor lasslcl1Winsor nwlcl1Winsor mblcl1Winsor q_salesvol1Winsor cf_vol1Winsor spmim_true exch lfirmageWinsor if randomsample==1, vce(cluster gvkey)
  outreg2 using "C:\Users\lcyhk\Desktop\Processed_data\Table3_part2", replace
 
 xi: regress liq_linetot i.yeara i.sic_1d cflcl1Winsor tanglcl1Winsor lasslcl1Winsor nwlcl1Winsor mblcl1Winsor q_salesvol1Winsor cf_vol1Winsor spmim_true exch lfirmageWinsor if randomsample==1, vce(cluster gvkey) 
 est store r3
 
 xi: regress liq_linetot i.yeara i.sic_1d cflcl1Winsor tanglcl1Winsor lasslcl1Winsor nwlcl1Winsor mblcl1Winsor q_salesvol1Winsor cf_vol1Winsor spmim_true exch lfirmageWinsor if randomsample==1 & lineofcredit_rs==1, vce(cluster gvkey) 
 est store r4
 
 xi: regress liq_lineun i.yeara i.sic_1d cflcl1Winsor tanglcl1Winsor lasslcl1Winsor nwlcl1Winsor mblcl1Winsor q_salesvol1Winsor cf_vol1Winsor spmim_true exch lfirmageWinsor if randomsample==1, vce(cluster gvkey)
 est store r5
 
 xi: regress liq_lineun i.yeara i.sic_1d cflcl1Winsor tanglcl1Winsor lasslcl1Winsor nwlcl1Winsor mblcl1Winsor q_salesvol1Winsor cf_vol1Winsor spmim_true exch lfirmageWinsor if randomsample==1 & lineofcredit_rs==1, vce(cluster gvkey)
 est store r6
 
 ssc install estout
 esttab r* using C:\Users\lcyhk\Desktop\Processed_data\Table3_part3.rtf, replace
 
 *************************************************************************************
 ***** Figure 1 *****
 use "C:\Users\lcyhk\Desktop\Processed_data\7Table_1_winsor.dta", clear
 
 gen cash_assets = che / at
 xtile cfcat = cflcl1, nq(10)
 label variable cash_assets "Cash/assets"
 label variable cfcat "Deciles of EBITDA/(assets-cash)"
 label variable lineofcredit "Fraction with line of credit"
 
 * Calculate the mean values for "line of credit" and "cash/assets" & group based on cfcat
 collapse (mean) lineofcredit cash_assets, by(cfcat)
 
 * Generate Graph
 set scheme s1color
 twoway (connected cash_assets cfcat, mcolor(black) msymbol(lgx) lpattern(dash)) (connected lineofcredit cfcat, yaxis(2) mcolor(black) msymbol(square) lpattern(solid)), ylabel(0(0.1)0.6, angle(0) valuelabel grid glpattern(solid)) ylabel(0(0.1)1, angle(0) axis(2))  ytitle(Cash/assets, axis(1)) ytitle(Fraction with line of credit, axis(2)) xtitle(Deciles of EBITDA/(assets-cash)) 
 
 graph export "C:\Users\lcyhk\Desktop\Processed_data\/Figure1.png", replace