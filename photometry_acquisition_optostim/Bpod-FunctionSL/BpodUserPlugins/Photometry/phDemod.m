function demod = phDemod(rawData, refData, sampleRate, modRate, lowCutoff)
% DEMODULATE AM-MODULATED INPUT IN QUADRATURE GIVEN A REFERENCE
% tBaseline-  baseline period, in seconds
% lowCutoff corner frequency for 5-pole butterworth filter (lowpass),
%{
 Note 9/2018 I am not using the modRate parameter at all because I'm directly using the refData here (since it already exists in memory)
 Also refData has to be the actual data and not the generative parameters
 (new way of demodulating by reconstructing the reference signal)
 Also, this whole thing is super kludgy (compared to my offline code) but
 I'm not changing it now because it doesn't really matter
%}
    global nidaq
    if nargin < 5
        lowCutoff = 15; 
    end

%     if nargin < 5
%         tBaseline = []; % if empty, normalize (zscore) by entire range
%     end
    
    if size(rawData, 2) ~= 1 || size(refData, 2) ~= 1
        disp('*** Error in phDemod, refData and rawData must be column vectors ***');
        demod = [];
        return
    end
    rawData = rawData(:); % ensure column vectors
    refData = refData(:); 


    % note-   5 pole Butterworth filter in Matlab used in Frohlich and McCormick  
     % Create butterworth filter
    lowCutoff = lowCutoff/(sampleRate/2); % normalize to nyquist frequency
    % for a cutoff freq of 300Hz and sample rate of 1000Hz, cutoff
    % corresponds to 0.6pi rad/sample    300/1000 * 2 = 0.6    
    [z,p,k] = butter(5, lowCutoff, 'low');   % double order of butterworth filter since I'm not using filtfilt
   [sos, g] = zp2sos(z,p,k);
    [z,p,k] = butter(5, 25/(sampleRate/2), 'high');   % double order of butterworth filter since I'm not using filtfilt
   [sos_ac, g_ac] = zp2sos(z,p,k);
    if modRate
        if ~isstruct(refData)
            nSamples = length(rawData);
            refData = refData(1:nSamples,1); % shorten refData to same size as rawData    
            refData = filtfilt(sos_ac, g_ac, refData); % *** get rid of DC offset!!!!
            rawData = filtfilt(sos_ac, g_ac, rawData);
            % generate 90degree shifted copy of refData
            samplesPerPeriod = 1/modRate / (1/sampleRate);
            quarterPeriod = round(samplesPerPeriod / 4); % ideally you shouldn't have to round, i.e. mod frequencies should be close to factors of sample freq
            refData90 = circshift(refData, [1 quarterPeriod]);

            processedData_0 = rawData .* refData;
            processedData_90 = rawData .* refData90;
        else
            error(' refData mode not implemented- see phDemod_v2 and demodulateSession found in CSHL repo');
        end
    end

    pad = 1; % pad beginning of data to attenuate filter artifact
    if modRate
        if pad
    %         paddedData = fliplr(demodData(1:sampleRate, 1)); % pad with 1s of reflected data
    %         paddedData = demodData(randperm(sampleRate), 1); % pad with 1s of randomized data (should still contain DC trend)
            paddedData_0 = processedData_0(1:sampleRate, 1); % AGV sez: pad with 1s of data, should be in phase as period should be an integer factor of 1 second
            paddedData_90 = processedData_90(1:sampleRate, 1); % AGV sez: pad with 1s of data, should be in phase as period should be an integer factor of 1 second        
            % HOWEVER- an additional problem is that there is a hardware onset
            % transient when the LED turns on

            %% for online analysis just use filt for speed (not filtfilt)
            demodDataFilt_0 = filtfilt(sos,g,[paddedData_0; processedData_0]);
            demodDataFilt_90 = filtfilt(sos,g,[paddedData_90; processedData_90]);        
            demod_0 = demodDataFilt_0(length(paddedData_0) + 1:end, 1);
            demod_90 = demodDataFilt_90(length(paddedData_90)+1:end, 1);        
        else
    %         demod_0 = filtfilt(b, a, demodData_0);
        end
        demod = (demod_0 .^2 + demod_90.^2) .^(1/2); % quadrature decoding

        % correct for amplitude of reference 
        % Vsig = Vsig*Vref/2 + Vsig*Vref/2 * Cos(2*Fmod * time)
        % you filter out the second term
        % multiply by two given that Vref = 1;

        demod = demod * 2;
      
    else %% Post 9/2018 kludge, if modRate = 0, then you are in the DC mode where you don't modulate the LEDs.  Therefore, don't demodulate the data, instead just filter and return
        if pad
            paddedData = rawData(1:sampleRate, 1);
            demod = filtfilt(sos,g,[paddedData; rawData]);
            demod = demod(length(paddedData) + 1:end, 1);
        end
    end
    
    
    
