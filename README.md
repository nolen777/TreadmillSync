# TreadmillSync
Sync workout data from a LifeSpan Treadmill to Apple Health

The Mac application listens over Bluetooth for the LifeSpan treadmill, then sends a series of commands to retrieve
step count, duration, distance, and calorie count. It then broadcasts a service to wake up an iPhone app, which 
receives that data and writes it to Apple Health.
