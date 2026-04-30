function movementstatsfmri(ConfigFile)

tic
CurrentDir = pwd;

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('fMRI MovementStats start at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
disp(['Current directory is: ',CurrentDir]);
fprintf('Script: %s\n', which('movementstatsfmri.m'));
fprintf('Configfile: %s\n', ConfigFile);
fprintf('\n')
disp('------------------------------------------------------------------');

% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------
ConfigFile = strtrim(ConfigFile);
if ~exist(ConfigFile, 'file')
    error('cannot find the configuration file')
end
disp(ConfigFile);
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
disp(ConfigFile);
eval(ConfigFile);
clear ConfigFile;


spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmqcscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/qc/' spm_version];

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based qc scripts path: %s\n', spmqcscript_path);
addpath(genpath(spmqcscript_path));

%-Configurations
spmversion   = strtrim(paralist.spmversion);
subjectlist  = strtrim(paralist.subjectlist);
exp_runlist  = strtrim(paralist.runlist);
raw_dir      = strtrim(paralist.rawdatadir);
project_dir  = strtrim(paralist.projectdir);
prep_folder  = strtrim(paralist.preprocessed_folder);
ScanToScanCrit = paralist.scantoscancrit;
%if  exist('paralist.voxdim','var')
VoxSize = str2double(strtrim(paralist.voxdim));
%end

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

%-Check for spm version mismatch
%--------------------------------------------------------------------------
if ~strcmp(spmversion, spm_version)
    error('spm version mismatch');
end
subjtxtfile = fopen(subjectlist);
subjectlist=textscan(subjtxtfile,'%s %s %s','Delimiter',',','HeaderLines',1);
fclose(subjtxtfile);

%subjectlist = csvread(subjectlist,1);
NumSubjs =  size(subjectlist{1},1);
Conditions = ReadList(exp_runlist);
NumConds = length(Conditions);
NumRuns = NumSubjs*NumConds;

RunIndex = zeros(NumRuns, 4);
[C1, C2] = meshgrid(1:NumSubjs, 1:NumConds);
RunIndex(:,1) = C1(:);
RunIndex(:,2) = C2(:);
RunIndex(:,3) = 1:NumRuns;
RunIndex(:,4) = 1;

MvmntDir = cell(NumRuns, 1);
%-overall max range | sum of max range | overall max scan to scan movement |
%-max of sum of scan to scan movement | # scans > 0.5 voxel w.r.t. max overall scan
%-to scan movement
MvmntStats = zeros(12);
myCluster = parcluster('local');
%myCluster.NumWorkers = 8;  % 'Modified' property now TRUE
%saveProfile(myCluster);
%parpool(8)

for isubj = 1:NumSubjs
        subject           = subjectlist{1}{isubj};
        visit             = subjectlist{2}{isubj};
        session           = subjectlist{3}{isubj};
        for iCond = 1:NumConds
            try
            RunCnt=(isubj-1)*NumConds+iCond;
            MvmntStats = zeros(12);
           % if exist(fullfile(project_dir,'/data/imaging/participants', ...
           %         subject,['visit',visit],['session',session], 'fmri', ...
           %         Conditions{iCond}, prep_folder, 'MovementStats.txt'),'file');
           %     continue;
           % end

            % UnnormDir = fullfile(raw_dir, subject, ['visit',visit],['session',session], 'fmri', ...
            %     Conditions{iCond}, 'mproc');
            % if ~exist(UnnormDir, 'dir')
            %     fprintf('Cannot find the mproc folder: %s\n', UnnormDir);
            %     %RunIndex(4) = 0;
            %     %RunCnt = RunCnt + 1;
            %     continue;
            % end
            % if  ~exist('paralist.voxdim','var') || VoxSize == '';
            %     tmp_dir = fullfile('/scratch/users',getenv('LOGNAME'), 'tmp_files');

            %     if ~exist(tmp_dir, 'dir')
            %         mkdir(tmp_dir);
            %     end
              
            %     temp_dir = fullfile(tmp_dir, [subject,['visit',visit],['session',session], ...
            %     Conditions{iCond},'_', tempname,]);
          
            %       if ~exist(temp_dir, 'dir')
            %         mkdir(temp_dir);
            %       else
            %         unix(sprintf('rm -rf %s', temp_dir));
            %         mkdir(temp_dir);
            %       end
            %       unix(sprintf('rm -rf %s', fullfile(temp_dir, '*')));
            %       unix(sprintf('cp -aLf %s %s', fullfile(UnnormDir, ['I*']), ...
            %         temp_dir));

            %     unix(sprintf('gunzip -fq %s', fullfile(temp_dir, 'I.nii.gz')));
            %     ImgFile = fullfile(temp_dir, 'I.nii');
            %     if ~exist(ImgFile, 'file')
            %         fprintf('Cannot find the image file: %s\n', ImgFile);
            %         %RunIndex(4) = 0;
            %         %RunCnt = RunCnt + 1;
            %         continue;
            %     end
            %     V = spm_vol(ImgFile);
            %     VoxSize = abs(V(1).mat(1,1));
          
            %     unix(sprintf('gzip -fq %s', fullfile(UnnormDir, 'I.nii')));
            % end
            % MvmntDir{RunCnt} = fullfile(project_dir,'/data/imaging/participants', ...
            %     subject,['visit',visit],['session',session], 'fmri', ...
            %     Conditions{iCond}, prep_folder);
            
            % MvmntFile = fullfile(MvmntDir{RunCnt}, 'rp_I.txt');
            % GSFile = fullfile(MvmntDir{RunCnt}, 'VolumRepair_GlobalSignal.txt');
            fprintf('---> Subject: %s | Visit: %s | Session: %s | Task: %s | VoxelSize: %f\n', ...
                subject, visit, session, Conditions{iCond}, VoxSize);
            MvmntDir=fullfile(project_dir,'/data/imaging/participants', ...
                 subject,['visit',visit],['session',session], 'fmri', ...
                 Conditions{iCond}, prep_folder);
            MvmntFile = fullfile(MvmntDir, 'rp_I.txt');
            GSFile = fullfile(MvmntDir, 'VolumRepair_GlobalSignal.txt');
            
            if ~exist(MvmntFile, 'file') || ~exist(GSFile, 'file')
                fprintf('Cannot find movement file or global signal file: %s\n', subject);
                %RunIndex(4) = 0;
               % RunCnt = RunCnt + 1;
                continue;
            else
                %-Load rp_I.txt
                rp_I = load(MvmntFile);
                
                %-translation and rotation movement
                TransMvmnt = rp_I(:, 1:3);
                %RotMvmnt = 50.*rp_I(:, 4:6);
                RotMvmnt = rp_I(:, 4:6);
                TotalMvmnt = [TransMvmnt, RotMvmnt];
                TotalDisp = sqrt(sum(TotalMvmnt.^2, 2));
                
                ScanToScanTrans = abs(diff(TransMvmnt));
                %ScanToScanRot = 50.*abs(diff(rp_I(:, 4:6)));
                ScanToScanRot = abs(diff(rp_I(:, 4:6)));
                ScanToScanMvmnt = [ScanToScanTrans, ScanToScanRot];
                
                ScanToScanTotalDisp = sqrt(sum(ScanToScanMvmnt.^2, 2));
                
                
                TransRange = range(rp_I(:, 1:3));
                %RotRange = 180/pi*range(rp_I(:, 4:6));
                RotRange = range(rp_I(:, 4:6));
                MvmntStats(1) = TransRange(1);
                MvmntStats(2) = TransRange(2);
                MvmntStats(3) = TransRange(3);
                MvmntStats(4) = RotRange(1);
                MvmntStats(5) = RotRange(2);
                MvmntStats(6) = RotRange(3);
                
                MvmntStats(7) = max(TotalDisp);
                
                MvmntStats(8) = max(ScanToScanTotalDisp);
                
                MvmntStats(9) = mean(ScanToScanTotalDisp);
                
                MvmntStats(10) = sum(ScanToScanTotalDisp > (ScanToScanCrit*VoxSize));
                
                mvnout_idx = (find(ScanToScanTotalDisp > (ScanToScanCrit*VoxSize)))'+1;
                
                g = load(GSFile);
                gsigma = std(g);
                gmean = mean(g);
                mincount = 5*gmean/100;
                %z_thresh = max( z_thresh, mincount/gsigma );
                z_thresh = mincount/gsigma;        % Default value is PercentThresh.
                z_thresh = 0.1*round(z_thresh*10); % Round to nearest 0.1 Z-score value
                zscoreA = (g - mean(g))./std(g);  % in case Matlab zscore is not available
                glout_idx = (find(abs(zscoreA) > z_thresh))';
                
                MvmntStats(11) = length(glout_idx);
                
                union_idx = unique([1; mvnout_idx(:); glout_idx(:)]);
                MvmntStats(12) = length(union_idx)/length(g)*100;
                
                CondStatsFile = fullfile(project_dir,'/data/imaging/participants', ...
                    subject,['visit',visit],['session',session], 'fmri', ...
                    Conditions{iCond}, prep_folder, 'MovementStats.txt');
                
                fid = fopen(CondStatsFile, 'w+');
                fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'TASK', 'PID', 'Session', 'Visit', ...
                    'Range x', 'Range y', 'Range z', 'Range pitch', 'Range roll', 'Range yaw', 'Max Displacement', ...
                    'Max Scan-to-Scan Displacement', 'Mean Scan-to-Scan Displacement', 'Num Scans > 0.5 Voxel Displacement', ...
                    'Num Scans > 5% Global Signal', '% of Volumes Repaired');
                fprintf(fid, '%s\t%s\t%s\t%s\t', Conditions{iCond}, subject, session, visit);
                fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', MvmntStats(1), ...
                    MvmntStats(2), MvmntStats(3), ...
                    MvmntStats(4), MvmntStats(5), ...
                    MvmntStats(6), MvmntStats(7), ...
                    MvmntStats(8), MvmntStats(9), ...
                    MvmntStats(10), MvmntStats(11), ...
                    MvmntStats(12));
                fclose(fid);
                
                %RunCnt = RunCnt + 1;
            end
            catch
                continue
            end
        end

end
cd(CurrentDir);
disp('------------------------------------------------------------------');
fprintf('Analysis is done!\n');
fprintf('Please check: MovementMissingInfo.txt (if any) for subjects that do not have movement files\n');
fprintf('Please check: MovementSummaryStats.txt for summary stats\n');
disp('------------------------------------------------------------------');
toc

