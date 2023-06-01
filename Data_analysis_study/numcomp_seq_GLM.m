%Script to fit the GLM at individual and GLMM at group level 
%on trial-by-trial responses to the numerosity comparison task in 
%sequential mode of presentation described in Dolfi et al. (in preparation)
%Serena Dolfi, May 2023, serena.dolfi@phd.unipd.it

clear
clc

%% Load dataset

exp_data = readtable('data_numcomp_visual.xlsx'); %Change as desired

%Note that both datasets only includes participants not discarded for
%-Difference in refresh rate
%-Low performance in practice or easy trials
%-Too many outlier RTs

%% Prepare data: create choice vector, exclude trials based on RT

exp_data.Resp_key = categorical(exp_data.Resp_key);
exp_data.Resp_choice(exp_data.Resp_key == 'first') = 0;
exp_data.Resp_choice(exp_data.Resp_key == 'second') = 1;

%To exclude trials below and above a certain response time
idx_exclude = exp_data.Resp_rt > 4 | exp_data.Resp_rt < 0.2;
exp_data.Resp_rt(idx_exclude) = NaN;
exp_data.Resp_choice(idx_exclude) = NaN;

%Compute ratios
exp_data.num_logratio = log2(exp_data.Num_2./exp_data.Num_1);
exp_data.dur_logratio = log2(exp_data.Dur_2./exp_data.Dur_1);
exp_data.tmpsp_logratio = log2(exp_data.Tmp_sp_2./exp_data.Tmp_sp_1);

%% Fit GLM at individual level 

ID_list = unique(exp_data.ID);
for s = 1:length(ID_list) %For each participant separately
    subj = ID_list(s);
    subj_idx = exp_data.ID == subj;
    
    subj_tbl = exp_data(subj_idx,:); %extract data of participant
    subj_tbl(isnan(subj_tbl.Resp_choice),:) = []; %exclude NaN rows
    
    %Fit GLM 
    out_model = fitglm(subj_tbl,'Resp_choice ~ num_logratio + dur_logratio + tmpsp_logratio',...
        'Distribution','binomial','Link','probit');
    
    %Store the results in a struct
    out_fit.ID(s,1) = subj;
    out_fit.B_Side(s,1) = out_model.Coefficients.Estimate(1);
    out_fit.B_Num(s,1) = out_model.Coefficients.Estimate(2);
    out_fit.B_Dur(s,1) = out_model.Coefficients.Estimate(3);
    out_fit.B_TmSp(s,1) = out_model.Coefficients.Estimate(4);
    out_fit.RSquared_adj(s,1) = out_model.Rsquared.Adjusted;
  
end

%% Compute projections

%[X Y Z] where x is Dur, y is TmSp and z is Num

%Axes/vectors corresponding to the different features:
feature_vec(1).Name = 'Num';  feature_vec(1).Vec = [0 0 1];
feature_vec(2).Name = 'Dur';  feature_vec(2).Vec = [1 0 0];
feature_vec(3).Name = 'TmSp'; feature_vec(3).Vec = [0 1 0];
feature_vec(4).Name = 'TED';  feature_vec(4).Vec = [1/2 0 1/2]; 
feature_vec(5).Name = 'MED';  feature_vec(5).Vec = [1/2 0 -1/2];
feature_vec(6).Name = 'TSD';  feature_vec(6).Vec = [0 1/2 1/2];
feature_vec(7).Name = 'MEP';  feature_vec(7).Vec = [0 1/2 -1/2];
feature_vec(8).Name = 'Cov';  feature_vec(8).Vec = [1/2 -1/2 0];

%For each participant we compute the projections of their discrimination vector
%onto all the single temporal features and we compute the magnitude of the
%projections
for s = 1:length(ID_list)
    vec_subj = [out_fit.B_Dur(s) out_fit.B_TmSp(s) out_fit.B_Num(s)];
    for f = 1:length(feature_vec)
        feature_axis = feature_vec(f).Vec;
        projection(f,:) = (dot(vec_subj,feature_axis)/norm(feature_axis)^2)*feature_axis;
        proj_magnitudes(s,f) = norm(projection(f,:));
    end
end

proj_names = strcat({feature_vec.Name}, '_proj');
proj_magnitudes = array2table(proj_magnitudes,'VariableNames',proj_names);

%% Vec-line-angle from numerosity

%For each participant we compute the angle between their discrimination
%vector and the numerosity axis

num_vec = feature_vec(1).Vec;
for s = 1:length(ID_list)
    vec_subj = [out_fit.B_Dur(s) out_fit.B_TmSp(s) out_fit.B_Num(s)];
    vecline_ang_deg(s,1) = atan2d(norm(cross(vec_subj,num_vec)),dot(vec_subj,num_vec));
end

%% Store all individual results in the same table 

out_fit = struct2table(out_fit);
out_table = [out_fit,proj_magnitudes];
out_table.vecline_ang_deg = vecline_ang_deg;

%% Alternative: fit GLMM to group data

%Prepare group table
group_tbl = exp_data;
group_tbl(isnan(group_tbl.Resp_choice),:) = [];

%We exclude individuals with poor fit of individual model 
%Comment following lines to fit the GLMM on all participants
incl_subj = out_table.ID(out_table.RSquared_adj > 0.2);
incl_idx = ismember(group_tbl.ID,incl_subj);
group_tbl = group_tbl(incl_idx,:);

%Fit GLMM
out_model_group = fitglme(group_tbl,'Resp_choice ~ num_logratio + dur_logratio + tmpsp_logratio + (1 + num_logratio + dur_logratio + tmpsp_logratio|ID)', ...
    'Distribution','Binomial','Link','probit');

%Print summary
out_model_group