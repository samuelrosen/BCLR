% close all
% clear all
% clc
% format long
% 
% %% ===========================================================
% % Preliminaries 
% %=============================================================
% 
% %***USER MODIFIES THIS SECTION***
% 
% order = 3;      %order of approximation  
% Ts = 50001;    %simulation length
% 
% 
% % Calibrated parameters
% alphap = 0.34;    
% mu = 0.018/12;     
% gamma = 13;          
% rho=0.8^(1/12);
% rhovol = 0.01;
% beta = 0.947^(1/12);%0.95
% sigma = 0.036/12^0.5;
% sigmax = 0.1*sigma; %No LRR sigmax = 0;
% sigmad = 0.065/12^0.5;
% sigmas = 0.1*sigmax;
% deltak = 0.06/12;
% deltac = 1;%0.0484;
% philev = 2;
% xi = 1.5;%7
% cxi = 40;
% xil = 1;
% psi = 2; %0.9
% %le = log(1-0.18);
% Lss = 0.82;
% mar = 1.0057;%1.002
% Pi = 1;
% alphac = 0.999;%0.99
global arc alphap alphac phi_growth rhoar deltak deltac mar Lss gamma xi cxi sigma sigmax sigmas rhovol ar_1_switch b_ma beta croce_switch delta eps f gam labor_switch mubar Nbar phi psi rho rho_sigma stoch_vol_switch tau tca_productivity_switch v varphi vcov ORDER Np_ss Nc_ss  Abar xi_p nu eta chi ome_p_bar phi_p gcctrl
global gold_switch IcYratio IcYratioExo bundle_labor
%% ===========================================================
% Deterministic Steady-State Values
%=============================================================
% clear;
% cal_no=1;
% calibrations;
% All variables de-trended
mu = mubar;
% mu = [0.326820488811955];
Mss = beta*exp(-mu/psi);                        % SDF
Rss = Mss^-1;                                  
Rcss = Mss^-1; 

%Vss = (1-Mss*exp(mu))^(-1);                     % value of consumption claim
qss = 1;                                        % marginal q
Kss = ((Rss+deltak-1)/(w*((1-1/tau)*(1-xi_p)*alphap*Abar)*(exp(ome_p_bar)*(1-Lss))^(1-alphap)))^(1/(alphap-1));    % capital
Kcss = ((Rcss+deltac-1)/((1-w)*(alphac*Abar)*(exp(ome_p_bar)*(1-Lss))^(1-alphap)*exp(arc)^(1-alphac)))^(1/(alphac-1));

Iss = Kss*(exp(mu)-(1-deltak));                    % investment
Icss = Kcss*(exp(mu)-(1-deltac));



Gss = 0;                             % adjustment cost function
Gprimss = 0;                                 % first derivative of the above
Yss = exp(log(Abar)+(1-alphap)*(ome_p_bar)+ alphap*(log(Kss)));                                % output
Ycss = exp(log(Abar)+(1-alphac)*(ome_p_bar)+ alphac*(log(Kcss))+arc);
ytss = 1/(1-1/tau)*log(w*Yss^(1-1/tau)+(1-w)*Ycss^(1-1/tau));
ptest = w/(1-w)*(Yss/Ycss)^(-1/tau);
ptiltest = 1/(1-w)*(Ycss/exp(ytss))^(1/tau);
x_pss = (1/(1-xi_p))*log(xi_p*nu*(1-1/tau)/(1-xi_p/tau)) + (1-alphap)*(ome_p_bar)+ alphap*(log(Kss))+(1-alphap)*log(1-Lss);
pi_pss = log(1/nu-1) + x_pss +log(ptest);
v_pss = pi_pss - log(1-(1-phi_p)*Mss);
S = (Mss*exp(v_pss)*(exp(mu) - (1-phi_p)))/ptiltest;
vtheta = log(chi) + (eta-1)*log(S);
gr = log(exp(vtheta+log(S)) + 1-phi_p);
Css = exp(ytss)-Iss-Icss-(ptest/ptiltest)*exp(x_pss)-S;                                  % consumption
%o = 1/(((1-alphap)*Yss/(1-Lss))*(Lss^(1/xil)/(Css)^(1/xil))+1);

Utss = ((1-beta)*Css^(1-1/psi)/(1-beta*exp(mu*(1-1/psi))))^(1/(1-1/psi));
% utss = ((1/(1-1/psi))*log((1-beta)*exp(x(5)*(1-1/psi))+beta*exp((1-1/psi)/(1-gamma)*x(4))));
ngss = mu;

