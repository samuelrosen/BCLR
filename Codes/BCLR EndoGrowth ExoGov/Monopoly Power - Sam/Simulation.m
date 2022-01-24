numPeriods = 35001;
load TSM_Consumption_Ratio.mat;
shocks = mvnrnd(zeros(4,1),dyn_vcov_exo,numPeriods)';
    for jj=1:4
        shocks(jj,:)=shocks(jj,:)-mean(shocks(jj,:));
    end
    pop_sim = dynare_simul('TSM_Consumption_Ratio.mat',shocks);
    save TSM_Consumption_Ratio.mat;
    sim_mean=mean(pop_sim(:,501:35001),2)*400;
    sim_rf_std=std(pop_sim(dyn_i_rf,501:35001))*4^0.5*100;
    sim_cg_std=std(pop_sim(dyn_i_cg,501:35001))*4^0.5*100;
    sim_tyg_std=std(pop_sim(dyn_i_tyg,501:35001))*4^0.5*100;
    sim_tig_std=std(pop_sim(dyn_i_tig,501:35001))*4^0.5*100;
    sigmacy=sim_cg_std/sim_tyg_std;
    sim_ig_std=std(pop_sim(dyn_i_ig,501:35001))*4^0.5*100;
    sigmaiy=sim_ig_std/sim_tyg_std;
    rhocr=corr(pop_sim(dyn_i_cg,501:35001)',pop_sim(dyn_i_rex,501:35001)');
    rhoci=corr(pop_sim(dyn_i_cg,501:35001)',pop_sim(dyn_i_ig,501:35001)');
    rhocic=corr(pop_sim(dyn_i_cg,501:35001)',pop_sim(dyn_i_icg,501:35001)');
    acfcg  =         autocorr(pop_sim(dyn_i_cg,501:35001)',1);
    