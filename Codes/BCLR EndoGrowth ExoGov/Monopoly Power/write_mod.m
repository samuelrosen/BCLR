global cal_no a1 alphap alphac deltak deltac w tau Np Nc gamma xi cxi sigma sigmax sigmas rhovol rhoar rhotest ar_1_switch arc beta croce_switch delta eps f gam labor_switch Nbar phi psi rho rho_sigma stoch_vol_switch gcctrl tca_productivity_switch v varphi vcov con_shocka con_shockx volx ORDER
global gold_switch gov_adjustment_switch phi_growth rhoinv phi_growth_f Np_ss Nc_ss theta_sla omega theta_P theta_G phi_o_s Abar xi_p nu eta chi ome_p_bar phi_p
global biga bigv bnca bncv rho_ig rho_nc rho_ivol rho_ia rho_nvol rho_na exo_gov_switch exo_gov_labor_lag bundle_labor
% cal_no=102;
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
% alpha0 = (alpha1/(1-1/xi))*(Iss/Kss*exp(mu))^(1-1/xi)-(Iss/Kss*exp(mu));
Steady_state_TSM;
% if gov_adjustment_switch==0
% calpha1 = 1/((exp(icss)/exp(kcss)*exp(mu)+1)^(-1/cxi));
% calpha0 = (exp(icss)/exp(kcss)*exp(mu)+1)-(calpha1/(1-1/cxi))*((exp(icss)/exp(kcss)*exp(mu)+1))^(1-1/cxi);
% end;
% if gov_adjustment_switch==1
% calpha1 = 1/((exp(icss)/exp(kcss)*exp(mu))^(-1/cxi));
% calpha0 = (exp(icss)/exp(kcss)*exp(mu))-(calpha1/(1-1/cxi))*((exp(icss)/exp(kcss)*exp(mu)))^(1-1/cxi);
% end;
app = 0.005;
%cal_no = 0;

%% ===========================================================
% Write Dynare++ Source File
%=============================================================

% Create file

   fid=fopen(strcat('Monopoly_Power_Approx_',num2str(cal_no),'.mod'),'w+');
    
% Variable/parameter declaration
if stoch_vol_switch==1;
% fprintf(fid, 'var EV ut da argp ev ca Np Nc dgdpa dgdppa dfyp dfyc dgdpp dycp ypa yca ya kpa kca ipa Ic Vexp dVexp D Tax G Gprim T Tprim Gamp Gampprim Gamc Gamcprim m mc dc qp qc p ptil r rc re x dyp dyc dyvp dip igitot exr exr_G rf vol eng Eng Engma kratio gratio wratio yratio tyg tig gammav dy pqr wagep wagec Vr EMVr qpt VexpK ikp iyp ar_inv dkp ia x_f kpkg;\n');%Vr EMVr 
fprintf(fid, 'var EV ut da argp ev ca ypa yca ya kpa kca ipa Ic G Gprim T Tprim Gamp Gampprim Gamc Gamcprim m mc dc qp qc p ptil r rc dyp dyc dyvp dip igitot exr exr_G rf vol tyg titot gammav dy pqr wagep wagec iyp ia tca dtc np nc ntotal npnt ncnt sla LC dLCdHP dLCdHG wagepc w_var ome_p x_p pi_p v_p vtheta s kratio ds x dtfp gdp dgdp rpatent exrpatent D Vexp VexpK rrnd exrrnd Iyg Tax Vexpg VexpKg dpgdp pgdp dypa dya r_H exrr_H r_H_patent exrr_H_patent coeff1 coeff2 Er Errnd Erc Er_H_patent;\n');%Vr EMVr   Tax Vexpg VexpKg  Er Errnd Erc Er_H_patent
fprintf(fid, 'varexo ea es;\n');
end;
if stoch_vol_switch==0;
fprintf(fid, 'var EV ut da argp ev ca ypa yca ya kpa kca ipa Ic G Gprim T Tprim Gamp Gampprim Gamc Gamcprim m mc dc qp qc p ptil r rc dyp dyc dyvp dip igitot exr exr_G rf tyg titot gammav dy pqr wagep wagec iyp ia tca dtc np nc ntotal npnt ncnt sla LC dLCdHP dLCdHG wagepc w_var ome_p x_p pi_p v_p vtheta s kratio ds x dtfp gdp dgdp;\n');%Vr EMVr 
fprintf(fid, 'varexo ea;\n');
end;

fprintf(fid, '\n');
fprintf(fid, 'parameters theta deltac mu rho rhovol rhoar psi gamma alphap deltak xi cxi alpha1 alpha0 calpha1 calpha0 philev sigma sigmax alphac beta app tau w arc con_shocka con_shockx phi_growth pss ptilss ypss yss ipss kpss kcss rhoinv phi_growth_f theta_sla omega_barp omega_barc omega Np_ss Nc_ss theta_P theta_G phi_o_s Abar xi_p nu eta chi ome_p_bar phi_p gcctrl biga bigv bnca bncv rho_ig rho_nc Iygbar ncntbar rho_ivol rho_ia rho_nvol rho_na;\n');
fprintf(fid, '\n');

