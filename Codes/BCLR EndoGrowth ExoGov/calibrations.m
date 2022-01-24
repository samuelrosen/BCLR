global a1 arc alphap alphac deltak deltac mar tau w Np Nc Lss gamma xi cxi sigma sigmax sigmas rhovol ar_1_switch b_ma beta croce_switch delta eps f gam labor_switch mubar Nbar phi psi rho rhoar rhotest rho_sigma stoch_vol_switch tca_productivity_switch v varphi vcov voltense ORDER test
global gold_switch varphi_g f_g Gbar_ss coint_g tau_g a1_g eps_g phi0_g phi1_g sigma_g corr_g G_ss QG_ss con_shocka con_shockx volx phi_growth rhoinv phi_growth_f Np_ss Nc_ss theta_sla omega Abar xi_p nu eta chi ome_p_bar phi_p gcctrl
global ep_cov_calc_switch conditional_moments_switch shock_direction_switch simul_fast pdratio allshocks shortlongshocks gov_adjustment_switch theta_P theta_G phi_o_s
global biga bigv bnca bncv rho_ig rho_nc rho_ivol rho_ia rho_nvol rho_na exo_gov_switch IcYratio IcYratioExo exo_gov_labor_lag bundle_labor
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%%
%% Default Calibration with labor %%
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%%

%% Frequency
frEq=4;
%% Technology
alphap  = 0.3;                    % Production function exponent
deltak  = 0.06/frEq;             % Depreciation rate of capital in normal goods sector
Lss   = 0;                  % leisure in steady state.
Np_ss = 1-Lss;
Nc_ss = 1-Lss;
theta_P = 0;
theta_G = 0;
theta_sla = 0.1;
omega = 100000;
xi    = 10;                     % Adjustment cost exponent
tau = 5;
w = 0.8;
phi_o_s = 0;
voltense = 2.3;
%% Government Passive Rule
biga = 0;
bigv = 0;
bnca = 0;
bncv = 0;
rho_ig = 0;
rho_nc = 0;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
exo_gov_switch = 1;
exo_gov_labor_lag = 0;
IcYratioExo = 0;
%% Preferences
gamma    = 10;                      % Risk aversion
psi    = 2.0;  %2.5               % Intertemporal elasticity of substitution
beta   = 0.973^(1/frEq);          % Subjective discount factor 
% f      = 1; %1.1                  % Elasticity of substitution between consumption and labor
% phi    = 1;                       % phi=1 => A_{t}   in consumption-labor
                                  % phi=0 => A_{t-1} in consumption-labor
labor_switch = 0;                 % ==1 -> with labor
tca_productivity_switch = 1;      % ==1 -> No labor-augmenting productivity in utility

%% Productivity
mubar       = 0.0195/frEq;            % Long run mean of productivity
rho      = 0.961^(1/frEq);         % Persistence of long run shock
sigma  = 0.045/sqrt(frEq);        % Std of short-run shock
sigmax = 0.1*sigma;               % Std of long-run shock
phi_x    = 0.10;                  % Rescaling factor for LRR
ar_1_switch = 0;                  % if 1, we switch to growth ~ AR(1)
                                  % if 2, we switch to growth ~ ARMA(1,1)
b_ma       = 0;                   % MA(1) if da~ARMA(1,1)
rhoar = 0.8;
rhoinv = 0.1;

arc = -0.4322;
%% Vol-of-Vol
rhovol   = rho;                   % Stochastic vol persistence
sigmas = 2*sigma;              % Vol of vol
corr_v    = 0;                    % Correlation betwenn vol-shocks and LRR-news
stoch_vol_switch = 1;             % =1 have stochastic vol, =0 no stoch vol
volx=1;
con_shocka =0;
con_shockx =0;
%% Adjustment costs
croce_switch = 0;                 % =1 Croce approximated adjustment costs; 
                                  % =0 Jermann adjustment costs ("a1" = elasticity);
                                  % =2 BCF;
                                  % =3 nothing;
                                  % =4 ACL.
                                  
                                  
                                  %% Gov Adjustment costs
gov_adjustment_switch = 0;                 % =0 revertible costs; 
                                  % =1 irrevertible costs;
                                 
