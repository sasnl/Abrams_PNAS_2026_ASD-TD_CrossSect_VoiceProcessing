%% ASD-only Age x Social Communication (SC) ROI GLM follow-ups (Option A)
% - ADOS-SA is used as-is (higher = worse)
% - All outputs are labeled in Ability space:
%     Ability 25th = LOW ability  ≡ ADOS-SA 75th (HIGH impairment)
%     Ability 75th = HIGH ability ≡ ADOS-SA 25th (LOW impairment)
% - Contrast is flipped: NF voices − Mother's voice
% - Outputs:
%     * Figures -> GLM_Scatters
%     * CSV with model fit and Ability-based simple slopes -> Results

close all; clear; clc

%% ===== Paths =====
age_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt';
sc_path  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_n39_ADOS_SocAffect.txt';
mat_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Data/ASDonly_n39_GLM_SigLev_Age_SC_Int_MothOth.mat';

% Output paths
save_dir_results = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Results';
save_dir_figs    = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Scatters/GLM_Scatters';
if ~exist(save_dir_results, 'dir'), mkdir(save_dir_results); end
if ~exist(save_dir_figs,    'dir'), mkdir(save_dir_figs);    end

%% ===== Load data =====
Age = readmatrix(age_path); Age = Age(:);
SC  = readmatrix(sc_path);  SC  = SC(:);    % ADOS-SA: higher = worse

S = load(mat_path);
if ~isfield(S,'roi_con'), error('Field "roi_con" not found in MAT file.'); end
roi_con = S.roi_con;                      % nSubj x nROIs

% >>> FLIP CONTRAST: [Mother − NF] -> [NF − Mother]
roi_con = -roi_con;
% <<< FLIP CONTRAST

% ROI names
if isfield(S,'roi_name')
    roi_names = S.roi_name;
    if isstring(roi_names), roi_names = cellstr(roi_names); end
    if ~iscell(roi_names),  roi_names = cellstr(roi_names); end
else
    roi_names = arrayfun(@(k)sprintf('ROI %d',k), 1:size(roi_con,2), 'UniformOutput', false);
end

%% ===== Plot style =====
CLR.lowAb  = [0.95 0.25 0.15];   % LOW ability (Ability 25 ≡ ADOS 75)
CLR.highAb = [0.00 0.60 1.00];   % HIGH ability (Ability 75 ≡ ADOS 25)
CLR.pts    = [0.7 0.7 0.7];
MSZ  = 70;  LW = 2.75;  EDLW = 0.6;  ALPH = 0.20;

%% ===== Accumulator for CSV rows =====
rows = [];   % width set on first pass

