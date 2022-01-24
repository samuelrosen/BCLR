// import all of the raw datasets downloaded from FRED, WRDS, or other sources
// into Stata format for use in other programs within this directory

	set more off

	/*change to project directory (exact file path differs by user)*/
	cd "C:\Users\tuk40836\Dropbox\Research\BCLR\1_SafeCapital"
	
	/*path where analysis specific intermediate or final datasets are saved*/
	global rawPath = "Empirical_Analysis\raw"
	global dtapath = "Empirical_Analysis\dta"
	
	
/*********************************************************************************************/	
// treasury yields

	// downloaded from https://www.federalreserve.gov/pubs/feds/2006/200628/200628abs.html
	import excel "${rawPath}\Yield Curve Sack Wright\feds200628.xlsx", ///
		firstrow case(lower) cellrange(A10) clear	
	gen date = date(a,"YMD")
	label var date "Date"
	format date %td	
	order date
	drop a
	
	// keep only the data series we will potentially use
	keep date sveny01-sveny07
	save "${dtapath}\treasury_zero_coupon_yields_daily", replace	
	
	// quarterly dataset
	use "${dtapath}\treasury_zero_coupon_yields_daily", clear
	gen dateqtr = qofd(date)
	format dateqtr %tq	
	collapse (mean) sven*, by(dateqtr)
	save "${dtapath}\treasury_zero_coupon_yields_quarterly", replace
	
	// annual dataset
	use "${dtapath}\treasury_zero_coupon_yields_daily", clear
	gen year = year(date)
	collapse (mean) sven*, by(year)
	save "${dtapath}\treasury_zero_coupon_yields_annual", replace	
	
	
	
/*********************************************************************************************/	
// ken french data library: market returns and industry classification
	
	// daily factors
	import excel using "${rawPath}\Ken French Data Library\F-F_Research_Data_Factors_for_import.xlsx",  ///
		clear sheet("F-F_Research_Data_Factors_daily") firstrow case(lower) cellrange(A5:E24500) allstring
	destring mktrf smb hml rf, replace	
	rename mktrf rm_minus_rf // rename excess return
	gen date = date(a,"YMD")
	label var date "Date"
	format date %td
	drop a
	drop if missing(date) // drops non-data obs
	order date	
	save "${dtapath}\famafrench_daily_factors", replace	
	
	// monthly factors
	import excel using "${rawPath}\Ken French Data Library\F-F_Research_Data_Factors_for_import.xlsx",  ///
		clear sheet("F-F_Research_Data_Factors") firstrow case(lower) cellrange(A4:E1119) allstring	
	destring mktrf smb hml rf, replace	
	gen datemo = mofd(date(a,"YM"))
	label var datemo "Date Month"
	format datemo %tm
	drop a
	order datemo	
	save "${dtapath}\famafrench_monthly_factors", replace

	// 49 industry definitions by SIC code from Ken French website
	import excel "${rawPath}\Ken French Data Library\49_Industry_Portfolios_for_import.xlsx", sheet("Siccodes49_for_import") firstrow clear
	
		// check difference between start/end codes
		gen diff = sic_end_num - sic_start_num
		set more off
		tab diff
		drop diff	

		// add var for each sic code
		forvalues j = 0/100 {
			gen sic`j' = sic_start_num+`j'
		}		

		// reshape		
		reshape long sic, i(sic_start_num sic_end_num industry_short_name industry_long_name) j(sic_count)
		drop sic_count		
		keep if sic>=sic_start_num & sic<=sic_end_num
		keep sic sic_start_num sic_end_num industry_short_name industry_long_name
		tab industry_short_name
		
		// double check no duplicate sic codes
		//keep sic
		//duplicates drop
		
	save "${dtapath}\siccodes_industries_49", replace		
	
	
	
