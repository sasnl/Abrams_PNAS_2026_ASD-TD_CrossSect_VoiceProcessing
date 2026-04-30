%% ASD-only gPPI Age x Social Communication (SC) follow-ups (Right pSTS seed; Option A)
% - Model uses ADOS-SA (higher = worse) as-is
% - Outputs are Ability-only (no impairment-labeled results in CSV)
%       Ability 25th ≡ ADOS-SA 75th (low ability)   -> red
%       Ability 75th ≡ ADOS-SA 25th (high ability)  -> blue
% - Figures -> Scatters/gPPI_Scatters; CSV -> Results (ABILITYONLY schema)

close all; clear; clc

%% ===== Paths =====
age_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt';
sc_path  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_n39_ADOS_SocAffect.txt';
mat_path = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Data/ASDonly_n39_gPPI_SigLev_MothOth_R_pSTS_Age_SC_Int_pos.mat';

save_dir_results = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Results';
save_dir_figs    = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Scatters/gPPI_Scatters';

if ~exist(save_dir_results, 'dir'), mkdir(save_dir_results); end
if ~exist(save_dir_figs,    'dir'), mkdir(save_dir_figs);    end

%% ===== Load data =====
Age = readmatrix(age_path); Age = Age(:);
SC  = readmatrix(sc_path);  SC  = SC(:);    % ADOS-SA (higher = worse)

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

%% ===== Style (plots) =====
CLR.lo  = [0.95 0.25 0.15];   % red (Low ability; Ability 25th ≡ ADOS 75th)
CLR.hi  = [0.00 0.60 1.00];   % blue (High ability; Ability 75th ≡ ADOS 25th)
CLR.pts = [0.7 0.7 0.7];
MSZ = 70; LW = 2.75; EDLW = 0.6; ALPH = 0.20;

%% ===== Accumulator =====
rows = [];

