function MakeAndUploadSounds(obj, action, varargin)

GetSoloFunctionArgs

% SpeakerCalibrationFile = '/Users/ranades/MATLAB/ratter/ExperPort/Settings/Calibration20110202.mat';
% SpeakerCalibrationFile = 'C:\ratter\ExperPort\Settings\Calibration20110118.mat';

SpeakerCalibrationFile = 'C:\ratter\ExperPort\Settings\SpeakerStereoCalibration.mat';

WhiteNoiseDuration = 30;
% WhiteNoiseIntensity = 60;
% PunishSoundIntensity = 90;
SoundIntensity = StimDurList(n_done_trials+1);
switch action
    case 'init'
        if sum(varargin{1} == 'SoundDuration') == 13
            SoundDuration = varargin{2};
        end

        % Set Parameters
        sDuration = value(SoundDuration);
        nDuration = value(PunishSoundDuration);
        SoundFreq=value(SoundFrequency);
        %%%

        % --- Define sounds ---
        SoundManagerSection(obj, 'init');
        SoundManagerSection(obj, 'declare_new_sound', 'Signal', [0]);
        SoundManagerSection(obj, 'declare_new_sound', 'Response', [0]);
        SoundManagerSection(obj, 'declare_new_sound', 'Bad', [0]);
        SoundManagerSection(obj, 'declare_new_sound', 'Punish', [0]);
        SoundManagerSection(obj, 'declare_new_sound', 'WhiteNoise', [0]);
        
        sf = SoundManagerSection(obj, 'get_sample_rate');
        if strcmp(PunishSound,'On')
            Bad = 0.5*(rand(sf*nDuration,1)-0.5);
            Punish = 0.5*(rand(sf*value(Punish_ITI),1)-0.5);
            WhiteNoise = 0.5*(rand(sf*WhiteNoiseDuration,1)-0.5);
        else
            Bad = [];
        end
        TimeVec = (0:1/sf:sDuration)';
        Response = sin(2*pi*SoundFreq*TimeVec);
        RaiseFallDuration = 0.08;
        Response = apply_risefall(Response,RaiseFallDuration,sf);
        
        Signal = sin(2*pi*SoundFreq*TimeVec);
        RaiseFallDuration = 0.08;
        Signal= apply_risefall(Signal,RaiseFallDuration,sf);

        % Calculate attenuation for tone used
        try 
            SpeakerCalibration = load(SpeakerCalibrationFile);
        catch
            SpeakerCalibration.SoundTypeIndex.Tone = 1; % Noise = 2;
            SpeakerCalibration.FrequencyVector = [1,1e5];
            SpeakerCalibration.AttenuationVector = 0.0032*[1,1]; % Around 70dB-SPL
            SpeakerCalibration.TargetSPL = 70;
            warning(['No calibration file found: %s\n  ',...
                     'sound intensity will not be accurate!'],...
                    SpeakerCalibrationFile),
        end
%         % Apply attenuation to Signal
        ind = SpeakerCalibration.SoundTypeIndex.Tone;
        interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),SoundFreq,'linear');
        DiffSPL = SoundIntensity-SpeakerCalibration.TargetSPL;
        AttFactor = sqrt(10^(DiffSPL/10));
        attenuation = AttFactor * interpolate;
        Signal = Signal*attenuation;
        

        % Apply attenuation to Noise
        ind = SpeakerCalibration.SoundTypeIndex.Noise;
        interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),10000,'linear');
        DiffSPL = value(WhiteNoiseIntensity)-SpeakerCalibration.TargetSPL;
        AttFactor = sqrt(10^(DiffSPL/10));
        attenuation = AttFactor * interpolate;
        WhiteNoise = WhiteNoise*attenuation;
        
%         % Apply attenuation to other punishment sounds
        ind = SpeakerCalibration.SoundTypeIndex.Noise;
        interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),10000,'linear');
        interpolate = mean(interpolate);
        DiffSPL = value(PunishSoundIntensity)-SpeakerCalibration.TargetSPL;
        AttFactor = sqrt(10^(DiffSPL/10));
        attenuation = AttFactor * interpolate;
        Punish = Punish*attenuation;
        Bad = Bad*attenuation;
        Response = Response*attenuation;
