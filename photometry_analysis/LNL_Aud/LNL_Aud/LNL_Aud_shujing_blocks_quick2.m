%%
saveOn = 1; 
%
sessions = bpLoadSessions;
%%
TE = makeTE_LNL_Aud(sessions);

%% save data in a base directory, code below creates a folder named according to subject (e.g. DAT_1) and sets the save path within
basepath = uigetdir;
sep = strfind(TE.filename{1}, '_');
subjectName = TE.filename{1}(1:sep(2)-1);
disp(subjectName);
savepath = fullfile(basepath, subjectName);
ensureDirectory(savepath);

%%
% assume that photometry channels are consistent across sessions
channels=[]; dFFMode = {}; BL = {};
if sessions(1).SessionData.Settings.GUI.LED1_amp > 0
    channels(end+1) = 1;
% 'expFit' subtracts biexponential fit to initial bleaching transient within
% trials (flattens this artifact), also try 'simple'
    dFFMode{end+1} = 'simple'; 
    BL{end + 1} = [0.2 4]; % window start from preCSRecroding
end

if sessions(1).SessionData.Settings.GUI.LED2_amp > 0
    channels(end+1) = 2;
    dFFMode{end+1} = 'simple';
    BL{end + 1} = [0.2 4];   
end
  
TE.Photometry = processTrialAnalysis_Photometry4(sessions, 'dFFMode', dFFMode, 'blMode', 'byTrial', 'zeroField', 'Cue', 'channels', channels, 'baseline', BL); 

%% extract peak trial dFF responses to cues and reinforcement and lick counts
% zero is defined as time of cue- see call to
% processTrialAnalysis_Photometry2
saveOn = 1; 
channels = TE.Photometry.settings.channels;
nSessions = max(TE.sessionIndex);
nTrials = length(TE.filename);
TE.RT = cellfun(@(x,y) y(1) - x(1), TE.Cue, TE.AnswerLick);
AnswerZeros = cellfun(@(x,y) max([x(1) y(1)]), TE.AnswerLick, TE.AnswerNoLick);
usZeros = cellfun(@(x,y,z) max([x(1) y(1) z(1)]), TE.Reward, TE.Punish, TE.Neutral); %'Reward', 'Punish', 'Neutral'
TE.Us = usZeros;
winzeros = TE.Us - usZeros;
usWindow1 = [0 1];
usWindow2 = [-0.5 0];
baselineWindow = [-1 0];
csWindow0 = [-0.5 0];
winStart = cellfun(@(x) x(1), TE.Cue) - AnswerZeros;
mywin = [winStart winzeros];
TE.fpWindow = cellfun(@(x) x(1) - x(end), TE.foreperiod);
mywin2 = [TE.fpWindow winzeros];
TE.fpLicks = countEventFromTE(TE, 'Port1In', mywin2, TE.Cue);

% line below extracts time when the us occurs (accounting for the various
% outcome state possibilities)
% Us = TE.ReinforcementOutcome;
winStart2 = cellfun(@(x) x(1), TE.Cue) - usZeros;
usWindow3 = [winStart2 winzeros]; % from Cue to Us
TE.usWindow3 = usWindow3(:, 1);
TE.csLicks = countEventFromTE(TE, 'Port1In', usWindow3, usZeros); % window for counting CS licks between cue to us
TE.usLicks = countEventFromTE(TE, 'Port1In', [0 2], usZeros); %wider window for counting US licks than photometry US response
TE.RT2 = calcEventLatency(TE, 'Port1In', TE.Cue, TE.Us); %count reaction time for slow licking after answer window but before US
TE.Answer = cellfun(@(x) x(1), TE.Cue) + TE.RT2; %count answerlicking for slow licking after answer window but before US
for counter = 1:nTrials
    if ~isnan(TE.RT2(counter))
        winEnd(counter) = TE.RT2(counter); % CS window ends at first answerlick or US which comes first 
    else 
        winEnd(counter) = -winStart2(counter);  % CS window ends at first answerlick or US which comes first       
    end
end
csWindow2 = [winzeros winEnd']; % CS window ends at first answerlick or US which comes first
csWindow1 = [0 nanmean(TE.RT2)]; % CS window equal to average RT for NoLick trials
% phField = 'ddFZS';
% fluorField = 'ddFZS'; 
% phField = 'dFF';
% fluorField = 'dFF'; 
phField = 'ZS';
fluorField = 'ZS'; 
%%
for channel = TE.Photometry.settings.channels
    TE.phPeakMean_baseline(channel) = bpCalcPeak_dFF(TE.Photometry, channel, BL{channel}, [], 'method', 'mean', 'phField', phField);
    TE.phPeakMean_usWindow1(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow1, usZeros, 'method', 'mean', 'phField', phField); % US window[0 1] from TE.Us;
    TE.phPeakMean_usWindow2(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow2, usZeros, 'method', 'mean', 'phField', phField); % US window[-0.4 0] from TE.Us;
    TE.phPeakMean_usWindow3(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow3, usZeros, 'method', 'mean', 'phField', phField); % US window from TE.cue to TE.Us
    TE.phPeakMean_fpWindow(channel) = bpCalcPeak_dFF(TE.Photometry, channel, mywin2, TE.Cue, 'method', 'mean', 'phField', phField); % foreperiod window from TE.Cue
    TE.phPeakMean_csWindow0(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow0, TE.Cue, 'method', 'mean', 'phField', phField); % CS window[-0.5 0] from TE.Cue;
    TE.phPeakMean_csWindow1(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow1, TE.Cue, 'method', 'mean', 'phField', phField); % CS window[0  average RT] from TE.Cue;
    TE.phPeakMean_csWindow2(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow2, TE.Answer, 'method', 'mean', 'phField', phField); % CS window from TE.Cue to first answerlick or US which comes first
    TE.phPeakMean_csWindow3(channel) = bpCalcPeak_dFF(TE.Photometry, channel, mywin, TE.Answer, 'method', 'mean', 'phField', phField); % CS window from TE.Cue to first lick
    TE.phPeakPercentile_fpWindow(channel) = bpCalcPeak_dFF(TE.Photometry, channel, mywin2, TE.Cue, 'method', 'percentile', 'percentile', 0.9, 'phField', phField);
    TE.phPeakPercentile_csWindow0(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow0, TE.Cue, 'method', 'percentile', 'percentile', 0.9, 'phField', phField);
    TE.phPeakPercentile_csWindow1(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow1, TE.Cue, 'method', 'percentile', 'percentile', 0.9, 'phField', phField);
    TE.phPeakPercentile_csWindow2(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow2, TE.Answer, 'method', 'percentile', 'percentile', 0.9, 'phField', phField);
    TE.phPeakPercentile_csWindow3(channel) = bpCalcPeak_dFF(TE.Photometry, channel, mywin, TE.Answer, 'method', 'percentile', 'percentile', 0.9, 'phField', phField);
    TE.phPeakPercentile_usWindow1(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow1, usZeros, 'method', 'percentile', 'percentile', 0.9, 'phField', phField);
    TE.phPeakPercentile_usWindow2(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow2, usZeros, 'method', 'percentile', 'percentile', 0.9, 'phField', phField);
    TE.phPeakPercentile_usWindow3(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow3, usZeros, 'method', 'percentile', 'percentile', 0.9, 'phField', phField);
end

if saveOn
    save(fullfile(savepath, 'TE.mat'), 'TE');
    disp(['*** Saved: ' fullfile(savepath, 'TE.mat')]);
end
%% cross sessions bleaching curve and dual exponential fits
for channel = TE.Photometry.settings.channels
    figname = ['sessionBleach_Correction_ch' num2str(channel)];
    ensureFigure(figname, 1);
    plot(TE.Photometry.data(channel).blF_raw, 'k'); hold on;
    plot(TE.Photometry.data(channel).blF, 'r');
    if saveOn
        saveas(gcf, fullfile(savepath, [figname '.fig']));
        saveas(gcf, fullfile(savepath, [figname '.jpg']));
    end
    % cross trial bleaching fits for each session plotted as axis array
    try
        figname = ['trialBleach_Correction_ch' num2str(channel)];
        ensureFigure(figname, 1);
        nSessions = length(TE.Photometry.bleachFit);
        subA = ceil(sqrt(nSessions));
        for counter = 1:nSessions
            subplot(subA, subA, counter);
            plot(TE.Photometry.bleachFit(counter, channel).trialTemplate, 'k'); hold on;
            plot(TE.Photometry.bleachFit(counter, channel).trialFit, 'r');
            title(num2str(counter));   
            textBox(['r2 = ' num2str(TE.Photometry.bleachFit(counter, channel).gof_trial.rsquare)],[], [0.5 1], 9);
        end
    catch
    end
    if saveOn
        saveas(gcf, fullfile(savepath, [figname '.fig']));
        saveas(gcf, fullfile(savepath, [figname '.jpg']));
    end
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
    badTrials1 = isnan(cellfun(@(x) x(1), TE.Cue));
    badTrials = badTrials1;     

    allTrials = filterTE(TE, 'reject', 0) & ~badTrials;
    
    Sound1Trials = filterTE(TE, 'SoundValveIndex', 1, 'reject', 0) & ~badTrials;
    Sound2Trials = filterTE(TE, 'SoundValveIndex', 2, 'reject', 0) & ~badTrials; 
    Sound3Trials = filterTE(TE, 'SoundValveIndex', 3, 'reject', 0) & ~badTrials;
    Sound4Trials = filterTE(TE, 'SoundValveIndex', 4, 'reject', 0) & ~badTrials;
    uncuedTrials = filterTE(TE, 'SoundValveIndex', 0, 'reject', 0) & ~badTrials;

    rewardTrials = (cellfun (@(x) x(1), TE.Reward) > 0) & ~badTrials;
    punishTrials = (cellfun (@(x) x(1), TE.Punish) > 0) & ~badTrials;
    neutralTrials = (cellfun (@(x) x(1), TE.Neutral) > 0) & ~badTrials;
    uncuedReward = uncuedTrials & rewardTrials;
    uncuedPunish = uncuedTrials & punishTrials; 

    hitTrials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'reject', 0) & ~badTrials;
    missTrials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'nolick', 'reject', 0) & ~badTrials;
    FATrials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'reject', 0) & ~badTrials;
    CRTrials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'nolick', 'reject', 0) & ~badTrials;        

    if ismember(50, TE.SoundAmplitude)
        Sound1_50_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Sound1_40_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound1_30_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound1_20_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;

        Sound2_50_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Sound2_40_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound2_30_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound2_20_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;

        hit50Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        hit40Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        hit30Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        hit20Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;

        FA50Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        FA40Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        FA30Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        FA20Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;

        LickTrials = filterTE(TE, 'LickAction', 'lick', 'reject', 0) & ~badTrials; 
        Lick50Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
        Lick40Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Lick30Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Lick20Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;

    elseif ismember (15, TE.SoundAmplitude)
        Sound1_50_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound1_40_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound1_30_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        Sound1_20_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 15, 'reject', 0) & ~badTrials;

        Sound2_50_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound2_40_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound2_30_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        Sound2_20_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 15, 'reject', 0) & ~badTrials;

        hit50Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        hit40Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        hit30Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        hit20Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 15, 'reject', 0) & ~badTrials;

        FA50Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        FA40Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        FA30Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        FA20Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 15, 'reject', 0) & ~badTrials;

        LickTrials = filterTE(TE, 'LickAction', 'lick', 'reject', 0) & ~badTrials; 
        Lick50Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Lick40Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Lick30Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        Lick20Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 15, 'reject', 0) & ~badTrials;
    else
        Sound1_50_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound1_40_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound1_30_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        Sound1_20_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 10, 'reject', 0) & ~badTrials;

        Sound2_50_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Sound2_40_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Sound2_30_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        Sound2_20_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 10, 'reject', 0) & ~badTrials;

        hit50Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        hit40Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        hit30Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        hit20Trials = filterTE(TE, 'SoundValveIndex', 1, 'LickAction', 'lick', 'SoundAmplitude', 10, 'reject', 0) & ~badTrials;

        FA50Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        FA40Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        FA30Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        FA20Trials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'SoundAmplitude', 10, 'reject', 0) & ~badTrials;

        LickTrials = filterTE(TE, 'LickAction', 'lick', 'reject', 0) & ~badTrials; 
        Lick50Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
        Lick40Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
        Lick30Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
        Lick20Trials = filterTE(TE, 'LickAction', 'lick', 'SoundAmplitude', 10, 'reject', 0) & ~badTrials;
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
%% analysis for Reaction time and foreperiod for each session
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

        ordering = {...
            'hit', hitTrialsThisSession;...
            'FA', FATrialsThisSession;...
            'mix', LickTrialsThisSession;...
            'hit50', hit50TrialsThisSession;...
            'hit40', hit40TrialsThisSession;...
            'hit30', hit30TrialsThisSession;...
            'hit20', hit20TrialsThisSession;... 
            };

            for c2 = 1:size(ordering,1)
                RT_pooled.(ordering{c2,1}).rt{counter,:} = TE.RT(ordering{c2, 2}); 
                RT_pooled.(ordering{c2,1}).fp{counter,:} = TE.fpWindow(ordering{c2, 2}); 
            end
    end
    if saveOn
        save(fullfile(savepath, ['summary_' subjectName '_RT_pooled.mat']), 'RT_pooled');
        disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_RT_pooled.mat']) ' ***']);
    end
    %%   
    figSize = [12 20];
    saveName = ['RT distribution_individual session'];
    ensureFigure(saveName, 1); 
    subA = ceil(sqrt(nSessions));
    for counter = 1:nSessions 
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
    ylim1 = [0 30];
    ylim2 = [0 60];
    ylim3 = [0 20];
    ylim4 = [0 40];
    ylim5 = [0 50];
    ylim6 = [0 100];
 
    subplot(4,3,1);
    RT_hit_value = [];
    FP_hit_value = [];

    for counter = 1:nSessions
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
%     for counter = 1:8
    for counter = 1:nSessions
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
    for counter = 1:nSessions
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

    %  Reaction time vs foreperiod
    figSize = [12 12];
    saveName = ['RT and foreperiod'];
    ensureFigure(saveName, 1); 

    FP_mix_value = [];
    RT_mix_value = []; 

    for counter = 1:nSessions        
        FP_mix_value = [FP_mix_value; RT_pooled.mix.fp{counter, 1}];   
        RT_mix_value = [RT_mix_value; RT_pooled.mix.rt{counter, 1}];  
    end
    subA = ceil(sqrt(nSessions + 1));    
    subplot(subA,subA,1);
    yData = RT_mix_value;
    xData = FP_mix_value;
    scatter(xData, yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2); 
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 9);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 9); 
    set(gca, 'xlim', [-4 0]);
    ylabel('RT'); xlabel(['Foreperiod for All LickTrials']); title('');
 
    for counter = 1:nSessions     
        subplot(subA,subA,1+counter);
        yData = RT_pooled.mix.rt{counter, 1};
        xData = RT_pooled.mix.fp{counter, 1};
        scatter(xData, yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2); 
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 9);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 9); 
        set(gca, 'xlim', [-4 0]);
        ylabel('RT'); xlabel(['Foreperiod Session' num2str(counter)]); title('');
    end
%         formatFigurePublish('size', figSize);
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
        save(fullfile(savepath, ['summary_' subjectName '_RT_pooled.mat']), 'RT_pooled');
        disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_RT_pooled.mat']) ' ***']);
    end
          
