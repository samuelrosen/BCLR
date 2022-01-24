function F = myfun5(x, beta, psi, Lss, alphac, alphap, deltak, deltac, tau, arc, w, Abar, ome_p_bar, xi_p, nu, eta, chi, phi_p, ngss, ypss, IcYratio)
F = [(x(1) -(log(Abar)+(1-alphac)*(ome_p_bar)+ alphac*(x(3))+(1-alphac)*(log(1-Lss)+arc)));
(x(2) - (exp(x(3)+ngss)-(1-deltac)*exp(x(3))));
(x(4) - (1/(1-1/tau)*log(w*(exp(ypss))^(1-1/tau)+(1-w)*(exp(x(1)))^(1-1/tau))));
(x(2)-(exp(x(4))*IcYratio));
];


%1 ycss 2 Icss 3 kcss 4 yss

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