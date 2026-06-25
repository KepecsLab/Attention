
function wheel_opto_cont3
    % continuous water delivery (valve click is only "cue"   
    
    global BpodSystem 

    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    defaults = {...        
        'GUIPanels.Timing', {'Epoch',  'mu_iti', 'PrimeReward', 'Reward', 'RewardValveCode', 'maxTrials'};...
        'GUI.Epoch', 1;...
        'GUI.mu_iti', 2;...
        'GUI.PrimeReward', 1;...
        'GUI.Reward', 1;...     
        'GUI.RewardValveCode', 1;... 
        'GUI.maxTrials', 500;...
        'GUITabs.Timing', {'Timing'};...
        
        'GUI.StimFreq.Active' , [1 0 0 0]';...
        'GUI.StimFreq.Freq' , [0.5 25 20, 10]';...
        'GUI.StimFreq.NPulses' , [1 50 40 20]';...
        'GUI.StimFreq.PulseDuration_ms' , [2000 10 10 10]';...
        'GUI.StimFreq.Amplitude' , [5 5 5 5]';...        
        'GUIMeta.StimFreq.Style' , 'table';
        'GUIMeta.StimFreq.String' , 'Stim Freq';
        'GUIMeta.StimFreqTable.ColumnLabel' , {'Active', 'Freq', 'NPulses', 'PulseDuration_ms', 'Amplitude'};...
        'GUIPanels.StimFreqTable' , {'StimFreq'};
        'GUI.alternateLaser', 0;...
        'GUIMeta.alternateLaser.Style', 'checkbox';... 
        'GUI.alternateLED', 0;...
        'GUIMeta.alternateLED.Style', 'checkbox';...  
        'GUI.LaserRatio', 0.2;...
        'GUI.PulseDelay_ms', 0;...          
        'GUIPanels.TrainParams', {'alternateLaser', 'alternateLED', 'LaserRatio', 'PulseDelay_ms'};...                   
        'GUITabs.Laser', {'TrainParams', 'StimFreqTable'};...         
        };    
    S = setBpodDefaultSettings(S, defaults);  
    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI2('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI2('sync', S); % Sync parameters with BpodParameterGUI plugin 
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;
    S.PrimeRewardValveTime = GetValveTimes(S.GUI.PrimeReward, S.GUI.RewardValveCode);
    S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.GUI.RewardValveCode);
    S.LaserTime = 0.05; % just 50ms to trigger pulse pal now 
    BpodSystem.Data.Settings = S;
    %% load default PulsePal stimulus train matrix
    if S.GUI.alternateLaser
        load('wheel_opto_pulse_burst.mat'); % load PulsePal stimulus train matrix in the same folder
        ParameterMatrixDefault = wheel_opto_pulse_burst;
         try % detect if pulse pal is on...             
             ProgramPulsePal(ParameterMatrixDefault);        
         catch % if forgot to start pulse pal
             PulsePal ('COM6');
             ProgramPulsePal(ParameterMatrixDefault);                 
         end          
    end 
    if S.GUI.alternateLED
        load('wheel_opto_pulse_burst2.mat'); % load PulsePal stimulus train matrix in the same folder
        ParameterMatrixDefault = wheel_opto_pulse_burst;
         try % detect if pulse pal is on...             
             ProgramPulsePal(ParameterMatrixDefault);        
         catch % if forgot to start pulse pal
             PulsePal ('COM6');
             ProgramPulsePal(ParameterMatrixDefault);                 
         end          
    end
    
    TotalRewardDisplay('init')

    %% determine nidaq/point grey and olfactometer triggering arguments
    npgWireArg = 0;
    npgBNCArg = 1; % BNC 1 source to trigger Nidaq is hard coded
    if ~BpodSystem.EmulatorMode        
%     % retrieve machine specific point grey camera settings
        addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
%         pgSettings = machineSpecific_pointGrey;    
        % switch pgSettings.triggerType
        %     case 'WireState'
        %         npgWireArg = bitset(npgWireArg, pgSettings.triggerNumber); % its a wire trigger
        %     case 'BNCState'
        %         npgBNCArg = bitset(npgBNCArg, pgSettings.triggerNumber); % its a BNC trigger
        % end       
    end
    %% Define trials    
    % Outcomes -> NaN: future trial, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot) 
    ReinforcementOutcome = []; % local version of BposSystem.Data.ReinforcementOutcome
%     BpodSystem.Data.SoundFreq = [];
%     BpodSystem.Data.SoundDura = [];
%     BpodSystem.Data.SoundAmp = [];
    BpodSystem.Data.TrialType = [];
    BpodSystem.Data.StimFreq = [];
    BpodSystem.Data.StimAmp = [];
    BpodSystem.Data.NPulses = [];
    BpodSystem.Data.PulseDuration_ms = [];
    BpodSystem.Data.iTrial = [];
    BpodSystem.Data.TrialTypes = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.TrialOutcome = []; % onlineFilterTrials dependent on this variable
