function F = myfun2(x, rho, beta, psi, gamma, Lss, alphac, alphap, deltak, deltac, xi, tau, arc, w, Gprimss, Gss, philev, Abar, ome_p_bar, xi_p, nu, eta, chi, phi_p)
F = [(x(1)-(x(1)));
    (x(2)-(x(2)));
    (x(4)-(x(4)));
%     (x(1)-(exp((x(2) + x(3))*( 1 - gamma ))));
% (exp(x(4))-(x(1)));
% (x(2)-((1/(1-1/psi))*log((1-beta)*exp(x(5)*(1-1/psi))+beta*exp((1-1/psi)/(1-gamma)*x(4)))));
%(x(5) - (x(7)*x(6)+(1-x(7))*(less-x(3))));
(x(24) - (1/(1-1/tau)*log(w*(exp(x(6)))^(1-1/tau)+(1-w)*(exp(x(7)))^(1-1/tau))));
(x(6) - (log(Abar)+(1-alphap)*(ome_p_bar)+alphap*(x(8)) + (1-alphap)*log(1-Lss)));
(x(7) - (log(Abar)+(1-alphap)*(ome_p_bar)+alphac*(x(9))+ (1-alphac)*(log(1-Lss)+arc)));
(x(25) - (w/(1-w)*(exp(x(6)-x(7)))^(-1/tau)));
(x(26) - (1/(1-w)*(exp(x(7)-x(24)))^(1/tau)));

(exp(x(24))- (exp(x(5)) + exp(x(10))+exp(x(11))+(x(25)/x(26))*exp(x(15))+exp(x(19))));
(Gss - (exp(x(10)-x(8))-(x(12)/(1-1/xi)*(exp(x(10)-x(8)))^(1-1/xi) + x(13))));
(Gprimss - (1-x(12)*exp(x(10)-x(8))^(-1/xi)));
(exp(x(8)+x(3)) -( (1-deltak)*exp(x(8))+exp(x(10))-Gss*exp(x(8))));
(exp(x(9)+x(3))-((1-deltac)*exp(x(9))+exp(x(11))));
% (x(14) - (log(beta)+(-1/psi)*x(3)+(1/psi-gamma)*(x(2)+x(3)-(1/(1-gamma))*x(4))));
(x(14) - (log(beta)+(-1/psi)*x(3)));

(x(16) - (x(26)/(1-Gprimss)));
(exp(x(17)) - (((1-1/tau)*x(25)*alphap*(1-xi_p)*exp(x(6) - x(8)) + x(16)*(1-deltak)+x(16)*(-Gprimss*exp(x(10)-x(9))+Gss))/x(16)));
(1-( exp(x(14) + x(17))));
(exp(x(23))-(alphac*exp(x(7)-x(9))+x(16)*(1-deltac))/x(16));
(1-( exp(x(14) + x(23))));
%(((1-x(7))/x(7)*exp(1/xil*(x(6)))*exp((-1/xil)*less))-((1-alphap)*exp(x(8))/(1-exp(less))));
(exp(x(3)) - (exp(log(chi) + (eta-1)*x(19)+x(19)) + 1-phi_p));
(x(18) - (rho*x(18)));
(x(15) - ((1/(1-xi_p))*log(xi_p*nu*(1-1/tau)/(1-xi_p/tau)) + (1-alphap)*(ome_p_bar)+ alphap*(x(8))+(1-alphap)*log(1-Lss)));
(x(26)*exp(x(19)) - (exp(x(14) + x(20))*(exp(3) - (1-phi_p))));
(x(20) -(log(1/nu-1) + x(15) +log(x(25))-log(1-(1-phi_p)*exp(x(14)))));
(1/exp(x(22)) - (exp(x(14))));
(x(21) - (philev*(exp(x(17))-exp(x(22)))));];


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