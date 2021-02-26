classdef Visualizer < rl.env.viz.AbstractFigureVisualizer
% Visualize a reinforcement learning environment in a figure

% Copyright 2021 The MathWorks, Inc.

    methods
        function this = Visualizer(env)
            this = this@rl.env.viz.AbstractFigureVisualizer(env);
        end
    end
    methods (Access = protected)
        function f = buildFigure(this)
            f = figure(...
                'Toolbar','none',...
                'Visible','on',...
                'HandleVisibility','off', ...
                'NumberTitle','off',...
                'Name','Visualizer',... 
                'MenuBar','none',...
                'CloseRequestFcn',@(~,~)delete(this));
            if ~strcmp(f.WindowStyle,'docked')
                f.Position(3:4) = [400 500];
            end
            ha = gca(f);
            
            ha.XLimMode = 'manual';
            ha.YLimMode = 'manual';
            ha.ZLimMode = 'manual';
            ha.DataAspectRatioMode = 'manual';
            ha.PlotBoxAspectRatioMode = 'manual';
            ha.XTick = [];
            ha.YTick = [];
            ha.Box = 'on';
            
            ha.XLim = this.Environment.XLim;
            ha.YLim = [1.1 1] .* this.Environment.YLim;
            
            hold(ha,'on');
        end
        function updatePlot(this)
            env = this.Environment;
            f = this.Figure;
            ha = gca(f);
            cla(ha);
            
            % bh is the length of the paddle
            bl = env.PaddleLength;
            % bw is the width of the paddle
            bw = env.PaddleWidth;
            % rad is the radius of the ball
            rad = env.BallRadius;
            
            % extract position and angle
            state = env.State;
            ball_x = state(1);
            ball_y = state(2);
            paddle_x = state(5);
            
            % plot ball
            rectangle(ha,'Position',[ball_x-rad ball_y-rad 2*rad 2*rad],'Curvature',[1 1],'FaceColor','r')
            
            % plot paddle
            rectangle(ha,'Position',[paddle_x-0.5*bl env.YLim(1)-bw bl bw],'FaceColor','k');
            
            % plot number of hits
            txt = sprintf("Hits: %d",env.Hits);
            text(ha,env.XLim(2)-0.5,env.YLim(2)-0.2,txt);
            
            % Refresh rendering in figure window
            drawnow();
        end
    end
end