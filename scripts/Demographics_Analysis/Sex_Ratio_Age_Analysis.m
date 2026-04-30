%% Sex ratio analyses (Included Only + External Ages + Hard Fail on Missing)
% (1) ASD vs TD chi-square / Fisher's exact
% (2) Logistic regression: Sex ~ Age × Group
% Save as: SexRatio_GroupAndAge_Analysis_INCLUDED_ONLY_ExternalAges_HardFail.m
clear; clc;

% ================= USER INPUTS =================
xlsxPath = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Demographics_Analysis/td_asd_mothers_voice_behav_w_ados_adi (1).xlsx';
sheetTD  = 'TD';
sheetASD = 'ASD';

% PID include lists
tdListCSV  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/TD_selected_PID_List.csv';
asdListCSV = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_PID_List_n39_ADOS.csv';

% >>> External age lists (use these instead of Age in the XLS)
tdAgePath  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/TD_selected_age_scan.txt';
asdAgePath = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt';

% Original human-readable headers in Excel
wanted = struct( ...
  'PID',  "PID", ...
  'Age',  "Age scan", ...
  'Sex',  "Gender");   % values typically "MALE"/"FEMALE"

% Canonical names enforced inside MATLAB
canonNames = {'PID','Age','Sex'};

% Output control
writeCSV = true;
outCSV   = fullfile(tempdir, 'SexRatio_AgeXGroup_Logistic_INCLUDED_ONLY_ExternalAges.csv');
% ==============================================

fprintf('Reading Excel file:\n  %s\n', xlsxPath);
try
    TD  = readtable(xlsxPath, 'Sheet', sheetTD,  'PreserveVariableNames', true);
    ASD = readtable(xlsxPath, 'Sheet', sheetASD, 'PreserveVariableNames', true);
catch
    TD  = readtable(xlsxPath, 'Sheet', sheetTD);
    ASD = readtable(xlsxPath, 'Sheet', sheetASD);
end

% ---------- Standardize columns & add Group ----------
TD  = stdCols_gender(TD,  wanted, canonNames, 'TD');
ASD = stdCols_gender(ASD, wanted, canonNames, 'ASD');

% Normalize PIDs for safe matching
TD.PID  = normalizePIDColumn(TD.PID);
ASD.PID = normalizePIDColumn(ASD.PID);

% ---------- Load include lists & HARD FAIL if any PID not found ----------
fprintf('\nLoading include lists:\n  TD : %s\n  ASD: %s\n', tdListCSV, asdListCSV);
tdKeep  = loadPIDList(tdListCSV);
asdKeep = loadPIDList(asdListCSV);

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

% ---------- Filter to included participants only ----------
nTD0 = height(TD); nASD0 = height(ASD);
TD   = TD(ismember(TD.PID, tdKeep), :);
ASD  = ASD(ismember(ASD.PID, asdKeep), :);
fprintf('Filtered TD:  kept %d / %d (excluded %d)\n',  height(TD),  nTD0,  nTD0-height(TD));
fprintf('Filtered ASD: kept %d / %d (excluded %d)\n',   height(ASD), nASD0, nASD0-height(ASD));

% ---------- Replace Age with external lists (HARD SOURCE OF TRUTH) ----------
fprintf('\nReplacing Age from external lists:\n  TD ages : %s\n  ASD ages: %s\n', tdAgePath, asdAgePath);
TD  = replaceAgeFromFile(TD,  tdAgePath,  'TD');
ASD = replaceAgeFromFile(ASD, asdAgePath, 'ASD');

% ---------- Concatenate ----------
T = [TD; ASD];

% ---------- Type fixes & Sex normalization ----------
% Age numeric
if iscell(T.Age) || isstring(T.Age), T.Age = str2double(string(T.Age)); end

% Normalize Sex to MALE/FEMALE; accept common variants (M/F, Male/Female, 1/0)
SexStr = upper(strtrim(string(T.Sex)));
SexStr = regexprep(SexStr, '^\s*MALE\s*$',   'MALE');
SexStr = regexprep(SexStr, '^\s*FEMALE\s*$', 'FEMALE');
SexStr = regexprep(SexStr, '^\s*M\s*$',      'MALE');
SexStr = regexprep(SexStr, '^\s*F\s*$',      'FEMALE');
SexStr = regexprep(SexStr, '^\s*1\s*$',      'MALE');
SexStr = regexprep(SexStr, '^\s*0\s*$',      'FEMALE');
T.Sex  = categorical(SexStr);

