function SoftCodeHandler_PlaySound(SoundID)
    if SoundID == 255
        PsychToolboxSoundServer('StopAll');
    else
        PsychToolboxSoundServer('Play', SoundID);
    end
end   