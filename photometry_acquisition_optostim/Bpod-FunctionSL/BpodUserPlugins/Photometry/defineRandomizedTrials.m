function trialTypes = defineRandomizedTrials(typeMatrix, maxTrials)
    % creates vector containing random series of the trial types specified in column 1 of
    % typeMatrix in proportions specified by column 2 of typeMatrix. Column
    % 2 must add up to unity (1).
    % maxTrials- length of trialTypes (optional, default = 1000);
%     Example: 
%     typeMatrix = [...
%         % long tone
%         1, 1/3 * 0.45;... % small reward
%         2, 1/3 * 0.45;... % big reward
%         3, 1/3 * 0.1;...  % omit
%         % short tone
%         4, 1/3 * 0.45;... % small reward
%         5, 1/3 * 0.45;... % big reward
%         6, 1/3 * 0.1;...  % omit
%         % uncued
%         7, 1/3 * 0.5;...  % small reward
%         8, 1/3 * 0.5;...  % big reward
%         ];
%     
%     MaxTrials = 1000;       
%     TrialTypes = defineRandomizedTrials(typeMatrix, MaxTrials);  


    if nargin < 2
        maxTrials = 1000;
    end
    
    if abs(sum(typeMatrix(:,2)) - 1) > 1e-9  % it should add up to 1 but be tolerant of data precision limitations
        disp('*** Error in defineRandomizedTrials, typeMatrix proportions do not add up to 1 ***');
        trialTypes = [];
        return
    end
    
    rng('shuffle')
    trialTypes = zeros(1, maxTrials);
    p = rand(1, maxTrials);
    
    b1 = 0;
    for counter = 1:size(typeMatrix, 1)
        type = typeMatrix(counter, 1);
        b2 = typeMatrix(counter, 2) + b1;
        trialTypes(p > b1 & p <= b2) = type;
        b1 = b2;
    end
        