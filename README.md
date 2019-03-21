# Controlling the level of a system with four reservoirs interconnected using Reinforcment Learning - Actor and Critic

#### The System (plant)

The plant is composed of 4 interconnected tanks, 1 is connected to 2, 2 connected to 3 and so on. tanks 2 and 4 have holes in the botton, so water can flow both direction, wich makes the system somewhat complex to model and control properly

![123](https://user-images.githubusercontent.com/23335136/54704935-77a44d00-4b1a-11e9-9eaf-d6c7c22756d3.png)

#### Reinforcment Learning - Actor and Critic

Actor-critic algorithms learn both policies and function values. The actor is the component that learns policies, and the critic is the component that learns about how the policy used by the actor is behaving to criticize its choices. The critic uses difference-time algorithms to learn the value-state of the function for the current actor's policy, the value of the function allows the critic to critique the actor's choices of actions by sending TD errors to the actor. A positive TD error would mean that the action was good because it took the environment to a better state than expected, while the negative TD error indicates that the action was bad because it led to a worse than expected state, the criticism drives the update each iteration, the structure is as the image bellow

![123](https://user-images.githubusercontent.com/23335136/54726566-74c54e80-4b52-11e9-8a55-a340d6426dbb.png)

Algorithm flow

