% Continuous licking task analysis script   -----Shujing Li
%%
sessions = bpLoadSessions; % load sessions
%% 
TE = makeTE_wheel_opto_cont(sessions); % make TE structure
%% save data in a base directory, code below creates a folder named according to subject (e.g. DAT_1) and sets the save path within
saveOn = 1;
basepath = uigetdir;
sep = strfind(TE.filename{1}, '_');
subjectName = TE.filename{1}(1:sep(2)-1);
disp(subjectName);
savepath = fullfile(basepath, subjectName);
ensureDirectory(savepath);
%% extract peak trial dFF responses to cues and reinforcement and lick counts
nSessions = max(TE.sessionIndex);
nTrials = length(TE.filename);
csZeros = cellfun(@(x) x(1), TE.Start);
usZeros = cellfun(@(x) x(1), TE.Laser);
TE.preLicks = countEventFromTE(TE, 'Port1In', [-1.5 0], TE.Laser); % window for counting licks before laser window
TE.laserLicks = countEventFromTE(TE, 'Port1In', [0 2], TE.Laser); %wider window for counting licks during laser window
TE.postLicks = countEventFromTE(TE, 'Port1In', [2 4], TE.Laser); % window for counting licks before laser window
%% exclude trials at end of session where the mouse stops licking
rewardTrialsTrunc = filterTE(TE, 'TrialType', [1]);
truncateSessionsFromTE(TE, 'init', 'laserLicks', rewardTrialsTrunc);
% left/right arrow to adjust truncation point.  up/down arrow to switch
% sessions 'u' to update

%% rewards (Sound) vs lasers (Sound+Laser)
rejectTrials = filterTE(TE, 'reject', 1);
badTrials = rejectTrials; 
Laser20Trials = filterTE(TE, 'StimFreq', 20) & ~badTrials;
Laser10Trials = filterTE(TE, 'StimFreq', 10) & ~badTrials;
Laser5Trials = filterTE(TE, 'StimFreq', 5) & ~badTrials;
Laser1Trials = filterTE(TE, 'StimFreq', 0.5) & ~badTrials;
LaserTrials = filterTE(TE, 'StimAmp', 5) & ~badTrials;
NoLaserTrials = filterTE(TE, 'StimAmp', 0) & ~badTrials;
LickTrials = ~isnan(cellfun (@(x) x(1), TE.AnswerLick)) & ~badTrials;
NoLickTrials = isnan(cellfun (@(x) x(1), TE.AnswerLick)) & ~badTrials;
Type1Trials = filterTE(TE, 'TrialType', 1) & ~badTrials;
Type2Trials = filterTE(TE, 'TrialType', 2) & ~badTrials;
LickNoLaser = filterTE(TE, 'TrialOutcome', 1) & ~badTrials;
LickLaser = filterTE(TE, 'TrialOutcome', 0) & ~badTrials;
NoLickNoLaser = filterTE(TE, 'TrialOutcome', -1) & ~badTrials;
NoLickLaser = filterTE(TE, 'TrialOutcome', 2) & ~badTrials;
LickLaser20Trials = filterTE(TE, 'TrialOutcome', 0, 'StimFreq', 20) & ~badTrials;
LickLaser10Trials = filterTE(TE, 'TrialOutcome', 0, 'StimFreq', 10) & ~badTrials;
LickLaser5Trials = filterTE(TE, 'TrialOutcome', 0, 'StimFreq', 5) & ~badTrials;
LickLaser1Trials = filterTE(TE, 'TrialOutcome', 0, 'StimFreq', 0.5) & ~badTrials;
NoLickLaser20Trials = filterTE(TE, 'TrialOutcome', 2, 'StimFreq', 20) & ~badTrials;
NoLickLaser10Trials = filterTE(TE, 'TrialOutcome', 2, 'StimFreq', 10) & ~badTrials;
NoLickLaser5Trials = filterTE(TE, 'TrialOutcome', 2, 'StimFreq', 5) & ~badTrials;
NoLickLaser1Trials = filterTE(TE, 'TrialOutcome', 2, 'StimFreq', 0.5) & ~badTrials;
if saveOn
    save(fullfile(savepath, 'TE.mat'), 'TE');
    disp(['*** Saved: ' fullfile(savepath, 'TE.mat')]);
