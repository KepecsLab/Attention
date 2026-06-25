function blocks = gonogo_3Aud_blocks
blocks = {};

%% block 1 initial training for cued-reward
S = struct(); ST = struct();
ST.BlockNumber = [1; 1]; 
ST.P = [0.7; 0.3];
ST.CS = [1; 1]; % cueA-reward 
ST.SoundAmplitude = [60; 50];
ST.CSValence = [1; 1];
ST.US = {'Reward'; 'Reward'};   
ST.Instrumental = [0; 0];
ST.WaterAmount = [8; 8];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;


%% block 2 pavlovian for cued-reward, cued-omission, uncued-reward
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2]; 
ST.P = [0.8; 0.1; 0.1];
ST.CS = [1; 1; 0]; % reward cue A-reward, cueA-omission and uncued reward
ST.SoundAmplitude = [50; 50; 0];
ST.CSValence = [1; 1; 1];
ST.US = {'Reward'; 'Neutral'; 'Reward'};  
ST.Instrumental = [0; 0; 0];
ST.WaterAmount = [8; 0; 8];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 3 operant task for lick-reward, remember to set long answer window = 20s 
S = struct(); ST = struct();
ST.BlockNumber = [3; 3]; 
ST.P = [0.5; 0.5];
ST.CS = [1; 1]; % GoTone A 
ST.SoundAmplitude = [50; 50];
ST.CSValence = [1; 1];
ST.US = {'Reward'; 'Reward'};  
ST.Instrumental = [1; 1];
ST.WaterAmount = [8; 8];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 4 gonogo with neutral, uncued reward, uncued punish
S = struct(); ST = struct();
ST.BlockNumber = [4; 4; 4; 4; 4]; 
ST.P = [0.4; 0.3; 0.2; 0.05; 0.05];
ST.CS = [1; 4; 3; 0; 0]; % GoTone A, NoGoTone D, NeutralTone C
ST.SoundAmplitude = [50; 50; 50; 0; 0];
ST.CSValence = [1; 1; 1; 1; 1];
ST.US = {'Reward'; 'Punish'; 'Neutral'; 'Reward'; 'Punish'};   
ST.Instrumental = [1; 1; 1; 0; 0];
ST.WaterAmount = [8; 0; 0; 8; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 5 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [5; 5; 5; 5]; 
ST.P = [0.3; 0.2; 0.3; 0.2];
ST.CS = [1; 1; 4; 4]; % GoTone A and NoGoTone B
ST.SoundAmplitude = [50; 40; 50; 40];
ST.CSValence = [1; 1; 1; 1];
ST.Instrumental = [1; 1; 1; 1];
ST.WaterAmount = [8; 8; 0; 0];
ST.US = {'Reward'; 'Reward'; 'Punish'; 'Punish'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 6 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [6; 6; 6; 6; 6; 6]; 
ST.P = [0.20; 0.15; 0.15; 0.20; 0.15; 0.15];
ST.CS = [1; 1; 1; 4; 4; 4]; % GoTone A and NoGoTone B
ST.SoundAmplitude = [50; 40; 30; 50; 40; 30];
ST.CSValence = [1; 1; 1; 1; 1; 1];
ST.Instrumental = [1; 1; 1; 1; 1; 1];
ST.WaterAmount = [8; 8; 8; 0; 0; 0];
ST.US = {'Reward'; 'Reward'; 'Reward'; 'Punish'; 'Punish'; 'Punish'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 7 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [7; 7; 7; 7; 7; 7; 7; 7]; % fluff
ST.P = [0.15; 0.15; 0.1; 0.1; 0.15; 0.15; 0.1; 0.1];
ST.CS = [1; 1; 1; 1; 4; 4; 4; 4]; % GoTone A and NoGoTone B
ST.SoundAmplitude = [50; 40; 30; 20; 50; 40; 30; 20];
ST.CSValence = [1; 1; 1; 1; 1; 1; 1; 1];
ST.Instrumental = [1; 1; 1; 1; 1; 1; 1; 1];
ST.WaterAmount = [8; 8; 8; 8; 0; 0; 0; 0];
ST.US = {'Reward'; 'Reward'; 'Reward'; 'Reward'; 'Punish'; 'Punish'; 'Punish'; 'Punish'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 8 pavlovian with different values
S = struct(); ST = struct();
ST.BlockNumber = [8; 8; 8; 8]; 
ST.P = [0.25; 0.25; 0.25; 0.25];
ST.CS = [1; 2; 3; 4]; % high reward cue A, low reward cue B, neutral tone C, punish cue D
ST.SoundAmplitude = [50; 50; 50; 50];
ST.CSValence = [1; 1; 1; 1];
ST.US = {'Reward'; 'Reward'; 'Neutral'; 'Punish'};  
ST.Instrumental = [0; 0; 0; 0];
ST.WaterAmount = [8; 4; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 9 pavlovian with different Reward probability
S = struct(); ST = struct();
ST.BlockNumber = [9; 9; 9; 9]; 
ST.P = [0.3; 0.2; 0.2; 0.3];
ST.CS = [1; 2; 2; 3]; % cue A with 100% reward, cue B with 50%, cue C with 0%
ST.SoundAmplitude = [50; 50; 50; 50];
ST.CSValence = [1; 1; 1; 1];
ST.US = {'Reward'; 'Reward'; 'Neutral'; 'Neutral'};  
ST.Instrumental = [0; 0; 0; 0];
ST.WaterAmount = [8; 8; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 9 pavlovian with different Reward probability
% S = struct(); ST = struct();
% ST.BlockNumber = [9; 9; 9; 9; 9; 9; 9; 9; 9; 9; 9]; % fluff
% ST.P = [0.1; 0.1; 0.1; 0.05; 0.05; 0.05; 0.05; 0.05; 0.05; 0.3; 0.1];
% ST.CS = [1; 1; 1; 2; 2; 2; 2; 2; 2; 3; 0]; % high reward cue A, low reward cue B, punish cue C and neutral tone D
% ST.SoundAmplitude = [50; 40; 30; 50; 40; 30; 50; 40; 30; 50; 0];
% ST.CSValence = [1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1];
% ST.US = {'Reward'; 'Reward'; 'Reward'; 'Reward'; 'Reward'; 'Reward'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Reward'};  
% ST.Instrumental = [0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0];
% ST.WaterAmount = [8; 8; 8; 8; 8; 8; 0; 0; 0; 0; 8];
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% blocks{end + 1} = S;