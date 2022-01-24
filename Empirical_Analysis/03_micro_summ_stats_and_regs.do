/*create the tables and figures in the draft/slides

  datasets for this program often come from 01_import_and_clean_data.do
  
*/

	set more off

	/*change to project directory (exact file path differs by user)*/
	cd "C:\Users\tuk40836\Dropbox\Research\BCLR\1_SafeCapital"

	/*path where analysis specific intermediate or final datasets are saved*/
	global rawPath = "Empirical_Analysis\raw"
	global dtapath = "Empirical_Analysis\dta"

	// tables, figures and spreadsheets
	global outPath   = "Empirical_Analysis\output_for_paper"
	global outFigure = "Empirical_Analysis\figures"


	
	
/*********************************************************************************************/			
// compute balance sheet variables using annual compustat data

if 1==1 { // only run if needed

	// check certain vars for computing cash flow profitability measures
	use "${rawPath}\CRSP_Compustat\compustat_annual", clear	
	
		// check depreciation
		gen dp_chk = oibdp - oiadp 
		gen diff_dp_chk = dp_chk - dp 
		summ diff_dp_chk, detail
		gen has_dp = ~missing(dp)
		gen has_dp_chk = ~missing(dp_chk)
		tab2 has_dp has_dp_chk
		//br oibdp oiadp dp_chk dp if has_dp==0 & has_dp_chk==1
		summ dp_chk if has_dp==0 & has_dp_chk==1, detail
		tab2 has_dp has_dp_chk if dp_chk~=0
		// conclusion: if dp not present, almost always zero from computed 
		//             value so just use dp value and assume 0 if missing
		
		// check taxes
		gen has_txt = ~missing(txt)
		tab has_txt
		
		// check ocf
		gen neg_txt = -txt // so can be added
		egen ocf = rowtotal(ebit dp neg_txt), missing
		//br lpermno datadate ebit dp neg_txt ocf if missing(ebit) & ~missing(ocf)
		//br if lpermno==23536	
		drop ocf
		// note that someimtes ebit missing but oiadp is not and they match otherwise
		
		// recompute ocf using ebit/oiadp and require non-missing ebit_fill
		gen ebit_fill = ebit
		replace ebit_fill = oiadp if missing(ebit) & ~missing(oiadp)
		egen ocf = rowtotal(ebit_fill dp neg_txt) if ~missing(ebit_fill), missing	
		
		// check SG&A
		gen has_sga = ~missing(xsga)
		tab has_sga
		tab2 fyear has_sga
	
	
	
	// compute annual compustat data
	use "${rawPath}\CRSP_Compustat\compustat_annual", clear	
	
	// check relative size of foreign companies
	if 1==0 {
		set more off
		tab curcd	
		tab fic	
		gen at_usa = at if fic=="USA"
		gen at_for = at if fic~="USA"
		gen xrd_usa = xrd if fic=="USA"
		gen xrd_for = xrd if fic~="USA"		
		collapse (sum) at_usa at_for xrd_usa xrd_for, by(fyear)
		gen pct_at_usa = at_usa / (at_usa + at_for)	
		gen pct_xrd_usa = xrd_usa / (xrd_usa + xrd_for)	
	}
	
	// do some data cleaning
	keep if curcd=="USD" // figures must be in USD
	keep if fic=="USA"
	// note: restrict to firms incorporated in US for now but
	//       we may want to expand because R&D expense by foreign companies 
	//       in the US should count to US investment in GDP figures
	drop if missing(at)

	// total investment measure as capex plus R&D investment
	gen total_inv         = capx + xrd
	egen total_inv_misseq0 = rowtotal(capx xrd)
	
	// real investment series
	gen datemo = mofd(datadate)
	format datemo %tm
	merge m:1 datemo using "${dtapath}\inflation_index_monthly", nogen keep(master match)
	gen real_xrd       = xrd       / inflation_index
	gen real_capx      = capx      / inflation_index
	//gen real_total_inv = total_inv / inflation_index // compute later instead
	
	// R&D intensity measures
	egen xrd_misseq0 = rowtotal( xrd )
	gen rnd_to_total_inv 		 = xrd / total_inv
	gen rnd_misseq0_to_total_inv = xrd_misseq0 / total_inv_misseq0
	gen rnd_to_assets 			 = xrd / at
	gen rnd_misseq0_to_assets 	 = xrd_misseq0 / at
	
	// compute markups
	gen markup_rev    = (revt-cogs) / revt
	gen markup_ebitda = oibdp / revt
	gen markup_rev_rnd_nomiss    = markup_rev    if ~missing(rnd_to_total_inv)
	gen markup_ebitda_rnd_nomiss = markup_ebitda if ~missing(rnd_to_total_inv)
	
	// merge on sic code industry based on FamaFrench definitions
	rename sic sic_txt
	destring sic_txt, gen(sic)

		// 49 industries classification
		merge m:1 sic using "${dtapath}\siccodes_industries_49", nogen keep(master match) keepusing(industry_short_name)
		rename industry_short_name port_sic49
		label var port_sic49 "Industry"
		replace port_sic49 = "Other" if missing(port_sic49)
		
	// components of book leverage as in Corhay (2017) [see PDF in folder]
	// Leverage is [total long-term debt (DLTT) + debt in current liabilities (DLC)] to [total long-term debt (DLTT) + debt in current liabilities (DLC) + book equity].
	// Book equity is deﬁned as [book value of stockholders’ equity (CEQ) + balance sheet deferred taxes (TXDITC) - book value of preferred stock (PST)]. 
	egen book_debt = rowtotal(dltt dlc)
	//egen equity_nomiss = rowmax(ceq seq)
	//egen tempvar = rowtotal(equity_nomiss txditc)
	// note: just use CEQ because not sure SEQ is correct to replace with
		//if 1==0 {			
		//	gen obs_type = "use ceq" if ~missing(ceq)
		//	replace obs_type = "ceq much smaller" if ceq/seq<0.9
		//	replace obs_type = "use seq" if missing(ceq) & ~missing(seq)
		//	replace obs_type = "missing" if missing(ceq) & missing(seq)
		//}		
	egen tempvar = rowtotal(ceq txditc)
	gen book_equity = tempvar
	replace book_equity = tempvar - pst if ~missing(pst)
	gen book_leverage_raw = book_debt / (book_debt+book_equity)
	gen book_leverage_trunc = book_leverage_raw
	replace book_leverage_trunc = 1 if book_leverage_raw>1 & ~missing(book_leverage_raw) // due to negative book equity which is like 100% book leverage
	replace book_leverage_trunc = 0 if book_leverage_raw<0 & ~missing(book_leverage_raw) // due to negative book debt which is like 0% book leverage
	gen book_leverage_maxjfe = 1- (book_equity/at)

		// chceck out extreme values
		if 1==0 {			
			keep if fyear>=1970
			keep if book_leverage_raw>1 | book_leverage_raw<0
			order book_leverage_raw book_debt dltt dlc book_equity ceq seq
			sort book_leverage_raw
			// note: almost all leverage above 1 or below 0 due to negative
			//       book equity which can happen with large losses that wipe
			//       out book equity. I will set all of these values to 1 in
			//       the truncated equity measure
		}		
	
	
		// tests of book leverage values
		if 1==0 {			
			keep if fyear>=1970
			order book_leverage book_debt dltt dlc book_equity ceq seq
			summ book_leverage, detail
			set more off
			bysort fyear: summ book_leverage, detail
			bysort port_sic30: summ book_leverage, detail
			collapse (sum) book_equity book_debt, by(fyear)
			gen book_leverage = book_debt / (book_debt+book_equity)
			bysort fyear: summ book_leverage, detail
			summ book_leverage, detail
		}	
	
		
		// more tests of alternatve book leverage values
		if 1==0 {
			gen debt_chk1 = dt
			gen debt_chk2 = at - teq
			gen debt_chk3 = at - ceq
			gen diffseq = seq - ceq
			order debt debt_chk1 debt_chk2 debt_chk3 at dt dltt teq seq ceq diffseq
			sort gvkey datadate
			egen equity = rowmax(teq seq ceq)	
			gen lev = equity/at
			order equity lev
			summ lev, detail
		}
		
	// save just book debt values to merge on in the specific month
	//gen datemo = mofd(datadate)
	//format datemo %tm	
	//order lpermno year_for_merge datemo		
	//preserve
	//	keep lpermno datemo	book_debt	
	//	rename book_debt book_debt_current // call current because it is value
		// that corresponds to as of the datemo it will be merged with
		// book_debt above will be value from the previous year
	//	save "${dtapath}\compustat_book_debt_current_vals_for_merge", replace
	//restore
	
	// operating cash flow (added June 2019)
	gen neg_txt = -txt // so can be added
	gen ebit_fill = ebit
	replace ebit_fill = oiadp if missing(ebit) & ~missing(oiadp)
	egen ocf = rowtotal(ebit_fill dp neg_txt) if ~missing(ebit_fill), missing	
		
	
	// merge on patent apps/grants from Autor et al
	gen year=fyear
	merge m:1 gvkey year using "${dtapath}\patent_apps_and_grants_by_gvkey_year", nogen keep(master match)
	drop year
	
	// merge on patent values from Kogan et al (QJE 2017) aka KPSS
	gen year=fyear
	gen permno=lpermno
	merge m:1 permno year using "${dtapath}\kpss_patent_data_by_permno_year", nogen keep(master match)
	drop year permno
	
	// double check that  patent values to thousands of dollars to match compustat units
	gen temp_ratio = pat_val_cw/at
	//br lpermno fyear at pat_val_cw temp_ratio if lpermno==10078
	drop temp_ratio
	// one can see in "firm_innovation_v2" that the values for this firm are
	// roughly 0.10-0.15 in the period 2000-2009 so we confirm that at
	// is in millions of dollars
		
	// more real variables (added January 2020)
	foreach myvar in "revt" "xsga" "ocf" "pat_val_cw" "pat_val_sm" "at" {
		gen real_`myvar' = `myvar' / inflation_index
	}
	
	// labor productivity (added January 2020)
	gen labor_prod = revt / emp
		
	// merge on firm-level log TFP from Imrohoroglu and Tuzel (2014) paper
	destring gvkey, gen(gvkey_num)
	merge m:1 gvkey_num fyear using "${dtapath}\tfp_from_IT2014_by_gvkey_year", nogen keep(master match)
	drop gvkey_num
	
		
	rename sic sic_compustat
	keep lpermno fyear datemo fic at revt oibdp cogs capx xrd emp sic_compustat port_sic* /// year_for_merge
		book_debt book_equity /// 	
		real_* ///
		ocf ///
		markup_rev markup_ebitda markup_rev_rnd_nomiss markup_ebitda_rnd_nomiss ///
		rnd_to_total_inv rnd_misseq0_to_total_inv ///
		rnd_to_assets    rnd_misseq0_to_assets ///				
		book_leverage_raw book_leverage_trunc book_leverage_maxjfe 	///
		patent_grants patent_apps ///
		labor_prod tfp_it2014		
	save "${dtapath}\compustat_annual_for_merge", replace
	
	
		// check how often employment is missing
		use "${dtapath}\compustat_annual_for_merge", clear
		gen has_emp = (emp>0) & ~missing(emp)
		gen has_rnd = (xrd>0) & ~missing(xrd)
		gen has_rnd_not_emp = (xrd>0) & ~missing(xrd) & missing(emp)
		tab has_emp has_rnd
		collapse (sum) has_emp has_rnd has_rnd_not_emp (count) lpermno, by(fyear)
		gen pct_has_emp = 100 * has_emp / lpermno
		gen pct_has_rnd = 100 * has_rnd / lpermno
		gen pct_rnd_no_emp = 100 * has_rnd_not_emp / has_rnd
		tsset fyear
		tsline pct_has_emp pct_has_rnd pct_rnd_no_emp, graphregion(color(white)) ///
			legend( label(1 "Has Emp.") label(2 "Has R&D") label(3 "R&D w/o Emp") cols(3) ) ///
			lpattern(solid dash solid) lcolor(black blue red) ///
			lwidth(0.7 0.7 0.7) ///
			xline(1972, lpattern(dash) lcolor(black)) ytitle("Percent")
		graph export "${outFigure}\tsline_compustat_relative_available_xrd_and_emp.png", replace
		window manage close graph		
		// conclusion: from 1973, only 1.38% of firms on average have R&D 
		// expense but not employees figure. 
		//summ pct_rnd_no_emp if fyear>=1973 & fyear<=2013
		//
		//    Variable |        Obs        Mean    Std. Dev.       Min        Max
		//-------------+---------------------------------------------------------
		//pct_rnd_no~p |         41    1.380047     .545803   .3821656   2.333153
		tsline pct_rnd_no_emp, graphregion(color(white)) ///
			lpattern(solid dash solid) lcolor(red) ///
			lwidth(0.7 0.7 0.7) ///
			title("Percent of Compustat Firms with R&D But Missing Emp.") ///
			xline(1972, lpattern(dash) lcolor(black)) ytitle("Percent")
		graph export "${outFigure}\tsline_compustat_pct_rnd_no_emp.png", replace
		window manage close graph			

	
	
		// save just sic code info (see tests below to confirm almost always one unique code but sometimes there is a second one)
		use "${dtapath}\compustat_annual_for_merge", clear
		keep lpermno sic_compustat port_sic*
		gen obs_dummy = 1
		collapse (sum) sic_count=obs_dummy, by(lpermno sic_compustat port_sic*)
		gsort lpermno -sic_count
		by lpermno: gen sic_num = _n	
		keep if sic_num==1 // pick sic code with most entries
		drop sic_count sic_num
		save "${dtapath}\compustat_firms_sic_unique_for_merge", replace
	
	
		// check how often compustat firms change fiscal year end
		use lpermno datemo using "${dtapath}\compustat_annual_for_merge", clear
		gen month = month(dofm(datemo))
		drop datemo
		duplicates drop
		gen month_ind = 1
		reshape wide month_ind, i(lpermno) j(month)		
		egen month_count = rowtotal(month*)
		tab month_count
		gsort -month_count
	
	
		// check how often compustat firms change sic code
		use lpermno sic_compustat using "${dtapath}\compustat_annual_for_merge", clear
		drop if missing(sic_compustat)
		gen obs_dummy = 1
		collapse (sum) sic_count=obs_dummy, by(lpermno sic_compustat)
		gsort lpermno -sic_count
		by lpermno: gen sic_num = _n
		reshape wide sic_compustat sic_count, i(lpermno) j(sic_num)
			// check that sic_count1 is usually higher (sometimes the same)
			gen check = (sic_count1>=sic_count2) if ~missing(sic_count2)
			tab check
			drop check
			gen check2 = (sic_count1>sic_count2) if ~missing(sic_count2)
			tab check2
			drop check2
		gen sic_unique = 1
		replace sic_unique = 2 if ~missing(sic_count2)
		tab sic_unique
		// conclusion: SIC code is unique over 99% of firms. for most others, it stays relatively close. therefore not worth programming complicated
	
	
		// check how often firms report missing R&D expense one year and non-missing another
		use "${dtapath}\compustat_annual_for_merge", clear	
		keep if datemo>=ym(1975,1)
		gen xrd_nonmiss = ~missing(xrd)
		collapse (sum) xrd_nonmiss real_capx real_xrd (count) num_obs=at, by(lpermno)
		gen pct_xrd_nonmiss = xrd_nonmiss/num_obs
		summ pct_xrd_nonmiss, detail
		gen xrd_nonmiss_group = "Sometimes"
		replace xrd_nonmiss_group = "Never" if pct_xrd_nonmiss==0
		replace xrd_nonmiss_group = "Always" if pct_xrd_nonmiss==1
		collapse (sum) real_capx real_xrd, by(xrd_nonmiss_group) 
		egen agg_real_capx = sum(real_capx)
		egen agg_real_xrd  = sum(real_xrd)
		gen pct_agg_real_capx = real_capx / agg_real_capx
		gen pct_agg_real_xrd  = real_xrd  / agg_real_xrd
	
}		
	
// look at dataset
use "${dtapath}\compustat_annual_for_merge", clear	
//keep lpermno datemo at capx xrd real_capx real_xrd emp revt cogs oibdp book_debt book_equity ocf
	

	


