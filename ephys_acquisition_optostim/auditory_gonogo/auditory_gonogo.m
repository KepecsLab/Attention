function [obj] = auditory_gonogo(varargin)
% This protocol requires mice to respond to a tone embedded in white noise
% and not respond to absence of tone in white noise.
% Task has only 1 reward port active
% Punishment for false alarm is timeout.

% SPR 2011-03-01

global ResponseCounter
global MaxTrials
global BlockMemory
global LaserTimer_agonogo   % get this for sure to be able to stimulate
global AO   % anolog output object from laser stim. protocol
MaxTrials = 10000;
Operant = [];

RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));    % initialize the state of the random generator

% =============================================

% Default object is of our own class (mfilename);
% We inherit from Plugins/@pluginname

obj = class(struct, mfilename, saveload, water, soundmanager, pokesplot);

%---------------------------------------------------------------
%   BEGIN SECTION COMMON TO ALL PROTOCOLS, DO NOT MODIFY
%---------------------------------------------------------------

% If creating an empty object, return without further ado:
if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty')),
    return;
end;

if isa(varargin{1}, mfilename), % If first arg is an object of this class itself, we are
    % Most likely responding to a callback from
    % a SoloParamHandle defined in this mfile.
    if length(varargin) < 2 || ~isstr(varargin{2}),
        error(['If called with a "%s" object as first arg, a second arg, a ' ...
            'string specifying the action, is required\n']);
    else action = varargin{2}; varargin = varargin(3:end);
    end;
else % Ok, regular call with first param being the action string.
    action = varargin{1}; varargin = varargin(2:end);
end;
if ~isstr(action), error('The action parameter must be a string'); end;

GetSoloFunctionArgs(obj);

%---------------------------------------------------------------
%   END OF SECTION COMMON TO ALL PROTOCOLS, MODIFY AFTER THIS LINE
%---------------------------------------------------------------

