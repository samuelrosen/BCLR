% Usage:
%       out = Monopoly_Power_Approx_85_f(params, y)
%   where
%       out    is a (98,1) column vector of the residuals
%              of the static system
%       params is a (66,1) vector of parameter values
%              in the ordering as declared
%       y      is a (98,1) vector of endogenous variables
%              in the ordering as declared
%
% Created by Dynare++ v. 4.2.1

% params ordering
% =====================
% theta
% deltac
% mu
% rho
% rhovol
% rhoar
% psi
% gamma
% alphap
% deltak
% xi
% cxi
% alpha1
% alpha0
% calpha1
% calpha0
% philev
% sigma
% sigmax
% alphac
% beta
% app
% tau
% w
% arc
% con_shocka
% con_shockx
% phi_growth
% pss
% ptilss
% ypss
% yss
% ipss
% kpss
% kcss
% rhoinv
% phi_growth_f
% theta_sla
% omega_barp
% omega_barc
% omega
% Np_ss
% Nc_ss
% theta_P
% theta_G
% phi_o_s
% Abar
% xi_p
% nu
% eta
% chi
% ome_p_bar
% phi_p
% gcctrl
% biga
% bigv
% bnca
% bncv
% rho_ig
% rho_nc
% Iygbar
% ncntbar
% rho_ivol
% rho_ia
% rho_nvol
% rho_na
%
% y ordering
% =====================
% EV
% ut
% da
% argp
% ev
% ca
% ypa
% yca
% ya
% kpa
% kca
% ipa
% Ic
% G
% Gprim
% T
% Tprim
% Gamp
% Gampprim
% Gamc
% Gamcprim
% m
% mc
% dc
% qp
% qc
% p
% ptil
% r
% rc
% dyp
% dyc
% dyvp
% dip
% igitot
% exr
% exr_G
% rf
% vol
% tyg
% titot
% gammav
% dy
% pqr
% wagep
% wagec
% iyp
% ia
% tca
% dtc
% np
% nc
% ntotal
% npnt
% ncnt
% sla
% LC
% dLCdHP
% dLCdHG
% wagepc
% w_var
% ome_p
% x_p
% pi_p
% v_p
% vtheta
% s
% kratio
% ds
% x
% dtfp
% gdp
% dgdp
% rpatent
% exrpatent
% D
% Vexp
% VexpK
% rrnd
% exrrnd
% Iyg
% Tax
% Vexpg
% VexpKg
% dpgdp
% pgdp
% dypa
% dya
% r_H
% exrr_H
% r_H_patent
% exrr_H_patent
% coeff1
% coeff2
% Er
% Errnd
% Erc
% Er_H_patent

function out = Monopoly_Power_Approx_85_f(params, y)
if size(y) ~= [98,1]
	error('Wrong size of y, must be [98,1]');
end
if size(params) ~= [66,1]
	error('Wrong size of params, must be [66,1]');
end