%% ===== Loop over ROIs =====
nROIs = size(roi_con, 2);
for r = 1:nROIs
    y = roi_con(:, r);
    this_label = roi_names{min(r, numel(roi_names))};

    % Center predictors (dataset-wide)
    Age_mu = mean(Age);
    SC_mu  = mean(SC);
    Age_c  = Age - Age_mu;
    SC_c   = SC  - SC_mu;

    % Model with interaction in ADOS-SA space
    T = table(Age_c, SC_c, y, 'VariableNames', {'Age_c','SC_c','gPPI'});
    mdl = fitlm(T, 'gPPI ~ Age_c * SC_c');

    % ----- Ability mapping (labels only; computed from ADOS-SA) -----
    sc_p25_ADOS = prctile(SC, 25);   % LOW impairment (HIGH ability)
    sc_p75_ADOS = prctile(SC, 75);   % HIGH impairment (LOW ability)

    % Ability 25 (LOW ability) ≡ ADOS-SA 75
    ab25_raw = sc_p75_ADOS;                 % raw ADOS at Ab25
    ab25_c   = ab25_raw - SC_mu;            % centered value used for contrasts

    % Ability 75 (HIGH ability) ≡ ADOS-SA 25
    ab75_raw = sc_p25_ADOS;                 % raw ADOS at Ab75
    ab75_c   = ab75_raw - SC_mu;

    % Age grid for plotting
    xgrid_raw = linspace(7, 17, 200)';      % adjust if needed
    xgrid_c   = xgrid_raw - Age_mu;

    % Predictions for LOW/HIGH ability
    new_Ab25 = table(xgrid_c, repmat(ab25_c, size(xgrid_c)), 'VariableNames', {'Age_c','SC_c'}); % LOW ability
    new_Ab75 = table(xgrid_c, repmat(ab75_c, size(xgrid_c)), 'VariableNames', {'Age_c','SC_c'}); % HIGH ability

    [yhat_Ab25, yci_Ab25] = predict(mdl, new_Ab25, 'Prediction','curve');
    [yhat_Ab75, yci_Ab75] = predict(mdl, new_Ab75, 'Prediction','curve');

    % ===== Figure =====
    figure('Color','w'); hold on;
    set(gca,'LineWidth',1.5,'FontSize',18); box off; grid off;

    scatter(Age, y, MSZ, 's', ...
        'MarkerFaceColor', CLR.pts, 'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', 0.65, 'MarkerEdgeAlpha', 0.25, 'LineWidth', EDLW);

    % LOW ability (Ability 25 ≡ ADOS 75)
    fill([xgrid_raw; flipud(xgrid_raw)], [yci_Ab25(:,1); flipud(yci_Ab25(:,2))], CLR.lowAb, 'FaceAlpha', ALPH, 'EdgeColor','none');
    plot(xgrid_raw, yhat_Ab25, '-', 'Color', CLR.lowAb,  'LineWidth', LW);

    % HIGH ability (Ability 75 ≡ ADOS 25)
    fill([xgrid_raw; flipud(xgrid_raw)], [yci_Ab75(:,1); flipud(yci_Ab75(:,2))], CLR.highAb, 'FaceAlpha', ALPH, 'EdgeColor','none');
    plot(xgrid_raw, yhat_Ab75, '-', 'Color', CLR.highAb, 'LineWidth', LW);

    xlim([7 17]); ylim([-2 3]); xticks([8 10 12 14 16]); yticks([-2 0 2]);
    set(gca,'TickDir','out');
    ylabel('NF voices − Mother''s voice (β)');
    set(gcf, 'Position', [440 440 250 250]);

    % ===== Ability simple slopes (no impairment/SC outputs) =====
    % Extract coefficients and covariance
    CT    = mdl.Coefficients;
    b     = CT.Estimate;
    COV   = mdl.CoefficientCovariance;
    names = mdl.CoefficientNames;
    df    = mdl.DFE;

    bAge = b(strcmp(names,'Age_c'));
    bInt = b(strcmp(names,'Age_c:SC_c'));

    % Contrast vectors for slope of Age at Ability 25 and 75
    L_Ab25 = zeros(1, numel(b));  L_Ab25(strcmp(names,'Age_c')) = 1;  L_Ab25(strcmp(names,'Age_c:SC_c')) = ab25_c;
    L_Ab75 = zeros(1, numel(b));  L_Ab75(strcmp(names,'Age_c')) = 1;  L_Ab75(strcmp(names,'Age_c:SC_c')) = ab75_c;

    slope_Ability25 = bAge + bInt*ab25_c;
    se_Ability25    = sqrt(L_Ab25 * COV * L_Ab25');
    t_Ability25     = slope_Ability25 / se_Ability25;
    p_Ability25     = 2*tcdf(-abs(t_Ability25), df);

    slope_Ability75 = bAge + bInt*ab75_c;
    se_Ability75    = sqrt(L_Ab75 * COV * L_Ab75');
    t_Ability75     = slope_Ability75 / se_Ability75;
    p_Ability75     = 2*tcdf(-abs(t_Ability75), df);

    % ===== Console summary (Ability-only) =====
    bi  = CT{'Age_c:SC_c','Estimate'};
    sei = CT{'Age_c:SC_c','SE'};
    if ismember('tStat', CT.Properties.VariableNames)
        ti = CT{'Age_c:SC_c','tStat'};
    else
        ti = CT{'Age_c:SC_c','t'};
    end
    if ismember('pValue', CT.Properties.VariableNames)
        pi = CT{'Age_c:SC_c','pValue'};
    else
        pi = CT{'Age_c:SC_c','p'};
    end

    fprintf('\n%s\n', this_label);
    fprintf('  Interaction β(Age×SC[ADOS-SA])=%.4f, SE=%.4f, t(%d)=%.2f, p=%.4g\n', bi, sei, df, ti, pi);
    fprintf('  Ability anchors: Ability25 (LOW ability) ≡ ADOS-SA75 = %.2f | Ability75 (HIGH ability) ≡ ADOS-SA25 = %.2f\n', ab25_raw, ab75_raw);
    fprintf('  Simple slope at LOW ability  (Ability25): slope=%.4f, SE=%.4f, t(%d)=%.2f, p=%.4g\n', slope_Ability25, se_Ability25, df, t_Ability25, p_Ability25);
    fprintf('  Simple slope at HIGH ability (Ability75): slope=%.4f, SE=%.4f, t(%d)=%.2f, p=%.4g\n', slope_Ability75, se_Ability75, df, t_Ability75, p_Ability75);

    % ===== Save figures =====
    safe_label = regexprep(this_label, '[^\w\-]+', '_');
    print(gcf, fullfile(save_dir_figs, sprintf('GLM_Age_AbilitySlopes_%s.png', safe_label)), '-dpng',  '-r300');
    print(gcf, fullfile(save_dir_figs, sprintf('GLM_Age_AbilitySlopes_%s.tif', safe_label)),  '-dtiff', '-r300');
    savefig(     fullfile(save_dir_figs, sprintf('GLM_Age_AbilitySlopes_%s.fig', safe_label)));
    % close(gcf);

    % ===== Model fit + ΔR² and nested test (reduced excludes interaction) =====
    mdl_red = fitlm(T, 'gPPI ~ Age_c + SC_c');
    dR2  = mdl.Rsquared.Ordinary - mdl_red.Rsquared.Ordinary;

    Fchg = NaN; pchg = NaN;
    try
        cmp = compare(mdl_red, mdl);
        if ismember('F', cmp.Properties.VariableNames)
            Fchg = cmp.F(2);
        elseif ismember('FStat', cmp.Properties.VariableNames)
            Fchg = cmp.FStat(2);
        else
            error('F column not found in compare() output.');
        end
        if ismember('pValue', cmp.Properties.VariableNames)
            pchg = cmp.pValue(2);
        elseif ismember('p', cmp.Properties.VariableNames)
            pchg = cmp.p(2);
        else
            error('p-value column not found in compare() output.');
        end
    catch
        try
            A2 = anova(mdl_red, mdl);
            if ismember('F', A2.Properties.VariableNames)
                Fchg = A2.F(end);
            else
                Fchg = A2.FStat(end);
            end
            if ismember('pValue', A2.Properties.VariableNames)
                pchg = A2.pValue(end);
            else
                pchg = A2.p(end);
            end
        catch
            SSEr = mdl_red.SSE;  DFr = mdl_red.DFE;
            SSEf = mdl.SSE;      DFf = mdl.DFE;
            df1  = DFr - DFf;    df2 = DFf;
            Fchg = ((SSEr - SSEf)/df1) / (SSEf/df2);
            pchg = 1 - fcdf(Fchg, df1, df2);
        end
    end
    fprintf('  R^2=%.3f (adj=%.3f); ΔR^2=%.3f; F_change=%.2f, p_change=%.4g\n', ...
        mdl.Rsquared.Ordinary, mdl.Rsquared.Adjusted, dR2, Fchg, pchg);

    % ===== Collect row for CSV (Ability-only exports) =====
    bAge  = CT{'Age_c','Estimate'};   seAge = CT{'Age_c','SE'};
    if ismember('tStat', CT.Properties.VariableNames), tAge = CT{'Age_c','tStat'}; else, tAge = CT{'Age_c','t'}; end
    if ismember('pValue', CT.Properties.VariableNames), pAge = CT{'Age_c','pValue'}; else, pAge = CT{'Age_c','p'}; end

    bSC   = CT{'SC_c','Estimate'};    seSC  = CT{'SC_c','SE'};
    if ismember('tStat', CT.Properties.VariableNames), tSC = CT{'SC_c','tStat'}; else, tSC = CT{'SC_c','t'}; end
    if ismember('pValue', CT.Properties.VariableNames), pSC = CT{'SC_c','pValue'}; else, pSC = CT{'SC_c','p'}; end

    numeric_vals = [ ...
        height(T), mdl.Rsquared.Ordinary, mdl.Rsquared.Adjusted, dR2, Fchg, pchg, ...
        bAge, seAge, tAge, pAge, bSC, seSC, tSC, pSC, ...
        bi, sei, ti, pi, ...
        slope_Ability25, se_Ability25, t_Ability25, p_Ability25, ...
        slope_Ability75, se_Ability75, t_Ability75, p_Ability75, ...
        Age_mu, SC_mu, ab25_raw, ab75_raw ...
        ];
    row = [{this_label}, num2cell(numeric_vals)];

    if isempty(rows)
        rows = cell(0, numel(row));
    end
    if size(rows,2) ~= numel(row)
        error('Row width mismatch: expected %d, got %d', size(rows,2), numel(row));
    end
    rows(end+1, :) = row;

end % ROI loop

%% ===== Build table (Ability-only), BH-FDR on interaction p, write CSV =====
varNames = { ...
    'ROI','n','R2','R2_adj','dR2','F_change','p_change', ...
    'b_Age','se_Age','t_Age','p_Age', ...
    'b_SC','se_SC','t_SC','p_SC', ...
    'b_AgeXSC','se_AgeXSC','t_AgeXSC','p_AgeXSC', ...
    'slope_Ability25','se_Ability25','t_Ability25','p_Ability25', ...
    'slope_Ability75','se_Ability75','t_Ability75','p_Ability75', ...
    'Age_mean','SC_mean', ...
    'Ability25_equiv_ADOS75','Ability75_equiv_ADOS25' ...
    };

Tout = cell2table(rows,'VariableNames',varNames);

% BH-FDR across ROIs on the interaction term p-values
Tout.q_AgeXSC = bh_qvalues(Tout.p_AgeXSC);

% Write CSV
out_csv = fullfile(save_dir_results,'ASD_AgeXSC_ROI_stats_ABILITYONLY.csv');
writetable(Tout, out_csv);
fprintf('\nWrote CSV (Ability-only): %s\n', out_csv);

%% ===== Local function: BH q-values =====
function q = bh_qvalues(p)
% BH_QVALUES  Benjamini–Hochberg FDR adjusted p-values (q-values).
% Input:  p (vector of p-values)
% Output: q (same size, BH-adjusted)
    p = p(:);
    m = numel(p);
    [ps, idx] = sort(p);
    ranks = (1:m)';
    qtemp = ps .* m ./ ranks;
    for i = m-1:-1:1
        qtemp(i) = min(qtemp(i), qtemp(i+1));
    end
    q = zeros(m,1);
    q(idx) = min(qtemp, 1);
    q = reshape(q, size(p));
end
