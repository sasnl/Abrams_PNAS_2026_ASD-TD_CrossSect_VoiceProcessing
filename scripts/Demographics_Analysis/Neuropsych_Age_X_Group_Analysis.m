%% Neuropsych Age × Group analysis (TD vs ASD) + Welch t-tests
% Included Only + External Ages + HARD FAIL on any missing + HARD FAIL if inclusion PID not found
% Save as: Neuropsych_Age_X_Group_Analysis.m

clear; clc;

% ===================== USER INPUTS =======================================
xlsxPath   = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Demographics_Analysis/td_asd_mothers_voice_behav_w_ados_adi (1).xlsx';
sheetTD    = 'TD';
sheetASD   = 'ASD';

% Participant include lists
tdListCSV  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/TD_selected_PID_List.csv';
asdListCSV = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_PID_List_n39_ADOS.csv';

% External age lists
tdAgePath  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/TD_selected_age_scan.txt';
asdAgePath = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt';

% Output directory and filenames
outdir = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Demographics_Analysis';
outCSV               = fullfile(outdir, 'Age_x_Group_Neuropsych_Results_INCLUDED_ONLY_ExternalAges.csv');
missingAgesReportTxt = fullfile(outdir, 'MissingAges_INCLUDED_ONLY_ExternalAges.txt');

% Variable headers (as they appear in Excel)
wanted = struct( ...
  'PID',  "PID", ...
  'WR',   "WIATII Word Reading", ...
  'RC',   "WIATII Reading Comp", ...
  'Age',  "Age scan", ...
  'FSIQ', "WASI FSIQ", ...
  'PIQ',  "WASI PIQ", ...
  'VIQ',  "WASI VIQ");

% Canonical names enforced in MATLAB
canonNames = {'PID','WIAT_WR','WIAT_RC','Age','WASI_FSIQ','WASI_PIQ','WASI_VIQ'};

% Key variables for hard-fail completeness check
keyVars = {'Age','WIAT_WR','WIAT_RC','WASI_FSIQ','WASI_PIQ','WASI_VIQ'};

% ========================================================================
fprintf('Reading Excel file:\n  %s\n', xlsxPath);

try
    TD  = readtable(xlsxPath, 'Sheet', sheetTD,  'PreserveVariableNames', true);
    ASD = readtable(xlsxPath, 'Sheet', sheetASD, 'PreserveVariableNames', true);
catch
    TD  = readtable(xlsxPath, 'Sheet', sheetTD);
    ASD = readtable(xlsxPath, 'Sheet', sheetASD);
end

TD  = standardizeColumns(TD,  wanted, canonNames, 'TD');
ASD = standardizeColumns(ASD, wanted, canonNames, 'ASD');

% ===================== Inclusion filtering ==============================
fprintf('\nLoading include lists:\n  TD : %s\n  ASD: %s\n', tdListCSV, asdListCSV);
tdKeep  = loadPIDList(tdListCSV);
asdKeep = loadPIDList(asdListCSV);

% Normalize PIDs before comparing
TD.PID  = normalizePIDColumn(TD.PID);
ASD.PID = normalizePIDColumn(ASD.PID);

% HARD FAIL if any included PID not found in the source sheets
tdMissingInData  = setdiff(tdKeep, TD.PID);
asdMissingInData = setdiff(asdKeep, ASD.PID);
if ~isempty(tdMissingInData) || ~isempty(asdMissingInData)
    msg = "Hard fail: Inclusion list contains PIDs not present in the Excel sheets.";
    if ~isempty(tdMissingInData)
        msg = msg + sprintf('\n  TD missing (%d): %s', numel(tdMissingInData), strjoin(tdMissingInData, ', '));
    end
    if ~isempty(asdMissingInData)
        msg = msg + sprintf('\n  ASD missing (%d): %s', numel(asdMissingInData), strjoin(asdMissingInData, ', '));
    end
    error('%s', msg);
