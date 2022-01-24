clear all;
clc;
%% Import data
ginvest = 1;
%GDP;
clear all;
clc;

 addpath(genpath('data_for_Productivity_Uncertainty')); 
    addpath(genpath('matlab')); 
%     addpath(genpath('matlab/PattonWebsite')); 
%     addpath(genpath('matlab/CominGertler')); 

%% Import PD ratio
start_year = 1969;% 2q/1969-4q/2016
end_year = 2016;
A=importdata(strcat(['data_for_PU_measure_',num2str(start_year),'_',num2str(end_year),'.csv']));
data=A.data;
% clear A;
tfpqgr = data(:,1)./400;
year = data(:,2);
qtr = data(:,3); 
bondy1q = data(:,4);
bondy2q = data(:,5);
bondy3q = data(:,6);
bondy4q = data(:,7); 
bondy5q = data(:,8);
bondy6q = data(:,9);
bondy7q = data(:,10);
inflationq = data(:,11);
ltgovbond = data(:,12);
PD = data(:,13);
ivol = data(:,14);
% G_y = data(:,15);
% ig_itot = data(:,16);
% ig_y = data(:,17);

F=[bondy1q bondy2q bondy3q bondy4q bondy5q bondy6q inflationq PD ivol];
%% Run Regression da   = ca + b_x * F(-1) + ea; %2q/1969-1q/2011
lags = 4;
weight = 1;
Y = tfpqgr(2:end,1);
X = [ones(length(Y),1) F(1:end-1,:)];
[BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
TstaEA = BetaseEA./SesEA;
% TCDFEA = tcdf(TstaEA,length(tfpqgr(2:end,1)-5));
% PvalueEA_ols = 2*(1-tcdf(abs(TstaEA),length(Y)-5));
ea = Y-X*BetaseEA; %2q/1969-1q/2011
Yea = Y;
Xea = X;
b_x = BetaseEA(2:end,1);
x = F*b_x+BetaseEA(1,1);%1q/1969-1q/2011

x_MAX = x;

clear X Y;
%% Run Regression (ea^2).^0.5  = cv + b_vol*F(-1) + resid; %2q/1969-1q/2011
lags = 4;
weight = 1;
Y = (ea.^2).^0.5;
X = [ones(length(Y),1) F(1:end-1,:)];
[BetaseEV,SesEV,RsqrEV,RsqradjEV,VCVEV,FEV]=olsgmm(Y,X,lags,weight);
TstaEV = BetaseEV./SesEV;
TCDFEV = tcdf(TstaEA,length(tfpqgr(2:end,1)-5));
PvalueEV_ols = 2*(1-tcdf(abs(TstaEV),length(Y)-5));
stdv = X*BetaseEV; %1q/1969-4q/2010
normstdv = stdv./exp(mean(log(stdv)));
stdv_full = [ones(length(Y)+1,1) F(1:end,:)]*BetaseEV;
normstdv_full = stdv_full./exp(mean(log(stdv_full)));
X_full = [ones(length(Y)+1,1) F(1:end,:)];
StErr_XB_full = diag((X_full*VCVEV*X_full')).^0.5./exp(mean(log(stdv_full)));

%% data structure %1q/1969-1q/2011
% for i = 1+adjust_q:length(tfpqgr)+adjust_q;
%    year(i,1) = start_year + floor((i-1)/4);
% end
field1 = 'year';  value1 = year;
field2 = 'qtr';  value2 = qtr;
field3 = 'dtfp';  value3 = tfpqgr;
field4 = 'x';  value4 = x;
field5 = 'expvol';  value5 = normstdv_full;
field6 = 'expvol_se';  value6 = StErr_XB_full;
data_inv_reg_qtr = struct(field1,value1,field2,value2,field3,value3,field4,value4,field5,value5,field6,value6);

table = [value1 value2 value3 value4 value5 value6];
table_headers = {field1,field2,field3,field4,field5,field6};

fname=strcat(['data_inv_reg_qtr_',num2str(start_year),'_',num2str(end_year)]);    
save(strcat(['data_for_Productivity_Uncertainty/',fname,'.mat']),'data_inv_reg_qtr');
csvwrite_with_headers(strcat(['data_for_Productivity_Uncertainty/',fname,'.csv']),table,table_headers);

%% Table C1
further_test = 1;
if further_test == 1
%% Added by Max on 02/03
TeMp = exp(mean(log(stdv)));

stdv=normstdv;
StErr_XB = diag((X*VCVEV*X')).^0.5;%1q/1969-4q/2010
clear X Y;

%% Run Regression x = \rho_x*x(-1) + ex; %2q/1969-1q/2011
lags = 4;
weight = 1;
Y = x(2:end,1);
X = [x(1:end-1,1) ea];%2q/1969-1q/2011
[BetaseEX,SesEX,RsqrEX,RsqradjEX,VCVEX,FEX]=olsgmm(Y,X,lags,weight);
TstaEX = BetaseEX./SesEX;
TCDFEX = tcdf(TstaEX,length(Y));
PvalueEX_ols = 2*(1-tcdf(abs(TstaEX),length(Y)-5));
ex = Y-X*BetaseEX; %2q/1969-1q/2011

StErr_X_MAX = diag((X*VCVEX*X')).^0.5;

clear X Y;
%% Run Regression log(stdv) = c + \rho_v*log(stdv(-1))   +  b_v|x * ex + b_v|a * ea + ev. ; 2q/1969-4q/2010
lags = 4;
weight = 1;

Y = log(stdv(2:end,1)); % 2q/1969-4q/2010
X = [ones(length(Y),1) log(stdv(1:end-1,1)) ex(1:end-1,1) ea(1:end-1,1)]; %2q/1969-4q/2010
[BetaseEVV,SesEVV,RsqrEVV,RsqradjEVV,VCVEX,FEVV]=olsgmm(Y,X,lags,weight);
TstaEVV = BetaseEVV./SesEVV;
TCDFEVV = tcdf(TstaEVV,length(Y));
PvalueEVV_ols = 2*(1-tcdf(abs(TstaEVV),length(Y)-5));
ev = Y-X*BetaseEVV; %2q/1969-4q/2010
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
GMM_data_test = [tfpqgr F];

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
% 
% x_LB = x(1:end-2,1) -2*StErr_X_MAX(1:end-1,1);
% x_UB = x(1:end-2,1) +2*StErr_X_MAX(1:end-1,1);
% 
% plot(time,x(1:end-2,1),'-k', time,x_LB, '--k', time,x_UB, '--k')
% shade(NBERQ_start,NBERQ_finish,colorstr); hold on
% plot(time,x(1:end-2,1),'-k', time,x_LB, '--k', time,x_UB, '--k')
% 
% %plot(time,stdv(2:end,1)./exp(mean(log(stdv))))
% title('x','interpreter','latex')
% 
% 
% 
% 
% 
% 
% subplot(2,1,2);
% % plot(time,stdv(2:end,1)./exp(mean(log(stdv))),'-',time,((stdv(2:end,1)+2*StErr_XB(2:end,1))./exp(mean(log(stdv)))),'--',time,((stdv(2:end,1)-2*StErr_XB(2:end,1))./exp(mean(log(stdv)))),'--')
% % plot(time,stdv(2:end,1)./exp(mean(log(stdv))),'-k',time,(stdv(2:end,1)+2*StErr_XB(2:end,1)/TeMp),'--k',time,(stdv(2:end,1)-2*StErr_XB(2:end,1)/TeMp),'--k')
% % shade(NBERQ_start,NBERQ_finish,colorstr); hold on;
% % plot(time,stdv(2:end,1)./exp(mean(log(stdv))),'-k',time,(stdv(2:end,1)+2*StErr_XB(2:end,1)/TeMp),'--k',time,(stdv(2:end,1)-2*StErr_XB(2:end,1)/TeMp),'--k')
% stdv_se = StErr_XB/TeMp;
% vol_LB = stdv-2*stdv_se;
% vol_UB = stdv+2*stdv_se;
% plot(time,stdv(2:end),'-k',time,vol_LB(2:end),'--k',time,vol_UB(2:end),'--k')
% shade(NBERQ_start,NBERQ_finish,colorstr); hold on;
% plot(time,stdv(2:end),'-k',time,vol_LB(2:end),'--k',time,vol_UB(2:end),'--k')
% 
% 
% title('exp(vol)','interpreter','latex')
% %plot(time,stdv(2:end,1)./0.002)
% saveas(j,'shocks_test')
%     saveas(j,'shocks_test','png')
%     print('shocks_test','-dpdf')
%   %  close;
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
