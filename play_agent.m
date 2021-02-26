%% PLAY a PING PONG GAME USING REINFORCEMENT LEARNING
% This script loads a pre-trained DDDPG agent to play a game.

% Copyright 2021 The MathWorks, Inc.

%% Load the agent
load('savedAgents/agent_01-13-2021.mat','agent');

%% Play the game
env = Environment;
maxsteps = 1e8;
plot(env);
simOptions = rlSimulationOptions('MaxSteps',maxsteps);
experience = sim(env,agent,simOptions);