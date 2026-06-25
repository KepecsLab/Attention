classdef PokesPlot < handle

properties

    eventTime = 0.01;
    %duration to assign to input events
    %for purposes of displaying them
    
    imagePixels = [1024, 512];
    %size of the internal buffer image
    
    StateColors = [];
    EventAliases = [];
    
    autostep   = 0;
    manualstep = 1;
    mode       = nan;
    
    firstToPlot = nan;
    lastToPlot = nan;
    
    Data = [];
    
    %GUI stuff
    fig = [];
    AlignOnLabel = [];
    AlignOnMenu = [];
    LeftEdgeLabel = [];
    LeftEdgeBox = [];
    RightEdgeLabel = [];
    RightEdgeBox = [];
    NToPlotLabel   = [];
    NToPlotBox = [];
    
    BackButton = [];
    ForwardButton = [];
    BigBackButton = [];
    BigForwardButton = [];
    
    
    axMain   = [];
    axColors = [];
    
    
end

methods
    
    function PP = PokesPlot(m,sc,evt,varargin)
        
        if(strcmp(m, 'autostep'))
            PP.mode = PP.autostep;
        elseif(strcmp(m, 'manualstep'))
            PP.mode = PP.manualstep;
        else
            error(['PokesPlot mode ' m ' does not exist.']);
        end
        
        PP.StateColors = sc;
        PP.EventAliases = evt;
        if(length(varargin)>=1)
            PP.imagePixels = varargin{1};
        end
        
        stateNames =  fieldnames(PP.StateColors);
    
        PP.fig = figure('Position', [100 280 400 700],'name','PokesPlot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'on');
        PP.AlignOnLabel = uicontrol('Style', 'text','String','align on:', 'Position', [30 70 60 20], 'FontWeight', 'normal', 'FontSize', 10,'FontName', 'Arial');
        PP.AlignOnMenu = uicontrol('Style', 'popupmenu','Value',1, 'String', fields(PP.StateColors), 'Position', [95 70 150 20], 'FontWeight', 'normal', 'FontSize', 10, 'BackgroundColor','white', 'FontName', 'Arial','Callback', {@updateCallback, PP});
        
        PP.LeftEdgeLabel = uicontrol('Style', 'text','String','start', 'Position', [30 35 40 20], 'FontWeight', 'normal', 'FontSize', 10,'FontName', 'Arial');
        PP.LeftEdgeBox = uicontrol('Style', 'edit','String',-0.25, 'Position', [75 35 40 20], 'FontWeight', 'normal', 'FontSize', 10, 'BackgroundColor','white', 'FontName', 'Arial','Callback', {@updateCallback, PP});
        
        PP.RightEdgeLabel = uicontrol('Style', 'text','String','end', 'Position', [30 10 40 20], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
        PP.RightEdgeBox = uicontrol('Style', 'edit','String',3, 'Position', [75 10 40 20], 'FontWeight', 'normal', 'FontSize', 10, 'BackgroundColor','white', 'FontName', 'Arial','Callback', {@updateCallback, PP});
         
        PP.NToPlotLabel = uicontrol('Style', 'text','String','N trials', 'Position', [130 33 50 20], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
        PP.NToPlotBox = uicontrol('Style', 'edit','String',10, 'Position', [185 35 40 20], 'FontWeight', 'normal', 'FontSize', 10, 'BackgroundColor','white', 'FontName', 'Arial','Callback', {@updateCallback, PP});
        
        if(PP.mode==PP.manualstep)
            set(PP.fig, 'Position', [100 280 500 700]);
            PP.BackButton= uicontrol('Style', 'pushbutton','String', '<', 'Position', [310, 70, 60, 20], 'FontWeight', 'normal', 'FontSize', 10, 'BackgroundColor','white', 'FontName', 'Arial','Callback', {@stepCallback, PP, -1});
            PP.ForwardButton= uicontrol('Style', 'pushbutton','String', '>', 'Position', [370, 70, 60, 20], 'FontWeight', 'normal', 'FontSize', 10, 'BackgroundColor','white', 'FontName', 'Arial','Callback', {@stepCallback, PP, 1});
            PP.BigBackButton= uicontrol('Style', 'pushbutton','String', '<<', 'Position', [250, 70, 60, 20], 'FontWeight', 'normal', 'FontSize', 10, 'BackgroundColor','white', 'FontName', 'Arial','Callback', {@stepCallback, PP, -10});
            PP.BigForwardButton= uicontrol('Style', 'pushbutton','String', '>>', 'Position', [430, 70, 60, 20], 'FontWeight', 'normal', 'FontSize', 10, 'BackgroundColor','white', 'FontName', 'Arial','Callback', {@stepCallback, PP, 10});
        end
        
        PP.axMain = axes('Position', [0.15 0.38 0.8 0.6],'Color', [1 1 1]);
        
        set(PP.fig, 'CurrentAxes', PP.axMain);
        set(gca, 'XLim', [str2double(get(PP.LeftEdgeBox, 'String')) str2double(get(PP.RightEdgeBox, 'String'))]);
        set(gca, 'YLim', [0.5 str2double(get(PP.NToPlotBox, 'String'))+0.5]);
        %set(gca, 'XTick', []);
        set(gca, 'YTick',[1, 10:10:5000] );
        set(gca, 'TickLength',[0 0]);
        xlabel('Time (s)');
        ylabel('Trial Number');
        
        PP.axColors = axes('Position', [0.2 0.27 0.7 0.03]);
         
        % plot reference colors
        
        for i=1:length(stateNames)
            fill([i-0.9 i-0.9 i-0.1 i-0.1], [0 1 1 0], PP.StateColors.(stateNames{i}),'EdgeColor','none');
            if length(stateNames{i})< 10
                legend = stateNames{i};
            else
                legend = stateNames{i}(1:10);
            end
            hold on; 
            txt = text(i-0.5, -0.5, legend);
            set(txt, 'Interpreter', 'none', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90);
            set(gca, 'Visible', 'off');
        end;
        ylim([0 1]); 
        xlim([0 length(stateNames)]);
        update(PP);
        %this sets axes up
    end
    
    function update(PP, varargin)
        
        img = ones(PP.imagePixels(1), PP.imagePixels(2), 3);
        
        if(length(varargin)>=1)
            PP.Data = varargin{1};
        end
        if(isempty(PP.Data))
            currentTrial = 0;
        else
            currentTrial = PP.Data.nTrials;
        end
        nToPlot = str2double(get(PP.NToPlotBox,'String'));
        
        if(PP.mode==PP.autostep)
       
            PP.lastToPlot  = max(currentTrial, nToPlot);
            PP.firstToPlot = PP.lastToPlot - nToPlot + 1;
        else
            if(isnan(PP.firstToPlot) || isnan(PP.lastToPlot))
                %just plot the last n trials by default
                PP.lastToPlot  = max(currentTrial, nToPlot);
                PP.firstToPlot = PP.lastToPlot - nToPlot + 1;
            else
                %need to update assuming that nToPlot may have changed
                PP.lastToPlot  = PP.firstToPlot + nToPlot;
            end
        end 
        
        xmin = str2double(get(PP.LeftEdgeBox, 'String'));
        xmax = str2double(get(PP.RightEdgeBox,'String'));
        ymin = PP.firstToPlot - 0.5;
        ymax = PP.lastToPlot + 0.5;
    
        if(~isempty(PP.Data) && PP.Data.nTrials > 0)
        
            stateNames = fieldnames(PP.Data.RawEvents.Trial{1,PP.Data.nTrials}.States);
        
            for i=PP.firstToPlot:PP.lastToPlot
        
                
                
                if i>0 && i<= PP.Data.nTrials

                    names = get(PP.AlignOnMenu, 'String');
                    
                    alignTo = names{get(PP.AlignOnMenu, 'Value')};
                    
                    aligning_time = nan;
                    
                    if(isfield(PP.Data.RawEvents.Trial{i}.States, alignTo))
                        aligning_time = getfield(PP.Data.RawEvents.Trial{i}.States, alignTo);
                        aligning_time = aligning_time(1);
                    elseif(isfield(PP.Data.RawEvents.Trial{i}.Events, alignTo))
                        aligning_time = getfield(PP.Data.RawEvents.Trial{i}.Events, alignTo);
                        if(~isempty(aligning_time))
                            aligning_time = aligning_time(1);
                        end
                    end
        
                    if(isnan(aligning_time))
                        %disp(['Warning: PokesPlot is trying to align to a state or event which did not occur in trial ' i])
                    else
            
                        for j=1:length(stateNames)
                
                            stateName = stateNames{j};
                
                            if isfield(PP.StateColors, stateName)
                                %if there is a color defined for this state, use it
                                state_color = PP.StateColors.(stateName);
                            else
                                state_color = [1 1 1];
                            end
                
                            t = PP.Data.RawEvents.Trial{i}.States.(stateName)-aligning_time(1);
                            y1 = i - 0.45;
                            y2 = i;
                            img = fillRectangle(img, t(1), t(2), y1, y2, xmin, xmax, ymin, ymax, state_color);
                
                        end
            
                        events = PP.Data.RawEvents.Trial{1,i}.Events;
                        %struct with event names and times
        
                        eventNames = fieldnames(PP.Data.RawEvents.Trial{1,i}.Events);

                        for k = 1:length(eventNames)
                
                            eventName = eventNames{k};
                            %if the event has a special name assigned to it
                            if(isfield(PP.EventAliases, eventName))
                                alias = getfield(PP.EventAliases, eventName);
                                % if we set PokesPlot to track this event
                                if(isfield(PP.StateColors, alias))
                        
                                    color = PP.StateColors.(alias);
                                    times = getfield(events, eventName);
                                    %get all times at which this occurred

                                    %make a separate patch for each time
                                    for m = 1:length(times)
                                        t = times(m) - aligning_time(1);
                                        y1 = i;
                                        y2 = i + 0.45;
                                        img = fillRectangle(img, t, t+PP.eventTime, y1, y2, xmin, xmax, ymin, ymax, color);
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        currentFig = gcf;
      
        figure(PP.fig);
      
        set(PP.fig, 'CurrentAxes', PP.axMain);
        image([xmin,xmax],[ymin,ymax],img)
        set(gca, 'YDir', 'normal');
        set(gca, 'XLim', [xmin xmax]);
        set(gca, 'YLim', [ymin ymax]);
        set(gca, 'YTick',[1, 10:10:5000] );
        xlabel('Time (s)');
        ylabel('Trial Number');
        
        if(~isempty(PP.Data) && isfield(PP.Data, 'SubjectName') && isfield(PP.Data, 'Date') && isfield(PP.Data, 'SessionDescription'))
            set(gcf, 'Name', ['PokesPlot - ', PP.Data.SubjectName, ' - ', PP.Data.Date, ' - ', PP.Data.SessionDescription]);
        end

        figure(currentFig);
    end
    

    function step(PP, s)

        newFirstToPlot = max(PP.firstToPlot + s, 1);
        newLastToPlot  = newFirstToPlot + str2double(get(PP.NToPlotBox, 'String'));
        
        if(newFirstToPlot ~= PP.firstToPlot || newLastToPlot ~= PP.lastToPlot)
            PP.firstToPlot = newFirstToPlot;
            PP.lastToPlot  = newLastToPlot;
            update(PP);
        end
    end


    function close(PP)
        close(PP.fig);
    end
end

end
%end classdef

function updateCallback(~, ~, PP)
    update(PP);
end

function stepCallback(~, ~, PP, s)
    step(PP, s);
end

