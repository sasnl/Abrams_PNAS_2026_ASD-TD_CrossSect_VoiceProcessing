% This script selects subjects based on a matching criteria
%
% To run subjselect:
% mlsubmit subjselect.m subjselect_config.m
% _________________________________________________________________________
% 2018 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: movementstatsfmri.m 2018-03-16 $
%
% Created by: ksupekar 2012-08-20
% -------------------------------------------------------------------------

function subjselect (Config_File)

current_dir = pwd;

idstr = '$Id: subjselect.m Kaustubh Supekar 2012-08-20 v1$';
warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
%fname = sprintf('subjselect-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
%diary(fname);
disp('==================================================================');
fprintf('Subject select starts at %d/%02d/%02d %02d:%02d:%02d\n',c);
fprintf('%s\n', idstr);
disp('==================================================================');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

Config_File = strtrim(Config_File);

%-Check existence of configuration file
if ~exist(Config_File,'file')
  fprintf('Cannot find the configuration file ... \n');
  diary off; return;
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(Config_File);
eval(ConfigFile);
clear ConfigFile;

spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
subjselectscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/utilities/groupMatch/' spm_version];


% -------------------------------------------------------------------------
%-Read in contruct parameters
%-Get field names and values
fdname = fieldnames(paralist);
fdlength = length(fdname);
for i = 1:fdlength
  fdval = paralist.(fdname{i});
  if ischar(fdval)
    eval([genvarname(fdname{i}) '= strtrim(fdval);']);
  else
    eval([genvarname(fdname{i}) '= fdval;']);
  end
end
disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

% -------------------------------------------------------------------------
%-Do matching using Genetic algorithm
data = csvread(subjectlist);
numSubjects = length(data);
disp('Genetic matching begins');
disp(['Selecting ' num2str(numberofselectedsubjects) ' subjects from a total of '  num2str(numSubjects) ' subjects']);

options = gaoptimset('CreationFcn',{@subjselect_gacreate,numSubjects},...
            'CrossoverFcn',@subjselect_crossoverscattered,...
            'MutationFcn',@subjselect_mutationuniform,...
            'PopulationSize',3,... 
            'PopInitRange',[1;numSubjects],...
            'FitnessLimit', 0,...
            'StallGenLimit',1000,...
            'StallTimeLimit',100000,...
            'TimeLimit',100000,...
            'Generations',1000,...
            'CrossoverFraction',0.5,...
	    'Display', 'iter');
            %'Display','iter',...
            %'PlotFcn',@gaplotbestf);
          
% options = gaoptimset('CreationFcn',{@subjselect_gacreate,numSubjects},...
%             'CrossoverFcn',@subjselect_crossoverscattered,...
%             'MutationFcn',@subjselect_mutationuniform,...
%             'PopulationSize',10000,... 
%             'PopInitRange',[1;numSubjects],...
%             'FitnessLimit', 0,...
%             'StallGenLimit',500,...
%             'StallTimeLimit',500,...
%             'TimeLimit',10000,...
%             'Generations',5000,...
%             'CrossoverFraction',0.5,...
% 	    'Display', 'iter');
%             %'Display','iter',...
%             %'PlotFcn',@gaplotbestf);

FitnessFcn = {@subjselect_gafit,data,var_names, var_type, var_mean, var_std, var_priority};

hf = figure;
set(hf,'visible','off');
[selectedSubjects, errorRate] = ga(FitnessFcn, ...
        numberofselectedsubjects,options);


disp('Genetic matching finishes');

cd(current_dir);
csvwrite(selectedsubjectlist, data(selectedSubjects,:));

c     = fix(clock);
disp('==================================================================');
fprintf('Subject Select finishes at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');

%diary off;
clear all;
close all;

end
