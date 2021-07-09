# mP-iOS
A simple Swift app used to test the mParticle iOS SDK. ATT has been implemented, as well as APN. 

## Implementing mParticle 
In AppDelegate.swift, be sure to include valid iOS Platform Key and Secret from mP account Setup

## Testing Push Notifications
In terminal, navigate to the main directory, then run the following command (below) which will send the request body in testPush.apn (from the main directory) to the booted simulator.
> xcrun simctl push booted testPush.apn  

## Common Issues
- Make sure to install pods before Building / Running the app. 
