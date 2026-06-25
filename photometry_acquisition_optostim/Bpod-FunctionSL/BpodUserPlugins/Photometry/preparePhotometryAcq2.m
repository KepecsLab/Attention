function S = preparePhotometryAcq2(S)
    % Updated 4/20/2017 Now resets daq with every new trial
    % prepares NIDAQ session    
    % S = Bpod settings structure (contains updated information about LED
    % intensity, etc.)
    global nidaq BpodSystem
    
    
    
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
    
    
%     maxDemodChannels = 2; % 
    maxDemodChannels = 4; % 
    
% sync nidaq settings (part of BpodSystem.Settings) with nidaq structure (containing nidaq session)
    syncPhotometrySettings2;
    
    % DO I NEED CHANNELNAMES NOW THAT i HAVE CHANNELS ON? 5/29/17
    nidaq.ai_channelNames          = S.nidaq.ai_channelNames;       
    nidaq.ai_data = [];
    % Define parameters for analog outputs.
    nidaq.ao_channelNames          = S.nidaq.ao_channelNames;
    nidaq.ao_data = [];
    nidaq.aiChannels = {};
    nidaq.aoChannels = {};
    
    %% fields for online analysis
    nidaq.online.currentDemodData = cell(1, maxDemodChannels);
    nidaq.online.currentXData = []; % x data starts from 0 (thus independent of protocol), add/subtract offset to redefine zero in protocol-specific funtions
    nidaq.online.trialXData = {};
    nidaq.online.trialDemodData = cell(1, maxDemodChannels);
    nidaq.online.decimationFactor = 1000;


    %% Set up session and channels
    nidaq.session = daq.createSession('ni');
    

    %% add inputs
    counter = 1;
    for ch = nidaq.channelsOn
%         if length(nidaq.session.Channels) < counter
            nidaq.aiChannels{counter} = addAnalogInputChannel(nidaq.session,S.nidaq.Device,ch - 1,'Voltage'); % - 1 because nidaq channels are zero based
            nidaq.aiChannels{counter}.TerminalConfig = 'SingleEnded';
            counter = counter + 1;
%         end
    end
%     %% add aux inputs, slightly different style, store channels as channels objects
%     if any(nidaq.auxChannelsOn)
%         nidaq.auxChannels = addAnalogInputChannel(nidaq.session,S.nidaq.Device,nidaq.auxChannelNumbers,'Voltage'); % - 1 because nidaq channels are zero based
%         nidaq.auxChannels.TerminalConfig = 'SingleEnded';
%     end
    
    %% add outputs
    counter = 1;
    for ch = nidaq.channelsOnOut
%         if length(nidaq.session.Channels) < (counter + length(nidaq.session.Channels))
            nidaq.aoChannels{counter} = nidaq.session.addAnalogOutputChannel(S.nidaq.Device,ch - 1, 'Voltage'); % - 1 because nidaq channels are zero based
            counter = counter + 1;
%         end
    end

    %% add trigger external trigger, if specified
    if S.nidaq.TriggerConnection
        addTriggerConnection(nidaq.session, 'external', [S.nidaq.Device '/' S.nidaq.TriggerSource], 'StartTrigger');
        nidaq.session.ExternalTriggerTimeout = 900; % something really long (15min), might be necessary during freely moving behavior when animal doesn't re-initiate trial for a while
    end
    
    %% Sampling rate and continuous updating (important for queue-ing ao data)

    nidaq.session.Rate = nidaq.sample_rate;
    if floor(nidaq.session.Rate) ~= nidaq.sample_rate
        error('*** need to handle case where true sample rate < requested sample rate ***');
    end

    if nidaq.IsContinuous
        nidaq.session.IsContinuous = true;
    else
        nidaq.session.IsContinuous = false; % would work with this set to true as well since setting the samples acquired callback to be equal to acq duration effectively makes it non-continous
    end
    
    
    %% create and cue data for output, add callback function
    updateLEDData2; 
    % data available notify must be set after queueing data
    if nidaq.IsContinuous
        nidaq.session.NotifyWhenDataAvailableExceeds = floor(nidaq.session.Rate * nidaq.updateInterval);         
        display(['data availableexceeds set at ' num2str(floor(nidaq.session.Rate * nidaq.updateInterval))]);
    else
        nidaq.session.NotifyWhenDataAvailableExceeds = floor(nidaq.session.Rate * nidaq.duration); % fire only at the end of acquisition
        display(['data availableexceeds set at ' num2str(floor(nidaq.session.Rate * nidaq.duration))]);
    end

    lh{1} = nidaq.session.addlistener('DataAvailable',@processNidaqData); 
    
    %%
    nidaq.ai_data = [];
    nidaq.session.prepare(); %Saves 50ms on startup time, perhaps more for repeats.
    nidaq.session.startBackground(); % takes ~0.1 second to start and release control.