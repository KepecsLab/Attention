function processPhotometryAcq(currentTrial)
    global BpodSystem nidaq
    
%     wait(nidaq.session);
%     wait('nidaq.session');
    tic
    while ~nidaq.session.IsDone
        pause(0.05);
        if toc > 120
            error('what is going on');
        end
    end

%     pause(0.1); 
%     nidaq.session.stop() % Kills ~0.002 seconds after state matrix is done.
%     wait(nidaq.session) % Trying to wait until session is done - did we record the full session?
    
    % ensure outputs reset to zero
%     nidaq.session.outputSingleScan(zeros(1,length(nidaq.aoChannels)));

    %% Save data in BpodSystem format.   
    BpodSystem.Data.NidaqData{currentTrial, 1} = nidaq.ai_data(:, 1:length(nidaq.channelsOn)); %input photometry data
    BpodSystem.Data.NidaqData{currentTrial, 2} = nidaq.ref; % output data, now just parameters 5/29/17
    
    %% Downsample and Save Auxilliary Channels
    if ~isempty(nidaq.auxChannelsOn)
        
        BpodSystem.Data.AuxSettings(currentTrial).auxDownsample = nidaq.auxDownsample;
%         BpodSystem.Data.AuxSettings(currentTrial).auxChannelNames = nidaq.auxChannelNames;
        BpodSystem.Data.AuxSettings(currentTrial).auxChannelNumbers = nidaq.auxChannelNumbers;
        BpodSystem.Data.AuxSettings(currentTrial).auxChannelsOn = nidaq.auxChannelsOn;
        
        for counter = 1:length(nidaq.auxChannelsOn)
            channel = nidaq.auxChannelsOn(counter);
            rawData = nidaq.ai_data(:,length(nidaq.channelsOn) + counter);
            if ~isempty(rawData)
                [p, q] = rat(nidaq.auxDownsample(counter)/nidaq.sample_rate);   % coefficients for resampling    
                BpodSystem.Data.AuxData{currentTrial, nidaq.auxChannelNumbers(counter)} = resample(rawData, p, q); % put channel in column matching channel number (not necessarily consecutive)
            end
        end
    end
    