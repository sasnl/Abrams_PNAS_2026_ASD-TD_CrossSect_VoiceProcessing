%% ==============================================
%  True SVR Brain→Age prediction (TD & ASD) — 4-fold CV + tuning + fast perms
%  - Linear SVR (fitrsvm)
%  - 4-fold outer CV (balanced by age), 3-fold inner CV for (C, Epsilon)
%  - ROI-level parfor (no nested parallelism)
%  - Permutation test with early-stop at alpha = 0.10
%  - Precompute outer folds once and reuse in permutations
%  - Report signed r, MAE, RMSE; keep linear Beta (avg over folds)
% ===============================================
clear; clc; close all;

%% ---- Parallel pool: match Slurm CPUs (ROI-level parallel) ----
cpus_env = str2double(getenv('SLURM_CPUS_PER_TASK'));
if isnan(cpus_env) || cpus_env < 1, cpus = min(4, feature('numcores')); else, cpus = cpus_env; end
p = gcp('nocreate'); if isempty(p) || p.NumWorkers ~= cpus, parpool('local', cpus); end
pctRunOnAll maxNumCompThreads(1);
warning('off'); rng(42,'twister');

%% -------- Paths & filenames --------
sig_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract';
ASD_matfile = 'ASDonly_n39_SigLevels_Age_MotherEnv.mat';
TD_matfile  = 'TDonly_n40_SigLevels_Age_MotherEnv.mat';

age_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/behavior';
ASD_age_fname = 'ASD_selected_age_scan_n39_ADOS.txt';
TD_age_fname  = 'TD_selected_age_scan.txt';

out_dir  = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/Confirmatory_SVR_SigLevels_Age/NEW_TrueSVR';
out_file = 'Brain_Age_Predictions_MotherEnv_All_ROIs_TD_ASD_SVR_4fold.mat';

%% -------- Load data --------
td = load(fullfile(sig_dir, TD_matfile));   % td.roi_con (nTD x nROI), td.roi_name
asd = load(fullfile(sig_dir, ASD_matfile)); % asd.roi_con (nASD x nROI)

roi_name     = td.roi_name;
td_roi_sigs  = td.roi_con;
asd_roi_sigs = asd.roi_con;

TD_ages = readtable(fullfile(age_dir, TD_age_fname),  'Delimiter','\t','ReadVariableNames',false); TD_ages = TD_ages.Var1;
ASD_ages = readtable(fullfile(age_dir, ASD_age_fname), 'Delimiter','\t','ReadVariableNames',false); ASD_ages = ASD_ages.Var1;

no_rois = numel(roi_name);

%% -------- Hyperparameters --------
Kouter    = 4;         % 4-fold outer CV (balanced by age)
Kinner    = 3;         % 3-fold inner CV (tuning) on training folds
num_boot  = 300;       % permutations (fast, bump later if needed)
alpha     = 0.10;      % early-stop threshold (two-sided)

% Linear SVR tuning grid (small/log-spaced)
C_grid    = [0.1, 1, 10];
Eps_grid  = [0.01, 0.1, 0.5];

%% -------- Precompute balanced 4-folds (by age) and reuse --------
folds_TD  = make_balanced_folds(TD_ages, Kouter);
folds_ASD = make_balanced_folds(ASD_ages, Kouter);

%% -------- Containers (TD / ASD) --------
TD_r   = nan(no_rois,1); TD_mae = nan(no_rois,1); TD_rmse = nan(no_rois,1);
TD_p   = nan(no_rois,1); TD_beta= nan(no_rois,1); TD_bestC= nan(no_rois,1); TD_bestEps = nan(no_rois,1);

ASD_r  = nan(no_rois,1); ASD_mae= nan(no_rois,1); ASD_rmse= nan(no_rois,1);
ASD_p  = nan(no_rois,1); ASD_beta=nan(no_rois,1); ASD_bestC= nan(no_rois,1); ASD_bestEps = nan(no_rois,1);

