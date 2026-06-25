function phDemodOnline(currentTrial)
    global BpodSystem nidaq

    decimationFactor = nidaq.online.decimationFactor;
    lowCutoff = 15;
    mod_freq = [nidaq.LED1_f nidaq.LED2_f];
    
    for counter = 1:length(nidaq.channelsOn)
        ch = nidaq.channelsOn(counter);
%         %kludge
%         if mod_freq(ch)
%             nidaq.online.currentDemodData{ch} = phDemod(nidaq.ai_data(:,ch) - mean(nidaq.ai_data(:,ch)), nidaq.ao_data(:,ch), nidaq.sample_rate, mod_freq(ch), lowCutoff);
%         else
%             nidaq.online.currentDemodData{ch} = phDemod(nidaq.ai_data(:,ch), nidaq.ao_data(:,ch), nidaq.sample_rate, mod_freq(ch), lowCutoff);
%         end
        nidaq.online.currentDemodData{ch} = phDemod(nidaq.ai_data(:,counter), nidaq.ao_data(:,counter), nidaq.sample_rate, mod_freq(ch), lowCutoff);
        nidaq.online.trialDemodData{currentTrial, ch} = nidaq.online.currentDemodData{:, ch};
    end
%         nidaq.online.currentDemodData{1} = NaN(size(nidaq.ai_data(:,1)));
%     end
%     if nidaq.LED2_amp > 0    
%         nidaq.online.currentDemodData{2} = phDemod(nidaq.ai_data(:,2), nidaq.ao_data(:,2), nidaq.sample_rate, LED2_f, lowCutoff);    
%     else
%         nidaq.online.currentDemodData{2} = NaN(size(nidaq.ai_data(:,2)));
%     end
    %% generate x data, scale from 0 initially (you can add/subtract offsets to x data within downstream funtions)
    dT = 1/nidaq.sample_rate;
    nidaq.online.currentXData = 0:dT:nidaq.duration - dT;
    nidaq.online.currentXData = nidaq.online.currentXData(:); % make column vector

    
  %% pad or truncate if acquisition stopped short or long
    for ch = nidaq.channelsOn  
        if ~nidaq.IsContinuous
            samplesShort = length(nidaq.online.currentXData) - length(nidaq.online.trialDemodData{currentTrial, ch});
            if samplesShort > 0 % i.e. not 0
                nidaq.online.trialDemodData{currentTrial, ch} = [nidaq.online.trialDemodData{currentTrial, ch}; zeros(samplesShort, 1)];       
            elseif samplesShort < 0
                nidaq.online.trialDemodData{currentTrial, ch} = nidaq.online.trialDemodData{currentTrial, ch}(1:length(nidaq.online.currentXData));
            end     
        else
            nidaq.online.currentXData = nidaq.online.currentXData(1:size(nidaq.online.currentDemodData{ch}, 1));
        end

        nidaq.online.currentDemodData{ch} = nidaq.online.trialDemodData{currentTrial, ch};
        %% downsample and save trial data
        nidaq.online.trialDemodData{currentTrial, ch} = decimate(nidaq.online.currentDemodData{ch}, decimationFactor);
    end
    
    nidaq.online.trialXData = decimate(nidaq.online.currentXData, decimationFactor);