/*********************************************************************************************/			
// create monthly dataset of compustat values more efficiently

	// create dataset with 12 months before first val and and 12 months ahead last val
	use "${dtapath}\compustat_annual_for_merge", clear	
	collapse (min) min_datemo=datemo (max) max_datemo=datemo, by(lpermno)
	gen datemo1 = min_datemo-13
	gen datemo2 = max_datemo+13
	keep lpermno datemo1 datemo2
	reshape long datemo, i(lpermno) j(j)
	format datemo %tm
	drop j
	save "${dtapath}\temp_lpermno_datemo_vals_to_ensure_full_range", replace

	// add this dataset to the annual dataset and then use tsfill to fill in
	// the gap months
	use "${dtapath}\compustat_annual_for_merge", clear	
	append using "${dtapath}\temp_lpermno_datemo_vals_to_ensure_full_range"
	keep lpermno datemo at capx xrd real_* emp revt cogs oibdp book_debt book_equity ocf patent_grants patent_apps tfp_it2014
	gen fakevar1 = 0 // create variable as buffer between CRSP and compustat vars
	gen fakevar2 = 0 // create variable as buffer between CRSP and compustat vars
	order lpermno datemo fakevar1
	tsset lpermno datemo 
	
	// fill in the gap months
	tsfill
	foreach compvar of varlist fakevar1-fakevar2 {
	
	  set more off
	  
		disp "`compvar'"
	
		// remember that compustat values are either stocks (e.g., assets "at")
		// or flows (e.g., capital expenditures "capx"). the value as of a date
		// is end of period value. the code below fills that end-of-period value
		// until the next one is reported
	
		// grab lagged values
		gen `compvar'_raw = `compvar'
		gen compvar       = `compvar'
		drop `compvar'
		forvalues i=1/11 {
			by lpermno: gen compvar_L`i' = L`i'.compvar
		}
		
		// fill these values in, starting with most recent
		forvalues i=1/11 {
			replace compvar = compvar_L`i' if missing(compvar)
		}		
		drop compvar_L*
		
		// pick the right "current" value to be used when summing over
		// portfolios. this is the latest end-of-period value reported
		gen `compvar'_F0 = L1.compvar
		drop compvar
		
		// grab the future valus in order to compute growth rates
		foreach i in 12 24 36 48 60 72 {
			gen `compvar'_F`i' = F`i'.`compvar'_F0
		}
		
	}	
	drop fakevar* // no longer needed
	
	// save space: don't need debt and equity values in the future
	//foreach i in 12 24 36 48 60 72 {
	//	drop book_debt_F`i' book_equity_F`i'
	//}				
	// nevermind: we need these for computing future tobinQ and future mkt value of assets
	
	// keep only obs with any non-missing data
	egen rownonmiss_count = rownonmiss(at*)
	drop if rownonmiss_count==0
	drop rownonmiss_count
	
	// save
	compress
	drop if datemo<=ym(1970,12) // earliest data we need is 1971m1
	//save "${dtapath}\compustat_monthly_for_merge_new", replace
	save "${dtapath}\compustat_monthly_for_merge", replace
	
		// check new vs old to make sure new method creates same dataset
		if 1==0 {
		
			use "${dtapath}\compustat_monthly_for_merge", replace
		
			// find a candidate with long history
			use "${dtapath}\compustat_monthly_for_merge_new", replace
			collapse (count) count_at=at_raw, by(lpermno)
			gsort -count_at
			
			// compare
			use "${dtapath}\compustat_monthly_for_merge_new", replace
			//keep if lpermno==20482
			keep lpermno date real_capx_*
			// compute forward-looking geometric growth rates
			foreach myvar in "real_capx" {
				gen gro_ann_1yr_`myvar' = 100*( (`myvar'_F24/`myvar'_F12)^(1/1) - 1 ) 
				gen gro_ann_2yr_`myvar' = 100*( (`myvar'_F36/`myvar'_F12)^(1/2) - 1 ) 
				gen gro_ann_3yr_`myvar' = 100*( (`myvar'_F48/`myvar'_F12)^(1/3) - 1 ) 
				gen gro_ann_4yr_`myvar' = 100*( (`myvar'_F60/`myvar'_F12)^(1/4) - 1 ) 
				gen gro_ann_5yr_`myvar' = 100*( (`myvar'_F72/`myvar'_F12)^(1/5) - 1 ) 			
			}				
			foreach myvar of varlist real_capx* gro_* {	
				rename `myvar' `myvar'_new
			}
			merge 1:1 lpermno date using "${dtapath}\compustat_monthly_for_merge", keepusing(real_capx_*) 
			// the original file is located in the following location on Sam's Temple desktop if needed
			// D:\Users\Public\Backups\BCLR\from before first ecta submission\compustat_monthly_for_merge
			//keep if lpermno==20482
			foreach myvar in "real_capx" {
				gen gro_ann_1yr_`myvar' = 100*( (`myvar'_F24/`myvar'_F12)^(1/1) - 1 ) 
				gen gro_ann_2yr_`myvar' = 100*( (`myvar'_F36/`myvar'_F12)^(1/2) - 1 ) 
				gen gro_ann_3yr_`myvar' = 100*( (`myvar'_F48/`myvar'_F12)^(1/3) - 1 ) 
				gen gro_ann_4yr_`myvar' = 100*( (`myvar'_F60/`myvar'_F12)^(1/4) - 1 ) 
				gen gro_ann_5yr_`myvar' = 100*( (`myvar'_F72/`myvar'_F12)^(1/5) - 1 ) 			
			}	
			//br lpermno datemo _merge gro_ann_1yr_*
			forvalues j=1/5 {
				gen check_`j'yr = (gro_ann_`j'yr_real_capx==gro_ann_`j'yr_real_capx_new) & (missing(gro_ann_`j'yr_real_capx)==missing(gro_ann_`j'yr_real_capx_new))
				tab check_`j'yr, missing
			}
			// conclusion: new method that uses tsfill is way faster and generates
			//             the same dataset
			
		}
	
	
/*********************************************************************************************/			
// create a CRSP-Compustat merged dataset using the monthly Compustat dataset 
// created above instead of the annual compustat data like in the other program
	
	use "${rawPath}\CRSP\crsp_monthly", clear		
	gen datemo = mofd(date)
	format datemo %tm	
	order datemo	

	// standard filtering
	keep if inlist(shrcd,10,11,12)
	keep if inlist(exchcd,1,2,3)
	drop if missing(ret)

	// double check one obs per datemo per permno
	//collapse (count) permno_datemo_count=ret, by(permno datemo)
	//summ permno_datemo_count, detail
	
	// market cap in billions (shares outstanding are in 1000)
	//summ prc // close price is negative if the average of closing bid/ask prices	
	//summ shrout // common shares outstanding in thousands
	gen mkt_cap = abs(prc)*shrout/10^6
	//gen mkt_cap_millions = abs(prc)*shrout/10^3
	
	// use Apple Inc as example if needed
	//br if permno==14593	
	
	// also check sum of all companies here
	// collapse (sum) mkt_cap, by(datemo)
	
	// prepare for merging on compustat data	
	keep permno datemo date ret mkt_cap siccd // mkt_cap_millions
	rename permno lpermno
	drop date

	// merge on compustat data, which includes industry definition
	merge 1:1 lpermno datemo using "${dtapath}\compustat_monthly_for_merge", nogen keep(master match)
	// note: balance sheet values already filled in the monthly dataset
	
	// total investment measure as capex plus R&D investment
	gen total_inv_F0 = capx_F0 + xrd_F0
	egen total_inv_misseq0_F0 = rowtotal(capx_F0 xrd_F0)	
	
	// compute also total investment with future leads
	//foreach fval in 0 12 24 36 48 60 72 {
		//egen real_total_inv_F`fval' = rowtotal(real_capx_F`fval' real_xrd_F`fval'), missing
	//}
	// NOTE: compute later instead
	
	// R&D intensity measures
	//egen xrd_misseq0 = rowtotal( xrd )
	gen rnd_to_total_inv 		 = xrd_F0 / total_inv_F0
	//gen rnd_misseq0_to_total_inv = xrd_misseq0 / total_inv_misseq0
	gen rnd_to_assets 			 = xrd_F0 / at_F0
	gen rnd_misseq0_to_assets 	 = total_inv_misseq0_F0 / at_F0	

	// SG&A intensity ratio (added April 2020). note that
	// we use real values because didn't save nominal values
	// from previous datasets for space reasons. xsga and at
	// use same index to convert nominal to real so this
	// index cancels out to give correct ratio
	gen xsga_to_assets = real_xsga_F0 / real_at_F0
	gen xsga_to_assets_rnd = xsga_to_assets if ~missing(rnd_to_assets)
	// check that this ratio is relatively well populated and not
	// subject to extreme values
	if 1==0 {
		collapse (count) has_xsga=xsga_to_assets has_at=real_at_F0 ///
			(mean) mean_xsga_to_assets=xsga_to_assets ///
			(min)  min_xsga_to_assets=xsga_to_assets ///			
			(p1)   p01_xsga_to_assets=xsga_to_assets ///
			(p10)  p10_xsga_to_assets=xsga_to_assets ///
			(p50)  p50_xsga_to_assets=xsga_to_assets ///
			(p90)  p90_xsga_to_assets=xsga_to_assets ///
			(p99)  p99_xsga_to_assets=xsga_to_assets ///
			(max)  max_xsga_to_assets=xsga_to_assets ///
			, by(datemo)
		tsset datemo
		//tsline p01 p10
		// note: confirm 1st and 10th percentile value always positive
	}
	
	// sales to assets
	gen sales_to_assets = revt_F0 / at_F0
	
	// leverages
	gen book_leverage_raw = book_debt_F0 / (book_debt_F0+book_equity_F0)
	gen book_leverage_trunc = book_leverage_raw
	replace book_leverage_trunc = 1 if book_leverage_raw>1 & ~missing(book_leverage_raw) // due to negative book equity which is like 100% book leverage
	replace book_leverage_trunc = 0 if book_leverage_raw<0 & ~missing(book_leverage_raw) // due to negative book debt which is like 0% book leverage
	gen book_leverage_maxjfe = 1- (book_equity_F0/at_F0)
	//gen chk_lev = book_leverage_maxjfe / book_leverage_raw
	//summ chk_lev, detail
	// note: book_leverage_maxjfe bigger for 95% of obs
	
	// compute markups	
	//gen markup_rev    = (revt-cogs) / revt	
	//gen markup_ebitda = oibdp / revt
	//gen markup_rev_rnd_nomiss    = markup_rev    if ~missing(rnd_to_total_inv)
	//gen markup_ebitda_rnd_nomiss = markup_ebitda if ~missing(rnd_to_total_inv)	
	
	// fill in market cap values
	sort lpermno datemo
	tsset lpermno datemo
	gen lag_mkt_cap = L1.mkt_cap	
			
	
	// create comparable forward-looking market cap vars for computing
	// market value of asssets. note that in previous steps we define
	//    gen `compvar'_F0 = L1.compvar
	// meaning that lag_mkt_cap is like mkt_cap_F0
	gen mkt_cap_F0 = lag_mkt_cap*(10^3) // convert to millions
	foreach i in 12 24 36 48 60 72 {
		gen mkt_cap_F`i' = F`i'.mkt_cap_F0
	}				
			
	// tobin's Q
	gen tobinQ = lag_mkt_cap*(10^3)/book_equity_F0	
	replace tobinQ = . if lag_mkt_cap<0 & book_equity_F0<0 // seems like odd obs if exists
	summ tobinQ, detail
	replace tobinQ = . if tobinQ<0 // sensible limit
	gen tobinQ_trunc = tobinQ	
	summ tobinQ_trunc, detail
	replace tobinQ_trunc = r(p99) if tobinQ_trunc>r(p99) & ~missing(tobinQ_trunc)
	summ tobinQ_trunc, detail
	
	// create forward looking tobinQ as well (added feb 2020)
	foreach i in 0 12 24 36 48 60 72 {
		gen tobinQ_F`i' = mkt_cap_F`i'/book_equity_F`i'
		replace tobinQ_F`i' = . if mkt_cap_F`i'<0 & book_equity_F`i'<0 // seems like odd obs if exists
		replace tobinQ_F`i' = . if tobinQ_F`i'<0 // sensible limit		
	}					
	
	// cash flow profitability
	gen cfprof_ratio = ocf_F0 / revt_F0 
	summ cfprof_ratio, detail
	//br lpermno datemo cfprof_ratio revt_F0 ocf_F0 if cfprof_ratio<0
	//br lpermno datemo cfprof_ratio revt_F0 ocf_F0 if cfprof_ratio>1 & ~missing(cfprof_ratio)
	//br lpermno datemo cfprof_ratio revt_F0 ocf_F0 if revt_F0<0 & ocf_F0<0
	replace cfprof_ratio = . if revt_F0<0 // these obs make no sense so don't count otherwise ratio is positive and large
	summ cfprof_ratio, detail
	//replace cfprof_ratio = r(p99) if cfprof_ratio>r(p99) & ~missing(cfprof_ratio) // may affect too many obs
	//replace cfprof_ratio =  r(p1) if cfprof_ratio<r(p1)  & ~missing(cfprof_ratio)
	replace cfprof_ratio = 1 if cfprof_ratio>1 & ~missing(cfprof_ratio) // sensible limit	
	replace cfprof_ratio = -1 if cfprof_ratio<-1 // sensible imit
	summ cfprof_ratio, detail
		
	// use as simpler cash flow profitability measure than OCF/Revt		
	// keep name markup_ebitda_F0 to avoid having to rename everywhere
	// and consistency with portfolio level measure
	gen markup_ebitda_F0 = oibdp_F0 / revt_F0 
	summ markup_ebitda_F0, detail
	replace markup_ebitda_F0 = . if revt_F0<0
	summ markup_ebitda_F0, detail
	replace markup_ebitda_F0 = 1 if markup_ebitda_F0>1 & ~missing(markup_ebitda_F0) // sensible limit	
	replace markup_ebitda_F0 = -1 if markup_ebitda_F0<-1 // sensible imit
	summ markup_ebitda_F0, detail
	
	// labor prod (added Feb. 2020)
	foreach fval in 0 12 24 36 48 60 72 {
		gen labor_prod_F`fval' = revt_F`fval' / emp_F`fval'
	}		

	
	// real market value of assets (added feb 2020)	
	foreach i in 0 12 24 36 48 60 72 {
		//gen mkt_at_F`i' = book_debt_F`i' + mkt_cap_F`i'
		gen real_mkt_at_F`i' = (book_debt_F`i' + mkt_cap_F`i') * (real_at_F`i' / at_F`i')
		// note: did not carry over inflation index but use (real_at_F`i' / at_F`i')
		//       as implied index because real_at = at / inflation_index
	}


	
	// num firms with non-missing xrd jumps in 1972
	//keep if year_for_merge>=1972
	//drop year_for_merge
	keep if datemo>=ym(1971,1)
	
	// merge on SIC code info from Compustat
	merge m:1 lpermno using "${dtapath}\compustat_firms_sic_unique_for_merge", nogen keep(master match)
	
	// check if sic codes are same in compustat and crsp dataset
	//order sic_compustat siccd
	if 1==0 {
		tab sic_compustat
		tab siccd
		gen check_diff = (sic_compustat-siccd)
		summ check_diff, detail
		gen same_exact_value = check_diff==0 if ~missing(check_diff)
		tab same_exact_value, missing
		gen same_3digit_value = abs(check_diff)<10 if ~missing(check_diff)
		tab same_3digit_value
		gen same_2digit_value = abs(check_diff)<100 if ~missing(check_diff)
		tab same_2digit_value		
		tab sic_compustat if abs(check_diff)>1000
		tab siccd if abs(check_diff)>1000
		list sic_compustat siccd if abs(check_diff)>1000 in 1/5000
		tab siccd if check_diff
		gen missing_sic_compustat = missing(sic_compustat)
		gen missing_sic_crsp      = missing(siccd)
		tab missing_sic_compustat
		tab missing_sic_crsp
	}
	// conclusion: use sic_compustat even tho more often missing because 
	//             seem more accurate in terms of being specific number
	drop siccd
	
	// keep only variables needed for analysis
	gen fakevar=0
	order datemo lpermno ret lag_mkt_cap book_debt_F0 book_equity_F0 ///
		at_F* xrd_F* capx_F0 ///
		rnd_to_total_inv rnd_to_assets rnd_misseq0_to_assets ///
		emp_F* ///
		///real_xrd_F* real_capx_F* ///
		real_* /// change january 2020 to use all real quantities
		oibdp_F0 revt_* cogs_F0 ocf_F0 ///
		sic_compustat ///							
		tobinQ* cfprof_ratio markup_ebitda_F0 ///
		patent_* /// added january 2020
		labor_prod_* /// added january 2020
		tfp_it2014_* /// added january 2020
		xsga_to_assets xsga_to_assets_rnd ///
		fakevar
	keep datemo-fakevar
	drop fakevar	
	
	compress
	save "${dtapath}\crsp_merged_with_monthly_compustat", replace
	
	
	
	
	
/********************************************************************/
// compare R&D intensity across portfolios and compare to the govt	
	
	// portfolio thresholds
	use lpermno lag_mkt_cap datemo rnd_to_assets using "${dtapath}\crsp_merged_with_monthly_compustat", clear
	collapse ///
		(p20) p20=rnd_to_assets ///
		(p40) p40=rnd_to_assets ///
		(p60) p60=rnd_to_assets ///
		(p80) p80=rnd_to_assets ///
		, by(datemo)
	keep if datemo>=ym(1972,1) & datemo<=ym(2016,12) // keep only our analysis sample
	
	// merge on govt values
	gen year = year(dofm(datemo))
	merge m:1 year using "${dtapath}\bea_annual", nogen keep(master match) keepusing(gross_govt_inv_nom_rnd)
	merge m:1 year using "${dtapath}\bea_fixed_assets_tables_data_annual", nogen keep(master match) keepusing(govt_fa_tot)	
	gen govt_rnd_to_kg = gross_govt_inv_nom_rnd / govt_fa_tot			
	drop gross_govt_inv_nom_rnd govt_fa_tot
		
		// figure for visual checking
		tsline p20 p40 p60 p80 govt_rnd_to_kg, ///
			graphregion(color(white)) xtitle(" ") ytitle("Fraction") ///
			xlabel(120(120)600,format(%tm)) ///
			legend(cols(4) label(1 "20") label(2 "40") label(3 "60") label(4 "80") label(5 "Govt")) ///
			lcolor(blue blue red red green) ///
			lpattern(solid dash dash solid solid) ///
			lwidth(1.0 1.0 1.0 1.0 1.0)
		graph export "${outFigure}/tsline_quintiles_rnd_to_assets_and_govt_rnd_to_kg.png", replace
		window manage close graph	
			
			
	// compute time series averages and standard errors
	tsset datemo
	reg p20
	reg p20, robust
	newey p20, lag(12)
	foreach regvar in "p20" "p40" "p60" "p80" "govt_rnd_to_kg" {
	
		// put in percent
		gen regvar = 100*`regvar'
	
		// regress on constant to get mean and SE
		qui newey regvar, lag(12)
		// use 12 lags for NW estimator because these variables
		// are very persistent
		
		// save coefficients
		matrix b = e(b)
		matrix V = e(V)
		gen mean_`regvar' = b[1,1] if _n==1
		gen semean_`regvar' = sqrt(V[1,1]) if _n==1
		
		drop regvar
		
	}

	// export out the table of saved coefficients
	keep mean_* semean_*
	gen stat = "reg_newey" if _n==1
	order stat
	keep if _n==1
	export excel using "${outPath}\tables_for_paper.xlsx", sheet("raw_rnd_intens_quint_govt") sheetreplace firstrow(variables)


	
/********************************************************************/
// number of firms with non-missing patent-related variables
	
	// overall
	use "${dtapath}\crsp_merged_with_monthly_compustat", clear				
	gen year = year(dofm(datemo))
	keep if year>=1972
	collapse (count) real_pat_val_cw_raw real_pat_val_sm_raw patent_apps_raw patent_grants_raw, by(year)
	label var real_pat_val_cw "Value (CW or SM)"
	label var patent_apps "Applications"
	label var patent_grants "Grants"
	tsset year
	tsline real_pat_val_cw patent_apps patent_grants, graphregion(color(white)) ///
		legend( cols(3) ) ///
		lpattern(solid dash solid) lcolor(black blue red) ///
		lwidth(0.7 0.7 0.7) ///
		ytitle("Number of Firms") ///
		title("Non-Missing Patent Var Firm Counts (All)")
	graph export "${outFigure}/tsline_nonmissing_patent_var_firm_counts_all.png", replace
	window manage close graph		

	
	// non-missing R&D
	use "${dtapath}\crsp_merged_with_monthly_compustat", clear		
	gen year = year(dofm(datemo))
	keep if year>=1972
	drop if missing(rnd_to_assets)
	collapse (count) real_pat_val_cw_raw real_pat_val_sm_raw patent_apps_raw patent_grants_raw, by(year)
	label var real_pat_val_cw "Value (CW or SM)"
	label var patent_apps "Applications"
	label var patent_grants "Grants"
	tsset year
	tsline real_pat_val_cw patent_apps patent_grants, graphregion(color(white)) ///
		legend( cols(3) ) ///
		lpattern(solid dash solid) lcolor(black blue red) ///
		lwidth(0.7 0.7 0.7) ///
		ytitle("Number of Firms") ///
		title("Non-Missing Patent Var Firm Counts (Non-Missing R&D)")
	graph export "${outFigure}/tsline_nonmissing_patent_var_firm_counts_nonmissing_rnd_to_assets.png", replace
	window manage close graph			
		
		
	// by R&D portfolio
	use lpermno lag_mkt_cap datemo rnd_to_assets ///
		real_pat_val_cw_raw real_pat_val_sm_raw patent_apps_raw patent_grants_raw ///
		using "${dtapath}\crsp_merged_with_monthly_compustat", clear
	
		// create portfolios
		local myportvar = "rnd_to_assets"
		set more off
		bysort datemo: egen p20=pctile(`myportvar'), p(20)
		bysort datemo: egen p40=pctile(`myportvar'), p(40)
		bysort datemo: egen p60=pctile(`myportvar'), p(60)
		bysort datemo: egen p80=pctile(`myportvar'), p(80)
		gen port_quint = 1 if `myportvar'<=p20
		replace port_quint = 2 if `myportvar'>p20 & `myportvar'<=p40
		replace port_quint = 3 if `myportvar'>p40 & `myportvar'<=p60
		replace port_quint = 4 if `myportvar'>p60 & `myportvar'<=p80
		replace port_quint = 5 if `myportvar'>p80
		replace port_quint = . if missing(`myportvar')
		drop if missing(port_quint) // keep only if in a portfolio		
		rename port_quint port
	
		// restrict time period
		gen year = year(dofm(datemo))
		keep if year>=1972

		// count by portfolio
		collapse (count) patval_cw=real_pat_val_cw_raw patval_sm=real_pat_val_sm_raw apps=patent_apps_raw grants=patent_grants_raw, by(port year)
		
		// reshape wide
		reshape wide patval_cw patval_sm apps grants, i(year) j(port)
		tsset year
		
		label var patval_cw1 "Low"
		label var patval_cw2 "Mid-2"
		label var patval_cw3 "Mid-3"
		label var patval_cw4 "Mid-4"
		label var patval_cw5 "High"
		tsline patval_cw*, graphregion(color(white)) ///
			legend( cols(5) ) ///
			lpattern(solid dash dash dash solid) lcolor(red blue green orange black) ///
			lwidth(0.7 0.5 0.5 0.5 0.7) ///
			ytitle("Number of Firms") ///
			title("Non-Missing Patent Value (CW or SM) Firm Counts by R&D Portfolio")
		graph export "${outFigure}/tsline_firm_counts_by_rnd_to_assets_port_nonmissing_patval_cw.png", replace
		window manage close graph		
	
		label var apps1 "Low"
		label var apps2 "Mid-2"
		label var apps3 "Mid-3"
		label var apps4 "Mid-4"
		label var apps5 "High"
		tsline apps*, graphregion(color(white)) ///
			legend( cols(5) ) ///
			lpattern(solid dash dash dash solid) lcolor(red blue green orange black) ///
			lwidth(0.7 0.5 0.5 0.5 0.7) ///
			ytitle("Number of Firms") ///
			title("Non-Missing Patent Application Firm Counts by R&D Portfolio")
		graph export "${outFigure}/tsline_firm_counts_by_rnd_to_assets_port_nonmissing_apps.png", replace
		window manage close graph		
		
		label var grants1 "Low"
		label var grants2 "Mid-2"
		label var grants3 "Mid-3"
		label var grants4 "Mid-4"
		label var grants5 "High"
		tsline grants*, graphregion(color(white)) ///
			legend( cols(5) ) ///
			lpattern(solid dash dash dash solid) lcolor(red blue green orange black) ///
			lwidth(0.7 0.5 0.5 0.5 0.7) ///
			ytitle("Number of Firms") ///
			title("Non-Missing Patent Grant Firm Counts by R&D Portfolio")
		graph export "${outFigure}/tsline_firm_counts_by_rnd_to_assets_port_nonmissing_grants.png", replace
		window manage close graph			
		
	
	// histograms for non-missing variable valuse at the firm level
	use lpermno lag_mkt_cap datemo rnd_to_assets ///
		revt_raw real_pat_val_cw_raw real_pat_val_sm_raw patent_apps_raw patent_grants_raw ///
		using "${dtapath}\crsp_merged_with_monthly_compustat", clear		
	drop if missing(rnd_to_assets) // keep only if in a portfolio		
	gen year = year(dofm(datemo))
	keep if year>=1972		
	keep if year<=2013
	collapse (count) total_firm_obs=revt_raw patval_cw=real_pat_val_cw_raw patval_sm=real_pat_val_sm_raw apps=patent_apps_raw grants=patent_grants_raw, by(lpermno)	
	foreach myvar of varlist patval_cw patval_sm apps grants {
		gen pct_`myvar' = `myvar'/total_firm_obs	
		replace pct_`myvar' = 1 if pct_`myvar'>1 & ~missing(pct_`myvar')
	}
	summ total_firm_obs // to figure out maximum potential firm obs		
	gen pct_N = total_firm_obs / `r(max)' // how many firm obs there are
	foreach myvar in "patval_cw" "apps" "grants" {
		histogram pct_`myvar', freq
		graph export "${outFigure}/histogram_pct_`myvar'_all.png", replace
		histogram pct_`myvar' if pct_`myvar'>0, freq
		graph export "${outFigure}/histogram_pct_`myvar'_pos.png", replace
		tab lpermno if pct_N>0.9
		tab lpermno if pct_N>0.8
		histogram pct_`myvar' if pct_N>0.8, freq
		graph export "${outFigure}/histogram_pct_`myvar'_pos_gt80.png", replace
		histogram pct_`myvar' if pct_N>0.9, freq
		graph export "${outFigure}/histogram_pct_`myvar'_pos_gt90.png", replace
		histogram pct_`myvar' if pct_N==1, freq
		graph export "${outFigure}/histogram_pct_`myvar'_pos_100.png", replace
	}
	
	

	
	
	
/*********************************************************************************************/			
// portfolio assignments and create time series by portfolio

foreach myportvar in "rnd_to_assets" "xsga_to_assets" "xsga_to_assets_rnd" { // 

	//local myportvar="rnd_to_assets"

	disp "`myportvar'"
	
// portfolio assignments	
	
	// monthly rebalancing
	use lpermno lag_mkt_cap datemo `myportvar' using "${dtapath}\crsp_merged_with_monthly_compustat", clear
	
	// foreach myportvar in "rnd_to_total_inv"  {		
		set more off
		bysort datemo: egen p20=pctile(`myportvar'), p(20)
		bysort datemo: egen p40=pctile(`myportvar'), p(40)
		bysort datemo: egen p60=pctile(`myportvar'), p(60)
		bysort datemo: egen p80=pctile(`myportvar'), p(80)
		gen port_quint = 1 if `myportvar'<=p20
		replace port_quint = 2 if `myportvar'>p20 & `myportvar'<=p40
		replace port_quint = 3 if `myportvar'>p40 & `myportvar'<=p60
		replace port_quint = 4 if `myportvar'>p60 & `myportvar'<=p80
		replace port_quint = 5 if `myportvar'>p80
		replace port_quint = . if missing(`myportvar')
		//tab port
		//rename port port_`myportvar'		
		//rename p20 p20_`myportvar'
		//rename p40 p40_`myportvar'
		//rename p60 p60_`myportvar'
		//rename p80 p80_`myportvar'
		drop p20* p40* p60* p80*
		
	tsset lpermno datemo
		
	// choose which portfolio assignment to use
	gen port = port_quint
	keep datemo lpermno port
	//save "${dtapath}\port_rebal_monthly", replace
	save "${dtapath}\temp_port_rebal_monthly", replace

// create time series by portfolio

	use "${dtapath}\crsp_merged_with_monthly_compustat", clear
	//merge 1:1 lpermno datemo using "${dtapath}\port_rebal_monthly", nogen // should be exact match with all obs
	merge 1:1 lpermno datemo using "${dtapath}\temp_port_rebal_monthly", nogen // should be exact match with all obs
	
	// keep only the analysis period of interest
	keep if datemo>=ym(1972, 1)	
	//keep if datemo<=ym(2013,12)	
	keep if datemo<=ym(2016,12)	// sample cut off for consistency across all empirical analysis
	
	// create vars with values that are non-mising only if forward values
	// to which growth rates will be computed are also non-missing
	foreach myvar in "real_xrd" "real_capx" "emp" "xrd" "at" /// from before february 2020
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020
	{
	  gen nomiss_F12_`myvar'_F12     = `myvar'_F12     if ~missing(at_F12) // missing assets is the key
	  foreach fval in 24 36 48 60 72 {
		gen nomiss_F`fval'_`myvar'_F12     = `myvar'_F12     if ~missing(at_F`fval') // missing assets is the key
		gen nomiss_F`fval'_`myvar'_F`fval' = `myvar'_F`fval' if ~missing(at_F`fval') // missing assets is the key
		gen nomiss_xrd_`myvar'_F`fval' = `myvar'_F`fval' if ~missing(xrd_F`fval')
	  }
	}	
		
	// NOTE: no need to run these if needed but leave here just in case want to check again	
	// non-missing revt_F0 value for cash flow ratio
	//gen revt_F0_for_cfr = revt_F0 if ~missing(ocf_F0) & ~missing(revt_F0)
	//gen ocf_F0_for_cfr  = ocf_F0  if ~missing(ocf_F0) & ~missing(revt_F0)

	// for computing unlevered equal-weighted returns
	// note that I set to missing a handful of outliers
	gen quasimkt_lvg = book_debt_F0 / (book_debt_F0 + lag_mkt_cap*(10^3)) // put mkt_cap in millions	
	replace quasimkt_lvg = . if quasimkt_lvg<0 // set to missing if negative
	replace quasimkt_lvg = . if quasimkt_lvg>1 & ~missing(quasimkt_lvg) // set to missing if greater than 100%
	//summ quasimkt_lvg, detail
	gen ret_un = (1-quasimkt_lvg)*ret
	
	// collapse for market portfolio including those with missing port values
	preserve
		
		// prepare for collapsing
		bysort datemo: egen lag_mkt_cap_sum = sum(lag_mkt_cap)
		gen contrib_wgt = (lag_mkt_cap/lag_mkt_cap_sum)
		gen contrib_ret = contrib_wgt * ret	
		sort lpermno datemo // for visual checking		
		
		// collapse by portfolios
		collapse (count) num_firms=ret (mean) port_ret_ew=ret port_ret_un_ew=ret_un ///
			(sum) check_wgt=contrib_wgt port_ret_vw=contrib_ret lag_mkt_cap book_debt_F0 book_equity_F0 ///
				  emp* real_xrd* real_capx* /// 
				  at_* xrd_* ///
				  oibdp_* revt_* cogs_* ///
				  ocf_F0 ///
				  real_revt* real_xsga* real_ocf* real_pat_* patent_* /// added february 2020
				  nomiss_* ///
			, by(datemo) 
		//summ check_wgt 
		drop if check_wgt <0.9 // should only drop missing observations	
		drop check_wgt		
		
		gen port=999
		save "${dtapath}\temp_market_port_incl_missing_port", replace	
		
	restore		
	
	// focus on firms that are in portfolios
	drop if missing(port)		
	
	// export list of counts by SIC code
	preserve
	  if "`myportvar'"=="rnd_to_assets" { // only export this sheet for benchmark myportvar
		gen dummy=1
		collapse (sum) count=dummy, by(datemo port sic_compustat)
		bysort datemo port: egen port_N = sum(count) 
		gen pct_count = count / port_N
		collapse (sum) count (mean) mean_pct_count=pct_count, by(port sic_compustat)
		bysort port: egen port_N = sum(count) 
		gen sum_pct_count = count / port_N
		gsort port -sum_pct_count
		bysort port: egen rank_mean_pct = rank(mean_pct_count), field
		bysort port: egen  rank_sum_pct = rank( sum_pct_count), field
		tostring port, gen(temp_port_str)
		tostring rank_mean_pct, gen(temp_rank_mean_pct_str)
		tostring rank_sum_pct, gen(temp_rank_sum_pct_str)
		gen lookup_val_rank_mean = "port" + temp_port_str + "-" + temp_rank_mean_pct_str
		gen lookup_val_rank_sum  = "port" + temp_port_str + "-" + temp_rank_sum_pct_str
		drop temp_*
		// zzz
		export excel using "${outPath}\tables_for_paper.xlsx", sheet("raw_sic_code_summ_by_port") sheetreplace firstrow(variables)
	  }
	restore
	
	// collapse for market portfolio
	preserve
		
		// prepare for collapsing
		bysort datemo: egen lag_mkt_cap_sum = sum(lag_mkt_cap)
		gen contrib_wgt = (lag_mkt_cap/lag_mkt_cap_sum)
		gen contrib_ret = contrib_wgt * ret	
		sort lpermno datemo // for visual checking		
		
		// collapse by portfolios
		collapse (count) num_firms=ret (mean) port_ret_ew=ret port_ret_un_ew=ret_un ///
			(sum) check_wgt=contrib_wgt port_ret_vw=contrib_ret lag_mkt_cap book_debt_F0 book_equity_F0 ///
				  emp* real_xrd* real_capx* ///
				  at_* xrd_* ///
				  oibdp_* revt_* cogs_* ///
				  ocf_F0 ///
				  real_revt* real_xsga* real_ocf* real_pat_* patent_* /// added february 2020
				  nomiss_* ///
			, by(datemo) 
		//summ check_wgt 
		drop if check_wgt <0.9 // should only drop missing observations	
		drop check_wgt		
		
		gen port=0
		save "${dtapath}\temp_market_port", replace	
		
	restore	
	
	
	// collapse for mid portfolio combined
	preserve
		
		// keep only middle portfolios
		keep if port==2 | port==3 | port==4
		replace port=234 // combined portfolios 2 3 and 4
		
		// prepare for collapsing by portfolio
		bysort port datemo: egen lag_mkt_cap_sum = sum(lag_mkt_cap)
		gen contrib_wgt = (lag_mkt_cap/lag_mkt_cap_sum)
		gen contrib_ret = contrib_wgt * ret	
		sort lpermno datemo // for visual checking
				
		// collapse by portfolio
		collapse (count) num_firms=ret (mean) port_ret_ew=ret port_ret_un_ew=ret_un ///
			(sum) check_wgt=contrib_wgt port_ret_vw=contrib_ret lag_mkt_cap book_debt_F0 book_equity_F0 ///
				  emp* real_xrd* real_capx* ///
				  at_* xrd_* ///
				  oibdp_* revt_* cogs_* ///
				  ocf_F0 ///
				  real_revt* real_xsga* real_ocf* real_pat_* patent_* /// added february 2020
				  nomiss_* ///
			, by(datemo port) 
		drop if check_wgt <0.9 // should only drop missing observations	
		drop check_wgt	
				
		save "${dtapath}\temp_mid_port", replace	
		
	restore		
	
	
	// focus on firms that are in portfolios (repeated from above just in case)
	drop if missing(port)			
	
	// prepare for collapsing by portfolio
	bysort port datemo: egen lag_mkt_cap_sum = sum(lag_mkt_cap)
	gen contrib_wgt = (lag_mkt_cap/lag_mkt_cap_sum)
	gen contrib_ret = contrib_wgt * ret	
	sort lpermno datemo // for visual checking

			// check outlier in port2
			if 1==0 {
				keep if port==2
				keep if datemo==ym(1981,1)
				gen gro_5yr_real_totinv = 100*(real_totinv_F72/real_totinv_F12-1) if datemo<=ym(2011,12)
				order real_totinv_F72 real_totinv_F12 gro_5yr_real_totinv real_totinv_F*
				//sort gro_5yr_real_totinv
				gsort -real_totinv_F12
			}
			
			// check why earnings per unit of capital so negative in early 2000s for high R&D port
			if 1==0 {
				keep if port==5
				keep if datemo==ym(2003,2)
				gen ebitda_at_F0 = oibdp_F0 / at_F0	
				order oibdp_F0 at_F0 ebitda_at_F0 
				//sort gro_5yr_real_totinv
				gsort oibdp_F0
			}
			
	// collapse by portfolio
	collapse (count) num_firms=ret (mean) port_ret_ew=ret port_ret_un_ew=ret_un ///
		(sum) check_wgt=contrib_wgt port_ret_vw=contrib_ret lag_mkt_cap book_debt_F0 book_equity_F0 ///
			  emp* real_xrd* real_capx* ///
			  at_* xrd_* ///
			  oibdp_* revt_* cogs_* ///
			  ocf_F0 /// ocf_F0_for_cfr 
			  real_revt* real_xsga* real_ocf* real_pat_* patent_* /// added february 2020
			  nomiss_* ///
		, by(datemo port) 
	drop if check_wgt <0.9 // should only drop missing observations	
	drop check_wgt
	
	// add back market portfolio and combined middle portfolio
	append using "${dtapath}\temp_market_port_incl_missing_port"
	append using "${dtapath}\temp_market_port"
	append using "${dtapath}\temp_mid_port"
	
	// set patent-related values to missing instead of zero b/c no data available
	// means we should not use such values in growth rates
	foreach mypatvar of varlist real_pat_val* patent_* {
		replace `mypatvar'=. if `mypatvar'==0
	}
	
	// compute R&D intensity and labor prod
	foreach fval in 0 12 24 36 48 60 72 {
		gen rnd_to_assets_F`fval' = xrd_F`fval' / at_F`fval'
		gen labor_prod_F`fval' = revt_F`fval' / emp_F`fval' // added Feb. 2020
	}		
	
	// compute total investment variables
	foreach fval in 0 12 24 36 48 60 72 {
		egen real_totinv_F`fval' = rowtotal(real_capx_F`fval' real_xrd_F`fval'), missing
		if `fval'>12 {
		  egen nomiss_F`fval'_real_totinv_F12 = rowtotal(nomiss_F`fval'_real_capx_F12 nomiss_F`fval'_real_xrd_F12) if ~missing(at_F`fval') // missing assets is the key
		  egen nomiss_F`fval'_real_totinv_F`fval' = rowtotal(nomiss_F`fval'_real_capx_F`fval' nomiss_F`fval'_real_xrd_F`fval') if ~missing(at_F`fval') // missing assets is the key
		  egen nomiss_xrd_real_totinv_F`fval' = rowtotal(nomiss_xrd_real_capx_F`fval' nomiss_xrd_real_xrd_F`fval'), missing
		}
	}		
	
	// markup at the portfolio level
	gen markup_ebitda_F0 = oibdp_F0 / revt_F0
	gen markup_rev_F0    = (revt_F0-cogs_F0) / revt_F0

	// earnings per unit of capital
	gen ebitda_at_F0 = oibdp_F0 / at_F0	
	
	// for computing unlevered value-weighted returns
	gen quasimkt_lvg = book_debt_F0 / (book_debt_F0 + lag_mkt_cap*(10^3)) // put mkt_cap in millions
	gen port_ret_un_vw = (1-quasimkt_lvg)*port_ret_vw	
		
	
	// other ratios of interest for summary table
	
		// sales to assets
		gen sales_to_assets = revt_F0 / at_F0
		
		// more leverage ratios
		gen book_leverage_raw = book_debt_F0 / (book_debt_F0+book_equity_F0)
		gen book_leverage_trunc = book_leverage_raw
		replace book_leverage_trunc = 1 if book_leverage_raw>1 & ~missing(book_leverage_raw) // due to negative book equity which is like 100% book leverage
		replace book_leverage_trunc = 0 if book_leverage_raw<0 & ~missing(book_leverage_raw) // due to negative book debt which is like 0% book leverage
		gen book_leverage_maxjfe = 1- (book_equity_F0/at_F0)	
		
		// tobin's Q
		gen tobinQ = lag_mkt_cap*(10^3)/book_equity_F0
		summ tobinQ, detail
		//sort datemo
		//line tobinQ datemo if port==1
		//line tobinQ datemo if port==5
		
		// cash flow profitability ratio
		gen cfprof_ratio = ocf_F0 / revt_F0 		
		summ cfprof_ratio, detail		
		//sort datemo
		//line cfprof_ratio datemo if port==1
		//line cfprof_ratio datemo if port==5
		// negative ratio for port 5 is not data error in 2000s		
		//gen cfprof_ratio2 = ocf_F0_for_cfr / revt_F0_for_cfr  
		//line cfprof_ratio2 datemo if port==5
	
	
	/*deflate returns from nominal to real using a cpi deflator*/
	local deflator = "ibbotson" // either choose "cpi" or "ibbotson"
	if "`deflator'"=="ibbotson" {
		//merge m:1 datemo using "${dtapath}\ibbotson_monthly", nogen noreport keep(master match)					
		merge m:1 datemo using "${dtapath}\inflation_monthly", ///
			nogen noreport keep(master match) keepusing(inflation_deflator)				
		gen port_ret_vw_real = (1+port_ret_vw)/inflation_deflator - 1
		gen port_ret_ew_real = (1+port_ret_ew)/inflation_deflator - 1
		gen port_ret_un_vw_real = (1+port_ret_un_vw)/inflation_deflator - 1
		gen port_ret_un_ew_real = (1+port_ret_un_ew)/inflation_deflator - 1
	}
	else {
		error "choose either cpi or inflation to deflate returns"
	}	
	
	// compute forward-looking growth rates
	foreach myvar in "real_xrd" "real_capx" "real_totinv" "emp" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020	
		"labor_prod" /// added february 2020	
	{
	
		gen gro_1yr_`myvar' = 100*(`myvar'_F24/`myvar'_F12-1) 
		gen gro_2yr_`myvar' = 100*(`myvar'_F36/`myvar'_F12-1) 
		gen gro_3yr_`myvar' = 100*(`myvar'_F48/`myvar'_F12-1) 
		gen gro_4yr_`myvar' = 100*(`myvar'_F60/`myvar'_F12-1) if datemo<=ym(2012,12)						
		gen gro_5yr_`myvar' = 100*(`myvar'_F72/`myvar'_F12-1) if datemo<=ym(2011,12)						 				
		// for 2012 and 2013 the cumulative growth rates will be off because
		// underlying sample ends in 2016. technically there are some data
		// points in 2017 but these are sparse

		gen gro_ann_1yr_`myvar' = 100*((`myvar'_F24/`myvar'_F12)^(1/1)-1) 
		gen gro_ann_2yr_`myvar' = 100*((`myvar'_F36/`myvar'_F12)^(1/2)-1) 
		gen gro_ann_3yr_`myvar' = 100*((`myvar'_F48/`myvar'_F12)^(1/3)-1) 
		gen gro_ann_4yr_`myvar' = 100*((`myvar'_F60/`myvar'_F12)^(1/4)-1) if datemo<=ym(2012,12)						
		gen gro_ann_5yr_`myvar' = 100*((`myvar'_F72/`myvar'_F12)^(1/5)-1) if datemo<=ym(2011,12)		
		
		// repeat for totals computed only when future non-missing
		//gen nomiss_gro_1yr_`myvar' = 100*(nomiss_F24_`myvar'_F24/nomiss_F24_`myvar'_F12-1) 
		//gen nomiss_gro_2yr_`myvar' = 100*(nomiss_F36_`myvar'_F36/nomiss_F36_`myvar'_F12-1) 
		//gen nomiss_gro_3yr_`myvar' = 100*(nomiss_F48_`myvar'_F48/nomiss_F48_`myvar'_F12-1) 
		//gen nomiss_gro_4yr_`myvar' = 100*(nomiss_F60_`myvar'_F60/nomiss_F60_`myvar'_F12-1) if datemo<=ym(2012,12)						
		//gen nomiss_gro_5yr_`myvar' = 100*(nomiss_F72_`myvar'_F72/nomiss_F72_`myvar'_F12-1) if datemo<=ym(2011,12)			
		
	}		
		
		
	// compute change in ratio values
	foreach myvar in "rnd_to_assets" {
		// old method that generates negative average market growth
		gen diff_ratio_1yr_`myvar' = 100*(`myvar'_F24 - `myvar'_F12) 
		gen diff_ratio_2yr_`myvar' = 100*(`myvar'_F36 - `myvar'_F12) 
		gen diff_ratio_3yr_`myvar' = 100*(`myvar'_F48 - `myvar'_F12) 
		gen diff_ratio_4yr_`myvar' = 100*(`myvar'_F60 - `myvar'_F12) if datemo<=ym(2012,12)						 
		gen diff_ratio_5yr_`myvar' = 100*(`myvar'_F72 - `myvar'_F12) if datemo<=ym(2011,12)	
		
		gen diff_ratio_ann_1yr_`myvar' = 100*(`myvar'_F24 - `myvar'_F12)/1 
		gen diff_ratio_ann_2yr_`myvar' = 100*(`myvar'_F36 - `myvar'_F12)/2 
		gen diff_ratio_ann_3yr_`myvar' = 100*(`myvar'_F48 - `myvar'_F12)/3 
		gen diff_ratio_ann_4yr_`myvar' = 100*(`myvar'_F60 - `myvar'_F12)/4 if datemo<=ym(2012,12)						 
		gen diff_ratio_ann_5yr_`myvar' = 100*(`myvar'_F72 - `myvar'_F12)/5 if datemo<=ym(2011,12)			
		// new method that should have positive average value for market (or close to zero)
		if "`myvar'"=="rnd_to_assets" {
			// assuming missing xrd values are zero and use average of assets
			// in denominator to avoid the impact of large changes in assets
			// during some sub samples
			gen diff_1yr_`myvar' = 100*(xrd_F24-xrd_F12)/((at_F24+at_F12)/2)
			gen diff_2yr_`myvar' = 100*(xrd_F36-xrd_F12)/((at_F36+at_F12)/2)
			gen diff_3yr_`myvar' = 100*(xrd_F48-xrd_F12)/((at_F48+at_F12)/2)			
			gen diff_4yr_`myvar' = 100*(xrd_F60-xrd_F12)/((at_F60+at_F12)/2) if datemo<=ym(2012,12)						 
			gen diff_5yr_`myvar' = 100*(xrd_F72-xrd_F12)/((at_F72+at_F12)/2) if datemo<=ym(2011,12)						 		
			// no missing xrd values
			gen nomiss_diff_1yr_`myvar' = 100*(xrd_F24/nomiss_xrd_at_F24 - xrd_F12/at_F12)
			gen nomiss_diff_2yr_`myvar' = 100*(xrd_F36/nomiss_xrd_at_F36 - xrd_F12/at_F12)
			gen nomiss_diff_3yr_`myvar' = 100*(xrd_F48/nomiss_xrd_at_F48 - xrd_F12/at_F12)
			gen nomiss_diff_4yr_`myvar' = 100*(xrd_F60/nomiss_xrd_at_F60 - xrd_F12/at_F12) if datemo<=ym(2012,12)						 
			gen nomiss_diff_5yr_`myvar' = 100*(xrd_F72/nomiss_xrd_at_F72 - xrd_F12/at_F12) if datemo<=ym(2011,12)						 					
		}		
	}
		
	/*add on recession indicators*/
	gen full=1
	merge m:1 datemo using "${dtapath}\nber_recession_dummies", nogen noreport keep(match) keepusing(rec_dum)
	merge m:1 datemo using "${dtapath}\integrated_volatility_monthly", nogen noreport keep(match) ///
		keepusing(high_ivol_80 high_ivol_90 high_ivol_95)
		//keepusing(high_ivol_80 high_ivol_90 high_ivol_95 high_ivol_qtr_80 high_ivol_qtr_90 high_ivol_qtr_95)
		
	// add on economic policy uncertainty indicator
	merge m:1 datemo using "${dtapath}\epu_hist_index_monthly", nogen keep(master match) ///
		keepusing( ///
			high_epu_hist_full_80 high_epu_hist_full_90 high_epu_hist_full_95 ///
			high_epu_hist_from1972_80 high_epu_hist_from1972_90 high_epu_hist_from1972_95 ///
		)
	
	
	// compute excess returns
	merge m:1 datemo using "${dtapath}\famafrench_monthly_factors", nogen keepusing(rf) keep(master match)
	foreach rettype in "ew" "vw" "un_ew" "un_vw" {
		gen ex_ret_`rettype' = port_ret_`rettype' - rf/100
	}
	
	// compute market cap shares
	gen lag_mkt_cap_for_sum = lag_mkt_cap if inlist(port,1,2,3,4,5)
	bysort datemo: egen sum_lag_mkt_cap = sum(lag_mkt_cap_for_sum)
	gen share_lag_mkt_cap = lag_mkt_cap / sum_lag_mkt_cap
	drop lag_mkt_cap_for_sum sum_lag_mkt_cap
	
	sort port datemo
	tsset port datemo		
	save "${dtapath}\time_series_by_port_`myportvar'", replace				
	
}

	// save default portfolio
	use "${dtapath}\time_series_by_port_rnd_to_assets", clear
	save "${dtapath}\time_series_by_port", replace				
	
	// check out the others
	use "${dtapath}\time_series_by_port_rnd_to_assets", clear
	//use "${dtapath}\time_series_by_port_rnd_misseq0_to_assets", clear
	
	// figures to test out new patent-related measures
			
		// check out patent values
		local myvar = "real_pat_val_sm"
		local myyear=3
		use "${dtapath}\time_series_by_port", replace
		keep if month(dofm(datemo))==7
		gen plotvar = gro_ann_`myyear'yr_`myvar'  if gro_ann_`myyear'yr_`myvar'>-100		
		keep port datemo plotvar `myvar'*
		tab port		
		//br if port==1 
		keep if port>=1 & port<=5
		keep port datemo plotvar 
		reshape wide plotvar, i(datemo) j(port)
		//tsline plotvar*
		// conclusion: there is too much variation the low R&D portfolio probably
		//             because of insufficient or low data
		
		
		// check out patent values
		local myvar = "labor_prod"
		local myyear=3
		use "${dtapath}\time_series_by_port", replace
		keep if month(dofm(datemo))==7
		gen plotvar = gro_ann_`myyear'yr_`myvar'  if gro_ann_`myyear'yr_`myvar'>-100		
		keep port datemo plotvar `myvar'*
		tab port		
		//br if port==1 
		keep if port>=1 & port<=5
		keep port datemo plotvar 
		reshape wide plotvar, i(datemo) j(port)
		//tsline plotvar*
		// conclusion: aggregated series look fine but maybe some issues in 2014
	

	
	
