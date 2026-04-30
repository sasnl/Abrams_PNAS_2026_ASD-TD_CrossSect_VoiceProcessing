%% ASD-only: Does sex ratio vary with age? (Logistic regression)
% - Includes PIDs from ASD include CSV
% - Age from headerless TXT (aligned 1:1 with PID CSV)
% - Warn on missing; proceed with available data
clear; clc;

% ========= USER INPUTS =========
xlsxPath   = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Demographics_Analysis/td_asd_mothers_voice_behav_w_ados_adi (1).xlsx';
sheetASD   = 'ASD';

asdPIDcsv  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_PID_List_n39_ADOS.csv';
asdAgeTxt  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt'; % headerless

sexHeaderInXLS = "Gender";   % original human-readable header
pidHeaderInXLS = "PID";      % original human-readable header

% Output
outCSV = fullfile(tempdir, 'ASD_only_Sex_vs_Age_Logistic.csv');
% ===============================

fprintf('Reading ASD sheet:\n  %s\n', xlsxPath);
try
    ASD = readtable(xlsxPath, 'Sheet', sheetASD, 'PreserveVariableNames', true);
catch
    ASD = readtable(xlsxPath, 'Sheet', sheetASD);
end

% --- Find and standardize PID and Sex columns (robust to truncation) -----
ASD = stdCols_ASD_min(ASD, pidHeaderInXLS, sexHeaderInXLS);  % gives ASD.PID, ASD.Sex
ASD.PID = normalizePIDColumn(ASD.PID);

% --- Load ASD include list (normalized; order preserved) ------------------
fprintf('\nLoading ASD include list:\n  %s\n', asdPIDcsv);
asdKeep = loadPIDList(asdPIDcsv);

% Filter ASD sheet to included PIDs
missingInSheet = setdiff(asdKeep, ASD.PID);
if ~isempty(missingInSheet)
    warning('ASD PIDs in include list but NOT in ASD sheet (%d): %s', ...
        numel(missingInSheet), strjoin(missingInSheet, ', '));
end
ASD = ASD(ismember(ASD.PID, asdKeep), :);

% --- Build Age table from include list + headerless TXT ages --------------
fprintf('\nReading headerless ages from:\n  %s\n', asdAgeTxt);
ageVec = loadAgeVector_noHeader(asdAgeTxt);
if numel(ageVec) ~= numel(asdKeep)
    error('Age vector length (%d) != PID include list length (%d).', numel(ageVec), numel(asdKeep));
end
AgeTbl = table(asdKeep(:), double(ageVec(:)), 'VariableNames', {'PID','Age'});

% Merge by PID
ASD = outerjoin(ASD, AgeTbl, 'Keys','PID', 'MergeKeys', true, 'Type','left');
if ~ismember('Age', ASD.Properties.VariableNames)
    vn = string(ASD.Properties.VariableNames);
    k = find(vn == "Age_right" | contains(vn,"Age"), 1);
    if ~isempty(k), ASD.Age = ASD.(vn(k)); ASD.(vn(k)) = []; else, error('Age column not found after join'); end
end

% --- Normalize Sex; make binary outcome -----------------------------------
SexStr = upper(strtrim(string(ASD.Sex)));
SexStr = regexprep(SexStr, '^\s*MALE\s*$',   'MALE');
SexStr = regexprep(SexStr, '^\s*FEMALE\s*$', 'FEMALE');
SexStr = regexprep(SexStr, '^\s*M\s*$',      'MALE');
SexStr = regexprep(SexStr, '^\s*F\s*$',      'FEMALE');
SexStr = regexprep(SexStr, '^\s*1\s*$',      'MALE');
SexStr = regexprep(SexStr, '^\s*0\s*$',      'FEMALE');
ASD.Sex = categorical(SexStr);
ASD.SexBin = double(ASD.Sex == "MALE");  % 1=Male, 0=Female

