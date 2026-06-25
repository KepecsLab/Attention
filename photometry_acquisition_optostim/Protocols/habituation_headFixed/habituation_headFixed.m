%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
function habituation_headFixed
    % habituate mouse to head fixation and water delivery (valve click
    % is only "cue"

    
    
    global BpodSystem 

    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        S.GUI.Reward = 3;
        S.GUI.RewardValveCode = 1;
        S.GUI.mu_iti = 2;% 6; % approximate mean iti duration
        S.GUI.maxTrials = 800;
        S.RewardValveTime = [];
        S.ITI = [];
    end
    

    
    %% Initialize parameter GUI plugin
    BpodParameterGUI('init', S);
    

    BpodSystem.Data.Settings = S;

    
    %% Define trials

    

 
%% init lick raster plot

    lickRasterFig = ensureFigure('Licks', 1);
    lickRasterAx = axes('Parent', lickRasterFig);




    %% Main trial loop
    for currentTrial = 1:S.GUI.maxTrials
        S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.GUI.RewardValveCode);

       
        S.ITI = inf;
        while S.ITI > 3 * S.GUI.mu_iti   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
            S.ITI = exprnd(S.GUI.mu_iti); %
        end
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

        sma = NewStateMatrix(); % Assemble state matrix
        sma = AddState(sma, 'Name','Pre',...
            'Timer', 0.5,...  %.5
            'StateChangeConditions',{'Tup','Reward'},...
            'OutputActions',{});
        sma = AddState(sma,'Name', 'Reward', ...
            'Timer',S.RewardValveTime,... % time will be 0 for omission
            'StateChangeConditions', {'Tup', 'Post'},...
            'OutputActions', {'ValveState', S.GUI.RewardValveCode});    
        sma = AddState(sma, 'Name','Post',...
            'Timer', 2,... %1 
            'StateChangeConditions',{'Tup','ITI'},...
            'OutputActions',{});
        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer',S.ITI,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{});
        %%
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SendStateMatrix(sma);



        % Run state matrix
        RawEvents = RunStateMatrix();  % Blocking!
%         disp('trial ended');


        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            
            TotalRewardDisplay('add', S.GUI.Reward);
            % something for raster
            BpodSystem.Data.TrialTypes(currentTrial) = 1; % 
            BpodSystem.Data.TrialOutcome(currentTrial) = 1;
            
            % rast5er
            bpLickRaster(BpodSystem.Data, 1, 1, 'Reward', [], lickRasterAx);
            set(gca, 'XLim', [-1, 2.5]);

            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        end
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            return
        end 
    end
end

