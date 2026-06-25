function sound=SoundGenerator_SL(sampRate, Ramp, meanFreq, duration, amplitude)
%sound=SoundGenerator(sampRate, meanFreq, duration, amplitude).
%
%Generates a pure tone.
%The frequencies are defined by "meanFreq".
%sampRate is the sampling Rate of the sound card.
%function written by Shujing for lickNolick_Aud bpod protocol.

%     if nargin ~=4
%         disp('*** please enter correct arguments for the SoundGenerator function ***');
%         return;
%     end

   
    TimeVec = (0:1/sampRate:duration);
    signal = sin(2*pi*meanFreq*TimeVec);
    sound = [signal; signal];
    
    % load sound calibration file
    % Cal = BpodSystem.CalibrationTables.SoundCal;
    % if(isempty(Cal))
    %     disp('Error: no sound calibration file specified');
    %     return
    % end
%     SpeakerCalibrationFile = 'C:\Users\Adam\BpodUser\Calibration Files\SoundCalibration.mat';
%     SoundCal = load(SpeakerCalibrationFile);

    Cal = load('C:\Users\Kepecs\Documents\Data\Shujing\Bpod\Calibration Files\SoundCalibration.mat');
    % adjust signal volume
    for s=1:2 %loop over two speakers
        toneAtt = polyval(Cal.SoundCal(1,s).Coefficient, meanFreq);
        diffSPL = amplitude - [Cal.SoundCal(1,s).TargetSPL];
        attFactor = sqrt(10.^(diffSPL./10)); 
        att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
        sound(s,:) = sound(s,:).*att; 
    end    

%     toneAtt = polyval(Cal.SoundCal(1,1).Coefficient,meanFreq);
%     diffSPL = amplitude - [Cal.SoundCal(1,1).TargetSPL];
%     attFactor = sqrt(10.^(diffSPL./10)); 
%     att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
%     sound =sound*att;

%  put an envelope to avoide clicking sounds at beginning and end
    omega=(acos(sqrt(0.1))-acos(sqrt(0.9)))/(Ramp/pi*2); % This is for the envelope with Ramp duration duration
    t=0 : (1/sampRate) : pi/2/omega;
    t=t(1:(end-1));
    RaiseVec= (cos(omega*t)).^2;

    Envelope = ones(length(sound),1); % This is the envelope
    Envelope(1:length(RaiseVec)) = fliplr(RaiseVec);
    Envelope(end-length(RaiseVec)+1:end) = (RaiseVec);

    sound = sound.*Envelope';

    

        


        
