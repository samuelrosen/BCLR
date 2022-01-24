global cal_no a1 alphap alphac deltak deltac w tau Np Nc gamma xi cxi sigma sigmax sigmas rhovol rhoar rhotest ar_1_switch arc beta croce_switch delta eps f gam labor_switch mu Nbar phi psi rho rho_sigma stoch_vol_switch tau tca_productivity_switch v varphi vcov con_shocka con_shockx volx ORDER
global gold_switch gov_adjustment_switch phi_growth rhoinv phi_growth_f
calibrations;
%% ===========================================================
% Preliminaries 
%=============================================================

%***USER MODIFIES THIS SECTION***

% order = 3;      %order of approximation  
%Ts = 100001;    %simulation length


% Calibrated parameters
% alphap = 0.3;    
% mu = 0.018/4;     
% gamma = 12;          
% rho=0.8^(1/4);
% rhovol = rho;
% beta = 0.982^(1/4);%0.95
% sigma = 0.036/4^0.5;
% sigmax = 0.1*sigma; %No LRR sigmax = 0;
% sigmad = 0.065/4^0.5;
% sigmas = 0.1*sigmax;
% deltak = 0.06/4;
% deltac = 0;%0.0484 %0
% philev = 2;
% xi = 1.5;%7
% cxi = 100;
% xil = 1;
% psi = 2; %0.9
% %le = log(1-0.18);
% Lss = 1-0.18;
% mar = 0.00681;%1.062 %0.0698*0.95 %0.017885
% alphac = 0.99;%0.99

%% ===========================================================
% Deterministic Steady-State Values
%=============================================================

% % All variables de-trended
% 
% Lss = 1-0.18;
% Mss = beta*exp(-mu/psi);                        % SDF
% Rss = Mss^-1;                                  
% Rcss = Mss^-1; 
% 
% %Vss = (1-Mss*exp(mu))^(-1);                     % value of consumption claim
% qss = 1;                                        % marginal qp
% Kss = ((Rss+deltak-1)/(alphap*(Np)^(1-alphap)*exp(mu)^(1-alphap)))^(1/(alphap-1));    % capital
% Kcss = (Rcss/(alphac*mar*exp(mu)^(1-alphac)))^(1/(alphac-1));
% 
% Iss = Kss*(1-(1-deltak)/exp(mu));                    % investment
% Icss = Kcss;
% 
% 
% 
% Gss = 0;                             % adjustment cost function
% Gprimss = 0;                                 % first derivative of the above
% Yss = (Kss/exp(mu))^alphap*(Np)^(1-alphap);                                % output
% Ycss = mar*(Kcss/exp(mu))^alphac;
% 
% Css = Yss+Ycss-Iss-Icss;                                  % consumption
% %o = 1/(((1-alphap)*Yss/(Np))*(Lss^(1/xil)/(Css)^(1/xil))+1);
% 
% Utss = ((1-beta)*Css^(1-1/psi)/(1-beta*exp(mu*(1-1/psi))))^(1/(1-1/psi));
% ngss = mu;
% 
% alpha1 = 1/((Iss/Kss*exp(mu))^(-1/xi));
% alpha0 = (alpha1/(1-1/xi))*(Iss/Kss*exp(mu))^(1-1/xi)-(Iss/Kss*exp(mu));
Steady_state_TSM;
if gov_adjustment_switch==0
calpha1 = 1/((exp(icss)/exp(kcss)*exp(mu)+1)^(-1/cxi));
calpha0 = (exp(icss)/exp(kcss)*exp(mu)+1)-(calpha1/(1-1/cxi))*((exp(icss)/exp(kcss)*exp(mu)+1))^(1-1/cxi);
end;
if gov_adjustment_switch==1
calpha1 = 1/((exp(icss)/exp(kcss)*exp(mu))^(-1/cxi));
calpha0 = (exp(icss)/exp(kcss)*exp(mu))-(calpha1/(1-1/cxi))*((exp(icss)/exp(kcss)*exp(mu)))^(1-1/cxi);
end;
app = 0.005;
%cal_no = 0;

