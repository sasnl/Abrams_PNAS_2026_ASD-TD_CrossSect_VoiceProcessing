function results = roi_glm_runner(asd_age_path, asd_mat_path, td_age_path, td_mat_path, out_dir)
% Runs the ROI-level GLMs and returns interaction & slope stats per ROI.

% --- your full script here ---

%% ================== ROI-LEVEL GLMs: ASD + TD (No SC) ==================
% (A) Between-group:  ROI ~ Group * Age_c
% (B) ASD-only:       ROI ~ Age_c
% (C) TD-only:        ROI ~ Age_c


% %% ======== Paths: ASD ========
% asd_age_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt';
% asd_mat_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Figure_Generation/Scatterplots/OtherEnv_Scatters/ASDonly_n39_SigLevels_Age_OtherEnv.mat';
% 
% %% ======== Paths: TD ========
% td_age_path  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/TD_selected_age_scan.txt';
% td_mat_path  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Figure_Generation/Scatterplots/OtherEnv_Scatters/TDonly_n40_SigLevels_Age_OtherEnv.mat'

%% ======== Output directory ========
out_dir = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_Results/TD_ASD_ROI_SigLevel_GLM_n40_n39/Results/Simulation_Results';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

%% ======== Load ASD data ========
Age_ASD = readmatrix(asd_age_path); Age_ASD = Age_ASD(:);

S_asd = load(asd_mat_path);
assert(isfield(S_asd,'roi_con'), 'ASD MAT missing roi_con.');
roi_asd = S_asd.roi_con;
if isvector(roi_asd), roi_asd = roi_asd(:); end
if size(roi_asd,1) ~= numel(Age_ASD) && size(roi_asd,2) == numel(Age_ASD)
    roi_asd = roi_asd.';
end
assert(size(roi_asd,1) == numel(Age_ASD), 'ASD roi_con rows != #ASD subjects.');

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
if size(roi_td,1) ~= numel(Age_TD) && size(roi_td,2) == numel(Age_TD)
    roi_td = roi_td.';
end
assert(size(roi_td,1) == numel(Age_TD), 'TD roi_con rows != #TD subjects.');
assert(size(roi_td,2) == numel(roi_names), 'ASD and TD ROI column counts differ.');

%% ======== Build combined table for Group model ========
nA = numel(Age_ASD);
nT = numel(Age_TD);
Group = [repmat(categorical("ASD"), nA, 1); repmat(categorical("TD"), nT, 1)];
Age   = [Age_ASD; Age_TD];
Age_c = Age - mean(Age,'omitnan');
roi_all = [roi_asd; roi_td];

T_all = table(Group, Age_c);
nROIs = size(roi_all,2);
for r = 1:nROIs
    T_all.(roi_names{r}) = roi_all(:,r);
end

%% ======== (A) Between-group GLM: ROI ~ Group * Age_c ========
coef_group  = cell(nROIs,1);
anova_group = cell(nROIs,1);

% Preallocate summary of the Group×Age_c interaction across ROIs
int_ROI        = strings(nROIs,1);
int_F          = nan(nROIs,1);
int_df1        = nan(nROIs,1);
int_df2        = nan(nROIs,1);
int_p          = nan(nROIs,1);
int_partialEta = nan(nROIs,1);
int_cohensF    = nan(nROIs,1);

