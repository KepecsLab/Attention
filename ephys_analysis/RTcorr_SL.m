function [R p H] = RTcorr_SL(I,varargin)
%RTCORR   Correlation of firing rate and reaction time.
%   [R P H] = RTCORR(CELLID) calculates linear correlation (R;
%   significance, P) between post-stimulus firing rate (window, 0-0.5 s)
%   and reaction time for a given cell (CELLID). Scatter plot with line fit
%   is drawn in figure H ('display' has to be set to true, see below).
%   Default behavior can be overwritten using the following parameter-value
%   pairs as optional input arguments (with default values):
%       'window',[0 0.5] - timing relative to the event for spike rate
%           window
%       'event', 'LeftPortIn' - reference event for spike rate window
%       'display', false - control plotting behavior
%
%   Example:
%   RTcorr('n027_120209a_6.2','event','StimulusOn','window',[0 0.5],...
%       'display',true)
%
%   See also MODELCORR.

%   Edit log: BH 7/2/12

%   Modified by: Shujing Li, Cold Spring Harbor Laboratory / Washington
%   University in St. Louis
%   shujing@wustl.com

dbstop if error
if ~isequal(whichcb,'NB')
    choosecb('NB')    % swhitch to 'NB' CellBase
end

% Load CellBase if indices to CELLIDLIST are passed
if isnumeric(I)
    loadcb
    I = CELLIDLIST(I);
end
NumCell = length(I);  % number of cells
rho = nan(18,1);
pval = nan(18,1);
for j = 1:NumCell
    cellid = I{j};
    disp(cellid)

    % Default arguments
    prs = inputParser;
    addRequired(prs,'cellid',@iscellid)
    addParamValue(prs,'window',[0 0.5],@(s)isnumeric(s)&isequal(length(s),2))  % time window relative to the event, in seconds
    addParamValue(prs,'event','LeftPortIn',@ischar)   % default reference event: 'LeftPortIn'
    addParamValue(prs,'display',false,@(s)islogical(s)|ismember(s,[0 1]))   % control displaying rasters and PSTHs
    parse(prs,cellid,varargin{:})
    g = prs.Results;

    % Load trial events
    ST = loadcb(cellid,'EVENTSPIKES');   % load prealigned spikes for stimulation events
    TE = loadcb(cellid,'TrialEvents');
    event_pos = findcellstr(ST.events(:,1),g.event);
    spikes_stimon = ST.event_stimes{event_pos};

    % Reaction time
%     rt = TE.GoRT;
    rt = TE.NoGoRT; % False alarm SL_20250830

    % Pre-stimulus frequency
    lim1 = g.window(1);
    lim2 = g.window(2);
    NUMtrials = length(spikes_stimon);
    prestimfreq = nan(1,NUMtrials);
    for k = 1:NUMtrials-1
        lspikes = spikes_stimon{k};
        lspikes2 = lspikes(lspikes>lim1&lspikes<lim2);   % time window: one sec before stimulus onset
        prestimfreq(k) = length(lspikes2) / (lim2 - lim1);
    end

    % Filter trials
    hitinx = find(~isnan(TE.Hit));  % hits
%     hitinx = find(~isnan(TE.FalseAlarm));  % SL_20250827
    hrt = rt(hitinx);
    hfr = prestimfreq(hitinx);

    % Plot
    x = hrt * 1000;   % reaction time in ms
    y = hfr;
    if g.display
        H = figure;
        plot(x,y,'ko','MarkerFaceColor','k')
        % [gr icp err] = linefit(x,y);
        coef = polyfit(x,y,1);
        gr = coef(1);
        icp = coef(2);
        xx = (min(x)-0.1):0.01:(max(x)+0.1);
        yy = xx .* gr + icp;
        hold on
        plot(xx,yy,'LineWidth',2,'Color','black')
        xlabel('Reaction time (ms)')
        ylabel('Firing rate (Hz)')
    else
        H = NaN;
    end

    % Correlation
%     [b,bint,r,rint,stats] = regress(hfr',[ones(length(hrt),1),hrt']); %#ok<*ASGLU>
%     pR = corrcoef(hfr,hrt);
%     R = pR(2); 
%     R2 = sqrt(stats(1));         % correlation coefficient (R-value of the regression)
%     F = stats(2);           %#ok<NASGU> % F-test for H0: all coeff.-s are zero
%     p = stats(3);           % F-test significance
    [rho(j), pval(j)] = corr(hfr',hrt','type','Pearson');   % SL_20250827
%     [rho(j), pval(j)] = corr(hfr',hrt','type','Spearman');   
%     disp([R p])
    textBox(['R = ' num2str(rho(j))],[], [0.5 1], 9);  
    textBox(['P = ' num2str(pval(j))],[], [0.5 0.9], 9); 


% Save
    resdir = ['C:\Kepecs lab\PV project\Balazs data\NBPV\RTcorrPlot\'];
%     saveName = [cellid '_FA_RTcorr'];
    saveName = [cellid '_Hit_RTcorr'];
    print(gcf, '-dpdf', fullfile(resdir, [saveName '.pdf']));
    saveas(gcf, fullfile(resdir, [saveName '.fig']));
    saveas(gcf, fullfile(resdir, [saveName '.jpg'])); 
    save(fullfile(resdir, 'RTcorr.mat'), 'rho', 'pval');
end
