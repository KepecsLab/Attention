function trialTypeIndices = pickRandomTrials_blocks(block, nTrials)
    % creates vector containing random series of trial type indices (equivalent to trial type)
    % in proportions specified by P column of the block table
    % block proportions must add up to unity
    

    if nargin < 2
        nTrials = 1;
    end
    
    probabilities = block.P; % probability vector from block
    
    if abs(sum(probabilities) - 1) > 1e-9  % it should add up to 1 but be tolerant of data precision limitations
        disp('*** Error in pickRandomTrials_blocks, proportions do not add up to 1 ***');
        trialTypeIndices = [];
        return
    end
    
    rng('shuffle')
    trialTypeIndices = zeros(1, nTrials);
    pv = rand(1, nTrials);
    
    b1 = 0;
    for counter = 1:length(probabilities)
        b2 = probabilities(counter) + b1;
        trialTypeIndices(pv > b1 & pv <= b2) = counter;
        b1 = b2;
    end
        