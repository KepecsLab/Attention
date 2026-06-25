function TE = makeTE_wheel_opto_cont(sessions)
    if nargin < 1
        sessions = bpLoadSessions;
    end
    
    % find total number of trials acrosss selected sesssions
    scounter = zeros(size(sessions));
    for i = 1:length(sessions)
        scounter(i) = sessions(i).SessionData.nTrials;
    end
    nTrials = sum(scounter);

    %% initialize TE
    TE = struct(...
        'filename', [],... 
        'trialNumber', zeros(nTrials, 1),...
        'TrialType', zeros(nTrials, 1),...  
        'TrialStartTimestamp', zeros(nTrials, 1),...
        'Epoch', NaN(nTrials, 1),... 
        'sessionIndex', NaN(nTrials, 1),...
        'sessionChange', NaN(nTrials, 1),...
        'StimFreq', zeros(nTrials, 1),...
        'StimAmp', zeros(nTrials, 1),...
        'NPulses', zeros(nTrials, 1),...
        'PulseDuration_ms', zeros(nTrials, 1),...
        'TrialOutcome', zeros(nTrials, 1),...
        'ReinforcementOutcome', [],...
        'WaterAmount', zeros(nTrials, 1),...
        'LickAction', []...
        );

    TE(1).Start = bpAddStateAsTrialEvent(sessions, 'Start');
    TE(1).Reward = bpAddStateAsTrialEvent(sessions, 'Reward');
    TE(1).AnswerDelay = bpAddStateAsTrialEvent(sessions, 'AnswerDelay');
    TE(1).AnswerLick = bpAddStateAsTrialEvent(sessions, 'AnswerLick');
    TE(1).Laser = bpAddStateAsTrialEvent(sessions, 'Laser');
    TE(1).Post = bpAddStateAsTrialEvent(sessions, 'Post');
    TE(1).AnswerLick2 = bpAddStateAsTrialEvent(sessions, 'AnswerLick2');
    TE(1).Reward2 = bpAddStateAsTrialEvent(sessions, 'Reward2');
    TE(1).AnswerDelay2 = bpAddStateAsTrialEvent(sessions, 'AnswerDelay2');
    TE(1).ITI = bpAddStateAsTrialEvent(sessions, 'ITI');
    
    TE(1).Port1In = bpAddEventAsTrialEvent(sessions, 'Port1In');
    
    TE.filename = cell(nTrials, 1);
    
    tcounter = 1;
    for sCounter = 1:length(sessions)
        session = sessions(sCounter);
        for counter = 1:session.SessionData.nTrials
            TE.filename{tcounter,1} = session.filename;
            TE.trialNumber(tcounter,1) = counter;
            TE.TrialType(tcounter,1) = session.SessionData.TrialTypes(counter);
            TE.TrialStartTimestamp(tcounter,1) = session.SessionData.TrialStartTimestamp(counter);
            TE.StimFreq(tcounter,1) = session.SessionData.StimFreq(counter);
            TE.StimAmp(tcounter,1) = session.SessionData.StimAmp(counter);
            TE.NPulses(tcounter,1) = session.SessionData.NPulses(counter);
            TE.PulseDuration_ms(tcounter,1) = session.SessionData.PulseDuration_ms(counter);
            TE.TrialOutcome(tcounter,1) = session.SessionData.TrialOutcome(counter);
            TE.ReinforcementOutcome{tcounter, 1} = session.SessionData.ReinforcementOutcome{counter};
            TE.WaterAmount(tcounter,1) = session.SessionData.WaterAmount(counter);
            TE.LickAction{tcounter, 1} = session.SessionData.LickAction{counter};
            
            if isfield(session.SessionData, 'Epoch')
                TE.Epoch(tcounter,1) = session.SessionData.Epoch(counter);
            end
            tcounter = tcounter + 1; % don't forget :)    
        end
    end
    
    sessionNames = unique(TE.filename);
    for counter = 1:length(sessionNames)
        sname = sessionNames{counter};
        TE.sessionIndex(cellfun(@(x) strcmp(x, sname), TE.filename)) = counter;
    end
    TE.sessionChange = [0; diff(TE.sessionIndex)];
    
    
    
