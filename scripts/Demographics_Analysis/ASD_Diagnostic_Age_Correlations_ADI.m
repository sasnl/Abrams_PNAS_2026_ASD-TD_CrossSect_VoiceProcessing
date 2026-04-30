%% ASD: Age ~ ADI (A/B/C), New Social Affect, and Neuropsych (WIAT/WASI)
% Included Only; External Ages from headerless TXT; Warn on Missing; Pairwise correlations
% Save as: ASD_Age_vs_ADI_SA_and_Neuropsych_INCLUDED_ONLY_WARN_Missing_NoHeaderAges.m
clear; clc;

% ===================== USER INPUTS ========================================
xlsxPath   = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Demographics_Analysis/td_asd_mothers_voice_behav_w_ados_adi (1).xlsx';
sheetASD   = 'ASD';

asdPIDcsv  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_PID_List_n39_ADOS.csv';
asdAgeTxt  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt'; % headerless list

% Output
outdir     = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Demographics_Analysis';
outCSV     = fullfile(outdir, 'ASD_Age_vs_ADI_SA_Neuropsych_INCLUDED_ONLY_WARN_Missing.csv');

% Options
doSpearman = false;   % also compute Spearman rho
alpha      = 0.05;    % 95% CI
% ==========================================================================

% Desired (human) headers in XLS (robust even if truncated)
wanted = struct( ...
  'PID',     "PID", ...
  'DiagA',   "Diagnostic Total A: Qualitative Abnormalities in Reciprocal Social Interaction", ...
  'DiagB',   "Diagnostic Total B - Verbal: Qualitative Abnormalities in Communication", ...
  'DiagC',   "Diagnostic Total C: Restricted, Repetitive, and Stereotyped Patterns of Behavior", ...
  'SAnew',   "New. Social Affect Total", ...
  'WIAT_WR', "WIATII Word Reading", ...
  'WIAT_RC', "WIATII Reading Comp", ...
  'AgeXLS',  "Age scan", ...
  'WASI_F',  "WASI FSIQ", ...
  'WASI_P',  "WASI PIQ", ...
  'WASI_V',  "WASI VIQ" ...
);

% Canonical names used inside MATLAB (order matters)
canon = {'PID','DiagA','DiagB','DiagC','SAnew','WIAT_WR','WIAT_RC','AgeXLS','WASI_F','WASI_P','WASI_V'};

fprintf('Reading ASD sheet from:\n  %s\n', xlsxPath);
try
    ASD = readtable(xlsxPath, 'Sheet', sheetASD, 'PreserveVariableNames', true);
catch
    ASD = readtable(xlsxPath, 'Sheet', sheetASD);
end

% ---------- Standardize columns ----------
ASD = stdCols_ASD_full(ASD, wanted, canon);
ASD.PID = normalizePIDColumn(ASD.PID);

% ---------- Load include PID list (normalized) & warn if any missing -----
fprintf('\nLoading ASD include list:\n  %s\n', asdPIDcsv);
asdKeep = loadPIDList(asdPIDcsv);          % normalized, original order preserved

missingInSheet = setdiff(asdKeep, ASD.PID);
if ~isempty(missingInSheet)
    warning('ASD PIDs in include list but NOT in ASD sheet (%d): %s', ...
        numel(missingInSheet), strjoin(missingInSheet, ', '));
end

% Filter ASD sheet to included only
n0 = height(ASD);
ASD = ASD(ismember(ASD.PID, asdKeep), :);
fprintf('Filtered ASD: kept %d / %d (excluded %d)\n', height(ASD), n0, n0-height(ASD));

% ---------- Build Age table from PID list + headerless age TXT ------------
fprintf('\nReading headerless ages from:\n  %s\n', asdAgeTxt);
ageVec = loadAgeVector_noHeader(asdAgeTxt);   % numeric column vector
if numel(ageVec) ~= numel(asdKeep)
    error('Age vector length (%d) != PID include list length (%d).', numel(ageVec), numel(asdKeep));
end
AgeTbl = table(asdKeep(:), double(ageVec(:)), 'VariableNames', {'PID','Age'});

% Merge Age onto ASD by PID
ASD = outerjoin(ASD, AgeTbl, 'Keys','PID', 'MergeKeys', true, 'Type','left');

% Ensure Age column is named exactly 'Age'
if ~ismember('Age', ASD.Properties.VariableNames)
    vn = string(ASD.Properties.VariableNames);
    k = find(vn == "Age_right" | vn == "Age_Age" | contains(vn,"Age"), 1);
    if ~isempty(k)
        ASD.Age = ASD.(vn(k)); ASD.(vn(k)) = [];
    else
        error('Could not locate merged Age column after join.');
    end
end

