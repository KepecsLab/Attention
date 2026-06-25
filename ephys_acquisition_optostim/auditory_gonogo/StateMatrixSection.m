% Create and send state matrix.
%
% Santiago Jaramillo - 2008.07.10

function sma = StateMatrixSection(obj, action)

Operant = [];

GetSoloFunctionArgs;
%                         'StimDur','Delay2Resp','RespDur',...
%                         'CPokeInitiated','IdleTrials2Suspend','Punish_ITI
%                         ',...
%                         'IdleTrialCount','TrialTypeList','TrialTypes'});

global right1water;
global left1water;

right1water = Settings('get', 'DIOLINES', 'right1water');
left1water  = Settings('get', 'DIOLINES', 'left1water');
center2water  = Settings('get', 'DIOLINES', 'center2water');
left2water = Settings('get','DIOLINES', 'left2water');

cLED = Settings('get', 'DIOLINES', 'center1led'); % for Sound synch
rLED = Settings('get', 'DIOLINES', 'right1led');  % for Response synch
lLED = Settings('get', 'DIOLINES', 'left1led');
c2LED = Settings('get', 'DIOLINES', 'center2led'); %laser
l2LED = Settings('get', 'DIOLINES', 'left2led'); %masking light

MinTimeInState = 0.01;
DrinkIdleTimer = 1.5;

switch action
    case 'update',
        % -- Sound parameters --
        Bad = SoundManagerSection(obj, 'get_sound_id', 'Bad');
        Punish = SoundManagerSection(obj, 'get_sound_id', 'Punish');
        RespondNow = SoundManagerSection(obj, 'get_sound_id', 'Response');
        Signal= SoundManagerSection(obj, 'get_sound_id', 'Signal');
        Noise = SoundManagerSection(obj, 'get_sound_id', 'WhiteNoise');
        
        % -- Reward parameters --
        [ValveDurationL,ValveDurationR] = WaterValvesSection(obj,'get_water_times');
        
        % -- Params for left vs. right trials --
        LeftAct = value(LeftAction);
        TupAct = value(TimeUpAction);
        
        hit_output_action = {'SoundOut',-Signal};
%         hit_output_action = {};

        % -- Params for signal modality --
        if strcmp(value(SignalModality),'VISUAL'), % Visual does not work anymore
            DelStim_output_action = {'DOut',cLED};
            BeginResponse_output_actions = {'SoundOut', RespondNow};
            StimDuration=value(StimDurList(n_done_trials+1));
        else
            DelStim_output_action = {'SoundOut',Signal,'DOut',cLED};
%             BeginResponse_output_actions = {'DOut',lLED};
            BeginResponse_output_actions = {};
            BeginResponse_output_actions = {};
            StimDuration=value(SoundDuration);
            
%             direct_output_action = {'DOut',lLED};
            direct_output_action = {};
        end
        SideListNumeric = double(value(TrialTypeList)=='l');

        % Direct Delivery on: Water given automatically
        if strcmp(value(DirectDelivery), 'On')
            if SideListNumeric(n_done_trials+1) == 1,
                DDtup = 'direct';
            else
                DDtup = 'correctreject';
            end
        else
            if SideListNumeric(n_done_trials+1) == 1,
                DDtup = 'miss';
            else
                DDtup = 'correctreject';
            end
        end
        % AllowEarly on: Ignore early responses
        if strcmp(value(AllowEarly),'On')
            EarlyITI = {};
            EarlyWaiting = {'Lin',LeftAct};
        else
            EarlyITI = {};
            EarlyWaiting = {'Lin','learlyresponse'};
        end
        
        
        % AllowRestartITI
        if strcmp(value(AllowRestartITI),'On')
            AllowRestart_input_action = {'Lin','NoPokeITI'};
        else
            AllowRestart_input_action = {};
        end
        
        % For go response.
        if SideListNumeric(n_done_trials+1)==1,
            CorrectAct=LeftAct; % hit or direct
            CorrectValveDur=ValveDurationL;
            CorrectValve=left1water;
            LeftActDD = 'ldeliver';
            TupActDD = 'restart_ddwait';
            rewardstamp_input_to_statechange = {'Tup', 'final_state'};
            falsealarm_output_action = {};
            if strcmp(value(AllowEarly),'On') % Allow incorrect pokes, but trigger a punish sound
                ThisTrialSides = {'Lin',LeftAct,'Tup',TupAct};
                ThisTrialSidesDD = {'Lin',LeftActDD,'Tup',TupActDD};
            else
                ThisTrialSides = {'Lin',LeftAct,'Tup',TupAct};
                ThisTrialSidesDD = {'Lin',LeftActDD,'Tup',TupActDD};
            end
        else % no-go response