% hardwired constants
a0 =            0;
a1 =            1;
a2 = NaN;
a3 =    1.1283792;
% numerical constants
a11 =            1;
a76 =            2;
a172 =            0;
% parameter values
% theta not used in the model
a335 = params(2); % deltac
a66 = params(3); % mu
a534 = params(4); % rho
a547 = params(5); % rhovol
a571 = params(6); % rhoar
a20 = params(7); % psi
a5 = params(8); % gamma
a143 = params(9); % alphap
a325 = params(10); % deltak
a267 = params(11); % xi
a290 = params(12); % cxi
a266 = params(13); % alpha1
a273 = params(14); % alpha0
a289 = params(15); % calpha1
a296 = params(16); % calpha0
% philev not used in the model
% sigma not used in the model
% sigmax not used in the model
a155 = params(20); % alphac
a24 = params(21); % beta
% app not used in the model
a128 = params(23); % tau
a169 = params(24); % w
a578 = params(25); % arc
a549 = params(26); % con_shocka
a552 = params(27); % con_shockx
% phi_growth not used in the model
% pss not used in the model
% ptilss not used in the model
% ypss not used in the model
% yss not used in the model
% ipss not used in the model
% kpss not used in the model
% kcss not used in the model
% rhoinv not used in the model
% phi_growth_f not used in the model
a64 = params(38); % theta_sla
a41 = params(39); % omega_barp
a47 = params(40); % omega_barc
a52 = params(41); % omega
a74 = params(42); % Np_ss
a80 = params(43); % Nc_ss
a73 = params(44); % theta_P
a79 = params(45); % theta_G
a170 = params(46); % phi_o_s
a141 = params(47); % Abar
a354 = params(48); % xi_p
a427 = params(49); % nu
a515 = params(50); % eta
a513 = params(51); % chi
a536 = params(52); % ome_p_bar
a488 = params(53); % phi_p
a287 = params(54); % gcctrl
% biga not used in the model
% bigv not used in the model
% bnca not used in the model
% bncv not used in the model
% rho_ig not used in the model
% rho_nc not used in the model
% Iygbar not used in the model
% ncntbar not used in the model
% rho_ivol not used in the model
% rho_ia not used in the model
% rho_nvol not used in the model
% rho_na not used in the model
% exogenous variables to zeros
a542 = 0.0; % ea
a556 = 0.0; % es
% endogenous variables to y
a7 = y(1); % EV
a19 = y(2); % ut
a8 = y(2); % ut
a61 = y(3); % da
a9 = y(3); % da
a440 = y(3); % da
a573 = y(4); % argp
a163 = y(4); % argp
a116 = y(5); % ev
a16 = y(5); % ev
a583 = y(6); % ca
a39 = y(6); % ca
a247 = y(7); % ypa
a140 = y(7); % ypa
a133 = y(8); % yca
a125 = y(8); % yca
a132 = y(9); % ya
a124 = y(9); % ya
a148 = y(10); % kpa
a322 = y(10); % kpa
a159 = y(11); % kca
a332 = y(11); % kca
a596 = y(12); % ipa
a207 = y(12); % ipa
a625 = y(13); % Ic
a210 = y(13); % Ic
a263 = y(14); % G
a277 = y(15); % Gprim
a283 = y(16); % T
a300 = y(17); % Tprim
a306 = y(18); % Gamp
a311 = y(19); % Gampprim
a314 = y(20); % Gamc
a319 = y(21); % Gamcprim
a107 = y(22); % m
a434 = y(22); % m
a122 = y(23); % mc
a409 = y(23); % mc
a582 = y(24); % dc
a390 = y(25); % qp
a342 = y(25); % qp
a406 = y(26); % qc
a345 = y(26); % qc
a237 = y(27); % p
a191 = y(27); % p
a236 = y(28); % ptil
a199 = y(28); % ptil
a376 = y(29); % r
a410 = y(29); % r
a393 = y(30); % rc
a414 = y(30); % rc
a591 = y(31); % dyp
a604 = y(32); % dyc
a632 = y(33); % dyvp
a595 = y(34); % dip
a608 = y(35); % igitot
a650 = y(36); % exr
a657 = y(37); % exr_G
a654 = y(38); % rf
a646 = y(38); % rf
a171 = y(39); % vol
a546 = y(39); % vol
a617 = y(40); % tyg
a623 = y(41); % titot
a4 = y(42); % gammav
a613 = y(43); % dy
a348 = y(44); % pqr
a351 = y(45); % wagep
a361 = y(46); % wagec
a637 = y(47); % iyp
a640 = y(48); % ia
a59 = y(49); % tca
a26 = y(49); % tca
a58 = y(50); % dtc
a45 = y(51); % np
a48 = y(52); % nc
a96 = y(53); % ntotal
a100 = y(54); % npnt
a104 = y(55); % ncnt
a67 = y(56); % sla
a42 = y(56); % sla
a72 = y(57); % LC
a87 = y(58); % dLCdHP
a92 = y(59); % dLCdHG
a360 = y(60); % wagepc
a168 = y(61); % w_var
a538 = y(62); % ome_p
a145 = y(62); % ome_p
a214 = y(63); % x_p
a501 = y(64); % pi_p
a478 = y(64); % pi_p
a499 = y(65); % v_p
a485 = y(65); % v_p
a490 = y(65); % v_p
a507 = y(66); % vtheta
a528 = y(67); % s
a218 = y(67); % s
a587 = y(68); % kratio
a600 = y(69); % ds
a566 = y(70); % x
a559 = y(71); % dtfp
a227 = y(72); % gdp
a222 = y(72); % gdp
a226 = y(73); % dgdp
a496 = y(74); % rpatent
a663 = y(75); % exrpatent
a421 = y(76); % D
a437 = y(76); % D
a433 = y(77); % Vexp
a436 = y(77); % Vexp
a444 = y(78); % VexpK
a524 = y(79); % rrnd
a700 = y(79); % rrnd
a666 = y(80); % exrrnd
a643 = y(81); % Iyg
a448 = y(82); % Tax
a457 = y(82); % Tax
a455 = y(83); % Vexpg
a456 = y(83); % Vexpg
a462 = y(84); % VexpKg
a258 = y(85); % dpgdp
a259 = y(86); % pgdp
a254 = y(86); % pgdp
a244 = y(87); % dypa
a231 = y(88); % dya
a669 = y(89); % r_H
a679 = y(90); % exrr_H
a688 = y(91); % r_H_patent
a705 = y(91); % r_H_patent
a694 = y(92); % exrr_H_patent
a682 = y(93); % coeff1
a685 = y(94); % coeff2
a697 = y(95); % Er
a699 = y(96); % Errnd
a702 = y(97); % Erc
a704 = y(98); % Er_H_patent