for r = 1:nROIs
    yname = roi_names{r};

    % Fit model; ensure Group is categorical
    mdl = fitlm(T_all, sprintf('%s ~ Group*Age_c', yname), 'CategoricalVars','Group');

    % Save coefficients
    coef_tbl = mdl.Coefficients;
    coef_group{r} = coef_tbl;
    writetable(coef_tbl, fullfile(out_dir, sprintf('GROUP_%s_Coeffs.csv', yname)));

    % ANOVA (Type I) summary (kept as in your original for continuity)
    A  = anova(mdl, 'summary');
    ss = A.SumSq;   if iscell(ss), ss = cell2mat(ss); end
    Fv = A.F;       if iscell(Fv), Fv = cell2mat(Fv); end
    pv = A.pValue;  if iscell(pv), pv = cell2mat(pv); end

    rows = A.Properties.RowNames;
    isIntercept = strcmpi(rows,'(Intercept)');
    isErrorLike = strcmpi(rows,'Error') | strcmpi(rows,'Residual') | contains(rows,'Error','IgnoreCase',true) | isnan(Fv);

    keep  = ~(isIntercept | isErrorLike);
    SSerr = sum(ss(isErrorLike));
    eta   = ss(keep) ./ (ss(keep) + SSerr);

    terms = rows(keep);
    A_short = table(terms, Fv(keep), pv(keep), eta, 'VariableNames', {'Term','F','p','PartialEta2'});
    anova_group{r} = A_short;
    writetable(A_short, fullfile(out_dir, sprintf('GROUP_%s_ANOVA.csv', yname)));

    % === Cohen's f for Group×Age_c interaction (joint F-test via coefTest) ===
    coefNames  = mdl.CoefficientNames;  % e.g., {'(Intercept)','Group_TD','Age_c','Group_TD:Age_c'}
    isInteract = contains(coefNames,'Group') & contains(coefNames,'Age_c');
    idxCols    = find(isInteract);
    P          = numel(coefNames);
    K          = numel(idxCols);

    if K > 0
        C = zeros(K, P);
        for k = 1:K, C(k, idxCols(k)) = 1; end

        % coefTest returns [p, F, df1]; error df2 is mdl.DFE
        [pInt, Fint, df1] = coefTest(mdl, C);
        df2 = mdl.DFE;

        % Convert to partial eta^2 and Cohen's f
        partialEta2 = (Fint * df1) / (Fint * df1 + df2);
        cohensF     = sqrt(partialEta2 / (1 - partialEta2));

        int_ROI(r)        = string(yname);
        int_F(r)          = Fint;
        int_df1(r)        = df1;
        int_df2(r)        = df2;
        int_p(r)          = pInt;
        int_partialEta(r) = partialEta2;
        int_cohensF(r)    = cohensF;
    else
        warning('No Group×Age_c interaction columns detected for ROI %s.', yname);
    end

end

% Save per-ROI detailed outputs
save(fullfile(out_dir, 'GROUP_AllROIs.mat'), 'roi_names','coef_group','anova_group');

% Save concise interaction summary across ROIs
InteractionSummary = table(int_ROI, int_F, int_df1, int_df2, int_p, int_partialEta, int_cohensF, ...
    'VariableNames', {'ROI','F','df1','df2','p','PartialEta2','CohensF'});
writetable(InteractionSummary, fullfile(out_dir, 'GROUP_Interaction_Summary.csv'));

%% ======== (B) ASD-only GLM: ROI ~ Age_c ========
Age_c_ASD = Age_ASD - mean(Age_ASD,'omitnan');
coef_asd  = cell(nROIs,1);
anova_asd = cell(nROIs,1);

for r = 1:nROIs
    y = roi_asd(:,r);
    T_asd = table(Age_c_ASD, y, 'VariableNames', {'Age_c','Y'});
    mdl   = fitlm(T_asd, 'Y ~ Age_c');

    coef_tbl = mdl.Coefficients;
    coef_asd{r} = coef_tbl;
    writetable(coef_tbl, fullfile(out_dir, sprintf('ASD_%s_Coeffs.csv', roi_names{r})));

    A  = anova(mdl, 'summary');
    ss = A.SumSq; if iscell(ss), ss = cell2mat(ss); end
    Fv = A.F; if iscell(Fv), Fv = cell2mat(Fv); end
    pv = A.pValue; if iscell(pv), pv = cell2mat(pv); end

    rows = A.Properties.RowNames;
    isIntercept = strcmpi(rows,'(Intercept)');
    isErrorLike = strcmpi(rows,'Error') | strcmpi(rows,'Residual') | contains(rows,'Error','IgnoreCase',true) | isnan(Fv);

    keep  = ~(isIntercept | isErrorLike);
    SSerr = sum(ss(isErrorLike));
    eta   = ss(keep) ./ (ss(keep) + SSerr);

    terms = rows(keep);
    A_short = table(terms, Fv(keep), pv(keep), eta, 'VariableNames', {'Term','F','p','PartialEta2'});
    anova_asd{r} = A_short;
    writetable(A_short, fullfile(out_dir, sprintf('ASD_%s_ANOVA.csv', roi_names{r})));
