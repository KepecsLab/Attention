function updateLEDData
    % updated 4/21/2017
    global nidaq

    % generate output data
    nidaq.dt = 1/nidaq.session.Rate;    
%     t = (0:nidaq.dt:nidaq.duration - nidaq.dt)'; %last sample starts dt prior to t = duration
    if nidaq.IsContinuous
        % 10/26/20  added an extra 0.2 seconds to see if this avoids matlab
        % freezing
        t = (0:nidaq.dt:(nidaq.duration + rem(nidaq.duration, nidaq.updateInterval) + 0.2))'; % pad output data so that it is an integer multiple of updateInterval so that you can save the last snippet of data      
    else
        t = (0:nidaq.dt:(nidaq.duration + 0.2))'; %add 200 extra samples to ensure that you have enough output data to satisfy NotifyWhenDataAvailableExceeds property
    end
    nidaq.ao_data = [];
    ref = struct(...
        'phaseShift', [],...
        'freq', [],...
        'amp', [],...
        'duration', [],...
        'sample_rate', []...
        );
    for ch = nidaq.channelsOn
        phaseShift = rand(1) * 2 * pi;
        freq = nidaq.(['LED' num2str(ch) '_f']);
        amp = nidaq.(['LED' num2str(ch) '_amp']);
        if freq % modulation mode
            channelData = (sin(2*pi*freq*t + phaseShift) + 1) /2 * amp;
        else % DC mode, if freq = 0;
            channelData = zeros(size(t)) + amp / 2; % should be same mean amplitude as modulated, assuming that LED driver is linear
        end
        channelData(end) = 0;
        nidaq.ao_data = [nidaq.ao_data channelData];
        ref.phaseShift(end + 1) = phaseShift;
        ref.freq(end + 1) = freq;
        ref.amp(end + 1) = amp;
        ref.duration(end + 1) = nidaq.duration;
        ref.sample_rate(end + 1) = nidaq.session.Rate;
    end
    ref.channelsOn = nidaq.channelsOn;
    nidaq.ref = ref;
    nidaq.session.queueOutputData(nidaq.ao_data);
    display([num2str(size(nidaq.ao_data, 1)) ' samples queued']);