% --- Warn about missing; proceed with available ---------------------------
missAge = isnan(ASD.Age);
missSex = ismissing(ASD.Sex) | ~(ASD.Sex=="MALE"|ASD.Sex=="FEMALE");
if any(missAge|missSex)
    warnPIDs = ASD.PID(missAge|missSex);
    warning('ASD-only logistic: excluding %d participant(s) due to missing/invalid Age or Sex: %s', ...
        numel(warnPIDs), strjoin(string(warnPIDs), ', '));
end

idx = ~missAge & ~missSex;
D = ASD(idx, {'PID','Age','Sex','SexBin'});

fprintf('\nASD-only logistic sample size: %d (excluded %d)\n', height(D), height(ASD)-height(D));

% --- Center Age for interpretability (optional) ---------------------------
D.Age_c = D.Age - mean(D.Age, 'omitnan');

% ===================== Primary model: Sex ~ Age ===========================
mdl1 = fitglm(D, 'SexBin ~ Age_c', 'Distribution','binomial');
coefs1 = mdl1.Coefficients;

B_age   = safeCoef(coefs1,"Age_c","Estimate");
SE_age  = safeCoef(coefs1,"Age_c","SE");
z_age   = B_age / max(SE_age, eps);
p_age   = safeCoef(coefs1,"Age_c","pValue");
if isnan(p_age), p_age = 2*(1 - normcdf(abs(z_age))); end

CI1 = coefCI(mdl1, 0.05);
rowAge = safeRowIndex(coefs1,"Age_c");
OR_age = NaN; OR_lo = NaN; OR_hi = NaN;
if ~isnan(rowAge)
    OR_age = exp(coefs1.Estimate(rowAge));
    OR_lo  = exp(CI1(rowAge,1));
    OR_hi  = exp(CI1(rowAge,2));
end

fprintf('\n=== ASD-only logistic: P(Male) ~ Age_c ===\n');
fprintf('Age (centered): B = %.4f, SE = %.4f, z = %.2f, p = %.4g,  OR/year = %.3f  [%.3f, %.3f]\n', ...
    B_age, SE_age, z_age, p_age, OR_age, OR_lo, OR_hi);

% ================= Optional nonlinearity: add Age^2 =======================
D.Age2_c = (D.Age_c).^2;
mdl2 = fitglm(D, 'SexBin ~ Age_c + Age2_c', 'Distribution','binomial');

% Likelihood Ratio Test: mdl1 vs mdl2
LL1 = mdl1.LogLikelihood; k1 = mdl1.NumCoefficients;
LL2 = mdl2.LogLikelihood; k2 = mdl2.NumCoefficients;
LR  = 2*(LL2 - LL1);
df  = k2 - k1;
p_LR = 1 - chi2cdf(LR, df);

B_age2  = safeCoef(mdl2.Coefficients,"Age2_c","Estimate");
SE_age2 = safeCoef(mdl2.Coefficients,"Age2_c","SE");
p_age2  = safeCoef(mdl2.Coefficients,"Age2_c","pValue");

fprintf('\n=== Nonlinearity check: add Age^2 ===\n');
fprintf('LRT (linear vs. quadratic): LR=%.3f, df=%d, p=%.4g\n', LR, df, p_LR);
fprintf('Quadratic term Age^2: B = %.4f, SE = %.4f, p = %.4g\n', B_age2, SE_age2, p_age2);

% ===================== Save compact results ================================
out = table(height(D), B_age, SE_age, z_age, p_age, OR_age, OR_lo, OR_hi, LR, df, p_LR, ...
    'VariableNames', {'N','B_Age','SE_Age','z_Age','p_Age','OR_perYear','OR_lo','OR_hi','LR_linear_vs_quad','df','p_LR'});
writetable(out, outCSV);
fprintf('\nResults written to: %s\n', outCSV);