% ---------- HARD FAIL: any missing/invalid in included data ----------
invalidSex = ~(T.Sex == "MALE" | T.Sex == "FEMALE");
missingAny = isnan(T.Age) | ismissing(T.Sex) | invalidSex | ismissing(T.Group);

if any(missingAny)
    bad = T(missingAny, {'PID','Group','Age','Sex'});
    bad.PID = string(bad.PID);
    preview = strjoin(strcat(bad.PID, " (", string(bad.Group), ", Age=", string(bad.Age), ", Sex=", string(bad.Sex), ")"), ', ');
    error('Hard fail: Missing/invalid data for %d participants: %s', sum(missingAny), preview);
end

% ---------- Derived variables ----------
T.SexBin = double(T.Sex=="MALE");  % 1=Male, 0=Female
T.Age_c  = T.Age - mean(T.Age,'omitnan');
T.Group  = categorical(T.Group, {'TD','ASD'});

% ---------- (1) Chi-square ASD vs TD × Sex ----------
[gTbl, chi2, p_chi2, ~] = crosstab(T.Group, T.Sex);
N = sum(gTbl,'all');
rowS = sum(gTbl,2); colS = sum(gTbl,1);
expTbl = (rowS * colS) / N;
useFisher = any(expTbl(:) < 5);

fprintf('\n=== Sex distribution by Group (ASD vs TD) — INCLUDED ONLY + External Ages ===\n');
rowNames = cellstr(categories(T.Group));
colNames = cellstr(categories(T.Sex));
fprintf('Counts (rows=Group, cols=Sex):\n');
fprintf('          '); fprintf('%8s', colNames{:}); fprintf('\n');
for r = 1:size(gTbl,1)
    fprintf('%8s', rowNames{r});
    fprintf('%8d', gTbl(r,:));
    fprintf('\n');
end

if useFisher && all(size(gTbl)==[2 2])
    [p_fisher, stats_fisher] = fishertest(gTbl);
    fprintf('Fisher''s exact test: p = %.4g (odds ratio = %.3f; 95%% CI [%.3f, %.3f])\n', ...
        p_fisher, stats_fisher.OddsRatio, stats_fisher.ConfidenceInterval(1), stats_fisher.ConfidenceInterval(2));
    fprintf('(Chi-square for reference: chi2 = %.3f, p = %.4g)\n', chi2, p_chi2);
else
    df = (size(gTbl,1)-1)*(size(gTbl,2)-1);
    fprintf('Chi-square test of independence: chi2 = %.3f, p = %.4g, df = %d\n', chi2, p_chi2, df);
end

% ---------- (2) Logistic: Sex ~ Age_c * Group ----------
mdl = fitglm(T, 'SexBin ~ Age_c*Group', 'Distribution','binomial');
coefs = mdl.Coefficients;

% Estimates & SE
B_age   = safeCoef(coefs,"Age_c","Estimate");      SE_age   = safeCoef(coefs,"Age_c","SE");
B_grp   = safeCoef(coefs,"Group_ASD","Estimate");  SE_grp   = safeCoef(coefs,"Group_ASD","SE");
B_int   = safeCoef(coefs,"Age_c:Group_ASD","Estimate"); SE_int = safeCoef(coefs,"Age_c:Group_ASD","SE");

% Wald z
z_age   = B_age/max(SE_age,eps);
z_grp   = B_grp/max(SE_grp,eps);
z_int   = B_int/max(SE_int,eps);

% p-values (prefer model table, fall back to normal approx)
p_age = safeCoef(coefs,"Age_c","pValue");           if isnan(p_age), p_age = 2*(1 - normcdf(abs(z_age))); end
p_grp = safeCoef(coefs,"Group_ASD","pValue");       if isnan(p_grp), p_grp = 2*(1 - normcdf(abs(z_grp))); end
p_int = safeCoef(coefs,"Age_c:Group_ASD","pValue"); if isnan(p_int), p_int = 2*(1 - normcdf(abs(z_int))); end

% OR and CI for interaction
CI = coefCI(mdl, 0.05);
betaHat = mdl.Coefficients.Estimate;
rowInt  = safeRowIndex(coefs,"Age_c:Group_ASD");
if ~isnan(rowInt)
    OR_int = exp(betaHat(rowInt));
    OR_lo  = exp(CI(rowInt,1));
    OR_hi  = exp(CI(rowInt,2));
