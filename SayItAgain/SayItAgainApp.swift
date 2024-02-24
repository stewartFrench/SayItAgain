//
//  SayItAgainApp.swift
//  SayItAgain
//
//  Created by Stewart French on 2/5/24.
//

import SwiftUI

@main
struct SayItAgainApp: App
{

  var musicVM : MusicViewModel = MusicViewModel()

  var body: some Scene
  {
    WindowGroup
    {
      LaunchScreenView()
        .preferredColorScheme( .dark )
        .environmentObject(musicVM)

    } // WindowGroup
  }  // var body

} // SayItAgainApp
