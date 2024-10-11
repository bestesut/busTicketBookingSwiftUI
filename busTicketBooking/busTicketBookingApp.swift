//
//  busTicketBookingApp.swift
//  busTicketBooking 
//
//  Created by Beste on 27.09.2024.
//

import SwiftUI
import Firebase

@main
struct busTicketBookingApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