%% Save behavior plot 504030201510_all

    saveName = ['behavior_all'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  

    subplot(4,2,1);     
    performance_hit50 = length(find(hit50Trials)) / length(find(Sound1_50_Trials));
    performance_hit40 = length(find(hit40Trials)) / length(find(Sound1_40_Trials));
    performance_hit30 = length(find(hit30Trials)) / length(find(Sound1_30_Trials));
    performance_hit20 = length(find(hit20Trials)) / length(find(Sound1_20_Trials));
    x = [50 40 30 20];
    y = [performance_hit50 performance_hit40 performance_hit30 performance_hit20];
    plot(x,y,'-o', 'color', [0/255 128/255 0/255]); hold on;
    
    performance_FA50 = length(find(FA50Trials)) / length(find(Sound2_50_Trials));
    performance_FA40 = length(find(FA40Trials)) / length(find(Sound2_40_Trials));
    performance_FA30 = length(find(FA30Trials)) / length(find(Sound2_30_Trials));  
    performance_FA20 = length(find(FA20Trials)) / length(find(Sound2_20_Trials)); 
    y = [performance_FA50 performance_FA40 performance_FA30 performance_FA20];      
    plot(x,y,'-o', 'color', [215/255 48/255 31/255]); 
    legend({'hit', 'FA'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL (dB)'); ylabel('Performance'); title('Performance');
    hold off
    
    subplot(4,2,2); 
    Lickprob_hit50 = length(find(hit50Trials)) / length(find(Lick50Trials));
    Lickprob_hit40 = length(find(hit40Trials)) / length(find(Lick40Trials));
    Lickprob_hit30 = length(find(hit30Trials)) / length(find(Lick30Trials));
    Lickprob_hit20 = length(find(hit20Trials)) / length(find(Lick20Trials));
    x = [50 40 30 20];
    y = [Lickprob_hit50 Lickprob_hit40 Lickprob_hit30 Lickprob_hit20];
    plot(x,y,'-o', 'color', [0/255 128/255 0/255]); hold on;
    
    Lickprob_FA50 = length(find(FA50Trials)) / length(find(Lick50Trials));
    Lickprob_FA40 = length(find(FA40Trials)) / length(find(Lick40Trials));
    Lickprob_FA30 = length(find(FA30Trials)) / length(find(Lick30Trials)); 
    Lickprob_FA20 = length(find(FA20Trials)) / length(find(Lick20Trials));
    y = [Lickprob_FA50 Lickprob_FA40 Lickprob_FA30 Lickprob_FA20];    
    plot(x,y,'-o', 'color', [215/255 48/255 31/255]); 
    legend({'hit', 'FA'}, 'Location','northwest');
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL (dB)'); ylabel('Lick prob.'); title('Psychometric');
    hold off
    
    subplot(4,2,3);  
    x = [50 40 30 20];   
    y = [mean(TE.RT(hit50Trials)) mean(TE.RT(hit40Trials)) mean(TE.RT(hit30Trials)) mean(TE.RT(hit20Trials))];
    err = [std(TE.RT(hit50Trials)) std(TE.RT(hit40Trials)) std(TE.RT(hit30Trials)) std(TE.RT(hit20Trials))]; 
    errorbar(x,y,err,'-s','color', [0/255 128/255 0/255], 'MarkerSize',10,...
    'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]); hold on;
    y = [mean(TE.RT(FA50Trials)) mean(TE.RT(FA40Trials)) mean(TE.RT(FA30Trials)) mean(TE.RT(FA20Trials))];
    err = [std(TE.RT(FA50Trials)) std(TE.RT(FA40Trials)) std(TE.RT(FA30Trials)) std(TE.RT(FA20Trials))];    
    errorbar(x,y,err,'-s','color', [215/255 48/255 31/255], 'MarkerSize',10,...
    'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]); 
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL'); ylabel('RT'); title('RT Mean'); 
    
    subplot(4,2,4);  
    x = [50 40 30 20];   
    y = [median(TE.RT(hit50Trials)) median(TE.RT(hit40Trials)) median(TE.RT(hit30Trials)) median(TE.RT(hit20Trials))];      
    plot(x,y,'-o', 'color', [0/255 128/255 0/255], 'LineWidth', 1); hold on;
    y = [median(TE.RT(FA50Trials)) median(TE.RT(FA40Trials)) median(TE.RT(FA30Trials)) median(TE.RT(FA20Trials))];
    plot(x,y,'-o', 'color', [215/255 48/255 31/255], 'LineWidth', 1);
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL'); ylabel('RT'); title('RT Median'); 
    
    subplot(4,2,5); 
    yData = TE.RT(hitTrials);
    xData = TE.SoundAmplitude(hitTrials);
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2); 
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16); 
    set(gca, 'xlim', [10 50], 'XTick', [10 15 20 30 40 50]);
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL'); ylabel('RT'); title('Hit Trials RT');
    
    subplot (4,2,6);
    xData = TE.RT(hit50Trials);
    cdfplot (xData); hold on;
    xData = TE.RT(hit40Trials);
    cdfplot (xData);  
    xData = TE.RT(hit30Trials);
    cdfplot (xData); 
    xData = TE.RT(hit20Trials);
    cdfplot (xData); 
    legend('Hit-50db','Hit-40db', 'Hit-30db', 'Hit-20db', 'Location','northwest')
    xlabel('Reaction time'); ylabel('Fraction'); title('Hit Trials RT cumulative');
    hold off
    
    subplot(4,2,7);  
    yData = TE.RT(FATrials);
    xData = TE.SoundAmplitude(FATrials);
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    set(gca, 'xlim', [10 50], 'XTick', [10 15 20 30 40 50]);
    set(gca, 'YLim', [0 1], 'YTick', [0 0.2 0.4 0.6 0.8 1]);
    xlabel('SPL'); ylabel('RT'); title('FA Trials RT');
%     
    subplot(4,2,8);  
    xData = TE.RT(FA50Trials);
    cdfplot (xData); hold on;
    xData = TE.RT(FA40Trials);
    cdfplot (xData); 
    xData = TE.RT(FA30Trials);
    cdfplot (xData);   
    xData = TE.RT(FA20Trials);
    cdfplot (xData);  
    legend('FA-50db', 'FA-40db', 'FA-30db', 'FA-20db', 'Location','northwest')
    xlabel('Reaction time'); ylabel('Fraction'); title('FA Trials RT cumulative');
    hold off;
        
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
    
   %% lick and photometry rasters aligned to cue
% phField = 'ZS';
% fluorField = 'ZS'; 
clim1 = [-6 6];
clim2 = [-4 4];
% clim1 = [-0.01 0.01];
% clim2 = [-0.1 0.1];
clims = [clim1; clim1];
channels = TE.Photometry.settings.channels;
validchannel = 1;
% for channel = channels
for channel = validchannel
    saveName = [subjectName '_cue response_ch' num2str(channel)];

    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    clim = clims(channel,:);
    
    subplot(3,4,1); % lick raster for Sound1
    eventRasterFromTE(TE, Sound1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound1Trials'); ylabel('trial number');
    set(gca, 'XLim', [-4 5]); set(gca, 'FontSize', 14); 
    
    subplot(3,4,2); % lick average for Sound1
    avgData1 = eventAverageFromTE(TE, Sound1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 5], 'zeroTimes', TE.Cue);
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
        
    subplot(3,4,3); % phRaster for Sound1
    phRasterFromTE(TE, Sound1Trials, channel, 'window', [-4 5], 'zeroTimes', TE.Cue, 'CLim', clim, 'FluorDataField', fluorField);
    % imagesc('XData', xData', 'CData', alignedPhotometryData);
    
    subplot(3,4,4); % phAverage for Sound1
    avgData = phAverageFromTE(TE, Sound1Trials, channel, 'window', [-4 5], 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
    plot(avgData.xData, avgData.Avg); title(num2str(fluorField));  xlabel('time from cue (s)');
    
    subplot(3,4,5); % lick raster for Sound2
    eventRasterFromTE(TE, Sound2Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound2Trials'); ylabel('trial number');
    set(gca, 'XLim', [-4 5]); set(gca, 'FontSize', 14);
    
    subplot(3,4,6); % lick average for Sound2
    avgData1 = eventAverageFromTE(TE, Sound2Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(3,4,7); % phRaster for Sound2
    phRasterFromTE(TE, Sound2Trials, channel, 'window', [-4 5], 'zeroTimes', TE.Cue, 'CLim', clim, 'FluorDataField', fluorField);
    
    subplot(3,4,8); % phAverage for Sound2
    avgData = phAverageFromTE(TE, Sound2Trials, channel, 'window', [-4 5], 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
    plot(avgData.xData, avgData.Avg); title(num2str(fluorField)); xlabel('time from cue (s)');
    
    subplot(3,4,9); % lick raster for Sound3
    eventRasterFromTE(TE, Sound3Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound3Trials'); ylabel('trial number');
    set(gca, 'XLim', [-4 5]); set(gca, 'FontSize', 14);
    
    subplot(3,4,10); % lick average for Sound3
    avgData1 = eventAverageFromTE(TE, Sound3Trials, 'Port1In', 'trialNumbering', 'consecutive',...
      'window', [-4, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from cue (s)'); 
    
    subplot(3,4,11); % phRaster for Sound3
    phRasterFromTE(TE, Sound3Trials, channel, 'window', [-4 5], 'zeroTimes', TE.Cue, 'CLim', clim, 'FluorDataField', fluorField);
    
    subplot(3,4,12); % phAverage for Sound3
    avgData = phAverageFromTE(TE, Sound3Trials, channel, 'window', [-4 5], 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
    plot(avgData.xData, avgData.Avg); title(num2str(fluorField));  xlabel('time from cue (s)');   
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
end

% lick and photometry rasters aligned to cue

for channel = validchannel
    saveName = [subjectName '_cue response2_ch' num2str(channel)];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    clim = clims(channel,:);
     
    subplot(4,4,1); % lick raster for hit
    eventRasterFromTE(TE, hitTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('hit'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,2); % phRaster for hit
    phRasterFromTE(TE, hitTrials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField);
    
    subplot(4,4,3); % lick raster for miss
    eventRasterFromTE(TE, missTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('miss'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,4); % phRaster for miss
    phRasterFromTE(TE, missTrials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField);
 
    
    subplot(4,4,5); % lick raster for FA
    eventRasterFromTE(TE, FATrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('FA'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,6); % phRaster for FA
    phRasterFromTE(TE, FATrials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField); 
    
    subplot(4,4,7); % lick raster for CR
    eventRasterFromTE(TE, CRTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('CR'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,8); % phRaster for CR
    phRasterFromTE(TE, CRTrials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField);
    
    subplot(4,4,9); % lick raster for Sound3
    eventRasterFromTE(TE, Sound3Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound3'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,10); % phRaster for Sound3
    phRasterFromTE(TE, Sound3Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField);
    
    subplot(4,4,11); % lick raster for uncuedReward
    eventRasterFromTE(TE, uncuedReward, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('uncuedReward'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,12); % phRaster for uncuedReward
    phRasterFromTE(TE, uncuedReward, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField);
    
    subplot(4,4,13); % lick raster for uncuedPunish
    eventRasterFromTE(TE, uncuedPunish, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('uncuedPunish'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,14); % phRaster for uncuedPunish
    phRasterFromTE(TE, uncuedPunish, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField); 
        
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
end
 %% Averages aligned to Cue
    saveName = [subjectName '_Cue response_Avg'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [3 1]; 
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('FA'); mycolors_SL2('sound3'); mycolors_SL2('uncuedReward'); mycolors_SL2('uncuedPunish')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-4, 4], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1Trials, Sound2Trials, Sound3Trials, uncuedReward, uncuedPunish}, 'Port1In', varargin{:});
    legend(hl, {'Sound1', 'Sound2', 'Sound3', 'uncuedReward', 'uncuedPunish'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');     
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {Sound1Trials, Sound2Trials, Sound3Trials, uncuedReward, uncuedPunish}, 1, varargin{:});
    title('Ch1'); ylabel('Ch1');
                        
    if ismember(2, channels)
        subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
        [ha, hl] = phPlotAverageFromTE(TE, {Sound1Trials, Sound2Trials, Sound3Trials, uncuedReward, uncuedPunish}, 2, varargin{:});
        title('Ch2'); ylabel('Ch2');               
    end  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end     

%% Averages aligned to Cue
    saveName = [subjectName '_Cue response_Avgs'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    
%     ylim1 = [-0.01 0.01];
%     ylim2 = [-0.01 0.05];
    ylim1 = [-3 3];
    ylim2 = [-2 5];

    pm = [3 1]; 
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('FA'); mycolors_SL2('CR'); mycolors_SL2('sound3'); mycolors_SL2('uncuedReward'); mycolors_SL2('uncuedPunish')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-4, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors, 'alpha', 1, 'LineWidth', 4};
    axh = [];
    subplot(pm(1), pm(2), 1); 
   [ha, hl] = plotEventAverageFromTE(TE, {hitTrials, missTrials, FATrials, CRTrials}, 'Port1In', varargin{:});
    addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);    
    legend(hl, {'hit', 'miss', 'FA', 'CR'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');     
    set(gca, 'XLim', [-4 4], 'YLim', [-1 15], 'XTick', [-2 0 2 4], 'YTick', [0 10 20]);
    title('Licks'); ylabel('Licks (s)');  
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {hitTrials, missTrials, FATrials, CRTrials}, 1, varargin{:});
    addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);
    set(gca, 'XLim', [-4 4], 'XTick', [-2 0 2 4], 'YTick', [0 1 2 4 6]);
    set(gca, 'YLim', ylim1);
    title('Ch1'); ylabel('Fluor. (\sigma-bl.)');
                        
    if ismember(2, TE.Photometry.settings.channels)
        subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
        [ha, hl] = phPlotAverageFromTE(TE, {hitTrials, missTrials, FATrials, CRTrials}, 2, varargin{:});
        addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);
        set(gca, 'XLim', [-4 4], 'XTick', [-2 0 2 4], 'YTick', [0 1 2 3 4]);
        set(gca, 'YLim', ylim1);
        title('Ch2'); ylabel('Fluor. (\sigma-bl.)'); xlabel('Time from Cue (s)');   
%         figSize = [4 12]; formatFigurePublish('size', figSize);
    end  
       
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));     
    end  
    

    %% Averages aligned to Cue hit trials SPL
    saveName = [subjectName '_Cue response_Avgs2'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [3 1]; 
    tcolors = [0 34 0; 0 109 44; 44 162 95; 153 216 201]; tcolors = tcolors ./ 255;
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.3, 'FluorDataField', fluorField, 'window', [-4, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', tcolors, 'alpha', 1, 'LineWidth', 4};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {hit50Trials, hit40Trials, hit30Trials, hit20Trials}, 'Port1In', varargin{:});
    legend(hl, {'hit50dB', 'hit40dB', 'hit30dB', 'hit20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');     
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {hit50Trials, hit40Trials, hit30Trials, hit20Trials}, 1, varargin{:});
    legend(hl, {'hit50dB', 'hit40dB', 'hit30dB', 'hit20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Ch1'); ylabel(['Ch1' num2str(fluorField)]);
                  
    if ismember(2, channels)
        subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
        [ha, hl] = phPlotAverageFromTE(TE, {hit50Trials, hit40Trials, hit30Trials, hit20Trials}, 2, varargin{:});
        legend(hl, {'hit50dB', 'hit40dB', 'hit30dB', 'hit20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
        title('Ch2'); ylabel(['Ch2' num2str(fluorField)]);               
    end  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));     
    end  
    
 % Averages aligned to Cue FA trials SPL
    saveName = [subjectName '_Cue response_Avgs3'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [3 1]; 
    tcolors = [100 0 0; 222 45 38; 251 106 74; 252 174 137]; tcolors = tcolors ./ 255;
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.3, 'FluorDataField', fluorField, 'window', [-4, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', tcolors};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {FA50Trials, FA40Trials, FA30Trials, FA20Trials}, 'Port1In', varargin{:});
    legend(hl, {'FA50dB', 'FA40dB', 'FA30dB', 'FA20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');     
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {FA50Trials, FA40Trials, FA30Trials, FA20Trials}, 1, varargin{:});
    legend(hl, {'FA50dB', 'FA40dB', 'FA30dB', 'FA20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Ch1'); ylabel(['Ch1' num2str(fluorField)]);
                        
    if ismember(2, channels)
        subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
        [ha, hl] = phPlotAverageFromTE(TE, {FA50Trials, FA40Trials, FA30Trials, FA20Trials}, 2, varargin{:});
        legend(hl, {'FA50dB', 'FA40dB', 'FA30dB', 'FA20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
        title('Ch2'); ylabel(['Ch2' num2str(fluorField)]);               
    end  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));      
    end 

%% Averages aligned to AnswerLick
    saveName = [subjectName '_AnswerLick response_Avgs'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [3 1]; % subplot matrix
    tcolors = [0 128 0; 215 48 31]; tcolors = tcolors ./ 255;
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.25, 'FluorDataField', fluorField, 'window', [-4, 4], 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', tcolors, 'alpha', 1, 'LineWidth', 4};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {hitTrials, FATrials}, 'Port1In', varargin{:}, 'zeroTimes', TE.Answer);
    legend(hl, {'Hit', 'FA'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from AnswerLick (s)');  
    set(gca, 'XLim', [-2 4], 'YLim', [-1 25], 'XTick', [-2 0 2 4], 'YTick', [0 5 10 15]);
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {hitTrials, FATrials}, 1, varargin{:}, 'zeroTimes', TE.Answer);
    legend(hl, {'Hit', 'FA'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Ch1'); ylabel(['Ch1' num2str(fluorField)]);
    set(gca, 'XLim', [-2 4], 'XTick', [-2 0 2 4], 'YTick', [0 2 4 6]);
%     set(gca, 'YLim', [-1 4.5]);
                        
    if ismember(2, channels)
    subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {hitTrials, FATrials}, 2, varargin{:}, 'zeroTimes', TE.Answer, 'linespec', {'g', 'r'});
    legend(hl, {'Hit', 'FA'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Ch2');
    set(gca, 'XLim', [-2 4], 'XTick', [-2 0 2 4], 'YTick', [0 2 4 6]);
%     set(gca, 'YLim', [-1 4.5]);
%     figSize = [4 12]; 
%     formatFigurePublish('size', figSize);
    end  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));      
    end 

%% Averages aligned to Us
    saveName = [subjectName '_Us response_Avgs'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    

    pm = [3 1]; 
%     tcolors = [0 128 0; 160 177 186; 215 48 31; 253 204 138; 255 170 0; 43 140 190; 204 121 167]; tcolors = tcolors ./ 255;
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('FA'); mycolors_SL2('CR'); mycolors_SL2('sound3'); mycolors_SL2('uncuedReward'); mycolors_SL2('uncuedPunish')];    
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.3, 'FluorDataField', fluorField, 'window', [-4, 4], 'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors, 'alpha', 1, 'LineWidth', 4};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {hitTrials, missTrials, FATrials, CRTrials, Sound3Trials, uncuedReward, uncuedPunish}, 'Port1In', varargin{:});
%    [ha, hl] = plotEventAverageFromTE(TE, {hitTrials, missTrials, FATrials, CRTrials, Sound3Trials}, 'Port1In', varargin{:});
    addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);    
    legend(hl, {'hit', 'miss', 'FA', 'CR', 'Sound3', 'uncuedReward', 'uncuedPunish'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');     
    set(gca, 'XLim', [-3 3], 'YLim', [-1 15], 'XTick', [-2 0 2 4], 'YTick', [0 10 20]);
    title('Licks'); ylabel('Licks (s)');  
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {hitTrials, missTrials, FATrials, CRTrials, Sound3Trials, uncuedReward, uncuedPunish}, 1, varargin{:});
    addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);
    set(gca, 'XLim', [-3 3], 'XTick', [-2 0 2 4], 'YTick', [0 1 2 4 6]);
    set(gca, 'YLim', ylim1);
    title('Ch1'); ylabel('Fluor. (\sigma-bl.)');
                        
    if ismember(2, TE.Photometry.settings.channels)
        subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
        [ha, hl] = phPlotAverageFromTE(TE, {hitTrials, missTrials, FATrials, CRTrials, Sound3Trials, uncuedReward, uncuedPunish}, 2, varargin{:});
        addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);
        set(gca, 'XLim', [-3 3], 'XTick', [-2 0 2 4], 'YTick', [0 1 2 3 4]);
        set(gca, 'YLim', ylim1);
        title('Ch2'); ylabel('Fluor. (\sigma-bl.)'); xlabel('Time from Us (s)');   
%         figSize = [4 12]; formatFigurePublish('size', figSize);
    end 
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));    
    end
    
    %% Averages aligned to US hit trials SPL
    saveName = [subjectName '_Us response_Avgs2'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [3 1]; 
    tcolors = [0 34 0; 0 109 44; 44 162 95; 153 216 201]; tcolors = tcolors ./ 255;
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.25, 'FluorDataField', fluorField, 'window', [-3, 4], 'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', tcolors, 'alpha', 1, 'LineWidth', 4};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {hit50Trials, hit40Trials, hit30Trials, hit20Trials}, 'Port1In', varargin{:});
    legend(hl, {'hit50dB', 'hit40dB', 'hit30dB', 'hit20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Us (s)');     
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {hit50Trials, hit40Trials, hit30Trials, hit20Trials}, 1, varargin{:});
    legend(hl, {'hit50dB', 'hit40dB', 'hit30dB', 'hit20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Ch1'); ylabel(['Ch1' num2str(fluorField)]);
                  
    if ismember(2, channels)
        subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
        [ha, hl] = phPlotAverageFromTE(TE, {hit50Trials, hit40Trials, hit30Trials, hit20Trials}, 2, varargin{:});
        legend(hl, {'hit50dB', 'hit40dB', 'hit30dB', 'hit20dB'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
        title('Ch2'); ylabel('Ch2');               
    end  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));      
    end  

%% lick and photometry rasters aligned to cue as function of SPL
clim1 = [-3 3];
clim2 = [-4 4];
clims = [clim1; clim2];
% clim = [];
% for channel = channels
for channel = validchannel
    saveName = [subjectName '_cue response3_ch' num2str(channel)];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    clim = clims(channel,:);
    
    subplot(4,4,1); % lick raster for hit50dB
    eventRasterFromTE(TE, hit50Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('hit50dB'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,2); % phRaster 
    phRasterFromTE(TE, hit50Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim, 'FluorDataField', fluorField); xlabel('time from Cue (s)');
    
    subplot(4,4,3); % lick raster for hit40dB
    eventRasterFromTE(TE, hit40Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('hit40dB'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,4); % phRaster 
    phRasterFromTE(TE, hit40Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField);
 
    
    subplot(4,4,5); % lick raster for hit30dB
    eventRasterFromTE(TE, hit30Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('hit30dB'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,6); % phRaster 
    phRasterFromTE(TE, hit30Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField); 
    
    subplot(4,4,7); % lick raster for hit30dB
    eventRasterFromTE(TE, hit20Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('hit20dB'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,8); % phRaster 
    phRasterFromTE(TE, hit20Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField); 
    
    subplot(4,4,9); % lick raster for FA50dB
    eventRasterFromTE(TE, FA50Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('FA50dB'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,10); % phRaster 
    phRasterFromTE(TE, FA50Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField); xlabel('time from Cue (s)');
    
    subplot(4,4,11); % lick raster for FA40dB
    eventRasterFromTE(TE, FA40Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('FA40dB'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,12); % phRaster 
    phRasterFromTE(TE, FA40Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField); 
    
    subplot(4,4,13); % lick raster for FA30dB
    eventRasterFromTE(TE, FA30Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('FA30dB'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,14); % phRaster 
    phRasterFromTE(TE, FA30Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField); 
    
    subplot(4,4,15); % lick raster for FA20dB
    eventRasterFromTE(TE, FA20Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('FA20dB'); ylabel('trial number'); xlabel('time from Cue (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,16); % phRaster 
    phRasterFromTE(TE, FA20Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Cue, 'CLim', clim,'FluorDataField', fluorField); 
   
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
end       
% lick and photometry rasters aligned to Us
% clim1 = [-6 6];
% clim2 = [-4 4];
% clims = [clim1; clim2];
% clim = [];
% for channel = channels
for channel = validchannel
    saveName = [subjectName '_Us response2_ch' num2str(channel)];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    clim = clims(channel,:);
     
    subplot(4,4,1); % lick raster for hit
    eventRasterFromTE(TE, hitTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('hit'); ylabel('trial number'); xlabel('time from Us (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,2); % phRaster for hit
    phRasterFromTE(TE, hitTrials, channel, 'window', [-4 6], 'zeroTimes', TE.Us, 'CLim', clim,'FluorDataField', fluorField);
    
    subplot(4,4,3); % lick raster for miss
    eventRasterFromTE(TE, missTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('miss'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14); 
    
    subplot(4,4,4); % phRaster for miss
    phRasterFromTE(TE, missTrials, channel, 'window', [-4 6], 'zeroTimes', TE.Us, 'CLim', clim,'FluorDataField', fluorField);
 
    
    subplot(4,4,5); % lick raster for FA
    eventRasterFromTE(TE, FATrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('FA'); ylabel('trial number'); 
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,6); % phRaster for FA
    phRasterFromTE(TE, FATrials, channel, 'window', [-4 6], 'zeroTimes', TE.Us, 'CLim', clim,'FluorDataField', fluorField); 
    
    subplot(4,4,7); % lick raster for CR
    eventRasterFromTE(TE, CRTrials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('CR'); ylabel('trial number'); xlabel('time from Us (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,8); % phRaster for CR
    phRasterFromTE(TE, CRTrials, channel, 'window', [-4 6], 'zeroTimes', TE.Us, 'CLim', clim,'FluorDataField', fluorField);
    
    subplot(4,4,9); % lick raster for Sound3
    eventRasterFromTE(TE, Sound3Trials, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('Sound3'); ylabel('trial number'); xlabel('time from Us (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,10); % phRaster for Sound3
    phRasterFromTE(TE, Sound3Trials, channel, 'window', [-4 6], 'zeroTimes', TE.Us, 'CLim', clim,'FluorDataField', fluorField);
    
    subplot(4,4,11); % lick raster for uncuedReward
    eventRasterFromTE(TE, uncuedReward, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('uncuedReward'); ylabel('trial number'); xlabel('time from Us (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,12); % phRaster for uncuedReward
    phRasterFromTE(TE, uncuedReward, channel, 'window', [-4 6], 'zeroTimes', TE.Us, 'CLim', clim,'FluorDataField', fluorField);
    
    subplot(4,4,13); % lick raster for uncuedPunish
    eventRasterFromTE(TE, uncuedPunish, 'Port1In', 'trialNumbering', 'consecutive',...
        'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
    title('uncuedPunish'); ylabel('trial number'); xlabel('time from Us (s)');
    set(gca, 'XLim', [-4 6]); set(gca, 'FontSize', 14);
    
    subplot(4,4,14); % phRaster for uncuedPunish
    phRasterFromTE(TE, uncuedPunish, channel, 'window', [-4 6], 'zeroTimes', TE.Us, 'CLim', clim,'FluorDataField', fluorField); 
        
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
end    

%% foreperiod bar plot 2 RTs 
hitFastestTrials = hitTrials;
FAFastestTrials = FATrials;

for channel = TE.Photometry.settings.channels
    s2 = struct(...
        'all', [],...
        'data', cell(1,1),...
        'avg', zeros(nSessions, 1),...
        'SEM', zeros(nSessions, 1)...
        );
    fpWindow_pooled2 = struct(...
        'FastHitRT', s2,...
        'SlowHitRT', s2,...
        'FastFART', s2,...
        'SlowFART', s2...
        );
    csWindow0_pooled2 = struct(...
        'FastHitRT', s2,...
        'SlowHitRT', s2,...
        'FastFART', s2,...
        'SlowFART', s2...
        );
    fpWindow_pooled2_norm = struct(...
        'FastHitRT', s2,...
        'SlowHitRT', s2,...
        'FastFART', s2,...
        'SlowFART', s2...
        );
    csWindow0_pooled2_norm = struct(...
        'FastHitRT', s2,...
        'SlowHitRT', s2,...
        'FastFART', s2,...
        'SlowFART', s2...
        );
    for counter = 1:nSessions  
        HitTrialsThisSession = find(hitTrials & (TE.sessionIndex == counter));
        [sorted,Ix] = sort (TE.RT (HitTrialsThisSession)); 
        HitTrialsThisSession = HitTrialsThisSession(Ix);
        m = length(HitTrialsThisSession);
        if mod(m, 2) == 0 
            FastHitTrials_temp = HitTrialsThisSession (1: m/2);
            SlowHitTrials_temp = HitTrialsThisSession (m/2+1:end);
        else
            FastHitTrials_temp = HitTrialsThisSession (1: (m-1)/2);
            SlowHitTrials_temp = HitTrialsThisSession ((m+1)/2:end);
        end
        
        FATrialsThisSession = find(FATrials & (TE.sessionIndex == counter));
        [sorted,Ix] = sort (TE.RT (FATrialsThisSession)); 
        FATrialsThisSession = FATrialsThisSession(Ix);
        m = length(FATrialsThisSession);
        if mod(m, 2) == 0 
            FastFATrials_temp = FATrialsThisSession (1: m/2);
            SlowFATrials_temp = FATrialsThisSession (m/2+1:end);
        else
            FastFATrials_temp = FATrialsThisSession (1: (m-1)/2);
            SlowFATrials_temp = FATrialsThisSession ((m+1)/2:end);
        end 

        ordering = {...
            'FastHitRT', FastHitTrials_temp;...
            'SlowHitRT', SlowHitTrials_temp;... 
            'FastFART', FastFATrials_temp;...
            'SlowFART', SlowFATrials_temp;... 
            };

            for c2 = 1:size(ordering,1)
                thisData = TE.phPeakMean_fpWindow(channel).data(ordering{c2, 2});
                fpWindow_pooled2.(ordering{c2,1}).data{counter,:} = thisData;
                fpWindow_pooled2.(ordering{c2,1}).avg(counter,:) = nanmean(thisData);
                fpWindow_pooled2.(ordering{c2,1}).SEM(counter,:) = nanSEM(thisData); 
                fpWindow_pooled2.(ordering{c2,1}).all = [fpWindow_pooled2.(ordering{c2,1}).all; thisData];
            end
            
            for c2 = 1:size(ordering,1)
                thisData = TE.phPeakMean_csWindow0(channel).data(ordering{c2, 2});
                csWindow0_pooled2.(ordering{c2,1}).data{counter,:} = thisData;
                csWindow0_pooled2.(ordering{c2,1}).avg(counter,:) = nanmean(thisData);
                csWindow0_pooled2.(ordering{c2,1}).SEM(counter,:) = nanSEM(thisData);
                csWindow0_pooled2.(ordering{c2,1}).all = [csWindow0_pooled2.(ordering{c2,1}).all; thisData];
            end 
            
        ordering = {...
            'FastHitRT', FastHitTrials_temp;...
            'SlowHitRT', SlowHitTrials_temp;...  
            };
            for c3 = 1:size(ordering,1)
                thisData = (fpWindow_pooled2.(ordering{c3,1}).data{counter,:} - fpWindow_pooled2.FastHitRT.avg(counter,:)) / abs(fpWindow_pooled2.FastHitRT.avg(counter,:)) +1;
                fpWindow_pooled2_norm.(ordering{c3,1}).data{counter,:} = thisData;
                fpWindow_pooled2_norm.(ordering{c3,1}).avg(counter,:) = nanmean(thisData);
                fpWindow_pooled2_norm.(ordering{c3,1}).SEM(counter,:) = nanSEM(thisData); 
                fpWindow_pooled2_norm.(ordering{c3,1}).all = [fpWindow_pooled2_norm.(ordering{c3,1}).all; thisData];

                thisData = (csWindow0_pooled2.(ordering{c3,1}).data{counter,:} - csWindow0_pooled2.FastHitRT.avg(counter,:)) / abs(csWindow0_pooled2.FastHitRT.avg(counter,:)) +1;
                csWindow0_pooled2_norm.(ordering{c3,1}).data{counter,:} = thisData;
                csWindow0_pooled2_norm.(ordering{c3,1}).avg(counter,:) = nanmean(thisData);
                csWindow0_pooled2_norm.(ordering{c3,1}).SEM(counter,:) = nanSEM(thisData);  
                csWindow0_pooled2_norm.(ordering{c3,1}).all = [csWindow0_pooled2_norm.(ordering{c3,1}).all; thisData];
            end 
        ordering = {...
            'FastFART', FastFATrials_temp;...
            'SlowFART', SlowFATrials_temp;...  
            };
            for c4 = 1:size(ordering,1)
                thisData = (fpWindow_pooled2.(ordering{c4,1}).data{counter,:} - fpWindow_pooled2.FastFART.avg(counter,:)) / abs(fpWindow_pooled2.FastFART.avg(counter,:)) +1;
                fpWindow_pooled2_norm.(ordering{c4,1}).data{counter,:} = thisData;
                fpWindow_pooled2_norm.(ordering{c4,1}).avg(counter,:) = nanmean(thisData);
                fpWindow_pooled2_norm.(ordering{c4,1}).SEM(counter,:) = nanSEM(thisData);  
                fpWindow_pooled2_norm.(ordering{c4,1}).all = [fpWindow_pooled2_norm.(ordering{c4,1}).all; thisData];
                
                thisData = (csWindow0_pooled2.(ordering{c4,1}).data{counter,:} - csWindow0_pooled2.FastFART.avg(counter,:)) / abs(csWindow0_pooled2.FastFART.avg(counter,:)) +1;
                csWindow0_pooled2_norm.(ordering{c4,1}).data{counter,:} = thisData;
                csWindow0_pooled2_norm.(ordering{c4,1}).avg(counter,:) = nanmean(thisData);
                csWindow0_pooled2_norm.(ordering{c4,1}).SEM(counter,:) = nanSEM(thisData);  
                csWindow0_pooled2_norm.(ordering{c4,1}).all = [csWindow0_pooled2_norm.(ordering{c4,1}).all; thisData];
            end 
    end
    if saveOn
        save(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled2_ch' num2str(channel) '.mat']), 'fpWindow_pooled2');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled2_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled2_norm_ch' num2str(channel) '.mat']), 'fpWindow_pooled2_norm');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled2_norm_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled2_ch' num2str(channel) '.mat']), 'csWindow0_pooled2');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled2_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled2_norm_ch' num2str(channel) '.mat']), 'csWindow0_pooled2_norm');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled2_norm_ch' num2str(channel) '.mat']) ' ***']);
    end
end
%
for channel = TE.Photometry.settings.channels  
    load(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled2_ch' num2str(channel) '.mat']), 'fpWindow_pooled2');
    load(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled2_norm_ch' num2str(channel) '.mat']), 'fpWindow_pooled2_norm');
    figSize = [4 4];
    yTick1 = [-0.8 -0.6 -0.4 -0.2 0 0.2 0.4 0.6 0.8 1.0];
    yTick2 = [-1 0 1 2 3 4 5];
    ylim1 = [-0.5 0.5];
    ylim2 = [-3 3]; 
    saveName = ['foreperiod_barPlot_RT2_ch' num2str(channel)];
    ensureFigure(saveName, 1);
    subplot(2,3,1); 
    yData = [nanmean(fpWindow_pooled2.FastHitRT.all) nanmean(fpWindow_pooled2.SlowHitRT.all)];
    bData = [nanSEM(fpWindow_pooled2.FastHitRT.all) nanSEM(fpWindow_pooled2.SlowHitRT.all)];
    errorbar([1 2], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    [h, p] = ttest2(fpWindow_pooled2.FastHitRT.all, fpWindow_pooled2.SlowHitRT.all);
    textBox(['unpaired ttest p = ' num2str(p)],[], [0.8 0.95], 9);
    
    subplot(2,3,2); 
    for counter = 1:nSessions
        yData = [fpWindow_pooled2.FastHitRT.avg(counter) fpWindow_pooled2.SlowHitRT.avg(counter)];
        bData = [fpWindow_pooled2.FastHitRT.SEM(counter) fpWindow_pooled2.SlowHitRT.SEM(counter)];
        plot([1 2], yData, 'color', [179/255 179/255 179/255]);
        set(gca, 'XLim', [0.5 2.5], 'YLim', ylim1, 'XTick', [1 2], 'XTickLabel', {'FastRT', 'SlowRT'}, 'YTick', yTick1); 
        hold on;
    end
    yData = [nanmean(fpWindow_pooled2.FastHitRT.avg) nanmean(fpWindow_pooled2.SlowHitRT.avg)];
    bData = [nanSEM(fpWindow_pooled2.FastHitRT.avg) nanSEM(fpWindow_pooled2.SlowHitRT.avg)];
    errorbar([1 2], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    [h, p] = ttest(fpWindow_pooled2.FastHitRT.avg, fpWindow_pooled2.SlowHitRT.avg);
    textBox(['paired ttest p = ' num2str(p)],[], [0.8 0.95], 9);

    subplot(2,3,3); 
    for counter = 1:nSessions
        yData = [fpWindow_pooled2_norm.FastHitRT.avg(counter) fpWindow_pooled2_norm.SlowHitRT.avg(counter)];
        bData = [fpWindow_pooled2_norm.FastHitRT.SEM(counter) fpWindow_pooled2_norm.SlowHitRT.SEM(counter)];
        plot([1 2], yData, 'color', [179/255 179/255 179/255]);
        set(gca, 'XLim', [0.5 2.5], 'YLim', ylim2, 'XTick', [1 2], 'XTickLabel', {'FastRT', 'SlowRT'}, 'YTick', yTick2); 
        hold on;
    end
    yData = [nanmean(fpWindow_pooled2_norm.FastHitRT.avg) nanmean(fpWindow_pooled2_norm.SlowHitRT.avg)];
    bData = [nanSEM(fpWindow_pooled2_norm.FastHitRT.avg) nanSEM(fpWindow_pooled2_norm.SlowHitRT.avg)];
    errorbar([1 2], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    [h, p] = ttest(fpWindow_pooled2_norm.FastHitRT.avg, fpWindow_pooled2_norm.SlowHitRT.avg);
    textBox(['p = ' num2str(p)],[], [0.8 0.95], 9); title('normed');
        
    subplot(2,3,4); 
    yData = [nanmean(fpWindow_pooled2.FastFART.all) nanmean(fpWindow_pooled2.SlowFART.all)];
    bData = [nanSEM(fpWindow_pooled2.FastFART.all) nanSEM(fpWindow_pooled2.SlowFART.all)];
    errorbar([1 2], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    [h, p] = ttest2(fpWindow_pooled2.FastFART.all, fpWindow_pooled2.SlowFART.all);
    textBox(['p = ' num2str(p)],[], [0.8 0.95], 9);
        
    subplot(2,3,5); 
    for counter = 1:nSessions
        yData = [fpWindow_pooled2.FastFART.avg(counter) fpWindow_pooled2.SlowFART.avg(counter)];
        bData = [fpWindow_pooled2.FastFART.SEM(counter) fpWindow_pooled2.SlowFART.SEM(counter)];
        plot([1 2], yData, 'color', [179/255 179/255 179/255]);
        set(gca, 'XLim', [0.5 2.5], 'YLim', ylim1, 'XTick', [1 2], 'XTickLabel', {'FastRT', 'SlowRT'}, 'YTick', yTick1); 
        hold on;
    end
    yData = [nanmean(fpWindow_pooled2.FastFART.avg) nanmean(fpWindow_pooled2.SlowFART.avg)];
    bData = [nanSEM(fpWindow_pooled2.FastFART.avg) nanSEM(fpWindow_pooled2.SlowFART.avg)];
    errorbar([1 2], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    [h, p] = ttest(fpWindow_pooled2.FastFART.avg, fpWindow_pooled2.SlowFART.avg);
    textBox(['p = ' num2str(p)],[], [0.8 0.95], 9);

    subplot(2,3,6); 
    for counter = 1:nSessions
        yData = [fpWindow_pooled2_norm.FastFART.avg(counter) fpWindow_pooled2_norm.SlowFART.avg(counter)];
        bData = [fpWindow_pooled2_norm.FastFART.SEM(counter) fpWindow_pooled2_norm.SlowFART.SEM(counter)];
        plot([1 2], yData, 'color', [179/255 179/255 179/255]);
        set(gca, 'XLim', [0.5 2.5], 'YLim', ylim2, 'XTick', [1 2], 'XTickLabel', {'FastRT', 'SlowRT'}, 'YTick', yTick2); 
        hold on;
    end
    yData = [nanmean(fpWindow_pooled2_norm.FastFART.avg) nanmean(fpWindow_pooled2_norm.SlowFART.avg)];
    bData = [nanSEM(fpWindow_pooled2_norm.FastFART.avg) nanSEM(fpWindow_pooled2_norm.SlowFART.avg)];
    errorbar([1 2], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    [h, p] = ttest(fpWindow_pooled2_norm.FastFART.avg, fpWindow_pooled2_norm.SlowFART.avg);
    textBox(['p = ' num2str(p)],[], [0.8 0.95], 9);
%     formatFigurePublish('size', figSize);
%     set(gcf,'toolbar','figure');
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end

% preCue bar plot 2 RTs     
    figSize = [4 4];
    yTick1 = [-0.8 -0.6 -0.4 -0.2 0 0.2 0.4 0.6 0.8 1.0];
    yTick2 = [-1 0 1 2 3 4 5];
    ylim1 = [-0.5 0.5];
    ylim2 = [-3 3];      
    saveName = ['preCue_barPlot_RT2_ch' num2str(channel)];
    ensureFigure(saveName, 1);
    load(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled2_ch' num2str(channel) '.mat']), 'csWindow0_pooled2');
    load(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled2_norm_ch' num2str(channel) '.mat']), 'csWindow0_pooled2_norm');
    % linecolors = [mycolors('gr1'); mycolors('gr2'); mycolors('gr3'); mycolors('gr4')];
    subplot(2,3,1);
    yData = [nanmean(csWindow0_pooled2.FastHitRT.all) nanmean(csWindow0_pooled2.SlowHitRT.all)];
    bData = [nanSEM(csWindow0_pooled2.FastHitRT.all) nanSEM(csWindow0_pooled2.SlowHitRT.all)];
    errorbar([1 2], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    [h, p] = ttest2(csWindow0_pooled2.FastHitRT.all, csWindow0_pooled2.SlowHitRT.all);
    textBox(['unpaired ttest p = ' num2str(p)],[], [0.8 0.95], 9);
    
    subplot(2,3,2);
    for counter = 1:nSessions
        yData = [csWindow0_pooled2.FastHitRT.avg(counter) csWindow0_pooled2.SlowHitRT.avg(counter)];
        bData = [csWindow0_pooled2.FastHitRT.SEM(counter) csWindow0_pooled2.SlowHitRT.SEM(counter)];
        plot([1 2], yData, 'color', [179/255 179/255 179/255]);
        set(gca, 'XLim', [0.5 2.5], 'YLim', ylim1, 'XTick', [1 2], 'XTickLabel', {'FastRT', 'SlowRT'}, 'YTick', yTick1); 
        hold on;
    end
    yData = [nanmean(csWindow0_pooled2.FastHitRT.avg) nanmean(csWindow0_pooled2.SlowHitRT.avg)];
    bData = [nanSEM(csWindow0_pooled2.FastHitRT.avg) nanSEM(csWindow0_pooled2.SlowHitRT.avg)];
    errorbar([1 2], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    [h, p] = ttest(csWindow0_pooled2.FastHitRT.avg, csWindow0_pooled2.SlowHitRT.avg);
    textBox(['paired ttest p = ' num2str(p)],[], [0.8 0.95], 9);
    
    subplot(2,3,3); 
    for counter = 1:nSessions
        yData = [csWindow0_pooled2_norm.FastHitRT.avg(counter) csWindow0_pooled2_norm.SlowHitRT.avg(counter)];
        bData = [csWindow0_pooled2_norm.FastHitRT.SEM(counter) csWindow0_pooled2_norm.SlowHitRT.SEM(counter)];
        plot([1 2], yData, 'color', [179/255 179/255 179/255]);
        set(gca, 'XLim', [0.5 2.5], 'YLim', ylim2, 'XTick', [1 2], 'XTickLabel', {'FastRT', 'SlowRT'}, 'YTick', yTick2); 
        hold on;
    end
    yData = [nanmean(csWindow0_pooled2_norm.FastHitRT.avg) nanmean(csWindow0_pooled2_norm.SlowHitRT.avg)];
    bData = [nanSEM(csWindow0_pooled2_norm.FastHitRT.avg) nanSEM(csWindow0_pooled2_norm.SlowHitRT.avg)];
    errorbar([1 2], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    [h, p] = ttest(csWindow0_pooled2_norm.FastHitRT.avg, csWindow0_pooled2_norm.SlowHitRT.avg);
    textBox(['p = ' num2str(p)],[], [0.8 0.95], 9); title('normed');
    
    subplot(2,3,4); 
    yData = [nanmean(csWindow0_pooled2.FastFART.all) nanmean(csWindow0_pooled2.SlowFART.all)];
    bData = [nanSEM(csWindow0_pooled2.FastFART.all) nanSEM(csWindow0_pooled2.SlowFART.all)];
    errorbar([1 2], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    [h, p] = ttest2(csWindow0_pooled2.FastFART.all, csWindow0_pooled2.SlowFART.all);
    textBox(['p = ' num2str(p)],[], [0.8 0.95], 9);
    
    subplot(2,3,5); 
    for counter = 1:nSessions
        yData = [csWindow0_pooled2.FastFART.avg(counter) csWindow0_pooled2.SlowFART.avg(counter)];
        bData = [csWindow0_pooled2.FastFART.SEM(counter) csWindow0_pooled2.SlowFART.SEM(counter)];
        plot([1 2], yData, 'color', [179/255 179/255 179/255]);
        set(gca, 'XLim', [0.5 2.5], 'YLim', ylim1, 'XTick', [1 2], 'XTickLabel', {'FastRT', 'SlowRT'}, 'YTick', yTick1); 
        hold on;
    end
    yData = [nanmean(csWindow0_pooled2.FastFART.avg) nanmean(csWindow0_pooled2.SlowFART.avg)];
    bData = [nanSEM(csWindow0_pooled2.FastFART.avg) nanSEM(csWindow0_pooled2.SlowFART.avg)];
    errorbar([1 2], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    [h, p] = ttest(csWindow0_pooled2.FastFART.avg, csWindow0_pooled2.SlowFART.avg);
    textBox(['p = ' num2str(p)],[], [0.8 0.95], 9);

    subplot(2,3,6); 
    for counter = 1:nSessions
        yData = [csWindow0_pooled2_norm.FastFART.avg(counter) csWindow0_pooled2_norm.SlowFART.avg(counter)];
        bData = [csWindow0_pooled2_norm.FastFART.SEM(counter) csWindow0_pooled2_norm.SlowFART.SEM(counter)];
        plot([1 2], yData, 'color', [179/255 179/255 179/255]);
        set(gca, 'XLim', [0.5 2.5], 'YLim', ylim2, 'XTick', [1 2], 'XTickLabel', {'FastRT', 'SlowRT'}, 'YTick', yTick2); 
        hold on;
    end
    yData = [nanmean(csWindow0_pooled2_norm.FastFART.avg) nanmean(csWindow0_pooled2_norm.SlowFART.avg)];
    bData = [nanSEM(csWindow0_pooled2_norm.FastFART.avg) nanSEM(csWindow0_pooled2_norm.SlowFART.avg)];
    errorbar([1 2], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    [h, p] = ttest(csWindow0_pooled2_norm.FastFART.avg, csWindow0_pooled2_norm.SlowFART.avg);
    textBox(['p = ' num2str(p)],[], [0.8 0.95], 9); title('normed');
%     formatFigurePublish('size', figSize);
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
end
%% foreperiod bar plot 3 RTs 
for channel = TE.Photometry.settings.channels
      s2 = struct(...
        'all', [],...
        'data', cell(1,1),...
        'avg', zeros(nSessions, 1),...
        'SEM', zeros(nSessions, 1)...
        );
     fpWindow_pooled3 = struct(...
        'Hit_RT1', s2,...
        'Hit_RT2', s2,...
        'Hit_RT3', s2,...
        'FA_RT1', s2,...
        'FA_RT2', s2,...
        'FA_RT3', s2...
        );
     csWindow0_pooled3 = struct(...
        'Hit_RT1', s2,...
        'Hit_RT2', s2,...
        'Hit_RT3', s2,...
        'FA_RT1', s2,...
        'FA_RT2', s2,...
        'FA_RT3', s2...
        );
     fpWindow_pooled3_norm = struct(...
        'Hit_RT1', s2,...
        'Hit_RT2', s2,...
        'Hit_RT3', s2,...
        'FA_RT1', s2,...
        'FA_RT2', s2,...
        'FA_RT3', s2...
        );
     csWindow0_pooled3_norm = struct(...
        'Hit_RT1', s2,...
        'Hit_RT2', s2,...
        'Hit_RT3', s2,...
        'FA_RT1', s2,...
        'FA_RT2', s2,...
        'FA_RT3', s2...
        );
    for counter = 1:nSessions  
        HitTrialsThisSession = find(hitFastestTrials & (TE.sessionIndex == counter));
        [sorted,Ix] = sort (TE.RT (HitTrialsThisSession)); 
        HitTrialsThisSession = HitTrialsThisSession(Ix);
        m = length(HitTrialsThisSession);
        if mod (m,3) == 0
            Hit_RT1_temp = HitTrialsThisSession (1: m/3);
            Hit_RT2_temp = HitTrialsThisSession (m/3+1: m*2/3);
            Hit_RT3_temp = HitTrialsThisSession (m*2/3+1: end);
        elseif mod (m,3) == 1
            Hit_RT1_temp = HitTrialsThisSession (1: (m-1)/3);
            Hit_RT2_temp = HitTrialsThisSession ((m-1)/3+1: (m-1)*2/3);
            Hit_RT3_temp = HitTrialsThisSession ((m-1)*2/3+1: end);
        else
            Hit_RT1_temp = HitTrialsThisSession (1: (m-2)/3);
            Hit_RT2_temp = HitTrialsThisSession ((m-2)/3+1: (m-2)*2/3);
            Hit_RT3_temp = HitTrialsThisSession ((m-2)*2/3+1: end);       
        end 
        
        FATrialsThisSession = find(FAFastestTrials & (TE.sessionIndex == counter));
        [sorted,Ix] = sort (TE.RT (FATrialsThisSession)); 
        FATrialsThisSession = FATrialsThisSession(Ix);
        m = length(FATrialsThisSession);
         if mod (m,3) == 0
            FA_RT1_temp = FATrialsThisSession (1: m/3);
            FA_RT2_temp = FATrialsThisSession (m/3+1: m*2/3);
            FA_RT3_temp = FATrialsThisSession (m*2/3+1: end);
        elseif mod (m,3) == 1
            FA_RT1_temp = FATrialsThisSession (1: (m-1)/3);
            FA_RT2_temp = FATrialsThisSession ((m-1)/3+1: (m-1)*2/3);
            FA_RT3_temp = FATrialsThisSession ((m-1)*2/3+1: end);
        else
            FA_RT1_temp = FATrialsThisSession (1: (m-2)/3);
            FA_RT2_temp = FATrialsThisSession ((m-2)/3+1: (m-2)*2/3);
            FA_RT3_temp = FATrialsThisSession ((m-2)*2/3+1: end);       
        end  

        ordering = {...
            'Hit_RT1', Hit_RT1_temp;...
            'Hit_RT2', Hit_RT2_temp;... 
            'Hit_RT3', Hit_RT3_temp;...
            'FA_RT1', FA_RT1_temp;...
            'FA_RT2', FA_RT2_temp;...
            'FA_RT3', FA_RT3_temp...                
            };

            for c2 = 1:size(ordering,1)
                thisData = TE.phPeakMean_fpWindow(channel).data(ordering{c2, 2});
                fpWindow_pooled3.(ordering{c2,1}).data{counter,:} = thisData;
                fpWindow_pooled3.(ordering{c2,1}).avg(counter,:) = nanmean(thisData);
                fpWindow_pooled3.(ordering{c2,1}).SEM(counter,:) = nanSEM(thisData);  
                fpWindow_pooled3.(ordering{c2,1}).all = [fpWindow_pooled3.(ordering{c2,1}).all; thisData];
            end  
            
            for c2 = 1:size(ordering,1)          
                thisData = TE.phPeakMean_csWindow0(channel).data(ordering{c2, 2});
                csWindow0_pooled3.(ordering{c2,1}).data{counter,:} = thisData;
                csWindow0_pooled3.(ordering{c2,1}).avg(counter,:) = nanmean(thisData);
                csWindow0_pooled3.(ordering{c2,1}).SEM(counter,:) = nanSEM(thisData);
                csWindow0_pooled3.(ordering{c2,1}).all = [csWindow0_pooled3.(ordering{c2,1}).all; thisData];
            end 
            
        ordering = {...
            'Hit_RT1', Hit_RT1_temp;...
            'Hit_RT2', Hit_RT2_temp;... 
            'Hit_RT3', Hit_RT3_temp;...            
            };
            for c3 = 1:size(ordering,1)
                thisData = (fpWindow_pooled3.(ordering{c3,1}).data{counter,:} - fpWindow_pooled3.Hit_RT1.avg(counter,:)) / abs(fpWindow_pooled3.Hit_RT1.avg(counter,:)) +1;
                fpWindow_pooled3_norm.(ordering{c3,1}).data{counter,:} = thisData;
                fpWindow_pooled3_norm.(ordering{c3,1}).avg(counter,:) = nanmean(thisData);
                fpWindow_pooled3_norm.(ordering{c3,1}).SEM(counter,:) = nanSEM(thisData); 
                fpWindow_pooled3_norm.(ordering{c3,1}).all = [fpWindow_pooled3_norm.(ordering{c3,1}).all; thisData];

                thisData = (csWindow0_pooled3.(ordering{c3,1}).data{counter,:} - csWindow0_pooled3.Hit_RT1.avg(counter,:)) / abs(csWindow0_pooled3.Hit_RT1.avg(counter,:)) +1;
                csWindow0_pooled3_norm.(ordering{c3,1}).data{counter,:} = thisData;
                csWindow0_pooled3_norm.(ordering{c3,1}).avg(counter,:) = nanmean(thisData);
                csWindow0_pooled3_norm.(ordering{c3,1}).SEM(counter,:) = nanSEM(thisData);  
                csWindow0_pooled3_norm.(ordering{c3,1}).all = [csWindow0_pooled3_norm.(ordering{c3,1}).all; thisData];
            end 
        ordering = {...
            'FA_RT1', FA_RT1_temp;...
            'FA_RT2', FA_RT2_temp;...
            'FA_RT3', FA_RT3_temp...                
            };
            for c4 = 1:size(ordering,1)
                thisData = (fpWindow_pooled3.(ordering{c4,1}).data{counter,:} - fpWindow_pooled3.FA_RT1.avg(counter,:)) / abs(fpWindow_pooled3.FA_RT1.avg(counter,:)) +1;
                fpWindow_pooled3_norm.(ordering{c4,1}).data{counter,:} = thisData;
                fpWindow_pooled3_norm.(ordering{c4,1}).avg(counter,:) = nanmean(thisData);
                fpWindow_pooled3_norm.(ordering{c4,1}).SEM(counter,:) = nanSEM(thisData);  
                fpWindow_pooled3_norm.(ordering{c4,1}).all = [fpWindow_pooled3_norm.(ordering{c4,1}).all; thisData];

                thisData = (csWindow0_pooled3.(ordering{c4,1}).data{counter,:} - csWindow0_pooled3.FA_RT1.avg(counter,:)) / abs(csWindow0_pooled3.FA_RT1.avg(counter,:)) +1;
                csWindow0_pooled3_norm.(ordering{c4,1}).data{counter,:} = thisData;
                csWindow0_pooled3_norm.(ordering{c4,1}).avg(counter,:) = nanmean(thisData);
                csWindow0_pooled3_norm.(ordering{c4,1}).SEM(counter,:) = nanSEM(thisData); 
                csWindow0_pooled3_norm.(ordering{c4,1}).all = [csWindow0_pooled3_norm.(ordering{c4,1}).all; thisData];
            end
    end
    if saveOn
        save(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled3_ch' num2str(channel) '.mat']), 'fpWindow_pooled3');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled3_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled3_norm_ch' num2str(channel) '.mat']), 'fpWindow_pooled3_norm');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled3_norm_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled3_ch' num2str(channel) '.mat']), 'csWindow0_pooled3');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled3_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled3_norm_ch' num2str(channel) '.mat']), 'csWindow0_pooled3_norm');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled3_norm_ch' num2str(channel) '.mat']) ' ***']);
    end
end

for channel = TE.Photometry.settings.channels    
% foreperiod bar plot 3 RTs
    figSize = [4 4];
    saveName = ['foreperiod_barPlot_RT3_ch' num2str(channel)];
    yTick1 = [-0.8 -0.6 -0.4 -0.2 0 0.2 0.4 0.6 0.8 1.0];
    yTick2 = [-1 0 1 2 3 4 5];
    ylim1 = [-0.5 0.5];
    ylim2 = [-3 3];  
    ensureFigure(saveName, 1);
    load(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled3_ch' num2str(channel) '.mat']), 'fpWindow_pooled3');
    load(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled3_norm_ch' num2str(channel) '.mat']), 'fpWindow_pooled3_norm');  
    subplot(2,3,1);
    yData = [nanmean(fpWindow_pooled3.Hit_RT1.all) nanmean(fpWindow_pooled3.Hit_RT2.all) nanmean(fpWindow_pooled3.Hit_RT3.all)];
    bData = [nanSEM(fpWindow_pooled3.Hit_RT1.all) nanSEM(fpWindow_pooled3.Hit_RT2.all) nanSEM(fpWindow_pooled3.Hit_RT3.all)];
    errorbar([1 2 3], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);    
%     A = [fpWindow_pooled3.Hit_RT1.all fpWindow_pooled3.Hit_RT2.all fpWindow_pooled3.Hit_RT3.all];
%     groups = {'RT1', 'RT2', 'RT3'};
%     p = anova1(A, groups, 'off');
%     textBox(['p = ' num2str(p)],[], [0.5 1], 12);
    
    subplot(2,3,2);
    for counter = 1:nSessions
    yData = [fpWindow_pooled3.Hit_RT1.avg(counter) fpWindow_pooled3.Hit_RT2.avg(counter) fpWindow_pooled3.Hit_RT3.avg(counter)];
    bData = [fpWindow_pooled3.Hit_RT1.SEM(counter) fpWindow_pooled3.Hit_RT2.SEM(counter) fpWindow_pooled3.Hit_RT3.SEM(counter)];
    plot([1 2 3], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 3.5], 'YLim', ylim1, 'XTick', [1 2 3], 'XTickLabel', {'RT1', 'RT2', 'RT3'}, 'YTick', yTick1); 
    hold on;
    end
    yData = [nanmean(fpWindow_pooled3.Hit_RT1.avg) nanmean(fpWindow_pooled3.Hit_RT2.avg) nanmean(fpWindow_pooled3.Hit_RT3.avg)];
    bData = [nanSEM(fpWindow_pooled3.Hit_RT1.avg) nanSEM(fpWindow_pooled3.Hit_RT2.avg) nanSEM(fpWindow_pooled3.Hit_RT3.avg)];
    errorbar([1 2 3], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);    
    A = [fpWindow_pooled3.Hit_RT1.avg fpWindow_pooled3.Hit_RT2.avg fpWindow_pooled3.Hit_RT3.avg];
    groups = {'RT1', 'RT2', 'RT3'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    subplot(2,3,3); 
    for counter = 1:nSessions
    yData = [fpWindow_pooled3_norm.Hit_RT1.avg(counter) fpWindow_pooled3_norm.Hit_RT2.avg(counter) fpWindow_pooled3_norm.Hit_RT3.avg(counter)];
    bData = [fpWindow_pooled3_norm.Hit_RT1.SEM(counter) fpWindow_pooled3_norm.Hit_RT2.SEM(counter) fpWindow_pooled3_norm.Hit_RT3.SEM(counter)];
    plot([1 2 3], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 3.5], 'YLim', ylim2, 'XTick', [1 2 3], 'XTickLabel', {'RT1', 'RT2', 'RT3'}, 'YTick', yTick2); 
    hold on;
    end
    yData = [nanmean(fpWindow_pooled3_norm.Hit_RT1.avg) nanmean(fpWindow_pooled3_norm.Hit_RT2.avg) nanmean(fpWindow_pooled3_norm.Hit_RT3.avg)];
    bData = [nanSEM(fpWindow_pooled3_norm.Hit_RT1.avg) nanSEM(fpWindow_pooled3_norm.Hit_RT2.avg) nanSEM(fpWindow_pooled3_norm.Hit_RT3.avg)];
    errorbar([1 2 3], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    A = [fpWindow_pooled3_norm.Hit_RT1.avg fpWindow_pooled3_norm.Hit_RT2.avg fpWindow_pooled3_norm.Hit_RT3.avg];
    groups = {'RT1', 'RT2', 'RT3'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12); title('norm. to RT1');

    subplot(2,3,4); 
    yData = [nanmean(fpWindow_pooled3.FA_RT1.all) nanmean(fpWindow_pooled3.FA_RT2.all) nanmean(fpWindow_pooled3.FA_RT3.all)];
    bData = [nanSEM(fpWindow_pooled3.FA_RT1.all) nanSEM(fpWindow_pooled3.FA_RT2.all) nanSEM(fpWindow_pooled3.FA_RT3.all)];
    errorbar([1 2 3], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
%      A = [fpWindow_pooled3.FA_RT1.all fpWindow_pooled3.FA_RT2.all fpWindow_pooled3.FA_RT3.all];
%     groups = {'RT1', 'RT2', 'RT3'};
%     p = anova1(A, groups, 'off');
%     textBox(['p = ' num2str(p)],[], [0.5 1], 12);
    
    subplot(2,3,5); 
    for counter = 1:nSessions
    yData = [fpWindow_pooled3.FA_RT1.avg(counter) fpWindow_pooled3.FA_RT2.avg(counter) fpWindow_pooled3.FA_RT3.avg(counter)];
    bData = [fpWindow_pooled3.FA_RT1.SEM(counter) fpWindow_pooled3.FA_RT2.SEM(counter) fpWindow_pooled3.FA_RT3.SEM(counter)];
    plot([1 2 3], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 3.5], 'YLim', ylim1, 'XTick', [1 2 3], 'XTickLabel', {'RT1', 'RT2', 'RT3'}, 'YTick', yTick1); 
    hold on;
    end
    yData = [nanmean(fpWindow_pooled3.FA_RT1.avg) nanmean(fpWindow_pooled3.FA_RT2.avg) nanmean(fpWindow_pooled3.FA_RT3.avg)];
    bData = [nanSEM(fpWindow_pooled3.FA_RT1.avg) nanSEM(fpWindow_pooled3.FA_RT2.avg) nanSEM(fpWindow_pooled3.FA_RT3.avg)];
    errorbar([1 2 3], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
     A = [fpWindow_pooled3.FA_RT1.avg fpWindow_pooled3.FA_RT2.avg fpWindow_pooled3.FA_RT3.avg];
    groups = {'RT1', 'RT2', 'RT3'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    subplot(2,3,6); 
    for counter = 1:nSessions
    yData = [fpWindow_pooled3_norm.FA_RT1.avg(counter) fpWindow_pooled3_norm.FA_RT2.avg(counter) fpWindow_pooled3_norm.FA_RT3.avg(counter)];
    bData = [fpWindow_pooled3_norm.FA_RT1.SEM(counter) fpWindow_pooled3_norm.FA_RT2.SEM(counter) fpWindow_pooled3_norm.FA_RT3.SEM(counter)];
    plot([1 2 3], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 3.5], 'YLim', ylim2, 'XTick', [1 2 3], 'XTickLabel', {'RT1', 'RT2', 'RT3'}, 'YTick', yTick2); 
    hold on;
    end
    yData = [nanmean(fpWindow_pooled3_norm.FA_RT1.avg) nanmean(fpWindow_pooled3_norm.FA_RT2.avg) nanmean(fpWindow_pooled3_norm.FA_RT3.avg)];
    bData = [nanSEM(fpWindow_pooled3_norm.FA_RT1.avg) nanSEM(fpWindow_pooled3_norm.FA_RT2.avg) nanSEM(fpWindow_pooled3_norm.FA_RT3.avg)];
    errorbar([1 2 3], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    A = [fpWindow_pooled3_norm.FA_RT1.avg fpWindow_pooled3_norm.FA_RT2.avg fpWindow_pooled3_norm.FA_RT3.avg];
    groups = {'RT1', 'RT2', 'RT3'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);
%     formatFigurePublish('size', figSize);

    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end

% preCue bar plot 3 RTs
    saveName = ['preCue_barPlot_RT3_ch' num2str(channel)];
    ensureFigure(saveName, 1);
    load(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled3_ch' num2str(channel) '.mat']), 'csWindow0_pooled3');
    load(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled3_norm_ch' num2str(channel) '.mat']), 'csWindow0_pooled3_norm'); 
    % linecolors = [mycolors('gr1'); mycolors('gr2'); mycolors('gr3'); mycolors('gr4')];
    figSize = [4 4];
    yTick1 = [-0.8 -0.6 -0.4 -0.2 0 0.2 0.4 0.6 0.8 1.0];
    yTick2 = [-1 0 1 2 3 4 5];
    ylim1 = [-0.5 0.5];
    ylim2 = [-3 3]; 
    subplot(2,3,1); 
    yData = [nanmean(csWindow0_pooled3.Hit_RT1.all) nanmean(csWindow0_pooled3.Hit_RT2.all) nanmean(csWindow0_pooled3.Hit_RT3.all)];
    bData = [nanSEM(csWindow0_pooled3.Hit_RT1.all) nanSEM(csWindow0_pooled3.Hit_RT2.all) nanSEM(csWindow0_pooled3.Hit_RT3.all)];
    errorbar([1 2 3], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
%     A = [csWindow0_pooled3.Hit_RT1.all csWindow0_pooled3.Hit_RT2.all csWindow0_pooled3.Hit_RT3.all];
%     groups = {'RT1', 'RT2', 'RT3'};
%     p = anova1(A, groups, 'off');
%     textBox(['p = ' num2str(p)],[], [0.5 1], 12);
    
    subplot(2,3,2); 
    for counter = 1:nSessions
    yData = [csWindow0_pooled3.Hit_RT1.avg(counter) csWindow0_pooled3.Hit_RT2.avg(counter) csWindow0_pooled3.Hit_RT3.avg(counter)];
    bData = [csWindow0_pooled3.Hit_RT1.SEM(counter) csWindow0_pooled3.Hit_RT2.SEM(counter) csWindow0_pooled3.Hit_RT3.SEM(counter)];
    plot([1 2 3], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 3.5], 'YLim', ylim1, 'XTick', [1 2 3], 'XTickLabel', {'RT1', 'RT2', 'RT3'}, 'YTick', yTick1); 
    hold on;
    end
    yData = [nanmean(csWindow0_pooled3.Hit_RT1.avg) nanmean(csWindow0_pooled3.Hit_RT2.avg) nanmean(csWindow0_pooled3.Hit_RT3.avg)];
    bData = [nanSEM(csWindow0_pooled3.Hit_RT1.avg) nanSEM(csWindow0_pooled3.Hit_RT2.avg) nanSEM(csWindow0_pooled3.Hit_RT3.avg)];
    errorbar([1 2 3], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    A = [csWindow0_pooled3.Hit_RT1.avg csWindow0_pooled3.Hit_RT2.avg csWindow0_pooled3.Hit_RT3.avg];
    groups = {'RT1', 'RT2', 'RT3'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    subplot(2,3,3); 
    for counter = 1:nSessions
    yData = [csWindow0_pooled3_norm.Hit_RT1.avg(counter) csWindow0_pooled3_norm.Hit_RT2.avg(counter) csWindow0_pooled3_norm.Hit_RT3.avg(counter)];
    bData = [csWindow0_pooled3_norm.Hit_RT1.SEM(counter) csWindow0_pooled3_norm.Hit_RT2.SEM(counter) csWindow0_pooled3_norm.Hit_RT3.SEM(counter)];
    plot([1 2 3], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 3.5], 'YLim', ylim2, 'XTick', [1 2 3], 'XTickLabel', {'RT1', 'RT2', 'RT3'}, 'YTick', yTick2); 
    hold on;
    end
    yData = [nanmean(csWindow0_pooled3_norm.Hit_RT1.avg) nanmean(csWindow0_pooled3_norm.Hit_RT2.avg) nanmean(csWindow0_pooled3_norm.Hit_RT3.avg)];
    bData = [nanSEM(csWindow0_pooled3_norm.Hit_RT1.avg) nanSEM(csWindow0_pooled3_norm.Hit_RT2.avg) nanSEM(csWindow0_pooled3_norm.Hit_RT3.avg)];
    errorbar([1 2 3], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    A = [csWindow0_pooled3_norm.Hit_RT1.avg csWindow0_pooled3_norm.Hit_RT2.avg csWindow0_pooled3_norm.Hit_RT3.avg];
    groups = {'RT1', 'RT2', 'RT3'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12); title('norm to RT1');

    subplot(2,3,4); 
    yData = [nanmean(csWindow0_pooled3.FA_RT1.all) nanmean(csWindow0_pooled3.FA_RT2.all) nanmean(csWindow0_pooled3.FA_RT3.all)];
    bData = [nanSEM(csWindow0_pooled3.FA_RT1.all) nanSEM(csWindow0_pooled3.FA_RT2.all) nanSEM(csWindow0_pooled3.FA_RT3.all)];
    errorbar([1 2 3], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
%     A = [csWindow0_pooled3.FA_RT1.all csWindow0_pooled3.FA_RT2.all csWindow0_pooled3.FA_RT3.all];
%     groups = {'RT1', 'RT2', 'RT3'};
%     p = anova1(A, groups, 'off');
%     textBox(['p = ' num2str(p)],[], [0.5 1], 12);
    
    subplot(2,3,5); 
    for counter = 1:nSessions
    yData = [csWindow0_pooled3.FA_RT1.avg(counter) csWindow0_pooled3.FA_RT2.avg(counter) csWindow0_pooled3.FA_RT3.avg(counter)];
    bData = [csWindow0_pooled3.FA_RT1.SEM(counter) csWindow0_pooled3.FA_RT2.SEM(counter) csWindow0_pooled3.FA_RT3.SEM(counter)];
    plot([1 2 3], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 3.5], 'YLim', ylim1, 'XTick', [1 2 3], 'XTickLabel', {'RT1', 'RT2', 'RT3'}, 'YTick', yTick1); 
    hold on;
    end
    yData = [nanmean(csWindow0_pooled3.FA_RT1.avg) nanmean(csWindow0_pooled3.FA_RT2.avg) nanmean(csWindow0_pooled3.FA_RT3.avg)];
    bData = [nanSEM(csWindow0_pooled3.FA_RT1.avg) nanSEM(csWindow0_pooled3.FA_RT2.avg) nanSEM(csWindow0_pooled3.FA_RT3.avg)];
    errorbar([1 2 3], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    A = [csWindow0_pooled3.FA_RT1.avg csWindow0_pooled3.FA_RT2.avg csWindow0_pooled3.FA_RT3.avg];
    groups = {'RT1', 'RT2', 'RT3'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    subplot(2,3,6); 
    for counter = 1:nSessions
    yData = [csWindow0_pooled3_norm.FA_RT1.avg(counter) csWindow0_pooled3_norm.FA_RT2.avg(counter) csWindow0_pooled3_norm.FA_RT3.avg(counter)];
    bData = [csWindow0_pooled3_norm.FA_RT1.SEM(counter) csWindow0_pooled3_norm.FA_RT2.SEM(counter) csWindow0_pooled3_norm.FA_RT3.SEM(counter)];
    plot([1 2 3], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 3.5], 'YLim', ylim2, 'XTick', [1 2 3], 'XTickLabel', {'RT1', 'RT2', 'RT3'}, 'YTick', yTick2); 
    hold on;
    end
    yData = [nanmean(csWindow0_pooled3_norm.FA_RT1.avg) nanmean(csWindow0_pooled3_norm.FA_RT2.avg) nanmean(csWindow0_pooled3_norm.FA_RT3.avg)];
    bData = [nanSEM(csWindow0_pooled3_norm.FA_RT1.avg) nanSEM(csWindow0_pooled3_norm.FA_RT2.avg) nanSEM(csWindow0_pooled3_norm.FA_RT3.avg)];
    errorbar([1 2 3], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    A = [csWindow0_pooled3_norm.FA_RT1.avg csWindow0_pooled3_norm.FA_RT2.avg csWindow0_pooled3_norm.FA_RT3.avg];
    groups = {'RT1', 'RT2', 'RT3'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
end 
%% foreperiod bar plot 4 RTs
for channel = TE.Photometry.settings.channels
     s2 = struct(...
        'all', [],...
        'data', cell(1,1),...
        'avg', zeros(nSessions, 1),...
        'SEM', zeros(nSessions, 1)...
        );
     fpWindow_pooled4 = struct(...
        'Hit_RT1', s2,...
        'Hit_RT2', s2,...
        'Hit_RT3', s2,...
        'Hit_RT4', s2,...
        'FA_RT1', s2,...
        'FA_RT2', s2,...
        'FA_RT3', s2,...
        'FA_RT4', s2...
        );
     csWindow0_pooled4 = struct(...
        'Hit_RT1', s2,...
        'Hit_RT2', s2,...
        'Hit_RT3', s2,...
        'Hit_RT4', s2,...
        'FA_RT1', s2,...
        'FA_RT2', s2,...
        'FA_RT3', s2,...
        'FA_RT4', s2...
        );
     fpWindow_pooled4_norm = struct(...
        'Hit_RT1', s2,...
        'Hit_RT2', s2,...
        'Hit_RT3', s2,...
        'Hit_RT4', s2,...
        'FA_RT1', s2,...
        'FA_RT2', s2,...
        'FA_RT3', s2,...
        'FA_RT4', s2...
        );
     csWindow0_pooled4_norm = struct(...
        'Hit_RT1', s2,...
        'Hit_RT2', s2,...
        'Hit_RT3', s2,...
        'Hit_RT4', s2,...
        'FA_RT1', s2,...
        'FA_RT2', s2,...
        'FA_RT3', s2,...
        'FA_RT4', s2...
        );
    for counter = 1:nSessions 
         HitTrialsThisSession = find(hitFastestTrials & (TE.sessionIndex == counter));
        [sorted,Ix] = sort (TE.RT (HitTrialsThisSession)); 
        HitTrialsThisSession = HitTrialsThisSession(Ix);
        m = length(HitTrialsThisSession);
        if mod(m, 2) == 0 
            FastHitTrials_temp = HitTrialsThisSession (1: m/2);
            SlowHitTrials_temp = HitTrialsThisSession (m/2+1:end);
        else
            FastHitTrials_temp = HitTrialsThisSession (1: (m-1)/2);
            SlowHitTrials_temp = HitTrialsThisSession ((m+1)/2:end);
        end
        n = length (FastHitTrials_temp);
        if mod (n,2) == 0
            Hit_RT1_temp = FastHitTrials_temp (1: n/2);
            Hit_RT2_temp = FastHitTrials_temp (n/2+1: end);
        else
            Hit_RT1_temp = FastHitTrials_temp (1: (n-1)/2);
            Hit_RT2_temp = FastHitTrials_temp ((n+1)/2: end);
        end

        n = length (SlowHitTrials_temp);
        if mod (n,2) == 0
            Hit_RT3_temp = SlowHitTrials_temp (1: n/2);
            Hit_RT4_temp = SlowHitTrials_temp (n/2+1: end);
        else
            Hit_RT3_temp = SlowHitTrials_temp (1: (n-1)/2);
            Hit_RT4_temp = SlowHitTrials_temp ((n+1)/2: end);
        end
        
        FATrialsThisSession = find(FAFastestTrials & (TE.sessionIndex == counter));
        [sorted,Ix] = sort (TE.RT (FATrialsThisSession)); 
        FATrialsThisSession = FATrialsThisSession(Ix);
        m = length(FATrialsThisSession);
        if mod(m, 2) == 0 
            FastFATrials_temp = FATrialsThisSession (1: m/2);
            SlowFATrials_temp = FATrialsThisSession (m/2+1:end);
        else
            FastFATrials_temp = FATrialsThisSession (1: (m-1)/2);
            SlowFATrials_temp = FATrialsThisSession ((m+1)/2:end);
        end 
        n = length (FastFATrials_temp);
        if mod (n,2) == 0
            FA_RT1_temp = FastFATrials_temp (1: n/2);
            FA_RT2_temp = FastFATrials_temp (n/2+1: end);
        else
            FA_RT1_temp = FastFATrials_temp (1: (n-1)/2);
            FA_RT2_temp = FastFATrials_temp ((n+1)/2: end);
        end

        n = length (SlowFATrials_temp);
        if mod (n,2) == 0
            FA_RT3_temp = SlowFATrials_temp (1: n/2);
            FA_RT4_temp = SlowFATrials_temp (n/2+1: end);
        else
            FA_RT3_temp = SlowFATrials_temp (1: (n-1)/2);
            FA_RT4_temp = SlowFATrials_temp ((n+1)/2: end);
        end

        ordering = {...
            'Hit_RT1', Hit_RT1_temp;...
            'Hit_RT2', Hit_RT2_temp;... 
            'Hit_RT3', Hit_RT3_temp;...
            'Hit_RT4', Hit_RT4_temp;...
            'FA_RT1', FA_RT1_temp;...
            'FA_RT2', FA_RT2_temp;...
            'FA_RT3', FA_RT3_temp;...
            'FA_RT4', FA_RT4_temp;...    
            };

            for c2 = 1:size(ordering,1)
                thisData = TE.phPeakMean_fpWindow(channel).data(ordering{c2, 2});
                fpWindow_pooled4.(ordering{c2,1}).data{counter,:} = thisData;
                fpWindow_pooled4.(ordering{c2,1}).avg(counter,:) = nanmean(thisData);
                fpWindow_pooled4.(ordering{c2,1}).SEM(counter,:) = nanSEM(thisData); 
                fpWindow_pooled4.(ordering{c2,1}).all = [fpWindow_pooled4.(ordering{c2,1}).all; thisData];
            end  
            
            for c2 = 1:size(ordering,1)          
                thisData = TE.phPeakMean_csWindow0(channel).data(ordering{c2, 2});
                csWindow0_pooled4.(ordering{c2,1}).data{counter,:} = thisData;
                csWindow0_pooled4.(ordering{c2,1}).avg(counter,:) = nanmean(thisData);
                csWindow0_pooled4.(ordering{c2,1}).SEM(counter,:) = nanSEM(thisData);
                csWindow0_pooled4.(ordering{c2,1}).all = [csWindow0_pooled4.(ordering{c2,1}).all; thisData];
            end
            ordering = {...
                    'Hit_RT1', Hit_RT1_temp;...
                    'Hit_RT2', Hit_RT2_temp;... 
                    'Hit_RT3', Hit_RT3_temp;...
                    'Hit_RT4', Hit_RT4_temp;...    
                    };
                for c3 = 1:size(ordering,1)
                    thisData = (fpWindow_pooled4.(ordering{c3,1}).data{counter,:} - fpWindow_pooled4.Hit_RT1.avg(counter,:)) / abs(fpWindow_pooled4.Hit_RT1.avg(counter,:)) +1;
                    fpWindow_pooled4_norm.(ordering{c3,1}).data{counter,:} = thisData;
                    fpWindow_pooled4_norm.(ordering{c3,1}).avg(counter,:) = nanmean(thisData);
                    fpWindow_pooled4_norm.(ordering{c3,1}).SEM(counter,:) = nanSEM(thisData); 
                    fpWindow_pooled4_norm.(ordering{c3,1}).all = [fpWindow_pooled4_norm.(ordering{c3,1}).all; thisData];

                    thisData = (csWindow0_pooled4.(ordering{c3,1}).data{counter,:} - csWindow0_pooled4.Hit_RT1.avg(counter,:)) / abs(csWindow0_pooled4.Hit_RT1.avg(counter,:)) +1;
                    csWindow0_pooled4_norm.(ordering{c3,1}).data{counter,:} = thisData;
                    csWindow0_pooled4_norm.(ordering{c3,1}).avg(counter,:) = nanmean(thisData);
                    csWindow0_pooled4_norm.(ordering{c3,1}).SEM(counter,:) = nanSEM(thisData);  
                    csWindow0_pooled4_norm.(ordering{c3,1}).all = [csWindow0_pooled4_norm.(ordering{c3,1}).all; thisData];
                end 
            ordering = {...
                'FA_RT1', FA_RT1_temp;...
                'FA_RT2', FA_RT2_temp;...
                'FA_RT3', FA_RT3_temp;...
                'FA_RT4', FA_RT4_temp;...    
                };
                for c4 = 1:size(ordering,1)
                    thisData = (fpWindow_pooled4.(ordering{c4,1}).data{counter,:} - fpWindow_pooled4.FA_RT1.avg(counter,:)) / abs(fpWindow_pooled4.FA_RT1.avg(counter,:)) +1;
                    fpWindow_pooled4_norm.(ordering{c4,1}).data{counter,:} = thisData;
                    fpWindow_pooled4_norm.(ordering{c4,1}).avg(counter,:) = nanmean(thisData);
                    fpWindow_pooled4_norm.(ordering{c4,1}).SEM(counter,:) = nanSEM(thisData); 
                    fpWindow_pooled4_norm.(ordering{c4,1}).all = [fpWindow_pooled4_norm.(ordering{c4,1}).all; thisData];

                    thisData = (csWindow0_pooled4.(ordering{c4,1}).data{counter,:} - csWindow0_pooled4.FA_RT1.avg(counter,:)) / abs(csWindow0_pooled4.FA_RT1.avg(counter,:)) +1;
                    csWindow0_pooled4_norm.(ordering{c4,1}).data{counter,:} = thisData;
                    csWindow0_pooled4_norm.(ordering{c4,1}).avg(counter,:) = nanmean(thisData);
                    csWindow0_pooled4_norm.(ordering{c4,1}).SEM(counter,:) = nanSEM(thisData);  
                    csWindow0_pooled4_norm.(ordering{c4,1}).all = [csWindow0_pooled4_norm.(ordering{c4,1}).all; thisData];
                end 
    end
    
    if saveOn
        save(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled4_ch' num2str(channel) '.mat']), 'fpWindow_pooled4');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled3_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled4_norm_ch' num2str(channel) '.mat']), 'fpWindow_pooled4_norm');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled3_norm_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled4_ch' num2str(channel) '.mat']), 'csWindow0_pooled4');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled3_ch' num2str(channel) '.mat']) ' ***']);
        save(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled4_norm_ch' num2str(channel) '.mat']), 'csWindow0_pooled4_norm');
%         disp(['*** saving: ' fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled3_norm_ch' num2str(channel) '.mat']) ' ***']);
    end
end

for channel = TE.Photometry.settings.channels
  % foreperiod bar plot 4 RTs    
    saveName = ['foreperiod_barPlot_RT4_ch' num2str(channel)];
    ensureFigure(saveName, 1);
    load(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled4_ch' num2str(channel) '.mat']), 'fpWindow_pooled4');
    load(fullfile(savepath, ['summary_' subjectName '_fpWindow_pooled4_norm_ch' num2str(channel) '.mat']), 'fpWindow_pooled4_norm'); 
    figSize = [4 4];
    yTick1 = [-0.8 -0.6 -0.4 -0.2 0 0.2 0.4 0.6 0.8 1.0];
    yTick2 = [-1 0 1 2 3 4 5];
    ylim1 = [-0.5 0.5];
    ylim2 = [-3 3];  
    subplot(2,3,1); 
    yData = [nanmean(fpWindow_pooled4.Hit_RT1.all) nanmean(fpWindow_pooled4.Hit_RT2.all) nanmean(fpWindow_pooled4.Hit_RT3.all)  nanmean(fpWindow_pooled4.Hit_RT4.all)];
    bData = [nanSEM(fpWindow_pooled4.Hit_RT1.all) nanSEM(fpWindow_pooled4.Hit_RT2.all) nanSEM(fpWindow_pooled4.Hit_RT3.all)  nanSEM(fpWindow_pooled4.Hit_RT4.all)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
        
    subplot(2,3,2); 
    for counter = 1:nSessions
    yData = [fpWindow_pooled4.Hit_RT1.avg(counter) fpWindow_pooled4.Hit_RT2.avg(counter) fpWindow_pooled4.Hit_RT3.avg(counter)  fpWindow_pooled4.Hit_RT4.avg(counter)];
    bData = [fpWindow_pooled4.Hit_RT1.SEM(counter) fpWindow_pooled4.Hit_RT2.SEM(counter) fpWindow_pooled4.Hit_RT3.SEM(counter)  fpWindow_pooled4.Hit_RT4.SEM(counter)];
    plot([1 2 3 4], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 4.5], 'YLim', ylim1, 'XTick', [1 2 3 4], 'XTickLabel', {'RT1', 'RT2', 'RT3', 'RT4'}, 'YTick', yTick1); 
    hold on;
    end
    yData = [nanmean(fpWindow_pooled4.Hit_RT1.avg) nanmean(fpWindow_pooled4.Hit_RT2.avg) nanmean(fpWindow_pooled4.Hit_RT3.avg)  nanmean(fpWindow_pooled4.Hit_RT4.avg)];
    bData = [nanSEM(fpWindow_pooled4.Hit_RT1.avg) nanSEM(fpWindow_pooled4.Hit_RT2.avg) nanSEM(fpWindow_pooled4.Hit_RT3.avg)  nanSEM(fpWindow_pooled4.Hit_RT4.avg)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    A = [fpWindow_pooled4.Hit_RT1.avg fpWindow_pooled4.Hit_RT2.avg fpWindow_pooled4.Hit_RT3.avg fpWindow_pooled4.Hit_RT4.avg];
    groups = {'RT1', 'RT2', 'RT3', 'RT4'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    subplot(2,3,3); 
    for counter = 1:nSessions
    yData = [fpWindow_pooled4_norm.Hit_RT1.avg(counter) fpWindow_pooled4_norm.Hit_RT2.avg(counter) fpWindow_pooled4_norm.Hit_RT3.avg(counter)  fpWindow_pooled4_norm.Hit_RT4.avg(counter)];
    bData = [fpWindow_pooled4_norm.Hit_RT1.SEM(counter) fpWindow_pooled4_norm.Hit_RT2.SEM(counter) fpWindow_pooled4_norm.Hit_RT3.SEM(counter)  fpWindow_pooled4_norm.Hit_RT4.SEM(counter)];
    plot([1 2 3 4], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 4.5], 'YLim', ylim2, 'XTick', [1 2 3 4], 'XTickLabel', {'RT1', 'RT2', 'RT3', 'RT4'}, 'YTick', yTick2); 
    hold on;
    end
    yData = [nanmean(fpWindow_pooled4_norm.Hit_RT1.avg) nanmean(fpWindow_pooled4_norm.Hit_RT2.avg) nanmean(fpWindow_pooled4_norm.Hit_RT3.avg)  nanmean(fpWindow_pooled4_norm.Hit_RT4.avg)];
    bData = [nanSEM(fpWindow_pooled4_norm.Hit_RT1.avg) nanSEM(fpWindow_pooled4_norm.Hit_RT2.avg) nanSEM(fpWindow_pooled4_norm.Hit_RT3.avg)  nanSEM(fpWindow_pooled4_norm.Hit_RT4.avg)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    A = [fpWindow_pooled4_norm.Hit_RT1.avg fpWindow_pooled4_norm.Hit_RT2.avg fpWindow_pooled4_norm.Hit_RT3.avg fpWindow_pooled4_norm.Hit_RT4.avg];
    groups = {'RT1', 'RT2', 'RT3', 'RT4'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);
    
    subplot(2,3,4); 
    yData = [nanmean(fpWindow_pooled4.FA_RT1.all) nanmean(fpWindow_pooled4.FA_RT2.all) nanmean(fpWindow_pooled4.FA_RT3.all)  nanmean(fpWindow_pooled4.FA_RT4.all)];
    bData = [nanSEM(fpWindow_pooled4.FA_RT1.all) nanSEM(fpWindow_pooled4.FA_RT2.all) nanSEM(fpWindow_pooled4.FA_RT3.all)  nanSEM(fpWindow_pooled4.FA_RT4.all)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    
    subplot(2,3,5); 
    for counter = 1:nSessions
    yData = [fpWindow_pooled4.FA_RT1.avg(counter) fpWindow_pooled4.FA_RT2.avg(counter) fpWindow_pooled4.FA_RT3.avg(counter)  fpWindow_pooled4.FA_RT4.avg(counter)];
    bData = [fpWindow_pooled4.FA_RT1.SEM(counter) fpWindow_pooled4.FA_RT2.SEM(counter) fpWindow_pooled4.FA_RT3.SEM(counter)  fpWindow_pooled4.FA_RT4.SEM(counter)];
    plot([1 2 3 4], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 4.5], 'YLim', ylim1, 'XTick', [1 2 3 4], 'XTickLabel', {'RT1', 'RT2', 'RT3', 'RT4'}, 'YTick', yTick1); 
    hold on;
    end
    yData = [nanmean(fpWindow_pooled4.FA_RT1.avg) nanmean(fpWindow_pooled4.FA_RT2.avg) nanmean(fpWindow_pooled4.FA_RT3.avg)  nanmean(fpWindow_pooled4.FA_RT4.avg)];
    bData = [nanSEM(fpWindow_pooled4.FA_RT1.avg) nanSEM(fpWindow_pooled4.FA_RT2.avg) nanSEM(fpWindow_pooled4.FA_RT3.avg)  nanSEM(fpWindow_pooled4.FA_RT4.avg)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    A = [fpWindow_pooled4.FA_RT1.avg fpWindow_pooled4.FA_RT2.avg fpWindow_pooled4.FA_RT3.avg fpWindow_pooled4.FA_RT4.avg];
    groups = {'RT1', 'RT2', 'RT3', 'RT4'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    subplot(2,3,6); 
    for counter = 1:nSessions
    yData = [fpWindow_pooled4_norm.FA_RT1.avg(counter) fpWindow_pooled4_norm.FA_RT2.avg(counter) fpWindow_pooled4_norm.FA_RT3.avg(counter)  fpWindow_pooled4_norm.FA_RT4.avg(counter)];
    bData = [fpWindow_pooled4_norm.FA_RT1.SEM(counter) fpWindow_pooled4_norm.FA_RT2.SEM(counter) fpWindow_pooled4_norm.FA_RT3.SEM(counter)  fpWindow_pooled4_norm.FA_RT4.SEM(counter)];
    plot([1 2 3 4], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 4.5], 'YLim', ylim2, 'XTick', [1 2 3 4], 'XTickLabel', {'RT1', 'RT2', 'RT3', 'RT4'}, 'YTick', yTick2); 
    hold on;
    end
    yData = [nanmean(fpWindow_pooled4_norm.FA_RT1.avg) nanmean(fpWindow_pooled4_norm.FA_RT2.avg) nanmean(fpWindow_pooled4_norm.FA_RT3.avg)  nanmean(fpWindow_pooled4_norm.FA_RT4.avg)];
    bData = [nanSEM(fpWindow_pooled4_norm.FA_RT1.avg) nanSEM(fpWindow_pooled4_norm.FA_RT2.avg) nanSEM(fpWindow_pooled4_norm.FA_RT3.avg)  nanSEM(fpWindow_pooled4_norm.FA_RT4.avg)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
     A = [fpWindow_pooled4_norm.FA_RT1.avg fpWindow_pooled4_norm.FA_RT2.avg fpWindow_pooled4_norm.FA_RT3.avg fpWindow_pooled4_norm.FA_RT4.avg];
    groups = {'RT1', 'RT2', 'RT3', 'RT4'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);
%     set(gcf,'toolbar','figure');
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end

% preCue bar plot 4 RTs
    saveName = ['preCue_barPlot_RT4_ch' num2str(channel)];
    ensureFigure(saveName, 1);
    load(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled4_ch' num2str(channel) '.mat']), 'csWindow0_pooled4');
    load(fullfile(savepath, ['summary_' subjectName '_csWindow0_pooled4_norm_ch' num2str(channel) '.mat']), 'csWindow0_pooled4_norm'); 
    figSize = [4 4];
    yTick1 = [-0.8 -0.6 -0.4 -0.2 0 0.2 0.4 0.6 0.8 1.0];
    yTick2 = [-1 0 1 2 3 4 5];
     ylim1 = [-0.5 0.5];
    ylim2 = [-3 3]; 
    subplot(2,3,1); 
    yData = [nanmean(csWindow0_pooled4.Hit_RT1.all) nanmean(csWindow0_pooled4.Hit_RT2.all) nanmean(csWindow0_pooled4.Hit_RT3.all)  nanmean(csWindow0_pooled4.Hit_RT4.all)];
    bData = [nanSEM(csWindow0_pooled4.Hit_RT1.all) nanSEM(csWindow0_pooled4.Hit_RT2.all) nanSEM(csWindow0_pooled4.Hit_RT3.all)  nanSEM(csWindow0_pooled4.Hit_RT4.all)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    
    subplot(2,3,2); 
    for counter = 1:nSessions
    yData = [csWindow0_pooled4.Hit_RT1.avg(counter) csWindow0_pooled4.Hit_RT2.avg(counter) csWindow0_pooled4.Hit_RT3.avg(counter)  csWindow0_pooled4.Hit_RT4.avg(counter)];
    bData = [csWindow0_pooled4.Hit_RT1.SEM(counter) csWindow0_pooled4.Hit_RT2.SEM(counter) csWindow0_pooled4.Hit_RT3.SEM(counter)  csWindow0_pooled4.Hit_RT4.SEM(counter)];
    plot([1 2 3 4], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 4.5], 'YLim', ylim1, 'XTick', [1 2 3 4], 'XTickLabel', {'RT1', 'RT2', 'RT3', 'RT4'}, 'YTick', yTick1); 
    hold on;
    end
    yData = [nanmean(csWindow0_pooled4.Hit_RT1.avg) nanmean(csWindow0_pooled4.Hit_RT2.avg) nanmean(csWindow0_pooled4.Hit_RT3.avg)  nanmean(csWindow0_pooled4.Hit_RT4.avg)];
    bData = [nanSEM(csWindow0_pooled4.Hit_RT1.avg) nanSEM(csWindow0_pooled4.Hit_RT2.avg) nanSEM(csWindow0_pooled4.Hit_RT3.avg)  nanSEM(csWindow0_pooled4.Hit_RT4.avg)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    A = [csWindow0_pooled4.Hit_RT1.avg csWindow0_pooled4.Hit_RT2.avg csWindow0_pooled4.Hit_RT3.avg csWindow0_pooled4.Hit_RT4.avg];
    groups = {'RT1', 'RT2', 'RT3', 'RT4'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    subplot(2,3,3); 
    for counter = 1:nSessions
    yData = [csWindow0_pooled4_norm.Hit_RT1.avg(counter) csWindow0_pooled4_norm.Hit_RT2.avg(counter) csWindow0_pooled4_norm.Hit_RT3.avg(counter)  csWindow0_pooled4_norm.Hit_RT4.avg(counter)];
    bData = [csWindow0_pooled4_norm.Hit_RT1.SEM(counter) csWindow0_pooled4_norm.Hit_RT2.SEM(counter) csWindow0_pooled4_norm.Hit_RT3.SEM(counter)  csWindow0_pooled4_norm.Hit_RT4.SEM(counter)];
    plot([1 2 3 4], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 4.5], 'YLim', ylim2, 'XTick', [1 2 3 4], 'XTickLabel', {'RT1', 'RT2', 'RT3', 'RT4'}, 'YTick', yTick2); 
    hold on;
    end
    yData = [nanmean(csWindow0_pooled4_norm.Hit_RT1.avg) nanmean(csWindow0_pooled4_norm.Hit_RT2.avg) nanmean(csWindow0_pooled4_norm.Hit_RT3.avg)  nanmean(csWindow0_pooled4_norm.Hit_RT4.avg)];
    bData = [nanSEM(csWindow0_pooled4_norm.Hit_RT1.avg) nanSEM(csWindow0_pooled4_norm.Hit_RT2.avg) nanSEM(csWindow0_pooled4_norm.Hit_RT3.avg)  nanSEM(csWindow0_pooled4_norm.Hit_RT4.avg)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [0/255 128/255 0/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[0/255 128/255 0/255],'MarkerFaceColor',[0/255 128/255 0/255]);
    A = [csWindow0_pooled4_norm.Hit_RT1.avg csWindow0_pooled4_norm.Hit_RT2.avg csWindow0_pooled4_norm.Hit_RT3.avg csWindow0_pooled4_norm.Hit_RT4.avg];
    groups = {'RT1', 'RT2', 'RT3', 'RT4'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);
 
    subplot(2,3,4); 
    yData = [nanmean(csWindow0_pooled4.FA_RT1.all) nanmean(csWindow0_pooled4.FA_RT2.all) nanmean(csWindow0_pooled4.FA_RT3.all)  nanmean(csWindow0_pooled4.FA_RT4.all)];
    bData = [nanSEM(csWindow0_pooled4.FA_RT1.all) nanSEM(csWindow0_pooled4.FA_RT2.all) nanSEM(csWindow0_pooled4.FA_RT3.all)  nanSEM(csWindow0_pooled4.FA_RT4.all)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    
    subplot(2,3,5); 
    for counter = 1:nSessions
    yData = [csWindow0_pooled4.FA_RT1.avg(counter) csWindow0_pooled4.FA_RT2.avg(counter) csWindow0_pooled4.FA_RT3.avg(counter)  csWindow0_pooled4.FA_RT4.avg(counter)];
    bData = [csWindow0_pooled4.FA_RT1.SEM(counter) csWindow0_pooled4.FA_RT2.SEM(counter) csWindow0_pooled4.FA_RT3.SEM(counter)  csWindow0_pooled4.FA_RT4.SEM(counter)];
    plot([1 2 3 4], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 4.5], 'YLim', ylim1, 'XTick', [1 2 3 4], 'XTickLabel', {'RT1', 'RT2', 'RT3', 'RT4'}, 'YTick', yTick1); 
    hold on;
    end
    yData = [nanmean(csWindow0_pooled4.FA_RT1.avg) nanmean(csWindow0_pooled4.FA_RT2.avg) nanmean(csWindow0_pooled4.FA_RT3.avg)  nanmean(csWindow0_pooled4.FA_RT4.avg)];
    bData = [nanSEM(csWindow0_pooled4.FA_RT1.avg) nanSEM(csWindow0_pooled4.FA_RT2.avg) nanSEM(csWindow0_pooled4.FA_RT3.avg)  nanSEM(csWindow0_pooled4.FA_RT4.avg)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
      A = [csWindow0_pooled4.FA_RT1.avg csWindow0_pooled4.FA_RT2.avg csWindow0_pooled4.FA_RT3.avg csWindow0_pooled4.FA_RT4.avg];
    groups = {'RT1', 'RT2', 'RT3', 'RT4'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);

    subplot(2,3,6); 
    for counter = 1:nSessions
    yData = [csWindow0_pooled4_norm.FA_RT1.avg(counter) csWindow0_pooled4_norm.FA_RT2.avg(counter) csWindow0_pooled4_norm.FA_RT3.avg(counter)  csWindow0_pooled4_norm.FA_RT4.avg(counter)];
    bData = [csWindow0_pooled4_norm.FA_RT1.SEM(counter) csWindow0_pooled4_norm.FA_RT2.SEM(counter) csWindow0_pooled4_norm.FA_RT3.SEM(counter)  csWindow0_pooled4_norm.FA_RT4.SEM(counter)];
    plot([1 2 3 4], yData, 'color', [179/255 179/255 179/255]);
    set(gca, 'XLim', [0.5 4.5], 'YLim', ylim2, 'XTick', [1 2 3 4], 'XTickLabel', {'RT1', 'RT2', 'RT3', 'RT4'}, 'YTick', yTick2); 
    hold on;
    end
    yData = [nanmean(csWindow0_pooled4_norm.FA_RT1.avg) nanmean(csWindow0_pooled4_norm.FA_RT2.avg) nanmean(csWindow0_pooled4_norm.FA_RT3.avg)  nanmean(csWindow0_pooled4_norm.FA_RT4.avg)];
    bData = [nanSEM(csWindow0_pooled4_norm.FA_RT1.avg) nanSEM(csWindow0_pooled4_norm.FA_RT2.avg) nanSEM(csWindow0_pooled4_norm.FA_RT3.avg)  nanSEM(csWindow0_pooled4_norm.FA_RT4.avg)];
    errorbar([1 2 3 4], yData, bData,'-o','color', [215/255 48/255 31/255], 'MarkerSize',10, 'LineWidth', 2,...
        'MarkerEdgeColor',[215/255 48/255 31/255],'MarkerFaceColor',[215/255 48/255 31/255]);
    A = [csWindow0_pooled4_norm.FA_RT1.avg csWindow0_pooled4_norm.FA_RT2.avg csWindow0_pooled4_norm.FA_RT3.avg csWindow0_pooled4_norm.FA_RT4.avg];
    groups = {'RT1', 'RT2', 'RT3', 'RT4'};
    p = anova1(A, groups, 'off');
    textBox(['p = ' num2str(p)],[], [0.5 1], 12);
%     set(gcf,'toolbar','figure');
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));  
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
end

%% ranked by hittrials in each session
 TE.RTpr_hit_pS = [];
for counter = 1:nSessions 
    pr = [];
    for i = 1:length(RT_pooled.hit.rt{counter, 1})
        pr(i) = percentileranking (RT_pooled.hit.rt{counter, 1}, RT_pooled.hit.rt{counter, 1}(i));
    end
    pr = pr';
    TE.RTpr_hit_pS = [TE.RTpr_hit_pS; pr];
    hitTrialsThisSession = find(hitTrials & (TE.sessionIndex == counter));
     for channel = channels  
        hitTrialsThisSession_Data.fpWindow_peakMean = TE.phPeakMean_fpWindow(channel).data(hitTrialsThisSession);
        hitTrialsThisSession_Data.fpWindow_peakPercentile = TE.phPeakPercentile_fpWindow(channel).data(hitTrialsThisSession);
        hitTrialsThisSession_Data.csWindow0_peakMean = TE.phPeakMean_csWindow0(channel).data(hitTrialsThisSession);
        hitTrialsThisSession_Data.csWindow0_peakPercentile = TE.phPeakPercentile_csWindow0(channel).data(hitTrialsThisSession);

        % Save peak data_hit trials_scatter plot
        saveName = [subjectName '_RTpr_hit_scatterplot_ch' num2str(channel) 'session' num2str(counter)];
        h=ensureFigure(saveName, 1);
        mcPortraitFigSetup(h);    

        subplot(2,2,1); 
        xData = pr;
        yData = hitTrialsThisSession_Data.fpWindow_peakMean;
        scatter(xData,yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2);
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
        xlabel('RTpr'); ylabel('phMean'); title('hitTrials foreperiod Mean'); 

        subplot(2,2,2); 
        yData = hitTrialsThisSession_Data.fpWindow_peakPercentile;
        scatter(xData,yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2);
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
        xlabel('RTpr'); ylabel('phMean'); title('hitTrials foreperiod Percentile0.9'); 


        subplot(2,2,3); 
        yData = hitTrialsThisSession_Data.csWindow0_peakMean;
        scatter(xData,yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2);
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
        xlabel('RTpr'); ylabel('phMean'); title('hitTrials (-0.4 0) from cue Mean'); 

        subplot(2,2,4); 
        yData = hitTrialsThisSession_Data.csWindow0_peakPercentile;
        scatter(xData,yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2);
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
        xlabel('RTpr'); ylabel('phMean'); title('hitTrials (-0.4 0) from cue Percentile0.9'); 

        if saveOn
            saveas(gcf, fullfile(savepath, [saveName '.fig']));
            saveas(gcf, fullfile(savepath, [saveName '.jpg']));
            print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
        end
     end
end
 
 %% percentile ranking hitTrials scatter plot _pooled_ranked by each Session
% TE.RTpr_hit_pS = [];
% for counter = 1:nSessions    
%     pr = [];
%     for i = 1:length(RT_pooled.hit.rt{1, counter})
%         pr(i) = percentileranking (RT_pooled.hit.rt{1, counter}, RT_pooled.hit.rt{1, counter}(i));
%     end
%     pr = pr';
%     TE.RTpr_hit_pS = [TE.RTpr_hit_pS; pr];
% end
 for channel = TE.Photometry.settings.channels  
    hitTrials_Data.fpWindow_peakMean = TE.phPeakMean_fpWindow(channel).data(hitTrials);
    hitTrials_Data.fpWindow_peakPercentile = TE.phPeakPercentile_fpWindow(channel).data(hitTrials);
    hitTrials_Data.csWindow0_peakMean = TE.phPeakMean_csWindow0(channel).data(hitTrials);
    hitTrials_Data.csWindow0_peakPercentile = TE.phPeakPercentile_csWindow0(channel).data(hitTrials);
    hitTrials_Data.csWindow1_peakMean = TE.phPeakMean_csWindow1(channel).data(hitTrials);
    hitTrials_Data.csWindow1_peakPercentile = TE.phPeakPercentile_csWindow1(channel).data(hitTrials);
    hitTrials_Data.csWindow2_peakMean = TE.phPeakMean_csWindow2(channel).data(hitTrials);
    hitTrials_Data.csWindow2_peakPercentile = TE.phPeakPercentile_csWindow2(channel).data(hitTrials); 
    hitTrials_Data.csWindow3_peakMean = TE.phPeakMean_csWindow3(channel).data(hitTrials);
    hitTrials_Data.csWindow3_peakPercentile = TE.phPeakPercentile_csWindow3(channel).data(hitTrials); 
    hitTrials_Data.usWindow2_peakMean = TE.phPeakMean_usWindow2(channel).data(hitTrials);
    hitTrials_Data.usWindow2_peakPercentile = TE.phPeakPercentile_usWindow2(channel).data(hitTrials);     
    hitTrials_Data.usWindow1_peakMean = TE.phPeakMean_usWindow1(channel).data(hitTrials);
    hitTrials_Data.usWindow1_peakPercentile = TE.phPeakPercentile_usWindow1(channel).data(hitTrials);  
    hitTrials_Data.usWindow3_peakMean = TE.phPeakMean_usWindow3(channel).data(hitTrials);
    hitTrials_Data.usWindow3_peakPercentile = TE.phPeakPercentile_usWindow3(channel).data(hitTrials); 
    
    % Save peak data_hit trials_scatter plot
    saveName = [subjectName '_RTpr_bySession_hit_scatterplot_ch' num2str(channel)];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);    

    subplot(4,2,1); 
    xData = TE.RTpr_hit_pS;
    yData = hitTrials_Data.fpWindow_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean'); title('hitTrials foreperiod Mean'); 
   
    subplot(4,2,2); 
    yData = hitTrials_Data.fpWindow_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean'); title('hitTrials foreperiod Percentile0.9'); 
    
    
    subplot(4,2,3); 
    yData = hitTrials_Data.csWindow0_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean'); title('hitTrials (-0.4 0) from cue Mean'); 
   
    subplot(4,2,4); 
    yData = hitTrials_Data.csWindow0_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean'); title('hitTrials (-0.4 0) from cue Percentile0.9'); 
      
    subplot(4,2,5); 
    yData = hitTrials_Data.csWindow3_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean'); title('hitTrials from cue to anslick Mean'); 

    subplot(4,2,6); 
    yData = hitTrials_Data.csWindow3_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean'); title('hitTrials from cue to anslick Percentile0.9'); 
       
    subplot(4,2,7); 
    yData = hitTrials_Data.usWindow3_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean'); title('hitTrials from cue to US Mean'); 

    subplot(4,2,8); 
    yData = hitTrials_Data.usWindow3_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean'); title('hitTrials from cue to US Percentile0.9'); 
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
 end


%% ranked by FAtrials in each session
 TE.RTpr_FA_pS = [];
%  FATrials = filterTE(TE, 'SoundValveIndex', 2, 'LickAction', 'lick', 'reject', 0) & ~badTrials;
for counter = 1:nSessions    
    pr = [];
    for i = 1:length(RT_pooled.FA.rt{counter, 1})
        pr(i) = percentileranking (RT_pooled.FA.rt{counter, 1}, RT_pooled.FA.rt{counter, 1}(i));
    end
    pr = pr';
    TE.RTpr_FA_pS = [TE.RTpr_FA_pS; pr];
    FATrialsThisSession = find(FAFastestTrials & (TE.sessionIndex == counter));
     for channel = channels  
        FATrialsThisSession_Data.fpWindow_peakMean = TE.phPeakMean_fpWindow(channel).data(FATrialsThisSession);
        FATrialsThisSession_Data.fpWindow_peakPercentile = TE.phPeakPercentile_fpWindow(channel).data(FATrialsThisSession);
        FATrialsThisSession_Data.csWindow0_peakMean = TE.phPeakMean_csWindow0(channel).data(FATrialsThisSession);
        FATrialsThisSession_Data.csWindow0_peakPercentile = TE.phPeakPercentile_csWindow0(channel).data(FATrialsThisSession);

        % Save peak data_FA trials_scatter plot
        saveName = [subjectName '_RTpr_FA_scatterplot_ch' num2str(channel) 'session' num2str(counter)];
        h=ensureFigure(saveName, 1);
        mcPortraitFigSetup(h);    

        subplot(2,2,1); 
        xData = pr;
        yData = FATrialsThisSession_Data.fpWindow_peakMean;
        scatter(xData,yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2);
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
        xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials foreperiod Mean'); 

        subplot(2,2,2); 
        yData = FATrialsThisSession_Data.fpWindow_peakPercentile;
        scatter(xData,yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2);
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
        xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials foreperiod Percentile0.9'); 


        subplot(2,2,3); 
        yData = FATrialsThisSession_Data.csWindow0_peakMean;
        scatter(xData,yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2);
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
        xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials (-0.4 0) from cue Mean'); 

        subplot(2,2,4); 
        yData = FATrialsThisSession_Data.csWindow0_peakPercentile;
        scatter(xData,yData); hold on;
        fo = fitoptions('poly1');
        fob = fit(xData, yData, 'poly1', fo); 
        fph=plot(fob,'predfunc'); legend off;
        set(fph, 'LineWidth', 2);
        [rho, pval]= corr(xData, yData);
        textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
        textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
        xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials (-0.4 0) from cue Percentile0.9'); 

        if saveOn
            saveas(gcf, fullfile(savepath, [saveName '.fig']));
            saveas(gcf, fullfile(savepath, [saveName '.jpg']));
            print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
        end
     end
end

 % FA pooled_ranked by FA trials in each session
% TE.RTpr_FA_pS = [];
% for counter = 1:nSessions    
%     pr = [];
%     for i = 1:length(RT_pooled.FA.rt{1, counter})
%         pr(i) = percentileranking (RT_pooled.FA.rt{1, counter}, RT_pooled.FA.rt{1, counter}(i));
%     end
%     pr = pr';
%     TE.RTpr_FA_pS = [TE.RTpr_FA_pS; pr];
% end
 for channel = TE.Photometry.settings.channels  
    FATrials_Data.fpWindow_peakMean = TE.phPeakMean_fpWindow(channel).data(FAFastestTrials);
    FATrials_Data.fpWindow_peakPercentile = TE.phPeakPercentile_fpWindow(channel).data(FAFastestTrials);
    FATrials_Data.csWindow0_peakMean = TE.phPeakMean_csWindow0(channel).data(FAFastestTrials);
    FATrials_Data.csWindow0_peakPercentile = TE.phPeakPercentile_csWindow0(channel).data(FAFastestTrials);
    FATrials_Data.csWindow1_peakMean = TE.phPeakMean_csWindow1(channel).data(FAFastestTrials);
    FATrials_Data.csWindow1_peakPercentile = TE.phPeakPercentile_csWindow1(channel).data(FAFastestTrials);
    FATrials_Data.csWindow2_peakMean = TE.phPeakMean_csWindow2(channel).data(FAFastestTrials);
    FATrials_Data.csWindow2_peakPercentile = TE.phPeakPercentile_csWindow2(channel).data(FAFastestTrials); 
    FATrials_Data.csWindow3_peakMean = TE.phPeakMean_csWindow3(channel).data(FAFastestTrials);
    FATrials_Data.csWindow3_peakPercentile = TE.phPeakPercentile_csWindow3(channel).data(FAFastestTrials); 
    FATrials_Data.usWindow2_peakMean = TE.phPeakMean_usWindow2(channel).data(FAFastestTrials);
    FATrials_Data.usWindow2_peakPercentile = TE.phPeakPercentile_usWindow2(channel).data(FAFastestTrials);     
    FATrials_Data.usWindow1_peakMean = TE.phPeakMean_usWindow1(channel).data(FAFastestTrials);
    FATrials_Data.usWindow1_peakPercentile = TE.phPeakPercentile_usWindow1(channel).data(FAFastestTrials);  
    FATrials_Data.usWindow3_peakMean = TE.phPeakMean_usWindow3(channel).data(FAFastestTrials);
    FATrials_Data.usWindow3_peakPercentile = TE.phPeakPercentile_usWindow3(channel).data(FAFastestTrials); 

    
    % Save peak data_FA trials_scatter plot
    saveName = [subjectName '_RTpr_bySession_FA_scatterplot_ch' num2str(channel)];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);    

    subplot(4,2,1); 
    xData = TE.RTpr_FA_pS;
    yData = FATrials_Data.fpWindow_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials foreperiod Mean'); 
   
    subplot(4,2,2); 
    yData = FATrials_Data.fpWindow_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials foreperiod Percentile0.9'); 
    
    
    subplot(4,2,3); 
    yData = FATrials_Data.csWindow0_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials (-0.4 0) from cue Mean'); 
   
    subplot(4,2,4); 
    yData = FATrials_Data.csWindow0_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials (-0.4 0) from cue Percentile0.9'); 
      
    subplot(4,2,5); 
    yData = FATrials_Data.csWindow3_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials from cue to anslick Mean'); 

    subplot(4,2,6); 
    yData = FATrials_Data.csWindow3_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials from cue to anslick Percentile0.9'); 
       
    subplot(4,2,7); 
    yData = FATrials_Data.usWindow3_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials from cue to US Mean'); 

    subplot(4,2,8); 
    yData = FATrials_Data.usWindow3_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 16);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 16);
    xlabel('RTpr'); ylabel('phMean ZS'); title('FATrials from cue to US Percentile0.9'); 
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
 end
 

%% hit/FA trials  by ranking compared to licking trials in each sessions
TE.hitRTpr_lick_pS = [];
TE.FARTpr_lick_pS = [];
for counter = 1:nSessions    
    pr = [];
    for i = 1:length(RT_pooled.hit.rt{counter, 1})
        pr(i) = percentileranking (RT_pooled.mix.rt{counter, 1}, RT_pooled.hit.rt{counter, 1}(i));
    end
    pr = pr';
    TE.hitRTpr_lick_pS = [TE.hitRTpr_lick_pS; pr];
end
for counter = 1:nSessions    
    pr = [];
    for i = 1:length(RT_pooled.FA.rt{counter, 1})
        pr(i) = percentileranking (RT_pooled.mix.rt{counter, 1}, RT_pooled.FA.rt{counter, 1}(i));
    end
    pr = pr';
    TE.FARTpr_lick_pS = [TE.FARTpr_lick_pS; pr];
end
 for channel = TE.Photometry.settings.channels    
    saveName = [subjectName '_hitRTpr_byLick_perSession_scatterplot_ch' num2str(channel)];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);    
    hitTrialsFastestNTrials_Data.fpWindow_peakMean = TE.phPeakMean_fpWindow(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.fpWindow_peakPercentile = TE.phPeakPercentile_fpWindow(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.csWindow0_peakMean = TE.phPeakMean_csWindow0(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.csWindow0_peakPercentile = TE.phPeakPercentile_csWindow0(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.csWindow1_peakMean = TE.phPeakMean_csWindow1(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.csWindow1_peakPercentile = TE.phPeakPercentile_csWindow1(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.csWindow2_peakMean = TE.phPeakMean_csWindow2(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.csWindow2_peakPercentile = TE.phPeakPercentile_csWindow2(channel).data(hitTrials); 
    hitTrialsFastestNTrials_Data.csWindow3_peakMean = TE.phPeakMean_csWindow3(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.csWindow3_peakPercentile = TE.phPeakPercentile_csWindow3(channel).data(hitTrials); 
    hitTrialsFastestNTrials_Data.usWindow2_peakMean = TE.phPeakMean_usWindow2(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.usWindow2_peakPercentile = TE.phPeakPercentile_usWindow2(channel).data(hitTrials);     
    hitTrialsFastestNTrials_Data.usWindow1_peakMean = TE.phPeakMean_usWindow1(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.usWindow1_peakPercentile = TE.phPeakPercentile_usWindow1(channel).data(hitTrials);  
    hitTrialsFastestNTrials_Data.usWindow3_peakMean = TE.phPeakMean_usWindow3(channel).data(hitTrials);
    hitTrialsFastestNTrials_Data.usWindow3_peakPercentile = TE.phPeakPercentile_usWindow3(channel).data(hitTrials); 
    FATrialsFastestNTrials_Data.fpWindow_peakMean = TE.phPeakMean_fpWindow(channel).data(FATrials);
    FATrialsFastestNTrials_Data.fpWindow_peakPercentile = TE.phPeakPercentile_fpWindow(channel).data(FATrials);
    FATrialsFastestNTrials_Data.csWindow0_peakMean = TE.phPeakMean_csWindow0(channel).data(FATrials);
    FATrialsFastestNTrials_Data.csWindow0_peakPercentile = TE.phPeakPercentile_csWindow0(channel).data(FATrials);
    FATrialsFastestNTrials_Data.csWindow1_peakMean = TE.phPeakMean_csWindow1(channel).data(FATrials);
    FATrialsFastestNTrials_Data.csWindow1_peakPercentile = TE.phPeakPercentile_csWindow1(channel).data(FATrials);
    FATrialsFastestNTrials_Data.csWindow2_peakMean = TE.phPeakMean_csWindow2(channel).data(FATrials);
    FATrialsFastestNTrials_Data.csWindow2_peakPercentile = TE.phPeakPercentile_csWindow2(channel).data(FATrials); 
    FATrialsFastestNTrials_Data.csWindow3_peakMean = TE.phPeakMean_csWindow3(channel).data(FATrials);
    FATrialsFastestNTrials_Data.csWindow3_peakPercentile = TE.phPeakPercentile_csWindow3(channel).data(FATrials); 
    FATrialsFastestNTrials_Data.usWindow2_peakMean = TE.phPeakMean_usWindow2(channel).data(FATrials);
    FATrialsFastestNTrials_Data.usWindow2_peakPercentile = TE.phPeakPercentile_usWindow2(channel).data(FATrials);     
    FATrialsFastestNTrials_Data.usWindow1_peakMean = TE.phPeakMean_usWindow1(channel).data(FATrials);
    FATrialsFastestNTrials_Data.usWindow1_peakPercentile = TE.phPeakPercentile_usWindow1(channel).data(FATrials);  
    FATrialsFastestNTrials_Data.usWindow3_peakMean = TE.phPeakMean_usWindow3(channel).data(FATrials);
    FATrialsFastestNTrials_Data.usWindow3_peakPercentile = TE.phPeakPercentile_usWindow3(channel).data(FATrials); 
    
    subplot(4,4,1); 
    xData = TE.hitRTpr_lick_pS;
    yData = hitTrialsFastestNTrials_Data.fpWindow_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Mean ZS'); title('foreperiod'); 
   
    subplot(4,4,2); 
    yData = hitTrialsFastestNTrials_Data.fpWindow_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Percentile0.9');  
    
    subplot(4,4,3); 
    xData = TE.FARTpr_lick_pS;
    yData = FATrialsFastestNTrials_Data.fpWindow_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr FATrials'); ylabel('Mean ZS'); 
   
    subplot(4,4,4); 
    yData = FATrialsFastestNTrials_Data.fpWindow_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Percentile0.9'); 
    
    
    subplot(4,4,5); 
    xData = TE.hitRTpr_lick_pS;
    yData = hitTrialsFastestNTrials_Data.csWindow0_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Mean ZS'); title('(-0.4 0) from cue'); 
    
    subplot(4,4,6); 
    yData = hitTrialsFastestNTrials_Data.csWindow0_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Percentile0.9');  
    
    subplot(4,4,7); 
    xData = TE.FARTpr_lick_pS;
    yData = FATrialsFastestNTrials_Data.csWindow0_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr FATrials'); ylabel('Mean ZS'); 
   
    subplot(4,4,8); 
    yData = FATrialsFastestNTrials_Data.csWindow0_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr FATrials'); ylabel('Percentile0.9');  
      
    subplot(4,4,9); 
    xData = TE.hitRTpr_lick_pS;
    yData = hitTrialsFastestNTrials_Data.csWindow3_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Mean ZS'); title('from cue to anslick'); 

    subplot(4,4,10); 
    yData = hitTrialsFastestNTrials_Data.csWindow3_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Percentile0.9'); 
    
    subplot(4,4,11); 
    xData = TE.FARTpr_lick_pS;
    yData = FATrialsFastestNTrials_Data.csWindow3_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr FATrials'); ylabel('Mean ZS'); 

    subplot(4,4,12); 
    yData = FATrialsFastestNTrials_Data.csWindow3_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr FATrials'); ylabel('Percentile0.9'); 
       
    subplot(4,4,13); 
    xData = TE.hitRTpr_lick_pS;
    yData = hitTrialsFastestNTrials_Data.usWindow3_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Mean ZS'); title('from cue to US'); 

    subplot(4,4,14); 
    yData = hitTrialsFastestNTrials_Data.usWindow3_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr hitTrials'); ylabel('Percentile0.9'); 
    
    subplot(4,4,15); 
    xData = TE.FARTpr_lick_pS;
    yData = FATrialsFastestNTrials_Data.usWindow3_peakMean;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr FATrials'); ylabel('Mean ZS'); 

    subplot(4,4,16); 
    yData = FATrialsFastestNTrials_Data.usWindow3_peakPercentile;
    scatter(xData,yData); hold on;
    fo = fitoptions('poly1');
    fob = fit(xData, yData, 'poly1', fo); 
    fph=plot(fob,'predfunc'); legend off;
    set(fph, 'LineWidth', 2);
    [rho, pval]= corr(xData, yData);
    textBox(['R = ' num2str(rho, 3)],[], [0.2 0.95], 8);
    textBox(['p = ' num2str(pval, 3)],[], [0.8 0.95], 8);
    xlabel('RTpr FATrials'); ylabel('Percentile0.9'); 
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
        save(fullfile(savepath, 'TE.mat'), 'TE');
        disp(['*** Saved: ' fullfile(savepath, 'TE.mat')]);
    end
 end
 
%% grand averages aligned to cue and licking
% channel = 2;
t = 2; %hitTrials
type = 'Hit';
Ttype = hitTrials;
linecolors = [mycolors_SL2('gr4'); mycolors_SL2('gr3'); mycolors_SL2('gr2'); mycolors_SL2('gr1')];
% t = 3; %FATrials
% type = 'FA';
% Ttype = FATrials;
% linecolors = [mycolors_SL2('re4'); mycolors_SL2('re3'); mycolors_SL2('re2'); mycolors_SL2('re1')];

    nTrials = length(TE.filename);   
    TE.RTpr_lick_pS_all = [];              
    i=1;
    j=1;
    for counter2 = 1:nTrials                       
        if ismember(counter2, find(hitTrials))                
            TE.RTpr_lick_pS_all(counter2) = TE.hitRTpr_lick_pS(i); % TE.hitRTpr_lick_pS is calculated by each session
            i=i+1;
        elseif ismember(counter2, find(FATrials))
            TE.RTpr_lick_pS_all(counter2) = TE.FARTpr_lick_pS(j); % TE.FARTpr_lick_pS is calculated by each session
            j=j+1;
        else
            TE.RTpr_lick_pS_all(counter2) = NaN;
        end
    end
    TE.RTpr_lick_pS_all = TE.RTpr_lick_pS_all';
    allTrials2 = (hitTrials + missTrials + FATrials + CRTrials) > 0;
    me_all2 = nanmedian(TE.RTpr_lick_pS_all(allTrials2));
    p75_all2 = prctile (TE.RTpr_lick_pS_all(allTrials2), 75);
    p25_all2 = prctile (TE.RTpr_lick_pS_all(allTrials2), 25);    
    RT1Trials = TE.RTpr_lick_pS_all < p25_all2;
    RT2Trials = (TE.RTpr_lick_pS_all >= p25_all2) & (TE.RTpr_lick_pS_all < me_all2);
    RT3Trials = (TE.RTpr_lick_pS_all >= me_all2) & (TE.RTpr_lick_pS_all < p75_all2);
    RT4Trials = TE.RTpr_lick_pS_all >= p75_all2;  
                
% Averages aligned to Cue
    saveName = [subjectName '_RT4_' type '_csAligned_avgs'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    ylim1 = [-1 4];
    ylim2 = [-1 2];
    xlim = [-4 4];
    pm = [3 1]; 
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-4, 5], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors, 'alpha', 1, 'LineWidth', 4};
    axh = [];
    subplot(pm(1), pm(2), 1); 
%     [ha, hl] = plotEventAverageFromTE(TE, {hitTrials, missTrials, FATrials, CRTrials}, 'Port1In', varargin{:});
   [ha, hl] = plotEventAverageFromTE(TE, {RT1Trials & Ttype, RT2Trials & Ttype, RT3Trials & Ttype, RT4Trials & Ttype}, 'Port1In', varargin{:});
    addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);    
    legend(hl, {'RT1', 'RT2', 'RT3', 'RT4'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');     
    set(gca, 'XLim', xlim, 'YLim', [-1 15], 'XTick', [-2 0 2 4], 'YTick', [0 10 20]);
    title('Licks'); ylabel('Licks (s)');  
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {RT1Trials & Ttype, RT2Trials & Ttype, RT3Trials & Ttype, RT4Trials & Ttype}, 1, varargin{:});
    addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);
    set(gca, 'XLim', xlim, 'XTick', [-2 0 2 4], 'YTick', [0 1 2 4 6]);
    set(gca, 'YLim', ylim1);
    title('Ch1'); ylabel('Fluor. (\sigma-bl.)');
                        
    if ismember(2, TE.Photometry.settings.channels)
        subplot(pm(1), pm(2), 3, 'FontSize', 12, 'LineWidth', 1); 
        [ha, hl] = phPlotAverageFromTE(TE, {RT1Trials & Ttype, RT2Trials & Ttype, RT3Trials & Ttype, RT4Trials & Ttype}, 2, varargin{:});
        addStimulusPatch(gca, [0 0.5], '', [0.8 0.8 0.8], 0.5);
        set(gca, 'XLim', xlim, 'XTick', [-2 0 2 4], 'YTick', [0 1 2 3 4]);
        set(gca, 'YLim', ylim2);
        title('Ch2'); ylabel('Fluor. (\sigma-bl.)'); xlabel('Time from Cue (s)');   
%         figSize = [4 12]; formatFigurePublish('size', figSize);
    end  
       
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));     
    end  
 