end

% Now filter to included PIDs only
nTD0 = height(TD); nASD0 = height(ASD);
TD   = TD(ismember(TD.PID,  tdKeep), :);
ASD  = ASD(ismember(ASD.PID, asdKeep), :);
fprintf('Filtered TD:  kept %d / %d (excluded %d)\n',  height(TD),  nTD0,  nTD0-height(TD));
fprintf('Filtered ASD: kept %d / %d (excluded %d)\n',   height(ASD), nASD0, nASD0-height(ASD));

% ===================== Replace Age with external lists ==================
fprintf('\nReplacing Age from external lists:\n  TD ages : %s\n  ASD ages: %s\n', tdAgePath, asdAgePath);
TD  = replaceAgeFromFile(TD,  tdAgePath,  'TD');
ASD = replaceAgeFromFile(ASD, asdAgePath, 'ASD');

% Report any missing ages (prior to hard fail below)
missTD  = TD.PID(isnan(TD.Age));
missASD = ASD.PID(isnan(ASD.Age));
if ~isempty(missTD) || ~isempty(missASD)
    fid = fopen(missingAgesReportTxt, 'w');
    fprintf(fid, "Missing Ages after external-age replacement:\n\nTD:\n%s\n\nASD:\n%s\n", ...
        strjoin(missTD, ', '), strjoin(missASD, ', '));
    fclose(fid);
    fprintf('Wrote missing-age report: %s\n', missingAgesReportTxt);
end

% ===================== Concatenate & type fixes =========================
T = [TD; ASD];
if ~isstring(T.PID); T.PID = string(T.PID); end

% Force numeric types for key variables
for v = keyVars
    vn = v{1};
    if iscell(T.(vn)) || isstring(T.(vn))
        T.(vn) = str2double(string(T.(vn)));
    end
end

% ===================== HARD FAIL on any missing ==========================
missingAny = false(height(T),1);
for v = keyVars
    missingAny = missingAny | isnan(T.(v{1}));
end
if any(missingAny)
    badPIDs = T.PID(missingAny);
    error('Hard fail: Missing data detected for %d participants: %s', numel(badPIDs), strjoin(string(badPIDs), ', '));
end

% Center Age
T.Age_c = T.Age - mean(T.Age, 'omitnan');

% ===================== Outcomes & model fits ============================
outcomes = {'WIAT_WR','WIAT_RC','WASI_FSIQ','WASI_PIQ','WASI_VIQ'};

results = table('Size',[0 14], ...
    'VariableTypes', {'string','double','double','double','double','double', ...
                      'double','double','double', ...
                      'double','double','double','double','double'}, ...
    'VariableNames', {'Outcome','n','TD_mean','TD_sd','ASD_mean','ASD_sd', ...
                      'B_Age','B_GroupASD','B_Age_x_GroupASD', ...
                      'p_ASDvsTD','t_ASDvsTD','df_ASDvsTD','Diff_ASDminusTD','d_ASDminusTD'});

pExtras = table('Size',[0 7], ...
    'VariableTypes', repmat("double",1,7), ...
    'VariableNames', {'p_Age','p_GroupASD','p_Age_x_GroupASD','R2','R2Adj','F','p_F'});