%% ===========================================================
% Write Dynare++ Source File
%=============================================================

% Create file

   fid=fopen(strcat('Monopoly_Power_Approx_',num2str(cal_no),'.mod'),'w+');
    
% Variable/parameter declaration
if stoch_vol_switch==1;
fprintf(fid, 'var EV ut da argp ev ca dgdpa dgdppa dfyp dfyc dgdpp dycp ypa yca ya kpa kca ipa Ic Vexp dVexp D Tax G Gprim T Tprim Gamp Gampprim Gamc Gamcprim m mc dc qp qc p ptil r rc re x dyp dyc dyvp dip igitot exr exr_G rf vol eng Eng Engma kratio gratio wratio yratio tyg tig gammav dy pqr wagep wagec Vr EMVr qpt VexpK ikp iyp ar_inv dkp ia x_f kpkg;\n');%Vr EMVr 
fprintf(fid, 'varexo ea ex es;\n');
end;
if stoch_vol_switch==0;
fprintf(fid, 'var EV ut da argp ev ca dgdpa dgdppa dfyp dfyc dgdpp dycp ypa yca ya kpa kca ipa Ic Vexp dVexp D Tax G Gprim T Tprim Gamp Gampprim Gamc Gamcprim m mc dc qp qc p ptil r rc re x dyp dyc dyvp dip igitot exr exr_G rf eng Eng Engma kratio gratio wratio yratio tyg tig gammav dy pqr wagep wagec Vr EMVr qpt VexpK;\n');%Vr EMVr 
fprintf(fid, 'varexo ea ex;\n');
end;

fprintf(fid, '\n');
fprintf(fid, 'parameters deltac mu rho rhovol rhoar psi gamma alphap deltak xi cxi alpha1 alpha0 calpha1 calpha0 philev sigma sigmax alphac beta app tau w Np Nc arc con_shocka con_shockx phi_growth pss ptilss ypss yss ipss kpss kcss rhoinv phi_growth_f;\n');
fprintf(fid, '\n');

% Parameters
fprintf(fid, 'mu = %3.6f;\n',mu);
fprintf(fid, 'rho = %3.6f;\n',rho);
fprintf(fid, 'rhovol = %3.6f;\n',rhovol);
fprintf(fid, 'rhoar = %3.6f;\n',rhoar);
fprintf(fid, 'arc = %3.6f;\n',arc);
fprintf(fid, 'w = %3.6f;\n',w);
fprintf(fid, 'tau = %3.6f;\n',tau);
%fprintf(fid, 'beta = %3.6f;\n',beta);
fprintf(fid, 'psi = %3.6f;\n',psi);
fprintf(fid, 'gamma = %3.6f;\n',gamma);
%fprintf(fid, 'o = %3.6f;\n',o);
%fprintf(fid, 'xil = %3.6f;\n',xil);
fprintf(fid, 'alphap = %3.6f;\n',alphap);
fprintf(fid, 'deltak = %3.6f;\n',deltak);
fprintf(fid, 'xi = %3.6f;\n',xi);
fprintf(fid, 'cxi = %3.6f;\n',cxi); 
fprintf(fid, 'calpha1 = %3.6f;\n',calpha1);
fprintf(fid, 'calpha0 = %3.6f;\n',calpha0);
fprintf(fid, 'philev = %3.6f;\n',philev);
fprintf(fid, 'alpha1 = %3.6f;\n',alpha1);
fprintf(fid, 'alpha0 = %3.6f;\n',alpha0);
% fprintf(fid, 'calpha1 = %3.6f;\n',calpha1);
% fprintf(fid, 'calpha0 = %3.6f;\n',calpha0);
fprintf(fid, 'sigma = %3.6f;\n',sigma);
fprintf(fid, 'sigmax = %3.6f;\n',sigmax);
fprintf(fid, 'Np = %3.6f;\n',Np);
fprintf(fid, 'Nc = %3.6f;\n',Nc);
fprintf(fid, 'alphac = %3.6f;\n',alphac);