/*********************************************************************************************/		
/*NBER recession dates*/
	
	import excel "${rawPath}\NBER\NBER chronology.xlsx", sheet("NBER chronology") firstrow case(lower) clear
	
	/*turn string dates into month dates*/
	keep peakmonth troughmonth
	gen official_startmo = mofd(date(peakmonth,"MY"))
	gen official_endmo   = mofd(date(troughmonth,"MY"))
	format official_startmo official_endmo %tm
	
	/*clean and save*/
	keep if ~missing(official_startmo)
	keep official_startmo official_endmo
	gen recnum = _n
	order recnum
	save "${dtapath}\nber_recession_dates", replace


	/*save temp dataset with additional var just for merging*/
	use "${dtapath}\nber_recession_dates", clear
	local total_recs = _N
	
	/*create dataset with datemo as only variable*/
	use datemo using "${dtapath}\famafrench_monthly_factors", clear

	/*loop through each pair of dates in recession dates*/
	forvalue i=1/`total_recs' {
		gen recnum = `i'
		quiet merge m:1 recnum using "${dtapath}\nber_recession_dates", nogen keep(match)
		
		/*create recession dummy*/
		gen recession_dummy_`i' = ((datemo>=official_startmo) & (datemo<=official_endmo))

		/*create expanded recession (including 6 mos prior) dummy*/
		gen expand_recession_dummy_`i' = ((datemo>=official_startmo-6) & (datemo<=official_endmo))		

		/*create shifted recession (by 6 mos) dummy*/
		gen shift_recession_dummy_`i' = ((datemo>=official_startmo-6) & (datemo<=official_endmo-6))			
		
		drop recnum official_startmo official_endmo
	}
	
	/*generate final recession dummies*/
	egen rec_dum = rowmax(recession_dummy_*)
	label var rec_dum "Recession Dummy"
	drop recession_dummy_*
	egen exp_rec_dum = rowmax(expand_recession_dummy_*)
	label var exp_rec_dum "Expanded Recession Dummy"	
	drop expand_recession_dummy_*
	egen shift_rec_dum = rowmax(shift_recession_dummy_*)
	label var shift_rec_dum "Shifted Recession Dummy"	
	drop shift_recession_dummy_*	
	
	/*save final datset*/
	save "${dtapath}\nber_recession_dummies", replace
	
	
	/*also create a quarterly dataset*/
	use "${dtapath}\nber_recession_dummies", clear
	gen dateqtr = qofd(dofm(datemo))
	format dateqtr %tq
	collapse (max) rec_dum, by(dateqtr)
	tsset dateqtr
	gen shift_rec_dum = f2.rec_dum
	replace shift_rec_dum = 0 if missing(shift_rec_dum)
	label var rec_dum "Recession Dummy"
	label var shift_rec_dum "Shifted Recession Dummy"	
	save "${dtapath}\nber_recession_dummies_quarterly", replace
	
		
	/*also create an annual dataset*/
	use "${dtapath}\nber_recession_dummies", clear
	gen year = year(dofm(datemo))	
	collapse (sum) sum_rec_dum = rec_dum, by(year)	
	gen rec_dum = 0
	replace rec_dum = 1 if sum_rec_dum>=4
	label var rec_dum "Recession Dummy (at least 4 months of the year)"
	keep year rec_dum
	save "${dtapath}\nber_recession_dummies_annual", replace	
	
	
	
/*********************************************************************************************/		
/*integrated volatility (ivol)*/			

	/*ivol measure can be used as alternative to NBER recession*/
	
	use "${dtapath}\famafrench_daily_factors", clear
	gen datemo = mofd(date)
	gen date_month = mdy(month(date),1,year(date))
	format datemo %tm
	format date_month %td
	
	/*generate daily squared market returns*/
	gen rm = rm_minus_rf + rf
	gen rm_sqr = rm^2
	
	/*sum by month*/
	collapse (sum) rm_sqr_sum = rm_sqr (count) num_obs = rm_sqr, by(datemo date_month)
	
	/*re-scale the sum depending on obs*/
	gen rm_sqr_sum_norm = rm_sqr_sum * 22 / num_obs
	drop rm_sqr_sum num_obs
	
	/*take square root to get intergated volatility measure (IVOL)*/
	gen ivol = sqrt(rm_sqr_sum_norm)
	label var ivol "Integrated Vol."
	drop rm_sqr_sum_norm
	
	/*classify high ivol according to being above 80th percentile*/
	egen ivol_05 = pctile(ivol),  p(5)	
	egen ivol_10 = pctile(ivol), p(10)		
	egen ivol_20 = pctile(ivol), p(20)			
	egen ivol_80 = pctile(ivol), p(80)
	egen ivol_90 = pctile(ivol), p(90)
	egen ivol_95 = pctile(ivol), p(95)

	/*dummy variables for periods of high ivol*/
	gen low_ivol_05 = (ivol<=ivol_05)
	gen low_ivol_10 = (ivol<=ivol_10)
	gen low_ivol_20 = (ivol<=ivol_20)
	gen high_ivol_80 = (ivol>=ivol_80)
	gen high_ivol_90 = (ivol>=ivol_90)
	gen high_ivol_95 = (ivol>=ivol_95)	
	
	/*save final datset*/
	save "${dtapath}\integrated_volatility_monthly", replace		
	
	/*merge and export dataset with recession dummies for comparison*/
	//merge 1:1 datemo using "${dtapath}\nber_recession_dummies", nogen
	//outsheet using "${dtapath}\integrated_volatility_monthly.csv", replace comma	
	

	/*also create a quarterly dataset*/
	use "${dtapath}\famafrench_daily_factors", clear
	gen dateqtr = qofd(date)
	format dateqtr %tq
	
	/*generate daily squared market returns*/
	gen rm = rm_minus_rf + rf
	gen rm_sqr = rm^2
	
	/*sum by month*/
	collapse (sum) rm_sqr_sum = rm_sqr (count) num_obs = rm_sqr, by(dateqtr)
	
	/*re-scale the sum depending on obs*/
	gen rm_sqr_sum_norm = rm_sqr_sum * 66 / num_obs
	drop rm_sqr_sum num_obs
	
	/*take square root to get intergated volatility measure (IVOL)*/
	gen ivol = sqrt(rm_sqr_sum_norm)
	label var ivol "Integrated Vol."
	drop rm_sqr_sum_norm
	
	/*classify high ivol according to being above 80th percentile*/
	egen ivol_05 = pctile(ivol),  p(5)	
	egen ivol_10 = pctile(ivol), p(10)		
	egen ivol_20 = pctile(ivol), p(20)			
	egen ivol_80 = pctile(ivol), p(80)
	egen ivol_90 = pctile(ivol), p(90)
	egen ivol_95 = pctile(ivol), p(95)

	/*dummy variables for periods of high ivol*/
	gen low_ivol_05 = (ivol<=ivol_05)
	gen low_ivol_10 = (ivol<=ivol_10)
	gen low_ivol_20 = (ivol<=ivol_20)
	gen high_ivol_80 = (ivol>=ivol_80)
	gen high_ivol_90 = (ivol>=ivol_90)
	gen high_ivol_95 = (ivol>=ivol_95)	
	
	/*save final datset*/
	save "${dtapath}\integrated_volatility_quarterly", replace		

	
	
	/*also create an annual dataset*/
	use "${dtapath}\famafrench_daily_factors", clear
	gen year = year(date)
	
	/*generate daily squared market returns*/
	gen rm = rm_minus_rf + rf
	gen rm_sqr = rm^2
	
	/*sum by year*/
	collapse (sum) rm_sqr_sum = rm_sqr (count) num_obs = rm_sqr, by(year)
	
	/*re-scale the sum depending on obs*/
	gen rm_sqr_sum_norm = rm_sqr_sum * 252 / num_obs
	drop rm_sqr_sum num_obs
	
	/*take square root to get intergated volatility measure (IVOL)*/
	gen ivol = sqrt(rm_sqr_sum_norm)
	label var ivol "Integrated Vol."
	drop rm_sqr_sum_norm
	
	/*classify high ivol according to being above 80th percentile*/
	egen ivol_05 = pctile(ivol),  p(5)	
	egen ivol_10 = pctile(ivol), p(10)		
	egen ivol_20 = pctile(ivol), p(20)			
	egen ivol_80 = pctile(ivol), p(80)
	egen ivol_90 = pctile(ivol), p(90)
	egen ivol_95 = pctile(ivol), p(95)

	/*dummy variables for periods of high ivol*/
	gen low_ivol_05 = (ivol<=ivol_05)
	gen low_ivol_10 = (ivol<=ivol_10)
	gen low_ivol_20 = (ivol<=ivol_20)
	gen high_ivol_80 = (ivol>=ivol_80)
	gen high_ivol_90 = (ivol>=ivol_90)
	gen high_ivol_95 = (ivol>=ivol_95)	
	
	/*save final datset*/
	save "${dtapath}\integrated_volatility_annual", replace				
	

/*********************************************************************************************/		
// Ibbotson data on equity returns, bond returns, and inflation	
// sent by Ravi via email to Sam Rosen on February 7 2015	
// sam updated ltgovbd data series on 7/10/2019 so we have data through 2016
	
	/*import monthly data worksheet*/
	import excel "${rawPath}\Ibbotson\Ibbotson_Monthly_Data.xls", sheet("monthly") firstrow case(lower) clear
	gen datemo = mofd(date(yymm,"YM"))
	format datemo %tm
	drop if missing(datemo)
	order datemo
	drop yymm i		
	tsset datemo
	
	// note: used to compute inflation deflator here but
	//       now do so in full stitched together time series (inflation_monthly)

	/*save out raw dataset*/
	save "${dtapath}\ibbotson_monthly", replace	
	
	
	// create quarterly dataset too for comparison
	use "${dtapath}\ibbotson_monthly", clear
	gen dateqtr = qofd(dofm(datemo))
	format dateqtr %tq		
	//gen ln_ltgovbd = ln(1+ltgovbd)
	//collapse (sum) ln_ltgovbd, by(dateqtr)	
	//gen ltgovbd = exp(ln_ltgovbd)-1
	collapse (sum) ltgovbd, by(dateqtr)	
	keep dateqtr ltgovbd	
	save "${dtapath}\ibbotson_quarterly", replace	
	
	
	// create annual dataset too
	use "${dtapath}\ibbotson_monthly", clear
	gen year = year(dofm(datemo))
	collapse (sum) ltgovbd, by(year)	
	keep year ltgovbd	
	save "${dtapath}\ibbotson_annual", replace		
	
	
	// create long dataset with average and component return series
	use "${dtapath}\ibbotson_monthly", clear
	
		/*combine government bond series into a single equal-weighted return series (mult by 100 for percent)*/
		gen govt_ibbotson_avg = 100*(ltgovbd + itgovbd + tbill) / 3
		keep datemo govt_ibbotson_avg
		gen port_name = "eql_wgt_avg"
		gen port_ret = govt_ibbotson_avg
		foreach bondport in "ltgovbd" "itgovbd" "tbill" "largecap" "smallcap" "ltcrpbd" {
			append using "${dtapath}\ibbotson_monthly", keep(datemo `bondport')
			replace port_name = "`bondport'" if missing(port_ret)
			replace port_ret = 100*`bondport' if missing(port_ret) // also *100 so values are percent
		}
		keep datemo port_name port_ret
		/*only government bonds*/
		keep if inlist(port_name, "eql_wgt_avg", "ltgovbd", "itgovbd", "tbill")
		save "${dtapath}\ibbotson_govt_bond_ret_monthly_long", replace	
	

	
	
	
	
/*********************************************************************************************/		
// CPI and inflation
// CPI index from the bureau of labor statistics (BLS) to compute inflation with

// NOTE: the ibbotson inflation series (which we used to use) uses this CPI index to compute 
//       its inflation value. I bring in this data series in order to compute more recent 
//       inflation values because I don't have access to Ibbotson date (Ravi sent that original
//       spreadsheet). Note that we still need Ibbotston data for government bond
//       return series


	// monthly CPI series
	import excel "${rawPath}\BLS\CPI_index.xlsx", sheet("for_import") firstrow case(lower) clear		
	destring year, replace
	gen datemo = ym(year,month)
	format datemo %tm
	drop year month	
	save "${dtapath}\bls_cpi_monthly", replace		

	
	// create inflation deflator to use for annual compustat variables
	use "${dtapath}\bls_cpi_monthly", clear
		
		// 12-month moving average so we can apply index directly to annual 
		// computstat values by datadate
		tsset datemo
		gen cpi_t12sum = cpi
		forvalues j=1/11 {
			replace cpi_t12sum = cpi_t12sum + L`j'.cpi
		}
		gen cpi_t12ma = cpi_t12sum/12
		
		// normalize by 2009m12 value
		gen tempvar = cpi_t12ma if datemo==ym(2009,12)
		egen divisor = max(tempvar)
		gen inflation_index_for_comp = cpi_t12ma / divisor

		keep datemo inflation_index
		drop if missing(inflation_index)
		save "${dtapath}\inflation_index_monthly", replace	
	
	
	// monthly inflation series. combine CPI series and Ibbotson data. 
	// use Ibbotson before 2007 because CPI only reported with one 
	// decimal before then so monthly changes are less accurate.
	
		// inflation from BLS CPI
		use "${dtapath}\bls_cpi_monthly", clear				
		tsset datemo
		gen inflation = cpi / L1.cpi - 1
		keep datemo inflation
		keep if datemo>=ym(2007,1)
		save "${dtapath}\temp_bls_inflation_monthly", replace	
	
		// inflation from Ibbotson
		use "${dtapath}\ibbotson_monthly", clear
		tsset datemo
		keep datemo inflation
		keep if datemo<ym(2007,1)
		save "${dtapath}\temp_ibbotson_inflation_monthly", replace		
	
		// combine together
		use "${dtapath}\temp_bls_inflation_monthly", clear
		append using "${dtapath}\temp_ibbotson_inflation_monthly"
		tsset datemo
		gen inflation_deflator = (1+inflation)/(1+l1.inflation)			
		save "${dtapath}\inflation_monthly", replace		
	
	
	// also create quarterly inflation series
	use "${dtapath}\inflation_monthly", clear
	gen ln_inflation = ln(1+inflation)
	gen dateqtr = qofd(dofm(datemo))
	format dateqtr %tq	
	collapse (sum) ln_inflation, by(dateqtr)
	gen inflation = exp(ln_inflation)-1
	keep dateqtr inflation
	save "${dtapath}\inflation_quarterly", replace
	
	
	// also create annual inflation series
	use "${dtapath}\inflation_monthly", clear
	gen ln_inflation = ln(1+inflation)
	gen year = year(dofm(datemo))	
	collapse (sum) ln_inflation, by(year)
	gen inflation = exp(ln_inflation)-1
	keep year inflation
	save "${dtapath}\inflation_annual", replace	
	
	
	