fprintf('\n=== Age × Group models (fitlm with interaction) + Welch t-tests ===\n');
for k = 1:numel(outcomes)
    y = outcomes{k};
    Tk = T(~isnan(T.(y)), :);

    TD_idx   = Tk.Group == 'TD';
    ASD_idx  = Tk.Group == 'ASD';
    TD_vals  = Tk.(y)(TD_idx);
    ASD_vals = Tk.(y)(ASD_idx);

    TD_mean  = mean(TD_vals);  TD_sd  = std(TD_vals);
    ASD_mean = mean(ASD_vals); ASD_sd = std(ASD_vals);

    nTD  = sum(~isnan(TD_vals));
    nASD = sum(~isnan(ASD_vals));

    % Welch t-test
    [~, pWelch, ~, statsWelch] = ttest2(ASD_vals, TD_vals, 'Vartype','unequal');
    tWelch  = statsWelch.tstat; dfWelch = statsWelch.df;

    % Cohen's d (pooled SD)
    Diff_ASDminusTD = ASD_mean - TD_mean;
    sp = sqrt(((nASD-1)*ASD_sd^2 + (nTD-1)*TD_sd^2) / max(nASD + nTD - 2, 1));
    d_ASDminusTD = Diff_ASDminusTD / sp;

    % GLM with interaction
    mdl = fitlm(Tk, 'interactions', 'ResponseVar', y, 'PredictorVars', {'Age_c','Group'});

    coefs = mdl.Coefficients;
    B_Age         = getCoef(coefs, 'Age_c',            'Estimate');
    B_GroupASD    = getCoef(coefs, 'Group_ASD',        'Estimate');
    B_Age_x_Group = getCoef(coefs, 'Age_c:Group_ASD',  'Estimate');

    p_Age         = getCoef(coefs, 'Age_c',            'pValue');
    p_GroupASD    = getCoef(coefs, 'Group_ASD',        'pValue');
    p_Age_x_Group = getCoef(coefs, 'Age_c:Group_ASD',  'pValue');

    fprintf('%-10s  n=%3d | Welch ASD–TD: t=%.2f, df=%.1f, p=%.3g | Age: B=%.4f (p=%.3g) | Group: B=%.4f (p=%.3g) | Age×Group: B=%.4f (p=%.3g) | R²=%.3f\n', ...
        y, height(Tk), tWelch, dfWelch, pWelch, B_Age, p_Age, B_GroupASD, p_GroupASD, B_Age_x_Group, p_Age_x_Group, mdl.Rsquared.Ordinary);

    results = [results; {string(y), height(Tk), TD_mean, TD_sd, ASD_mean, ASD_sd, ...
                         B_Age, B_GroupASD, B_Age_x_Group, ...
                         pWelch, tWelch, dfWelch, Diff_ASDminusTD, d_ASDminusTD}];

    modelAnova = anova(mdl,'summary');
    try
        Fstat = modelAnova.F(2); pF = modelAnova.pValue(2);
    catch
        Fstat = NaN; pF = NaN;
    end
    pExtras = [pExtras; {p_Age, p_GroupASD, p_Age_x_Group, ...
                         mdl.Rsquared.Ordinary, mdl.Rsquared.Adjusted, Fstat, pF}];
end

out = [results pExtras];
disp(' '); disp(out);
writetable(out, outCSV);
fprintf('\nResults written to: %s\n', outCSV);

% ======================= Helper functions ================================
function Tstd = standardizeColumns(Tin, wanted, canonNames, groupLabel)
% STANDARDIZECOLUMNS  Rename/fill/reorder columns to canonical names.
    Tstd = Tin;

    visNames = string(Tstd.Properties.VariableNames);
    if isprop(Tstd.Properties, 'VariableDescriptions')
        origNames = string(Tstd.Properties.VariableDescriptions);
    else
        origNames = repmat("", size(visNames));
    end

    wantList = {
        'PID',       wanted.PID,   'PID'
        'WIAT_WR',   wanted.WR,    'WIAT Word Reading'
        'WIAT_RC',   wanted.RC,    'WIAT Reading Comp'
        'Age',       wanted.Age,   'Age scan'
        'WASI_FSIQ', wanted.FSIQ,  'WASI FSIQ'
        'WASI_PIQ',  wanted.PIQ,   'WASI PIQ'
        'WASI_VIQ',  wanted.VIQ,   'WASI VIQ'
    };

    found = containers.Map;
    for i = 1:size(wantList,1)
        canon   = wantList{i,1};
        target1 = wantList{i,2};
        target2 = wantList{i,3};
        actual = findBestMatch(visNames, origNames, target1, target2);
        if actual ~= ""
            found(canon) = actual;
        end
    end

    for i = 1:numel(canonNames)
        cn = canonNames{i};
        if isKey(found, cn)
            old = found(cn);
            if ~strcmp(old, cn)
                Tstd.Properties.VariableNames{strcmp(Tstd.Properties.VariableNames, old)} = cn;
            end
        else
            switch cn
                case 'PID', Tstd.(cn) = strings(height(Tstd),1);
                otherwise,  Tstd.(cn) = nan(height(Tstd),1);
            end
        end
    end

    Tstd.Group = categorical(repmat({groupLabel}, height(Tstd), 1));
    Tstd = Tstd(:, [{'PID','Group'}, canonNames(2:end)]);
