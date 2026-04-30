%-prediction analysis brain-behavioral
% using brain imaging data to predict age
clear all; close all; clc;
warning('off');

% ================================
% Load in GLM SigLevel data
% ================================

save_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract';
ASD_matfile = 'ASDonly_n39_SigLevels_Age_MotherEnv.mat';
TD_matfile = 'TDonly_n40_SigLevels_Age_MotherEnv.mat';

td_roi_data = load(fullfile(save_dir, TD_matfile));
td_roi_sigs = td_roi_data.roi_con;

roi_name = td_roi_data.roi_name;

asd_roi_data = load(fullfile(save_dir, ASD_matfile));
asd_roi_sigs = asd_roi_data.roi_con;

% ================================
% Load in Age data
% ================================

age_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/behavior';
ASD_age_fname = 'ASD_selected_age_scan_n39_ADOS.txt';
TD_age_fname = 'TD_selected_age_scan.txt';

ASD_age_raw = readtable(fullfile(age_dir, ASD_age_fname), ...
    'Delimiter', '\t', 'ReadVariableNames', false);
TD_age_raw  = readtable(fullfile(age_dir, TD_age_fname), ...
    'Delimiter', '\t', 'ReadVariableNames', false);
ASD_ages = ASD_age_raw.Var1;
TD_ages  = TD_age_raw.Var1;

no_rois = length(roi_name);

% ================================
% Run SVR on TDs
% ================================

for roi_i = 1:no_rois
    
    %== configurations ===
    y = TD_ages; % behavioral data -- can have multiple columns (different behavioral measures)
    x_data = td_roi_sigs(:,roi_i); % brain imaging data (mean ROI betas etc)
    %=====================
    
    
    %=====================
    %do not make changes beyond this line
    addpath('/oak/stanford/groups/menon/deprecatedGems/from_musk2_old_server/spm8_scripts/BrainBehav_Prediction');
    
    y_data_total = y;
    pval = zeros(size(y_data_total, 2), size(x_data, 2));
    corrval = zeros(size(y_data_total, 2), size(x_data, 2));
    
    for iy = 1:size(y_data_total, 2)
        y_data = y_data_total(:,iy);
        y_data = (y_data - mean(y_data))./std(y_data);
        x_data = (x_data - repmat(mean(x_data), length(y_data), 1))./repmat(std(x_data), length(y_data), 1);
        
        num_boot = 1000;
        num_run = 100;
        
        nfold = 4;
        pthresh = 0.5;
        nobsv = length(y_data);
        nvar = size(x_data, 2);
        
        corr_val = cell(num_run, 1);
%         matlabpool local 8;
        parfor irun = 1:num_run
            corr_val_run = zeros(nvar, 1);
            for ivar = 1:nvar
                x = x_data(:, ivar);
                y = y_data(:);
                
                fold_idx = bcv_sample(x, y, nfold, pthresh);
                
                y_pred = zeros(nobsv, 1);
                
                for ifold = 1:nfold
                    te_idx = find(fold_idx == ifold);
                    tr_idx = find(fold_idx ~= ifold);
                    est_beta = regress(y(tr_idx), x(tr_idx));
                    y_pred(te_idx) = x(te_idx)*est_beta;
                end
                
                corr_val_run(ivar) = corr(y_pred(:), y(:));
            end
            corr_val{irun} = corr_val_run;
        end
%         matlabpool close;
        
        null_corr_val = cell(num_boot, 1);
%         matlabpool local 8;
        parfor iboot = 1:num_boot
            null_corr_val_run = zeros(num_run, nvar);
            for ivar = 1:nvar
                x = x_data(:, ivar);
                y = y_data(:);
                null_y = y(randperm(length(y_data)));
                
                for irun = 1:num_run
                    fold_idx = bcv_sample(x, null_y, nfold, pthresh);
                    null_y_pred = zeros(nobsv, 1);
                    for ifold = 1:nfold
                        te_idx = find(fold_idx == ifold);
                        tr_idx = find(fold_idx ~= ifold);
                        est_beta = regress(null_y(tr_idx), x(tr_idx));
                        null_y_pred(te_idx) = x(te_idx)*est_beta;
                    end
                    null_corr_val_run(irun, ivar) = corr(null_y(:), null_y_pred(:));
                end
            end
            null_corr_val{iboot} = null_corr_val_run;
        end
%         matlabpool close;
        
        sum_corr_val = 0;
        for irun = 1:num_run
            sum_corr_val = sum_corr_val + corr_val{irun};
        end
        corr_val = sum_corr_val/num_run;
        
        mean_null_corr_val = zeros(num_boot, nvar);
        
        for iboot = 1:num_boot
            mean_null_corr_val(iboot, :) = squeeze(mean(null_corr_val{iboot}, 1));
        end
        null_corr_val = mean_null_corr_val;
        
        p_val = zeros(nvar,1);
        for i = 1:nvar
            p_val(i) = sum(null_corr_val(:,i) > corr_val(i))/num_boot;
        end
        
        pval(iy, :) = p_val(:)';
        corrval(iy, :) = corr_val(:)';
    end
    
    fprintf('p values : \n')
    pval
    fprintf('correlations between the observed and predicted: \n')
    corrval
    
    TD_pval_list(roi_i,1) = pval;
    TD_corrval_list(roi_i,1) = corrval;
    
