function [waveform] = toneWave(frequency, duration, ramp, sampling_rate)
% make the waveform corresponding to a single pure tone pulse
%
% parameters:
%
% frequency - tone frequency
% duration  - tone duration
% ramp      - ramp of the envelope (the larger this is, the slower the ramp
% rises)

%construct modulation at the target frequency
t          = 1/sampling_rate:1/sampling_rate:duration;


if(frequency<=0.0001)
    waveform = zeros(1, length(t));
else


modulation = sin(t*frequency*2*pi);


%construct the envelope

ramp_norm     = acos(sqrt(0.1)) - acos(sqrt(0.9));

%omega         = (acos(sqrt(0.1)) - acos(sqrt(0.9)))/ramp;
%this is some sort of magic parameter for the envelope

u             = 0:(1/sampling_rate):(pi/2 * ramp/ramp_norm); 
u             = u(1:(end-1));
fall          = cos(u/(ramp/ramp_norm)).^2;
rise          = fliplr(fall);

envelope      = ones(1, length(t));
envelope(1:length(rise)) = rise;
envelope((length(envelope) - length(fall) + 1):length(envelope)) = fall;

waveform      = envelope.*modulation;

end


end