% Parameters
fprintf(fid, 'mu = %3.6f;\n',mu); 
fprintf(fid, 'rho = %3.6f;\n',rho);
fprintf(fid, 'rhovol = %3.6f;\n',rhovol);
fprintf(fid, 'rhoar = %3.6f;\n',rhoar);
fprintf(fid, 'arc = %3.6f;\n',arc);
fprintf(fid, 'w = %3.6f;\n',w);
fprintf(fid, 'phi_o_s = %3.6f;\n',phi_o_s);
fprintf(fid, 'tau = %3.6f;\n',tau);
%fprintf(fid, 'beta = %3.6f;\n',beta);
fprintf(fid, 'psi = %3.6f;\n',psi);
fprintf(fid, 'gamma = %3.6f;\n',gamma);
fprintf(fid, 'theta = %3.6f;\n',(1-1/psi)/(1-gamma));
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

fprintf(fid, 'theta_sla = %3.6f;\n',theta_sla);
fprintf(fid, 'omega_barp = %3.6f;\n',omega_barp);
fprintf(fid, 'omega_barc = %3.6f;\n',omega_barc);
fprintf(fid, 'omega = %3.6f;\n',omega);
fprintf(fid, 'theta_P = %3.6f;\n',theta_P);
fprintf(fid, 'theta_G = %3.6f;\n',theta_G);
fprintf(fid, 'Np_ss = %3.6f;\n',Np_ss);
fprintf(fid, 'Nc_ss = %3.6f;\n',Nc_ss);

fprintf(fid, 'Abar = %3.6f;\n',Abar);
fprintf(fid, 'xi_p = %3.6f;\n',xi_p);
fprintf(fid, 'nu = %3.6f;\n',nu);
fprintf(fid, 'eta = %3.6f;\n',eta);
fprintf(fid, 'chi = %3.6f;\n',chi);
fprintf(fid, 'ome_p_bar = %3.6f;\n',ome_p_bar);
fprintf(fid, 'phi_p = %3.6f;\n',phi_p);
fprintf(fid, 'gcctrl = %3.6f;\n',gcctrl);

% biga bigv bnca bncv rho_ig rho_nc Iygbar ncntbar
fprintf(fid, 'biga = %3.6f;\n',biga);
fprintf(fid, 'bigv = %3.6f;\n',bigv);
fprintf(fid, 'bnca = %3.6f;\n',bnca);
fprintf(fid, 'bncv = %3.6f;\n',bncv);
fprintf(fid, 'rho_ig = %3.6f;\n',rho_ig);
fprintf(fid, 'rho_nc = %3.6f;\n',rho_nc);
fprintf(fid, 'Iygbar = %3.6f;\n',Icss/exp(yss));
fprintf(fid, 'ncntbar = %3.6f;\n',Nc_ss/(Np_ss+Nc_ss));
fprintf(fid, 'rho_ivol = %3.6f;\n',rho_ivol);
fprintf(fid, 'rho_ia = %3.6f;\n',rho_ia);
fprintf(fid, 'rho_nvol = %3.6f;\n',rho_nvol);
fprintf(fid, 'rho_na = %3.6f;\n',rho_na);
%Abar xi_p nu eta chi

%fprintf(fid, 'xstar = %3.6f;\n',0);
fprintf(fid, '\n');

% Model
fprintf(fid, 'model;\n');
fprintf(fid, '//Time Varing Gamma and beta;\n');%1
fprintf(fid, 'gammav = gamma;\n');%+0.5*exp(vol)-0.5
% fprintf(fid, 'deltav = (deltabar+(1-deltabar)*(1/(1+app/exp(vol))))^(1/12);\n');%(deltabar+(1-deltabar)*(1/(1+0.1/exp(vol))))^(1/12)
fprintf(fid, '//Utility;\n');%12
fprintf(fid, 'EV = exp((ut(+1)+da)*(1-gammav));\n');
fprintf(fid, 'exp(ev) = EV;\n');
fprintf(fid, 'ut = (1/(1-1/psi))*log((1-beta)*exp(tca*(1-1/psi))+beta*exp((1-1/psi)/(1-gammav)*ev));\n');

if bundle_labor == 1
fprintf(fid, 'exp(tca) = exp(ca) - omega_barp*exp(sla)*(exp(np)+omega_barc*exp(nc))^omega/omega;\n');
else
fprintf(fid, 'exp(tca) = exp(ca) - omega_barp*exp(sla)*(exp(np))^omega/omega-omega_barc*exp(sla)*(exp(nc))^omega/omega;\n');
end
% fprintf(fid, 'Q    = exp((uc(+1)+dtc(+1))*(1-gamma));\n');
% fprintf(fid, 'logQ = log(Q);\n');
% fprintf(fid, 'exp((1-1/psi)*uc) = (1-beta)+beta*(Q^theta);\n');
% fprintf(fid, 'exp(m) = beta*exp(dtc*(-1/psi))*exp((uc+dtc)*(1/psi-gamma)/exp(logQ(-1)*(1-theta));\n');
fprintf(fid, 'dtc = tca - tca(-1) + da(-1);\n');
fprintf(fid, 'sla = (1-theta_sla)*(mu+sla(-1)-da(-1));\n');
fprintf(fid, 'LC       = exp(sla)*(theta_P*( (exp(np)) - Np_ss )^2 + theta_G*( (exp(nc)) - Nc_ss )^2);\n');
fprintf(fid, 'dLCdHP   = exp(sla)*2*theta_P*( (exp(np)) - Np_ss  );\n');
fprintf(fid, 'dLCdHG   = exp(sla)*2*theta_G*(  (exp(nc)) - Nc_ss );\n');
fprintf(fid, 'ntotal   = log(exp(np)+exp(nc));\n');
fprintf(fid, 'npnt   = exp(np)/exp(ntotal);\n');
fprintf(fid, 'ncnt   = exp(nc)/exp(ntotal);\n');