sigma_g     = 0/sqrt(frEq);   % Gold Storage vol
corr_g      = 0;              % corr(Gold, LRR)

%% Storage goods sector
gold_switch = 0;     % Activates the gold side   
alphac  = 0.3;       % Production function exponent
deltac = deltak;          % Depreciation rate of capital in storage goods sector
cxi = 10;           % Adjustment cost exponent  
mar = 0.0076;      % Production function exponent
philev = 2;
pdratio = 0;
gcctrl = 1;
%% Innovation
xi_p = 0.47;
eta = 0.83;
chi = 0.45;
ome_p_bar = 0;
phi_p = 0.04;



%% Investment Growth Option
phi_growth = 0;
phi_growth_f = 5;
%% Calculate equity premium manually using covariance formula (see sim_dyn_mod.m)
ep_cov_calc_switch = 0;
                          
%% Calculate conditional moments (see sim_dyn_mod.m)
conditional_moments_switch = 0;

%% Simul_Fast Option
simul_fast = 1; 

%% Positive or Negative Shocks for IRFs
shock_direction_switch = 1; % 1 = positive shocks, (-1) = negative shocks

%% Abs Value approximation parameter
% eps    = 100;	% Coeff 4 approximation of absolute value    
% eps_g  = 10;	% Coeff 4 approximation of absolute value (gbar constraint) 

%% Approx Order
ORDER  = 3;
allshocks=0;
shortlongshocks=0;


%%~~~~~~~~~~~~~~~~~~~~~~~%%
%% Gold     calibrations %%
%%~~~~~~~~~~~~~~~~~~~~~~~%%
     
    
    %% All calibrations 0--9 have no gold  
        
        gold_switch  = 0;
        test = 0;
       
     
     if cal_no==1 %exogenous government policy
       ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.1;
bigv = 0.02;
bnca = -0.02;
bncv = 0.003;
rho_ig = 0.8;
rho_nc = 0.9;
     end
                                                                    
          if cal_no==2 %123 in Monopoly Folder
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
          end
          if cal_no==3 %123 in Monopoly Folder
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
          end
            
              if cal_no==4 %123 in Monopoly Folder
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
          end
  
                            if cal_no==11 %exogenous government policy
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
                            end         
                             if cal_no==12 %Fit the data IRFs
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.4;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.7;
rho_nc = 0.85;
                             end 
                                                     if cal_no==13 %exogenous government policy
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.021/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -1.2;
bigv = 0.025;
bnca = -1;
bncv = 0.012;
rho_ig = 0.7;
rho_nc = 0.85;
     end              
                             if cal_no==14 %full depreciation
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
IcYratio = 0.03;
IcYratioExo = 1;
                             end 
                             if cal_no==15 %full depreciation and low TFP level
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.65;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
IcYratio = 0.03;
IcYratioExo = 1;
                             end 
                             if cal_no>= 21 && cal_no<= 25
                             exo_gov_labor_lag = 1;
                             end
                              if cal_no==21 %exogenous government policy
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
                            end         
                             if cal_no==22 %Fit the data IRFs
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.4;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.7;
rho_nc = 0.85;
                             end 
                                                     if cal_no==23 %exogenous government policy
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.021/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -1.2;
bigv = 0.025;
bnca = -1;
bncv = 0.012;
rho_ig = 0.7;
rho_nc = 0.85;
     end              
                             if cal_no==24 %full depreciation
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
IcYratio = 0.03;
IcYratioExo = 1;
                             end 
                             if cal_no==25 %full depreciation and low TFP level
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.65;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
IcYratio = 0.03;
IcYratioExo = 1;
                             end
                             if cal_no>= 21 && cal_no<= 25
                             bncv = 0.0012;
                             end
                       
                              if cal_no==31 %exogenous government policy
                                  exo_gov_labor_lag = 1;
                                  bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
                              end         
                                                      if cal_no==34 %full depreciation
                                                          exo_gov_labor_lag = 1;
                                                                    bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
IcYratio = 0.03;
IcYratioExo = 1;
                             end 
                             if cal_no==35 %full depreciation and low TFP level
                                 exo_gov_labor_lag = 1;
                                 bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.025/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.65;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3;
