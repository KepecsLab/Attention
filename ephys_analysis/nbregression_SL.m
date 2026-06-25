function nbregression_SL(I,issave)
%NBREGRESSION   Linear regression.
%   NBREGRESSION(I,ISSAVE) calculates linear regression for firing rate as
%   dependent variable and task-related variables as regressors.
%       I - index set to CELLIDLIST (see CellBase documentation); if empty
%           or not specified, a predefined set of basal forebrain cells is
%           used.
%       ISSAVE - controls saving
%
%   See also NBPERFORMANCECURVES, NBTUNINGCURVES and NBRTCURVES.

%   Balazs Hangya, Cold Spring Harbor Laboratory
%   1 Bungtown Road, Cold Spring Harbor
%   balazs.cshl@gmail.com
%   6-Oct-2012

%   Edit log: BH 10/6/12

%   Modified by: Shujing Li, Cold Spring Harbor Laboratory / Washington
%   University in St. Louis
%   shujing@wustl.com
 
% Pass the control to the user in case of error
dbstop if error
if ~isequal(whichcb,'NB')
    choosecb('NB')    % swhitch to 'NB' CellBase
end

% Directories
% group = 'All';
% global DATAPATH
% fs = filesep;
% resdir = [DATAPATH 'NB' fs 'regression_newdata' fs group fs 'slowfastexclude' fs];   % results directory
resdir = ['C:\Kepecs lab\PV project\Balazs data\NBPV\' whichcb '_response_profiles_eg\'];

% % Input argument check
% error(nargchk(0,2,nargin))
% if nargin < 2
%     issave = false;   % saving is controled by the second input argument
%     disp('Results will not be saved.')
% end
% if nargin < 1
%     I = [];   % initialize list of cell IDs
% end
% 
% % List of cellIDs
% if isempty(I)
%     switch group
%         case 'ChAT'
%             ChAT = selectcell(['"ChAT+"==1&"ID_PC">20&"Lr_PC"<0.15&"validity"==1&' ...
%                 'ismember("Area1",{''GP'',''GP/SI'',''SI'',''IC'',''RT/IC'',''EP'',''EA'',''EAC''})']);  % identified ChAT+ cells
%             I = ChAT;
%             
%         case 'pChAT'
%             pChAT = selectcell(['"pChAT+"==1&"ID_PC">20&"Lr_PC"<0.15&"validity"==1&' ...
%                 'ismember("Area1",{''GP'',''GP/SI'',''SI'',''IC'',''RT/IC'',''EP'',''EA'',''EAC''})']);  % putative ChAT+ cells
%             I = pChAT;
%             
%         case 'allChAT'
%             ChAT = selectcell(['"ChAT+"==1&"ID_PC">20&"Lr_PC"<0.15&"validity"==1&' ...
%                 'ismember("Area1",{''GP'',''GP/SI'',''SI'',''IC'',''RT/IC'',''EP'',''EA'',''EAC''})']);  % identified ChAT+ cells
%             pChAT = selectcell(['"pChAT+"==1&"ID_PC">20&"Lr_PC"<0.15&"validity"==1&' ...
%                 'ismember("Area1",{''GP'',''GP/SI'',''SI'',''IC'',''RT/IC'',''EP'',''EA'',''EAC''})']);  % putative ChAT+ cells
%             I = [ChAT pChAT];
%             
%         case 'PV'
%             PV = selectcell(['"PV+"==1&"ID_PC">20&"Lr_PC"<0.15&"validity"==1&' ...
%                 'ismember("Area1",{''GP'',''GP/SI'',''SI'',''IC'',''RT/IC'',''EP'',''EA'',''EAC''})']);  % identified PV+ cells
%             I = PV;
%             
%         case 'All'
%             loadcb
%             I = CELLIDLIST;
%             
%         case 'activated'
%             activated = getgroups;   % load groups of activated and inhibited NB cells
%             I = activated;
%             
%         case 'inhibited'
%             [activated inhibited] = getgroups;   % load groups of activated and inhibited NB cells
%             I = inhibited;
%     end
% end
I = I(:)';   % convert to row vector

% Regression
main(I,resdir,issave);

% -------------------------------------------------------------------------
function [R p] = main(I,resdir,issave)

% Load CellBase if indices to CELLIDLIST are passed
if isnumeric(I)
    loadcb
    I = CELLIDLIST(I);
end

% Preallocate
problem_ids = {};   % cellIDs for which PSTH failed
problem_msg = {};   % corresponding error messages
NumCell = length(I);  % number of cells
fnm = [resdir 'temp.mat'];
p = struct('iti',{},'iti025',{},'iti05',{},'iti10',{},...
    'stim_10_0',{},'stim_05_0',{},'stim_10_075',{},'stim_075_05',{},'stim_05_025',{},'stim_025_0',{},...
    'stim_10_09',{},'stim_09_08',{},'stim_08_07',{},'stim_07_06',{},'stim_06_05',{},'stim_05_04',{},...
    'stim_04_03',{},'stim_03_02',{},'stim_02_01',{},'stim_01_0',{},...
    'stim_20_18',{},'stim_18_16',{},'stim_16_14',{},'stim_14_12',{},'stim_12_10',{},...
    'stim_10_08',{},'stim_08_06',{},'stim_06_04',{},'stim_04_02',{},'stim_02_0',{});
R = struct('iti',{},'iti025',{},'iti05',{},'iti10',{},...
    'stim_10_0',{},'stim_05_0',{},'stim_10_075',{},'stim_075_05',{},'stim_05_025',{},'stim_025_0',{},...
    'stim_10_09',{},'stim_09_08',{},'stim_08_07',{},'stim_07_06',{},'stim_06_05',{},'stim_05_04',{},...
    'stim_04_03',{},'stim_03_02',{},'stim_02_01',{},'stim_01_0',{},...
    'stim_20_18',{},'stim_18_16',{},'stim_16_14',{},'stim_14_12',{},'stim_12_10',{},...
    'stim_10_08',{},'stim_08_06',{},'stim_06_04',{},'stim_04_02',{},'stim_02_0',{}, 'hitinx',{});
% [R p] = deal(struct('stim2resp',{}));
% [R p] = deal(nan(1,NumCell));
for k = 1:NumCell
    cellid = I{k};
    disp(cellid)

    try
        [R(k) p(k)] = regression_analysis_SL(cellid);
        if issave && (mod(k,50) == 0 || isequal(k,NumCell))
            save(fnm,'p','R','I','problem_ids','problem_msg')   % save temporary file
        end
        
    catch ME
        
        % Error handling
        problem_ids{end+1} = cellid;  %#ok<AGROW> % collect cellIDs resulting in error
        problem_msg{end+1} = ME.message;  %#ok<AGROW> % store corresponding error messages
        disp(['Something went wrong for cell ' cellid '.'])
        disp(ME.message)   % display error message
    end
end

% Save
if issave
    fnm = [resdir 'regression_results.mat'];
    save(fnm,'p','R','I','problem_ids','problem_msg')   % save final results
end