fprintf(fid, '//SDF and Prices;\n');%2
fprintf(fid, 'm = log(beta)+(-1/psi)*dtc+(1/psi-gammav)*(ut+da(-1)-(1/(1-gammav))*ev(-1));\n');
fprintf(fid, 'mc = log(exp(m)*exp(ya-yca)^(1/tau)/exp(ya(-1)-yca(-1))^(1/tau));\n');

%fprintf(fid, 'c_bar = o*ca+(1-o)*(le-da);\n');
fprintf(fid, '//Output and Resources;\n');%2
fprintf(fid, 'ypa = log(Abar)+(1-alphap)*(ome_p)+ alphap*(kpa(-1))+(1-alphap)*log((exp(np)));\n');
fprintf(fid, 'yca =log(Abar)+(1-alphac)*(ome_p)+ alphac*(kca(-1))+(1-alphac)*(log((exp(nc)))+argp);\n');
% fprintf(fid, 'dtfp = (1-alphap)*(ome_p-ome_p(-1)+da(-1));\n');

fprintf(fid, '//relative prices;\n');%5
fprintf(fid, 'w_var = w*exp(phi_o_s*(vol(-1)-0));\n');
fprintf(fid, 'ya = 1/(1-1/tau)*log(w_var*(exp(ypa))^(1-1/tau)+(1-w_var)*(exp(yca))^(1-1/tau));\n');
fprintf(fid, 'p = w_var/(1-w_var)*(exp(ypa-yca))^(-1/tau);\n');
fprintf(fid, 'ptil = 1/(1-w_var)*(exp(yca-ya))^(1/tau);\n');


fprintf(fid, 'exp(ya)= exp(ca)+exp(ipa)+Ic+LC+(p/ptil)*exp(x_p)+exp(s);\n');
fprintf(fid, 'exp(gdp) = exp(ya) - (p/ptil)*exp(x_p);\n');
% fprintf(fid, 'exp(gdp) = (ptil*exp(ya) - p*exp(x_p))/p;\n');

% total gdp in numeraire
fprintf(fid, 'dgdp = gdp-gdp(-1)+da(-1);\n');
% total output in numeraire
% fprintf(fid, 'dya= log(exp(ya)*ptil)-log(exp(ya(-1))*ptil(-1))+da;\n');
fprintf(fid, 'dya= log(exp(ya)*(ptil/p))-log(exp(ya(-1))*(ptil(-1)/p(-1)))+da;\n');
% private output in numeraire
fprintf(fid, 'dypa= log(exp(ypa)*p)-log(exp(ypa(-1))*p(-1))+da;\n');

% fprintf(fid, 'exp(pgdp) = p*exp(ypa) - p*exp(x_p);\n');
fprintf(fid, 'exp(pgdp) = exp(ypa) - exp(x_p);\n');

% private gdp in numeraire
fprintf(fid, 'dpgdp = pgdp-pgdp(-1)+da(-1);\n');
% pgdp dypa dya dpgdp

% fprintf(fid, 'dgdpa= log(exp(ya)*ptil)-log(exp(ya(-1))*ptil(-1))+da;\n');
% fprintf(fid, 'dfyp= log(exp(ypa)*p/ptil)-log(exp(ypa(-1))*p(-1)/ptil(-1))+da;\n');
% fprintf(fid, 'dfyc= log(exp(yca)/ptil)-log(exp(yca(-1))/ptil(-1))+da;\n');
% fprintf(fid, 'dycp= log(exp(yca)/p)-log(exp(yca(-1))/p(-1))+da;\n');

 
%fprintf(fid, 'exp(ca)+Tax+Vexp=(Vexp+D)+wagep*(exp(np))/ptil+wagec*(exp(nc))/ptil;\n');

%fprintf(fid, 'ypa = alphap*(kpa(-1)-da)+(1-alphap)*log(1-exp(le));\n');

fprintf(fid, '//Adjustment Costs G and T;\n');%8
fprintf(fid, 'G = exp(ipa-kpa(-1))-(alpha1/(1-1/xi)*(exp(ipa-kpa(-1)))^(1-1/xi)+alpha0);\n');
fprintf(fid, 'Gprim = 1-alpha1*exp(ipa-kpa(-1))^(-1/xi);\n');
if gov_adjustment_switch==0
fprintf(fid, 'T = Ic*exp(-kca(-1))+gcctrl-(calpha1/(1-1/cxi)*(Ic*exp(-kca(-1))+gcctrl)^(1-1/cxi)+calpha0);\n');
fprintf(fid, 'Tprim = 1-calpha1*(Ic*exp(-kca(-1))+gcctrl)^(-1/cxi);\n');
end;
if gov_adjustment_switch==1
fprintf(fid, 'T = Ic*exp(-kca(-1))-(calpha1/(1-1/cxi)*(Ic*exp(-kca(-1)))^(1-1/cxi)+calpha0);\n');
fprintf(fid, 'Tprim = 1-calpha1*(Ic*exp(-kca(-1)))^(-1/cxi);\n');
end;
fprintf(fid, 'Gamp = exp(ipa)/exp(kpa(-1))-G;\n');
fprintf(fid, 'Gampprim = 1-Gprim;\n');
fprintf(fid, 'Gamc = Ic/exp(kca(-1))-T;\n');
fprintf(fid, 'Gamcprim = 1-Tprim;\n');

fprintf(fid, '//The Law of Motion of Capital;\n');%5
fprintf(fid, 'exp(kpa+da) = (1-deltak)*exp(kpa(-1))+exp(ipa)-G*exp(kpa(-1));\n');
fprintf(fid, 'exp(kca+da) = (1-deltac)*exp(kca(-1))+Ic-T*exp(kca(-1));\n');

