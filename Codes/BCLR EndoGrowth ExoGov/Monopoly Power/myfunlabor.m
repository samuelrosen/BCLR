function F = myfunlabor(x, wagepss, wagecss, ptilss, slass, npss, ncss, omega)
F = [(wagepss/ptilss - (x(1)*exp(slass)*(exp(npss)+x(2)*exp(ncss))^(omega-1)));
(wagecss/ptilss - (x(1)*x(2)*exp(slass)*(exp(npss)+x(2)*exp(ncss))^(omega-1)));
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