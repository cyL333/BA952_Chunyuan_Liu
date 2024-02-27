********************************************************************************
***** Mutual fund holdings and Russell 1000/2000 index membership *****
********************************************************************************

***** CRSP mutual fund *****
use "C:\Users\lcyhk\Desktop\raw data\CRSP_mutual fund.dta", clear
sort crsp_fundno crsp_portno
format crsp_portno %10.0g
duplicates drop crsp_fundno, force

* Identify whether the index fund is active or passive 
gen passive = strmatch(fund_name, "*Index*" "*Idx*" "*Indx*" "*Ind *" "*Russell*" "*S & P*" "*S and P*" "*S&P*" "*SandP*" "*SP*" "*DOW*" "*Dow*" "*DJ*" "*MSCI*" "*Bloomberg*" "*KBW*" "*NASDAQ*" "*NYSE*" "*STOXX*" "*FTSE*" "*Wilshire*" "*Morningstar*" "*100*" "*400*" "*500*" "*600*" "*900*" "*1000*" "*1500*" "*2000*" "*5000*")
replace passive = 1 if index_fund_flag != ""
replace passive = 2 if passive == 0
sort crsp_fundno

***** Merge CRSP_mutual fund with MFLINK 1 *****
merge m:1 crsp_fundno using "C:\Users\lcyhk\Desktop\raw data\mflink1_raw.dta"
keep if _merge == 3
duplicates drop wficn, force
keep wficn passive
save "C:\Users\lcyhk\Desktop\Intermediate data\CRSPmutual_mflink1.dta", replace

***** Merge with MFLINK 2 *****
use "C:\Users\lcyhk\Desktop\raw data\mflink2_raw.dta", clear
merge m:1 wficn using "C:\Users\lcyhk\Desktop\Intermediate data\CRSPmutual_mflink1.dta"
keep if _merge == 2 | _merge == 3
drop _merge
save "C:\Users\lcyhk\Desktop\Intermediate data\CRSPmutual_mflink1_mflink2.dta", replace

***** Thomson Reuters S12 *****
* Used Python (filename: "populate_missingdata.ipynb") to populate missing values in S12 that are prior to year 2004 & the quarterly gap <= 2
* Data has been stored to "C:\Users\lcyhk\Desktop\raw data\S12_screened.dta"

***** CRSP-stock *****
use "C:\Users\lcyhk\Desktop\raw data\CRSP_stock.dta", clear
rename (PERMNO NCUSIP PERMCO CUSIP PRC SHROUT CFACPR CFACSHR) (permno ncusip permco cusip prc shrout cfacpr cfacshr)
gen year = year(date)
gen month = month(date)
keep if inlist(month, 3, 6, 9, 12)
drop if year < 1998 | year > 2006

* Calculate market capitalization
gen share_outst = shrout * 1000
gen price = abs(prc) * cfacpr
gen market_cap = price * share_outst * cfacshr
bysort year month permco: egen co_cap = sum(market_cap)
gen cusip_merge = ncusip
drop if cusip_merge == ""
*duplicates drop cusip_merge year month, force
save "C:\Users\lcyhk\Desktop\Intermediate data\CRSP_stock.dta", replace

* Historical cusip should be related to cusip in Thomosn Reuters S12
* Merge with S12_screened file
use "C:\Users\lcyhk\Desktop\raw data\S12_screened.dta", clear
merge m:1 cusip_merge year month using "C:\Users\lcyhk\Desktop\Intermediate data\CRSP_stock.dta"
drop _merge

* Delete observations where total mutual fund holdings exceed a stock's capitalization
sort cusip year month
gen cap_stock = shares * price
bysort cusip_merge year month permco: egen cap_fund = total(cap_stock)
drop if cap_fund > co_cap
save "C:\Users\lcyhk\Desktop\Intermediate data\S12_CRSP.dta", replace

***** Merge with S12 *****
use "C:\Users\lcyhk\Desktop\Intermediate data\CRSPmutual_mflink1_mflink2.dta", clear
gen year = year(fdate)
gen month = month(fdate)
duplicates drop fundno year month, force
merge 1:m fundno year month using "C:\Users\lcyhk\Desktop\Intermediate data\S12_CRSP.dta"
keep if _merge == 2 | _merge == 3
replace passive = 3 if missing(passive)
drop _merge
save "C:\Users\lcyhk\Desktop\Intermediate data\merged.dta", replace

********************************************************************************
***** Link to Russell *****
use "C:\Users\lcyhk\Desktop\raw data\russell_all.dta", clear
tostring yearmonth, gen (newdate)
destring newdate, replace
gen year = 1998 + (newdate - 461)/12
gen month = 6
rename cusip cusip_merge
drop newdate
merge 1:m cusip_merge year month using "C:\Users\lcyhk\Desktop\Intermediate data\merged.dta"
*keep if inlist(month, 6, 9)
format share_outst market_cap co_cap cap_fund %20.0g
save "C:\Users\lcyhk\Desktop\Intermediate data\merged_Russell.dta", replace

