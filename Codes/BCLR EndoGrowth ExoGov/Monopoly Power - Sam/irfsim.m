global fname irf_sim dyn_irfp_ea_mean dyn_irfp_ex_mean dyn_irfp_es_mean dyn_irfp_ea_es_mean stoch_vol_switch voltense
global dyn_irfp_eg_mean gold_switch shock_direction_switch allshocks shortlongshocks% SAM ADD
%load(strcat(fname,'.mat'));

% Time 1 has no shock and is steady state of all variables

% SAM ADD (make var name smaller)
SHK=shock_direction_switch;
if abs(shock_direction_switch)~=1
    disp('Shock direction not set to 1 or -1');
end
shock_test = 0;
if mean(size(dyn_vcov_exo))==2
    shocks1=[0 SHK zeros(1,irf_sim-2); zeros(1,irf_sim)      ]*sqrt(dyn_vcov_exo(1,1));
    shocks2=[zeros(1,irf_sim);     0 SHK*((log(voltense)-log(1))/sqrt(dyn_vcov_exo(2,2))*sqrt(dyn_vcov_exo(2,2))) zeros(1,irf_sim-2)];
elseif mean(size(dyn_vcov_exo))==3
    shocks1=[0 SHK zeros(1,irf_sim-2); zeros(1,irf_sim);         zeros(1,irf_sim)]*sqrt(dyn_vcov_exo(1,1));
    shocks2=[zeros(1,irf_sim);         0 SHK zeros(1,irf_sim-2); zeros(1,irf_sim)]*sqrt(dyn_vcov_exo(2,2));
    shocks3=[zeros(1,irf_sim);         zeros(1,irf_sim);         0 SHK*((log(voltense)-log(1))/sqrt(dyn_vcov_exo(3,3))*sqrt(dyn_vcov_exo(3,3))) zeros(1,irf_sim-2)]; 
    shocks5=[0 0 -SHK*sqrt(dyn_vcov_exo(1,1)) zeros(1,irf_sim-3);        zeros(1,irf_sim);         0 SHK*((log(voltense)-log(1))/sqrt(dyn_vcov_exo(3,3))*sqrt(dyn_vcov_exo(3,3))) zeros(1,irf_sim-2)]; 
    shocks6=[0 SHK zeros(1,irf_sim-2); zeros(1,irf_sim);         zeros(1,irf_sim)]*sqrt(dyn_vcov_exo(1,1));
    shocks7=[0 -1*SHK*sqrt(dyn_vcov_exo(1,1)) zeros(1,irf_sim-2); 0 -1*SHK*sqrt(dyn_vcov_exo(2,2)) zeros(1,irf_sim-2);         zeros(1,irf_sim)];
elseif mean(size(dyn_vcov_exo))==4
    shocks1=[0 SHK zeros(1,irf_sim-2); zeros(1,irf_sim);         zeros(1,irf_sim);         zeros(1,irf_sim)]*sqrt(dyn_vcov_exo(1,1));
    shocks2=[zeros(1,irf_sim);         0 SHK zeros(1,irf_sim-2); zeros(1,irf_sim);         zeros(1,irf_sim)]*sqrt(dyn_vcov_exo(2,2));
    shocks3=[zeros(1,irf_sim);         zeros(1,irf_sim);         0 SHK zeros(1,irf_sim-2); zeros(1,irf_sim)]*sqrt(dyn_vcov_exo(3,3));    
    shocks4=[zeros(1,irf_sim);         zeros(1,irf_sim);         zeros(1,irf_sim);         0 SHK zeros(1,irf_sim-2)]*sqrt(dyn_vcov_exo(4,4));    
else 
    error(char(strcat({'Code not equipped to handle '},num2str(mean(size(dyn_vcov_exo))),{' shocks'})))
end

  
% Simulate
dyn_irfp_ea_mean=dynare_simul(strcat(fname,'.mat'),shocks1);
dyn_irfp_es_mean=dynare_simul(strcat(fname,'.mat'),shocks2);

if allshocks ==1 && shortlongshocks==0
    dyn_irfp_all_mean=dynare_simul(strcat(fname,'.mat'),shocks6);
elseif allshocks ==0 && shortlongshocks==1
    dyn_irfp_all_mean=dynare_simul(strcat(fname,'.mat'),shocks7);
end
    
if shock_test==1 && gold_switch==0
  dyn_irfp_es_mean=dynare_simul(strcat(fname,'.mat'),shocks3);
  dyn_irfp_ea_es_mean=dynare_simul(strcat(fname,'.mat'),shocks5);
elseif shock_test==0 && gold_switch==1
  dyn_irfp_eg_mean=dynare_simul(strcat(fname,'.mat'),shocks3);
elseif shock_test==1 && gold_switch==1
  dyn_irfp_es_mean=dynare_simul(strcat(fname,'.mat'),shocks3);
  dyn_irfp_ea_es_mean=dynare_simul(strcat(fname,'.mat'),shocks5);
  dyn_irfp_eg_mean=dynare_simul(strcat(fname,'.mat'),shocks4);
end