bigv = 0.025;
bnca = -0.3;
bncv = 0.012;
rho_ig = 0.65;
rho_nc = 0.8;
IcYratio = 0.03;
IcYratioExo = 1;
                             end   
                             if cal_no==41 %exogenous government policy
                                  exo_gov_labor_lag = 1;
                                  bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.3; %-0.3
bigv = 0.05; %0.025
bnca = -0.3; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;

                             end        
                                                                    if cal_no==44 %full depreciation
                                                          exo_gov_labor_lag = 1;
                                                                    bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
IcYratio = 0.03;
IcYratioExo = 1;
                             end 
                             if cal_no==45 %full depreciation and low TFP level
                                 exo_gov_labor_lag = 1;
                                 bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.65;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
IcYratio = 0.03;
IcYratioExo = 1;
                             end   
                             if cal_no==51 %exogenous government policy
                                  exo_gov_labor_lag = 1;
                                  bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;

                             end        
                                                                    if cal_no==54 %full depreciation
                                                          exo_gov_labor_lag = 1;
                                                                    bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
IcYratio = 0.03;
IcYratioExo = 1;
                             end 
                             if cal_no==55 %full depreciation and low TFP level
                                 exo_gov_labor_lag = 1;
                                 bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.65;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
IcYratio = 0.03;
IcYratioExo = 1;
                             end   
                             
                                                        if cal_no==61 %exogenous government policy
                                  exo_gov_labor_lag = 1;
                                  bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0; %0.025
bnca = -0.5; %-0.3
bncv = 0; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;

                             end        
                                                                    if cal_no==64 %full depreciation
                                                          exo_gov_labor_lag = 1;
                                                                    bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.97;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.098;%0.128 0.0973
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
IcYratio = 0.03;
IcYratioExo = 1;
                             end 
                             if cal_no==65 %full depreciation and low TFP level
                                 exo_gov_labor_lag = 1;
                                 bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.65;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
IcYratio = 0.03;
IcYratioExo = 1;
                             end   
                                       if cal_no==71 %123 in Monopoly Folder
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
                                       end
                                      if cal_no==72 %exogenous government policy
                                  exo_gov_labor_lag = 1;
                                  bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;

                             end        
                                                                    if cal_no==73 %full depreciation
                                                          exo_gov_labor_lag = 1;
                                                                    bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 
        deltac = 1;
        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.22*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.9; %-0.3
bigv = 0.025; %0.025
bnca = -0.5; %-0.3
bncv = 0.012; %0.012
rho_ig = 0.6; %0.65
rho_nc = 0.8; %0.8
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
IcYratio = 0.03;
IcYratioExo = 1;
                                                                    end
                                                                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                                    
                                                                    
                                                                    
if cal_no==81 ... % 81 is New Benchmark June 2020. other cals are deviations that Sam tried out in October 2020
        || cal_no==90 || cal_no==91 || cal_no==92 || cal_no==93 || cal_no==94 || cal_no==95 || cal_no==96 || cal_no==97 || cal_no==98 || cal_no==99 ...
        || cal_no==120 || cal_no==121 || cal_no==122 || cal_no==123 || cal_no==124 || cal_no==125 || cal_no==126 || cal_no==127 || cal_no==128 || cal_no==129 ...
        || cal_no==78 ... % new calibration that affect average Ig/Y added may 2021 for jpe responses
        || cal_no==77 % new calibration that fix labor added june 2021 for jpe responses
    
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
         %xi  = 4;                     % Adjustment cost exponent 3.5
         %cxi = 4;           % Adjustment cost exponent 3.5
         xi  = 5; % SAM change in nov 2020 as part of last-minute calibration fix
         cxi = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        %gamma    = 10;                      % Risk aversion
         gamma  = 12; % SAM change in nov 2020 as part of last-minute calibration fix        
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5; 
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
%eta = 0.76;
%chi = 0.128;
eta = 0.80; % SAM change in nov 2020 as part of last-minute calibration fix
chi = 0.122; % SAM change in nov 2020 as part of last-minute calibration fix
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
simul_fast = 1; 
simul_fast = 0; % SAM: put simul_fast by default for time series moments
end
% added may 2021 to get different average level of Ig/Y
if cal_no==78
    % lower Ig/Y when Ig is endogenous
    deltac = 0.14/4;