/*********************************************************************************************/		
// Price-Dividend Data from Robert Shiller website
// http://www.econ.yale.edu/~shiller/data.htm	
	
	// monthly price-dividend data
	import excel "${rawPath}\Shiller Website\ie_data.xls", ///
		clear sheet("Data") cellrange(A8:K1791) firstrow case(lower)	
	
	// date and month
	gen year = int(date)
	gen month = 100*(date-year)
	gen datemo = ym(year,month)
	format datemo %tm
	tsset datemo
	
	// compute pd ratio in a few different ways
	gen pd_ratio_beg = p/L1.d
	gen pd_ratio_end = F1.p/d
	
	keep datemo pd_ratio_beg pd_ratio_end
	save "${dtapath}\pd_ratio_monthly", replace		
	

	// quarterly PD ratio
	use "${dtapath}\pd_ratio_monthly", clear
	gen dateqtr = qofd(dofm(datemo))
	format dateqtr %tq	
	drop pd_ratio_beg // to avoid confusion
	//keep if inlist(month(dofm(datemo)),3,6,9,12) // end-of-quarter value
	//drop datemo	
	// take quarterly average
	collapse (mean) pd_ratio_end, by(dateqtr)
	order dateqtr
	tsset dateqtr
	save "${dtapath}\pd_ratio_quarterly", replace		
	
	
	
	// annual PD ratio
	use "${dtapath}\pd_ratio_monthly", clear
	gen year = year(dofm(datemo))	
	drop pd_ratio_beg // to avoid confusion
	// take annual average	
	collapse (mean) pd_ratio_end, by(year)
	order year
	tsset year
	save "${dtapath}\pd_ratio_annual", replace		
	
		
	
	
	
	
/*********************************************************************************************/		
// national aggregates (e.g., GDP) downloaded from FRED
// underlying data from the BEA NIPA tables


// QUARTERLY END OF PERIOD (will combine with quarterly)
	
	import excel "${rawPath}\FRED\BCLR_National_Aggregates.xls", sheet("Quarterly,_End_of_Period") firstrow case(lower) clear	
	gen dateqtr = qofd(date)
	format dateqtr %tq
	order dateqtr	
	drop date	
	rename tnwmvbsnncb nonfin_corp_net_worth
	label var nonfin_corp_net_worth "Nonfinancial corporate business; net worth, Level (NSA Billions of Dollars)"	
	save "${dtapath}\temp_nonfin_corp_net_worth", replace	
	
	
