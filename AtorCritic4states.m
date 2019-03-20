%% Reinforcment Learning - Actor and Critic for the control of 4 reservoirs system
% Simulink model by Adolfo Bauchspiess
% This code was started by Lucas Guilhem

% Author: Álvaro Queiroz

clc;
close all;
clear;


% Process Parameters
d=6;      % reservoirs depth
A1=d*9.9; % cm2   - transversal section of the reservoirs
A2=d*10;  % cm2
A3=d*10;  % cm2
A4=d*10;  % cm2

% Valve positions, this will help us test the algorithm capacity to adapt
% to changes, refer to TG2 for more info
k1=0; 
k3= 0;
k2=4.313;
k4=4.9667;

k12=9.06;
k23=11.89;
k34=10.09;

% initial conditions (empty reservoirs)
h1=0;
h2=0;
h3=0;
h4=0;

% reservoirs heigth 50 cm - gain of 0.02 - this is because of the gain in the sensor of the real system
hmax=1;  
qmax=60;
qmin=0;

% Sampling time
T = 0.5;  %seconds

% Auxiliarie, this will help calculations in the main loop
for i=1:9
    b(i) = (10-i)/10;
end

% dfening RNA - RBF                                                                              
num_ent_actor   = 5; 
% the actor net will take 5 inputs, the 4 reservoirs height and the
% reference

num_ent_critic  = 6;
% the critic net will take all 5 inputs as the actor and wil have also the
% output of the actor net

%Numer of hidden layers for the actor and critic
cam1            = 4^num_ent_actor;
cam2            = 4^num_ent_critic;

%auxiliaries. They are used in the "Actor" and "Critical" functions to later update the weights.
aux             = zeros(cam1,1);
aux2            = zeros(cam2,1);

% Learning rate for the actor and critic
eta_actor       = 0.1;                                                     
eta_critic      = 0.1;                                                     
eta_mi          = 0.1;                                                     
epsilon         = 0.02;                                                    % = 1 cm, as said, sensor has a gain of 0.02
LearnRateDecay = 1;

% we will save the learning rate for the actor and critic, in case we would
% need to restore it when the raference changes, it is not needed the
% learningratedecay is 1 as learning rate will not change in each iteration
eta_actor0 = eta_actor;
eta_critic0 = eta_critic;

% Variance of the Actor and Critic Activation functions.
sigma_actor     = 0.2;
sigma_critic    = 0.2;
 
%% Initialization / Initial Conditions

% Actor and Critic Weights Respectively
w = rand(1,cam1)* 1-0.5;
v = rand(1,cam2)*1-0.5;


% Center uniformely distributed for the actor and critic
mi_actor = [];                                                            
mi_actor(1,:) = repelem(linspace(0,1,64),16);
mi_actor(2,:) = repelem(linspace(0,1,64),16);
mi_actor(3,:) = repelem(linspace(0,1,64),16);
mi_actor(4,:) = repelem(linspace(0,1,64),16);
mi_actor(5,:) = repelem(linspace(0,1,64),16);


mi_critic = [];
mi_critic(1,:) = repmat(linspace(0,1,64),1,64);
mi_critic(2,:) = repmat(linspace(0,1,64),1,64);
mi_critic(3,:) = repmat(linspace(0,1,64),1,64);
mi_critic(4,:) = repmat(linspace(0,1,64),1,64);
mi_critic(5,:) = repmat(linspace(0,1,64),1,64);
mi_critic(6,:) = repmat(linspace(0,1,64),1,64);

% Randomly distributed weights for actor and critic
 for i=1:num_ent_actor                                                     
    mi_actor(i,:) = rand(1,cam1);
 end   
 
 for i=1:num_ent_critic
    mi_critic(i,:) = rand(1,cam2);
 end

gama = 1;

% The last 100 system outputs to be able to filter and use in the estimator
H4       = zeros(100,1);   
H4F      = 0;                                                              
% The last 100 filtered outputs of the system
H4_EST   = zeros(100,1);                                                  
% Number of seconds that each reference point will remain in original value: 900 / T
D        = 900/T;                                                                                
ref      = repelem([0.2 0.3 0.4 0.3 0.2 0.3 0.4 0.3 0.2 0.3 0.4 0.3 0.2 0.3 0.4 0.3 0.2 0.3 0.4 0.3 0.2 0.3 0.4 0.3],D);                       % references   
%ref = idinput([28800,1,3],'prbs',[0 0.005],[0,0.2]);
%ref = refFunc();
 
%we will initialize all variables vector that will be used in the main loop
%with zeros, variable lengh vector fuck up system performance

