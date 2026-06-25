%%
sessions = bpLoadSessions;
%%
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
TE.fpLicks = countEventFromTE(TE, 'Port1In', [0 1], TE.PreCsRecording); 

winStart2 = cellfun(@(x) x(1), TE.Cue) - usZeros;
usWindow3 = [winStart2 winzeros];
TE.csLicks = countEventFromTE(TE, 'Port1In', usWindow3, TE.Us); % window for counting CS licks between cue to us
TE.usLicks = countEventFromTE(TE, 'Port1In', [0 1], usZeros); %wider window for counting US licks than photometry US response
TE.RT = calcEventLatency(TE, 'Port1In', TE.Cue, TE.Us); %count reaction time for slow licking after answer window but before US
TE.Answer = cellfun(@(x) x(1), TE.Cue) + TE.RT;
winStart = cellfun(@(x) x(1), TE.Cue) - TE.Answer;
mywin = [winStart winzeros];
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
    disp(['*** Saved: ' fullfile(savepath, 'TE.mat')]);
end

%% exclude trials at end of session where the mouse stops licking
rewardTrialsTrunc = filterTE(TE, 'trialType', [1]);
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
    
    fpLickTrials = TE.fpLicks.count > 0;
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
    LaserTrials = filterTE(TE, 'StimAmp', 5, 'reject', 0) & ~badTrials;
    NoLaserTrials = filterTE(TE, 'StimAmp', 0, 'reject', 0) & ~badTrials;
    LickNoLaser2 = anticipTrials & NoLaserTrials;
    LickNoLaser = filterTE(TE, 'TrialOutcome', 1, 'StimAmp', 0, 'reject', 0) & ~badTrials;
    LickLaser = filterTE(TE, 'TrialOutcome', 1, 'StimAmp', 5, 'reject', 0) & ~badTrials;
    NoLickNoLaser2 = noanticipTrials & NoLaserTrials;
    NoLickNoLaser = filterTE(TE, 'TrialOutcome', -1, 'StimAmp', 0, 'reject', 0) & ~badTrials;
    NoLickLaser = filterTE(TE, 'TrialOutcome', -1, 'StimAmp', 5, 'reject', 0) & ~badTrials;
%     LickLaser30Trials = filterTE(TE, 'TrialOutcome', 1, 'StimFreq', 30, 'reject', 0) & ~badTrials;
    LickLaser30Trials = filterTE(TE, 'TrialOutcome', 1)  & Laser30Trials; 
    LickLaser20Trials = filterTE(TE, 'TrialOutcome', 1, 'StimFreq', 20, 'reject', 0)& ~badTrials;
    LickLaser10Trials = filterTE(TE, 'TrialOutcome', 1, 'StimFreq', 10, 'reject', 0) & ~badTrials;
    LickLaser5Trials = filterTE(TE, 'TrialOutcome', 1, 'StimFreq', 5, 'reject', 0) & ~badTrials;
    LickLaser1Trials = filterTE(TE, 'TrialOutcome', 1, 'StimFreq', 0.5, 'reject', 0) & ~badTrials;
