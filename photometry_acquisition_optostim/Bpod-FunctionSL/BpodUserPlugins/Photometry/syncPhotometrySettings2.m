function syncPhotometrySettings2    
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
    
    %% determine which channels are being acquired
    nidaq.channelsOn = []; nidaq.channelsOnOut = [];
    ch1on = 0; ch2on = 0; ch3on = 0; ch4on = 0; % Input to DAQ
    ch1onO = 0; ch2onO = 0;   % Output to DAQ
    try
        if S.GUI.LED1    
            ch1on = 1;
            ch1onO = 1;
            if S.GUI.BilateralOn  
                ch3on = 1;
            end
        end
    catch
        if S.GUI.LED1_amp > 0
            ch1on = 1;
            ch1onO = 1;
            if S.GUI.BilateralOn  
                ch3on = 1;
            end
        end
    end
    
    try
        if S.GUI.LED2
            ch2on = 1;
            ch2onO = 1;
            if S.GUI.BilateralOn  
                ch4on = 1;
            end
        end
    catch
        if S.GUI.LED2_amp > 0
            ch2on = 1;
            ch2onO = 1;
            if S.GUI.BilateralOn  
                ch4on = 1;
            end
        end
    end    
    
    if ch1on
        nidaq.channelsOn = [nidaq.channelsOn 1];
    end
    
    if ch2on
        nidaq.channelsOn = [nidaq.channelsOn 2];
    end
    
    if ch3on
        nidaq.channelsOn = [nidaq.channelsOn 3];
    end
    
    if ch4on
        nidaq.channelsOn = [nidaq.channelsOn 4];
    end
    
        
    if ch1onO
        nidaq.channelsOnOut = [nidaq.channelsOnOut 1];
    end
    
    if ch2onO
        nidaq.channelsOnOut = [nidaq.channelsOnOut 2];
    end
    
    if isempty(nidaq.channelsOnOut)
        error('you need at least one acquisition channel turned on');
    end
    
    