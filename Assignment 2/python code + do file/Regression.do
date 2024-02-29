use "C:\Users\lcyhk\Desktop\Processed_data\main data.dta", clear

********************************************************************************
***** Table 1 *****

tabstat total_shares Passive_share Active_share Unclassified_share independent_director poison_removal greater_ability dualclass ROA, stats(n mean median sd) c(s) f(%10.3f)

********************************************************************************
***** Table 2 *****
rename co_cap mktcap
gen lnmktcap = ln(mktcap)
gen lnmktcap2 = lnmktcap^2
gen lnmktcap3 = lnmktcap^3
gen lnfloat = ln(adj_mrktvalue)

* Column (1)
reghdfe total_shares r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (2)
reghdfe Passive_share r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (3)
reghdfe Active_share r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)
* Column (4)
reghdfe Unclassified_share r2000 lnmktcap lnmktcap2 lnmktcap3 lnfloat, absorb(year) vce(cluster cusip_merge)

********************************************************************************
***** Table 3 *****
egen passive_sd = sd(Passive_share)
gen passive_y = Passive_share / passive_sd

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
ivreghdfe id_y lnmktcap lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (2)
ivreghdfe id_y lnmktcap lnmktcap2 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (3)
ivreghdfe id_y lnmktcap lnmktcap2 lnmktcap3 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)

********************************************************************************
***** Table 5 *****
* Year 1998 - 2002
preserve 
drop if year <= 2002
* Column (1)
ivreghdfe id_y lnmktcap lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (2)
ivreghdfe id_y lnmktcap lnmktcap2 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (3)
ivreghdfe id_y lnmktcap lnmktcap2 lnmktcap3 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
restore

* Year 2003 - 2006
preserve
drop if year >= 2003
* Column (4)
ivreghdfe id_y lnmktcap lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (5)
ivreghdfe id_y lnmktcap lnmktcap2 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (6)
ivreghdfe id_y lnmktcap lnmktcap2 lnmktcap3 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
restore

********************************************************************************
***** Table 6 *****
egen greater_sd = sd(greater_ability)
gen greater_y = greater_ability / greater_sd

* Column (4)
ivreghdfe greater_y lnmktcap lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (5)
ivreghdfe greater_y lnmktcap lnmktcap2 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (6)
ivreghdfe greater_y lnmktcap lnmktcap2 lnmktcap3 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)

********************************************************************************
***** Table 7 *****
egen dual_sd = sd(dualclass)
gen dual_y = dualclass / dual_sd

* Column (1)
ivreghdfe dual_y lnmktcap lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (2)
ivreghdfe dual_y lnmktcap lnmktcap2 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)
* Column (3)
ivreghdfe dual_y lnmktcap lnmktcap2 lnmktcap3 lnfloat (passive_y=r2000), absorb(year) vce(cluster cusip_merge)