end
% added june 2021 to see what happens if labor is fixed
if cal_no==77
      theta_P = 10;
      theta_G = 10;
end

% sensitivities wrt a single parameter
    if cal_no==90 % 
            psi =1.8;
    end                                       
    if cal_no==91 % 
            psi=2.2;
    end  
    if cal_no==92 % 
            gamma  = 10.8;
    end                                       
    if cal_no==93 % 
            gamma  = 13.2;
    end  
    if cal_no==94 
            chi  = 0.110;
    end                                       
    if cal_no==95 
            chi  = 0.130;
    end  
    if cal_no==96
            eta  = 0.72;
    end                                       
    if cal_no==97 
            eta  = 0.88;
    end      
    if cal_no==98 % exp(arc) is equal to chiL in the text
            arc  = log(0.60);
    end                                       
    if cal_no==99 
            arc  = log(0.70);
    end          
    if cal_no==120 
        sigmas  = 0.00000000000000000000001;
    end              
    if cal_no==121
        % empty
        sigmas  = 0.00000000000000000000001;
        phi_o_s = -0.015;
    end                
    if cal_no==122 
        omega = 1.2;
    end              
    if cal_no==123
        omega = 1.8;
    end       
    
if cal_no==82 ... % EGI June 2020
    || cal_no==130 || cal_no==131 || cal_no==132 || cal_no==133 || cal_no==134 || cal_no==135 || cal_no==136 || cal_no==137 || cal_no==138 || cal_no==139 ...
    || cal_no==140 || cal_no==141 || cal_no==142 || cal_no==143 || cal_no==144 || cal_no==145 || cal_no==146 || cal_no==147 || cal_no==148 || cal_no==149 ...
    || cal_no==79 % new calibratinos that affect average Ig/Y added may 2021 for jpe responses

        exo_gov_labor_lag = 1;
        bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
         %xi  = 4;                     % Adjustment cost exponent 3.5
         %cxi = 4;           % Adjustment cost exponent 3.5
        % xi  = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        % cxi = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        xi   = 8; % changed in december 2020 to improve EGI cal
        cxi  = 8; % changed in december 2020 to improve EGI cal         
        %gamma    = 10;                      % Risk aversion
         gamma  = 12; % SAM change in nov 2020 as part of last-minute calibration fix        
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 %beta   = 0.98^(1/frEq);          % Subjective discount factor
 beta = 0.965^(1/frEq); % changed in december 2020 to improve EGI cal
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       %sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        %sigmax = 0.22*sigma;               % Std of long-run shock
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock. updated dec 2020 to match benchmark 81
        sigmax = 0.2*sigma;               % Std of long-run shock. updated dec 2020 to match benchmark 81
        
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
%eta = 0.76;
%chi = 0.128;
%eta = 0.80; % SAM change in nov 2020 as part of last-minute calibration fix
eta  = 0.76; % changed in december 2020 to improve EGI cal
chi = 0.122; % SAM change in nov 2020 as part of last-minute calibration fix
rhoar = 0.99;
%biga = -0.9; %-0.3
%bigv = 0.025; %0.025
%bnca = -0.5; %-0.3
%bncv = 0.012; %0.012
biga = -0.04; %-0.3 % changed in december 2020 to improve EGI cal
bigv = 0.030; % changed in december 2020 to improve EGI cal
bnca = -0.2; %-0.3 % changed in december 2020 to improve EGI cal
bncv = 0.015; % changed in december 2020 to improve EGI cal
%rho_ig = 0.6; %0.65
%rho_nc = 0.8; %0.8
rho_ig = 0.80; % SAM change in december 2020 to get better IRFs
rho_nc = 0.90; % SAM change in december 2020 to get better IRFs
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
%IcYratio = 0.03; % controls Ig/Itotal ratio
IcYratio = 0.040; % SAM change in december 2020 to match 5.3% avg in data
IcYratioExo = 1; % indicates that this ratio is exogenous
simul_fast=1; % speed up simulations
simul_fast=0;
end
% sensitivities wrt a single parameter
    if cal_no==130 % 
        beta = 0.966^(1/frEq); % Subjective discount factor
    end                                       
    if cal_no==131 % 
        beta = 0.964^(1/frEq); % Subjective discount factor
    end  
    if cal_no==132 % 
        %
    end                                       
    if cal_no==133 % 
        rho_ig = 0.70; %0.65
    end  
    if cal_no==134 % 
        rho_ig = 0.70; %0.65
        rho_nc = 0.85; %0.8 
    end     
    if cal_no==135 % 
        rho_ig = 0.80; %0.65
        rho_nc = 0.85; %0.8 
    end     
    if cal_no==136 
        rho_ig = 0.70; %0.65
        rho_nc = 0.90; %0.8 
    end                                       
    if cal_no==137
        rho_ig = 0.80; %0.65
        rho_nc = 0.90; %0.8 
    end  
    if cal_no==138
        rho_ig = 0.85; %0.65
        rho_nc = 0.90; %0.8 
    end                                       
    if cal_no==139
        rho_ig = 0.90; %0.65
        rho_nc = 0.90; %0.8 
    end 
    if cal_no==140 %          
        rho_ig = 0.7; %0.65
        rho_nc = 0.9; %0.8 
    end  
    if cal_no==141 % 
        bigv = 0.025; % changed in december 2020 to improve EGI cal
        bncv = 0.015; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65         
    end    
    if cal_no==142 % 
        bigv = 0.030; % changed in december 2020 to improve EGI cal
        bncv = 0.012; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65         
    end    
    if cal_no==143 % 
        bigv = 0.035; % changed in december 2020 to improve EGI cal
        bncv = 0.012; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65                  
    end   
    if cal_no==144 % 
        bigv = 0.035; % changed in december 2020 to improve EGI cal
        bncv = 0.015; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65         
    end        
    if cal_no==145 % 
        bigv = 0.030; % changed in december 2020 to improve EGI cal
        bncv = 0.018; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65      
    end   
    if cal_no==146 % 
        bigv = 0.035; % changed in december 2020 to improve EGI cal
        bncv = 0.018; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65
    end     
    if cal_no==147 % 
        bigv = 0.035; % changed in december 2020 to improve EGI cal
        bncv = 0.020; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65
    end   
    if cal_no==148 % 
        bigv = 0.040; % changed in december 2020 to improve EGI cal
        bncv = 0.018; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65
    end      
    if cal_no==149 % 
        bigv = 0.040; % changed in december 2020 to improve EGI cal
        bncv = 0.020; % changed in december 2020 to improve EGI cal
        rho_ig = 0.7; %0.65 
    end          
