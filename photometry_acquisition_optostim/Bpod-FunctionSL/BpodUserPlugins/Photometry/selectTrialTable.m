function trialTable = selectTrialTable(blockTable)

    p = cumsum(blockTable.P);
    rn = rand(1);
    p = p - rn;
    p(p < 0) = Inf;
    [~,I] = min(p);
    trialTable = blockTable(I,:);
    

    
    
    

    