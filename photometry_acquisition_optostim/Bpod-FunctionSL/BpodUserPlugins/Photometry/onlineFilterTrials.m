function out = onlineFilterTrials(types, outcomes, epochs)
% you may supply multiple types or outcomes as vectors
% to filter based only on types, pass [] to outcomes and vice versa

    global BpodSystem
    

    nTrials = length(BpodSystem.Data.TrialTypes);
    
    if isempty(types)
        out = ismember(BpodSystem.Data.TrialOutcome(1:nTrials), outcomes);        
    elseif isempty(outcomes)
        out = ismember(BpodSystem.Data.TrialTypes(1:nTrials), types);        
    else
        out = ismember(BpodSystem.Data.TrialTypes(1:nTrials), types) & ismember(BpodSystem.Data.TrialOutcome(1:nTrials), outcomes);
    end
    
%     if ~isempty(epochs)
%         out = ismember(BpodSystem.Data.Epoch, epochs) & out;
%     end
    out = find(out);
    
    
    