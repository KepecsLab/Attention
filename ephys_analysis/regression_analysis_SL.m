function [R p] = regression_analysis_SL(cellid,varargin)
%REGRSSION_ANALYSIS   Linear regression for firing rate.
%   REGRESSION_ANALYSIS(CELLID) calculates linear regression coefficients
%   for firing rate variables (aligned to stimulus and response onset) and
%   various task-related regressors.
%
%   See also NBREGRESSION.

%   Balazs Hangya, Cold Spring Harbor Laboratory
%   1 Bungtown Road, Cold Spring Harbor
%   balazs.cshl@gmail.com
%   6-Oct-2012

%   Edit log: 10/6/12, 7/30/13

%   Modified by: Shujing Li, Cold Spring Harbor Laboratory / Washington
%   University in St. Louis
%   shujing@wustl.com

% Default arguments
prs = inputParser;
addRequired(prs,'cellid',@iscellid)
g = parse(prs,cellid,varargin{:});

% Load trial events
try
    TE = loadcb(cellid,'TrialEvents');   % load events
    ST = loadcb(cellid,'EVENTSPIKES');   % load prealigned spikes
catch ME
    disp('There was no behavioral protocol for ths session.')
    error(ME.message)
end

% Checking whether 'DeliverFeedback' event is available
sesstype = getvalue('session_type',cellid);
if isequal(sesstype,{'feedbackdelay'})
    alignevent_fa = 'DeliverFeedback';
    alignevent_hit = 'DeliverFeedback';
else
    alignevent_fa = 'LeftPortIn';
    alignevent_hit = 'LeftWaterValveOn';
end

% Relative spike times
stim_pos = findcellstr(ST.events(:,1),'StimulusOn');   % tone onset
response_pos_fa = findcellstr(ST.events(:,1),alignevent_fa);   % animal's respones, false alarms
response_pos_hit = findcellstr(ST.events(:,1),alignevent_hit);   % animal's respones, hits 
spikes_stimulus = ST.event_stimes{stim_pos};   % spikes relative to tone onset
spikes_response = cell(size(spikes_stimulus));
spikes_response(TE.FalseAlarm==1) = ST.event_stimes{response_pos_fa}(TE.FalseAlarm==1);   % spikes relative to response onset, false alarms
spikes_response(TE.Hit==1) = ST.event_stimes{response_pos_hit}(TE.Hit==1);   % spikes relative to response onset, hits

% Calculate regressors and dependent variables
NumTrials = length(TE.TrialStart);   % number of trials
wn = 20;   % window size (number of trials)
[hits,fas,gos,nogos,hitrate,farate,discrimination,dprime,engagement,...
    correct,incorrect,responded,skipped,...
    gort,nogort,gortint,nogortint,gortloc,nogortloc,loudness,iti,...
    fr_stim_0_05,fr_stim_0_10,fr_stim2resp,fr_resp_0_05,fr_resp_0_10,fr_resp_02_0,...
    fr_stim_025_0, fr_stim_05_0, fr_stim_05_025, fr_stim_10_0, fr_stim_10_075, fr_stim_075_05, ...
    fr_stim_10_09, fr_stim_09_08, fr_stim_08_07, fr_stim_07_06, fr_stim_06_05, fr_stim_05_04, fr_stim_04_03, ...
    fr_stim_03_02, fr_stim_02_01, fr_stim_01_0, ...
    fr_stim_20_18, fr_stim_18_16, fr_stim_16_14, fr_stim_14_12, fr_stim_12_10, ...
    fr_stim_10_08, fr_stim_08_06, fr_stim_06_04, fr_stim_04_02, fr_stim_02_0, fr_iti, fr_iti025, fr_iti05, fr_iti10] = deal(nan(NumTrials-1,1));  % SL_20250827