%             StimDuration=MinTimeInState;
%             DelStim_output_action = {};
            CorrectAct=TupAct;
            CorrectValveDur=0;
            CorrectValve=left1water;
%             RightActDD = 'rewardstamp';
            LeftActDD = LeftAct;
            rewardstamp_input_to_statechange = {'Tup', 'final_state'};
            % for airpuff
            if strcmp(value(AirPuff),'On'),
                falsealarm_output_action = {'DOut',center2water+rLED,'SoundOut',-Signal};
            else
                falsealarm_output_action = {'DOut',center2water+rLED,'SoundOut',Punish};
            end
            if strcmp(value(AllowEarly),'On') % Allow incorrect pokes, but trigger a punish sound
                ThisTrialSides = {'Lin',LeftAct,'Tup',CorrectAct};
                ThisTrialSidesDD = {'Lin', 'TriggerPunishSoundDD','Tup',CorrectAct};
            else
                ThisTrialSides = {'Lin',LeftAct,'Tup',CorrectAct};
                ThisTrialSidesDD = {'Lin',LeftActDD,'Tup',CorrectAct};
            end
        end

        % -- Optogenetics parameters --
        if LightStimList(n_done_trials+1)==1,
            DelLight_output_action={'DOut',c2LED};
        else
            DelLight_output_action={};
        end
                
        % Define a default state matrix
            % ITI
            ITI_self_timer = ITIs(n_done_trials+1);
            ITI_input_to_statechange = {AllowRestart_input_action{:},EarlyITI{:},'Tup','DeliverStim'}; % was {EarlyITI{:}, 'Tup', 'DeliverStim'}