end

function actual = findBestMatch(visNames, origNames, target1, target2)
    candidates = unique([origNames; visNames]);
    candidates = candidates(candidates ~= "");

    k = strcmpi(candidates, target1) | strcmpi(candidates, target2);
    if any(k), actual = pickVisible(visNames, candidates(k)); return; end

    k = contains(lower(candidates), lower(target1)) | contains(lower(candidates), lower(target2));
    if any(k), actual = pickVisible(visNames, candidates(k)); return; end

    clean = @(s) regexprep(lower(s), '[^a-z0-9]', '');
    ct1 = clean(string(target1)); ct2 = clean(string(target2));
    kc = strcmp(clean(candidates), ct1) | strcmp(clean(candidates), ct2);
    if any(kc), actual = pickVisible(visNames, candidates(kc)); return; end

    actual = "";
end

function actual = pickVisible(visNames, matched)
    for m = matched(:).'
        if any(strcmp(visNames, m)), actual = m; return; end
        pref = extractBefore(m, min(strlength(m), 20));
        if strlength(pref) > 0
            idx = startsWith(visNames, pref);
            if any(idx), actual = visNames(find(idx,1,'first')); return; end
        end
    end
    actual = "";
end

function val = getCoef(coefTbl, name, field)
    rows = string(coefTbl.Properties.RowNames);
    if contains(name, ":")
        parts = split(string(name), ":"); a = parts(1); b = parts(2);
        exact1 = rows == a + ":" + b; exact2 = rows == b + ":" + a;
        if any(exact1), val = coefTbl.(field)(find(exact1,1)); return; end
        if any(exact2), val = coefTbl.(field)(find(exact2,1)); return; end
        both = contains(rows, a) & contains(rows, b) & contains(rows, ":");
        if any(both), val = coefTbl.(field)(find(both,1)); return; end
    else
        exact = rows == string(name); if any(exact), val = coefTbl.(field)(find(exact,1)); return; end
        cie = strcmpi(rows, string(name)); if any(cie), val = coefTbl.(field)(find(cie,1)); return; end
    end
    val = NaN;
end

function keepPIDs = loadPIDList(csvPath)
    try
        Tpid = readtable(csvPath, 'PreserveVariableNames', true);
    catch
        Tpid = readtable(csvPath);
    end
    varNames = string(Tpid.Properties.VariableNames);
    pidCol = find(strcmpi(varNames, 'PID'), 1, 'first'); if isempty(pidCol), pidCol = 1; end
    raw = Tpid.(varNames(pidCol));
    keepPIDs = normalizePIDColumn(raw);
    keepPIDs = unique(keepPIDs(keepPIDs ~= ""));
end

function pidStr = normalizePIDColumn(col)
% Version-safe PID normalization:
% - trims
% - numeric → zero-pad width 4 (strip commas/spaces)
% - alphanumeric → uppercase as-is
    s = string(col);
    s = strtrim(s);
    s_digits = regexprep(s, '[^0-9]', '');
    numVals  = str2double(s_digits);           % non-numeric -> NaN
    isNum    = ~isnan(numVals) & s ~= "";

    pidStr = strings(size(s));
    pidStr(isNum)  = pad(string(round(numVals(isNum))), 4, 'left', '0');
    pidStr(~isNum) = upper(s(~isNum));
    pidStr(ismissing(pidStr)) = "";
