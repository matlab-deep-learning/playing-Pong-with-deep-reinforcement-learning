%% TRAIN REINFORCEMENT LEARNING AGENT TO PLAY A GAME
% This script creates and trains a DDDPG agent.

% Copyright 2021 The MathWorks, Inc.

%% Create Environment and I/O specifications
env     = Environment;
obsInfo = env.getObservationInfo;
actInfo = env.getActionInfo;
numObs  = obsInfo.Dimension(1);
numAct  = numel(actInfo);

%% CRITIC
statePath = [
    featureInputLayer(numObs, 'Normalization', 'none', 'Name', 'observation')
    fullyConnectedLayer(128, 'Name', 'CriticStateFC1')
    reluLayer('Name', 'CriticRelu1')
    fullyConnectedLayer(200, 'Name', 'CriticStateFC2')];
actionPath = [
    featureInputLayer(numAct, 'Normalization', 'none', 'Name', 'action')
    fullyConnectedLayer(200, 'Name', 'CriticActionFC1', 'BiasLearnRateFactor', 0)];
commonPath = [
    additionLayer(2,'Name', 'add')
    reluLayer('Name','CriticCommonRelu')
    fullyConnectedLayer(1, 'Name', 'CriticOutput')];

criticNetwork = layerGraph(statePath);
criticNetwork = addLayers(criticNetwork, actionPath);
criticNetwork = addLayers(criticNetwork, commonPath);
criticNetwork = connectLayers(criticNetwork,'CriticStateFC2','add/in1');
criticNetwork = connectLayers(criticNetwork,'CriticActionFC1','add/in2');

criticOptions = rlRepresentationOptions('LearnRate',1e-03,'GradientThreshold',1);

critic = rlQValueRepresentation(criticNetwork,obsInfo,actInfo,'Observation',{'observation'},'Action',{'action'},criticOptions);

%% ACTOR
actorNetwork = [
    featureInputLayer(numObs, 'Normalization', 'none', 'Name', 'observation')
    fullyConnectedLayer(128, 'Name', 'ActorFC1')
    reluLayer('Name', 'ActorRelu1')
    fullyConnectedLayer(200, 'Name', 'ActorFC2')
    reluLayer('Name', 'ActorRelu2')
    fullyConnectedLayer(1, 'Name', 'ActorFC3')
    tanhLayer('Name', 'ActorTanh1')
    scalingLayer('Name','ActorScaling','Scale',max(actInfo.UpperLimit))];

actorOptions = rlRepresentationOptions('LearnRate',5e-04,'GradientThreshold',1);

actor = rlDeterministicActorRepresentation(actorNetwork,obsInfo,actInfo,'Observation',{'observation'},'Action',{'ActorScaling'},actorOptions);

%% Agent options
agentOptions = rlDDPGAgentOptions(...
    'SampleTime',env.Ts,...
    'TargetSmoothFactor',1e-3,...
    'ExperienceBufferLength',1e6,...
    'MiniBatchSize',128);
agentOptions.NoiseOptions.Variance = 0.4;
agentOptions.NoiseOptions.VarianceDecayRate = 1e-5;

agent = rlDDPGAgent(actor,critic,agentOptions);

%% Training options
maxepisodes = 20000;
maxsteps = 1e8;
trainingOptions = rlTrainingOptions(...
    'MaxEpisodes',maxepisodes,...
    'MaxStepsPerEpisode',maxsteps,...
    'StopOnError','on',...
    'Verbose',false,...
    'Plots','training-progress',...
    'StopTrainingCriteria','AverageReward',...
    'StopTrainingValue',Inf,...
    'ScoreAveragingWindowLength',10); 

%% Plot environment
plot(env);

%% Train agent
trainingStats = train(agent,env,trainingOptions);

%% Play the game with the trained agent
simOptions = rlSimulationOptions('MaxSteps',maxsteps);
experience = sim(env,agent,simOptions);