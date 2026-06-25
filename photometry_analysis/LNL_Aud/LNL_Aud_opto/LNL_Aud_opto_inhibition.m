%%
sessions = bpLoadSessions;
%
TE = makeTE_LNL_Aud_opto(sessions);
%% save data in a base directory, code below creates a folder named according to subject (e.g. DAT_1) and sets the save path within
basepath = uigetdir;
sep = strfind(TE.filename{1}, '_');
subjectName = TE.filename{1}(1:sep(2)-1);
disp(subjectName);
savepath = fullfile(basepath, subjectName);
ensureDirectory(savepath);

%% extract peak trial dFF responses to cues and reinforcement and lick counts
% zero is defined as time of cue- see call to
% processTrialAnalysis_Photometry2
saveOn = 1; 
nSessions = max(TE.sessionIndex);
nTrials = length(TE.filename);
% TE.Answer = cellfun(@(x,y) max([x(1) y(1)]), TE.AnswerLick, TE.AnswerNoLick);
% AnswerZeros = cellfun(@(x,y) max([x(1) y(1)]), TE.AnswerLick, TE.AnswerNoLick);
usZeros = cellfun(@(x,y,z) max([x(1) y(1) z(1)]), TE.Reward, TE.Punish, TE.Neutral); %'Reward', 'Punish', 'Neutral'
TE.Us = usZeros;
winzeros = zeros(nTrials, 1);
usWindow1 = [0 1];
usWindow2 = [-0.4 0];
baselineWindow = [-1 0];
csWindow0 = [-1 0];
TE.fpWindow = cellfun(@(x) x(1) - x(end), TE.foreperiod);
mywin2 = [TE.fpWindow winzeros];
TE.fpLicks = countEventFromTE(TE, 'Port1In', [0 4], TE.PreCsRecording); 
winStart2 = cellfun(@(x) x(1), TE.Cue) - usZeros;
usWindow3 = [winStart2 winzeros];
TE.csLicks = countEventFromTE(TE, 'Port1In', usWindow3, TE.Us); % window for counting CS licks between cue to us
TE.usLicks = countEventFromTE(TE, 'Port1In', [0 1], usZeros); %wider window for counting US licks than photometry US response
TE.RT = calcEventLatency(TE, 'Port1In', TE.Cue, TE.Us); %count reaction time for slow licking after answer window but before US
TE.Answer = cellfun(@(x) x(1), TE.Cue) + TE.RT;
winStart = cellfun(@(x) x(1), TE.Cue) - TE.Answer;
mywin = [winStart winzeros];
% winEnd = [];
for counter = 1:nTrials
    if ~isnan(TE.RT(counter))
        winEnd(counter) = TE.RT(counter); % CS window ends at first answerlick or US which comes first 
    else 
        winEnd(counter) = -winStart2(counter);  % CS window ends at first answerlick or US which comes first       
    end
end
csWindow2 = [winzeros winEnd']; % CS window ends at first answerlick or US which comes first
csWindow1 = [0 nanmean(TE.RT)]; % CS window equal to average RT for NoLick trials

if saveOn
    save(fullfile(savepath, 'TE.mat'), 'TE');
%     disp(['*** Saved: ' fullfile(savepath, 'TE.mat')]);
end

%% exclude trials at end of session where the mouse stops licking
% rewardTrialsTrunc = filterTE(TE, 'trialType', [1]);
rewardTrialsTrunc = filterTE(TE, 'SoundValve', [1]);
usZeros = cellfun(@(x,y,z) max([x(1) y(1) z(1)]), TE.Reward, TE.Punish, TE.Neutral); %'Reward', 'Punish', 'Neutral'
usEnds = cellfun(@(x) x(end), TE.PostUsRecording); %'Reward', 'Punish', 'Neutral'
TE.latency = calcEventLatency(TE, 'Port1In', usZeros, usEnds);
truncateSessionsFromTE_SL(TE, 'init', 'usLicks', rewardTrialsTrunc);
% left/right arrow to adjust truncation point.  up/down arrow to switch
% sessions 'u' to update
%% generate trial lookups for different combinations of conditions
    validTrials = filterTE(TE, 'reject', 0);
    badTrials = isnan(cellfun(@(x) x(1), TE.Cue));
    allTrials = filterTE(TE, 'reject', 0) & ~badTrials; 

    fpLickTrials = filterTE(TE, 'reject', 0) & (TE.fpLicks.count > 0);
    fpLickNoLaser = filterTE(TE, 'StimAmp', 0, 'reject', 0) & fpLickTrials;
    fpLickLaser = filterTE(TE, 'StimAmp', 5, 'reject', 0) & fpLickTrials;
    fpLickLaser1 = filterTE(TE, 'StimFreq', 0.5, 'reject', 0) & fpLickTrials;
    fpLickLaser10 = filterTE(TE, 'StimFreq', 10, 'reject', 0) & fpLickTrials;
    fpLickLaser20 = filterTE(TE, 'StimFreq', 20, 'reject', 0) & fpLickTrials;
    fpLickLaser30 = (filterTE(TE, 'StimFreq', 30) | filterTE(TE, 'StimFreq', 31.25, 'reject', 0)) & fpLickTrials;
    
    Sound1Trials = filterTE(TE, 'SoundValveIndex', 1, 'reject', 0) & ~badTrials;
    Sound2Trials = filterTE(TE, 'SoundValveIndex', 2, 'reject', 0) & ~badTrials; 
    Sound3Trials = filterTE(TE, 'SoundValveIndex', 3, 'reject', 0) & ~badTrials;
    Sound4Trials = filterTE(TE, 'SoundValveIndex', 4, 'reject', 0) & ~badTrials;
    uncuedTrials = filterTE(TE, 'SoundValveIndex', 0, 'reject', 0) & ~badTrials;
    
    anticipTrials = TE.csLicks.count >= 1;
    noanticipTrials = TE.csLicks.count < 1;
    
    Sound1Lick = Sound1Trials & anticipTrials;
    Sound1NoLick = Sound1Trials & noanticipTrials;
    Sound2Lick = Sound2Trials & anticipTrials;
    Sound2NoLick = Sound2Trials & noanticipTrials;
    Sound3Lick = Sound3Trials & anticipTrials;
    Sound3NoLick = Sound3Trials & noanticipTrials;
    Sound4Lick = Sound4Trials & anticipTrials;
    Sound4NoLick = Sound4Trials & noanticipTrials;    

    rewardTrials = (cellfun (@(x) x(1), TE.Reward) > 0) & ~badTrials;
    punishTrials = (cellfun (@(x) x(1), TE.Punish) > 0) & ~badTrials;
    neutralTrials = (cellfun (@(x) x(1), TE.Neutral) > 0) & ~badTrials;
    uncuedReward = uncuedTrials & rewardTrials;
    uncuedPunish = uncuedTrials & punishTrials;
    
    hitTrials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'reject', 0) & ~badTrials;
    missTrials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'nolick', 'reject', 0) & ~badTrials;
    FATrials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'reject', 0) & ~badTrials;
    CRTrials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'nolick', 'reject', 0) & ~badTrials;    
     
    Sound1Reward =  Sound1Trials & rewardTrials;
    Sound1Neutral = Sound1Trials & neutralTrials;
    Sound2Reward = Sound2Trials & rewardTrials;
    Sound2Neutral = Sound2Trials & neutralTrials; 
    Sound3Reward = Sound3Trials & rewardTrials;
    Sound3Neutral = Sound3Trials & neutralTrials; 
    Sound4Punish = Sound4Trials & punishTrials;
    Sound4Neutral = Sound4Trials & neutralTrials;     
  
    Sound1LickReward = Sound1Lick & rewardTrials;
    Sound1LickNeutral = Sound1Lick & neutralTrials;
    Sound1NoLickReward = Sound1NoLick & rewardTrials;
    Sound1NoLickNeutral = Sound1NoLick & neutralTrials;
    
    Sound4LickPunish = Sound4Lick & punishTrials;
    Sound4LickNeutral = Sound4Lick & neutralTrials;
    Sound4NoLickReward = Sound4NoLick & punishTrials;
    Sound4NoLickNeutral = Sound4NoLick & neutralTrials;         

    Laser30Trials = (filterTE(TE, 'StimFreq', 30) | filterTE(TE, 'StimFreq', 31.25, 'reject', 0)) & ~badTrials;  
    Laser20Trials = filterTE(TE, 'StimFreq', 20, 'reject', 0) & ~badTrials;
    Laser10Trials = filterTE(TE, 'StimFreq', 10, 'reject', 0) & ~badTrials;
    Laser5Trials = filterTE(TE, 'StimFreq', 5, 'reject', 0) & ~badTrials;
    Laser1Trials = filterTE(TE, 'StimFreq', 0.5, 'reject', 0) & ~badTrials;
%     Laser1Trials = filterTE(TE, 'StimFreq', 0.2, 'reject', 0) & ~badTrials;
    LaserTrials = filterTE(TE, 'StimAmp', 5, 'reject', 0) & ~badTrials;
    NoLaserTrials = filterTE(TE, 'StimAmp', 0, 'reject', 0) & ~badTrials;
    LickNoLaser2 = anticipTrials & NoLaserTrials;
    LickNoLaser = filterTE(TE, 'TrialOutcome', 1, 'StimAmp', 0, 'reject', 0) & ~badTrials;
    LickLaser = filterTE(TE, 'TrialOutcome', 1, 'StimAmp', 5, 'reject', 0) & ~badTrials;
    NoLickNoLaser2 = noanticipTrials & NoLaserTrials;
    NoLickNoLaser = filterTE(TE, 'TrialOutcome', -1, 'StimAmp', 0, 'reject', 0) & ~badTrials;
    NoLickLaser = filterTE(TE, 'TrialOutcome', -1, 'StimAmp', 5, 'reject', 0) & ~badTrials;
    LickLaserTrials = filterTE(TE, 'TrialOutcome', 1, 'StimAmp', 5, 'reject', 0) & ~badTrials;
    LickLaser30Trials = filterTE(TE, 'TrialOutcome', 1)  & Laser30Trials; 
    LickLaser20Trials = filterTE(TE, 'TrialOutcome', 1, 'reject', 0) & Laser20Trials & ~badTrials;
    LickLaser10Trials = filterTE(TE, 'TrialOutcome', 1, 'reject', 0) & Laser10Trials & ~badTrials;
    LickLaser5Trials = filterTE(TE, 'TrialOutcome', 1, 'reject', 0) & Laser5Trials & ~badTrials;
    LickLaser1Trials = filterTE(TE, 'TrialOutcome', 1, 'reject', 0) & Laser1Trials & ~badTrials;
%     NoLickLaser30Trials = filterTE(TE, 'TrialOutcome', -1, 'StimFreq', 30, 'reject', 0) & ~badTrials;
    NoLickLaser30Trials = filterTE(TE, 'TrialOutcome', -1) & Laser30Trials & ~badTrials;
    NoLickLaser20Trials = filterTE(TE, 'TrialOutcome', -1, 'reject', 0) & Laser20Trials & ~badTrials;
    NoLickLaser10Trials = filterTE(TE, 'TrialOutcome', -1, 'reject', 0) & Laser10Trials & ~badTrials;
    NoLickLaser5Trials = filterTE(TE, 'TrialOutcome', -1, 'reject', 0) & Laser5Trials & ~badTrials;
    NoLickLaser1Trials = filterTE(TE, 'TrialOutcome', -1, 'reject', 0) & Laser1Trials & ~badTrials;
    
    Sound1Laser = Sound1Trials & LaserTrials;
    Sound1Laser30 = Sound1Trials & Laser30Trials;
    Sound1Laser20 = Sound1Trials & Laser20Trials;
    Sound1Laser10 = Sound1Trials & Laser10Trials;
    Sound1Laser5 = Sound1Trials & Laser5Trials;
    Sound1Laser1 = Sound1Trials & Laser1Trials;
    Sound1NoLaser = Sound1Trials & NoLaserTrials;
    Sound2Laser = Sound2Trials & LaserTrials;
    Sound2Laser30 = Sound2Trials & Laser30Trials;
    Sound2Laser20 = Sound2Trials & Laser20Trials;
    Sound2Laser10 = Sound2Trials & Laser10Trials;
    Sound2Laser5 = Sound2Trials & Laser5Trials;
    Sound2Laser1 = Sound2Trials & Laser1Trials;
    Sound2NoLaser = Sound2Trials & NoLaserTrials;
    Sound3Laser = Sound3Trials & LaserTrials;
    Sound3Laser30 = Sound3Trials & Laser30Trials;
    Sound3Laser20 = Sound3Trials & Laser20Trials;
    Sound3Laser10 = Sound3Trials & Laser10Trials;
    Sound3Laser5 = Sound3Trials & Laser5Trials;
    Sound3Laser1 = Sound3Trials & Laser1Trials;
    Sound3NoLaser = Sound3Trials & NoLaserTrials;
    Sound4Laser = Sound4Trials & LaserTrials;
    Sound4Laser30 = Sound4Trials & Laser30Trials;
    Sound4Laser20 = Sound4Trials & Laser20Trials;
    Sound4Laser10 = Sound4Trials & Laser10Trials;
    Sound4Laser5 = Sound4Trials & Laser5Trials;
    Sound4Laser1 = Sound4Trials & Laser1Trials;
    Sound4NoLaser = Sound4Trials & NoLaserTrials;
    
    hitLaser = hitTrials & LaserTrials;
    hitLaser30 = hitTrials & Laser30Trials;
    hitLaser20 = hitTrials & Laser20Trials;
    hitLaser10 = hitTrials & Laser10Trials;
    hitLaser5 = hitTrials & Laser5Trials;
    hitLaser1 = hitTrials & Laser1Trials;
    hitNoLaser = hitTrials & NoLaserTrials;
    
    missLaser = missTrials & LaserTrials;
    missLaser30 = missTrials & Laser30Trials;
    missLaser20 = missTrials & Laser20Trials;
    missLaser10 = missTrials & Laser10Trials;
    missLaser5 = missTrials & Laser5Trials;
    missLaser1 = missTrials & Laser1Trials;
    missNoLaser = missTrials & NoLaserTrials;
    
    FALaser = FATrials & LaserTrials;
    FALaser30 = FATrials & Laser30Trials;
    FALaser20 = FATrials & Laser20Trials;
    FALaser10 = FATrials & Laser10Trials;
    FALaser5 = FATrials & Laser5Trials;
    FALaser1 = FATrials & Laser1Trials;
    FANoLaser = FATrials & NoLaserTrials;
    
    CRLaser = CRTrials & LaserTrials;
    CRLaser30 = CRTrials & Laser30Trials;
    CRLaser20 = CRTrials & Laser20Trials;
    CRLaser10 = CRTrials & Laser10Trials;
    CRLaser5 = CRTrials & Laser5Trials;
    CRLaser1 = CRTrials & Laser1Trials;
    CRNoLaser = CRTrials & NoLaserTrials;
        