// QUARTERLY
import excel "${rawPath}\FRED\BCLR_National_Aggregates.xls", sheet("Quarterly") firstrow case(lower) clear	

	gen dateqtr = qofd(date)
	format dateqtr %tq
	order dateqtr	
	drop date
	
	rename gdp gdp_nom
	label var gdp_nom  "Gross Domestic Product, SA Annual Rate (Billons of Dollars)"

	rename gdpc96 gdp_real
	label var gdp_real "Real Gross Domestic Product, SA Annual Rate (Billions of Chained 2009 Dollars)"	
	
	rename a939rc0q052sbea gdp_per_capita_nom
	label var gdp_per_capita_nom "GDP per Capita, SA Annual Rate (Dollars)"

	rename a939rx0q048sbea gdp_per_capita_real
	label var gdp_per_capita_real "Real GDP per Capita, SA Annual Rate (Chained 2009 Dollars)"	
	
	rename pcec pce_nom
	label var pce_nom "Personal Consumption Expenditures, SA Annual Rate (Billons of Dollars)"
	
	rename a957rc1q027sbea consumption_govt_fed
	label var consumption_govt_fed "Federal Govt Consumption Expenditures, SA Annual Rate (Billons of Dollars)"

	rename a991rc1q027sbea consumption_govt_snl
	label var consumption_govt_snl "State and Local Govt Consumption Expenditures, SA Annual Rate (Billons of Dollars)"	

	rename gpdi gross_priv_inv_incl_inventories
	label var gross_priv_inv_incl_inventories "Nominal Gross Private Investment including inventories, SA annual rate, Billions of dollars"			
	// OLD VARIABLE NAME/LABEL:
	//rename gpdi gross_private_investment_all
	//label var gross_private_investment_all "Gross Private Domestic Investment (fixed and inventories), SA Annual Rate (Billons of Dollars)"	
	
	rename fpi gross_priv_inv_nom
	label var gross_priv_inv_nom "Nominal Gross Private Fixed Investment, SA annual rate, Billions of dollars"				
	// OLD VARIABLE NAME/LABEL:
	//rename fpi gross_private_investment_fixed
	//label var gross_private_investment_fixed "Fixed Private Investment, SA Annual Rate (Billons of Dollars)"		
	
	rename gce govt_con_and_inv_nom // formerly named govt_consumption_and_investment
	label var govt_con_and_inv_nom "Government Consumption Expenditures and Gross Investment, SA Annual Rate (Billons of Dollars)"	
	
	rename a782rl1q225sbea gross_govt_investment_real_pchg
	// OLD NAME:
	//rename a782rl1q225sbea gross_govt_inv_real_pct_chg
	label var gross_govt_investment_real_pchg "Real Gross Govt Investment, SA annual rate, Percent Change from Preceding Period"	
	
	rename gpdic1 gross_private_investment_real
	label var gross_private_investment_real "Real Gross Private Domestic Investment, SA Annual Rate (Chained 2009 Dollars)"		

	rename a007rl1q225sbea fixed_priv_investment_real_pchg
	label var fixed_priv_investment_real_pchg "Real Gross Private Domestic Investment: Fixed Investment, SA annual rate, Percent Change from Preceding Period"		
	
	rename pcecc96 pce_real
	label var pce_real "Real Personal Consumption Expenditures, SA Annual Rate (Chained 2009 Dollars)"				
	
	rename gcec1 govt_con_and_inv_real
	label var govt_con_and_inv_real "Real Government Consumption Expenditures and Gross Investment"

	rename a193rc1q027sbea gross_va_hh_nom
	label var gross_va_hh_nom "Gross value added: GDP: Households and institutions, SA Billions"
	
	rename a193rx1q020sbea gross_va_hh_real
	label var gross_va_hh_real "Real gross value added: GDP: Households and institutions"
	
	// OLD NAME:
	//rename a195rc1q027sbea gross_va_busi_nom
	//label var gross_va_busi_nom "Gross value added: GDP: Business"

	// OLD NAME:
	//rename a195rx1q020sbea gross_va_busi_real
	//label var gross_va_busi_real "Real gross value added: GDP: Business"
	
	rename a765rc1q027sbea gross_va_govt_nom
	label var gross_va_govt_nom "Gross value added: GDP: General government"
	
	rename a765rx1q020sbea gross_va_govt_real
	label var gross_va_govt_real "Real gross value added: GDP: General government"
		
	// investment from the BEA NIPA tables from Section 3 and Section 5
		
	rename y001rc1q027sbea gross_fpi_ipp_tot
	label var gross_fpi_ipp_tot "Gross Private Domestic Investment: Fixed Investment: Nonresidential: Intellectual Property Products, SA Annual Rate (Billons of Dollars)"	
	
	rename y006rc1q027sbea gross_fpi_ipp_rnd
	label var gross_fpi_ipp_rnd "Gross Private Domestic Investment: Fixed Investment: Nonresidential: Intellectual Property Products: Research and Development, SA Annual Rate (Billons of Dollars)"	

	rename w170rc1q027sbea gross_inv_nom
	label var gross_inv_nom "Nominal Gross Domestic Investment, SA annual rate, Billions of dollars"			

	//rename w987rc1q027sbea  gross_priv_busi_inv_nom
	//label var gross_priv_busi_inv_nom "Nominal Gross Private Domestic Business Investment, SA annual rate, Billions of dollars"			
	
	//rename w988rc1q027sbea gross_priv_busi_hh_nom
	//label var gross_priv_busi_hh_nom "Nominal Gross Private Households and institutions Investment, SA annual rate, Billions of dollars"					
	
	rename a782rc1q027sbea gross_govt_inv_nom
	label var gross_govt_inv_nom "Nominal Gross Govt Investment, SA annual rate, Billions of dollars"
	
	rename dgi gross_govt_inv_fed_def_nom
	label var gross_govt_inv_fed_def_nom "Nominal Gross Federal Govt Defense Investment, SA annual rate, Billions of dollars"
	
	rename ndgi gross_govt_inv_fed_nondef_nom
	label var gross_govt_inv_fed_nondef_nom "Nominal Gross Federal Govt Nondefense Investment, SA annual rate, Billions of dollars"
	
	rename slinv gross_govt_inv_snl_nom
	label var gross_govt_inv_snl_nom "Nominal Gross State and Local Govt Investment, SA annual rate, Billions of dollars"	  
	
	rename a787rc1q027sbea gross_fed_govt_inv_nom
	label var gross_fed_govt_inv_nom "Nominal Gross Federal Govt Investment, SA annual rate, Billions of dollars"

	rename a264rc1q027sbea govt_cfc_nom
	label var govt_cfc_nom "Nominal government consumption of fixed capital, SA annual rate, Billions of dollars"
	
	rename a264rx1q020sbea govt_cfc_real
	label var govt_cfc_real "Real government consumption of fixed capital, SA annual rate, Billions of dollars"
	
	//rename a918rc1q027sbea fed_govt_cfc_nom
	//label var fed_govt_cfc_nom "Nominal federal government consumption of fixed capital, SA annual rate, Billions of dollars"

	rename a782rx1q020sbea gross_govt_inv_real
	label var gross_govt_inv_real "Real Gross Govt Investment"	
	// note: this variable appears to be mislabeld on FRED as "Real government consumption expenditures and gross investment: State and local: Gross investment: Equipment and software"
	//       but I confirmed by going to NIPA tables that this series the real gross govt investment total from 3.9.6
	
	rename y055rc1q027sbea gross_govt_inv_nom_ipp
	label var gross_govt_inv_nom_ipp "Nominal Government Gross Investment: Intellectual Property Products, SA annual rate, Billions of dollars"
	
	rename y057rc1q027sbea gross_govt_inv_nom_rnd
	label var gross_govt_inv_nom_rnd "Nominal Government Gross Investment: Intellectual Property Products: Research and Development, SA annual rate, Billions of dollars"

	//rename y069rc1q027sbea govt_fed_nondef_inv_nom_rnd
	
	//rename y073rc1q027sbea govt_snl_inv_nom_rnd
	
	//rename y076rc1q027sbea govt_fed_def_inv_nom_rnd
	
	/*double check that gross_inv_nom is sum of gross_priv_inv_nom and gross_govt_inv_nom*/
	//gen test = gross_priv_inv_incl_inventories + gross_govt_inv_nom
	//gen test2 = abs(gross_inv_nom - test)
	//summ test2	
	
	// government and private sector value added based on series in NIPA tables 1.3.5 and 1.3.6
	
	//rename a193rc1q027sbea gdp_va_hh_nom
	//label var gdp_va_hh_nom "Gross value added: GDP: Households and institutions, SA USD Billions"
	
	//rename a193rx1q020sbea gdp_va_hh_real
	//label var gdp_va_hh_real "Real gross value added: GDP: Households and institutions, SA USD Billions Chained 2009"
	
	rename a195rc1q027sbea gdp_va_busi_nom	
	label var gdp_va_busi_nom "Gross value added: GDP: Business, SA USD Billions"
	
	rename a195rx1q020sbea gdp_va_busi_real	
	label var gdp_va_busi_real "Real gross value added: GDP: Business, SA USD Billions Chained 2009"
	
	//rename a765rc1q027sbea gdp_va_govt_gen_nom
	//label var gdp_va_govt_gen_nom "Gross value added: GDP: General government, NSA USD Billions"
	
	//rename a765rx1q020sbea gdp_va_govt_gen_real
	//label var gdp_va_govt_gen_real "Real gross value added: GDP: General government, SA Billions of Chained 2009 Dollars"	
	
	
	// compute level of real govt investment using real percent change
	// series and the level of the available real govt investment series,
	// which is only available back to 1999
	//br dateqtr gross_govt_inv_real gross_govt_investment_real_pchg
	
		// compute index of Ig real using percent change
		gen temp_log_vals = ln(1+gross_govt_investment_real_pchg/100)/4
		gen temp_logIg_cumsum = sum(temp_log_vals)
		gen temp_Ig_real_index = exp(temp_logIg_cumsum)
		
		// check ratios and compute implied Ig real according to ratio
		gen temp_ratio = gross_govt_inv_nom / (gross_priv_inv_nom+gross_govt_inv_nom)
		gen temp_ratio_chk = gross_govt_inv_real / (gross_private_investment_real+gross_govt_inv_real)
		//line temp_ratio_chk temp_ratio dateqtr if ~missing(temp_ratio_chk)		
		// note: not really a close match in terms of ratio
		gen temp_implied_Ig_real = gross_private_investment_real * (temp_ratio/(1-temp_ratio))
		//br dateqtr gross_govt_inv_real temp_implied_Ig_real if ~missing(gross_govt_inv_real)
		//line gross_govt_inv_real temp_implied_Ig_real dateqtr if ~missing(gross_govt_inv_real)		
		// note: the implied Ig real series does not match well the available Ig real series
		//       so let's use the real Ig value instead
		
		// use scale factor implied by available real series
		// use value as of 2002Q1, which is somewhat arbirtrary but
		// is the earliest value we have so closest to the middle
		// of the time series
		gen temp_val = gross_govt_inv_real / temp_Ig_real_index if dateqtr==yq(2002,1) 
		egen temp_scale = max(temp_val)				
		gen gross_govt_investment_real = temp_scale*temp_Ig_real_index 
		//br dateqtr gross_govt_investment_real_pchg temp_* gross_govt_investment_real
		drop temp_* // clean up
	
	// book value of corp equities for use in agg Tobin's Q measure
	gen nonfin_corp_equity_mkt = ncbeilq027s / 10^3 // convert to billions
	drop ncbeilq027s
	label var nonfin_corp_equity_mkt "Nonfinancial corporate business; corporate equities; liability, Level (NSA billions of USD)"
	
	// merge on the market value series also for use in agg Tobin's Q measure
	merge 1:1 dateqtr using "${dtapath}\temp_nonfin_corp_net_worth", nogen keep(master match)
	
	save "${dtapath}\bea_quarterly", replace		
	

	
// details of government investment. pull separately to avoid having
// to re-download the original BEA data 
import excel "${rawPath}\FRED\BCLR_Govt_Investment_Details 20211216.xls", sheet("Quarterly") firstrow case(lower) clear	

	gen dateqtr = qofd(date)
	format dateqtr %tq
	order dateqtr	
	drop date

	rename y057rc1q027sbea gross_govt_inv_nom_rnd
	label var gross_govt_inv_nom_rnd "Nominal Government Gross Investment: Intellectual Property Products: Research and Development, SA annual rate, Billions of dollars"

	rename y069rc1q027sbea govt_fed_nondef_inv_nom_rnd
	
	rename y073rc1q027sbea govt_snl_inv_nom_rnd
	
	rename y076rc1q027sbea govt_fed_def_inv_nom_rnd	
	
	rename a782rc1q027sbea gross_govt_inv_nom
	label var gross_govt_inv_nom "Nominal Gross Govt Investment, SA annual rate, Billions of dollars"
	
	rename dgi gross_govt_inv_fed_def_nom
	label var gross_govt_inv_fed_def_nom "Nominal Gross Federal Govt Defense Investment, SA annual rate, Billions of dollars"
	
	rename y061rc1q027sbea govt_fed_inv_nom_rnd

	save "${dtapath}\bea_quarterly_specific_govt_inv_series", replace
	
	
	
