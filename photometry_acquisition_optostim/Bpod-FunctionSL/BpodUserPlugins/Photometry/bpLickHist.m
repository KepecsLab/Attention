function [ax, lh, lp] = bpLickHist(SessionData, type, outcome, binSpecs, zeroField, startField, endField, linespec, figName, ax)
        % To do in future: consider having binSpecs, zeroField, startField
        % as optional parameters (part of varargin)
        % defaults, also consider doing parameter parsing like Balazs does
        
        % create lick histogram for an individual session
        % optional arguments: if you want to use a preexisting axis,
        % then pass '' to figName and pass the axes handle
        
        % type, outcome: scalar or vectors (must be matched in length),
        % ex: histMatrix = [1 2; 1 3; 1 4],  matrix with column 1 as types,
        % column 2 as outcomes,  then...
        % bpLickHist(SessionData,histMatrix(:,1), histMatrix(:, 2),...);
        
        % zerofield: string, e.g. 'DeliverStimulus', or cell, e.g.
        % {'DeliverStimulus', 'first'}    % other option is 'last'
        % startField, endField: string, e.g. 'NoLick', 'PostTrialRecording'
    if nargin < 9
        figName = 'lickHistogram';
    end
    
    if ~isempty(figName)
        fig = ensureFigure(figName);
    end
    
    if nargin < 9
        clf
    end
    
    if nargin < 10 %make a new axes unless one is provided
        ax=axes(...
        'Parent', fig...
        );
    else
        axes(ax); % bring it to front
    end
    
    if nargin < 8 || isempty(linespec)
        linespec = {'k', 'r', 'b', 'g', 'm'}; % default linespecs
    elseif ischar(linespec)
        linspec = {linespec};
    end
    lh = zeros(1, length(type));
    lp = zeros(1, length(type));
    for counter = 1:length(type)
        color = linespec{counter};
        if iscell(outcome)
            thisOutcome = outcome{counter}; % to accommodate multiple outcomes to be grouped together
        elseif isempty(outcome)
            thisOutcome = []; % like a wildcard, don't filter by outcome if empty
        else
            thisOutcome = outcome(counter);
        end
        
        if iscell(type)
            thisType = type{counter}; % to accommodate multiple types to be grouped together
        elseif isempty(type)
            thisType = [];
        else
            thisType = type(counter);
        end
        
        [lickRates, lickRatesN, binCenters] =  bpLickCounts(SessionData, thisType, thisOutcome, zeroField, binSpecs, startField, endField);
%         lickRatesAvg = sum(lickRates) ./ lickRatesN;
        if isvector(lickRates) % e.g. first trial when using bpLickHist for online plotting
            thisLine = plot(binCenters, lickRates, color);
            thisPatch = NaN;
        else
            lickRatesAvg = nanmean(lickRates);
            lickRatesSEM = std(lickRates, 'omitnan') ./ sqrt(sum(~isnan(lickRates), 1));
            [thisLine, thisPatch] = boundedline(binCenters, lickRatesAvg, lickRatesSEM, color, ax, 'alpha');
        end
        lh(counter) = thisLine;
        lp(counter) = thisPatch;
    end
        
    
    
    