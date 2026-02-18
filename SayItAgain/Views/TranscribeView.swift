//
//  TranscribeView.swift
//  SayItAgain
//
//  Created by Stewart French on 2/6/24.
//
// 2026/02/04 - S.French - An update.
// 
// I watched a video on "agentic coding in Xcode" -
//     https://www.youtube.com/watch?v=oV6mC8Rt1kY
// 
// Following the directions of the video I installed Xcode 26.3 and
// connected my OpenAI account to it through
//   Xode -> Settings -> Intelligence
// I also enabled the OpenAI codex.
// With this view open in the Xcode editor I asked the Xcode "Coding
// Assistant" these sequence of requests.
//
//    First:
//    
//    I have a "PageFlip Firefly" foot pedal.  I want to add direct
//    support for this pedal without affecting the existing
//    functionality.
//    - Make it so that a right pedal push (generates a right-arrow)
//      causes the playback to toggle between play and pause. 
//    - Make it so that a left pedal push (generates a left-arrow)
//      causes the playback to backup nn seconds. 
//    - Make it work with the Transcribe View all the time.
//
//    Second:
//
//    When I tap the foot pedal the app puts a blue line around the
//    whole screen.  I don't want a blue line around the screen.  Also
//    I find that after a few seconds the line goes away but the pedal
//    doesn't work until I tap it again, and the blue line comes
//    back.
//    
// Through a series of prompt/responses I got it compile and run
// successfully.
//    
// This worked good on an iPad, but not on an iPhone.  The "dynamic
// island" seems to be interfering with the foot pedal bluetooth
// connection.  Whenever I didn't touch it for 10 seconds 
// the dynamic island  would go dormant and the iPhone would break the
// connection with the foot pedal.
// I "fixed" this by introducing a watchdogTimer that touched the
// dynamic island periodically and kept it active.
//

import Foundation
import SwiftUI


//-------------------------------------------
struct TranscribeView: View
{

  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject var musicVM : MusicViewModel

  @State var localTrackSelected : Int
  @State var savedElapsedTime : Double? = nil

  @State var musicStateChanged : Bool = false

  @State var elapsedTrackTime : Float = 0

  @State var durationOfTrack : Float = 1.0
  @State var timeInput : String = ""

  @State var timer = Timer.publish(
    every: 0.5,
    on: .main,
    in: .common ).autoconnect()

  @State var watchdogTimer = Timer.publish(
    every: 5.0,
    on: .main,
    in: .common ).autoconnect()

  @State var trackTimeSliderValue : Float = 5.0
  @State var volumeSliderValue : Float = 5.0
  @State var backupSliderValue : Float = 5.0
  @State var speedSliderValue : Float = 1.0
  
  
  //-------------------------------------------

            // UIKit key command catcher to avoid SwiftUI focus ring
            // and keep pedal active

  struct KeyCommandCatcher: UIViewControllerRepresentable 
  {
    var onLeft: () -> Void
    var onRight: () -> Void
    var onUp: () -> Void
    var onDown: () -> Void

    //--------------------------------
    func makeUIViewController(
            context: Context ) -> KeyCatcherViewController 
    {
      let vc = KeyCatcherViewController()
      vc.onLeft = onLeft
      vc.onRight = onRight
      vc.onUp = onUp
      vc.onDown = onDown
      return vc
    } // makeUIViewController

    //--------------------------------
    func updateUIViewController(
            _ uiViewController: KeyCatcherViewController, 
                       context: Context ) 
    {
      uiViewController.onLeft = onLeft
      uiViewController.onRight = onRight
      uiViewController.onUp = onUp
      uiViewController.onDown = onDown
    } // updateUIViewController


    //--------------------------------
    final class KeyCatcherViewController: UIViewController 
    {
      var onLeft: (() -> Void)?
      var onRight: (() -> Void)?
      var onUp: (() -> Void)?
      var onDown: (() -> Void)?

      override var canBecomeFirstResponder: Bool { true }

      //-----------------------
      override func viewWillAppear( _ animated: Bool )
      {
        super.viewWillAppear(animated)
        self.becomeFirstResponder()
      } // viewWillAppear

      //-----------------------
      override func viewDidAppear( _ animated: Bool ) 
      {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
      } // viewDidAppear

      //-----------------------
      override func viewDidLayoutSubviews() 
      {
        super.viewDidLayoutSubviews()
        // Reassert first responder after layout changes
        if !self.isFirstResponder { self.becomeFirstResponder() }
      } // viewDidLayoutSubviews

      //-----------------------
      override func viewWillDisappear( _ animated: Bool ) 
      {
        super.viewWillDisappear(animated)
        self.resignFirstResponder()
      } // viewWillDisappear

