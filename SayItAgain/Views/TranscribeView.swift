//
//  TranscribeView.swift
//  SayItAgain
//
//  Created by Stewart French on 2/6/24.
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

  @State var trackTimeSliderValue : Float = 5.0
  @State var volumeSliderValue : Float = 5.0
  @State var backupSliderValue : Float = 5.0
  @State var speedSliderValue : Float = 1.0
  

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

               if !musicVM.isPlaying()
               {
                 musicVM.setPlaybackRate(
                   playbackRate: speedSliderValue )
                  musicVM.pauseSelectedTrack()
               }
               else
               {
                 musicVM.setPlaybackRate(
                   playbackRate: speedSliderValue )
               }

            } ) // Slider

          HStack
          {
            Text( "\(speedSliderValue)" + "x" )
              .offset( y: -10 )
            Spacer()
            Text( "Playback Speed" )
            Spacer()
            Text( "2x" )
              .offset( y: -10 )
          }
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
          }
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
              } 
              else 
              {
                // This appears to be a bug in Apple's music
                // interface.  One can only set the time while the
                // player is playing.
                
                musicVM.playSelectedTrack()
                musicVM.skipToTimeInTrack( pTime: Double(elapsedTrackTime) )

                startTimer()
              } // if

              musicStateChanged = !musicStateChanged
            }, 
          label: 
            {
              ZStack
              {
                Text( musicStateChanged ? "" : "" )
                Image( musicVM.isPlaying() ? "slf_pause" : "slf_play" )
              }
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
      }
      .font(.system(size:64))

      } // VStack
      .padding( 3.0 )

      .gesture(

            // I got this code from StackOverflow.
            // I've commented out the print statements, but left them
            // in for completeness.
            
            // This code is here to support swipe gestures generated
            // by a foot pedal while in Accessibility Mode, using
            // Switch Control.

         DragGesture(
            minimumDistance: 80, 
            coordinateSpace: .local )
          .onEnded(
          { value in

            let yChange = abs(value.startLocation.y - value.location.y)
            let xChange = abs(value.startLocation.x - value.location.x)
     
            if (yChange > xChange) 
            {
              if (value.startLocation.y > value.location.y) 
              {
//                print("up")
              } 
              else 
              {
//                print("down")
              }
            }
            else 
            {
              if (value.startLocation.x > value.location.x) 
              {
//                print("left")
                if musicVM.isPlaying()
                {
                  stopTimer()
                  musicVM.pauseSelectedTrack()
                } 
                else 
                {
                  musicVM.playSelectedTrack()
                  musicVM.skipToTimeInTrack( pTime: Double(elapsedTrackTime) )
                  startTimer()
                }
                musicStateChanged = !musicStateChanged
              } 
              else 
              {
//                print("right")
                musicVM.skipBackInTrack( 
                  skipTime: Double( backupSliderValue ) )
                musicVM.saveTrackElapsedTime(
                   saveTime: musicVM.elapsedTimeOfSelectedTrack() - 5.0 )
                elapsedTrackTime = Float(musicVM.elapsedTimeOfSelectedTrack())

              } // if
            } // if

          } ) // onEnded
      ) // gesture




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

  } // var body

} // TranscribeView