* Select firms in the 250 bandwidth around the cutoff between the Russell 1000 and 2000 indexes
***** Choose firm that are bottom 250 in Russell 1000 *****
use "C:\Users\lcyhk\Desktop\Intermediate data\merged_Russell.dta", clear
keep if r2000 == 0
duplicates drop cusip_merge year, force
gsort year adj_mrktvalue
by year: gen rank_r = _n
gen bottom_250 = rank_r <= 250  
keep if bottom_250 == 1
keep year cusip_merge r2000 bottom_250
save "C:\Users\lcyhk\Desktop\Intermediate data\bottom250.dta", replace

***** Choose firm that are top 250 in Russell 2000 *****
use "C:\Users\lcyhk\Desktop\Intermediate data\merged_Russell.dta", clear
keep if r2000 == 1
duplicates drop cusip_merge year, force
gsort year -adj_mrktvalue
by year: gen rank_r = _n
gen top_250 = rank_r <= 250  
keep if top_250 == 1
keep year cusip_merge r2000 top_250
save "C:\Users\lcyhk\Desktop\Intermediate data\top250.dta", replace

***** Merge firms around the 250 bandwidth with Russell index *****
use "C:\Users\lcyhk\Desktop\Intermediate data\merged_Russell.dta", clear
drop _merge
merge m:1 cusip_merge year using "C:\Users\lcyhk\Desktop\Intermediate data\bottom250.dta"
drop _merge
merge m:1 cusip_merge year using "C:\Users\lcyhk\Desktop\Intermediate data\top250.dta"
drop _merge
keep if bottom_250 == 1 | top_250 == 1
save "C:\Users\lcyhk\Desktop\Intermediate data\completed.dta", replace
use "C:\Users\lcyhk\Desktop\Intermediate data\completed.dta", clear
keep if month == 6

* % of shares outstanding held by mutual funds in September of year t
gen tot_shr = shares / (shr * cfacshr * 1000)
drop if missing(shares) | shares == 0
bysort permco year: egen total_share = sum(tot_shr)
bysort permco year: egen total_shares = max(total_share)
replace total_shares = total_shares * 100
bysort permco year: egen Passive = sum(tot_shr) if passive == 1
bysort permco year: egen Passive_share = max(Passive) 
replace Passive_share = Passive_share * 100
bysort permco year: egen Active = sum(tot_shr) if passive == 2
bysort permco year: egen Active_share = max(Active) 
replace Active_share = Active_share * 100
bysort permco year: egen Unclassified = sum(tot_shr) if passive == 3
bysort permco year: egen Unclassified_share = max(Unclassified)
replace Unclassified_share = Unclassified_share * 100

duplicates drop cusip_merge year, force
sum total_shares Passive_share Active_share Unclassified_share
save "C:\Users\lcyhk\Desktop\Intermediate data\mutual fund.dta", replace

********************************************************************************
***** Governance, voting, accounting, and compensation data *****
********************************************************************************

***** ISS-Director *****
use "C:\Users\lcyhk\Desktop\raw data\ISS_director.dta", clear
drop if CLASSIFICATION == "L"
gen year = year(MEETINGDATE)
sort CUSIP year DIRECTOR_DETAIL_ID
gen inde_dic = 0
gen tot_dic = 1
replace inde_dic = 1 if CLASSIFICATION == "I"

* Calculate no. of independent directors and total directors for each firm in each year
bysort CUSIP year: egen num_inde_dic = sum(inde_dic)
bysort CUSIP year: egen num_tot_dic = sum(tot_dic)
gen independent_director = num_inde_dic / num_tot_dic * 100
rename CUSIP cusip6
keep cusip6 year independent_director
duplicates drop cusip6 year, force

save "C:\Users\lcyhk\Desktop\Intermediate data\independent_director.dta", replace

***** ISS-Governance *****
use "C:\Users\lcyhk\Desktop\raw data\iss_governance.dta", clear
rename (CN6 YEAR DUALCLASS PPILL LSPMT) (cusip6 year dualclass ppill lspmt)
recast int (dualclass ppill lspmt)
format %6.0g (dualclass ppill lspmt)
sort cusip6 year

* Indicator for Poison pill removal equals to 1 if a firm's poison pill is either withdrawn or allowed to expire at time t, and zero otherwise
by cusip6: gen poison_removal = 1 if ppill == 0 & ppill[_n-1] == 1
replace poison_removal = 0 if missing(poison_removal)