t6 = a4 - a5;
t10 = a8 + a9;
t12 = a11 - a4;
t13 = t10 * t12;
t14 = exp(t13);
t15 = a7 - t14;
t17 = exp(a16);
t18 = t17 - a7;
t21 = a11 / a20;
t22 = a11 - t21;
t23 = a11 / t22;
t25 = a11 - a24;
t27 = t22 * a26;
t28 = exp(t27);
t29 = t25 * t28;
t30 = t22 / t12;
t31 = a16 * t30;
t32 = exp(t31);
t33 = a24 * t32;
t34 = t29 + t33;
t35 = log(t34);
t36 = t23 * t35;
t37 = a19 - t36;
t38 = exp(a26);
t40 = exp(a39);
t43 = exp(a42);
t44 = a41 * t43;
t46 = exp(a45);
t49 = exp(a48);
t50 = a47 * t49;
t51 = t46 + t50;
t53 = t51 ^ a52;
t54 = t44 * t53;
t55 = t54 / a52;
t56 = t40 - t55;
t57 = t38 - t56;
t60 = a26 - a59;
t62 = t60 + a61;
t63 = a58 - t62;
t65 = a11 - a64;
t68 = a66 + a67;
t69 = t68 - a61;
t70 = t65 * t69;
t71 = a42 - t70;
t75 = t46 - a74;
t77 = t75 ^ a76;
t78 = a73 * t77;
t81 = t49 - a80;
t82 = t81 ^ a76;
t83 = a79 * t82;
t84 = t78 + t83;
t85 = t43 * t84;
t86 = a72 - t85;
t88 = t43 * a76;
t89 = a73 * t88;
t90 = t75 * t89;
t91 = a87 - t90;
t93 = a79 * t88;
t94 = t81 * t93;
t95 = a92 - t94;
t97 = t46 + t49;
t98 = log(t97);
t99 = a96 - t98;
t101 = exp(a96);
t102 = t46 / t101;
t103 = a100 - t102;
t105 = t49 / t101;
t106 = a104 - t105;
t108 = log(a24);
t109 = -(a11);
t110 = t109 / a20;
t111 = a58 * t110;
t112 = t108 + t111;
t113 = t21 - a4;
t114 = a19 + a61;
t115 = a11 / t12;
t117 = t115 * a116;
t118 = t114 - t117;
t119 = t113 * t118;
t120 = t112 + t119;
t121 = a107 - t120;
t123 = exp(a107);
t126 = a124 - a125;
t127 = exp(t126);
t129 = a11 / a128;
t130 = t127 ^ t129;
t131 = t123 * t130;
t134 = a132 - a133;
t135 = exp(t134);
t136 = t135 ^ t129;
t137 = t131 / t136;
t138 = log(t137);
t139 = a122 - t138;
t142 = log(a141);
t144 = a11 - a143;
t146 = t144 * a145;
t147 = t142 + t146;
t149 = a143 * a148;
t150 = t147 + t149;
t151 = log(t46);
t152 = t144 * t151;
t153 = t150 + t152;
t154 = a140 - t153;
t156 = a11 - a155;
t157 = a145 * t156;
t158 = t142 + t157;
t160 = a155 * a159;
t161 = t158 + t160;
t162 = log(t49);
t164 = t162 + a163;
t165 = t156 * t164;
t166 = t161 + t165;
t167 = a125 - t166;
t173 = a171 - a172;
t174 = a170 * t173;
t175 = exp(t174);
t176 = a169 * t175;
t177 = a168 - t176;
t178 = a11 - t129;
t179 = a11 / t178;
t180 = exp(a140);
t181 = t180 ^ t178;
t182 = a168 * t181;
t183 = a11 - a168;
t184 = exp(a125);
t185 = t184 ^ t178;
t186 = t183 * t185;
t187 = t182 + t186;
t188 = log(t187);
t189 = t179 * t188;
t190 = a124 - t189;
t192 = a168 / t183;
t193 = a140 - a125;
t194 = exp(t193);
t195 = t109 / a128;
t196 = t194 ^ t195;
t197 = t192 * t196;
t198 = a191 - t197;
t200 = a11 / t183;
t201 = a125 - a124;
t202 = exp(t201);
t203 = t202 ^ t129;
t204 = t200 * t203;
t205 = a199 - t204;
t206 = exp(a124);
t208 = exp(a207);
t209 = t40 + t208;
t211 = t209 + a210;
t212 = a72 + t211;
t213 = a191 / a199;
t215 = exp(a214);
t216 = t213 * t215;
t217 = t212 + t216;
t219 = exp(a218);
t220 = t217 + t219;
t221 = t206 - t220;
t223 = exp(a222);
t224 = t206 - t216;
t225 = t223 - t224;
t228 = a222 - a227;
t229 = a61 + t228;
t230 = a226 - t229;
t232 = a199 / a191;
t233 = t206 * t232;
t234 = log(t233);
t235 = exp(a132);
t238 = a236 / a237;
t239 = t235 * t238;
t240 = log(t239);
t241 = t234 - t240;
t242 = a9 + t241;
t243 = a231 - t242;
t245 = t180 * a191;
t246 = log(t245);
t248 = exp(a247);
t249 = a237 * t248;
t250 = log(t249);
t251 = t246 - t250;
t252 = a9 + t251;
t253 = a244 - t252;
t255 = exp(a254);
t256 = t180 - t215;
t257 = t255 - t256;
t260 = a254 - a259;
t261 = a61 + t260;
t262 = a258 - t261;
t264 = a207 - a148;
t265 = exp(t264);
t268 = a11 / a267;
t269 = a11 - t268;
t270 = a266 / t269;
t271 = t265 ^ t269;
t272 = t270 * t271;
t274 = t272 + a273;
t275 = t265 - t274;
t276 = a263 - t275;
t278 = t109 / a267;
t279 = t265 ^ t278;
t280 = a266 * t279;
t281 = a11 - t280;
t282 = a277 - t281;
t284 = -(a159);
t285 = exp(t284);
t286 = a210 * t285;
t288 = t286 + a287;
t291 = a11 / a290;
t292 = a11 - t291;
t293 = a289 / t292;
t294 = t288 ^ t292;
t295 = t293 * t294;
t297 = t295 + a296;
t298 = t288 - t297;
t299 = a283 - t298;
t301 = t109 / a290;
t302 = t288 ^ t301;
t303 = a289 * t302;
t304 = a11 - t303;
t305 = a300 - t304;
t307 = exp(a148);
t308 = t208 / t307;
t309 = t308 - a263;
t310 = a306 - t309;
t312 = a11 - a277;
t313 = a311 - t312;
t315 = exp(a159);
t316 = a210 / t315;
t317 = t316 - a283;
t318 = a314 - t317;
t320 = a11 - a300;
t321 = a319 - t320;
t323 = a9 + a322;
t324 = exp(t323);
t326 = a11 - a325;
t327 = t307 * t326;
t328 = t208 + t327;
t329 = a263 * t307;
t330 = t328 - t329;
t331 = t324 - t330;
t333 = a9 + a332;
t334 = exp(t333);
t336 = a11 - a335;
t337 = t315 * t336;
t338 = a210 + t337;
t339 = a283 * t315;
t340 = t338 - t339;
t341 = t334 - t340;
t343 = a199 / a311;
t344 = a342 - t343;
t346 = a199 / a319;
t347 = a345 - t346;
t349 = a345 / a342;
t350 = a348 - t349;
t352 = t178 * a191;
t353 = t144 * t352;
t355 = a11 - a354;
t356 = t353 * t355;
t357 = t180 * t356;
t358 = t357 / t46;
t359 = a351 - t358;
t362 = a351 / a361;
t363 = a360 - t362;
t364 = a351 / a199;
t365 = a52 - a11;
t366 = t51 ^ t365;
t367 = t44 * t366;
t368 = a87 + t367;
t369 = t364 - t368;
t370 = a361 / a199;
t371 = a41 * a47;
t372 = t43 * t371;
t373 = t366 * t372;
t374 = a92 + t373;
t375 = t370 - t374;
t377 = exp(a376);
t378 = a143 * t352;
t379 = t355 * t378;
t380 = a140 - a148;
t381 = exp(t380);
t382 = t379 * t381;
t383 = t326 * a342;
t384 = -(a311);
t385 = t265 * t384;
t386 = a306 + t385;
t387 = a342 * t386;
t388 = t383 + t387;
t389 = t382 + t388;
t391 = t389 / a390;
t392 = t377 - t391;
t394 = exp(a393);
t395 = a125 - a159;
t396 = exp(t395);
t397 = a155 * t396;
t398 = t336 * a345;
t399 = -(a319);
t400 = a210 * t399;
t401 = t285 * t400;
t402 = a314 + t401;
t403 = a345 * t402;
t404 = t398 + t403;
t405 = t397 + t404;
t407 = t405 / a406;
t408 = t394 - t407;
t411 = a409 + a410;
t412 = exp(t411);
t413 = a11 - t412;
t415 = a409 + a414;
t416 = exp(t415);
t417 = a11 - t416;
t418 = t156 * t184;
t419 = t418 / t49;
t420 = a361 - t419;
t422 = a199 * a421;
t423 = t46 * a351;
t424 = t245 - t423;
t425 = a199 * t208;
t426 = t424 - t425;
t428 = a11 / a427;
t429 = a191 * t428;
t430 = t215 * t429;
t431 = t426 - t430;
t432 = t422 - t431;
t435 = exp(a434);
t438 = a436 + a437;
t439 = t435 * t438;
t441 = exp(a440);
t442 = t439 * t441;
t443 = a433 - t442;
t445 = exp(a322);
t446 = a433 / t445;
t447 = a444 - t446;
t449 = a199 * a448;
t450 = t49 * a361;
t451 = t184 - t450;
t452 = a199 * a210;
t453 = t451 - t452;
t454 = t449 - t453;
t458 = a456 + a457;
t459 = t435 * t458;
t460 = t441 * t459;
t461 = a455 - t460;
t463 = exp(a332);
t464 = a455 / t463;
t465 = a462 - t464;
t466 = a11 / t355;
t467 = a354 * a427;
t468 = t178 * t467;
t469 = a354 / a128;
t470 = a11 - t469;
t471 = t468 / t470;
t472 = log(t471);
t473 = t466 * t472;
t474 = t146 + t473;
t475 = t149 + t474;
t476 = t152 + t475;
t477 = a214 - t476;
t479 = t428 - a11;
t480 = log(t479);
t481 = a214 + t480;
t482 = log(a191);
t483 = t481 + t482;
t484 = a478 - t483;
t486 = exp(a485);
t487 = exp(a478);
t489 = a11 - a488;
t491 = a409 + a490;
t492 = exp(t491);
t493 = t489 * t492;
t494 = t487 + t493;
t495 = t486 - t494;
t497 = exp(a496);
t498 = t486 * t489;
t500 = exp(a499);
t502 = exp(a501);
t503 = t500 - t502;
t504 = t498 / t503;
t505 = t497 - t504;
t506 = exp(a9);
t508 = a218 + a507;
t509 = exp(t508);
t510 = a11 + t509;
t511 = t510 - a488;
t512 = t506 - t511;
t514 = log(a513);
t516 = a515 - a11;
t517 = a218 * t516;
t518 = t514 + t517;
t519 = a507 - t518;
t520 = a199 * t219;
t521 = t506 - t489;
t522 = t492 * t521;
t523 = t520 - t522;
t525 = exp(a61);
t526 = t525 - t489;
t527 = t486 * t526;
t529 = exp(a528);
t530 = a236 * t529;
t531 = t527 / t530;
t532 = log(t531);
t533 = a524 - t532;
t535 = a11 - a534;
t537 = t535 * a536;
t539 = a534 * a538;
t540 = t537 + t539;
t541 = exp(a171);
t543 = t541 * a542;
t544 = t540 + t543;
t545 = a145 - t544;
t548 = a171 * a547;
t550 = a542 * a549;
t551 = t548 + t550;
t553 = a9 - a61;
t554 = a552 * t553;
t555 = t551 + t554;
t557 = t555 + a556;
t558 = a546 - t557;
t560 = a534 - a11;
t561 = a538 - a536;
t562 = t560 * t561;
t563 = a61 + t562;
t564 = t543 + t563;
t565 = a559 - t564;
t567 = a145 - a536;
t568 = t560 * t567;
t569 = a9 + t568;
t570 = a566 - t569;
t572 = a11 - a571;
t574 = t572 * a573;
t575 = a66 - a61;
t576 = t572 * t575;
t577 = t574 + t576;
t579 = a571 * a578;
t580 = t577 + t579;
t581 = a163 - t580;
t584 = a39 - a583;
t585 = a61 + t584;
t586 = a582 - t585;
t588 = t445 + t463;
t589 = t463 / t588;
t590 = a587 - t589;
t592 = a140 - a247;
t593 = a61 + t592;
t594 = a591 - t593;
t597 = a207 - a596;
t598 = a61 + t597;
t599 = a595 - t598;
t601 = a218 - a528;
t602 = a61 + t601;
t603 = a600 - t602;
t605 = a125 - a133;
t606 = a61 + t605;
t607 = a604 - t606;
t609 = t208 + a210;
t610 = t219 + t609;
t611 = a210 / t610;
t612 = a608 - t611;
t614 = a124 - a132;
t615 = a61 + t614;
t616 = a613 - t615;
t618 = a125 + a140;
t619 = a133 + a247;
t620 = t618 - t619;
t621 = a61 + t620;
t622 = a617 - t621;
t624 = exp(a596);
t626 = t624 + a625;
t627 = t529 + t626;
t628 = t610 / t627;
t629 = t525 * t628;
t630 = log(t629);
t631 = a623 - t630;
t633 = t245 / t249;
t634 = log(t633);
t635 = a61 + t634;
t636 = a632 - t635;
t638 = a207 - a124;
t639 = a637 - t638;
t641 = log(t609);
t642 = a640 - t641;
t644 = a210 / t206;
t645 = a643 - t644;
t647 = exp(a646);
t648 = a11 / t647;
t649 = t648 - t435;
t651 = t130 * t377;
t652 = t651 / t136;
t653 = log(t652);
t655 = t653 - a654;
t656 = a650 - t655;
t658 = t130 * t394;
t659 = t658 / t136;
t660 = log(t659);
t661 = t660 - a654;
t662 = a657 - t661;
t664 = a496 - a654;
t665 = a663 - t664;
t667 = a524 - a654;
t668 = a666 - t667;
t670 = t307 * a390;
t671 = t377 * t670;
t672 = exp(a524);
t673 = t500 * t672;
t674 = t671 + t673;
t675 = t500 + t670;
t676 = t674 / t675;
t677 = log(t676);
t678 = a669 - t677;
t680 = a669 - a654;
t681 = a679 - t680;
t683 = t670 / t675;
t684 = a682 - t683;
t686 = t500 / t675;
t687 = a685 - t686;
t689 = t497 * t500;
t690 = t671 + t689;
t691 = t690 / t675;
t692 = log(t691);
t693 = a688 - t692;
t695 = a688 - a654;
t696 = a694 - t695;
t698 = a697 - a410;
t701 = a699 - a700;
t703 = a702 - a414;
t706 = a704 - a705;
% setting the output variable
out = zeros(98, 1);
out(1) = t6;
out(2) = t15;
out(3) = t18;
out(4) = t37;
out(5) = t57;
out(6) = t63;
out(7) = t71;
out(8) = t86;
out(9) = t91;
out(10) = t95;
out(11) = t99;
out(12) = t103;
out(13) = t106;
out(14) = t121;
out(15) = t139;
out(16) = t154;
out(17) = t167;
out(18) = t177;
out(19) = t190;
out(20) = t198;
out(21) = t205;
out(22) = t221;
out(23) = t225;
out(24) = t230;
out(25) = t243;
out(26) = t253;
out(27) = t257;
out(28) = t262;
out(29) = t276;
out(30) = t282;
out(31) = t299;
out(32) = t305;
out(33) = t310;
out(34) = t313;
out(35) = t318;
out(36) = t321;
out(37) = t331;
out(38) = t341;
out(39) = t344;
out(40) = t347;
out(41) = t350;
out(42) = t359;
out(43) = t363;
out(44) = t369;
out(45) = t375;
out(46) = t392;
out(47) = t408;
out(48) = t413;
out(49) = t417;
out(50) = t420;
out(51) = t432;
out(52) = t443;
out(53) = t447;
out(54) = t454;
out(55) = t461;
out(56) = t465;
out(57) = t477;
out(58) = t484;
out(59) = t495;
out(60) = t505;
out(61) = t512;
out(62) = t519;
out(63) = t523;
out(64) = t533;
out(65) = t545;
out(66) = t558;
out(67) = t565;
out(68) = t570;
out(69) = t581;
out(70) = t586;
out(71) = t590;
out(72) = t594;
out(73) = t599;
out(74) = t603;
out(75) = t607;
out(76) = t612;
out(77) = t616;
out(78) = t622;
out(79) = t631;
out(80) = t636;
out(81) = t639;
out(82) = t642;
out(83) = t645;
out(84) = t649;
out(85) = t656;
out(86) = t662;
out(87) = t665;
out(88) = t668;
out(89) = t678;
out(90) = t681;
out(91) = t684;
out(92) = t687;
out(93) = t693;
out(94) = t696;
out(95) = t698;
out(96) = t701;
out(97) = t703;
out(98) = t706;
