%%
saveOn = 1; 
sessions = bpLoadSessions;
%%
TE = makeTE_LNL_Aud(sessions);

% save data in a base directory, code below creates a folder named according to subject (e.g. DAT_1) and sets the save path within
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
    BL{end + 1} = [1 4];
end

if sessions(1).SessionData.Settings.GUI.LED2_amp > 0
    channels(end+1) = 2;
    dFFMode{end+1} = 'simple';
    BL{end + 1} = [1 4];    
end

% dFFMode: 'simple', 'expFit',   !(now with hard-coded time constant for exponential) expFit- subtracts within-trial exponential bleaching trend using an exponential fit to the trial average baseline period
% blMode: 'byTrial', 'bySession', 'expFit', expFit- interpolates baseline from biexponential fit to raw fl baselines across trials
TE.Photometry = processTrialAnalysis_Photometry7(sessions, 'dFFMode', dFFMode, 'blMode', 'byTrial', 'zeroField', 'Cue', 'startField', 'StartRecording', 'channels', channels, 'baseline', BL);

%% cross sessions bleaching curve and dual exponential fits
for channel = channels
    figname = ['sessionBleach_Correction_ch' num2str(channel)];
    ensureFigure(figname, 1);
    plot(TE.Photometry.data(channel).blF_raw, 'k'); hold on;
    plot(TE.Photometry.data(channel).blF, 'r');
    title(['blMode' TE.Photometry.settings.blMode(channel)]); xlabel('Trials'); ylabel('meanF BL xTrials'); 
    legend('raw','1st FitCurve');
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
            title(['dFFMode' TE.Photometry.settings.dFFMode(channel)]);  xlabel('Time'); ylabel('dF BL xTime'); 
            legend('mean across trials','2nd FitCurve'); 
        end
    catch
    end
    if saveOn
        saveas(gcf, fullfile(savepath, [figname '.fig']));
        saveas(gcf, fullfile(savepath, [figname '.jpg']));
    end
end
 %% 
nSessions = max(TE.sessionIndex);
for counter = 1:nSessions
    trial = 5;
    for channel = channels
        figname = ['nidaq_rawdata_session' num2str(counter) '_ch' num2str(channel)];
        ensureFigure(figname, 1);
        plot(sessions(counter).SessionData.NidaqData{trial,1}(:, channel), 'k'); 
        if saveOn
            saveas(gcf, fullfile(savepath, [figname '.fig']));
            saveas(gcf, fullfile(savepath, [figname '.jpg']));
        end
    end
end

%% extract peak trial dFF responses to cues and reinforcement and lick counts
% zero is defined as time of cue- see call to
% processTrialAnalysis_Photometry2
channels = TE.Photometry.settings.channels;
nSessions = max(TE.sessionIndex);
BL{1} = [1 4];
BL{2} = [1 4];
nTrials = length(TE.filename);
TE.Answer = cellfun(@(x,y) max([x(1) y(1)]), TE.AnswerLick, TE.AnswerNoLick);
AnswerZeros = cellfun(@(x,y) max([x(1) y(1)]), TE.AnswerLick, TE.AnswerNoLick);
usZeros = cellfun(@(x,y,z) max([x(1) y(1) z(1)]), TE.Reward, TE.Punish, TE.Neutral); %'Reward', 'Punish', 'Neutral'
TE.Us = usZeros;
winzeros = TE.Us - usZeros;
usWindow1 = [0 1];
usWindow2 = [-0.4 0];
baselineWindow = [-1 0];
csWindow1 = [0 1];
csWindow2 = [-0.2 0.2];
csWindow0 = [-1 0];

winStart = cellfun(@(x) x(1), TE.Cue) - AnswerZeros;
winEnd = TE.Answer - AnswerZeros; 
mywin = [winStart winzeros];

TE.fpWindow = cellfun(@(x) x(1) - x(end), TE.foreperiod);
mywin2 = [TE.fpWindow winzeros];
TE.fpLicks = countEventFromTE(TE, 'Port1In', mywin2, TE.Cue);

winStart2 = cellfun(@(x) x(1), TE.Cue) - usZeros;
usWindow3 = [winStart2 winzeros];