else
    OR_int = NaN; OR_lo = NaN; OR_hi = NaN;
end

fprintf('\n=== Logistic regression (INCLUDED ONLY + External Ages): P(Male) ~ Age_c * Group ===\n');
fprintf('Age (centered):      B = %.4f, SE = %.4f, z = %.2f, p = %.4g\n', B_age, SE_age, z_age, p_age);
fprintf('Group (ASD vs TD):   B = %.4f, SE = %.4f, z = %.2f, p = %.4g\n', B_grp, SE_grp, z_grp, p_grp);
fprintf('Age×Group (ASD):     B = %.4f, SE = %.4f, z = %.2f, p = %.4g,  OR = %.3f  [%.3f, %.3f]\n', ...
        B_int, SE_int, z_int, p_int, OR_int, OR_lo, OR_hi);

% ---------- Optional CSV ----------
if writeCSV
    out = table(B_age,SE_age,z_age,p_age,B_grp,SE_grp,z_grp,p_grp,B_int,SE_int,z_int,p_int,OR_int,OR_lo,OR_hi);
    writetable(out, outCSV);
    fprintf('\nLogistic results written to: %s\n', outCSV);
end

% ================== Helpers ==================
function Tstd = stdCols_gender(Tin, wanted, canonNames, groupLabel)
    Tstd = Tin;
    visNames = string(Tstd.Properties.VariableNames);
    if isprop(Tstd.Properties,'VariableDescriptions')
        origNames = string(Tstd.Properties.VariableDescriptions);
    else
        origNames = repmat("", size(visNames));
    end
    wantList = {
        'PID', wanted.PID, 'PID'
        'Age', wanted.Age, 'Age scan'
        'Sex', wanted.Sex, 'Gender'
    };
    found = containers.Map;
    for i=1:size(wantList,1)
        canon=wantList{i,1}; t1=wantList{i,2}; t2=wantList{i,3};
        actual = findBestMatch(visNames, origNames, t1, t2);
        if actual ~= "", found(canon)=actual; end
    end
    for i=1:numel(canonNames)
        cn = canonNames{i};
        if isKey(found,cn)
            old = found(cn);
            if ~strcmp(old,cn)
                Tstd.Properties.VariableNames{strcmp(Tstd.Properties.VariableNames,old)} = cn;
            end
        else
            switch cn
                case {'PID','Sex'}, Tstd.(cn) = strings(height(Tstd),1);
                otherwise,          Tstd.(cn) = nan(height(Tstd),1);
            end
        end
    end
    Tstd.Group = categorical(repmat({groupLabel},height(Tstd),1), {'TD','ASD'});
    Tstd = Tstd(:, [{'PID','Group'}, canonNames(2:end)]);
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
            idx = startsWith(visNames,pref); if any(idx), actual = visNames(find(idx,1)); return; end
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

function val = safeCoef(coefTbl, name, field)
    rows = string(coefTbl.Properties.RowNames);
    if contains(name,":")
        parts = split(string(name),":"); a=parts(1); b=parts(2);
        exact1 = rows==a+":"+b; exact2 = rows==b+":"+a;
        if any(exact1), val = coefTbl.(field)(find(exact1,1)); return; end
        if any(exact2), val = coefTbl.(field)(find(exact2,1)); return; end
        both = contains(rows,a)&contains(rows,b)&contains(rows,":");
        if any(both), val = coefTbl.(field)(find(both,1)); return; end
        val = NaN; return;
    else
        exact = rows==string(name); if any(exact), val = coefTbl.(field)(find(exact,1)); return; end
        cie = strcmpi(rows,string(name)); if any(cie), val = coefTbl.(field)(find(cie,1)); return; end
        val = NaN;
    end
end

function idx = safeRowIndex(coefTbl, name)
    rows = string(coefTbl.Properties.RowNames);
    parts = split(string(name),":");
    if numel(parts)==2
        a=parts(1); b=parts(2);
        exact1 = rows==a+":"+b; exact2 = rows==b+":"+a;
        if any(exact1), idx = find(exact1,1); return; end
        if any(exact2), idx = find(exact2,1); return; end
        both = contains(rows,a)&contains(rows,b)&contains(rows,":");
        if any(both), idx = find(both,1); return; end
        idx = NaN;
    else
        exact = rows==string(name); if any(exact), idx=find(exact,1); else, idx=NaN; end
    end
end
