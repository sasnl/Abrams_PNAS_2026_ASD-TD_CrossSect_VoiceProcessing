%% ==============================================
%  True SVR Brain→Age prediction (TD & ASD)
%  - Cross-validated SVR (fitrsvm)
%  - cvpartition K-fold splits (no bcv_sample)
%  - Train-only scaling (Standardize=true)
%  - Two-sided permutation p-values (with early-stop at alpha=0.10)
%  - Fisher-z averaging across runs
%  - Signed corr(pred, true) for direction
%  - Precompute folds once per run (reused in perms)
% ===============================================
clear; clc; close all;

%% ---- Parallel pool setup: match workers to Slurm CPUs ----
cpus_env = str2double(getenv('SLURM_CPUS_PER_TASK'));
if isnan(cpus_env) || cpus_env < 1
    cpus = feature('numcores');   % local fallback (interactive)
else
    cpus = cpus_env;
end
p = gcp('nocreate');
if isempty(p) || p.NumWorkers ~= cpus
    parpool('local', cpus);
end
pctRunOnAll maxNumCompThreads(1);

warning('off');
rng(42,'twister');  % top-level seed for reproducibility

%% -------- Paths & filenames --------
sig_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract';
ASD_matfile = 'ASDonly_n39_SigLevels_Age_MotherOther.mat';
TD_matfile  = 'TDonly_n40_SigLevels_Age_MotherOther.mat';

age_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/behavior';
ASD_age_fname = 'ASD_selected_age_scan_n39_ADOS.txt';
TD_age_fname  = 'TD_selected_age_scan.txt';

out_dir  = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/Confirmatory_SVR_SigLevels_Age/NEW_TrueSVR';
out_file = 'Brain_Age_Predictions_MotherOther_All_ROIs_TD_ASD_SVR.mat';

%% -------- Load data --------
td = load(fullfile(sig_dir, TD_matfile));        % expects td.roi_con (nTD x nROI), td.roi_name
asd = load(fullfile(sig_dir, ASD_matfile));      % expects asd.roi_con (nASD x nROI)

roi_name     = td.roi_name;
td_roi_sigs  = td.roi_con;
asd_roi_sigs = asd.roi_con;

TD_ages_tbl  = readtable(fullfile(age_dir, TD_age_fname),  'Delimiter','\t','ReadVariableNames',false);
ASD_ages_tbl = readtable(fullfile(age_dir, ASD_age_fname), 'Delimiter','\t','ReadVariableNames',false);
TD_ages      = TD_ages_tbl.Var1;
ASD_ages     = ASD_ages_tbl.Var1;

no_rois = numel(roi_name);

%% -------- Analysis hyperparameters --------
num_boot = 1000;     % permutation draws (early-stop will often end sooner)
num_run  = 100;      % repeated CV runs
nfold    = 4;        % K-fold CV
alpha    = 0.10;     % early-stop threshold for perms (two-sided)

% SVR settings (tune if desired)
svr_kernel  = 'linear';   % 'linear' or 'rbf'
svr_epsilon = 0.1;
svr_boxC    = 1;

%% -------- Containers --------
TD_pval_list        = nan(no_rois,1);
TD_corrval_list     = nan(no_rois,1);
TD_beta_mean_list   = nan(no_rois,1);   % mean linear weight across all folds & runs (only for 'linear')

ASD_pval_list       = nan(no_rois,1);
ASD_corrval_list    = nan(no_rois,1);
ASD_beta_mean_list  = nan(no_rois,1);

%% ================================
%  Run SVR on TDs (per ROI)
% ================================
for roi_i = 1:no_rois
    x = td_roi_sigs(:, roi_i);
    y = TD_ages(:);

    [r_obs, p_two_sided, beta_mean] = svr_cv_perm(x, y, ...
        num_run, num_boot, nfold, alpha, svr_kernel, svr_epsilon, svr_boxC);

    TD_corrval_list(roi_i)   = r_obs;
    TD_pval_list(roi_i)      = p_two_sided;
    TD_beta_mean_list(roi_i) = beta_mean;
end

%% ================================
%  Run SVR on ASDs (per ROI)
% ================================
for roi_i = 1:no_rois
    x = asd_roi_sigs(:, roi_i);
    y = ASD_ages(:);

    [r_obs, p_two_sided, beta_mean] = svr_cv_perm(x, y, ...
        num_run, num_boot, nfold, alpha, svr_kernel, svr_epsilon, svr_boxC);

    ASD_corrval_list(roi_i)   = r_obs;
    ASD_pval_list(roi_i)      = p_two_sided;
    ASD_beta_mean_list(roi_i) = beta_mean;