%% ================================  TD (parallel across ROIs)
parfor roi_i = 1:no_rois
    x = td_roi_sigs(:, roi_i);
    y = TD_ages(:);

    [r, mae, rmse, pval, beta_mean, bestC, bestEps] = ...
        svr_4fold_tuned_perm(x, y, folds_TD, Kinner, C_grid, Eps_grid, ...
                             num_boot, alpha);

    TD_r(roi_i)     = r;
    TD_mae(roi_i)   = mae;
    TD_rmse(roi_i)  = rmse;
    TD_p(roi_i)     = pval;
    TD_beta(roi_i)  = beta_mean;
    TD_bestC(roi_i) = bestC;
    TD_bestEps(roi_i)= bestEps;
end

%% ================================  ASD (parallel across ROIs)
parfor roi_i = 1:no_rois
    x = asd_roi_sigs(:, roi_i);
    y = ASD_ages(:);

    [r, mae, rmse, pval, beta_mean, bestC, bestEps] = ...
        svr_4fold_tuned_perm(x, y, folds_ASD, Kinner, C_grid, Eps_grid, ...
                             num_boot, alpha);

    ASD_r(roi_i)     = r;
    ASD_mae(roi_i)   = mae;
    ASD_rmse(roi_i)  = rmse;
    ASD_p(roi_i)     = pval;
    ASD_beta(roi_i)  = beta_mean;
    ASD_bestC(roi_i) = bestC;
    ASD_bestEps(roi_i)= bestEps;
end

%% -------- Save results --------
if ~exist(out_dir,'dir'); mkdir(out_dir); end
save(fullfile(out_dir, out_file), ...
    'roi_name', ...
    'TD_r','TD_mae','TD_rmse','TD_p','TD_beta','TD_bestC','TD_bestEps', ...
    'ASD_r','ASD_mae','ASD_rmse','ASD_p','ASD_beta','ASD_bestC','ASD_bestEps', ...
    'Kouter','Kinner','num_boot','alpha','C_grid','Eps_grid');

fprintf('Done. Saved to: %s\n', fullfile(out_dir, out_file));

%% ========== Local functions ==========

function [r_obs, mae_obs, rmse_obs, p_two_sided, beta_mean_overall, bestC_avg, bestEps_avg] = ...
    svr_4fold_tuned_perm(x_in, y_in, ~, Kinner, C_grid, Eps_grid, num_boot, alpha)
