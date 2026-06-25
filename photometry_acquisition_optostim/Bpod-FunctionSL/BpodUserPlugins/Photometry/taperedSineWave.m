function SineWave = taperedSineWave(SamplingRate, Frequency, Duration, RampDuration)
% Duration in seconds
% FS MOD:
% ramp: default 10ms ramp at beginning and end of sine wave
if nargin < 4
    RampDuration = 0.01; % 10ms ramp
end
dt = 1/SamplingRate;
t = 0:dt:Duration;
SineWave=sin(2*pi*Frequency*t);

if RampDuration
    rampSamples = round(RampDuration / dt);
    slope = 1/rampSamples;
    rampData = 1:rampSamples;
    rampData = slope * rampData;
    envelope = ones(size(SineWave));
    envelope(1:rampSamples) = rampData;
    envelope(end - rampSamples + 1 : end) = fliplr(rampData);
    SineWave = SineWave .* envelope;
end