/*export macro data (both nominal and real) for use in VAR analysis that are 
  used to create IRF output*/


/*housekeeping*/

	set more off

	/*change to project directory (exact file path differs by user)*/
	cd "C:\Users\tuk40836\Dropbox\Research\BCLR\1_SafeCapital"
	
	/*path where analysis specific intermediate or final datasets are saved*/
	global dtapath     = "Empirical_Analysis\dta"
	global PUdatapath  = "Empirical_Analysis\data_for_Productivity_Uncertainty"
	global VARdatapath = "Empirical_Analysis\data_for_VAR"
	global rawPath = "Empirical_Analysis\raw"

	
/*********************************************************************************************/		
// private output as a percent of GDP

	// national aggregates
	use "${dtapath}\bea_quarterly", clear
	keep dateqtr ///
		 gdp_real gdp_nom /// GDP
		 gross_va_govt_nom /// govt output
		 gdp_va_busi_nom gdp_va_busi_real /// private output
		 

	// ratio
	gen Yp_over_GDP = gdp_va_busi_nom / gdp_nom
	gen Yg_over_GDP = gross_va_govt_nom / gdp_nom
	gen Yp_over_Yp_plus_Yg = gdp_va_busi_nom / (gdp_va_busi_nom+gross_va_govt_nom)
	//gen Yp_real_over_GDP_real = gdp_va_busi_real / gdp_real
	
	tsset dateqtr
	//tsline Yp_over_GDP Yg_over_GDP
	//tsline Yp_over_Yp_plus_Yg
	
	
	
/*********************************************************************************************/		
// components of GDP

	// national aggregates
	use "${dtapath}\bea_quarterly", clear
	keep dateqtr ///
		 gdp_real gdp_nom /// GDP
		 pce_real pce_nom /// Consumption
		 gross_priv_inv_incl_inventories /// below we combine with gross_private_investment_real to deflate nominal values to real
		 govt_con_and_inv_nom /// Government Consumption Expenditures and Gross Investment
		 gross_priv_inv_nom /// Nominal Gross Private Fixed Investment
		 gross_govt_inv_nom /// Nominal Gross Govt Investment
		 gross_govt_inv_nom_ipp gross_govt_inv_nom_rnd ///
		 gdp_va_busi_nom gdp_va_busi_real /// gdp value added measures
		 nonfin_corp_net_worth nonfin_corp_equity_mkt  // for computing agg Tobin's Q
	
	
	gen C_Y = pce_nom / gdp_nom
	gen Ip_Y = gross_priv_inv_incl_inventories / gdp_nom
	gen Ig_Y = gross_govt_inv_nom / gdp_nom
	gen G_Y = govt_con_and_inv_nom / gdp_nom
	gen Cg_Y = (govt_con_and_inv_nom-gross_govt_inv_nom) / gdp_nom
	
	tsset dateqtr
	//tsline C_Y Ip_Y Ig_Y Cg_Y G_Y
	//tsline Ip_Y Ig_Y Cg_Y G_Y
	
	
/*********************************************************************************************/		
// check out patent measures


	// aggregate by quarter
	use "${dtapath}\agg_patent_app_and_iss_by_qtr", clear

	
	// aggregate by year
	use "${dtapath}\agg_patent_app_and_iss_by_year", clear	

	
	// annual counts by firm
	use "${dtapath}\patent_apps_and_grants_by_gvkey_year", clear
	
		// rename to avoid confusion
		rename patent_grants agg_compustat_patent_grants
		rename patent_apps agg_compustat_patent_apps
	
		// sum by year
		collapse (sum) agg_comp*, by(year)
		
		// normalize by GDP
		merge 1:1 year using "${dtapath}\bea_annual", nogen keep(master match) keepusing(gdp_nom)
		gen agg_compustat_patent_grants_gdp = agg_compustat_patent_grants/gdp_nom
		gen agg_compustat_patent_apps_gdp = agg_compustat_patent_apps/gdp_nom
		drop gdp_nom
		
		// drop years with data issues
		drop if year<1974
		drop if year>2012
		tsset year
		//tsline agg_compustat_patent_grants_gdp agg_compustat_patent_apps_gdp
		replace agg_compustat_patent_grants = . if year<1975
		replace agg_compustat_patent_grants_gdp = . if year<1975
		replace agg_compustat_patent_apps = . if year>2010
		replace agg_compustat_patent_apps_gdp = . if year>2010

		
		save "${dtapath}\agg_compustat_patent_measures", replace		

	
	// annual value by firm
	use "${dtapath}\kpss_patent_data_by_permno_year", clear
	
		// sum by year and then normalize by agg stock market cap
		collapse (sum) agg_pat_val_cw=pat_val_cw agg_pat_val_sm=pat_val_sm, by(year)
			
		// normalize by agg stock market cap
		merge 1:1 year using "${dtapath}\agg_mkt_cap_avg_by_year", nogen keep(master match)
		gen agg_pat_val_cw_to_mkt = agg_pat_val_cw / avg_agg_mkt_cap_mlns
		gen agg_pat_val_sm_to_mkt = agg_pat_val_sm / avg_agg_mkt_cap_mlns
		
		tsset year	
		//tsline agg_pat_val_cw_to_mkt agg_pat_val_sm_to_mkt
		//tsline agg_pat_val_cw_to_mkt agg_pat_val_sm_to_mkt if year>=1960
		keep year agg_*
		save "${dtapath}\agg_pat_val_to_mkt_measures", replace			
	
	
	