fprintf(fid, 'qp = ptil/(Gampprim);\n');
fprintf(fid, 'qc = ptil/(Gamcprim);\n');
fprintf(fid, 'pqr = qc/qp;\n');

fprintf(fid, '//Wages in Government Good Prices;\n');%5
fprintf(fid, 'wagep = p*(1-1/tau)*(1-alphap)*(1-xi_p)*exp(ypa)/(exp(np));\n');
fprintf(fid, 'wagepc = wagep/wagec;\n');

if bundle_labor == 1
fprintf(fid, 'wagep/ptil = omega_barp*exp(sla)*(exp(np)+omega_barc*exp(nc))^(omega-1)+dLCdHP;\n');
fprintf(fid, 'wagec/ptil = omega_barp*omega_barc*exp(sla)*(exp(np)+omega_barc*exp(nc))^(omega-1)+dLCdHG;\n');    
else
fprintf(fid, 'wagep/ptil = omega_barp*exp(sla)*(exp(np))^(omega-1)+dLCdHP;\n');
fprintf(fid, 'wagec/ptil = omega_barc*exp(sla)*(exp(nc))^(omega-1)+dLCdHG;\n');
end

fprintf(fid, '//Returns;\n');%4
fprintf(fid, 'exp(r) = ((1-1/tau)*p*alphap*(1-xi_p)*exp(ypa-kpa(-1))+(qp*(1-deltak)+qp*(-Gampprim*exp(ipa-kpa(-1))+Gamp)))/(qp(-1));\n');
fprintf(fid, 'exp(rc) = (alphac*exp(yca-kca(-1))+(qc*(1-deltac)+qc*(-Gamcprim*Ic*exp(-kca(-1))+Gamc)))/(qc(-1));\n');
fprintf(fid, '1 = exp(mc(+1) + r(+1));\n');

%%exogenous policy rule
if exo_gov_switch == 0
fprintf(fid, '1 = exp(mc(+1) + rc(+1));\n');
fprintf(fid, 'wagec = (1-alphac)*exp(yca)/(exp(nc));\n');
end
if exo_gov_switch == 1
fprintf(fid, 'Iyg =  (1-rho_ig)*Iygbar+rho_ig*Iyg(-1)+biga*ea+bigv*es+ rho_ivol*vol(-1)+rho_ia*(ome_p(-1)-ome_p_bar);\n'); 
if exo_gov_labor_lag == 1
fprintf(fid, 'ncnt   = (1-rho_nc)*ncntbar+rho_nc*ncnt(-1)+bnca*ea+bncv*es(-1) + rho_nvol*vol(-1)+rho_na*(ome_p(-1)-ome_p_bar);\n');
else
fprintf(fid, 'ncnt   = (1-rho_nc)*ncntbar+rho_nc*ncnt(-1)+bnca*ea+bncv*es+ rho_nvol*vol(-1)+rho_na*(ome_p(-1)-ome_p_bar);\n');
end
% fprintf(fid, 'ncnt   = (1-rho_nc)*ncntbar+rho_nc*ncnt(-1)+bnca*ea(-1)+bncv*es(-1);\n');
end

% fprintf(fid, 'EMVr = exp(mc(+1))*Vr(+1)*exp(da(+1));\n');
% fprintf(fid, 'Vr = 1/tau*p*exp(ypa)+EMVr;\n');
% fprintf(fid, 'qpt = qp+EMVr/exp(kpa);\n');


fprintf(fid, 'ptil*D = p*exp(ypa)-wagep*(exp(np))-ptil*exp(ipa)-p*(1/nu)*exp(x_p);\n');
fprintf(fid, 'Vexp = exp(m(+1))*(Vexp(+1)+D(+1))*exp(da(+1));\n');
fprintf(fid, 'VexpK =Vexp/exp(kpa) ;\n');
% 
fprintf(fid, 'ptil*Tax = exp(yca)-wagec*(exp(nc))-ptil*Ic;\n'); %Tax Vexpg VexpKg
if deltac == 1
fprintf(fid, 'Vexpg = exp(m(+1))*(Tax(+1))*exp(da(+1));\n');
% fprintf(fid, 'ncnt   = (1-rho_nc)*ncntbar+rho_nc*ncnt(-1)+bnca*ea(-1)+bncv*es(-1);\n');
else
fprintf(fid, 'Vexpg = exp(m(+1))*(Vexpg(+1)+Tax(+1))*exp(da(+1));\n');
end
fprintf(fid, 'VexpKg =Vexpg/exp(kca) ;\n');

fprintf(fid, '//Innovation;\n');%6
fprintf(fid, 'x_p = (1/(1-xi_p))*log(xi_p*nu*(1-1/tau)/(1-xi_p/tau)) + (1-alphap)*(ome_p)+ alphap*(kpa(-1))+(1-alphap)*log((exp(np)));\n');
fprintf(fid, 'pi_p = log(1/nu-1) + x_p +log(p);\n');
fprintf(fid, 'exp(v_p) = exp(pi_p) + (1-phi_p)*exp(mc(+1) + v_p(+1));\n');
fprintf(fid, 'exp(rpatent) = (1-phi_p)*exp(v_p)/(exp(v_p(-1))-exp(pi_p(-1)));\n');