// ANNUAL
import excel "${rawPath}\FRED\BCLR_National_Aggregates.xls", sheet("Annual") firstrow case(lower) clear	

	gen year = year(date)	
	order year
	drop date
	
	rename gdpa gdp_nom
	label var gdp_nom  "Gross Domestic Product, NSA (Billons of Dollars)"

	rename gdpca gdp_real
	label var gdp_real "Real Gross Domestic Product, NSA (Billions of Chained 2009 Dollars)"		

	rename a939rc0a052nbea gdp_per_capita_nom
	label var gdp_per_capita_nom "GDP per Capita, SA Annual Rate (Dollars)"
	
	rename pceca pce_nom
	label var pce_nom "Personal Consumption Expenditures, (Billons of Dollars)"
	
	rename a957rc1a027nbea consumption_govt_fed
	label var consumption_govt_fed "Federal Govt Consumption Expenditures, (Billons of Dollars)"
	
	rename a991rc1a027nbea consumption_govt_snl
	label var consumption_govt_snl "State and Local Govt Consumption Expenditures, (Billons of Dollars)"	

	rename gpdia gross_private_investment_nom
	label var gross_private_investment_nom "Gross Private Domestic Investment, NSA (Billions of Dollars)"		
	
	rename gpdica gross_private_investment_real
	label var gross_private_investment_real "Real Gross Private Domestic Investment, NSA (Billions of Chained 2009 Dollars)"		

	rename a007rl1a225nbea fixed_priv_investment_real_pchg
	label var fixed_priv_investment_real_pchg "Real Gross Private Domestic Investment: Fixed Investment, SA annual rate, Percent Change from Preceding Period"			
	
	rename a782rx1a020nbea gross_govt_investment_real
	label var gross_govt_investment_real "Real Gross Govt Investment, NSA (Billions of Chained 2009 Dollars)"			

	rename dpcerx1a020nbea pce_real
	label var pce_real "Real Personal Consumption Expenditures, NSA (Billions of Chained 2009 Dollars)"				
	
	rename a193rc1a027nbea gross_va_hh_nom
	label var gross_va_hh_nom "Gross value added: GDP: Households and institutions"
	
	rename a193rx1a020nbea gross_va_hh_real
	label var gross_va_hh_real "Real gross value added: GDP: Households and institutions"
	
	// OLD NAME/LABEL:
	//rename a195rc1a027nbea gross_va_busi_nom
	//label var gross_va_busi_nom "Gross value added: GDP: Business"
	
	// OLD NAME/LABEL:
	//rename a195rx1a020nbea gross_va_busi_real
	//label var gross_va_busi_real "Real gross value added: GDP: Business"
	
	rename a765rc1a027nbea gross_va_govt_nom
	label var gross_va_govt_nom "Gross value added: GDP: General government"
	
	rename a765rx1a020nbea gross_va_govt_real
	label var gross_va_govt_real "Real gross value added: GDP: General government"
	
	rename gcea govt_con_and_inv_nom
	label var govt_con_and_inv_nom "Government Consumption Expenditures and Gross Investment"
	
	rename gceca govt_con_and_inv_real
	label var govt_con_and_inv_real "Real Government Consumption Expenditures and Gross Investment"
	  
	rename y001rc1a027nbea gross_fpi_ipp_tot
	label var gross_fpi_ipp_tot "Gross Private Domestic Investment: Fixed Investment: Nonresidential: Intellectual Property Products"	
	
	rename y006rc1a027nbea gross_fpi_ipp_rnd
	label var gross_fpi_ipp_rnd "Gross Private Domestic Investment: Fixed Investment: Nonresidential: Intellectual Property Products: Research and Development"				
	  
	rename fpia gross_priv_inv_nom
	label var gross_priv_inv_nom "Nominal Gross Private Fixed Investment, Billions of dollars"
	
	//rename gpdia gross_priv_inv_incl_inventories
	//label var gross_priv_inv_incl_inventories "Nominal Gross Govt Investment including Inventories, Billions of dollars"
		
	rename a782rc1a027nbea gross_govt_inv_nom
	label var gross_govt_inv_nom "Nominal Gross Govt Investment, Billions of dollars"		
	
	rename a782rl1a225nbea gross_govt_inv_real_pct_chg
	label var gross_govt_inv_real_pct_chg "Real Gross Govt Investment, Percent Change from Preceding Period"	
	
	//rename a782rx1a020nbea gross_govt_inv_real
	//label var gross_govt_inv_real "Real Gross Govt Investment, Billions of chained 2009 dollars"
	
	rename a787rc1a027nbea gross_fed_govt_inv_nom
	label var gross_fed_govt_inv_nom "Nominal Gross Federal Govt Investment, Billions of dollars"
	
	rename a788rc1a027nbea gross_fed_govt_inv_nom_def // federal defense
	
	rename a264rc1a027nbea govt_cfc_nom
	label var govt_cfc_nom "Nominal government consumption of fixed capital, Billions of dollars"
		
	rename a264rl1a225nbea govt_cfc_real
	label var govt_cfc_real "Real government consumption of fixed capital, Billions of dollars"
	
	rename a918rc1a027nbea fed_govt_cfc_nom
	label var fed_govt_cfc_nom "Nominal federal government consumption of fixed capital, Billions of dollars"

	//rename i3gtotl1rd000 gross_govt_inv_rnd_nom
	//label var gross_govt_inv_rnd_nom "Nominal Gross Govt Investment into Research and Development (part of Intellectual Property), Billions of dollars"		
	
	rename y055rc1a027nbea gross_govt_inv_nom_ipp
	label var gross_govt_inv_nom_ipp "Nominal Government Gross Investment: Intellectual Property Products, SA annual rate, Billions of dollars"
	
	rename y057rc1a027nbea gross_govt_inv_nom_rnd
	label var gross_govt_inv_nom_rnd "Nominal Government Gross Investment: Intellectual Property Products: Research and Development, SA annual rate, Billions of dollars"	
	
	//rename y069rc1a027nbea govt_fed_nondef_inv_nom_rnd
	
	//rename i3gstlc1rd000 govt_snl_inv_nom_rnd
	
	//rename y076rc1a027nbea govt_fed_def_inv_nom_rnd	  
	  
	// government and private sector value added based on series in NIPA tables 1.3.5 and 1.3.6
	
	//rename a193rc1a027nbea gdp_va_hh_nom
	//label var gdp_va_hh_nom "Gross value added: GDP: Households and institutions, NSA USD Billions"	

	//rename a193rx1a020nbea gdp_va_hh_real
	//label var gdp_va_hh_real "Real gross value added: GDP: Households and institutions, NSA USD Billions Chained 2009"
	
	rename a195rc1a027nbea gdp_va_busi_nom	
	label var gdp_va_busi_nom "Gross value added: GDP: Business, NSA USD Billions"
	
	rename a195rx1a020nbea gdp_va_busi_real	
	label var gdp_va_busi_real "Real gross value added: GDP: Business, NSA USD Billions Chained 2009"
	
	//rename a765rc1a027nbea gdp_va_govt_gen_nom
	//label var gdp_va_govt_gen_nom "Gross value added: GDP: General government, NSA USD Billions"
	
	//rename a765rx1a020nbea gdp_va_govt_gen_real
	//label var gdp_va_govt_gen_real "Real gross value added: GDP: General government, NSA Billions of Chained 2009 Dollars"		  
	  
	// real govt investment only available back to 1967 but percent
	// change is available back to 1929
	br year gross_govt_investment_real gross_govt_inv_real_pct_chg
	  
		// if we need real levels of annual govt investment then repeat
		// same steps as done in quarterly section here
	  
	  
	save "${dtapath}\bea_annual", replace		

	
	
// MONTHLY
import excel "${rawPath}\FRED\BCLR_National_Aggregates.xls", sheet("Monthly") firstrow case(lower) clear	

	gen datemo = mofd(date)
	format datemo %tm
	order datemo	
	drop date	

	rename usgovt employees_govt_all_sa
	label var employees_govt_all_sa "All Government Employees, Thousands of Persons, SA"
	
	rename uspriv employees_priv_all_sa
	label var employees_priv_all_sa "All Employees: Total Private Industries, Thousands of Persons, SA"
		
	rename payems employees_total_sa
	label var employees_total_sa "All Employees: Total Nonfarm Payrolls, Thousands of Persons, SA"		
		
	label var pop "Total Population: All Ages including Armed Forces Overseas (Thousands)"
		
	save "${dtapath}\national_employment_monthly", replace			
	

	
	
	
	