%fprintf(fid, 'Pi = %3.6f;\n',Pi);
fprintf(fid, 'deltac = %3.6f;\n',deltac);
fprintf(fid, 'app = %3.6f;\n',app);
%fprintf(fid, 'deltabar = %3.6f;\n',(beta+1-2/(1+exp(-1)))/(2-2/(1+exp(-1))));
% fprintf(fid, 'deltabar = %3.6f;\n',(beta^12-1/(1+app/1))/(1-1/(1+app/1)));
fprintf(fid, 'beta = %3.6f;\n',beta);
fprintf(fid, 'con_shocka = %3.6f;\n',con_shocka);
fprintf(fid, 'con_shockx = %3.6f;\n',con_shockx);
fprintf(fid, 'phi_growth = %3.6f;\n',phi_growth);
fprintf(fid, 'phi_growth_f = %3.6f;\n',phi_growth_f);

fprintf(fid, 'pss = %3.6f;\n',pss);
fprintf(fid, 'ptilss = %3.6f;\n',ptilss);
fprintf(fid, 'ypss = %3.6f;\n',ypss);
fprintf(fid, 'yss = %3.6f;\n',yss);
fprintf(fid, 'ipss = %3.6f;\n',ipss);
fprintf(fid, 'kpss = %3.6f;\n',kpss);
fprintf(fid, 'kcss = %3.6f;\n',kcss);
fprintf(fid, 'rhoinv = %3.6f;\n',rhoinv);

%fprintf(fid, 'xstar = %3.6f;\n',0);
fprintf(fid, '\n');

% Model
fprintf(fid, 'model;\n');
fprintf(fid, '//Time Varing Gamma and beta;\n');%1
fprintf(fid, 'gammav = gamma;\n');%+0.5*exp(vol)-0.5
% fprintf(fid, 'deltav = (deltabar+(1-deltabar)*(1/(1+app/exp(vol))))^(1/12);\n');%(deltabar+(1-deltabar)*(1/(1+0.1/exp(vol))))^(1/12)
fprintf(fid, '//Utility;\n');%3
fprintf(fid, 'EV = exp((ut(+1)+da(+1))*(1-gammav));\n');
fprintf(fid, 'exp(ev) = EV;\n');
fprintf(fid, 'ut = (1/(1-1/psi))*log((1-beta)*exp(ca*(1-1/psi))+beta*exp((1-1/psi)/(1-gammav)*ev));\n');
%fprintf(fid, 'c_bar = o*ca+(1-o)*(le-da);\n');
fprintf(fid, '//Output and Resources;\n');%6
fprintf(fid, 'ypa = alphap*(kpa(-1)-da)+(1-alphap)*log(Np);\n');
fprintf(fid, 'yca = alphac*(kca(-1)-da)+(1-alphac)*(log(Nc)+argp);\n');
fprintf(fid, 'ya = 1/(1-1/tau)*log(w*(exp(ypa))^(1-1/tau)+(1-w)*(exp(yca))^(1-1/tau));\n');
fprintf(fid, 'p = w/(1-w)*(exp(ypa-yca))^(-1/tau);\n');
fprintf(fid, 'ptil = 1/(1-w)*(exp(yca-ya))^(1/tau);\n');
fprintf(fid, 'exp(ya)= exp(ca)+exp(ipa)+Ic;\n');
fprintf(fid, 'dgdpa= log(exp(ya)*ptil)-log(exp(ya(-1))*ptil(-1))+da;\n');
fprintf(fid, 'dgdppa= log(exp(ypa)*p)-log(exp(ypa(-1))*p(-1))+da;\n');
fprintf(fid, 'dfyp= log(exp(ypa)*p/ptil)-log(exp(ypa(-1))*p(-1)/ptil(-1))+da;\n');
fprintf(fid, 'dfyc= log(exp(yca)/ptil)-log(exp(yca(-1))/ptil(-1))+da;\n');
fprintf(fid, 'dgdpp= log(exp(ya)*ptil/p)-log(exp(ya(-1))*ptil(-1)/p(-1))+da;\n');
fprintf(fid, 'dycp= log(exp(yca)/p)-log(exp(yca(-1))/p(-1))+da;\n');

 
%fprintf(fid, 'exp(ca)+Tax+Vexp=(Vexp+D)+wagep*Np/ptil+wagec*Nc/ptil;\n');

