clear all; close all; clc

% load in the ASD sublist
sublist_path = '/Users/daniela/Documents/Scratch/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/ASD_selected_PID_List.csv';
sublist = readmatrix(sublist_path);
sublist = sublist(:,1);

% Preallocate a cell array for efficiency
no_subs = length(sublist);
praat_list = cell(no_subs, 1);

praat_list{1} = 'subs$[1] = "Control1"';
praat_list{2} = 'subs$[2] = "Control2"';

% Fill the cell array with the desired strings
for i = 1:no_subs
    this_i = int2str(i+2);
    this_sub = int2str(sublist(i));
    praat_list{i+2} = ['subs$[' this_i '] = "ExpMom_Sub' this_sub '"'];
end

% Display the result
disp(praat_list);