TE.usLicks = countEventFromTE(TE, 'Port1In', [0 2], usZeros); %wider window for counting US licks than photometry US response
TE.RT = cellfun(@(x,y) y(1) - x(1), TE.Cue, TE.AnswerLick);
% phField = 'ZS';
% fluorField = 'ZS'; 
% phField = 'dFF';
% fluorField = 'dFF'; 
phField = 'dF';
fluorField = 'dF'; 
for channel = channels
    TE.phPeakMean_baseline(channel) = bpCalcPeak_dFF(TE.Photometry, channel, BL{channel}, [], 'method', 'mean', 'phField', phField);
    TE.phPeakMean_usWindow1(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow1, usZeros, 'method', 'mean', 'phField', phField);
    TE.phPeakMean_usWindow2(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow2, usZeros, 'method', 'mean', 'phField', phField);
    TE.phPeakMean_usWindow3(channel) = bpCalcPeak_dFF(TE.Photometry, channel, usWindow3, usZeros, 'method', 'mean', 'phField', phField);
    TE.phPeakMean_fpWindow(channel) = bpCalcPeak_dFF(TE.Photometry, channel, mywin2, TE.Cue, 'method', 'mean', 'phField', phField);
    TE.phPeakMean_csWindow0(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow0, TE.Cue, 'method', 'mean', 'phField', phField);
    TE.phPeakMean_csWindow1(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow1, TE.Cue, 'method', 'mean', 'phField', phField);
    TE.phPeakMean_csWindow2(channel) = bpCalcPeak_dFF(TE.Photometry, channel, csWindow2, TE.Answer, 'method', 'mean', 'phField', phField);
    TE.phPeakMean_csWindow3(channel) = bpCalcPeak_dFF(TE.Photometry, channel, mywin, TE.Answer, 'method', 'mean', 'phField', phField);
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
% exclude trials at end of session where the mouse stops licking
rewardTrialsTrunc = filterTE(TE, 'trialType', [1]);
usZeros = cellfun(@(x,y,z) max([x(1) y(1) z(1)]), TE.Reward, TE.Punish, TE.Neutral); %'Reward', 'Punish', 'Neutral'
usEnds = cellfun(@(x) x(end), TE.PostUsRecording); %'Reward', 'Punish', 'Neutral'
TE.latency = calcEventLatency(TE, 'Port1In', usZeros, usEnds);
truncateSessionsFromTE_SL(TE, 'init', 'usLicks', rewardTrialsTrunc);
% left/right arrow to adjust truncation point.  up/down arrow to switch
% sessions 'u' to update

%% generate trial lookups for different combinations of conditions
% see Pavlovian_reversals_blocks    blocks 2
    validTrials = filterTE(TE, 'reject', 0);
    badTrials7 = isnan (TE.phPeakMean_csWindow1(1).data);
    badTrials8 = isinf (TE.phPeakMean_csWindow1(1).data);
    badTrials = badTrials7  + badTrials8;    
    allTrials = filterTE(TE, 'reject', 0) & ~badTrials;
%     TE.fpLicks = countEventFromTE(TE, 'Port1In', mywin2, TE.Cue); 
    fpLickTrials = TE.fpLicks.count > 0;
  
    Sound1Trials = filterTE(TE, 'SoundValveIndex', 1, 'reject', 0) & ~badTrials;
    Sound2Trials = filterTE(TE, 'SoundValveIndex', 2, 'reject', 0) & ~badTrials; 
    Sound3Trials = filterTE(TE, 'SoundValveIndex', 3, 'reject', 0) & ~badTrials;
    Sound4Trials = filterTE(TE, 'SoundValveIndex', 4, 'reject', 0) & ~badTrials;
    uncuedTrials = filterTE(TE, 'SoundValveIndex', 0, 'reject', 0) & ~badTrials;

    TE.csLicks = countEventFromTE(TE, 'Port1In', usWindow3, TE.Us); % window for counting CS licks between cue to us
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
     
    Sound1Reward =  Sound1Trials & rewardTrials;
    Sound1Neutral = Sound1Trials & neutralTrials;
    Sound2Reward = Sound2Trials & rewardTrials;
    Sound2Neutral = Sound2Trials & neutralTrials; 
    Sound3Reward = Sound3Trials & rewardTrials;
    Sound3Neutral = Sound3Trials & neutralTrials; 
    Sound4Punish = Sound4Trials & punishTrials;
    Sound4Neutral = Sound4Trials & neutralTrials; 
    
    Sound1LickReward = Sound1Lick & rewardTrials;
    Sound1NoLickReward = Sound1NoLick & rewardTrials;
    Sound3LickNeutral = Sound3Lick & neutralTrials;
    Sound3NoLickNeutral = Sound3NoLick & neutralTrials;
    Sound4LickPunish = Sound4Lick & punishTrials;
    Sound4NoLickPunish = Sound4NoLick & punishTrials;