%     BpodSystem.Data.CSValence = []; % 1 = CS+, -1 = CS-, 0 = unCued or a 'control' Sound that doesn't affect outcomes or adaptive reversals
    BpodSystem.Data.ReinforcementOutcome = []; % i.e. Reward, Punish, WNoise, or Neutral
    BpodSystem.Data.WaterAmount = []; % i.e. WaterAmount
%     BpodSystem.Data.SoundAmplitude = []; % i.e. SoundAmplitude    
    BpodSystem.Data.LickAction = []; % 'lick' or 'noLick' 
%     BpodSystem.Data.SoundValve = []; % e.g. 1st sound = sound1, or sound2
%     BpodSystem.Data.SoundValveIndex = []; % 1st Sound, 2nd Sound
    BpodSystem.Data.Epoch = []; % onlineFilterTrials dependent on this variable
%     BpodSystem.Data.BlockNumber = [];
    BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
    BpodSystem.Data.SwitchParameterCriterion = [];
    BpodSystem.Data.AnswerLicks = struct('count', [], 'rate', [], 'duration', []); % number of licks during answer period, nTrials x 1
%     BpodSystem.Data.AnswerLicksROC = struct('auROC', [], 'pVal', [], 'CI', []); 
    lickOutcome = '';
    noLickOutcome = '';
    lickAction = '';
 
%% init lick raster plot
    lickRasterFig = ensureFigure('Licks', 1);
    lickRasterAx = axes('Parent', lickRasterFig);
    lickRasterFig2 = ensureFigure('Licks LaserOn', 1);
    lickRasterAx2 = axes('Parent', lickRasterFig2);
%% Outcome Plot
    trialsToShow = 50;
%     TrialTypes = [];
%     TrialOutcomes = [];
    BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [500 200 600 300],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none');
    BpodSystem.GUIHandles.OutcomePlot = axes;
    TrialTypeOutcomePlot2(BpodSystem.GUIHandles.OutcomePlot, 'init', BpodSystem.Data.TrialTypes);%, 'ntrials', trialsToShow);

    %% Main trial loop
    m = 1; 
    totalReward = 0;  
    for currentTrial = 1:S.GUI.maxTrials
   
        S.ITI = inf;
        while S.ITI > 3 * S.GUI.mu_iti   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
            S.ITI = exprnd(S.GUI.mu_iti); %
        end
        S = BpodParameterGUI2('sync', S); % Sync parameters with BpodParameterGUI plugin
 
        r = 1 / S.GUI.LaserRatio;
        if S.GUI.alternateLaser || S.GUI.alternateLED
           if mod(m,r)== 0
               useLaser = true;
               TrialType = 2;
           else
               useLaser = false;
               TrialType = 1;
           end
        else
            useLaser = false;
            TrialType = 1;
        end
        m = m + 1;
        % update outcome plot to show trial type of current trial with outcome undefined (NaN)
        TrialTypeOutcomePlot2(BpodSystem.GUIHandles.OutcomePlot, 'update',... 
            currentTrial, [BpodSystem.Data.TrialTypes TrialType], [BpodSystem.Data.TrialOutcome NaN]);   
        %TrialOutcome -> NaN: future trial or omission, -1: nolick+nolaser, 0: lick+laser, 1: lick+nolaser, 2: nolick+laser (see TrialTypeOutcomePlot)
        if useLaser
            %update current trial fields
            ActiveFreqIdx = find(logical(S.GUI.StimFreq.Active));
            n = floor (currentTrial/r);
            idx = mod(n,length(ActiveFreqIdx));
            if idx == 0
                idx=length(ActiveFreqIdx);
            end
            StimFreq = S.GUI.StimFreq.Freq(ActiveFreqIdx(idx));
            StimAmp = S.GUI.StimFreq.Amplitude(ActiveFreqIdx(idx));  
            NPulses = S.GUI.StimFreq.NPulses(ActiveFreqIdx(idx));
            PulseDuration_ms = S.GUI.StimFreq.PulseDuration_ms(ActiveFreqIdx(idx));
            % Action = {'GlobalTimerTrig', 2, 'WireState',  bitset(0, 3)};
            Action = {'GlobalTimerTrig', 2, 'BNCState',  2};
        else
            StimFreq = 0;
            StimAmp = 0;
            NPulses = 0;
            PulseDuration_ms = 0;
            Action = {'GlobalTimerTrig', 2,};
        end
        BpodSystem.Data.StimFreq(currentTrial) = StimFreq;