end

function Tout = replaceAgeFromFile(Tin, agePath, groupLabel)
% Overwrite Tin.Age using age list (txt/csv) matched on PID.
    A = loadAgeTable(agePath);
    Tin.PID = normalizePIDColumn(Tin.PID);
    A.PID   = normalizePIDColumn(A.PID);

    Tin.Age_original = Tin.Age;
    Tin = outerjoin(Tin, A, 'Keys','PID', 'MergeKeys', true, 'Type','left', ...
        'LeftVariables', Tin.Properties.VariableNames, 'RightVariables', {'Age'});

    rightAgeVar = string(Tin.Properties.VariableNames);
    rightAgeVar = rightAgeVar(contains(rightAgeVar, 'Age') & ~strcmp(rightAgeVar, 'Age') & ~strcmp(rightAgeVar, 'Age_original'));
    if ~isempty(rightAgeVar)
        rightAgeVar = rightAgeVar(1);
        useExternal = ~isnan(Tin.(rightAgeVar));
        Tin.Age(useExternal) = Tin.(rightAgeVar)(useExternal);
        Tin.(rightAgeVar) = [];
    end

    nHad = sum(~isnan(Tin.Age_original));
    nNow = sum(~isnan(Tin.Age));
    nUpdated = sum(~isnan(Tin.Age) & (Tin.Age ~= Tin.Age_original) & ~isnan(Tin.Age_original));
    nFilledFromMissing = sum(isnan(Tin.Age_original) & ~isnan(Tin.Age));
    nMissing = sum(isnan(Tin.Age));

    fprintf('[%s] Ages: had=%d, now=%d | updated=%d, filled_from_missing=%d, still_missing=%d (of %d)\n', ...
        groupLabel, nHad, nNow, nUpdated, nFilledFromMissing, nMissing, height(Tin));

    Tin.Age_original = [];
    Tout = Tin;
end

function A = loadAgeTable(pathStr)
% Robustly read an age file; returns table with PID(string) & Age(double)
    try
        opts = detectImportOptions(pathStr, 'NumHeaderLines', 0);
        for i = 1:numel(opts.VariableTypes)
            if ~strcmpi(opts.VariableTypes{i}, 'double')
                opts = setvartype(opts, opts.VariableNames{i}, 'string');
            end
        end
        T = readtable(pathStr, opts);
    catch
        try
            T = readtable(pathStr, 'Delimiter','\t', 'PreserveVariableNames', true);
        catch
            try
                T = readtable(pathStr, 'Delimiter',',', 'PreserveVariableNames', true);
            catch
                T = readtable(pathStr, 'Delimiter',' ', 'MultipleDelimsAsOne', true, 'PreserveVariableNames', true);
            end
        end
    end

    vn = string(T.Properties.VariableNames);

    pidCol = find(strcmpi(vn, 'PID'), 1);
    if isempty(pidCol)
        isNum = varfun(@(x) isnumeric(x), T, 'OutputFormat', 'uniform');
        pidCol = find(~isNum, 1, 'first'); if isempty(pidCol), pidCol = 1; end
    end

    ageCol = find(contains(lower(vn), 'age'), 1);
    if isempty(ageCol)
        isNum = varfun(@(x) isnumeric(x), T, 'OutputFormat', 'uniform');
        ageCol = find(isNum, 1, 'first');
        if isempty(ageCol), error('Could not locate an Age column in %s', pathStr); end
    end

    A = table;
    A.PID = string(T.(vn(pidCol)));
    A.Age = double(T.(vn(ageCol)));
    A.PID = strtrim(A.PID);
    A.Age(~isfinite(A.Age)) = NaN;
end
