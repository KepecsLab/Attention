       
function S = initPhotometry2(S)
    %% NIDAQ :: Set up NIDAQ data aquisision
    global nidaq BpodSystem

    daq.reset; % currently re-initializing nidaq with every acquisition- see preparePhotometryAcq
    daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true); % Necessary for this Nidaq
    
    % retrieve machine specific settings
    try
        addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
        phSettings = machineSpecific_Photometry2;
        rmpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict        
    catch
        addpath(genpath(fullfile(BpodSystem.BpodPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
        phSettings = machineSpecific_Photometry2;
        rmpath(genpath(fullfile(BpodSystem.BpodPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict
    end        
    
%     % defaults
%     phDefaults = {...
%         'TriggerConnection', 1;...
%         'LED1_f', 211;...
%         'LED2_f', 531;...
%         'duration', 6;...
%         'sample_rate', 6100;...
%         'ai_channelNames', {'ai0','ai1','ai2'};...
%         'ao_channelNames', {'ao0', 'ao1'};...
%         'IsContinuous', 0;... % whether to save all data at end of acquisition or intermittently (advantage of at end is that you acquire exactly the right number of samples for your behavioral trial, advantage of intermittently is that you can have more flexible acquisitions (say if mouse behavior terminates trial early)
%         'updateInterval', 0.1;... % when isContinuous = 1, controls how frequently new data is pulled off the nidaq card for saving
%         };
%     % defaults linked to Bpod parameter GUI
%     phGUIDefaults = {...
%         'LED1_amp', 1.5;...
%         'LED2_amp', 5;...
%         };
    phDefaults = phSettings.phDefaults;
    phGUIDefaults = phSettings.phGUIDefaults;

    
%     set defaults
    for counter = 1:size(phDefaults, 1)
        if ~isfield(S.nidaq, phDefaults{counter, 1})
            S.nidaq.(phDefaults{counter, 1}) = phDefaults{counter, 2};
        end
    end
    for counter = 1:size(phGUIDefaults, 1)
        if ~isfield(S.GUI, phGUIDefaults{counter, 1})
            S.GUI.(phGUIDefaults{counter, 1}) = phGUIDefaults{counter, 2};
        end
    end    
    
    %Note! 7/21/17- stupid to hard code nDemodChannels (But it doesn't
    %matter because it is just used to initialize empty cell arrays)
%     nDemodChannels = 2; % right now number of AM photometry channels hard coded == 2
    nDemodChannels = 4; % right now number of AM photometry channels hard coded == 4    11/22/2024_SL
    
    % SYNCHRONIZE NIDAQ GLOBAL VARIABLE:
    % synchronize current settings between maching-specific defaults,
    % settings hard coded in protocol (   S.nidaq.(exampleField)  )   and
    % settings selected in GUI   (      S.GUI.(exampleField)      )    
    syncPhotometrySettings2; % 11/20/24  SJ    
    
    nidaq.ai_channelNames          = S.nidaq.ai_channelNames;       % 4 channels might make sense to have 2 supplementary channels for fast photodiodes measuring excitation light later
    nidaq.ai_data = [];
    % Define parameters for analog outputs.
    nidaq.ao_channelNames          = S.nidaq.ao_channelNames;
    nidaq.ao_data = [];
    nidaq.aiChannels = {};
    nidaq.aoChannels = {};
    
    
    %% fields for online analysis
    nidaq.online.currentDemodData = cell(1, nDemodChannels);
    nidaq.online.currentXData = []; % x data starts from 0 (thus independent of protocol), add/subtract offset to redefine zero in protocol-specific funtions
    nidaq.online.trialXData = {};
    nidaq.online.trialDemodData = cell(1, nDemodChannels);
    nidaq.online.decimationFactor = 1000;
    
    % initialize Photometry variables within PluginObjects
    BpodSystem.PluginObjects.Photometry.trialDFF = cell(1, nDemodChannels);

