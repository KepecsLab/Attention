function processNidaqData(src,event)

    global nidaq
    
    nidaq.ai_data = [nidaq.ai_data; event.Data]; % for non-continuous acquisition
    
% %     OLD CRAP:
%     correctSamples = nidaq.duration * nidaq.sample_rate;
%     nSamples = size(nidaq.ai_data, 1);
%     samplesShort = correctSamples - nSamples;
%     if samplesShort > 0
%         nidaq.ai_data = [nidaq.ai_data; NaN(samplesShort, size(event.Data, 2))];
%     elseif samplesShort < 0
%         nidaq.ai_data = nidaq.ai_data(1:correctSamples, :);
%     end
% 
%     %     Error using processNidaqData (line 15)
%     % Internal Error: The hardware did not report that it stopped before the timeout elapsed.
%     disp('callback executing');
%     nidaq.session.stop(); % Kills ~0.002 seconds after state matrix is done.
%     wait(nidaq.session);
%     disp('at least tried to stop');
%     while ~nidaq.session.IsDone
%         pause(0.05);
%         disp('processNidaqData: Waiting for Stop');
%         nidaq.session.stop();
%     end
%     nidaq.session.outputSingleScan(zeros(1, length(nidaq.channelsOn))); % make sure LEDs are turned off

    
    %     pause(0.05); % wait for hardware to stop, see error message below, I think this addresses the below error message:
% %     Error using processNidaqData (line 15)
% % Internal Error: The hardware did not report that it stopped before the timeout elapsed.
%     nidaq.session.stop(); % Kills ~0.002 seconds after state matrix is done.
%     wait(nidaq.session);
%     nidaq.session.outputSingleScan([0 0]); % make sure LEDs are turned off