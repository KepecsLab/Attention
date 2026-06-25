
% Bpod protocol plot for displaying sound stimuli
% shows the sound on the first channel:
% the audio signal in the time domain (upper plot)
% and the power spectral density (lower plot)
classdef StimPlot < handle

properties
    

    
    %GUI stuff
    fig = [];
    topAxes = [];
    bottomAxes = [];
    

end

methods
    
    function SP = StimPlot() 


        width = 500;
        height= 300;
        
        SP.fig            = figure('Position', [100 280 width height],'name','StimPlot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'on'  );
        SP.topAxes        = axes('Position', [0.15, 0.65, 0.75, 0.3],'Color', [1 1 1]);
        SP.bottomAxes     = axes('Position', [0.15, 0.2, 0.75, 0.3],'Color', [1 1 1]);
        
    end
    
    function show(SP, soundWave, sampleRate)

        prevFig = gcf;
        figure(SP.fig);

        set(SP.fig, 'CurrentAxes', SP.topAxes);
        t = (1:length(soundWave))/sampleRate;
        plot(t, soundWave);
        xlabel('Time (s)');
        ylabel('Sound Signal');
        
        xlim([0, t(end)]);

        y = fft(soundWave);

        psd = y.*conj(y)/length(soundWave);

        f = sampleRate/length(soundWave)*(0:length(soundWave)/2);
        
        set(SP.fig, 'CurrentAxes', SP.bottomAxes);
        plot(f/1000, psd(1:length(f)));
        xlabel('Frequency (kHz)');
        ylabel('Power');
        
        %display power in freq band [0, 80 kHz]
        xlim([0, 80/1000]);

        figure(prevFig);
        
    end

    function close(LP)
        close(LP.fig);
    end

end

end
%end StimPlot classdef