      //-----------------------
      override var keyCommands: [UIKeyCommand]? 
      {
        let left = 
          UIKeyCommand(
                      input: UIKeyCommand.inputLeftArrow,
              modifierFlags: [], 
                     action: #selector(handleLeft))

        let right = 
          UIKeyCommand(
                      input: UIKeyCommand.inputRightArrow, 
              modifierFlags: [], 
                     action: #selector(handleRight))

        let up = 
          UIKeyCommand(
                      input: UIKeyCommand.inputUpArrow,
              modifierFlags: [], 
                     action: #selector(handleUp))

        let down = 
          UIKeyCommand(
                      input: UIKeyCommand.inputDownArrow, 
              modifierFlags: [], 
                     action: #selector(handleDown))

        left.discoverabilityTitle = "Backup"
        right.discoverabilityTitle = "Play/Pause"
        up.discoverabilityTitle = "Backup"
        down.discoverabilityTitle = "Play/Pause"

        if #available(iOS 15.0, *) 
        {
          left.wantsPriorityOverSystemBehavior = true
          right.wantsPriorityOverSystemBehavior = true
          up.wantsPriorityOverSystemBehavior = true
          down.wantsPriorityOverSystemBehavior = true
        } // if
        return [left, right, up, down]
      } // override var keyCommands

      @objc private func handleLeft() 
      {
        onLeft?()
      } // handleLeft

      @objc private func handleRight() 
      {
        onRight?()
      } // handleRight

      @objc private func handleUp() 
      {
        onUp?()
      } // handleUp

      @objc private func handleDown() 
      {
        onDown?()
      } // handleDown
    } // KeyCatcherViewController
  } // KeyCommandCatcher
  

  //-------------------------------------------
  func stopTimer()
  {
    timer.upstream.connect().cancel()
  } // stopTimer
  
  
  func startTimer()
  {
    timer = Timer.publish(
      every: 0.5,
      on: .main,
      in: .common ).autoconnect()
  } // startTimer
  
  
  //-------------------------------------------
  func stopWatchdogTimer()
  {
    watchdogTimer.upstream.connect().cancel()
  } // stopTimer
  
  
  func startWatchdogTimer()
  {
    watchdogTimer = Timer.publish(
      every: 0.5,
      on: .main,
      in: .common ).autoconnect()
  } // startTimer
  
  
  //-------------------------------------------
  func timeString( time: Double ) -> String
  {
    let tMinutes = Int(time) / 60
    let tSeconds = Int(time) % 60
    let s = String( format: "%02d:%02d", tMinutes, tSeconds )
    return s
  } // timeString

  

  //-------------------------------------------
  var body: some View 
  {
    ZStack {
      VStack
      {
        Divider()

          // -------------
          // Artist Name
          
        HStack
        {
          Text( "Artist:" )
            .lineLimit( 2...2 )
              .offset( y: -20 )

          Text(
            musicVM.trackArtist(
              trackIndex: musicVM.selectedTrackIndex! ) )
            .font(.title)
            .bold()
            .lineLimit( 2...2 )

            Spacer()
         } // HStack
        
         Divider()

          // -------------
          // Album Name
          
          HStack
          {
            Text( "Album:" )
              .lineLimit( 2...2 )
              .offset( y: -20 )

            Text( musicVM.trackAlbum(
              trackIndex: localTrackSelected ) )
            .foregroundColor( Color.white )
            .font(.title)
            .bold()
            .lineLimit( 2...2 )

            Spacer()
          } // HStack
          
          Divider()

          // -------------
          // Song Title
          
          HStack
          {
            Text( "Track:" )
              .lineLimit( 3...3 )
              .offset( y: -20 )

            Text( musicVM.trackName(
                trackIndex: musicVM.selectedTrackIndex! ) )
            .foregroundColor( Color.white )
            .font(.title)
            .bold()
            .lineLimit( 3...3 )

            Spacer()
          } // HStack

          Spacer()

          Divider()

          // -------------
          // Time Slider
        
          VStack
          {
            HStack
            {
              Spacer()
              Text( timeString( time: musicVM.durationOfSelectedTrack() ) )
                .offset( y: +10 )
            }

            Slider(
              value: $elapsedTrackTime,
                 in: 0...durationOfTrack,
               step: 0.1,
              onEditingChanged: 
                  { editing in 

                    if editing
                    {
                      if musicVM.isPlaying()
                      {
                        stopTimer()
                      } // if

                      musicVM.skipToTimeInTrack( pTime: Double(elapsedTrackTime) )
                      musicVM.saveTrackElapsedTime(
                        saveTime: Double(elapsedTrackTime) - 5.0 )
                    }
                    else
                    {
                      musicVM.skipToTimeInTrack( pTime: Double(elapsedTrackTime) )
                      musicVM.saveTrackElapsedTime(
                        saveTime: Double(elapsedTrackTime) - 5.0 )

                      if musicVM.isPlaying()
                      {
                        startTimer()
                      } // if

                    } // if
              } ) // Slider

              HStack
              {
                Text( timeString( time: Double(elapsedTrackTime) ) )
                  .offset( y: -10 )
                Spacer()
                Text( "-" + 
                   timeString( 
                     time: musicVM.durationOfSelectedTrack() -
                             Double( elapsedTrackTime ) ) )
                  .offset( y: -10 )
              }
            
          } // VStack

          Spacer()
        
          // -------------
          // Speed Slider
        
          VStack
          {
            Slider(
              value: $speedSliderValue,
                 in: 0.0...2.0,
               step: 0.2,
              onEditingChanged: 
                {_ in 

                 // There is a Slider bug in iOS 26 such that the step
                 // does not work correctly.  The fix is the manually
                 // round it.  Note that my round takes it to 0.1 (and
                 // not the correct step value of 0.2).  Turns out this
                 // is fine when I use it in the app.

                 speedSliderValue = round( speedSliderValue * 10 ) / 10.0
                 if !musicVM.isPlaying()
                 {
                   musicVM.setPlaybackRate(
                     playbackRate: speedSliderValue )
                    musicVM.pauseSelectedTrack()
                 } // if
                 else
                  {

                    // All these shenanigans with pause/play/skip etc
                    // seem to be required in order for the rate to
                    // change correctly.  This is a bug that appeared in
                    // iOS 26.
                  
                    musicVM.setPlaybackRate(
                      playbackRate: speedSliderValue )
                    stopTimer()
                    musicVM.pauseSelectedTrack()
                    musicStateChanged = !musicStateChanged

//                  musicVM.playSelectedTrack()
//                  musicVM.skipToTimeInTrack( pTime: Double(elapsedTrackTime) )
//                  startTimer()
                 } // else

              } ) // Slider

            HStack
            {
              Text( 
                "\( round(speedSliderValue * 10) / 10.0)" + "x" )
                .offset( y: -10 )
              Spacer()
              Text( "Playback Speed" )
              Spacer()
              Text( "2x" )
                .offset( y: -10 )
            } // HStack
          } // VStack
      
          Spacer()

          // -------------
          // Backup Time Slider

          VStack
          {
            Slider(
              value: $backupSliderValue,
                 in: 0...10,
               step: 1.0 )

            HStack
            {
              Text( String( "\(backupSliderValue)" ) )
                .offset( y: -10 )
              Spacer()
              Text( "Backup Time in Seconds" )
              Spacer()
              Text( "10" )
                .offset( y: -10 )
            } // HStack
          } // VStack

        Spacer()
        

        //-------------------------------------------
        // Backup nn Seconds Button
        
        HStack
        {
          Button(
            action:
              {
                musicVM.skipBackInTrack( 
                  skipTime: Double( backupSliderValue ) )
                musicVM.saveTrackElapsedTime(
                  saveTime: musicVM.elapsedTimeOfSelectedTrack() - 5.0 )
                elapsedTrackTime = Float(musicVM.elapsedTimeOfSelectedTrack())
              }, 
              label: 
              {
                ZStack
                {
                  Image( "minus_nn_v1" ) 
                  Text( String(Int(backupSliderValue)) )
                  .font(.system(size:12))
               } // ZStack
              } ) // Button

            Spacer()
        
        
          //-------------------------------------------
          // Play/Pause Button
        
          Button(
            action:
              {
                localTrackSelected = musicVM.getSelectedTrackIndex() ?? 0
              
                if musicVM.isPlaying()
                {
                  stopTimer()
                  musicVM.pauseSelectedTrack()
                } // if
                else 
                {
                  // This appears to be a bug in Apple's music
                  // interface.  One can only set the time while the
                  // player is playing.
                
                  musicVM.playSelectedTrack()
                  musicVM.skipToTimeInTrack( pTime: Double(elapsedTrackTime) )

                  startTimer()
                } // else

                musicStateChanged = !musicStateChanged
              }, 
            label: 
              {
                ZStack
                {
                  Text( musicStateChanged ? "" : "" )
                  Image( musicVM.isPlaying() ? "slf_pause" : "slf_play" )
                } // ZStack
              } ) // Button

          Spacer()
        
        
          //-------------------------------------------
          // Forward nn Seconds Button
        
          Button(
            action:
              {
                musicVM.skipForwardInTrack( 
                  skipTime: Double( backupSliderValue ) )
                musicVM.saveTrackElapsedTime(
                  saveTime: musicVM.elapsedTimeOfSelectedTrack() - 5.0 )
                elapsedTrackTime = Float(musicVM.elapsedTimeOfSelectedTrack())
              }, 
              label: 
              {
                ZStack
                {
                  Image( "plus_nn_v1" )
                  Text( String(Int(backupSliderValue)) )
                  .font(.system(size:12))
               } // ZStack
              
              } ) // Button
        } // HStack
        .font(.system(size:64))

      } // VStack
      .padding( 3.0 )




    //-------------------------------------------
    // When the View appears
    
    .onAppear
    {
      stopTimer()

      if savedElapsedTime != nil
      {
        elapsedTrackTime = Float( savedElapsedTime! )
        musicVM.skipToTimeInTrack( pTime: savedElapsedTime! )
      }
      else
      {
        musicVM.skipToTimeInTrack( pTime: 0.0 )
        elapsedTrackTime = 0.0
      }

      musicStateChanged = !musicStateChanged
      durationOfTrack = Float( musicVM.durationOfSelectedTrack() )
    } // onAppear


    //-------------------------------------------
    // When the View disappears
    
    .onDisappear()
    {
      if musicVM.isPlaying()
      {
        stopTimer()
        musicVM.pauseSelectedTrack()
      }
    } // onDisappear

    
    //-------------------------------------------
    // Each time the Watchdog Timer goes off
    
    .onReceive( watchdogTimer,
     perform:
     { _ in

            // The intent here is to "touch" the music player every so
            // often to keep the "Dynamic Island" alive.  This appears
            // to be a bug in iOS 26 when capturing key events from a
            // foot pedal. Only needed on iPhone, not iPad.

       #if os(iOS)
       if UIDevice.current.userInterfaceIdiom == .phone
       {
         if !musicVM.isPlaying()
         {
           musicVM.playSelectedTrack()
           musicVM.pauseSelectedTrack()
         } // if
       } // if
       #endif
     } ) // onReceive

    //-------------------------------------------
    // Each time the Timer goes off
    
    .onReceive( timer,
     perform:
     { _ in

       durationOfTrack = Float( musicVM.durationOfSelectedTrack() )
       elapsedTrackTime =
         Float( musicVM.elapsedTimeOfSelectedTrack() )

       musicVM.saveTrackElapsedTime(
         saveTime: musicVM.elapsedTimeOfSelectedTrack() - 5.0 )

       musicStateChanged = !musicStateChanged

     } )  // onReceive

      // Invisible key-command catcher to receive pedal arrow key
      // events without focus ring
      
      KeyCommandCatcher(

        onLeft: 
        {
          musicVM.skipBackInTrack( 
            skipTime: Double(backupSliderValue) )
          musicVM.saveTrackElapsedTime(
            saveTime: musicVM.elapsedTimeOfSelectedTrack() - 5.0 )
          elapsedTrackTime = 
            Float( musicVM.elapsedTimeOfSelectedTrack() )
        },  // onLeft

        onRight: 
        {
          if musicVM.isPlaying() 
          {
            stopTimer()
            musicVM.pauseSelectedTrack()
          } 
          else 
          {
            musicVM.playSelectedTrack()
            musicVM.skipToTimeInTrack(pTime: Double(elapsedTrackTime))
            startTimer()
          } // if
          musicStateChanged.toggle()
        }, // onRight

        onUp: 
        {
          musicVM.skipBackInTrack( 
            skipTime: Double(backupSliderValue) )
          musicVM.saveTrackElapsedTime(
            saveTime: musicVM.elapsedTimeOfSelectedTrack() - 5.0 )
          elapsedTrackTime = 
            Float( musicVM.elapsedTimeOfSelectedTrack() )
        },  // onUp

        onDown: 
        {
          if musicVM.isPlaying() 
          {
            stopTimer()
            musicVM.pauseSelectedTrack()
          } 
          else 
          {
            musicVM.playSelectedTrack()
            musicVM.skipToTimeInTrack(pTime: Double(elapsedTrackTime))
            startTimer()
          } // if
          musicStateChanged.toggle()
        } // onDown
      ) // KeyCommandCatcher
      .frame(width: 1, height: 1)
      .opacity(0.01)
      .allowsHitTesting(false)
      .onAppear 
      {
        // Nudge the representable so it (re)becomes first responder
        // after appear
        DispatchQueue.main.async 
        {
          // no-op to ensure the UIViewController has appeared
        } // DispatchQueue
      } // onAppear

    } // ZStack

  } // var body

} // TranscribeView



