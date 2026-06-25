function [] = CJS_SoundStim_01()
%BPod protocol for playing white Stim at random intervals
%while animal moves freely in the box

global BpodSystem;

PsychToolboxSoundServer('init');
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

BNC_SoundOnset = 'BNC1High';
%BNC input which gets the TTL signal of sound onset
%from the sound card

BNC_ScanImage  = 1;
%BNC which triggers ScanImage

BpodSystem.Data.sampleRate    = 192000;

%--------------------------------------------------------------------------
%global parameters are here:

BpodSystem.Data.ISI    = 2;
BpodSystem.Data.volume = 65;
%the volume of all pure tones and tonecloud tones

BpodSystem.Data.WNReps = 1;
BpodSystem.Data.TCReps = 1;
BpodSystem.Data.PTReps = 1;

BpodSystem.Data.soundWait = 0.05;

%--------------------------------------------------------------------------
%Protocol Settings GUI

S = BpodSystem.ProtocolSettings;

if isempty(S) || isempty(fieldnames(S))
    %populate with default settings
    S.GUI = struct;
    
    S.GUI.Subject = struct;
    S.GUI.Subject.panel = 'Protocol'; 
    S.GUI.Subject.style = 'text'; 
    S.GUI.Subject.string = 'NoName'; 
    
    S.GUI.Image = struct;
    S.GUI.Image.panel = 'Protocol';
    S.GUI.Image.style = 'checkbox';
    S.GUI.Image.string = '';
    S.GUI.Image.value = 1;  
    
end


% Initialize parameter GUI plugin
EnhancedBpodParameterGUI('init', S);


%%% Pokes plot
stateColors = struct( ...
        'Stim', [1, 0, 0],...
        'ISI',  [1, 1, 0]);


%pull some information about session from data path
BpodSystem.Data.SubjectName = BpodSystem.GUIData.SubjectName;
s = strsplit(BpodSystem.DataPath, '_');
BpodSystem.Data.Date = [s{length(s)-2} '-' s{length(s)-1}];
s = strsplit(s{length(s)}, '.');     
BpodSystem.Data.SessionDescription = s{1};

BpodSystem.Data.nTrials = 0;

MaxTrials = 5000;


BpodSystem.Data.TrialStart  = [];
%trial start time
BpodSystem.Data.TrialEnd    = [];
%trial end time
BpodSystem.Data.Image       = [];
%whether we imaged on this trial

BpodSystem.ProtocolFigures.StimPlot = StimPlot();

BpodSystem.ProtocolFigures.PokesPlot = PokesPlot('autostep', stateColors, []);
update(BpodSystem.ProtocolFigures.PokesPlot, BpodSystem.Data);

BpodSystem.ProtocolFigures.InitialMsg = msgbox({'', ' Edit your settings and click OK when you are ready to start!     ', ''},'SoundStim...');
uiwait(BpodSystem.ProtocolFigures.InitialMsg);

%generate a struct for each possible stimulus

%white noise

S = EnhancedBpodParameterGUI('sync', S); 

%load sound calibration file
%this just loads the default, we may want to save our own
%somewhere else
soundCal = BpodSystem.CalibrationTables.SoundCal;


%--------------------------------------------------------------------------
% Generate all stimuli

rng(pi);

stimulus_num = 1;

%--------------------------------------------------------------------------
% Generate white noise


% PARAMETERS
%sample_rate, 
%pulse_length, 
%duty_cycle, 
%total_duration,
%ramp_duration,
%do_test
    
% Min and max pulse frequency (accounts for duty cycle)
WN = struct;
WN.min_freq = 5;
WN.max_freq = 15;
WN.n_freqs  = 10;
WN.duty_cycle = 0.5;
WN.total_duration = 2; % Seconds
WN.ramp_duration = 0.01;
WN.all_pulse_lengths = logspace(log10(1/WN.max_freq),log10(1/WN.min_freq),WN.n_freqs)*WN.duty_cycle;

WN.sample_rate = BpodSystem.Data.sampleRate;

for pl = 1:length(WN.all_pulse_lengths)
    for rep = 1:BpodSystem.Data.WNReps
        WN.pulse_length = WN.all_pulse_lengths(pl);
        Stimuli(stimulus_num).WN_params = WN;
        
        wnb = make_white_noise_bursts(...
            WN.sample_rate,...
            WN.pulse_length, ...
            WN.duty_cycle, ...
            WN.total_duration,...
            WN.ramp_duration);
        
        %duplicate the stimulus waveform
        %(one row for each speaker)
        Stimuli(stimulus_num).sound_wave = [wnb; wnb];
        
        stimulus_num = stimulus_num + 1;
    end
