function AuditoryTuningOpto3
 % replaces reward with a trigger for pulse pal
    global BpodSystem
    
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S    
    defaults = {...
        'GUIPanels.Photometry', {'PhotometryOn', 'LED1_amp', 'LED2_amp', 'LED1', 'LED2', 'LED1_f', 'LED2_f', 'BilateralOn'};...
        'GUI.PhotometryOn', 1;...
        'GUI.LED1_amp', 1;...
        'GUI.LED2_amp', 5;...       
        'GUI.LED1', 1;...
        'GUIMeta.LED1.Style', 'checkbox';...    
        'GUI.LED2', 1;...
        'GUIMeta.LED2.Style', 'checkbox';...  
        'GUI.LED1_f', 531;...
        'GUI.LED2_f', 211;...
        'GUI.BilateralOn', 1;...
        'GUIMeta.BilateralOn.Style', 'checkbox';... 
        
        'GUIPanels.Timing', {'Epoch', 'Baseline', 'AcqLength', 'mu_IRI', 'mu_iti'};...
        'GUI.Epoch', 1;...
        'GUI.Baseline', 2;...
        'GUI.AcqLength', 7;... % Nidaq Acquisition time must > 5s but <baseline + RewardValve/Laser time + IRT
        'GUI.mu_IRI', 5;... % mean inter-reward interval       
        'GUI.mu_iti', 2;...
        
        'GUIPanels.Laser', {'Reward', 'RewardValveCode', 'PulseDuration_ms', 'PulseDelay_ms', 'StimFreq', 'NPulses', 'StimAmp','SoundOptoPairing'};... 
        'GUI.Reward', 8;...     
        'GUI.RewardValveCode', 1;...         
        'GUI.PulseDuration_ms', 1;...
        'GUI.PulseDelay_ms', 0;...
        'GUI.StimFreq', 10;...
        'GUI.NPulses', 20;...
        'GUI.StimAmp', 5;...
        'GUI.SoundOptoPairing', 0;...
        'GUIMeta.SoundOptoPairing.Style', 'checkbox';...
        
        'GUIPanels.TuningTest', {'SoundFreq', 'SoundAmp', 'SoundRepeat', 'BlockRepeat', 'PairedFreq'};... 
        'GUI.SoundAmp', 60;
        'GUI.SoundRepeat', 5;
        'GUI.BlockRepeat', 4;
        'GUI.PairedFreq', 15000;
        'GUI.SoundFreq.Freq', [0 1000 2500 5000 7500 10000 15000 20000 25000 30000 35000 40000]';... 
        'GUI.SoundFreq.Active', [1 1 1 1 1 1 1 1 1 1 1 1]';...
        'GUIMeta.SoundFreq.Style', 'table';...
        'GUIMeta.SoundFreqTable.ColumnLabel', {'Freq','Active'};...       
        
        'GUITabs.Photometry', {'Photometry'};...
        'GUITabs.Timing', {'Timing'};...
        'GUITabs.Laser', {'Laser'};...
        'GUITabs.TuningTest', {'TuningTest'};...
        
        'SoundSamplingRate', 192000;... 
        'Ramp', 0.05;...
        };
    
    S = setBpodDefaultSettings(S, defaults);
    
    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin 
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;
%     S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.GUI.RewardValveCode);
    S.LaserTime = 0.05; % just 50ms to trigger pulse pal now    
    %% Initialize NIDAQ
    S.nidaq.duration = S.GUI.AcqLength;
    S.nidaq.IsContinuous = false;
    S.nidaq.updateInterval = 0.1; % save new data every n seconds  
    startX = 0 - S.GUI.Baseline;
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        S = initPhotometry2(S);
    end
    % daq.reset;
    %% photometry plots
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        if S.GUI.BilateralOn
            updatePhotometryPlot4Ch('init', startX); %nidaq raw data, dff
            BpodSystem.PluginObjects.Photometry.baselinePeriod = [0 S.GUI.Baseline];
%             prfh('init', 'baselinePeriod', [1 4]) %phRasters
%             updatePhotometryPlotKatharinaBil('init',[0 0 0 0],{'Reward','Stimulus'});
        else
            updatePhotometryPlot4Ch('init', startX); %nidaq raw data, dff
%             updatePhotometryPlot('init', startX);
            BpodSystem.PluginObjects.Photometry.baselinePeriod = [0 S.GUI.Baseline];