for iT = 1:NumTrials-1     % last trial may be incomplete    
    % Outcome
    if iT >= wn
        hits(iT) = sum(~isnan(TE.Hit(iT-wn+1:iT)));   % number of hits
        fas(iT) = sum(~isnan(TE.FalseAlarm(iT-wn+1:iT)));   % number of false alarms
        gos(iT) = sum(~isnan(TE.Hit(iT-wn+1:iT))|~isnan(TE.Miss(iT-wn+1:iT)));   % number of go tones
        nogos(iT) = sum(~isnan(TE.FalseAlarm(iT-wn+1:iT))|~isnan(TE.CorrectRejection(iT-wn+1:iT)));   % number of no-go tones
    end
    
    hitrate(iT) = hits(iT) / gos(iT);   % hit rate
    farate(iT) = fas(iT) / nogos(iT);   % false alarm rate
    discrimination(iT) = hitrate(iT) - farate(iT);   % hit - false alarm
    dprime(iT) = norminv(hitrate(iT)) - norminv(farate(iT));   % d' (SDT measure of discrimnability)
    engagement(iT) = hitrate(iT) + farate(iT);   % hit + false alarm
    
    correct(iT) = isequal(TE.Hit(iT),1) | isequal(TE.CorrectRejection(iT),1);
    incorrect(iT) = isequal(TE.FalseAlarm(iT),1) | isequal(TE.Miss(iT),1);
    responded(iT) = isequal(TE.Hit(iT),1) | isequal(TE.FalseAlarm(iT),1);
    skipped(iT) = isequal(TE.Miss(iT),1) | isequal(TE.CorrectRejection(iT),1);
    
    % Reaction time
    gort(iT) = TE.GoRT(iT);   % reaction time
    nogort(iT) = TE.NoGoRT(iT);   % response time for false alarms
    rts(iT) = TE.ReactionTime(iT);      
    if iT >= wn
        gortint(iT) = nanmean(TE.GoRT(iT-wn+1:iT));   % reaction time averaged over the window
        nogortint(iT) = nanmean(TE.NoGoRT(iT-wn+1:iT));   % no-go response time averaged over the window
    end
    gortloc(iT) = gort(iT) - gortint(iT);   % current reaction time relative to window average
    nogortloc(iT) = nogort(iT) - nogortint(iT);   % current no-go response time relative to window average 
    
    % Sound intensity
    loudness(iT) = TE.StimulusDuration(iT);   % tone intensity
    
    % Foreperiod (expectancy)
    iti(iT) = TE.ITIDistribution(iT);   % length of foreperiod (s)
        
    % Firing rate 0.5 s after stimulus onset
    lim1 = 0;  % start of time window
    lim2 = 0.5;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_0_05(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate 1 s after stimulus onset
    lim1 = 0;  % start of time window
    lim2 = 1;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_0_10(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate in from stimulus to response
    lim1 = 0;
    lim2 = TE.ReactionTime(iT);
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim2resp(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate 0.25 s before stimulus onset
    lim1 = -0.25;  % start of time window
    lim2 = 0;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_025_0(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate 0.5 s before stimulus onset
    lim1 = -0.5;  % start of time window
    lim2 = 0;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_05_0(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate 0.5-0.25 s before stimulus onset
    lim1 = -0.5;  % start of time window
    lim2 = -0.25;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_05_025(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate 1 s before stimulus onset
    lim1 = -1;  % start of time window
    lim2 = 0;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_10_0(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
        % Firing rate 1-0.75 s before stimulus onset
    lim1 = -1;  % start of time window
    lim2 = -0.75;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_10_075(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
        % Firing rate 0.75-0.5 s before stimulus onset
    lim1 = -0.75;  % start of time window
    lim2 = -0.5;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_075_05(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window    
            
    % Firing rate 1-0.9 s before stimulus onset
    lim1 = -1;  % start of time window
    lim2 = -0.9;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_10_09(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.9-0.8 s before stimulus onset
    lim1 = -0.9;  % start of time window
    lim2 = -0.8;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_09_08(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.8-0.7 s before stimulus onset
    lim1 = -0.8;  % start of time window
    lim2 = -0.7;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_08_07(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.7-0.6 s before stimulus onset
    lim1 = -0.7;  % start of time window
    lim2 = -0.6;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_07_06(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.6-0.5 s before stimulus onset
    lim1 = -0.6;  % start of time window
    lim2 = -0.5;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_06_05(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.5-0.4 s before stimulus onset
    lim1 = -0.5;  % start of time window
    lim2 = -0.4;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_05_04(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.4-0.3 s before stimulus onset
    lim1 = -0.4;  % start of time window
    lim2 = -0.3;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_04_03(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.3-0.2 s before stimulus onset
    lim1 = -0.3;  % start of time window
    lim2 = -0.2;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_03_02(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.2-0.1 s before stimulus onset
    lim1 = -0.2;  % start of time window
    lim2 = -0.1;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_02_01(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.1-0 s before stimulus onset
    lim1 = -0.1;  % start of time window
    lim2 = 0;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_01_0(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window    
        
    % Firing rate 2-1.8 s before stimulus onset
    lim1 = -2;  % start of time window
    lim2 = -1.8;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_20_18(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 1.8-1.6 s before stimulus onset
    lim1 = -1.8;  % start of time window
    lim2 = -1.6;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_18_16(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 1.6-1.4 s before stimulus onset
    lim1 = -1.6;  % start of time window
    lim2 = -1.4;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_16_14(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 1.4-1.2 s before stimulus onset
    lim1 = -1.4;  % start of time window
    lim2 = -1.2;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_14_12(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 1.2-1 s before stimulus onset
    lim1 = -1.2;  % start of time window
    lim2 = -1;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_12_10(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window 
    
    % Firing rate 1-0.8 s before stimulus onset
    lim1 = -1;  % start of time window
    lim2 = -0.8;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_10_08(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.8-0.6 s before stimulus onset
    lim1 = -0.8;  % start of time window
    lim2 = -0.6;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_08_06(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.6-0.4 s before stimulus onset
    lim1 = -0.6;  % start of time window
    lim2 = -0.4;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_06_04(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.4-0.2 s before stimulus onset
    lim1 = -0.4;  % start of time window
    lim2 = -0.2;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_04_02(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
        
    % Firing rate 0.2-0 s before stimulus onset
    lim1 = -0.2;  % start of time window
    lim2 = 0;   % end of time window
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_stim_02_0(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window      
    
    % Firing rate 0.5 s after response onset
    lim1 = 0;  % start of time window
    lim2 = 0.5;   % end of time window
    lspikes = spikes_response{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_resp_0_05(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate 1 s after response onset
    lim1 = 0;  % start of time window
    lim2 = 1;   % end of time window
    lspikes = spikes_response{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_resp_0_10(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate 0.2 s before response onset
    lim1 = -0.2;  % start of time window
    lim2 = 0;   % end of time window
    lspikes = spikes_response{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_resp_02_0(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate in the foreperiod
    itiwin = TE.ITIDistribution(iT);   % ITI
    lim1 = -itiwin;
    lim2 = 0;
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_iti(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate in the foreperiod, but max 0.25 s
    itiwin = TE.ITIDistribution(iT);   % ITI
    lim1 = max(-itiwin,-0.25);
    lim2 = 0;
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_iti025(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate in the foreperiod, but max 0.5 s
    itiwin = TE.ITIDistribution(iT);   % ITI
    lim1 = max(-itiwin,-0.5);
    lim2 = 0;
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_iti05(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
    
    % Firing rate in the foreperiod, but max 1 s
    itiwin = TE.ITIDistribution(iT);   % ITI
    lim1 = max(-itiwin,-1);
    lim2 = 0;
    lspikes = spikes_stimulus{iT};   % spikes relative to the event
    lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % spikes in the time window
    fr_iti10(iT) = length(lspikes2) / (lim2 - lim1);   % firing rate in the time window
end

% Regression
% hitinx = intersect(find(~isnan(TE.Hit)),(wn:NumTrials-1));
% hitinx = intersect(find(~isnan(TE.Hit)),find(gort<0.61)); % SL_20250827
% hitinx = intersect(find(~isnan(TE.Hit)),find(fr_stim_01_0<prctile(fr_stim_01_0, 98))); % SL_20250827
hitinx = intersect(find(~isnan(TE.FalseAlarm)),find(nogort<0.61)); % SL_20250827
% hitinx = intersect(find(~isnan(TE.FalseAlarm)),find(fr_stim_01_0<prctile(fr_stim_01_0, 98))); % SL_20250827
% y = gort(hitinx);
y = nogort(hitinx);

X = [ones(length(hitinx),1) fr_iti(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.iti = stats(3);
pR = corrcoef(y,X(:,2));
R.iti = pR(3);

X = [ones(length(hitinx),1) fr_iti025(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.iti025 = stats(3);
pR = corrcoef(y,X(:,2));
R.iti025 = pR(3);
 
X = [ones(length(hitinx),1) fr_iti05(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.iti05 = stats(3);
pR = corrcoef(y,X(:,2));
R.iti05 = pR(3);
 
X = [ones(length(hitinx),1) fr_iti10(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.iti10 = stats(3);
pR = corrcoef(y,X(:,2));
R.iti10 = pR(3);
 
X = [ones(length(hitinx),1) fr_stim_10_0(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_10_0 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_10_0 = pR(3);

X = [ones(length(hitinx),1) fr_stim_05_0(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_05_0 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_05_0 = pR(3);

X = [ones(length(hitinx),1) fr_stim_10_075(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_10_075 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_10_075 = pR(3);

X = [ones(length(hitinx),1) fr_stim_075_05(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_075_05 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_075_05 = pR(3);

X = [ones(length(hitinx),1) fr_stim_05_025(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_05_025 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_05_025 = pR(3);

X = [ones(length(hitinx),1) fr_stim_025_0(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_025_0 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_025_0 = pR(3);

X = [ones(length(hitinx),1) fr_stim_10_09(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_10_09 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_10_09 = pR(3);

X = [ones(length(hitinx),1) fr_stim_09_08(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_09_08 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_09_08 = pR(3);

X = [ones(length(hitinx),1) fr_stim_08_07(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_08_07 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_08_07 = pR(3);

X = [ones(length(hitinx),1) fr_stim_07_06(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_07_06 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_07_06 = pR(3);


X = [ones(length(hitinx),1) fr_stim_06_05(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_06_05 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_06_05 = pR(3);

X = [ones(length(hitinx),1) fr_stim_05_04(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_05_04 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_05_04 = pR(3);

X = [ones(length(hitinx),1) fr_stim_04_03(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_04_03 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_04_03 = pR(3);

X = [ones(length(hitinx),1) fr_stim_03_02(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_03_02 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_03_02 = pR(3);

X = [ones(length(hitinx),1) fr_stim_02_01(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_02_01 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_02_01 = pR(3);

X = [ones(length(hitinx),1) fr_stim_01_0(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_01_0 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_01_0 = pR(3);


X = [ones(length(hitinx),1) fr_stim_20_18(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_20_18 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_20_18 = pR(3);

X = [ones(length(hitinx),1) fr_stim_18_16(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_18_16 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_18_16 = pR(3);

X = [ones(length(hitinx),1) fr_stim_16_14(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_16_14 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_16_14 = pR(3);

X = [ones(length(hitinx),1) fr_stim_14_12(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_14_12 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_14_12 = pR(3);

X = [ones(length(hitinx),1) fr_stim_12_10(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_12_10 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_12_10 = pR(3);


X = [ones(length(hitinx),1) fr_stim_10_08(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_10_08 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_10_08 = pR(3);

X = [ones(length(hitinx),1) fr_stim_08_06(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_08_06 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_08_06 = pR(3);

X = [ones(length(hitinx),1) fr_stim_06_04(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_06_04 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_06_04 = pR(3);

X = [ones(length(hitinx),1) fr_stim_04_02(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_04_02 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_04_02 = pR(3);

X = [ones(length(hitinx),1) fr_stim_02_0(hitinx)];
[b,bint,r,rint,stats] = regress(y,X);
p.stim_02_0 = stats(3);
pR = corrcoef(y,X(:,2));
R.stim_02_0 = pR(3);

R.hitinx = hitinx;