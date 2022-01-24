clear all;
clc;
%% Import data
ginvest = 1;
%GDP
% load GDP.mat;
clear all;
clc;

 addpath(genpath('data_for_Productivity_Uncertainty')); 
    addpath(genpath('matlab')); 
%     addpath(genpath('matlab/PattonWebsite')); 
%     addpath(genpath('matlab/CominGertler')); 

%% Import PD ratio
% 1q/1969-1q/2011
start_year = 1969;
end_year = 2016;
A=importdata(strcat(['data_for_ann_PU_measure_',num2str(start_year),'_',num2str(end_year),'.csv']));

data=A.data;
% clear A;
tfpygr = data(:,1)/100; 
year = data(:,2);
% qtr = data(:,3);
bondy1y = data(:,3);
bondy2y = data(:,4);
bondy3y = data(:,5);
bondy4y = data(:,6);
bondy5y = data(:,7);
bondy6y = data(:,8);
bondy7y = data(:,9);
inflationy = data(:,10);
ltgovbond = data(:,11);
pdratio = data(:,12);
ivoly = data(:,13);
% kg_ktot = data(:,14);
% G_y = data(:,15);
% ig_itot = data(:,16);
% ig_y = data(:,17);
% 1q/1969-1q/2011
% F=[bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy pdratio ivoly G_y kg_ktot ig_itot ig_y];
F=[bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy pdratio ivoly];
%% Run Regression da   = ca + b_x * F(-1) + ea; %1970-2011
lags = 4;
weight = 1;
% Y = tfpygr(2:end,1);
Y = tfpygr(2:end,1);
X = [ones(length(Y),1) F(1:end-1,:)];
[BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
TstaEA = BetaseEA./SesEA;
TCDFEA = tcdf(TstaEA,length(tfpygr(2:end,1)-5));
PvalueEA_ols = 2*(1-tcdf(abs(TstaEA),length(Y)-5));
ea = Y-X*BetaseEA; %1970-2011
Yea = Y;
Xea = X;
b_x = BetaseEA(2:end,1);
x = F*b_x+BetaseEA(1,1);%1969-2011
x_full= x;
x_MAX = x;
clear X Y;
%% Run Regression (ea^2).^0.5  = cv + b_vol*F(-1) + resid; %1970-2011
lags = 4;
weight = 1;
Y = (ea.^2).^0.5;
X = [ones(length(Y),1) F(1:end-1,:)];
[BetaseEV,SesEV,RsqrEV,RsqradjEV,VCVEV,FEV]=olsgmm(Y,X,lags,weight);
TstaEV = BetaseEV./SesEV;
TCDFEV = tcdf(TstaEA,length(tfpygr(2:end,1)-5));
PvalueEV_ols = 2*(1-tcdf(abs(TstaEV),length(Y)-5));
stdv = X*BetaseEV; %1969-2010
stdv_full = [ones(length(Y)+1,1) F(1:end,:)]*BetaseEV; %1969-2011
normstdv = stdv./exp(mean(log(stdv)));
normstdv_full = stdv_full./exp(mean(log(stdv_full)));
X_full = [ones(length(Y)+1,1) F(1:end,:)];
StErr_XB_full = diag((X_full*VCVEV*X_full')).^0.5./exp(mean(log(stdv_full)));
%% data structure
field1 = 'year';  value1 = year;
field2 = 'dtfp';  value2 = tfpygr;
field3 = 'x';  value3 = x;
field4 = 'expvol';  value4 = normstdv_full;
field5 = 'expvol_se';  value5 = StErr_XB_full;
data_inv_reg_ann = struct(field1,value1,field2,value2,field3,value3,field4,value4,field5,value5);

table = [value1 value2 value3 value4 value5];
table_headers = {field1,field2,field3,field4,field5};
fname=strcat(['data_inv_reg_ann_',num2str(start_year),'_',num2str(end_year)]);    
save(strcat(['data_for_Productivity_Uncertainty/',fname,'.mat']),'data_inv_reg_ann');
csvwrite_with_headers(strcat(['data_for_Productivity_Uncertainty/',fname,'.csv']),table,table_headers);
further_test = 1;
if further_test == 1
%% Added by Max on 02/03
TeMp = exp(mean(log(stdv)));

stdv=normstdv;
StErr_XB = diag((X*VCVEV*X')).^0.5;%1969-2010
clear X Y;

% normstdv_full_test = stdv_full./mean(stdv_full);%
% data_full = [tfpygr x_full normstdv_full_test];
%% Run Regression x = \rho_x*x(-1) + ex; %1970-2011
lags = 4;
weight = 1;
Y = x(2:end,1);
X = [x(1:end-1,1) ea];
[BetaseEX,SesEX,RsqrEX,RsqradjEX,VCVEX,FEX]=olsgmm(Y,X,lags,weight);
TstaEX = BetaseEX./SesEX;
TCDFEX = tcdf(TstaEX,length(Y));
PvalueEX_ols = 2*(1-tcdf(abs(TstaEX),length(Y)-5));
ex = Y-X*BetaseEX; 

StErr_X_MAX = diag((X*VCVEX*X')).^0.5;
clear X Y;
%% Run Regression stdv = c + \rho_v*stdv(-1)   +  b_v|x * ex + b_v|a * ea + ev. ; 2q/1969-4q/2010
lags = 4;
weight = 1;
% Y = stdv(2:end,1); % 2q/1969-4q/2010
% X = [ones(length(Y),1) stdv(1:end-1,1) ex(1:end-1,1) ea(1:end-1,1)./stdv(1:end-1,1)]; %2q/1969-4q/2010
% [BetaseEVV,SesEVV,RsqrEVV,RsqradjEVV,VCVEX,FEVV]=olsgmm(Y,X,lags,weight);
% TstaEVV = BetaseEVV./SesEVV;
% TCDFEVV = tcdf(TstaEVV,length(Y));
% PvalueEVV_ols = 2*(1-tcdf(abs(TstaEVV),length(Y)-5));
% ev = Y-X*BetaseEVV; %2q/1969-4q/2010

Y = log(stdv(2:end,1)); 
X = [ones(length(Y),1) log(stdv(1:end-1,1)) ex(1:end-1,1) ea(1:end-1,1)]; 
[BetaseEVV,SesEVV,RsqrEVV,RsqradjEVV,VCVEX,FEVV]=olsgmm(Y,X,lags,weight);
TstaEVV = BetaseEVV./SesEVV;
TCDFEVV = tcdf(TstaEVV,length(Y));
PvalueEVV_ols = 2*(1-tcdf(abs(TstaEVV),length(Y)-5));
ev = Y-X*BetaseEVV; 
err=(exp(Y)-exp(X*BetaseEVV));
sev = sqrt((err)'*(err)/length(err));
clear X Y; 

%% Moment condition
NN = size(ea(1:end-1,1),1);
siga = (sum(ea(1:end-1,1).^2)/NN)^0.5;
sigx = (sum(ex(1:end-1,1).^2)/NN)^0.5;
sigxa = sigx/siga;
sigv = (sum(ev.^2)/NN)^0.5;
% E = b_5^2 - sum(ea.^2)/N
% E2 = (b_4*b_5)^2 - sum(ex.^2)/N

beta = [BetaseEA;BetaseEV;BetaseEX;BetaseEVV;siga;sigxa;sigv];
GMM_data_test = [tfpygr F];

%% Figure starts
% NBERQ_start = [1949 1953.5 1957.75 1960.5 1970 1974 1980.25 1981.75 1990.75 2001.25 2008];
% NBERQ_finish = [1950 1954.5 1958.5 1961.25 1971 1975.25 1980.75 1983 1991.25 2002 2009.5];
%colorstr=[159 182 205]/256;
% NBERQ_start = [1970 1974 1980.25 1981.75 1990.75 2001.25 2008];
% NBERQ_finish = [ 1971 1975.25 1980.75 1983 1991.25 2002 2009.5];
% colorstr=[159 182 205]/226;
% 
% 
% 
% j=1;
% figure(j)
% subplot(2,1,1);
% %plot(time,ev,'-',time,1.7*std(ev)*ones(1,length(time)),'--')
% %plot(time,ea(1:end-1,1))
%  %x 1969-2011
% % x_LB = x(1:end-2,1) -2*StErr_X_MAX(1:end-1,1);
% % x_UB = x(1:end-2,1) +2*StErr_X_MAX(1:end-1,1);
% 
% x_LB = x(2:end-1,1) -2*StErr_X_MAX(1:end-1,1);
% x_UB = x(2:end-1,1) +2*StErr_X_MAX(1:end-1,1);
% % plot(time,x(1:end-2,1),'-k', time,x_LB, '--k', time,x_UB, '--k')
% % shade(NBERQ_start,NBERQ_finish,colorstr); hold on
% % plot(time,x(1:end-2,1),'-k', time,x_LB, '--k', time,x_UB, '--k')
% plot(time,x(2:end-1,1),'-k', time,x_LB, '--k', time,x_UB, '--k')
% shade(NBERQ_start,NBERQ_finish,colorstr); hold on
% plot(time,x(2:end-1,1),'-k', time,x_LB, '--k', time,x_UB, '--k')
% 
% %plot(time,stdv(2:end,1)./exp(mean(log(stdv))))
% title('x','interpreter','latex')




%stdv 1970-2010

% subplot(2,1,2);
% % plot(time,stdv(2:end,1)./exp(mean(log(stdv))),'-',time,((stdv(2:end,1)+2*StErr_XB(2:end,1))./exp(mean(log(stdv)))),'--',time,((stdv(2:end,1)-2*StErr_XB(2:end,1))./exp(mean(log(stdv)))),'--')
% % plot(time,stdv(2:end,1)./exp(mean(log(stdv))),'-k',time,(stdv(2:end,1)+2*StErr_XB(2:end,1)/TeMp),'--k',time,(stdv(2:end,1)-2*StErr_XB(2:end,1)/TeMp),'--k')
% % shade(NBERQ_start,NBERQ_finish,colorstr); hold on;
% % plot(time,stdv(2:end,1)./exp(mean(log(stdv))),'-k',time,(stdv(2:end,1)+2*StErr_XB(2:end,1)/TeMp),'--k',time,(stdv(2:end,1)-2*StErr_XB(2:end,1)/TeMp),'--k')
% 
% stdv_se = StErr_XB/TeMp;
% vol_LB = stdv-2*stdv_se;
% vol_UB = stdv+2*stdv_se;
% plot(time,stdv(2:end,1),'-k',time,vol_LB(2:end),'--k',time,vol_UB(2:end),'--k')
% shade(NBERQ_start,NBERQ_finish,colorstr); hold on;
% plot(time,stdv(2:end,1),'-k',time,vol_LB(2:end),'--k',time,vol_UB(2:end),'--k')
% 
% 
% 
% title('exp(vol)','interpreter','latex')
% %plot(time,stdv(2:end,1)./0.002)
% saveas(j,'shocks_test')
%     saveas(j,'shocks_test_annual','png')
%     print('shocks_test_annual','-dpdf')
% save GMMdata.mat
GMM_test;

end
table_C1 = [[beta(24,1);stderr(24,1)] [beta(29,1);stderr(29,1)] [WT; pval]];

% j=0;
% for i=1927:2013
%     for k=1:4
%         j=j+1;
%     qtr(j,1)=k;
%     end
% end