alpha1ss = 1/((Iss/Kss)^(-1/xi));
alpha0ss = (Iss/Kss)-(alpha1ss/(1-1/xi))*(Iss/Kss)^(1-1/xi);

less = log(Lss);

%% The Initial Guess
X=[ log(Kss);
    log(Kcss);
    log(S);
    mu;
    ptiltest;
    ];

%% The Function
[x,FVAL,Stest,N] = fsolve(@(x) myfun3(x, beta, psi, Lss, alphac, alphap, deltak, deltac, tau, arc, w, Abar, ome_p_bar, xi_p, nu, eta, chi, phi_p),X, optimset('MaxFunEvals', 3000000,'MaxIter',100000,'Display','off'));

%[x,FVAL,Stest,N] = fsolve(@(x) myfun2(x, rho, beta, psi, gamma, Lss, alphac, alphap, deltak, deltac, xi, tau, arc, w, Gprimss, Gss, philev, Abar, ome_p_bar, xi_p, nu, eta, chi, phi_p),X, optimset('MaxFunEvals', 3000000,'MaxIter',100000,'Display','off'));
%EV1 ut2 ng ev c_bar c o y k i alpha1 alpha0 m cg cg_bar q r x yg ig rex rf;
kpss = x(1);
kcss = x(2);
sss = x(3);
ngss = x(4);
ptilss = x(5);

ycss =log(Abar)+(1-alphac)*(ome_p_bar)+ alphac*(kcss)+(1-alphac)*(log(1-Lss)+arc);
Icss = exp(kcss+ngss)-(1-deltac)*exp(kcss);
ypss = log(Abar)+(1-alphap)*(ome_p_bar)+ alphap*(kpss)+(1-alphap)*log(1-Lss);
yss = 1/(1-1/tau)*log(w*(exp(ypss))^(1-1/tau)+(1-w)*(exp(ycss))^(1-1/tau));

if exo_gov_switch == 1 && IcYratioExo == 1%1 ycss 2 Icss 3 kcss 4 yss
    X=[kpss;
   kcss;
sss;
ngss;
ptilss; 
    ycss;
    Icss;
    yss;
    ypss
    ];

[x,FVAL,Stest,N] = fsolve(@(x) myfun6(x, beta, psi, Lss, alphac, alphap, deltak, deltac, tau, arc, w, Abar, ome_p_bar, xi_p, nu, eta, chi, phi_p, IcYratio),X, optimset('MaxFunEvals', 3000000,'MaxIter',100000,'Display','off'));
kpss = x(1);
kcss = x(2);
sss = x(3);
ngss = x(4);
ptilss = x(5);
ycss = x(6);
Icss = x(7);
yss = x(8);
ypss = x(9);
end


pss = w/(1-w)*(exp(ypss-ycss))^(-1/tau);
ipss = log(exp(kpss+ngss)-(1-deltak)*exp(kpss));
x_pss = (1/(1-xi_p))*log(xi_p*nu*(1-1/tau)/(1-xi_p/tau)) + (1-alphap)*(ome_p_bar)+ alphap*(x(1))+(1-alphap)*log(1-Lss);
css= log(exp(yss)-exp(ipss)-Icss-(pss/ptilss)*exp(x_pss)-exp(sss));
pi_pss = log(1/nu-1) + x_pss +log(pss);
Mss = beta*exp(-x(4)/psi);
mss = log(Mss);
mcss = mss;
v_pss = pi_pss - log(1-(1-phi_p)*Mss);
dass = ngss;
vthetass = log(chi) + (eta-1)*sss;
npss = log(1-Lss);
ncss = log(1-Lss);
slass = 0;
wagepss = pss*(1-1/tau)*(1-alphap)*(1-xi_p)*exp(ypss)/(exp(npss));
wagecss = (1-alphac)*exp(ycss)/(exp(ncss));

if bundle_labor == 1
omega_barp = (1/ptilss)*wagepss;
omega_barc = (1/ptilss)*wagecss;
    X=[omega_barp;
       omega_barc
    ];

[x,FVAL,Stest,N] = fsolve(@(x) myfunlabor(x, wagepss, wagecss, ptilss, slass, npss, ncss, omega),X, optimset('MaxFunEvals', 3000000,'MaxIter',100000,'Display','off'));
omega_barp = x(1);
omega_barc = x(2);
tcass = log(exp(css) - omega_barp*exp(slass)*(exp(npss)+omega_barc*exp(ncss))^omega/omega);
else
omega_barp = (1/ptilss)*wagepss;
omega_barc = (1/ptilss)*wagecss;
tcass = log(exp(css) - omega_barp*exp(npss)^omega/omega-omega_barc*exp(ncss)^omega/omega);
end