%fprintf(fid, 'ypa = alphap*(kpa(-1)-da)+(1-alphap)*log(1-exp(le));\n');

fprintf(fid, '//Adjustment Costs G and T;\n');%8
fprintf(fid, 'G = exp(ipa-kpa(-1)+da)-(alpha1/(1-1/xi)*(exp(ipa-kpa(-1)+da))^(1-1/xi)+alpha0);\n');
fprintf(fid, 'Gprim = 1-alpha1*exp(ipa-kpa(-1)+da)^(-1/xi);\n');
if gov_adjustment_switch==0
fprintf(fid, 'T = Ic*exp(-kca(-1)+da)+1-(calpha1/(1-1/cxi)*(Ic*exp(-kca(-1)+da)+1)^(1-1/cxi)+calpha0);\n');
fprintf(fid, 'Tprim = 1-calpha1*(Ic*exp(-kca(-1)+da)+1)^(-1/cxi);\n');
end;
if gov_adjustment_switch==1
fprintf(fid, 'T = Ic*exp(-kca(-1)+da)-(calpha1/(1-1/cxi)*(Ic*exp(-kca(-1)+da))^(1-1/cxi)+calpha0);\n');
fprintf(fid, 'Tprim = 1-calpha1*(Ic*exp(-kca(-1)+da))^(-1/cxi);\n');
end;
fprintf(fid, 'Gamp = exp(ipa+da)/exp(kpa(-1))-G;\n');
fprintf(fid, 'Gampprim = 1-Gprim;\n');
fprintf(fid, 'Gamc = Ic*exp(da)/exp(kca(-1))-T;\n');
fprintf(fid, 'Gamcprim = 1-Tprim;\n');

fprintf(fid, '//The Law of Motion of Capital;\n');%2
fprintf(fid, 'exp(kpa+da) = (1-deltak)*exp(kpa(-1))+exp(ipa+da)-G*exp(kpa(-1));\n');
fprintf(fid, 'exp(kca+da) = (1-deltac)*exp(kca(-1))+Ic*exp(da)-T*exp(kca(-1));\n');

fprintf(fid, '//SDF and Prices;\n');%5
fprintf(fid, 'm = log(beta)+(-1/psi)*dc+(1/psi-gammav)*(ut+da-(1/(1-gammav))*ev(-1));\n');
fprintf(fid, 'mc = log(exp(m)*exp(ya-yca)^(1/tau)/exp(ya(-1)-yca(-1))^(1/tau));\n');

fprintf(fid, 'qp = ptil/(Gampprim);\n');
fprintf(fid, 'qc = ptil/(Gamcprim);\n');
fprintf(fid, 'pqr = qc/qp;\n');

fprintf(fid, '//Wages in Government Good Prices;\n');%2
fprintf(fid, 'wagep = p*(1-1/tau)*(1-alphap)*exp(ypa)/Np;\n');
fprintf(fid, 'wagec = (1-alphac)*exp(yca)/Nc;\n');

fprintf(fid, '//Returns;\n');%7
fprintf(fid, 'exp(r) = ((1-1/tau)*p*alphap*exp(ypa-kpa(-1)+da)+(-(1-alphap)*(1/tau)*p*(1-rhoar)*phi_growth*exp(ypa-kpa(-1)+da))+(p*(1-alphap)*exp(ypa)*phi_growth*exp(-kpa(-1)+da))+qp*(1-deltak)+qp*(-Gampprim*exp(ipa-kpa(-1)+da)+Gamp))/(qp(-1));\n');
fprintf(fid, 'exp(rc) = (alphac*exp(yca-kca(-1)+da)+(-(1-alphac)*exp(yca)*rhoar*phi_growth*exp(-kca(-1)+da))+qc*(1-deltac)+qc*(-Gamcprim*Ic*exp(-kca(-1)+da)+Gamc))/(qc(-1));\n');
fprintf(fid, '1 = exp(mc(+1) + r(+1));\n');
fprintf(fid, '1 = exp(mc(+1) + rc(+1));\n');

