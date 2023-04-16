//
//  Group_04_MAPD724_Assignment_01_App.swift
//  Group#04_MAPD724_Assignment#01_
//
//
//
//  Student Name & ID:
//      Ajay Shrivastav - 301284668
//      Apeksha Parmar - 301205325
//      Brijen Jayeshbhai Shah - 301271637
//
//  App Description  - MyChatApp
//      -This is a live chat app using various frameworks.
//
//  Created by Apeksha Parmar on 2023-03-20.
//

import SwiftUI
import FirebaseCore
import Firebase


@main
struct Group_04_MAPD724_Assignment_01_App: App {
    
    //let auth = Auth.auth()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView(didCompleteLoginProcess: {})
        }
    }
}
