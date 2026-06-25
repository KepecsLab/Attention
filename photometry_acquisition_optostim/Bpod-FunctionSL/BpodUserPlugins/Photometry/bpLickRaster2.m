function [ax, lh] = bpLickRaster2(filtArg, zeroField, figName, ax, trialMode)
        % create lickRaster for an individual session
        % optional arguments: if you want to use a preexisting axis,
        % then pass '' to figName and pass the axes handle
        % zerofield: string, e.g. 'DeliverStimulus'
    if nargin < 3
        figName = 'lickRaster';
    end
    
    if ~isempty(figName)
        fig = ensureFigure(figName);
    else
        fig = gcf;
    end

    
    if nargin < 4 || isempty(ax) %make a new axes unless one is provided
        ax=axes(...
        'Parent', fig,...
        'YDir', 'reverse'...
        );
    else
        axes(ax); %bring it to front and make sure that YDir is reversed
        set(ax, 'YDir', 'reverse');
    end
    
    if nargin < 5
        trialMode = 'consecutive';
    end


    [lickTimes, lickTrials, nLickTrials] = bpGetLicks2(filtArg, zeroField, trialMode);
        
    lh = linecustommarker(lickTimes, lickTrials, [], [], ax);
    % make sure that yaxis spans total number of trials so that in the absence of licks the number of lickless trials is indicated    
    try
        set(ax, 'YLim', [0, max(nLickTrials, 1)]);
    catch
        set(ax, 'YLim', [0, 1]);
    end
        

    
    
    
    
    