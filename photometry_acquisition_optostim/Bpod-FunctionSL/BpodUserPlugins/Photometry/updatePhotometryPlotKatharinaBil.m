function updatePhotometryPlotKatharinaBil(Op, startX, titles)
% startX: time point in seconds from beginning of photometry
% acquisition to be defined as 0
if nargin<3
    titles={'start recording'};
    if nargin < 2
        startX = 0;
    end
end
channelColors=[0 .5 0; .7 0 0; 0 .2 .8; .8 .2 0];
window=[-1 2];

global BpodSystem nidaq

%% for simulation (reverse when finished)
% if ~BpodSystem.EmulatorMode
syncPhotometrySettings2;
% else
%     titles={'reward','stimulus'};
%     samples=round(rand*1000);
%     startX=sort(randsample(samples,2));
%
%     nidaq.online.currentXData=1:samples;
%     nidaq.online.currentDemodData{1}=rand(1,samples);
%     nidaq.online.currentDemodData{1}(startX(1))=10;
%     nidaq.online.currentDemodData{1}(startX(2))=20;
%
%     nidaq.online.currentDemodData{1}=smoothdata(nidaq.online.currentDemodData{1},'gaussian',10);
%     nidaq.online.currentDemodData{2}=rand(1,samples);
% end
Op = lower(Op);

switch Op
    case 'init'
        scrsz = get(groot,'ScreenSize');
        widthScr=scrsz(3);
        heightScr=scrsz(4);
        widthFig1 = min(scrsz(3)*.2*length(startX),scrsz(3)-25);
        widthFig2 = min(scrsz(3)*.2*2,scrsz(3)-25);
        heightFig1=min(scrsz(4)*.2*2);
        heightFig2=min(scrsz(4)*.2*length(startX));
        marg=100;
        %% start with raw signal figure
        BpodSystem.ProtocolFigures.rawFig       = figure(...
            'Position', [marg heightScr-heightFig1/2-marg widthFig1 heightFig1/2],...
            'Name','Raw signal plot','numbertitle','off');
        for ch=1:length(startX)
            BpodSystem.ProtocolFigures.rawPanel(ch,1)=subplot(1,length(startX),ch);
            hold off;
        end

        %% continue with DFF figure
        if length(startX)>2
        BpodSystem.ProtocolFigures.dffFig       = figure(...
            'Position', [marg heightScr-heightFig2-marg widthFig2 heightFig2 ],...
            'Name','DFF plot','numbertitle','off');
        else
            % add here old settings
        end
        k=1;
        for ch=1:length(startX)
            for condition=1:numel(titles)
                BpodSystem.ProtocolFigures.dffPanel(ch,condition)=subplot(length(startX),numel(titles),k);
                hold on;
                windowSample=bpX2pnt(window, nidaq.sample_rate/nidaq.online.decimationFactor);
                BpodSystem.ProtocolFigures.dffMean(ch,condition)=plot(BpodSystem.ProtocolFigures.dffPanel(ch,condition),...
                    windowSample(1):windowSample(2),zeros(length(windowSample(1):windowSample(2)),1),'Color',channelColors(ch,:),'LineWidth',1);
                if ch==1
                    BpodSystem.ProtocolFigures.dffPanel(ch,condition).Title.String=titles{condition};
                end
                k=k+1;
            end
        end
        
    case 'update'
        n_chI = 1:numel(nidaq.channelsOn);
        ai_n = 1;
        for ch = nidaq.channelsOn
            plot(BpodSystem.ProtocolFigures.rawPanel(ch),nidaq.ai_data(:,n_chI(ai_n)),'Color',channelColors(ch,:),'LineWidth',.5);
            
            for condition=1:length(startX)
                if ~isnan(startX(condition))
                    %single trace
                    alignedXData=nidaq.online.currentXData-startX(condition);
%                     alignedXData=alignedXData-min(alignedXData(alignedXData>0));
                    idx = alignedXData>=window(1)&alignedXData<=window(2);
                    xData = ceil(alignedXData(idx)*100)/100;
                    try
%                         yData = BpodSystem.PluginObjects.Photometry.currentTrialDFF{ch}(idx);                        
                    yData = nidaq.online.currentDemodData{ch}(idx);
                    catch
                    end
                    plot(BpodSystem.ProtocolFigures.dffPanel(ch,condition),xData, yData,'Color','k','LineWidth',.5);
                    
                    %update mean
                    if all(BpodSystem.ProtocolFigures.dffMean(ch,condition).YData==0)
                        %pad data to the right and left to make sure that
                        %future
                        BpodSystem.ProtocolFigures.dffMean(ch,condition).XData=xData;
                        BpodSystem.ProtocolFigures.dffMean(ch,condition).YData=yData;
                    else
                        weight=length(findall(BpodSystem.ProtocolFigures.dffPanel(ch,condition),'Type','Line'))-1;
                        meanYData=BpodSystem.ProtocolFigures.dffMean(ch,condition).YData';
                        meanXData=BpodSystem.ProtocolFigures.dffMean(ch,condition).XData';
                        updateIdx=ismember(meanXData,xData);%meanXData>min(xData)&meanXData<max(xData);%
                        oldIdx=ismember(xData,meanXData);%xData>min(meanXData)&xData<max(meanXData);%
                        %update timepoints that are in mean and in new
                        %trial
                        try
                        meanYData(updateIdx)=(meanYData(updateIdx).*weight+yData(oldIdx))./(weight+1);
                        %add new timepoints that are not yet in mean but in
                        %new trial
                        meanXData=[meanXData;xData(~oldIdx)];
                        [meanXData sortIdx]=sort(meanXData);
                        meanYData=[meanYData;yData(~oldIdx)];
                        meanYData=meanYData(sortIdx);
                        catch
                        fprintf('Figure not updated, Trial %d\n',length(BpodSystem.Data.Custom.RewardReceivedTotal));    
                        end
                        BpodSystem.ProtocolFigures.dffMean(ch,condition).XData=meanXData;
                        BpodSystem.ProtocolFigures.dffMean(ch,condition).YData=meanYData;
                        uistack(BpodSystem.ProtocolFigures.dffMean(ch,condition),'top');
                    end
                end
            end
            ai_n = ai_n+1;
        end
        %             drawnow;
        %     legend(nidaq.ai_channels,'Location','East')
end