// National account components including saving, investment, and series that
// tie the two together
//import excel "${rawPath}\FRED\BCLR_Check_National_Accounting 20200508.xlsx", sheet("Quarterly") firstrow case(lower) clear	
import excel "${rawPath}\FRED\BCLR_Check_National_Accounting 20200517.xls", sheet("Quarterly") firstrow case(lower) clear	

	gen dateqtr = qofd(date)
	format dateqtr %tq
	order dateqtr	
	drop date
	
	local newname = "gross_national_income"
	rename a023rc1q027sbea `newname'
	label var `newname' "Gross national income, SA USD Billions"	

	local newname = "national_income"
	rename nicur `newname'
	label var `newname' "National income, SA USD Billions"			
	
	local newname = "gross_dom_income"
	rename gdi `newname'
	label var `newname' "Gross Domestic Income"		

	local newname = "gdp_nom"
	rename gdp `newname'
	label var `newname' "Gross Domestic Product, SA Annual Rate (Billons of Dollars)"	

	local newname = "net_exports"
	rename netexp `newname'
	label var `newname' "Net Exports of Goods and Services"		
	
	// don't use this version because missing often and other CA series works (NETFI)
	//local newname = "curr_acct_final_v2"
	//rename ieabc  `newname'
	//label var `newname' "Balance on current account"	
	
	local newname = "curr_acct_nipa"
	rename netfi  `newname'
	label var `newname' "Balance on Current Account, NIPA's"	
	
	local newname = "curr_acct_stat_discrep"
	rename a030rc1q027sbea  `newname'
	label var `newname' "Net lending or net borrowing (-), NIPAs: Government: Statistical discrepancy"
	
	local newname = "gross_govt_inv_nom"
	rename a782rc1q027sbea `newname'
	label var `newname' "Nominal Gross Govt Investment, SA annual rate, Billions of dollars"	
	
	local newname = "gross_dom_inv_plus_others"
	rename a928rc1q027sbea `newname'
	label var `newname' "Gross domestic investment, capital account transactions, and net lending, NIPAs"	

	local newname = "gross_dom_inv_nom"
	rename w170rc1q027sbea `newname'
	label var `newname' "Gross domestic investment"				
	
	local newname = "gross_priv_inv_incl_inventories"
	rename gpdi `newname'
	label var `newname' "Nominal Gross Private Investment including inventories, SA annual rate, Billions of dollars"					
	
	local newname = "total_saving"
	rename gsave `newname'
	label var `newname' "Gross Saving"			
	
	local newname = "priv_saving"
	rename gpsave `newname'
	label var `newname' "Gross Private Saving"			
	
	local newname = "govt_saving"
	rename ggsave `newname'
	label var `newname' "Gross Government Saving"		
	
	local newname = "govt_con_and_inv_nom"
	rename gce `newname'
	label var `newname' "Government Consumption Expenditures and Gross Investment, SA Annual Rate (Billons of Dollars)"		

	local newname = "govt_wages"
	rename a194rc1q027sbea `newname'
	label var `newname' "Government consumption expenditures: Gross output of general government: Value added: Compensation of general government employees, SA Annual Rate (Billons of Dollars)"		
	
	// don't need these components of net lending or net borrowing b/c
	// they are contained within curr_acct_nipas
	// w162rc1q027sbea
	// w167rc1q027sbea
	// not currently using net domestic investment (w171rc1q027sbea) nor net saving (w201rc1q027sbea)

	// was used for checking in Excel, gross saving as percentage of gross national income (w206rc1q156sbea)
	
	save "${dtapath}\bea_quarterly_additional_saving_investment_series", replace			
	
	
	
// labor data for checking labor moments.  some series appear in other
// FRED files but didn't want to mess those up with updates so put
// them in this file too

	// annual data

		import excel "${rawPath}\FRED\BCLR_Labor_Data 20210217.xls", sheet("Annual") firstrow case(lower) clear		
		
		gen year = year(date)
		order year
		drop date	
		
		local newname = "emp_wages_priv"
		rename b203rc1a027nbea `newname'
		label var `newname' "National income: Compensation of employees: Wages and salaries: Other (Billons of Dollars)"				

		local newname = "emp_wages_govt"
		rename a553rc1a027nbea `newname'
		label var `newname' "National income: Compensation of employees: Wages and salaries: Government (Billons of Dollars)"					
			
		save "${dtapath}\bea_labor_data_annual", replace			
	
	// monthly convert to annual data

		import excel "${rawPath}\FRED\BCLR_Labor_Data 20210217.xls", sheet("Monthly") firstrow case(lower) clear			

		gen datemo = mofd(date)
		format datemo %tm
		order datemo	
		gen year = year(date)
		drop date	

		rename usgovt emp_govt_all_sa
		label var emp_govt_all_sa "All Government Employees, Thousands of Persons, SA"
		
		rename uspriv emp_priv_all_sa
		label var emp_priv_all_sa "All Employees: Total Private Industries, Thousands of Persons, SA"
			
		collapse (mean) emp_govt_all_sa_avg=emp_govt_all_sa emp_priv_all_sa_avg=emp_priv_all_sa  (count) Nobs=emp_govt_all_sa, by(year)
			
		drop if Nobs<12
		
		save "${dtapath}\bea_labor_data_annual_from_monthly", replace			
	
	
	
/*********************************************************************************************/		
// credit spreads downloaded from FRED

	// credit spreads, which are monthly
	import excel "${rawPath}\FRED\BCLR_Financial_Conditions.xls", sheet("Monthly") firstrow case(lower) clear	
	gen datemo = mofd(date)
	format datemo %tm
	order datemo		
	save "${dtapath}\credit_spreads_month", replace
	
		/*average by quarter to make quarterly data series*/
		use "${dtapath}\credit_spreads_month", clear
		gen dateqtr = qofd(date)
		format dateqtr %tq	
		collapse (mean) aaa10ym baa10ym gs10, by(dateqtr)	
		save "${dtapath}\credit_spreads_qtr", replace
		
		/*average by year to make year data series*/
		use "${dtapath}\credit_spreads_month", clear
		gen year = year(date)
		collapse (mean) aaa10ym baa10ym gs10, by(year)	
		drop if year==2017 // not full year of data
		save "${dtapath}\credit_spreads_ann", replace		
	
	// chicago fed financial conditions indxes, which are weekly
	import excel "${rawPath}\FRED\BCLR_Financial_Conditions.xls", sheet("Weekly,_Ending_Friday") firstrow case(lower) clear	
	save "${dtapath}\chicago_fed_fci_week", replace	

		// save quarterly dataset
		use "${dtapath}\chicago_fed_fci_week", clear
		gen dateqtr = qofd(date)
		format dateqtr %tq
		collapse (mean) nfci anfci, by(dateqtr)
		save "${dtapath}\chicago_fed_fci_qtr", replace	
		
		
		// save annual dataset
		use "${dtapath}\chicago_fed_fci_week", clear
		gen year = year(date)
		collapse (mean) nfci anfci, by(year)
		drop if year==2017 // not full year of data
		save "${dtapath}\chicago_fed_fci_ann", replace			
		

		
/*********************************************************************************************/		
// data from the BEA fixed assets tables
	
	import excel "${rawPath}\BEA\Fixed Assets Tables.xlsx", sheet("for_import") firstrow case(lower) clear	
	drop yearend_str // just for formulas in slide
	
	// set year as one in advance so assets are beginning of the year to
	// be consistent with the data series we pulled from NIPA Table 5.10
	gen year = yearend+1
	drop yearend
	order year
	
	// note that old names for priv_fa_tot and govt_fa_tot were
	// produced_fixed_assets_govt 
	// produced_fixed_assets_private
	
	save "${dtapath}\bea_fixed_assets_tables_data_annual", replace		

		
		
/*********************************************************************************************/		
/*total factor productivity (TFP) measures and related data from the FRB of San Francisco
  they have quarterly TFP and also a utilization-adjusted TFP*/			