% fprintf(fid, 'qpt = qp+EMVr;\n');
% fprintf(fid, 'EMVr = exp(mc(+1))*Vr(+1);\n');
% fprintf(fid, 'Vr = 1/tau*p*exp(ypa-kpa(-1)+da)+EMVr;\n');
fprintf(fid, 'EMVr = exp(mc(+1))*Vr(+1)*exp(da(+1));\n');
fprintf(fid, 'Vr = 1/tau*p*exp(ypa)+EMVr;\n');
fprintf(fid, 'qpt = qp+EMVr/exp(kpa);\n');


fprintf(fid, 'ptil*D = p*exp(ypa)-wagep*Np-ptil*exp(ipa);\n');
fprintf(fid, 'Vexp = exp(m(+1))*(Vexp(+1)+D(+1))*exp(da(+1));\n');
fprintf(fid, 'VexpK =Vexp/exp(kpa) ;\n');

fprintf(fid, '-ptil*Tax = exp(yca)-wagec*Nc-ptil*Ic;\n');



fprintf(fid, '//Productivity;\n');%4
fprintf(fid, 'ar_inv = (1-rhoinv)*ar_inv(-1)+(1-rhoinv)*(dip-mu);\n');
if stoch_vol_switch==1;
fprintf(fid, 'da = mu + x(-1) + exp(vol(-1))*ea+ phi_growth*((kpa(-1)-kca(-1))-(kpss-kcss)) ;\n');
if volx ==1;
fprintf(fid, 'x = rho*x(-1) + exp(vol(-1))*ex;\n');
% fprintf(fid, 'x_f = rho*x_f(-1)+log(phi_growth_f*(dip-mu)+1)+ exp(vol(-1))*ex;\n');
% fprintf(fid, 'x_f = rho*x_f(-1)+(-exp(-phi_growth_f*(dip-mu))+1)+ exp(vol(-1))*ex;\n');
fprintf(fid, 'x_f = rho*x_f(-1)+(1/phi_growth_f)*(-exp(-phi_growth_f*(dip-mu))+1)+ exp(vol(-1))*ex;\n');
% fprintf(fid, 'x_f = rho*x_f(-1)+(dip-mu+1)^(1/phi_growth_f)+ exp(vol(-1))*ex;\n');
% fprintf(fid, 'x_f = x+phi_growth_f*log(dip-mu+1);\n');
end;
if volx ==0;
fprintf(fid, 'x = rho*x(-1) + ex;\n');
end;
fprintf(fid, 'vol = rhovol*vol(-1)+ con_shocka*ea+con_shockx*ex+es;\n');
end
if stoch_vol_switch==0;
    fprintf(fid, 'da = mu + x(-1) + ea ;\n');
    fprintf(fid, 'x = rho*x(-1) + ex;\n');
end
% if rhotest == 0;
% fprintf(fid, 'argp = rhoar*argp(-1)+(rhoar-1)*(da-mu);\n');
% end;
% if rhotest == 1;
fprintf(fid, 'argp = (1-rhoar)*argp(-1)+(1-rhoar)*(mu-da)+rhoar*arc;\n');  
% end
fprintf(fid, '//Growth;\n');%11
fprintf(fid, 'dc = ca - ca(-1) + da;\n');
fprintf(fid, 'kratio = exp(kca)/(exp(kca)+exp(kpa)) ;\n');
fprintf(fid, 'gratio = exp(kca)*qc/(exp(ypa)*p+exp(yca)) ;\n');
fprintf(fid, 'wratio = exp(kca)*qc/(exp(kca)*qc+exp(kpa)*qpt) ;\n');
%fprintf(fid, 'wratio = exp(kca)*qc/(exp(kca)*qc+Vexp*ptil) ;\n');
fprintf(fid, 'yratio = exp(yca)/(exp(ypa)*p+exp(yca)) ;\n');
fprintf(fid, 'dyp = ypa - ypa(-1) + da;\n');
fprintf(fid, 'dip = ipa - ipa(-1) + da;\n');
fprintf(fid, 'dkp = kpa - kpa(-1) + da;\n');