% ---------- Type fixes ----------
numVars = {'DiagA','DiagB','DiagC','SAnew','WIAT_WR','WIAT_RC','AgeXLS','WASI_F','WASI_P','WASI_V','Age'};
for v = numVars
    vn = v{1};
    if iscell(ASD.(vn)) || isstring(ASD.(vn))
        ASD.(vn) = str2double(string(ASD.(vn)));
    end
end

% ---------- WARN & summarize missing (pairwise later) ---------------------
missing = struct();
missing.DiagA  = isnan(ASD.DiagA);
missing.DiagB  = isnan(ASD.DiagB);
missing.DiagC  = isnan(ASD.DiagC);
missing.SAnew  = isnan(ASD.SAnew);
missing.WIAT_WR= isnan(ASD.WIAT_WR);
missing.WIAT_RC= isnan(ASD.WIAT_RC);
missing.WASI_F = isnan(ASD.WASI_F);
missing.WASI_P = isnan(ASD.WASI_P);
missing.WASI_V = isnan(ASD.WASI_V);
missing.Age    = isnan(ASD.Age);
missing.AgeXLS = isnan(ASD.AgeXLS);

names = fieldnames(missing);
fprintf('\nMissing summary among INCLUDED ASD (pairwise will be used):\n');
for i = 1:numel(names)
    nm = names{i};
    fprintf('  Missing %-8s: %d\n', nm, sum(missing.(nm)));
end
% List any PIDs with any missing among the measures we will correlate
anyMissingForAnalysis = missing.DiagA | missing.DiagB | missing.DiagC | missing.SAnew | ...
                        missing.WIAT_WR | missing.WIAT_RC | missing.WASI_F | missing.WASI_P | missing.WASI_V | ...
                        missing.Age;
if any(anyMissingForAnalysis)
    warnPIDs = ASD.PID(anyMissingForAnalysis);
    warning('Participants with at least one missing variable used in correlations (%d): %s', ...
        sum(anyMissingForAnalysis), strjoin(string(warnPIDs), ', '));
end

% ---------- Quick consistency check: external Age vs Age scan (AgeXLS) ----
idxBothAge = ~isnan(ASD.Age) & ~isnan(ASD.AgeXLS);
if sum(idxBothAge) >= 3
    [rAge, pAge] = corr(ASD.Age(idxBothAge), ASD.AgeXLS(idxBothAge), 'Rows','complete', 'Type','Pearson');
    madAge = mean(abs(ASD.Age(idxBothAge) - ASD.AgeXLS(idxBothAge)));
    fprintf('\nAge consistency (External vs Age scan): n=%d | r=%.3f, p=%.4g | Mean abs diff = %.3f years\n', ...
        sum(idxBothAge), rAge, pAge, madAge);
else
    fprintf('\nAge consistency (External vs Age scan): insufficient data (n=%d).\n', sum(idxBothAge));
end

% ---------- Correlations: Age ~ [ADI A/B/C, SAnew, WIAT/WASI] -------------
vars   = {'DiagA','DiagB','DiagC','SAnew','WIAT_WR','WIAT_RC','WASI_F','WASI_P','WASI_V'};
labels = {'Diagnostic Total A','Diagnostic Total B (Verbal)','Diagnostic Total C','New. Social Affect Total', ...
          'WIAT Word Reading','WIAT Reading Comp','WASI FSIQ','WASI PIQ','WASI VIQ'};

results = table('Size',[numel(vars) 9], ...
    'VariableTypes', {'string','double','double','double','double','double','double','double','double'}, ...
    'VariableNames', {'Measure','N_used','N_missing_score','N_missing_age','r','p','CI_lo','CI_hi','Spearman_r'});

for i = 1:numel(vars)
    y = ASD.(vars{i});   % outcome
    x = ASD.Age;         % predictor (external age)

    idx = ~isnan(x) & ~isnan(y);   % pairwise inclusion
    n  = sum(idx);

    nMissScore = sum(isnan(y));
    nMissAge   = sum(isnan(x));

    if n >= 3
        [r, p] = corr(x(idx), y(idx), 'Rows','complete', 'Type','Pearson');

        % Fisher z CI for r
        zr   = atanh(r);
        se   = 1/sqrt(n-3);
        zcrt = norminv(1 - alpha/2);
        lo   = tanh(zr - zcrt*se);
        hi   = tanh(zr + zcrt*se);

        if doSpearman
            rho = corr(x(idx), y(idx), 'Rows','complete', 'Type','Spearman');
        else
            rho = NaN;
        end
    else
        r = NaN; p = NaN; lo = NaN; hi = NaN; rho = NaN;
        warning('%s: insufficient data for correlation (n=%d; need >=3).', labels{i}, n);
    end

    results(i,:) = {labels{i}, n, nMissScore, nMissAge, r, p, lo, hi, rho};

    fprintf('%s: n=%d (missing score=%d, missing age=%d) | r=%.3f, p=%.4g, 95%% CI [%.3f, %.3f]%s\n', ...
        labels{i}, n, nMissScore, nMissAge, r, p, lo, hi, ...
        ternary(doSpearman, sprintf(' | Spearman rho=%.3f', rho), ''));
