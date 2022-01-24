// assemble dataset of annual data 1929-2016 for computing the data moments
// in the data vs moments table

/*********************************************************************************************/	
/*housekeeping*/

	set more off

	/*change to project directory (exact file path differs by user)*/
	cd "C:\Users\tuk40836\Dropbox\Research\BCLR\1_SafeCapital"
	
	/*path where analysis specific intermediate or final datasets are saved*/
	global dtapath = "Empirical_Analysis\dta"
	global outPath = "Empirical_Analysis\data_for_data_moments"

	
/*********************************************************************************************/	
// investigate other moments that we are intersted in but may not include in main data table	
	
	// private to govt labor share
	use "${dtapath}\national_employment_monthly", replace
	gen frac_priv_empl_v1 = employees_priv_all_sa / employees_total_sa
	gen frac_priv_empl_v2 = employees_priv_all_sa / (employees_priv_all_sa+employees_govt_all_sa)
	summ frac_priv_empl_v1 frac_priv_empl_v2
	tsset datemo
	//tsline frac_priv_empl_v1 frac_priv_empl_v2
	
	// govt wages
	use "${dtapath}\bea_quarterly_additional_saving_investment_series", replace
	// govt_wages
	
	// govt labor data gathered feb 2021
	use "${dtapath}\bea_labor_data_annual", clear
	keep year emp_wages_priv emp_wages_govt
	merge 1:1 year using "${dtapath}\bea_labor_data_annual_from_monthly", nogen keep(master match) keepusing(emp_govt_all_sa emp_priv_all_sa)	
	tsset year
	//tsline emp_wages_govt emp_wages_priv	
	foreach myvar in ///
		"emp_wages_govt" "emp_wages_priv" /// "emp_wages_total" 
		"emp_govt_all_sa_avg" "emp_priv_all_sa_avg" /// "emp_total_all_sa_avg" 
		/// "w_priv" "w_govt" "w_total" ///
	{
		gen logvar = log(`myvar')
		gen d1_log_`myvar' = 100*d1.logvar
		drop logvar
	}
	if 1==0 {
		label var d1_log_emp_wages_govt "Govt"
		label var d1_log_emp_wages_priv "Private"
		tsline d1_log_emp_wages_govt d1_log_emp_wages_priv if year<=2019, title("Growth Rates in Wage Compenstation")
		graph export "Empirical_Analysis/figures/tsline_d1_log_emp_wages_govt_vs_priv.png", replace
		label var d1_log_emp_govt_all_sa_avg "Govt"
		label var d1_log_emp_priv_all_sa_avg "Private"		
		tsline d1_log_emp_govt_all_sa_avg d1_log_emp_priv_all_sa_avg if year<=2019, title("Growth Rates in Employees")
		graph export "Empirical_Analysis/figures/tsline_d1_log_emp_govt_all_sa_avg_vs_priv.png", replace
		gen ratio_emp_priv_to_govt = emp_priv_all_sa / emp_govt_all_sa 
		tsline ratio_emp_priv_to_govt if year<=2019, title("Ratio of Private Employees to Govt Employees")
		graph export "Empirical_Analysis/figures/tsline_ratio_emp_priv_to_govt.png", replace
		gen pct_emp_priv_to_govt = 100 * emp_priv_all_sa / (emp_priv_all_sa+emp_govt_all_sa )
		tsline pct_emp_priv_to_govt if year<=2019, title("Private Employees as Percent of Total Employees")
		graph export "Empirical_Analysis/figures/tsline_pct_emp_priv_to_govt.png", replace		
	}
	
	// persistence and vol of quarterly productivity growth, consumption growth, and output growth
	use "${dtapath}\bea_quarterly", clear
	keep dateqtr pce_real gdp_real gdp_per_capita_real gdp_va_busi_real 
	merge 1:1 dateqtr using "${dtapath}\tfp_data_from_frbsf_quarterly", keepusing(dtfp_busi_sector_reg_frbsf dy)
	gen dtfp = dtfp_busi_sector_reg_frbsf/100 // put in decimal for consistency with shares that are in decimals
	gen temp_dtfp_qtr = dtfp/4
	tsset dateqtr
	sort dateqtr
	gen tfp = sum(temp_dtfp_qtr)
	replace tfp = . if tfp==0	
	tsset dateqtr
	
	// test out persistence calulations
	newey pce_real L1.pce_real, lag(4)
	gen ln_pce_real = ln(pce_real)
	ivreg2 ln_pce_real L1.ln_pce_real, robust bw(auto)
	gen dpce_real = D1.ln_pce_real
	newey dpce_real L1.dpce_real, lag(4)
	ivreg2 dpce_real L1.dpce_real, robust bw(4)
	ivreg2 dpce_real L1.dpce_real, robust bw(auto)
	tsfilter hp pce_real_dt=ln_pce_real, smooth(1600) // set lambda=1600 for quarterly data
	//tsline pce_real_dt
	ivreg2 pce_real_dt L1.pce_real_dt, robust bw(4)
	ivreg2 pce_real_dt L1.pce_real_dt, robust bw(auto)
	drop ln_pce_real pce_real_dt dpce_real
	
	// run for each macro variable
	foreach myvar in "pce_real" "gdp_real" "gdp_va_busi_real" {
		gen ln_`myvar' = ln(`myvar')
		qui gen d`myvar' = D1.ln_`myvar'
		ivreg2 d`myvar' L1.d`myvar', robust bw(auto)
		qui tsfilter hp `myvar'_dt=ln_`myvar', smooth(1600) // set lambda=1600 for quarterly data
		ivreg2 `myvar'_dt L1.`myvar'_dt, robust bw(auto)
		drop ln_`myvar' `myvar'_dt d`myvar'	
	}
	
	// run for dtfp
	ivreg2 dtfp L1.dtfp, robust bw(auto)

	
	
/*********************************************************************************************/	
// assemble the annual dataset

	// monthly inflation from BLS CPI
	use "${dtapath}\bls_cpi_monthly", clear				
	tsset datemo
	gen inflation = cpi / L1.cpi - 1
	keep datemo inflation
	gen inflation_deflator = (1+inflation)/(1+l1.inflation)	
	save "${dtapath}\temp_inflation_deflator_for_rf", replace	
	
	// annual inflation from BLS CPI
	use "${dtapath}\bls_cpi_monthly", clear				
	keep if month(dofm(datemo))==12
	gen year = year(dofm(datemo))
	tsset year
	gen inflation = cpi / L1.cpi - 1	
	keep year inflation
	save "${dtapath}\temp_annual_inflation", replace	
	

	// create annual market excess return and annual real risk-free rate
	use "${dtapath}\famafrench_monthly_factors", replace
	merge 1:1 datemo using "${dtapath}\temp_inflation_deflator_for_rf", keep(master match)
	//gen rf_real = (1+rf/100)/inflation_deflator - 1	
	//gen rf_real = rf/100 - inflation
	gen year = year(dofm(datemo))
	gen ln_mktrf = ln(1+mktrf/100)
	gen ln_mkt = ln(1+(mktrf+rf)/100)
	gen ln_rf_nom = ln(1+rf/100)
	//gen ln_rf_real = ln(1+rf_real)
	collapse (sum) ln_mktrf ln_mkt ln_rf_nom /// ln_rf_real
		(count) N=ln_mktrf, by(year)
	keep if N==12 // require full year
	gen mktrf = 100*(exp(ln_mktrf)-1)
	gen rf_nom = 100*(exp(ln_rf_nom)-1)
	//gen rf_real = 100*(exp(ln_rf_real)-1)
	merge 1:1 year using "${dtapath}\temp_annual_inflation", keep(master match)
	gen rf_real = 100*((1+rf_nom/100)/(1+inflation) - 1)
	gen ln_rf_real = ln(1+rf_real/100)
	//keep year mktrf rf_nom rf_real
	keep year ln_mktrf ln_rf_real mktrf rf_real ln_rf_nom rf_nom
	save "${dtapath}\mktrf_and_rf_annual_for_data_moments", replace
	//line ln_rf_real year
	keep if year>=1929
	keep if year<=2016
	collapse (mean) mktrf rf_real ln_rf_real (sd) sd_mktrf=mktrf sd_rf_real=rf_real
	list mktrf sd_mktrf rf_real sd_rf_real ln_rf_real
 
 
	// create annual govt bond excess return 
	use "${dtapath}\famafrench_monthly_factors", replace
	merge 1:1 datemo using "${dtapath}\govt_bond_return_hall_monthly", keep(master match)
	gen year = year(dofm(datemo))
	gen ln_hall_ret = ln(1+hall_ret)
	gen ln_ex_hall_ret = ln(1+hall_ret-rf/100)
	collapse (sum) ln_hall_ret ln_ex_hall_ret /// ln_rf_real
		(count) N=ln_ex_hall_ret, by(year)
	keep if N==12 // require full year
	gen ex_hall_ret = 100*(exp(ln_ex_hall_ret)-1)
	gen hall_ret= 100*(exp(ln_hall_ret)-1)
	//keep year mktrf rf_nom rf_real
	keep year ln_ex_hall_ret ex_hall_ret // hall_ret ln_ex_hall_ret 
	save "${dtapath}\hall_ret_for_data_moments", replace
	//line ln_rf_real year
	keep if year>=1929
	keep if year<=2016
	preserve
		collapse (mean) ln_ex_hall_ret ex_hall_ret // hall_ret ln_ex_hall_ret 
		list 
	restore
	preserve
		collapse (sd) ln_ex_hall_ret ex_hall_ret // hall_ret ln_ex_hall_ret 
		list 
	restore 
 
 
	/*gdp components*/
	use "${dtapath}\bea_annual", clear
	keep year ///
		gdp_nom gdp_real ///
		gdp_per_capita_nom ///
		govt_con_and_inv_nom govt_con_and_inv_real ///
		pce_nom pce_real consumption_govt_fed consumption_govt_snl ///
		gross_private_investment_real gross_private_investment_nom ///
		gross_priv_inv_nom /// Nominal Gross Private Fixed Investment
		gross_govt_inv_nom /// Nominal Gross Govt Investment		
		gross_fpi_ipp_rnd
	// note: gross_private_investment contains investment in inventories, which
	//       we do not want to include. I am only using these two series to get
	//       a deflator for comparing nominal and real values
	
	// fixed assets (or book capital or produced assets) from the BEA
	merge 1:1 year using "${dtapath}\bea_fixed_assets_tables_data_annual", nogen keep(master match) 
	/*descriptions:
		priv_fa_tot: "Produced Fixed Assets (Private), Billions of Dollars"	
		govt_fa_tot: "Produced Fixed Assets (Govt), Billions of Dollars"
	*/		
	
	// returns
	merge 1:1 year using "${dtapath}\mktrf_and_rf_annual_for_data_moments", keep(master match) nogen
	merge 1:1 year using "${dtapath}\hall_ret_for_data_moments", keep(master match) nogen
	
	// compute potential deflators for computing real total investment (private + govt)
	gen real_deflator_inv = gross_private_investment_nom/gross_private_investment_real
	gen real_deflator_gdp = gdp_nom/gdp_real
	gen real_deflator_pce = pce_nom/pce_real
	
	// compute potential deflators for computing real total investment (private + govt)
	gen itot_nom  = (gross_priv_inv_nom+gross_govt_inv_nom)
	gen itot_real = itot_nom/real_deflator_inv
	gen ip_fixed_real_tot = gross_priv_inv_nom/real_deflator_inv // we have real total private investment (gross_private_investment_real) but annual series only available back to 1967 for fixed
	
	/*compute ratios variables of interest*/	
	gen ig_itot = 100*gross_govt_inv_nom / itot_nom
	gen ip_y = 100*gross_priv_inv_nom / gdp_nom
	gen ig_y = 100*gross_govt_inv_nom / gdp_nom
	gen kg_ktot = 100 * govt_fa_tot / (govt_fa_tot+priv_fa_tot)	
	
	/*back out population in billions from per capital vars*/
	// note: gdp_nom is in billions and gdp_per_capita_nom is in dollars
	gen pop_billions = gdp_nom / gdp_per_capita_nom
	
	// labor data 
	merge 1:1 year using "${dtapath}\bea_labor_data_annual", nogen keep(master match) keepusing(emp_wages_priv emp_wages_govt)
	merge 1:1 year using "${dtapath}\bea_labor_data_annual_from_monthly", nogen keep(master match) keepusing(emp_govt_all_sa emp_priv_all_sa)
	
	// total employment and compensation
	gen emp_wages_total = emp_wages_govt + emp_wages_priv 
	gen emp_total_all_sa_avg = emp_govt_all_sa_avg + emp_priv_all_sa_avg
	
	// back out wages
	foreach myvar in "priv" "govt" "total" {
		gen w_`myvar' = 1000*emp_wages_`myvar' / emp_`myvar'_all_sa_avg
	}
	
	// employment ratios
	gen ratio_emp_priv_to_govt  = emp_priv_all_sa / emp_govt_all_sa 
	gen ratio_emp_priv_to_total = 100 * emp_priv_all_sa / (emp_priv_all_sa+emp_govt_all_sa)
	
	/*rename vars for consistency*/
	rename gdp_nom  gdp_nom_tot
	rename gdp_real gdp_real_tot
	
	rename gdp_per_capita_nom  gdp_nom_percap
	gen gdp_real_percap  = gdp_real / pop_billions
	
	rename pce_nom  pce_nom_tot
	gen pce_nom_percap  = pce_nom_tot / pop_billions	
	
	rename pce_real pce_real_tot	
	gen pce_real_percap = pce_real_tot / pop_billions

	gen ctot_nom_tot = pce_nom_tot + consumption_govt_fed + consumption_govt_snl
	gen ctot_nom_percap = ctot_nom_tot / pop_billions	
	
	rename itot_nom itot_nom_tot
	gen itot_nom_percap  = itot_nom_tot / pop_billions

	rename itot_real itot_real_tot
	gen itot_real_percap  = itot_real_tot / pop_billions	
	
	rename gross_priv_inv_nom ip_nom_tot
	gen ip_nom_percap = ip_nom_tot / pop_billions	
	
	rename gross_private_investment_real ip_real_tot
	gen ip_real_percap  = ip_real_tot / pop_billions
	
	// fixed private investment important distinction from total private investment which includes inventories
	gen ip_fixed_real_percap  = ip_fixed_real_tot / pop_billions	
	
	rename gross_govt_inv_nom ig_nom_tot
	gen ig_nom_percap = ig_nom_tot / pop_billions	

	rename gross_fpi_ipp_rnd ip_rnd_real_tot
	gen ip_rnd_real_percap  = ip_rnd_real_tot / pop_billions			
	
	/*compute growth rates*/
	tsset year
	foreach myvar in "gdp_nom_tot" "gdp_real_tot" "gdp_nom_percap" "gdp_real_percap" ///
		"pce_nom_tot" "pce_real_tot" "pce_nom_percap" "pce_real_percap" ///
		"ctot_nom_tot" "ctot_nom_percap" ///
		"itot_nom_tot" "itot_nom_percap" "itot_real_tot" "itot_real_percap" ///
		"ip_nom_tot" "ip_nom_percap" "ip_real_tot" "ip_real_percap" "ip_fixed_real_tot" "ip_rnd_real_percap" "ip_fixed_real_percap" ///
		"ig_nom_tot" "ig_nom_percap" ///
		"emp_wages_govt" "emp_wages_priv" "emp_wages_total" ///
		"emp_govt_all_sa_avg" "emp_priv_all_sa_avg" "emp_total_all_sa_avg" ///
		"w_priv" "w_govt" "w_total" ///
	{
		gen logvar = log(`myvar')
		gen d1_log_`myvar' = 100*d1.logvar
		drop logvar
	}	

	
	// drop beyond date range for consistency
	keep if year >= 1929
	//keep if year <= 2014
	keep if year <= 2016
	
	// keep only needed vars and export
	gen fakevar=0 // b/c last column of csv always read into matlab as cell array
	keep year ip_y ig_y ig_itot kg_ktot d1_* ///
		ln_mktrf ln_rf_real mktrf ///
		ln_ex_hall_ret ex_hall_ret ///
		rf_real ln_rf_nom rf_nom ///
		ratio_emp_priv_to_govt ratio_emp_priv_to_total /// 
		fakevar
	outsheet using "${outPath}\data_for_moment_calcs_ann.csv", replace comma

	
	
	// pick data series most analogous to model
	gen dy  = d1_log_gdp_real_percap 
	gen dc  = d1_log_pce_real_percap 
	gen dip = d1_log_ip_fixed_real_percap // fixed private investment excludes inventory investment 	
	gen dip_rnd = d1_log_ip_rnd_real_percap // private R&D investment
	gen ditot = d1_log_itot_real_percap
	keep year dy dc dip dip_rnd ditot ip_y ig_y ig_itot d1_log_emp* d1_log_w* ratio_emp_priv_to_govt ratio_emp_priv_to_total

	// correlations and autocorrelation
	corr dc dip
	local corr_dc_dip = r(rho)
	corrgram dc, lags(1)
	matrix acf_dc = e(b)
	local acf_dc = acf_dc[1,1]
	corr d1_log_emp_govt_all_sa_avg d1_log_emp_priv_all_sa_avg
	local corr_demppriv_dempgovt = r(rho)
	
	// compute summary stats
	collapse (sd) sd_dy=dy sd_dc=dc sd_ditot=ditot sd_dip_rnd=dip_rnd sd_ip_y=ip_y sd_ig_itot=ig_itot sd_ig_y=ig_y ///
				d1_log_emp_wages_govt d1_log_emp_wages_priv d1_log_emp_wages_total /// 
				d1_log_emp_govt_all_sa_avg d1_log_emp_priv_all_sa_avg d1_log_emp_total_all_sa_avg ///
				d1_log_w_priv d1_log_w_govt d1_log_w_total ///
				ratio_emp_priv_to_govt ratio_emp_priv_to_total ///
			(mean) mean_ip_y=ip_y mean_ig_itot=ig_itot mean_ig_y=ig_y
	gen ratio_sd_dc_dy    = sd_dc    / sd_dy
	gen ratio_sd_ditot_dy = sd_ditot / sd_dy
	gen ratio_sd_dip_rnd_dy = sd_dip_rnd / sd_dy
	gen corr_dc_dip = `corr_dc_dip'
	gen corr_demppriv_dempgovt = `corr_demppriv_dempgovt'
	gen acf_dc = `acf_dc'
	order sd_dy ratio_sd_dc_dy ratio_sd_ditot_dy sd_dip_rnd ratio_sd_dip_rnd_dy mean_ip_y sd_ip_y corr_dc_dip acf_dc mean_ig_itot sd_ig_itot mean_ig_y sd_ig_y d1_log_emp* d1_log_w* corr_demppriv_dempgovt ratio_emp_*
	keep  sd_dy ratio_sd_dc_dy ratio_sd_ditot_dy sd_dip_rnd ratio_sd_dip_rnd_dy mean_ip_y sd_ip_y corr_dc_dip acf_dc mean_ig_itot sd_ig_itot mean_ig_y sd_ig_y d1_log_emp* d1_log_w* corr_demppriv_dempgovt ratio_emp_*
	format * %9.2f
	



	
	