 ***** Preprocess the data *****
 
 * Item 10 - pstkl
 * Transform annual data to quarterly data
 use "C:\Users\lcyhk\Desktop\raw data\Paper 2\Item10.dta", clear
 destring gvkey, replace
 sort gvkey fyear
 drop indfmt consol popsrc datafmt curcd costat
 expand 4
 sort gvkey fyear
 bysort gvkey fyear: gen fqtr = _n
 rename pstkl pstklq
 sort gvkey fyear fqtr
 save "C:\Users\lcyhk\Desktop\Processed_data_2\Item_10.dta"
 
 * Merge datasets
 use "C:\Users\lcyhk\Desktop\raw data\Paper 2\Main.dta", clear
 destring gvkey, replace
 drop datadate indfmt consol popsrc datafmt curcdq
 gen fyear = fyearq
 sort gvkey fyear fqtr
 merge gvkey fyear fqtr using C:\Users\lcyhk\Desktop\Processed_data_2\Item_10.dta
 table _merge
 keep if _merge == 3
 drop _merge
 sort gvkey fyear fqtr
 drop if missing(datacqtr)
 gen quarternum = yq(fyear,fqtr)
 duplicates drop gvkey quarternum, force
 xtset gvkey quarternum
 sort gvkey fyear fqtr
 save "C:\Users\lcyhk\Desktop\Processed_data_2\Merged_data.dta"
 
 ***** Summary Statistics *****
 use "C:\Users\lcyhk\Desktop\Processed_data_2\Merged_data.dta", clear
 sort gvkey quarternum
 * Book debt
 gen bookdebt = dlttq + dlcq
 
 ** Capital structure variables
 * Net debt issuance (basis points)
 gen atql = l.atq
 gen net_debt_issuance = (bookdebt - l.bookdebt) / atql * 10000
 
 * Net equity issuance (basis points)
 gen net_equity_inssuance = (sstky - prstkcy) / atql * 1000
 
 * Book debt/assets
 gen book_debtassets = bookdebt / atq
 
 ** Covenant control variables
 * Net worth/assets
 gen networth_asset = (atq - ltq) / atq
 
 * Net working capital/assets
 gen networkingcapital_asset = (actq - lctq) / atq
 
 * Cash/assets
 gen cash_assets = cheq / atq
 
 * EBITDA/assets_t-1
 gen EBITDA_asset = oibdpq / atql
 
 * Cash flow/assets_t-1
 gen cashflow_asset = (ibadjq + dpq) / atql
 
 * Net income/assets_t-1
 gen netincome_asset = niq / atql
 
 * Interest expense/assets_t-1
 gen interestexpense_asset = xintq / atql
 
 ** Other control variables
 * Market-to-book ratio
 gen marketvalue_equity = prccq * cshoq
 gen bookvalue_equity = atq - ltq - pstklq + txditcq
 gen markettobook_ratio = marketvalue_equity / bookvalue_equity
 
 * Tangible assets/assets
 gen tangible_asset = ppentq / atq
 
 * Ln(assets)
 gen lnAsset = ln(atq)
 
 save "C:\Users\lcyhk\Desktop\Processed_data_2\Paper 2_var.dta"
 

 * Prof. Sufi's data from Creditor Control Rights, Corporate Governance, and Firm Value
 * Extract the year, month and date from datadate
 use "C:\Users\lcyhk\Desktop\raw data\Paper 2\sufi_data.dta", clear
 gen fyear = substr(datadate,5,4)
 destring fyear, replace
 gen month = substr(datadate,1,2)
 destring month, replace
 sort gvkey fyear month
 
 * Label quarter
 gen fqtr = 4
 replace fqtr = 3 if month < 10
 replace fqtr = 2 if month < 7
 replace fqtr = 1 if month < 4
 sort gvkey fyear fqtr
 gen fyearq = fyear
 sort gvkey fyearq fqtr
 save "C:\Users\lcyhk\Desktop\Processed_data_2\sufi_data.dta"
 
 * Merge datasets
 use "C:\Users\lcyhk\Desktop\Processed_data_2\Paper 2_var.dta", clear
 sort gvkey fyearq fqtr
 merge gvkey fyearq fqtr using C:\Users\lcyhk\Desktop\Processed_data_2\sufi_data.dta
 table _merge
 drop if _merge == 2
 drop _merge
 drop if fyear < 1996 | fyear > 2005
 drop month
 sort gvkey fyearq fqtr
 save "C:\Users\lcyhk\Desktop\Processed_data_2\Paper 2.dta" 
 *************************************************************************************
 ***** Sample construction *****
 * Presence of both period t and t-1 data are required
 use "C:\Users\lcyhk\Desktop\Processed_data_2\Paper 2.dta", clear
 sort gvkey quarternum
 
 foreach var in bookdebt atq ltq lctq cheq oibdpq ibadjq dpq niq xintq prstkcy pstklq txditcq cshoq prccq {
    gen missing_`var' = missing(`var') | missing(l.`var')
 }
 
 drop if missing_bookdebt | missing_atq | missing_ltq | missing_lctq | missing_cheq | missing_oibdpq | missing_ibadjq | missing_dpq | missing_niq | missing_xintq | missing_prstkcy | missing_pstklq | missing_txditcq | missing_cshoq | missing_prccq

 foreach var in bookdebt atq ltq lctq cheq oibdpq ibadjq dpq niq xintq prstkcy pstklq txditcq cshoq prccq {
    drop missing_`var'
 }
 
 * Each firm should have at least four consecutive quarters of available data
 sort gvkey quarternum
 rangestat (count) count1 = gvkey, interval(quarter -3 0) by(gvkey)
 bysort gvkey: egen count2 = max(count1)
 keep if count2 >= 4
 drop count1 count2
 *************************************************************************************
 ***** Winsorize at 5th and 95th percentile *****
 ssc install winsor
 ssc install winsor2
 
 local FinVar net_debt_issuance net_equity_inssuance book_debtassets networth_asset networkingcapital_asset cash_assets EBITDA_asset cashflow_asset netincome_asset interestexpense_asset markettobook_ratio tangible_asset lnAsset
 foreach x in `FinVar'{
	winsor `x', p(0.05) gen(`x'Winsor)
	drop `x'
	rename `x'Winsor `x'
 }
 sort gvkey fyearq fqtr
 save "C:\Users\lcyhk\Desktop\Processed_data_2\Table 2.dta"
 