/*********************************************************************************************/			
// create time series by industry (i.e., industry portfolios)

foreach myindvar in "ff49_rnd" "sic2_rnd" "ff49_rnd0" "sic2_rnd0"  { // can also try ff30 and/or sic3

//local myindvar="sic2"

	disp "`myindvar'"
	
// create time series by portfolio

	use "${dtapath}\crsp_merged_with_monthly_compustat", clear

	// note that sic_compustat missing often
	
		// by period
		if 1==0 {
			gen missing_sic_compustat = missing(sic_compustat)
			collapse (sum) missing_sic_compustat (count) total=missing_sic_compustat, by(datemo)
			gen pct_missing = missing_sic_compustat / total
			tsset datemo
			tsline pct_missing
			// note: missing alot more often in early 1970s
		}
		
		// by firm
		if 1==0 {
			gen missing_sic_compustat = missing(sic_compustat)
			gen missing_assets = missing(at_F0)
			gen missing_xrd = missing(xrd_F0)
			
			bysort lpermno: egen total_missing_sic = total(missing_sic_compustat)
			br if total_missing_sic>100
			
			collapse ///
				(sum) missing_sic_compustat missing_assets missing_xrd ///
				(count) total=missing_sic_compustat ///
				, by(lpermno)
			gen pct_missing_sic = missing_sic_compustat / total
			gen pct_missing_at  = missing_assets / total
			gen pct_missing_xrd = missing_xrd / total
			tab pct_missing_sic			
			summ pct_missing_at if pct_missing_sic==1, detail
			summ pct_missing_xrd if pct_missing_sic==1, detail
			summ pct_missing_at if pct_missing_sic==0, detail
			summ pct_missing_xrd if pct_missing_sic==0, detail		
			summ total if pct_missing_sic==1, detail
			// note: firms always missing sic are also always missing assets. this
			// is because they have monthly returns data but not balance sheet
			// info. these are firms not matched from crsp to compustat
		}		
		

	// drop if no sic code because nothing can do about it
	drop if missing(sic_compustat)
	
	// check out percent of firms with non-missing xrd
	if 1==0 { 
		gen has_nomiss_xrd = 1
		gen Nfirms = 1
		tostring sic_compustat, gen(sic_str)
		gen length_sic_str = length(sic_str)
		tab length_sic_str 
		tab sic_str if length_sic_str<4
		gen sic2 = substr(sic_str,1,2)			
		replace sic2 = "0" + substr(sic_str,1,1) if length_sic_str==3
		keep datemo lpermno has_nomiss_xrd Nfirms sic2
		collapse (sum) has_nomiss_xrd Nfirms, by(sic2 datemo)
		replace has_nomiss_xrd = 0 if missing(has_nomiss_xrd)
		replace Nfirms = 0 if missing(Nfirms)
		reshape wide has_nomiss_xrd Nfirms, i(datemo) j(sic2) s
		keep if datemo>=ym(1973,1)
		tsset datemo
		//tsline has_*, legend(off)
		summ has_*
		// conclusion: depends on industry but can be zero
	}	
	
	// drop firm-year obs with missing rnd if desired. note that
	// default is to keep firms with missing xrd
	if "`myindvar'"=="ff49_rnd" | "`myindvar'"=="sic2_rnd" {		
		drop if missing(rnd_to_assets)
	}
	
	// fama-french industry classifications	
	if "`myindvar'"=="ff49_rnd" | "`myindvar'"=="ff49_rnd0" {
		//use "${dtapath}\siccodes_industries_49", clear		
		gen sic = sic_compustat	
		merge m:1 sic using "${dtapath}\siccodes_industries_49", nogen keep(master match) keepusing(industry_short_name)
		rename industry_short_name port_ind
		replace port_ind = "Other" if missing(port_ind)	
		tab port_ind
		label var port_ind "FF49 Industry"
		drop sic
	}
	
	// direct SIC-based industry classification
	if "`myindvar'"=="sic2_rnd" | "`myindvar'"=="sic2_rnd0" {
		//use "${dtapath}\siccodes_industries_49", clear	
		tostring sic_compustat, gen(sic_str)
		gen length_sic_str = length(sic_str)
		tab length_sic_str 
		tab sic_str if length_sic_str<4
		gen port_ind = substr(sic_str,1,2)
		replace port_ind = "0" + substr(sic_str,1,1) if length_sic_str==3
		tab port_ind
		label var port_ind "SIC2 Industry"
		drop sic_str length_sic_str
	}	

	// keep only the analysis period of interest
	keep if datemo>=ym(1972, 1)	
	//keep if datemo<=ym(2013,12)	
	keep if datemo<=ym(2016,12)	// sample cut off for consistency across all empirical analysis
	
	// create vars with values that are non-mising only if forward values
	// to which growth rates will be computed are also non-missing
	foreach myvar in "real_xrd" "real_capx" "emp" "xrd" "at" /// from before february 2020
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020
	{
	  gen nomiss_F12_`myvar'_F12     = `myvar'_F12     if ~missing(at_F12) // missing assets is the key
	  foreach fval in 24 36 48 60 72 {
		gen nomiss_F`fval'_`myvar'_F12     = `myvar'_F12     if ~missing(at_F`fval') // missing assets is the key
		gen nomiss_F`fval'_`myvar'_F`fval' = `myvar'_F`fval' if ~missing(at_F`fval') // missing assets is the key
		gen nomiss_xrd_`myvar'_F`fval' = `myvar'_F`fval' if ~missing(xrd_F`fval')
	  }
	}	
		
	// NOTE: no need to run these if needed but leave here just in case want to check again	
	// non-missing revt_F0 value for cash flow ratio
	//gen revt_F0_for_cfr = revt_F0 if ~missing(ocf_F0) & ~missing(revt_F0)
	//gen ocf_F0_for_cfr  = ocf_F0  if ~missing(ocf_F0) & ~missing(revt_F0)

	// for computing unlevered equal-weighted returns
	// note that I set to missing a handful of outliers
	gen quasimkt_lvg = book_debt_F0 / (book_debt_F0 + lag_mkt_cap*(10^3)) // put mkt_cap in millions	
	replace quasimkt_lvg = . if quasimkt_lvg<0 // set to missing if negative
	replace quasimkt_lvg = . if quasimkt_lvg>1 & ~missing(quasimkt_lvg) // set to missing if greater than 100%
	//summ quasimkt_lvg, detail
	gen ret_un = (1-quasimkt_lvg)*ret
	
	// focus on firms that are in portfolios
	drop if missing(port)		
	
	// prepare for collapsing by portfolio
	bysort port datemo: egen lag_mkt_cap_sum = sum(lag_mkt_cap)
	gen contrib_wgt = (lag_mkt_cap/lag_mkt_cap_sum)
	gen contrib_ret = contrib_wgt * ret	
	sort lpermno datemo // for visual checking
			
	// collapse by portfolio
	collapse (count) num_firms=ret (mean) port_ret_ew=ret port_ret_un_ew=ret_un ///
		(sum) check_wgt=contrib_wgt port_ret_vw=contrib_ret lag_mkt_cap book_debt_F0 book_equity_F0 ///
			  emp* real_xrd* real_capx* ///
			  at_* xrd_* ///
			  oibdp_* revt_* cogs_* ///
			  ocf_F0 /// ocf_F0_for_cfr 
			  real_revt* real_xsga* real_ocf* real_pat_* patent_* /// added february 2020
			  nomiss_* ///
		, by(datemo port) 
	drop if check_wgt <0.9 // should only drop missing observations	
	drop check_wgt
	
	// set patent-related values to missing instead of zero b/c no data available
	// means we should not use such values in growth rates
	foreach mypatvar of varlist real_pat_val* patent_* {
		replace `mypatvar'=. if `mypatvar'==0
	}
	
	// compute R&D intensity and labor prod
	foreach fval in 0 12 24 36 48 60 72 {
		gen rnd_to_assets_F`fval' = xrd_F`fval' / at_F`fval'
		gen labor_prod_F`fval' = revt_F`fval' / emp_F`fval' // added Feb. 2020
	}		
	
	// compute total investment variables
	foreach fval in 0 12 24 36 48 60 72 {
		egen real_totinv_F`fval' = rowtotal(real_capx_F`fval' real_xrd_F`fval'), missing
		if `fval'>12 {
		  egen nomiss_F`fval'_real_totinv_F12 = rowtotal(nomiss_F`fval'_real_capx_F12 nomiss_F`fval'_real_xrd_F12) if ~missing(at_F`fval') // missing assets is the key
		  egen nomiss_F`fval'_real_totinv_F`fval' = rowtotal(nomiss_F`fval'_real_capx_F`fval' nomiss_F`fval'_real_xrd_F`fval') if ~missing(at_F`fval') // missing assets is the key
		  egen nomiss_xrd_real_totinv_F`fval' = rowtotal(nomiss_xrd_real_capx_F`fval' nomiss_xrd_real_xrd_F`fval'), missing
		}
	}		
	
	// markup at the portfolio level
	gen markup_ebitda_F0 = oibdp_F0 / revt_F0
	gen markup_rev_F0    = (revt_F0-cogs_F0) / revt_F0

	// earnings per unit of capital
	gen ebitda_at_F0 = oibdp_F0 / at_F0	
	
	// for computing unlevered value-weighted returns
	gen quasimkt_lvg = book_debt_F0 / (book_debt_F0 + lag_mkt_cap*(10^3)) // put mkt_cap in millions
	gen port_ret_un_vw = (1-quasimkt_lvg)*port_ret_vw	
		
	
	// other ratios of interest for summary table
	
		// sales to assets
		gen sales_to_assets = revt_F0 / at_F0
		
		// more leverage ratios
		gen book_leverage_raw = book_debt_F0 / (book_debt_F0+book_equity_F0)
		gen book_leverage_trunc = book_leverage_raw
		replace book_leverage_trunc = 1 if book_leverage_raw>1 & ~missing(book_leverage_raw) // due to negative book equity which is like 100% book leverage
		replace book_leverage_trunc = 0 if book_leverage_raw<0 & ~missing(book_leverage_raw) // due to negative book debt which is like 0% book leverage
		gen book_leverage_maxjfe = 1- (book_equity_F0/at_F0)	
		
		// tobin's Q
		gen tobinQ = lag_mkt_cap*(10^3)/book_equity_F0
		summ tobinQ, detail
		//sort datemo
		//line tobinQ datemo if port==1
		//line tobinQ datemo if port==5
		
		// cash flow profitability ratio
		gen cfprof_ratio = ocf_F0 / revt_F0 		
		summ cfprof_ratio, detail		
		//sort datemo
		//line cfprof_ratio datemo if port==1
		//line cfprof_ratio datemo if port==5
		// negative ratio for port 5 is not data error in 2000s		
		//gen cfprof_ratio2 = ocf_F0_for_cfr / revt_F0_for_cfr  
		//line cfprof_ratio2 datemo if port==5
	
	
	/*deflate returns from nominal to real using a cpi deflator*/
	local deflator = "ibbotson" // either choose "cpi" or "ibbotson"
	if "`deflator'"=="ibbotson" {
		//merge m:1 datemo using "${dtapath}\ibbotson_monthly", nogen noreport keep(master match)					
		merge m:1 datemo using "${dtapath}\inflation_monthly", ///
			nogen noreport keep(master match) keepusing(inflation_deflator)				
		gen port_ret_vw_real = (1+port_ret_vw)/inflation_deflator - 1
		gen port_ret_ew_real = (1+port_ret_ew)/inflation_deflator - 1
		gen port_ret_un_vw_real = (1+port_ret_un_vw)/inflation_deflator - 1
		gen port_ret_un_ew_real = (1+port_ret_un_ew)/inflation_deflator - 1
	}
	else {
		error "choose either cpi or inflation to deflate returns"
	}	
	
	// compute forward-looking growth rates
	foreach myvar in "real_xrd" "real_capx" "real_totinv" "emp" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020	
		"labor_prod" /// added february 2020	
	{
	
		gen gro_1yr_`myvar' = 100*(`myvar'_F24/`myvar'_F12-1) 
		gen gro_2yr_`myvar' = 100*(`myvar'_F36/`myvar'_F12-1) 
		gen gro_3yr_`myvar' = 100*(`myvar'_F48/`myvar'_F12-1) 
		gen gro_4yr_`myvar' = 100*(`myvar'_F60/`myvar'_F12-1) if datemo<=ym(2012,12)						
		gen gro_5yr_`myvar' = 100*(`myvar'_F72/`myvar'_F12-1) if datemo<=ym(2011,12)						 				
		// for 2012 and 2013 the cumulative growth rates will be off because
		// underlying sample ends in 2016. technically there are some data
		// points in 2017 but these are sparse

		gen gro_ann_1yr_`myvar' = 100*((`myvar'_F24/`myvar'_F12)^(1/1)-1) 
		gen gro_ann_2yr_`myvar' = 100*((`myvar'_F36/`myvar'_F12)^(1/2)-1) 
		gen gro_ann_3yr_`myvar' = 100*((`myvar'_F48/`myvar'_F12)^(1/3)-1) 
		gen gro_ann_4yr_`myvar' = 100*((`myvar'_F60/`myvar'_F12)^(1/4)-1) if datemo<=ym(2012,12)						
		gen gro_ann_5yr_`myvar' = 100*((`myvar'_F72/`myvar'_F12)^(1/5)-1) if datemo<=ym(2011,12)		
		
		// repeat for totals computed only when future non-missing
		//gen nomiss_gro_1yr_`myvar' = 100*(nomiss_F24_`myvar'_F24/nomiss_F24_`myvar'_F12-1) 
		//gen nomiss_gro_2yr_`myvar' = 100*(nomiss_F36_`myvar'_F36/nomiss_F36_`myvar'_F12-1) 
		//gen nomiss_gro_3yr_`myvar' = 100*(nomiss_F48_`myvar'_F48/nomiss_F48_`myvar'_F12-1) 
		//gen nomiss_gro_4yr_`myvar' = 100*(nomiss_F60_`myvar'_F60/nomiss_F60_`myvar'_F12-1) if datemo<=ym(2012,12)						
		//gen nomiss_gro_5yr_`myvar' = 100*(nomiss_F72_`myvar'_F72/nomiss_F72_`myvar'_F12-1) if datemo<=ym(2011,12)			
		
	}		
		
		
	// compute change in ratio values
	foreach myvar in "rnd_to_assets" {
		// old method that generates negative average market growth
		gen diff_ratio_1yr_`myvar' = 100*(`myvar'_F24 - `myvar'_F12) 
		gen diff_ratio_2yr_`myvar' = 100*(`myvar'_F36 - `myvar'_F12) 
		gen diff_ratio_3yr_`myvar' = 100*(`myvar'_F48 - `myvar'_F12) 
		gen diff_ratio_4yr_`myvar' = 100*(`myvar'_F60 - `myvar'_F12) if datemo<=ym(2012,12)						 
		gen diff_ratio_5yr_`myvar' = 100*(`myvar'_F72 - `myvar'_F12) if datemo<=ym(2011,12)	
		
		gen diff_ratio_ann_1yr_`myvar' = 100*(`myvar'_F24 - `myvar'_F12)/1 
		gen diff_ratio_ann_2yr_`myvar' = 100*(`myvar'_F36 - `myvar'_F12)/2 
		gen diff_ratio_ann_3yr_`myvar' = 100*(`myvar'_F48 - `myvar'_F12)/3 
		gen diff_ratio_ann_4yr_`myvar' = 100*(`myvar'_F60 - `myvar'_F12)/4 if datemo<=ym(2012,12)						 
		gen diff_ratio_ann_5yr_`myvar' = 100*(`myvar'_F72 - `myvar'_F12)/5 if datemo<=ym(2011,12)			
		// new method that should have positive average value for market (or close to zero)
		if "`myvar'"=="rnd_to_assets" {
			// assuming missing xrd values are zero and use average of assets
			// in denominator to avoid the impact of large changes in assets
			// during some sub samples
			gen diff_1yr_`myvar' = 100*(xrd_F24-xrd_F12)/((at_F24+at_F12)/2)
			gen diff_2yr_`myvar' = 100*(xrd_F36-xrd_F12)/((at_F36+at_F12)/2)
			gen diff_3yr_`myvar' = 100*(xrd_F48-xrd_F12)/((at_F48+at_F12)/2)			
			gen diff_4yr_`myvar' = 100*(xrd_F60-xrd_F12)/((at_F60+at_F12)/2) if datemo<=ym(2012,12)						 
			gen diff_5yr_`myvar' = 100*(xrd_F72-xrd_F12)/((at_F72+at_F12)/2) if datemo<=ym(2011,12)						 		
			// no missing xrd values
			gen nomiss_diff_1yr_`myvar' = 100*(xrd_F24/nomiss_xrd_at_F24 - xrd_F12/at_F12)
			gen nomiss_diff_2yr_`myvar' = 100*(xrd_F36/nomiss_xrd_at_F36 - xrd_F12/at_F12)
			gen nomiss_diff_3yr_`myvar' = 100*(xrd_F48/nomiss_xrd_at_F48 - xrd_F12/at_F12)
			gen nomiss_diff_4yr_`myvar' = 100*(xrd_F60/nomiss_xrd_at_F60 - xrd_F12/at_F12) if datemo<=ym(2012,12)						 
			gen nomiss_diff_5yr_`myvar' = 100*(xrd_F72/nomiss_xrd_at_F72 - xrd_F12/at_F12) if datemo<=ym(2011,12)						 					
		}		
	}
		
	/*add on recession indicators*/
	gen full=1
	merge m:1 datemo using "${dtapath}\nber_recession_dummies", nogen noreport keep(match) keepusing(rec_dum)
	merge m:1 datemo using "${dtapath}\integrated_volatility_monthly", nogen noreport keep(match) ///
		keepusing(high_ivol_80 high_ivol_90 high_ivol_95)
		//keepusing(high_ivol_80 high_ivol_90 high_ivol_95 high_ivol_qtr_80 high_ivol_qtr_90 high_ivol_qtr_95)
		
	// add on economic policy uncertainty indicator
	merge m:1 datemo using "${dtapath}\epu_hist_index_monthly", nogen keep(master match) ///
		keepusing( ///
			high_epu_hist_full_80 high_epu_hist_full_90 high_epu_hist_full_95 ///
			high_epu_hist_from1972_80 high_epu_hist_from1972_90 high_epu_hist_from1972_95 ///
		)
	
	
	// compute excess returns
	merge m:1 datemo using "${dtapath}\famafrench_monthly_factors", nogen keepusing(rf) keep(master match)
	foreach rettype in "ew" "vw" "un_ew" "un_vw" {
		gen ex_ret_`rettype' = port_ret_`rettype' - rf/100
	}
	
	// compute market cap shares
	//gen lag_mkt_cap_for_sum = lag_mkt_cap if inlist(port,1,2,3,4,5)
	gen lag_mkt_cap_for_sum = lag_mkt_cap // only individual industry ports in this data so no if condition needed
	bysort datemo: egen sum_lag_mkt_cap = sum(lag_mkt_cap_for_sum)
	gen share_lag_mkt_cap = lag_mkt_cap / sum_lag_mkt_cap
	drop lag_mkt_cap_for_sum sum_lag_mkt_cap
	
	// create time series
	sort port_ind datemo	
	egen port_ind_num = group(port_ind)
	// if 2-digit SIC or similar where can be converted to number, use that for port_ind_num
	destring port_ind, gen(try_destring) force
	replace port_ind_num = try_destring if ~missing(try_destring)		
	drop try_destring
	tsset port_ind_num datemo	
	
	// save final data
	save "${dtapath}\time_series_by_port_`myindvar'", replace				
	
}

	// view outcome for ff49
	use "${dtapath}\time_series_by_port_ff49_rnd", clear
	
	
	