%     Sound1missReward = Sound1missTrials & Sound1Reward;
%     Sound1hitNeutral = Sound1hitTrials & Sound1Neutral;
%     Sound2hitReward = Sound2hitTrials & Sound2Reward;
%     Sound2missReward = Sound2missTrials & Sound2Reward;
%     Sound2hitNeutral = Sound2hitTrials & Sound2Neutral;    
    Sound2LickReward = Sound2Lick & rewardTrials;
    Sound2LickNeutral = Sound2Lick & neutralTrials;
    Sound2NoLickReward = Sound2NoLick & rewardTrials;
    Sound2NoLickNeutral = Sound2NoLick & neutralTrials;
         
    Sound1_50_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
    Sound1_40_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
    Sound1_30_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
    Sound1_20_Trials = filterTE(TE, 'SoundValveIndex', 1, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;
    Sound2_50_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 50, 'reject', 0) & ~badTrials;
    Sound2_40_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 40, 'reject', 0) & ~badTrials;
    Sound2_30_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 30, 'reject', 0) & ~badTrials;
    Sound2_20_Trials = filterTE(TE, 'SoundValveIndex', 2, 'SoundAmplitude', 20, 'reject', 0) & ~badTrials;

    Sound1hit50Trials = Sound1Lick & Sound1_50_Trials;
    Sound1hit40Trials = Sound1Lick & Sound1_40_Trials;
    Sound1hit30Trials = Sound1Lick & Sound1_30_Trials;
    Sound1hit20Trials = Sound1Lick & Sound1_20_Trials;
    Sound2hit50Trials = Sound2LickReward & Sound2_50_Trials;
    Sound2hit40Trials = Sound2LickReward & Sound2_40_Trials;
    Sound2hit30Trials = Sound2LickReward & Sound2_30_Trials;
    Sound2hit20Trials = Sound2LickReward & Sound2_20_Trials;
    
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
    saveName = [subjectName '_behavior-'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);  

    subplot(2,2,1); 
    performance_sound1 = length(find(Sound1Lick)) / length(find(Sound1Trials));
    performance_sound2 = length(find(Sound2Lick)) / length(find(Sound2Trials));
    performance_sound3 = length(find(Sound3Lick)) / length(find(Sound3Trials));
    performance_sound4 = length(find(Sound4Lick)) / length(find(Sound4Trials));
    x = [1 2 3 4];
    y = [performance_sound1 performance_sound2 performance_sound3 performance_sound4];
    plot(x,y,'-o', 'color', 'g');   
    set(gca, 'YLim', [0 1]);
    xlabel('Sound'); ylabel('Performance'); title('Performance'); 
           
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
    end
%  
% phField = 'ZS';
% fluorField = 'ZS';
% clim1 = [-1 1];
% clim2 = [-1 1];

% phField = 'dFF';
% fluorField = 'dFF'; 
% clim1 = [-0.8 0.8];
% clim2 = [-0.03 0.03];
% clims = [clim1; clim2];

% ylim = [-0.05 0.05];
%
phField = 'dF';
fluorField = 'dF'; 
clim1 = [-0.3 0.3];
clim2 = [0 1];
clim3 = [0 1];
clim4 = [2 3];
clims = [clim1; clim1];
ylim = clim1;
ylim2 = [0 20];
window = [-4 4];

saveName = [subjectName '_Sound1 response'];

h=ensureFigure(saveName, 1);
mcPortraitFigSetup(h);
% clim = clims(channel,:);
% fluorField = 'ZS'; 

