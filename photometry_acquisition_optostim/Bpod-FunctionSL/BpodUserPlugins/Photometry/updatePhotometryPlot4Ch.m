function updatePhotometryPlot4Ch(Op, startX)
% startX: time point in seconds from beginning of photometry
% acquisition to be defined as 0
    if nargin < 2
        startX = 0;
    end
    global BpodSystem nidaq
    
    syncPhotometrySettings2;

    Op = lower(Op);
    channelsOn = nidaq.channelsOn;

    switch Op
        case 'init'
            scrsz = get(groot,'ScreenSize'); 
            heightScr=scrsz(4);
            widthFig1 = min(scrsz(3)*.1*2,scrsz(3)/5-50);
%             heightFig1=min(scrsz(4)*.2*2);
            heightFig1=scrsz(4)/3;
            marg=25;
            %% start with Nidaq raw input figure
%             BpodSystem.ProtocolFigures.rawFig       = figure(...
%                 'Position', [marg heightScr-heightFig1/2-marg widthFig1 heightFig1/2],...
%                 'Name','Raw signal plot','numbertitle','off');
            BpodSystem.ProtocolFigures.rawFig       = figure(...
                'Position', [marg scrsz(4)*2/3-100 widthFig1 heightFig1],...
                'Name','Nidaq Raw Input','numbertitle','off');
            for ch=nidaq.channelsOn
                BpodSystem.ProtocolFigures.rawPanel(ch)=subplot(4,1,ch);
                hold off;                
            end
            %% continue with DFF figure            
            BpodSystem.ProtocolFigures.NIDAQFig       = figure(...
                'Position', [widthFig1 scrsz(4)*2/3-100 widthFig1 heightFig1],'Name','Demod Data','numbertitle','off');
            for ch=nidaq.channelsOn
                BpodSystem.ProtocolFigures.NIDAQPanel(ch)= subplot(4,1,ch);
            end
     
        case 'update'
            n_chI = 1:numel(nidaq.channelsOn);
            ai_n = 1;
            for ch = nidaq.channelsOn
                plot(BpodSystem.ProtocolFigures.rawPanel(ch),nidaq.ai_data(:,n_chI(ai_n)),'LineWidth',.5);
            
                xData = nidaq.online.currentXData + startX;                
                demod_ch = nidaq.online.currentDemodData{ch};
                plot(BpodSystem.ProtocolFigures.NIDAQPanel(ch), xData, demod_ch);   
                ylabel(BpodSystem.ProtocolFigures.NIDAQPanel(ch),{['ch' num2str(ch)]});

                zoomFactor = 5; % scale y axis +/- zoomFactor standard deviations from the mean
                
                m = mean(demod_ch);
                s = std(demod_ch);                

                try % if LED amp is 0 then this doesn't work
                    set(BpodSystem.ProtocolFigures.NIDAQPanel(ch), 'YLim', [m - s*zoomFactor, m + s*zoomFactor]);
                catch
                end
                ai_n = ai_n+1;
%                 drawnow;
        %     legend(nidaq.ai_channels,'Location','East')
            end
    end