switch action
    
    %---------------------------------------------------------------
    %          CASE init
    %---------------------------------------------------------------
    
    case 'init'
        
        SoloParamHandle(obj, 'myfig', 'saveable', 0); myfig.value = figure;
        name = mfilename;
        set(value(myfig), 'Name', name, 'Tag', name, ...
            'closerequestfcn', 'dispatcher(''close_protocol'')', 'MenuBar', 'none');
        
        % --------------  Initialize Main Figure Window ----------------
        set(value(myfig), 'Position', [400   300   900   750]);
        xpos = 5; ypos = 5; maxypos=5; % Initial position on main GUI window
        
        % --------------  Initialize Save/Load and Water ----------------
        % From Plugins/@saveload:
        [xpos, ypos] = SavingSection(obj, 'init', xpos, ypos);
        SavingSection(obj,'set_autosave_frequency',10);
        ResponseCounter = 0;
        
        % From Plugins/@water:
        [xpos, ypos] = WaterValvesSection(obj, 'init', xpos, ypos);
        WaterValvesSection(obj, 'set_water_amounts', 5, 5, 5); % HR
        xpos = 220;ypos = 5;
        
        % --------------  Initialize General Task Parameters ----------------
        NumeditParam(obj, 'IdleTrials2Suspend', 10000, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'Punish_ITI', 1, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'DrinkTime', 2, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'RespDur',4, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'Delay2Resp',0.8, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'StimDur', [0.5 0.1 0.05], xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'StimProb', .5, xpos, ypos); next_row(ypos,1.5);
        
        % ------------- OPTOGENETICS PARAMETERS ---------------------------
        NumeditParam(obj, 'LightProb', 0, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'LightProb2', 0, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'LightDur', 1, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'LightLatency', 0.5, xpos, ypos); next_row(ypos,1.5);
        MenuParam(obj, 'LightStimType', {'Blockwise', 'TrialByTrial'}, 'Blockwise', xpos, ypos); next_row(ypos,1.5);
        SoloParamHandle(obj, 'LightStimList', 'value', nan(1,MaxTrials)); % Actual vector of StimDurs.
        
        % --------------- ITI parameters ----------------------------------
        SubheaderParam(obj, 'title', 'Trial Parameters', xpos, ypos);
        next_row(ypos, 1.5);
        xpos = 440; ypos=5;
        NumeditParam(obj, 'ITIMax', 15, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'ITIMin', 2, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'ITISD',3, xpos, ypos); next_row(ypos,1.5);
        NumeditParam(obj, 'ITIMean', 6, xpos, ypos); next_row(ypos,1.5);
        MenuParam(obj, 'ITIDistrib', {'EXP', 'UNIFORM', 'GAUSS', 'BIMODAL', 'UNIMODAL'}, 'GAUSS', xpos, ypos); next_row(ypos);
        SubheaderParam(obj, 'title', 'ITI Distribution parameters', xpos, ypos); next_row(ypos, 1.5);
        
        % --------------  Training Parameters ------------------
        NumeditParam(obj, 'BlockSize', 30, xpos, ypos); next_row(ypos,1.0);
        NumeditParam(obj, 'MaxAntiBias', 0, xpos, ypos); next_row(ypos,1.0);
        MenuParam(obj, 'Anti_Bias', {'On', 'Off','Inf'}, 'Off', xpos, ypos); next_row(ypos);
        MenuParam(obj, 'AllowEarly', {'On', 'Off'}, 'Off', xpos, ypos); next_row(ypos);
        MenuParam(obj, 'AllowRestartITI', {'On', 'Off'}, 'On', xpos, ypos,...
            'TooltipString','controls whether lick during iti will lead to nopoke iti'); next_row(ypos);
        NumeditParam(obj, 'LeftRTWins', 0, xpos, ypos); next_row(ypos);
        NumeditParam(obj, 'RightRTWins', 0, xpos, ypos); next_row(ypos);
        MenuParam(obj, 'DirectDelivery', {'On', 'Off'}, 'Off', xpos, ypos); next_row(ypos);
        NumeditParam(obj, 'Hits', 0, xpos, ypos); next_row(ypos);
        NumeditParam(obj, 'RightRewards', 0, xpos, ypos); next_row(ypos);
        MenuParam(obj, 'Operant', {'On', 'Off'}, 'Off', xpos, ypos); next_row(ypos);
        MenuParam(obj, 'SignalModality', {'VISUAL','AUDITORY'}, 'AUDITORY', xpos, ypos); next_row(ypos);
        xpos = 660; ypos=5;
        NumeditParam(obj, 'SoundIntensity',[60 70],xpos, ypos,'TooltipString','dB'); next_row(ypos,1.25);
        NumeditParam(obj, 'SoundDuration',1, xpos, ypos); next_row(ypos,1.25);
        NumeditParam(obj, 'PunishSoundDuration',0.25, xpos, ypos); next_row(ypos,1.25);
        NumeditParam(obj, 'SoundFrequency',18000, xpos, ypos); next_row(ypos,1.25);
        NumeditParam(obj, 'DirectWait4PickupDur', 90, xpos, ypos); next_row(ypos,1.25); % Amount of time to wait for animal to get DD reward
        NumeditParam(obj, 'DDTargetRT', 3, xpos, ypos); next_row(ypos,1.25); % Max # of seconds the subject can take to respond to get a point for DirectDelivery mode
        NumeditParam(obj, 'DDThreshold', 10, xpos, ypos); next_row(ypos,1.25); % # of successful DD responses per side
        NumeditParam(obj, 'OperantThreshold', 10, xpos, ypos); next_row(ypos,1.25); % # of successful reward retrievals for each side
        NumEditParam(obj, 'PunishSoundIntensity',80, xpos, ypos,'TooltipString','dB'); next_row(ypos,1.25);
        MenuParam(obj,    'PunishSound', {'On', 'Off'}, 'On', xpos, ypos); next_row(ypos,1.25);
        MenuParam(obj,    'AirPuff', {'On', 'Off'}, 'On', xpos, ypos); next_row(ypos,1.25);
        MenuParam(obj,    'WhiteNoise', {'On', 'Off'}, 'On', xpos, ypos); next_row(ypos,1.25);
        NumEditParam(obj, 'WhiteNoiseIntensity',60, xpos, ypos,'TooltipString','dB'); next_row(ypos,1.25);
        NumeditParam(obj, 'NumBlocks', 100, xpos, ypos, 'TooltipString', '-1 = inf'); next_row(ypos,1.25);
        NumeditParam(obj, 'TrialsPerBlock', 3, xpos, ypos, 'TooltipString', '# of each condition per block'); next_row(ypos,1.25);
        
        NumeditParam(obj, 'PulseTrainDuration', 300000, xpos, ypos, 'TooltipString', 'ms'); next_row(ypos,1.5);
        NumeditParam(obj, 'BurstDuration', 250, xpos, ypos, 'TooltipString', 'ms'); next_row(ypos,1.5);
        NumeditParam(obj, 'BurstInterval', 250, xpos, ypos, 'TooltipString', 'ms'); next_row(ypos,1.5);
        NumeditParam(obj, 'PulseInterval', 12, xpos, ypos, 'TooltipString', 'ms'); next_row(ypos,1.5);
        NumeditParam(obj, 'PulseDuration', 1, xpos, ypos, 'TooltipString', 'ms'); next_row(ypos,1.5);
        
        set_callback({SoundDuration; SoundFrequency; Punish_ITI},{'MakeAndUploadSounds','update'});
        set_callback({PunishSound; PunishSoundIntensity; PunishSoundDuration; WhiteNoise; WhiteNoiseIntensity;...
            },{'MakeAndUploadSounds','update2'});
        
        % --------------  Initialize Non-GUI Parameters ----------------
        SoloParamHandle(obj, 'HitHistory','value', nan(value(MaxTrials),1));
        
        BlockMemory = zeros(1,value(BlockSize));
        xpos = 120;
        SoloParamHandle(obj, 'LeftAction', 'value', 'hit');
        SoloParamHandle(obj, 'TimeUpAction', 'value', 'miss');
        SoloParamHandle(obj, 'IdleTrialCount', 'value', 0);
        SoloParamHandle(obj, 'TrialTypeList', 'value', nan(1,MaxTrials)); % 'l' or 'r' type.
        SoloParamHandle(obj, 'TrialTypes', 'value', zeros(1,MaxTrials)); % 0 for no-stim 1-length(StimDur) for stim trials
        SoloParamHandle(obj, 'LightStimulation2', 'value', zeros(1,MaxTrials)); % 0 for no-stim 1 for stimulation during ITI
        SoloParamHandle(obj, 'StimDurList', 'value', nan(1,MaxTrials)); % Actual vector of StimDurs.
        SoloParamHandle(obj, 'ITIs', 'value', zeros(1,MaxTrials));
