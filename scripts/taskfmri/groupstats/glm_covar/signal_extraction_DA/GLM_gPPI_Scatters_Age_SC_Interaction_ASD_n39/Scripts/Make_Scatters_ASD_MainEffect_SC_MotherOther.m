%% ASD-only: Main effect of Social Communication (SC) per ROI (legacy panel style, dynamic Y)
% - Full model per ROI: y ~ Age_c * SC_c
% - Report conditional main effect of SC (at mean Age)
% - Outputs: beta_SC, SE, t(df), p, partial R2, Cohen f^2 & f, ΔR^2, F_change, p_change, standardized beta
% - Figures -> Scatters/GLM_Scatters; CSV -> Results
% - Legacy plot look: small square panel, purple 'x' markers, thick gray regression line
% - Dynamic Y-limits (include all points/line). X-limits fixed to [4 18].

clearvars; close all; clc;

%% ===== Paths =====
results_dir = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Results';
fig_dir     = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Scatters/GLM_Scatters';
data_dir    = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Data';

ASD_save_fname = 'ASDonly_n39_GLM_SigLev_SC_MainEffect_MothOth';  % contains roi_con, roi_name
age_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt';
sc_path  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_n39_ADOS_SocAffect.txt';

if ~exist(results_dir,'dir'), mkdir(results_dir); end
if ~exist(fig_dir,'dir'),     mkdir(fig_dir);     end

%% ===== Load data =====
Age = readmatrix(age_path); Age = Age(:);
SC  = readmatrix(sc_path);  SC  = SC(:);      % ADOS-SA (higher = worse)

S = load(fullfile(data_dir, ASD_save_fname), 'roi_con','roi_name');
if ~isfield(S,'roi_con'), error('roi_con not found in MAT file'); end
roi_con  = S.roi_con;                          % nSubj x nROIs
if isfield(S,'roi_name'), roi_name = S.roi_name; else
    roi_name = arrayfun(@(k)sprintf('ROI %d',k), 1:size(roi_con,2), 'UniformOutput', false);
end
nROIs = size(roi_con,2);

%% ===== Colors (cycle your legacy set) =====
base_colors = [255 0 0; 128 0 128; 0 63 95] ./ 255;   % red, purple, blue-gray
color_plots = base_colors(1+mod(0:nROIs-1, size(base_colors,1)), :);

%% ===== Style (legacy look) =====
MARK_LW = 2;                    % thickness of 'x' strokes
LINE_LW = 3;                    % regression line thickness
LINE_CLR = [0.5 0.5 0.5];       % gray line
FIG_POS = [150 150 120 120];    % tiny square panel

%% ===== Accumulator =====
rows = {};   % cell rows for table

