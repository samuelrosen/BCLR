function F = myfun4(x, beta, psi, gamma, tcass, ngss)
F = [(x(1) -( (1/(1-1/psi))*log((1-beta)*exp(tcass*(1-1/psi))+beta*exp((1-1/psi)/(1-gamma)*((x(1)+ngss)*(1-gamma))))));];


%1 EV 2 ut 3 ev

% EVss = x(1);
% utss = x(2);
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
% cgss =x(15); x_p = x(15)
% qss =x(16);
% rss =x(17);
% xss =x(18);
% ygss =x(19); s = x(19)
% igss =x(20);v_p =x(20);
% rexss =x(21);
% rfss=x(22);
% rcss = x(23);
% yss= x(24);
% pss= x(25);
% ptilss= x(26);