%         BpodSystem.Data.StimFreqIdx(currentTrial) = ActiveFreqIdx(idx);
        BpodSystem.Data.StimAmp(currentTrial) = StimAmp;
        BpodSystem.Data.NPulses(currentTrial) = NPulses;
        BpodSystem.Data.PulseDuration_ms(currentTrial) = PulseDuration_ms;
        BpodSystem.Data.iTrial(currentTrial) = currentTrial;
        
        if useLaser
            %Program PulsePal
            ParameterMatrix = ParameterMatrixDefault;
            if S.GUI.alternateLaser
                OutputChannels = 2;
            end
            if S.GUI.alternateLED
               OutputChannels = 4;
            end
%             OutputChannels = 2;
    %         OutputChannels = [1:4] .* ismember('1234',num2str(S.GUI.PulsePalOutputChannels));
    %         OutputChannels = OutputChannels(OutputChannels>0);
    %         OutputChannels = union(OutputChannels, S.GUI.PulsePalOutputTTL); % add the output TTL if not already specified in output channels    
    %         %TriggerChannel 
    %             % PulsePalTriggerChannel is 1 by default;
    %             ParameterMatrix(13,OutputChannels+1) = {1};
    %             ParameterMatrix(14,OutputChannels+1) = {0};
            %just one pulse? (e.g. using power meter)
            if NPulses == 1
                onePulse = true;
            else
                onePulse = false;
            end

            if ~onePulse
                %Inter-pulse interval
                ParameterMatrix(8,OutputChannels+1)={1./StimFreq - PulseDuration_ms/1000};
                %Burst Duration
                ParameterMatrix(9,OutputChannels+1)={1./StimFreq * NPulses};
                %stimulus train duration
                ParameterMatrix(11,OutputChannels+1)={1./StimFreq * NPulses};       
            else            
                %Inter-pulse interval
                ParameterMatrix(8,OutputChannels+1)={0};
                %Burst Duration
                ParameterMatrix(9,OutputChannels+1)={PulseDuration_ms/1000};
                %stimulus train duration
                ParameterMatrix(11,OutputChannels+1)={PulseDuration_ms/1000};
            end

            %single pulse duration
            ParameterMatrix(5,OutputChannels+1)={PulseDuration_ms/1000};               
            %amplitude       
            ParameterMatrix(3,OutputChannels+1)={StimAmp};
            %Stimulus Train Delay
            ParameterMatrix(12,OutputChannels+1)={S.GUI.PulseDelay_ms/1000};
            %override amplitude for TTL IF amplitude > 0?
%             ParameterMatrix(3,S.GUI.PulsePalOutputTTL) = {5}; % 5V for TTL logic
            
            ProgramPulsePal(ParameterMatrix);
        end
      %% Assemble state matrix  
%         Timer1 = S.GUI.Baseline + S.RewardValveTime;
        sma = NewStateMatrix(); % Assemble state matrix
        sma = SetGlobalTimer(sma,1,2); % counting down 2s + valvetime from baseline, if works then could do continuous small water rewarding + laser at 2s   
        sma = SetGlobalTimer(sma,2,4); 
        sma = AddState(sma, 'Name','Start',...
            'Timer', 0,...  %.05
            'StateChangeConditions',{'Tup','Reward'},...
            'OutputActions',{'GlobalTimerTrig', 1, 'WireState', bitset(0, 2)});   
        sma = AddState(sma, 'Name','Reward',...
            'Timer', S.PrimeRewardValveTime,...  %.05
            'StateChangeConditions',{'GlobalTimer1_End', 'Laser', 'Tup','AnswerDelay'},...
            'OutputActions',{'ValveState', S.GUI.RewardValveCode}); 
        sma = AddState(sma, 'Name','AnswerDelay',...
            'Timer', 2,...  %2s
            'StateChangeConditions',{'Port1In','AnswerLick', 'GlobalTimer1_End', 'Laser', 'Tup','Laser'},...
            'OutputActions',{});  
        sma = AddState(sma, 'Name', 'AnswerLick', ... 
            'Timer', 0.5,...
            'StateChangeConditions', {'GlobalTimer1_End', 'Laser', 'Tup', 'Reward'},...
            'OutputActions', {});