/*********************************************************************************************/		
// check relationship between saving and investment vars

	use "${dtapath}\bea_quarterly_additional_saving_investment_series", clear
		
	// rename to make the same as the other vars
	rename gross_priv_inv_incl_inventories Ip_incl_inv_nom
	rename gross_govt_inv_nom Ig_nom	
	rename priv_saving Sp_nom
	rename govt_saving Sg_nom
	gen CA_nom_net = curr_acct_nipa - curr_acct_stat_discrep // net value to make eqn hold
		
	// confirm relationship
	gen chkdiff = (Ig_nom - Sg_nom) - (Sp_nom - Ip_incl_inv_nom - CA_nom_net)
	summ chkdiff, detail	
	
	// check govt wages proportion
	gen pct_G_wages = govt_wages / govt_con_and_inv_nom
	gen pct_Cg_wages = govt_wages / (govt_con_and_inv_nom - Ig_nom	)
	tsset dateqtr 
	//tsline pct_Cg_wages pct_G_wages
	summ pct_Cg_wages pct_G_wages, detail
	
	
	// convert to percents and check averages
	gen Sp_Y = 100*Sp_nom / gdp_nom
	gen Ip_Y = 100*Ip_incl_inv_nom / gdp_nom
	gen Sg_Y = 100*Sg_nom / gdp_nom
	gen Ig_Y = 100*Ig_nom / gdp_nom	
	gen CA_Y = 100*CA_nom_net / gdp_nom
	
	
	/*our integrated volatility measure (see 01 program)*/
	merge 1:1 dateqtr using "${dtapath}\integrated_volatility_quarterly", nogen noreport keep(master match) keepusing(ivol)
	// note: ivol is quarterly in percent
	
	// ratio averages by ivol bin
	
		tab dateqtr
		keep if dateqtr>=yq(1947,1) & dateqtr<=yq(2016,4) // our sample period at least from figures
		
		// percentiles
		summ ivol, detail
		egen ivol_pctile_25=pctile(ivol), p(25)
		egen ivol_pctile_33=pctile(ivol), p(33)
		egen ivol_pctile_50=pctile(ivol), p(50)
		egen ivol_pctile_67=pctile(ivol), p(67)
		egen ivol_pctile_75=pctile(ivol), p(75)
		egen ivol_pctile_90=pctile(ivol), p(90)
		egen ivol_pctile_95=pctile(ivol), p(95)
		
		// bin: 2 groups
		gen ivol_2bin = 2
		replace ivol_2bin = 1 if ivol<=ivol_pctile_50
		tab ivol_2bin

		// bin: 3 groups
		gen ivol_3bin = 2
		replace ivol_3bin = 1 if ivol<=ivol_pctile_33
		replace ivol_3bin = 3 if ivol>=ivol_pctile_67
		tab ivol_3bin
		
		// bin: 4 groups
		gen ivol_4bin = 3
		replace ivol_4bin = 1 if ivol<=ivol_pctile_25
		replace ivol_4bin = 2 if ivol> ivol_pctile_25 & ivol<=ivol_pctile_50
		replace ivol_4bin = 4 if ivol> ivol_pctile_75
		tab ivol_4bin		
		
		// extreme vol bins
		gen ivol_ge_90 = (ivol>=ivol_pctile_90)
		gen ivol_ge_95 = (ivol>=ivol_pctile_95)
		
		// extreme vol bin as great recession
		gen is_great_recession = (dateqtr>=yq(2007,4) & dateqtr<=yq(2009,2))
		
		
		// averages
		preserve
			collapse (mean) Sp_Y Ip_Y Sg_Y Ig_Y CA_Y
			list
			export excel using "Empirical_Analysis\output_for_paper\check_saving_investment_ratio_means\check_saving_investment_ratio_means.xlsx", sheet("overall_means") sheetreplace firstrow(var)
		restore		
		preserve
			collapse (mean) Sp_Y Ip_Y Sg_Y Ig_Y CA_Y, by(ivol_2bin)
			list
			export excel using "Empirical_Analysis\output_for_paper\check_saving_investment_ratio_means\check_saving_investment_ratio_means.xlsx", sheet("bin2_means") sheetreplace firstrow(var)
		restore
		preserve
			collapse (mean) Sp_Y Ip_Y Sg_Y Ig_Y CA_Y, by(ivol_3bin)
			export excel using "Empirical_Analysis\output_for_paper\check_saving_investment_ratio_means\check_saving_investment_ratio_means.xlsx", sheet("bin3_means") sheetreplace firstrow(var)
			list
		restore
		preserve
			collapse (mean) Sp_Y Ip_Y Sg_Y Ig_Y CA_Y, by(ivol_4bin)
			export excel using "Empirical_Analysis\output_for_paper\check_saving_investment_ratio_means\check_saving_investment_ratio_means.xlsx", sheet("bin4_means") sheetreplace firstrow(var)
			list
		restore	
		preserve
			collapse (mean) Sp_Y Ip_Y Sg_Y Ig_Y CA_Y, by(ivol_ge_90)
			export excel using "Empirical_Analysis\output_for_paper\check_saving_investment_ratio_means\check_saving_investment_ratio_means.xlsx", sheet("bin_ge90_means") sheetreplace firstrow(var)
			list
		restore				
		preserve
			collapse (mean) Sp_Y Ip_Y Sg_Y Ig_Y CA_Y, by(ivol_ge_95)
			export excel using "Empirical_Analysis\output_for_paper\check_saving_investment_ratio_means\check_saving_investment_ratio_means.xlsx", sheet("bin_ge95_means") sheetreplace firstrow(var)
			list
		restore						
		preserve
			collapse (mean) Sp_Y Ip_Y Sg_Y Ig_Y CA_Y, by(is_great_recession)
			export excel using "Empirical_Analysis\output_for_paper\check_saving_investment_ratio_means\check_saving_investment_ratio_means.xlsx", sheet("bin_greatrec_means") sheetreplace firstrow(var)
			list
		restore		

	//tsline Ig_Y, title("Ig/Y")
	//tsline Sg_Y, title("Sg/Y")
	//tsline CA_Y, title("CA/Y")
	collapse (mean) Sp_Y Ip_Y Sg_Y Ig_Y CA_Y
	
	gen Sp_Y_minus_Ip_Y = Sp_Y - Ip_Y
	gen Ig_minus_Sg_plus_CA = Ig_Y - Sg_Y + CA_Y

	
	
	
/*********************************************************************************************/		
// productivity uncertainty measure computed in Wenxi's "measure_productivity_uncertainty.m"

	import delimited "${PUdatapath}\data_for_PU_measure_1961_2016.csv", clear
	

	