* Indicator for Greater ability to call special meeting equals to 1 if shareholders are better able to call a special meeting at time t, and zero otherwise
by cusip6: gen greater_ability = 1 if lspmt == 0 & lspmt[_n-1] == 1
replace greater_ability = 0 if missing(greater_ability)

save "C:\Users\lcyhk\Desktop\Intermediate data\iss_governance.dta", replace

***** ROA *****
use "C:\Users\lcyhk\Desktop\raw data\roa.dta", clear
gen cusip8 = substr(cusip,1,8)
gen year = year(datadate)
drop if missing(ni) | missing(at)
gen roa = ni / at
winsor roa, gen(ROA) p(0.01)
duplicates drop cusip8 year, force
keep cusip cusip8 year ROA 
rename cusip8 cusip_merge
save "C:\Users\lcyhk\Desktop\Processed_data\roa.dta", replace

********************************************************************************
***** Merge the above data with the main dataset *****
use "C:\Users\lcyhk\Desktop\Intermediate data\mutual fund.dta", clear
merge m:1 cusip6 year using "C:\Users\lcyhk\Desktop\Intermediate data\independent_director.dta"
drop if _merge == 2
drop _merge

merge m:1 cusip6 year using "C:\Users\lcyhk\Desktop\Intermediate data\iss_governance.dta"
drop if _merge == 2
drop _merge

merge m:1 cusip_merge year using "C:\Users\lcyhk\Desktop\Processed_data\roa.dta"
drop if _merge == 2

save "C:\Users\lcyhk\Desktop\Processed_data\main data.dta", replace

********************************************************************************
***** Table 1 *****

tabstat total_shares Passive_share Active_share Unclassified_share independent_director poison_removal greater_ability dualclass ROA, stats(n mean median sd) c(s) f(%10.3f)

********************************************************************************
***** Table 2 *****
use "C:\Users\lcyhk\Desktop\Intermediate data\main data.dta", clear

rename co_cap mktcap
gen lnmktcap = ln(mktcap)
gen lnmktcap2 = lnmktcap^2
gen lnmktcap3 = lnmktcap^3
gen lnfloat = ln(adj_mrktvalue)

replace total_share = total_share * 100
replace Passive = Passive * 100
replace Active = Active * 100
replace Unclassified = Unclassified * 100

replace total_share = 0 if missing(total_share)
replace Passive = 0 if missing(Passive)
replace Active = 0 if missing(Active)
replace Unclassified = 0 if missing(Unclassified)

* Column (1)
reghdfe total_shares r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat i.year, vce(cluster cusip_merge)
* Column (2)
reghdfe Passive_share r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat i.year, vce(cluster cusip_merge)
* Column (3)
reghdfe Active r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat i.year, vce(cluster cusip_merge)
* Column (4)
reghdfe Unclassified r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat i.year, vce(cluster cusip_merge)

********************************************************************************
***** Table 3 *****
egen passive_sd = sd(passive)
gen passive_y = passive / passive_sd

* Column (1)
reghdfe passive_y r2000 lnmktcap lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (2)
reghdfe passive_y r2000 lnmktcap lnmktcap2 lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (3)
reghdfe passive_y r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)

********************************************************************************
***** Table 4 *****
egen independent_director_sd = sd(independent_director)
gen id_y = independent_director / independent_director_sd

* Column (1)
ivreghdfe id_y passive_y lnmktcap lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (2)
reghdfe id_y passive_y lnmktcap lnmktcap2 lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (3)
reghdfe id_y passive_y lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)

********************************************************************************
***** Table 5 *****
preserve 
drop if year > 2002
reghdfe id_y passive_y lnmktcap lnfloat, absorb(year) vce(cluster cusip_merge)
reghdfe id_y passive_y lnmktcap lnmktcap2 lnfloat, absorb(year) vce(cluster cusip_merge)
reghdfe id_y passive_y lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)
restore

preserve
drop if year < 2003
reghdfe id_y passive_y lnmktcap lnfloat, absorb(year) vce(cluster cusip_merge)
reghdfe id_y passive_y lnmktcap lnmktcap2 lnfloat, absorb(year) vce(cluster cusip_merge)
reghdfe id_y passive_y lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)
restore

********************************************************************************
***** Table 6 *****
egen greater_sd = sd(greater_ability)
gen greater_y = greater_ability / greater_sd

* Column (4)
reghdfe greater_y passive_y lnmktcap lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (5)
reghdfe greater_y passive_y lnmktcap lnmktcap2 lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (6)
reghdfe greater_y passive_y lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)

********************************************************************************
***** Table 7 *****
egen dual_sd = sd(dualclass)
gen dual_y = dualclass / dual_sd

* Column (1)
reghdfe dual_y passive_y lnmktcap lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (2)
reghdfe dual_y passive_y lnmktcap lnmktcap2 lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (3)
reghdfe dual_y passive_y lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)