/********************************************************************/
// prepare ivol, epu, and orthogonalized (i.e., z series) to use 
// as RHS in portfolio- and firm-level tests
		
	// market portfolio from our BCLR sample to use
	// when comparing residuals in a below setp
	use datemo lpermno rnd_to_assets lag_mkt_cap ret using "${dtapath}\crsp_merged_with_monthly_compustat", clear
	keep if ~missing(rnd_to_assets)
	// prepare for collapsing
	bysort datemo: egen lag_mkt_cap_sum = sum(lag_mkt_cap)
	gen contrib_wgt = (lag_mkt_cap/lag_mkt_cap_sum)
	gen contrib_ret = contrib_wgt * ret	
	sort lpermno datemo // for visual checking			
	// collapse by portfolios
	collapse (count) num_firms=ret (mean) ret_ew=ret ///
		(sum) check_wgt=contrib_wgt ret_vw=contrib_ret lag_mkt_cap ///
		, by(datemo) 
	gen mkt_blcr = 100*ret_vw
	save "${dtapath}\temp_market_our_sample", replace	
	
	
	// create monthly version of news vix (nvix) measure
	use "${dtapath}\nvix_by_date", replace		
	// already in percent units
	gen datemo = mofd(date)
	format datemo %tm	
	collapse (mean) nvix, by(datemo)
	save "${dtapath}\temp_nvix_monthly", replace	
	
	
	// monthly data for ivol and epu
	
		// merge together data
		use datemo ivol using "${dtapath}\integrated_volatility_monthly", clear
		merge 1:1 datemo using "${dtapath}\pd_ratio_monthly", nogen
		merge 1:1 datemo using "${dtapath}\epu_hist_index_monthly", nogen keepusing(epu_hist_index)
		merge 1:1 datemo using "${dtapath}\temp_nvix_monthly", nogen 
		rename epu_hist_index epu
		//keep if datemo>=ym(1971,12) & datemo<=ym(2013,12) // leave extra month at beginning for L1
		keep if datemo>=ym(1971,12) & datemo<=ym(2016,12) // leave extra month at beginning for L1
		tsset datemo	
		
		// ivol residuals
		
			// ivol ar(1) regression
			reg ivol L1.ivol, robust			
			// compute Durbin-watson and add to regression results
				dwstat
				estat durbina, force
				dwstat
				gen tempval = `r(dw)'			
				tostring tempval, replace force format(%5.3f)
				local mydwstat = tempval[1]
				disp `mydwstat'
				estadd local mydwstat `mydwstat'
				drop tempval
			predict evol_ar1, resid
			// compute JB test and add to regression results
				sktest evol_ar1
				summ evol_ar1, detail
				gen tempval = (`r(N)'/6)*(`r(skewness)'^2 + 1/4*(`r(kurtosis)'-3)^2)
				tostring tempval, replace force format(%5.3f)
				local myjbstat = tempval[1]
				disp `myjbstat'
				//estadd local myjbstat `myjbstat'
				drop tempval			
			estimates store reg_ivol_AR1 // for summary table later
			
				// check with two lags
				corrgram ivol
				reg ivol L1.ivol L2.ivol, robust
				// compute Durbin-watson and add to regression results
					dwstat
					estat durbina, force
					dwstat
					gen tempval = `r(dw)'			
					tostring tempval, replace force format(%5.3f)
					local mydwstat = tempval[1]
					disp `mydwstat'
					estadd local mydwstat `mydwstat'
					drop tempval								
				estimates store reg_ivol_AR2 // for summary table later				
				predict evol_ar2, resid
				
				// check with two lags
				reg ivol L1.ivol L2.ivol L3.ivol, robust
				dwstat		
				estat durbina, force				
				

			// choose which pd ratio to use
			gen pd = pd_ratio_end // uses price at end of period so contemporaneous like ivol
			//gen pd = ln(pd_ratio_end) // try log values instead
			
			// regress pd ratio on ivol
			reg pd ivol, robust
			predict epd_ivol, resid
			
			// pd ar(1) regression
			reg epd_ivol L1.epd_ivol, robust
			// compute Durbin-watson and add to regression results
				dwstat
				gen tempval = `r(dw)'			
				tostring tempval, replace force format(%5.3f)
				local mydwstat = tempval[1]
				disp `mydwstat'
				estadd local mydwstat `mydwstat'
				drop tempval		
			estimates store reg_epd_ivol_AR1 // for summary table later
			predict resid_epd_ar1_vol_noevol, resid				
			// compute JB test and add to regression results
				sktest resid_epd_ar1_vol_noevol
				summ resid_epd_ar1_vol_noevol, detail
				gen tempval = (`r(N)'/6)*(`r(skewness)'^2 + 1/4*(`r(kurtosis)'-3)^2)
				tostring tempval, replace force format(%5.3f)
				local myjbstat = tempval[1]
				disp `myjbstat'
				//estadd local myjbstat `myjbstat'
				drop tempval					
			// regress this residual on evol_ar1 to get orthogonal shock
			reg epd_ivol L1.epd_ivol evol_ar1, robust		
			predict resid_epd_ar1_vol, resid
		
				// check with two lags
				corrgram epd_ivol
				reg epd_ivol L1.epd_ivol L2.epd_ivol, robust	
				// compute Durbin-watson and add to regression results
					dwstat
					estat durbina, force
					dwstat
					gen tempval = `r(dw)'			
					tostring tempval, replace force format(%5.3f)
					local mydwstat = tempval[1]
					disp `mydwstat'
					estadd local mydwstat `mydwstat'
					drop tempval				
				estimates store reg_epd_ivol_AR2 // for summary table later							

			// output AR(1) regression results table

				esttab reg_ivol_AR1 reg_ivol_AR2 reg_epd_ivol_AR1 reg_epd_ivol_AR2 ///
				///esttab reg_ivol_AR1 reg_ivol_AR2 reg_epd_ivol_AR1 ///
				using "Empirical_Analysis/tables/table_reg_AR1_ivol_epd_ivol.tex" ///
				, cells(b(star  fmt(3)) t(par  fmt(2))) ///
				stat(r2 mydwstat N, fmt(%9.3f %9.3f %9.0g) labels("\$R^{2}$" "Durbin-Watson" "N")) ///
				style(tex) starlevels(* 0.10  ** 0.05 *** 0.01)  ///
				///mtitles("(1)" "(2)" "(3)" "(4)"  "(5)"  "(6)" "(7)"  "(8)"  "(9)"  "(10)" "(11)"  "(12)"  "(13)"  "(14)") ///
				mtitles("iVol" "iVol" "z" "z" ) ///
				///mtitles("iVol" "z" ) ///
				nonumbers collabels(none) ///
				coeflabels( ///
					///retention_fiverr_v5 "Alt. Token Retention" ///					
					L.ivol "Lag iVol" /// 
					L.epd_ivol "Lag z" ///
					L2.ivol "Lag 2 iVol" /// 
					L2.epd_ivol "Lag 2 z" ///					
					_cons "Constant" ///
				) order( ///
					L.ivol ///						
					L2.ivol ///	
					L.epd_ivol ///
					L2.epd_ivol ///					
					_cons) ///
				/// drop( ) 
				replace 		
		
		
		// repeat for epu instead of ivol

			// ivol ar(1) regression
			reg epu L1.epu, robust
			predict eepu_ar1, resid
			
			// regress pd ratio on ivol
			reg pd epu, robust
			predict epd_epu, resid
			
			// pd ar(1) regression
			//reg epd_epu L1.epd_epu, robust
			//predict resid_epd_ar1_epu, resid		
			// regress this residual on evol_ar1 to get orthogonal shock
			reg epd_epu L1.epd_epu eepu_ar1, robust		
			predict resid_epd_ar1_epu, resid
			
			
		// repeat for nvix instead of ivol

			// ivol ar(1) regression
			reg nvix L1.nvix, robust
			predict envix_ar1, resid
			
			// regress pd ratio on ivol
			reg pd nvix, robust
			predict epd_nvix, resid
			
			// pd ar(1) regression
			//reg epd_nvix L1.epd_nvix, robust
			//predict resid_epd_ar1_nvix, resid		
			// regress this residual on evol_ar1 to get orthogonal shock
			reg epd_nvix L1.epd_nvix envix_ar1, robust		
			predict resid_epd_ar1_nvix, resid			
	
		
		// compare residuals to market return as a comparison
		if 1==0 {
			merge 1:1 datemo using "${dtapath}\famafrench_monthly_factors", nogen keep(master match) keepusing(rm_minus_rf rf)
			corr resid rm_minus_rf
			reg rm_minus_rf resid, robust
			merge 1:1 datemo using "${dtapath}\temp_market_our_sample", nogen keep(master match) keepusing(mkt_blcr)
			gen mkt_bclr_minus_rf = mkt_blcr - rf
			reg mkt_bclr_minus_rf resid, robust		
			corr rm_minus_rf mkt_bclr_minus_rf
		}
		
		gen lag1_ivol = L1.ivol // useful for some regressions
		save "${dtapath}\resid_series_for_panel_regs_monthly", replace	
	
			// check volatility of monthly evol
			use "${dtapath}\resid_series_for_panel_regs_monthly", clear
			//keep if datemo>=ym(1972,1) & datemo<=ym(2013,12)
			keep if datemo>=ym(1972,1) & datemo<=ym(2016,12)
			collapse (sd) evol_ar1 (count) count_evol=evol_ar1	


	// create annual version of EPU index
	use datemo epu_hist_index using "${dtapath}\epu_hist_index_monthly", clear
	gen year = year(dofm(datemo))
	collapse (mean) epu=epu_hist_index, by(year)
	save "${dtapath}\temp_epu_annual", replace	

	
	// create annual version of our PU measure
	use "${dtapath}\data_inv_reg_qtr_1961_2016", clear
	replace expvol = 100*expvol // make percent to match other vol measures
	collapse (mean) expvol, by(year)
	save "${dtapath}\temp_expvol_annual", replace	
	
	
	// create annual version of nvix measure
	use "${dtapath}\nvix_by_date", replace		
	// already in percent units
	gen year = year(date)
	collapse (mean) nvix, by(year)
	save "${dtapath}\temp_nvix_annual", replace		
	
	
	// repeat for annual ivol and pd data
	
		// merge together data		
		use "${dtapath}\pd_ratio_monthly", clear		
		keep if month(dofm(datemo))==12 // annual value is at end of december
		gen year = year(dofm(datemo))
		gen pd = pd_ratio_end // uses price at end of period so contemporaneous like ivol
		//gen pd = ln(pd_ratio_end) // try log values instead
		keep year pd		
		merge 1:1 year using "${dtapath}\integrated_volatility_annual", nogen keepusing(ivol)
		merge 1:1 year using "${dtapath}\temp_epu_annual", nogen 		
		merge 1:1 year using "${dtapath}\temp_expvol_annual", nogen
		merge 1:1 year using "${dtapath}\temp_nvix_annual", nogen		
		//keep if year>=1972 & year<=2013 // leave extra year at beginning for L1
		//keep if year>=1971 & year<=2013 // leave extra year at beginning for L1
		keep if year>=1971 & year<=2016 // leave extra year at beginning for L1
		tsset year
		
		// ivol ar(1) regression
		reg ivol L1.ivol, robust
		predict evol_ar1, resid

		// regress pd ratio on ivol
		reg pd ivol, robust
		predict epd_ivol, resid	
		
			//tsline pd
			//tsline ivol
			//tsline epd_ivol

		// epd ar(1) regression 
		//reg epd_ivol L1.epd_ivol, robust		
		//predict resid_epd_ar1_vol, resid		
		
		// epd ar(1) regression controlling for evol_ar1
		reg epd_ivol L1.epd_ivol evol_ar1, robust		
		predict resid_epd_ar1_vol, resid		
		
		// repeat for epu

			// ivol ar(1) regression
			reg epu L1.epu, robust
			predict eepu_ar1, resid
			
			// regress pd ratio on ivol
			reg pd epu, robust
			predict epd_epu, resid	

			// epd ar(1) regression
			//reg epd_epu L1.epd_epu, robust		
			//predict resid_epd_ar1_epu, resid
			
			// epd ar(1) regression controlling for evol_ar1
			reg epd_epu L1.epd_epu eepu_ar1, robust		
			predict resid_epd_ar1_epu, resid
			
		// repeat for expvol

			// ivol ar(1) regression
			reg expvol L1.expvol, robust
			predict eexpvol_ar1, resid
			
			// regress pd ratio on ivol
			reg pd expvol, robust
			predict epd_expvol, resid	

			// epd ar(1) regression
			//reg epd_expvol L1.epd_expvol, robust		
			//predict resid_epd_ar1_expvol, resid
			
			// epd ar(1) regression controlling for evol_ar1
			reg epd_expvol L1.epd_expvol eexpvol_ar1, robust		
			predict resid_epd_ar1_expvol, resid			
			
		// repeat for nvix

			// ivol ar(1) regression
			reg nvix L1.nvix, robust
			predict envix_ar1, resid
			
			// regress pd ratio on ivol
			reg pd nvix, robust
			predict epd_nvix, resid	

			// epd ar(1) regression
			//reg epd_nvix L1.epd_nvix, robust		
			//predict resid_epd_ar1_nvix, resid
			
			// epd ar(1) regression controlling for evol_ar1
			reg epd_nvix L1.epd_nvix envix_ar1, robust		
			predict resid_epd_ar1_nvix, resid					
			
		save "${dtapath}\resid_series_for_panel_regs_annual", replace	
	
			// check volatility of annual ivol
			use "${dtapath}\resid_series_for_panel_regs_annual", clear
			//keep if year>=1972 & year<=2013
			keep if year>=1972 & year<=2016
			collapse (mean) ivol_avg=ivol (sd) ivol_sd=ivol (count) count_ivol=ivol
	
	
	
/*********************************************************************************************/			
// simple summary table in spirit of Max's JFE paper with Steve, Thien, and Lukas

	// compute returns including for the HML portfolio
		
		// high 
		use "${dtapath}\time_series_by_port", clear		
		keep if port==5
		keep datemo port num_firms ///
			ex_ret_ew ex_ret_un_ew port_ret_ew port_ret_un_ew ///
			share_lag_mkt_cap rnd_to_assets_F0 sales_to_assets ///
			quasimkt_lvg book_leverage_raw book_leverage_trunc book_leverage_maxjfe 
			//ex_ret_vw ex_ret_un_vw port_ret_vw port_ret_un_vw 
		save "${dtapath}\temp_high", replace				

		// low
		use "${dtapath}\time_series_by_port", clear
		keep if port==1
		keep datemo port num_firms ///
			ex_ret_ew ex_ret_un_ew port_ret_ew port_ret_un_ew ///
			share_lag_mkt_cap rnd_to_assets_F0 sales_to_assets ///
			quasimkt_lvg book_leverage_raw book_leverage_trunc book_leverage_maxjfe 
			//ex_ret_vw ex_ret_un_vw port_ret_vw port_ret_un_vw 
		save "${dtapath}\temp_low", replace						

		// high minus low returns
		use "${dtapath}\temp_high", clear
		foreach myvar in "ex_ret_ew" "ex_ret_un_ew" "port_ret_ew" "port_ret_un_ew"   ///
			/// "ex_ret_vw" "ex_ret_un_vw" "port_ret_vw" "port_ret_un_vw"  ///
		{
			rename `myvar' `myvar'_5
		}
		drop port
		merge 1:1 datemo using "${dtapath}\temp_low", nogen
		drop port
		foreach myvar in "ex_ret_ew" "ex_ret_un_ew" "port_ret_ew" "port_ret_un_ew"   ///
			/// "ex_ret_vw" "ex_ret_un_vw" "port_ret_vw" "port_ret_un_vw"  ///
		{
			rename `myvar' `myvar'_1
			gen `myvar' = `myvar'_5 - `myvar'_1
		}		
		gen port = 51
		keep datemo port ex_ret_ew ex_ret_un_ew port_ret_ew port_ret_un_ew  // port_ret_vw port_ret_un_vw  ex_ret_vw ex_ret_un_vw 
		save "${dtapath}\temp_hml", replace	
		
		
		// combine into a single dataset
		use "${dtapath}\temp_high", clear
		append using "${dtapath}\temp_low"
		append using "${dtapath}\temp_hml"
		tsset port datemo
		save "${dtapath}\temp_data_for_port_summary", replace
				
		// collapse into summary table
		use "${dtapath}\temp_data_for_port_summary", clear
		gen retvar = port_ret_ew
		//if 1==0 {
			//keep if datemo>=ym(1975, 1)	
		//}		
		gen num_firms_post1975 = num_firms if datemo>=ym(1975,1)
		collapse ///
			(count) num_months=retvar ///
			(mean) num_firms num_firms_post1975 retvar ///
				share_lag_mkt_cap rnd_to_assets_F0 sales_to_assets ///
				quasimkt_lvg book_leverage_raw book_leverage_trunc book_leverage_maxjfe ///				
			(sd) retvar_sd=retvar ///
			, by(port)
		
		// save out data table
		export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("out_port_summ_stats") sheetreplace
			

			

/*********************************************************************************************/			
// excess returns regressions in  in R&D-sorted Portfolios

	// compute returns including for the HML portfolio
		
		// high 
		use "${dtapath}\time_series_by_port", clear
		keep if port==5
		keep datemo port ex_ret_ew ex_ret_vw ex_ret_un_ew ex_ret_un_vw port_ret_ew port_ret_vw port_ret_un_ew port_ret_un_vw 
		save "${dtapath}\temp_high", replace				

		// low
		use "${dtapath}\time_series_by_port", clear
		keep if port==1
		keep datemo port ex_ret_ew ex_ret_vw ex_ret_un_ew ex_ret_un_vw port_ret_ew port_ret_vw port_ret_un_ew port_ret_un_vw 
		save "${dtapath}\temp_low", replace						

		// high minus low
		use "${dtapath}\temp_high", clear
		foreach myvar in "ex_ret_ew" "ex_ret_vw" "ex_ret_un_ew" "ex_ret_un_vw" ///
			"port_ret_ew" "port_ret_vw" "port_ret_un_ew" "port_ret_un_vw"  ///
		{
			rename `myvar' `myvar'_5
		}
		drop port
		merge 1:1 datemo using "${dtapath}\temp_low", nogen
		drop port
		foreach myvar in "ex_ret_ew" "ex_ret_vw" "ex_ret_un_ew" "ex_ret_un_vw" ///
			"port_ret_ew" "port_ret_vw" "port_ret_un_ew" "port_ret_un_vw"  ///
		{
			rename `myvar' `myvar'_1
			gen `myvar' = `myvar'_5 - `myvar'_1
		}		
		gen port = 51
		keep datemo port ex_ret_ew ex_ret_vw ex_ret_un_ew ex_ret_un_vw port_ret_ew port_ret_vw port_ret_un_ew port_ret_un_vw  
		save "${dtapath}\temp_hml", replace						
		
		
			// check HML return on its own
			use  "${dtapath}\temp_hml", clear
			reg port_ret_ew			
			reg port_ret_ew, robust
			matrix b = e(b)
			matrix V = e(V)
			disp 12*100*b[1,1]
			disp sqrt(V[1,1])
			disp 100*sqrt(12*V[1,1])
			gen tempret = 100*12*port_ret_ew
			reg tempret, robust			
			
		
		// combine into a single dataset
		use "${dtapath}\temp_high", clear
		append using "${dtapath}\temp_low"
		append using "${dtapath}\temp_hml"
		tsset port datemo
		save "${dtapath}\temp_data_for_port_summary", replace
		
		
	// compute the figures for the table to be used in the paper
	foreach startyr in 1972 1975 {
	
		use "${dtapath}\temp_data_for_port_summary", clear

		// merge on and create RHS vars
		merge m:1 datemo using "${dtapath}\resid_series_for_panel_regs_monthly", nogen keep(master match)
		gen vol_news = evol_ar1
		//gen vol_news = evol_ar2 // try residual based on AR(2) instead of ivol
		gen lr_news = resid_epd_ar1_vol
		tsset port datemo			
	
		// columns for table
		gen rowlabel = ""
		foreach myport in 5 1 51 {			
			gen col_`myport'_val = .
			gen col_`myport'_se  = .
			//gen col_`myport'_t   = .
		}
		order rowlabel col_*
		
		// create values for each row of table
		foreach row in 1 {
		
			//local startyr = 1972 // can also try 1975
		
			// levered returns avgs
			replace rowlabel = "lev_ret_avg" if _n==`row'
			//gen lev_ret = 12*100*port_ret_ew // annualize
			gen lev_ret = 12*100*ex_ret_ew // annualize
			foreach myport in 5 1 51 {			
				reg lev_ret if datemo>=ym(`startyr',1) & port==`myport', cons robust	
				matrix b = e(b)
				matrix V = e(V)
				replace col_`myport'_val = b[1,1] if _n==`row'
				replace col_`myport'_se = sqrt(V[1,1]) if _n==`row'
				//replace col_`myport'_t   = b[1,1]/sqrt(V[1,1]) if _n==`row'								
			}
		    local row = `row'+1
			
			
			// un-levered returns avgs
			replace rowlabel = "unlev_ret_avg" if _n==`row'
			//gen unlev_ret = 12*100*port_ret_un_ew // annualize
			gen unlev_ret = 12*100*ex_ret_un_ew // annualize
			foreach myport in 5 1 51 {			
				reg unlev_ret if datemo>=ym(`startyr',1) & port==`myport', cons robust	
				matrix b = e(b)
				matrix V = e(V)
				replace col_`myport'_val = b[1,1] if _n==`row'
				replace col_`myport'_se = sqrt(V[1,1]) if _n==`row'
			}
		    local row = `row'+1			
			
			
			// coefficients for reg of unlev_ret on evol and ez			
			foreach myport in 5 1 51 {			
				preserve
					keep if port==`myport'
					tsset datemo
					ivreg2 unlev_ret vol_news lr_news if datemo>=ym(`startyr',1) & port==`myport', robust bw(auto) // optimal lag selection				
					//disp e(r2)
					//reg unlev_ret vol_news lr_news
					//disp e(r2) 
					// note: I confirm r2 from reg same as from ivreg2
				restore	
				matrix b = e(b)
				matrix V = e(V)	
				
				replace rowlabel = "beta_z" if _n==`row'+0
				replace col_`myport'_val = b[1,2] if _n==`row'+0
				replace col_`myport'_se  = sqrt(V[2,2]) if _n==`row'+0

				replace rowlabel = "beta_vol" if _n==`row'+1
				replace col_`myport'_val = b[1,1] if _n==`row'+1
				replace col_`myport'_se  = sqrt(V[1,1]) if _n==`row'+1
								
				replace rowlabel = "r2" if _n==`row'+2
				replace col_`myport'_val = e(r2) if _n==`row'+2
				
			}
		    local row = `row'+1					
		
		}
				
		// save out data table
		keep rowlabel col_*
		keep if ~missing(rowlabel)
		set excelxlsxlargefile on
		export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("raw_ret_by_port_summ_`startyr'") sheetreplace
		
	} // mystartyr
	
	
	// export HML returns for use in quarterly data VAR
	
		use "${dtapath}\temp_data_for_port_summary", clear

		// merge on and create RHS vars
		merge m:1 datemo using "${dtapath}\resid_series_for_panel_regs_monthly", nogen keep(master match)
		gen vol_news = evol_ar1
		//gen vol_news = evol_ar2 // try residual based on AR(2) instead of ivol
		gen lr_news = resid_epd_ar1_vol
		tsset port datemo			
		
		// keep for time period of VAR
		keep if datemo>=ym(1972,1) & datemo<=ym(2016,12)
		
		// compute annualized HML ret
		gen lev_ret = 12*100*ex_ret_ew 
		gen unlev_ret = 12*100*ex_ret_un_ew 
		gen ln_ex_ret_ew    = ln(1+ex_ret_ew)
		gen ln_ex_ret_un_ew = ln(1+ex_ret_un_ew)
		//br ex_ret_un_ew ln_ex_ret_un_ew
	
		// reshape wide
		keep port datemo vol_news lr_news unlev_ret lev_ret ln_ex_ret_ew ln_ex_ret_un_ew
		reshape wide unlev_ret lev_ret ln_ex_ret_ew ln_ex_ret_un_ew, i(datemo vol_news lr_news) j(port)
		tsset datemo
		
		// double check regression results
		ivreg2 unlev_ret5  vol_news lr_news, robust bw(auto) // optimal lag selection				
		ivreg2 unlev_ret1  vol_news lr_news, robust bw(auto) // optimal lag selection				
		ivreg2 unlev_ret51 vol_news lr_news, robust bw(auto) // optimal lag selection			
		
		// aggregate to quarterly returns
		gen dateqtr = yq(year(dofm(datemo)),quarter(dofm(datemo)))
		format dateqtr %tq
		collapse (sum) ln_ex_ret_ew* ln_ex_ret_un_ew* (mean) vol_news lr_news, by(dateqtr)
		
		// compute quarterly HML, keep  in fraction
		foreach myport in 5 1 51 {	
			gen lev_ret`myport' = exp(ln_ex_ret_ew`myport')-1
			gen unlev_ret`myport' = exp(ln_ex_ret_un_ew`myport')-1
		}

		// make sure time series averages look right (should be same as monthly time series avgs)
		summ lev_ret* unlev_ret*
		
		/*separate dateqtr to year and qtr vars*/
		gen year = year(dofq(dateqtr))
		gen month = month(dofq(dateqtr))
		gen qtr  = 1
		replace qtr = 2 if month== 4
		replace qtr = 3 if month== 7
		replace qtr = 4 if month==10
		drop dateqtr month
		order year qtr		
		
		// save out for VAR 
		keep year qtr lev_ret* unlev_ret*
		save "${dtapath}\hml_retuns_qtr_1972_2016", replace
		keep if year<=2016 // don't want data past 2016 even in full series figures
		outsheet using "Empirical_Analysis\data_for_VAR\hml_retuns_qtr_1972_2016.csv", replace comma
	
	
	
	// re-run table 1 output but using news vix
	foreach startyr in 1972 {
	
		use "${dtapath}\temp_data_for_port_summary", clear

		// merge on and create RHS vars
		merge m:1 datemo using "${dtapath}\resid_series_for_panel_regs_monthly", nogen keep(master match)
		gen vol_news = envix_ar1
		//gen vol_news = envix_ar2 // try residual based on AR(2) 
		gen lr_news = resid_epd_ar1_nvix
		tsset port datemo			
	
		// columns for table
		gen rowlabel = ""
		foreach myport in 5 1 51 {			
			gen col_`myport'_val = .
			gen col_`myport'_se  = .
			//gen col_`myport'_t   = .
		}
		order rowlabel col_*
		
		// create values for each row of table
		foreach row in 1 {
		
			//local startyr = 1972 // can also try 1975
		
			// levered returns avgs
			replace rowlabel = "lev_ret_avg" if _n==`row'
			//gen lev_ret = 12*100*port_ret_ew // annualize
			gen lev_ret = 12*100*ex_ret_ew // annualize
			foreach myport in 5 1 51 {			
				reg lev_ret if datemo>=ym(`startyr',1) & port==`myport', cons robust	
				matrix b = e(b)
				matrix V = e(V)
				replace col_`myport'_val = b[1,1] if _n==`row'
				replace col_`myport'_se = sqrt(V[1,1]) if _n==`row'
				//replace col_`myport'_t   = b[1,1]/sqrt(V[1,1]) if _n==`row'								
			}
		    local row = `row'+1
			
			
			// un-levered returns avgs
			replace rowlabel = "unlev_ret_avg" if _n==`row'
			//gen unlev_ret = 12*100*port_ret_un_ew // annualize
			gen unlev_ret = 12*100*ex_ret_un_ew // annualize
			foreach myport in 5 1 51 {			
				reg unlev_ret if datemo>=ym(`startyr',1) & port==`myport', cons robust	
				matrix b = e(b)
				matrix V = e(V)
				replace col_`myport'_val = b[1,1] if _n==`row'
				replace col_`myport'_se = sqrt(V[1,1]) if _n==`row'
			}
		    local row = `row'+1			
			
			
			// coefficients for reg of unlev_ret on evol and ez			
			foreach myport in 5 1 51 {			
				preserve
					keep if port==`myport'
					tsset datemo
					ivreg2 unlev_ret vol_news lr_news if datemo>=ym(`startyr',1) & port==`myport', robust bw(auto) // optimal lag selection				
					//disp e(r2)
					//reg unlev_ret vol_news lr_news
					//disp e(r2) 
					// note: I confirm r2 from reg same as from ivreg2
				restore	
				matrix b = e(b)
				matrix V = e(V)	
				
				replace rowlabel = "beta_z" if _n==`row'+0
				replace col_`myport'_val = b[1,2] if _n==`row'+0
				replace col_`myport'_se  = sqrt(V[2,2]) if _n==`row'+0

				replace rowlabel = "beta_vol" if _n==`row'+1
				replace col_`myport'_val = b[1,1] if _n==`row'+1
				replace col_`myport'_se  = sqrt(V[1,1]) if _n==`row'+1
								
				replace rowlabel = "r2" if _n==`row'+2
				replace col_`myport'_val = e(r2) if _n==`row'+2
				
			}
		    local row = `row'+1					
		
		}
				
		// save out data table
		keep rowlabel col_*
		keep if ~missing(rowlabel)
		set excelxlsxlargefile on
		export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("raw_ret_by_port_summ_nvix") sheetreplace
			//firstrow(var) sheet("raw_ret_by_port_summ_nvix`startyr'") sheetreplace
		
	} // mystartyr	
	
	
	
	
/*********************************************************************************************/			
// run full set of potential regressions that we considered to use for return
// regressions that we include in the returns by portfolio summary table

	
	// simple return regressions to get averages with SEs and t-stats
	use "${dtapath}\temp_data_for_port_summary", clear

		// variables to create
		
			// categorize the row
			gen startyr = .
			gen retvar = ""
		
			// average return regressions
			gen avg_5 = .
			gen t_avg_5 = .
			gen avg_1 = .
			gen t_avg_1 = .
			gen avg_51 = .
			gen t_avg_51 = .
		
			// example
			reg ex_ret_ew if datemo>=ym(1972,1) & port==5, cons		
			reg ex_ret_ew if datemo>=ym(1972,1) & port==5, cons	robust // robust doesnt matter with only constant
		
		// run reg by portfolio for all combinations of retvar and sample
		local row = 1				
		foreach startyr in 1972 1975 {					
		  foreach retvar in "ex_ret_ew" "ex_ret_vw" "ex_ret_un_ew" "ex_ret_un_vw" ///
			"port_ret_ew" "port_ret_vw" ///
		  {
		    replace startyr = `startyr' if _n==`row'				
			replace retvar = "`retvar'" if _n==`row'				
			foreach myport in 5 1 51 {			
				reg `retvar' if datemo>=ym(`startyr',1) & port==`myport', cons robust	
				matrix b = e(b)
				matrix V = e(V)
				//replace avg_`myport' = 12*100*b[1,1] if _n==`row'
				replace avg_`myport' = 100*((1+b[1,1])^12-1) if _n==`row'
				replace t_avg_`myport' = b[1,1]/sqrt(V[1,1]) if _n==`row'				
			}
		    local row = `row'+1
		  }		
		}
		
		
	// return regressions on news to ivol and news to z (orthog portion of pd ratio to ivol)
	use "${dtapath}\temp_data_for_port_summary", clear
	
		// merge on and create RHS vars
		merge m:1 datemo using "${dtapath}\resid_series_for_panel_regs_monthly", nogen keep(master match)
		gen vol_news = evol_ar1
		gen interact = lag1_ivol*vol_news // note that ivol lagged in levels
		gen lr_news = resid_epd_ar1_vol
		//gen lr_news = resid_epd_ar1_vol_noevol // alternative way to compute news to z without evol_ar1 on RHS
		tsset port datemo		
		//br port datemo ivol lag1_ivol evol_ar1 vol_news interact lr_news
	
		// variables to create
		
			// categorize the row
			gen startyr = .
			gen retvar = ""
		
			// average return regressions
			foreach myport in 5 1 51 {
				gen beta0_`myport' = .
				gen t_beta0_`myport' = .
				gen beta1_`myport' = .
				gen t_beta1_`myport' = .
				gen gam_`myport' = .
				gen t_gam_`myport' = .				
				gen cons_`myport' = .
				gen t_cons_`myport' = .					
			}

			// example
			//reg ex_ret_ew vol_news interact lr_news if datemo>=ym(1972,1) & port==5, cons
			preserve
				keep if port==5
				tsset datemo
				ivreg2 ex_ret_ew vol_news interact lr_news if datemo>=ym(1972,1), robust bw(auto) // optimal lag selection				
			restore

		
		// run reg by portfolio for all combinations of retvar and sample
		local row = 1				
		foreach startyr in 1972 1975 {					
		  foreach retvar in "ex_ret_ew" "ex_ret_vw" "ex_ret_un_ew" "ex_ret_un_vw" ///
			"port_ret_ew" "port_ret_vw" ///
		  {
		    replace startyr = `startyr' if _n==`row'				
			replace retvar = "`retvar'" if _n==`row'				
			foreach myport in 5 1 51 {			
				//reg `retvar' vol_news interact lr_news if datemo>=ym(`startyr',1) & port==`myport', cons
				preserve
					keep if port==`myport'
					tsset datemo
					gen lhsvar = `retvar'*100 // put in percentage points
					ivreg2 lhsvar vol_news interact lr_news if datemo>=ym(`startyr',1) & port==`myport', robust bw(auto) // optimal lag selection				
				restore				
				matrix b = e(b)
				matrix V = e(V)
				replace beta0_`myport' = b[1,1] if _n==`row'
				replace t_beta0_`myport' = b[1,1]/sqrt(V[1,1]) if _n==`row'				
				replace beta1_`myport' = b[1,2] if _n==`row'
				replace t_beta1_`myport' = b[1,2]/sqrt(V[2,2]) if _n==`row'								
				replace gam_`myport' = b[1,3] if _n==`row'
				replace t_gam_`myport' = b[1,3]/sqrt(V[3,3]) if _n==`row'												
				replace cons_`myport' = b[1,4] if _n==`row'
				replace t_cons_`myport' = b[1,4]/sqrt(V[4,4]) if _n==`row'																
			}
		    local row = `row'+1
		  }		
		}		
		

		
		
	// return regressions on just news to ivol and news to z (orthog portion of pd ratio to ivol)
	// without an interaction term
	use "${dtapath}\temp_data_for_port_summary", clear
	
		// merge on and create RHS vars
		merge m:1 datemo using "${dtapath}\resid_series_for_panel_regs_monthly", nogen keep(master match)
		gen vol_news = evol_ar1
		gen lr_news = resid_epd_ar1_vol
		//gen lr_news = resid_epd_ar1_vol_noevol // alternative way to compute news to z without evol_ar1 on RHS
		tsset port datemo		
	
		// variables to create
		
			// categorize the row
			gen startyr = .
			gen retvar = ""
		
			// average return regressions
			foreach myport in 5 1 51 {
				gen beta0_`myport' = .
				gen t_beta0_`myport' = .
				gen gam_`myport' = .
				gen t_gam_`myport' = .				
				gen cons_`myport' = .
				gen t_cons_`myport' = .					
			}

			// example
			//reg ex_ret_ew vol_news interact lr_news if datemo>=ym(1972,1) & port==5, cons
			preserve
				keep if port==51
				tsset datemo
				ivreg2 ex_ret_ew vol_news lr_news if datemo>=ym(1972,1), robust bw(auto) // optimal lag selection				
				ivreg2 ex_ret_un_ew vol_news lr_news if datemo>=ym(1972,1), robust bw(auto) // optimal lag selection				
				reg ex_ret_un_ew vol_news lr_news if datemo>=ym(1972,1), robust 
			restore

		
		// run reg by portfolio for all combinations of retvar and sample
		local row = 1				
		foreach startyr in 1972 1975 {					
		  foreach retvar in "ex_ret_ew" "ex_ret_vw" "ex_ret_un_ew" "ex_ret_un_vw" ///
			"port_ret_ew" "port_ret_vw" ///
		  {
		    replace startyr = `startyr' if _n==`row'				
			replace retvar = "`retvar'" if _n==`row'				
			foreach myport in 5 1 51 {			
				preserve
					keep if port==`myport'
					tsset datemo
					gen lhsvar = `retvar'*100 // put in percentage points
					ivreg2 lhsvar vol_news lr_news if datemo>=ym(`startyr',1) & port==`myport', robust bw(auto) // optimal lag selection				
				restore				
				matrix b = e(b)
				matrix V = e(V)
				replace beta0_`myport' = b[1,1] if _n==`row'
				replace t_beta0_`myport' = b[1,1]/sqrt(V[1,1]) if _n==`row'				
				replace gam_`myport' = b[1,2] if _n==`row'
				replace t_gam_`myport' = b[1,2]/sqrt(V[2,2]) if _n==`row'												
				replace cons_`myport' = b[1,3] if _n==`row'
				replace t_cons_`myport' = b[1,3]/sqrt(V[3,3]) if _n==`row'																
			}
		    local row = `row'+1
		  }		
		}		
		

		
		
/********************************************************************/
// summary stats that we need for interpreting our regression results
// in the text of the draft

// for portfolio-level regression results

	// portfolio-level variables at annaul frequency
	use "${dtapath}\time_series_by_port", clear		
	keep datemo port rnd_to_assets_F0
	keep if ~missing(rnd_to_assets_F0)		
	keep if inlist(port,1,5) // keep only high and low portfoio
	gen year = year(dofm(datemo))
	keep if month(dofm(datemo))==7 // focus on values as of june 30 in a given year
	drop datemo
	keep if year>=1972 & year<=2013 // regressions through 2013 to account for at least 3-year forward loooking growth rate
	rename rnd_to_assets_F0 rnd_to_assets // to avoid confusion with reshaped var name
	reshape wide rnd_to_assets, i(year) j(port)
	
	// merge on ivol
	merge 1:1 year using "${dtapath}\integrated_volatility_annual", nogen keep(match) keepusing(ivol)

	// compute averages and standard deviations
	collapse (mean) rnd_to_assets1_avg=rnd_to_assets1 rnd_to_assets5_avg=rnd_to_assets5 ivol_avg=ivol ///
		(sd) ivol_sd=ivol (count) count_obs=ivol	
		
	save "${dtapath}\temp_summ_stats_port_rnd_intensity_and_ivol", replace		
		
		
		
// for the firm-level regressions

	// run over different requirements on number of observations
	foreach Nobsmin in 21 26 30 34 38 100 {        
  
		use datemo lpermno rnd_to_assets using "${dtapath}\crsp_merged_with_monthly_compustat", clear
		keep if ~missing(rnd_to_assets)
		
		// compute average R&D intensity at the firm level
		// this average can be time varying if we distinguish more
		// than one subperiod
		gen year = year(dofm(datemo))
		local startyr=1972
		gen subperiod = 1  if year>=`startyr' & year<=2013	
		replace subperiod = . if year<`startyr' | year>2013
		// note: keep 2013 as last year because we require at least 3 years ahead of data
			
			// 3-year subperiods
			forvalues j=2/14 { // note that 14 corresponds to last data point in 2013, which works for 3-year fwd growth rates in sample ending 2016
				replace subperiod = `j' if year>=1972+3*(`j'-1) & ~missing(subperiod) // divide in half
			}
			//keep year subperiod
			//duplicates drop		
			//br
					
		sort lpermno subperiod datemo
		by lpermno subperiod: egen avg_rnd_to_assets = mean(rnd_to_assets) if ~missing(subperiod)	

		// keep one obs per year and merge on ivol	
		keep if month(dofm(datemo))==7 // focus on values as of june 30 in a given year
		tsset lpermno year
		
		// keep only sample we care about
		keep if year>=1972 & year<=2013
		// note: keep 2013 as last year because we require at least 3 years ahead of data
		
		// check obs count
		bysort lpermno: egen Nobs = count(rnd_to_assets)
		summ Nobs, detail	
		local Nobs_max = r(max)
		// take into account if less obs available than choice for Nobsmin
		if `Nobsmin' > `Nobs_max' {
			local Nobs_cutoff = `Nobs_max'
		}
		else {
			local Nobs_cutoff = `Nobsmin'	
		}
		//disp `Nobs_cutoff'
		keep if Nobs>=`Nobs_cutoff'
	
		// compute the averages when using averages for different subperiods 
		keep if ~missing(subperiod)
		keep lpermno avg_rnd_to_assets subperiod
		duplicates drop
		bysort subperiod: egen p80_avg_rnd_to_assets = pctile(avg_rnd_to_assets), p(80)
		bysort subperiod: egen p20_avg_rnd_to_assets = pctile(avg_rnd_to_assets), p(20)
		gen avg_rnd_to_assets_top80 = avg_rnd_to_assets if avg_rnd_to_assets>=p80_avg_rnd_to_assets
		gen avg_rnd_to_assets_top20 = avg_rnd_to_assets if avg_rnd_to_assets<=p20_avg_rnd_to_assets
		collapse (mean) avg_rnd_to_assets avg_rnd_to_assets_top20 avg_rnd_to_assets_top80, by(subperiod)
		collapse (mean) ///
			avg_rnd_to_assets_Nobs`Nobsmin'=avg_rnd_to_assets ///
			avg_rnd_to_assets_top20_Nobs`Nobsmin'=avg_rnd_to_assets_top20 ///
			avg_rnd_to_assets_top80_Nobs`Nobsmin'=avg_rnd_to_assets_top80
				
		gen dummy=1 // for merging
		save "${dtapath}\temp_summ_stats_firm_rnd_intensity_Nobs`Nobsmin'", replace		
		
	}	
		
		