*************************************************************************************
 ***** Table 2 *****
 tabstat net_debt_issuance net_equity_inssuance book_debtassets networth_asset networkingcapital_asset cash_assets EBITDA_asset cashflow_asset netincome_asset interestexpense_asset markettobook_ratio tangible_asset lnAsset, s(mean p50 sd n) col(stat) f(%7.3f)
 
*************************************************************************************
 ***** Table 3 *****

 ***** S&P Rating *****
 use "C:\Users\lcyhk\Desktop\raw data\Paper 2\s&p.dta", clear
 destring gvkey, replace
 gen year = year(datadate)
 gen sp = 1
 replace sp = 0 if missing(splticrm) & missing(spsdrm) & missing(spsticrm) & missing(spcsrc)
 duplicates drop gvkey year sp, force
 sort gvkey year
 expand 4
 bysort gvkey year: gen fqtr = _n
 sort gvkey year fqtr
 save "C:\Users\lcyhk\Desktop\Processed_data_2\s&p.dta"
 
 * Merge datasets
 use "C:\Users\lcyhk\Desktop\Processed_data_2\s&p.dta", clear
 rename year fyearq
 sort gvkey fyearq fqtr
 merge gvkey fyearq fqtr using "C:\Users\lcyhk\Desktop\Processed_data_2\Table 2.dta"
 table _merge
 keep if _merge == 3
 drop _merge
 sort gvkey fyearq fqtr
 save "C:\Users\lcyhk\Desktop\Processed_data_2\Table 3.dta"
 
 ***** Panel A *****
 use "C:\Users\lcyhk\Desktop\Processed_data_2\Table 3.dta", clear
 * Find calender year-quarter indicator variables of each firm
 gen cyear = substr(datacqtr, 1, 4)
 destring cyear, replace
 gen cqtr = substr(datacqtr, length(datacqtr), 1)
 destring cqtr, replace
 gen cquarternum = yq(cyear,cqtr)
 duplicates drop gvkey quarternum, force
 
 * Install reghdfe
 ssc install reghdfe
 ssc install ftools
 
 * Column (1)
 xtset gvkey quarternum
 gen lviol = l.viol
 
 reghdfe net_debt_issuance viol l.viol, absorb(cquarternum fqtr) vce(cluster gvkey)
 
 * Column (2)
 * Include 11 covenant control variables
 reghdfe net_debt_issuance viol lviol l.lnAsset l.tangible_asset l.markettobook_ratio l.sp l.book_debtassets l.networth_asset l.cash_assets l.EBITDA_asset EBITDA_asset l.cashflow_asset cashflow_asset l.netincome_asset netincome_asset l.interestexpense_asset interestexpense_asset, absorb(gvkey cquarternum fqtr) vce(cluster gvkey)
 

 * Column (3)
 * Include 4 covenant control interaction variables
 gen inter1 = l.book_debtassets * l.cashflow_asset
 gen inter2 = l.book_debtassets * l.EBITDA_asset
 gen inter3 = l.book_debtassets * l.networth_asset
 gen inter4 = l.EBITDA_asset * l.interestexpense_asset
 
 reghdfe net_debt_issuance viol lviol l.lnAsset l.tangible_asset l.markettobook_ratio l.sp l.book_debtassets l.networth_asset l.cash_assets l.EBITDA_asset EBITDA_asset l.cashflow_asset cashflow_asset l.netincome_asset netincome_asset l.interestexpense_asset interestexpense_asset inter1 inter2 inter3 inter4, absorb(cquarternum fqtr) vce(cluster gvkey)
 
 
 * Column (4)
 gen lbook_debtassets = l.book_debtassets
 gen lnetworth_asset = l.networth_asset
 gen lcash_assets = l.cash_assets
 gen lEBITDA_asset = l.EBITDA_asset
 gen lcashflow_asset = l.cashflow_asset
 gen lnetincome_asset = l.netincome_asset
 gen linterestexpense_asset = l.interestexpense_asset
 
 local variables lbook_debtassets lnetworth_asset lcash_assets lEBITDA_asset EBITDA_asset lcashflow_asset cashflow_asset lnetincome_asset netincome_asset linterestexpense_asset interestexpense_asset inter1 inter2 inter3 inter4
 
 ssc inst egenmore
 * Generate squared and to the third power variables, and five quantile indicator variables
 foreach x in `variables'{
	gen `x'_2 = `x' ^ 2
	gen `x'_3 = `x' ^ 3
	egen `x'_qtl = xtile(`x'), nq(5)
 }
 
 reghdfe net_debt_issuance viol lviol l.lnAsset l.tangible_asset l.markettobook_ratio l.sp l.book_debtassets l.networth_asset l.cash_assets l.EBITDA_asset EBITDA_asset l.cashflow_asset cashflow_asset l.netincome_asset netincome_asset l.interestexpense_asset interestexpense_asset inter1 inter2 inter3 inter4 *_2 *_3 *_qtl, absorb(gvkey cquarternum fqtr) vce(cluster gvkey)
 
 
 ***** Panel B *****
 * Column (1)
 gen dif_net_debt_issuance = net_debt_issuance - l.net_debt_issuance
 
 reghdfe dif_net_debt_issuance viol l.viol, absorb(cquarternum fqtr) vce(cluster gvkey)
 
 
 * Column (2)
 local var1 lnAsset tangible_asset markettobook_ratio sp 
 foreach x in `var1'{
 	gen dif_`x' = l.`x' - l2.`x'
 }
 
 local var2 lnetworth_asset lcash_assets lEBITDA_asset EBITDA_asset lcashflow_asset cashflow_asset lnetincome_asset netincome_asset linterestexpense_asset interestexpense_asset
 foreach x in `var2'{
 	gen dif_`x' = `x' - l.`x'
 }
 
 gen dif_book_debtassets = book_debtassets - l2.book_debtassets
 
 reghdfe dif_net_debt_issuance viol lviol dif_lnAsset dif_tangible_asset dif_markettobook_ratio dif_sp dif_book_debtassets dif_lnetworth_asset dif_lcash_assets dif_lEBITDA_asset dif_EBITDA_asset dif_lcashflow_asset dif_cashflow_asset dif_lnetincome_asset dif_netincome_asset dif_linterestexpense_asset dif_interestexpense_asset, absorb(gvkey cquarternum fqtr) vce(cluster gvkey)
 
 
 * Column (3)
 gen dif_inter1 = inter1 - l2.inter1
 gen dif_inter2 = inter2 - l2.inter2
 gen dif_inter3 = inter3 - l2.inter3
 gen dif_inter4 = inter4 - l2.inter4
 
 reghdfe dif_net_debt_issuance viol lviol dif_lnAsset dif_tangible_asset dif_markettobook_ratio dif_sp dif_book_debtassets dif_lnetworth_asset dif_lcash_assets dif_lEBITDA_asset dif_EBITDA_asset dif_lcashflow_asset dif_cashflow_asset dif_lnetincome_asset dif_netincome_asset dif_linterestexpense_asset dif_interestexpense_asset dif_inter1 dif_inter2 dif_inter3 dif_inter4, absorb(cquarternum fqtr) vce(cluster gvkey)
 
 
 * Column (4)
 local var4 dif_net_debt_issuance dif_lnAsset dif_tangible_asset dif_markettobook_ratio dif_sp dif_book_debtassets dif_lnetworth_asset dif_lcash_assets dif_lEBITDA_asset dif_EBITDA_asset dif_lcashflow_asset dif_cashflow_asset dif_lnetincome_asset dif_netincome_asset dif_linterestexpense_asset dif_interestexpense_asset dif_inter1 dif_inter2 dif_inter3 dif_inter4
 
 foreach x in `var4'{
 	gen `x'_2 = `x' ^ 2
	gen `x'_3 = `x' ^ 3
	egen `x'_qtl = xtile(`x'), nq(5)
 }
 
 reghdfe dif_net_debt_issuance viol lviol dif_lnAsset dif_tangible_asset dif_markettobook_ratio dif_sp dif_book_debtassets dif_lnetworth_asset dif_lcash_assets dif_lEBITDA_asset dif_EBITDA_asset dif_lcashflow_asset dif_cashflow_asset dif_lnetincome_asset dif_netincome_asset dif_linterestexpense_asset dif_interestexpense_asset dif_inter1 dif_inter2 dif_inter3 dif_inter4 *_2 *_3 *_qtl, absorb(cquarternum fqtr) vce(cluster gvkey)
 