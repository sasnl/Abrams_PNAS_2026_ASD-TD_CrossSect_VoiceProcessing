%% ================== ROI-LEVEL GLMs: ASD + TD (No SC) ==================
% (A) Between-group:  ROI ~ Group * Age_c
% (B) ASD-only:       ROI ~ Age_c
% (C) TD-only:        ROI ~ Age_c
%
% Contrast: flipped so that positive β = NF voices > Mother’s voice
% Interpretation: positive Δslope or main effect → TD > ASD, NF > Mother
%
% Outputs (CSV):
%   - GROUP_Interaction_Summary.csv  (F, p, p_FDR, partial η², Cohen's f, Δslope, 95% CI)
%   - TD_Within_Age.csv              (β per year, t, df, p, partial η²)
%   - ASD_Within_Age.csv             (β per year, t, df, p, partial η²)

close all; clear; clc

%% ======== Paths: ASD ========
asd_age_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt';
asd_mat_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_Results/TD_ASD_ROI_SigLevel_GLM_n40_n39/Data/Control_ROIs_ACx/ASDonly_n39_Control_ACx_MothOth_NEG.mat';

%% ======== Paths: TD ========
td_age_path  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/TD_selected_age_scan.txt';
td_mat_path  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_Results/TD_ASD_ROI_SigLevel_GLM_n40_n39/Data/Control_ROIs_ACx/TDonly_n40_Control_ACx_MothOth_NEG.mat';

%% ======== Output directory ========
out_dir = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_Results/TD_ASD_ROI_SigLevel_GLM_n40_n39/Results/Control_ROIs_ACx/NF_minus_Mother';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

%% ======== Load ASD data ========
Age_ASD = readmatrix(asd_age_path); Age_ASD = Age_ASD(:);
S_asd = load(asd_mat_path);
assert(isfield(S_asd,'roi_con'), 'ASD MAT missing roi_con.');
roi_asd = S_asd.roi_con;
if isvector(roi_asd), roi_asd = roi_asd(:); end
if size(roi_asd,1) ~= numel(Age_ASD) && size(roi_asd,2) == numel(Age_ASD), roi_asd = roi_asd.'; end
assert(size(roi_asd,1) == numel(Age_ASD), 'ASD roi_con rows != #ASD subjects.');

% Flip contrast: Mother−NF  →  NF−Mother
roi_asd = -roi_asd;

if isfield(S_asd,'roi_name')
    roi_names = S_asd.roi_name;
    if isstring(roi_names), roi_names = cellstr(roi_names); end
    if ~iscell(roi_names),  roi_names = cellstr(roi_names); end
else
    roi_names = arrayfun(@(k)sprintf('ROI_%02d',k), 1:size(roi_asd,2), 'UniformOutput', false);
end

%% ======== Load TD data ========
Age_TD = readmatrix(td_age_path); Age_TD = Age_TD(:);
S_td = load(td_mat_path);
assert(isfield(S_td,'roi_con'), 'TD MAT missing roi_con.');
roi_td = S_td.roi_con;
if isvector(roi_td), roi_td = roi_td(:); end
if size(roi_td,1) ~= numel(Age_TD) && size(roi_td,2) == numel(Age_TD), roi_td = roi_td.'; end
assert(size(roi_td,1) == numel(Age_TD), 'TD roi_con rows != #TD subjects.');
assert(size(roi_td,2) == numel(roi_names), 'ASD and TD ROI column counts differ.');

% Flip contrast: Mother−NF  →  NF−Mother
roi_td = -roi_td;

%% ======== Build combined table for Group model ========
nA = numel(Age_ASD);
nT = numel(Age_TD);
Group = [repmat(categorical("ASD"), nA, 1); repmat(categorical("TD"), nT, 1)];
Group = reordercats(Group, {'ASD','TD'}); % ASD as reference -> Δslope = TD−ASD
Age   = [Age_ASD; Age_TD];
Age_c = Age - mean(Age,'omitnan');        % grand-mean center for interaction model
roi_all = [roi_asd; roi_td];

T_all = table(Group, Age_c);
nROIs = size(roi_all,2);
for r = 1:nROIs
    T_all.(roi_names{r}) = roi_all(:,r);
end

%% ======== (A) Between-group GLM: ROI ~ Group * Age_c ========
% Y units/meaning: positive β = NF voices > Mother’s voice; positive Δslope = TD > ASD
int_ROI        = strings(nROIs,1);
int_F          = nan(nROIs,1);
int_df1        = nan(nROIs,1);
int_df2        = nan(nROIs,1);
int_p          = nan(nROIs,1);
int_partialEta = nan(nROIs,1);
int_cohensF    = nan(nROIs,1);
int_beta       = nan(nROIs,1);  % Δslope (interaction coefficient)
int_ci_low     = nan(nROIs,1);
int_ci_high    = nan(nROIs,1);

for r = 1:nROIs
    yname = roi_names{r};
    mdl = fitlm(T_all, sprintf('%s ~ Group*Age_c', yname), 'CategoricalVars','Group');

    coefNames  = mdl.CoefficientNames;  % {'(Intercept)','Group_TD','Age_c','Group_TD:Age_c', ...}
    isInteract = contains(coefNames,'Group_TD') & contains(coefNames,'Age_c');
    idxCols    = find(isInteract);
    P          = numel(coefNames);

    if ~isempty(idxCols)
        C = zeros(numel(idxCols), P); 
        for k = 1:numel(idxCols), C(k, idxCols(k)) = 1; end
        [pInt, Fint, df1] = coefTest(mdl, C);
        df2 = mdl.DFE;

        partialEta2 = (Fint * df1) / (Fint * df1 + df2);
        cohensF     = sqrt(partialEta2 / (1 - partialEta2));

        b  = mdl.Coefficients.Estimate;
        ci = coefCI(mdl, 0.05);

        int_ROI(r)        = string(yname);
        int_F(r)          = Fint;
        int_df1(r)        = df1;
        int_df2(r)        = df2;
        int_p(r)          = pInt;
        int_partialEta(r) = partialEta2;
        int_cohensF(r)    = cohensF;
        int_beta(r)       = b(idxCols(1));
        int_ci_low(r)     = ci(idxCols(1),1);
        int_ci_high(r)    = ci(idxCols(1),2);
    else
        warning('No Group_TD:Age_c interaction for ROI %s.', yname);
    end
end

% === FDR across ROIs (BH) ===
p_FDR = nan(size(int_p));
try
    p_FDR = mafdr(int_p, 'BHFDR', true);
catch
    [p_sorted, ix] = sort(int_p); m = numel(p_sorted);
    adj = p_sorted .* m ./ (1:m)'; for i=m-1:-1:1, adj(i)=min(adj(i),adj(i+1)); end
    p_FDR(ix) = min(adj,1);
end

% === Round interaction summary ===
F_2       = round(int_F, 2);
p_3       = round(int_p, 3);
pFDR_3    = round(p_FDR, 3);
eta_3     = round(int_partialEta, 3);
f_3       = round(int_cohensF, 3);
beta_4    = round(int_beta, 4);
ci_low_4  = round(int_ci_low, 4);
ci_high_4 = round(int_ci_high, 4);

InteractionSummary = table( ...
    int_ROI, F_2, int_df1, int_df2, p_3, pFDR_3, eta_3, f_3, beta_4, ci_low_4, ci_high_4, ...
    'VariableNames', {'ROI','F','df1','df2','p','p_FDR','PartialEta2','CohensF','DeltaSlope','CI_low','CI_high'});

writetable(InteractionSummary, fullfile(out_dir, 'GROUP_Interaction_Summary.csv'));

%% ======== (B) ASD-only GLM: ROI ~ Age_c ========
Age_c_ASD = Age_ASD - mean(Age_ASD,'omitnan');
ASD_within = local_within_table(roi_asd, Age_c_ASD, roi_names);
writetable(ASD_within, fullfile(out_dir, 'ASD_Within_Age.csv'));

%% ======== (C) TD-only GLM: ROI ~ Age_c ========
Age_c_TD = Age_TD - mean(Age_TD,'omitnan');
TD_within = local_within_table(roi_td, Age_c_TD, roi_names);
writetable(TD_within, fullfile(out_dir, 'TD_Within_Age.csv'));

fprintf('\n✅ Finished: results written to %s\n', out_dir);
fprintf('   ↳ Interaction summary: %s\n', fullfile(out_dir,'GROUP_Interaction_Summary.csv'));
fprintf('   ↳ Within-group (TD):  %s\n', fullfile(out_dir,'TD_Within_Age.csv'));
fprintf('   ↳ Within-group (ASD): %s\n', fullfile(out_dir,'ASD_Within_Age.csv'));

%% ======================= Local helper =======================
function T = local_within_table(Ymat, Age_c_vec, names)
% Simple regression Y ~ Age_c (per ROI)
    nR = size(Ymat,2);
    beta  = nan(nR,1);
    tstat = nan(nR,1);
    pval  = nan(nR,1);
    df    = nan(nR,1);
    peta2 = nan(nR,1);

    for rr = 1:nR
        y = Ymat(:,rr);
        mdl  = fitlm(table(Age_c_vec, y, 'VariableNames', {'Age_c','Y'}), 'Y ~ Age_c');
        c    = mdl.Coefficients;
        beta(rr)  = c{'Age_c','Estimate'};
        tstat(rr) = c{'Age_c','tStat'};
        pval(rr)  = c{'Age_c','pValue'};
        df(rr)    = mdl.DFE;
        t2        = tstat(rr)^2;
        peta2(rr) = t2 / (t2 + df(rr));
    end

    beta  = round(beta, 4);
    tstat = round(tstat, 2);
    pval  = round(pval, 3);
    peta2 = round(peta2, 3);
    df    = round(df);

    T = table(string(names(:)), beta, tstat, df, pval, peta2, ...
        'VariableNames', {'ROI','Beta_per_year','t','df','p','PartialEta2'});
end
