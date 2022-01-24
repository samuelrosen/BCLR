clear all;
close all;

%% load the data

% was previously called the following
%load GDP.mat;

addpath(genpath('data_for_data_moments'));
T = readtable('data_for_moment_calcs_ann.csv');
data_macro_ann = table2struct(T,'ToScalar',true);            
clear T


%%
%diff 1929-2016
% delta_c = log(Ca(2:end,1))-log(Ca(1:end-1,1));
% delta_y = log(Ya(2:end,1))-log(Ya(1:end-1,1));
% delta_i = log(Ia_n(2:end,1)+Ia_s(2:end,1))-log(Ia_n(1:end-1,1)+Ia_s(1:end-1,1));
% delta_ip = log(Ia_n(2:end,1))-log(Ia_n(1:end-1,1));
delta_c = data_macro_ann.d1_log_pce_real_percap(2:end); % first period 1929 is NaN
delta_y = data_macro_ann.d1_log_gdp_real_percap(2:end); % first period 1929 is NaN
delta_i = data_macro_ann.d1_log_itot_real_percap(2:end);
delta_ip = data_macro_ann.d1_log_ip_real_percap(2:end);
delta_iprnd = data_macro_ann.d1_log_ip_rnd_real_percap(2:end);
T = length(delta_c);
B = 100000;
w = 5;

% new labor series added feb 2021

% start from earliest year available
dcomp = data_macro_ann.d1_log_emp_wages_total(2:end-2); % first period 1929 is NaN. this data only through 2014
dcomp_priv = data_macro_ann.d1_log_emp_wages_priv( 2:end-2); % first period 1929 is NaN. this data only through 2014
dcomp_govt = data_macro_ann.d1_log_emp_wages_govt( 2:end-2); % first period 1929 is NaN. this data only through 2014
demp = data_macro_ann.d1_log_emp_total_all_sa_avg(12:end); % this data only starts in 1939 and therefore 1940 with growth rate
demp_priv = data_macro_ann.d1_log_emp_priv_all_sa_avg(12:end); % this data only starts in 1939 and therefore 1940 with growth rate
demp_govt = data_macro_ann.d1_log_emp_govt_all_sa_avg(12:end); % this data only starts in 1939 and therefore 1940 with growth rate
dwage = data_macro_ann.d1_log_w_total(12:end-2); % combination of comp and emp and so inherits both data restrictions
dwage_priv = data_macro_ann.d1_log_w_priv(12:end-2); % combination of comp and emp and so inherits both data restrictions
dwage_govt = data_macro_ann.d1_log_w_govt(12:end-2); % combination of comp and emp and so inherits both data restrictions
Np_Ng = data_macro_ann.ratio_emp_priv_to_govt(12:end);
Np_Nt = data_macro_ann.ratio_emp_priv_to_total(12:end);
% start from 1953:
% dcomp = data_macro_ann.d1_log_emp_wages_total(25:end-2); % first period 1929 is NaN. this data only through 2014
% dcomp_priv = data_macro_ann.d1_log_emp_wages_priv(25:end-2); % first period 1929 is NaN. this data only through 2014
% dcomp_govt = data_macro_ann.d1_log_emp_wages_govt(25:end-2); % first period 1929 is NaN. this data only through 2014
% demp = data_macro_ann.d1_log_emp_total_all_sa_avg(25:end); % this data only starts in 1939 and therefore 1940 with growth rate
% demp_priv = data_macro_ann.d1_log_emp_priv_all_sa_avg(25:end); % this data only starts in 1939 and therefore 1940 with growth rate
% demp_govt = data_macro_ann.d1_log_emp_govt_all_sa_avg(25:end); % this data only starts in 1939 and therefore 1940 with growth rate
% dwage = data_macro_ann.d1_log_w_total(25:end-2); % combination of comp and emp and so inherits both data restrictions
% dwage_priv = data_macro_ann.d1_log_w_priv(25:end-2); % combination of comp and emp and so inherits both data restrictions
% dwage_govt = data_macro_ann.d1_log_w_govt(25:end-2); % combination of comp and emp and so inherits both data restrictions
% Np_Ng = data_macro_ann.ratio_emp_priv_to_govt(25:end);
% Np_Nt = data_macro_ann.ratio_emp_priv_to_total(25:end);