%     NoLickLaser30Trials = filterTE(TE, 'TrialOutcome', -1, 'StimFreq', 30, 'reject', 0) & ~badTrials;
    NoLickLaser30Trials = filterTE(TE, 'TrialOutcome', -1) & Laser30Trials;
    NoLickLaser20Trials = filterTE(TE, 'TrialOutcome', -1, 'StimFreq', 20, 'reject', 0) & ~badTrials;
    NoLickLaser10Trials = filterTE(TE, 'TrialOutcome', -1, 'StimFreq', 10, 'reject', 0) & ~badTrials;
    NoLickLaser5Trials = filterTE(TE, 'TrialOutcome', -1, 'StimFreq', 5, 'reject', 0) & ~badTrials;
    NoLickLaser1Trials = filterTE(TE, 'TrialOutcome', -1, 'StimFreq', 0.5, 'reject', 0) & ~badTrials;
    
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
    
    if ismember(60, TE.SoundAmplitude) 
        t50Trials = filterTE(TE, 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        t40Trials = filterTE(TE, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        t30Trials = filterTE(TE, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        t20Trials = filterTE(TE, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        
        Sound1_50_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        Sound1_40_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Sound1_30_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound1_20_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;

        Sound4_50_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        Sound4_40_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Sound4_30_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound4_20_Trials = filterTE(TE, 'SoundValveIndex', 4, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;

        hit50Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        hit40Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        hit30Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        hit20Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;

        FA50Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        FA40Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        FA30Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        FA20Trials = filterTE(TE, 'SoundValveIndex', 4, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
    
        LickTrials = filterTE(TE, 'LickAction', 'lick', 'reject', 0) & ~badTrials; 
        Lick50Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 60, 'reject', 0) & ~badTrials;
        Lick40Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Lick30Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Lick20Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
    end
    
    % write badTrials into TE   
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
        
    % Save behavior plot
    saveName = [subjectName '_behavior'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  

    subplot(2,2,1); 
    performance_sound1 = length(find(Sound1Lick)) / length(find(Sound1Trials));
    performance_sound4 = length(find(Sound4Lick)) / length(find(Sound4Trials));
    x = [1 4];
    y = [performance_sound1 performance_sound4];
    plot(x,y,'-o', 'color', 'g');   
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Performance'); title('Performance');
    
    subplot(2,2,2);  
    x = [1 4];   
    y = [nanmean(TE.RT(Sound1Lick)) nanmean(TE.RT(Sound4Lick))];
    err = [nanSEM(TE.RT(Sound1Lick)) nanSEM(TE.RT(Sound4Lick))];    
    errorbar(x,y,err,'-s','MarkerSize',10,'MarkerEdgeColor','red','MarkerFaceColor','red');
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('RT'); title('RT Mean');    
    
    subplot(2,2,3);  
    x = [1 4];   
    y = [nanmedian(TE.RT(Sound1Lick)) nanmedian(TE.RT(Sound4Lick))];  
    plot(x,y,'-s','MarkerSize',10, 'color', 'k'); 
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('RT'); title('RT Median');     
   
    subplot (2,2,4);
    xData = TE.RT(Sound1Lick);
    cdfplot (xData); hold on; 
    xData = TE.RT(Sound2Lick);
    cdfplot (xData);
    xData = TE.RT(Sound3Lick);
    cdfplot (xData);
    xData = TE.RT(Sound4Lick);
    cdfplot (xData);
%     legend('Sound1', 'Sound2', 'Sound3', 'Sound4', 'Location','northwest')
    legend('Sound1', 'Sound2', 'Sound3', 'Location','northwest')
    xlabel('Reaction time'); ylabel('Fraction'); title('Hit Trials RT cumulative');
    hold off    
           
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
    
    % Save behavior plot
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
    
    % Save behavior plot
    saveName = [subjectName '_behavior3'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  

    subplot(2,3,1); 
    performance_sound1 = length(find(anticipTrials & Sound1Laser10)) / length(find(Sound1Laser10));
    performance_sound4 = length(find(anticipTrials & Sound4Laser10)) / length(find(Sound4Laser10));
    x = [1 4];
    y = [performance_sound1 performance_sound4];
    plot(x,y,'-o', 'color', [251/255 106/255 74/255]);  hold on;
        
    performance_sound1 = length(find(anticipTrials & Sound1Laser30)) / length(find(Sound1Laser30));
    performance_sound4 = length(find(anticipTrials & Sound4Laser30)) / length(find(Sound4Laser30));
    x = [1 4];
    y = [performance_sound1 performance_sound4];
    plot(x,y,'-o', 'color', [103/255 0/255 13/255]);  
    
    performance2_sound1 = length(find(anticipTrials & Sound1NoLaser)) / length(find(Sound1NoLaser));
    performance2_sound4 = length(find(anticipTrials & Sound4NoLaser)) / length(find(Sound4NoLaser));
    x = [1 4];
    y = [performance2_sound1 performance2_sound4];
    plot(x,y,'-o', 'color', [0/255 128/255 0/255]);      
    set(gca, 'YLim', [0 1]);
    legend({'Laser10', 'Laser30', 'NoLaser'}, 'Location','southwest');
    xlabel('Sound'); ylabel('Performance'); title('Performance');
    
    subplot(2,3,2);  
    y1 = length(find(fpLickNoLaser)) / length(find(filterTE(TE, 'StimAmp', 0, 'reject', 0))); 
    y2 = length(find(fpLickLaser10)) / length(find(filterTE(TE, 'StimFreq', 10, 'reject', 0))); 
    y3 = length(find(fpLickLaser30)) / length(find(filterTE(TE, 'StimFreq', 30) | filterTE(TE, 'StimFreq', 31.25, 'reject', 0))); 
    yData = [y1 y2 y3];
    bar (yData, 'FaceColor',[0/255 128/255 0/255],'EdgeColor',[0/255 128/255 0/255]); hold on;  
    set(gca, 'XTick', [1 2 3], 'XTickLabel', {'NoLaser', 'Laser10', 'Laser30'}, 'YLim', [0 1]); 
    ylabel('Licks(Hz)'); title('fpLicks chance');  
    
    subplot(2,3,3);  
    x = [1 4];   
    y1 = [nanmean(TE.csLicks.rate(Sound1Laser10)) nanmean(TE.csLicks.rate(Sound4Laser10))];
    err = [nanSEM(TE.csLicks.rate(Sound1Laser10)) nanSEM(TE.csLicks.rate(Sound4Laser10))];    
    errorbar(x,y1,err,'-s','color', [251/255 106/255 74/255], 'MarkerSize',10,'MarkerEdgeColor',[251/255 106/255 74/255],'MarkerFaceColor',[251/255 106/255 74/255]); hold on;
    y3 = [nanmean(TE.csLicks.rate(Sound1Laser30)) nanmean(TE.csLicks.rate(Sound4Laser30))];
    err = [nanSEM(TE.csLicks.rate(Sound1Laser30)) nanSEM(TE.csLicks.rate(Sound4Laser30))];    
    errorbar(x,y3,err,'-s','color', [103/255 0/255 13/255], 'MarkerSize',10,'MarkerEdgeColor',[103/255 0/255 13/255],'MarkerFaceColor',[103/255 0/255 13/255]); 
    y2 = [nanmean(TE.csLicks.rate(Sound1NoLaser)) nanmean(TE.csLicks.rate(Sound4NoLaser))];
    err = [nanSEM(TE.csLicks.rate(Sound1NoLaser)) nanSEM(TE.csLicks.rate(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Licks(Hz)'); title('csLicks rate'); 
    
    subplot(2,3,4);  
    x = [1 4];   
    y1 = [nanmean(TE.usLicks.rate(Sound1Laser10)) nanmean(TE.usLicks.rate(Sound4Laser10))];
    err = [nanSEM(TE.usLicks.rate(Sound1Laser10)) nanSEM(TE.usLicks.rate(Sound4Laser10))];    
    errorbar(x,y1,err,'-s','color', [251/255 106/255 74/255], 'MarkerSize',10,'MarkerEdgeColor',[251/255 106/255 74/255],'MarkerFaceColor',[251/255 106/255 74/255]); hold on;
    y3 = [nanmean(TE.usLicks.rate(Sound1Laser30)) nanmean(TE.usLicks.rate(Sound4Laser30))];
    err = [nanSEM(TE.usLicks.rate(Sound1Laser30)) nanSEM(TE.usLicks.rate(Sound4Laser30))];    
    errorbar(x,y3,err,'-s','color', [103/255 0/255 13/255], 'MarkerSize',10,'MarkerEdgeColor',[103/255 0/255 13/255],'MarkerFaceColor',[103/255 0/255 13/255]); 
    y2 = [nanmean(TE.usLicks.rate(Sound1NoLaser)) nanmean(TE.usLicks.rate(Sound4NoLaser))];
    err = [nanSEM(TE.usLicks.rate(Sound1NoLaser)) nanSEM(TE.usLicks.rate(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Licks(Hz)'); title('usLicks rate'); 
    
    subplot(2,3,5);  
    x = [1 4];   
    y1 = [nanmean(TE.RT(Sound1Laser10)) nanmean(TE.RT(Sound4Laser10))];
    err = [nanSEM(TE.RT(Sound1Laser10)) nanSEM(TE.RT(Sound4Laser10))];    
    errorbar(x,y1,err,'-s','color', [251/255 106/255 74/255], 'MarkerSize',10,'MarkerEdgeColor',[251/255 106/255 74/255],'MarkerFaceColor',[251/255 106/255 74/255]); hold on;
    y3 = [nanmean(TE.RT(Sound1Laser30)) nanmean(TE.RT(Sound4Laser30))];
    err = [nanSEM(TE.RT(Sound1Laser30)) nanSEM(TE.RT(Sound4Laser30))];    
    errorbar(x,y3,err,'-s','color', [103/255 0/255 13/255], 'MarkerSize',10,'MarkerEdgeColor',[103/255 0/255 13/255],'MarkerFaceColor',[103/255 0/255 13/255]); 
    y2 = [nanmean(TE.RT(Sound1NoLaser)) nanmean(TE.RT(Sound4NoLaser))];
    err = [nanSEM(TE.RT(Sound1NoLaser)) nanSEM(TE.RT(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('RT'); title('RT Mean');    
    
    subplot(2,3,6);  
    x = [1 4];   
    y1 = [nanmedian(TE.RT(Sound1Laser10)) nanmedian(TE.RT(Sound4Laser10))];  
    plot(x,y1,'-s','color', [251/255 106/255 74/255], 'MarkerSize',10, 'color', [251/255 106/255 74/255]); hold on;
    y3 = [nanmedian(TE.RT(Sound1Laser30)) nanmedian(TE.RT(Sound4Laser30))];  
    plot(x,y3,'-s','color', [103/255 0/255 13/255], 'MarkerSize',10, 'color', [103/255 0/255 13/255]); 
    y2 = [nanmedian(TE.RT(Sound1NoLaser)) nanmedian(TE.RT(Sound4NoLaser))];  
    plot(x,y2,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10, 'color', [0/255 128/255 0/255]); 
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('RT'); title('RT Median');         
           
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end  

% sated trials
    satedTrials = filterTE(TE, 'reject', 1);
    satedSound1 = filterTE(TE, 'SoundValveIndex', 1, 'reject', 1) & ~badTrials;
    satedSound4 = filterTE(TE, 'SoundValveIndex', 4, 'reject', 1) & ~badTrials;
    satedLaser30 = (filterTE(TE, 'StimFreq', 30) | filterTE(TE, 'StimFreq', 31.25, 'reject', 1)) & ~badTrials;  
    satedLaser20 = filterTE(TE, 'StimFreq', 20, 'reject', 1) & ~badTrials;
    satedLaser10 = filterTE(TE, 'StimFreq', 10, 'reject', 1) & ~badTrials;
    satedLaser5 = filterTE(TE, 'StimFreq', 5, 'reject', 1) & ~badTrials;
    satedLaser1 = filterTE(TE, 'StimFreq', 0.5, 'reject', 1) & ~badTrials;
    satedLaser = filterTE(TE, 'StimAmp', 5, 'reject', 1) & ~badTrials;
    satedNoLaser = filterTE(TE, 'StimAmp', 0, 'reject', 1) & ~badTrials;
% plot
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

%% lick and photometry rasters aligned to cue
clim1 = [-8 8];
clim2 = [-6 6];
% clim1 = [-0.06 0.06];
% clim2 = [-0.06 0.06];
clims = [clim1; clim2];
    saveName = [subjectName '_cue response'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
%     clim = clims(channel,:);
        
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
    
% lick and photometry rasters aligned to cue
% clim1 = [-6 6];
% clim2 = [-6 6];
% clims = [clim1; clim2];
% clim = [];

    saveName = [subjectName '_cue response3'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
%     clim = clims(channel,:);
     
    subplot(5,4,1); % lick raster for hit
    eventRasterFromTE(TE, Sound1NoLaser, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1NoLaser'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,2); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound1NoLaser, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    set(gca, 'XLim', [-3 5]);
    
    subplot(5,4,3); % lick raster for miss
    eventRasterFromTE(TE, Sound1Laser, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1Laser'); ylabel('trial number'); 
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,4); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound1Laser, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    set(gca, 'XLim', [-3 5]);
    
     subplot(5,4,5); % lick raster for hit
    eventRasterFromTE(TE, Sound2NoLaser, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound2NoLaser'); ylabel('trial number'); xlabel('time from Cue (s)');
   set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,6); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound2NoLaser, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    set(gca, 'XLim', [-3 5]);
    
    subplot(5,4,7); % lick raster for miss
    eventRasterFromTE(TE, Sound2Laser, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound2Laser'); ylabel('trial number'); 
    set(gca, 'XLim', [-3 5]);set(gca, 'FontSize', 14); 
    
    subplot(5,4,8); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound2Laser, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)');  
    set(gca, 'XLim', [-3 5]); 
    
    subplot(5,4,9); % lick raster for FA
    eventRasterFromTE(TE, Sound3NoLaser, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound3NoLaser'); ylabel('trial number'); 
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14);
    
    subplot(5,4,10); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound3NoLaser, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    set(gca, 'XLim', [-3 5]);
    
    subplot(5,4,11); % lick raster for CR
    eventRasterFromTE(TE, Sound3Laser, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound3Laser'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14);
    
    subplot(5,4,12); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound3Laser, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)');   
    set(gca, 'XLim', [-3 5]); 
    
     subplot(5,4,13); % lick raster for hit
    eventRasterFromTE(TE, Sound4NoLaser, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4NoLaser'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,14); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound4NoLaser, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    set(gca, 'XLim', [-3 5]);
    
    subplot(5,4,15); % lick raster for miss
    eventRasterFromTE(TE, Sound4Laser, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound4Laser'); ylabel('trial number'); 
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(5,4,16); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound4Laser, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    set(gca, 'XLim', [-3 5]);
    
    subplot(5,4,17); % lick raster for uncuedReward
    eventRasterFromTE(TE, uncuedReward, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('uncuedReward'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14);
    
    subplot(5,4,18); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, uncuedReward, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(5,4,19); % lick raster for uncuedPunish
    eventRasterFromTE(TE, uncuedPunish, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('uncuedPunish'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14);
    
    subplot(5,4,20); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, uncuedPunish, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)');   
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end

%
    saveName = [subjectName '_lick_raster'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    varargin = {'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording'};
    subplot(5,2,1); % lick raster for Sound1
    eventRasterFromTE(TE, NoLaserTrials, 'Port1In', varargin{:});
    title('NoLaserTrials'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(5,2,2); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

    subplot(5,2,3); % lick raster for Sound1
    eventRasterFromTE(TE, Laser1Trials, 'Port1In', varargin{:});
    title('Laser1Trials'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(5,2,4); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Laser1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

    subplot(5,2,5); % lick raster for Sound1
    eventRasterFromTE(TE, Laser10Trials, 'Port1In', varargin{:});
    title('Laser10Trials'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(5,2,6); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Laser10Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

    subplot(5,2,7); % lick raster for Sound1
    eventRasterFromTE(TE, Laser20Trials, 'Port1In', varargin{:});
    title('Laser20Trials'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(5,2,8); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Laser20Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

    subplot(5,2,9); % lick raster for Sound1
    eventRasterFromTE(TE, Laser30Trials, 'Port1In', varargin{:});
    title('Laser30Trials'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(5,2,10); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Laser30Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-3 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

if saveOn
    saveas(gcf, fullfile(savepath, [saveName '.fig']));
    saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
    print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
end    
 %% Averages aligned to Laser
    saveName = [subjectName '_Laser response_Avg'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
 
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('re4'); mycolors_SL2('re3'); mycolors_SL2('re2'); mycolors_SL2('re1')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'window', [-3, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(3, 1, 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {NoLaserTrials, Laser1Trials, Laser10Trials, Laser20Trials, Laser30Trials}, 'Port1In', varargin{:});
    legend(hl, {'NoLaserTrials', 'Laser1Trials', 'Laser10Trials', 'Laser20Trials', 'Laser30Trials'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
        
    subplot(3, 1, 2); 
    [ha, hl] = plotEventAverageFromTE(TE, {LickNoLaser, LickLaser1Trials, LickLaser10Trials, LickLaser20Trials, LickLaser30Trials}, 'Port1In', varargin{:});
    legend(hl, {'LickNoLaser', 'LickLaser1Trials', 'LickLaser10Trials', 'LickLaser20Trials', 'LickLaser30Trials'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
    
    subplot(3, 1, 3); 
    [ha, hl] = plotEventAverageFromTE(TE, {NoLickNoLaser, NoLickLaser1Trials, NoLickLaser10Trials, NoLickLaser20Trials, NoLickLaser30Trials}, 'Port1In', varargin{:});
    legend(hl, {'NoLickNoLaser', 'NoLickLaser1Trials', 'NoLickLaser10Trials', 'NoLickLaser20Trials', 'NoLickLaser30Trials'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
 
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end     
     % Averages aligned to Laser
    saveName = [subjectName '_Laser response_Avg2'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
 
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('re4'); mycolors_SL2('re3'); mycolors_SL2('re2'); mycolors_SL2('re1')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'window', [-3, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(4, 1, 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1NoLaser, Sound1Laser1, Sound1Laser10, Sound1Laser20, Sound1Laser30}, 'Port1In', varargin{:});
    legend(hl, {'Sound1NoLaser', 'Sound1Laser1', 'Sound1Laser10', 'Sound1Laser20', 'Sound1Laser30'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
        
    subplot(4, 1, 2); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound2NoLaser, Sound2Laser1, Sound2Laser10, Sound2Laser20, Sound2Laser30}, 'Port1In', varargin{:});
    legend(hl, {'Sound2NoLaser', 'Sound2Laser1', 'Sound2Laser10', 'Sound2Laser20', 'Sound2Laser30'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
    
    subplot(4, 1, 3); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound3NoLaser, Sound3Laser1, Sound3Laser10, Sound3Laser20, Sound3Laser30}, 'Port1In', varargin{:});
    legend(hl, {'Sound3NoLaser', 'Sound3Laser1', 'Sound3Laser10', 'Sound3Laser20', 'Sound3Laser30'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
    
    subplot(4, 1, 4); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound4NoLaser, Sound4Laser1, Sound4Laser10, Sound4Laser20, Sound4Laser30}, 'Port1In', varargin{:});
    legend(hl, {'Sound4NoLaser', 'Sound4Laser1', 'Sound4Laser10', 'Sound4Laser20', 'Sound4Laser30'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
 
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end     
%% Averages aligned to Laser
    saveName = [subjectName '_lick_raster2'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    
    varargin = {'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording'};

    linecolors = [mycolors_SL2('neutral'); mycolors_SL2('uncuedReward'); mycolors_SL2('re3'); mycolors_SL2('re2'); mycolors_SL2('re1')];
    varargin2 = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'window', [-3, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    
    subplot(4,3,1); % lick raster for Sound1
    eventRasterFromTE(TE, Sound1NoLaser, 'Port1In', varargin{:});
    title('Sound1NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(4,3,2); % lick raster for Sound1
    eventRasterFromTE(TE, Sound1Laser, 'Port1In', varargin{:});
    title('Sound1Laser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,3,3); % lick average for Sound1
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1NoLaser, Sound1Laser}, 'Port1In', varargin2{:});
    legend(hl, {'Sound1NoLaser', 'Sound1Laser'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
        
    subplot(4,3,4); % lick raster for Sound1
    eventRasterFromTE(TE, Sound2NoLaser, 'Port1In', varargin{:});
    title('Sound2NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
        
    subplot(4,3,5); % lick raster for Sound1
    eventRasterFromTE(TE, Sound2Laser, 'Port1In', varargin{:});
    title('Sound2Laser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,3,6); % lick average for Sound1
    [ha, hl] = plotEventAverageFromTE(TE, {Sound2NoLaser, Sound2Laser}, 'Port1In', varargin2{:});
    legend(hl, {'Sound2NoLaser', 'Sound2Laser'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
    
    subplot(4,3,7); % lick raster for Sound1
    eventRasterFromTE(TE, Sound3NoLaser, 'Port1In', varargin{:});
    title('Sound3NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
        
    subplot(4,3,8); % lick raster for Sound1
    eventRasterFromTE(TE, Sound3Laser, 'Port1In', varargin{:});
    title('Sound3Laser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,3,9); % lick average for Sound1
    [ha, hl] = plotEventAverageFromTE(TE, {Sound3NoLaser, Sound3Laser}, 'Port1In', varargin2{:});
    legend(hl, {'Sound3NoLaser', 'Sound3Laser'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
        
    subplot(4,3,10); % lick raster for Sound1
    eventRasterFromTE(TE, Sound4NoLaser, 'Port1In', varargin{:});
    title('Sound4NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
        
    subplot(4,3,11); % lick raster for Sound1
    eventRasterFromTE(TE, Sound4Laser, 'Port1In', varargin{:});
    title('Sound4Laser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,3,12); % lick average for Sound1
    [ha, hl] = plotEventAverageFromTE(TE, {Sound4NoLaser, Sound4Laser}, 'Port1In', varargin2{:});
    legend(hl, {'Sound4NoLaser', 'Sound4Laser'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)'); 
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
  
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end     
    
    %% Averages aligned to Laser
    saveName = [subjectName '_lick_raster4'];
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
    
    subplot(4,4,3); % lick raster for Sound1Laser30
    eventRasterFromTE(TE, Sound1Laser30, 'Port1In', varargin{:});
    title('Sound1Laser30'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,4,4); % lick average for Sound1
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1NoLaser, Sound1Laser10, Sound1Laser30}, 'Port1In', varargin2{:});
    legend(hl, {'Sound1NoLaser', 'Sound1Laser10', 'Sound1Laser30'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
  
    subplot(4,4,5); % lick raster for Sound2NoLaser
    eventRasterFromTE(TE, Sound2NoLaser, 'Port1In', varargin{:});
    title('Sound2NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(4,4,6); % lick raster for Sound2Laser10
    eventRasterFromTE(TE, Sound2Laser10, 'Port1In', varargin{:});
    title('Sound2Laser10'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,7); % lick raster for Sound2Laser30
    eventRasterFromTE(TE, Sound2Laser30, 'Port1In', varargin{:});
    title('Sound2Laser30'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,4,8); % lick average for Sound2
    [ha, hl] = plotEventAverageFromTE(TE, {Sound2NoLaser, Sound2Laser10, Sound2Laser30}, 'Port1In', varargin2{:});
    legend(hl, {'Sound2NoLaser', 'Sound2Laser10', 'Sound2Laser30'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);     
     
    subplot(4,4,9); % lick raster for Sound3NoLaser
    eventRasterFromTE(TE, Sound3NoLaser, 'Port1In', varargin{:});
    title('Sound3NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(4,4,10); % lick raster for Sound3Laser10
    eventRasterFromTE(TE, Sound3Laser10, 'Port1In', varargin{:});
    title('Sound3Laser10'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,11); % lick raster for Sound3Laser30
    eventRasterFromTE(TE, Sound3Laser30, 'Port1In', varargin{:});
    title('Sound3Laser30'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,4,12); % lick average for Sound3
    [ha, hl] = plotEventAverageFromTE(TE, {Sound3NoLaser, Sound3Laser10, Sound3Laser30}, 'Port1In', varargin2{:});
    legend(hl, {'Sound3NoLaser', 'Sound3Laser10', 'Sound3Laser30'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
     
    subplot(4,4,13); % lick raster for Sound4NoLaser
    eventRasterFromTE(TE, Sound4NoLaser, 'Port1In', varargin{:});
    title('Sound4NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(4,4,14); % lick raster for Sound4Laser10
    eventRasterFromTE(TE, Sound4Laser10, 'Port1In', varargin{:});
    title('Sound4Laser10'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,15); % lick raster for Sound4Laser30
    eventRasterFromTE(TE, Sound4Laser30, 'Port1In', varargin{:});
    title('Sound4Laser30'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,4,16); % lick average for Sound4
    [ha, hl] = plotEventAverageFromTE(TE, {Sound4NoLaser, Sound4Laser10, Sound4Laser30}, 'Port1In', varargin2{:});
    legend(hl, {'Sound4NoLaser', 'Sound4Laser10', 'Sound4Laser30'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); 
  
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end    
    
% Averages aligned to Cue
    saveName = [subjectName '_Cue response_Avgs'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [3 1]; 
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('sound3'); mycolors_SL2('FA'); mycolors_SL2('uncuedReward')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2,  'window', [-4, 6], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1Trials, Sound2Trials, Sound3Trials, Sound4Trials, uncuedReward}, 'Port1In', varargin{:});
    legend(hl, {'Sound1', 'Sound2', 'Sound3','Sound4', 'uncuedReward'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');     
    
%     subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
%     [ha, hl] = phPlotAverageFromTE(TE, {Sound1Trials, Sound2Trials, Sound3Trials, Sound4Trials, uncuedReward}, 1, varargin{:});
% %     legend(hl, {'Sound1', 'Sound2', 'Sound3', 'Sound4', 'uncuedReward'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
%     title('Ch1'); ylabel('Ch1');
%                         
%     if ismember(2, channels)
%         subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
%         [ha, hl] = phPlotAverageFromTE(TE, {Sound1Trials, Sound2Trials, Sound3Trials, Sound4Trials, uncuedReward}, 2, varargin{:});
% %         legend(hl, {'Sound1', 'Sound2', 'Sound3','Sound4', 'uncuedReward'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
%         title('Ch2'); ylabel('Ch2');               
%     end  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end  
%% 10hz vs 20hz
% Save behavior plot
    saveName = [subjectName '_behavior4'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  

    subplot(2,3,1); 
    performance_sound1 = length(find(anticipTrials & Sound1Laser10)) / length(find(Sound1Laser10));
    performance_sound4 = length(find(anticipTrials & Sound4Laser10)) / length(find(Sound4Laser10));
    x = [1 4];
    y = [performance_sound1 performance_sound4];
    plot(x,y,'-o', 'color', [251/255 106/255 74/255]);  hold on;
        
    performance_sound1 = length(find(anticipTrials & Sound1Laser20)) / length(find(Sound1Laser20));
    performance_sound4 = length(find(anticipTrials & Sound4Laser20)) / length(find(Sound4Laser20));
    x = [1 4];
    y = [performance_sound1 performance_sound4];
    plot(x,y,'-o', 'color', [103/255 0/255 13/255]);  
    
    performance2_sound1 = length(find(anticipTrials & Sound1NoLaser)) / length(find(Sound1NoLaser));
    performance2_sound4 = length(find(anticipTrials & Sound4NoLaser)) / length(find(Sound4NoLaser));
    x = [1 4];
    y = [performance2_sound1 performance2_sound4];
    plot(x,y,'-o', 'color', [0/255 128/255 0/255]);      
    set(gca, 'YLim', [0 1]);
    legend({'Laser10', 'Laser20', 'NoLaser'}, 'Location','southwest');
    xlabel('Sound'); ylabel('Performance'); title('Performance');
      
    subplot(2,3,2);  
    y1 = length(find(fpLickNoLaser)) / length(find(filterTE(TE, 'StimAmp', 0, 'reject', 0))); 
    y2 = length(find(fpLickLaser10)) / length(find(filterTE(TE, 'StimFreq', 10, 'reject', 0))); 
    y3 = length(find(fpLickLaser20)) / length(find(filterTE(TE, 'StimFreq', 20, 'reject', 0))); 
    yData = [y1 y2 y3];
    bar (yData, 'FaceColor',[0/255 128/255 0/255],'EdgeColor',[0/255 128/255 0/255]); hold on;  
    set(gca, 'XTick', [1 2 3], 'XTickLabel', {'NoLaser', 'Laser10', 'Laser20'}, 'YLim', [0 1]); 
    ylabel('Licks(Hz)'); title('fpLicks chance'); 
    
    subplot(2,3,3);  
    x = [1 4];   
    y1 = [nanmean(TE.csLicks.rate(Sound1Laser10)) nanmean(TE.csLicks.rate(Sound4Laser10))];
    err = [nanSEM(TE.csLicks.rate(Sound1Laser10)) nanSEM(TE.csLicks.rate(Sound4Laser10))];    
    errorbar(x,y1,err,'-s','color', [251/255 106/255 74/255], 'MarkerSize',10,'MarkerEdgeColor',[251/255 106/255 74/255],'MarkerFaceColor',[251/255 106/255 74/255]); hold on;
    y3 = [nanmean(TE.csLicks.rate(Sound1Laser20)) nanmean(TE.csLicks.rate(Sound4Laser20))];
    err = [nanSEM(TE.csLicks.rate(Sound1Laser20)) nanSEM(TE.csLicks.rate(Sound4Laser20))];    
    errorbar(x,y3,err,'-s','color', [103/255 0/255 13/255], 'MarkerSize',10,'MarkerEdgeColor',[103/255 0/255 13/255],'MarkerFaceColor',[103/255 0/255 13/255]); 
    y2 = [nanmean(TE.csLicks.rate(Sound1NoLaser)) nanmean(TE.csLicks.rate(Sound4NoLaser))];
    err = [nanSEM(TE.csLicks.rate(Sound1NoLaser)) nanSEM(TE.csLicks.rate(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Licks(Hz)'); title('csLicks rate'); 
    
    subplot(2,3,4);  
    x = [1 4];   
    y1 = [nanmean(TE.usLicks.rate(Sound1Laser10)) nanmean(TE.usLicks.rate(Sound4Laser10))];
    err = [nanSEM(TE.usLicks.rate(Sound1Laser10)) nanSEM(TE.usLicks.rate(Sound4Laser10))];    
    errorbar(x,y1,err,'-s','color', [251/255 106/255 74/255], 'MarkerSize',10,'MarkerEdgeColor',[251/255 106/255 74/255],'MarkerFaceColor',[251/255 106/255 74/255]); hold on;
    y3 = [nanmean(TE.usLicks.rate(Sound1Laser20)) nanmean(TE.usLicks.rate(Sound4Laser20))];
    err = [nanSEM(TE.usLicks.rate(Sound1Laser20)) nanSEM(TE.usLicks.rate(Sound4Laser20))];    
    errorbar(x,y3,err,'-s','color', [103/255 0/255 13/255], 'MarkerSize',10,'MarkerEdgeColor',[103/255 0/255 13/255],'MarkerFaceColor',[103/255 0/255 13/255]); 
    y2 = [nanmean(TE.usLicks.rate(Sound1NoLaser)) nanmean(TE.usLicks.rate(Sound4NoLaser))];
    err = [nanSEM(TE.usLicks.rate(Sound1NoLaser)) nanSEM(TE.usLicks.rate(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
%     set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Licks(Hz)'); title('usLicks rate'); 
    
    subplot(2,3,5);  
    x = [1 4];   
    y1 = [nanmean(TE.RT(Sound1Laser10)) nanmean(TE.RT(Sound4Laser10))];
    err = [nanSEM(TE.RT(Sound1Laser10)) nanSEM(TE.RT(Sound4Laser10))];    
    errorbar(x,y1,err,'-s','color', [251/255 106/255 74/255], 'MarkerSize',10,'MarkerEdgeColor',[251/255 106/255 74/255],'MarkerFaceColor',[251/255 106/255 74/255]); hold on;
    y3 = [nanmean(TE.RT(Sound1Laser20)) nanmean(TE.RT(Sound4Laser20))];
    err = [nanSEM(TE.RT(Sound1Laser20)) nanSEM(TE.RT(Sound4Laser20))];    
    errorbar(x,y3,err,'-s','color', [103/255 0/255 13/255], 'MarkerSize',10,'MarkerEdgeColor',[103/255 0/255 13/255],'MarkerFaceColor',[103/255 0/255 13/255]); 
    y2 = [nanmean(TE.RT(Sound1NoLaser)) nanmean(TE.RT(Sound4NoLaser))];
    err = [nanSEM(TE.RT(Sound1NoLaser)) nanSEM(TE.RT(Sound4NoLaser))];    
    errorbar(x,y2,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    set(gca, 'YLim', [0 1.5]);
    xlabel('Sound'); ylabel('RT'); title('RT Mean');    
    
    subplot(2,3,6);  
    x = [1 4];   
    y1 = [nanmedian(TE.RT(Sound1Laser10)) nanmedian(TE.RT(Sound4Laser10))];  
    plot(x,y1,'-s','color', [251/255 106/255 74/255], 'MarkerSize',10, 'color', [251/255 106/255 74/255]); hold on;
    y3 = [nanmedian(TE.RT(Sound1Laser20)) nanmedian(TE.RT(Sound4Laser20))];  
    plot(x,y3,'-s','color', [103/255 0/255 13/255], 'MarkerSize',10, 'color', [103/255 0/255 13/255]); 
    y2 = [nanmedian(TE.RT(Sound1NoLaser)) nanmedian(TE.RT(Sound4NoLaser))];  
    plot(x,y2,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10, 'color', [0/255 128/255 0/255]); 
    set(gca, 'YLim', [0 1.5]);
    xlabel('Sound'); ylabel('RT'); title('RT Median');         
           
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
    
    % Averages aligned to Laser
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
  
    subplot(4,4,5); % lick raster for Sound2NoLaser
    eventRasterFromTE(TE, Sound2NoLaser, 'Port1In', varargin{:});
    title('Sound2NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(4,4,6); % lick raster for Sound2Laser10
    eventRasterFromTE(TE, Sound2Laser10, 'Port1In', varargin{:});
    title('Sound2Laser10'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,7); % lick raster for Sound2Laser20
    eventRasterFromTE(TE, Sound2Laser20, 'Port1In', varargin{:});
    title('Sound2Laser20'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,4,8); % lick average for Sound2
    [ha, hl] = plotEventAverageFromTE(TE, {Sound2NoLaser, Sound2Laser10, Sound2Laser20}, 'Port1In', varargin2{:});
    legend(hl, {'Sound2NoLaser', 'Sound2Laser10', 'Sound2Laser20'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);     
     
    subplot(4,4,9); % lick raster for Sound3NoLaser
    eventRasterFromTE(TE, Sound3NoLaser, 'Port1In', varargin{:});
    title('Sound3NoLaser'); ylabel('trial number');
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]); set(gca, 'FontSize', 14); 
        
    subplot(4,4,10); % lick raster for Sound3Laser10
    eventRasterFromTE(TE, Sound3Laser10, 'Port1In', varargin{:});
    title('Sound3Laser10'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,11); % lick raster for Sound3Laser20
    eventRasterFromTE(TE, Sound3Laser20, 'Port1In', varargin{:});
    title('Sound3Laser20'); ylabel('trial number');
    set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

    subplot(4,4,12); % lick average for Sound3
    [ha, hl] = plotEventAverageFromTE(TE, {Sound3NoLaser, Sound3Laser10, Sound3Laser20}, 'Port1In', varargin2{:});
    legend(hl, {'Sound3NoLaser', 'Sound3Laser10', 'Sound3Laser20'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    ylabel('licks (s)'); xlabel('time from Cue (s)');  
    set(gca, 'XLim', [-3 5], 'XTick', [-2 0 2 4]);
     
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
    set(gca, 'YLim', [-0.5 0.5], 'YTick', [-0.4 -0.2 0 0.2 0.4]);
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
    set(gca, 'YLim', [-0.5 0.5], 'YTick', [-0.4 -0.2 0 0.2 0.4]);
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
    set(gca, 'YLim', [-0.5 0.5], 'YTick', [-0.4 -0.2 0 0.2 0.4]);
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
    
