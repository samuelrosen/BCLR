
function MAIN(cal_no_)

%% Housekeeping
%addpath(genpath('Monopoly Power'))
% SAM add the following lines so he can use dynare_simul for PC
if strcmp(getenv('COMPUTERNAME'),'FIN-SROSE-T480S') || strcmp(getenv('COMPUTERNAME'),'FIN-SROSEN-3620')
    addpath(genpath('Monopoly Power - Sam'));
else
    addpath(genpath('Monopoly Power'));
end
clearvars -global -except cal_no_; clc
warning off %#ok<WNOFF>
global cal_no saved_dir fname beta psi gamma alphap alphac rhoar arc rhotest deltap deltac w tau xi kappa  mu rho sigma rhovol stoch_vol_switch f con_shocka con_shockx;
% Gold Addition
global gold_switch varphi_g f_g Gbar_ss coint_g tau_g a1_g eps_g phi0_g phi1_g sigma_g corr_g G_ss
global ep_cov_calc_switch conditional_moments_switch shock_direction_switch simul_fast

cal_no=cal_no_; clearvars cal_no_

tic

%% Say which calibration is solved
disp(['Calibration: ' num2str(cal_no)]);

%% Write mod file
disp('Write the mod...'); 
write_mod 

%% Choose dynare++
Use_New_Dynare=0;
if Use_New_Dynare==0
    dynare_ver='2.1'; 
elseif Use_New_Dynare==1
    dynare_ver='3.1';
    disp('Using Dynare++ 4.3.1')
elseif Use_New_Dynare==2
    dynare_ver='3.2';
    disp('Using Dynare++ 4.3.2')
end

%% Execute dynare++
disp('Solving...');
fname=strcat('Monopoly_Power_Approx_',num2str(cal_no)); mod_name=strcat(fname,'.mod'); %#ok<*NODEF>
%mac_switch = 1;
% SAM add below flexibility to running MAIN code
if strcmp(getenv('COMPUTERNAME'),'FIN-SROSE-T480S') || strcmp(getenv('COMPUTERNAME'),'FIN-SROSEN-3620')
    mac_switch = 0;
else
    mac_switch = 1;
end
if mac_switch == 1
   system(strcat(['/Applications/Dynare/4.6.1/dynare++/dynare++ --sim 3 --per 10 --no-irfs --ss-tol 1e-10 ',mod_name]));
else
eval(strcat(['!dynare++_4.',dynare_ver,' --sim 3 --per 10 --no-irfs --ss-tol 1e-10 ',mod_name]))
end

%% To speed up
% load(strcat(fname,'.mat'));
% JESUS=[dyn_steady_states dyn_ss];
%     disp('RF_Steady RF_SS')
%     disp(num2str(JESUS(dyn_i_rf,:)*frEq*100));
%     disp('EP_Steady EP_SS (unlevered, %)')
%     disp(num2str(JESUS(dyn_i_exr,:)*frEq*100));
%     if gold_switch==1
%     disp(['J/I: ' num2str(dyn_ss(dyn_i_JA)/exp(dyn_ss(dyn_i_ia)))]);
%     end
% toc



%% Create extra variables outside of the mod file
create_var

%% Plot IRF
disp('IRFs...');
irfplot
toc


%% Calculate statistics
disp('Simulating ...');
sim_dyn_mod
toc


disp('Writing the Report ...');

