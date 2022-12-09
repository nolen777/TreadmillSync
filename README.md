# TreadmillSync
Sync workout data from a LifeSpan Treadmill to Apple Health

The Mac application listens over Bluetooth for the LifeSpan treadmill, then sends a series of commands to retrieve
step count, duration, distance, and calorie count. It then broadcasts a service to wake up an iPhone app, which 
receives that data and writes it to Apple Health.

## Basic Flow
1) the desktop application scans for all available Bluetooth devices, inside BluetoothController.swift. The treadmill 
    console does not advertise any services, so it cannot be more selective (or run in the background on iOS.)
2) If it finds one with the name "LifeSpan", it initiates a connection and listens for updates on a particular
   characteristic.
3) It issues a series of commands to the treadmill, specified in LifeSpanCommands.swift.
4) For each command, the treadmill to update a characteristic with a value representing step count, distance, speed,
   etc. The application parses these responses and adds them to a dictionary, along with the current timestamp.
4) If at any point it learns that the treadmill is actually running, it aborts the whole process. See "Known Issues."
5) When it has gone through the whole set of query commands successfully, it sends a "reset" command to the treadmill
   to reset the existing counters to avoid duplication.
6) It sends the complete value dictionary to PhoneSyncPeripheral, which starts advertising a service.
7) The phone application is listening (including in the background) for that particular service, and wakes up and
   subscribes for updates in BluetoothWorkoutReceiver.swift.
8) When the desktop app receives the subscription, it pushes one dictionary at a time to the phone. If successful,
   it removes the dictionary from its store. When it is out of data to send, it sends an "EOM" and stops advertising.
9) When the phone successfully receives a dictionary, it writes the data to Apple Health (WorkoutConstructor.swift) 
   and posts a local notification (NotificationHandler.swift). When it receives EOM, it disconnects.

## Known Issues
* The treadmill seems to use two bytes for the step count, and rolls over at 65,536 steps.
* The reset command does not seem to work when the treadmill is actually running, so the desktop app just aborts if it
  detects that. Alternatively, we could maintain the last set of counters and subtract, but that gets tricky given the
  65,536 step limit.
* There are a few commands that returns values that I don't know what they represent. I'll probably remove those in the
  future.
* There's no pairing/authorization of connecting either Phone <-> Desktop or Desktop <-> treadmill right now, anything
  in Bluetooth range will just connect. We could generate a UUID on the phone and have some kind of "connect" UX.

## Notes
* LifeSpanCommands.swift also contains some commands for controlling the treadmill: start, stop, adjust speed. Those
  aren't used anywhere.

## Thanks
https://github.com/brandonarbini/treadmill was very helpful for finding the query commands and parsing the return
values.
