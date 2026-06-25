
function SO = initValveSlave(portname)

% SO = serial object, [] if failure occurs
%   e.g.  portname = 'COM7';
    SO = [];
    try
        SO = serial(portname, 'BaudRate', 9600, 'DataBits', 8, 'StopBits', 1, 'Timeout', 1, 'DataTerminalReady', 'off');
    catch
        disp('serial port init failure: initValveSlave');
        return
    end
    
    set(SO, 'OutputBufferSize', 8000);
    set(SO, 'InputBufferSize', 50000);
    try
        fopen(SO);
    catch
        fclose(instrfind);
        fopen(SO);
    end
    fwrite(SO, char(50));
    pause(.1); % wait for arduino to talk back
                                                        %     tic;
                                                        %     while SO.BytesAvailable == 0
                                                        %         if toc > 1
                                                        %             break
                                                        %         end
                                                        %     end
    success = fread(SO, SO.BytesAvailable);
    if success ~= 50
        SO = [];
        return
    else
        disp('*** valve slave connected ***');
    end