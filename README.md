# Controlling the level of a system with four reservoirs interconnected using Reinforcment Learning - Actor and Critic

#### The System (plant)

The plant is composed of 4 interconnected reservoirs, 1 is connected to 2, 2 connected to 3 and so on. Reservoirs 2 and 4 have holes in the botton, so water can flow both direction, wich makes the system somewhat complex to model and control properly. The good thing about this system, is that we can change valve positions at anytime, so we will change de valves postion during the tests to see how the algorithm handle time-varying systems

![123](https://user-images.githubusercontent.com/23335136/54704935-77a44d00-4b1a-11e9-9eaf-d6c7c22756d3.png)

#### Reinforcment Learning - Actor and Critic

Actor-critic algorithms learn both policies and function values. The actor is the component that learns policies, and the critic is the component that learns about how the policy used by the actor is behaving to criticize its choices. The critic uses difference-time algorithms to learn the value-state of the function for the current actor's policy, the value of the function allows the critic to critique the actor's choices of actions by sending TD errors to the actor. A positive TD error would mean that the action was good because it took the environment to a better state than expected, while the negative TD error indicates that the action was bad because it led to a worse than expected state, the criticism drives the update each iteration. The nets for the actor and critic are Radial Basis Networks (RBN).
The structure is as the image bellow:

![123](https://user-images.githubusercontent.com/23335136/54726566-74c54e80-4b52-11e9-8a55-a340d6426dbb.png)

Algorithm flow

For each iteration
1. Initialize the state s_k and all constant parameters to be used by the controller.
2. Initialize the action a_k using the RBN defined for the actor.
3. Initialize Q_k using the RBN defined for the value function.
4. Take action a_k on the model to predict the next state s_ (k + 1).
5. Observe the reward r_ (k + 1) (proportional to the error).
6. Calculate the action a_ (k + 1) using the RBN defined for the actor.
7. Calculate Q_ (k + 1) using the RBN defined for the value function.
8. Calculate the time difference δ_td.
9. Train the networks of the actor and the critic.
10. Perform new measurement of system output, calculate new action a_k to be taken.
end

#### Actor Critic architecture in time-varying systems control

We can make the system change over time changing the valve position, this is somewhat a nightmare for engineers to control, but as we can see bellow, for an unity rate of decay of the learning rate, or gamma = 1, the algorithm can ajust and control the system without ss error.
Black arrows indicate when valve postion changes

![123](https://user-images.githubusercontent.com/23335136/54727198-409f5d00-4b55-11e9-9948-385c2fd02b96.png)

In depth explanation is in TG2.pdf (In portuguese)