fprintf(fid, 'dyc = yca - yca(-1) + da;\n');
fprintf(fid, 'dVexp = Vexp/Vexp(-1)*exp(da);\n');
fprintf(fid, 'igitot = Ic/(exp(ipa)+Ic);\n');
fprintf(fid, 'dy = ya-ya(-1)+da;\n');

fprintf(fid, 'tyg = (ypa+yca) - (ypa(-1)+yca(-1)) + da;\n');
fprintf(fid, 'tig = log((exp(ipa)+Ic)/(exp(ipa(-1))+Ic(-1))*exp(da));\n');
fprintf(fid, 'dyvp = log(exp(ypa)*p/(ypa(-1)*p(-1))) + da;\n');
fprintf(fid, 'ikp =  ipa-kpa(-1)+da ;\n');
fprintf(fid, 'iyp =  ipa-ya;\n');
fprintf(fid, 'ia =  log((exp(ipa)+Ic));\n');
fprintf(fid, 'kpkg =  exp(kpa)/exp(kca);\n');


fprintf(fid, '//Excess Rate of Returns;\n');%7
fprintf(fid, '1/exp(rf) = exp(m(+1));\n');
fprintf(fid, 'exp(re) = (1-kratio)*exp(r)+kratio*exp(rc);\n');
fprintf(fid, 'exr = log(exp(r)*exp(ya-yca)^(1/tau)/exp(ya(-1)-yca(-1))^(1/tau))-rf(-1);\n');
fprintf(fid, 'exr_G = log(exp(rc)*exp(ya-yca)^(1/tau)/exp(ya(-1)-yca(-1))^(1/tau))-rf(-1);\n');
if stoch_vol_switch==1;
fprintf(fid, 'Engma = exp(mu+x+0.5*exp(2*vol)*sigma^2);\n');
end;
if stoch_vol_switch==0;
fprintf(fid, 'Engma = exp(mu+x+0.5*exp(2*0)*sigma^2);\n');
end;
fprintf(fid, 'eng = exp(da);\n');
fprintf(fid, 'Eng = eng(+1);\n');
fprintf(fid, 'end;\n');
fprintf(fid, '\n');

