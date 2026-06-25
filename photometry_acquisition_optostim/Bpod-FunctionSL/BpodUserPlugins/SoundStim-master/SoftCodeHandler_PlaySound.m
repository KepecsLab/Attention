function [] = SoftCodeHandler_PlaySound(soundID)

if(soundID~=255)
    PsychToolboxSoundServer('Play', soundID);
else
    PsychToolboxSoundServer('StopAll');
end

end

