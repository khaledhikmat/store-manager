Since we are using Redis for state and pubsub, we don't need to start anything else since Redis is already part of `init dapr`. 

In case there are additional infrastructure that need to be started, perhaps a folder for each is nice (as in dapr-traffic-control solution).