subplot(4,2,1); % lick raster for Sound1
eventRasterFromTE(TE, Sound1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
title('Licks'); ylabel('trial number'); xlabel('Time from cue (s)'); 
set(gca, 'XLim', window); 

subplot(4,2,2); % lick average for Sound1
avgData1 = eventAverageFromTE(TE, Sound1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', window, 'zeroTimes', TE.Cue);
plot(avgData1.xData, avgData1.Avg); ylabel('licks (s)'); xlabel('Time from cue (s)'); set(gca, 'YLim', ylim2);

subplot(4,2,3); % phRaster for Sound1
phRasterFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'CLim', clim1, 'FluorDataField', fluorField);
% imagesc('XData', xData', 'CData', alignedPhotometryData);
title(['gDAsensor ' num2str(fluorField)]); ylabel('trial number'); xlabel('Time from cue (s)');     

subplot(4,2,4); % phAverage for Sound1
avgData = phAverageFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); ylabel(num2str(fluorField));  xlabel('Time from cue (s)'); 
set(gca, 'YLim', ylim);

subplot(4,2,5); % phRaster for Sound1
phRasterFromTE(TE, Sound1Trials, 2, 'window', window, 'zeroTimes', TE.Cue, 'CLim', clim1, 'FluorDataField', fluorField);
% imagesc('XData', xData', 'CData', alignedPhotometryData);
title(['RFP ' num2str(fluorField)]); ylabel('trial number'); xlabel('Time from cue (s)');  

subplot(4,2,6); % phAverage for Sound1
avgData = phAverageFromTE(TE, Sound1Trials, 2, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); ylabel(num2str(fluorField));  xlabel('Time from cue (s)');    
set(gca, 'YLim', ylim);

fluorField = 'ddF';
subplot(4,2,7); % phRaster for Sound1
phRasterFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'CLim', clim1, 'FluorDataField', fluorField);
% imagesc('XData', xData', 'CData', alignedPhotometryData);
title('dF(gDAsensor-RFP)'); ylabel('trial number'); xlabel('Time from cue (s)');     

subplot(4,2,8); % phAverage for Sound1
avgData = phAverageFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); ylabel(num2str(fluorField));  xlabel('Time from cue (s)'); 
set(gca, 'YLim', ylim);

if saveOn
    saveas(gcf, fullfile(savepath, [saveName '.fig']));
    saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
    print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
end

% 
saveName = [subjectName '_Sound1 response_MovCorr'];
h=ensureFigure(saveName, 1);
mcPortraitFigSetup(h);

fluorField = 'fRaw';
subplot(4,2,1); % phAverage for Sound1
avgData = phAverageFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); ylabel(num2str(fluorField));  xlabel('Time from cue (s)'); 
ylim1 = [mean(avgData.Avg)-0.5 mean(avgData.Avg)+0.5];
set(gca, 'YLim', ylim1);

subplot(4,2,2); % phRaster for Sound1
phRasterFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'CLim', ylim1, 'FluorDataField', fluorField);
% imagesc('XData', xData', 'CData', alignedPhotometryData);
title('raw(gDAsensor / RFP)'); ylabel('trial number'); xlabel('Time from cue (s)');     

fluorField = 'Fcorr';
subplot(4,2,3); % phAverage for Sound1
avgData = phAverageFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); ylabel(num2str(fluorField));  xlabel('Time from cue (s)'); 
ylim1 = [mean(avgData.Avg)-0.5 mean(avgData.Avg)+0.5];
set(gca, 'YLim', ylim1);