/*********************************************************************************************/		
// convert monthly data to quarterly

	use "${dtapath}\national_employment_monthly", replace			
	
	// check total employment
	gen test_all = employees_total_sa - employees_govt_all_sa - employees_priv_all_sa
	summ test_all, detail
	// conclusion: yes, it is the total of govt and private.
	
	// compute shares
	gen labor_share_govt = employees_govt_all_sa / (employees_govt_all_sa + employees_priv_all_sa)
	gen labor_share_priv = employees_priv_all_sa / (employees_govt_all_sa + employees_priv_all_sa)
	
	// keep levels but rename
	rename employees_govt_all_sa labor_govt
	rename employees_priv_all_sa labor_priv
	gen labor_tot = labor_govt + labor_priv
	gen ln_labor_govt = ln(labor_govt)
	gen ln_labor_priv = ln(labor_priv)
	gen ln_labor_tot  = ln(labor_tot)
	
	// use end-of-quarter values
	gen month = month(dofm(datemo))
	tab month
	keep if inlist(month,3,6,9,12)
	gen dateqtr = yq(year(dofm(datemo)), quarter(dofm(datemo)))
	format dateqtr %tq

	//line labor_share_priv dateqtr
	//line labor_share_priv dateqtr if dateqtr>=yq(1970,1)
	
	order dateqtr labor_share_govt labor_share_priv labor_govt labor_priv labor_tot ln_labor_govt ln_labor_priv ln_labor_tot
	keep  dateqtr labor_share_govt labor_share_priv labor_govt labor_priv labor_tot ln_labor_govt ln_labor_priv ln_labor_tot
	save "${dtapath}\temp_labor_share_qtr", replace
	

	
/*********************************************************************************************/		
// check how big government R&D investment is
	
use "${dtapath}\bea_quarterly", clear

// share of R&D investment within govt
	
	gen pct_rnd_gross_govt_inv_nom = 100 * gross_govt_inv_nom_rnd / gross_govt_inv_nom
	line pct_rnd_gross_govt_inv_nom dateqtr, title("Govt. Investment Share of R&D") ytitle("Percent")
	graph export "Empirical_Analysis/figures/line_pct_rnd_gross_govt_inv_nom_dateqtr.png", replace

	
// aggregate share of R&D investment including govt

	gen ipprnd_ip_privonly = 100 * gross_fpi_ipp_rnd / gross_priv_inv_nom	
	
	gen ipprnd_ip_combined = 100 * (gross_fpi_ipp_rnd + gross_govt_inv_nom_rnd) / (gross_priv_inv_nom+gross_govt_inv_nom)
	
	gen ipprnd_ip_govtonly = 100 * gross_govt_inv_nom_rnd / gross_govt_inv_nom
	
	label var ipprnd_ip_privonly "Priv. Only (Benchmark)"
	label var ipprnd_ip_combined "Priv. + Govt."
	label var ipprnd_ip_govtonly "Govt. Only"
	line ipprnd_ip_govtonly ipprnd_ip_combined ipprnd_ip_privonly dateqtr, title("Compare R&D Investment Shares") ytitle("Percent") lpattern(solid dash solid)
	graph export "Empirical_Analysis/figures/line_ipprnd_ip_by_group_dateqtr.png", replace
	
	
// total real R&D investment with and without govt	
	
	gen gross_inv_rnd_priv_and_pub = gross_fpi_ipp_rnd + gross_govt_inv_nom_rnd	
	
	gen inv_deflate = gross_priv_inv_incl_inventories / gross_private_investment_real
	gen gross_inv_rnd_priv_only_real = gross_fpi_ipp_rnd / inv_deflate	
	gen gross_inv_rnd_priv_and_pub_real = gross_inv_rnd_priv_and_pub / inv_deflate
	
	label var gross_inv_rnd_priv_and_pub_real "Priv. + Govt."	
	label var gross_inv_rnd_priv_only_real "Priv. Only (Benchmark)"
	
	line gross_inv_rnd_priv_and_pub_real gross_inv_rnd_priv_only_real dateqtr, ///
		title("Real R&D Investment: Including Govt. (Full)") ///
		ytitle("Real Dollars") yscale(log)
	graph export "Empirical_Analysis/figures/line gross_inv_rnd_priv_and_pub_real_gross_inv_rnd_priv_only_real_dateqtr_full.png", replace		
	
	line gross_inv_rnd_priv_and_pub_real gross_inv_rnd_priv_only_real dateqtr if dateqtr>=yq(1972,1), ///
		title("Real R&D Investment: Including Govt. (From 1972)") ///
		ytitle("Real Dollars") yscale(log)
	graph export "Empirical_Analysis/figures/line gross_inv_rnd_priv_and_pub_real_gross_inv_rnd_priv_only_real_dateqtr_since1972.png", replace		
	
	
	
/*********************************************************************************************/		
// check how big government defense R&D investment is
	
use "${dtapath}\bea_quarterly_specific_govt_inv_series", clear	
	
	gen chk_govt_rnd_inv_v1 = (govt_fed_nondef_inv_nom_rnd + govt_fed_def_inv_nom_rnd + govt_snl_inv_nom_rnd) - gross_govt_inv_nom_rnd
	summ chk_govt_rnd_inv_v1, detail

	gen chk_govt_rnd_inv_v2 = (govt_fed_inv_nom_rnd + govt_snl_inv_nom_rnd) - gross_govt_inv_nom_rnd
	summ chk_govt_rnd_inv_v2, detail	
	
	gen def_rnd_as_pct_govt_rnd = 100 * govt_fed_def_inv_nom_rnd / gross_govt_inv_nom_rnd		
	
	gen def_tot_as_pct_govt_tot = 100 * gross_govt_inv_fed_def_nom / gross_govt_inv_nom

	gen tot_rnd_as_pct_govt_tot = 100 * gross_govt_inv_nom_rnd / gross_govt_inv_nom
	gen def_rnd_as_pct_govt_def = 100 * govt_fed_def_inv_nom_rnd / gross_govt_inv_fed_def_nom
		
	label var def_rnd_as_pct_govt_rnd "Fed. Def. R&D to Total R&D"
	line def_rnd_as_pct_govt_rnd dateqtr, title("Fed. Def. R&D to Total Govt. R&D") ytitle("Percent") lpattern(solid dash solid) yscale(r(0 100))
	graph export "Empirical_Analysis/figures/line_fed_def_rnd_as_percent_govt_dateqtr.png", replace		
	
	
	line def_tot_as_pct_govt_tot dateqtr, title("Fed. Def. to Total Govt. Investment") ytitle("Percent") lpattern(solid dash solid) yscale(r(0 100))
	graph export "Empirical_Analysis/figures/line_def_tot_as_pct_govt_tot_dateqtr.png", replace			

	
	label var tot_rnd_as_pct_govt_tot "Total R&D / Total Investment"
	label var def_rnd_as_pct_govt_def "Defense R&D / Defense Investment"
	line def_rnd_as_pct_govt_def tot_rnd_as_pct_govt_tot dateqtr, ///
		title("R&D Intensity in Govt. Investment") ///
		legend(cols(1)) ///
		ytitle("Percent") lpattern(solid dash solid) yscale(r(0 100))
	graph export "Empirical_Analysis/figures/line_govt_rnd_inv_intensities_dateqtr.png", replace			
		
	
	
	
	
	