end

%--------------------------------------------------------------------------
% Generate tone clouds

TC = struct;
TC.min_freq           = 5e3;
TC.max_freq           = 40e3;
TC.n_bands            = 3;
TC.n_freqs_per_octave = 6;
TC.overlap            = 0.02; % seconds
TC.ramp               = 0.005;
TC.sampleRate         = BpodSystem.Data.sampleRate;

TC.volume             = BpodSystem.Data.volume;

TC.toneDuration       = 0.03; % seconds
TC.target_duration    = 2;
%the target total stimulus duration
%may not be precise because tone duration is fixed
TC.nTones             = floor((TC.target_duration - (TC.toneDuration - TC.overlap))/(TC.toneDuration - TC.overlap));

%ignore this, only relevant for 2-AFC stimuli
TC.proportions = 1;

%generate a list of all frequencies used in the full frequency range
TC.allfreqs = 2.^(log2(TC.min_freq):(1/TC.n_freqs_per_octave):log2(TC.max_freq));

%divide the frequencies into bands
TC.highest_freq_index_per_band = floor( (length(TC.allfreqs)/TC.n_bands)*(1:TC.n_bands)+0.5);
TC.lowest_freq_index_per_band  = [1, TC.highest_freq_index_per_band(2:end)-1];

for b = 1:TC.n_bands
    for rep = 1:BpodSystem.Data.TCReps
        %get the vector of frequencies to use for this tone cloud
        %(generate the tone cloud by uniformly sampling within them)
        %need to pass this as a cell array of length 1
        TC.frequencies = {TC.allfreqs(TC.lowest_freq_index_per_band(b):TC.highest_freq_index_per_band(b))};

        %generate the sound wave
        TC2 = toneCloudWave(TC, soundCal);
        
        Stimuli(stimulus_num).TC_params   = TC;
        Stimuli(stimulus_num).sound_wave  = TC2.wave;
        stimulus_num = stimulus_num + 1;
    end

end

%--------------------------------------------------------------------------
% Generate pure tones

PT = struct;
PT.min_freq = 5e3;
PT.max_freq = 40e3;
PT.n_freqs_per_octave = 6;
PT.duration = 0.2; %seconds
PT.volume = BpodSystem.Data.volume;

PT.allfreqs = 2.^(log2(TC.min_freq):(1/TC.n_freqs_per_octave):log2(TC.max_freq));

PT.sampleRate = BpodSystem.Data.sampleRate;
PT.ramp       = 0.005;

for f = 1:length(PT.allfreqs)
    for rep = 1:BpodSystem.Data.PTReps
        PT.freq = PT.allfreqs(f);
        Stimuli(stimulus_num).sound_wave = pureTone(PT.freq, PT.duration, PT.ramp, PT.sampleRate, PT.volume, soundCal);
        Stimuli(stimulus_num).PT_params  = PT;
        stimulus_num = stimulus_num + 1;
    end
end

%--------------------------------------------------------------------------
%high-pass filter all stimuli
%to protect ultrasound speakers

sound_filter = designfilt('highpassiir',...
  'StopbandFrequency',3800 ,...
  'PassbandFrequency',4000,...
  'StopbandAttenuation',65,...
  'PassbandRipple',0.5,...
  'SampleRate',BpodSystem.Data.sampleRate,...
  'DesignMethod','butter');

for s = 1:length(Stimuli)
    sound_wave = Stimuli(s).sound_wave;
    for channel = 1:2
         sound_wave(channel, :) = filter(sound_filter, sound_wave(channel, :));
    end
    Stimuli(s).sound_wave = sound_wave;
end

%--------------------------------------------------------------------------
%generate an order in which to present stimuli

stimOrder = randperm(length(Stimuli));

[~, reverse_perm] = sort(stimOrder);

Stimuli = Stimuli(stimOrder);

%save all stimuli and related info
%we don't append them to Bpod data because we don't want to save every
%trial (sound waves are big)

s = strsplit(BpodSystem.DataPath, '.');
saveDir = s{1};
if(~exist(saveDir, 'dir'))
    mkdir(saveDir);