%             prfh('init', 'baselinePeriod', [1 4])
%             updatePhotometryPlotKatharina('init',[0 0],{'Reward','Stimulus'});
        end
    end
    %% Initialize Sound Stimuli    
    SF = 192000;     
    PsychToolboxSoundServer('init')   
    %% define opto-stimulation parameters
    if S.GUI.SoundOptoPairing
       PulsePal('COM5');
        % load default PulsePal stimulus train matrix        
        ParameterMatrixDefault =  load('LightTrain.mat');             
        ParameterMatrix = ParameterMatrixDefault.wheel_opto_pulse_burst;
        OutputChannels = 4;               
        %single pulse duration
        ParameterMatrix(5,OutputChannels+1)={S.GUI.PulseDuration_ms/1000};
        %Inter-pulse interval
        ParameterMatrix(8,OutputChannels+1)={1./S.GUI.StimFreq - S.GUI.PulseDuration_ms/1000};
        %Burst Duration
        ParameterMatrix(9,OutputChannels+1)={1./S.GUI.StimFreq * S.GUI.NPulses};
        %stimulus train duration
        ParameterMatrix(11,OutputChannels+1)={1./S.GUI.StimFreq * S.GUI.NPulses};         
        %Stimulus Train Delay
        ParameterMatrix(12,OutputChannels+1)={S.GUI.PulseDelay_ms/1000};
%         %override amplitude for TTL        
%         ParameterMatrix(3,OutputChannels+1)={StimAmp};        
%         ProgramPulsePal(ParameterMatrix); 
    end
    %% load default PulsePal stimulus train matrix
        % alternate LED modulation mode
       typeMatrix = [...
            1, 0;...   
            2, 1000;...  
            3, 2500;...  
            4, 5000;...  
            5, 7500;...  
            6, 10000;...
            7, 15000;...
            8, 20000;...
            9, 25000;...
            10, 30000;...
            11, 35000;...
            12, 40000;...
            ];
        
    ActiveSoundIdx = find(S.GUI.SoundFreq.Active);    
    if S.GUI.SoundOptoPairing
        ActiveTypes = [ActiveSoundIdx; ActiveSoundIdx]; % if pairing : tuning = 1:1 
%         ActiveTypes = [ActiveSoundIdx; ActiveSoundIdx; ActiveSoundIdx]; % if pairing : tuning = 2:1 
    else
        ActiveTypes = ActiveSoundIdx;
    end
    Types = length(ActiveTypes);
    MaxTrials = Types * S.GUI.SoundRepeat * S.GUI.BlockRepeat; % repeat times for each sound frequency
    totalReward = 0; 
           
    %% determine nidaq/point grey and olfactometer triggering arguments
    npgWireArg = 0;
    npgBNCArg = 1; % BNC 1 source to trigger Nidaq is hard coded
    % if ~BpodSystem.EmulatorMode        
    % % retrieve machine specific point grey camera settings
    %     addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
    %     pgSettings = machineSpecific_pointGrey;    
    %     switch pgSettings.triggerType
    %         case 'WireState'
    %             npgWireArg = bitset(npgWireArg, pgSettings.triggerNumber); % its a wire trigger
    %         case 'BNCState'
    %             npgBNCArg = bitset(npgBNCArg, pgSettings.triggerNumber); % its a BNC trigger
    %     end       
    % end    

    %% Main trial loop
    for iTrial = 1:MaxTrials 
        nRewardThisTrial = 0;            
        disp([' *** Trial # ' num2str(iTrial)]); 
        % Update NIDAQ                                                                                                                            
        S.nidaq.duration = S.GUI.AcqLength;   
        startX = 0 - S.GUI.Baseline; 
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI        
        BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
        BpodSystem.Data.Settings = S;
        
        %update current trial fields         
        S.ITI = inf;
        while S.ITI > 3 * S.GUI.mu_iti   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
            S.ITI = exprnd(S.GUI.mu_iti);
        end 
        
        idx = floor((iTrial-1)/S.GUI.SoundRepeat) + 1; % determine trial type/sound frequency divided by sound repeat times   
        if mod(idx,Types)== 0
            idx2 = Types;
        else
            idx2 = mod(idx,Types);
        end
                
        if S.GUI.SoundOptoPairing                   
            PairingMode = floor((idx2-1) / (Types/2)) + 1; % if pairing : tuning = 1:1 
%             PairingMode = floor((idx2-1) / (Types/3)) + 1; % if pairing : tuning = 2:1 
            switch PairingMode
                case 1    % Pairing On, if pairing : tuning = 1:1
%                 case {1, 2}    % Pairing On, if pairing : tuning = 2:1
                    TrialType = ActiveTypes(idx2);
                    SoundFreq = typeMatrix(TrialType, 2);
                    if ismember(SoundFreq, [0; S.GUI.PairedFreq])
                        StimAmp = S.GUI.StimAmp;
                    else
                        StimAmp = 0;
                    end                        
                case 2    % Pairing Off, if pairing : tuning = 1:1  
%                 case 3    % Pairing Off, if pairing : tuning = 2:1
                    TrialType = ActiveTypes(idx2);
                    SoundFreq = typeMatrix(TrialType, 2);
                    StimAmp = 0;     
            end
        else
            PairingMode = 2; % if pairing : tuning = 1:1 