% 4-fold outer CV (rebuilt per ROI after masking), 3-fold inner CV with a tiny grid,
% serial permutation test with early stop at alpha.

    % ---- per-ROI masking ----
    x = x_in(:); y = y_in(:);
    valid = isfinite(x) & isfinite(y);
    x = x(valid); y = y(valid);
    n = numel(y);

    assert(n >= 8, 'Too few valid subjects for this ROI after masking (n=%d).', n);

    % ---- (Re)make balanced 4-folds on *masked* data ----
    Kouter = min(4, n);                        % if n<4, we’ll do fewer folds
    folds_outer = make_balanced_folds(y, Kouter);

    % Sanity
    assert(numel(folds_outer) == n, 'folds_outer length (%d) != n (%d).', numel(folds_outer), n);
    assert(all(ismember(folds_outer, 1:Kouter)), 'folds_outer has labels outside 1..Kouter.');

    % ---------- Observed outer CV with inner tuning ----------
    y_pred = nan(n,1);
    betas  = nan(Kouter,1);
    bestC_perFold   = nan(Kouter,1);
    bestEps_perFold = nan(Kouter,1);

    for f = 1:Kouter
        te_idx = (folds_outer == f);
        tr_idx = ~te_idx;

        assert(any(te_idx), 'Fold %d has no test samples.', f);
        assert(sum(tr_idx) >= 3, 'Fold %d has too few training samples (%d).', f, sum(tr_idx));

        % Inner CV on training only (balanced on y_tr)
        y_tr = y(tr_idx);
        innerK = min(Kinner, max(2, sum(tr_idx)));   % never > #train; at least 2
        inner_folds = make_balanced_folds(y_tr, innerK);

        % Tiny grid search over (C, Eps) using inner MSE
        best_loss = Inf; bestC = NaN; bestEps = NaN;
        for C = C_grid
            for eps = Eps_grid
                loss = inner_cv_mse(x(tr_idx), y_tr, inner_folds, C, eps);
                if loss < best_loss
                    best_loss = loss; bestC = C; bestEps = eps;
                end
            end
        end

        % Retrain on full training fold with best (C, Eps)
        mdl = fitrsvm( x(tr_idx), y(tr_idx), ...
                       'KernelFunction','linear', ...
                       'BoxConstraint',bestC, ...
                       'Epsilon',bestEps, ...
                       'Standardize',true );
        y_pred(te_idx) = predict(mdl, x(te_idx));
        if isprop(mdl,'Beta') && ~isempty(mdl.Beta)
            betas(f) = mdl.Beta;
        end
        bestC_perFold(f)   = bestC;
        bestEps_perFold(f) = bestEps;
    end

    % Observed metrics
    r_obs    = corr(y_pred, y, 'rows','complete');
    err      = y_pred - y;
    mae_obs  = mean(abs(err));
    rmse_obs = sqrt(mean(err.^2));
    beta_mean_overall = mean(betas,'omitnan');
    bestC_avg   = mean(bestC_perFold,'omitnan');
    bestEps_avg = mean(bestEps_perFold,'omitnan');

    % ---------- Permutation test (serial) with early stop ----------
    exceed = 0; ib = 0;
    for ib = 1:num_boot
        y_perm = y(randperm(n));
        y_pred_perm = nan(n,1);

        for f = 1:Kouter
            te_idx = (folds_outer == f);
            tr_idx = ~te_idx;

            yp_tr = y_perm(tr_idx);
            innerK = min(Kinner, max(2, sum(tr_idx)));
            inner_folds = make_balanced_folds(yp_tr, innerK);

            best_loss = Inf; bestC = NaN; bestEps = NaN;
            for C = C_grid
                for eps = Eps_grid
                    loss = inner_cv_mse(x(tr_idx), yp_tr, inner_folds, C, eps);
                    if loss < best_loss
                        best_loss = loss; bestC = C; bestEps = eps;
                    end
                end
            end

            mdlp = fitrsvm( x(tr_idx), y_perm(tr_idx), ...
                            'KernelFunction','linear', ...
                            'BoxConstraint',bestC, ...
                            'Epsilon',bestEps, ...
                            'Standardize',true );
            y_pred_perm(te_idx) = predict(mdlp, x(te_idx));
        end

        r_null = corr(y_perm, y_pred_perm, 'rows','complete');
        if abs(r_null) >= abs(r_obs), exceed = exceed + 1; end

        % Early-stop bounds
        min_p = exceed / ib;
        max_p = (exceed + (num_boot - ib)) / num_boot;
        if (min_p > alpha) || (max_p <= alpha), break; end
    end
    p_two_sided = (exceed + 1) / (ib + 1);
end



function mse = inner_cv_mse(X, y, folds, C, eps)
% Compute inner-CV MSE for a given (C, eps).
    K = numel(unique(folds));
    yhat = nan(size(y));
    for k = 1:K
        te = (folds == k); tr = ~te;
        mdl = fitrsvm( X(tr,:), y(tr,:), ...
                       'KernelFunction','linear', ...
                       'BoxConstraint', C, ...
                       'Epsilon', eps, ...
                       'Standardize', true );
        yhat(te) = predict(mdl, X(te,:));
    end
    mse = mean( (yhat - y).^2 );
end

function folds = make_balanced_folds(y, K)
% Balanced K-fold indices for regression via quantile binning of y, then round-robin.
    y = y(:);
    n = numel(y);
    K = min(K, max(1, n));     % never exceed n, at least 1

    % If all y identical or n is tiny, just round-robin
    if numel(unique(y)) < 2 || n <= K
        folds = 1 + mod((0:n-1), K)';   % exact length n
        return;
    end

    % Use up to 4 quantile bins but not more than #unique y
    qbins = min(4, numel(unique(y)));
    edges = [-Inf, quantile(y, (1:qbins-1)/qbins), Inf];
    [~,~,bin] = histcounts(y, edges);

    folds = zeros(n,1);
    for b = 1:qbins
        idx = find(bin == b);
        % deterministic order for reproducibility
        for ii = 1:numel(idx)
            folds(idx(ii)) = 1 + mod(ii-1, K);
        end
    end

    % Any leftovers (numerical edge cases) get round-robin
    if any(folds==0)
        idx = find(folds==0);
        for ii = 1:numel(idx)
            folds(idx(ii)) = 1 + mod(ii-1, K);
        end
    end
end
