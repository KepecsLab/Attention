function slaveResponse = updateValveSlave(so, valve)
% update command valve to be used by slave arduino (0 for omission)
    fwrite(so, valve);
    pause(0.05);
    try
        slaveResponse = fread(so);
        slaveResponse = slaveResponse(1); % to handle error where fread doesn't just pull 1 number (not sure why this is very occasionally happening)
    catch
        slaveReponse = [];
    end