/*see workbook for notes and info about underlying data and calculations*/
 
  
/*quarterly*/

	/*Note:  All variables are percent change at an annual rate (=400 * change in natural log). Produced on August 11, 2015  1:36 PM*/
	
	import excel "${rawPath}\FRBSF\quarterly_tfp.xlsx", sheet("quarterly") firstrow case(lower) cellrange(A2) clear
	drop w x y z aa
	
	gen year = substr(date,1,4)	
	gen qtr  = substr(date,-1,1)
	destring year qtr, replace force
	drop if missing(year)
	gen dateqtr = yq(year,qtr)
	format dateqtr %tq
	order dateqtr
	tsset dateqtr
	drop date year qtr
		
	/*add labels*/
	label var dy_prod "Business output, expenditure (product) side"
	label var dy_inc "Business output, measured from income side"
	label var dy "Output"
	label var dhours "Hours, bus sector"
	label var dlp "Business- sector labor productivity"
	label var dk "Capital input"
	label var dlq_bls_interpolated "Labor composition/quality from BLS"
	label var dlq_aaronson_sullivan "Labor composition/quality following Aaronson-Sullivan"
	label var dlq "Labor composition/quality actually used"
	label var alpha "Capital's  share of income"
	label var dtfp "Business sector TFP, annualized growth rate (%)"
	label var dutil "Utilization of capital and labor"
	label var dtfp_util "Utilization-adjusted TFP, annualized growth rate (%)"
	label var relativeprice "Relative price of 'consumption' to price of 'equipment'"
	label var invshare "Equipment and consumer durables share of output"
	label var dtfp_i "TFP in equip and consumer durables"
	label var dtfp_c "TFP in non-equipment business output  ('consumption')"
	label var du_invest "Utilization in producing investment"
	label var du_consumption "Utilization in producing non-investment business output ('consumption')"
	label var dtfp_i_util "Utilization-adjusted TFP in producing equipment and consumer durables"
	label var dtfp_c_util "Utilization-adjusted TFP in producing non-equipment output"
	
	/*rename certain variables*/
	rename dtfp dtfp_busi_sector_reg_frbsf
	rename dtfp_util dtfp_busi_sector_util_frbsf

	// compute average forward looking growth rate of tfp from t to t+n	
	//gen temp_dtfp = dtfp_busi_sector_reg_frbsf
	//gen year = year(dofq(dateqtr))
	//collapse (sum) sum_dtfp=dtfp_busi_sector_reg_frbsf (mean) mean_dtfp =dtfp_busi_sector_reg_frbsf, by(year)
	//foreach numyears in 5 7 10 {		
	//	local numqtrs = `numyears'*4
	//	forvalues j=1/`numqtrs' {
	//		gen temp_dtfp_F`j' = F`j'.temp_dtfp
	//	}
	//	egen dtfp_bs_t_tp`numyears'yrs = rowmean(temp_dtfp_*) // sum up all the quarterly growth rates
	//	egen miss_chk = rowmiss(temp_dtfp_*) // check if any misssing
	//	replace dtfp_bs_t_tp`numyears'yrs = . if miss_chk>0 // do not count an obs with missing growth rate
	//	drop temp_dtfp_F* miss_chk
	//}
	//br dateqtr dtfp_busi_sector_reg_frbsf dtfp_bs_t_tp*
	
	
	save "${dtapath}\tfp_data_from_frbsf_quarterly", replace
	
	

/*annual*/	

	/*note: all growth rates in percent*/
	
	import excel "${rawPath}\FRBSF\quarterly_tfp.xlsx", sheet("annual") firstrow case(lower) clear	
	drop w x y z aa
	rename date year
	drop if missing(year)

	/*add labels*/
	label var dy_prod "Business output, expenditure (product) side"
	label var dy_inc "Business output, measured from income side"
	label var dy "Output"
	label var dhours "Hours, bus sector"
	label var dlp "Business- sector labor productivity"
	label var dk "Capital input"
	label var dlq_bls_interpolated "Labor composition/quality from BLS"
	label var dlq_aaronson_sullivan "Labor composition/quality following Aaronson-Sullivan"
	label var dlq "Labor composition/quality actually used"
	label var alpha "Capital's  share of income"
	label var dtfp "Business sector TFP, growth rate (%)"
	label var dutil "Utilization of capital and labor"
	label var dtfp_util "Utilization-adjusted TFP, growth rate (%)"
	label var relativeprice "Relative price of 'consumption' to price of 'equipment'"
	label var invshare "Equipment and consumer durables share of output"
	label var dtfp_i "TFP in equip and consumer durables"
	label var dtfp_c "TFP in non-equipment business output  ('consumption')"
	label var du_invest "Utilization in producing investment"
	label var du_consumption "Utilization in producing non-investment business output ('consumption')"
	label var dtfp_i_util "Utilization-adjusted TFP in producing equipment and consumer durables"
	label var dtfp_c_util "Utilization-adjusted TFP in producing non-equipment output"
	
	/*rename certain variables*/
	rename dtfp dtfp_busi_sector_reg_frbsf
	rename dtfp_util dtfp_busi_sector_util_frbsf
	
	save "${dtapath}\tfp_data_from_frbsf_annual", replace
		
		
		
		
/*********************************************************************************************/		
/*government MFP measures starting 1998 from integrated industry accounts of BEA/BLS*/	
	
	
	import excel "${rawPath}\BLS\BEA-BLS industry-level production account_1998-2013.xlsx", sheet("MFP_import") firstrow case(lower) cellrange(A2) clear	
	tsset year
	
	rename mfp_govt_fed mfp_govt_fed_bea
	label var mfp_govt_fed_bea "Federal Govt MFP Measure from BEA/BLS Integrated Industry-level Production Account"
	gen log_mfp_govt_fed_bea = log(mfp_govt_fed_bea)
	gen dmfp_govt_fed_bea = 100*D1.log_mfp_govt_fed_bea

	rename mfp_govt_state_local mfp_govt_statelocal_bea
	label var mfp_govt_statelocal_bea "State & Local Govt MFP Measure from BEA/BLS Integrated Industry-level Production Account"	
	gen log_mfp_govt_statelocal_bea = log(mfp_govt_statelocal_bea)
	gen dmfp_govt_statelocal_bea = 100*D1.log_mfp_govt_statelocal_bea

	rename mfp_private mfp_private_bea
	label var mfp_private_bea "VW MFP Measure from BEA/BLS Integrated Industry-level Production Account"
	gen log_mfp_private_bea = log(mfp_private_bea)
	gen dmfp_private_bea = 100*D1.log_mfp_private_bea

	save "${dtapath}\mfp_bea_integ_prod_accts_annual", replace		
			
			
		// time series of productivity measures
		use "${dtapath}\mfp_bea_integ_prod_accts_annual", replace		
		tsset year
		label var log_mfp_govt_fed_bea "Fed. Govt."
		label var log_mfp_govt_statelocal_bea "State and Local Govt."
		label var log_mfp_private_bea "Private Sector"
		label var dmfp_govt_fed_bea "Fed. Govt."
		label var dmfp_govt_statelocal_bea "State and Local Govt."
		label var dmfp_private_bea "Private Sector"		
		tsline log_mfp_govt_fed_bea log_mfp_govt_statelocal_bea log_mfp_private_bea, title("MFP Log Levels") ytitle("Log Value") xtitle("Year") xlabel(1998(3)2013) graphregion(color(white)) bgcolor(white)			
		graph export "Empirical_Analysis/figures/tsline_compare_mfp_log_levels_govt_vs_private.png", replace
		tsline dmfp_govt_fed_bea dmfp_govt_statelocal_bea dmfp_private_bea, title("MFP Growth Rates") ytitle("Change in Log Value") xtitle("Year") xlabel(1998(3)2013) graphregion(color(white)) bgcolor(white)			
		graph export "Empirical_Analysis/figures/tsline_compare_change_in_mfp_log_levels_govt_vs_private.png", replace
		label var dmfp_govt_fed_bea "Fed. Govt. Change in Log of MFP"
		label var dmfp_private_bea "Private Sector Change in Log of MFP"				
		scatter dmfp_govt_fed_bea dmfp_private_bea || lfit dmfp_govt_fed_bea dmfp_private_bea, title("MFP Growth Rates") ytitle("Fed. Govt. Change in Log of MFP") graphregion(color(white)) bgcolor(white)			
		graph export "Empirical_Analysis/figures/scatter_dmfp_govt_fed_bea_dmfp_private_bea.png", replace
		

		
/*********************************************************************************************/		
/*Economic Policy Uncertainty (EPU) indexes from Baker, Bloom and Davis
  downloaded from http://www.policyuncertainty.com/ */
	
	// historical index with data back to 1900 and through 2014m10
	import excel "${rawPath}\Economic Policy Uncertainty\US_Historical_EPU_data.xlsx", sheet("Historical EPU") firstrow case(lower) clear	
	rename news epu_hist_index 
	drop if missing(epu_hist_index)
	destring year, replace
	gen datemo = ym(year, month)
	format datemo %tm
	drop year month
	order datemo
	
	// classify periods based on full sample
	foreach mypctle in 80 90 95 {
		egen epu_hist_full_`mypctle' = pctile(epu_hist_index),  p(`mypctle')	
		gen high_epu_hist_full_`mypctle' = (epu_hist_index>=epu_hist_full_`mypctle')
	}
	
	// classify periods based on sample since 1972
	foreach mypctle in 80 90 95 {
		egen epu_hist_from1972_`mypctle' = pctile(epu_hist_index) if datemo>=ym(1972,1),  p(`mypctle')	
		gen high_epu_hist_from1972_`mypctle' = (epu_hist_index>=epu_hist_from1972_`mypctle') if ~missing(epu_hist_from1972_`mypctle')
	}	

	order datemo epu_hist_index epu_hist_full* high_epu_hist_full* epu_hist_from* high_epu_hist_from*
	save "${dtapath}\epu_hist_index_monthly", replace		

	
	
	// the main index only has data back to 1985 and therefore we use the historical
	// index in our analysis because we need the pre-1985 data.
	import excel "${rawPath}\EconomicPolicyUncertainty\US_Policy_Uncertainty_Data.xlsx", sheet("Main Index") firstrow case(lower) clear	
	rename baseline epu_main_index 
	rename news epu_news_index 
	drop if missing(epu_main_index)
	destring year, replace
	gen datemo = ym(year, month)
	format datemo %tm
	drop year month
	order datemo
	
	// classify periods based on full sample
	foreach myvar in "epu_main" "epu_news" {
	  foreach mypctle in 80 90 95 {
		egen `myvar'_`mypctle' = pctile(`myvar'_index),  p(`mypctle')	
		gen high_`myvar'_`mypctle' = (`myvar'_index>=`myvar'_`mypctle')
	  }	
	  order `myvar'_* high_`myvar'*
	}		
	order datemo epu_main_index epu_news_index
	
	// don't save because we don't want to confuse
	// with the historical index which we will use
	// for analysis because of its longer history
	//save "${dtapath}\epu_main_index_monthly", replace				
		
		
		
