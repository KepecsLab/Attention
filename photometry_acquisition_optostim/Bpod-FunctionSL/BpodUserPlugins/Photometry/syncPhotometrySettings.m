function syncPhotometrySettings    
%     function attempts to sync nidaq settings (part of
%     BpodSystem.Settings) with nidaq structure (containing nidaq session)
%     Note conventions below (somewhat historical):
    % convention is to have GUI-linked nidaq settings stored as
    % S.GUI.nidaqSetting and non-GUI-linked nidaq settings stored as
    % S.nidaq.nidaqSetting
    % function first attempts to find a GUI-linked version setting to sync, then
    % tries non-GUI-linked setting
    global nidaq BpodSystem
    S = BpodSystem.ProtocolSettings;   
    
    % these fields will either be specified in 
    syncFields = {'LED1_f', 'LED2_f', 'duration', 'sample_rate', 'LED1_amp', 'LED2_amp', 'IsContinuous', 'updateInterval'};    
    
    for counter = 1:length(syncFields)        
        sf = syncFields{counter};
        
        try
            nidaq.(sf) = S.GUI.(sf);
        catch
            try
                nidaq.(sf) = S.nidaq.(sf);
            catch
            end
        end
    end
    
    %% determine which channels are being acquired and sync the nidaq.channelsOn list, too.
    nidaq.channelsOn = [];
    ch1on = 0; ch2on = 0;
    try
        if S.GUI.ch1
            ch1on = 1;
        end
    catch
        if S.GUI.LED1_amp > 0 % for backwards compatibility, I used to let LED amp determine whether trial is acquired.  This became undesireable- e.g. if you want to look at crosstalk from one channel to another.
            ch1on = 1;
        end
    end
    
    try
        if S.GUI.ch2
            ch2on = 1;
        end
    catch
        if S.GUI.LED2_amp > 0
            ch2on = 1;
        end
    end    
    
    if ch1on
        nidaq.channelsOn = union(nidaq.channelsOn, 1);
    end
    
    if ch2on
        nidaq.channelsOn = union(nidaq.channelsOn, 2);
    end
    
    if isempty(nidaq.channelsOn)
        error('you need at least one acquisition channel turned on');
    end
    
    %% determine which aux channels are being acquired, use table GUI element for this
    nidaq.auxChannelsOn = [];
    nidaq.auxDownsample = []; % downsampled rates for each channel
%     nidaq.auxChannelNames = {}; % to be used in future
    nidaq.auxChannelNumbers = []; % which AI port on NI breakout board (e.g. 3 for AI3)
    
    if isfield(S.GUI, 'Aux')
        nidaq.auxChannelsOn = find(S.GUI.Aux.channelsOn);
        nidaq.auxDownsample = S.GUI.Aux.downsample(nidaq.auxChannelsOn);
        nidaq.auxChannelNumbers = S.GUI.Aux.channelNumbers(nidaq.auxChannelsOn);
    end
        
    
    