% Initial values
%fprintf(fid, 'var EV ut da argp ev ca ypa yca ya kpa kca ipa Ic Vexp D Tax G Gprim T Tprim Gamp Gampprim Gamc Gamcprim m mc 
%dc qp qc p ptil r rc re x dyp dyc dip dic exr exr_G rf vol eng Eng Engma kratio wratio yratio tyg tig gammav dy pqr wagep wagec;\n');%Vr EMVr 
fprintf(fid, 'initval;\n');
fprintf(fid, 'gammav=%3.6f;\n',gamma);
fprintf(fid, 'ca=%3.6f;\n',css);
fprintf(fid, 'm=%3.6f;\n',mss);
fprintf(fid, 'mc=%3.6f;\n',mss);
fprintf(fid, 'da=%3.6f;\n', ngss);
fprintf(fid, 'argp=%3.6f;\n', arc);
fprintf(fid, 'ar_inv=%3.6f;\n', 0);
fprintf(fid, 'ut=%3.6f;\n', utss);
fprintf(fid, 'ya=%3.6f;\n', yss);
fprintf(fid, 'dgdpa=%3.6f;\n', mu);
fprintf(fid, 'dgdppa=%3.6f;\n', mu);
fprintf(fid, 'dfyp=%3.6f;\n', mu);
fprintf(fid, 'dfyc=%3.6f;\n', mu);
fprintf(fid, 'dgdpp=%3.6f;\n', mu);
fprintf(fid, 'dycp=%3.6f;\n', mu);
fprintf(fid, 'ypa=%3.6f;\n', ypss);
fprintf(fid, 'yca=%3.6f;\n', ycss);
fprintf(fid, 'kpa=%3.6f;\n', kpss);
fprintf(fid, 'kca=%3.6f;\n', kcss);
fprintf(fid, 'kratio=%3.6f;\n', exp(kcss)/(exp(kcss)+exp(kpss)));
Vrss = 1/tau*pss*exp(ypss)/(1-exp(mss));
Dss = (pss*exp(ypss)-(pss*(1-1/tau)*(1-alphap)*exp(ypss)/Np)*Np-ptilss*exp(ipss))/ptilss;
fprintf(fid, 'wratio=%3.6f;\n', exp(kcss)*ptilss/(exp(kcss)*ptilss+exp(kpss)*(ptilss+exp(mss)*Vrss)));
fprintf(fid, 'gratio=%3.6f;\n', exp(kcss)*ptilss/(exp(ycss)*ptilss+exp(yss)));
%fprintf(fid, 'wratio=%3.6f;\n', exp(kcss)*ptilss/(exp(kcss)*ptilss+exp(mss)*Dss/(1-exp(mss))*ptilss));
fprintf(fid, 'yratio=%3.6f;\n', exp(ycss)/(exp(ycss)*ptilss+exp(yss)));
fprintf(fid, 'ipa=%3.6f;\n', ipss);
fprintf(fid, 'Ic=%3.6f;\n', exp(icss));
fprintf(fid, 'wagep=%3.6f;\n', pss*(1-1/tau)*(1-alphap)*exp(ypss)/Np);
fprintf(fid, 'wagec=%3.6f;\n', (1-alphac)*exp(ycss)/Nc);
fprintf(fid, 'D=%3.6f;\n', (pss*exp(ypss)-(pss*(1-1/tau)*(1-alphap)*exp(ypss)/Np)*Np-ptilss*exp(ipss))/ptilss);
fprintf(fid, 'Tax=%3.6f;\n', -(exp(ycss)-((1-alphac)*exp(ycss)/Nc)*Nc-ptilss*exp(icss))/ptilss);
fprintf(fid, 'Vexp=%3.6f;\n',exp(mss)*exp(mu)*Dss/(1-exp(mss)*exp(mu)));
fprintf(fid, 'VexpK=%3.6f;\n',(exp(mss)*exp(mu)*Dss/(1-exp(mss)*exp(mu)))/exp(kpss));
fprintf(fid, 'Vr=%3.6f;\n',Vrss);
fprintf(fid, 'EMVr=%3.6f;\n',exp(mss)*Vrss);
fprintf(fid, 'qpt=%3.6f;\n', ptilss+exp(mss)*Vrss/exp(kpss));
fprintf(fid, 'G=%3.6f;\n', 0);
fprintf(fid, 'Gprim = %3.6f;\n', 0);
fprintf(fid, 'Gamp=%3.6f;\n', exp(ipss+ngss)/exp(kpss));
fprintf(fid, 'Gampprim = %3.6f;\n', 1);
fprintf(fid, 'T=%3.6f;\n', 0);
fprintf(fid, 'Tprim = %3.6f;\n', 0);
fprintf(fid, 'Gamc=%3.6f;\n', exp(icss+ngss)/exp(kcss));
fprintf(fid, 'Gamcprim = %3.6f;\n', 1);
fprintf(fid, 'dc=%3.6f;\n', cgss);
fprintf(fid, 'dyp=%3.6f;\n', ygss);
fprintf(fid, 'dyvp=%3.6f;\n', ygss);
fprintf(fid, 'dyc=%3.6f;\n', mu);
fprintf(fid, 'dy=%3.6f;\n', mu);
fprintf(fid, 'tyg=%3.6f;\n', mu);
fprintf(fid, 'dVexp=%3.6f;\n', exp(mu));
fprintf(fid, 'dip=%3.6f;\n', igss);
fprintf(fid, 'dkp=%3.6f;\n', igss);
fprintf(fid, 'igitot=%3.6f;\n', exp(icss)/(exp(ipss)+exp(icss)));
fprintf(fid, 'tig=%3.6f;\n', mu);
fprintf(fid, 'ikp=%3.6f;\n', ipss-kpss+mu);
fprintf(fid, 'iyp=%3.6f;\n', ipss-yss);
fprintf(fid, 'ia=%3.6f;\n', log(exp(ipss)+exp(icss)));
fprintf(fid, 'kpkg=%3.6f;\n', exp(kpss)/exp(kcss));


fprintf(fid, 'p=%3.6f;\n', pss);
fprintf(fid, 'ptil=%3.6f;\n', ptilss);
fprintf(fid, 'qp=%3.6f;\n', ptilss);
fprintf(fid, 'qc=%3.6f;\n', ptilss);
fprintf(fid, 'r=%3.6f;\n', rss);
fprintf(fid, 'rc=%3.6f;\n', rcss);
fprintf(fid, 'rf=%3.6f;\n', rfss);
fprintf(fid, 're=%3.6f;\n', rfss);
fprintf(fid, 'exr=%3.6f;\n', 0);
fprintf(fid, 'exr_G=%3.6f;\n', 0);
fprintf(fid, 'x = %3.6f;\n', 0);
fprintf(fid, 'x_f = %3.6f;\n', 0);
if stoch_vol_switch==1;
fprintf(fid, 'vol = %3.6f;\n', 0);
fprintf(fid, 'EV = %3.6f;\n', EVss);
end;
if stoch_vol_switch==0;
fprintf(fid, 'EV = %3.6f;\n', EVss);
end;
fprintf(fid, 'EV = %3.6f;\n', EVss);
fprintf(fid, 'ev = %3.6f;\n', evss);
fprintf(fid, 'eng = %3.6f;\n', exp(ngss));
fprintf(fid, 'Eng = %3.6f;\n', exp(ngss+0.5*sigma^2));
fprintf(fid, 'Engma = %3.6f;\n', exp(ngss+0.5*sigma^2));
fprintf(fid, 'pqr=%3.6f;\n', 1);
fprintf(fid, 'end;\n');
fprintf(fid, '\n');

%%dynare
% 
% fprintf(fid, 'steady;\n');
% fprintf(fid, 'check;\n');
% fprintf(fid, 'shocks;\n');
% fprintf(fid, 'var ea; stderr %3.9f;\n', sigma);
% fprintf(fid, 'var ex; stderr  %3.9f;\n', sigmax);
% %fprintf(fid, 'var ed; stderr  %3.9f;\n', sigmad);
% fprintf(fid, 'var es; stderr  %3.9f;\n', sigmas);
% fprintf(fid, 'end;\n');
if stoch_vol_switch==1;
fprintf(fid, 'vcov = [%3.12f 0      0;\n',sigma^2);
fprintf(fid, '        0      %3.12f 0;\n',sigmax^2);
% fprintf(fid, '        0      0      %3.12f 0 ;\n',sigmad^2);
fprintf(fid, '        0      0        %3.12f] ;\n',sigmas^2);
fprintf(fid, '\n');
fprintf(fid, 'order = %i;\n',ORDER);
end;

if stoch_vol_switch==0;
    fprintf(fid, 'vcov = [%3.12f 0     ;\n',sigma^2);
fprintf(fid, '        0      %3.12f];\n',sigmax^2);
% % fprintf(fid, '        0      0      %3.12f 0 ;\n',sigmad^2);
% fprintf(fid, '        0      0        %3.12f] ;\n',sigmas^2);
fprintf(fid, '\n');
fprintf(fid, 'order = %i;\n',ORDER);
end;

% fprintf(fid, 'options_.pruning=1;\n');
% fprintf(fid, 'stoch_simul(periods= %i, order = 3);\n',Ts);
% % , hp_filter = 128000

fclose(fid);

%% ===========================================================
% Solve Model using Dynare++
%=============================================================


%% Call executable
% disp('Running...')
% 
% !dynare++ --order 3 --sim 3 --per 10 --no-irfs --ss-tol 1e-10 TSM_Consumption_Ratio.mod
% 
% disp('Done!')

%% Call dynare
%dynare SafeCapital_Model_3_Approx_0.mod;
% %save LRP2_vol_of_vol.mat;
% save TSM_vol_of_vol7.mat;
% save Newtest.mat;