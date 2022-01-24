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
global arc alphap alphac deltak deltac mar Lss gamma xi cxi sigma sigmax sigmas rhovol ar_1_switch b_ma beta croce_switch delta eps f gam labor_switch mu Nbar phi psi rho rho_sigma stoch_vol_switch tau tca_productivity_switch v varphi vcov ORDER
global gold_switch
%% ===========================================================
% Deterministic Steady-State Values
%=============================================================

% All variables de-trended

Mss = beta*exp(-mu/psi);                        % SDF
Rss = Mss^-1;                                  
Rcss = Mss^-1; 

%Vss = (1-Mss*exp(mu))^(-1);                     % value of consumption claim
qss = 1;                                        % marginal q
Kss = ((Rss+deltak-1)/((1-1/tau)*w*alphap*(1-Lss)^(1-alphap)*exp(mu)^(1-alphap)))^(1/(alphap-1));    % capital
Kcss = ((Rcss+deltac-1)/((1-w)*alphac*exp(mu+arc)^(1-alphac)))^(1/(alphac-1));

Iss = Kss*(1-(1-deltak)/exp(mu));                    % investment
Icss = Kcss*(1-(1-deltac)/exp(mu));



Gss = 0;                             % adjustment cost function
Gprimss = 0;                                 % first derivative of the above
Yss = (Kss/exp(mu))^alphap;                                % output
Ycss = (Kcss/exp(mu))^alphac;
ytss = 1/(1-1/tau)*log(w*Yss^(1-1/tau)+(1-w)*Ycss^(1-1/tau));
ptest = w/(1-w)*(Yss/Ycss)^(-1/tau);
ptiltest = 1/(1-w)*(Ycss/exp(ytss))^(1/tau);
Css = exp(ytss)-Iss-Icss;                                  % consumption
%o = 1/(((1-alphap)*Yss/(1-Lss))*(Lss^(1/xil)/(Css)^(1/xil))+1);

Utss = ((1-beta)*Css^(1-1/psi)/(1-beta*exp(mu*(1-1/psi))))^(1/(1-1/psi));
ngss = mu;

alpha1ss = 1/((Iss/Kss*exp(mu))^(-1/xi));
alpha0ss = (Iss/Kss*exp(mu))-(alpha1ss/(1-1/xi))*(Iss/Kss*exp(mu))^(1-1/xi);

less = log(Lss);

%% The Initial Guess
X=[exp((log(Utss)+mu)*(1-gamma));
    log(Utss);
    mu;
    (log(Utss)+mu)*(1-gamma);
    log(Css);
    log(Yss);
    log(Ycss);
    log(Kss);
    log(Kcss);
    log(Iss);
    log(Icss);
    alpha1ss;
    alpha0ss;
    log(Mss);
    mu;
    ptiltest;
    log(Rss);
    0;
    mu;
    mu;
    0;
    log(Rss);
    log(Rss);
    ytss;
    ptest;
    ptiltest;
    ];
%X = [2.97860724394658e-07;1.66461815017815;0.00435847636704774;-15.0325037495964;0.588928144364739;1.13906628643651;0.790218033001734;3.80122233879997;2.63837438928406;-0.147277768182890;-1.31004599454688;0.0721197243766218;-0.0387360241426575;0.00333690818186616;0.00436098345885342;4.72159835037802;-0.00252525225191263;-0.000140929866261374;0.00435865576151377;0.00435865576151377;0.00161916436333931;-0.00333719172394268;-0.00414535496747045;1.07667641223600;3.73043283892977;4.72159639534603;];

%% The Function
[x,FVAL,S,N] = fsolve(@(x) myfun2(x, mu, rho, beta, psi, gamma, Lss, alphac, alphap, deltak, deltac, xi, tau, arc, w, Gprimss, Gss, philev),X, optimset('MaxFunEvals', 3000000,'MaxIter',100000,'Display','off'));
%EV1 ut2 ng ev c_bar c o y k i alpha1 alpha0 m cg cg_bar q r x yg ig rex rf;
EVss = x(1);
utss = x(2);
ngss = x(3);
evss = x(4);
css = x(5);
ypss = x(6);
ycss = x(7);
kpss =x(8);
kcss = x(9);
ipss =x(10);
icss = x(11);
alpha1 =x(12);
alpha0 =x(13);
mss =x(14);
cgss =x(15);
qss =x(16);
rss =x(17);
xss =x(18);
ygss =x(19);
igss =x(20);
rexss =x(21);
rfss=x(22);
rcss = x(23);
yss= x(24);
pss= x(25);
ptilss= x(26);