// combine together and export		
		
	use "${dtapath}\temp_summ_stats_port_rnd_intensity_and_ivol", clear
	gen dummy=1
	merge 1:1 dummy using "${dtapath}\temp_summ_stats_firm_rnd_intensity_Nobs100", nogen
	merge 1:1 dummy using "${dtapath}\temp_summ_stats_firm_rnd_intensity_Nobs38", nogen
	merge 1:1 dummy using "${dtapath}\temp_summ_stats_firm_rnd_intensity_Nobs34", nogen
	merge 1:1 dummy using "${dtapath}\temp_summ_stats_firm_rnd_intensity_Nobs30", nogen
	merge 1:1 dummy using "${dtapath}\temp_summ_stats_firm_rnd_intensity_Nobs26", nogen
	merge 1:1 dummy using "${dtapath}\temp_summ_stats_firm_rnd_intensity_Nobs21", nogen
	export excel using "${outPath}\tables_for_paper.xlsx", ///
	firstrow(var) sheet("rnd_and_ivol_summ_stats") sheetreplace

	

/********************************************************************/
// portfolio-level regression analysis
// ppp	

//foreach control_credit_cond in 1 0 { // yes==1, otherwise no
foreach control_credit_cond in 1 { // yes==1, otherwise no
 foreach port_cfprof_cont_var in "none" "markup_ebitda_F0" { // "none" means no controls, any other choice is that cash flow control plus average Tobin's Q
 //foreach port_cfprof_cont_var in "markup_ebitda_F0" { // "none" means no controls, any other choice is that cash flow control plus average Tobin's Q
 // choices for potential profitability controls: markup_ebitda_F0, cfprof_ratio 
  foreach interact_credit_cond_rndvar in 0 3 {
   foreach new_export_sheet in 1 { 
    //foreach startyr in 1972 1975 1982 { //    
    foreach startyr in 1972 { //    
     foreach vol_var in "ivol" "epu" "expvol" "nvix" { // "ivol" "epu" run for both 
	 //foreach vol_var in "ivol" "epu" { // try it out
	 //foreach vol_var in "nvix" { // try it out
  
     disp "Running vol_var `vol_var',  ..."
	
//local new_export_sheet = 1
//local vol_var = "ivol"

	// set bw_val to desired number of hag lags plus 1 (i.e, 1 lag = bw(2))
	//local mybwval = 5 // standard before feb 2020
	local mybwval = 2 // try only one lag
  
	//local interact_credit_cond_rndvar = 1 // yes add interact term between baa and avgrnd
	//local interact_credit_cond_rndvar = 2 // yes add interact term between baa and rnd intensity median dummy
	local interact_credit_cond_rndvar = 3 // yes add interact term between zt and avgrnd
	//local interact_credit_cond_rndvar = 4 // yes add interact term between zt and rnd intensity median dummy  
  
	set more off
	
	use "${dtapath}\time_series_by_port", clear		
	keep if ~missing(rnd_to_assets_F0)
	
	// keep only quintile ports
	tab port
	keep if inlist(port,1,2,3,4,5)
	
	// compute unlevered excess returns
	merge m:1 datemo using "${dtapath}\famafrench_monthly_factors", nogen keepusing(rf) keep(master match)
	gen ex_ret_unlev = port_ret_un_vw-rf/100			
	
	// compute average R&D intensity at the firm level
	// this average can be time varying if we distinguish more
	// than one subperiod
	gen year = year(dofm(datemo))
	//gen subperiod = 1  if year>=1972 & year<=2013
	gen subperiod = 1  if year>=`startyr' & year<=2013
	// note: keep 2013 as last year because we require at least 3 years ahead of data
	
	sort port subperiod datemo
	by port subperiod: egen avg_rnd_to_assets = mean(rnd_to_assets_F0) if ~missing(subperiod)
	
		// check the averages
		preserve
			keep if ~missing(subperiod)
			collapse (mean) avg_rnd_to_assets, by(port)
			//collapse (mean) avg_rnd_to_assets, by(port subperiod)
			//br
			//collapse (mean) mean_avg_rnd_to_assets=avg_rnd_to_assets (sd) sd_avg_rnd_to_assets=avg_rnd_to_assets, by(port)
			//br
		restore
		
	keep if ~missing(subperiod) // make sure no extra data used in different regressions
	save "${dtapath}\temp_data_for_regs", replace	
		
	// run annual var regressions
	use "${dtapath}\temp_data_for_regs", clear
	
	// keep one obs per year and merge on ivol	
	keep if month(dofm(datemo))==7 // focus on values as of june 30 in a given year
	drop datemo
	merge m:1 year using "${dtapath}\integrated_volatility_annual", nogen keep(master match)
	merge m:1 year using "${dtapath}\resid_series_for_panel_regs_annual", nogen keep(master match) // more sophisticated ivol residuals		
	merge m:1 year using "${dtapath}\credit_spreads_ann", nogen  keep(master match) keepusing(baa10ym) // credit conditions variables
	tsset port year
	
	// pick volatility var and the compute interaction and choose the orthog z variable
	if "`vol_var'"== "ivol" {
		gen vol_var      = ivol
		gen interact_var = ivol*avg_rnd_to_assets
		gen z_var        = epd_ivol
	}
	else if "`vol_var'"== "epu" {
		gen vol_var      = epu
		gen interact_var = epu*avg_rnd_to_assets
		gen z_var        = epd_epu		
	}
	else if "`vol_var'"== "expvol" {
		gen vol_var      = expvol
		gen interact_var = expvol*avg_rnd_to_assets
		gen z_var        = epd_expvol		
	}	
	else if "`vol_var'"== "nvix" {
		gen vol_var      = nvix
		gen interact_var = nvix*avg_rnd_to_assets
		gen z_var        = epd_nvix		
	}		
	else {
		disp("vol_var not recognized")
		error
	}		

	// add interaction term between firm-level R&D intesnity and Baa corporate spreads
	// remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
	if "`interact_credit_cond_rndvar'"=="1" & "`control_credit_cond'"=="1" {
		gen interact_var_cc = baa10ym*avg_rnd_to_assets 
	}
	if "`interact_credit_cond_rndvar'"=="2" & "`control_credit_cond'"=="1" {
		bysort datemo: egen medvalue = pctile(avg_rnd_to_assets), p(50)
		gen med_dummy = avg_rnd_to_assets>medvalue if ~missing(medvalue) & ~missing(avg_rnd_to_assets)
		gen interact_var_cc = baa10ym*med_dummy 
	}	
	if "`interact_credit_cond_rndvar'"=="3" {
		gen interact_var_cc = z_var*avg_rnd_to_assets 
	}	
	if "`interact_credit_cond_rndvar'"=="4" {
		bysort datemo: egen medvalue = pctile(avg_rnd_to_assets), p(50)
		gen med_dummy = avg_rnd_to_assets>medvalue if ~missing(medvalue) & ~missing(avg_rnd_to_assets)
		gen interact_var_cc = z_var*med_dummy 
	}			
	
	// create empty vars to hold regression output
	foreach myvar in "real_capx" "real_totinv" "emp" "rnd_to_assets" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 
		"labor_prod" /// added february 2020	
		"real_pat_val_cw2" "real_pat_val_sm2" /// added february 2020
		"patent_grants2" "patent_apps2" /// added february 2020 		
	{	
		gen reg_beta_ivol_`myvar' = .
		gen reg_beta_inter_`myvar' = .		
		gen reg_beta_e_pd_`myvar'  = .
		gen reg_se_ivol_`myvar' = .
		gen reg_se_inter_`myvar' = .		
		gen reg_se_e_pd_`myvar'    = .
		gen reg_t_ivol_`myvar' = .
		gen reg_t_inter_`myvar' = .		
		gen reg_t_e_pd_`myvar'     = .
		gen reg_Nobs_`myvar' = .
		gen reg_Nfirms_`myvar' = .
		gen reg_wald_fval_`myvar' = .
		gen reg_wald_pval_`myvar' = .
		gen reg_r2_full_`myvar' = .
		gen reg_r2_drop1_`myvar'  = .
		gen reg_r2_drop2_`myvar'  = .	
		if `control_credit_cond'==1 {
			gen reg_beta_cc_`myvar' = .
			gen reg_se_cc_`myvar' = .
			gen reg_t_cc_`myvar' = .		
		}
	}		
	
	// run example regression
	local myyear = 3		
	//local myvar = "real_totinv"
	local myvar = "real_pat_val_cw"
	//local myvar = "real_xsga"
	//gen depvar = gro_ann_`myyear'yr_`myvar' 
	gen depvar = gro_ann_`myyear'yr_`myvar'  if gro_ann_`myyear'yr_`myvar'>-100
	summ depvar, detail
	ivreg2 depvar vol_var interact_var z_var baa10ym i.port ///
		(vol_var interact_var z_var baa10ym i.port=vol_var interact_var z_var baa10ym i.port) ///
		, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
	drop depvar	
	
		// try other regressions with patent-related measures
		local myyear = 3		
		//local myvar = "real_pat_val_sm" // doesn't work
		local myvar = "real_pat_val_cw" // works
		//local myvar = "patent_grants" // doesn't work
		//local myvar = "patent_apps" // doesn't work
		gen depvar = gro_ann_`myyear'yr_`myvar'  if gro_ann_`myyear'yr_`myvar'>-100
		summ depvar, detail
		ivreg2 depvar vol_var interact_var z_var baa10ym i.port ///
			(vol_var interact_var z_var baa10ym i.port=vol_var interact_var z_var baa10ym i.port) ///
			if port>=2 /// try removing low R&D portfolio
			, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		drop depvar		
		
	// create new patent-related vars that only are non-missing for port>=2
	// because it seems like lowest R&D port has series too volatile
	// given lack of consistent data on patent values
	foreach myvar in ///
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 	  
	{	
	  foreach myyear in 1 2 3 4 5 {	
		gen gro_ann_`myyear'yr_`myvar'2 = gro_ann_`myyear'yr_`myvar' if port>=2
	  }
	}
		
	// run annual regressions
	foreach myyear in 1 2 3 4 5 {	
	  //foreach myvar in "real_totinv" {	   
	  foreach myvar in "real_totinv" "rnd_to_assets" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 	  
		"emp" "labor_prod" /// added february 2020	
		"real_pat_val_cw2" "real_pat_val_sm2" /// added february 2020
		"patent_grants2" "patent_apps2" /// added february 2020 	  		
	  {	// "real_capx" "emp" 
		disp "`myvar' `myyear'yr..."				  
		
			// pick out dependant var based on myvar
			if "`myvar'"=="rnd_to_assets" {
				gen depvar = diff_ratio_`myyear'yr_`myvar' // change in rnd to assets ratio
				//gen depvar = diff_ratio_ann_`myyear'yr_`myvar' // change in rnd to assets ratio
			}
			else {
				//xtreg gro_`myyear'yr_`myvar'  ivol interact_ivol_rnd epd_ivol, fe vce(cluster sic2)
				//gen depvar = gro_`myyear'yr_`myvar'
				//gen depvar = gro_ann_`myyear'yr_`myvar' // use annualized growth rate to be consistent with firm-level regs
				gen depvar = gro_ann_`myyear'yr_`myvar' if gro_ann_`myyear'yr_`myvar'>-100 // make sure not using points based on zeros
			}			
		
			// run main regression specification with or without control for credit conditions
			if `control_credit_cond'==1 {
			  if "`port_cfprof_cont_var'"=="none" {
				if "`interact_credit_cond_rndvar'"=="1" | "`interact_credit_cond_rndvar'"=="2" | "`interact_credit_cond_rndvar'"=="3" | "`interact_credit_cond_rndvar'"=="4" {
					ivreg2 depvar vol_var interact_var z_var baa10ym interact_var_cc tobinQ i.port ///
						(vol_var interact_var z_var baa10ym tobinQ i.port=vol_var interact_var z_var baa10ym tobinQ i.port) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
				}				
				else {
					ivreg2 depvar vol_var interact_var z_var baa10ym tobinQ i.port ///
						(vol_var interact_var z_var baa10ym tobinQ i.port=vol_var interact_var z_var baa10ym tobinQ i.port) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
				}
			  }
			  else {
				if "`interact_credit_cond_rndvar'"=="1" | "`interact_credit_cond_rndvar'"=="2" | "`interact_credit_cond_rndvar'"=="3" | "`interact_credit_cond_rndvar'"=="4" {
					ivreg2 depvar vol_var interact_var z_var baa10ym interact_var_cc `port_cfprof_cont_var' tobinQ  i.port ///
						(vol_var interact_var z_var baa10ym interact_var_cc `port_cfprof_cont_var' tobinQ  i.port = ///
						 vol_var interact_var z_var baa10ym interact_var_cc `port_cfprof_cont_var' tobinQ  i.port) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				}				
				else {			  
					ivreg2 depvar vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ  i.port ///
						(vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ  i.port = ///
						 vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ  i.port) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				}
			  }
			}
			else {
			  if "`port_cfprof_cont_var'"=="none" {
				if "`interact_credit_cond_rndvar'"=="1" | "`interact_credit_cond_rndvar'"=="2" | "`interact_credit_cond_rndvar'"=="3" | "`interact_credit_cond_rndvar'"=="4" {
					ivreg2 depvar vol_var interact_var z_var interact_var_cc i.port i.year ///
						(vol_var interact_var z_var interact_var_cc i.port i.year=vol_var interact_var z_var interact_var_cc i.port i.year) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
				}				
				else {				  
					ivreg2 depvar vol_var interact_var z_var i.port i.year ///
						(vol_var interact_var z_var i.port i.year=vol_var interact_var z_var i.port i.year) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
				}
			  }
			  else {
				if "`interact_credit_cond_rndvar'"=="1" | "`interact_credit_cond_rndvar'"=="2" | "`interact_credit_cond_rndvar'"=="3" | "`interact_credit_cond_rndvar'"=="4" {
					ivreg2 depvar vol_var interact_var z_var interact_var_cc `port_cfprof_cont_var' tobinQ i.port i.year ///
						(vol_var interact_var z_var interact_var_cc `port_cfprof_cont_var' tobinQ i.port i.year = ///
						 vol_var interact_var z_var interact_var_cc `port_cfprof_cont_var' tobinQ i.port i.year) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				}				
				else {				  
					ivreg2 depvar vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port i.year ///
						(vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port i.year = ///
						 vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port i.year) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				}
			  }
			}
			
				// old regression specifications tried/used
				//xtreg depvar vol_var interact_ivol_rnd epd_ivol, fe vce(cluster sic2)
				//areg depvar vol_var interact_var z_var, absorb(lpermno) vce(cluster sic2)	
				//areg depvar vol_var interact_var z_var, absorb(port) vce(robust)
				//ivreg2 depvar vol_var interact_var z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				// note: run with GMM option even though it gives same answer			
	
			// save results
			matrix b = e(b)
			matrix V = e(V)
			local reg_beta_ivol     = b[1,1]
			local reg_beta_inter = b[1,2]
			local reg_beta_e_pd     = b[1,3]
			local reg_se_ivol       = sqrt(V[1,1])
			local reg_se_inter   = sqrt(V[2,2])
			local reg_se_e_pd       = sqrt(V[3,3])
			local reg_t_ivol     = b[1,1] / sqrt(V[1,1])
			local reg_t_inter = b[1,2] / sqrt(V[2,2])	
			local reg_t_e_pd     = b[1,3] / sqrt(V[3,3])
			local reg_Nobs = e(N)
			//local reg_Nfirm = e(N_g) // for xtreg
			local reg_Nfirm = e(k_absorb) // for areg
			local reg_r2_full = e(r2)
			replace reg_beta_ivol_`myvar'     = `reg_beta_ivol'     if _n==`myyear'
			replace reg_beta_inter_`myvar' = `reg_beta_inter' if _n==`myyear'
			replace reg_beta_e_pd_`myvar'     = `reg_beta_e_pd'     if _n==`myyear'	
			replace reg_se_ivol_`myvar'       = `reg_se_ivol'       if _n==`myyear'
			replace reg_se_inter_`myvar'   = `reg_se_inter'   if _n==`myyear'
			replace reg_se_e_pd_`myvar'       = `reg_se_e_pd'       if _n==`myyear'	
			replace reg_t_ivol_`myvar'        = `reg_t_ivol'        if _n==`myyear'
			replace reg_t_inter_`myvar'    = `reg_t_inter'    if _n==`myyear'
			replace reg_t_e_pd_`myvar'        = `reg_t_e_pd'        if _n==`myyear'	
			replace reg_Nobs_`myvar'    	  = `reg_Nobs'          if _n==`myyear'				
			replace reg_Nfirms_`myvar'    	  = `reg_Nfirm'         if _n==`myyear'				
			replace reg_r2_full_`myvar' = `reg_r2_full' if _n==`myyear'	
			if `control_credit_cond'==1 {
				local reg_beta_cc  = b[1,4] 
				local reg_se_cc    = sqrt(V[4,4]) 
				local reg_t_cc     = b[1,4] / sqrt(V[4,4])			
				replace reg_beta_cc_`myvar' = `reg_beta_cc' if _n==`myyear'
				replace reg_se_cc_`myvar' = `reg_se_cc'     if _n==`myyear'
				replace reg_t_cc_`myvar' = `reg_t_cc'	    if _n==`myyear'	
			}			
			
			// wald test stats
			
				// joint test that betas for both ivol and interaction term are zero
				test vol_var interact_var
				replace reg_wald_fval_`myvar' = r(chi2) if _n==`myyear'				
				replace reg_wald_pval_`myvar' = r(p) if _n==`myyear'				
			
			// re-run regression without certain terms and save r2
			// note: use ivreg2 without GMM to Stata expressions are simpler
			//       but we get the same coefficients
				
				//areg depvar vol_var z_var, absorb(lpermno) vce(cluster sic2)	
				//areg depvar vol_var z_var, absorb(port) vce(robust)
				//ivreg2 depvar vol_var z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				if `control_credit_cond'==1 {
				  if "`port_cfprof_cont_var'"=="none" {	
					ivreg2 depvar vol_var z_var baa10ym tobinQ i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)					
				  }
				  else {
				    ivreg2 depvar vol_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				  }
				}
				else {
				  if "`port_cfprof_cont_var'"=="none" {	
					//ivreg2 depvar vol_var z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					//ivreg2 depvar vol_var z_var i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					ivreg2 depvar vol_var z_var tobinQ i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				  }
				  else {
				    ivreg2 depvar vol_var z_var `port_cfprof_cont_var' tobinQ  i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				  }
				}				
				local reg_r2_drop1 = e(r2)
				replace reg_r2_drop1_`myvar' = `reg_r2_drop1' if _n==`myyear'
						
				//areg depvar z_var, absorb(lpermno) vce(cluster sic2)	
				//areg depvar z_var, absorb(port) vce(robust)
				//ivreg2 depvar z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				if `control_credit_cond'==1 {
				  if "`port_cfprof_cont_var'"=="none" {	
					//ivreg2 depvar z_var baa10ym i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					ivreg2 depvar z_var baa10ym tobinQ i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				  }
				  else {
				    ivreg2 depvar z_var baa10ym `port_cfprof_cont_var' tobinQ i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				  }
				}
				else {
				  if "`port_cfprof_cont_var'"=="none" {	
					//ivreg2 depvar z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					//ivreg2 depvar z_var i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					ivreg2 depvar z_var tobinQ i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				  }
				  else {
				    ivreg2 depvar z_var `port_cfprof_cont_var' tobinQ  i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				  }
				}									
				local reg_r2_drop2 = e(r2)		
				replace reg_r2_drop2_`myvar' = `reg_r2_drop2' if _n==`myyear'
			
			// clean up
			drop depvar 
	  }
	}
	
	
	// save out the dataset
	keep if _n<=5	
	gen N_years_fwd = _n
	keep N_years_fwd reg_*	
	gen vol_var="`vol_var'"
	gen startyr=`startyr'
	tostring N_years_fwd, gen(temp_str)
	//gen vlookup_var = vol_var+"-"+temp_str
	gen vlookup_var = "`startyr'"+"-"+vol_var+"-"+temp_str
	drop temp_str
	order vlookup_var vol_var startyr N_years_fwd
	save "${dtapath}\temp_results_port_regs", replace
	
	// save out the compile dataset	
	if `new_export_sheet'==1 {
		use "${dtapath}\temp_results_port_regs", clear
		save "${dtapath}\results_port_regs", replace
		local new_export_sheet=0
	}
	else {
		use "${dtapath}\temp_results_port_regs", clear
		append using "${dtapath}\results_port_regs"
		save "${dtapath}\results_port_regs", replace
	}	
	
   } // vol_var loop
   } // startyr loop
	
	// export regression results into workbook
	use "${dtapath}\results_port_regs", clear
	if "`interact_credit_cond_rndvar'"=="1" | "`interact_credit_cond_rndvar'"=="2" | "`interact_credit_cond_rndvar'"=="3" | "`interact_credit_cond_rndvar'"=="4" {
		export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("portreg_`port_cfprof_cont_var'_`control_credit_cond'_`interact_credit_cond_rndvar'") sheetreplace
	}
	else {
		export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("portreg_`port_cfprof_cont_var'_`control_credit_cond'") sheetreplace	
	}
	
    

   } // new_export_sheet
  } // interact_credit_cond_rndvar
 } // port_cfprof_cont_var loop
} // control_credit_cond loop 
	

	
/********************************************************************/
// re-do portfolio-level regression analysis on different subsets
// that incorporate data availiability of mydepvar
// qqq
 
foreach mydepvar in "real_pat_val_sm" "real_pat_val_cw" "patent_apps" "patent_grants" "real_capx" {
foreach new_export_sheet in 1 {
 foreach myportvar in "rnd_to_assets" {
  foreach control_credit_cond in 1 0 { // yes==1, otherwise no
   foreach port_cfprof_cont_var in "none" { // "none" means no controls, any other choice is that cash flow control plus average Tobin's Q
    foreach startyr in 1972 1975 { //  1975 1982 
     foreach vol_var in "ivol" { // "ivol" "epu" run for both   
	
//local mydepvar = "real_pat_val_sm"	
//local myportvar = "rnd_to_assets"

	// set bw_val to desired number of hag lags plus 1 (i.e, 1 lag = bw(2))
	//local mybwval = 5 // standard before feb 2020
	local mybwval = 2 // try only one lag
	
	// portfolio assignments	

		use lpermno lag_mkt_cap datemo `myportvar' `mydepvar'_* using "${dtapath}\crsp_merged_with_monthly_compustat", clear
	
		// compute forward-looking growth rates for depvar
		// compute forward-looking growth rates

			gen gro_ann_1yr_`mydepvar' = 100*((`mydepvar'_F24/`mydepvar'_F12)^(1/1)-1) 
			gen gro_ann_2yr_`mydepvar' = 100*((`mydepvar'_F36/`mydepvar'_F12)^(1/2)-1) 
			gen gro_ann_3yr_`mydepvar' = 100*((`mydepvar'_F48/`mydepvar'_F12)^(1/3)-1) 
			gen gro_ann_4yr_`mydepvar' = 100*((`mydepvar'_F60/`mydepvar'_F12)^(1/4)-1) if datemo<=ym(2012,12)						
			gen gro_ann_5yr_`mydepvar' = 100*((`mydepvar'_F72/`mydepvar'_F12)^(1/5)-1) if datemo<=ym(2011,12)		
	
		// keep only the analysis period of interest
		keep if datemo>=ym(1972, 1)	
		keep if datemo<=ym(2016,12)	// sample cut off for consistency across all empirical analysis		
	
		// focus on firms with non-missing portfolio sorting var
		keep if ~missing(`myportvar')
		
		// also focus on firms with sufficient depvar info
		gen has_5yr_depvar = ~missing(gro_ann_5yr_`mydepvar') if datemo<=ym(2013,12) & month(dofm(datemo))==7
		bysort lpermno: egen total_has_5yr_depvar = total(has_5yr_depvar)
		tab total_has_5yr_depvar
		keep if total_has_5yr_depvar>=10 // minimum depvar 5-year growth rate annual obs
	
		// assign portfolios
		set more off
		bysort datemo: egen p20=pctile(`myportvar'), p(20)
		bysort datemo: egen p40=pctile(`myportvar'), p(40)
		bysort datemo: egen p60=pctile(`myportvar'), p(60)
		bysort datemo: egen p80=pctile(`myportvar'), p(80)
		gen port_quint = 1 if `myportvar'<=p20
		replace port_quint = 2 if `myportvar'>p20 & `myportvar'<=p40
		replace port_quint = 3 if `myportvar'>p40 & `myportvar'<=p60
		replace port_quint = 4 if `myportvar'>p60 & `myportvar'<=p80
		replace port_quint = 5 if `myportvar'>p80
		replace port_quint = . if missing(`myportvar')
		//tab port
		//rename port port_`myportvar'		
		//rename p20 p20_`myportvar'
		//rename p40 p40_`myportvar'
		//rename p60 p60_`myportvar'
		//rename p80 p80_`myportvar'
		drop p20* p40* p60* p80*
			
		tsset lpermno datemo
			
		// choose which portfolio assignment to use
		gen port = port_quint
		keep datemo lpermno port
		save "${dtapath}\temp_port_rebal_monthly", replace

	// create time series by portfolio

		use "${dtapath}\crsp_merged_with_monthly_compustat", clear
		merge 1:1 lpermno datemo using "${dtapath}\temp_port_rebal_monthly", nogen // should be exact match with all obs
	
		// focus on firms that are in portfolios
		drop if missing(port)
		tab port
		//keep if inlist(port,1,2,3,4,5)
	
		// for computing unlevered equal-weighted returns
		// note that I set to missing a handful of outliers
		gen quasimkt_lvg = book_debt_F0 / (book_debt_F0 + lag_mkt_cap*(10^3)) // put mkt_cap in millions	
		replace quasimkt_lvg = . if quasimkt_lvg<0 // set to missing if negative
		replace quasimkt_lvg = . if quasimkt_lvg>1 & ~missing(quasimkt_lvg) // set to missing if greater than 100%
		//summ quasimkt_lvg, detail
		gen ret_un = (1-quasimkt_lvg)*ret	
	
		// prepare for collapsing by portfolio
		bysort port datemo: egen lag_mkt_cap_sum = sum(lag_mkt_cap)
		gen contrib_wgt = (lag_mkt_cap/lag_mkt_cap_sum)
		gen contrib_ret = contrib_wgt * ret	
		sort lpermno datemo // for visual checking

		// collapse by portfolio
		collapse (count) num_firms=ret (mean) port_ret_ew=ret port_ret_un_ew=ret_un ///
			(sum) check_wgt=contrib_wgt port_ret_vw=contrib_ret lag_mkt_cap book_debt_F0 book_equity_F0 ///
				  emp* real_xrd* real_capx* ///
				  at_* xrd_* ///
				  oibdp_* revt_* cogs_* ///
				  ocf_F0 /// ocf_F0_for_cfr 
				  real_revt* real_xsga* real_ocf* real_pat_* patent_* /// added february 2020
			, by(datemo port) 
		summ check_wgt
		drop if check_wgt <0.9 // should only drop missing observations	
		drop check_wgt
	
		// set patent-related values to missing instead of zero b/c no data available
		// means we should not use such values in growth rates
		foreach mypatvar of varlist real_pat_val* patent_* {
			replace `mypatvar'=. if `mypatvar'==0
		}
		
		// compute R&D intensity and labor prod
		foreach fval in 0 12 24 36 48 60 72 {
			gen rnd_to_assets_F`fval' = xrd_F`fval' / at_F`fval'
			gen labor_prod_F`fval' = revt_F`fval' / emp_F`fval' // added Feb. 2020
		}		
		
		// compute total investment variables
		foreach fval in 0 12 24 36 48 60 72 {
			egen real_totinv_F`fval' = rowtotal(real_capx_F`fval' real_xrd_F`fval'), missing
		}	
		
		// markup at the portfolio level
		gen markup_ebitda_F0 = oibdp_F0 / revt_F0
		gen markup_rev_F0    = (revt_F0-cogs_F0) / revt_F0

		// other ratios of interest for summary table
		
			// sales to assets
			gen sales_to_assets = revt_F0 / at_F0
			
			// more leverage ratios
			gen book_leverage_raw = book_debt_F0 / (book_debt_F0+book_equity_F0)
			gen book_leverage_trunc = book_leverage_raw
			replace book_leverage_trunc = 1 if book_leverage_raw>1 & ~missing(book_leverage_raw) // due to negative book equity which is like 100% book leverage
			replace book_leverage_trunc = 0 if book_leverage_raw<0 & ~missing(book_leverage_raw) // due to negative book debt which is like 0% book leverage
			gen book_leverage_maxjfe = 1- (book_equity_F0/at_F0)	
			
			// tobin's Q
			gen tobinQ = lag_mkt_cap*(10^3)/book_equity_F0
			summ tobinQ, detail
			//sort datemo
			//line tobinQ datemo if port==1
			//line tobinQ datemo if port==5
			
			// cash flow profitability ratio
			gen cfprof_ratio = ocf_F0 / revt_F0 		
			summ cfprof_ratio, detail		
			//sort datemo
			//line cfprof_ratio datemo if port==1
			//line cfprof_ratio datemo if port==5
			// negative ratio for port 5 is not data error in 2000s		
			//gen cfprof_ratio2 = ocf_F0_for_cfr / revt_F0_for_cfr  
			//line cfprof_ratio2 datemo if port==5

		
		// for computing unlevered value-weighted returns
		gen quasimkt_lvg = book_debt_F0 / (book_debt_F0 + lag_mkt_cap*(10^3)) // put mkt_cap in millions
		gen port_ret_un_vw = (1-quasimkt_lvg)*port_ret_vw					
	
		/*deflate returns from nominal to real using a cpi deflator*/
		local deflator = "ibbotson" // either choose "cpi" or "ibbotson"
		if "`deflator'"=="ibbotson" {
			//merge m:1 datemo using "${dtapath}\ibbotson_monthly", nogen noreport keep(master match)					
			merge m:1 datemo using "${dtapath}\inflation_monthly", ///
				nogen noreport keep(master match) keepusing(inflation_deflator)				
			gen port_ret_vw_real = (1+port_ret_vw)/inflation_deflator - 1
			gen port_ret_ew_real = (1+port_ret_ew)/inflation_deflator - 1
			gen port_ret_un_vw_real = (1+port_ret_un_vw)/inflation_deflator - 1
			gen port_ret_un_ew_real = (1+port_ret_un_ew)/inflation_deflator - 1
		}
		else {
			error "choose either cpi or inflation to deflate returns"
		}	
	
		// compute forward-looking growth rates
		foreach myvar in "real_xrd" "real_capx" "real_totinv" "emp" ///
			"real_revt" "real_xsga" "real_ocf" /// added february 2020
			"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
			"patent_grants" "patent_apps" /// added february 2020	
			"labor_prod" /// added february 2020	
		{

			gen gro_ann_1yr_`myvar' = 100*((`myvar'_F24/`myvar'_F12)^(1/1)-1) 
			gen gro_ann_2yr_`myvar' = 100*((`myvar'_F36/`myvar'_F12)^(1/2)-1) 
			gen gro_ann_3yr_`myvar' = 100*((`myvar'_F48/`myvar'_F12)^(1/3)-1) 
			gen gro_ann_4yr_`myvar' = 100*((`myvar'_F60/`myvar'_F12)^(1/4)-1) if datemo<=ym(2012,12)						
			gen gro_ann_5yr_`myvar' = 100*((`myvar'_F72/`myvar'_F12)^(1/5)-1) if datemo<=ym(2011,12)		
		
		}		
		
		
		// compute change in ratio values
		foreach myvar in "rnd_to_assets" {
			// old method that generates negative average market growth
			gen diff_ratio_1yr_`myvar' = 100*(`myvar'_F24 - `myvar'_F12) 
			gen diff_ratio_2yr_`myvar' = 100*(`myvar'_F36 - `myvar'_F12) 
			gen diff_ratio_3yr_`myvar' = 100*(`myvar'_F48 - `myvar'_F12) 
			gen diff_ratio_4yr_`myvar' = 100*(`myvar'_F60 - `myvar'_F12) if datemo<=ym(2012,12)						 
			gen diff_ratio_5yr_`myvar' = 100*(`myvar'_F72 - `myvar'_F12) if datemo<=ym(2011,12)	
		}
			
		/*add on recession indicators*/
		gen full=1
		merge m:1 datemo using "${dtapath}\nber_recession_dummies", nogen noreport keep(match) keepusing(rec_dum)
		merge m:1 datemo using "${dtapath}\integrated_volatility_monthly", nogen noreport keep(match) ///
			keepusing(high_ivol_80 high_ivol_90 high_ivol_95)
			//keepusing(high_ivol_80 high_ivol_90 high_ivol_95 high_ivol_qtr_80 high_ivol_qtr_90 high_ivol_qtr_95)
			
		// add on economic policy uncertainty indicator
		merge m:1 datemo using "${dtapath}\epu_hist_index_monthly", nogen keep(master match) ///
			keepusing( ///
				high_epu_hist_full_80 high_epu_hist_full_90 high_epu_hist_full_95 ///
				high_epu_hist_from1972_80 high_epu_hist_from1972_90 high_epu_hist_from1972_95 ///
			)		
		
		// compute excess returns
		merge m:1 datemo using "${dtapath}\famafrench_monthly_factors", nogen keepusing(rf) keep(master match)
		foreach rettype in "ew" "vw" "un_ew" "un_vw" {
			gen ex_ret_`rettype' = port_ret_`rettype' - rf/100
		}
		
		// compute market cap shares
		gen lag_mkt_cap_for_sum = lag_mkt_cap if inlist(port,1,2,3,4,5)
		bysort datemo: egen sum_lag_mkt_cap = sum(lag_mkt_cap_for_sum)
		gen share_lag_mkt_cap = lag_mkt_cap / sum_lag_mkt_cap
		drop lag_mkt_cap_for_sum sum_lag_mkt_cap
		
		sort port datemo
		tsset port datemo
	
		// earnings per unit of capital
		gen ebitda_at_F0 = oibdp_F0 / at_F0	
	
		// compute unlevered excess returns
		merge m:1 datemo using "${dtapath}\famafrench_monthly_factors", nogen keepusing(rf) keep(master match)
		gen ex_ret_unlev = port_ret_un_vw-rf/100			

		// compute average R&D intensity at the firm level
		// this average can be time varying if we distinguish more
		// than one subperiod
		gen year = year(dofm(datemo))
		//gen subperiod = 1  if year>=1972 & year<=2013
		gen subperiod = 1  if year>=`startyr' & year<=2013
		// note: keep 2013 as last year because we require at least 3 years ahead of data
		
		sort port subperiod datemo
		by port subperiod: egen avg_rnd_to_assets = mean(rnd_to_assets_F0) if ~missing(subperiod)
	
		// check the averages
		preserve
			keep if ~missing(subperiod)
			collapse (mean) avg_rnd_to_assets, by(port)
			//collapse (mean) avg_rnd_to_assets, by(port subperiod)
			//br
			//collapse (mean) mean_avg_rnd_to_assets=avg_rnd_to_assets (sd) sd_avg_rnd_to_assets=avg_rnd_to_assets, by(port)
			//br
		restore
		
		keep if ~missing(subperiod) // make sure no extra data used in different regressions
		save "${dtapath}\temp_data_for_regs", replace	
		
	// run annual var regressions
	
		use "${dtapath}\temp_data_for_regs", clear
		
		// keep one obs per year and merge on ivol	
		keep if month(dofm(datemo))==7 // focus on values as of june 30 in a given year
		drop datemo
		merge m:1 year using "${dtapath}\integrated_volatility_annual", nogen keep(master match)
		merge m:1 year using "${dtapath}\resid_series_for_panel_regs_annual", nogen keep(master match) // more sophisticated ivol residuals		
		merge m:1 year using "${dtapath}\credit_spreads_ann", nogen  keep(master match) keepusing(baa10ym) // credit conditions variables
		tsset port year
	
		// pick volatility var and the compute interaction and choose the orthog z variable
		if "`vol_var'"== "ivol" {
			gen vol_var      = ivol
			gen interact_var = ivol*avg_rnd_to_assets
			gen z_var        = epd_ivol
		}
		else if "`vol_var'"== "epu" {
			gen vol_var      = epu
			gen interact_var = epu*avg_rnd_to_assets
			gen z_var        = epd_epu		
		}
		else {
			disp("vol_var not recognized")
			error
		}			
		
		
		// create empty vars to hold regression output
		foreach myvar in "real_capx" "real_totinv" "emp" "rnd_to_assets" ///
			"real_revt" "real_xsga" "real_ocf" /// added february 2020
			"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
			"patent_grants" "patent_apps" /// added february 2020 
			"labor_prod" /// added february 2020		
		{	
			gen reg_beta_ivol_`myvar' = .
			gen reg_beta_inter_`myvar' = .		
			gen reg_beta_e_pd_`myvar'  = .
			gen reg_se_ivol_`myvar' = .
			gen reg_se_inter_`myvar' = .		
			gen reg_se_e_pd_`myvar'    = .
			gen reg_t_ivol_`myvar' = .
			gen reg_t_inter_`myvar' = .		
			gen reg_t_e_pd_`myvar'     = .
			gen reg_Nobs_`myvar' = .
			gen reg_Nfirms_`myvar' = .
			gen reg_wald_fval_`myvar' = .
			gen reg_wald_pval_`myvar' = .
			gen reg_r2_full_`myvar' = .
			gen reg_r2_drop1_`myvar'  = .
			gen reg_r2_drop2_`myvar'  = .	
			if `control_credit_cond'==1 {
				gen reg_beta_cc_`myvar' = .
				gen reg_se_cc_`myvar' = .
				gen reg_t_cc_`myvar' = .		
			}
		}		
		
		// run example regressions		
		local myyear = 3		
		//local myvar = "real_totinv"
		local myvar = "real_pat_val_cw"
		//local myvar = "real_xsga"
		//gen depvar = gro_ann_`myyear'yr_`myvar' 
		gen depvar = gro_ann_`myyear'yr_`myvar'  if gro_ann_`myyear'yr_`myvar'>-100
		summ depvar, detail
		ivreg2 depvar vol_var interact_var z_var baa10ym i.port ///
			(vol_var interact_var z_var baa10ym i.port=vol_var interact_var z_var baa10ym i.port) ///
			, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		drop depvar	
		
			// try other regressions with patent-related measures
			local myyear = 5	
			local myvar = "real_pat_val_sm" // doesn't work
			//local myvar = "real_pat_val_cw" // works
			//local myvar = "patent_grants" // doesn't work
			//local myvar = "patent_apps" // doesn't work
			gen depvar = gro_ann_`myyear'yr_`myvar'  if gro_ann_`myyear'yr_`myvar'>-100
			summ depvar, detail
			ivreg2 depvar vol_var interact_var z_var baa10ym i.port ///
				(vol_var interact_var z_var baa10ym i.port=vol_var interact_var z_var baa10ym i.port) ///
				if port>=2 /// try removing low R&D portfolio
				, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
			drop depvar		
		
		
		// run the full set of annual regressions
		foreach myyear in 1 2 3 4 5 {	
		  //foreach myvar in "real_totinv" {	   
		  foreach myvar in "real_totinv" "rnd_to_assets" ///
			"real_revt" "real_xsga" "real_ocf" /// added february 2020
			"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
			"patent_grants" "patent_apps" /// added february 2020 	  
			"emp" "labor_prod" /// added february 2020	
		  {	// "real_capx" "emp" 
			disp "`myvar' `myyear'yr..."				  
			
				// pick out dependant var based on myvar
				if "`myvar'"=="rnd_to_assets" {
					gen depvar = diff_ratio_`myyear'yr_`myvar' // change in rnd to assets ratio
					//gen depvar = diff_ratio_ann_`myyear'yr_`myvar' // change in rnd to assets ratio
				}
				else {
					//xtreg gro_`myyear'yr_`myvar'  ivol interact_ivol_rnd epd_ivol, fe vce(cluster sic2)
					//gen depvar = gro_`myyear'yr_`myvar'
					//gen depvar = gro_ann_`myyear'yr_`myvar' // use annualized growth rate to be consistent with firm-level regs
					gen depvar = gro_ann_`myyear'yr_`myvar' if gro_ann_`myyear'yr_`myvar'>-100 // make sure not using points based on zeros
				}			
			
				// run main regression specification with or without control for credit conditions
				if `control_credit_cond'==1 {
				  if "`port_cfprof_cont_var'"=="none" {
					ivreg2 depvar vol_var interact_var z_var baa10ym i.port ///
						(vol_var interact_var z_var baa10ym i.port=vol_var interact_var z_var baa10ym i.port) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
				  }
				  else {
					ivreg2 depvar vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ  i.port ///
						(vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ  i.port = ///
						 vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ  i.port) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				  }
				}
				else {
				  if "`port_cfprof_cont_var'"=="none" {
					ivreg2 depvar vol_var interact_var z_var i.port i.year ///
						(vol_var interact_var z_var i.port i.year=vol_var interact_var z_var i.port i.year) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
				  }
				  else {
					ivreg2 depvar vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port i.year ///
						(vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port i.year = ///
						 vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port i.year) ///
						, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				  }
				}
				
					// old regression specifications tried/used
					//xtreg depvar vol_var interact_ivol_rnd epd_ivol, fe vce(cluster sic2)
					//areg depvar vol_var interact_var z_var, absorb(lpermno) vce(cluster sic2)	
					//areg depvar vol_var interact_var z_var, absorb(port) vce(robust)
					//ivreg2 depvar vol_var interact_var z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					// note: run with GMM option even though it gives same answer			
		
				// save results
				matrix b = e(b)
				matrix V = e(V)
				local reg_beta_ivol     = b[1,1]
				local reg_beta_inter = b[1,2]
				local reg_beta_e_pd     = b[1,3]
				local reg_se_ivol       = sqrt(V[1,1])
				local reg_se_inter   = sqrt(V[2,2])
				local reg_se_e_pd       = sqrt(V[3,3])
				local reg_t_ivol     = b[1,1] / sqrt(V[1,1])
				local reg_t_inter = b[1,2] / sqrt(V[2,2])	
				local reg_t_e_pd     = b[1,3] / sqrt(V[3,3])
				local reg_Nobs = e(N)
				//local reg_Nfirm = e(N_g) // for xtreg
				local reg_Nfirm = e(k_absorb) // for areg
				local reg_r2_full = e(r2)
				replace reg_beta_ivol_`myvar'     = `reg_beta_ivol'     if _n==`myyear'
				replace reg_beta_inter_`myvar' = `reg_beta_inter' if _n==`myyear'
				replace reg_beta_e_pd_`myvar'     = `reg_beta_e_pd'     if _n==`myyear'	
				replace reg_se_ivol_`myvar'       = `reg_se_ivol'       if _n==`myyear'
				replace reg_se_inter_`myvar'   = `reg_se_inter'   if _n==`myyear'
				replace reg_se_e_pd_`myvar'       = `reg_se_e_pd'       if _n==`myyear'	
				replace reg_t_ivol_`myvar'        = `reg_t_ivol'        if _n==`myyear'
				replace reg_t_inter_`myvar'    = `reg_t_inter'    if _n==`myyear'
				replace reg_t_e_pd_`myvar'        = `reg_t_e_pd'        if _n==`myyear'	
				replace reg_Nobs_`myvar'    	  = `reg_Nobs'          if _n==`myyear'				
				replace reg_Nfirms_`myvar'    	  = `reg_Nfirm'         if _n==`myyear'				
				replace reg_r2_full_`myvar' = `reg_r2_full' if _n==`myyear'	
				if `control_credit_cond'==1 {
					local reg_beta_cc  = b[1,4] 
					local reg_se_cc    = sqrt(V[4,4]) 
					local reg_t_cc     = b[1,4] / sqrt(V[4,4])			
					replace reg_beta_cc_`myvar' = `reg_beta_cc' if _n==`myyear'
					replace reg_se_cc_`myvar' = `reg_se_cc'     if _n==`myyear'
					replace reg_t_cc_`myvar' = `reg_t_cc'	    if _n==`myyear'	
				}			
				
				// wald test stats
				
					// joint test that betas for both ivol and interaction term are zero
					test vol_var interact_var
					replace reg_wald_fval_`myvar' = r(chi2) if _n==`myyear'				
					replace reg_wald_pval_`myvar' = r(p) if _n==`myyear'				
				
				// re-run regression without certain terms and save r2
				// note: use ivreg2 without GMM to Stata expressions are simpler
				//       but we get the same coefficients
					
					//areg depvar vol_var z_var, absorb(lpermno) vce(cluster sic2)	
					//areg depvar vol_var z_var, absorb(port) vce(robust)
					//ivreg2 depvar vol_var z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					if `control_credit_cond'==1 {
					  if "`port_cfprof_cont_var'"=="none" {	
						ivreg2 depvar vol_var z_var baa10ym i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					  }
					  else {
						ivreg2 depvar vol_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					  }
					}
					else {
					  if "`port_cfprof_cont_var'"=="none" {	
						//ivreg2 depvar vol_var z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
						ivreg2 depvar vol_var z_var i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					  }
					  else {
						ivreg2 depvar vol_var z_var `port_cfprof_cont_var' tobinQ  i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					  }
					}				
					local reg_r2_drop1 = e(r2)
					replace reg_r2_drop1_`myvar' = `reg_r2_drop1' if _n==`myyear'
							
					//areg depvar z_var, absorb(lpermno) vce(cluster sic2)	
					//areg depvar z_var, absorb(port) vce(robust)
					//ivreg2 depvar z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					if `control_credit_cond'==1 {
					  if "`port_cfprof_cont_var'"=="none" {	
						ivreg2 depvar z_var baa10ym i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					  }
					  else {
						ivreg2 depvar z_var baa10ym `port_cfprof_cont_var' tobinQ i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					  }
					}
					else {
					  if "`port_cfprof_cont_var'"=="none" {	
						//ivreg2 depvar z_var i.port, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
						ivreg2 depvar z_var i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					  }
					  else {
						ivreg2 depvar z_var `port_cfprof_cont_var' tobinQ  i.port i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					  }
					}									
					local reg_r2_drop2 = e(r2)		
					replace reg_r2_drop2_`myvar' = `reg_r2_drop2' if _n==`myyear'
				
				// clean up
				drop depvar 
		  }
		}
		
		
		// save out the dataset
		keep if _n<=5	
		gen N_years_fwd = _n
		keep N_years_fwd reg_*	
		gen vol_var="`vol_var'"
		gen startyr=`startyr'
		gen port_cfprof_cont_var = "`port_cfprof_cont_var'"
		gen control_credit_cond = `control_credit_cond'
		gen myportvar = "`myportvar'"
		tostring control_credit_cond, gen(temp_cc)
		tostring N_years_fwd, gen(temp_str)
		//gen vlookup_var = vol_var+"-"+temp_str
		gen vlookup_var = "`startyr'"+"-"+vol_var+"-"+port_cfprof_cont_var+"-"+temp_cc+"-"+temp_str
		drop temp_str temp_cc
		order vlookup_var myportvar startyr vol_var port_cfprof_cont_var control_credit_cond N_years_fwd
		save "${dtapath}\temp_results_port_regs", replace
		
		// save out the compile dataset	
		if `new_export_sheet'==1 {
			use "${dtapath}\temp_results_port_regs", clear
			save "${dtapath}\results_port_regs", replace
			local new_export_sheet=0
		}
		else {
			use "${dtapath}\temp_results_port_regs", clear
			append using "${dtapath}\results_port_regs"
			save "${dtapath}\results_port_regs", replace
		}	
			
     } // vol_var
    } // startyr
   } // port_cfprof_cont_var
  } // control_credit_cond	
 } // myportvar
 
// export regression results into workbook
use "${dtapath}\results_port_regs", clear
export excel using "${outPath}\tables_for_paper.xlsx", ///
firstrow(var) sheet("portreg_`mydepvar'") sheetreplace		 
 
} // new_export_sheet
} // mydepvar  
	
	
	
	
	
	
		
/********************************************************************/
// industry-level regression analysis
// iii

foreach myindvar in "ff49_rnd" "sic2_rnd" "ff49_rnd0" "sic2_rnd0"  { // 
//foreach myindvar in "ff49" "sic2" { // 
foreach myrndvar in "rnd_to_assets_F0" { // standard variable for measuring R&D intensity
//foreach control_credit_cond in 1 0 { // yes==1, otherwise no. run both for draft
foreach control_credit_cond in 1 { // simple run
//foreach control_credit_cond in 0 { // simple run
//foreach port_cfprof_cont_var in "markup_ebitda_F0" "none" "cfprof_ratio"  { 
//foreach port_cfprof_cont_var in "markup_ebitda_F0" "cfprof_ratio"  { // smaller run
//foreach port_cfprof_cont_var in "markup_ebitda_F0" "none" { // smaller run
foreach port_cfprof_cont_var in "markup_ebitda_F0" { // benchmark
// profitability control options: none (no controls), markup_ebitda_F0, cfprof_ratio 
foreach new_export_sheet in 1 { 
 //foreach startyr in 1972 1975 1982 { // full run
 //foreach startyr in 1972 1975 {  
 foreach startyr in 1972 {   
  //foreach vol_var in "ivol" "epu" { // "ivol" "epu"  
  foreach vol_var in "ivol" { // simple run

    display "$S_TIME  $S_DATE"
    disp "Running "
	disp "   myrndvar `myrndvar'"
	disp "   control_credit_cond `control_credit_cond'"
	disp "   port_cfprof_cont_var `port_cfprof_cont_var'"
	disp "   startyr `startyr'"	
	disp "   vol_var `vol_var'"
	disp "   ..."   
    
	// set bw_val to desired number of hag lags plus 1 (i.e, 1 lag = bw(2))
	//local mybwval = 5 // standard before feb 2020
	local mybwval = 2 // try only one lag
	
	// winsorize or not
	local winsorize_switch=0 // ==0 --> no winsorization
	//local winsorize_switch=1 // ==1 --> yes winsorize explanatory and dependent vars
	
//local myrndvar = "rnd_to_assets_F0"
//local control_credit_cond = 1
//local port_cfprof_cont_var = "markup_ebitda_F0"
//local new_export_sheet = 1
//local startyr = 1972   
//local vol_var = "ivol"
  
	set more off
  
    //use "${dtapath}\time_series_by_port_ff49_rnd", clear
	use "${dtapath}\time_series_by_port_`myindvar'", clear	
	keep if ~missing(`myrndvar') // should be zero deleted
	
	// compute average R&D intensity at the firm level
	// this average can be time varying if we distinguish more
	// than one subperiod
	gen year = year(dofm(datemo))
	gen subperiod = 1  if year>=`startyr' & year<=2013	
	replace subperiod = . if year<`startyr' | year>2013
	// note: keep 2013 as last year because we require at least 3 years ahead of data
		
		// try two subperiods
		//replace subperiod = 2 if year>=1993 & ~missing(subperiod) // divide in half
		
		// try 3-year subperiods
		if `startyr'==1972 {
			forvalues j=2/14 { // note that 14 corresponds to last data point in 2013, which works for 3-year fwd growth rates in sample ending 2016
				replace subperiod = `j' if year>=1972+3*(`j'-1) & ~missing(subperiod) 
			}
		}
		if `startyr'==1975 {
			forvalues j=2/13 { // note that 13 corresponds to last data point in 2013, which works for 3-year fwd growth rates in sample ending 2016
				replace subperiod = `j' if year>=1975+3*(`j'-1) & ~missing(subperiod) 
			}
		}		
		if `startyr'==1982 {
			forvalues j=2/11 { // note that 11 corresponds to last data point in 2014, which is one year after sample. as a result last subperiod (11) only has 2 years
				replace subperiod = `j' if year>=1982+3*(`j'-1) & ~missing(subperiod) 
			}
		}		
		//keep year subperiod
		//duplicates drop		
		//br
				
	sort port_ind_num subperiod datemo
	by port_ind_num subperiod: egen avg_rnd_to_assets = mean(`myrndvar') if ~missing(subperiod) // can use diff rnd intensity measures
	
	save "${dtapath}\temp_data_for_regs", replace	
	
	// run annual var regressions
	use "${dtapath}\temp_data_for_regs", clear
	
	// keep one obs per year and merge on ivol	
	keep if month(dofm(datemo))==7 // focus on values as of june 30 in a given year
	drop datemo
	merge m:1 year using "${dtapath}\integrated_volatility_annual", nogen keep(master match)
	merge m:1 year using "${dtapath}\resid_series_for_panel_regs_annual", nogen keep(master match) // more sophisticated ivol residuals		
	merge m:1 year using "${dtapath}\credit_spreads_ann", nogen  keep(master match) keepusing(baa10ym) // credit conditions variables
	tsset port_ind_num year
	
	// keep only sample we care about
	keep if year>=1972 & year<=2013
	// note: keep 2013 as last year because we require at least 3 years ahead of data
	keep if year>=`startyr'
	
	// potentially winsorize the explanatory and dependent variables
	if `winsorize_switch'==1 {
		foreach mywinvar in "avg_rnd_to_assets" "`port_cfprof_cont_var'" "tobinQ" {
			qui summ `mywinvar', detail
			replace `mywinvar' =  `r(p1)' if `mywinvar'< `r(p1)' & ~missing(`mywinvar')
			replace `mywinvar' = `r(p99)' if `mywinvar'>`r(p99)' & ~missing(`mywinvar')		
		}
	}
	
	// pick volatility var and the compute interaction and choose the orthog z variable
	if "`vol_var'"== "ivol" {
		gen vol_var      = ivol
		gen interact_var = ivol*avg_rnd_to_assets // remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
		gen z_var        = epd_ivol
	}
	else if "`vol_var'"== "epu" {
		gen vol_var      = epu
		gen interact_var = epu*avg_rnd_to_assets // remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
		gen z_var        = epd_epu		
	}
	else {
		disp("vol_var not recognized")
		error
	}		

	
	// create empty vars to hold regression output
	foreach myvar in "real_capx" "real_totinv" "emp" "rnd_to_assets" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 
		"labor_prod" /// added february 2020	
		///"tfp_it2014" /// added february 2020	
		///"rndassmiss" /// added february 2020. rnd_to_assets assuming missing rnd==0
		///"real_at" /// added february 2020	
		///"real_mkt_at" /// added february 2020
		///"tobinQ" /// added february 2020
	{	
		gen reg_beta_ivol_`myvar' = .
		gen reg_beta_inter_`myvar' = .		
		gen reg_beta_e_pd_`myvar'  = .
		gen reg_se_ivol_`myvar' = .
		gen reg_se_inter_`myvar' = .		
		gen reg_se_e_pd_`myvar'    = .
		gen reg_t_ivol_`myvar' = .
		gen reg_t_inter_`myvar' = .		
		gen reg_t_e_pd_`myvar'     = .
		gen reg_Nobs_`myvar' = .
		gen reg_Nfirms_`myvar' = .
		gen reg_wald_fval_`myvar' = .
		gen reg_wald_pval_`myvar' = .
		gen reg_r2_full_`myvar' = .
		gen reg_r2_drop1_`myvar'  = .
		gen reg_r2_drop2_`myvar'  = .
		if `control_credit_cond'==1 {
			gen reg_beta_cc_`myvar' = .
			gen reg_se_cc_`myvar' = .
			gen reg_t_cc_`myvar' = .		
		}		
	}		
	
	// run example regression
	local myyear = 3		
	local myvar = "real_totinv"
	gen depvar = gro_ann_`myyear'yr_`myvar'
	//ivreghdfe depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ, absorb(port_ind_num ) robust bw(2)	
	drop depvar
	
	// run annual regressions
	foreach myyear in 3 4 5 { // 1 2 
	  //foreach myvar in "real_totinv" {	   
	  foreach myvar in "real_totinv" "rnd_to_assets" "real_capx" "emp" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 
		"labor_prod" /// added february 2020	
		///"tfp_it2014" /// added february 2020	
		///"rndassmiss" /// added february 2020. rnd_to_assets assuming missing rnd==0
		///"real_at" /// added february 2020
		///"real_mkt_at" /// added february 2020
		///"tobinQ" /// added february 2020		
	  {
		disp "`myvar' `myyear'yr..."				  

//local myyear = 3		
//local myvar = "real_totinv"
		
			// pick out dependant var based on myvar
			//if "`myvar'"=="rnd_to_assets" {
			if "`myvar'"=="rnd_to_assets" | "`myvar'"=="rndassmiss" {
				//gen depvar = diff_rat_`myyear'yr_`myvar' // change in rnd to assets ratio
				gen depvar = diff_`myyear'yr_`myvar' // change in rnd to assets ratio
				//gen depvar = diff_xrd_`myyear'yr_`myvar' // change in xrd divided by avg assets
			}
			else if "`myvar'"=="tfp_it2014" {
				gen depvar = dlog_ann_`myyear'yr_`myvar' // approx ann. pct change b/c diff in var that is in log units
			}
			else {
				//gen depvar = gro_`myyear'yr_`myvar'
				gen depvar = gro_ann_`myyear'yr_`myvar'
			}			
		
			// potentially winsorize the explanatory and dependent variables
			if `winsorize_switch'==1 {
				foreach mywinvar in "depvar" {
					qui summ `mywinvar', detail
					replace `mywinvar' =  `r(p1)' if `mywinvar'< `r(p1)' & ~missing(`mywinvar')
					replace `mywinvar' = `r(p99)' if `mywinvar'>`r(p99)' & ~missing(`mywinvar')		
				}
			}
		
			// because of new patent vars, need to check that depvar is nonmissing
			// enough for estimation not to break
			bysort port_ind_num: egen depvar_count = count(depvar)
			local min_depvar_count = 0 // don't want this restriction for port_ind_num so setting zero effectively removes
		
			// run main regression specification
			//xtreg depvar vol_var interact_ivol_rnd epd_ivol, fe vce(cluster sic2)
			//areg depvar vol_var interact_var z_var, absorb(port_ind_num) vce(cluster sic2)	
			areg depvar vol_var interact_var z_var ///
				if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				, absorb(port_ind_num) // no vce(cluster sic2) for port_ind_num
			local reg_Nfirm = e(k_absorb) // get number of firms from areg
			
			// run main regression specification with or without control for credit conditions
			if `control_credit_cond'==1 {
			  if "`port_cfprof_cont_var'"=="none" {
				//qui ivreg2 depvar vol_var interact_var z_var baa10ym i.port_ind_num ///
				  //(vol_var interact_var z_var baa10ym i.port_ind_num = ///
				   //vol_var interact_var z_var baa10ym i.port_ind_num ) ///
				   //if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  //, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				// don't bother with gmm2s option b/c makes code longer and
				// gives same estimate. we can still claim GMM
				qui ivreghdfe depvar vol_var interact_var z_var baa10ym ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(port_ind_num) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
			  }
			  else {
				//qui ivreg2 depvar vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.port_ind_num ///
				  //(vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.port_ind_num = ///
				   //vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.port_ind_num ) ///
				   //if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  //, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)		
				// don't bother with gmm2s option b/c makes code longer and
				// gives same estimate. we can still claim GMM				  
				qui ivreghdfe depvar vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(port_ind_num) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
			  }			  
			}
			else {
			  if "`port_cfprof_cont_var'"=="none" {						
				//qui ivreg2 depvar vol_var interact_var z_var i.port_ind_num i.year ///
				  //(vol_var interact_var z_var i.port_ind_num i.year = ///
				   //vol_var interact_var z_var i.port_ind_num i.year) ///
				   //if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  //, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)		
				// don't bother with gmm2s option b/c makes code longer and
				// gives same estimate. we can still claim GMM				  				  
				qui ivreghdfe depvar vol_var interact_var z_var ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(port_ind_num year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)					  
			  }
			  else {
				//qui ivreg2 depvar vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port_ind_num i.year ///
				  //(vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port_ind_num i.year = ///
				   //vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.port_ind_num i.year) ///
				   //if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  //, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				qui ivreghdfe depvar vol_var interact_var z_var `port_cfprof_cont_var' tobinQ ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(port_ind_num year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
			  }
			}
			
			
			// save results
			matrix b = e(b)
			matrix V = e(V)
			local reg_beta_ivol  = b[1,1]
			local reg_beta_inter = b[1,2]
			local reg_beta_e_pd  = b[1,3]
			local reg_se_ivol    = sqrt(V[1,1])
			local reg_se_inter   = sqrt(V[2,2])
			local reg_se_e_pd    = sqrt(V[3,3])
			local reg_t_ivol     = b[1,1] / sqrt(V[1,1])
			local reg_t_inter    = b[1,2] / sqrt(V[2,2])	
			local reg_t_e_pd     = b[1,3] / sqrt(V[3,3])
			local reg_Nobs = e(N)
			//local reg_Nfirm = e(N_g) // for xtreg
			//local reg_Nfirm = e(k_absorb) // for areg
			local reg_r2_full = e(r2)
			replace reg_beta_ivol_`myvar'     = `reg_beta_ivol'     if _n==`myyear'
			replace reg_beta_inter_`myvar'    = `reg_beta_inter'    if _n==`myyear'
			replace reg_beta_e_pd_`myvar'     = `reg_beta_e_pd'     if _n==`myyear'	
			replace reg_se_ivol_`myvar'       = `reg_se_ivol'       if _n==`myyear'
			replace reg_se_inter_`myvar'      = `reg_se_inter'      if _n==`myyear'
			replace reg_se_e_pd_`myvar'       = `reg_se_e_pd'       if _n==`myyear'	
			replace reg_t_ivol_`myvar'        = `reg_t_ivol'        if _n==`myyear'
			replace reg_t_inter_`myvar'       = `reg_t_inter'       if _n==`myyear'
			replace reg_t_e_pd_`myvar'        = `reg_t_e_pd'        if _n==`myyear'	
			replace reg_Nobs_`myvar'    	  = `reg_Nobs'          if _n==`myyear'				
			replace reg_Nfirms_`myvar'    	  = `reg_Nfirm'         if _n==`myyear'				
			replace reg_r2_full_`myvar' = `reg_r2_full' if _n==`myyear'	
			if `control_credit_cond'==1 {
				local reg_beta_cc  = b[1,4] 
				local reg_se_cc    = sqrt(V[4,4]) 
				local reg_t_cc     = b[1,4] / sqrt(V[4,4])			
				replace reg_beta_cc_`myvar' = `reg_beta_cc' if _n==`myyear'
				replace reg_se_cc_`myvar' = `reg_se_cc'     if _n==`myyear'
				replace reg_t_cc_`myvar' = `reg_t_cc'	    if _n==`myyear'	
			}	
			
			// wald test stats
			
				// joint test that betas for both ivol and interaction term are zero
				test vol_var interact_var
				replace reg_wald_fval_`myvar' = r(F) if _n==`myyear' // ivreghdfe produces F instead of chi2
				//replace reg_wald_fval_`myvar' = r(chi2) if _n==`myyear' // chi2 from ivreg2 but cannot use ivreg2 for firmlevel									
				replace reg_wald_pval_`myvar' = r(p) if _n==`myyear'	
				
				// alternatively can acumulate individual tests
				//test vol_var=0
				//test interact_var=0, accum
			
			// re-run regression without certain terms and save r2
				
				//areg depvar vol_var z_var, absorb(port_ind_num) vce(cluster sic2)	
				//qui ivreg2 depvar vol_var z_var i.port_ind_num, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				if `control_credit_cond'==1 {
				  if "`port_cfprof_cont_var'"=="none" {
					//qui ivreg2 depvar vol_var z_var baa10ym i.port_ind_num ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					qui ivreghdfe depvar vol_var z_var baa10ym ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(port_ind_num) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				  }
				  else {
					//qui ivreg2 depvar vol_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.port_ind_num ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
					qui ivreghdfe depvar vol_var z_var baa10ym `port_cfprof_cont_var' tobinQ ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(port_ind_num) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				  }
				}
				else {
				  if "`port_cfprof_cont_var'"=="none" {
					//qui ivreg2 depvar vol_var z_var i.port_ind_num i.year ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					qui ivreghdfe depvar vol_var z_var  ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(port_ind_num year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				  }
				  else {
				    //qui ivreg2 depvar vol_var z_var `port_cfprof_cont_var' tobinQ  i.port_ind_num i.year ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				    qui ivreghdfe depvar vol_var z_var `port_cfprof_cont_var' tobinQ  ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(port_ind_num year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  						
				  }
				}
				local reg_r2_drop1 = e(r2)
				replace reg_r2_drop1_`myvar' = `reg_r2_drop1' if _n==`myyear'
					
				//areg depvar z_var, absorb(port_ind_num) vce(cluster sic2)	
				//qui ivreg2 depvar z_var i.port_ind_num, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				if `control_credit_cond'==1 {
				  if "`port_cfprof_cont_var'"=="none" {
					//qui ivreg2 depvar z_var baa10ym i.port_ind_num ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)		
					qui ivreghdfe depvar z_var baa10ym ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(port_ind_num) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)							
				  }
				  else {
					//qui ivreg2 depvar z_var baa10ym `port_cfprof_cont_var' tobinQ i.port_ind_num ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
					qui ivreghdfe depvar z_var baa10ym `port_cfprof_cont_var' tobinQ ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(port_ind_num) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)								
				  }
				}
				else {
				  if "`port_cfprof_cont_var'"=="none" {
					//qui ivreg2 depvar z_var i.port_ind_num i.year ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
					qui ivreghdfe depvar z_var ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(port_ind_num year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				  }
				  else {
				    //qui ivreg2 depvar z_var `port_cfprof_cont_var' tobinQ i.port_ind_num i.year ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				    qui ivreghdfe depvar z_var `port_cfprof_cont_var' tobinQ ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(port_ind_num year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)							
				  }
				}				
				local reg_r2_drop2 = e(r2)		
				replace reg_r2_drop2_`myvar' = `reg_r2_drop2' if _n==`myyear'
			
			// clean up
			drop depvar depvar_count
	  }
	}
	
	// save out the dataset
	keep if _n<=5	
	gen N_years_fwd = _n
	keep N_years_fwd reg_*	
	gen startyr=`startyr'
	gen vol_var="`vol_var'"
	//gen Nobsmin=`Nobsmin'
	gen min_depvar_count = `min_depvar_count'
	tostring N_years_fwd, gen(temp_str)
	//gen vlookup_var = "`startyr'"+"-"+vol_var+"-"+"`Nobsmin'"+"-"+temp_str
	//gen vlookup_var = "`startyr'"+"-"+vol_var+"-"+"`Nobsmin'"+"-"+"`min_depvar_count'"+"-"+temp_str
	gen vlookup_var = "`startyr'"+"-"+vol_var+"-"+"`min_depvar_count'"+"-"+temp_str
	gen port_cfprof_cont_var = "`port_cfprof_cont_var'"
	gen control_credit_cond = "`control_credit_cond'"
	drop temp_str
	//order vlookup_var startyr vol_var Nobsmin min_depvar_count N_years_fwd port_cfprof_cont_var control_credit_cond
	order vlookup_var startyr vol_var min_depvar_count N_years_fwd port_cfprof_cont_var control_credit_cond
	save "${dtapath}\temp_results_panel_regs", replace
	
	// save out the compile dataset	
	if `new_export_sheet'==1 {
		use "${dtapath}\temp_results_panel_regs", clear
		save "${dtapath}\results_panel_regs", replace
		local new_export_sheet=0
	}
	else {
		foreach myLHSvartype in "realvar" { // "retvar" not run anymore
			use "${dtapath}\temp_results_panel_regs", clear
			append using "${dtapath}\results_panel_regs"
			save "${dtapath}\results_panel_regs", replace
		}	
	}
	


	//} // min_depvar_count
   //} // Nobsmin
  } // vol_var 
 } // startyr 
 
 // export regression results into workbook
 use "${dtapath}\results_panel_regs", clear
 export excel using "${outPath}\tables_for_paper.xlsx", ///
	firstrow(var) sheet("`myindvar'reg_`port_cfprof_cont_var'_`control_credit_cond'") sheetreplace
 
 
} // new_export_sheet 
} // port_cfprof_cont_var loop
} // control_credit_cond loop
} // myrndvar loop
} // myindvar

	
	
	
	
	
	
	
	
	
	
	
	
	
/********************************************************************/
// test out firm-level reg commands to figure out whether we
// can replace ivreg2 with another one

if 1==0 { // don't need to run each time

	// step 1: install the ado files if needed
	if 1==0 {
	
		// the following from Sergio Correria's ivreghdfe readme file
		// https://github.com/sergiocorreia/ivreghdfe
		
		* Install ftools (remove program if it existed previously)
		cap ado uninstall ftools
		net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")

		* Install reghdfe
		cap ado uninstall reghdfe
		net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

		* Install boottest (Stata 11 and 12)
		//if (c(version)<13) cap ado uninstall boottest
		//if (c(version)<13) ssc install boottest

		* Install moremata (sometimes used by ftools but not needed for reghdfe)
		cap ssc install moremata

		* Install ivreg2, the core package
		cap ado uninstall ivreg2
		ssc install ivreg2

		* Finally, install this package
		cap ado uninstall ivreghdfe
		net install ivreghdfe, from(https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/)	
	
	}
	
	
	// create dataset to test
	use datemo lpermno rnd_to_assets rnd_misseq0_to_assets ///
		real_* xrd_F* at_F* emp_* book_debt lag_mkt_cap ret sic_compustat ///
		markup_ebitda_F0 cfprof_ratio tobinQ labor_prod* ///
		patent_* /// added feb 2020
		using "${dtapath}\crsp_merged_with_monthly_compustat", clear
	keep if ~missing(rnd_to_assets) 
	gen sic4 = sic_compustat
	gen sic3 = floor(sic4/10)
	gen sic2 = floor(sic4/100)	
	// compute average R&D intensity at the firm level
	// this average can be time varying if we distinguish more
	// than one subperiod
	gen year = year(dofm(datemo))
	gen subperiod = 1  if year>=1972 & year<=2013		
	forvalues j=2/14 { // note that 14 corresponds to last data point in 2013, which works for 3-year fwd growth rates in sample ending 2016
		replace subperiod = `j' if year>=1972+3*(`j'-1) & ~missing(subperiod) 
	}	
	sort lpermno subperiod datemo
	by lpermno subperiod: egen avg_rnd_to_assets = mean(rnd_to_assets) if ~missing(subperiod)	
	// compute total investment variables
	foreach fval in 12 24 36 48 60 72 {
		egen real_totinv_F`fval' = rowtotal(real_capx_F`fval' real_xrd_F`fval') if ~missing(at_F`fval')
	}		
	// compute forward-looking geometric growth rates
	foreach myvar in "real_capx" "real_totinv" "emp" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 
		"labor_prod" /// added february 2020	
	{
		gen gro_ann_1yr_`myvar' = 100*( (`myvar'_F24/`myvar'_F12)^(1/1) - 1 ) 
		gen gro_ann_2yr_`myvar' = 100*( (`myvar'_F36/`myvar'_F12)^(1/2) - 1 ) 
		gen gro_ann_3yr_`myvar' = 100*( (`myvar'_F48/`myvar'_F12)^(1/3) - 1 ) 
		gen gro_ann_4yr_`myvar' = 100*( (`myvar'_F60/`myvar'_F12)^(1/4) - 1 ) 
		gen gro_ann_5yr_`myvar' = 100*( (`myvar'_F72/`myvar'_F12)^(1/5) - 1 ) 		
	}	
	// keep one obs per year and merge on ivol	
	keep if month(dofm(datemo))==7 // focus on values as of june 30 in a given year
	merge m:1 year using "${dtapath}\integrated_volatility_annual", nogen keep(master match)
	merge m:1 year using "${dtapath}\resid_series_for_panel_regs_annual", nogen keep(master match) // more sophisticated ivol residuals		
	merge m:1 year using "${dtapath}\credit_spreads_ann", nogen  keep(master match) keepusing(baa10ym) // credit conditions variables
	tsset lpermno year
	// keep only sample we care about
	keep if year>=1972 & year<=2013
	// check obs count
	bysort lpermno: egen Nobs = count(at_F0)
	summ Nobs, detail	
	// pick volatility var and the compute interaction and choose the orthog z variable
	gen vol_var      = ivol
	gen interact_var = ivol*avg_rnd_to_assets // remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
	gen z_var        = epd_ivol
	// pick out dependant var based on myvar
	//local myvar = "real_totinv"
	local myvar = "real_pat_val_sm"
	//gen depvar = gro_ann_3yr_`myvar'
	//gen depvar = gro_ann_4yr_`myvar'
	gen depvar = gro_ann_5yr_`myvar'
	bysort lpermno: egen depvar_count = count(depvar)
		
	// test regressions
	if 1==0 {
	
		// implement cutoffs to make easier to run individual lines below
		//keep if Nobs>=100
		//keep if depvar_count>=10
		foreach Nobs_cutoff in 38 42 {
		  foreach min_depvar_count in 10 {

			// with baa spread
			qui ivreghdfe depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ///
				if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count' ///
				, absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				
			estimates store baa

			// with time FE and remove vol_var and z_var to avoid error message
			qui ivreghdfe depvar interact_var markup_ebitda_F0 tobinQ ///
				if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count' ///
				, absorb(lpermno year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				
			estimates store time_fe
			
				// check for serieal correlation
				//ivreghdfe depvar interact_var markup_ebitda_F0 tobinQ ///
					//, absorb(lpermno year, resid(myresid)) 
				//xtqptest myresid, lags(12)
				//xthrtest myresid, force	
				//xtistest myresid if ~missing(myresid), lags(12)
				//xtreg myresid L1.myresid L2.myresid L3.myresid L4.myresid, fe
				//xtreg myresid L1.myresid L2.myresid L3.myresid L4.myresid L5.myresid L6.myresid L7.myresid L8.myresid, fe
				//ac myresid
				//pac myresid
				//estat bgodfrey, lags(5) nomiss
				//estat durbinalt, lags(5) 
				//estat dwatson
				// conclusion: not sure how best to test
				
			
				// repeat with only robust SE 
				qui ivreghdfe depvar interact_var markup_ebitda_F0 tobinQ ///
					if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count' ///
					, absorb(lpermno year) robust bw(1) 
				estimates store tfe_rob
				
				// try different lags
				qui forvalues j=2/13 {
					ivreghdfe depvar interact_var markup_ebitda_F0 tobinQ ///
					if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count' ///
						, absorb(lpermno year) robust bw(`j') 
					estimates store tfe_bw`j'		
				}
				
			disp "Nobs_cutoff=`Nobs_cutoff'"
			disp "min_depvar_count=`min_depvar_count'"
			estimates table baa time_fe ///
				tfe_rob ///
				tfe_bw2 ///
				tfe_bw3 ///
				tfe_bw4 ///
				tfe_bw5 ///
				tfe_bw6 ///
				tfe_bw7 ///
				tfe_bw8 ///
				tfe_bw9 ///
				tfe_bw10 ///
				tfe_bw11 ///
				tfe_bw12 ///
				tfe_bw13 ///
				, se t keep(interact_var markup_ebitda_F0 tobinQ)

		  } // min_depvar_count 
		} // Nobs_cutoff 				
				
	}
		
		
	// compare against ivreg2 without time FE
		
		local Nobs_cutoff=38
		local min_depvar_count=8
			
		qui ivreg2 depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ i.lpermno ///
		  (vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ i.lpermno = ///
		   vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ i.lpermno ) ///
		   if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count' ///
		  , gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		estimates store ivreg2

		ivreghdfe depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ///
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			absorb(lpermno) 
		estimates store test1

		ivreghdfe depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ///
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		estimates store test2
		
		ivreghdfe depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ///
		  (vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ = ///
		   vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ) ///		
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			gmm2s absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		estimates store test3	
		
		estimates table ivreg2 test1 test2 test3, se keep(vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ)
		
		estimates table ivreg2 test2 test3, se keep(vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ)
		// note: SEs are similar but not the same when we use same SE options			
		
	
	// compare against ivreg2 with time FE
		
		order Nobs depvar_count lpermno year depvar vol_var interact_var z_var markup_ebitda_F0 tobinQ
		
		local Nobs_cutoff=38
		local min_depvar_count=8
			
		ivreg2 depvar vol_var interact_var z_var markup_ebitda_F0 tobinQ i.lpermno i.year ///
		  (vol_var interact_var z_var markup_ebitda_F0 tobinQ i.lpermno i.year = ///
		   vol_var interact_var z_var markup_ebitda_F0 tobinQ i.lpermno i.year ) ///
		   if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count' ///
		  , gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		estimates store ivreg2_fe
		estimates table ivreg2_fe, se keep(vol_var interact_var z_var markup_ebitda_F0 tobinQ) stat(N Fdf1 inexog_ct)

		ivreghdfe depvar vol_var interact_var z_var markup_ebitda_F0 tobinQ ///
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			absorb(lpermno year) 
		estimates store test1_fe

		ivreghdfe depvar vol_var interact_var z_var markup_ebitda_F0 tobinQ ///
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			absorb(lpermno year) robust bw(`mybwval')
		estimates store test2_fe
		// note: automatically drops vol_var and z_var b/c colinear with year FE. 
		
		ivreghdfe depvar vol_var interact_var z_var markup_ebitda_F0 tobinQ ///
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			absorb(lpermno year) robust bw(`mybwval') partial(vol_var z_var)
		estimates store test3_fe		
		
		ivreghdfe depvar vol_var interact_var z_var markup_ebitda_F0 tobinQ ///
		  (vol_var interact_var z_var markup_ebitda_F0 tobinQ = ///
		   vol_var interact_var z_var markup_ebitda_F0 tobinQ ) ///		
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			gmm2s absorb(lpermno year) robust bw(`mybwval') /// num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
			partial(vol_var z_var) // need to partial out the two macro time series b/c otherwise colinear with year FE
		estimates store test4_fe	
		
		estimates table ivreg2_fe test1_fe test2_fe test3_fe test4_fe, se keep(vol_var interact_var z_var markup_ebitda_F0 tobinQ)
		// note: SEs are similar but not the same when we use same SE options	
		// note 2: we need to be careful with specifying year FE b/c it omits macro series. use
		//         specification without gmm2s b/c that way interact_var is still the 2nd coeff estimate
		//         so our code that grabs coeff estiamtes will work
		estimates table test2_fe, se
		estimates table test3_fe, se
	
	
	// try for cases where against ivreg2 doesnt work
		
		local Nobs_cutoff=26
		local min_depvar_count=8
		
		// won't work (check if needed)
		if 1==0 {
		  qui ivreg2 depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ i.lpermno ///
		  (vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ i.lpermno = ///
		   vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ i.lpermno ) ///
		   if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count' ///
		  , gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		}
			
		ivreghdfe depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ///
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			absorb(lpermno) 
		estimates store test1_26

		ivreghdfe depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ///
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		estimates store test2_26
		
		ivreghdfe depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ///
		  (vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ = ///
		   vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ ) ///		
			if Nobs>=`Nobs_cutoff' & depvar_count>=`min_depvar_count', ///
			gmm2s absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
		estimates store test3_26	
		
		estimates table test1_26 test2_26 test3_26, se keep(vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ)
		// conclusion: ivreghdfe works in these cases!
	
}
	
	
	
	
		
/********************************************************************/
// firm-level regression analysis
// fff
	
//xsga_to_assets
//xsga_to_assets_rnd 	
	
//foreach myrndvar in "rnd_to_assets" "rnd_misseq0_to_assets" { // run both
//foreach myrndvar in "rnd_to_assets" "xsga_to_assets" { // R&D intensity plus SG&A intensity
foreach myrndvar in "rnd_to_assets" { // standard variable for measuring R&D intensity (no missing values)
//foreach myrndvar in "rnd_misseq0_to_assets" { // assume R&D=0 if missing in intensity measure
//foreach myrndvar in "xsga_to_assets" { // SG&A intensity
//foreach myrndvar in "rnd_misseq0_to_assets" { // alternative variable for measuring R&D intensity (missing values set to 0)
//foreach control_credit_cond in 1 0 { // yes==1, otherwise no. run both for draft
foreach control_credit_cond in 1 { // simple run
//foreach control_credit_cond in 0 { // simple run
//foreach port_cfprof_cont_var in "markup_ebitda_F0" "none" "cfprof_ratio"  { 
//foreach port_cfprof_cont_var in "markup_ebitda_F0" "cfprof_ratio"  { // smaller run
//foreach port_cfprof_cont_var in "markup_ebitda_F0" "none" { // smaller run
foreach port_cfprof_cont_var in "markup_ebitda_F0" { 
// profitability control options: none (no controls), markup_ebitda_F0, cfprof_ratio 
foreach new_export_sheet in 1 { 
 //foreach startyr in 1972 1975 1982 { // full run
 //foreach startyr in 1972 1975 {  
 foreach startyr in 1972 {   
  //foreach vol_var in "ivol" "epu" "expvol" { // "ivol" "epu"  
  //foreach vol_var in "ivol" "expvol" { // "ivol" "epu"  
  foreach vol_var in "ivol" { // simple run
  ///foreach vol_var in "expvol" { // try our PU measure
  //foreach vol_var in "nvix" { // try NVIX measure of manela and morreira
   //foreach Nobsmin in 10 20 25 30 35 100 {    
   //foreach Nobsmin in 30 32 34 35 36 38 40 100 {
     // 100 is full sample
	 // 30 and 35 are nice round numbers 
	 // for the period 1972-2013 (42 years):
	 // 21 is at least 50% of sample
	 // 26 is at least 60% of sample
	 // 30 is at least 70% of sample
	 // 32 is at least 75% of sample
	 // 34 is at least 80% of sample
	 // 36 is at least 85% of sample
	 // 38 is at least 90% of sample
	 // 40 is at least 95% of sample
	 // for the period 1975-2013 (39 years):
	 // 20 is at least 50% of sample
	 // 24 is at least 60% of sample
	 // 28 is at least 70% of sample
	 // 32 is at least 80% of sample
	 // 36 is at least 90% of sample
   //foreach Nobsmin in 16 20 21 23 24 26 29 30 32 34 36 38 100 { // full set from 1972 or 1975 or 1982
   //foreach Nobsmin in 20 21 24 26 29 30 32 34 36 38 100 { // full set from 1972 or 1975
   foreach Nobsmin in 21 26 30 34 38 100 { // full set from 1972 only
   //foreach Nobsmin in 30 34 38 100 { // 
   //foreach Nobsmin in 34 38 100 {      
   //foreach Nobsmin in 38 100 {      
   //foreach Nobsmin in 100 {  
    display "$S_TIME  $S_DATE"
    disp "Running "
	disp "   myrndvar `myrndvar'"
	disp "   control_credit_cond `control_credit_cond'"
	disp "   port_cfprof_cont_var `port_cfprof_cont_var'"
	disp "   startyr `startyr'"	
	disp "   vol_var `vol_var'"
	disp "   Nobsmin `Nobsmin'"
	disp "   ..."   
   
    //qui foreach min_depvar_count in 5 10 15 20 25 { // at least min_depvar_count years of non-missing depvar
	//qui foreach min_depvar_count in 10 15 20 { // smaller run
	qui foreach min_depvar_count in 10 { // single run
    
	// set bw_val to desired number of hag lags plus 1 (i.e, 1 lag = bw(2))
	//local mybwval = 5 // standard before feb 2020
	local mybwval = 2 // try only one lag
	
	// winsorize or not
	//local winsorize_switch=0 // ==0 --> no winsorization
	local winsorize_switch=1 // ==1 --> yes winsorize explanatory and dependent vars

	// interact R&D intensity with credit spreads		
	//local interact_credit_cond_rndvar = 0 // no interaction term (baseline)
	//local interact_credit_cond_rndvar = 1 // yes add interact term between baa and avgrnd
	//local interact_credit_cond_rndvar = 2 // yes add interact term between baa and rnd intensity median dummy
	//local interact_credit_cond_rndvar = 3 // yes add interact term between zt and avgrnd
	local interact_credit_cond_rndvar = 4 // yes add interact term between zt and rnd intensity median dummy
	
//local new_export_sheet = 1	
//local port_cfprof_cont_var = "markup_ebitda_F0"	
//local myrndvar = "rnd_misseq0_to_assets"	
//local control_credit_cond = 0
//local startyr = 1972   
//local vol_var = "ivol"
//local Nobsmin = 34 // 100 38 34
//local min_depvar_count = 20 // 100 38 34
//local mybwval = 2 // try only one lag
//local winsorize_switch=1

//local new_export_sheet = 1	
//local port_cfprof_cont_var = "markup_ebitda_F0"
//local myrndvar = "rnd_to_assets"	
//local control_credit_cond = 1
//local startyr = 1972   
//local vol_var = "ivol"
//local vol_var = "expvol"
//local Nobsmin = 34 // 100 38 34
//local min_depvar_count = 10 // 
//local mybwval = 2 // try only one lag
//local winsorize_switch=1
  
	set more off
  
	use datemo lpermno rnd_to_assets rnd_misseq0_to_assets /// 
		real_* xrd_F* at_F* emp_* book_debt lag_mkt_cap ret sic_compustat ///
		markup_ebitda_F0 cfprof_ratio tobinQ* labor_prod* ///
		patent_* /// added feb 2020
		tfp_* /// added feb 2020
		xsga_to_assets  xsga_to_assets_rnd /// 
		using "${dtapath}\crsp_merged_with_monthly_compustat", clear
		
	//keep if ~missing(rnd_to_assets)
	keep if ~missing(`myrndvar') // depends on whether want to count missing R&D as zero
	gen sic4 = sic_compustat
	gen sic3 = floor(sic4/10)
	gen sic2 = floor(sic4/100)
	
	// compute unlevered excess returns
	gen quasimkt_lvg = book_debt / (book_debt + lag_mkt_cap*(10^3)) // put mkt_cap in millions
	gen ret_unlev = 100*(1-quasimkt_lvg)*ret
	merge m:1 datemo using "${dtapath}\famafrench_monthly_factors", nogen keepusing(rf) keep(master match)
	gen ex_ret_unlev = ret_unlev-rf
	
	// compute average R&D intensity at the firm level
	// this average can be time varying if we distinguish more
	// than one subperiod
	gen year = year(dofm(datemo))
	gen subperiod = 1  if year>=`startyr' & year<=2013	
	replace subperiod = . if year<`startyr' | year>2013
	// note: keep 2013 as last year because we require at least 3 years ahead of data
		
		// try two subperiods
		//replace subperiod = 2 if year>=1993 & ~missing(subperiod) // divide in half
		
		// try 3-year subperiods
		if `startyr'==1972 {
			forvalues j=2/14 { // note that 14 corresponds to last data point in 2013, which works for 3-year fwd growth rates in sample ending 2016
				replace subperiod = `j' if year>=1972+3*(`j'-1) & ~missing(subperiod) 
			}
		}
		if `startyr'==1975 {
			forvalues j=2/13 { // note that 13 corresponds to last data point in 2013, which works for 3-year fwd growth rates in sample ending 2016
				replace subperiod = `j' if year>=1975+3*(`j'-1) & ~missing(subperiod) 
			}
		}		
		if `startyr'==1982 {
			forvalues j=2/11 { // note that 11 corresponds to last data point in 2014, which is one year after sample. as a result last subperiod (11) only has 2 years
				replace subperiod = `j' if year>=1982+3*(`j'-1) & ~missing(subperiod) 
			}
		}		
		//keep year subperiod
		//duplicates drop		
		//br
				
	sort lpermno subperiod datemo
	//by lpermno subperiod: egen avg_rnd_to_assets = mean(rnd_to_assets) if ~missing(subperiod)	
	by lpermno subperiod: egen avg_rnd_to_assets = mean(`myrndvar') if ~missing(subperiod) // can use diff rnd intensity measures
	
	save "${dtapath}\temp_data_for_regs", replace	
	
	// run annual var regressions
	use "${dtapath}\temp_data_for_regs", clear
	
	// compute total investment variables
	foreach fval in 12 24 36 48 60 72 {
		egen real_totinv_F`fval' = rowtotal(real_capx_F`fval' real_xrd_F`fval') if ~missing(at_F`fval')
	}		
	
	// note: patent-related vars are missing when zero
	
	// compute forward-looking geometric growth rates
	foreach myvar in "real_capx" "real_totinv" "emp" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 
		"labor_prod" /// added february 2020	
		"real_at" /// added february 2020	
		"real_mkt_at" /// added february 2020	
		"tobinQ" /// added february 2020	
	{

		gen gro_1yr_`myvar' = 100*( (`myvar'_F24/`myvar'_F12) - 1 ) 
		gen gro_2yr_`myvar' = 100*( (`myvar'_F36/`myvar'_F12) - 1 ) 
		gen gro_3yr_`myvar' = 100*( (`myvar'_F48/`myvar'_F12) - 1 ) 
		gen gro_4yr_`myvar' = 100*( (`myvar'_F60/`myvar'_F12) - 1 ) 
		gen gro_5yr_`myvar' = 100*( (`myvar'_F72/`myvar'_F12) - 1 ) 	
		
		gen gro_ann_1yr_`myvar' = 100*( (`myvar'_F24/`myvar'_F12)^(1/1) - 1 ) 
		gen gro_ann_2yr_`myvar' = 100*( (`myvar'_F36/`myvar'_F12)^(1/2) - 1 ) 
		gen gro_ann_3yr_`myvar' = 100*( (`myvar'_F48/`myvar'_F12)^(1/3) - 1 ) 
		gen gro_ann_4yr_`myvar' = 100*( (`myvar'_F60/`myvar'_F12)^(1/4) - 1 ) 
		gen gro_ann_5yr_`myvar' = 100*( (`myvar'_F72/`myvar'_F12)^(1/5) - 1 ) 
		
	}	
	
	// compute forward-looking differences using different methods
	foreach myvar in "rnd_to_assets" {	
		
		// difference in the ratio of R&D to assets		
		gen diff_rat_1yr_`myvar' = 100*(xrd_F24/at_F24 - xrd_F12/at_F12) 
		gen diff_rat_2yr_`myvar' = 100*(xrd_F36/at_F36 - xrd_F12/at_F12) 
		gen diff_rat_3yr_`myvar' = 100*(xrd_F48/at_F48 - xrd_F12/at_F12) 
		gen diff_rat_4yr_`myvar' = 100*(xrd_F60/at_F60 - xrd_F12/at_F12)  if datemo<=ym(2012,12)						 
		gen diff_rat_5yr_`myvar' = 100*(xrd_F72/at_F72 - xrd_F12/at_F12)  if datemo<=ym(2011,12)		
		//gen diff_rat_1yr_`myvar' = 100*(xrd_F24/at_F24 - xrd_F12/at_F12)/1
		//gen diff_rat_2yr_`myvar' = 100*(xrd_F36/at_F36 - xrd_F12/at_F12)/2 
		//gen diff_rat_3yr_`myvar' = 100*(xrd_F48/at_F48 - xrd_F12/at_F12)/3 
		//gen diff_rat_4yr_`myvar' = 100*(xrd_F60/at_F60 - xrd_F12/at_F12)/4 if datemo<=ym(2012,12)						 
		//gen diff_rat_5yr_`myvar' = 100*(xrd_F72/at_F72 - xrd_F12/at_F12)/5 if datemo<=ym(2011,12)		
		
		// difference in R&D over average assets
		//gen diff_xrd_1yr_`myvar' = 100*(xrd_F24-xrd_F12)/((at_F24+at_F12)/2)
		//gen diff_xrd_2yr_`myvar' = 100*(xrd_F36-xrd_F12)/((at_F36+at_F12)/2)
		//gen diff_xrd_3yr_`myvar' = 100*(xrd_F48-xrd_F12)/((at_F48+at_F12)/2)			
		//gen diff_xrd_4yr_`myvar' = 100*(xrd_F60-xrd_F12)/((at_F60+at_F12)/2) if datemo<=ym(2012,12)						 
		//gen diff_xrd_5yr_`myvar' = 100*(xrd_F72-xrd_F12)/((at_F72+at_F12)/2) if datemo<=ym(2011,12)								

	}
	
	// compute forward-looking differences using different intensity measure
	foreach myvar in "rnd_misseq0_to_assets" {	
		
		// copy same difference when allowing missing valuse
		gen diff_rat_1yr_rndassmiss = diff_rat_1yr_rnd_to_assets
		gen diff_rat_2yr_rndassmiss = diff_rat_2yr_rnd_to_assets
		gen diff_rat_3yr_rndassmiss = diff_rat_3yr_rnd_to_assets
		gen diff_rat_4yr_rndassmiss = diff_rat_4yr_rnd_to_assets
		gen diff_rat_5yr_rndassmiss = diff_rat_5yr_rnd_to_assets
		
		// replace missing with zero when assets are non-missing (i.e., assume missing xrd==0)
		replace diff_rat_1yr_rndassmiss = 0 if missing(diff_rat_1yr_rndassmiss) & ~missing(at_F12) & ~missing(at_F24)
		replace diff_rat_2yr_rndassmiss = 0 if missing(diff_rat_2yr_rndassmiss) & ~missing(at_F12) & ~missing(at_F36)
		replace diff_rat_3yr_rndassmiss = 0 if missing(diff_rat_3yr_rndassmiss) & ~missing(at_F12) & ~missing(at_F48)
		replace diff_rat_4yr_rndassmiss = 0 if missing(diff_rat_4yr_rndassmiss) & ~missing(at_F12) & ~missing(at_F60) & datemo<=ym(2012,12)	
		replace diff_rat_5yr_rndassmiss = 0 if missing(diff_rat_5yr_rndassmiss) & ~missing(at_F12) & ~missing(at_F72) & datemo<=ym(2011,12)		
	}	
	

	// compute forward-looking change in log variable
	foreach myvar in ///
		"tfp_it2014" /// added february 2020	
	{

		gen dlog_ann_1yr_`myvar' = 100*(`myvar'_F24 - `myvar'_F12)/1
		gen dlog_ann_2yr_`myvar' = 100*(`myvar'_F36 - `myvar'_F12)/2		
		gen dlog_ann_3yr_`myvar' = 100*(`myvar'_F48 - `myvar'_F12)/3
		gen dlog_ann_4yr_`myvar' = 100*(`myvar'_F60 - `myvar'_F12)/4
		gen dlog_ann_5yr_`myvar' = 100*(`myvar'_F72 - `myvar'_F12)/5
				
	}		
	
	// keep one obs per year and merge on ivol	
	keep if month(dofm(datemo))==7 // focus on values as of june 30 in a given year
	merge m:1 year using "${dtapath}\integrated_volatility_annual", nogen keep(master match)
	merge m:1 year using "${dtapath}\resid_series_for_panel_regs_annual", nogen keep(master match) // more sophisticated ivol residuals		
	if `control_credit_cond'==1 {
		merge m:1 year using "${dtapath}\credit_spreads_ann", nogen  keep(master match) keepusing(baa10ym) // credit conditions variables
	}	
	tsset lpermno year
	
	// keep only sample we care about
	keep if year>=1972 & year<=2013
	// note: keep 2013 as last year because we require at least 3 years ahead of data
	keep if year>=`startyr'
	
	// check obs count
	bysort lpermno: egen Nobs = count(at_F0)
	summ Nobs, detail	
	local Nobs_max = r(max)
	// take into account if less obs available than choice for Nobsmin
	if `Nobsmin' > `Nobs_max' {
		local Nobs_cutoff = `Nobs_max'
	}
	else {
		local Nobs_cutoff = `Nobsmin'	
	}
	//disp `Nobs_cutoff'
	keep if Nobs>=`Nobs_cutoff'
	
		// check the averages when using the full sample R&D average
		if 1==0 {
			keep if ~missing(subperiod)
			keep lpermno avg_rnd_to_assets
			duplicates drop
			egen p80_avg_rnd_to_assets = pctile(avg_rnd_to_assets), p(80)
			egen p20_avg_rnd_to_assets = pctile(avg_rnd_to_assets), p(20)
			gen avg_rnd_to_assets_top80 = avg_rnd_to_assets if avg_rnd_to_assets>=p80_avg_rnd_to_assets
			gen avg_rnd_to_assets_top20 = avg_rnd_to_assets if avg_rnd_to_assets<=p20_avg_rnd_to_assets
			collapse (mean) avg_rnd_to_assets avg_rnd_to_assets_top20 avg_rnd_to_assets_top80
			br
		}		

		// check the averages when using averages for different subperiods 
		if 1==0 {
			keep if ~missing(subperiod)
			keep lpermno avg_rnd_to_assets subperiod
			duplicates drop
			bysort subperiod: egen p80_avg_rnd_to_assets = pctile(avg_rnd_to_assets), p(80)
			bysort subperiod: egen p20_avg_rnd_to_assets = pctile(avg_rnd_to_assets), p(20)
			gen avg_rnd_to_assets_top80 = avg_rnd_to_assets if avg_rnd_to_assets>=p80_avg_rnd_to_assets
			gen avg_rnd_to_assets_top20 = avg_rnd_to_assets if avg_rnd_to_assets<=p20_avg_rnd_to_assets
			collapse (mean) avg_rnd_to_assets avg_rnd_to_assets_top20 avg_rnd_to_assets_top80, by(subperiod)
			collapse (mean) avg_rnd_to_assets avg_rnd_to_assets_top20 avg_rnd_to_assets_top80
			br
		}				
		
	// average R&D intensity at the firm level already computed above
	//bysort lpermno: egen avg_rnd_to_assets = mean(rnd_to_assets)	
	
		// check time series of percentiles of average
		if 1==0 {
			summ avg_rnd_to_assets if year==1990, detail
			summ avg_rnd_to_assets if year==2000, detail
			summ avg_rnd_to_assets if year==2010, detail
			// 10%     .0029607
			// 10%     .00153
			// 10%     .0021039
		}
	

	// potentially winsorize the explanatory and dependent variables
	if `winsorize_switch'==1 {
		foreach mywinvar in "avg_rnd_to_assets" "`port_cfprof_cont_var'" "tobinQ" {		
			qui summ `mywinvar', detail
			replace `mywinvar' =  `r(p1)' if `mywinvar'< `r(p1)' & ~missing(`mywinvar')
			replace `mywinvar' = `r(p99)' if `mywinvar'>`r(p99)' & ~missing(`mywinvar')		
		}
	}
	
	// pick volatility var and the compute interaction and choose the orthog z variable
	if "`vol_var'"== "ivol" {
		gen vol_var      = ivol
		gen interact_var = ivol*avg_rnd_to_assets // remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
		gen z_var        = epd_ivol
	}
	else if "`vol_var'"== "epu" {
		gen vol_var      = epu
		gen interact_var = epu*avg_rnd_to_assets // remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
		gen z_var        = epd_epu		
	}
	else if "`vol_var'"== "expvol" {
		gen vol_var      = expvol
		gen interact_var = expvol*avg_rnd_to_assets // remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
		gen z_var        = epd_expvol	
	}		
	else if "`vol_var'"== "nvix" {
		gen vol_var      = nvix
		gen interact_var = nvix*avg_rnd_to_assets // remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
		gen z_var        = epd_nvix	
	}	
	else {
		disp("vol_var not recognized")
		error
	}		

	// add interaction term between firm-level R&D intesnity and Baa corporate spreads
	// remember avg_rnd_to_assets can use diff rnd intensity measures, depends on myrndvar
	if "`interact_credit_cond_rndvar'"=="1" & "`control_credit_cond'"=="1" {
		gen interact_var_cc = baa10ym*avg_rnd_to_assets 
	}
	if "`interact_credit_cond_rndvar'"=="2" & "`control_credit_cond'"=="1" {
		bysort datemo: egen medvalue = pctile(avg_rnd_to_assets), p(50)
		gen med_dummy = avg_rnd_to_assets>medvalue if ~missing(medvalue) & ~missing(avg_rnd_to_assets)
		gen interact_var_cc = baa10ym*med_dummy 
	}	
	if "`interact_credit_cond_rndvar'"=="3" {
		gen interact_var_cc = z_var*avg_rnd_to_assets 
	}	
	if "`interact_credit_cond_rndvar'"=="4" {
		bysort datemo: egen medvalue = pctile(avg_rnd_to_assets), p(50)
		gen med_dummy = avg_rnd_to_assets>medvalue if ~missing(medvalue) & ~missing(avg_rnd_to_assets)
		gen interact_var_cc = z_var*med_dummy 
	}		
	
	// create empty vars to hold regression output
	foreach myvar in "real_capx" "real_totinv" "emp" "rnd_to_assets" ///
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 
		"labor_prod" /// added february 2020	
		"tfp_it2014" /// added february 2020	
		"rndassmiss" /// added february 2020. rnd_to_assets assuming missing rnd==0
		"real_at" /// added february 2020	
		"real_mkt_at" /// added february 2020
		"tobinQ" /// added february 2020
	{	
		gen reg_beta_ivol_`myvar' = .
		gen reg_beta_inter_`myvar' = .		
		gen reg_beta_e_pd_`myvar'  = .
		gen reg_se_ivol_`myvar' = .
		gen reg_se_inter_`myvar' = .		
		gen reg_se_e_pd_`myvar'    = .
		gen reg_t_ivol_`myvar' = .
		gen reg_t_inter_`myvar' = .		
		gen reg_t_e_pd_`myvar'     = .
		gen reg_Nobs_`myvar' = .
		gen reg_Nfirms_`myvar' = .
		gen reg_wald_fval_`myvar' = .
		gen reg_wald_pval_`myvar' = .
		gen reg_r2_full_`myvar' = .
		gen reg_r2_drop1_`myvar'  = .
		gen reg_r2_drop2_`myvar'  = .
		if "`control_credit_cond'"=="1" {
			gen reg_beta_cc_`myvar' = .
			gen reg_se_cc_`myvar' = .
			gen reg_t_cc_`myvar' = .		
		}		
	}		
	
	// run example regression
	local myyear = 3		
	local myvar = "real_totinv"
	gen depvar = gro_ann_`myyear'yr_`myvar'
	//ivreg2 depvar vol_var interact_var z_var i.lpermno, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
	//ivreg2 depvar vol_var interact_var z_var baa10ym i.lpermno, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)		
	//ivreg2 depvar vol_var interact_var z_var i.lpermno i.year, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
	// markup_ebitda_F0 cfprof_ratio 
	//ivreg2 depvar vol_var interact_var z_var baa10ym markup_ebitda_F0 tobinQ i.lpermno, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
	drop depvar
	
	// double check relative appearances of potential dependant variables
	if 1==0 {
	  foreach myvar in "real_totinv" "real_capx" "emp" /// "rnd_to_assets" 
		"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 
		"labor_prod" /// added february 2020
		"tfp_it2014" /// added february 2020	
		"rndassmiss" /// added february 2020. rnd_to_assets assuming missing rnd==0
		"real_mkt_at" /// added february 2020
		"tobinQ" /// added february 2020		
	  {	
		qui bysort lpermno: egen cnt_`myvar' = count(gro_ann_5yr_`myvar')
	    disp "`myvar'"
	    summ cnt_`myvar' if ~missing(vol_var) & ~missing(interact_var) & ~missing(z_var)
		qui drop cnt_`myvar'
	  }
	  // conclusion: patent vars (values and counts) often have at least
	  //             one firm with only 0 or 1 non-missing value
	  //             and therefore we need to add a condition in 
	  //             the regressions to drop firms without sufficient data
	}
	
	
	// run annual regressions
	foreach myyear in 3 4 5 { // 1 2 
	  //foreach myvar in "real_totinv" {	   
	  foreach myvar in "real_totinv" "rnd_to_assets" ///
		/// "real_capx" "emp" ///
	    ///"patent_grants" "real_pat_val_sm" "tobinQ" /// main ones from feb 2020
		///"real_revt" "real_xsga" "real_ocf" /// added february 2020
		"tobinQ" "real_xsga" ///
		"real_pat_val_cw" "real_pat_val_sm" /// added february 2020
		"patent_grants" "patent_apps" /// added february 2020 
		"labor_prod" /// added february 2020	
		"tfp_it2014" /// added february 2020	
		///"rndassmiss" /// added february 2020. rnd_to_assets assuming missing rnd==0
		///"real_at" /// added february 2020
		///"real_mkt_at" /// added february 2020
		///"tobinQ" /// added february 2020		
	  {
		disp "`myvar' `myyear'yr..."				  

//local myyear = 3		
//local myvar = "real_totinv"
		
			// pick out dependant var based on myvar
			//if "`myvar'"=="rnd_to_assets" {
			if "`myvar'"=="rnd_to_assets" | "`myvar'"=="rndassmiss" {
				gen depvar = diff_rat_`myyear'yr_`myvar' // change in rnd to assets ratio
				//gen depvar = diff_xrd_`myyear'yr_`myvar' // change in xrd divided by avg assets
			}
			else if "`myvar'"=="tfp_it2014" {
				gen depvar = dlog_ann_`myyear'yr_`myvar' // approx ann. pct change b/c diff in var that is in log units
			}
			else {
				//gen depvar = gro_`myyear'yr_`myvar'
				gen depvar = gro_ann_`myyear'yr_`myvar'
			}			
		
			// potentially winsorize the explanatory and dependent variables
			if `winsorize_switch'==1 {
				foreach mywinvar in "depvar" {
					qui summ `mywinvar', detail
					replace `mywinvar' =  `r(p1)' if `mywinvar'< `r(p1)' & ~missing(`mywinvar')
					replace `mywinvar' = `r(p99)' if `mywinvar'>`r(p99)' & ~missing(`mywinvar')		
				}
			}
		
			// because of new patent vars, need to check that depvar is nonmissing
			// enough for estimation not to break
			bysort lpermno: egen depvar_count = count(depvar)
			//local min_depvar_count = 8 // at least min_depvar_count years of non-missing depvar
		
			// run main regression specification
			//xtreg depvar vol_var interact_ivol_rnd epd_ivol, fe vce(cluster sic2)
			//areg depvar vol_var interact_var z_var, absorb(lpermno) vce(cluster sic2)	
			areg depvar vol_var interact_var z_var ///
				if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				, absorb(lpermno) vce(cluster sic2)	
			local reg_Nfirm = e(k_absorb) // get number of firms from areg
			//qui ivreg2 depvar vol_var interact_var z_var i.lpermno, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
			// The bw(#) option sets the bandwidth used in the estimation and kernel(string) 
			// is the kernel used; the default kernel is the Bartlett kernel also known in
			// econometrics as Newey-West (see help newey).
			// note: run with GMM option even though it gives same answer
			//qui ivreg2 depvar vol_var interact_var z_var i.lpermno (vol_var interact_var z_var i.lpermno = vol_var interact_var z_var i.lpermno), gmm2s robust bw(`mybwval') 
			
			// run main regression specification with or without control for credit conditions
			if `control_credit_cond'==1 {
			  if "`port_cfprof_cont_var'"=="none" {
				//qui ivreg2 depvar vol_var interact_var z_var baa10ym i.lpermno ///
				  //(vol_var interact_var z_var baa10ym i.lpermno = ///
				   //vol_var interact_var z_var baa10ym i.lpermno ) ///
				   //if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  //, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				// don't bother with gmm2s option b/c makes code longer and
				// gives same estimate. we can still claim GMM
				qui ivreghdfe depvar vol_var interact_var z_var baa10ym ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
			  }
			  else {
				//qui ivreg2 depvar vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.lpermno ///
				  //(vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.lpermno = ///
				   //vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.lpermno ) ///
				   //if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  //, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)		
				// don't bother with gmm2s option b/c makes code longer and
				// gives same estimate. we can still claim GMM				  
				if "`interact_credit_cond_rndvar'"=="1" | "`interact_credit_cond_rndvar'"=="2" | "`interact_credit_cond_rndvar'"=="3" | "`interact_credit_cond_rndvar'"=="4" {
				  qui ivreghdfe depvar vol_var interact_var z_var baa10ym interact_var_cc `port_cfprof_cont_var' tobinQ ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				}				
				else {
				  qui ivreghdfe depvar vol_var interact_var z_var baa10ym `port_cfprof_cont_var' tobinQ ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
				}
			  }			  
			}
			else {
			  if "`port_cfprof_cont_var'"=="none" {						
				//qui ivreg2 depvar vol_var interact_var z_var i.lpermno i.year ///
				  //(vol_var interact_var z_var i.lpermno i.year = ///
				   //vol_var interact_var z_var i.lpermno i.year) ///
				   //if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  //, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)		
				// don't bother with gmm2s option b/c makes code longer and
				// gives same estimate. we can still claim GMM				  				  
				qui ivreghdfe depvar vol_var interact_var z_var ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(lpermno year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)					  
			  }
			  else {
				//qui ivreg2 depvar vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.lpermno i.year ///
				  //(vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.lpermno i.year = ///
				   //vol_var interact_var z_var `port_cfprof_cont_var' tobinQ i.lpermno i.year) ///
				   //if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  //, gmm2s robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				qui ivreghdfe depvar vol_var interact_var z_var `port_cfprof_cont_var' tobinQ ///
				   if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
				  , absorb(lpermno year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
			  }
			}
			
			
			// save results
			matrix b = e(b)
			matrix V = e(V)
			local reg_beta_ivol  = b[1,1]
			local reg_beta_inter = b[1,2]
			local reg_beta_e_pd  = b[1,3]
			local reg_se_ivol    = sqrt(V[1,1])
			local reg_se_inter   = sqrt(V[2,2])
			local reg_se_e_pd    = sqrt(V[3,3])
			local reg_t_ivol     = b[1,1] / sqrt(V[1,1])
			local reg_t_inter    = b[1,2] / sqrt(V[2,2])	
			local reg_t_e_pd     = b[1,3] / sqrt(V[3,3])
			local reg_Nobs = e(N)
			//local reg_Nfirm = e(N_g) // for xtreg
			//local reg_Nfirm = e(k_absorb) // for areg
			local reg_r2_full = e(r2)
			replace reg_beta_ivol_`myvar'     = `reg_beta_ivol'     if _n==`myyear'
			replace reg_beta_inter_`myvar'    = `reg_beta_inter'    if _n==`myyear'
			replace reg_beta_e_pd_`myvar'     = `reg_beta_e_pd'     if _n==`myyear'	
			replace reg_se_ivol_`myvar'       = `reg_se_ivol'       if _n==`myyear'
			replace reg_se_inter_`myvar'      = `reg_se_inter'      if _n==`myyear'
			replace reg_se_e_pd_`myvar'       = `reg_se_e_pd'       if _n==`myyear'	
			replace reg_t_ivol_`myvar'        = `reg_t_ivol'        if _n==`myyear'
			replace reg_t_inter_`myvar'       = `reg_t_inter'       if _n==`myyear'
			replace reg_t_e_pd_`myvar'        = `reg_t_e_pd'        if _n==`myyear'	
			replace reg_Nobs_`myvar'    	  = `reg_Nobs'          if _n==`myyear'				
			replace reg_Nfirms_`myvar'    	  = `reg_Nfirm'         if _n==`myyear'				
			replace reg_r2_full_`myvar' = `reg_r2_full' if _n==`myyear'	
			if `control_credit_cond'==1 {
				local reg_beta_cc  = b[1,4] 
				local reg_se_cc    = sqrt(V[4,4]) 
				local reg_t_cc     = b[1,4] / sqrt(V[4,4])			
				replace reg_beta_cc_`myvar' = `reg_beta_cc' if _n==`myyear'
				replace reg_se_cc_`myvar' = `reg_se_cc'     if _n==`myyear'
				replace reg_t_cc_`myvar' = `reg_t_cc'	    if _n==`myyear'	
			}	
			
			// wald test stats
			
				// joint test that betas for both ivol and interaction term are zero
				test vol_var interact_var
				replace reg_wald_fval_`myvar' = r(F) if _n==`myyear' // ivreghdfe produces F instead of chi2
				//replace reg_wald_fval_`myvar' = r(chi2) if _n==`myyear' // chi2 from ivreg2 but cannot use ivreg2 for firmlevel									
				replace reg_wald_pval_`myvar' = r(p) if _n==`myyear'	
				
				// alternatively can acumulate individual tests
				//test vol_var=0
				//test interact_var=0, accum
			
			// re-run regression without certain terms and save r2
				
				//areg depvar vol_var z_var, absorb(lpermno) vce(cluster sic2)	
				//qui ivreg2 depvar vol_var z_var i.lpermno, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				if `control_credit_cond'==1 {
				  if "`port_cfprof_cont_var'"=="none" {
					//qui ivreg2 depvar vol_var z_var baa10ym i.lpermno ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					qui ivreghdfe depvar vol_var z_var baa10ym ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				  }
				  else {
					//qui ivreg2 depvar vol_var z_var baa10ym `port_cfprof_cont_var' tobinQ i.lpermno ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)	
					if "`interact_credit_cond_rndvar'"=="1" | "`interact_credit_cond_rndvar'"=="2" | "`interact_credit_cond_rndvar'"=="3" | "`interact_credit_cond_rndvar'"=="4" {
					  qui ivreghdfe depvar vol_var z_var baa10ym interact_var_cc `port_cfprof_cont_var' tobinQ ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)											
					}
					else {
					  qui ivreghdfe depvar vol_var z_var baa10ym `port_cfprof_cont_var' tobinQ ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
					}
				  }
				}
				else {
				  if "`port_cfprof_cont_var'"=="none" {
					//qui ivreg2 depvar vol_var z_var i.lpermno i.year ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
					qui ivreghdfe depvar vol_var z_var  ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				  }
				  else {
				    //qui ivreg2 depvar vol_var z_var `port_cfprof_cont_var' tobinQ  i.lpermno i.year ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)												
				    qui ivreghdfe depvar vol_var z_var `port_cfprof_cont_var' tobinQ  ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  						
				  }
				}
				local reg_r2_drop1 = e(r2)
				replace reg_r2_drop1_`myvar' = `reg_r2_drop1' if _n==`myyear'
					
				//areg depvar z_var, absorb(lpermno) vce(cluster sic2)	
				//qui ivreg2 depvar z_var i.lpermno, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)
				if `control_credit_cond'==1 {
				  if "`port_cfprof_cont_var'"=="none" {
					//qui ivreg2 depvar z_var baa10ym i.lpermno ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)		
					qui ivreghdfe depvar z_var baa10ym ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)							
				  }
				  else {
					//qui ivreg2 depvar z_var baa10ym `port_cfprof_cont_var' tobinQ i.lpermno ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
					qui ivreghdfe depvar z_var baa10ym `port_cfprof_cont_var' tobinQ ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)								
				  }
				}
				else {
				  if "`port_cfprof_cont_var'"=="none" {
					//qui ivreg2 depvar z_var i.lpermno i.year ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
					qui ivreghdfe depvar z_var ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)						
				  }
				  else {
				    //qui ivreg2 depvar z_var `port_cfprof_cont_var' tobinQ i.lpermno i.year ///
						//if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						//, robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)				  
				    qui ivreghdfe depvar z_var `port_cfprof_cont_var' tobinQ ///
						if depvar_count>=`min_depvar_count' /// added feb 2020 to handle patent vars that are often missing
						, absorb(lpermno year) robust bw(`mybwval') // num lags = mybwval-1 (e.g., mybwval==2 --> 1 lag)							
				  }
				}				
				local reg_r2_drop2 = e(r2)		
				replace reg_r2_drop2_`myvar' = `reg_r2_drop2' if _n==`myyear'
			
			// clean up
			drop depvar depvar_count
	  }
	}
	
	// save out the dataset
	keep if _n<=5	
	gen N_years_fwd = _n
	keep N_years_fwd reg_*	
	gen startyr=`startyr'
	gen vol_var="`vol_var'"
	gen Nobsmin=`Nobsmin'
	gen min_depvar_count = `min_depvar_count'
	tostring N_years_fwd, gen(temp_str)
	//gen vlookup_var = "`startyr'"+"-"+vol_var+"-"+"`Nobsmin'"+"-"+temp_str
	gen vlookup_var = "`startyr'"+"-"+vol_var+"-"+"`Nobsmin'"+"-"+"`min_depvar_count'"+"-"+temp_str
	gen port_cfprof_cont_var = "`port_cfprof_cont_var'"
	gen control_credit_cond = "`control_credit_cond'"
	drop temp_str
	order vlookup_var startyr vol_var Nobsmin min_depvar_count N_years_fwd port_cfprof_cont_var control_credit_cond
	save "${dtapath}\temp_results_panel_regs", replace
	
	// save out the compile dataset	
	if `new_export_sheet'==1 {
		use "${dtapath}\temp_results_panel_regs", clear
		save "${dtapath}\results_panel_regs", replace
		local new_export_sheet=0
	}
	else {
		foreach myLHSvartype in "realvar" { // "retvar" not run anymore
			use "${dtapath}\temp_results_panel_regs", clear
			append using "${dtapath}\results_panel_regs"
			save "${dtapath}\results_panel_regs", replace
		}	
	}
	


	} // min_depvar_count
   } // Nobsmin
  } // vol_var 
 } // startyr 
 
  
 // export regression results into workbook
 if "`myrndvar'"=="rnd_misseq0_to_assets" { // special case where we use diff rnd intensity measure
	 use "${dtapath}\results_panel_regs", clear
	 export excel using "${outPath}\tables_for_paper.xlsx", ///
		firstrow(var) sheet("firmreg_rnd0_`port_cfprof_cont_var'_`control_credit_cond'") sheetreplace
 }
 else if "`myrndvar'"=="xsga_to_assets" { // SG&A/Assets as intensity measure
	 use "${dtapath}\results_panel_regs", clear
	 //local port_cfprof_cont_var = "markup_ebitda_F0"
	 //local control_credit_cond = "1"
	 export excel using "${outPath}\tables_for_paper.xlsx", ///
		firstrow(var) sheet("firmreg_sga1_`port_cfprof_cont_var'_`control_credit_cond'") sheetreplace 
 }
 else if "`myrndvar'"=="xsga_to_assets_rnd" { // SG&A/Assets as intensity measure only when non-missing rnd_to_assets
	 use "${dtapath}\results_panel_regs", clear
	 export excel using "${outPath}\tables_for_paper.xlsx", ///
		firstrow(var) sheet("firmreg_sga2_`port_cfprof_cont_var'_`control_credit_cond'") sheetreplace 
 } 
 else {
	 use "${dtapath}\results_panel_regs", clear
	 if "`interact_credit_cond_rndvar'"=="1" {
		 export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("outreg_rnd_`control_credit_cond'_interact_var_cc") sheetreplace	 
	 }
	 else if "`interact_credit_cond_rndvar'"=="2" {
		 export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("outreg_rnd_`control_credit_cond'_inter_rndmeddum") sheetreplace	 
	 }	 
	 else if "`interact_credit_cond_rndvar'"=="3" {
		 export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("outreg_rnd_`control_credit_cond'_intz_avgrnd") sheetreplace	 
	 }
	 else if "`interact_credit_cond_rndvar'"=="4" {
		 export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("outreg_rnd_`control_credit_cond'_intz_rndmeddum") sheetreplace	 
	 }	 	 
	 else {
		 export excel using "${outPath}\tables_for_paper.xlsx", ///
			firstrow(var) sheet("firmreg_`port_cfprof_cont_var'_`control_credit_cond'") sheetreplace
	 
	 }		
 }
 
} // new_export_sheet 
} // port_cfprof_cont_var loop
} // control_credit_cond loop
} // myrndvar loop



//xsga_to_assets
//xsga_to_assets_rnd 