end
    

% ================================
% Run SVR on ASDs
% ================================

for roi_i = 1:no_rois
    
    %== configurations ===
    y = ASD_ages; % behavioral data -- can have multiple columns (different behavioral measures)
    x_data = asd_roi_sigs(:,roi_i); % brain imaging data (mean ROI betas etc)
    %=====================
    
    
    %=====================
    %do not make changes beyond this line
    addpath('/oak/stanford/groups/menon/deprecatedGems/from_musk2_old_server/spm8_scripts/BrainBehav_Prediction');
    
    y_data_total = y;
    pval = zeros(size(y_data_total, 2), size(x_data, 2));
    corrval = zeros(size(y_data_total, 2), size(x_data, 2));
    
    for iy = 1:size(y_data_total, 2)
        y_data = y_data_total(:,iy);
        y_data = (y_data - mean(y_data))./std(y_data);
        x_data = (x_data - repmat(mean(x_data), length(y_data), 1))./repmat(std(x_data), length(y_data), 1);
        
        num_boot = 1000;
        num_run = 100;
        
        nfold = 4;
        pthresh = 0.5;
        nobsv = length(y_data);
        nvar = size(x_data, 2);
        
        corr_val = cell(num_run, 1);
%         matlabpool local 8;
        parfor irun = 1:num_run
            corr_val_run = zeros(nvar, 1);
            for ivar = 1:nvar
                x = x_data(:, ivar);
                y = y_data(:);
                
                fold_idx = bcv_sample(x, y, nfold, pthresh);
                
                y_pred = zeros(nobsv, 1);
                
                for ifold = 1:nfold
                    te_idx = find(fold_idx == ifold);
                    tr_idx = find(fold_idx ~= ifold);
                    est_beta = regress(y(tr_idx), x(tr_idx));
                    y_pred(te_idx) = x(te_idx)*est_beta;
                end
                
                corr_val_run(ivar) = corr(y_pred(:), y(:));
            end
            corr_val{irun} = corr_val_run;
        end
%         matlabpool close;
        
        null_corr_val = cell(num_boot, 1);
%         matlabpool local 8;
        parfor iboot = 1:num_boot
            null_corr_val_run = zeros(num_run, nvar);
            for ivar = 1:nvar
                x = x_data(:, ivar);
                y = y_data(:);
                null_y = y(randperm(length(y_data)));
                
                for irun = 1:num_run
                    fold_idx = bcv_sample(x, null_y, nfold, pthresh);
                    null_y_pred = zeros(nobsv, 1);
                    for ifold = 1:nfold
                        te_idx = find(fold_idx == ifold);
                        tr_idx = find(fold_idx ~= ifold);
                        est_beta = regress(null_y(tr_idx), x(tr_idx));
                        null_y_pred(te_idx) = x(te_idx)*est_beta;
                    end
                    null_corr_val_run(irun, ivar) = corr(null_y(:), null_y_pred(:));
                end
            end
            null_corr_val{iboot} = null_corr_val_run;
        end
%         matlabpool close;
        
        sum_corr_val = 0;
        for irun = 1:num_run
            sum_corr_val = sum_corr_val + corr_val{irun};
        end
        corr_val = sum_corr_val/num_run;
        
        mean_null_corr_val = zeros(num_boot, nvar);
        
        for iboot = 1:num_boot
            mean_null_corr_val(iboot, :) = squeeze(mean(null_corr_val{iboot}, 1));
        end
        null_corr_val = mean_null_corr_val;
        
        p_val = zeros(nvar,1);
        for i = 1:nvar
            p_val(i) = sum(null_corr_val(:,i) > corr_val(i))/num_boot;
        end
        
        pval(iy, :) = p_val(:)';
        corrval(iy, :) = corr_val(:)';
    end
    
    fprintf('p values : \n')
    pval
    fprintf('correlations between the observed and predicted: \n')
    corrval
    
    ASD_pval_list(roi_i,1) = pval;
    ASD_corrval_list(roi_i,1) = corrval;
    
end


save_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/Confirmatory_SVR_SigLevels_Age';
save_fname = 'Brain_Age_Predictions_MotherEnv_All_ROIs_TD_ASD.mat';
save_path = fullfile(save_dir, save_fname);
save(save_path, 'roi_name', 'TD_pval_list', 'TD_corrval_list', 'ASD_pval_list', 'ASD_corrval_list');