/*********************************************************************************************/		
/*quarterly data*/

	// national aggregates
	use "${dtapath}\bea_quarterly", clear
	keep dateqtr ///
		 gdp_real gdp_nom /// GDP
		 pce_real pce_nom /// Consumption
		 gross_private_investment_real /// Gross Private Investment (fixed plus inventories)
		 gross_govt_investment_real /// Gross Real Govt Investment (total is only fixed)
		 gross_fpi_ipp_tot gross_fpi_ipp_rnd /// Investment in intellectual property products (total or just R&D)
		 gross_priv_inv_incl_inventories /// below we combine with gross_private_investment_real to deflate nominal values to real
		 govt_con_and_inv_nom /// Government Consumption Expenditures and Gross Investment
		 gross_priv_inv_nom /// Nominal Gross Private Fixed Investment
		 gross_govt_inv_nom /// Nominal Gross Govt Investment
		 gross_govt_inv_fed_def_nom /// Nominal Gross Federal Govt Defense Investment
		 gross_govt_inv_nom_ipp gross_govt_inv_nom_rnd ///
		 gdp_va_busi_nom gdp_va_busi_real /// gdp value added measures
		 nonfin_corp_net_worth nonfin_corp_equity_mkt  // for computing agg Tobin's Q

	// a few additoinal aggregates we didn't grab initially but grab
	// separately to avoid updating all other series
	merge 1:1 dateqtr using "${dtapath}\bea_quarterly_specific_govt_inv_series", nogen keep(master match) keepusing(govt_fed_def_inv_nom_rnd)					 
		 
	// measures of financial conditions
	merge 1:1 dateqtr using "${dtapath}\chicago_fed_fci_qtr", nogen keep(master match) keepusing(anfci nfci)
	merge 1:1 dateqtr using "${dtapath}\credit_spreads_qtr", nogen	keep(master match) keepusing(aaa10ym baa10ym)	
	//merge 1:1 dateqtr using "${dtapath}\gzspr_qtr", nogen	keep(master match)
	
	// aggregate patent counts (applications and issuances)
	merge 1:1 dateqtr using "${dtapath}\agg_patent_app_and_iss_by_qtr", nogen keep(master match) keepusing(total_app total_iss)			
	
	// aggregate compustat-based measures
	//merge 1:1 dateqtr using "${dtapath}\agg_compustat_shares_by_dateqtr", nogen keep(master match) keepusing(comp_assets_port_highrnd comp_assets_port_tot)			
	// note: need to fix Compustat data to actaully be quarterly if we want to use such data in VARs
	
	// check cig as percent of gdp
	gen cig_nom = pce_nom+gross_priv_inv_incl_inventories+govt_con_and_inv_nom
	//gen chk_frac_cig = cig_nom / gdp_nom
	//tsset dateqtr
	//tsline chk_frac_cig
	// chk_frac_cig looks good and lines up with the time series figure of net exports from FRED
	
	/*compute ratios*/
	gen ig_itot = gross_govt_inv_nom / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ig_y = gross_govt_inv_nom / gdp_nom
	gen ip_y = gross_priv_inv_nom / gdp_nom
	gen cp_y = pce_nom / gdp_nom
	gen ig_yp = gross_govt_inv_nom / gdp_va_busi_nom
	gen ip_yp = gross_priv_inv_nom / gdp_va_busi_nom
	gen cp_yp = pce_nom / gdp_va_busi_nom
	gen ig_cig = gross_govt_inv_nom / cig_nom
	gen ip_cig = gross_priv_inv_nom / cig_nom
	gen cp_cig = pce_nom / cig_nom	
	gen itot_y   = (gross_priv_inv_nom+gross_govt_inv_nom) / gdp_nom
	gen itot_yp  = (gross_priv_inv_nom+gross_govt_inv_nom) / gdp_va_busi_nom
	gen itot_cig = (gross_priv_inv_nom+gross_govt_inv_nom) / cig_nom
	gen ipptot_itot = gross_fpi_ipp_tot / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ipprnd_itot = gross_fpi_ipp_rnd / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ipptot_ip = gross_fpi_ipp_tot / gross_priv_inv_nom
	gen ipprnd_ip = gross_fpi_ipp_rnd / gross_priv_inv_nom	
	gen ipprnd_itot_incl_govt = (gross_fpi_ipp_rnd + gross_govt_inv_nom_rnd) / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ipprnd_itot_incl_nondefgovt  = (gross_fpi_ipp_rnd + gross_govt_inv_nom_rnd - govt_fed_def_inv_nom_rnd) / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ipprnd_itot_excl_defgovt = (gross_fpi_ipp_rnd + gross_govt_inv_nom_rnd - govt_fed_def_inv_nom_rnd) / (gross_priv_inv_nom+gross_govt_inv_nom-gross_govt_inv_fed_def_nom)
	gen ipprnd_itang_v1 = gross_fpi_ipp_rnd / (gross_govt_inv_nom+gross_priv_inv_nom-gross_fpi_ipp_tot)
	gen ipprnd_itang_v2 = gross_fpi_ipp_rnd / (gross_govt_inv_nom+gross_priv_inv_nom-gross_fpi_ipp_tot-gross_govt_inv_nom_ipp)
	gen ipprnd_itang_v3 = (gross_fpi_ipp_rnd+gross_govt_inv_nom_ipp) / (gross_govt_inv_nom+gross_priv_inv_nom-gross_fpi_ipp_tot-gross_govt_inv_nom_ipp)
	// new in may 2021:
	gen ig_less_def_y = (gross_govt_inv_nom-gross_govt_inv_fed_def_nom) / gdp_nom
	
	//br dateqtr gross_govt_inv_nom_rnd gross_govt_inv_fed_def_nom gross_govt_inv_nom
	gen igrnd_igtot = gross_govt_inv_nom_rnd / gross_govt_inv_nom
	gen igrndexdef_igtot = (gross_govt_inv_nom_rnd-govt_fed_def_inv_nom_rnd) / gross_govt_inv_nom
	
	
	// alternative versions of R&D capital share
	//gen ipprnd_ip_comp = comp_assets_port_highrnd / comp_assets_port_tot
	gen ip_ipprnd = gross_priv_inv_nom / gross_fpi_ipp_rnd 
	gen ipfix_ipprnd = (gross_priv_inv_nom-gross_fpi_ipp_rnd) / gross_fpi_ipp_rnd 
	//gen ip_ipprnd_comp = comp_assets_port_tot / comp_assets_port_highrnd
		
	
	//summ ipprnd_ip
	//tsline ipprnd_ip
	
	// deflate values to real using implied deflator observed in total private investment (fixed and inventories)
	gen inv_deflate = gross_priv_inv_incl_inventories / gross_private_investment_real
	gen gross_fpi_ipp_tot_real = gross_fpi_ipp_tot / inv_deflate
	gen gross_fpi_ipp_rnd_real = gross_fpi_ipp_rnd / inv_deflate
	//order gross_fpi_ipp_tot gross_fpi_ipp_tot_real gross_fpi_ipp_rnd gross_fpi_ipp_rnd_real
	//line gross_fpi_ipp_tot gross_fpi_ipp_tot_real dateqtr, legend(cols(1))
	
	/*our integrated volatility measure (see 01 program)*/
	merge 1:1 dateqtr using "${dtapath}\integrated_volatility_quarterly", nogen noreport keep(master match) keepusing(ivol)
	replace ivol = 4*ivol/100 // annualize units but put in decimal for consistency with shares that are in decimals

	/*log TFP growth. use data from FRBSF because they have both quarterly and annual*/
	merge 1:1 dateqtr using "${dtapath}\tfp_data_from_frbsf_quarterly", nogen noreport keep(master match) keepusing(dtfp_busi_sector_reg_frbsf)
	//merge 1:1 dateqtr using "${dtapath}\tfp_data_from_frbsf_quarterly", nogen noreport keep(master match) keepusing(dtfp_busi_sector_reg_frbsf dtfp_bs_t_tp5yrs dtfp_bs_t_tp7yrs dtfp_bs_t_tp10yrs)
	gen dtfp = dtfp_busi_sector_reg_frbsf/100 // put in decimal for consistency with shares that are in decimals
	gen temp_dtfp_qtr = dtfp/4
	tsset dateqtr
	sort dateqtr
	gen tfp = sum(temp_dtfp_qtr)
	replace tfp = . if tfp==0
	//gen dtfp_tp5yrs  = dtfp_bs_t_tp5yrs /100
	//gen dtfp_tp7yrs  = dtfp_bs_t_tp7yrs /100
	//gen dtfp_tp10yrs = dtfp_bs_t_tp10yrs/100
	drop dtfp_busi_sector_reg_frbsf
	
	// forward-moving averages
	tsset dateqtr
	foreach numyears in 1 5 7 10 {		
		local numqtrs = `numyears'*4
		forvalues j=1/`numqtrs' {
			gen temp_dtfp_F`j' = F`j'.dtfp
		}
		egen dtfp_tp`numyears'yrs = rowmean(temp_dtfp_*) // sum up all the quarterly growth rates
		egen miss_chk = rowmiss(temp_dtfp_*) // check if any misssing
		//egen dtfp_tp`numyears'yrs = rowmean(dtfp temp_dtfp_*) // try including current year
		//egen miss_chk = rowmiss(dtfp temp_dtfp_*) // try including current year
		replace dtfp_tp`numyears'yrs = . if miss_chk>0 // do not count an obs with missing growth rate
		drop temp_dtfp_F* miss_chk
	}
	//br dateqtr dtfp dtfp_tp*	
			
		
	// compute aggregate Tobin's Q
	// follow Max's JME that describes the data as follows: “Data on Tobin’s Q 
	// are from the Flow of Funds 723 (FoF) and are obtained directly from the 
	// St. Louis Fed by dividing the variable MVEONWMVBSNNCB 724 (line 35 of 
	// Table B.102 in the FoF report) by TNWMVBSNNCB (line 32 of table B.102 in
	// the FoF report).” I note that one of the series is discontinued so I had
	// to switch to the current version (NCBEILQ027S), which is supposed to 
	// be exactly the same.			
	gen tobinQ = nonfin_corp_equity_mkt / nonfin_corp_net_worth 
	//line tobinQ dateqtr if dateqtr>=yq(1951,1)
	
	// add on agg labor shares labor_share_govt and labor_share_priv
	merge 1:1 dateqtr using "${dtapath}\temp_labor_share_qtr", nogen keep(master match) 
	
	/*separate dateqtr to year and qtr vars*/
	gen year = year(dofq(dateqtr))
	gen month = month(dofq(dateqtr))
	gen qtr  = 1
	replace qtr = 2 if month== 4
	replace qtr = 3 if month== 7
	replace qtr = 4 if month==10
	drop dateqtr month
	order year qtr

	// save before reordering and removing vars
	save "${dtapath}\data_macro_qtr_all_vars", replace
	
	//order year qtr gross_govt_investment_real_pchg gross_private_investment_real ///
	gen fakevar = 0
	order year qtr gross_govt_investment_real gross_private_investment_real ///	
		gross_fpi_ipp_tot_real gross_fpi_ipp_rnd_real ///
		gdp_nom gdp_real pce_nom pce_real gdp_va_busi_nom gdp_va_busi_real ///
		ig_itot ipptot_itot ipprnd_itot ipptot_ip ipprnd_ip ipprnd_itot_incl_govt ipprnd_itang_v* ///
		ipprnd_itot_incl_nondefgovt ///
		ipprnd_itot_excl_defgovt ///
		igrnd_igtot igrndexdef_igtot ///	
		ig_y ip_y cp_y ig_yp ip_yp cp_yp ig_cig ip_cig cp_cig ig_less_def_y ///
		itot_y itot_yp itot_cig ///
		ivol dtfp ///
		dtfp_tp5yrs dtfp_tp7yrs dtfp_tp10yrs ///
		total_app total_iss tobinQ ///
		nfci anfci aaa10ym baa10ym ///
		labor_share_govt labor_share_priv labor_govt labor_priv labor_tot ln_labor_govt ln_labor_priv ln_labor_tot ///
		tfp /// add on 3-25-2020 for running VARs on levels
		gross_govt_inv_nom gross_priv_inv_incl_inventories govt_con_and_inv_nom ///
		/// comp_assets_port* ipprnd_ip_comp ip_ipprnd_comp  /// 
		ip_ipprnd ipfix_ipprnd ///
		fakevar
	keep year - fakevar
	// note: leave fakevar in data b/c otherwise Matlab import makes last 
	//       imported variable cell instead of a vector. 
		
	// rename variables for easier use in Matlab
	rename gross_govt_investment_real Ig_real
	rename gross_private_investment_real Ip_real
	gen Itot_real = Ip_real + Ig_real
	rename gross_fpi_ipp_tot_real IPPtot_real
	rename gross_fpi_ipp_rnd_real IPPrnd_real
	rename gdp_nom  Y_nom
	rename gdp_real Y_real
	rename gdp_va_busi_nom  Yp_nom
	rename gdp_va_busi_real Yp_real
	rename ig_itot Ig_Itot
	rename ig_y Ig_Y
	rename ig_less_def_y Ig_less_def_Y
	rename ipprnd_ip IPPrnd_Ip
	rename ipprnd_itot_incl_govt IPPrnd_Itot_Incl_Govt
	rename ipprnd_itot_incl_nondefgovt IPPrnd_Itot_Incl_NonDefGovt
	rename ipprnd_itot_excl_defgovt IPPrnd_Itot_Excl_DefGovt
	rename igrnd_igtot Igrnd_Igtot
	rename igrndexdef_igtot Igrndexdef_Igtot
	rename ipprnd_itot IPPrnd_Itot
	// use the following for creating figures only
	rename govt_con_and_inv_nom G_nom
	rename gross_govt_inv_nom Ig_nom
	gen Cg_nom = G_nom - Ig_nom
	//rename gross_priv_inv_nom Ip_nom
	rename gross_priv_inv_incl_inventories Ip_incl_inv_nom
	
	//rename comp_assets_port_highrnd COMP_IPPrnd_real
	//rename comp_assets_port_tot COMP_Ip_real
	//rename ipprnd_ip_comp COMP_IPPrnd_Ip
	
	rename ip_ipprnd Ip_IPPrnd
	rename ipfix_ipprnd Ipfix_IPPrnd
	//rename ip_ipprnd_comp COMP_Ip_IPPrnd
	
	// compute additional vars: differences in variables
	gen dateqtr = yq(year,qtr)
	tsset dateqtr
	foreach myvar in "Ig_real" "IPPrnd_real" "Ip_real" "Yp_real" {
		gen ln_`myvar' = ln(`myvar')
		gen dln_`myvar' = D1.ln_`myvar' // keep in decimal for consistency with dtfp and shares that are in decimals
	}
	gen D_Ig_Y = D1.Ig_Y	
	gen D_ivol = D1.ivol		
			
	// add additional vars for use in figures only
	merge 1:1 dateqtr using "${dtapath}\bea_quarterly_additional_saving_investment_series", nogen keep(master match) ///
		keepusing(priv_saving govt_saving curr_acct_nipa curr_acct_stat_discrep govt_wages)
		
	// rename to make the same as the other vars	
	rename priv_saving Sp_nom
	rename govt_saving Sg_nom
	gen CA_nom_net = curr_acct_nipa - curr_acct_stat_discrep // net value to make eqn hold
	rename curr_acct_nipa CA_nom_nipa
		
	// confirm relationship between saving and investment
	gen chkdiff = (Ig_nom - Sg_nom) - (Sp_nom - Ip_incl_inv_nom - CA_nom_net)
	summ chkdiff, detail
	drop chkdiff
	
	// 4qtr MA for ivol
	gen ivol_4qtrMA = (ivol + L1.ivol + L2.ivol + L3.ivol)/4
	
	// no longer needed
	drop dateqtr 
	
	// make sure still the last var
	order fakevar, last 
		
	// save out VAR folder by sample
	save "${dtapath}\data_macro_qtr_from_1947", replace
	keep if year<=2016 // don't want data past 2016 even in full series figures
	outsheet using "${VARdatapath}\data_macro_qtr_from_1947.csv", replace comma
	keep if year>=1961 & year<=2016
	drop if year==1961 & qtr==1 // investment regression data (i.e., expvol) starts in 1969Q2
	outsheet using "${VARdatapath}\data_macro_qtr_1961_2016.csv", replace comma
	keep if year>=1969 & year<=2016
	outsheet using "${VARdatapath}\data_macro_qtr_1969_2016.csv", replace comma	
	keep if year>=1972 & year<=2016
	outsheet using "${VARdatapath}\data_macro_qtr_1972_2016.csv", replace comma		
	keep if year>=1975 & year<=2016 // for robustness check and potential switch of benchmark
	outsheet using "${VARdatapath}\data_macro_qtr_1975_2016.csv", replace comma			
	keep if year>=1981 & year<=2014 // for patent data
	outsheet using "${VARdatapath}\data_macro_qtr_1981_2016.csv", replace comma		
	
	
	
