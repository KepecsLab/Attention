function out = bpFilterTrials(SessionData, types, outcomes)
% you may supply multiple types or outcomes as vectors
% to filter based only on types, pass [] to outcomes and vice versa

%     nTrials = length(SessionData.RawEvents.Trial);
    nTrials = SessionData.nTrials;
    
    if isempty(types)
        out = ismember(SessionData.TrialOutcome(1:SessionData.nTrials), outcomes);        
    elseif isempty(outcomes)
        out = ismember(SessionData.TrialTypes(1:SessionData.nTrials), types);        
    else
        out = ismember(SessionData.TrialTypes(1:SessionData.nTrials), types) & ismember(SessionData.TrialOutcome(1:SessionData.nTrials), outcomes);
    end
    out = find(out);
    
    