%% Generate Table 5
load(strcat(fname,'.mat'));
if mac_switch == 1
saved_dir=strcat('Results/',fname); mkdir(saved_dir)
else
saved_dir=strcat('Results\',fname); mkdir(saved_dir)
end
% Parameters table
param = str2num(num2str([beta psi gamma alphap alphac tau w xi cxi mu rho arc rhovol con_shocka con_shockx],'%3.4f ')); % SAM EDIT
columnLabels={'$\beta$';'$\psi$';'$\gamma$';'$\alpha_p$';'$\alpha_g$';'$\tau$';'$\omega$';'$\xi$';'$\xi_s$';'$\mu$';'$\rho$';'$ar_c$'; '$\rho_{\sigma}$'; '$\beta_{v,a}$'; '$\beta_{v,x}$'};
rowLabels={' '};
if mac_switch == 1
matrix2latex(param,strcat([saved_dir,'/table_parameters.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
else
matrix2latex(param,strcat([saved_dir,'\table_parameters.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
end

% Moments table
clear rowLabels columnLabels

rowLabels={'$\sigma(\Delta y)$ (\%)';
           '$\sigma(\Delta c)/\sigma(\Delta y)$';
           '$\sigma(\Delta i_{tot})/\sigma(\Delta y)$';
           '$\sigma(\Delta s)$';
           '$E\left[(I_p+S)/Y\right] (\%)$';
           '$\sigma((I_p+S)/Y)(\%)$ ';
           '$\rho(\Delta c,\Delta \ln(I_p+S))$';           
           '$E\left[I_g/Y\right] (\%)$';
           '$\sigma(I_g/Y)$ (\%)';
           '$E\left[\frac{K_g}{K_p+K_g}\right] (\%)$';
           '$E\left[Q_g\right]$';
           '$E\left[r_{p,ex}^{LEV}\right]$ (\%)';
           '$\sigma(r_{p,ex}^{LEV})$ (\%)';
           '$E\left[r_{g,ex}\right]$ (\%)';
           '$\sigma(r_{g,ex})$ (\%)';    
           '$E\left[r_{R\&D,ex}^{LEV}\right]$ (\%)';  % sam changed from '$E\left[{HML-R\&D}^{LEV}\right]$ (\%)';  to avoid confusion
           '$E\left[r^{f}\right]$ (\%)';
           '$\sigma(r^{f})$ (\%)';
           '$b^{10}_g$';
            '$\beta_{\Delta a_{10}|K^{H}_{R\&D}/K_{H}}-K_L/K_{tot}$';
             '$\beta_{\Delta a_{10}|K^{H}_{R\&D}/K_{H}}$';
           '$\beta_{\Delta a_{10}|I_{R\&D}/I_{Fixed}}$';
             '$\beta_{\Delta a_{10}|I_{g}/I_{tot}}$';
             '$E[\Delta y]$ (\%)';
%            '$E\left[Q_gK_g/(Y_g+Y_p*p)\right] (\%)$';
%            '$\sigma(Q_gK_g/(Y_g+Y_p*p))$ (\%)';
%             '$E\left[K_g/(K_p+K_g)\right] (\%)$';
%            '$E\left[Q_gK_g/(Q_pK_p+Q_gK_g)\right] (\%)$';
%            '$E\left[Y_g/(Y_g+Y_p*p)\right] (\%)$';
%            '$\rho(\Delta c,\Delta i_{p})$';
%            '$\rho(\frac{I_g}{Y},\frac{C}{Y})$';
%            '$\rho(\Delta c,r_p^{LEV})$';        
%            
%            '$E\left[r_{p,ex}^{LEV}\right]$ (\%)';
%            '$\sigma(r_{p,ex}^{LEV})$ (\%)';
%            '$E\left[r_{g,ex}\right]$ (\%)';
%            '$\sigma(r_{g,ex})$ (\%)';           
%            '$E\left[r^{f}\right]$ (\%)';
%            '$\sigma(r^{f})$ (\%)';
%            
%            '$ACF(r_{ex}^{LEV})$';
%            '$ACF(r^{f})$';
%           '$ACF(q)$';
%            '$ACF(\Delta c)$';
%            '$\sigma(vol)$';
%            '$\frac{E\left[U/A\right]-U/A(ss)}{U/A(ss)} (\%)$';
%            '$\sigma(\Delta s)$ (\%)';
%            '$E\left[r_{R\&D,ex}^{LEV}\right]$ (\%)';
%            '$\beta_{\Delta c|x}$';
%            '$\beta_{\Delta c|\epsilon_a}$';
%            '$\beta_{\Delta c|\epsilon_x}$';
%            '$\beta_{iy|\epsilon_a}$';
%            '$\beta_{iy|\epsilon_x}$';
%            '$\beta_{q|\epsilon_a}$';
%            '$\beta_{q|\epsilon_x}$'
%            '$\hat{b}_{K_g/K_{tot}-K^{H}_{R\&D}/K_{p}}$';
%            '$\sigma(\hat{b}_g)$ ';
%                       '$\sigma(r_{R\&D,ex}^{LEV})$ (\%)';
%                       '$\sigma(r_{R\&D,ex,ns}^{LEV})$ (\%)';
%                       '$Adj \quad R^2$';
%           '$Adj \quad R^2_{w/o R\&D share}$';
%           '$Adj \quad R^2_{w/o Gov K share}$';
           };

columnLabels={'Moments'};
if mac_switch == 1
matrix2latex(output(1:23,1),strcat([saved_dir,'/table_moments.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')

else
matrix2latex(output(1:24,1),strcat([saved_dir,'\table_moments.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
end
% output_copy_paste = output(1:23+3+2+2,1);
% if stoch_vol_switch==1;
% 
% % Is regression table
% clear rowLabels columnLabels
% 
% rowLabels={'Const';
%            '$Pvalue_{Const}$';
%            '$\frac{I_{s,t-1}}{I_{s,t-1}+I_{n,t-1}}$';
%            '$Pvalue_{\frac{I_{s,t-1}}{I_{s,t-1}+I_{n,t-1}}}$';
%            'ea*exp(vol(-1))';
%            '$Pvalue_{ea}$';
%            'ex*exp(vol(-1))';
%            '$Pvalue_{ex}$';
%            'ev';
%            '$Pvalue_{ev}$';
%            'R-squared';
%            };
% 
% columnLabels={'Is Regression Results'};
% matrix2latex(regresults,strcat([saved_dir,'\table_regression.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
% 
% % vol regression table
% clear rowLabels columnLabels
% 
% rowLabels={'Const';
%            '$Pvalue_{Const}$';
%            '$\log(std(-1))$';
%            '$Pvalue_{\log(std(-1))}$';
%            'ex*exp(vol(-1))';
%            '$Pvalue_{ex}$';
%            'ea*exp(vol(-1))';
%            '$Pvalue_{ea}$';
%            'R-squared';
%            };
% 
% columnLabels={'Vol Regression Results'};
% matrix2latex(regresults_vol,strcat([saved_dir,'\table_regression_vol.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
% end;



% Conditional moments table
if ep_cov_calc_switch==1
    
    clear rowLabels columnLabels

    columnLabels={'Moments'};

    if gold_switch==1
    rowLabels={'$E_t\left[r^{f}\right]$ (\%)';
               '$E_t\left[r_{k,ex}^{LEV}\right]$ (\%)';
               '$E_t\left[r_{g,ex}\right]$ (\%)'};
    matrix2latex([cond_sim_RF; cond_sim_EP_lev; cond_sim_EP_G],strcat([saved_dir,'\table_cond_moments.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
    else
    rowLabels={'$E_t\left[r^{f}\right]$ (\%)';
               '$E_t\left[r_{ex}^{LEV}\right]$ (\%)'};    
    matrix2latex([cond_sim_RF; cond_sim_EP_lev],strcat([saved_dir,'\table_cond_moments.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
    end

end


% Gold parameters and moments tables (SAM ADD)
if gold_switch==1  
    
    % parameters table
    clear rowLabels columnLabels
    param_gold = str2num(num2str([varphi_g G_ss Gbar_ss f_g coint_g a1_g tau_g phi0_g phi1_g eps_g sigma_g corr_g ],'%3.5f ')); % SAM EDIT
    columnLabels={'$\varphi_g$';'$Gpct_{SS}$';'$\overline{G}_{ss}/K_{ss}$';'$f_g$'; '$\tau_{coint}$'; '$a_{1g}$'; '$\tau_{g}$'; '$\phi_{0}$'; '$\phi_{1}$'; '$\epsilon_{g}$'; '$\sigma_{g}$'; '$\rho_{x,g}$'};
    rowLabels={' '};
    matrix2latex(param_gold,strcat([saved_dir,'\table_parameters_gold.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')

    % moments table
    rowLabels={'$E\left[r_{G}^{ex}\right]$ (\%)';
               '$\sigma(r_{G}^{ex})$ (\%)';
               '$E\left[J/Y\right] (\%)$';
               '$\sigma(J/Y)$ (\%)'};
    columnLabels={'Moments'};
    matrix2latex(output_G(:,1),strcat([saved_dir,'\table_moments_gold.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
    
    disp('G moments')
    output_copy_paste = [output_copy_paste; 
                         output_G(:,1)];
    
end



%% Write tex report
write_tex
eval(strcat(['cd ',saved_dir]))
if mac_switch == 1
   system(strcat(['/Library/TeX/texbin/pdflatex "Report.tex" -jobname Report_',num2str(cal_no)]));
else
eval(strcat(['!pdflatex.exe "Report.tex" -jobname Report_',num2str(cal_no)]))
end

cd ..
cd ..

%% Housekeeping
disp('Housekeeping ...');
movefile(strcat(fname,'*'),saved_dir)
if mac_switch == 1
open(strcat(saved_dir,'/Report.pdf'));    
else
open(strcat(saved_dir,'\Report_',num2str(cal_no),'.pdf'));
end

%disp('output_copy_paste:')
%output_copy_paste

clear all; %clc
beep;
toc