entrada = zeros(16*D,1);
saida = zeros(16*D,1);
eta_critic_r = zeros(16*D,1);
eta_actor_r = zeros(16*D,1);


%% STEP 1 - INITIALIZE THE SYSTEM AND DEFINE A0 AND S0
% CALCULATE U1 AND Q1

    ERRO1                      = ref(1) - H4F;
    X_actor                    = [ref(1);H4F;h1(end);h2(end);h3(end)];
    for i = 1:cam1
       aux(i,1)= exp(-0.5*(1/sigma_actor^2)*(norm(X_actor-mi_actor(:,i))^2));   
    end
   a1 = aux;  
   U = w*a1;
    
    if U > 1
        U = 1;
    else
        if U<0
            U=0;
        end
    end
    % actor output U - control signal                                                      

    X_critic                 = [ref(1);H4F;U;h1;h2;h3];
    for i = 1:cam2
       aux2(i,1)= exp(-0.5*(1/sigma_critic^2)*(norm(X_critic-mi_critic(:,i))^2));   
    end
    
    c1 = aux2;
    Q1 = v*c1;                                                             


ref_ref = 0;

%tic
for k=1:16*D
  
    %% STEP 2 - OBSERVE THE NEW STATE AND CALCULATE THE REWARD
      
    % we use circshift so new values enter vector e older ones go out
    H4 = circshift(H4,1);
    
    %simulate system to get new state - "modelo_simulink must be in the current folder    
    sim('modelo_simulink');
    
    % end of vector h4 has the current state, this is returned by the
    % simulation
    H4(1) = h4(end);
    
    
    H4F                      = b*H4(1:9)/sum(b);
    
    ERRO2                    = ERRO1;
    ERRO1                    = ref(k) - H4F;
    erro = ref(k) - H4(1);
           
    
    [ref(k); H4F; U]
        
    r = 3*ERRO1 - 0*ERRO2 ;                                                    

    %% STEP 3 - CALCULATE U2 - ACTOR OF THE NEW STATE
                                                      
    X_actor                  = [ref(k);H4F;h1(end);h2(end);h3(end)];                               
    for i = 1:cam1
       aux(i,1)= exp(-0.5*(1/sigma_actor^2)*(norm(X_actor-mi_actor(:,i))^2));   
    end
    
    a2 = aux;  
    U = w*a2; 
    
    if U > 1
        U = 1;
    else
        if U<0
            U=0;
        end
    end
    
    % actor output U is the signal of control
    
    %% STEP 4 - CALCULATE Q2 - CRITIC OF THE NEW STATE
    
    X_critic                 = [ref(1);H4F;U;h1(end);h2(end);h3(end)];                          
    for i = 1:cam2
       aux2(i,1)= exp(-0.5*(1/sigma_critic^2)*(norm(X_critic-mi_critic(:,i))^2));   
    end
    

    
    c2 = aux2;
    Q2 = v*c2;
    
    %% STEP 5 - CALCULATE THE TEMPORARY DIFFERENCE ERROR 
    
    td_error                 = r + gama*Q2 - Q1;    
    
    %% STEP 6 - UPDATE NEURAL NETWORKS


    if k < 16*D

        if abs((abs(ref(k))- abs(ref_ref)))> epsilon
            ref_ref = ref(k);
            eta_actor = eta_actor0;
            eta_critic = eta_critic0;
        else
            eta_critic = eta_critic*LearnRateDecay;
            eta_actor = eta_actor*LearnRateDecay;
        end

    w = w + eta_actor*td_error*a1';

    v  = v  + eta_critic*td_error*c1';
    end



   
    %% STEP 7 - S <-S 'and A <-A' or be U1 <-U2 E Q1 <-Q2
    
    entrada(k)               = U;
    saida(k)                 = H4(1);
    eta_critic_r(k)          = eta_critic;
    eta_actor_r(k)           = eta_actor;
    
    h1=h1(end);
    h2=h2(end);
    h3=h3(end);
    h4=h4(end);

    Q1                       = Q2;
    a1                       = a2;
    c1                       = c2;
    
    % change in valve position will take place in pre-defined times, this
    % help us evaluate the algoritm
    
    if k==2*D+D/2
        k23=20.62;
    end
    
    if k==4*D+D/2
        k23=11.89;
    end
    
    if k==6*D+D/2
        k23=20.62;
    end
    if k==9*D+D/2
        k23=11.89;
    end
    if k==12*D+D/2
        k23=20.62;
    end
    if k==14*D+D/2
        k23=11.89;
    end
%pause(k*T - toc);
end