% ============================ Helpers =====================================
function Tstd = stdCols_ASD_min(Tin, pidHuman, sexHuman)
    Tstd = Tin;
    vis = string(Tstd.Properties.VariableNames);
    if isprop(Tstd.Properties,'VariableDescriptions')
        desc = string(Tstd.Properties.VariableDescriptions);
    else
        desc = repmat("", size(vis));
    end
    pidCol = findBestMatch(vis, desc, pidHuman, 'PID');
    sexCol = findBestMatch(vis, desc, sexHuman, 'Gender');
    if pidCol ~= "", Tstd.Properties.VariableNames{strcmp(vis, pidCol)} = 'PID'; else, Tstd.PID = strings(height(Tstd),1); end
    if sexCol ~= "", Tstd.Properties.VariableNames{strcmp(vis, sexCol)} = 'Sex'; else, Tstd.Sex = strings(height(Tstd),1); end
    Tstd = Tstd(:, {'PID','Sex'});
end

function actual = findBestMatch(visNames, origNames, target1, target2)
    candidates = unique([origNames; visNames]); candidates = candidates(candidates~="");
    k = strcmpi(candidates,target1) | strcmpi(candidates,target2);
    if any(k), actual = pickVisible(visNames, candidates(k)); return; end
    k = contains(lower(candidates),lower(target1)) | contains(lower(candidates),lower(target2));
    if any(k), actual = pickVisible(visNames, candidates(k)); return; end
    clean = @(s) regexprep(lower(s),'[^a-z0-9]','');
    kc = strcmp(clean(candidates),clean(string(target1))) | strcmp(clean(candidates),clean(string(target2)));
    if any(kc), actual = pickVisible(visNames, candidates(kc)); return; end
    actual = "";
end

function actual = pickVisible(visNames, matched)
    for m = matched(:).'
        if any(strcmp(visNames,m)), actual = m; return; end
        pref = extractBefore(m, min(strlength(m),20));
        if strlength(pref)>0
            idx = startsWith(visNames,pref); if any(idx), actual = visNames(find(idx,1,'first')); return; end
        end
    end
    actual = "";
end

function keepPIDs = loadPIDList(csvPath)
    try
        Tpid = readtable(csvPath, 'PreserveVariableNames', true);
    catch
        Tpid = readtable(csvPath);
    end
    vn = string(Tpid.Properties.VariableNames);
    pidCol = find(strcmpi(vn, 'PID'), 1); if isempty(pidCol), pidCol = 1; end
    raw = Tpid.(vn(pidCol));
    keepPIDs = normalizePIDColumn(raw);
    keepPIDs = keepPIDs(:);
end

function pidStr = normalizePIDColumn(col)
    s = string(col); s = strtrim(s);
    s_digits = regexprep(s, '[^0-9]', '');
    numVals  = str2double(s_digits);
    isNum    = ~isnan(numVals) & s ~= "";
    pidStr = strings(size(s));
    pidStr(isNum)  = pad(string(round(numVals(isNum))), 4, 'left', '0');
    pidStr(~isNum) = upper(s(~isNum));
    pidStr(ismissing(pidStr)) = "";
end

function ageVec = loadAgeVector_noHeader(pathStr)
    try
        ageVec = readmatrix(pathStr);
    catch
        try
            T = readtable(pathStr, 'ReadVariableNames', false, 'Delimiter','\t'); ageVec = T{:,1};
        catch
            try
                T = readtable(pathStr, 'ReadVariableNames', false, 'Delimiter',','); ageVec = T{:,1};
            catch
                T = readtable(pathStr, 'ReadVariableNames', false, 'Delimiter',' ', 'MultipleDelimsAsOne', true); ageVec = T{:,1};
            end
        end
    end
    ageVec = double(ageVec(:));
end

function val = safeCoef(coefTbl, name, field)
    rows = string(coefTbl.Properties.RowNames);
    exact = rows==string(name); if any(exact), val = coefTbl.(field)(find(exact,1)); return; end
    cie = strcmpi(rows,string(name)); if any(cie), val = coefTbl.(field)(find(cie,1)); return; end
    % interaction-order fallback not needed here
    val = NaN;
end

function idx = safeRowIndex(coefTbl, name)
    rows = string(coefTbl.Properties.RowNames);
    exact = rows==string(name); if any(exact), idx = find(exact,1); else, idx = NaN; end
end