fprintf(fid, 'exp(da) = exp(vtheta+s) + 1-phi_p;\n');
fprintf(fid, 'vtheta = log(chi) + (eta-1)*s;\n');
fprintf(fid, 'ptil*exp(s) = exp(mc(+1) + v_p(+1))*(exp(da) - (1-phi_p));\n');
fprintf(fid, 'rrnd = log((exp(v_p)*(exp(da(-1)) - (1-phi_p)))/(ptil(-1)*exp(s(-1))));\n');

fprintf(fid, '//Productivity;\n');%3
% fprintf(fid, 'ar_inv = (1-rhoinv)*ar_inv(-1)+(1-rhoinv)*(dip-mu);\n');
if stoch_vol_switch==1;
fprintf(fid, '    ome_p = (1-rho)*ome_p_bar+ rho*ome_p(-1) + exp(vol(-1))*ea;\n');
fprintf(fid, 'vol = rhovol*vol(-1)+ con_shocka*ea+con_shockx*(da-da(-1))+es;\n');
fprintf(fid, '    dtfp = (rho-1)*(ome_p(-1)-ome_p_bar)+da(-1)+ exp(vol(-1))*ea;\n');
fprintf(fid, '    x = (rho-1)*(ome_p-ome_p_bar)+da;\n');

end
if stoch_vol_switch==0;
fprintf(fid, '    ome_p = (1-rho)*ome_p_bar + rho*ome_p(-1) + ea;\n');
end
fprintf(fid, 'argp = (1-rhoar)*argp(-1)+(1-rhoar)*(mu-da(-1))+rhoar*arc;\n');  
% end
fprintf(fid, '//Growth;\n');%14
fprintf(fid, 'dc = ca - ca(-1) + da(-1);\n');
fprintf(fid, 'kratio = exp(kca)/(exp(kca)+exp(kpa)) ;\n');
% fprintf(fid, 'gratio = Vexpg*ptil/(exp(ypa)*p+exp(yca)) ;\n');
% fprintf(fid, 'wratio = Vexpg*ptil/(Vexpg*ptil+Vexp*ptil) ;\n');
% fprintf(fid, 'yratio = exp(yca)/(exp(ypa)*p+exp(yca)) ;\n');

fprintf(fid, 'dyp = ypa - ypa(-1) + da(-1);\n');
fprintf(fid, 'dip = ipa - ipa(-1) + da(-1);\n');
% fprintf(fid, 'dkp = kpa - kpa(-1) + da(-1);\n');
fprintf(fid, 'ds = s - s(-1) + da(-1);\n');


fprintf(fid, 'dyc = yca - yca(-1) + da(-1);\n');
% fprintf(fid, 'dVexp = Vexp/Vexp(-1)*exp(da);\n');
% ipitot sitot ipiptot
fprintf(fid, 'igitot = Ic/(exp(ipa)+Ic+exp(s));\n');
% fprintf(fid, 'ipitot = exp(ipa)/(exp(ipa)+Ic+exp(s));\n');
% fprintf(fid, 'sitot = exp(s)/(exp(ipa)+Ic+exp(s));\n');
% fprintf(fid, 'ipiptot = exp(ipa)/(exp(ipa)+exp(s));\n');

fprintf(fid, 'dy = ya-ya(-1)+da(-1);\n');

fprintf(fid, 'tyg = (ypa+yca) - (ypa(-1)+yca(-1)) + da(-1);\n');
fprintf(fid, 'titot = log((exp(ipa)+Ic+exp(s))/(exp(ipa(-1))+Ic(-1)+exp(s(-1)))*exp(da(-1)));\n');
fprintf(fid, 'dyvp = log(exp(ypa)*p/(exp(ypa(-1))*p(-1))) + da(-1);\n');
% fprintf(fid, 'ikp =  ipa-kpa(-1) ;\n');
fprintf(fid, 'iyp =  ipa-ya;\n');
fprintf(fid, 'ia =  log((exp(ipa)+Ic));\n');
% fprintf(fid, 'kpkg =  exp(kpa)/exp(kca);\n');

%%exogenous policy rule biga bigv bnca bncv rho_ig rho_nc Iygbar ncntbar
fprintf(fid, 'Iyg =  Ic/exp(ya);\n');

fprintf(fid, '//Excess Rate of Returns;\n');%3
fprintf(fid, '1/exp(rf) = exp(m(+1));\n');
% fprintf(fid, 'exp(re) = (1-kratio)*exp(r)+kratio*exp(rc);\n');
fprintf(fid, 'exr = log(exp(r)*exp(ya-yca)^(1/tau)/exp(ya(-1)-yca(-1))^(1/tau))-rf(-1);\n');
fprintf(fid, 'exr_G = log(exp(rc)*exp(ya-yca)^(1/tau)/exp(ya(-1)-yca(-1))^(1/tau))-rf(-1);\n');
fprintf(fid, 'exrpatent = rpatent-rf(-1);\n');
fprintf(fid, 'exrrnd = rrnd-rf(-1);\n');

fprintf(fid, 'r_H = log((qp(-1)*exp(kpa(-1))*exp(r)+exp(v_p(-1))*exp(rrnd))/(qp(-1)*exp(kpa(-1))+exp(v_p(-1))));\n');
fprintf(fid, 'exrr_H = r_H-rf(-1);\n');
fprintf(fid, 'coeff1 = qp(-1)*exp(kpa(-1))/(qp(-1)*exp(kpa(-1))+exp(v_p(-1)));\n');
fprintf(fid, 'coeff2 = exp(v_p(-1))/(qp(-1)*exp(kpa(-1))+exp(v_p(-1)));\n');

