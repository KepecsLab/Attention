function [lickTimes, lickTrials, nTrials] = bpGetLicks2(filtArg, zeroField, trialMode)
    global BpodSystem
    if nargin < 2
        zeroField = '';
    end
    
    if nargin < 3
        trialMode = 'consecutive'; % consecutive or session
    end


    trials = onlineFilterTrials_v2(filtArg{1, :});
    switch trialMode
        case 'consecutive'
            trials = find(trials);
            nTrials = length(trials);
        case 'session'
            nTrials = length(trials);
            trials = find(trials);
    end
    
    lickTimes = [];
    lickTrials = [];
    if any(trials)
        for i = 1:length(trials)
            trial = trials(i);
            if isfield(BpodSystem.Data.RawEvents.Trial{trial}.Events, 'Port1In')
                theseLicks = BpodSystem.Data.RawEvents.Trial{trial}.Events.Port1In;
                if isempty(zeroField)
                    zeroTime = 0;
                else
                    zeroTime = BpodSystem.Data.RawEvents.Trial{trial}.States.(zeroField)(1,1); % always used first instance and start time stamp of zeroField for zeroing
                end
                theseLicks = theseLicks - zeroTime;
                lickTimes = [lickTimes theseLicks];
                switch trialMode
                    case 'consecutive'
                        lickTrials = [lickTrials zeros(1, length(theseLicks)) + i];
                    case 'session'
                        lickTrials = [lickTrials zeros(1, length(theseLicks)) + trial];
                    otherwise
                        error('incorrect trial mode');
                end
            else
                continue;
    %             lickTimes(end + 1) = NaN; % else add a dummy lick at time 0 so that you make an empty line on the raster
    %             lickTrials(end + 1) = i;
            end
        end
    end