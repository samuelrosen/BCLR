function sim_out=fill_dyn(sim_in)

global fname labor_switch
global gold_switch
load(strcat(fname,'.mat'));

% GDP, consumption, and investment to productivity in levels
%sim_in(dyn_i_Y_A,:)=exp(sim_in(dyn_i_y,:));
%sim_in(dyn_i_C_A,:)=exp(sim_in(dyn_i_c,:));
%sim_in(dyn_i_I_A,:)=exp(sim_in(dyn_i_i,:));
%sim_in(dyn_i_K_A,:)=exp(sim_in(dyn_i_k,:));
sim_in(dyn_i_Y_A,:)=exp(sim_in(dyn_i_ya,:));
sim_in(dyn_i_C_A,:)=exp(sim_in(dyn_i_ca,:));
sim_in(dyn_i_I_A,:)=exp(sim_in(dyn_i_ipa,:));
sim_in(dyn_i_K_A,:)=exp(sim_in(dyn_i_kpa,:));
sim_in(dyn_i_KC_A,:)=exp(sim_in(dyn_i_kca,:));
% Consumption, investment, and capital to GDP in levels
sim_in(dyn_i_C_Y,:)=sim_in(dyn_i_C_A,:)./sim_in(dyn_i_Y_A,:);
sim_in(dyn_i_I_Y,:)=sim_in(dyn_i_I_A,:)./sim_in(dyn_i_Y_A,:);
% sim_in(dyn_i_K_Y,:)=sim_in(dyn_i_K_A,:)./sim_in(dyn_i_Y_A,:);

% Aggregate productivity
%sim_in(dyn_i_a,:)=cumsum(sim_in(dyn_i_ng,:));
sim_in(dyn_i_a,:)=cumsum(sim_in(dyn_i_da,:));
sim_in(dyn_i_logYp,:)=cumsum(sim_in(dyn_i_dyp,:));


% Next section adds variables that might not exist

    % Add labor if it does not exist
%     if labor_switch==0
%         sim_in(dyn_i_n,:)=zeros(1,size(sim_in,2));
%     end
% 
%     % Gold (SAM ADD more vars)
%     if gold_switch==0
%         gold_vars = {'JA', 'dhc','dJoverA','ga','ga_bar','gda','BA','BG','pG','qG','rG','exr_G','CG','dg','dg_bar', 'dB'};%, 'dBG'};
%         for x = 1:size(gold_vars,2)
%             y=char(gold_vars(1,x));
%             eval(strcat('sim_in(dyn_i_',y,',:)=zeros(1,size(sim_in,2));'))
%         end
%     end



% Relative Investments
% sim_in(dyn_i_J_I,:)  = sim_in(dyn_i_JA,:)./(sim_in(dyn_i_I_A,:)+sim_in(dyn_i_JA,:));
% %sim_in(dyn_i_qKqG,:) = exp(sim_in(dyn_i_q,:))./exp(sim_in(dyn_i_qG,:));
% sim_in(dyn_i_qKqG,:) =   exp(sim_in(dyn_i_q,:)+sim_in(dyn_i_ka,:) ) ./ ( exp(sim_in(dyn_i_q,:)+sim_in(dyn_i_ka,:) ) +(exp(sim_in(dyn_i_qG,:))+ sim_in(dyn_i_BG,:)).*exp(sim_in(dyn_i_gda,:)) );    
% 
% % Gold utilization (SAM ADD)
% sim_in(dyn_i_G_Gbar,:) = (sim_in(dyn_i_gda,:) - sim_in(dyn_i_ga_bar,:) - 0*sim_in(dyn_i_da,:));
%     
    
    
    
% Added by Max
% Relative Investments
%sim_in(dyn_i_J_I,:)  = sim_in(dyn_i_JA,:)./exp(sim_in(dyn_i_ia,:));
%sim_in(dyn_i_qKqG,:) =   exp(sim_in(dyn_i_q,:)+sim_in(dyn_i_ka,:) ) ./ (exp(sim_in(dyn_i_qG,:))+ sim_in(dyn_i_BG,:)).*exp(sim_in(dyn_i_gda,:));    
%sim_in(dyn_i_qKqG,:) =    (sim_in(dyn_i_BA,:));    
 

sim_out=sim_in;