%         sma = AddState(sma,'Name', 'AnswerNoLick', ...
%             'Timer', 0,... % time will be 0 for omission
%             'StateChangeConditions', {'Tup', 'Neutral', 'GlobalTimer1_End', 'Laser'},...
%             'OutputActions', {}); 
%         sma = AddState(sma, 'Name','Neutral',...
%             'Timer', 0,...  %.05
%             'StateChangeConditions',{'GlobalTimer1_End', 'Laser', 'Tup','Laser'},...
%             'OutputActions',{}); 
        sma = AddState(sma,'Name', 'Laser', ...
            'Timer',0.05,... % 
            'StateChangeConditions', {'Tup', 'Post'},...
            'OutputActions', Action);        
        sma = AddState(sma, 'Name','Post',...
            'Timer', 4,... %1 
            'StateChangeConditions',{'Port1In','AnswerLick2', 'GlobalTimer2_End','ITI', 'Tup','ITI'},...
            'OutputActions',{});
        sma = AddState(sma, 'Name', 'AnswerLick2', ... 
            'Timer', 0.5,...
            'StateChangeConditions', {'Tup', 'Reward2', 'GlobalTimer2_End','ITI'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name','Reward2',...
            'Timer', S.RewardValveTime,...  %.05
            'StateChangeConditions',{'GlobalTimer2_End','ITI', 'Tup','AnswerDelay2'},...
            'OutputActions',{'ValveState', S.GUI.RewardValveCode}); 
        sma = AddState(sma, 'Name','AnswerDelay2',...
            'Timer', 3.5,...  %2s
            'StateChangeConditions',{'Port1In','AnswerLick2', 'GlobalTimer2_End','ITI', 'Tup','ITI'},...
            'OutputActions',{});  
        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer', S.ITI,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{});
        %%
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SendStateMatrix(sma);

        % Run state matrix
        RawEvents = RunStateMatrix();  % Blocking!
        disp(['*** Trial Type = ' num2str(TrialType) ' StimAmp' num2str(StimAmp) ' ***']);

        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
      %TrialOutcome -> NaN: future trial or omission, -1: nolick/neutral+nolaser, 0: lick/reward+laser, 1: lick/reward+nolaser, 2: nolick/neutral+laser (see TrialTypeOutcomePlot)
            if  isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Post)
                TrialOutcome = NaN;
            else
                if ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.AnswerLick(1))
                    lickAction = 'lick';
                    ReinforcementOutcome = 'Reward'; 
                    if useLaser
                        TrialOutcome = 0; %lick/reward+laser
                    else
                        TrialOutcome = 1; %lick/reward
                    end

                else
                    lickAction = 'nolick';
                    ReinforcementOutcome = 'Neutral';
                    if useLaser
                        TrialOutcome = 2; %nolick/neutral+laser
                    else
                        TrialOutcome = -1; %nolick/neutral
                    end
                end
            rew1 = length(find(~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.Reward(:, 1))));
            rew2 = length(find(~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.Reward2(:, 1))));
            rewardThisTrial = S.GUI.PrimeReward * rew1 + S.GUI.Reward * rew2;
            totalReward = totalReward + rewardThisTrial;
            end  
            
            
%             BpodSystem.Data.AnswerLicks.duration(end + 1) = diff(answerWindow);
%             BpodSystem.Data.AnswerLicks.rate(end + 1) = BpodSystem.Data.AnswerLicks.count(end) / BpodSystem.Data.AnswerLicks.duration(end);
% 
            BpodSystem.Data.TrialTypes(end + 1) = TrialType; % Adds the trial type of the current trial to data
            BpodSystem.Data.TrialOutcome(end + 1) = TrialOutcome;            
            BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;            
            BpodSystem.Data.ReinforcementOutcome{end + 1} = ReinforcementOutcome; % i.e. 1: reward, 2: neutral, 3: punish
            BpodSystem.Data.LickAction{end + 1} = lickAction;            
            BpodSystem.Data.WaterAmount(end + 1) = rewardThisTrial;
            
            
            % update outcome plot to reflect upcoming trial
            TrialTypeOutcomePlot2(BpodSystem.GUIHandles.OutcomePlot, 'update',...
                currentTrial, BpodSystem.Data.TrialTypes, BpodSystem.Data.TrialOutcome);  %for both trialtype1_nolaser and trialtype2_laser
            TotalRewardDisplay('add', rewardThisTrial);
            
%             % something for raster
%             BpodSystem.Data.TrialTypes(currentTrial) = 1; % 
%             BpodSystem.Data.TrialOutcome(currentTrial) = 1;
            
            % raster
            bpLickRaster(BpodSystem.Data, 1, 1, 'Laser', [], lickRasterAx); %for trialtype1 outcome1-lick/reward+nolaser only
            set(gca, 'XLim', [-2.5, 4.5]);
            
            bpLickRaster(BpodSystem.Data, 2, 0, 'Laser', [], lickRasterAx2); %for trialtype1 outcome1-lick/reward+nolaser only
            set(gca, 'XLim', [-2.5, 4.5]);
            
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            return
        end 
    end
end

