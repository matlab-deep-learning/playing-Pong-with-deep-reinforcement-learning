classdef Environment < rl.env.MATLABEnvironment
    % ENVIRONMENT simulates a game in MATLAB.
    
    % Copyright 2021, The MathWorks Inc.
    
    %% Properties (set properties' attributes accordingly)
    properties
        % X Limit for ball movement
        XLim = [-1 1]
        
        % Y Limit for ball movement
        YLim = [-1.5 1.5]
        
        % Radius of the ball
        BallRadius = 0.04
        
        % Starting ball Velocity
        BallVelocity = [2 2]
        
        % Length of the paddle
        PaddleLength = 0.25
        
        % Width of the paddle
        PaddleWidth = 0.02
        
        % Mass of the paddle
        PaddleMass = 0.05
        
        % Damping coefficient for paddle movement
        Damping = 0.01
        
        % Max force applied on the paddle in +/- X direction
        MaxForce = 5
               
        % Sample time
        Ts = 0.025
        
        % Threshold
        ImpactThreshold = 0.025 * 2
        
        % Reward each time step the ball is above the paddle
        RewardForNotFalling = 0
        
        % Reward for striking the ball
        RewardForStrike = 500;
        
        % Penalty when the ball falls below the paddle
        PenaltyForFalling = -100
        
        % Current number of hits
        Hits = 0
        
        % Initialize system state 
        State = [0 0 1 1 0 0 0]'
    end
    
    properties (Access = private, Transient)
        % Visualizer object for the game
        Visualizer = []
    end
    
    properties(Access = protected)
        % Initialize internal flag to indicate episode termination
        IsDone = false        
    end

    %% Necessary Methods
    methods              
        function this = Environment()
            % Initialize Observation settings
            ObservationInfo = rlNumericSpec([7 1]);
            ObservationInfo.Name = 'States';
            ObservationInfo.Description = 'ball_x, ball_y, paddle_dx, ball_dy, paddle_x, paddle_dx Fprev';
            
            % Initialize Action settings   
            ActionInfo = rlNumericSpec([1 1],'LowerLimit',-1,'UpperLimit',1);
            ActionInfo.Name = 'Action';
            ObservationInfo.Description = 'F';
            
            % The following line implements built-in functions of RL env
            this = this@rl.env.MATLABEnvironment(ObservationInfo,ActionInfo);
        end
        
        function [Observation,Reward,IsDone,LoggedSignals] = step(this,Action)
            % Apply system dynamics and simulates the environment with the 
            % given action for one step.
            
            LoggedSignals = [];
            
            % Get action
            Force = getForce(this,Action);            
            
            % Unpack state vector
            ball_x = this.State(1);
            ball_y = this.State(2);
            ball_dx = this.State(3);
            ball_dy = this.State(4);
            paddle_x = this.State(5);
            paddle_dx = this.State(6);
            
            IsDone = false;
            
            R = 0;
            
            ImpactThreshold_x = abs(this.Ts * ball_dx);
            ImpactThreshold_y = abs(this.Ts * ball_dy);
            
            % when ball reaches x bound, reverse the x velocity direction
            if (ball_x >= 0 && (ball_x + this.BallRadius) >= this.XLim(2) - ImpactThreshold_x) || ...
               (ball_x < 0 && (ball_x - this.BallRadius) <= this.XLim(1) + ImpactThreshold_x)     
                ball_dx = -ball_dx;  % reverse x velocity
            end
            % when ball reaches max y bound, reverse y velocity direction
            if (ball_y >= 0 && (ball_y + this.BallRadius) >= this.YLim(2) - ImpactThreshold_y)    
                ball_dy = -ball_dy;  % reverse Y velocity
            end
            % when ball reaches min y bound
            if (ball_y < 0 && (ball_y - this.BallRadius) <= this.YLim(1) + 0.5*this.PaddleWidth + ImpactThreshold_y)
                % check if balls hits paddle
                if (ball_x >= paddle_x - 0.5*this.PaddleLength - ImpactThreshold_x) && (ball_x <= paddle_x + 0.5*this.PaddleLength + ImpactThreshold_x)
                    % reverse Y velocity
                    ball_dy = -ball_dy;
                    % transfer some momentum from the paddle
                    ball_dx = ball_dx + 0.1 * paddle_dx;
                    R = this.RewardForStrike;
                    this.Hits = this.Hits + 1;
                else
                    IsDone = true;
                    this.Hits = 0;
                end
            end
            
            % Ball dynamics
            q1 = ball_x + ball_dx * this.Ts;  % new ball_x
            q2 = ball_y + ball_dy * this.Ts;  % new ball_y
            q3 = ball_dx;  % new ball_dx
            q4 = ball_dy;  % new ball_dy
            
            % Paddle dynamics
            paddle_ddx = -this.Damping/this.PaddleMass * paddle_dx + Force/this.PaddleMass;
            q5 = paddle_x + paddle_dx * this.Ts + 0.5 * paddle_ddx * this.Ts^2;
            q6 = paddle_dx + paddle_ddx * this.Ts;  % new paddle_dx
            if q5 - 0.5*this.PaddleLength <= this.XLim(1)
                q5 = this.XLim(1) + 0.5*this.PaddleLength;
                q6 = 0;
            end
            if q5 + 0.5*this.PaddleLength >= this.XLim(2)
                q5 = this.XLim(2) - 0.5*this.PaddleLength;
                q6 = 0;
            end
            
            q7 = Force;
            
            Observation = [q1 q2 q3 q4 q5 q6 q7]';

            % Update system states
            this.State = Observation;
            
            % Check terminal condition
            this.IsDone = IsDone;
            
            % Get reward
            Reward = getReward(this,R);
            
            % (optional) use notifyEnvUpdated to signal that the 
            % environment has been updated (e.g. to update visualization)
            notifyEnvUpdated(this);
        end
        
        function InitialObservation = reset(this)
            % Reset environment to initial state and output initial observation
                    
            if rand < 0.5
                LoggedSignal.State = [0 0 this.BallVelocity(1) this.BallVelocity(2) 0 0 0]';
            else
                ball_x = -0.1 + 0.2 * rand;
                ball_y = -0.1 + 0.2 * rand;
                ball_dx = this.BallVelocity(1);
                if rand < 0.5
                    ball_dx = -ball_dx;
                end
                ball_dy = this.BallVelocity(2);                
                paddle_x = -0.1 + 0.2 * rand;
                paddle_dx = -1 + 2 * rand;
                LoggedSignal.State = [ball_x ball_y ball_dx ball_dy paddle_x paddle_dx 0]';
            end

            InitialObservation = LoggedSignal.State;
            this.State = InitialObservation;
            
            this.Hits = 0;
            
            % (optional) use notifyEnvUpdated to signal that the 
            % environment has been updated (e.g. to update visualization)
            notifyEnvUpdated(this);
        end
        
        function y = saturate(this,u,lower,upper)
            y = u;
            if u - 0.5*this.PaddleLength <= lower
                y = lower + 0.5*this.PaddleLength;
            elseif u + 0.5*this.PaddleLength >= upper
                y = upper - 0.5*this.PaddleLength;
            end
        end
    end
    %% Optional Methods (set methods' attributes accordingly)
    methods               
        function force = getForce(this,action)
            % Helper methods to create the environment
            % Discrete force 1 or 2
            force = this.MaxForce * action;           
        end
        
        function Reward = getReward(this,R)
            % Reward function
            if ~this.IsDone
                Reward = R + this.RewardForNotFalling;
            else
                ball_x = this.State(1);
                paddle_x = this.State(5);
                Reward = R + this.PenaltyForFalling * abs(ball_x - paddle_x);
            end          
        end
        
        function varargout = plot(this)
            % (optional) Visualization method
            if isempty(this.Visualizer) || ~isvalid(this.Visualizer)
                this.Visualizer = Visualizer(this);
            else
                bringToFront(this.Visualizer);
            end
            if nargout
                varargout{1} = this.Visualizer;
            end
            % Update the visualization
            envUpdatedCallback(this)
        end
        
        %% (optional) Properties validation through set methods
        function set.State(this,state)
            validateattributes(state,{'numeric'},{'finite','real','vector','numel',7},'','State');
            this.State = double(state(:));
            notifyEnvUpdated(this);
        end
        function set.XLim(this,val)
            validateattributes(val,{'numeric'},{'finite','real','vector','numel',2},'','XLim');
            this.XLim = val;
            notifyEnvUpdated(this);
        end
        function set.YLim(this,val)
            validateattributes(val,{'numeric'},{'finite','real','vector','numel',2},'','YLim');
            this.YLim = val;
        end
        function set.BallRadius(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','BallRadius');
            this.BallRadius = val;
        end
        function set.BallVelocity(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','vector','numel',2},'','BallVelocity');
            this.BallVelocity = val;
        end
        function set.PaddleMass(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','PaddleMass');
            this.PaddleMass = val;
        end
        function set.MaxForce(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','MaxForce');
            this.MaxForce = val;
        end
        function set.Ts(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','Ts');
            this.Ts = val;
        end
        function set.ImpactThreshold(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','ImpactThreshold');
            this.ImpactThreshold = val;
        end
        function set.PaddleLength(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','PaddleLength');
            this.PaddleLength = val;
        end
        function set.PaddleWidth(this,val)
            validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','PaddleWidth');
            this.PaddleWidth = val;
        end
        function set.RewardForNotFalling(this,val)
            validateattributes(val,{'numeric'},{'real','finite','scalar'},'','RewardForNotFalling');
            this.RewardForNotFalling = val;
        end
        function set.PenaltyForFalling(this,val)
            validateattributes(val,{'numeric'},{'real','finite','scalar'},'','PenaltyForFalling');
            this.PenaltyForFalling = val;
        end
    end
    
    methods (Access = protected)
        % (optional) update visualization everytime the environment is updated 
        % (notifyEnvUpdated is called)
        function envUpdatedCallback(this)
            
        end
    end
end