%             PairingMode = 3; % if pairing : tuning = 2:1 
            TrialType = ActiveTypes(idx2);
            SoundFreq = typeMatrix(TrialType, 2);
            StimAmp = 0;            
        end        
        SoundDura = 2;
        SoundAmp = S.GUI.SoundAmp;
        Tone = SoundGenerator_SL(S.SoundSamplingRate, S.Ramp, SoundFreq, SoundDura, SoundAmp);
        PsychToolboxSoundServer('Load', 3, Tone);
        BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
        BpodSystem.Data.TrialType(iTrial) = TrialType;
        BpodSystem.Data.PairingMode(iTrial) = PairingMode; % 1, Pairing on; 2, Paring off.
        BpodSystem.Data.SoundFreq(iTrial) = SoundFreq;
        BpodSystem.Data.SoundDura(iTrial) = SoundDura;
        BpodSystem.Data.SoundAmp(iTrial) = SoundAmp;        
        BpodSystem.Data.StimAmp(iTrial) = StimAmp;
        BpodSystem.Data.iTrial(iTrial) = iTrial; 
        
        disp([' *** TrialType' num2str(TrialType) ' PairingMode' num2str(PairingMode) ' SoundFreq' num2str(SoundFreq) ' StimAmp' num2str(StimAmp)]); 
        
        % state matrix construction                
        sma = NewStateMatrix();      
%         sma = SetGlobalTimer(sma,1,S.GUI.AcqLength); % photometry acq duration
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0.025,...
            'StateChangeConditions', {'Tup', 'Baseline'},...
            'OutputActions', {'BNCState', npgBNCArg, 'WireState', npgWireArg, 'GlobalTimerTrig', 1, 'SoftCode', 255});
        if S.GUI.SoundOptoPairing % if we are doing opto-pairing
            sma = AddState(sma, 'Name','Baseline',...
            'Timer',S.GUI.Baseline,...
            'StateChangeConditions',{'Tup','DeliverStimulus'},...
            'OutputActions',{});             
            updatePulsePal; % nested function for legibility
        else % if you aren't doing opto-pairing, 
            sma = AddState(sma, 'Name','Baseline',...
                'Timer',S.GUI.Baseline,...
                'StateChangeConditions',{'Tup', 'DeliverStimulus'},...
                'OutputActions',{});  
            sma = AddState(sma,'Name', 'DeliverStimulus', ... 
                'Timer', S.LaserTime,... %
                'StateChangeConditions', {'Tup', 'IRI'},...
                'OutputActions', {'SoftCode', 3});       
            sma = AddState(sma,'Name', 'IRI', ... % use global timer
                'Timer', S.GUI.mu_IRI,...
                'StateChangeConditions', {'Tup','ITI'},...
                'OutputActions', {});
            sma = AddState(sma,'Name', 'ITI', ...
                'Timer', S.ITI,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'SoftCode', 255});
        end
        %
        SendStateMatrix(sma);

        % prep data acquisition

            if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
                preparePhotometryAcq2(S);
                % Run state matrix        
                RawEvents = RunStateMatrix();  
%                 disp('*** trial ended ***');
                % Stop Photometry session
                stopPhotometryAcq2;
                % Process NIDAQ session
                try 
                    processPhotometryAcq2(iTrial);                
                catch
                    disp('*** Data not saved, issue with processPhotometryAcq ***');
                end
                % online plotting
                try 
                    % online plotting of photometry rawdata and dFF
                    processPhotometryOnline2(iTrial);
                    if S.GUI.BilateralOn
                       updatePhotometryPlot4Ch('update', startX);
                       xlabel('Time from Cue (s)');
                    else
%                        updatePhotometryPlot('update', startX); 
                       updatePhotometryPlot4Ch('update', startX);
                       xlabel('Time from Cue (s)');
                    end
                catch
                    disp('*** Problem with online photometry processing ***');
                end
            else
                RawEvents = RunStateMatrix();  
%                 disp('*** trial ended ***');
            end
       
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            % collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(iTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)      
            % save data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file            
        else
            disp([' *** Trial # ' num2str(iTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end      
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
%             if ~BpodSystem.EmulatorMode
% %                 fclose(valveSlave);
% %                 delete(valveSlave);
%             end
            return
        end 
    end
%% Nested function for code legibility
    function updatePulsePal         
        %override amplitude for TTL        
        ParameterMatrix(3,OutputChannels+1)={StimAmp};
        
        ProgramPulsePal(ParameterMatrix); 
                
        % append to state matrix
            sma = AddState(sma,'Name', 'DeliverStimulus', ... 
                'Timer', S.LaserTime,... %
                'StateChangeConditions', {'Tup', 'IRI2'},...
                'OutputActions', {'WireState',  bitset(0, 3), 'SoftCode', 3});                   
            sma = AddState(sma,'Name', 'IRI2', ... % use global timer
                'Timer', S.GUI.mu_IRI,...
                'StateChangeConditions', {'Tup','ITI2'},...
                'OutputActions', {});
            sma = AddState(sma,'Name', 'ITI2', ...
                'Timer', S.ITI,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'SoftCode', 255});
    end
end