%         
%         Upload the sounds
        SoundManagerSection(obj, 'set_sound', 'Bad', Bad);
        SoundManagerSection(obj, 'set_sound', 'Response', Response);
        SoundManagerSection(obj, 'set_sound', 'Signal', Signal);
        SoundManagerSection(obj, 'set_sound', 'Punish', Punish);
        SoundManagerSection(obj, 'set_sound', 'WhiteNoise', WhiteNoise);
        
        SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');

    case 'update'
        % Set Parameters
        sDuration = value(SoundDuration);
        nDuration = value(PunishSoundDuration);
        SideListNumeric = double(value(TrialTypeList)=='l');
        % S- is now associated with a sound.
        if SideListNumeric(n_done_trials+1) == 0,
            SoundFreq = 4000;
%             SoundIntensity = 70;
        else
        SoundFreq=value(SoundFrequency);
        end

        sf = SoundManagerSection(obj, 'get_sample_rate');
        if strcmp(PunishSound,'On')
            Bad = 0.5*(rand(sf*nDuration,1)-0.5);
            Punish = 0.5*(rand(sf*value(Punish_ITI),1)-0.5);
%             WhiteNoise = 0.5*(rand(sf*WhiteNoiseDuration,1)-0.5);

        else
            Bad = zeros(sf*nDuration,1);
        end
        TimeVec = (0:1/sf:sDuration)';
        Response = sin(2*pi*SoundFreq*TimeVec);
        RaiseFallDuration = 0.08;
        Response = apply_risefall(Response,RaiseFallDuration,sf);
        
        Signal = sin(2*pi*SoundFreq*TimeVec);
        RaiseFallDuration = 0.08;
        Signal= apply_risefall(Signal,RaiseFallDuration,sf);

        % Calculate attenuation.
        try
            SpeakerCalibration = load(SpeakerCalibrationFile);
        catch
            SpeakerCalibration.SoundTypeIndex.Tone = 1; % Noise = 2;
            SpeakerCalibration.FrequencyVector = [1,1e5];
            SpeakerCalibration.AttenuationVector = 0.0032*[1,1]; % Around 70dB-SPL
            SpeakerCalibration.TargetSPL = 70;
            warning(['No calibration file found: %s\n  ',...
                     'sound intensity will not be accurate!'],...
                    SpeakerCalibrationFile),
        end
        % Apply attenuation to Signal
        ind = SpeakerCalibration.SoundTypeIndex.Tone;
        interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),SoundFreq,'linear');
        DiffSPL = SoundIntensity-SpeakerCalibration.TargetSPL;
        AttFactor = sqrt(10^(DiffSPL/10));
        attenuation = AttFactor * interpolate;
        Signal = Signal*attenuation;
        
        % Apply attenuation to Noise
%         ind = SpeakerCalibration.SoundTypeIndex.Noise;
%         interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),10000,'linear');
%         DiffSPL = value(WhiteNoiseIntensity)-SpeakerCalibration.TargetSPL;
%         AttFactor = sqrt(10^(DiffSPL/10));
%         attenuation = AttFactor * interpolate;
% %         WhiteNoise = WhiteNoise*attenuation;
% 
% 
%     % Apply attenuation to other punishment sounds
%         ind = SpeakerCalibration.SoundTypeIndex.Noise;
%         interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),10000,'linear');
%         DiffSPL = value(PunishSoundIntensity)-SpeakerCalibration.TargetSPL;
%         AttFactor = sqrt(10^(DiffSPL/10));
%         attenuation = AttFactor * interpolate;
%         if strcmp(value(PunishSound),'On'),
%             Punish = Punish*attenuation;
%         end
% Bad = Bad*attenuation;
%         Response = Response*attenuation;

        % Upload the sounds
%         SoundManagerSection(obj, 'set_sound', 'Bad', Bad);
%         SoundManagerSection(obj, 'set_sound', 'Response', Response);
        SoundManagerSection(obj, 'set_sound', 'Signal', Signal);
%         SoundManagerSection(obj, 'set_sound', 'Punish', Punish);
%         SoundManagerSection(obj, 'set_sound', 'WhiteNoise', WhiteNoise);
        SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');
    case 'update2'
        % Set Parameters
        sDuration = value(SoundDuration);
        nDuration = value(PunishSoundDuration);
        SideListNumeric = double(value(TrialTypeList)=='l');
        % S- is now associated with a sound.
        if SideListNumeric(n_done_trials+1) == 0,
            SoundFreq = 4000;