subplot(4,2,4); % phRaster for Sound1
phRasterFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'CLim', ylim1, 'FluorDataField', fluorField);
% imagesc('XData', xData', 'CData', alignedPhotometryData);
title('Fcorr(gDAsensor)'); ylabel('trial number'); xlabel('Time from cue (s)');  

subplot(4,2,5); % phAverage for Sound1
avgData = phAverageFromTE(TE, Sound1Trials, 2, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); ylabel(num2str(fluorField));  xlabel('Time from cue (s)'); 
ylim1 = [mean(avgData.Avg)-0.5 mean(avgData.Avg)+0.5];
set(gca, 'YLim', ylim1);

subplot(4,2,6); % phRaster for Sound1
phRasterFromTE(TE, Sound1Trials, 2, 'window', window, 'zeroTimes', TE.Cue, 'CLim', ylim1, 'FluorDataField', fluorField);
% imagesc('XData', xData', 'CData', alignedPhotometryData);
title('Fcorr(RFP)'); ylabel('trial number'); xlabel('Time from cue (s)'); 

fluorField = 'ratioF';
subplot(4,2,7); % phAverage for Sound1
avgData = phAverageFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); ylabel(num2str(fluorField));  xlabel('Time from cue (s)'); 
ylimR = [mean(avgData.Avg)-0.5 mean(avgData.Avg)+0.5];
set(gca, 'YLim', ylimR);

subplot(4,2,8); % phRaster for Sound1
phRasterFromTE(TE, Sound1Trials, 1, 'window', window, 'zeroTimes', TE.Cue, 'CLim', ylimR, 'FluorDataField', fluorField);
% imagesc('XData', xData', 'CData', alignedPhotometryData);
title('Fcorr(gDAsensor / RFP)'); ylabel('trial number'); xlabel('Time from cue (s)'); 

if saveOn
    saveas(gcf, fullfile(savepath, [saveName '.fig']));
    saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
    print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
end

% lick and photometry rasters aligned to cue
saveName = [subjectName '_cue response'];
h=ensureFigure(saveName, 1);
mcPortraitFigSetup(h);
fluorField = 'ratioF'; 
channel = 1;

subplot(4,4,1); % lick raster for Sound1
eventRasterFromTE(TE, Sound1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
title('Sound1Trials'); ylabel('trial number');
set(gca, 'XLim', window); set(gca, 'FontSize', 14); 

subplot(4,4,2); % lick average for Sound1
avgData1 = eventAverageFromTE(TE, Sound1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', window, 'zeroTimes', TE.Cue);
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('Licks (s)'); xlabel('Time from cue (s)'); 
set(gca, 'YLim', ylim2);

subplot(4,4,3); % phRaster for Sound1
phRasterFromTE(TE, Sound1Trials, channel, 'window', window, 'zeroTimes', TE.Cue, 'CLim', ylimR, 'FluorDataField', fluorField);
% imagesc('XData', xData', 'CData', alignedPhotometryData);

subplot(4,4,4); % phAverage for Sound1
avgData = phAverageFromTE(TE, Sound1Trials, channel, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); title('Fcorr(gDAsensor / RFP)'); ylabel('Fcorr'); xlabel('Time from cue (s)');
set(gca, 'YLim', ylimR);

subplot(4,4,5); % lick raster for Sound2
eventRasterFromTE(TE, Sound2Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
title('Sound2Trials'); ylabel('trial number');
set(gca, 'XLim', window); set(gca, 'FontSize', 14);

subplot(4,4,6); % lick average for Sound2
avgData1 = eventAverageFromTE(TE, Sound2Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', window, 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('Time from cue (s)'); 
set(gca, 'YLim', ylim2);

subplot(4,4,7); % phRaster for Sound2
phRasterFromTE(TE, Sound2Trials, channel, 'window', window, 'zeroTimes', TE.Cue, 'CLim', ylimR, 'FluorDataField', fluorField);

subplot(4,4,8); % phAverage for Sound2
avgData = phAverageFromTE(TE, Sound2Trials, channel, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); title('Fcorr(gDAsensor / RFP)'); ylabel('Fcorr'); xlabel('Time from cue (s)');
set(gca, 'YLim', ylimR);

subplot(4,4,9); % lick raster for Sound3
eventRasterFromTE(TE, Sound3Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
title('Sound3Trials'); ylabel('trial number');
set(gca, 'XLim', window); set(gca, 'FontSize', 14);

subplot(4,4,10); % lick average for Sound3
avgData1 = eventAverageFromTE(TE, Sound3Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', window, 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('Time from cue (s)'); 
set(gca, 'YLim', ylim2);

subplot(4,4,11); % phRaster for Sound3
phRasterFromTE(TE, Sound3Trials, channel, 'window', window, 'zeroTimes', TE.Cue, 'CLim', ylimR, 'FluorDataField', fluorField);

subplot(4,4,12); % phAverage for Sound3
avgData = phAverageFromTE(TE, Sound3Trials, channel, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); title('Fcorr(gDAsensor / RFP)'); ylabel('Fcorr'); xlabel('Time from cue (s)');
set(gca, 'YLim', ylimR);

subplot(4,4,13); % lick raster for Sound4Trials
eventRasterFromTE(TE, Sound4Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
title('Sound4Trials'); ylabel('trial number');
set(gca, 'XLim', window); set(gca, 'FontSize', 14);

subplot(4,4,14); % lick average for Sound4Trials
avgData1 = eventAverageFromTE(TE, Sound4Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', window, 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording');
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('Time from cue (s)'); 
set(gca, 'YLim', ylim2);

subplot(4,4,15); % phRaster for Sound4Trials
phRasterFromTE(TE, Sound4Trials, channel, 'window', window, 'zeroTimes', TE.Cue, 'CLim', ylimR, 'FluorDataField', fluorField);

subplot(4,4,16); % phAverage for Sound4Trials
avgData = phAverageFromTE(TE, Sound4Trials, channel, 'window', window, 'zeroTimes', TE.Cue, 'FluorDataField', fluorField);
plot(avgData.xData, avgData.Avg); title('Fcorr(gDAsensor / RFP)'); ylabel('Fcorr'); xlabel('Time from cue (s)');
set(gca, 'YLim', ylimR);

if saveOn
    saveas(gcf, fullfile(savepath, [saveName '.fig']));
    saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
    print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
end

% Averages aligned to Cue
    saveName = [subjectName '_Cue response_Avg'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
    nSessions = max(TE.sessionIndex);  
    ordering = {...
        '1', 'sound0',  'laser0';...
        '2', 'sound1', 'laser1';...
        '3', 'sound2', 'laser2';...
        '4',  'sound5', 'laser5';... 
        '5',  'sound7', 'laser7';... 
        '6', 'sound10', 'laser10';... 
        '7',  'sound15', 'laser15';...
        '8',  'sound40', 'laser40';...
        };

    Sound1TrialsSession1 = find(Sound1Trials & (TE.sessionIndex == 1));
    Sound1TrialsSession2 = find(Sound1Trials & (TE.sessionIndex == 2));
    Sound1TrialsSession3 = find(Sound1Trials & (TE.sessionIndex == 3));
    Sound1TrialsSession4 = find(Sound1Trials & (TE.sessionIndex == 4));
    Sound1TrialsSession5 = find(Sound1Trials & (TE.sessionIndex == 5));
    Sound1TrialsSession6 = find(Sound1Trials & (TE.sessionIndex == 6));
    Sound1TrialsSession7 = find(Sound1Trials & (TE.sessionIndex == 7));
    Sound1TrialsSession8 = find(Sound1Trials & (TE.sessionIndex == 8));

    pm = [3 1];     
    subplot(pm(1), pm(2), 1); 
    fluorField = 'dF';
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-4, 4], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'linespec', {'k', 'r', 'b', 'g', 'y', 'c', 'm', 'o'}};
    axh = [];      
    [ha, hl] = phPlotAverageFromTE(TE, {Sound1TrialsSession1, Sound1TrialsSession2, Sound1TrialsSession3, Sound1TrialsSession4, Sound1TrialsSession5, Sound1TrialsSession6, Sound1TrialsSession7, Sound1TrialsSession8}, channel, varargin{:}); 
    legend(hl, {'Sound1 Session1', 'Sound1 Session2', 'Sound1 Session3', 'Sound1 Session4', 'Sound1 Session5', 'Sound1 Session6', 'Sound1 Session7', 'Sound1 Session8'}, 'Location', 'northwest', 'FontSize', 9); legend('boxoff');
    title([fluorField '(gDAsensor)']); ylabel(fluorField); 
    
    subplot(pm(1), pm(2), 2); 
    fluorField = 'Fcorr';
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-4, 4], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'linespec', {'k', 'r', 'b', 'g', 'y', 'c', 'm', 'o'}};
    axh = [];      
    [ha, hl] = phPlotAverageFromTE(TE, {Sound1TrialsSession1, Sound1TrialsSession2, Sound1TrialsSession3, Sound1TrialsSession4, Sound1TrialsSession5, Sound1TrialsSession6, Sound1TrialsSession7, Sound1TrialsSession8}, channel, varargin{:}); 
    title([fluorField '(gDAsensor)']); ylabel(fluorField); 
    
    subplot(pm(1), pm(2), 3); 
    fluorField = 'ratioF';
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-4, 4], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'linespec', {'k', 'r', 'b', 'g', 'y', 'c', 'm', 'o'}};
    axh = [];      
    [ha, hl] = phPlotAverageFromTE(TE, {Sound1TrialsSession1, Sound1TrialsSession2, Sound1TrialsSession3, Sound1TrialsSession4, Sound1TrialsSession5, Sound1TrialsSession6, Sound1TrialsSession7, Sound1TrialsSession8}, channel, varargin{:}); 
    title([fluorField '(gDAsensor / RFP)']); ylabel(fluorField); 
    xlabel('Time from cue (s)');
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end  

%% Averages aligned to Cue
    saveName = [subjectName '_Cue response_Avgs'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [2 1]; 
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('sound3'); mycolors_SL2('FA'); mycolors_SL2('uncuedReward')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-4, 4], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1Trials, Sound2Trials, Sound3Trials}, 'Port1In', varargin{:});
    legend(hl, {'Sound1', 'Sound2', 'Sound3','Sound4'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('Licks (s)'); xlabel('Time from Cue (s)');     
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {Sound1Trials, Sound2Trials, Sound3Trials}, 1, varargin{:});
    legend(hl, {'Sound1', 'Sound2', 'Sound3', 'Sound4'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Fcorr(gDAsensor / RFP)'); ylabel('Fcorr');                      
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end  
    
% Averages aligned to Cue for probalibity task
    saveName = [subjectName '_Cue response_Avgs_2'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [2 1]; 
    linecolors = [mycolors_SL2('gr1'); mycolors_SL2('neutral'); mycolors_SL2('gr3'); mycolors_SL2('gr4');  mycolors_SL2('sound3'); mycolors_SL2('sound4');mycolors_SL2('uncuedReward')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-4, 6], 'zeroTimes', TE.Cue, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1Lick, Sound1NoLick, Sound2Lick, Sound2NoLick, Sound3Lick, Sound3NoLick}, 'Port1In', varargin{:});
    legend(hl, {'Sound1Reward100%Lick','Sound1Reward100%NoLick', 'Sound2Reward50%Lick','Sound2Reward50%NoLick', 'Sound3NeutralLick','Sound3NeutralNolick'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Cue (s)');     
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {Sound1Lick, Sound1NoLick, Sound2Lick, Sound2NoLick, Sound3Lick, Sound3NoLick}, 1, varargin{:});
    title('Fcorr(gDAsensor / RFP)'); ylabel('Fcorr');  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end   
    % Averages aligned to Us for probability task
    saveName = [subjectName '_Us response_Avgs4'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [2 1]; 
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('miss'); mycolors_SL2('uncuedReward'); mycolors_SL2('neutral')];     
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.5, 'FluorDataField', fluorField, 'window', [-5, 4], 'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound2LickReward, Sound2LickNeutral, Sound2NoLickReward, Sound2NoLickNeutral}, 'Port1In', varargin{:});
    legend(hl, {'Sound2LickReward', 'Sound2LickNeutral', 'Sound2NoLickReward', 'Sound2NoLickNeutral', 'uncuedReward'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Us (s)');     
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {Sound2LickReward, Sound2LickNeutral, Sound2NoLickReward, Sound2NoLickNeutral, uncuedReward}, 1, varargin{:});
    title('Fcorr(gDAsensor / RFP)'); ylabel('Fcorr');  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));       
    end  
    % Averages aligned to Us for probability task
    saveName = [subjectName '_Us response_Avgs_2--'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);

    pm = [2 1]; 
    linecolors = [mycolors_SL2('gr1'); mycolors_SL2('neutral'); mycolors_SL2('gr3'); mycolors_SL2('gr4');  mycolors_SL2('sound3')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.2, 'FluorDataField', fluorField, 'window', [-5, 4], 'zeroTimes', TE.Us, 'startField', 'PreCsRecording', 'endField', 'PostUsRecording', 'cmap', linecolors};
    axh = [];
    subplot(pm(1), pm(2), 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {Sound1LickReward, Sound1NoLickReward, Sound3LickNeutral, Sound3NoLickNeutral}, 'Port1In', varargin{:});
    legend(hl, {'Sound1LickReward','Sound1NoLickReward', 'Sound3LickNeutral','Sound3NolickNeutral', 'uncuedReward'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Us (s)');    
    
    subplot(pm(1), pm(2), 2, 'FontSize', 12, 'LineWidth', 1); 
    [ha, hl] = phPlotAverageFromTE(TE, {Sound1LickReward, Sound1NoLickReward, Sound3LickNeutral, Sound3NoLickNeutral}, 1, varargin{:});
    title('Fcorr(gDAsensor / RFP)'); ylabel('Fcorr');  
    
    if saveOn
        saveas(gcf, fullfile(savepath, [saveName '.fig']));
        saveas(gcf, fullfile(savepath, [saveName '.jpg']));   
        print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));      
    end   