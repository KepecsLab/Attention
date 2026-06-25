function out = onlineFilterTrials_v2(varargin)
% provide filtering fields and values as parameter-value pairs via varargin
% each pair is a field of structure, BpodSystem.Data
% data types can be numeric or cell arrays of strings 

    global BpodSystem
    

    out = ones(size(BpodSystem.Data.(varargin{1}))); % assuming that you'll always have TrialTypes
    %%
        counter = 1;
    while counter+1 <= length(varargin) 
        field = varargin{counter};
        val = varargin{counter+1};
        theseMatches = ismember(BpodSystem.Data.(field), val);
        if isempty(theseMatches)
            warning('*** no matches found ***');
        end
        out = out & theseMatches;
        counter=counter+2;
    end
  