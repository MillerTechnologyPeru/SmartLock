# SmartLock
Swift BLE Smart Lock system

## Overview

This project consists of a Swift Package `CoreLock` which consists of the model layer for the Bluetooth communcation protocol, as well as the `lockd` executable run on the embedded Linux device.

The Xcode project contains the `SmartLock` iOS app (and extensions) and the `LockKit` dynamic framework which embeds all the Swift packages in a single binary (so extensions dont have to statically link anything), as well as reusable code specific to Apple's platforms like UIKit, AppKit, WatchKit, CoreData, AppIntents, etc.

## Screenshots

### macOS

<img width="896" alt="Screenshot 2023-07-03 at 4 35 36 PM" src="https://github.com/MillerTechnologyPeru/SmartLock/assets/3419766/95c7880b-3699-432e-8117-dbaa9d4fd7ab">

<img width="900" alt="Screenshot 2023-07-03 at 4 37 29 PM" src="https://github.com/MillerTechnologyPeru/SmartLock/assets/3419766/66b8b196-3d96-42c2-a00a-454f4f0f2682">

### iOS

![IMG_D7C54B938AE7-1](https://github.com/MillerTechnologyPeru/SmartLock/assets/3419766/17e21b7f-b10f-4c12-a4ef-68a01b5b17d9) 

![IMG_D5959C9C7241-1](https://github.com/MillerTechnologyPeru/SmartLock/assets/3419766/eaf292ab-c39c-4cd5-9c41-5d3c92361e83)
