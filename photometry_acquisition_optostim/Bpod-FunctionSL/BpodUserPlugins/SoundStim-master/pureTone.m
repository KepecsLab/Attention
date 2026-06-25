function [soundwave] = pureTone(frequency, duration, ramp, sampling_rate, volume, SoundCal)
%generate a pure tone
%this is just a wrapper for 'toneWave' that takes the sound calibration into
%account
%always generates 2 waveforms (stereo)
%if sound calibration was for only 1 speaker, just duplicate one waveform
%(spoof stereo)

    s = size(SoundCal);
    

    toneAtt = [polyval(SoundCal(1,1).Coefficient, frequency), polyval(SoundCal(1,s(2)).Coefficient, frequency)];

    diffSPL = volume - [SoundCal(1,1).TargetSPL, SoundCal(1,s(2)).TargetSPL];
    
    attFactor = sqrt(10.^(diffSPL./10));
    
    att = toneAtt.*attFactor;
    
    waveform  = toneWave(frequency, duration, ramp, sampling_rate);
    
    soundwave = [waveform*att(1); waveform*att(2)];


end