%% ===== Loop ROIs =====
for r = 1:nROIs
    y = roi_con(:,r);
    this_label = roi_name{min(r,numel(roi_name))};

    % Center predictors
    Age_mu = mean(Age);  SC_mu = mean(SC);
    Age_c = Age - Age_mu;
    SC_c  = SC  - SC_mu;

    % ---- Full model: y ~ Age_c * SC_c
    T = table(Age_c, SC_c, y, 'VariableNames', {'Age_c','SC_c','y'});
    mdl = fitlm(T, 'y ~ Age_c * SC_c');

    % ---- Reduced model (drop SC main; keep Age & interaction)
    mdl_red = fitlm(T, 'y ~ Age_c + Age_c:SC_c');

    % ---- Extract SC stats
    CT = mdl.Coefficients;
    bSC  = CT{'SC_c','Estimate'};
    seSC = CT{'SC_c','SE'};
    if ismember('tStat', CT.Properties.VariableNames), tSC = CT{'SC_c','tStat'}; else, tSC = CT{'SC_c','t'}; end
    if ismember('pValue', CT.Properties.VariableNames), pSC = CT{'SC_c','pValue'}; else, pSC = CT{'SC_c','p'}; end
    df = mdl.DFE;

    % ---- Effect sizes
    partialR2_SC = (tSC.^2) / (tSC.^2 + df);   % unique to SC
    dR2_SC = mdl.Rsquared.Ordinary - mdl_red.Rsquared.Ordinary;
    f2_SC  = (tSC.^2) / df;
    f_SC   = sqrt(f2_SC);

    % ---- Nested F-change for adding SC
    Fchg = NaN; pchg = NaN;
    try
        cmp = compare(mdl_red, mdl);
        if ismember('F', cmp.Properties.VariableNames), Fchg = cmp.F(2);
        elseif ismember('FStat', cmp.Properties.VariableNames), Fchg = cmp.FStat(2); end
        if ismember('pValue', cmp.Properties.VariableNames), pchg = cmp.pValue(2);
        elseif ismember('p', cmp.Properties.VariableNames), pchg = cmp.p(2); end
    catch
        try
            A2 = anova(mdl_red, mdl);
            if ismember('F', A2.Properties.VariableNames), Fchg = A2.F(end); else, Fchg = A2.FStat(end); end
            if ismember('pValue', A2.Properties.VariableNames), pchg = A2.pValue(end); else, pchg = A2.p(end); end
        catch
            SSEr = mdl_red.SSE;  DFr = mdl_red.DFE;
            SSEf = mdl.SSE;      DFf = mdl.DFE;
            df1  = DFr - DFf;    df2 = DFf;
            Fchg = ((SSEr - SSEf)/df1) / (SSEf/df2);
            pchg = 1 - fcdf(Fchg, df1, df2);
        end
    end

    % ---- Standardized beta for SC (optional)
    y_z    = zscore(y);
    Age_z  = zscore(Age);
    SC_z   = zscore(SC);
    Tz     = table(Age_z, SC_z, y_z, 'VariableNames', {'Age_z','SC_z','y_z'});
    mdl_z  = fitlm(Tz, 'y_z ~ Age_z * SC_z');
    betaSC_std = mdl_z.Coefficients{'SC_z','Estimate'};

    % ---- R^2
    R2   = mdl.Rsquared.Ordinary;
    R2a  = mdl.Rsquared.Adjusted;

    % ---- Print summary (unchanged)
    fprintf('\n%s (SC main effect | at mean Age)\n', this_label);
    fprintf('  beta_SC = %.4f, SE = %.4f, t(%d) = %.2f, p = %.4g\n', bSC, seSC, df, tSC, pSC);
    fprintf('  partial R^2 = %.3f, Cohen f^2 = %.3f (f = %.3f), ΔR^2 = %.3f, F_change = %.2f, p_change = %.4g\n', ...
        partialR2_SC, f2_SC, f_SC, dR2_SC, Fchg, pchg);

    % ======== PLOT (legacy look w/ dynamic Y; X fixed to [4 18]) ========
    figure('Color','w'); hold on;

    % points as 'x' with thick strokes (purple, or cycled color)
    plot(SC, y, 'x', ...
        'Color', color_plots(r,:), ...
        'LineWidth', MARK_LW, ...
        'MarkerSize', 6);

    % regression line (predicted at Age_c = 0), thick gray
    sc_grid = linspace(min(SC), max(SC), 200)';  sc_c_grid = sc_grid - SC_mu;
    age_c_0 = zeros(size(sc_c_grid));
    yhat    = predict(mdl, table(age_c_0, sc_c_grid, 'VariableNames', {'Age_c','SC_c'}));
    plot(sc_grid, yhat, '-', 'Color', LINE_CLR, 'LineWidth', LINE_LW);

    % X look (fixed) and ticks
    xlim([4 18]);                     % << requested change
    set(gca,'XTick',[5 10 15]);       % sparse ticks (keeps the legacy feel)

    % Dynamic Y limits: include all data + fitted line with padding
    y_all = [y; yhat];
    yrng  = range(y_all);
    y_pad = max(0.10*yrng, 0.10);     % at least a small pad
    ylo   = min(y_all) - y_pad;
    yhi   = max(y_all) + y_pad;
    ylim([ylo, yhi]);

    % Prefer integer-ish ticks if span reasonable; otherwise ~5 ticks
    ytick_min = ceil(ylo);
    ytick_max = floor(yhi);
    if ytick_max >= ytick_min && (ytick_max - ytick_min) <= 8
        yticks(ytick_min:ytick_max);
    else
        yticks(linspace(ylo, yhi, 5));
    end

    set(gca, 'TickDir','out', 'XColor','k', 'YColor','k', 'FontSize',12, 'LineWidth',1);
    box off; axis square;                % small square panel, no labels/title
    set(gcf, 'Position', FIG_POS);

    % Save high-res PNG
    safe_label = regexprep(this_label, '[^\w\-]+', '_');
    print(fullfile(fig_dir, sprintf('ASD_SCmaineffect_%s.png', safe_label)), '-dpng', '-r600');
    % ====================================

    % ---- Gather row (17 numbers)
    vals = NaN(1, 17);
    vals(1)  = height(T);       % n
    vals(2)  = R2;              % R2
    vals(3)  = R2a;             % R2_adj
    vals(4)  = bSC;             % b_SC
    vals(5)  = seSC;            % se_SC
    vals(6)  = tSC;             % t_SC
    vals(7)  = df;              % df
    vals(8)  = pSC;             % p_SC
    vals(9)  = partialR2_SC;    % partial R^2
    vals(10) = f2_SC;           % Cohen f^2
    vals(11) = sqrt(f2_SC);     % Cohen f
    vals(12) = dR2_SC;          % ΔR^2 adding SC
    vals(13) = Fchg;            % F_change
    vals(14) = pchg;            % p_change
    vals(15) = betaSC_std;      % standardized beta
    vals(16) = Age_mu;          % Age mean
    vals(17) = SC_mu;           % SC mean

    rows(end+1,:) = [{this_label}, num2cell(vals)];
end

%% ===== Build table, FDR for SC p-values, write CSV =====
varNames = {'ROI','n','R2','R2_adj', ...
            'b_SC','se_SC','t_SC','df','p_SC', ...
            'partial_R2_SC','cohen_f2_SC','cohen_f_SC', ...
            'dR2_add_SC','F_change_SC','p_change_SC', ...
            'beta_SC_std','Age_mean','SC_mean'};
Tout = cell2table(rows,'VariableNames',varNames);

% Benjamini–Hochberg (BH) q-values for p_SC (inline)
p = Tout.p_SC; p = p(:);
m = numel(p);
[ps, idx] = sort(p);
ranks = (1:m)';
qtemp = ps .* m ./ ranks;
for i = m-1:-1:1
    qtemp(i) = min(qtemp(i), qtemp(i+1));
end
q = zeros(m,1);
q(idx) = min(qtemp, 1);
Tout.q_SC = q;

% Save CSV
out_csv = fullfile(results_dir, 'ASD_SC_MainEffect_ROI_stats.csv');
writetable(Tout, out_csv);
fprintf('\nWrote CSV to: %s\n', out_csv);
