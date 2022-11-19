//
//  RequestHandler.swift
//  MatterLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import HomeKit

class RequestHandler: HMMatterRequestHandler {

    override func rooms(in home: HMMatterHome) async throws -> [HMMatterRoom] {
        // Use this function to return the rooms your ecosystem manages.
        // If your ecosystem manages multiple homes, ensure you are returning rooms that belong to the provided home.
        return []
    }
    
    override func pairAccessory(in home: HMMatterHome, onboardingPayload: String) async throws -> Void {
        // Use this function to pair the accessory with your own CHIP/Matter stack
    }
  
    override func configureAccessory(named accessoryName: String, room accessoryRoom: HMMatterRoom) async throws -> Void {
        // Use this function to configure the (now) paired accessory with the given name and room.
    }
}