end
stimSavePath = fullfile(saveDir, 'Stimuli.mat');

save(stimSavePath, 'Stimuli', 'reverse_perm', 'sound_filter', 'soundCal');

%--------------------------------------------------------------------------
%main trial loop

for currentTrial = 1:MaxTrials
    
    S = EnhancedBpodParameterGUI('sync', S); 
    % Sync parameters with EnhancedBpodParameterGUI plugin
    
    show(BpodSystem.ProtocolFigures.StimPlot, Stimuli(currentTrial).sound_wave(1,:), BpodSystem.Data.sampleRate);
    
    BpodSystem.Data.Image(currentTrial)      = S.GUI.Image.value;
    
    
    %load the next sound to the sound server
    sound        = Stimuli(currentTrial).sound_wave;
    stimDuration = length(sound)/BpodSystem.Data.sampleRate;
    
    PsychToolboxSoundServer('Load', 1, sound);
    %each row of matrix is a separate channel

    
    %generate Bpod state matrix
    %structure: Stimulus, then ISI
    sma = NewStateMatrix(); 
    
    sma = AddState(sma, 'Name', 'Start',...
        'Timer', 0.001,...
        'StateChangeConditions', {'Tup', 'TriggerStim'},...
        'OutputActions', {'BNCState', BpodSystem.Data.Image(currentTrial)*BNC_ScanImage});
    
    sma = AddState(sma, 'Name', 'TriggerStim', ...
        'Timer', BpodSystem.Data.soundWait,...
        'StateChangeConditions', {'Tup', 'NoStim',...
        BNC_SoundOnset, 'Stim'},...
        'OutputActions', {'SoftCode', 1});
    
    %playing stimulus
    sma = AddState(sma, 'Name', 'Stim', ...
        'Timer', stimDuration,...
        'StateChangeConditions', {'Tup', 'ISI'},...
        'OutputActions', {});
                
    %error state that we enter if no sound plays
    %still go through rest so as to not mess up overall timing
    sma = AddState(sma, 'Name', 'NoStim', ...
        'Timer', stimDuration ,...
        'StateChangeConditions', {'Tup', 'ISI'},...
        'OutputActions', {}); 

    sma = AddState(sma, 'Name', 'ISI',...
        'Timer', BpodSystem.Data.ISI,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});

    if(currentTrial==1)
        BpodSystem.Data.SessionBirthdate = tic;
        BpodSystem.Data.TrialStart(currentTrial) = 0;
    else
        BpodSystem.Data.TrialStart(currentTrial) = toc(BpodSystem.Data.SessionBirthdate);
    end

    disp('---------------------------------------------');
    disp(['Started Trial ', num2str(currentTrial)]);
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;   
    
    BpodSystem.Data.TrialEnd(currentTrial) = toc(BpodSystem.Data.SessionBirthdate);
    
    disp(['Completed Trial ', num2str(currentTrial)]);
     

    noEvents   = 1;
    noStim     = 0;
                
    if ~isempty(fieldnames(RawEvents))
        noEvents = 0;
        data = struct;
        data = AddTrialEvents(data,RawEvents); 
        noStim     = ~isnan(data.RawEvents.Trial{1}.States.NoStim(1));
    end
                
    if(noEvents)
        disp('Error: received no BPod events');
    end
    if(noStim)
        disp('Error: no Stim played');
    end 
    
    
    if ~isempty(fieldnames(RawEvents)) 
        
        % If trial data was returned
        BpodSystem.Data.nTrials = currentTrial;
        
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents); 
        % Computes trial events from raw data

        savePath = fullfile(saveDir, 'BpodData.mat');
        %save(savePath, 'saveBlock', '-v6');'
        
        BpodData = BpodSystem.Data;
        save(savePath, 'BpodData');
        
        update(BpodSystem.ProtocolFigures.PokesPlot, BpodSystem.Data);
        
    end
    if BpodSystem.BeingUsed == 0
        return
    end
end
%end main trial loop
  

end


%    %code to plot psd - for testing

    %n = length(sound);

    %y = fft(sound);

    %psd = y.*conj(y)/n;

    %f = 192000/n*(0:n/2);

    %figure; plot(f, psd(1:length(f)));
    
    %wave = ((rand(1,BpodSystem.Data.sampleRate*BpodSystem.Data.Stim(currentTrial)) * 2 ) - 1) * BpodSystem.Data.Mult(currentTrial);