utss = log(((1-beta)*exp(tcass)^(1-1/psi)/(1-beta*exp(ngss*(1-1/psi))))^(1/(1-1/psi)));
EVss = exp((utss+ngss)*(1-gamma));
evss = log(EVss);
gdpss = log(exp(yss)-(pss/ptilss)*exp(x_pss));


X=[ utss;
    ];

[x,FVAL,Stest,N] = fsolve(@(x) myfun4(x, beta, psi, gamma, tcass, ngss),X, optimset('MaxFunEvals', 3000000,'MaxIter',100000,'Display','off'));

utss = x(1);
EVss = exp((utss+ngss)*(1-gamma));
evss = log(EVss);
% utss = (1/(1-1/psi))*log((1-beta)*exp(tcass*(1-1/psi))+beta*exp((1-1/psi)/(1-gamma)*evss));

alpha1 = 1/((exp(ipss)/exp(kpss))^(-1/xi));
alpha0 = (exp(ipss)/exp(kpss))-(alpha1/(1-1/xi))*(exp(ipss)/exp(kpss))^(1-1/xi);
calpha1 = 1/((Icss/exp(kcss)+gcctrl)^(-1/cxi));
calpha0 = (Icss/exp(kcss)+gcctrl)-(calpha1/(1-1/xi))*(Icss/exp(kcss)+gcctrl)^(1-1/xi);
qpss = ptilss;
qcss = ptilss;
pqrss = qcss/qpss;
rfss = -mss;
rss = -mss;
rcss = -mss;
if exo_gov_switch == 1 && IcYratioExo == 1
   rcss = log((alphac*exp(ycss-kcss)+(qcss*(1-deltac)+qcss*(-1*Icss*exp(-kcss)+Icss/exp(kcss))))/(qcss));
end
mu = ngss;

% 
% Kss = exp(x(1));
% ptest = (w/(1-w)*(exp((alphap*(x(1)) + (1-alphap)*log(1-Lss))-(alphac*(x(2))+ (1-alphac)*(log(1-Lss)+arc))))^(-1/tau));
% x_pss = (1/(1-xi_p))*log(xi_p*nu*(1-1/tau)/(1-xi_p/tau)) + (1-alphap)*(ome_p_bar)+ alphap*(log(Kss))+(1-alphap)*log(1-Lss);
% pi_pss = log(1/nu-1) + x_pss +log(ptest);
% 
% S = (Mss*exp(v_pss)*(exp(mu) - (1-phi_p)))/x(5);
% p_testtest = (w/(1-w)*(exp((alphap*(x(1)) + (1-alphap)*log(1-Lss))-(alphac*(x(2))+ (1-alphac)*(log(1-Lss)+arc))))^(-1/tau));
% dis = log(1-(1-phi_p)*beta*exp(-x(4)/psi));
% v_psstest = log(1/nu-1) + x_ptest +log(p_testtest ) - dis ;
% Stesttest = (Mss*(exp((log(1/nu-1) + ((1/(1-xi_p))*log(xi_p*nu*(1-1/tau)/(1-xi_p/tau)) + (1-alphap)*(ome_p_bar)+ alphap*(x(1))+(1-alphap)*log(1-Lss)) +log((w/(1-w)*(exp((alphap*(x(1)) + (1-alphap)*log(1-Lss))-(alphac*(x(2))+ (1-alphac)*(log(1-Lss)+arc))))^(-1/tau)))-log(1-(1-phi_p)*beta*exp(-x(4)/psi))))*(exp(x(4)) - (1-phi_p))))/x(5);
% % utss = x(2);
% ngss = x(3);
% evss = x(4);
% css = x(5);
% ypss = x(6);
% ycss = x(7);
% kpss =x(8);
% kcss = x(9);
% ipss =x(10);
% icss = x(11);
% alpha1 =x(12);
% alpha0 =x(13);
% mss =x(14);
% x_pss =x(15);
% qss =x(16);
% rss =x(17);
% xss =x(18);
% sss =x(19);
% v_pss =x(20);
% rexss =x(21);
% rfss=x(22);
% rcss = x(23);
% yss= x(24);
% pss= x(25);
% ptilss= x(26);


% 