fprintf(fid, 'r_H_patent = log((qp(-1)*exp(kpa(-1))*exp(r)+exp(v_p(-1))*exp(rpatent))/(qp(-1)*exp(kpa(-1))+exp(v_p(-1))));\n');
fprintf(fid, 'exrr_H_patent = r_H_patent-rf(-1);\n');
fprintf(fid, 'Er = r(+1);\n');
fprintf(fid, 'Errnd = rrnd(+1);\n');
fprintf(fid, 'Erc = rc(+1);\n');
fprintf(fid, 'Er_H_patent = r_H_patent(+1);\n');

% if stoch_vol_switch==1;
% fprintf(fid, 'Engma = exp(mu+x+0.5*exp(2*vol)*sigma^2);\n');
% end;
% if stoch_vol_switch==0;
% fprintf(fid, 'Engma = exp(mu+x+0.5*exp(2*0)*sigma^2);\n');
% end;
% fprintf(fid, 'eng = exp(da);\n');
% fprintf(fid, 'Eng = eng(+1);\n');
fprintf(fid, 'end;\n');%70
fprintf(fid, '\n');

% Initial values
%fprintf(fid, 'var EV ut da argp ev ca ypa yca ya kpa kca ipa Ic Vexp D Tax G Gprim T Tprim Gamp Gampprim Gamc Gamcprim m mc 
%dc qp qc p ptil r rc re x dyp dyc dip dic exr exr_G rf vol eng Eng Engma kratio wratio yratio tyg titot gammav dy pqr wagep wagec;\n');%Vr EMVr 
fprintf(fid, 'initval;\n');
fprintf(fid, 'gammav=%3.12f;\n',gamma);
fprintf(fid, 'ca=%3.12f;\n',css);
fprintf(fid, 'm=%3.12f;\n',mss);
fprintf(fid, 'mc=%3.12f;\n',mss);
fprintf(fid, 'da=%3.12f;\n', ngss);
fprintf(fid, 'argp=%3.12f;\n', arc);
fprintf(fid, 'ut=%3.15f;\n', utss);
fprintf(fid, 'ya=%3.12f;\n', yss);%8
fprintf(fid, 'gdp=%3.12f;\n', log(exp(yss) - (pss/ptilss)*exp(x_pss)));
% fprintf(fid, 'gdp=%3.12f;\n', log((ptilss*exp(yss) - pss*exp(x_pss))/pss));
fprintf(fid, 'pgdp=%3.12f;\n', log((pss*exp(ypss) - pss*exp(x_pss))/pss));
fprintf(fid, 'dgdp=%3.12f;\n', ngss); 
fprintf(fid, 'dypa=%3.12f;\n', ngss);
fprintf(fid, 'dya=%3.12f;\n', ngss);
fprintf(fid, 'dpgdp=%3.12f;\n', ngss);
%dypa dya dpgdp
% fprintf(fid, 'dfyc=%3.12f;\n', mu);
% fprintf(fid, 'dgdpp=%3.12f;\n', mu);
% fprintf(fid, 'dycp=%3.12f;\n', mu);
fprintf(fid, 'ypa=%3.12f;\n', ypss);
fprintf(fid, 'yca=%3.12f;\n', ycss);
fprintf(fid, 'kpa=%3.12f;\n', kpss);
fprintf(fid, 'kca=%3.12f;\n', kcss);%4
fprintf(fid, 'kratio=%3.12f;\n', exp(kcss)/(exp(kcss)+exp(kpss)));
Vrss = 1/tau*pss*exp(ypss)/(1-exp(mss));
Dss = (pss*exp(ypss)-(pss*(1-1/tau)*(1-alphap)*exp(ypss)/Np_ss)*Np_ss-ptilss*exp(ipss))/ptilss;
% fprintf(fid, 'wratio=%3.12f;\n', exp(kcss)*ptilss/(exp(kcss)*ptilss+exp(kpss)*(ptilss+exp(mss)*Vrss)));
% fprintf(fid, 'gratio=%3.12f;\n', exp(kcss)*ptilss/(exp(ycss)*ptilss+exp(yss)));
% %fprintf(fid, 'wratio=%3.12f;\n', exp(kcss)*ptilss/(exp(kcss)*ptilss+exp(mss)*Dss/(1-exp(mss))*ptilss));
% fprintf(fid, 'yratio=%3.12f;\n', exp(ycss)/(exp(ycss)*ptilss+exp(yss)));
fprintf(fid, 'ipa=%3.12f;\n', ipss);
fprintf(fid, 'Ic=%3.12f;\n', Icss);

fprintf(fid, 'wagep=%3.12f;\n', wagepss);
fprintf(fid, 'wagec=%3.12f;\n', wagecss);
fprintf(fid, 'wagepc=%3.12f;\n', wagepss/wagecss);%5
% fprintf(fid, 'D=%3.12f;\n', (pss*exp(ypss)-(pss*(1-1/tau)*(1-alphap)*exp(ypss)/Np_ss)*Np_ss-ptilss*exp(ipss))/ptilss);
% Taxss = -(exp(ycss)-((1-alphac)*exp(ycss)/Nc_ss)*Nc_ss-ptilss*exp(icss))/ptilss;
% % fprintf(fid, 'Tax=%3.12f;\n', Taxss);
% fprintf(fid, 'Vexp=%3.12f;\n',exp(mss)*exp(mu)*Dss/(1-exp(mss)*exp(mu)));
% Vexpss = exp(mss)*exp(mu)*Dss/(1-exp(mss)*exp(mu));
% fprintf(fid, 'VexpK=%3.12f;\n',(exp(mss)*exp(mu)*Dss/(1-exp(mss)*exp(mu)))/exp(kpss));
% fprintf(fid, 'Vexpg=%3.12f;\n',exp(mss)*exp(mu)*(-Taxss)/(1-exp(mss)*exp(mu)));
% Vexpgss = exp(mss)*exp(mu)*(-Taxss)/(1-exp(mss)*exp(mu));
% fprintf(fid, 'VexpKg=%3.12f;\n',(exp(mss)*exp(mu)*(-Taxss)/(1-exp(mss)*exp(mu)))/exp(kcss));
% 
% fprintf(fid, 'wratio=%3.12f;\n', Vexpss/(Vexpss+Vexpgss));
% fprintf(fid, 'gratio=%3.12f;\n', Vexpss/(exp(ycss)*ptilss+exp(yss)));
% %fprintf(fid, 'wratio=%3.12f;\n', exp(kcss)*ptilss/(exp(kcss)*ptilss+exp(mss)*Dss/(1-exp(mss))*ptilss));
% fprintf(fid, 'yratio=%3.12f;\n', exp(ycss)/(exp(ycss)*ptilss+exp(yss)));


% fprintf(fid, 'Vr=%3.12f;\n',Vrss);
% fprintf(fid, 'EMVr=%3.12f;\n',exp(mss)*Vrss);
% fprintf(fid, 'qpt=%3.12f;\n', ptilss+exp(mss)*Vrss/exp(kpss));
fprintf(fid, 'G=%3.12f;\n', 0);
fprintf(fid, 'Gprim = %3.12f;\n', 0);
fprintf(fid, 'Gamp=%3.12f;\n', exp(ipss)/exp(kpss));
fprintf(fid, 'Gampprim = %3.12f;\n', 1);
fprintf(fid, 'T=%3.12f;\n', 0);
fprintf(fid, 'Tprim = %3.12f;\n', 0);
fprintf(fid, 'Gamc=%3.12f;\n', Icss/exp(kcss));
fprintf(fid, 'Gamcprim = %3.12f;\n', 1);
fprintf(fid, 'dc=%3.12f;\n', ngss);
fprintf(fid, 'dyp=%3.12f;\n', ngss);
fprintf(fid, 'dyvp=%3.12f;\n', ngss);
fprintf(fid, 'dyc=%3.12f;\n', ngss);
fprintf(fid, 'dy=%3.12f;\n', ngss);
fprintf(fid, 'tyg=%3.12f;\n', ngss);%14



fprintf(fid, 'dip=%3.12f;\n', ngss);
fprintf(fid, 'ds=%3.12f;\n', ngss);
% fprintf(fid, 'dkp=%3.12f;\n', ngss);
fprintf(fid, 'igitot=%3.12f;\n', Icss/(exp(ipss)+Icss+exp(sss)));
% fprintf(fid, 'ipitot=%3.12f;\n', exp(ipss)/(exp(ipss)+Icss+exp(sss)));
% fprintf(fid, 'sitot=%3.12f;\n', exp(sss)/(exp(ipss)+Icss+exp(sss)));
% fprintf(fid, 'ipiptot=%3.12f;\n', exp(ipss)/(exp(ipss)+exp(sss)));

fprintf(fid, 'titot=%3.12f;\n', ngss);
% fprintf(fid, 'ikp=%3.12f;\n', ipss-kpss);
fprintf(fid, 'iyp=%3.12f;\n', ipss-yss);
fprintf(fid, 'ia=%3.12f;\n', log(exp(ipss)+Icss));
% fprintf(fid, 'kpkg=%3.12f;\n', exp(kpss)/exp(kcss));%8

fprintf(fid, 'tca=%3.12f;\n', tcass);
fprintf(fid, 'dtc=%3.12f;\n', ngss);
fprintf(fid, 'np=%3.12f;\n', log(Np_ss));
fprintf(fid, 'nc=%3.12f;\n', log(Nc_ss));
fprintf(fid, 'ntotal=%3.12f;\n', log(Np_ss+Nc_ss));
fprintf(fid, 'npnt=%3.12f;\n', Np_ss/(Np_ss+Nc_ss));
fprintf(fid, 'ncnt=%3.12f;\n', Nc_ss/(Np_ss+Nc_ss));%7
fprintf(fid, 'Iyg=%3.12f;\n', Icss/exp(yss));


fprintf(fid, 'sla=%3.12f;\n', 0);
fprintf(fid, 'LC=%3.12f;\n', 0);
fprintf(fid, 'dLCdHP=%3.12f;\n', 0);
fprintf(fid, 'dLCdHG=%3.12f;\n', 0);%4

fprintf(fid, 'w_var=%3.12f;\n', w);

fprintf(fid, 'p=%3.12f;\n', pss);
fprintf(fid, 'ptil=%3.12f;\n', ptilss);
fprintf(fid, 'qp=%3.12f;\n', ptilss);
fprintf(fid, 'qc=%3.12f;\n', ptilss);
fprintf(fid, 'r=%3.12f;\n', rss);
fprintf(fid, 'rc=%3.12f;\n', rcss);
fprintf(fid, 'rf=%3.12f;\n', rfss);
fprintf(fid, 'rpatent=%3.12f;\n', rss);
fprintf(fid, 'rrnd=%3.12f;\n', rss);
fprintf(fid, 'r_H=%3.12f;\n', rss);
fprintf(fid, 'r_H_patent=%3.12f;\n', rss);

fprintf(fid, 'Errnd=%3.12f;\n', rss);
fprintf(fid, 'Er=%3.12f;\n', rss);
fprintf(fid, 'Erc=%3.12f;\n', rcss);
fprintf(fid, 'Er_H_patent=%3.12f;\n', rss);

fprintf(fid, 'exr=%3.12f;\n', 0);
fprintf(fid, 'exr_G=%3.12f;\n', rcss-rfss);
fprintf(fid, 'exrpatent=%3.12f;\n', 0);
fprintf(fid, 'exrrnd=%3.12f;\n', 0);
fprintf(fid, 'exrr_H=%3.12f;\n', 0);
fprintf(fid, 'exrr_H_patent=%3.12f;\n', 0);
if stoch_vol_switch==1;
fprintf(fid, 'vol = %3.12f;\n', 0);
fprintf(fid, 'EV = %3.15f;\n', EVss);
end;
if stoch_vol_switch==0;
fprintf(fid, 'EV = %3.15f;\n', EVss);
end;
fprintf(fid, 'ev = %3.15f;\n', evss);
fprintf(fid, 'pqr=%3.12f;\n', 1);%14

fprintf(fid, 'ome_p=%3.12f;\n', ome_p_bar);
fprintf(fid, 'x_p=%3.12f;\n', x_pss);
fprintf(fid, 'pi_p=%3.12f;\n', pi_pss);
fprintf(fid, 'v_p=%3.12f;\n', v_pss);
fprintf(fid, 'vtheta=%3.12f;\n', vthetass);
fprintf(fid, 's=%3.12f;\n', sss);

fprintf(fid, 'dtfp=%3.12f;\n', ngss);
fprintf(fid, 'x=%3.12f;\n', ngss);
Dss = (pss*exp(ypss)-(pss*(1-1/tau)*(1-alphap)*exp(ypss)/Np_ss)*Np_ss-ptilss*exp(ipss)-pss*(1/nu)*exp(x_pss))/ptilss;
Vexpss = exp(mss)*exp(mu)*Dss/(1-exp(mss)*exp(mu));
fprintf(fid, 'D=%3.6f;\n', Dss);
fprintf(fid, 'Vexp=%3.6f;\n',Vexpss);
fprintf(fid, 'VexpK=%3.6f;\n',(exp(mss)*exp(mu)*Dss/(1-exp(mss)*exp(mu)))/exp(kpss));

Taxss = (exp(ycss)-wagecss*(Nc_ss)-ptilss*Icss)/ptilss;
Vexpgss = exp(mss)*exp(mu)*(Taxss)/(1-exp(mss)*exp(mu));
fprintf(fid, 'Tax=%3.6f;\n', Taxss);
fprintf(fid, 'Vexpg=%3.6f;\n',Vexpgss);
fprintf(fid, 'VexpKg=%3.6f;\n',Vexpgss/exp(kcss));
fprintf(fid, 'coeff1=%3.6f;\n',ptilss*exp(kpss)/(ptilss*exp(kpss)+exp(v_pss)));
fprintf(fid, 'coeff2=%3.6f;\n',exp(v_pss)/(ptilss*exp(kpss)+exp(v_pss)));


% ome_p x_p pi_p v_p vtheta s %6
fprintf(fid, 'end;\n');
fprintf(fid, '\n');
% fprintf(fid, '-ptil*Tax = exp(yca)-wagec*(exp(nc))-ptil*Ic;\n'); %Tax Vexpg VexpKg
% fprintf(fid, 'Vexpg = exp(m(+1))*(Vexpg(+1)-Tax(+1))*exp(da(+1));\n');
% fprintf(fid, 'VexpKg =Vexpg/exp(kca) ;\n');
%EV ut da argp ev ca ypa yca ya kpa kca 11
%ipa Ic G Gprim T Tprim Gamp Gampprim Gamc Gamcprim m mc 12
%dc qp qc p ptil r rc x dyp dyc dyvp dip igitot exr exr_G rf vol 17
%tyg titot gammav dy pqr wagep wagec 7
%ikp iyp dkp ia kpkg tca dtc np nc ntotal 10
%npnt ncnt sla LC dLCdHP dLCdHG wagepc w_var 8
% ome_p x_p pi_p v_p vtheta s 6


%%dynare
% 
% fprintf(fid, 'steady;\n');
% fprintf(fid, 'check;\n');
% fprintf(fid, 'shocks;\n');
% fprintf(fid, 'var ea; stderr %3.9f;\n', sigma);
% % % fprintf(fid, 'var ex; stderr  %3.9f;\n', sigmax);
% % %fprintf(fid, 'var ed; stderr  %3.9f;\n', sigmad);
% fprintf(fid, 'var es; stderr  %3.9f;\n', sigmas);
% fprintf(fid, 'end;\n');
if stoch_vol_switch==1;
fprintf(fid, 'vcov = [%3.12f 0 ;\n',sigma^2);
fprintf(fid, '       0        %3.12f] ;\n',sigmas^2);
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
% fprintf(fid, 'stoch_simul(periods= %i, order = 3);\n',1000);
% % , hp_filter = 128000

fclose(fid);

%% ===========================================================
% Solve Model using Dynare++
%=============================================================


%% Call executable
% disp('Running...')
% 
% !dynare++ --order 3 --sim 3 --per 10 --no-irfs --ss-tol 1e-10 Monopoly_Power_Approx_1.mod
% 
% disp('Done!')

%% Call dynare
% dynare Monopoly_Power_Approx_25.mod;
% %save LRP2_vol_of_vol.mat;
% save TSM_vol_of_vol7.mat;
% save Newtest.mat;