addpath(genpath('matlab'));
[bsc, dcind]= block_bootstrap(delta_c,B,w);

stddc = std(bsc)';
meanstddc = mean(stddc,1);
stdstddc = std(stddc);

bsy = delta_y(dcind);
stddy = std(bsy)';
meanstdy = mean(stddy,1);
stdstdy = std(stddy);
% SAM add: average growth rate
avgdy = mean(bsy)';
meanavgdy = mean(avgdy,1);
stdavgdy = std(avgdy);

ra_stdcy =stddc./stddy;
meanstdcy = mean(ra_stdcy,1);
stdstdcy = std(ra_stdcy);

bsi = delta_i(dcind);
stddi = std(bsi)';
ra_stdiy =stddi./stddy;
meanstdiy = mean(ra_stdiy,1);
stdstdiy = std(ra_stdiy);

bsip = delta_ip(dcind);
stddip = std(bsip)';
meanstddiprnd = mean(stddip,1);
stdstddiprnd = std(stddip);

bsiprnd = delta_iprnd(dcind);
stddiprnd = std(bsiprnd)';
meanstddiprnd = mean(stddiprnd,1);
stdstddiprnd = std(stddiprnd);

[bsIpYa, ~]= block_bootstrap(data_macro_ann.ip_y,B,w);
meanIpYa = mean(bsIpYa)';
stdIpYa = std(bsIpYa)';
mmeanIpYa = mean(meanIpYa);
mstdIpYa = mean(stdIpYa);
smeanIpYa = std(meanIpYa);
sstdIpYa = std(stdIpYa);

[bsIgYa, ~]= block_bootstrap(data_macro_ann.ig_y,B,w);
meanIgYa = mean(bsIgYa)';
stdIgYa = std(bsIgYa)';
mmeanIgYa = mean(meanIgYa);
mstdIgYa = mean(stdIgYa);
smeanIgYa = std(meanIgYa);
sstdIgYa = std(stdIgYa);

[bsKgKt, ~]= block_bootstrap(data_macro_ann.kg_ktot,B,w);
meanKgKt = mean(bsKgKt)';
stdKgKt = std(bsKgKt)';
mmeanKgKt = mean(meanKgKt);
mstdKgKt = mean(stdKgKt);
smeanKgKt = std(meanKgKt);
sstdKgKt = std(stdKgKt);

%[bsrm, rmind]= block_bootstrap(log_rm-log_rf,B,w);
%[bsrf, rfind]= block_bootstrap(log_rf,B,w);
[bsrm, ~]= block_bootstrap(100*data_macro_ann.ln_mktrf,B,w);
[bsrg, ~]= block_bootstrap(100*data_macro_ann.ln_ex_hall_ret,B,w);
[bsrf, ~]= block_bootstrap(100*data_macro_ann.ln_rf_real,B,w);
%[bsrm, ~]= block_bootstrap(data_macro_ann.mktrf,B,w);
%[bsrf, ~]= block_bootstrap(data_macro_ann.rf_real,B,w);

meanrm = mean(bsrm)';
stdrm = std(bsrm)';
mmeanrm = mean(meanrm);
mstdrm = mean(stdrm);
smeanrm = std(meanrm);
sstdrm = std(stdrm);

meanrg = mean(bsrg)';
stdrg = std(bsrg)';
mmeanrg = mean(meanrg);
mstdrg = mean(stdrg);
smeanrg = std(meanrg);
sstdrg = std(stdrg);

meanrf = mean(bsrf)';
stdrf = std(bsrf)';
mmeanrf = mean(meanrf);
mstdrf = mean(stdrf);
smeanrf = std(meanrf);
sstdrf = std(stdrf);