end

% ---------- Write results ----------
writetable(results, outCSV);
fprintf('\nResults written to: %s\n', outCSV);

% ======================= Helpers =========================================
function Tstd = stdCols_ASD_full(Tin, wanted, canon)
    Tstd = Tin;
    vis = string(Tstd.Properties.VariableNames);
    if isprop(Tstd.Properties,'VariableDescriptions')
        desc = string(Tstd.Properties.VariableDescriptions);
    else
        desc = repmat("", size(vis));
    end
    % Canonical -> target A (full) / target B (short/fallback)
    wantList = {
        'PID',     wanted.PID,     'PID'
        'DiagA',   wanted.DiagA,   'Diagnostic Total A'
        'DiagB',   wanted.DiagB,   'Diagnostic Total B'
        'DiagC',   wanted.DiagC,   'Diagnostic Total C'
        'SAnew',   wanted.SAnew,   'Social Affect'
        'WIAT_WR', wanted.WIAT_WR, 'WIAT Word Reading'
        'WIAT_RC', wanted.WIAT_RC, 'WIAT Reading Comp'
        'AgeXLS',  wanted.AgeXLS,  'Age scan'
        'WASI_F',  wanted.WASI_F,  'WASI FSIQ'
        'WASI_P',  wanted.WASI_P,  'WASI PIQ'
        'WASI_V',  wanted.WASI_V,  'WASI VIQ'
    };
    found = containers.Map;
    for i = 1:size(wantList,1)
        cn = wantList{i,1}; t1 = wantList{i,2}; t2 = wantList{i,3};
        actual = findBestMatch(vis, desc, t1, t2);
        if actual ~= "", found(cn) = actual; end
    end
    for i = 1:numel(canon)
        cn = canon{i};
        if isKey(found, cn)
            old = found(cn);
            if ~strcmp(old, cn)
                Tstd.Properties.VariableNames{strcmp(Tstd.Properties.VariableNames, old)} = cn;
            end
        else
            if strcmp(cn,'PID')
                Tstd.(cn) = strings(height(Tstd),1);
            else
                Tstd.(cn) = nan(height(Tstd),1);
            end
        end
    end
    Tstd = Tstd(:, canon);
end

function actual = findBestMatch(visNames, origNames, target1, target2)
    candidates = unique([origNames; visNames]); candidates = candidates(candidates~="");
    % exact
    k = strcmpi(candidates,target1) | strcmpi(candidates,target2);
    if any(k), actual = pickVisible(visNames, candidates(k)); return; end
    % contains
    k = contains(lower(candidates),lower(target1)) | contains(lower(candidates),lower(target2));
    if any(k), actual = pickVisible(visNames, candidates(k)); return; end
    % fuzzy cleaned
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
    pidCol = find(strcmpi(vn, 'PID'), 1, 'first'); if isempty(pidCol), pidCol = 1; end
    raw = Tpid.(vn(pidCol));
    keepPIDs = normalizePIDColumn(raw);
    keepPIDs = unique(keepPIDs(keepPIDs ~= ""));
end

function pidStr = normalizePIDColumn(col)
    s = string(col); s = strtrim(s);
    s_digits = regexprep(s, '[^0-9]', '');
    numVals  = str2double(s_digits);     % non-numeric -> NaN
    isNum    = ~isnan(numVals) & s ~= "";
    pidStr = strings(size(s));
    pidStr(isNum)  = pad(string(round(numVals(isNum))), 4, 'left', '0');
    pidStr(~isNum) = upper(s(~isNum));
    pidStr(ismissing(pidStr)) = "";
end

function ageVec = loadAgeVector_noHeader(pathStr)
% Read a headerless age vector (txt/csv). Returns Nx1 double.
    try
        ageVec = readmatrix(pathStr);
    catch
        % Fallbacks
        try
            T = readtable(pathStr, 'ReadVariableNames', false, 'Delimiter','\t');
            ageVec = T{:,1};
        catch
            try
                T = readtable(pathStr, 'ReadVariableNames', false, 'Delimiter',',');
                ageVec = T{:,1};
            catch
                T = readtable(pathStr, 'ReadVariableNames', false, 'Delimiter',' ', 'MultipleDelimsAsOne', true);
                ageVec = T{:,1};
            end
        end
    end
    ageVec = ageVec(:);
    ageVec = double(ageVec);
end

function s = ternary(cond, a, b)
    if cond, s = a; else, s = b; end
end