/*********************************************************************************************/		
/*annual data*/
	
// aggregated compustat measures 

	use "${rawPath}\CRSP_Compustat\compustat_annual", clear	
	
	// do same data cleaning as in regressions
	keep if curcd=="USD" // figures must be in USD
	keep if fic=="USA"
	// note: restrict to firms incorporated in US for now but
	//       we may want to expand because R&D expense by foreign companies 
	//       in the US should count to US investment in GDP figures
	drop if missing(at)
	
	// all Compustat firms
	gen capx_all = capx
	gen xrd_all = xrd

	// R&D intensity ratios	
	gen xrd_to_at = xrd / at
	egen xrd_to_at_nomiss = rowtotal(xrd_to_at)	
	gen miss_xrd = missing(xrd)
	tab fyear miss_xrd, row // reminder that xrd reported starting in 1972
	
	// high R&D compustat firms 
	bysort fyear: egen xrd_to_at_p80 = pctile(xrd_to_at), p(80)
	bysort fyear: egen xrd_to_at_p20 = pctile(xrd_to_at), p(20)
	preserve
		collapse (mean) xrd_to_at_p20 xrd_to_at_p80  (count) N=xrd_to_at_p20 , by(fyear)
		list
	restore
	summ xrd_to_at_p20 xrd_to_at_p80, detail
	gen capx_highport = capx if ~missing(xrd_to_at) & xrd_to_at> xrd_to_at_p80
	gen xrd_highport  = xrd  if ~missing(xrd_to_at) & xrd_to_at> xrd_to_at_p80
	gen capx_low1port = capx if ~missing(xrd_to_at) & xrd_to_at<=xrd_to_at_p20
	gen xrd_low1port  = xrd  if ~missing(xrd_to_at) & xrd_to_at<=xrd_to_at_p20	
	gen capx_allport  = capx if ~missing(xrd_to_at) 
	gen xrd_allport   = xrd  if ~missing(xrd_to_at) 
		
	collapse ///
		(sum) ///
			capx_all xrd_all ///
			capx_highport xrd_highport ///
			capx_low1port xrd_low1port ///
			capx_allport xrd_allport ///
		(min) xrd_to_at_p80 xrd_to_at_p20 /// for reference
		, by(fyear)
		
	// R&D investment intensity measures
	gen xrd_to_tot_all = xrd_all / (xrd_all + capx_all) // all computat firms
	gen xrd_to_tot_allport = xrd_all / (capx_allport+xrd_allport) // all computat firms
	gen highrnd_totinv_to_allport_totinv = (capx_highport+xrd_highport) / (capx_allport+xrd_allport) // share of investment from highR&D firms
	gen highrnd_totinv_to_all_totinv = (capx_highport+xrd_highport) / (xrd_all + capx_all) // share of investment from highR&D firms
		
	// investment ratios across portfolios	
	gen capx_high_to_low =  capx_highport                 /  capx_low1port	
	gen toti_high_to_low = (capx_highport + xrd_highport) / (capx_low1port + xrd_low1port)
	gen capx_high_to_low_keepln =  capx_high_to_low // will keep as log of ratio in VAR
		
	// check the measures
	line xrd_to_tot_all xrd_to_tot_allport highrnd_totinv_to_allport_totinv highrnd_totinv_to_all_totinv fyear, xline(1972)
	graph export "Empirical_Analysis/figures/aggregate_compustat_investment_share_measures.png", replace

	// check the measures
	line capx_high_to_low toti_high_to_low fyear, xline(1972)
	graph export "Empirical_Analysis/figures/aggregate_compustat_high_low_invest_ratios.png", replace
	
	
	// save dta to merge 	
	rename fyear year
	keep if year>=1972 // to match micro analysis plus thats when xrd data more readily available
	// keep only what is needed for VARs
	keep year ///
		xrd_to_tot_all xrd_to_tot_allport ///
		highrnd_totinv_to_allport_totinv highrnd_totinv_to_all_totinv ///
		capx_high_to_low toti_high_to_low capx_high_to_low_keepln
	save "${dtapath}\agg_compustat_shares_by_year", replace	
	