/*********************************************************************************************/	
// patent applications and grants at the firm level from Autor et al
// data downloaded from David Dorn's website

	// note: primary assignee is always a corporation
	use "${rawPath}\David Dorn Website\cw_patent_compustat_adhps", clear
	tab corpasg

	// by application year
	use "${rawPath}\David Dorn Website\cw_patent_compustat_adhps", clear
	gen patent_apps=1
	collapse (sum) patent_apps, by(gvkey appyear)
	rename appyear year
	save "${dtapath}\temp_patent_apps", replace		

	// by grant year
	use "${rawPath}\David Dorn Website\cw_patent_compustat_adhps", clear
	gen patent_grants=1
	collapse (sum) patent_grants, by(gvkey gyear)
	rename gyear year
	merge 1:1 gvkey year using "${dtapath}\temp_patent_apps", nogen
	sort gvkey year
	compress
	save "${dtapath}\patent_apps_and_grants_by_gvkey_year", replace			
	
	
/*********************************************************************************************/	
// value of patents by firm
//This data was collected for the paper:
//Kogan, L., Papanikolaou, D., Seru, A. and Stoffman, N., 2017. Technological
//innovation, resource allocation, and growth. Quarterly Journal of Economics, 132(2),
//pp. 665-712.
	
	import excel "${rawPath}\Amit Seru Website\firm_innovation_v2.xlsx", firstrow clear	
	rename Npats patent_grants_kpss
	rename Tcw pat_val_cw
	rename Tsm pat_val_sm
	label var pat_val_cw "Total dollar value of innovation based on citations in millions of USD"
	label var pat_val_sm "Total dollar value of innovation based on stock market in millions of USD"
	keep permno year patent_grants_kpss pat_val_cw pat_val_sm
	save "${dtapath}\kpss_patent_data_by_permno_year", replace			

	
/*********************************************************************************************/	
// firm-level TFP from Imrohoroglu and Tuzel (2014) paper
	
	import excel "${rawPath}\Tuzel Website\TFPData_updated_ImrohorogluTuzel.xlsx", firstrow clear	
	rename gvkey gvkey_num // to avoid confusion
	rename TFP tfp_it2014 // note: TFP is already in logs
	tsset gvkey_num fyear
	//gen dtfp = D1.tfp_it2014
	//summ dtfp, detail // note: there are some extreme values
	//drop dtfp
	save "${dtapath}\tfp_from_IT2014_by_gvkey_year", replace			

	
/*********************************************************************************************/	
// aggregate patent figures from USPTO
	
	// monthly patent stats
	use "${rawPath}\USPTO\monthly", clear	
	gen dateqtr = qofd(dofm(month))
	format dateqtr %tq
	collapse (sum) total_app total_iss , by(dateqtr)
	save "${dtapath}\agg_patent_app_and_iss_by_qtr", replace			

	// double check monthly stats by summing them over year
	// and comparing to annual
	use "${rawPath}\USPTO\monthly", clear	
	gen year = year(dofm(month))
	collapse (sum) total_app_from_monthly=total_app total_iss_from_monthly=total_iss , by(year)
	save "${dtapath}\temp_chk_monthly", replace			
	
				
	// annual patent stats that separate utility patents from US origin
	import excel "${rawPath}\USPTO\us_patent_agg_data.xlsx", sheet("for_import") firstrow clear	
	rename YearofApplicationorGrant year
	//keep year UtilityPatentApplicationsUS UtilityPatentApplicationsAll ///
		//UtilityPatentGrantsUSOrig UtilityPatentGrantsAllOrigi
	// merge on the annual stats downloaded from another part of USPTO website.
	// these data are longer but end in 2014
	merge 1:1 year using "${rawPath}\USPTO\annual", nogen keepusing(total_app total_iss )
	sort year 
	// double check that sum of monthly values equal yearly values
	if 1==0 {
		merge 1:1 year using "${dtapath}\temp_chk_monthly", nogen
		br year total_app* UtilityPatentApplicationsAll  total_iss* UtilityPatentGrantsAllOrigi if ~missing(total_app_from_monthly)
		// conclusion: the monthly values match the annual
		//             from the same part of the website. however
		//             the annual data from other part of website
		//             is slightly diff early in sample and much diff
		//             later in the sample
	}
	// compare annual vars
	if 1==0 {
		br year total_app UtilityPatentApplicationsAll  total_iss UtilityPatentGrantsAllOrigi ///
			if ~missing(UtilityPatentApplicationsAll)
		line total_app UtilityPatentApplicationsAll year  if ~missing(UtilityPatentApplicationsAll)
		// conclusion: annual values match each other early in sample
		//             especially applications but numbers become more
		//             diff in the late 1990s
	}	
	// merge together annual vars
	replace total_app = UtilityPatentApplicationsAll if ~missing(UtilityPatentApplicationsAll)
	//rename UtilityPatentGrantsUSOrig total_app_usa
	rename UtilityPatentApplicationsUS total_app_usa
	replace total_iss = UtilityPatentGrantsAllOrigi if ~missing(UtilityPatentGrantsAllOrigi)
	//rename UtilityPatentApplicationsUS total_iss_usa	
	rename UtilityPatentGrantsUSOrig total_iss_usa	
	// rename other vars
	rename DesignPatentApplications total_design_apps
	rename PlantPatentApplications total_plant_apps
	rename TotalPatentApplications total_apps_incl_design_plant
	rename DesignPatentGrants total_design_grants
	rename PlantPatentGrants total_plant_grants
	rename TotalPatentGrants total_grants_incl_design_plant	
	keep year total_*
	save "${dtapath}\agg_patent_app_and_iss_by_year", replace				
				


/*********************************************************************************************/	
// compute total market cap

	// aggregate market values
	use "${rawPath}\CRSP\crsp_vw_market", clear	
	
	// TOTCNT is the number of stocks in the current file with a valid price. 
	
	//TOTVAL contains the total market value for a given market, in $1000's, 
	// for all non-ADR securities with valid prices.
	gen agg_mkt_cap_mlns = totval / 10^3
	gen dateqtr = yq(year(date), quarter(date))
	format dateqtr %tq
	tab date if dateqtr==yq(2010,1)
	gen year = year(date)
	collapse (mean) avg_agg_mkt_cap_mlns=agg_mkt_cap_mlns, by(year)
	
	save "${dtapath}\agg_mkt_cap_avg_by_year", replace				
	
	
	
	
/*********************************************************************************************/		
// Government bond return data sent by Steve Raymond
	
	/*import monthly data worksheet*/
	import excel "${rawPath}\Government Bond Returns\from Steve Raymond\us_hpr_debt.xlsx", sheet("hpr") firstrow case(lower) clear
	destring year, replace force
	drop if missing(year)
	gen datemo = ym(year,month)
	format datemo %tm
	drop if missing(datemo)
	order datemo
	keep datemo hall_ret
	destring hall_ret, replace force
	drop if missing(hall_ret) // 2019 or some years in the 1800s with NAN
	tsset datemo	
	save "${dtapath}\govt_bond_return_hall_monthly", replace		
	
	

/*********************************************************************************************/	
// treasury yields

	// downloaded from https://www.federalreserve.gov/pubs/feds/2006/200628/200628abs.html
	import excel "${rawPath}\Asaf Manela Website\nvix_and_categories_timeseries_mar2016.xlsx", ///
		firstrow case(lower) clear sheet("news_implied_volatility")
	rename date datenum
	tostring datenum, gen(datestr)
	gen date = date(datestr,"YMD")
	format date %td
	order date
	keep date nvix
	save "${dtapath}\nvix_by_date", replace		
	