%             for itiss = 2:15
%                 eval(['ITI' num2str(itiss) '_self_timer = ITIs' num2str(itiss) '(n_done_trials+1);']);
%                 eval(['ITI' num2str(itiss) '_input_to_statechange = {''Lin'',''restart_iti' num2str(itiss) ''',''Tup'',''DeliverStim''};'])
%             end
            if strcmp(value(WhiteNoise),'On'),
                ITI_output_actions = {'SoundOut',Noise};
            else
                ITI_output_actions = {};
            end
            % TriggerLight
            TriggerLight_self_timer = MinTimeInState;
            TriggerLight_input_to_statechange = {EarlyITI{:},'Tup','DeliverStim'};
            TriggerLight_output_actions = DelLight_output_action;
            % DeliverStim
            DeliverStim_self_timer = StimDuration;
            DeliverStim_input_to_statechange = {EarlyWaiting{:},'Tup','WaitForResponse'};
            DeliverStim_output_actions = DelStim_output_action;
            % WaitForResponse
            WaitForResponse_self_timer = value(Delay2Resp);
            WaitForResponse_input_to_statechange = {EarlyWaiting{:},'Tup','TriggerResponseTimer'};
            WaitForResponse_output_actions = {};
            % BeginResponse
            BeginResponse_self_timer = value(RespDur);
            BeginResponse_input_to_statechange = {ThisTrialSides{:}, 'ResponseTimer_In', DDtup, 'Tup', DDtup};
            % BeginResponse_output_actions = defined above
            

        % Operant on: Poke for water
        if strcmp(value(Operant), 'On')
            % "Operant on" overrides default ITI state definition
            if (Hits <= OperantThreshold)
                % IF HE POKES,give him water, if he doesnt move on to next
                % trial.
                ITI_input_to_statechange = {'Lin','hit','Tup','final_state'};
                ITI_output_actions = {};
%                 hit_output_action = {'SoundOut',Signal};

%                 DeliverStim_self_timer = MinTimeInState;
%                 DeliverStim_input_to_statechange = {'Tup','hit'};
%                 DeliverStim_output_actions = {'SoundOut',Signal};
            end
        end

        % Optogenetics on, change state matrix accordingly
        if LightStimList(n_done_trials+1)==1
            if strcmp(LightStimType, 'Blockwise')
                % do nothing, keep defaults
                % Two TTLs will be sent at beginning of ITI
                % First one turns off BOSS, second one turns it back on
                % BOSS mode is set in mice_susattn2('prepare_next_trial')
            else
                ITI_self_timer = max(ITIs(n_done_trials+1) + value(LightLatency), MinTimeInState);
                ITI_input_to_statechange = {AllowRestart_input_action{:} EarlyITI{:},'Tup','TriggerLight'};

                TriggerLight_input_to_statechange = {EarlyITI{:},'Tup','ITI2'};

                DeliverStim_input_to_statechange = {EarlyWaiting{:}, 'Tup', 'WaitForResponse'};

                WaitForResponse_self_timer = max(value(LightLatency), MinTimeInState);
                WaitForResponse_input_to_statechange = {EarlyWaiting{:},'Tup','WaitForResponse2'};
            end
        end

    % ==== Actual state matrix definition ====

        sma = StateMachineAssembler('full_trial_structure');
        
        sma = add_state(sma, 'name', 'NoPokeITI', ...
            'self_timer', value(DrinkIdleTimer),...
            'input_to_statechange', {'Lout','restart_NoPokeITI','Lin','restart_NoPokeITI','Tup','ITI'},...
            'output_actions', {'DOut',c2LED});
        sma = add_state(sma, 'name', 'restart_NoPokeITI', ...
            'self_timer', MinTimeInState,...
            'input_to_statechange', {'Tup','NoPokeITI'},...
            'output_actions', {'DOut',c2LED});
        
        sma = add_state(sma, 'name', 'ITI', ...
            'self_timer', ITI_self_timer, ...
            'input_to_statechange', ITI_input_to_statechange, ...
            'output_actions', ITI_output_actions);
        sma = add_state(sma, 'name', 'TriggerLight', ...
            'self_timer', TriggerLight_self_timer, ...
            'input_to_statechange', TriggerLight_input_to_statechange, ...
            'output_actions', TriggerLight_output_actions);
        sma = add_state(sma, 'name', 'ITI2', ...
            'self_timer', max(-1*value(LightLatency), MinTimeInState), ...
            'input_to_statechange', {EarlyITI{:}, 'Tup', 'DeliverStim'}, ...
            'output_actions', {});
        sma = add_state(sma, 'name', 'DeliverStim', ...
            'self_timer', DeliverStim_self_timer, ...
            'input_to_statechange', DeliverStim_input_to_statechange, ...
            'output_actions', DeliverStim_output_actions);
        sma = add_state(sma, 'name', 'WaitForResponse', ...
            'self_timer', WaitForResponse_self_timer, ...
            'input_to_statechange', WaitForResponse_input_to_statechange, ...
            'output_actions', WaitForResponse_output_actions);
        sma = add_state(sma, 'name', 'WaitForResponse2', ...
            'self_timer', max(value(Delay2Resp) - value(LightLatency), MinTimeInState), ...
            'input_to_statechange', {EarlyWaiting{:}, 'Tup', 'TriggerResponseTimer'}, ...
            'output_actions', {});
                % ------------------------------------------------
                sma = add_scheduled_wave(sma, 'name', 'ResponseTimer',...
                    'preamble', value(RespDur));
                % ------------------------------------------------
        sma = add_state(sma, 'name', 'TriggerResponseTimer',...
            'self_timer', MinTimeInState,...
            'input_to_statechange',{'Lin',LeftAct,'Tup','BeginResponse'},...
            'output_actions', {'SchedWaveTrig','ResponseTimer'});
        sma = add_state(sma, 'name', 'BeginResponse', ...
            'self_timer', BeginResponse_self_timer, ...
            'input_to_statechange', BeginResponse_input_to_statechange, ...
            'output_actions', BeginResponse_output_actions);
            sma = add_state(sma, 'name', 'TriggerPunishSound',...
                'self_timer', value(PunishSoundDuration),...
                'input_to_statechange', {'Tup', 'BeginResponse2'},...
                'output_actions', {'SoundOut',Bad; BeginResponse_output_actions{:}});
            sma = add_state(sma, 'name', 'BeginResponse2', ...
                'self_timer', BeginResponse_self_timer, ...
                'input_to_statechange', {'Lin', LeftAct,'ResponseTimer_In', DDtup, 'Tup', DDtup}, ...
                'output_actions', BeginResponse_output_actions);
%             sma = add_state(sma, 'name', 'rpunish', ... 
%                 'self_timer', value(Punish_ITI),...
%                 'input_to_statechange', ...
%                 {'Tup', 'punishstamp'},...
%                 'output_actions', {'SoundOut',Bad});

        sma = add_state(sma, 'name', 'hit', ...
            'self_timer',MinTimeInState,...
            'input_to_statechange', ...
            {'Tup', 'ldeliver'},...
            'output_actions', hit_output_action);
            sma = add_state(sma, 'name', 'ldeliver', ...
                'self_timer', ValveDurationL,...
                'input_to_statechange', ...
                rewardstamp_input_to_statechange,...
                'output_actions', {'DOut', left1water+rLED});
            sma = add_state(sma, 'name', 'falsealarm', ...
                'self_timer', value(Punish_ITI),...
                'input_to_statechange', ...
                {'Tup', 'final_state'},...
                'output_actions', falsealarm_output_action);
            sma = add_state(sma, 'name', 'correctreject', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', ...
                rewardstamp_input_to_statechange,...
                'output_actions', {});
            sma = add_state(sma, 'name', 'miss', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', ...
                {'Tup', 'final_state'},...
                'output_actions', {});
            
%         sma = add_state(sma, 'name', 'rewardstamp', ...
%             'self_timer',MinTimeInState,...
%             'input_to_statechange', rewardstamp_input_to_statechange,...
%             'output_actions', {});
%         sma = add_state(sma, 'name', 'punishstamp', ...
%             'self_timer',MinTimeInState,...
%             'input_to_statechange', {'Tup', 'NoPokeITI'},...
%             'output_actions', {});

        sma = add_state(sma, 'name', 'direct', ...
            'self_timer',MinTimeInState,...
            'input_to_statechange', {'Tup', 'TriggerDDTimer'},...
            'output_actions', direct_output_action);
        sma = add_state(sma, 'name', 'TriggerDDTimer',...
            'self_timer',MinTimeInState,...
            'input_to_statechange', {'Tup', 'direct_waitforpickup'},...
            'output_actions', direct_output_action);
                % ----------------------------------------
                sma = add_scheduled_wave(sma, 'name', 'DDTimer',...
                    'preamble', value(DirectWait4PickupDur));
                % ----------------------------------------
        sma = add_state(sma, 'name', 'direct_waitforpickup', ...
            'self_timer', value(DirectWait4PickupDur),...
            'input_to_statechange', {ThisTrialSidesDD{:}, 'DDTimer_In', 'final_state', 'Tup', 'final_state'},...
            'output_actions', direct_output_action);
            sma = add_state(sma, 'name', 'restart_ddwait', ...
                'self_timer', MinTimeInState, ...
                'input_to_statechange', {'Tup', 'direct_waitforpickup'}, ...
                'output_actions', {'SoundOut', Bad});
            sma = add_state(sma, 'name', 'TriggerPunishSoundDD',...
                'self_timer', value(PunishSoundDuration),...
                'input_to_statechange', {'Tup', 'direct_waitforpickup'},...
                'output_actions', {'SoundOut',Bad; 'DOut',lLED});
            
%         sma = add_state(sma, 'name','restart_iti', ... % ensure that the next trial does not begin with the headin the reward port
%             'self_timer', MinTimeInState,...
%             'input_to_statechange', {'Tup','ITI2b'},...
%             'output_actions', {});
%         sma = add_state(sma, 'name','ITI2b', ...
%             'self_timer', ITI2_self_timer, ...
%             'input_to_statechange', ITI2_input_to_statechange, ...
%             'output_actions', ITI_output_actions);
%         sma = add_state(sma, 'name','restart_iti2', ...
%             'self_timer', MinTimeInState,...
%             'input_to_statechange', {'Tup','ITI3'},...
%             'output_actions', {});
%         sma = add_state(sma, 'name','ITI3', ...
%             'self_timer', ITI3_self_timer, ...
%             'input_to_statechange', ITI3_input_to_statechange, ...
%             'output_actions', ITI_output_actions);
%         sma = add_state(sma, 'name','restart_iti3', ...
%             'self_timer', MinTimeInState,...
%             'input_to_statechange', {'Tup','ITI4'},...
%             'output_actions', {});
%         for itiss = 4:14
%             eval(['sma = add_state(sma, ''name'',''ITI' num2str(itiss) ''',''self_timer'', ITI' num2str(itiss) '_self_timer,''input_to_statechange'', ITI' num2str(itiss) '_input_to_statechange,''output_actions'', ITI_output_actions);']);
%             eval(['sma = add_state(sma, ''name'',''restart_iti' num2str(itiss) ''',''self_timer'',MinTimeInState,''input_to_statechange'', {''Tup'',''ITI' num2str(itiss+1) '''},''output_actions'', {});']);
%         end
%         sma = add_state(sma, 'name','ITI15', ...
%             'self_timer', ITI15_self_timer, ...
%             'input_to_statechange', ITI15_input_to_statechange, ...
%             'output_actions', ITI_output_actions);
%         sma = add_state(sma, 'name','restart_iti15', ...
%             'self_timer', MinTimeInState,...
%             'input_to_statechange', {'Tup','ITI15'},...    % it restarts itself, and is fixed one second long!!!
%             'output_actions', {});

        sma = add_state(sma, 'name', 'learlyresponse', ...
            'self_timer',MinTimeInState,...
            'input_to_statechange', {'Tup', 'earlyresponse'},...
            'output_actions', {'SoundOut',Bad});
        sma = add_state(sma, 'name', 'earlyresponse', ...
            'self_timer',MinTimeInState,...
            'input_to_statechange', {'Tup', 'final_state'});

        sma = add_state(sma, 'name', 'suspended', ...
            'self_timer', 10000,...
            'input_to_statechange', {'Lin', 'final_state', 'Tup', 'final_state'},...
            'output_actions',{});
        
        sma = add_state(sma, 'name', 'final_state', ...
            'self_timer',MinTimeInState,...
            'input_to_statechange',...
            {'Tup', 'check_next_trial_ready'});

        dispatcher('send_assembler', sma, {'final_state'});
%         dispatcher('send_assembler', sma, {'rewardstamp','punishstamp','final_state'});

end %%% SWITCH action