% new labor moments

    [bscomp, dcompind]= block_bootstrap(dcomp,B,w);

        stddcomp = std(bscomp)';
        meanstddcomp = mean(stddcomp,1);
        stdstddcomp = std(stddcomp);
        
        bscomp_priv = dcomp_priv(dcompind);
        stddcomp_priv = std(bscomp_priv)';
        meanstddcomp_priv = mean(stddcomp_priv,1);
        stdstddcomp_priv = std(stddcomp_priv); 

        bscomp_govt = dcomp_govt(dcompind);
        stddcomp_govt = std(bscomp_govt)';
        meanstddcomp_govt = mean(stddcomp_govt,1);
        stdstddcomp_govt = std(stddcomp_govt);     
        
    [bsemp, dempind]= block_bootstrap(demp,B,w);

        stddemp = std(bsemp)';
        meanstddemp = mean(stddemp,1);
        stdstddemp = std(stddemp);

        bsemp_priv = demp_priv(dempind);
        stddemp_priv = std(bsemp_priv)';
        meanstddemp_priv = mean(stddemp_priv,1);
        stdstddemp_priv = std(stddemp_priv); 

        bsemp_govt = demp_govt(dempind);
        stddemp_govt = std(bsemp_govt)';
        meanstddemp_govt = mean(stddemp_govt,1);
        stdstddemp_govt = std(stddemp_govt);         

    [bswage, dwageind]= block_bootstrap(dwage,B,w);

        stddwage = std(bswage)';
        meanstddwage = mean(stddwage,1);
        stdstddwage = std(stddwage);

        bswage_priv = dwage_priv(dwageind);
        stddwage_priv = std(bswage_priv)';
        meanstddwage_priv = mean(stddwage_priv,1);
        stdstddwage_priv = std(stddwage_priv); 

        bswage_govt = dwage_govt(dwageind);
        stddwage_govt = std(bswage_govt)';
        meanstddwage_govt = mean(stddwage_govt,1);
        stdstddwage_govt = std(stddwage_govt);
       
    [bsNpNg, ~]= block_bootstrap(Np_Ng,B,w);
    meanNpNg = mean(bsNpNg)';
    stdNpNg = std(bsNpNg)';
    mmeanNpNg = mean(meanNpNg);
    mstdNpNg = mean(stdNpNg);
    smeanNpNg = std(meanNpNg);
    sstdNpNg = std(stdNpNg);        
    
    [bsNpNt, ~]= block_bootstrap(Np_Nt,B,w);
    meanNpNt = mean(bsNpNt)';
    stdNpNt = std(bsNpNt)';
    mmeanNpNt = mean(meanNpNt);
    mstdNpNt = mean(stdNpNt);
    smeanNpNt = std(meanNpNt);
    sstdNpNt = std(stdNpNt);      

for i=1:B
    corrdcdip(i) = corr(bsc(:,i),bsip(:,i)); 
    corrdcdi(i) = corr(bsc(:,i),bsi(:,i));     
    corr_demppriv_dempgovt(i) = corr(bsemp_priv(:,i),bsemp_govt(:,i));     
