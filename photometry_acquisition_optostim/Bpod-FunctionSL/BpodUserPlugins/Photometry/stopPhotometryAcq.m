function stopPhotometryAcq
    % as of 8/16/16, this function works to reliably stop photometry acquisition and flush any
    % output data 
    global nidaq
    

    if    ~nidaq.IsContinuous % for non-continuous mode you want to wait for whole nidaq acquisition to terminate
    %     count = 0;
        tic
        while (size(nidaq.ai_data, 1) < floor(nidaq.duration * nidaq.session.Rate)) && (toc < 20) % - (0.1 * nidaq.sample_rate)
    %         get(nidaq.session, 'ScansOutputByHardware')
            pause(0.05); % wait for processNidaqData to finish executing
    %         if count > 20
    %             keyboard
    %         end
    %         count = count + 1;
        end
    end
    nidaq.session.stop(); % Kills ~0.002 seconds after state matrix is done.
    wait(nidaq.session);
    nidaq.session.outputSingleScan(zeros(1, length(nidaq.channelsOn))); % make sure LEDs are turned off
