function processPhotometryOnline(currentTrial)
    % calculate baseline F and dF/F, this function is seperate from
    % phDemodOnline because you need a baseline period which is specific to
    % a given behavioral protocol

    phDemodOnline(currentTrial);

    
    global BpodSystem nidaq    
    baselinePeriod = BpodSystem.PluginObjects.Photometry.baselinePeriod;
    blStartP = bpX2pnt(baselinePeriod(1), nidaq.sample_rate/nidaq.online.decimationFactor);
    blEndP = bpX2pnt(baselinePeriod(2), nidaq.sample_rate/nidaq.online.decimationFactor);
    
    trialBaselines = zeros(1,2);
    channelsOn = nidaq.channelsOn;
    for ch = channelsOn % 2 channels are hard coded
        chData = nidaq.online.trialDemodData{currentTrial, ch};
        bl = nanmean(chData(blStartP:blEndP));
        dFF = (chData - bl) ./ bl;
        BpodSystem.PluginObjects.Photometry.trialDFF{ch}(currentTrial, :) = dFF;
        trialBaselines(ch) = bl;
    end
    BpodSystem.PluginObjects.Photometry.blF(currentTrial, :) = trialBaselines;
    