%     if cal_no==148
%         biga = -0.04; %-0.3
%         bnca = -0.2; %-0.3
%          beta   = 0.965^(1/frEq);          % Subjective discount factor
%             eta  = 0.75;
%          xi  = 8; % try less strict capital adjustment costs
%          cxi = 8; % try less strict capital adjustment costs                
%     end       
%     if cal_no==149
%         biga = -0.04; %-0.3
%         bnca = -0.2; %-0.3
%          beta   = 0.96^(1/frEq);          % Subjective discount factor
%             eta  = 0.72;
%          xi  = 8; % try less strict capital adjustment costs
%          cxi = 8; % try less strict capital adjustment costs                
%     end     
% added may 2021 to get different average level of Ig/Y
if cal_no==79
    IcYratio = 0.024; % to get average Ig/Y of 3.1%
end



 if cal_no==83 %full depreciation June 2020
                                                          exo_gov_labor_lag = 1;
                                                                    bundle_labor = 1;
         ORDER       = 3; 
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
         %xi  = 4;                     % Adjustment cost exponent 3.5
         %cxi = 4;           % Adjustment cost exponent 3.5
        % xi  = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        % cxi = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        xi   = 8; % changed in december 2020 to improve EGI cal
        cxi  = 8; % changed in december 2020 to improve EGI cal   
        deltac = 1;
        %gamma    = 10;                      % Risk aversion
         gamma  = 12; % SAM change in nov 2020 as part of last-minute calibration fix        
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
%beta   = 0.98^(1/frEq);          % Subjective discount factor
 beta = 0.965^(1/frEq); % changed in december 2020 to improve EGI cal
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
       %sigma  = 0.022/sqrt(frEq);        % Std of short-run shock
        %sigmax = 0.22*sigma;               % Std of long-run shock
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock. updated dec 2020 to match benchmark 81
        sigmax = 0.2*sigma;               % Std of long-run shock. updated dec 2020 to match benchmark 81       
        
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
%eta = 0.76;
%chi = 0.128;
%eta = 0.80; % SAM change in nov 2020 as part of last-minute calibration fix
eta  = 0.76; % changed in december 2020 to improve EGI cal
chi = 0.122; % SAM change in nov 2020 as part of last-minute calibration fix
rhoar = 0.99;
%biga = -0.9; %-0.3
%bigv = 0.025; %0.025
%bnca = -0.5; %-0.3
%bncv = 0.012; %0.012
biga = -0.04; %-0.3 % changed in december 2020 to improve EGI cal
bigv = 0.030; % changed in december 2020 to improve EGI cal
bnca = -0.2; %-0.3 % changed in december 2020 to improve EGI cal
bncv = 0.015; % changed in december 2020 to improve EGI cal
%rho_ig = 0.6; %0.65
%rho_nc = 0.8; %0.8
rho_ig = 0.80; % SAM change in december 2020 to get better IRFs
rho_nc = 0.90; % SAM change in december 2020 to get better IRFs
% IcYratio = 0.05;
% IcYratioExo = 1;
rho_ivol = 0;
rho_ia = 0;
rho_nvol = 0;
rho_na = 0;
%IcYratio = 0.03; % controls Ig/Itotal ratio
IcYratio = 0.04; % SAM change in december 2020 to match 5.3% avg in data
IcYratioExo = 1;
simul_fast=1;
simul_fast=0;
end 
    if cal_no==84 || cal_no==150 || cal_no==151 || cal_no==152 || cal_no==153 || cal_no==154 %no government sector June 2020
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
         %xi  = 4;                     % Adjustment cost exponent 3.5
         %cxi = 4;           % Adjustment cost exponent 3.5
         xi  = 5; % SAM change in nov 2020 as part of last-minute calibration fix
         cxi = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        %gamma    = 10;                      % Risk aversion
         gamma  = 12; % SAM change in nov 2020 as part of last-minute calibration fix  
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.999;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5; 
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
%eta = 0.76;
%chi = 0.128;
eta = 0.80; % SAM change in nov 2020 as part of last-minute calibration fix
%chi = 0.122; % SAM change in nov 2020 as part of last-minute calibration fix
chi = 0.0973; % SAM: chi value was already diff in this cal so just leave this value
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
% simul_fast = 1; 
 simul_fast = 0; 
    end  
    % additional variations for JPE referee response june 2021
    if cal_no==150 
        eta = 0.72;
    end
    if cal_no==151
        eta = 0.88;
    end
    if cal_no==152
        omega = 1.2;
    end
    if cal_no==153
        omega = 1.8;
    end    
    if cal_no==154
        omega = 3.0;
    end               
    
    if cal_no==85 %CRRA gamma = 10 IES = 0.1 June 2020
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
         %xi  = 4;                     % Adjustment cost exponent 3.5
         %cxi = 4;           % Adjustment cost exponent 3.5
         xi  = 5; % SAM change in nov 2020 as part of last-minute calibration fix
         cxi = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        %gamma    = 10;                      % Risk aversion
         gamma  = 12; % SAM change in nov 2020 as part of last-minute calibration fix  
          psi = 1/gamma;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5; 
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
%eta = 0.76;
%chi = 0.128;
eta = 0.80; % SAM change in nov 2020 as part of last-minute calibration fix
%chi = 0.122; % SAM change in nov 2020 as part of last-minute calibration fix
chi = 0.23; % SAM: chi value was already diff in this cal so just leave this value
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
% simul_fast = 1; 
simul_fast = 0; 
                                       end
   if cal_no==86 %CRRA gamma = 0.5 IES = 2 June 2020
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
         %xi  = 4;                     % Adjustment cost exponent 3.5
         %cxi = 4;           % Adjustment cost exponent 3.5
         xi  = 5; % SAM change in nov 2020 as part of last-minute calibration fix
         cxi = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        gamma    = 0.5;                      % Risk aversion
          psi = 1/gamma;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5; 
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
%eta = 0.76;
%chi = 0.128;
eta = 0.80; % SAM change in nov 2020 as part of last-minute calibration fix
%chi = 0.122; % SAM change in nov 2020 as part of last-minute calibration fix
chi = 0.139; % SAM: chi value was already diff in this cal so just leave this value
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
% simul_fast = 1; 
simul_fast = 0; 
   end        
                                       
   if cal_no==87 %with preference shocks \phi = -0.015 2020
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
         %xi  = 4;                     % Adjustment cost exponent 3.5
         %cxi = 4;           % Adjustment cost exponent 3.5
         xi  = 5; % SAM change in nov 2020 as part of last-minute calibration fix
         cxi = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        %gamma    = 10;                      % Risk aversion
         gamma  = 12; % SAM change in nov 2020 as part of last-minute calibration fix  
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5; 
      theta_P = 0;
      theta_G = 0;
      phi_o_s = -0.015;
      xi_p = 0.49;
