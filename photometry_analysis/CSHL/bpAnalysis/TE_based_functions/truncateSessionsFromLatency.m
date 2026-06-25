 
function TE = truncateSessionsFromLatency(TE, eventField, zeroTimes, endTimes, rewardTrials)
%  TE- trial event structure
% action-  'init', 'update', see below for use of update (you normally
% don't call it with update)
% lickField-  TE field containing lick event count structure, if empty
% defaults to 'usLicks'
% rewardTrials- trials with reward, defaults to trialOutcome = 1.



    % Use truncateSessionsFromLatency to interactively adjust session truncation points
    % designed initially with cuedOutcome_Odor_Complete TE structure in mind
    
    % WARNING! currently there are two ways to update
    % 1) call with 'update' as action, this will not overwrite TE, except
    % via output argument
    % 2) 'u' keypres- this WILL overwrite TE, changing only the reject
    % field Normally you use the 'u' keypress unless you want alternate
    % reject fields or something like that.
    
    % keyboard shortcuts-  left or right error- adjust truncation point for
    % a session.  Up or down arrow-  switch sessions.  Shift + left or
    % right error -> skip 10 trials rather than just 1 
    global TRUNC2
    evalin('base', 'global TRUNC2');
    % TRUNC2 trial is LAST INCLUDED TRIAL in each session    
     
    if nargin < 5
        rewardTrials = []; 
    end   
    
    yMax = 1;
            nSessions = max(TE.sessionIndex);
            nTrials = length(TE.sessionIndex);            
            lastTrial = [find(TE.sessionChange) - 1, ; nTrials]; % the last trial in each session
            firstTrial = [1; find(TE.sessionChange)]; % the first trial in each session
            TRUNC2 = struct(...
                'nSessions', nSessions,...
                'lastTrial', lastTrial,...
                'firstTrial', firstTrial,...
                'truncTrial', lastTrial,... % begin with trunc trial indicators pointing at last trial in each session
                'fig', [],...
                'ax', [],...
                'licksHandle', [],... % handle for reward licks vs trial number line plot
                'truncTrialHandle', [],... 
                'currentSession', 1, ... % index of session being interactively adjusted
                'reject', false(nTrials, 1)...
                );
                

            %% plot reward period lick rate vs trial number to visualize satiation/ lapsing behavior towards end of each session
            ensureFigure('truncFigure2', 1);
            if isempty(rewardTrials)
                TRUNC2.rewardTrials = find(filterTE(TE, 'trialOutcome', 1));
            elseif islogical(rewardTrials)
                rewardTrials = find(rewardTrials);
                TRUNC2.rewardTrials = rewardTrials;
            else
                TRUNC2.rewardTrials = rewardTrials;
            end
            
            TE.latency = calcEventLatency(TE, eventField, zeroTimes, endTimes);
            TRUNC2.latency = smooth(TE.latency(TRUNC2.rewardTrials), 5);
            TRUNC2.truncTrialHandle = zeros(1, nSessions); % will contain handles for TRUNC2 trial indicators            
            TRUNC2.licksHandle = plot(TRUNC2.rewardTrials, TRUNC2.latency); hold on; 
            
            sessionChange = [0; diff(TE.sessionIndex(rewardTrials))];
            plot(TRUNC2.rewardTrials,  sessionChange * yMax);
