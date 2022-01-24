function F = myfun6(x, beta, psi, Lss, alphac, alphap, deltak, deltac, tau, arc, w, Abar, ome_p_bar, xi_p, nu, eta, chi, phi_p, IcYratio)
F = [(1 - beta*exp(-x(4)/psi)*((  (1-1/tau)*(w/(1-w)*(exp((alphap*(x(1)) + (1-alphap)*log(1-Lss))-(alphac*(x(2))+ (1-alphac)*(log(1-Lss)+arc))))^(-1/tau))*alphap*(1-xi_p)*exp((log(Abar)+(1-alphap)*(ome_p_bar)+alphap*(x(1)) + (1-alphap)*log(1-Lss)) - x(1)) + x(5)*(1-deltak)    )/x(5)));
(exp(x(4)) - (exp(log(chi) + (eta)*x(3)) + 1-phi_p));
(x(5)*exp(x(3)) - beta*exp(-x(4)/psi)*(exp((log(1/nu-1) + ((1/(1-xi_p))*log(xi_p*nu*(1-1/tau)/(1-xi_p/tau)) + (1-alphap)*(ome_p_bar)+ alphap*(x(1))+(1-alphap)*log(1-Lss)) +log((w/(1-w)*(exp((alphap*(x(1)) + (1-alphap)*log(1-Lss))-(alphac*(x(2))+ (1-alphac)*(log(1-Lss)+arc))))^(-1/tau)))-log(1-(1-phi_p)*beta*exp(-x(4)/psi))))*(exp(x(4)) - (1-phi_p))));
(x(5) - (1/(1-w)*(exp((log(Abar)+(1-alphap)*(ome_p_bar)+alphac*(x(2))+ (1-alphac)*(log(1-Lss)+arc))-(1/(1-1/tau)*log(w*(exp((log(Abar)+(1-alphap)*(ome_p_bar)+alphap*(x(1))+ (1-alphap)*log(1-Lss))))^(1-1/tau)+(1-w)*(exp((log(Abar)+(1-alphap)*(ome_p_bar)+alphac*(x(2))+ (1-alphac)*(log(1-Lss)+arc))))^(1-1/tau)))))^(1/tau)));
(x(6) -(log(Abar)+(1-alphac)*(ome_p_bar)+ alphac*(x(2))+(1-alphac)*(log(1-Lss)+arc)));
(x(7) - (exp(x(2)+x(4))-(1-deltac)*exp(x(2))));
(x(8) - (1/(1-1/tau)*log(w*(exp(x(9)))^(1-1/tau)+(1-w)*(exp(x(6)))^(1-1/tau))));
(x(7)-(exp(x(8))*IcYratio));
(x(9) - (log(Abar)+(1-alphap)*(ome_p_bar)+ alphap*(x(1))+(1-alphap)*log(1-Lss)));
];


%1 kpss 2 kcss 3 sss 4 ngss 5 ptilss
%6 ycss 7 Icss 8 yss 4 ypss

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