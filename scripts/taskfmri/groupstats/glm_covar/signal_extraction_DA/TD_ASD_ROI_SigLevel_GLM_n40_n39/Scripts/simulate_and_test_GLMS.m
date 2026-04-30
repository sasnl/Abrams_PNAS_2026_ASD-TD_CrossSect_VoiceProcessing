function simulate_and_test_GLMS()
rng(7);  % Reproducible

% ---------- sample sizes & ages ----------
nA = 39; nT = 40;
Age_ASD = 8 + 10*rand(nA,1);  % 8–18y
Age_TD  = 8 + 10*rand(nT,1);
Age     = [Age_ASD; Age_TD];
Age_c   = Age - mean(Age,'omitnan');

Group        = [repmat(categorical("ASD"), nA,1); repmat(categorical("TD"), nT,1)];
isTD         = double(Group=="TD");

% ---------- define 5 ROI scenarios with ground truth ----------
% y = b0 + bG*TD + bA*Age_c + bInt*(TD.*Age_c) + noise
p.ROI1 = struct('b0',0, 'bG',0.0, 'bA',0.0, 'bInt',0.20, 'sigma',0.5);  % pure interaction
p.ROI2 = struct('b0',0, 'bG',0.0, 'bA',0.0, 'bInt',0.00, 'sigma',0.6);  % null
p.ROI3 = struct('b0',0, 'bG',1.0, 'bA',0.0, 'bInt',0.00, 'sigma',0.6);  % group main only
p.ROI4 = struct('b0',0, 'bG',0.0, 'bA',0.60, 'bInt',-0.60, 'sigma',0.5);% ASD-only slope
p.ROI5 = struct('b0',0, 'bG',0.0, 'bA',0.00, 'bInt',+0.60, 'sigma',0.5);% TD-only slope

roi_names = fieldnames(p);
nROIs = numel(roi_names);

% ---------- simulate ROI columns ----------
X_age  = Age_c;
X_int  = isTD .* Age_c;

Y = zeros(numel(Age), nROIs);
for r = 1:nROIs
    pr = p.(roi_names{r});
    mu = pr.b0 + pr.bG*isTD + pr.bA*X_age + pr.bInt*X_int;
    Y(:,r) = mu + pr.sigma*randn(size(mu));
end

% split back to ASD/TD matrices (subjects × ROIs)
roi_asd = Y(1:nA, :);
roi_td  = Y(nA+1:end, :);

% ---------- run the same models your script uses ----------
% Combined table (between-group model)
T_all = table(Group, Age_c);
for r = 1:nROIs, T_all.(roi_names{r}) = Y(:,r); end

% Storage
results = struct;

for r = 1:nROIs
    yname = roi_names{r};

    % (A) Between-group: ROI ~ Group * Age_c
    mdl = fitlm(T_all, sprintf('%s ~ Group*Age_c', yname), 'CategoricalVars','Group');

    % Joint F-test of interaction columns via coefTest (like your script)
    coefNames  = mdl.CoefficientNames;
    isInteract = contains(coefNames,'Group') & contains(coefNames,'Age_c');
    idxCols    = find(isInteract);
    P          = numel(coefNames);
    K          = numel(idxCols);

    pint = NaN; Fint = NaN; df1 = NaN; df2 = NaN;
    if K > 0
        C = zeros(K,P); for k = 1:K, C(k,idxCols(k)) = 1; end
        [pint, Fint, df1] = coefTest(mdl, C); %#ok<ASGLU>
        df2 = mdl.DFE;
    end

    % (B) ASD-only: Y ~ Age_c
    Age_c_ASD = Age_ASD - mean(Age_ASD,'omitnan');
    T_asd = table(Age_c_ASD, roi_asd(:,r), 'VariableNames', {'Age_c','Y'});
    mdl_asd = fitlm(T_asd, 'Y ~ Age_c');

    % (C) TD-only: Y ~ Age_c
    Age_c_TD = Age_TD - mean(Age_TD,'omitnan');
    T_td = table(Age_c_TD, roi_td(:,r), 'VariableNames', {'Age_c','Y'});
    mdl_td = fitlm(T_td, 'Y ~ Age_c');

    % Robust coefficient indexing (row name "Age_c")
    asd_b_age = mdl_asd.Coefficients{'Age_c','Estimate'};
    asd_p_age = mdl_asd.Coefficients{'Age_c','pValue'};
    td_b_age  = mdl_td.Coefficients{'Age_c','Estimate'};
    td_p_age  = mdl_td.Coefficients{'Age_c','pValue'};

    % Save key stats
    results.(yname).group_interaction_p = pint;
    results.(yname).group_interaction_F = Fint;
    results.(yname).ASD_age_p  = asd_p_age;
    results.(yname).ASD_age_b  = asd_b_age;
    results.(yname).TD_age_p   = td_p_age;
    results.(yname).TD_age_b   = td_b_age;
end

% ---------- EXPECTATIONS (ground truth → testable checks) ----------
fprintf('\n=== PASS/FAIL checks ===\n');

% ROI1: Interaction only -> interaction sig; ASD/TD slopes near 0
pass = results.ROI1.group_interaction_p < 0.01;
checkCase('ROI1 interaction-only', pass, results.ROI1);

% ROI2: Null -> interaction NOT sig; ASD/TD slopes NOT sig
pass = results.ROI2.group_interaction_p > 0.2 & ...
       results.ROI2.ASD_age_p > 0.2 & results.ROI2.TD_age_p > 0.2;
checkCase('ROI2 null', pass, results.ROI2);

% ROI3: Group main effect only -> interaction NOT sig; per-group slopes NOT sig
pass = results.ROI3.group_interaction_p > 0.2 & ...
       results.ROI3.ASD_age_p > 0.2 & results.ROI3.TD_age_p > 0.2;
checkCase('ROI3 group-main-only', pass, results.ROI3);

% ROI4: ASD-only slope -> interaction sig; ASD slope >0 and sig; TD slope ~0 and not sig
pass = results.ROI4.group_interaction_p < 0.01 & ...
       results.ROI4.ASD_age_p < 0.01 & results.ROI4.ASD_age_b > 0.2 & ...
       results.ROI4.TD_age_p > 0.1;
checkCase('ROI4 ASD-only slope', pass, results.ROI4);

% ROI5: TD-only slope -> interaction sig; TD slope >0 and sig; ASD slope ~0 and not sig
pass = results.ROI5.group_interaction_p < 0.01 & ...
       results.ROI5.TD_age_p < 0.01 & results.ROI5.TD_age_b > 0.2 & ...
       results.ROI5.ASD_age_p > 0.1;
checkCase('ROI5 TD-only slope', pass, results.ROI5);

% --------- helpers (renamed to avoid name conflicts) ----------
function checkCase(name, tf, R)
    fprintf('%-26s : %s', name, tern(tf,'PASS','FAIL'));
    if ~tf
        fprintf('  [p_int=%.3g, ASD b/p=%.3g/%.3g, TD b/p=%.3g/%.3g]', ...
            R.group_interaction_p, R.ASD_age_b, R.ASD_age_p, R.TD_age_b, R.TD_age_p);
    end
    fprintf('\n');
    if ~tf, assignin('base','last_failed',R); end
end

function s = tern(cond,a,b)
    if cond, s=a; else, s=b; end
end

end