%eta = 0.76;
%chi = 0.128;
eta = 0.80; % SAM change in nov 2020 as part of last-minute calibration fix
chi = 0.122; % SAM change in nov 2020 as part of last-minute calibration fix
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
% simul_fast = 1; 
simul_fast = 0; 
                                       end
   
      if cal_no==88 %No vol June 2020
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
         %xi  = 4;                     % Adjustment cost exponent 3.5
         %cxi = 4;           % Adjustment cost exponent 3.5
         xi  = 5; % SAM change in nov 2020 as part of last-minute calibration fix
         cxi = 5; % SAM change in nov 2020 as part of last-minute calibration fix
        %gamma    = 10;                      % Risk aversion
         gamma  = 12; % SAM change in nov 2020 as part of last-minute calibration fix  
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
      sigmas  = 0.00000000000000000000001;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5; 
      theta_P = 0;
      theta_G = 0;
      %phi_o_s = -0.015;
      phi_o_s = 0; % sam change this to zero in december 2020
      xi_p = 0.49;
%eta = 0.76;
%chi = 0.128;
eta = 0.80; % SAM change in nov 2020 as part of last-minute calibration fix
chi = 0.122; % SAM change in nov 2020 as part of last-minute calibration fix
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
% simul_fast = 1; 
simul_fast = 0; 
                                       end
      if cal_no==101 %New Benchmark July 2020 for sp
          bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        %xi    = 4;                     % Adjustment cost exponent 3.5
        %cxi = 4;           % Adjustment cost exponent 3.5
        xi  = 5; % sam change on december 20 to match november 2020 benchmark
        cxi = 5; % sam change on december 20 to match november 2020 benchmark
        
        %gamma    = 10;                      % Risk aversion
        gamma    = 12; % sam change on december 20 to match november 2020 benchmark
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line      
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 9; 
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
%eta = 0.76;
eta = 0.80; % sam change on december 20 to match november 2020 benchmark
% chi = 0.1882;
%chi = 0.128;
chi = 0.122; % sam change on december 20 to match november 2020 benchmark
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
simul_fast=1;
simul_fast=0;
                                       
                                       end
                                                 if cal_no==102 %123 in Monopoly Folder
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 8.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
                                                 end
                                                          if cal_no==103 %123 in Monopoly Folder
      bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 3.5;                     % Adjustment cost exponent
                cxi = 3.5;           % Adjustment cost exponent 

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 8.5;
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.83;
% chi = 0.1882;
chi = 0.06;
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
                                                          end
          
 if cal_no == 115
       bundle_labor = 1;
       ORDER       = 3; 
       exo_gov_switch = 0;
        alphap  = 0.3;                    % Production function exponent
         alphac  = 0.3;       % Production function exponent
        xi    = 4;                     % Adjustment cost exponent 3.5
                cxi = 4;           % Adjustment cost exponent 3.5

        gamma    = 10;                      % Risk aversion
        psi =2;
        rho =0.98;
        rhovol = 0.74;
