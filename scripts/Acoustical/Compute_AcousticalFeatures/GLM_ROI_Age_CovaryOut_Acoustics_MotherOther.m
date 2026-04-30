%% ROI GLM control: acoustics-adjusted Age×Group (LEAN SI table)
clear; clc;

%% ---- Paths (updated base: /Users/daa/Documents/Scratch/TD_ASD_CrossSectional)
base_dir   = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional';
project    = 'ASD_TD_MothersVoice_Recordings';

roi_dir    = fullfile(base_dir, project, 'Data',    'ROI_Sig_Levels');
age_dir    = fullfile(base_dir, project, 'Data',    'Sublists_Agelists');
acoust_dir = fullfile(base_dir, project, 'Results', 'Results_Praat_Acoustical_Analysis');

td_roi_sig_fname  = fullfile(roi_dir, 'TDonly_n40_SigLevels_Age_MotherOther.mat');
asd_roi_sig_fname = fullfile(roi_dir, 'ASDonly_n39_SigLevels_Age_MotherOther.mat');

td_age_path  = fullfile(age_dir, 'TD_selected_age_scan.txt');
asd_age_path = fullfile(age_dir, 'ASD_selected_age_scan_n39_ADOS.txt');

td_acoust_path  = fullfile(acoust_dir, 'Results_Praat_Acoustical_Analysis_TD_n40.mat');
asd_acoust_path = fullfile(acoust_dir, 'Results_Praat_Acoustical_Analysis_ASD_n39.mat');

out_dir = fullfile(base_dir, project, 'Results', 'Statistical_Results_ROIs_Controlled_for_Acoustics');
if ~exist(out_dir,'dir'), mkdir(out_dir); end
out_csv = fullfile(out_dir, 'GLM_MotherOth_AgeXGroup_AcousticsControl_ROI_LEAN.csv');

%% ---- Load ROI signals (and names)
load(td_roi_sig_fname);   % -> roi_con, roi_name
roi_signals_TD = roi_con; clear roi_con;

load(asd_roi_sig_fname);  % -> roi_con
roi_signals_ASD = roi_con; clear roi_con;

if ~exist('roi_name','var') || isempty(roi_name)
    roi_name = arrayfun(@(k)sprintf('ROI %d',k), 1:size(roi_signals_TD,2), 'UniformOutput', false);
elseif isstring(roi_name)
    roi_name = cellstr(roi_name);
end

%% ---- Load ages (robust to struct vs numeric)
tmpTD  = load(td_age_path);
tmpASD = load(asd_age_path);

if isstruct(tmpTD),  fns = fieldnames(tmpTD);  age_TD  = tmpTD.(fns{1});  else, age_TD  = tmpTD;  end
if isstruct(tmpASD), fns = fieldnames(tmpASD); age_ASD = tmpASD.(fns{1}); else, age_ASD = tmpASD; end

age_TD  = age_TD(:);
age_ASD = age_ASD(:);

%% ---- Load acoustics (expects headers; tolerate col_header vs col_headers)
S_TD  = load(td_acoust_path);   % mean_vals_per_mom, col_headers (or col_header)
S_ASD = load(asd_acoust_path);

td_acoust_all  = S_TD.mean_vals_per_mom;
asd_acoust_all = S_ASD.mean_vals_per_mom;

if     isfield(S_TD,'col_headers'), col_headers = S_TD.col_headers;
elseif isfield(S_TD,'col_header'),  col_headers = S_TD.col_header;
else,  error('Could not find col_headers/col_header in TD acoustics .mat');
end

need = {'pitch_mean','pitch_stdev','pitch_slope'};
[ok, idx] = ismember(need, col_headers);
assert(all(ok), 'Missing required acoustic headers: %s', strjoin(need(~ok), ', '));

acoustics_TD  = td_acoust_all(:, idx);
acoustics_ASD = asd_acoust_all(:, idx);

%% ---- Assemble data
roi_signals = [roi_signals_TD; roi_signals_ASD];           % N x R
age         = [age_TD;        age_ASD];                    % N x 1
group       = [zeros(size(age_TD)); ones(size(age_ASD))];  % 0=TD, 1=ASD
acoustics   = [acoustics_TD;  acoustics_ASD];              % N x 3

[N, R] = size(roi_signals);

% Center Age; z-score acoustics (pooled)
Age_c    = age - mean(age);
acoust_z = (acoustics - mean(acoustics,1)) ./ std(acoustics,[],1);

ac_names = {'pitch_mean_z','pitch_stdev_z','pitch_slope_z'};

%% ---- Run acoustics-adjusted model per ROI and collect lean stats
rows = {};
for r = 1:R
    y = roi_signals(:, r);

    % Build table
    T = table(y, Age_c, group, ...
        acoust_z(:,1), acoust_z(:,2), acoust_z(:,3), ...
        'VariableNames', {'y','Age_c','Group', ac_names{:}});

    % Fit: Signal ~ Age_c * Group + pitch_mean_z + pitch_stdev_z + pitch_slope_z
    rhs = sprintf('Age_c + Group + Age_c:Group + %s + %s + %s', ac_names{1}, ac_names{2}, ac_names{3});
    mdl = fitlm(T, ['y ~ ' rhs]);

    % Age×Group term
    CT = mdl.Coefficients;
    b  = CT{'Age_c:Group','Estimate'};
    se = CT{'Age_c:Group','SE'};
    if ismember('tStat', CT.Properties.VariableNames), t = CT{'Age_c:Group','tStat'}; else, t = CT{'Age_c:Group','t'}; end
    if ismember('pValue', CT.Properties.VariableNames), p = CT{'Age_c:Group','pValue'}; else, p = CT{'Age_c:Group','p'}; end
    df = mdl.DFE;

    % 95% CI, partial R^2, Cohen's f
    tcrit     = tinv(0.975, df);
    ci_lo     = b - tcrit*se;
    ci_hi     = b + tcrit*se;
    partialR2 = (t^2) / (t^2 + df);
    f         = sqrt((t^2) / df);

    rows(end+1,:) = [{roi_name{r}}, mdl.NumObservations, b, ci_lo, ci_hi, t, df, p, partialR2, f];
end

% Build table
varNames = {'ROI','N','beta_AgeXGroup','CI95_low','CI95_high','t','df','p','partial_R2','cohen_f'};
Tout = cell2table(rows, 'VariableNames', varNames);

% BH–FDR across ROIs (on p)
pvec = Tout.p; m = numel(pvec);
[ps, idxs] = sort(pvec);
ranks = (1:m)'; qtemp = ps .* m ./ ranks;
for i = m-1:-1:1, qtemp(i) = min(qtemp(i), qtemp(i+1)); end
q = zeros(m,1); q(idxs) = min(qtemp, 1);
Tout.q = q;

% Sort and save
Tout = sortrows(Tout, 'p');
writetable(Tout, out_csv);
fprintf('Wrote lean acoustics-control table to:\n  %s\n', out_csv);