end
corrdcdip = corrdcdip';
corrdcdi = corrdcdi';
corr_demppriv_dempgovt = corr_demppriv_dempgovt';
meancorrdcdip = mean(corrdcdip,1);
meancorrdcdi = mean(corrdcdi,1);
meancorr_demppriv_dempgovt = mean(corr_demppriv_dempgovt,1);
stdcorrdcdip = std(corrdcdip);
stdcorrdcdi = std(corrdcdi);
stdcorr_demppriv_dempgovt = std(corr_demppriv_dempgovt);

                
        
        
finaltable = [ ...
    meanavgdy, stdavgdy; ... % NEW: average growth rate
    meanstdy, stdstdy; ...
    meanstdcy, stdstdcy; ...
    meanstdiy, stdstdiy; ...
    meanstddiprnd, stdstddiprnd; ...    
    mmeanIpYa, smeanIpYa; ...
    mstdIpYa, sstdIpYa; ...
    meancorrdcdip, stdcorrdcdip; ...    
    mmeanIgYa, smeanIgYa; ...    
    mstdIgYa, sstdIgYa; ...    
    mmeanKgKt, smeanKgKt; ...    
    mmeanrm, smeanrm; ...
    mstdrm, sstdrm; ...
    mmeanrg, smeanrg; ... % Sam added these govt bond empirical moments on 20201215
    mstdrg, sstdrg; ... % Sam added these govt bond empirical moments on 20201215
    5.43, 2.95; ... % these are the point estimate and SE from running the regression of levered HML returns on a constant. see val and se for col_51_lev_ret_avg on the sheet "ret_by_port_summ" in "tables_for_paper.xlsx"
    mmeanrf, smeanrf; ...
    mstdrf, sstdrf; ...
    meanstddcomp, stdstddcomp; ...     
    meanstddcomp_priv, stdstddcomp_priv; ...
    meanstddcomp_govt, stdstddcomp_govt; ...        
    meanstddemp, stdstddemp; ...     
    meanstddemp_priv, stdstddemp_priv; ...
    meanstddemp_govt, stdstddemp_govt; ...              
    meanstddwage, stdstddwage; ...     
    meanstddwage_priv, stdstddwage_priv; ...
    meanstddwage_govt, stdstddwage_govt; ...     
    meancorr_demppriv_dempgovt, stdcorr_demppriv_dempgovt; ...
    mmeanNpNg, smeanNpNg; ...    
    mstdNpNg, sstdNpNg; ... 
    mmeanNpNt, smeanNpNt; ...    
    mstdNpNt, sstdNpNt; ...     
    ]

% row identifiers
rowLabels={'$E\left[\Delta y\right]$ (\%)';
           '$\sigma(\Delta y)$ (\%)';
           '$\sigma(\Delta c)/\sigma(\Delta y)$';
           '$\sigma(\Delta i_{tot})/\sigma(\Delta y)$';
           '$\sigma(\Delta i_{p,rnd})$';
           '$E\left[(I_{p,tot})/Y\right] (\%)$';
           '$\sigma((I_{p,tot})/Y)(\%)$ ';
           '$\rho(\Delta c,\Delta \ln(I_{p,tot}))$';           
           '$E\left[I_g/Y\right] (\%)$';
           '$\sigma(I_g/Y)$ (\%)';
           '$E\left[\frac{K_g}{K_p+K_g}\right] (\%)$';
           '$E\left[r_{m,ex}\right]$ (\%)';
           '$\sigma(r_{m,ex})$ (\%)';
           '$E\left[r_{g,ex}\right]$ (\%)';
           '$\sigma(r_{g,ex})$ (\%)';    
           '$E\left[{HML-R\&D}^{LEV}\right]$ (\%)';   
           '$E\left[r^{f}\right]$ (\%)';
           '$\sigma(r^{f})$ (\%)';
           '$\sigma(\Delta (w_{p}L_{p} + w_{g}L_{g}) )$ (\%)'; ...     
           '$\sigma(\Delta w_{p}L_{p} )$ (\%)'; ...     
           '$\sigma(\Delta w_{g}L_{g} )$ (\%)'; ...        
           '$\sigma(\Delta (L_{p} + L_{g}) )$ (\%)'; ...     
           '$\sigma(\Delta L_{p} )$ (\%)'; ...     
           '$\sigma(\Delta L_{g} )$ (\%)'; ...                 
           '$\sigma(\Delta w_{avg} )$ (\%)'; ...     
           '$\sigma(\Delta w_{p} )$ (\%)'; ...     
           '$\sigma(\Delta w_{g} )$ (\%)'; ...  
           '$\rho(\Delta L_{p},\Delta L_{g} )$';   
           '$E\left[ L_p/L_g \right] (\%)$';
           '$\sigma(L_p/L_g)(\%)$ ';           
           '$E\left[ L_p/ (L_g+L_g) \right] (\%)$';
           '$\sigma(L_p/(L_g+L_g))(\%)$ ';                      
           };
       
clearvars -except finaltable rowLabels varnames       
varnames = {'estimate', 'stderr'};
data_moments_table = array2table(finaltable, 'RowNames', rowLabels, 'VariableNames', varnames);
data_moments_table
%writetable(results_table, filename,'Sheet',1);       