%        beta   = 0.985^(1/frEq);          % Subjective discount factor
 beta   = 0.98^(1/frEq);          % Subjective discount factor
%         sigma  = 0.053/sqrt(frEq);        % Std of short-run shock
%         sigmax = 0.05*sigma;               % Std of long-run shock
%         rhovol   = 0.9;                   % Stochastic vol persistence
%         sigmas = 2*sigma;              % Vol of vol
        sigma  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax = 0.2*sigma;               % Std of long-run shock
       
        tau = 5;
        w = 0.8;
        stoch_vol_switch = 1;   % STOCHASTIC VOLATILITY
       con_shocka =-3.5;
       sigmas  = 0.1538;
       phi_growth = 0;
       phi_growth_f = 0;
%        con_shockx =0.0123*1000;

%           voltense = 1+sigmas; % SAM: new line
  voltense = 3; % SAM: new line
%           simul_fast=1;
      arc = -0.4322;
      theta_sla = 0.1;
      omega = 1.5; 
      theta_P = 0;
      theta_G = 0;
      phi_o_s = 0;
      xi_p = 0.49;
eta = 0.76;
% chi = 0.1882;
chi = 0.128;
rhoar = 0.99;
biga = -0.1;
bigv = 0.1;
bnca = -0.1;
bncv = 0.1;
rho_ig = 0.9;
rho_nc = 0.9;
simul_fast = 0; 
%simul_fast = 0; % SAM: put simul_fast by default for time series moments

          gamma = 12;
            chi   = 0.122;
            eta   = 0.80;
            xi    = 5;                     % Adjustment cost exponent 3.5
                cxi = 5;           % Adjustment cost exponent 3.5
     end