end

%% -------- Save results --------
if ~exist(out_dir,'dir'); mkdir(out_dir); end
save(fullfile(out_dir, out_file), ...
    'roi_name', ...
    'TD_pval_list','TD_corrval_list','TD_beta_mean_list', ...
    'ASD_pval_list','ASD_corrval_list','ASD_beta_mean_list', ...
    'svr_kernel','svr_epsilon','svr_boxC','num_run','num_boot','nfold','alpha');

fprintf('Done. Saved to: %s\n', fullfile(out_dir, out_file));

%% ========== Local functions ==========

function [r_fisher_avg, p_two_sided, beta_mean_overall] = svr_cv_perm(x, y, num_run, num_boot, nfold, alpha, svr_kernel, svr_epsilon, svr_boxC)
% Repeated-CV SVR with permutation test.
% - Precomputes folds once per run and reuses in perms.
% - Early-stops permutations at alpha using running bounds.

    x = x(:); y = y(:);
    nobsv = numel(y);

    %% ---- Precompute K-fold indices once per run ----
    fold_idx_runs = cell(num_run,1);
    for irun = 1:num_run
        fold_idx_runs{irun} = make_folds(nobsv, nfold, irun);
    end

    %% ---- Observed statistic across runs ----
    r_runs = zeros(num_run,1);
    all_betas = [];

    for irun = 1:num_run
        fold_idx = fold_idx_runs{irun};
        y_pred = zeros(nobsv,1);

        for ifold = 1:nfold
            te_idx = (fold_idx == ifold);
            tr_idx = ~te_idx;

            mdl = fitrsvm( x(tr_idx), y(tr_idx), ...
                           'KernelFunction', svr_kernel, ...
                           'Standardize', true, ...
                           'Epsilon', svr_epsilon, ...
                           'BoxConstraint', svr_boxC );

            y_pred(te_idx) = predict(mdl, x(te_idx));

            if strcmpi(svr_kernel,'linear')
                all_betas(end+1,1) = mdl.Beta; %#ok<AGROW>
            end
        end

        r_runs(irun) = corr(y_pred, y, 'rows','complete');
    end

    r_fisher_avg = fisher_mean(r_runs);

    if strcmpi(svr_kernel,'linear') && ~isempty(all_betas)
        beta_mean_overall = mean(all_betas,'omitnan');
    else
        beta_mean_overall = NaN;
    end

    %% ---- Permutation (serial) with early stop at alpha ----
    exceed = 0;
    ib = 0;  % actual permutations performed
    for ib = 1:num_boot
        y_perm = y(randperm(nobsv));
        r_perm_runs = zeros(num_run,1);

        for irun = 1:num_run
            fold_idx = fold_idx_runs{irun};
            y_pred_perm = zeros(nobsv,1);

            for ifold = 1:nfold
                te_idx = (fold_idx == ifold);
                tr_idx = ~te_idx;

                mdlp = fitrsvm( x(tr_idx), y_perm(tr_idx), ...
                                'KernelFunction', svr_kernel, ...
                                'Standardize', true, ...
                                'Epsilon', svr_epsilon, ...
                                'BoxConstraint', svr_boxC );

                y_pred_perm(te_idx) = predict(mdlp, x(te_idx));
            end

            r_perm_runs(irun) = corr(y_perm, y_pred_perm, 'rows','complete');
        end

        r_perm = fisher_mean(r_perm_runs);
        if abs(r_perm) >= abs(r_fisher_avg)
            exceed = exceed + 1;
        end

        % Early-stop logic (bounds without smoothing)
        min_possible_p = exceed / ib;                                   % if all remaining are non-exceed
        max_possible_p = (exceed + (num_boot - ib)) / num_boot;         % if all remaining exceed

        if min_possible_p > alpha || max_possible_p <= alpha
            break;  % cannot change the decision at level alpha
        end
    end

    % Add-one smoothing using actual ib permutations performed
    p_two_sided = (exceed + 1) / (ib + 1);
end

function rbar = fisher_mean(rvec)
    rvec = max(min(rvec, 0.999999), -0.999999);
    z = atanh(rvec);
    rbar = tanh(mean(z,'omitnan'));
end

function fold_idx = make_folds(nobs, nfold, run_id)
    rng(1000 + run_id, 'twister');   % per-run reproducibility
    c = cvpartition(nobs, 'KFold', nfold);
    fold_idx = zeros(nobs,1);
    for k = 1:nfold
        fold_idx(test(c, k)) = k;
    end
end
