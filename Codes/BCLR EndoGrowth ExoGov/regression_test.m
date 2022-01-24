function regression_test(mod)

close all

addpath(genpath('Monopoly Power'))
clearvars -global -except mod1 varargin; clc;



% %% Choose shocks and corresponding titles for each column
% if length(varargin)>=2
%   shocks = {varargin{1}; varargin{2}};
% else
%     disp('Using default shocks ea and es');
%     shocks = {'ex'; 'es'};
% end
% 
% MyTitles = {'NEED TITLE'; 'NEED TITLE'};

    

% %% Choose variables for IRF
% if length(varargin)==3
%     irf_vars={varargin{3}};
% else
%     %irf_vars={{'da';'dc';'di';'m';'exr';'q';'n'}};
%     irf_vars={{'dy';'dyp';'dc';'kratio';'dip';'igitot';'Vexp'}};
%     %irf_vars={{'da';'condE_exr';'corr_m&exr';'condStd_m';'condStd_exr';'covar_m&exr'}};
%     %irf_vars={{'dc';'di';'rf';'covar_m&r';'covar_m&rc'}};
% end
% 
% %compare_mod(5,5,'ea','ex',{'dc';'di';'rf';'covar_m&r';'covar_m&rc'})
% %compare_mod(5,5,'ex','es',{'dc';'di';'rf';'covar_m&r';'covar_m&rc'})

shocks = {'ea';'es';'ea_es'};
%% Plot of IRFs

        
           
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod),'/Monopoly_Power_Approx_',num2str(mod),'.mat'));
          Iqs_Itot = Istest'./Itottest';
          ea = shocks_times(1,:)'; 
           ex = shocks_times(2,:)'; 
            ev = shocks_times(3,:)'; 
          
          Y = Iqs_Itot(2:end);
X=[ones(length(Y),1) Iqs_Itot(1:end-1) ea(2:end,1) ex(2:end,1) ev(2:end,1)];
lags = 8;
weight = 1;
[Betas,Ses,Rsqr,Rsqradj,VCV,Ftest]=olsgmm(Y,X,lags,weight);
Tsta = Betas./Ses;
TCDF = tcdf(Tsta,length(Y)-5);
Pvalue_ols = 2*(1-tcdf(abs(Tsta),length(Y)-5));

save(strcat(fname,'.mat'),'Betas','Ses','Rsqr','Pvalue_ols','-append')            
          
end