// combine together annual measures and export	
	
	/*gdp and consumption*/
	use "${dtapath}\bea_annual", clear
	keep year ///
		 gdp_real gdp_nom /// GDP
		 pce_real pce_nom /// Prviate Consumption
		 gross_private_investment_real /// Gross Private Investment (fixed plus inventories)
		 gross_govt_investment_real /// Gross Govt Investment (total is only fixed)
		 gross_fpi_ipp_tot gross_fpi_ipp_rnd /// Investment in intellectual property products (total or just R&D)
		 gross_private_investment_nom /// combine with gross_private_investment_real to deflate nominal values to real
		 govt_con_and_inv_nom /// Government Consumption Expenditures and Gross Investment
		 gross_priv_inv_nom /// Nominal Gross Private Fixed Investment
		 gross_govt_inv_nom /// Nominal Gross Govt Investment
		 gross_fed_govt_inv_nom_def /// Nominal Gross Federal Govt Defense Investment
		 gross_govt_inv_nom_ipp gross_govt_inv_nom_rnd ///
		 gdp_va_busi_nom gdp_va_busi_real // gdp value added measures
	
	/*aggregate consumption: private + govt?????*/
	//gen consumption_agg_nom = pce_nom + consumption_govt_fed + consumption_govt_snl
	
	/*book capital (aka produced assets) for govt and private*/
	//merge 1:1 year using "${dtapath}\nipa_fixed_assets_and_investment_annual", nogen keep(master match) keepusing(produced_fixed_assets_govt produced_fixed_assets_private)
	/*descriptions:
		produced_fixed_assets_private: "Produced Fixed Assets (Private), Billions of Dollars"	
		produced_fixed_assets_govt:    "Produced Fixed Assets (Govt), Billions of Dollars"
	*/	
		
	// fixed assets (or book capital or produced assets) from the BEA
	merge 1:1 year using "${dtapath}\bea_fixed_assets_tables_data_annual", nogen keep(master match) 
	/*descriptions:
		priv_fa_tot: "Produced Fixed Assets (Private), Billions of Dollars"	
		govt_fa_tot: "Produced Fixed Assets (Govt), Billions of Dollars"
	*/		
		
	// measures of financial conditions
	merge 1:1 year using "${dtapath}\chicago_fed_fci_ann", nogen keep(master match) keepusing(anfci nfci)
	merge 1:1 year using "${dtapath}\credit_spreads_ann", nogen keep(master match) keepusing(aaa10ym baa10ym)		
	//merge 1:1 year using "${dtapath}\gzspr_ann", nogen	keep(master match)	
	
	// patent counts (applications and issuances)
	// as of 2020-04-03: keep all patent measures
	merge 1:1 year using "${dtapath}\agg_patent_app_and_iss_by_year", nogen keep(master match) //keepusing(total_app total_iss total_app_usa total_iss_usa)		

	// aggregated compustat-based measures
	merge 1:1 year using "${dtapath}\agg_compustat_shares_by_year", nogen keep(master match) //keepusing(total_app total_iss total_app_usa total_iss_usa)			
	
	// check cig as percent of gdp
	gen cig_nom = pce_nom+gross_private_investment_nom+govt_con_and_inv_nom
	//gen chk_frac_cig = cig_nom / gdp_nom
	//tsset year
	//tsline chk_frac_cig
	// chk_frac_cig looks good and lines up with the time series figure of net exports from FRED	
	
	/*compute ratios*/
	gen ig_itot = gross_govt_inv_nom / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ig_y = gross_govt_inv_nom / gdp_nom
	gen ip_y = gross_priv_inv_nom / gdp_nom
	gen cp_y = pce_nom / gdp_nom
	//gen kg_ktot = produced_fixed_assets_govt / (produced_fixed_assets_govt+produced_fixed_assets_private)
	gen kg_ktot = govt_fa_tot / (govt_fa_tot+priv_fa_tot)
	gen krnd_priv_ktot = priv_fa_ipp_rnd / (priv_fa_tot + govt_fa_tot)
	gen kipp_priv_ktot = priv_fa_ipp_tot / (priv_fa_tot + govt_fa_tot)	
	gen krnd_both_ktot = (priv_fa_ipp_rnd+govt_fa_ipp_rnd) / (priv_fa_tot + govt_fa_tot)
	gen kipp_both_ktot = (priv_fa_ipp_tot+govt_fa_ipp_tot) / (priv_fa_tot + govt_fa_tot)		
	gen ig_yp = gross_govt_inv_nom / gdp_va_busi_nom
	gen ip_yp = gross_priv_inv_nom / gdp_va_busi_nom
	gen cp_yp = pce_nom / gdp_va_busi_nom
	gen ig_cig = gross_govt_inv_nom / cig_nom
	gen ip_cig = gross_priv_inv_nom / cig_nom
	gen cp_cig = pce_nom / cig_nom		
	gen itot_y   = (gross_priv_inv_nom+gross_govt_inv_nom) / gdp_nom
	gen itot_yp  = (gross_priv_inv_nom+gross_govt_inv_nom) / gdp_va_busi_nom
	gen itot_cig = (gross_priv_inv_nom+gross_govt_inv_nom) / cig_nom	
	gen ipptot_itot = gross_fpi_ipp_tot / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ipprnd_itot = gross_fpi_ipp_rnd / (gross_priv_inv_nom+gross_govt_inv_nom)	
	gen ipptot_ip = gross_fpi_ipp_tot / gross_priv_inv_nom
	gen ipprnd_ip = gross_fpi_ipp_rnd / gross_priv_inv_nom
	gen ipprnd_itang_v1 = gross_fpi_ipp_rnd / (gross_govt_inv_nom+gross_priv_inv_nom-gross_fpi_ipp_tot)
	gen ipprnd_itang_v2 = gross_fpi_ipp_rnd / (gross_govt_inv_nom+gross_priv_inv_nom-gross_fpi_ipp_tot-gross_govt_inv_nom_ipp)
	gen ipprnd_itang_v3 = (gross_fpi_ipp_rnd+gross_govt_inv_nom_ipp) / (gross_govt_inv_nom+gross_priv_inv_nom-gross_fpi_ipp_tot-gross_govt_inv_nom_ipp)	
	// new in may 2021:
	gen ig_less_def_y = (gross_govt_inv_nom-gross_fed_govt_inv_nom_def) / gdp_nom
	gen igdef_to_igtot = gross_fed_govt_inv_nom_def / gross_govt_inv_nom
	
	// deflate values to real using implied deflator observed in total private investment (fixed and inventories)
	gen inv_deflate = gross_private_investment_nom / gross_private_investment_real
	gen gross_fpi_ipp_tot_real = gross_fpi_ipp_tot / inv_deflate
	gen gross_fpi_ipp_rnd_real = gross_fpi_ipp_rnd / inv_deflate
	//order gross_fpi_ipp_tot gross_fpi_ipp_tot_real gross_fpi_ipp_rnd gross_fpi_ipp_rnd_real
	//line gross_fpi_ipp_tot gross_fpi_ipp_tot_real year, legend(cols(1))	
	
	/*drop unncessary vars*/	
	drop gross_priv_inv_nom gross_govt_inv_nom 

	/*our integrated volatility measure (see 01 program)*/
	merge 1:1 year using "${dtapath}\integrated_volatility_annual", nogen noreport keep(master match) keepusing(ivol)
	replace ivol = ivol/100 // put in decimal for consistency with shares that are in decimals

	/*log TFP growth. use data from FRBSF because they have both quarterly and annual*/
	merge 1:1 year using "${dtapath}\tfp_data_from_frbsf_annual", nogen noreport keep(master match) keepusing(dtfp_busi_sector_reg_frbsf)
	gen dtfp = dtfp_busi_sector_reg_frbsf/100 // put in decimal for consistency with shares that are in decimals
	tsset year
	sort year
	gen tfp = sum(dtfp)
	replace tfp = . if tfp==0
	drop dtfp_busi_sector_reg_frbsf

	// aggregted compustat patent count measures
	merge 1:1 year using "${dtapath}\agg_compustat_patent_measures", nogen keep(master match)		
	
	// value of patent measures
	merge 1:1 year using "${dtapath}\agg_pat_val_to_mkt_measures", nogen keep(master match)	
	
	gen fakevar = 0
	order year gross_govt_investment_real gross_private_investment_real ///
		gross_fpi_ipp_tot_real gross_fpi_ipp_rnd_real ///
		gdp_nom gdp_real pce_nom pce_real gdp_va_busi_nom gdp_va_busi_real ///
		ig_itot ipptot_itot ipprnd_itot ipptot_ip ipprnd_ip ipprnd_itang_v* ig_less_def_y igdef_to_igtot ///
		ig_y ip_y cp_y ig_yp ip_yp cp_yp ig_cig ip_cig cp_cig ///	
		itot_y itot_yp itot_cig ///
		kg_ktot krnd_priv_ktot kipp_priv_ktot krnd_both_ktot kipp_both_ktot ///
		ivol dtfp ///
		nfci anfci aaa10ym baa10ym /// gzspr
		total_* /// patent count measures
		agg_comp* /// patent count measures from 
		agg_pat_* /// patent value measures
		xrd_to_tot_all xrd_to_tot_allport highrnd_totinv_to_allport_totinv highrnd_totinv_to_all_totinv capx_high_to_low toti_high_to_low capx_high_to_low_keepln /// aggregated compustat measures
		tfp /// also consider tfp in levels
		fakevar
	keep year - fakevar
	// note: leave fakevar in data so Matlab import doesn't mess up var we care
	//       about in the last column (Matlab import makes last var as Tx1 cell)
	
	// rename variables for easier use in Matlab
	rename gross_govt_investment_real Ig_real
	rename gross_private_investment_real Ip_real
	rename gross_fpi_ipp_tot_real IPPtot_real
	rename gross_fpi_ipp_rnd_real IPPrnd_real
	rename gdp_nom  Y_nom
	rename gdp_real Y_real
	rename gdp_va_busi_nom  Yp_nom
	rename gdp_va_busi_real Yp_real
	rename ig_itot Ig_Itot
	rename ig_less_def_y Ig_less_def_Y
	rename ig_y Ig_Y	
	rename kg_ktot Kg_Ktot
	
	// save out VAR folder
	save "${dtapath}\data_macro_ann_from_1929", replace
	keep if year<=2016 // don't want data past 2016 even in full series figures
	outsheet using "${VARdatapath}\data_macro_ann_from_1929.csv", replace comma
	keep if year>=1951 & year<=2016 // try postwar only
	outsheet using "${VARdatapath}\data_macro_ann_1951_2016.csv", replace comma			
	keep if year>=1963 & year<=2016 // for US only patent data
	outsheet using "${VARdatapath}\data_macro_ann_1963_2016.csv", replace comma		