% SAM ADD THIS BLOCK OF CODE
% Store and save raw IRF series for use in conditional
% moment IRF computations in sim_dyn_mod
dyn_irfp_ea_raw = dyn_irfp_ea_mean;
%dyn_irfp_ea_raw_cum = cumsum(dyn_irfp_ea_raw,2);
dyn_irfp_ea_raw_lev = dyn_irfp_ea_raw./(dyn_irfp_ea_raw(:,1)*ones(1,irf_sim))-1;
dyn_irfp_es_raw = dyn_irfp_es_mean;
%dyn_irfp_es_raw_cum = cumsum(dyn_irfp_es_raw,2);
dyn_irfp_es_raw_lev = dyn_irfp_es_raw./(dyn_irfp_es_raw(:,1)*ones(1,irf_sim))-1;
save(strcat(fname,'.mat'),'dyn_irfp_ea_raw','dyn_irfp_es_raw','dyn_irfp_ea_raw_lev','dyn_irfp_es_raw_lev','-append')
if allshocks ==1 && shortlongshocks==0
    dyn_irfp_all_raw=dynare_simul(strcat(fname,'.mat'),shocks6);
    save(strcat(fname,'.mat'),'dyn_irfp_all_raw','-append')
elseif allshocks ==0 && shortlongshocks==1
    dyn_irfp_all_raw=dynare_simul(strcat(fname,'.mat'),shocks7);
    save(strcat(fname,'.mat'),'dyn_irfp_all_raw','-append')
end
if shock_test==1
    dyn_irfp_es_raw = dyn_irfp_es_mean;
 %   dyn_irfp_es_raw_cum = cumsum(dyn_irfp_es_raw,2);
    dyn_irfp_es_raw_lev = dyn_irfp_es_raw./(dyn_irfp_es_raw(:,1)*ones(1,irf_sim))-1;
    dyn_irfp_ea_es_raw = dyn_irfp_ea_es_mean;
 %   dyn_irfp_ea_es_raw_cum = cumsum(dyn_irfp_ea_es_raw,2);
    dyn_irfp_ea_es_raw_lev = dyn_irfp_ea_es_raw./(dyn_irfp_ea_es_raw(:,1)*ones(1,irf_sim))-1;
    save(strcat(fname,'.mat'),'dyn_irfp_es_raw','dyn_irfp_es_raw_lev','-append')
    save(strcat(fname,'.mat'),'dyn_irfp_ea_es_raw','dyn_irfp_ea_es_raw_lev','-append')
end
if gold_switch==1 
    dyn_irfp_eg_raw = dyn_irfp_eg_mean;
    save(strcat(fname,'.mat'),'dyn_irfp_eg_raw','-append')
end


% Fill in varaibles not modeled
dyn_irfp_ea_mean=fill_dyn(dyn_irfp_ea_mean);
dyn_irfp_es_mean=fill_dyn(dyn_irfp_es_mean);
if shock_test==1
  dyn_irfp_es_mean=fill_dyn(dyn_irfp_es_mean);
end
%GOLD, SAM ADD
if gold_switch==1 
  dyn_irfp_eg_mean=fill_dyn(dyn_irfp_eg_mean); 
end 

% Demean variables
dyn_irfp_ea_mean=dyn_irfp_ea_mean-dyn_irfp_ea_mean(:,1)*ones(1,irf_sim);
dyn_irfp_ea_mean_cum = cumsum(dyn_irfp_ea_mean,2);
dyn_irfp_es_mean=dyn_irfp_es_mean-dyn_irfp_es_mean(:,1)*ones(1,irf_sim);
dyn_irfp_es_mean_cum = cumsum(dyn_irfp_es_mean,2);
if shock_test==1
    dyn_irfp_es_mean=dyn_irfp_es_mean-dyn_irfp_es_mean(:,1)*ones(1,irf_sim);
    dyn_irfp_es_mean_cum = cumsum(dyn_irfp_es_mean,2);
    dyn_irfp_ea_es_mean=dyn_irfp_ea_es_mean-dyn_irfp_ea_es_mean(:,1)*ones(1,irf_sim);
    dyn_irfp_ea_es_mean_cum = cumsum(dyn_irfp_ea_es_mean,2);
end

%GOLD, SAM ADD
if gold_switch==1 
  dyn_irfp_eg_mean=dyn_irfp_eg_mean-dyn_irfp_eg_mean(:,1)*ones(1,irf_sim);
end 

save(strcat(fname,'.mat'),'dyn_irfp_ea_mean','dyn_irfp_es_mean','-append')
save(strcat(fname,'.mat'),'dyn_irfp_ea_mean_cum','dyn_irfp_es_mean_cum','-append')
if shock_test==1
    save(strcat(fname,'.mat'),'dyn_irfp_es_mean','-append')
    save(strcat(fname,'.mat'),'dyn_irfp_ea_es_mean','-append')
    save(strcat(fname,'.mat'),'dyn_irfp_es_mean_cum','-append')
    save(strcat(fname,'.mat'),'dyn_irfp_ea_es_mean_cum','-append')
end
%GOLD, SAM ADD
if gold_switch==1 
    save(strcat(fname,'.mat'),'dyn_irfp_eg_mean','-append')
end 
if allshocks ==1  && shortlongshocks==0
    save(strcat(fname,'.mat'),'dyn_irfp_all_mean','-append')
elseif allshocks ==0  && shortlongshocks==1
    save(strcat(fname,'.mat'),'dyn_irfp_all_mean','-append')
end