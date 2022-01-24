clear;
close all;
clc;
for i=42:44;MAIN(i);end;

clear;
close all;
clc;
for i=31:36;compare_mod(34,i);end;

clear;
close all;
clc;
for i = 31:36; load(strcat('Results\Monopoly_Power_Approx_',num2str(i),'\Monopoly_Power_Approx_',num2str(i),'.mat')); data(:,i-30)=output;end;