%% Endo determined parameters               

nu = xi_p/(xi_p+(1-alphap)*(1-xi_p));
Abar = (xi_p*nu*(1-1/tau)/(1-xi_p/tau))^(xi_p/(1-xi_p));
ome_p_bar = -log(Abar)/(1-alphap);

exo_parameters = [ 
rho_ig ; %0.65    
biga; %-0.3
bigv; %0.025
rho_nc; %0.8
bnca; %-0.3
bncv; %0.012
rho_ivol;
rho_ia;
rho_nvol;
rho_na   
];     
                                    
                                           
                                           
%% Fixing the V-Cov matrix once and for all (except for ARMA)

if ar_1_switch ~= 2;

    if stoch_vol_switch==1
        
        if gold_switch==1
        %            ea          ex               es                eg
        vcov   = [sigma^2        0                0                 0;
                 0      (sigma*phi_x)^2           0  corr_g*(sigma*phi_x*sigma_g);
                 0               0            sigmas^2                0
                 0   corr_g*(sigma*phi_x*sigmax)  0                 sigma_g^2];
        else
         %            ea          ex        es
        vcov   = [sigma^2        0         0;
                 0    (sigma*phi_x)^2      corr_v*(sigma*phi_x*sigmas);
                 0               corr_v*(sigma*phi_x*sigmas)         sigmas^2];   
        end
            
    
    
%     elseif stoch_vol_switch==0
%         
%     
%         if gold_switch==1
%          %          ea     ex             eg
%         vcov   = [sigma_a^2  0               0;  
%                    0  phi_x^2*sigma_a^2   corr_g*(sigma_a*phi_x*sigma_g);
%                    0  corr_g*(sigma_a*phi_x*sigma_g)          sigma_g^2]; 
%         else
%                %            ea     ex       
%         vcov   = [sigma_a^2  0               ;  % Default, no TVV
%                    0  phi_x^2*sigma_a^2];      
%                  
%         end
               
    
    end
    
end






%% Fixing Labor 
% If varphi==1, then specify it in the calibration above. Otherwise, do not
% give varphi a value, and varphi will be calculated so that the steady
% state of exp(n)=Nbar. Note that if varphi=1 and Nbar=1, then leisure
% disappears from utility and \tilde_C = C.
if labor_switch==0
    varphi=1;
end

if isempty(varphi)
    varphi_ss
end

if simul_fast == 1
    disp('Simulations *reduced* to be fast');
end