%     satedTrials = filterTE(TE, 'reject', 1) & filterTE(TE, 'sessionIndex', [1:4]) & ~badTrials;
    satedTrials = filterTE(TE, 'reject', 1) & ~badTrials;
    satedSound1 = filterTE(TE, 'SoundValveIndex', 1, 'reject', 1) & satedTrials;
    satedSound4 = filterTE(TE, 'SoundValveIndex', 4, 'reject', 1) & satedTrials;
    satedLaser30 = (filterTE(TE, 'StimFreq', 30) | filterTE(TE, 'StimFreq', 31.25, 'reject', 1)) & satedTrials;  
    satedLaser20 = filterTE(TE, 'StimFreq', 20, 'reject', 1) & satedTrials;
    satedLaser10 = filterTE(TE, 'StimFreq', 10, 'reject', 1) & satedTrials;
    satedLaser5 = filterTE(TE, 'StimFreq', 5, 'reject', 1) & satedTrials;
    satedLaser1 = filterTE(TE, 'StimFreq', 0.5, 'reject', 1) & satedTrials;
    satedLaser = filterTE(TE, 'StimAmp', 5, 'reject', 1) & satedTrials;
    satedNoLaser = filterTE(TE, 'StimAmp', 0, 'reject', 1) & satedTrials;
    
    if ismember(60, TE.SoundAmplitude) 
        t50Trials = filterTE(TE, 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        t40Trials = filterTE(TE, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        t30Trials = filterTE(TE, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        t20Trials = filterTE(TE, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;

        Sound1_50_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        Sound1_40_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Sound1_30_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound1_20_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound1_3020_Trials = Sound1_30_Trials + Sound1_20_Trials;
        Sound1_5040_Trials = Sound1_50_Trials + Sound1_40_Trials;

        Sound4_50_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        Sound4_40_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Sound4_30_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound4_20_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound4_3020_Trials = Sound4_30_Trials + Sound4_20_Trials;
        Sound4_5040_Trials = Sound4_50_Trials + Sound4_40_Trials;

        hit50Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        hit40Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        hit30Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        hit20Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        hit3020Trials = hit30Trials + hit20Trials;
        hit5040Trials = hit50Trials + hit40Trials;

        FA50Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        FA40Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        FA30Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        FA20Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        FA3020Trials = FA30Trials + FA20Trials;
        FA5040Trials = FA50Trials + FA40Trials;

        LickTrials = filterTE(TE, 'LickAction', 'lick', 'reject', 0) & ~badTrials; 
        Lick50Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        Lick40Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Lick30Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Lick20Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
    else
        t50Trials = filterTE(TE, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        t40Trials = filterTE(TE, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        t30Trials = filterTE(TE, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        t20Trials = filterTE(TE, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;

        Sound1_50_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Sound1_40_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound1_30_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound1_20_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        Sound1_3020_Trials = Sound1_30_Trials + Sound1_20_Trials;
        Sound1_5040_Trials = Sound1_50_Trials + Sound1_40_Trials;

        Sound4_50_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Sound4_40_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound4_30_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound4_20_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        Sound4_3020_Trials = Sound4_30_Trials + Sound4_20_Trials;
        Sound4_5040_Trials = Sound4_50_Trials + Sound4_40_Trials;

        hit50Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        hit40Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        hit30Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        hit20Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        hit3020Trials = hit30Trials + hit20Trials;
        hit5040Trials = hit50Trials + hit40Trials;

        FA50Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        FA40Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        FA30Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        FA20Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        FA3020Trials = FA30Trials + FA20Trials;        
        FA5040Trials = FA50Trials + FA40Trials;

        LickTrials = filterTE(TE, 'LickAction', 'lick', 'reject', 0) & ~badTrials; 
        Lick50Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Lick40Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Lick30Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Lick20Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
    end
    
%    write badTrials into TE   
    TE.badTrials = [];
       for counter = 1:nTrials
            if badTrials(counter) > 0
                TE.badTrials(counter) = true;
                
            else 
                TE.badTrials(counter) = false;
            end         
       end       
        if saveOn
            save(fullfile(savepath, 'TE.mat'), 'TE');
            disp(['*** Saved: ' fullfile(savepath, 'TE.mat')]);
        end

    % comparison of Hit and FA rate w/o laser
    t2 = struct(...
    'all', [],...
    'pSess', zeros(nSessions, 1)...
    );
    s2 = struct(...
        'NoLaser', t2,...
        'Laser', t2,...
        'Laser10', t2,...
        'Laser20', t2,...
        'dL', t2...
        );
    HitRate_pooled = struct(...
        'Hit', s2,...
        'Hit50', s2,...
        'Hit40', s2,...
        'Hit30', s2,...
        'Hit20', s2,...
        'Hit5040', s2,...
        'Hit3020', s2...
        );
    FARate_pooled = struct(...
        'FA', s2,...
        'FA50', s2,...
        'FA40', s2,...
        'FA30', s2,...
        'FA20', s2,...
        'FA5040', s2,...
        'FA3020', s2...
        );
for counter = 1:nSessions 
    ordering2 = {...
        'Hit', hitTrials, Sound1Trials;...
        'Hit50', hit50Trials, Sound1_50_Trials;...
        'Hit40', hit40Trials, Sound1_40_Trials;...
        'Hit30', hit30Trials, Sound1_30_Trials;...
        'Hit20', hit20Trials, Sound1_20_Trials;...  
        'Hit5040', hit5040Trials, Sound1_5040_Trials;...
        'Hit3020', hit3020Trials, Sound1_3020_Trials;...
        };
        for c2 = 1:size(ordering2,1)
            NoLaserdata = length(find((ordering2{c2, 2}) & NoLaserTrials & (TE.sessionIndex == counter))) / length(find((ordering2{c2, 3}) & NoLaserTrials & (TE.sessionIndex == counter)));
            Laserdata = length(find((ordering2{c2, 2}) & LaserTrials & (TE.sessionIndex == counter))) / length(find((ordering2{c2, 3}) & LaserTrials & (TE.sessionIndex == counter)));
            Laser10data = length(find((ordering2{c2, 2}) & Laser10Trials & (TE.sessionIndex == counter))) / length(find((ordering2{c2, 3}) & Laser10Trials & (TE.sessionIndex == counter)));
            Laser20data = length(find((ordering2{c2, 2}) & Laser20Trials & (TE.sessionIndex == counter))) / length(find((ordering2{c2, 3}) & Laser20Trials & (TE.sessionIndex == counter)));
            HitRate_pooled.(ordering2{c2,1}).NoLaser.pSess(counter,:) = NoLaserdata;            
            HitRate_pooled.(ordering2{c2,1}).Laser.pSess(counter,:) = Laserdata;
            HitRate_pooled.(ordering2{c2,1}).Laser10.pSess(counter,:) = Laser10data;
            HitRate_pooled.(ordering2{c2,1}).Laser20.pSess(counter,:) = Laser20data;
            HitRate_pooled.(ordering2{c2,1}).dL.pSess(counter,:) = Laserdata - NoLaserdata;
        end
        
     ordering3 = {...
        'FA', FATrials, Sound4Trials;...
        'FA50', FA50Trials, Sound4_50_Trials;...
        'FA40', FA40Trials, Sound4_40_Trials;...
        'FA30', FA30Trials, Sound4_30_Trials;...
        'FA20', FA20Trials, Sound4_20_Trials;...  
        'FA5040', FA5040Trials, Sound4_5040_Trials;...
        'FA3020', FA3020Trials, Sound4_3020_Trials;...
        };
        for c3 = 1:size(ordering3,1)
            NoLaserdata = length(find((ordering3{c3, 2}) & NoLaserTrials & (TE.sessionIndex == counter))) / length(find((ordering3{c3, 3}) & NoLaserTrials & (TE.sessionIndex == counter)));
            Laserdata = length(find((ordering3{c3, 2}) & LaserTrials & (TE.sessionIndex == counter))) / length(find((ordering3{c3, 3}) & LaserTrials & (TE.sessionIndex == counter)));
            Laser10data = length(find((ordering3{c3, 2}) & Laser10Trials & (TE.sessionIndex == counter))) / length(find((ordering3{c3, 3}) & Laser10Trials & (TE.sessionIndex == counter)));
            Laser20data = length(find((ordering3{c3, 2}) & Laser20Trials & (TE.sessionIndex == counter))) / length(find((ordering3{c3, 3}) & Laser20Trials & (TE.sessionIndex == counter)));
            FARate_pooled.(ordering3{c3,1}).NoLaser.pSess(counter,:) = NoLaserdata;            
            FARate_pooled.(ordering3{c3,1}).Laser.pSess(counter,:) = Laserdata;
            FARate_pooled.(ordering3{c3,1}).Laser10.pSess(counter,:) = Laser10data;
            FARate_pooled.(ordering3{c3,1}).Laser20.pSess(counter,:) = Laser20data;
            FARate_pooled.(ordering3{c3,1}).dL.pSess(counter,:) = Laserdata - NoLaserdata;
        end         
end

    ordering2 = {...
        'Hit', hitTrials, Sound1Trials;...
        'Hit50', hit50Trials, Sound1_50_Trials;...
        'Hit40', hit40Trials, Sound1_40_Trials;...
        'Hit30', hit30Trials, Sound1_30_Trials;...
        'Hit20', hit20Trials, Sound1_20_Trials;...  
        'Hit5040', hit5040Trials, Sound1_5040_Trials;...
        'Hit3020', hit3020Trials, Sound1_3020_Trials;...
        };
    for c2 = 1:size(ordering2,1)
        NoLaserdata = length(find((ordering2{c2, 2}) & NoLaserTrials)) / length(find((ordering2{c2, 3}) & NoLaserTrials));
        Laserdata = length(find((ordering2{c2, 2}) & LaserTrials)) / length(find((ordering2{c2, 3}) & LaserTrials));
        Laser10data = length(find((ordering2{c2, 2}) & Laser10Trials)) / length(find((ordering2{c2, 3}) & Laser10Trials));
        Laser20data = length(find((ordering2{c2, 2}) & Laser20Trials)) / length(find((ordering2{c2, 3}) & Laser20Trials));
        HitRate_pooled.(ordering2{c2,1}).NoLaser.all = NoLaserdata;            
        HitRate_pooled.(ordering2{c2,1}).Laser.all = Laserdata;
        HitRate_pooled.(ordering2{c2,1}).Laser10.all = Laser10data;
        HitRate_pooled.(ordering2{c2,1}).Laser20.all = Laser20data;
        HitRate_pooled.(ordering2{c2,1}).dL.all = Laserdata - NoLaserdata;
    end
        
    ordering3 = {...
        'FA', FATrials, Sound4Trials;...
        'FA50', FA50Trials, Sound4_50_Trials;...
        'FA40', FA40Trials, Sound4_40_Trials;...
        'FA30', FA30Trials, Sound4_30_Trials;...
        'FA20', FA20Trials, Sound4_20_Trials;...  
        'FA5040', FA5040Trials, Sound4_5040_Trials;...
        'FA3020', FA3020Trials, Sound4_3020_Trials;...
        };
    for c3 = 1:size(ordering3,1)
        NoLaserdata = length(find((ordering3{c3, 2}) & NoLaserTrials)) / length(find((ordering3{c3, 3}) & NoLaserTrials));
        Laserdata = length(find((ordering3{c3, 2}) & LaserTrials)) / length(find((ordering3{c3, 3}) & LaserTrials));
        Laser10data = length(find((ordering3{c3, 2}) & Laser10Trials)) / length(find((ordering3{c3, 3}) & Laser10Trials));
        Laser20data = length(find((ordering3{c3, 2}) & Laser20Trials)) / length(find((ordering3{c3, 3}) & Laser20Trials));
        FARate_pooled.(ordering3{c3,1}).NoLaser.all = NoLaserdata;            
        FARate_pooled.(ordering3{c3,1}).Laser.all = Laserdata;
        FARate_pooled.(ordering3{c3,1}).Laser10.all = Laser10data;
        FARate_pooled.(ordering3{c3,1}).Laser20.all = Laser20data;
        FARate_pooled.(ordering3{c3,1}).dL.all = Laserdata - NoLaserdata;
    end
    if saveOn
        save(fullfile(savepath, ['summary_' subjectName '_HitRate_pooled.mat']), 'HitRate_pooled');
        save(fullfile(savepath, ['summary_' subjectName '_FARate_pooled.mat']), 'FARate_pooled');
    end  

% analysis for Reaction time and foreperiod for each session
 s2 = struct(...
    'rt', cell(1,1),...
    'fp', cell(1,1)...
    );
 RT_pooled = struct(...
    'hit', s2,...
    'FA', s2,...
    'mix', s2,...
    'hit50', s2,...
    'hit40', s2,...
    'hit30', s2,...
    'hit20', s2...
    );

    for counter = 1:nSessions          
        hitTrialsThisSession = find(hitTrials & (TE.sessionIndex == counter));
        FATrialsThisSession = find(FATrials & (TE.sessionIndex == counter));        
        LickTrialsThisSession = find(filterTE(TE, 'LickAction', 'lick', 'reject', 0) & ~badTrials & (TE.sessionIndex == counter));                
        hit50TrialsThisSession = find(hit50Trials & (TE.sessionIndex == counter));
        hit40TrialsThisSession = find(hit40Trials & (TE.sessionIndex == counter));
        hit30TrialsThisSession = find(hit30Trials & (TE.sessionIndex == counter));
        hit20TrialsThisSession = find(hit20Trials & (TE.sessionIndex == counter));
        FA50TrialsThisSession = find(FA50Trials & (TE.sessionIndex == counter));
        FA40TrialsThisSession = find(FA40Trials & (TE.sessionIndex == counter));
        FA30TrialsThisSession = find(FA30Trials & (TE.sessionIndex == counter));
        FA20TrialsThisSession = find(FA20Trials & (TE.sessionIndex == counter));
   
        ordering = {...
            'hit', hitTrialsThisSession;...
            'FA', FATrialsThisSession;...
            'mix', LickTrialsThisSession;...
            'hit50', hit50TrialsThisSession;...
            'hit40', hit40TrialsThisSession;...
            'hit30', hit30TrialsThisSession;...
            'hit20', hit20TrialsThisSession;... 
            'FA50', FA50TrialsThisSession;...
            'FA40', FA40TrialsThisSession;...
            'FA30', FA30TrialsThisSession;...
            'FA20', FA20TrialsThisSession;... 
            };

            for c2 = 1:size(ordering,1)
                RT_pooled.(ordering{c2,1}).rt{counter,:} = TE.RT(ordering{c2, 2}); 
                RT_pooled.(ordering{c2,1}).fp{counter,:} = TE.fpWindow(ordering{c2, 2}); 
            end   
    end
TE.RTpr_lick_pS_all = [];
    for counter = 1:nSessions               
        TrialsThisSession =  filterTE(TE, 'sessionIndex', counter);
        LickTrialsThisSession = find(filterTE(TE, 'LickAction', 'lick', 'reject', 0) & ~badTrials & (TE.sessionIndex == counter));                
        pr = [];
        A = find(TrialsThisSession);
        for i = min(A): max(A)
            if ismember(i, LickTrialsThisSession)                
                TE.RTpr_lick_pS_all(i) = percentileranking2(RT_pooled.mix.rt{counter, 1}(:), TE.RT(i));
            else
                TE.RTpr_lick_pS_all(i) = NaN;
            end
        end 
    end
    TE.RTpr_lick_pS_all =  TE.RTpr_lick_pS_all';
if saveOn
    save(fullfile(savepath, ['summary_' subjectName '_RT_pooled.mat']), 'RT_pooled');
%     disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_RT_pooled.mat']) ' ***']);
    save(fullfile(savepath, 'TE.mat'), 'TE');
%     disp(['*** Saved: ' fullfile(savepath, 'TE.mat')]); 
end
 
    
% CS US licks
s2 = struct(...
    'all', [],...
    'data', cell(1,1),...
    'avg', zeros(nSessions, 1),...
    'sem', zeros(nSessions, 1)...
    );

Cs_lick = struct(...
    'allTrials', s2,...
    'Sound1', s2,...
    'Sound4', s2,...
    'Sound1Laser', s2,...
    'Sound4Laser', s2,...    
    'Sound1NoLaser', s2,...  
    'Sound4NoLaser', s2...
    );
Us_lick = struct(...
    'allTrials', s2,...
    'Sound1', s2,...
    'Sound4', s2,...
    'Sound1Laser', s2,...
    'Sound4Laser', s2,...    
    'Sound1NoLaser', s2,...  
    'Sound4NoLaser', s2...
    );
Cs_lick_norm = struct(...
    'allTrials', s2,...
    'Sound1', s2,...
    'Sound4', s2,...
    'Sound1Laser', s2,...
    'Sound4Laser', s2,...    
    'Sound1NoLaser', s2,...  
    'Sound4NoLaser', s2...
    );
Us_lick_norm = struct(...
    'allTrials', s2,...
    'Sound1', s2,...
    'Sound4', s2,...
    'Sound1Laser', s2,...
    'Sound4Laser', s2,...    
    'Sound1NoLaser', s2,...  
    'Sound4NoLaser', s2...
    );
ordering = {...
    'allTrials', allTrials;...
    'Sound1', Sound1Trials;...
    'Sound4', Sound4Trials;...
    'Sound1Laser', Sound1Laser;...
    'Sound4Laser', Sound4Laser;...     
    'Sound1NoLaser', Sound1NoLaser;...  
    'Sound4NoLaser', Sound4NoLaser;...
    };
for c2 = 1:size(ordering,1)     
    Cs_lick.(ordering{c2,1}).all = TE.csLicks.rate(ordering{c2, 2});
    Us_lick.(ordering{c2,1}).all = TE.usLicks.rate(ordering{c2, 2});     
end

for counter = 1:nSessions 
    allTrialsThisSession = allTrials & (TE.sessionIndex == counter);      
    Sound1TrialsThisSession = Sound1Trials & (TE.sessionIndex == counter); 
    Sound4TrialsThisSession = Sound4Trials & (TE.sessionIndex == counter); 
    Sound1LaserThisSession = Sound1Laser & (TE.sessionIndex == counter);
    Sound4LaserThisSession = Sound4Laser & (TE.sessionIndex == counter);
    Sound1NoLaserThisSession = Sound1NoLaser & (TE.sessionIndex == counter);
    Sound4NoLaserThisSession = Sound4NoLaser & (TE.sessionIndex == counter);    
    ordering3 = {...
        'allTrials', allTrialsThisSession;...
        'Sound1', Sound1TrialsThisSession;...
        'Sound4', Sound4TrialsThisSession;...
        'Sound1Laser', Sound1LaserThisSession;...
        'Sound4Laser', Sound4LaserThisSession;...     
        'Sound1NoLaser', Sound1NoLaserThisSession;...  
        'Sound4NoLaser', Sound4NoLaserThisSession;...
        };
        for c3 = 1:size(ordering3,1)
            thisData = TE.csLicks.rate(ordering3{c3, 2});
            Cs_lick.(ordering3{c3,1}).data{counter,:} = thisData;
            Cs_lick.(ordering3{c3,1}).avg(counter,:) = nanmean(thisData);
            Cs_lick.(ordering3{c3,1}).sem(counter,:) = nanSEM(thisData); 

            thatData = TE.usLicks.rate(ordering3{c3, 2});
            Us_lick.(ordering3{c3,1}).data{counter,:} = thatData;
            Us_lick.(ordering3{c3,1}).avg(counter,:) = nanmean(thatData);
            Us_lick.(ordering3{c3,1}).sem(counter,:) = nanSEM(thatData); 
        end
   ordering3 = {...
        'allTrials', allTrialsThisSession;...
        'Sound1', Sound1TrialsThisSession;...
        'Sound4', Sound4TrialsThisSession;...
        'Sound1Laser', Sound1LaserThisSession;...
        'Sound4Laser', Sound4LaserThisSession;...     
        'Sound1NoLaser', Sound1NoLaserThisSession;...  
        'Sound4NoLaser', Sound4NoLaserThisSession;...
        };
        for c3 = 1:size(ordering3,1)
            thisData = Cs_lick.(ordering3{c3,1}).data{counter,:} / Cs_lick.Sound1.avg(counter);
            Cs_lick_norm.(ordering3{c3,1}).data{counter,:} = thisData;
            Cs_lick_norm.(ordering3{c3,1}).avg(counter,:) = nanmean(thisData);
            Cs_lick_norm.(ordering3{c3,1}).sem(counter,:) = nanSEM(thisData);
            A = Cs_lick_norm.(ordering3{c3,1}).all;
            Cs_lick_norm.(ordering3{c3,1}).all = [A; thisData];

            thatData = Us_lick.(ordering3{c3,1}).data{counter,:} / Us_lick.Sound1.avg(counter);
            Us_lick_norm.(ordering3{c3,1}).data{counter,:} = thatData;
            Us_lick_norm.(ordering3{c3,1}).avg(counter,:) = nanmean(thatData);
            Us_lick_norm.(ordering3{c3,1}).sem(counter,:) = nanSEM(thatData); 
            B = Us_lick_norm.(ordering3{c3,1}).all;
            Us_lick_norm.(ordering3{c3,1}).all = [B; thatData];
        end
end

if saveOn
    save(fullfile(savepath, ['summary_' subjectName '_Cs_lick.mat']), 'Cs_lick');
    save(fullfile(savepath, ['summary_' subjectName '_Us_lick.mat']), 'Us_lick');
    save(fullfile(savepath, ['summary_' subjectName '_Cs_lick_norm.mat']), 'Cs_lick_norm');
    save(fullfile(savepath, ['summary_' subjectName '_Us_lick_norm.mat']), 'Us_lick_norm');
end


% Save behavior plot
    saveName = [subjectName '_behavior4'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  

    color2 = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('FA'); mycolors_SL2('CR'); mycolors_SL2('uncuedReward'); mycolors_SL2('uncuedPunish'); mycolors_SL2('sound3'); mycolors_SL2('sound4'); mycolors_SL2('neutral'); mycolors_SL2('re1'); 0.5* mycolors_SL2('hit'); 0.5* mycolors_SL2('miss');];
    subplot(2,4,1); 
    for counter = 1:nSessions
        performance_sound1 = length(find(anticipTrials & Sound1Laser & (TE.sessionIndex == counter))) / length(find(Sound1Laser & (TE.sessionIndex == counter)));
        performance_sound4 = length(find(anticipTrials & Sound4Laser & (TE.sessionIndex == counter))) / length(find(Sound4Laser & (TE.sessionIndex == counter)));
        x = [1 4];
        y = [performance_sound1 performance_sound4];
        plot(x,y,'--o', 'color', color2(counter, :));  hold on;
        performance2_sound1 = length(find(anticipTrials & Sound1NoLaser & (TE.sessionIndex == counter))) / length(find(Sound1NoLaser & (TE.sessionIndex == counter)));
        performance2_sound4 = length(find(anticipTrials & Sound4NoLaser & (TE.sessionIndex == counter))) / length(find(Sound4NoLaser & (TE.sessionIndex == counter)));
        x = [1 4];
        y = [performance2_sound1 performance2_sound4]; hold on;
        plot(x,y,'-s', 'color', color2(counter, :));   
    end
    performance_sound1 = length(find(anticipTrials & Sound1Laser)) / length(find(Sound1Laser));
    performance_sound4 = length(find(anticipTrials & Sound4Laser)) / length(find(Sound4Laser));
    y = [performance_sound1 performance_sound4];
    plot(x,y,'--k','LineWidth',2);  hold on;
    performance2_sound1 = length(find(anticipTrials & Sound1NoLaser)) / length(find(Sound1NoLaser));
    performance2_sound4 = length(find(anticipTrials & Sound4NoLaser)) / length(find(Sound4NoLaser));
    y = [performance2_sound1 performance2_sound4];
    plot(x,y,'-k','LineWidth',2);
    set(gca, 'YLim', [0 1]);
    legend({'S1Laser+', 'S1Laser-', 'S2Laser+', 'S2Laser-'}, 'Location','southwest');
    xlabel('Sound'); ylabel('Performance'); title('Performance');
    
    subplot(2,4,2);  
    for counter = 1:nSessions
        y1 = length(find(fpLickNoLaser & (TE.sessionIndex == counter))) / length(find(filterTE(TE, 'StimAmp', 0, 'reject', 0) & (TE.sessionIndex == counter))); 
        y2 = length(find(fpLickLaser & (TE.sessionIndex == counter))) / length(find(filterTE(TE, 'StimAmp', 5, 'reject', 0) & (TE.sessionIndex == counter))); 
        yData = [y1 y2];
        plot (yData,'-o', 'color', color2(counter, :)); hold on;
    end
    y1 = length(find(fpLickNoLaser)) / length(find(filterTE(TE, 'StimAmp', 0, 'reject', 0))); 
    y2 = length(find(fpLickLaser)) / length(find(filterTE(TE, 'StimAmp', 5, 'reject', 0))); 
    plot([y1 y2],'-k','LineWidth',2); 
    set(gca, 'XTick', [1 2], 'XTickLabel', {'NoLaser', 'Laser'}, 'YLim', [0 1]); 
    ylabel('Licks(Hz)'); title('fpLick chance'); 
    
    subplot(2,4,3);  
    x = [1 4];  
    for counter = 1:nSessions
        y1 = [nanmean(TE.csLicks.rate(Sound1Laser & (TE.sessionIndex == counter))) nanmean(TE.csLicks.rate(Sound4Laser & (TE.sessionIndex == counter)))];
        plot(x,y1,'--o','color', color2(counter, :)); hold on;
        y2 = [nanmean(TE.csLicks.rate(Sound1NoLaser & (TE.sessionIndex == counter))) nanmean(TE.csLicks.rate(Sound4NoLaser & (TE.sessionIndex == counter)))];
        plot(x,y2,'-s','color', color2(counter, :)); hold on;
    end
    y1 = [nanmean(TE.csLicks.rate(Sound1Laser)) nanmean(TE.csLicks.rate(Sound4Laser))];
    plot(x,y1,'--k','LineWidth',2); hold on;
    y2 = [nanmean(TE.csLicks.rate(Sound1NoLaser)) nanmean(TE.csLicks.rate(Sound4NoLaser))];
    plot(x,y2,'-k','LineWidth',2);
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Licks(Hz)'); title('csLicks rate'); 
    
    subplot(2,4,4);  
    x = [1 4]; 
    for counter = 1:nSessions
    y1 = [nanmean(TE.usLicks.rate(Sound1Laser & (TE.sessionIndex == counter))) nanmean(TE.usLicks.rate(Sound4Laser & (TE.sessionIndex == counter)))];
    plot(x,y1,'--o','color', color2(counter, :)); hold on;
    y2 = [nanmean(TE.usLicks.rate(Sound1NoLaser & (TE.sessionIndex == counter))) nanmean(TE.usLicks.rate(Sound4NoLaser & (TE.sessionIndex == counter)))];
    plot(x,y2,'-s','color', color2(counter, :)); hold on;
    end
    y1 = [nanmean(TE.usLicks.rate(Sound1Laser)) nanmean(TE.usLicks.rate(Sound4Laser))];
    plot(x,y1,'--k','LineWidth',2); hold on;
    y2 = [nanmean(TE.usLicks.rate(Sound1NoLaser)) nanmean(TE.usLicks.rate(Sound4NoLaser))];
    plot(x,y2,'-k','LineWidth',2);
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Licks(Hz)'); title('usLicks rate'); 
    
    subplot(2,4,5);  
    x = [1 4];   
    for counter = 1:nSessions
        y1 = [nanmean(TE.RT(Sound1Laser & (TE.sessionIndex == counter))) nanmean(TE.RT(Sound4Laser & (TE.sessionIndex == counter)))];
        plot(x,y1,'--o','color', color2(counter, :)); hold on;
        y2 = [nanmean(TE.RT(Sound1NoLaser & (TE.sessionIndex == counter))) nanmean(TE.RT(Sound4NoLaser & (TE.sessionIndex == counter)))];
        plot(x,y2,'-s','color', color2(counter, :)); hold on;
    end
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('RT'); title('RT Mean');    
    
    subplot(2,4,6);  
    x = [1 4];  
    for counter = 1:nSessions
        y1 = [nanmedian(TE.RT(Sound1Laser & (TE.sessionIndex == counter))) nanmedian(TE.RT(Sound4Laser & (TE.sessionIndex == counter)))];  
        plot(x,y1,'--o','color', color2(counter, :)); hold on;
        y2 = [nanmedian(TE.RT(Sound1NoLaser & (TE.sessionIndex == counter))) nanmedian(TE.RT(Sound4NoLaser & (TE.sessionIndex == counter)))];  
        plot(x,y2,'-s','color', color2(counter, :)); hold on;
    end
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('RT'); title('RT Median');     
        
    subplot(2,4,7);  
    x = [1 4];   
    for counter = 1:nSessions
        y1 = [nanmean(TE.RTpr_lick_pS_all(Sound1Laser & (TE.sessionIndex == counter))) nanmean(TE.RTpr_lick_pS_all(Sound4Laser & (TE.sessionIndex == counter)))];
        plot(x,y1,'--o','color', color2(counter, :)); hold on;
        y2 = [nanmean(TE.RTpr_lick_pS_all(Sound1NoLaser & (TE.sessionIndex == counter))) nanmean(TE.RTpr_lick_pS_all(Sound4NoLaser & (TE.sessionIndex == counter)))];
        plot(x,y2,'-s','color', color2(counter, :)); hold on;        
    end
    y1 = [nanmean(TE.RTpr_lick_pS_all(Sound1Laser)) nanmean(TE.RTpr_lick_pS_all(Sound4Laser))];
    plot(x,y1,'--k','LineWidth',2); hold on;
    y2 = [nanmean(TE.RTpr_lick_pS_all(Sound1NoLaser)) nanmean(TE.RTpr_lick_pS_all(Sound4NoLaser))];
    plot(x,y2,'-k','LineWidth',2); 
    set(gca, 'YLim', [0 100]);
    xlabel('Sound'); ylabel('RTpr'); title('RTpr Mean');    
    
    subplot(2,4,8);  
    x = [1 4];  
    for counter = 1:nSessions
        y1 = [nanmedian(TE.RTpr_lick_pS_all(Sound1Laser & (TE.sessionIndex == counter))) nanmedian(TE.RTpr_lick_pS_all(Sound4Laser & (TE.sessionIndex == counter)))];  
        plot(x,y1,'--o','color', color2(counter, :)); hold on;
        y2 = [nanmedian(TE.RTpr_lick_pS_all(Sound1NoLaser & (TE.sessionIndex == counter))) nanmedian(TE.RTpr_lick_pS_all(Sound4NoLaser & (TE.sessionIndex == counter)))];  
        plot(x,y2,'-s','color', color2(counter, :)); hold on;
    end
    y1 = [nanmedian(TE.RTpr_lick_pS_all(Sound1Laser)) nanmedian(TE.RTpr_lick_pS_all(Sound4Laser))];
    plot(x,y1,'--k','LineWidth',2); hold on;
    y2 = [nanmedian(TE.RTpr_lick_pS_all(Sound1NoLaser)) nanmedian(TE.RTpr_lick_pS_all(Sound4NoLaser))];
    plot(x,y2,'-k','LineWidth',2); 
    set(gca, 'YLim', [0 100]);
    xlabel('Sound'); ylabel('RTpr'); title('RTpr Median'); 
           
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
    
    % Averages aligned to Laser
    saveName = [subjectName '_lick_raster2'];

    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    
    varargin = {'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording'};

    linecolors = [mycolors_SL2('neutral'); mycolors_SL2('uncuedReward'); mycolors_SL2('re3'); mycolors_SL2('re2'); mycolors_SL2('re1')];
    varargin2 = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'window', [-3, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    
    subplot(2,3,1); % lick raster for Sound1
    eventRasterFromTE2(TE, Sound1NoLaser, 'Port1In', varargin{:});
    title('Sound1NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(2,3,2); % lick raster for Sound1
    eventRasterFromTE2(TE, Sound1Laser, 'Port1In', varargin{:});
    title('Sound1Laser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(2,3,3); % lick average for Sound1
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1NoLaser, Sound1Laser}, 'Port1In', varargin2{:});
    legend(hl, {'Sound1NoLaser', 'Sound1Laser'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);      
            
    subplot(2,3,4); % lick raster for Sound1
    eventRasterFromTE2(TE, Sound4NoLaser, 'Port1In', varargin{:});
    title('Sound4NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
        
    subplot(2,3,5); % lick raster for Sound1
    eventRasterFromTE2(TE, Sound4Laser, 'Port1In', varargin{:});
    title('Sound4Laser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(2,3,6); % lick average for Sound1
    [ha, hl] = plotEventAverageFromTE(TE, {Sound4NoLaser, Sound4Laser}, 'Port1In', varargin2{:});
    legend(hl, {'Sound4NoLaser', 'Sound4Laser'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)'); 
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
  
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end   
    
    % SPL behavior plot
    saveName = [subjectName '_behavior_SPL'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  

    subplot(2,4,1);          
    performance_hit50 = length(find(hit50Trials)) / length(find(Sound1_50_Trials));
    performance_hit40 = length(find(hit40Trials)) / length(find(Sound1_40_Trials));
    performance_hit30 = length(find(hit30Trials)) / length(find(Sound1_30_Trials));
    performance_hit20 = length(find(hit20Trials)) / length(find(Sound1_20_Trials));
    x = [50 40 30 20];
    y = [performance_hit50 performance_hit40 performance_hit30 performance_hit20];
    plot(x,y,'-o', 'color', [0/255 128/255 0/255]); hold on;
    
    performance_FA50 = length(find(FA50Trials)) / length(find(Sound4_50_Trials));
    performance_FA40 = length(find(FA40Trials)) / length(find(Sound4_40_Trials));
    performance_FA30 = length(find(FA30Trials)) / length(find(Sound4_30_Trials));  
    performance_FA20 = length(find(FA20Trials)) / length(find(Sound4_20_Trials)); 
    y = [performance_FA50 performance_FA40 performance_FA30 performance_FA20];      
    plot(x,y,'-o', 'color', [215/255 48/255 31/255]); 
    legend({'hit', 'FA'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL (dB)'); ylabel('Lick prob'); title('Performance all');
    hold off
    
    subplot(2,4,2);  
    d50 = performance_hit50 - performance_FA50;
    d40 = performance_hit40 - performance_FA40;
    d30 = performance_hit30 - performance_FA30;
    d20 = performance_hit20 - performance_FA20;
    ydata = [d50 d40 d30 d20];
    plot(x,ydata,'-o', 'color', [152/255 78/255 163/255]); 
%     set(gca, 'YLim', [-0.5 0.5], 'YTick', [-0.4 -0.2 0 0.2 0.4]);
    xlabel('SPL (dB)'); ylabel('d(Lickprob)'); title('dHit - dFA');
    
    subplot(2,4,3);          
    y1 = length(find(hit50Trials & NoLaserTrials)) / length(find(Sound1_50_Trials & NoLaserTrials));
    y2 = length(find(hit40Trials & NoLaserTrials)) / length(find(Sound1_40_Trials & NoLaserTrials));
    y3 = length(find(hit30Trials & NoLaserTrials)) / length(find(Sound1_30_Trials & NoLaserTrials));
    y4 = length(find(hit20Trials & NoLaserTrials)) / length(find(Sound1_20_Trials & NoLaserTrials));
    ydata = [y1 y2 y3 y4];
    plot(x,ydata,'-o', 'color', [0/255 128/255 0/255]); hold on;
    
    y5 = length(find(hit50Trials & LaserTrials)) / length(find(Sound1_50_Trials & LaserTrials));
    y6 = length(find(hit40Trials & LaserTrials)) / length(find(Sound1_40_Trials & LaserTrials));
    y7 = length(find(hit30Trials & LaserTrials)) / length(find(Sound1_30_Trials & LaserTrials));
    y8 = length(find(hit20Trials & LaserTrials)) / length(find(Sound1_20_Trials & LaserTrials));
    ydata = [y5 y6 y7 y8];
    plot(x,ydata,'--o', 'color', [55/255 126/255 184/255]); 
   
    y11 = length(find(FA50Trials & NoLaserTrials)) / length(find(Sound4_50_Trials & NoLaserTrials));
    y12 = length(find(FA40Trials & NoLaserTrials)) / length(find(Sound4_40_Trials & NoLaserTrials));
    y13 = length(find(FA30Trials & NoLaserTrials)) / length(find(Sound4_30_Trials & NoLaserTrials));
    y14 = length(find(FA20Trials & NoLaserTrials)) / length(find(Sound4_20_Trials & NoLaserTrials));
    ydata = [y11 y12 y13 y14]; 
    plot(x,ydata,'-o', 'color', [215/255 48/255 31/255]); hold on;
    
    y15 = length(find(FA50Trials & LaserTrials)) / length(find(Sound4_50_Trials & LaserTrials));
    y16 = length(find(FA40Trials & LaserTrials)) / length(find(Sound4_40_Trials & LaserTrials));
    y17 = length(find(FA30Trials & LaserTrials)) / length(find(Sound4_30_Trials & LaserTrials));
    y18 = length(find(FA20Trials & LaserTrials)) / length(find(Sound4_20_Trials & LaserTrials));
    ydata = [y15 y16 y17 y18];
    plot(x,ydata,'--o', 'color', [152/255 78/255 163/255]); 
    legend({'Hit NoLaser', 'Hit Laser', 'FA NoLaser', 'FA Laser'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL (dB)'); ylabel('Lick prob'); title('NoLaser vs Laser');
    hold off 
    
    subplot(2,4,4);  
    d50 = (y5-y1) - (y15-y11);
    d40 = (y6-y2) - (y16-y12);
    d30 = (y7-y3) - (y17-y13);
    d20 = (y8-y4) - (y18-y14);
    ydata = [d50 d40 d30 d20];
    plot(x,ydata,'-o', 'color', [152/255 78/255 163/255]); 
    set(gca, 'YLim', [-0.5 1], 'YTick', [-0.4 -0.2 0 0.2 0.4]);
    xlabel('SPL (dB)'); ylabel('d(Laser - NoLaser)'); title('dHit - dFA');
       
    subplot(2,4,5);          
    y1 = length(find(hit50Trials & NoLaserTrials)) / length(find(Sound1_50_Trials & NoLaserTrials));
    y2 = length(find(hit40Trials & NoLaserTrials)) / length(find(Sound1_40_Trials & NoLaserTrials));
    y3 = length(find(hit30Trials & NoLaserTrials)) / length(find(Sound1_30_Trials & NoLaserTrials));
    y4 = length(find(hit20Trials & NoLaserTrials)) / length(find(Sound1_20_Trials & NoLaserTrials));
    ydata = [y1 y2 y3 y4];
    plot(x,ydata,'-o', 'color', [0/255 128/255 0/255]); hold on;
    
    y5 = length(find(hit50Trials & Laser10Trials)) / length(find(Sound1_50_Trials & Laser10Trials));
    y6 = length(find(hit40Trials & Laser10Trials)) / length(find(Sound1_40_Trials & Laser10Trials));
    y7 = length(find(hit30Trials & Laser10Trials)) / length(find(Sound1_30_Trials & Laser10Trials));
    y8 = length(find(hit20Trials & Laser10Trials)) / length(find(Sound1_20_Trials & Laser10Trials));
    ydata = [y5 y6 y7 y8];
    plot(x,ydata,'--o', 'color', [55/255 126/255 184/255]); 
    
    y11 = length(find(FA50Trials & NoLaserTrials)) / length(find(Sound4_50_Trials & NoLaserTrials));
    y12 = length(find(FA40Trials & NoLaserTrials)) / length(find(Sound4_40_Trials & NoLaserTrials));
    y13 = length(find(FA30Trials & NoLaserTrials)) / length(find(Sound4_30_Trials & NoLaserTrials));
    y14 = length(find(FA20Trials & NoLaserTrials)) / length(find(Sound4_20_Trials & NoLaserTrials));
    ydata = [y11 y12 y13 y14]; 
    plot(x,ydata,'-o', 'color', [215/255 48/255 31/255]); hold on;
    
    y15 = length(find(FA50Trials & Laser10Trials)) / length(find(Sound4_50_Trials & Laser10Trials));
    y16 = length(find(FA40Trials & Laser10Trials)) / length(find(Sound4_40_Trials & Laser10Trials));
    y17 = length(find(FA30Trials & Laser10Trials)) / length(find(Sound4_30_Trials & Laser10Trials));
    y18 = length(find(FA20Trials & Laser10Trials)) / length(find(Sound4_20_Trials & Laser10Trials));
    ydata = [y15 y16 y17 y18];
    plot(x,ydata,'--o', 'color', [152/255 78/255 163/255]); 
%     legend({'Hit NoLaser', 'HitLaser10', 'FA NoLaser', 'FA Laser10'}, 'Location','southwest');
    set(gca, 'YLim', [0 1], 'YTick', [-0.5 0 0.5]);
    xlabel('SPL (dB)'); ylabel('Lick prob'); title('NoLaser vs Laser10');
    hold off    
    
    subplot(2,4,6);  
    d50 = (y5-y1) - (y15-y11);
    d40 = (y6-y2) - (y16-y12);
    d30 = (y7-y3) - (y17-y13);
    d20 = (y8-y4) - (y18-y14);
    ydata = [d50 d40 d30 d20];
    plot(x,ydata,'-o', 'color', [152/255 78/255 163/255]); 
    set(gca, 'YLim', [-0.5 1], 'YTick', [-0.4 -0.2 0 0.2 0.4]);
    xlabel('SPL (dB)'); ylabel('d(Laser - NoLaser)'); title('dHit - dFA');    
    
    subplot(2,4,7);          
    y1 = length(find(hit50Trials & NoLaserTrials)) / length(find(Sound1_50_Trials & NoLaserTrials));
    y2 = length(find(hit40Trials & NoLaserTrials)) / length(find(Sound1_40_Trials & NoLaserTrials));
    y3 = length(find(hit30Trials & NoLaserTrials)) / length(find(Sound1_30_Trials & NoLaserTrials));
    y4 = length(find(hit20Trials & NoLaserTrials)) / length(find(Sound1_20_Trials & NoLaserTrials));
    ydata = [y1 y2 y3 y4];
    plot(x,ydata,'-o', 'color', [0/255 128/255 0/255]); hold on;
    
    y5 = length(find(hit50Trials & Laser20Trials)) / length(find(Sound1_50_Trials & Laser20Trials));
    y6 = length(find(hit40Trials & Laser20Trials)) / length(find(Sound1_40_Trials & Laser20Trials));
    y7 = length(find(hit30Trials & Laser20Trials)) / length(find(Sound1_30_Trials & Laser20Trials));
    y8 = length(find(hit20Trials & Laser20Trials)) / length(find(Sound1_20_Trials & Laser20Trials));
    ydata = [y5 y6 y7 y8];
    plot(x,ydata,'--o', 'color', [55/255 126/255 184/255]); 
    
    y11 = length(find(FA50Trials & NoLaserTrials)) / length(find(Sound4_50_Trials & NoLaserTrials));
    y12 = length(find(FA40Trials & NoLaserTrials)) / length(find(Sound4_40_Trials & NoLaserTrials));
    y13 = length(find(FA30Trials & NoLaserTrials)) / length(find(Sound4_30_Trials & NoLaserTrials));
    y14 = length(find(FA20Trials & NoLaserTrials)) / length(find(Sound4_20_Trials & NoLaserTrials));
    ydata = [y11 y12 y13 y14]; 
    plot(x,ydata,'-o', 'color', [215/255 48/255 31/255]); hold on;
    
    y15 = length(find(FA50Trials & Laser20Trials)) / length(find(Sound4_50_Trials & Laser20Trials));
    y16 = length(find(FA40Trials & Laser20Trials)) / length(find(Sound4_40_Trials & Laser20Trials));
    y17 = length(find(FA30Trials & Laser20Trials)) / length(find(Sound4_30_Trials & Laser20Trials));
    y18 = length(find(FA20Trials & Laser20Trials)) / length(find(Sound4_20_Trials & Laser20Trials));
    ydata = [y15 y16 y17 y18];
    plot(x,ydata,'--o', 'color', [152/255 78/255 163/255]); 
%     legend({'Hit NoLaser', 'HitLaser20', 'FA NoLaser', 'FA Laser20'}, 'Location','southwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL (dB)'); ylabel('Lick prob'); title('NoLaser vs Laser20');
    hold off    
    
    subplot(2,4,8);  
    d50 = (y5-y1) - (y15-y11);
    d40 = (y6-y2) - (y16-y12);
    d30 = (y7-y3) - (y17-y13);
    d20 = (y8-y4) - (y18-y14);
    ydata = [d50 d40 d30 d20];
    plot(x,ydata,'-o', 'color', [152/255 78/255 163/255]); 
    set(gca, 'YLim', [-0.5 0.5], 'YTick', [-0.4 -0.2 0 0.2 0.4]);
    xlabel('SPL (dB)'); ylabel('d(Laser - NoLaser)'); title('dHit - dFA');         
           
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
    
    % Save behavior plot
    saveName = [subjectName '_behavior_SPL_pSess2'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  
    color1 = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('FA'); mycolors_SL2('CR'); mycolors_SL2('uncuedReward'); mycolors_SL2('uncuedPunish'); mycolors_SL2('sound3'); mycolors_SL2('sound4'); mycolors_SL2('neutral'); mycolors_SL2('re1'); 0.5* mycolors_SL2('hit'); ; 0.5* mycolors_SL2('miss')];
    color2 = [mycolors_SL2('FA'); mycolors_SL2('CR'); mycolors_SL2('uncuedPunish'); mycolors_SL2('sound3')];
    subplot(3,3,1);    
    for counter = 1:nSessions
        x = [20 30 40 50];
        y = [HitRate_pooled.Hit20.NoLaser.pSess(counter,:) HitRate_pooled.Hit30.NoLaser.pSess(counter,:) HitRate_pooled.Hit40.NoLaser.pSess(counter,:) HitRate_pooled.Hit50.NoLaser.pSess(counter,:)];
        plot(x,y,'-','color', color1(counter, :)); hold on;
        y = [HitRate_pooled.Hit20.Laser.pSess(counter,:) HitRate_pooled.Hit30.Laser.pSess(counter,:) HitRate_pooled.Hit40.Laser.pSess(counter,:) HitRate_pooled.Hit50.Laser.pSess(counter,:)];
        plot(x,y,'--','color', color1(counter, :)); 
    end
    x = [20 30 40 50];
    y = [nanmean(HitRate_pooled.Hit20.NoLaser.pSess) nanmean(HitRate_pooled.Hit30.NoLaser.pSess) nanmean(HitRate_pooled.Hit40.NoLaser.pSess) nanmean(HitRate_pooled.Hit50.NoLaser.pSess)];
    err = [nanSEM(HitRate_pooled.Hit20.NoLaser.pSess) nanSEM(HitRate_pooled.Hit30.NoLaser.pSess) nanSEM(HitRate_pooled.Hit40.NoLaser.pSess) nanSEM(HitRate_pooled.Hit50.NoLaser.pSess)];
    errorbar(x,y,err,'-k', 'LineWidth', 2);      
    hold on;
    y = [nanmean(HitRate_pooled.Hit20.Laser.pSess) nanmean(HitRate_pooled.Hit30.Laser.pSess) nanmean(HitRate_pooled.Hit40.Laser.pSess) nanmean(HitRate_pooled.Hit50.Laser.pSess)];
    err = [nanSEM(HitRate_pooled.Hit20.Laser.pSess) nanSEM(HitRate_pooled.Hit30.Laser.pSess) nanSEM(HitRate_pooled.Hit40.Laser.pSess) nanSEM(HitRate_pooled.Hit50.Laser.pSess)];
    errorbar(x,y,err,'--k', 'LineWidth', 2);   
%     legend({'NoLaser', 'Laser'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
    xlabel('Norm. SPL'); ylabel('Lick Prob.'); title('Performance-Go');
    hold off;
    
    subplot(3,3,2);    
    for counter = 1:nSessions
        x = [20 30 40 50];
        y = [FARate_pooled.FA20.NoLaser.pSess(counter,:) FARate_pooled.FA30.NoLaser.pSess(counter,:) FARate_pooled.FA40.NoLaser.pSess(counter,:) FARate_pooled.FA50.NoLaser.pSess(counter,:)];
        plot(x,y,'-','color', color1(counter, :)); hold on;
        y = [FARate_pooled.FA20.Laser.pSess(counter,:) FARate_pooled.FA30.Laser.pSess(counter,:) FARate_pooled.FA40.Laser.pSess(counter,:) FARate_pooled.FA50.Laser.pSess(counter,:)];
        plot(x,y,'--','color', color1(counter, :)); 
    end
    x = [20 30 40 50];
    y = [nanmean(FARate_pooled.FA20.NoLaser.pSess) nanmean(FARate_pooled.FA30.NoLaser.pSess) nanmean(FARate_pooled.FA40.NoLaser.pSess) nanmean(FARate_pooled.FA50.NoLaser.pSess)];
    err = [nanSEM(FARate_pooled.FA20.NoLaser.pSess) nanSEM(FARate_pooled.FA30.NoLaser.pSess) nanSEM(FARate_pooled.FA40.NoLaser.pSess) nanSEM(FARate_pooled.FA50.NoLaser.pSess)];
    errorbar(x,y,err,'-k', 'LineWidth', 2);      
    hold on;
    y = [nanmean(FARate_pooled.FA20.Laser.pSess) nanmean(FARate_pooled.FA30.Laser.pSess) nanmean(FARate_pooled.FA40.Laser.pSess) nanmean(FARate_pooled.FA50.Laser.pSess)];
    err = [nanSEM(FARate_pooled.FA20.Laser.pSess) nanSEM(FARate_pooled.FA30.Laser.pSess) nanSEM(FARate_pooled.FA40.Laser.pSess) nanSEM(FARate_pooled.FA50.Laser.pSess)];
    errorbar(x,y,err,'--k', 'LineWidth', 2);   
    legend({'NoLaser', 'Laser'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
    xlabel('Norm. SPL'); ylabel('Lick Prob.'); title('Performance-NoGo');
    hold off;
    
    subplot(3,3,3);  
    for counter = 1:nSessions
        x = [20 30 40 50];
        d50 = HitRate_pooled.Hit50.dL.pSess(counter,:) - FARate_pooled.FA50.dL.pSess(counter,:);
        d40 = HitRate_pooled.Hit40.dL.pSess(counter,:) - FARate_pooled.FA40.dL.pSess(counter,:);
        d30 = HitRate_pooled.Hit30.dL.pSess(counter,:) - FARate_pooled.FA30.dL.pSess(counter,:);
        d20 = HitRate_pooled.Hit20.dL.pSess(counter,:) - FARate_pooled.FA20.dL.pSess(counter,:);
        ydata = [d20 d30 d40 d50]; 
        plot(x,ydata,'-','color', color1(counter, :)); hold on;
    end
    set(gca, 'YLim', [-1 1], 'YTick', [-1.0 -0.75 -0.50 -0.25 0 0.25 0.50 0.75 1.0]);
    xlabel('SPL (dB)'); ylabel('d(Laser - NoLaser)'); title('dHit - dFA');
    
    subplot(3,3,4); 
    for counter = 1:nSessions
        x = [20 30 40 50];   
        y1 = [mean(TE.RT(hit20Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit30Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit40Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit50Trials & NoLaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y1,'-','color', color1(counter, :));       
        hold on;  
%         y2 = [mean(TE.RT(FA30Trials & (TE.sessionIndex == counter))) mean(TE.RT(FA40Trials & (TE.sessionIndex == counter))) mean(TE.RT(FA50Trials & (TE.sessionIndex == counter)))];
%         plot(x,y2,'-.','color', color1(counter, :));  
%         hold on;
        y2 = [mean(TE.RT(hit20Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit30Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit40Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit50Trials & LaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y2,'--','color', color1(counter, :));       
        hold on;  
    end
        set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
        xlabel('Norm. SPL NoLaser'); ylabel('RT'); title('RT Mean'); 
        hold off; 
        
    subplot(3,3,5); 
    for counter = 1:nSessions
        x = [20 30 40 50];   
        y1 = [median(TE.RT(hit20Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit30Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit40Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit50Trials & NoLaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y1,'-','color', color1(counter, :));       
        hold on;  
        y2 = [median(TE.RT(hit20Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit30Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit40Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit50Trials & LaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y2,'--','color', color1(counter, :));       
        hold on;  
    end
        set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
        xlabel('Norm. SPL NoLaser'); ylabel('RT'); title('RT median'); 
        hold off;         
                
    subplot (3,3,6);
    xData = TE.RT(hit50Trials & NoLaserTrials);
    h(1, 1) = cdfplot (xData); 
    hold on; 
    xData = TE.RT(hit50Trials & LaserTrials);
    h(1, 2) = cdfplot (xData);  
    xData = TE.RT(hit40Trials & NoLaserTrials);
    h(1, 3) = cdfplot (xData); 
    xData = TE.RT(hit40Trials & LaserTrials);
    h(1, 4) = cdfplot (xData);  
    xData = TE.RT(hit3020Trials & NoLaserTrials);
    h(1, 5) = cdfplot (xData);   
    xData = TE.RT(hit3020Trials & LaserTrials);
    h(1, 6) = cdfplot (xData);

    set( h(:,1), 'LineStyle', '-', 'Color', mycolors_SL2('gr1'));
    set( h(:,2), 'LineStyle', '--', 'Color', mycolors_SL2('gr1'));
    set( h(:,3), 'LineStyle', '-', 'Color', mycolors_SL2('gr2'));
    set( h(:,4), 'LineStyle', '--', 'Color', mycolors_SL2('gr2'));
    set( h(:,5), 'LineStyle', '-', 'Color', mycolors_SL2('gr4'));
    set( h(:,6), 'LineStyle', '--', 'Color', mycolors_SL2('gr4'));
%     set( h(:,7), 'LineStyle', '-', 'Color', mycolors_SL2('gr4'));
%     set( h(:,8), 'LineStyle', '--', 'Color', mycolors_SL2('gr4'));
    legend('50db-NoLaser', '50db-Laser', '40db-NoLaser', '40db-Laser', '3020db-NoLaser', '3020db-Laser', 'Location','northwest')
    set(gca, 'xlim', [0 1], 'XTick', [0 0.2 0.4 0.6 0.8 1.0]);        
    xlabel('Reaction time'); ylabel('Fraction'); title('Hit Trials RT cumulative');
    hold off    

    subplot(3,3,7); 
    for counter = 1:nSessions
        x = [20 30 40 50];   
        y1 = [mean(TE.RTpr_lick_pS_all(hit20Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RTpr_lick_pS_all(hit30Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RTpr_lick_pS_all(hit40Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RTpr_lick_pS_all(hit50Trials & NoLaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y1,'-','color', color1(counter, :));       
        hold on;  
%         y2 = [mean(TE.RTpr_lick_pS_all(FA30Trials & (TE.sessionIndex == counter))) mean(TE.RTpr_lick_pS_all(FA40Trials & (TE.sessionIndex == counter))) mean(TE.RTpr_lick_pS_all(FA50Trials & (TE.sessionIndex == counter)))];
%         plot(x,y2,'-.','color', color1(counter, :));  
%         hold on;
        y2 = [mean(TE.RTpr_lick_pS_all(hit20Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RTpr_lick_pS_all(hit30Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RTpr_lick_pS_all(hit40Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RTpr_lick_pS_all(hit50Trials & LaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y2,'--','color', color1(counter, :));       
        hold on;  
    end
        set(gca, 'YLim', [0 100], 'YTick', [0 50 100], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
        xlabel('Norm. SPL NoLaser'); ylabel('RTpr'); title('RTpr Mean'); 
        hold off; 
        
    subplot(3,3,8); 
    for counter = 1:nSessions
        x = [20 30 40 50];   
        y1 = [median(TE.RTpr_lick_pS_all(hit20Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RTpr_lick_pS_all(hit30Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RTpr_lick_pS_all(hit40Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RTpr_lick_pS_all(hit50Trials & NoLaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y1,'-','color', color1(counter, :));       
        hold on;  
%         y2 = [median(TE.RTpr_lick_pS_all(FA30Trials & (TE.sessionIndex == counter))) median(TE.RTpr_lick_pS_all(FA40Trials & (TE.sessionIndex == counter))) median(TE.RTpr_lick_pS_all(FA50Trials & (TE.sessionIndex == counter)))];
%         plot(x,y2,'-.','color', color1(counter, :));  
%         hold on;
        y2 = [median(TE.RTpr_lick_pS_all(hit20Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RTpr_lick_pS_all(hit30Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RTpr_lick_pS_all(hit40Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RTpr_lick_pS_all(hit50Trials & LaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y2,'--','color', color1(counter, :));       
        hold on;  
    end
        set(gca, 'YLim', [0 100], 'YTick', [0 50 100], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
        xlabel('Norm. SPL NoLaser'); ylabel('RTpr'); title('RTpr median'); 
        hold off;  
    
    subplot (3,3,9);
    xData = TE.RTpr_lick_pS_all(hit50Trials & NoLaserTrials);
    h(1, 1) = cdfplot (xData); 
    hold on; 
    xData = TE.RTpr_lick_pS_all(hit50Trials & LaserTrials);
    h(1, 2) = cdfplot (xData);  
    xData = TE.RTpr_lick_pS_all(hit40Trials & NoLaserTrials);
    h(1, 3) = cdfplot (xData); 
    xData = TE.RTpr_lick_pS_all(hit40Trials & LaserTrials);
    h(1, 4) = cdfplot (xData);  
    xData = TE.RTpr_lick_pS_all(hit3020Trials & NoLaserTrials);
    h(1, 5) = cdfplot (xData);   
    xData = TE.RTpr_lick_pS_all(hit3020Trials & LaserTrials);
    h(1, 6) = cdfplot (xData);

    set( h(:,1), 'LineStyle', '-', 'Color', mycolors_SL2('gr1'));
    set( h(:,2), 'LineStyle', '--', 'Color', mycolors_SL2('gr1'));
    set( h(:,3), 'LineStyle', '-', 'Color', mycolors_SL2('gr2'));
    set( h(:,4), 'LineStyle', '--', 'Color', mycolors_SL2('gr2'));
    set( h(:,5), 'LineStyle', '-', 'Color', mycolors_SL2('gr4'));
    set( h(:,6), 'LineStyle', '--', 'Color', mycolors_SL2('gr4'));
%     set( h(:,7), 'LineStyle', '-', 'Color', mycolors_SL2('gr4'));
%     set( h(:,8), 'LineStyle', '--', 'Color', mycolors_SL2('gr4'));
    legend('50Laser-', '50Laser+', '40Laser-', '40Laser+', '3020Laser-', '3020Laser+', 'Location','southeast')
    set(gca, 'xlim', [0 100], 'XTick', [0 50 100]);        
    xlabel('RTpr'); ylabel('Fraction'); title('Hit Trials RTpr cumulative');
    hold off      
    
        
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
          
    % Save behavior plot
    saveName = [subjectName '_behavior5'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  
%     color1 = [60/255 0/255 0/255];
%     color2 = [0/255 60/255 0/255];
    color1 = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('FA'); mycolors_SL2('CR'); mycolors_SL2('uncuedReward'); mycolors_SL2('uncuedPunish'); mycolors_SL2('sound3');mycolors_SL2('sound4'); mycolors_SL2('neutral'); mycolors_SL2('re1'); 0.5*mycolors_SL2('hit'); 0.5*mycolors_SL2('miss')];
    color2 = [mycolors_SL2('hit'); mycolors_SL2('FA'); 0.5*mycolors_SL2('uncuedReward'); 0.5*mycolors_SL2('uncuedPunish'); 0.5*mycolors_SL2('sound3')];
    subplot(2,4,1);         
    x = [20 30 40 50];
    y = [HitRate_pooled.Hit20.NoLaser.all HitRate_pooled.Hit30.NoLaser.all HitRate_pooled.Hit40.NoLaser.all HitRate_pooled.Hit50.NoLaser.all];
    plot(x,y,'LineStyle', '-', 'Color', mycolors_SL2('gr2'), 'LineWidth', 2);  hold on;
    y = [HitRate_pooled.Hit20.Laser.all HitRate_pooled.Hit30.Laser.all HitRate_pooled.Hit40.Laser.all HitRate_pooled.Hit50.Laser.all];
    plot(x,y,'LineStyle', '--', 'Color', mycolors_SL2('gr2'), 'LineWidth', 2);    
    y = [FARate_pooled.FA20.NoLaser.all FARate_pooled.FA30.NoLaser.all FARate_pooled.FA40.NoLaser.all FARate_pooled.FA50.NoLaser.all];
    plot(x,y,'LineStyle', '-', 'Color', mycolors_SL2('re2'), 'LineWidth', 2);      
    y = [FARate_pooled.FA20.Laser.all FARate_pooled.FA30.Laser.all FARate_pooled.FA40.Laser.all FARate_pooled.FA50.Laser.all];
    plot(x,y,'LineStyle', '--', 'Color', mycolors_SL2('re2'), 'LineWidth', 2);   
    legend({'Hit-NoLaser', 'Hit-Laser', 'FA-NoLaser', 'FA-Laser'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
    xlabel('Norm. SPL'); ylabel('Lick Prob.'); title('Performance-NoGo');
    hold off;
    
    subplot(2,4,2);  
    for counter = 1:nSessions
        y1 = length(find(fpLickNoLaser & (TE.sessionIndex == counter))) / length(find(filterTE(TE, 'StimAmp', 0, 'reject', 0) & (TE.sessionIndex == counter))); 
        y2 = length(find(fpLickLaser & (TE.sessionIndex == counter))) / length(find(filterTE(TE, 'StimAmp', 5, 'reject', 0) & (TE.sessionIndex == counter))); 
        yData = [y1 y2];
        plot (yData,'-o', 'color', color1(counter, :)); hold on;
    end
    y1 = length(find(fpLickNoLaser)) / length(find(filterTE(TE, 'StimAmp', 0, 'reject', 0))); 
    y2 = length(find(fpLickLaser)) / length(find(filterTE(TE, 'StimAmp', 5, 'reject', 0))); 
    plot([y1 y2],'-k','LineWidth',2); 
    set(gca, 'XTick', [1 2], 'XTickLabel', {'NoLaser', 'Laser'}, 'YLim', [0 1]); 
    ylabel('Licks(Hz)'); title('fpLick chance'); 
    
    subplot(2,4,3);  
    x = [1 4];  
    for counter = 1:nSessions
        y1 = [Cs_lick_norm.Sound1Laser.avg(counter)  Cs_lick_norm.Sound4Laser.avg(counter)];
        plot(x,y1,'--o','color', color1(counter, :)); hold on;
        y2 = [Cs_lick_norm.Sound1NoLaser.avg(counter)  Cs_lick_norm.Sound4NoLaser.avg(counter)];
        plot(x,y2,'-s','color', color1(counter, :)); hold on;     
    end    
    y1 = [nanmean(Cs_lick_norm.Sound1Laser.avg)  nanmean(Cs_lick_norm.Sound4Laser.avg)];
    plot(x,y1,'--k','LineWidth',2); hold on;
    y2 = [nanmean(Cs_lick_norm.Sound1NoLaser.avg) nanmean(Cs_lick_norm.Sound4NoLaser.avg)];
    plot(x,y2,'-k','LineWidth',2); 
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Lick rate (norm. to all Sound1Trials)'); title('norm. csLicks rate'); 
    
    subplot(2,4,4);  
     x = [1 4];  
    for counter = 1:nSessions
        y1 = [Us_lick_norm.Sound1Laser.avg(counter)  Us_lick_norm.Sound4Laser.avg(counter)];
        plot(x,y1,'--o','color', color1(counter, :)); hold on;
        y2 = [Us_lick_norm.Sound1NoLaser.avg(counter)  Us_lick_norm.Sound4NoLaser.avg(counter)];
        plot(x,y2,'-s','color', color1(counter, :)); hold on;       
    end    
    y1 = [nanmean(Us_lick_norm.Sound1Laser.avg)  nanmean(Us_lick_norm.Sound4Laser.avg)];
    plot(x,y1,'--k','LineWidth',2); hold on;
    y2 = [nanmean(Us_lick_norm.Sound1NoLaser.avg) nanmean(Us_lick_norm.Sound4NoLaser.avg)];
    plot(x,y2,'-k','LineWidth',2); 
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Lick rate (norm. to all Sound1Trials)'); title('norm. usLicks rate'); 
    
    subplot(2,4,5); 
    x = [20 30 40 50];   
    y1 = [mean(TE.RTpr_lick_pS_all(hit20Trials & NoLaserTrials)) mean(TE.RTpr_lick_pS_all(hit30Trials & NoLaserTrials)) mean(TE.RTpr_lick_pS_all(hit40Trials & NoLaserTrials )) mean(TE.RTpr_lick_pS_all(hit50Trials & NoLaserTrials))];
    plot(x,y1,'-','color', mycolors_SL2('gr2'));       
    hold on;  
    y2 = [mean(TE.RTpr_lick_pS_all(hit20Trials & LaserTrials)) mean(TE.RTpr_lick_pS_all(hit30Trials & LaserTrials)) mean(TE.RTpr_lick_pS_all(hit40Trials & LaserTrials )) mean(TE.RTpr_lick_pS_all(hit50Trials & LaserTrials))];
    plot(x,y2,'--','color', mycolors_SL2('gr2'));       
    set(gca, 'YLim', [0 100], 'YTick', [0 50 100], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
    xlabel('Norm. SPL NoLaser'); ylabel('RTpr'); title('RTpr Mean'); 
    hold off; 
        
    subplot(2,4,6); 
    x = [20 30 40 50];   
    y1 = [median(TE.RTpr_lick_pS_all(hit20Trials & NoLaserTrials)) median(TE.RTpr_lick_pS_all(hit30Trials & NoLaserTrials)) median(TE.RTpr_lick_pS_all(hit40Trials & NoLaserTrials )) median(TE.RTpr_lick_pS_all(hit50Trials & NoLaserTrials))];
    plot(x,y1,'-','color', mycolors_SL2('gr2'));       
    hold on;  
    y2 = [median(TE.RTpr_lick_pS_all(hit20Trials & LaserTrials)) median(TE.RTpr_lick_pS_all(hit30Trials & LaserTrials)) median(TE.RTpr_lick_pS_all(hit40Trials & LaserTrials )) median(TE.RTpr_lick_pS_all(hit50Trials & LaserTrials))];
    plot(x,y2,'--','color', mycolors_SL2('gr2'));       
    set(gca, 'YLim', [0 100], 'YTick', [0 50 100], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
    xlabel('Norm. SPL NoLaser'); ylabel('RT'); title('RTpr median'); 
    hold off; 
    
    subplot (2,4,7);
    xData = TE.RTpr_lick_pS_all(hit50Trials & NoLaserTrials);
    h(1, 1) = cdfplot (xData); 
    hold on; 
    xData = TE.RTpr_lick_pS_all(hit50Trials & LaserTrials);
    h(1, 2) = cdfplot (xData);  
    xData = TE.RTpr_lick_pS_all(hit40Trials & NoLaserTrials);
    h(1, 3) = cdfplot (xData); 
    xData = TE.RTpr_lick_pS_all(hit40Trials & LaserTrials);
    h(1, 4) = cdfplot (xData);  
    xData = TE.RTpr_lick_pS_all(hit3020Trials & NoLaserTrials);
    h(1, 5) = cdfplot (xData);   
    xData = TE.RTpr_lick_pS_all(hit3020Trials & LaserTrials);
    h(1, 6) = cdfplot (xData);

    set( h(:,1), 'LineStyle', '-', 'Color', mycolors_SL2('gr1'));
    set( h(:,2), 'LineStyle', '--', 'Color', mycolors_SL2('gr1'));
    set( h(:,3), 'LineStyle', '-', 'Color', mycolors_SL2('gr2'));
    set( h(:,4), 'LineStyle', '--', 'Color', mycolors_SL2('gr2'));
    set( h(:,5), 'LineStyle', '-', 'Color', mycolors_SL2('gr4'));
    set( h(:,6), 'LineStyle', '--', 'Color', mycolors_SL2('gr4'));
%     set( h(:,7), 'LineStyle', '-', 'Color', mycolors_SL2('gr4'));
%     set( h(:,8), 'LineStyle', '--', 'Color', mycolors_SL2('gr4'));
    legend('50Laser-', '50Laser+', '40Laser-', '40Laser+', '3020Laser-', '3020Laser+', 'Location','southeast')
    set(gca, 'xlim', [0 100], 'XTick', [0 50 100]);        
    xlabel('RTpr'); ylabel('Fraction'); title('Hit Trials RTpr cumulative');
    hold off  
           
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end   
    
   %% Averages aligned to Laser
    saveName = [subjectName '_lick_raster5'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    
    varargin = {'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording'};

    linecolors = [mycolors_SL2('neutral'); mycolors_SL2('re3'); mycolors_SL2('re1')];
    varargin2 = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'window', [-3, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    
    subplot(4,4,1); % lick raster for Sound1NoLaser
    eventRasterFromTE(TE, Sound1NoLaser, 'Port1In', varargin{:});
    title('Sound1NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(4,4,2); % lick raster for Sound1Laser10
    eventRasterFromTE(TE, Sound1Laser10, 'Port1In', varargin{:});
    title('Sound1Laser10'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,3); % lick raster for Sound1Laser20
    eventRasterFromTE(TE, Sound1Laser20, 'Port1In', varargin{:});
    title('Sound1Laser20'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,4,4); % lick average for Sound1
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1NoLaser, Sound1Laser10, Sound1Laser20}, 'Port1In', varargin2{:});
    legend(hl, {'Sound1NoLaser', 'Sound1Laser10', 'Sound1Laser20'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
  
%     subplot(4,4,5); % lick raster for Sound2NoLaser
%     eventRasterFromTE(TE, Sound2NoLaser, 'Port1In', varargin{:});
%     title('Sound2NoLaser'); ylabel('trial number');
%     set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
%         
%     subplot(4,4,6); % lick raster for Sound2Laser10
%     eventRasterFromTE(TE, Sound2Laser10, 'Port1In', varargin{:});
%     title('Sound2Laser10'); ylabel('trial number');
%     set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
%     
%     subplot(4,4,7); % lick raster for Sound2Laser20
%     eventRasterFromTE(TE, Sound2Laser20, 'Port1In', varargin{:});
%     title('Sound2Laser20'); ylabel('trial number');
%     set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
% 
%     subplot(4,4,8); % lick average for Sound2
%     [ha, hl] = plotEventAverageFromTE(TE, {Sound2NoLaser, Sound2Laser10, Sound2Laser20}, 'Port1In', varargin2{:});
%     legend(hl, {'Sound2NoLaser', 'Sound2Laser10', 'Sound2Laser20'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
%     ylabel('licks (s)'); xlabel('time from Cue (s)');  
%     set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);     
%      
%     subplot(4,4,9); % lick raster for Sound3NoLaser
%     eventRasterFromTE(TE, Sound3NoLaser, 'Port1In', varargin{:});
%     title('Sound3NoLaser'); ylabel('trial number');
%     set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
%         
%     subplot(4,4,10); % lick raster for Sound3Laser10
%     eventRasterFromTE(TE, Sound3Laser10, 'Port1In', varargin{:});
%     title('Sound3Laser10'); ylabel('trial number');
%     set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
%     
%     subplot(4,4,11); % lick raster for Sound3Laser20
%     eventRasterFromTE(TE, Sound3Laser20, 'Port1In', varargin{:});
%     title('Sound3Laser20'); ylabel('trial number');
%     set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
% 
%     subplot(4,4,12); % lick average for Sound3
%     [ha, hl] = plotEventAverageFromTE(TE, {Sound3NoLaser, Sound3Laser10, Sound3Laser20}, 'Port1In', varargin2{:});
%     legend(hl, {'Sound3NoLaser', 'Sound3Laser10', 'Sound3Laser20'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
%     ylabel('licks (s)'); xlabel('time from Cue (s)');  
%     set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
     
    subplot(4,4,13); % lick raster for Sound4NoLaser
    eventRasterFromTE(TE, Sound4NoLaser, 'Port1In', varargin{:});
    title('Sound4NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(4,4,14); % lick raster for Sound4Laser10
    eventRasterFromTE(TE, Sound4Laser10, 'Port1In', varargin{:});
    title('Sound4Laser10'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,15); % lick raster for Sound4Laser20
    eventRasterFromTE(TE, Sound4Laser20, 'Port1In', varargin{:});
    title('Sound4Laser20'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,4,16); % lick average for Sound4
    [ha, hl] = plotEventAverageFromTE(TE, {Sound4NoLaser, Sound4Laser10, Sound4Laser20}, 'Port1In', varargin2{:});
    legend(hl, {'Sound4NoLaser', 'Sound4Laser10', 'Sound4Laser20'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); 
  
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end   
%%  performance pooled  
    ordering3 = {...        
        'Hit', 'B2', 'C2';...
        'Hit50', 'B4', 'C4';...
        'Hit40', 'B5', 'C5';...
        'Hit30', 'B6', 'C6';...
        'Hit20', 'B7', 'C7';...
        'Hit5040', 'B8', 'C8';...
        'Hit3020', 'B9', 'C9';...        
         };
    for d3 = 1:size(ordering3,1)
        groups = {'nolaser', 'laser', 'laser10', 'laser20'};
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], groups, 'Performance', 'B1');
        groups = {'Hit', 'FA', 'Hit50', 'Hit40', 'Hit30', 'Hit20', 'Hit5040', 'Hit3020', 'FA50', 'FA40', 'FA30', 'FA20', 'FA5040', 'FA3020'}';
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], groups, 'Performance', 'A2');
        data = [HitRate_pooled.(ordering3{d3,1}).NoLaser.all HitRate_pooled.(ordering3{d3,1}).Laser.all HitRate_pooled.(ordering3{d3,1}).Laser10.all HitRate_pooled.(ordering3{d3,1}).Laser20.all];
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], data, 'Performance', (ordering3{d3,2}));
    end
    
      ordering3 = {...        
        'FA', 'B3', 'C3';...
        'FA50', 'B10', 'C10';...
        'FA40', 'B11', 'C11';...
        'FA30', 'B12', 'C12';...
        'FA20', 'B13', 'C13';...
        'FA5040', 'B14', 'C14';...
        'FA3020', 'B15', 'C15';...
         };
    for d3 = 1:size(ordering3,1)
        data = [FARate_pooled.(ordering3{d3,1}).NoLaser.all FARate_pooled.(ordering3{d3,1}).Laser.all FARate_pooled.(ordering3{d3,1}).Laser10.all FARate_pooled.(ordering3{d3,1}).Laser20.all];
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], data, 'Performance', (ordering3{d3,2}));
    end     

% RT  pooled
   ordering3 = {...
        'hit', hitTrials, 'B2';...
        'FA', FATrials, 'B3';...
        'hit50', hit50Trials, 'B4';...
        'hit40', hit40Trials, 'B5';...
        'hit30', hit30Trials, 'B6';...
        'hit20', hit20Trials, 'B7';... 
        'hit5040', hit5040Trials, 'B8';...
        'hit3020', hit3020Trials, 'B9';...        
        'FA50', FA50Trials, 'B10';...
        'FA40', FA40Trials, 'B11';...
        'FA30', FA30Trials, 'B12';...
        'FA20', FA20Trials, 'B13';... 
        'FA5040', FA5040Trials, 'B14';...
        'FA3020', FA3020Trials, 'B15';... 
        }; 

    for d3 = 1:size(ordering3,1)
        groups = {'nolaser', 'laser', 'laser10', 'laser20'};
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], groups, 'RTprMean', 'B1');
        groups = {'Hit', 'FA', 'Hit50', 'Hit40', 'Hit30', 'Hit20', 'Hit5040', 'Hit3020', 'FA50', 'FA40', 'FA30', 'FA20', 'FA5040', 'FA3020'}';
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], groups, 'RTprMean', 'A2');
        y1 = nanmean(TE.RTpr_lick_pS_all(NoLaserTrials & (ordering3{d3,2})));
        y2 = nanmean(TE.RTpr_lick_pS_all(LaserTrials & (ordering3{d3,2})));
        y3 = nanmean(TE.RTpr_lick_pS_all(Laser10Trials & (ordering3{d3,2})));
        y4 = nanmean(TE.RTpr_lick_pS_all(Laser20Trials & (ordering3{d3,2})));
        data = [y1 y2 y3 y4];
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], data, 'RTprMean', (ordering3{d3,3}));
    end
    
    for d3 = 1:size(ordering3,1)
        groups = {'nolaser', 'laser', 'laser10', 'laser20'};
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], groups, 'RTprMedian', 'B1');
        groups = {'Hit', 'FA', 'Hit50', 'Hit40', 'Hit30', 'Hit20', 'Hit5040', 'Hit3020', 'FA50', 'FA40', 'FA30', 'FA20', 'FA5040', 'FA3020'}';
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], groups, 'RTprMedian', 'A2');
        y1 = nanmedian(TE.RTpr_lick_pS_all(NoLaserTrials & (ordering3{d3,2})));
        y2 = nanmedian(TE.RTpr_lick_pS_all(LaserTrials & (ordering3{d3,2})));
        y3 = nanmedian(TE.RTpr_lick_pS_all(Laser10Trials & (ordering3{d3,2})));
        y4 = nanmedian(TE.RTpr_lick_pS_all(Laser20Trials & (ordering3{d3,2})));
        data = [y1 y2 y3 y4];
        xlswrite([subjectName '_performance_SPL_pooled.xlsx'], data, 'RTprMedian', (ordering3{d3,3}));
    end

% CS US lick pooled 
ordering2 = {...
        'Cs_lick', Cs_lick;...
        'Us_lick', Us_lick;...
        'Cs_lick_norm', Cs_lick_norm;...
        'Us_lick_norm', Us_lick_norm;...
        };
    for c2 = 1:size(ordering2,1)   
        groups = {'nolaser', 'laser'};
        xlswrite([subjectName '_performance_pooled.xlsx'], groups, (ordering2{c2,1}), 'B1');
        groups = {'Go', 'Nogo'}';
        xlswrite([subjectName '_performance_pooled.xlsx'], groups, (ordering2{c2,1}), 'A2');
        data = (ordering2{c2,2});
        thisdata = [nanmean(data.Sound1NoLaser.all) nanmean(data.Sound1Laser.all)];
        xlswrite([subjectName '_performance_pooled.xlsx'], thisdata, (ordering2{c2,1}), 'B2');
        thatdata = [nanmean(data.Sound4NoLaser.all) nanmean(data.Sound4Laser.all)];
        xlswrite([subjectName '_performance_pooled.xlsx'], thatdata, (ordering2{c2,1}), 'B3');
    end

% fplicks pooled
r2 = struct(...
    'all', [],...
    'avg', [],...
    'sem', [],...
    'Sess', cell(1,1),...
    'Sess_avg', zeros(nSessions, 1)...
    );
s2 = struct(...
    'rate', r2,...
    'prob', r2...
    );
fpLicks_pooled = struct(...
    'nolaser', s2,...
    'laser', s2,...
    'laser1', s2,...
    'laser10', s2,...
    'laser20', s2...
   );

 ordering = {...        
    'nolaser', fpLickNoLaser, filterTE(TE, 'StimAmp', 0, 'reject', 0);...
    'laser', fpLickLaser, filterTE(TE, 'StimAmp', 5, 'reject', 0);...
    'laser1', fpLickLaser1, filterTE(TE, 'StimFreq', 1, 'reject', 0);...
    'laser10', fpLickLaser10, filterTE(TE, 'StimFreq', 10, 'reject', 0);...
    'laser20', fpLickLaser20, filterTE(TE, 'StimFreq', 20, 'reject', 0);...
    };  
    
   for c2 = 1:size(ordering,1)
       thisdata = TE.fpLicks.rate(ordering{c2, 2});
       fpLicks_pooled.(ordering{c2,1}).rate.all = thisdata;
       fpLicks_pooled.(ordering{c2,1}).rate.avg = nanmean(thisdata);
       fpLicks_pooled.(ordering{c2,1}).rate.sem = nanSEM(thisdata);
       
       thatdata = length(find(ordering{c2,2})) / length(find(ordering{c2,3}));        
       fpLicks_pooled.(ordering{c2,1}).prob.avg = thatdata; 
   end   
save(fullfile(savepath, ['summary_' subjectName '_fpLicks_pooled.mat']), 'fpLicks_pooled');

ordering2 = {...
    'nolaser', 'A2';...
    'laser', 'B2';...
    'laser1', 'C2';...
    'laser10', 'D2';...
    'laser20', 'E2';...
    };
for c2 = 1:size(ordering2,1) 
    groups = {'nolaser', 'laser', 'laser1', 'laser10', 'laser20', 'laser30'};
    xlswrite([subjectName '_fpLicks_pooled.xlsx'], groups, 'rate', 'A1');
    xlswrite([subjectName '_fpLicks_pooled.xlsx'], fpLicks_pooled.(ordering2{c2,1}).rate.avg, 'rate', (ordering2{c2,2}));
    xlswrite([subjectName '_fpLicks_pooled.xlsx'], groups, 'prob', 'A1');
    xlswrite([subjectName '_fpLicks_pooled.xlsx'], fpLicks_pooled.(ordering2{c2,1}).prob.avg, 'prob', (ordering2{c2,2}));    
end          
    
    %% RT distribution plot
    figSize = [12 20];
    saveName = ['RT distribution_individual session'];
    ensureFigure(saveName, 1); 

    subA = ceil(sqrt(nSessions));
    xsessions = 1:nSessions;
    
    for counter = xsessions 
        subplot(subA, subA, counter);
        histogram(RT_pooled.mix.rt{counter, 1}, 'BinWidth',0.05);
        set(gca, 'XLim', [0 1], 'XTickLabel', {'0', '0.2', '0.4', '0.6', '0.8', '1'}); 
        ylabel(['all lick RT Sess ' num2str(counter)]); 
        h1 = jbtest(RT_pooled.mix.rt{counter, 1});
        textBox(['hMix' num2str(counter) '= ' num2str(h1)],[], [0.8 0.95], 9); 
        h2 = jbtest(RT_pooled.hit.rt{counter, 1});
        textBox(['hHit' num2str(counter) '= ' num2str(h2)],[], [0.8 0.75], 9); 
        d = percentile(RT_pooled.hit.rt{counter, 1}, 0.9) - percentile(RT_pooled.hit.rt{counter, 1}, 0.1); %calculate width of RT distribution
        textBox(['dRT9010= ' num2str(d)],[], [0.8 0.55], 9); 
    end
    %     formatFigurePublish('size', figSize);
%     set(gcf,'toolbar','figure');
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
    
%  Reaction time distribution  
    figSize = [12 20];
%     nbins = 20;
    saveName = ['RT distribution'];
    ensureFigure(saveName, 1); 
    xTick = [0 0.2 0.4 0.6 0.8 1];
    ylim1 = [0 50];
    ylim2 = [0 150];
    ylim3 = [0 20];
    ylim4 = [0 40];
    ylim5 = [0 50];
    ylim6 = [0 150];
 
    subplot(4,3,1);
    RT_hit_value = [];
    FP_hit_value = [];

    for counter = xsessions
        RT_hit_value = [RT_hit_value; RT_pooled.hit.rt{counter, 1}];
        histogram(RT_pooled.hit.rt{counter, 1}, 'BinWidth',0.05);
        set(gca, 'XLim', [0 1], 'YLim', ylim1, 'XTick', xTick, 'XTickLabel', {'0', '0.2', '0.4', '0.6', '0.8', '1'}); 
        ylabel('Hit RT'); 
        h = jbtest(RT_pooled.hit.rt{counter, 1});
        textBox(['h' num2str(counter) '= ' num2str(h)],[], [0.8 0.95 - 0.1*counter], 9); 
        hold on;      
    end
    title('if h=1 reject normal distribution at 5% significance level'); 
    
    subplot(4,3,2); 
    histogram(RT_hit_value, 'BinWidth',0.05);
    set(gca, 'XLim', [0 1], 'YLim', ylim2, 'XTick', xTick, 'XTickLabel', {'0', '0.2', '0.4', '0.6', '0.8', '1'});  
    
    subplot(4,3,3);
    normplot(RT_hit_value); hold on;
%     h = jbtest(RT_hit_value);
    textBox(['h = ' num2str(h)],[], [0.2 0.95], 9); hold off;
    
    subplot(4,3,4);
    RT_FA_value = [];
    for counter = xsessions
        RT_FA_value = [RT_FA_value; RT_pooled.FA.rt{counter, 1}];  
        histogram(RT_pooled.FA.rt{counter, 1}, 'BinWidth',0.05);
        set(gca, 'XLim', [0 1], 'YLim', ylim3, 'XTick', xTick, 'XTickLabel', {'0', '0.2', '0.4', '0.6', '0.8', '1'}); 
        ylabel('FA RT'); 
%         h = jbtest(RT_pooled.FA.rt{counter, 1});
        textBox(['h' num2str(counter) '= ' num2str(h)],[], [0.8 0.95 - 0.1*counter], 9); hold on;        
    end

    subplot(4,3,5); 
    histogram(RT_FA_value, 'BinWidth',0.05);
    set(gca, 'XLim', [0 1], 'YLim', ylim4, 'XTick', xTick, 'XTickLabel', {'0', '0.2', '0.4', '0.6', '0.8', '1'});  
    
    subplot(4,3,6);
    normplot(RT_FA_value); hold on;
    h = jbtest(RT_FA_value);
    textBox(['h = ' num2str(h)],[], [0.2 0.95], 9);  
    
    subplot(4,3,7);
    RT_mix_value = [];
    for counter = xsessions
        RT_mix_value = [RT_mix_value; RT_pooled.mix.rt{counter, 1}];  
        histogram(RT_pooled.mix.rt{counter, 1}, 'BinWidth',0.05);
        set(gca, 'XLim', [0 1], 'YLim', ylim5, 'XTick', xTick, 'XTickLabel', {'0', '0.2', '0.4', '0.6', '0.8', '1'}); 
        ylabel('all lick trials RT'); 
        h = jbtest(RT_pooled.mix.rt{counter, 1});
        textBox(['h' num2str(counter) '= ' num2str(h)],[], [0.8 0.95 - 0.1*counter], 9); hold on;        
    end

    subplot(4,3,8); 
    histogram(RT_mix_value, 'BinWidth',0.05);
    set(gca, 'XLim', [0 1], 'YLim', ylim6, 'XTick', xTick, 'XTickLabel', {'0', '0.2', '0.4', '0.6', '0.8', '1'});  
    
    subplot(4,3,9);
    normplot(RT_mix_value); hold on;
    h = jbtest(RT_mix_value);
    textBox(['h = ' num2str(h)],[], [0.2 0.95], 9);     
%     formatFigurePublish('size', figSize);
    set(gcf,'toolbar','figure');
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end    
    %% Save behavior plot
    saveName = [subjectName '_behavior2'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  
    
    subplot(2,3,1); 
    performance_sound1 = length(find(anticipTrials & Sound1Laser)) / length(find(Sound1Laser));
    performance_sound4 = length(find(anticipTrials & Sound4Laser)) / length(find(Sound4Laser));
    x = [1 4];
    y = [performance_sound1 performance_sound4];
    plot(x,y,'-o', 'color', [215/255 48/255 31/255]);  hold on;
    performance2_sound1 = length(find(anticipTrials & Sound1NoLaser)) / length(find(Sound1NoLaser));
    performance2_sound4 = length(find(anticipTrials & Sound4NoLaser)) / length(find(Sound4NoLaser));
    x = [1 4];
    y = [performance2_sound1 performance2_sound4];
    plot(x,y,'-o', 'color', [0/255 128/255 0/255]);      
    set(gca, 'YLim', [0 1]);
    legend({'Laser', 'NoLaser'}, 'Location','southwest');
    xlabel('Sound'); ylabel('Performance'); title('Performance');
    
    subplot(2,3,2);  
    y1 = length(find(fpLickNoLaser)) / length(find(filterTE(TE, 'StimAmp', 0, 'reject', 0))); 
    y2 = length(find(fpLickLaser)) / length(find(filterTE(TE, 'StimAmp', 5, 'reject', 0))); 
    yData = [y1 y2];
    bar (yData, 'FaceColor',[0/255 128/255 0/255],'EdgeColor',[0/255 128/255 0/255]); hold on;
    set(gca, 'XTick', [1 2], 'XTickLabel', {'NoLaser', 'Laser'}, 'YLim', [0 1]); 
    ylabel('Licks(Hz)'); title('fpLick chance'); 
    
    subplot(2,3,3);  
    x = [1 4];   
    y1 = [nanmean(TE.csLicks.rate(Sound1Laser)) nanmean(TE.csLicks.rate(Sound4Laser))];
    err = [nanSEM(TE.csLicks.rate(Sound1Laser)) nanSEM(TE.csLicks.rate(Sound4Laser))];    
    errorbar(x,y1,err,'-s','color', [215/255 48/255 31/255], 'MarkerSize',10,'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]); hold on;
    y2 = [nanmean(TE.csLicks.rate(Sound1NoLaser)) nanmean(TE.csLicks.rate(Sound4NoLaser))];
    err = [nanSEM(TE.csLicks.rate(Sound1NoLaser)) nanSEM(TE.csLicks.rate(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Licks(Hz)'); title('csLicks rate'); 
    
    subplot(2,3,4);  
    x = [1 4];   
    y1 = [nanmean(TE.usLicks.rate(Sound1Laser)) nanmean(TE.usLicks.rate(Sound4Laser))];
    err = [nanSEM(TE.usLicks.rate(Sound1Laser)) nanSEM(TE.usLicks.rate(Sound4Laser))];    
    errorbar(x,y1,err,'-s','color', [215/255 48/255 31/255], 'MarkerSize',10,'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]); hold on;
    y2 = [nanmean(TE.usLicks.rate(Sound1NoLaser)) nanmean(TE.usLicks.rate(Sound4NoLaser))];
    err = [nanSEM(TE.usLicks.rate(Sound1NoLaser)) nanSEM(TE.usLicks.rate(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Licks(Hz)'); title('usLicks rate'); 
    
    subplot(2,3,5);  
    x = [1 4];   
    y1 = [nanmean(TE.RT(Sound1Laser)) nanmean(TE.RT(Sound4Laser))];
    err = [nanSEM(TE.RT(Sound1Laser)) nanSEM(TE.RT(Sound4Laser))];    
    errorbar(x,y1,err,'-s','color', [215/255 48/255 31/255], 'MarkerSize',10,'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]); hold on;
    y2 = [nanmean(TE.RT(Sound1NoLaser)) nanmean(TE.RT(Sound4NoLaser))];
    err = [nanSEM(TE.RT(Sound1NoLaser)) nanSEM(TE.RT(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('RT'); title('RT Mean');    
    
    subplot(2,3,6);  
    x = [1 4];   
    y1 = [nanmedian(TE.RT(Sound1Laser)) nanmedian(TE.RT(Sound4Laser))];  
    plot(x,y1,'-s','color', [215/255 48/255 31/255], 'MarkerSize',10, 'color', [215/255 48/255 31/255]); hold on;
    y2 = [nanmedian(TE.RT(Sound1NoLaser)) nanmedian(TE.RT(Sound4NoLaser))];  
    plot(x,y2,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10, 'color', [0/255 128/255 0/255]); 
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('RT'); title('RT Median');         
           
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end   

% lick and photometry rasters aligned to cue
clim1 = [-8 8];
clim2 = [-6 6];
% clim1 = [-0.06 0.06];
% clim2 = [-0.06 0.06];
clims = [clim1; clim2];
    saveName = [subjectName '_cue response'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
        
    subplot(4,4,1); % lick raster for Sound1
    eventRasterFromTE(TE, Sound1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1Trials'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,2); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 4], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
        
%     subplot(4,4,3); % phRaster for Sound1
%     phRasterFromTE(TE, Sound1Trials, channel, 'window', [-4 4], 'zeroTimes', TE.Cue, 'CLim', clim, 'FluorDataField', fluorField);
%     % imagesc('XData', xData', 'CData', alignedPhotometryData);
%     
%     subplot(4,4,4); % phAverage for Sound1
%     avgData = phAverageFromTE(TE, Sound1Trials, channel, 'window', [-4 4], 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
%     plot(avgData.xData, avgData.Avg); title('Reponse'); ylabel(num2str(fluorField)); xlabel('time from cue (s)');
    
    subplot(4,4,5); % lick raster for Sound2
    eventRasterFromTE(TE, Sound2Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound2Trials'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
    
    subplot(4,4,6); % lick average for Sound2
    avgData1 = eventAverageFromTE(TE, Sound2Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 4], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
%     subplot(4,4,7); % phRaster for Sound2
%     phRasterFromTE(TE, Sound2Trials, channel, 'window', [-4 4], 'zeroTimes', TE.Cue, 'CLim', clim, 'FluorDataField', fluorField);
%     
%     subplot(4,4,8); % phAverage for Sound2
%     avgData = phAverageFromTE(TE, Sound2Trials, channel, 'window', [-4 4], 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
%     plot(avgData.xData, avgData.Avg); title('Response'); ylabel(num2str(fluorField)); xlabel('time from cue (s)');
    
    subplot(4,4,9); % lick raster for Sound3
    eventRasterFromTE(TE, Sound3Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound3Trials'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
    
    subplot(4,4,10); % lick average for Sound3
    avgData1 = eventAverageFromTE(TE, Sound3Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 4], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
%     subplot(4,4,11); % phRaster for Sound3
%     phRasterFromTE(TE, Sound3Trials, channel, 'window', [-4 4], 'zeroTimes', TE.Cue, 'CLim', clim, 'FluorDataField', fluorField);
%     
%     subplot(4,4,12); % phAverage for Sound3
%     avgData = phAverageFromTE(TE, Sound3Trials, channel, 'window', [-4 4], 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
%     plot(avgData.xData, avgData.Avg); title('Response'); ylabel(num2str(fluorField)); xlabel('time from cue (s)');
    
    subplot(4,4,13); % lick raster for Sound4Trials
    eventRasterFromTE(TE, Sound4Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4Trials'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
    
    subplot(4,4,14); % lick average for Sound4Trials
    avgData1 = eventAverageFromTE(TE, Sound4Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 4], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
%     subplot(4,4,15); % phRaster for Sound4Trials
%     phRasterFromTE(TE, Sound4Trials, channel, 'window', [-4 4], 'zeroTimes', TE.Cue, 'CLim', clim, 'FluorDataField', fluorField);
%     
%     subplot(4,4,16); % phAverage for Sound4Trials
%     avgData = phAverageFromTE(TE, Sound4Trials, channel, 'window', [-4 4], 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
%     plot(avgData.xData, avgData.Avg); title('Response'); ylabel(num2str(fluorField)); xlabel('time from cue (s)');
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
 
% lick and photometry rasters aligned to cue
    saveName = [subjectName '_cue response3'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
        
    subplot(6,2,1); % lick raster for Sound1
    eventRasterFromTE2(TE, Sound1_50_Trials & NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1-50-NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
        
    subplot(6,2,2); % phRaster for Sound1
    eventRasterFromTE2(TE, Sound1_50_Trials & LaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1-50-Laser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14); 

    subplot(6,2,3); % lick raster for Sound1
    eventRasterFromTE2(TE, Sound1_40_Trials & NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1-40-NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
        
    subplot(6,2,4); % phRaster for Sound1
    eventRasterFromTE2(TE, Sound1_40_Trials & LaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1-40-Laser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14); 

    subplot(6,2,5); % lick raster for Sound1
    eventRasterFromTE2(TE, Sound1_3020_Trials & NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1-3020-NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
        
    subplot(6,2,6); % phRaster for Sound1
    eventRasterFromTE2(TE, Sound1_3020_Trials & LaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1-3020-Laser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14); 

    subplot(6,2,7); % lick raster for Sound4
    eventRasterFromTE2(TE, Sound4_50_Trials & NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4-50-NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
        
    subplot(6,2,8); % phRaster for Sound4
    eventRasterFromTE2(TE, Sound4_50_Trials & LaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4-50-Laser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14); 

    subplot(6,2,9); % lick raster for Sound4
    eventRasterFromTE2(TE, Sound4_40_Trials & NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4-40-NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
        
    subplot(6,2,10); % phRaster for Sound4
    eventRasterFromTE2(TE, Sound4_40_Trials & LaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4-40-Laser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14); 

    subplot(6,2,11); % lick raster for Sound4
    eventRasterFromTE2(TE, Sound4_3020_Trials & NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4-3020-NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);
        
    subplot(6,2,12); % phRaster for Sound4
    eventRasterFromTE2(TE, Sound4_3020_Trials & LaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4-3020-Laser'); ylabel('trial number');
    set(gca, 'XLim', [-4 4]); set(gca, 'FontSize', 14);     
 
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end

 % Averages aligned to Cue
    saveName = [subjectName '_Cue response_Avgs'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    linecolors = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('sound3'); mycolors_SL2('FA'); mycolors_SL2('uncuedReward')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2,  'window', [-4, 6], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];

    [ha, hl] = plotEventAverageFromTE(TE, {Sound1Trials, Sound4Trials}, 'Port1In', varargin{:});
    legend(hl, {'Sound1', 'Sound4' }, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');     
        
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end  
    
% lick and photometry rasters aligned to cue
% clim1 = [-6 6];
% clim2 = [-6 6];
% clims = [clim1; clim2];
% clim = [];

    saveName = [subjectName '_cue response2'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
%     clim = clims(channel,:);
     
    subplot(5,4,1); % lick raster for hit
    eventRasterFromTE(TE, Sound1Lick, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1hitTrials'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,2); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound1Lick, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(5,4,3); % lick raster for miss
    eventRasterFromTE(TE, Sound1NoLick, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1missTrials'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,4); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound1NoLick, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
     subplot(5,4,5); % lick raster for hit
    eventRasterFromTE(TE, Sound2Lick, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound2hitTrials'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,6); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound2Lick, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(5,4,7); % lick raster for miss
    eventRasterFromTE(TE, Sound2NoLick, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound2missTrials'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,8); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound2NoLick, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)');  
    
    subplot(5,4,9); % lick raster for FA
    eventRasterFromTE(TE, Sound4Lick, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4FATrials'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(5,4,10); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound4Lick, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(5,4,11); % lick raster for CR
    eventRasterFromTE(TE, Sound4NoLick, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4CRTrials'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(5,4,12); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound4NoLick, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)');   
    
     subplot(5,4,13); % lick raster for hit
    eventRasterFromTE(TE, Sound3Lick, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound3hitTrials'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,14); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound3Lick, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(5,4,15); % lick raster for miss
    eventRasterFromTE(TE, Sound3NoLick, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound3missTrials'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,16); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound3NoLick, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(5,4,17); % lick raster for uncuedReward
    eventRasterFromTE(TE, uncuedReward, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('uncuedReward'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(5,4,18); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, uncuedReward, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(5,4,19); % lick raster for uncuedPunish
    eventRasterFromTE(TE, uncuedPunish, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('uncuedPunish'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(5,4,20); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, uncuedPunish, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 6], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)');   
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end    
    
 % Averages aligned to Laser
    saveName = [subjectName '_Laser response_Avg'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
 
    linecolors = [mycolors_SL2('neutral'); mycolors_SL2('uncuedReward'); mycolors_SL2('re3'); mycolors_SL2('re2'); mycolors_SL2('re1')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'window', [-3, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(3, 1, 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {NoLaserTrials, LaserTrials}, 'Port1In', varargin{:});
    legend(hl, {'NoLaserTrials', 'LaserTrials'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
        
    subplot(3, 1, 2); 
    [ha, hl] = plotEventAverageFromTE(TE, {LickNoLaser, LickLaserTrials}, 'Port1In', varargin{:});
    legend(hl, {'LickNoLaser', 'LickLaserTrials'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
    
    subplot(3, 1, 3); 
    [ha, hl] = plotEventAverageFromTE(TE, {NoLickNoLaser, NoLickLaser}, 'Port1In', varargin{:});
    legend(hl, {'NoLickNoLaser', 'NoLickLaserTrials'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
 
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end
    

    %% sated raster pooled
    t2 = struct(...
        'rate', [],...
        'prob', []...
        );
    s2 = struct(...
        'nolaser', t2,...
        'laser', t2,...    
        'laser1', t2,...
        'laser10', t2,...
        'laser20', t2,...
        'laser30', t2...
       );
    sated_csLicks_pooled = struct(...
        'all', s2,...
        'sound1', s2,...
        'sound4', s2...
        );
    ordering = {...        
        'nolaser', satedNoLaser;...
        'laser', satedLaser;...
        'laser1', satedLaser1;...
        'laser10', satedLaser10;...
        'laser20', satedLaser20;...
        'laser30', satedLaser30;...
        };  
    
   for c2 = 1:size(ordering,1)      
       data = nanmean(TE.csLicks.rate(ordering{c2,2} & satedTrials));
       sated_csLicks_pooled.all.(ordering{c2,1}).rate = data;
       thisdata = nanmean(TE.csLicks.rate(ordering{c2,2} & satedSound1));
       sated_csLicks_pooled.sound1.(ordering{c2,1}).rate = thisdata;
       thatdata = nanmean(TE.csLicks.rate(ordering{c2,2} & satedSound4));
       sated_csLicks_pooled.sound4.(ordering{c2,1}).rate = thatdata;
       
       data = length(find(ordering{c2,2} & satedTrials & anticipTrials)) / length(find(ordering{c2,2} & satedTrials));        
       sated_csLicks_pooled.all.(ordering{c2,1}).prob = data; 
       thisdata = length(find(ordering{c2,2} & satedSound1 & anticipTrials)) / length(find(ordering{c2,2} & satedSound1));        
       sated_csLicks_pooled.sound1.(ordering{c2,1}).prob = thisdata; 
       thatdata = length(find(ordering{c2,2} & satedSound4 & anticipTrials)) / length(find(ordering{c2,2} & satedSound4));        
       sated_csLicks_pooled.sound4.(ordering{c2,1}).prob = thatdata; 
   end   
    save(fullfile(savepath, ['summary_' subjectName '_sated_csLicks_pooled.mat']), 'sated_csLicks_pooled');
%
     ordering2 = {...
        'nolaser', 'B2';...
        'laser', 'C2';...
        'laser1', 'D2';...
        'laser10', 'E2';...
        'laser20', 'F2';...
        'laser30', 'G2';...
        };
    for c2 = 1:size(ordering2,1) 
        groups = {'nolaser', 'laser', 'laser1', 'laser10', 'laser20', 'laser30'};
        xlswrite([subjectName '_sated_csLicks_pooled.xlsx'], groups, 'rate', 'B1');
        xlswrite([subjectName '_sated_csLicks_pooled.xlsx'], groups, 'prob', 'B1');
        groups = {'all', 'Sound1', 'Sound4'}';
        xlswrite([subjectName '_sated_csLicks_pooled.xlsx'], groups, 'rate', 'A2');
        xlswrite([subjectName '_sated_csLicks_pooled.xlsx'], groups, 'prob', 'A2');
        data = [sated_csLicks_pooled.all.(ordering2{c2,1}).rate sated_csLicks_pooled.sound1.(ordering2{c2,1}).rate sated_csLicks_pooled.sound4.(ordering2{c2,1}).rate]';
        xlswrite([subjectName '_sated_csLicks_pooled.xlsx'], data, 'rate', (ordering2{c2,2}));
        data = [sated_csLicks_pooled.all.(ordering2{c2,1}).prob sated_csLicks_pooled.sound1.(ordering2{c2,1}).prob sated_csLicks_pooled.sound4.(ordering2{c2,1}).prob]';
        xlswrite([subjectName '_sated_csLicks_pooled.xlsx'], data, 'prob', (ordering2{c2,2}));
    end
    % sated trials
    saveName = [subjectName '_sated behavior'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  
    
    subplot(2,3,1); 
    y1 = length(find(satedNoLaser & anticipTrials)) / length(find(satedNoLaser));
    y2 = length(find(satedLaser & anticipTrials)) / length(find(satedLaser));
    yData = [y1 y2];
    bar (yData, 'FaceColor',[0/255 128/255 0/255],'EdgeColor',[0/255 128/255 0/255]); hold on;  
    set(gca, 'XTick', [1 2], 'XTickLabel', {'NoLaser', 'Laser'}, 'YLim', [0 1]); 
    ylabel('AncitipLicks prob'); title('Sated-LickProp'); 

    subplot(2,3,2); 
    y1 = length(find(satedNoLaser & satedSound1 & anticipTrials)) / length(find(satedNoLaser & satedSound1));
    y2 = length(find(satedLaser & satedSound1 & anticipTrials)) / length(find(satedLaser & satedSound1));
    y3 = length(find(satedNoLaser & satedSound4 & anticipTrials)) / length(find(satedNoLaser & satedSound4));
    y4 = length(find(satedLaser & satedSound4 & anticipTrials)) / length(find(satedLaser & satedSound4));
    yData = [y1 y2 y3 y4];
    bar (yData, 'FaceColor',[0/255 128/255 0/255],'EdgeColor',[0/255 128/255 0/255]); hold on;  
    set(gca, 'XTick', [1 2 3 4], 'XTickLabel', {'GoLaser-', 'GoLaser+', 'NogoLaser-', 'NogoLaser+'}, 'YLim', [0 1]); 
    ylabel('AncitipLicks prob'); title('Sated-LickProp'); 
    
    subplot(2,3,3); 
    y1 = length(find(satedNoLaser & satedSound1 & anticipTrials)) / length(find(satedNoLaser & satedSound1));
    y2 = length(find(satedLaser10 & satedSound1 & anticipTrials)) / length(find(satedLaser10 & satedSound1));
    y3 = length(find(satedLaser20 & satedSound1 & anticipTrials)) / length(find(satedLaser20 & satedSound1));
    y4 = length(find(satedLaser30 & satedSound1 & anticipTrials)) / length(find(satedLaser30 & satedSound1));
    yData = [y1 y2 y3 y4];
    x = [1 2 3 4];
    plot(x,yData,'-o', 'color', [0/255 128/255 0/255]);  hold on;  
    y1 = length(find(satedNoLaser & satedSound4 & anticipTrials)) / length(find(satedNoLaser & satedSound4));
    y2 = length(find(satedLaser10 & satedSound4 & anticipTrials)) / length(find(satedLaser10 & satedSound4));
    y3 = length(find(satedLaser20 & satedSound4 & anticipTrials)) / length(find(satedLaser20 & satedSound4));
    y4 = length(find(satedLaser30 & satedSound4 & anticipTrials)) / length(find(satedLaser30 & satedSound4));
    yData = [y1 y2 y3 y4];
    plot(x,yData,'-o', 'color', [103/255 0/255 13/255]);
    legend({'Sound1', 'Sound4'}, 'Location','southwest');
    set(gca, 'XTick', [1 2 3 4], 'XTickLabel', {'NoLaser', 'Laser10', 'Laser20', 'Laser30'}, 'YLim', [0 1]); 
    ylabel('AncitipLicks prob'); title('Sated-LickProp');   
   
    subplot(2,3,4);  
    yData = [nanmean(TE.csLicks.rate(satedNoLaser)) nanmean(TE.csLicks.rate(satedLaser))];
    bar (yData, 'FaceColor',[0/255 128/255 0/255],'EdgeColor',[0/255 128/255 0/255]); hold on;  
    set(gca, 'XTick', [1 2 3 4], 'XTickLabel', {'NoLaser', 'Laser'}, 'YLim', [0 6]); 
    ylabel('AncitipLicks rate(Hz)'); title('Sated-LickRate');    
    
    subplot(2,3,5);  
    yData = [nanmean(TE.csLicks.rate(satedNoLaser & satedSound1)) nanmean(TE.csLicks.rate(satedLaser & satedSound1)) nanmean(TE.csLicks.rate(satedNoLaser & satedSound4)) nanmean(TE.csLicks.rate(satedLaser & satedSound4))];
    bar (yData, 'FaceColor',[0/255 128/255 0/255],'EdgeColor',[0/255 128/255 0/255]); hold on;  
    set(gca, 'XTick', [1 2 3 4], 'XTickLabel', {'GoLaser-', 'GoLaser+', 'NogoLaser-', 'NogoLaser+'}, 'YLim', [0 6]); 
    ylabel('AncitipLicks rate(Hz)'); title('Sated-LickRate');  
   
    subplot(2,3,6);      
    y1 = nanmean(TE.csLicks.rate(satedNoLaser & satedSound1));
    y2 = nanmean(TE.csLicks.rate(satedLaser10 & satedSound1));
    y3 = nanmean(TE.csLicks.rate(satedLaser20 & satedSound1));
    y4 = nanmean(TE.csLicks.rate(satedLaser30 & satedSound1));
    yData = [y1 y2 y3 y4];
    plot(x,yData,'-o', 'color', [0/255 128/255 0/255]);  hold on;  
    y1 = nanmean(TE.csLicks.rate(satedNoLaser & satedSound4));
    y2 = nanmean(TE.csLicks.rate(satedLaser10 & satedSound4));
    y3 = nanmean(TE.csLicks.rate(satedLaser20 & satedSound4));
    y4 = nanmean(TE.csLicks.rate(satedLaser30 & satedSound4));
    yData = [y1 y2 y3 y4];
    plot(x,yData,'-o', 'color', [103/255 0/255 13/255]);
    legend({'Sound1', 'Sound4'}, 'Location','southwest');
    set(gca, 'XTick', [1 2 3 4], 'XTickLabel', {'NoLaser', 'Laser10', 'Laser20', 'Laser30'}, 'YLim', [0 6]); 
    ylabel('AncitipLicks rate(Hz)'); title('Sated-LickRate');     
              
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
    
    %%
     % Save behavior plot
    saveName = [subjectName '_behavior_SPL_pSess'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  
    color1 = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('FA'); mycolors_SL2('CR'); mycolors_SL2('uncuedReward'); mycolors_SL2('uncuedPunish'); mycolors_SL2('sound3'); mycolors_SL2('sound4'); mycolors_SL2('neutral'); mycolors_SL2('re4'); 0.5* mycolors_SL2('hit'); ];
    color2 = [mycolors_SL2('FA'); mycolors_SL2('CR'); mycolors_SL2('uncuedPunish'); mycolors_SL2('sound3')];
    performance_hit50_all = [];
    performance_hit40_all = [];
    performance_hit3020_all = [];
    performance_FA50_all = [];
    performance_FA40_all = [];
    performance_FA3020_all = [];
    subplot(2,2,1);    
    for counter = 1:nSessions
        performance_hit = length(find(hitTrials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_hit50 = length(find(hit50Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_50_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_hit40 = length(find(hit40Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_40_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_hit30 = length(find(hit30Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_30_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_hit20 = length(find(hit20Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_20_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_hit3020 = length(find(hit3020Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_3020_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        x = [50 40 30 20];
        y = [performance_hit50 performance_hit40 performance_hit30 performance_hit20];
        plot(x,y,'-','color', color1(counter, :)); hold on;
        performance_hit_all(counter, :) = performance_hit;
        performance_hit50_all(counter, :) = performance_hit50;
        performance_hit40_all(counter, :)  = performance_hit40;
        performance_hit30_all(counter, :)  = performance_hit30;
        performance_hit20_all(counter, :)  = performance_hit20;
        performance_hit3020_all(counter, :)  = performance_hit3020;
                
        Laser_performance_hit = length(find(hitTrials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_hit50 = length(find(hit50Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_50_Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_hit40 = length(find(hit40Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_40_Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_hit30 = length(find(hit30Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_30_Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_hit20 = length(find(hit20Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_20_Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_hit3020 = length(find(hit3020Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound1_3020_Trials & LaserTrials & (TE.sessionIndex == counter)));
        x = [50 40 30 20];
        y = [Laser_performance_hit50 Laser_performance_hit40 Laser_performance_hit30 Laser_performance_hit20];
        plot(x,y,'-.','color', color1(counter, :)); hold on;
        Laser_performance_hit_all(counter, :) = Laser_performance_hit;
        Laser_performance_hit50_all(counter, :) = Laser_performance_hit50;
        Laser_performance_hit40_all(counter, :)  = Laser_performance_hit40;
        Laser_performance_hit30_all(counter, :)  = Laser_performance_hit30;
        Laser_performance_hit20_all(counter, :)  = Laser_performance_hit20;
        Laser_performance_hit3020_all(counter, :)  = Laser_performance_hit3020;
    end
    x = [20 30 40 50];
    y = [nanmean(performance_hit20_all) nanmean(performance_hit30_all) nanmean(performance_hit40_all) nanmean(performance_hit50_all)];
    err = [nanSEM(performance_hit20_all) nanSEM(performance_hit30_all) nanSEM(performance_hit40_all) nanSEM(performance_hit50_all)];
    errorbar(x,y,err,'-k', 'LineWidth', 2);      
    hold on;
    y = [nanmean(Laser_performance_hit20_all) nanmean(Laser_performance_hit30_all) nanmean(Laser_performance_hit40_all) nanmean(Laser_performance_hit50_all)];
    err = [nanSEM(Laser_performance_hit20_all) nanSEM(Laser_performance_hit30_all) nanSEM(Laser_performance_hit40_all) nanSEM(Laser_performance_hit50_all)];
    errorbar(x,y,err,'--k', 'LineWidth', 2);   
%     legend({'NoLaser', 'Laser'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
    xlabel('Norm. SPL'); ylabel('Lick Prob.'); title('Performance-Go');
    hold off;
    
    subplot(2,2,2);    
   for counter = 1:nSessions
        performance_FA = length(find(FATrials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_FA50 = length(find(FA50Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_50_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_FA40 = length(find(FA40Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_40_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_FA30 = length(find(FA30Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_30_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_FA20 = length(find(FA20Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_20_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        performance_FA3020 = length(find(FA3020Trials & NoLaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_3020_Trials & NoLaserTrials & (TE.sessionIndex == counter)));
        x = [50 40 30 20];
        y = [performance_FA50 performance_FA40 performance_FA30 performance_FA20];
        plot(x,y,'-','color', color1(counter, :)); hold on;
        performance_FA_all(counter, :) = performance_FA;
        performance_FA50_all(counter, :) = performance_FA50;
        performance_FA40_all(counter, :)  = performance_FA40;
        performance_FA30_all(counter, :)  = performance_FA30;
        performance_FA20_all(counter, :)  = performance_FA20;
        performance_FA3020_all(counter, :)  = performance_FA3020;
                
        Laser_performance_FA = length(find(FATrials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_FA50 = length(find(FA50Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_50_Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_FA40 = length(find(FA40Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_40_Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_FA30 = length(find(FA30Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_30_Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_FA20 = length(find(FA20Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_20_Trials & LaserTrials & (TE.sessionIndex == counter)));
        Laser_performance_FA3020 = length(find(FA3020Trials & LaserTrials & (TE.sessionIndex == counter))) / length(find(Sound4_3020_Trials & LaserTrials & (TE.sessionIndex == counter)));
        x = [50 40 30 20];
        y = [Laser_performance_FA50 Laser_performance_FA40 Laser_performance_FA30 Laser_performance_FA20];
        plot(x,y,'-.','color', color1(counter, :)); hold on;
        Laser_performance_FA_all(counter, :) = Laser_performance_FA;
        Laser_performance_FA50_all(counter, :) = Laser_performance_FA50;
        Laser_performance_FA40_all(counter, :)  = Laser_performance_FA40;
        Laser_performance_FA30_all(counter, :)  = Laser_performance_FA30;
        Laser_performance_FA20_all(counter, :)  = Laser_performance_FA20;
        Laser_performance_FA3020_all(counter, :)  = Laser_performance_FA3020;
    end
    x = [20 30 40 50];
    y = [nanmean(performance_FA20_all) nanmean(performance_FA30_all) nanmean(performance_FA40_all) nanmean(performance_FA50_all)];
    err = [nanSEM(performance_FA20_all) nanSEM(performance_FA30_all) nanSEM(performance_FA40_all) nanSEM(performance_FA50_all)];
    errorbar(x,y,err,'-k', 'LineWidth', 2);      
    hold on;
    y = [nanmean(Laser_performance_FA20_all) nanmean(Laser_performance_FA30_all) nanmean(Laser_performance_FA40_all) nanmean(Laser_performance_FA50_all)];
    err = [nanSEM(Laser_performance_FA20_all) nanSEM(Laser_performance_FA30_all) nanSEM(Laser_performance_FA40_all) nanSEM(Laser_performance_FA50_all)];
    errorbar(x,y,err,'--k', 'LineWidth', 2);   
    legend({'NoLaser', 'Laser'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
    xlabel('Norm. SPL'); ylabel('Lick Prob.'); title('Performance-NoGo');
    hold off;
    
    subplot(2,2,3); 
    for counter = 1:nSessions
        x = [20 30 40 50];   
        y1 = [mean(TE.RT(hit20Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit30Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit40Trials & NoLaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit50Trials & NoLaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y1,'-','color', color1(counter, :));       
        hold on;  
        y2 = [mean(TE.RT(hit20Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit30Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit40Trials & LaserTrials & (TE.sessionIndex == counter))) mean(TE.RT(hit50Trials & LaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y2,'--','color', color1(counter, :));       
        hold on;  
    end
        set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
        xlabel('Norm. SPL NoLaser'); ylabel('RT'); title('RT Mean'); 
        hold off; 
        
        subplot(2,2,4); 
    for counter = 1:nSessions
        x = [20 30 40 50];   
        y1 = [median(TE.RT(hit20Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit30Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit40Trials & NoLaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit50Trials & NoLaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y1,'-','color', color1(counter, :));       
        hold on;  
        y2 = [median(TE.RT(hit20Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit30Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit40Trials & LaserTrials & (TE.sessionIndex == counter))) median(TE.RT(hit50Trials & LaserTrials & (TE.sessionIndex == counter)))];
        plot(x,y2,'--','color', color1(counter, :));       
        hold on;  
    end
        set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1], 'XTick', [20 30 40 50], 'XTickLabel', {'20', '30', '40', '50'});
        xlabel('Norm. SPL NoLaser'); ylabel('RT'); title('RT median'); 
        hold off; 
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end