end
save(fullfile(out_dir, 'ASD_AllROIs.mat'), 'roi_names','coef_asd','anova_asd');

%% ======== (C) TD-only GLM: ROI ~ Age_c ========
Age_c_TD = Age_TD - mean(Age_TD,'omitnan');
coef_td  = cell(nROIs,1);
anova_td = cell(nROIs,1);

for r = 1:nROIs
    y = roi_td(:,r);
    T_td = table(Age_c_TD, y, 'VariableNames', {'Age_c','Y'});
    mdl  = fitlm(T_td, 'Y ~ Age_c');

    coef_tbl = mdl.Coefficients;
    coef_td{r} = coef_tbl;
    writetable(coef_tbl, fullfile(out_dir, sprintf('TD_%s_Coeffs.csv', roi_names{r})));

    A  = anova(mdl, 'summary');
    ss = A.SumSq; if iscell(ss), ss = cell2mat(ss); end
    Fv = A.F; if iscell(Fv), Fv = cell2mat(Fv); end
    pv = A.pValue; if iscell(pv), pv = cell2mat(pv); end

    rows = A.Properties.RowNames;
    isIntercept = strcmpi(rows,'(Intercept)');
    isErrorLike = strcmpi(rows,'Error') | strcmpi(rows,'Residual') | contains(rows,'Error','IgnoreCase',true) | isnan(Fv);

    keep  = ~(isIntercept | isErrorLike);
    SSerr = sum(ss(isErrorLike));
    eta   = ss(keep) ./ (ss(keep) + SSerr);

    terms = rows(keep);
    A_short = table(terms, Fv(keep), pv(keep), eta, 'VariableNames', {'Term','F','p','PartialEta2'});
    anova_td{r} = A_short;
    writetable(A_short, fullfile(out_dir, sprintf('TD_%s_ANOVA.csv', roi_names{r})));
end
save(fullfile(out_dir, 'TD_AllROIs.mat'), 'roi_names','coef_td','anova_td');

% fprintf('\n✅ Finished: results written to %s\n', out_dir);
% fprintf('   ↳ Interaction summary: %s\n', fullfile(out_dir,'GROUP_Interaction_Summary.csv'));

% Replace the final fprintfs with this:
% nROIs should already be defined as size(roi_asd,2) or numel(roi_names)
results = struct();                      % <-- scalar struct
results.ROI       = roi_names(:);        % cellstr column
results.int_p     = int_p(:);            % vector
results.ASD_age_b = nan(nROIs,1);
results.ASD_age_p = nan(nROIs,1);
results.TD_age_b  = nan(nROIs,1);
results.TD_age_p  = nan(nROIs,1);

for r = 1:nROIs
    % ASD coeffs table for ROI r
    ct_asd = coef_asd{r};
    rowA   = strcmp(ct_asd.Properties.RowNames, 'Age_c');
    results.ASD_age_b(r) = ct_asd.Estimate(rowA);
    results.ASD_age_p(r) = ct_asd.pValue(rowA);

    % TD coeffs table for ROI r
    ct_td = coef_td{r};
    rowT  = strcmp(ct_td.Properties.RowNames, 'Age_c');
    results.TD_age_b(r) = ct_td.Estimate(rowT);
    results.TD_age_p(r) = ct_td.pValue(rowT);
end