%         for itiss = 2:15   % initialize additional ITIs for restart ITI states
%             eval(['SoloParamHandle(obj, ''ITIs' num2str(itiss) ''', ''value'', zeros(1,MaxTrials));']);
%         end
        
        set_callback({SignalModality; NumBlocks; TrialsPerBlock; StimProb; StimDur; StimDurList;LightDur;LightProb},{'auditory_gonogo','Update_TrialTypes'});
        set_callback({ITIMean; ITISD; ITIMin; ITIMax; ITIDistrib},{'auditory_gonogo','Update_TrialTypes'});
        set_callback({SoundDuration; SoundFrequency; SoundIntensity},{'auditory_gonogo','Update_TrialTypes'});
%         set_callback({SoundDuration; SoundFrequency; SoundIntensity},{'MakeAndUploadSounds','update'});
        
        SoloFunctionAddVars('StateMatrixSection', 'rw_args',...
            {'StimDur','Delay2Resp','RespDur','DrinkTime',...
            'LightDur','LightProb','LightLatency','LightStimType',...
            'IdleTrials2Suspend','Punish_ITI','AirPuff',...
            'IdleTrialCount','AllowEarly','AllowRestartITI','DirectDelivery','Operant',...
            'OperantThreshold','Hits','RightRewards',...
            'DirectWait4PickupDur','DDTargetRT','DDThreshold','LeftRTWins','RightRTWins',...
            'SoundDuration','SoundFrequency','SignalModality','PunishSoundDuration'...
            'PunishSound','PunishSoundIntensity', 'PunishSoundDuration', 'WhiteNoise','WhiteNoiseIntensity'});
        
        % --------------  Set trial types ----------------
        % can be separated into a SidesSection
        auditory_gonogo(obj,'Update_TrialTypes');
        
        % --------------  Initialize Trial Outcome Plot ----------------
        
        SoloParamHandle(obj, 'RewardSideList','value', nan(value(MaxTrials),1));
        
        RewardSideList.labels.poke  = 1;
        RewardSideList.labels.nopoke = 2;
        RewardSideList.values = nan(value(MaxTrials),1);
        
        SoloFunctionAddVars('SidesPlotSection', 'rw_args',...
            {'TrialTypeList', 'RewardSideList'});
        
        [xpos, ypos] = SidesPlotSection(obj, 'init', xpos, ypos, ...
            TrialTypeList);
        next_row(ypos);
        
        % --------------  Initialize Sounds ----------------
        
        SoloFunctionAddVars('MakeAndUploadSounds', 'rw_args',...
            {'SoundDuration','SoundFrequency','SignalModality','TrialTypeList',...
            'PunishSound','PunishSoundDuration','StimDurList','Punish_ITI',...
            'SoundDuration','SoundFrequency','SignalModality','PunishSoundDuration'...
            'PunishSound','PunishSoundIntensity', 'PunishSoundDuration', 'WhiteNoise','WhiteNoiseIntensity'});
        
        MakeAndUploadSounds(obj, 'init', 'SoundDuration', value(SoundDuration));
        
        
        % ------------------ From PerformancePlotSection ------------------
        PerformancePlotSection(obj, 'init', xpos, ypos, value(MaxTrials),{'left','right'});
        
        
        % ---------------- Set BOSS Parameters -------------------
        %         InitializeBOSSModule;
        %         SetBOSSParameters('PulseDuration', value(PulseDuration), 'PulseInterval', value(PulseInterval),'BurstDuration', value(BurstDuration), 'BurstInterval', value(BurstInterval), 'PulseTrainDuration', value(PulseTrainDuration));
        %         set_callback({PulseDuration, PulseInterval, BurstDuration, BurstInterval, PulseTrainDuration}, {'SetBOSSParameters','''PulseDuration''',value(PulseDuration),'''PulseInterval''',value(PulseInterval),'''BurstDuration''',value(BurstDuration),'''BurstInterval''',value(BurstInterval),'''PulseTrainDuration''',value(PulseTrainDuration)});
        
        % ----------------------  Prepare first (empty) trial ---------------------
        sma = StateMachineAssembler('full_trial_structure');
        sma = add_state(sma, 'name', 'final_state', ...
            'self_timer', 2, 'input_to_statechange', {'Tup', 'check_next_trial_ready'});
        dispatcher('send_assembler', sma, 'check_next_trial_ready');
        
        %---------------------------------------------------------------
        %          CASE Update_TrialTypes
        %---------------------------------------------------------------
    case 'Update_TrialTypes'
        
        % Make this such that it takes StimProb into account.
        if strcmp(value(SignalModality), 'VISUAL')
            PossibleTrialTypes = [value(StimDur) zeros(1, length(value(StimDur)))];
        else
%             PossibleTrialTypes = [value(SoundIntensity) zeros(1, length(value(SoundIntensity)))];
            PossibleTrialTypes = repmat(value(SoundIntensity),1,2);
            TrialSides = [zeros(1,length(value(SoundIntensity))) ones(1,length(value(SoundIntensity)))];
        end
        
        if value(NumBlocks) ~= -1
            %%FIX ME
            % For Blocks, if I change something during the session it will change the trialtypelist from 1:MaxTrials
            % and not from n_done_trials.
            % Also does not work for StimProb ~= 0.5.
            if value(LightProb) == 0.5
                LightStimList.value = repmat([zeros(1,length(value(PossibleTrialTypes))*value(TrialsPerBlock)), ones(1,length(value(PossibleTrialTypes))*value(TrialsPerBlock))], 1, value(NumBlocks)/2);
            else
                LightStimList.value = repmat([zeros(1,length(value(PossibleTrialTypes))*value(TrialsPerBlock)*2)], 1, value(NumBlocks));
            end
            PossibleTrialTypes = repmat(PossibleTrialTypes, 1, value(TrialsPerBlock));
            TrialSides = repmat(TrialSides, 1, value(TrialsPerBlock));
            TempStimDurList = [];
            TempTrialSideList = [];
            for i = 1:value(NumBlocks)
                TempStimDurList = [TempStimDurList PossibleTrialTypes(randperm(length(PossibleTrialTypes)))];
                TempTrialSideList = [TempTrialSideList TrialSides(randperm(length(TrialSides)))];
                StimDurList.value = TempStimDurList;
            end
            TrialTypeList(TempTrialSideList~=0) = 'l';
            TrialTypeList(TempTrialSideList==0) = 'r';
            
        else
            for x=n_done_trials+1:MaxTrials
                if rand<value(StimProb) % Is this a stimulus trial?
                    % Then make this a left trial...
                    TrialTypeList(x)='l';
                    % ...and toss a coin to determine which StimDur or
                    % SoundIntensity to use
                    switch value(SignalModality)
                        case 'VISUAL'
                            [randnum,StimDur_ind]=max(rand(1,length(value(StimDur))));
                            StimDurList(x)=StimDur(StimDur_ind);
                            TrialTypes(x)=StimDur_ind;
                        case 'AUDITORY'
                            [randnum,StimDur_ind]=max(rand(1,length(value(SoundIntensity))));
                            StimDurList(x)=SoundIntensity(StimDur_ind);
                            TrialTypes(x)=StimDur_ind;
                    end
                else
                    TrialTypeList(x)='r';
%                     StimDurList(x)=0;
%                     TrialTypes(x)=0;
                    [randnum,StimDur_ind]=max(rand(1,length(value(SoundIntensity))));
                    StimDurList(x)=SoundIntensity(StimDur_ind);
                    TrialTypes(x)=StimDur_ind;
                end
                if rand<value(LightProb),
                    LightStimList(x)=1;
                else
                    LightStimList(x)=0;
                end
            end
        end
        % ------------------ Prepare the ITIs ----------------------
        FutureTrialIndices=n_done_trials+1:MaxTrials;
        NumTrials=size(FutureTrialIndices,2);
        switch value(ITIDistrib)
            case 'EXP'
                mns = value(ITIMean);
                ITIMean2 = mns(1) - value(ITIMin);
                ITIMax2 = value(ITIMax) - value(ITIMin);
                temp = exprnd(ITIMean2,NumTrials,1);
                while any(temp>ITIMax2)
                    inx = temp > ITIMax2;
                    temp(inx) = exprnd(ITIMean2,sum(inx),1);
                end
                temp = temp + value(ITIMin);
                ITIs(FutureTrialIndices) = temp;
%                 for itiss = 2:14    % additional sets of ITIs for restart ITI states
%                     temp = exprnd(ITIMean2,NumTrials,1);
%                     while any(temp>ITIMax2)
%                         inx = temp > ITIMax2;
%                         temp(inx) = exprnd(ITIMean2,sum(inx),1);
%                     end
%                     temp = temp + value(ITIMin);
%                     eval(['ITIs' num2str(itiss) '(FutureTrialIndices) = temp;']);
%                 end
            case 'UNIFORM'
                ITIs(FutureTrialIndices) = unifrnd(value(ITIMin),value(ITIMax),NumTrials,1);
%                 for itiss = 2:14
%                     temp =  unifrnd(value(ITIMin),value(ITIMax),NumTrials,1);
%                     eval(['ITIs' num2str(itiss) '(FutureTrialIndices) = temp;']);
%                 end
            case 'GAUSS'
                mns = value(ITIMean);
                ITIMean2 = mns(1) - value(ITIMin);
                ITIMax2 = value(ITIMax) - value(ITIMin);
                temp = normrnd(ITIMean2,value(ITISD),NumTrials,1);
                while any(temp>ITIMax2) || any(temp<0)
                    inx = temp > ITIMax2 | temp < 0;
                    temp(inx) = normrnd(ITIMean2,value(ITISD),sum(inx),1);
                end
                temp = temp + value(ITIMin);
                ITIs(FutureTrialIndices) = temp;
%                 for itiss = 2:14
%                     temp = normrnd(ITIMean2,value(ITISD),NumTrials,1);
%                     while any(temp>ITIMax2) || any(temp<0)
%                         inx = temp > ITIMax2 | temp < 0;
%                         temp(inx) = normrnd(ITIMean2,value(ITISD),sum(inx),1);
%                     end
%                     temp = temp + value(ITIMin);
%                     eval(['ITIs' num2str(itiss) '(FutureTrialIndices) = temp;']);
%                 end
            case 'BIMODAL'
                ITImin = value(ITIMin);  % ITIMin = 0.1;
                ITImax = value(ITIMax);  % ITIMax = 3;
                mns = value(ITIMean);
                mng1 = mns(1);   % mng1 = 0.3;   % parameters for the Gaussians
                mng2 = mns(end);   % mng2 = 2;
                sdg = value(ITISD);   % sdg = 0.15;
                pmx1 = 0.35;   % mixing probabilities
                pmx2 = 0.35;
                pmx3 = 1 - pmx1 - pmx2;
                
                ITIs1 = random('Normal',mng1,sdg,1,NumTrials);
                while any(ITIs1>ITImax) || any(ITIs1<ITImin)
                    inx = ITIs1 > ITImax  | ITIs1 < ITImin;
                    ITIs1(inx) = random('Normal',mng1,sdg,1,sum(inx));
                end
                ITIs2 = random('Normal',mng2,sdg,1,NumTrials);
                while any(ITIs2>ITImax) || any(ITIs2<ITImin)
                    inx = ITIs2 > ITImax  | ITIs2 < ITImin;
                    ITIs2(inx) = random('Normal',mng2,sdg,1,sum(inx));
                end
                ITIs3 = random('Uniform',ITImin,ITImax,1,NumTrials);
                prr = rand(1,NumTrials);
                rr = zeros(3,NumTrials);
                rr(1,prr<pmx1) = 1;
                rr(2,prr>=pmx1&prr<(pmx1+pmx2)) = 1;
                rr(3,prr>=(pmx1+pmx2)) = 1;
                ITIs(FutureTrialIndices) = rr(1,:) .* ITIs1 + rr(2,:) .* ITIs2 + rr(3,:) .* ITIs3;
            
            case 'UNIMODAL'
                ITImin = value(ITIMin);  % ITIMin = 0.1;
                ITImax = value(ITIMax);  % ITIMax = 3;
                mns = value(ITIMean);
                mng = mns(1);   % mng = 1.4;   % parameters for the Gaussians
                sdg = value(ITISD);   % sdg = 0.25;
                pmx1 = 0.65;   % mixing probabilities
                pmx2 = 1 - pmx1;
                
                ITIs1 = random('Normal',mng,sdg,1,NumTrials);
                while any(ITIs1>ITIMax) | any(ITIs1<ITIMin)
                    inx = ITIs1 > ITIMax  | ITIs1 < ITIMin;
                    ITIs1(inx) = random('Normal',mng,sdg,1,sum(inx));
                end
                ITIs2 = random('Uniform',ITIMin,ITIMax,1,NumTrials);
                prr = rand(1,NumTrials);
                rr = zeros(2,NumTrials);
                rr(1,prr<pmx1) = 1;
                rr(2,prr>=pmx1) = 1;
                ITIs(FutureTrialIndices) = rr(1,:) .* ITIs1 + rr(2,:) .* ITIs2;
                
        end
%         ITIs15(FutureTrialIndices) = ones(size(FutureTrialIndices));   % after 14 restarted ITIs, 1 sec ITIs coming
%         SoloFunctionAddVars('StateMatrixSection', 'rw_args',...
%             {'TrialTypes','TrialTypeList','ITIs','ITIs2','ITIs3','ITIs4','ITIs5',...
%             'ITIs6','ITIs7','ITIs8','ITIs9','ITIs10','ITIs11','ITIs12','ITIs13',...
%             'ITIs14','ITIs15','StimDurList','LightStimList'});
%         figure
%         hist(ITIs,30)
        SoloFunctionAddVars('StateMatrixSection', 'rw_args',...
            {'TrialTypes','TrialTypeList','ITIs','StimDurList','LightStimList'});
        
        
        SoloFunctionAddVars('SidesPlotSection', 'rw_args',...
            {'TrialTypes','TrialTypeList','StimDurList'});
        
        %SidesPlotSection(obj, 'update', n_done_trials+1, ...
        %    TrialTypeList,...
        %    HitHistory);
        
        %---------------------------------------------------------------
        %          CASE prepare_next_trial
        %---------------------------------------------------------------
    case 'prepare_next_trial'
        
        te = disassemble(current_assembler, raw_events, 'parsed_structure', 1);
        
        if(n_done_trials>1)
            %             disp(n_done_trials)
            % Update RT win counts if in DirectDelivery mode
            if strcmp(value(DirectDelivery),'On')
                if ~isempty(te.states.hit)|~isempty(te.states.correctreject) % if he got it right
                    if TrialTypeList(n_done_trials) == 'l'
                        if isempty(te.states.direct)
                            try
                                RT = te.states.hit(1) - te.states.beginresponse(1);
                                fprintf('%d-Hit: RT %2.2f',n_done_trials,RT)
                            catch
                                RT = te.states.hit(1) - te.states.deliverstim(2);
                                fprintf('%d-Hit: RT %2.2f',n_done_trials,RT)
                            end    
                            try
                                RT = te.states.hit(1) - te.states.beginresponse(1);
                            catch
                                RT = te.states.hit(1) - te.states.deliverstim(2);
                            end
                            fprintf('%d-Hit: RT %2.2f',n_done_trials,RT)
                        else
                            RT = te.states.hit(1) - te.states.deliverstim(1);
                            disp(sprintf('%d-DDHit: RT %2.2f',n_done_trials,RT))
                        end
                        if RT < DDTargetRT; 
                            LeftRTWins.value = LeftRTWins + 1; 
                            disp(value(LeftRTWins)); 
                        end
                    elseif TrialTypeList(n_done_trials) == 'r'
                        if isempty(te.states.direct)
                            try
                                RT = te.states.correctreject(1) - te.states.beginresponse(1);
                                disp(sprintf('%d-CR: RT %2.2f',n_done_trials,RT))
                            catch
                            end
                            
                        else
                            try
                                % Fix this
                                RT = te.states.correctreject(1) - te.states.direct(1);
                                disp(sprintf('%d-DD_CR: RT %d',n_done_trials,RT))
                            catch
                            end
                            
                        end
                        %                     if RT < DDTargetRT; RightRTWins.value = RightRTWins + 1; end
                    end
                end
                % Turn DD off if counts exceeded
                if (LeftRTWins > DDThreshold) && strcmp(value(DirectDelivery),'On')
                    DirectDelivery.value = 'Off';
                    StimProb.value = 1;
                    NumBlocks.value = -1;
                    auditory_gonogo(obj,'Update_TrialTypes');
                    
                end
            end
            
            % Update the reward delivery counts if in Operant mode
            if strcmp(value(Operant),'On')
                if(~isempty(te.states.hit))
                    Hits.value = Hits + 1;
                    disp(sprintf('%d-HIT No. %d',n_done_trials,value(Hits)))
                end
                if(~isempty(te.states.correctreject))
                    RightRewards.value = RightRewards + 1;
                    %                     disp(sprintf('%d-CR No. %d',n_done_trials,value(RightRewards)))
                end
                
                % Turn Operant off/DD on if threshold reached
                if (Hits >= OperantThreshold) && strcmp(value(Operant),'On'),
                    Operant.value = 'Off';
                    DirectDelivery.value = 'On';
                    NumBlocks.value = -1;
                    StimProb.value = 1;
                    auditory_gonogo(obj,'Update_TrialTypes');
                end
            end
            
            %      -1: miss trial    (red circle) (omission)
            %       0: error trial   (red dot) (false alarm and miss)
            %       1: correct trial (green dot) (hits and correctrejects)
            %       2: hit trial     (green circle)
            % hit
            % miss
            % correct reject
            % false alarm
            % omission
            if(~isempty(te.states.hit)|~isempty(te.states.correctreject))
                if TrialTypeList(n_done_trials) == 'l'
                    % if he did not poke in right poke
                    if isempty(te.pokes.R)
                        HitHistory(n_done_trials) = 1; IdleTrialCount.value = 0;   % Hit and Correct Reject
                        BlockMemory(1:(value(BlockSize) - 1)) = BlockMemory(2:value(BlockSize));
                        BlockMemory(value(BlockSize)) = 1;
                    else
%                         disp('poked right')
                        HitHistory(n_done_trials) = 2; IdleTrialCount.value = 0;   % Hit and Correct Reject
                        BlockMemory(1:(value(BlockSize) - 1)) = BlockMemory(2:value(BlockSize));
                        BlockMemory(value(BlockSize)) = 1;
                    end
%                     HitHistory(n_done_trials) = 1; IdleTrialCount.value = 0;   % Hit and Correct Reject
%                     BlockMemory(1:(value(BlockSize) - 1)) = BlockMemory(2:value(BlockSize));
%                     BlockMemory(value(BlockSize)) = 1;
                else
                    % if he did not poke in right poke
                    if isempty(te.pokes.R)
                        HitHistory(n_done_trials) = 1; IdleTrialCount.value = 0;   % Hit and Correct Reject
                        BlockMemory(1:(value(BlockSize) - 1)) = BlockMemory(2:value(BlockSize));
                        BlockMemory(value(BlockSize)) = 1;
                    else
%                         disp('poked right')
                        HitHistory(n_done_trials) = 2; IdleTrialCount.value = 0;   % Hit and Correct Reject
                        BlockMemory(1:(value(BlockSize) - 1)) = BlockMemory(2:value(BlockSize));
                        BlockMemory(value(BlockSize)) = 1;
                    end
                end
                if ~isempty(te.states.hit)
                    disp([(sprintf('%d-HIT',n_done_trials)) '   ' num2str(value(StimDurList(n_done_trials)))])
                    Hits.value = Hits + 1;
                elseif ~isempty(te.states.correctreject)
                    disp([(sprintf('%d-CORRECTREJECT',n_done_trials)) '   ' num2str(value(StimDurList(n_done_trials)))])
                end
            elseif(~isempty(te.states.miss))
                HitHistory(n_done_trials) = 0;   % Abort
                disp([(sprintf('%d-MISS',n_done_trials)) '   ' num2str(value(StimDurList(n_done_trials)))])
            elseif(~isempty(te.states.falsealarm)),
                disp([(sprintf('%d-FA',n_done_trials)) '   ' num2str(value(StimDurList(n_done_trials)))])
                HitHistory(n_done_trials) = 0; IdleTrialCount.value = 0;   % False Alarm and Miss
                BlockMemory(1:(value(BlockSize) - 1)) = BlockMemory(2:value(BlockSize));
                BlockMemory(value(BlockSize)) = 0;
                
            elseif(~isempty(te.states.learlyresponse))
                if TrialTypeList(n_done_trials) == 'l',
                    disp([(sprintf('%d-EARLY-HIT',n_done_trials)) '   ' num2str(value(StimDurList(n_done_trials)))])
                else
                    disp([(sprintf('%d-EARLY-FA',n_done_trials)) '   ' num2str(value(StimDurList(n_done_trials)))])
                end
                
                % Antibias
                if strcmp(value(Anti_Bias), 'On'),
                    if n_done_trials>value(MaxAntiBias)&&sum(HitHistory(n_done_trials-value(MaxAntiBias):n_done_trials)==0)<value(MaxAntiBias), % if there are already MaxAntiBias trials, give him a break
                        TrialTypes(n_done_trials + 1) = TrialTypes(n_done_trials);
                        TrialTypeList(n_done_trials + 1) = TrialTypeList(n_done_trials);
                        StimDurList(n_done_trials + 1) = StimDurList(n_done_trials);
                        SoloFunctionAddVars('SidesPlotSection', 'rw_args',...
                            {'TrialTypes','TrialTypeList','StimDurList'});
                        SoloFunctionAddVars('PerformancePlotSection', 'rw_args',...
                            {'TrialTypes','TrialTypeList','StimDurList'});
                        SoloFunctionAddVars('MakeAndUploadSounds','rw_args',...
                            {'StimDurList','TrialTypeList'});
                    end
                elseif strcmp(value(Anti_Bias),'Inf'),
                    
                    TrialTypes(n_done_trials + 1) = TrialTypes(n_done_trials);
                    TrialTypeList(n_done_trials + 1) = TrialTypeList(n_done_trials);
                    StimDurList(n_done_trials + 1) = StimDurList(n_done_trials);
                    SoloFunctionAddVars('SidesPlotSection', 'rw_args',...
                        {'TrialTypes','TrialTypeList','StimDurList'});
                    SoloFunctionAddVars('PerformancePlotSection', 'rw_args',...
                        {'TrialTypes','TrialTypeList','StimDurList'});
                    SoloFunctionAddVars('MakeAndUploadSounds','rw_args',...
                            {'StimDurList','TrialTypeList'});
                else
                end
            else
                HitHistory(n_done_trials) = -1;   % Otherwise
            end
            if sum(BlockMemory) == round(value(BlockSize)*.85)
                BlockMemory(1:value(BlockSize)) = 0;
                %             if strcmp(value(Task_Phase), 'BlockTraining')
                %             PercentLeft.value_callback = 1 - value(PercentLeft);
                %             end
                %CallUpdateTrialTypes
            end
            if value(IdleTrialCount) == value(IdleTrials2Suspend)
                IdleTrialCount.value = 0;
            end
            if HitHistory(n_done_trials) == -1
                IdleTrialCount.value = (value(IdleTrialCount) + 1);
            end
            
            % Check if we're in laser on or laser off mode and set BOSS mode accordingly
            %             if value(LightStimList(n_done_trials+1)) == 1
            %                 SetBOSSMode(1);
            %             elseif value(LightStimList(n_done_trials+1)) == 0
            %                 SetBOSSMode(0);
            %             end
            
        end
        
        % -------Prepare next trial sounds and events----------
        
        SidesPlotSection(obj, 'update', n_done_trials +1, ...
            TrialTypeList,...
            HitHistory);
        if(n_done_trials>1)
            if value(TrialTypeList(n_done_trials + 1)) == 'l'
                if strcmp(value(DirectDelivery),'On')
                    LeftAction.value = 'hit';
                    TimeUpAction.value = 'miss';
                else
                    LeftAction.value = 'hit';
                    TimeUpAction.value = 'miss';
                end
            elseif value(TrialTypeList(n_done_trials + 1)) == 'r'
                LeftAction.value = 'falsealarm';
                TimeUpAction.value = 'correctreject';
                %                 StimDur.value = 0;
            end
        end
        
        MakeAndUploadSounds(obj,'update')
        SoloFunctionAddVars('StateMatrixSection', 'rw_args',...
            {'IdleTrialCount', 'LeftAction','TimeUpAction'});
        
        % -- Create and send state matrix for next trial (includes generating sounds) --
        StateMatrixSection(obj,'update');
        
        % To start stimulation protocol.
        if value(LightProb2) > 0
            if rand <  value(LightProb2),
                LightStimulation2(n_done_trials+1) = 1;
                stop(LaserTimer_agonogo)
                if isequal(AO.running,'On')
                    stop(AO)
                end
                start(LaserTimer_agonogo)
            else
                stop(LaserTimer_agonogo)
                if isequal(AO.running,'On')
                    stop(AO)
                end
            end
        end
        %---------------------------------------------------------------
        %          CASE TRIAL_COMPLETED
        %---------------------------------------------------------------
    case 'trial_completed'
        MaxTrials = 1000;
        SavingSection(obj,'autosave_data');
        %         PerformancePlotSection(obj, 'update', n_done_trials,...
        %                            value(HitHistory),RewardSideList.values==1,TrialTypeList);
        
        PerformancePlotSection(obj, 'update', n_done_trials,...
            value(HitHistory),TrialTypeList=='l');
        %         auditory_gonogo(obj,'Update_TrialTypes');
        
        %---------------------------------------------------------------
        %          CASE UPDATE
        %---------------------------------------------------------------
    case 'update'
        %         if(USE_POKESPLOT)
        %             PokesPlotSection(obj, 'update');
        %         end
        %
        %     if strcmp(value(Task_Phase),'8_Sounds')
        %     Seqlength.value = 8;
        %     end
        
        %---------------------------------------------------------------
        %          CASE CLOSE
        %---------------------------------------------------------------
    case 'close'
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)),
            delete(value(myfig));
        end;
        delete_sphandle('owner', ['^@' class(obj) '$']);
        
    otherwise,
        warning('Unknown action! "%s"\n', action);
end

return