%             SoundIntensity = 70;
        else
        SoundFreq=value(SoundFrequency);
        end

        sf = SoundManagerSection(obj, 'get_sample_rate');
        if strcmp(PunishSound,'On')
            Bad = 0.5*(rand(sf*nDuration,1)-0.5);
            Punish = 0.5*(rand(sf*value(Punish_ITI),1)-0.5);
            WhiteNoise = 0.5*(rand(sf*WhiteNoiseDuration,1)-0.5);

        else
            Bad = zeros(sf*nDuration,1);
        end
        TimeVec = (0:1/sf:sDuration)';
        Response = sin(2*pi*SoundFreq*TimeVec);
        RaiseFallDuration = 0.08;
        Response = apply_risefall(Response,RaiseFallDuration,sf);
        
        Signal = sin(2*pi*SoundFreq*TimeVec);
        RaiseFallDuration = 0.08;
        Signal= apply_risefall(Signal,RaiseFallDuration,sf);

        % Calculate attenuation.
        try
            SpeakerCalibration = load(SpeakerCalibrationFile);
        catch
            SpeakerCalibration.SoundTypeIndex.Tone = 1; % Noise = 2;
            SpeakerCalibration.FrequencyVector = [1,1e5];
            SpeakerCalibration.AttenuationVector = 0.0032*[1,1]; % Around 70dB-SPL
            SpeakerCalibration.TargetSPL = 70;
            warning(['No calibration file found: %s\n  ',...
                     'sound intensity will not be accurate!'],...
                    SpeakerCalibrationFile),
        end
        % Apply attenuation to Signal
        ind = SpeakerCalibration.SoundTypeIndex.Tone;
        interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),SoundFreq,'linear');
        DiffSPL = SoundIntensity-SpeakerCalibration.TargetSPL;
        AttFactor = sqrt(10^(DiffSPL/10));
        attenuation = AttFactor * interpolate;
        Signal = Signal*attenuation;
        
        % Apply attenuation to Noise
        ind = SpeakerCalibration.SoundTypeIndex.Noise;
        interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),10000,'linear');
        DiffSPL = value(WhiteNoiseIntensity)-SpeakerCalibration.TargetSPL;
        AttFactor = sqrt(10^(DiffSPL/10));
        attenuation = AttFactor * interpolate;
        WhiteNoise = WhiteNoise*attenuation;


    % Apply attenuation to other punishment sounds
        ind = SpeakerCalibration.SoundTypeIndex.Noise;
        interpolate = interp1(SpeakerCalibration.FrequencyVector, SpeakerCalibration.AttenuationVector(:,:,ind),10000,'linear');
        DiffSPL = value(PunishSoundIntensity)-SpeakerCalibration.TargetSPL;
        AttFactor = sqrt(10^(DiffSPL/10));
        attenuation = AttFactor * interpolate;
        if strcmp(value(PunishSound),'On'),
            Punish = Punish*attenuation;
        end
        Bad = Bad*attenuation;
        Response = Response*attenuation;

        % Upload the sounds
        SoundManagerSection(obj, 'set_sound', 'Bad', Bad);
        SoundManagerSection(obj, 'set_sound', 'Response', Response);
        SoundManagerSection(obj, 'set_sound', 'Signal', Signal);
        SoundManagerSection(obj, 'set_sound', 'Punish', Punish);
        SoundManagerSection(obj, 'set_sound', 'WhiteNoise', WhiteNoise);
        SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');
end

function SoundWaveform = apply_risefall(SoundWaveform,RaiseFallDuration,SamplingRate)

TimeVec = (0:1/SamplingRate:RaiseFallDuration)';
RaiseVec = linspace(0,1,length(TimeVec))';

if(length(RaiseVec)<length(SoundWaveform))
    SoundWaveform(1:length(TimeVec)) = RaiseVec.*SoundWaveform(1:length(TimeVec));
    SoundWaveform(end-length(TimeVec)+1:end) = RaiseVec(end:-1:1).*SoundWaveform(end-length(TimeVec)+1:end);
else
    warning('Sound length is too short to apply rise and fall envelope');
end
return
