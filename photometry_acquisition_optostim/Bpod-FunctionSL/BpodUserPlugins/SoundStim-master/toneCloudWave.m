function [tc] = toneCloudWave(tc, soundCal, varargin)

%generate a tone cloud stimulus
% tc = struct of parameters
% tc.nTones       = number of tones in the full stimulus
% tc.toneDuration = duration of a single tone in s
% tc.overlap      = overlap between tones (in s) 
%                   can also make this negative -> get gap between tones
% tc.frequencies  = an array. Each entry is a vector containing the
%                   frequencies for a given category 
%                   (categories could be e.g. low, middle, high)
% tc.proportions  = proportion of tones to pick from each category
% tc.volume       = specified volume in dB


%example tonecloud struct:
% tc.overlap = 0
% tc.toneDuration = 0.03
% tc.nTones       = 3
% tc.frequencies = {logspace(log10(f1), log10(f2), 6), logspace(log10(f3), log10(f4), 6), logspace(log10(f5), log10(f6), 6)  };
% tc.proportions = [0.33 0.33 0.33];


%notes:
%stimulus duration is an upper limit!
%it can be smaller
%because overlap and tone duration are kept constant







tc.totalDuration = tc.nTones*tc.toneDuration - (tc.nTones - 1)*tc.overlap;
%the total stimulus time

%compute the number of tones to pick from each category:
tc.counts = floor(tc.proportions*tc.nTones);
excessTones = tc.nTones - sum(tc.counts);
if(excessTones > 0)
    %distribute the "rounding-error" tones at random
    for i = 1:excessTones
        claim = tc.proportions*tc.nTones - tc.counts;
        claim(claim < 0) = 0;
        p = claim/sum(claim);
        category = find(rand <= cumsum(p), 1);
        tc.counts(category) = tc.counts(category) + 1;
    end
end

%behavior-specific stuff:
%ensure that counts match target (low or high)
%otherwise 50:50 proportion stimuli with an odd total number of tones
%may not support the specified true side
low = 0;
high = 1;
if(length(varargin)>1)
    target = varargin{1};
    if( (target == low && tc.counts(1) < tc.counts(3)) ||...
          (target == high && tc.counts(1) > tc.counts(3))  )
        tc.counts = fliplr(tc.counts);
    end
end

%generate an abstract representation of the tone cloud
%where the category is an integer
tc.categories = [];

for c = 1:length(tc.counts)
    tc.categories = [tc.categories, repmat(c, 1, tc.counts(c))];
end

tc.categories = tc.categories(randperm(length(tc.categories)));

tc.lines     = zeros(tc.nTones, 3);
%line representation of the tonecloud
%n tones, start time, end time, and frequency
tc.wave  = zeros(2, floor(tc.totalDuration*tc.sampleRate));
%waveform representation of the tonecloud
%2 rows because stereo

prevFreq = nan;
startIndex = 1;

for i = 1:tc.nTones
   t1 =  (i-1)*(tc.toneDuration - tc.overlap);
   t2 = t1 + tc.toneDuration;
   %start and end times of the tone
   freqs = tc.frequencies{tc.categories(i)};
   freqs_allowed = freqs(freqs~=prevFreq);
   %disallow the previous frequency
   %to avoid repeating precisely the same frequency twice
   %the motivation for this is that repeated freqs sound qualitatively
   %different
   if(isempty(freqs_allowed))
       %if only 1 frequency was assigned per category,
       %we cannot avoid repetition
       freqs_allowed = freqs; 
   end
   f    = freqs_allowed(randi(length(freqs_allowed)));
   %sample a frequency from allowed pool, at random
   tc.lines(i,:) = [t1, t2, log10(f)];
   w = toneWave(f, tc.toneDuration, tc.ramp, tc.sampleRate);
   
   if(length(soundCal)==2)
       %2 speakers

        toneAtt = [polyval(soundCal(1,1).Coefficient,f)' polyval(soundCal(1,2).Coefficient,f)'];
        diffSPL = tc.volume - [soundCal(1,1).TargetSPL soundCal(1,2).TargetSPL];
   else
       %1 speaker - just generate the same waveform twice
        toneAtt = [polyval(soundCal(1,1).Coefficient,f)' polyval(soundCal(1,1).Coefficient,f)'];
        diffSPL = tc.volume - [soundCal(1,1).TargetSPL soundCal(1,1).TargetSPL];
   end
        
   attFactor = sqrt(10.^(diffSPL./10));

   att = toneAtt.*attFactor;
   
   ind = startIndex:(startIndex + length(w) - 1);
   tc.wave(1, ind) = w*att(1);
   tc.wave(2, ind) = w*att(2);
   prevFreq = f;
   startIndex = startIndex + length(w);
   
end


end



