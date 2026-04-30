% Close all, clear workspace and command window
close all; clear all; clc

% File paths
manip_folder = '/Users/daniela/Library/CloudStorage/Box-Box/2017 Projects/daa/asd_auditory/MothersVoiceRecordings/Manipulations';

td_pid_list = '/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/TD_selected_PID_List.csv';
asd_pid_list = '/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/ASD_selected_PID_List_n39_ADOS.csv';

% Read PID files
td_data = readcell(td_pid_list, 'Delimiter', ',');
asd_data = readcell(asd_pid_list, 'Delimiter', ',');

% Extract first column and clean PIDs
td_pids = td_data(2:end, 1);
asd_pids = asd_data(2:end, 1);
combined_pids = [td_pids; asd_pids];
combined_pids = cellfun(@(x) char(string(x)), combined_pids, 'UniformOutput', false);
combined_pids = unique(combined_pids);

% Subfolders to check
stim_types = {'Kee', 'Pee', 'Tee'};

% Initialize result storage
all_pid = {};
all_stim_type = {};
all_file = {};
all_duration = [];

% Initialize tracking for WAV file counts
wav_file_counts = zeros(length(combined_pids), 1);
missing_pids = {};


% Loop through each PID
for i = 1:length(combined_pids)
    pid = combined_pids{i};
    base_path = fullfile(manip_folder, ['ExpMom_Sub' pid], 'Raw_ChosenExemplars');
    
    file_count = 0;  % Count WAVs for this PID

    for j = 1:length(stim_types)
        stim_folder = fullfile(base_path, stim_types{j});
        wav_files = dir(fullfile(stim_folder, '*.wav'));

        file_count = file_count + length(wav_files);  % Accumulate

        for k = 1:length(wav_files)
            wav_path = fullfile(wav_files(k).folder, wav_files(k).name);

            try
                [y, fs] = audioread(wav_path);
                duration_sec = length(y) / fs;

                % Store results
                all_pid{end+1,1} = pid;
                all_stim_type{end+1,1} = stim_types{j};
                all_file{end+1,1} = wav_files(k).name;
                all_duration(end+1,1) = duration_sec;
            catch ME
                warning('Could not read file: %s\nError: %s', wav_path, ME.message);
            end
        end
    end

    wav_file_counts(i) = file_count;
    
    if file_count ~= 9
        missing_pids{end+1,1} = pid;
        fprintf('⚠️ PID %s has %d WAV files (expected 9)\n', pid, file_count);
    end
end

% Create results table
duration_table = table(all_pid, all_stim_type, all_file, all_duration, ...
    'VariableNames', {'PID', 'StimType', 'FileName', 'DurationSec'});

% === Compute average duration per subject (across all 9 stimuli) ===
[unique_pids, ~, pid_idx] = unique(duration_table.PID);
subject_avg_duration = accumarray(pid_idx, duration_table.DurationSec, [], @mean);

% Create summary table
subject_avg_table = table(unique_pids, subject_avg_duration, ...
    'VariableNames', {'PID', 'MeanDurationSec'});

% Save per-subject averages
subject_avg_file = fullfile(manip_folder, 'Mean_Stim_Duration_Per_Subject.csv');
writetable(subject_avg_table, subject_avg_file);

% === Compute grand average across all subjects ===
grand_average_duration = mean(subject_avg_duration);

% Display and optionally save
fprintf('\n✅ Grand average duration across all subjects: %.3f seconds\n', grand_average_duration);

% Optional: save as .txt
grand_avg_txt = fullfile(manip_folder, 'Grand_Average_Stim_Duration.txt');
fid = fopen(grand_avg_txt, 'w');
fprintf(fid, 'Grand average duration across all subjects: %.6f seconds\n', grand_average_duration);
fclose(fid);

% Compute percentage difference from 956 milliseconds (0.956 seconds)
reference_duration = 0.956;  % in seconds
percent_diff = ((grand_average_duration - reference_duration) / reference_duration) * 100;

fprintf('📏 Grand average duration: %.3f sec\n', grand_average_duration);
fprintf('📊 Percentage difference from 956 ms: %.2f%%\n', percent_diff);

% Save results to CSV
% output_file = fullfile(manip_folder, 'All_Wav_Durations.csv');
% writetable(duration_table, output_file);
% 
% fprintf('✅ Duration table saved to:\n%s\n', output_file);