%% ===== Loop over ROIs =====
nROIs = size(roi_con, 2);
for r = 1:nROIs
    y = roi_con(:, r);                       % gPPI contrast (NF − Mother)
    this_label = roi_names{min(r, numel(roi_names))};

    % Center predictors
    Age_mu = mean(Age);
    SC_mu  = mean(SC);                       % ADOS-SA mean
    Age_c  = Age - Age_mu;
    SC_c   = SC  - SC_mu;

    % Fit model with interaction: gPPI ~ Age_c * SC_c  (ADOS-SA space; Ability reported)
    T = table(Age_c, SC_c, y, 'VariableNames', {'Age_c','SC_c','gPPI'});
    mdl = fitlm(T, 'gPPI ~ Age_c * SC_c');

    %% Percentiles and Ability mapping (labels only)
    sc_p25_ADOS = prctile(SC, 25);
    sc_p75_ADOS = prctile(SC, 75);
    sc25_c_ADOS = sc_p25_ADOS - SC_mu;
    sc75_c_ADOS = sc_p75_ADOS - SC_mu;

    % Ability labels:
    % Ability25 ≡ ADOS-SA75 (low ability); Ability75 ≡ ADOS-SA25 (high ability)
    ab_p25 = sc_p75_ADOS;  ab25_c = sc75_c_ADOS;  % low ability
    ab_p75 = sc_p25_ADOS;  ab75_c = sc25_c_ADOS;  % high ability

    %% Predictions for plot
    xgrid_raw = linspace(7, 17, 200)';        % adjust if needed
    xgrid_c   = xgrid_raw - Age_mu;

    new_lowAb  = table(xgrid_c, repmat(ab25_c, size(xgrid_c)), 'VariableNames', {'Age_c','SC_c'});
    new_highAb = table(xgrid_c, repmat(ab75_c, size(xgrid_c)), 'VariableNames', {'Age_c','SC_c'});

    [yhat_low,  yci_low]  = predict(mdl, new_lowAb,  'Prediction','curve');
    [yhat_high, yci_high] = predict(mdl, new_highAb, 'Prediction','curve');

    %% Plot
    figure('Color','w'); hold on;
    set(gca,'LineWidth',1.5,'FontSize',18);
    box off; grid off;

    scatter(Age, y, MSZ, 's', ...
        'MarkerFaceColor', CLR.pts, 'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', 0.65, 'MarkerEdgeAlpha', 0.25, 'LineWidth', EDLW);

    fill([xgrid_raw; flipud(xgrid_raw)], [yci_low(:,1);  flipud(yci_low(:,2))],  CLR.lo, 'FaceAlpha', ALPH, 'EdgeColor','none');
    plot(xgrid_raw, yhat_low,  '-', 'Color', CLR.lo, 'LineWidth', LW);

    fill([xgrid_raw; flipud(xgrid_raw)], [yci_high(:,1); flipud(yci_high(:,2))], CLR.hi, 'FaceAlpha', ALPH, 'EdgeColor','none');
    plot(xgrid_raw, yhat_high, '-', 'Color', CLR.hi, 'LineWidth', LW);

    xlim([7 17]); xticks([8 10 12 14 16]);
    % ylabel('NF voices - Mother''s voice (β)');
    set(gca,'TickDir','out');
    set(gcf, 'Position', [440 440 250 250]);

    %% Simple slopes (compute internally; report only Ability slopes)
    b  = mdl.Coefficients.Estimate;
    C  = mdl.CoefficientCovariance;
    df = mdl.DFE;
    names = mdl.CoefficientNames;

    bA  = b(strcmp(names,'Age_c'));
    bAS = b(strcmp(names,'Age_c:SC_c'));

    % Internal SC-percentile slopes (to derive Ability)
    L25 = zeros(1,numel(b)); L25(strcmp(names,'Age_c')) = 1; L25(strcmp(names,'Age_c:SC_c')) = sc25_c_ADOS;
    L75 = zeros(1,numel(b)); L75(strcmp(names,'Age_c')) = 1; L75(strcmp(names,'Age_c:SC_c')) = sc75_c_ADOS;

    slope_SC25 = bA + bAS*sc25_c_ADOS;  se_SC25 = sqrt(L25*C*L25');  t_SC25 = slope_SC25/se_SC25;  p_SC25 = 2*tcdf(-abs(t_SC25), df);
    slope_SC75 = bA + bAS*sc75_c_ADOS;  se_SC75 = sqrt(L75*C*L75');  t_SC75 = slope_SC75/se_SC75;  p_SC75 = 2*tcdf(-abs(t_SC75), df);

    % Ability-labeled (reported)
    slope_Ab25 = slope_SC75;  se_Ab25 = se_SC75;  t_Ab25 = t_SC75;  p_Ab25 = p_SC75;   % low ability
    slope_Ab75 = slope_SC25;  se_Ab75 = se_SC25;  t_Ab75 = t_SC25;  p_Ab75 = p_SC25;   % high ability

    %% Interaction summary
    CT  = mdl.Coefficients;
    bi  = CT{'Age_c:SC_c','Estimate'};
    sei = CT{'Age_c:SC_c','SE'};
    if ismember('tStat', CT.Properties.VariableNames), ti = CT{'Age_c:SC_c','tStat'}; else, ti = CT{'Age_c:SC_c','t'}; end
    if ismember('pValue', CT.Properties.VariableNames), pi = CT{'Age_c:SC_c','pValue'}; else, pi = CT{'Age_c:SC_c','p'}; end

    fprintf('\n%s (Right pSTS gPPI)\n', this_label);
    fprintf('  Interaction β(Age×SC[ADOS-SA])=%.4f, SE=%.4f, t(%d)=%.2f, p=%.4g\n', bi, sei, df, ti, pi);
    fprintf('  Ability mapping: Ability25 ≡ ADOS-SA75 (%.2f), Ability75 ≡ ADOS-SA25 (%.2f)\n', sc_p75_ADOS, sc_p25_ADOS);
    fprintf('  Simple slope at Ability 25th (low ability):  slope = %.4f, SE = %.4f, t(%d) = %.2f, p = %.4g\n', ...
        slope_Ab25, se_Ab25, df, t_Ab25, p_Ab25);
    fprintf('  Simple slope at Ability 75th (high ability): slope = %.4f, SE = %.4f, t(%d) = %.2f, p = %.4g\n', ...
        slope_Ab75, se_Ab75, df, t_Ab75, p_Ab75);

    %% Save figures
    safe_label = regexprep(this_label, '[^\w\-]+', '_');
    print(gcf, fullfile(save_dir_figs, sprintf('RightpSTS_gPPI_Age_SCsimpleslopes_%s.png', safe_label)), '-dpng',  '-r300');
    print(gcf, fullfile(save_dir_figs, sprintf('RightpSTS_gPPI_Age_SCsimpleslopes_%s.tif', safe_label)),  '-dtiff', '-r300');
    savefig(     fullfile(save_dir_figs, sprintf('RightpSTS_gPPI_Age_SCsimpleslopes_%s.fig', safe_label)));
    % close(gcf);

    %% Model fit + ΔR² + nested F-change
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
            error('p column not found in compare() output.');
        end
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
    fprintf('  R^2=%.3f (adj=%.3f); ΔR^2=%.3f; F_change=%.2f, p_change=%.4g\n', ...
        mdl.Rsquared.Ordinary, mdl.Rsquared.Adjusted, dR2, Fchg, pchg);

    %% Collect row for CSV (Ability-only; explicit scalarizing)
    % Main effects
    bAge  = CT{'Age_c','Estimate'};   seAge = CT{'Age_c','SE'};
    if ismember('tStat', CT.Properties.VariableNames), tAge = CT{'Age_c','tStat'}; else, tAge = CT{'Age_c','t'}; end
    if ismember('pValue', CT.Properties.VariableNames), pAge = CT{'Age_c','pValue'}; else, pAge = CT{'Age_c','p'}; end

    bSC   = CT{'SC_c','Estimate'};    seSC  = CT{'SC_c','SE'};
    if ismember('tStat', CT.Properties.VariableNames), tSC = CT{'SC_c','tStat'}; else, tSC = CT{'SC_c','t'}; end
    if ismember('pValue', CT.Properties.VariableNames), pSC = CT{'SC_c','pValue'}; else, pSC = CT{'SC_c','p'}; end

    vals = num2cell([ ...
        scalar(height(T)), scalar(mdl.Rsquared.Ordinary), scalar(mdl.Rsquared.Adjusted), scalar(dR2), scalar(Fchg), scalar(pchg), ...
        scalar(bAge), scalar(seAge), scalar(tAge), scalar(pAge), scalar(bSC), scalar(seSC), scalar(tSC), scalar(pSC), ...
        scalar(bi), scalar(sei), scalar(ti), scalar(pi), ...
        scalar(slope_Ab25), scalar(se_Ab25), scalar(t_Ab25), scalar(p_Ab25), ...
        scalar(slope_Ab75), scalar(se_Ab75), scalar(t_Ab75), scalar(p_Ab75), ...
        scalar(Age_mu), scalar(ab_p25), scalar(ab_p75) ...
        ]);

    row = [{this_label}, vals];
    if isempty(rows), rows = cell(0, numel(row)); end
    if size(rows,2) ~= numel(row)
        error('Row width mismatch: expected %d, got %d', size(rows,2), numel(row));
    end
    rows(end+1, :) = row;

end % ROI loop

%% ===== Build table, add FDR q-values, write CSV =====
% Ability-only columns (no SC25/SC75 or raw SC percentile outputs)
varNames = {'ROI','n','R2','R2_adj','dR2','F_change','p_change', ...
    'b_Age','se_Age','t_Age','p_Age', 'b_SC','se_SC','t_SC','p_SC', ...
    'b_AgeXSC','se_AgeXSC','t_AgeXSC','p_AgeXSC', ...
    'slope_Ability25','se_Ability25','t_Ability25','p_Ability25', ...
    'slope_Ability75','se_Ability75','t_Ability75','p_Ability75', ...
    'Age_mean','Ability_p25_equivADOS75','Ability_p75_equivADOS25'};

Tout = cell2table(rows,'VariableNames',varNames);

% BH-FDR on interaction p-values across ROIs (q-values)
Tout.q_AgeXSC = bh_qvalues(Tout.p_AgeXSC);

% Write CSV (distinct filename for Right pSTS seed; Ability-only)
out_csv = fullfile(save_dir_results,'ASD_AgeXSC_gPPI_RightpSTS_ROI_stats_ABILITYONLY.csv');
writetable(Tout, out_csv);
fprintf('\nWrote CSV to: %s\n', out_csv);

%% ===== Local helpers =====
function x = scalar(xin)
%SCALAR Return a 1x1 double; convert [] to NaN; unwrap tables/cells; take first element if vector.
    if istable(xin), xin = xin{1,1}; end
    if iscell(xin),  xin = xin{1};   end
    if isempty(xin)
        x = NaN;
    else
        x = double(xin(1));
    end
end

function q = bh_qvalues(p)
%BH_QVALUES Benjamini–Hochberg FDR adjusted p-values (q-values).
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