end
%
saveName = [subjectName '_lick_raster2'];
h=ensureFigure(saveName, 1);
mcPortraitFigSetup(h);
figSize = [8 4];
subplot(2,2,1); % lick raster for NoLaser
eventRasterFromTE2(TE, NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI');
title('NoLaserTrials'); ylabel('trial number');
set(gca, 'XLim', [-2 4]); set(gca, 'FontSize', 14); 

subplot(2,2,3); % lick raster for Laser
eventRasterFromTE2(TE, LaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI');
title('LaserTrials'); ylabel('trial number');
set(gca, 'XLim', [-2 4]); set(gca, 'FontSize', 14); 

subplot(2,2,2); % lick average 
linecolors = [mycolors_SL2('neutral'); mycolors_SL2('uncuedReward')];
varargin2 = {'trialNumbering', 'consecutive',...
    'binWidth', 0.5, 'window', [-3, 4], 'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI', 'cmap', linecolors};
[ha, hl] = plotEventAverageFromTE(TE, {NoLaserTrials, LaserTrials}, 'Port1In', varargin2{:});
legend(hl, {'NoLaser', 'Laser'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
ylabel('licks (s)'); xlabel('time from Cue (s)');  
set(gca, 'XLim', [-1.5 4], 'XTick', [-2 0 2 4], 'YLim', [0 20]);
% formatFigurePublish('size', figSize);
if saveOn
    saveas(gcf, fullfile(savepath, [saveName '.fig']));
    saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
    print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
end
% Averages aligned to Laser
    saveName = [subjectName '_Laser response_Avg'];
    h=ensureFigure(saveName, 1);
    mcPortraitFigSetup(h);
 
    linecolors = [mycolors_SL2('hit'); mycolors_SL2('re4'); mycolors_SL2('re3'); mycolors_SL2('re2'); mycolors_SL2('re1')];
    varargin = {'trialNumbering', 'consecutive',...
        'binWidth', 0.1, 'window', [-3, 5], 'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI', 'cmap', linecolors};
    axh = [];
    subplot(3, 1, 1); 
    [ha, hl] = plotEventAverageFromTE(TE, {NoLaserTrials, LaserTrials}, 'Port1In', varargin{:});
    legend(hl, {'NoLaserTrials', 'LaserTrials'}, 'Location', 'northwest', 'FontSize', 12); legend('boxoff');
    title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)');  
        
    subplot(3, 1, 2); 
    [ha, hl] = plotEventAverageFromTE(TE, {LickNoLaser, LickLaser}, 'Port1In', varargin{:});
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

%
saveName = [subjectName '_lick_raster'];
h=ensureFigure(saveName, 1);
mcPortraitFigSetup(h);

subplot(5,2,1); % lick raster for NoLaser
eventRasterFromTE(TE, NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI');
title('NoLaserTrials'); ylabel('trial number');
set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

subplot(5,2,2); % lick average for NoLaser
avgData1 = eventAverageFromTE(TE, NoLaserTrials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', [-3 5], 'zeroTimes', TE.Laser);
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

subplot(5,2,3); % lick raster for LaserTypes
eventRasterFromTE(TE, Laser1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI');
title('Laser1Trials'); ylabel('trial number');
set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

subplot(5,2,4); % lick average for LaserTypes
avgData1 = eventAverageFromTE(TE, Laser1Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', [-3 5], 'zeroTimes', TE.Laser);
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

subplot(5,2,5); % lick raster for LaserTypes
eventRasterFromTE(TE, Laser5Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI');
title('Laser5Trials'); ylabel('trial number');
set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

subplot(5,2,6); % lick average for LaserTypes
avgData1 = eventAverageFromTE(TE, Laser5Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', [-3 5], 'zeroTimes', TE.Laser);
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

subplot(5,2,7); % lick raster for LaserTypes
eventRasterFromTE(TE, Laser10Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI');
title('Laser10Trials'); ylabel('trial number');
set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

subplot(5,2,8); % lick average for LaserTypes
avgData1 = eventAverageFromTE(TE, Laser10Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', [-3 5], 'zeroTimes', TE.Laser);
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

subplot(5,2,9); % lick raster for LaserTypes
eventRasterFromTE(TE, Laser20Trials, 'Port1In', 'trialNumbering', 'consecutive',...
    'zeroTimes', TE.Laser, 'startField', 'Start', 'endField', 'ITI');
title('Laser20Trials'); ylabel('trial number');
set(gca, 'XLim', [-3 5]); set(gca, 'FontSize', 14); 

subplot(5,2,10); % lick average for LaserTypes
avgData1 = eventAverageFromTE(TE, Laser20Trials, 'Port1In', 'trialNumbering', 'consecutive',...
  'window', [-3 5], 'zeroTimes', TE.Laser);
plot(avgData1.xData, avgData1.Avg); title('Licks'); ylabel('licks (s)'); xlabel('time from Laser (s)'); 

if saveOn
    saveas(gcf, fullfile(savepath, [saveName '.fig']));
    saveas(gcf, fullfile(savepath, [saveName '.jpg'])); 
    print(gcf, '-dpdf', fullfile(savepath, [saveName '.pdf']));
end

%% save data
r2 = struct(...
    'all', [],...
    'avg', [],...
    'sem', [],...
    'Sess', cell(1,1),...
    'Sess_avg', zeros(nSessions, 1)...
    );
s2 = struct(...
    'preLicks', r2,...
    'laserLicks', r2,...
    'postLicks', r2...
    );
performance_pooled = struct(...
    'NoLaser', s2,...
    'Laser', s2,...
    'Laser1', s2,...
    'Laser5', s2,...
    'Laser10', s2,...
    'Laser20', s2...
    );
     ordering = {...
        'NoLaser', NoLaserTrials;...
        'Laser', LaserTrials;...
        'Laser1', Laser1Trials;...
        'Laser5', Laser5Trials;...
        'Laser10', Laser10Trials;...
        'Laser20', Laser20Trials;...
        };
    
   for c2 = 1:size(ordering,1)
       thisdata = TE.preLicks.rate(ordering{c2, 2});
       performance_pooled.(ordering{c2,1}).preLicks.all = thisdata;
       performance_pooled.(ordering{c2,1}).preLicks.avg = nanmean(thisdata);
       performance_pooled.(ordering{c2,1}).preLicks.sem = nanSEM(thisdata);
              
       thisdata = TE.laserLicks.rate(ordering{c2, 2});
       performance_pooled.(ordering{c2,1}).laserLicks.all = thisdata;
       performance_pooled.(ordering{c2,1}).laserLicks.avg = nanmean(thisdata);
       performance_pooled.(ordering{c2,1}).laserLicks.sem = nanSEM(thisdata);
              
       thisdata = TE.postLicks.rate(ordering{c2, 2});
       performance_pooled.(ordering{c2,1}).postLicks.all = thisdata;
       performance_pooled.(ordering{c2,1}).postLicks.avg = nanmean(thisdata);
       performance_pooled.(ordering{c2,1}).postLicks.sem = nanSEM(thisdata);
   end
   
save(fullfile(savepath, ['summary_' subjectName '_performance_pooled.mat']), 'performance_pooled');

