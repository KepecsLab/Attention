
function output = make_white_noise_bursts(sample_rate, pulse_length, duty_cycle, total_duration,ramp_duration,do_test)

% Defaults
if nargin < 6
    do_test = 0;
end
if nargin < 5
    ramp_duration = 0.01;
end
if nargin < 4
    total_duration = 1;
end
if nargin < 3
    duty_cycle = 0.5;
end
if nargin < 2
    pulse_length = 0.1;
end
if nargin < 1
   
    sample_rate = 192e3;
end


% If nargin == 0, set defaults and show test images.
if nargin < 1
    % Note that at high sample rates, volume decreases because your speakers/ears can't produce/hear the output.
    duration = 1;
    sample_rate = 192e3;
    pulse_length = 0.2;
    duty_cycle = 0.5;
    total_duration = 2;
    ramp_duration = 0.01;
    do_test = 1;
end




% Create a long set of pulses and truncate as needed
n_pulses = ceil(total_duration/(pulse_length + (1-duty_cycle)*pulse_length));

% Pulses in rows
pulses = 2*rand( n_pulses ,ceil(sample_rate * pulse_length)) - 1;

ramp = linspace(0,1,ceil(ramp_duration*sample_rate));
pulses(:,1:length(ramp)) = bsxfun(@times,pulses(:,1:length(ramp)),ramp);
pulses(:,end-length(ramp)+1:end) = bsxfun(@times,pulses(:,end-length(ramp)+1:end),ramp(end:-1:1));

% Pauses in rows
pauses = zeros(n_pulses, ceil(sample_rate * (1-duty_cycle)*2*pulse_length));

% Reshape output
output = cat(2,pulses,pauses)';
output = output(:)';

%%
if do_test
    figure;
    subplot(3,1,1);
    imagesc(pulses);
    title('Pulses');
    subplot(3,1,2);
    imagesc(pauses);
    title('Pauses');
    subplot(3,1,3);
    imagesc( cat(2,pulses,pauses));
    %vline(pulse_length * sample_rate,'w--')
    title('Pulses+Pauses');
   
    %sound(output,sample_rate)
    
    psd_test = output;
    
    n = length(psd_test);

    y = fft(psd_test);

    psd = y.*conj(y)/n;

    f = sample_rate/n*(0:n/2);

    figure; plot(f, psd(1:length(f)));
   
end