%             % plot TRUNC2 trial indicators
%             for session = 1:TRUNC2.nSessions
%                 truncIndex = nearest(TRUNC2.rewardTrials, TRUNC2.truncTrial(session)); % take nearest reward outcome trial to TRUNC2 trial, better to step along along trials than just reward trials
%                 TRUNC2.truncTrialHandle(session) = line('XData', TRUNC2.rewardTrials(truncIndex), 'YData', TRUNC2.latency(truncIndex), 'Marker', 'o',...
%                     'MarkerSize', 8,...
%                     'MarkerFacecolor', 'm'); 
%             end
%             set(TRUNC2.truncTrialHandle(TRUNC2.currentSession), 'MarkerFaceColor', 'g'); % highlight current session TRUNC2 marker
% 
%             sep = strfind(TE.filename{1}, '_');
%             subjectName = TE.filename{1}(1:sep(2)-1);
%             ylabel('RewardCollectLatency'); xlabel('trial #'); textBox(subjectName);
%             set(gca, 'YLim', [0 yMax]); hold on;
end

            
%             % attempt to use TRUNC2ation points implied by reject field in
%             % TE (if it exists)
%             if isfield(TE, 'reject')
%                 TRUNC2.reject = TE.reject;
%                 for session = 1:TRUNC2.nSessions
%                     counter = TRUNC2.lastTrial(session);
%                     % scan back from last trial and find last rejected
%                     % trial (might be able to do this without a loop but whatever)
%                     while TRUNC2.reject(counter) == 1
%                         if counter == TRUNC2.firstTrial(session)
%                             break % if for some reason all trials in session have been rejected, stop at first trial
%                         end
%                         counter = counter - 1;
%                     end
%                     TRUNC2.truncTrial(session) = counter;
%                     updateTRUNC2(session, counter); % update
%                 end
%             else
%                 TE.reject = TRUNC2.reject;
%             end
% 
%         case 'update'
%             TE.reject = logical(TRUNC2.reject);
%     end
% end
% 
% function truncKeyPressFcn(src, evt) % window key press fcn, executes whenever figure or its children has/have focus...
%     global TRUNC2
%     si = TRUNC2.currentSession; % session index
%     switch evt.Character
%         case 28 % left arrow
%             if ~ismember('shift', evt.Modifier)
%                 updateTRUNC2(si, TRUNC2.truncTrial(si) - 1);
%             else
%                 updateTRUNC2(si, TRUNC2.truncTrial(si) - 10);
%             end
%         case 29 % right arrow
%             if ~ismember('shift', evt.Modifier)
%                 updateTRUNC2(si, TRUNC2.truncTrial(si) + 1);
%             else
%                 updateTRUNC2(si, TRUNC2.truncTrial(si) + 10);
%             end   
%         case 30 % up arrow
%             if si + 1 <= TRUNC2.nSessions
%                 updateTRUNC2(si + 1);
%             else
%                 updateTRUNC2(1); % cycle to first session
%             end
%         case 31 % down arrow
%             if si - 1 >= 1
%                 updateTRUNC2(si - 1);
%             else
%                 updateTRUNC2(TRUNC2.nSessions); % cycle to last session
%             end
%         case 117 % u, update 
%             evalin('base', 'TE.reject=TRUNC2.reject;');
%             display('*** TRUNC2ateSessionsFromTE: updated TE.reject ***');
%         otherwise
%     end
% end
% 
% function updateTRUNC2(s,t)
%     % s --> session number, pass [] to use current session
%     % t --> new trial number of TRUNC2 trial for current session
%     global TRUNC2
%     if nargin < 2
%         t = 0;
%     end
%     if isempty(s)
%         s = TRUNC2.currentSession;
%     end
%     if TRUNC2.currentSession ~= s
%         set(TRUNC2.truncTrialHandle(TRUNC2.currentSession), 'MarkerFaceColor', 'm'); % unhighlight old current session TRUNC2 marker
%         TRUNC2.currentSession = s;
%         set(TRUNC2.truncTrialHandle(TRUNC2.currentSession), 'MarkerFaceColor', 'g'); % highlight current session TRUNC2 marker
%     end
%     
%     if t
%         TRUNC2.truncTrial(s) = min(max(t, TRUNC2.firstTrial(s)), TRUNC2.lastTrial(s));
%         truncIndex = nearest(TRUNC2.latency, TRUNC2.truncTrial(s));
%         set(TRUNC2.truncTrialHandle(s), 'XData', TRUNC2.rewardTrials(truncIndex), 'YData', TRUNC2.latency(truncIndex));
%         
%         % update reject field, TRUNC2 trial is LAST INCLUDED TRIAL        
%         TRUNC2.reject(TRUNC2.firstTrial(s):TRUNC2.truncTrial(s)) = 0;
%         if TRUNC2.truncTrial(s) < TRUNC2.lastTrial(s)
%             TRUNC2.reject((TRUNC2.truncTrial(s) + 1):TRUNC2.lastTrial(s)) = 1;
%         end
%     end
% end
%     
%     
%     
% function TRUNC2Close(src,evt)
%     global TRUNC2
%     clf(TRUNC2.fig);
%     delete(TRUNC2.fig);
%     clear TRUNC2;
% end
% 
% 
% 
% 
