% Clear workspace
clear; clc;

% ========== File paths ==========
dataDir = '/Users/daniela/Library/CloudStorage/Box-Box/2022 ASD voice development/0. ELN/1. log of results/data_scripts_and_results/eprime_edats_as_csv';

tdListFile = '/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/TD_selected_PID_List.csv';
asdListFile = '/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/ASD_selected_PID_List_n39_ADOS.csv';

% ========== Load subject ID lists ==========
tdTable = readtable(tdListFile, 'VariableNamingRule', 'preserve');
asdTable = readtable(asdListFile, 'VariableNamingRule', 'preserve');

tdIDs = pad(string(tdTable{:,1}), 4, 'left', '0');
asdIDs = pad(string(asdTable{:,1}), 4, 'left', '0');

% ========== Get all CSV files ==========
csvFiles = dir(fullfile(dataDir, '*.csv'));

% ========== Initialize result tables ==========
TD_results = table();
ASD_results = table();

% ========== Loop through files ==========
for i = 1:length(csvFiles)
    file = csvFiles(i);
    filePath = fullfile(file.folder, file.name);

    % Extract PID from end of filename (e.g., "7026" in "_7026-1.csv")
    tokens = regexp(file.name, '_([0-9]+)-\d+\.csv$', 'tokens');
    if isempty(tokens)
        fprintf('Skipping file (no PID match at end): %s\n', file.name);
        continue;
    end
    pid = string(tokens{1}{1});
    pid = pad(pid, 4, 'left', '0');  % ✅ Standardize PID to 4-digit string

    % Read file with all columns as strings
    try
        opts = detectImportOptions(filePath, 'VariableNamingRule', 'preserve');
        opts.VariableTypes(:) = {'string'};
        dataRaw = readtable(filePath, opts);

        % Manually extract and convert required columns
        requiredCols = ["Sound1", "ChooseSorD.RESP", "ChooseSorD.RT"];
        if ~all(ismember(requiredCols, dataRaw.Properties.VariableNames))
            fprintf('⚠️ Missing required columns in file: %s\n', file.name);
            continue;
        end

        data = table();
        data.Sound1 = dataRaw.("Sound1");
        data.ChooseSorD_RESP = dataRaw.("ChooseSorD.RESP");
        data.ChooseSorD_RT = str2double(dataRaw.("ChooseSorD.RT"));

    catch ME
        fprintf('⚠️ Error reading file: %s\n', file.name);
        disp(ME.message);
        continue;
    end

    % Remove rows with missing RT or response
    validIdx = ~ismissing(data.ChooseSorD_RESP) & ~isnan(data.ChooseSorD_RT);
    data = data(validIdx, :);
    if isempty(data)
        fprintf('⚠️ No valid trials in file: %s\n', file.name);
        continue;
    end

    % Compute accuracy
    stimuli = string(data.Sound1);
    responses = lower(string(data.ChooseSorD_RESP));
    rtValues = data.ChooseSorD_RT;

    isMomTrial = startsWith(stimuli, 'Exper');
    isStrangerTrial = startsWith(stimuli, 'Cont');

    isCorrect = (isMomTrial & responses == "q") | ...
                (isStrangerTrial & responses == "p");

    medianRT = median(rtValues);
    meanACC = mean(isCorrect);

    % Create result row
    resultRow = table(pid, medianRT, meanACC, 'VariableNames', {'PID', 'MedianRT', 'MeanACC'});

    % Store in appropriate group table
    if ismember(pid, tdIDs)
        TD_results = [TD_results; resultRow];
    elseif ismember(pid, asdIDs)
        ASD_results = [ASD_results; resultRow];
    end
end

% ========== Display results ==========
disp('TD Results:');
disp(TD_results);

disp('ASD Results:');
disp(ASD_results);

% ========== (Optional) Save to CSV ==========
save_dir = '/Users/daniela/Documents/Scratch/MothersVoice_ID_Analysis';
writetable(TD_results, fullfile(save_dir, 'TD_summary.csv'));
writetable(ASD_results, fullfile(save_dir, 'ASD_summary.csv'));
