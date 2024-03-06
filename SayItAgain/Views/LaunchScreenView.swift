//
//  LaunchScreenView.swift
//  BigPlayer1
//
//  Created by Stewart French on 1/25/23.
//  Adapted for SayItAgain on 2/6/2024.
//

import SwiftUI

// --------------------------------------------
struct LaunchScreenView: View
{
  
  @EnvironmentObject var musicVM : MusicViewModel

  @Environment(\.scenePhase) var scenePhase
  
  @State var notAuthorized : Bool = false


  // ----------------------
  var body: some View
  {
    NavigationStack
    {
      ZStack 
      {
        // background
        
        Color.gray
          .edgesIgnoringSafeArea(.all)
        
        // content
        
        VStack
        {
          Spacer()
          
          // --------------
          HStack
          {


            Link(
              destination: URL(string: "https://SayItAgain.org")! )
            {
              Image( "goto_website" )
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 30, height: 30)
            }
            Text( "Say It Again" )
              .font( .largeTitle )
          } // HStack
          Text( "An Audio Transcription Aid" )
              .font( .caption )

          // --------------
          HStack
          {
            
            // -----
            NavigationLink(destination: NewestAlbumsView())
            {
              MyRectangleView(buttonLabel: "Newest \nAlbums")
            }

            .simultaneousGesture(
              TapGesture().onEnded
              {
                musicVM.clearSelections()
              } ) // simultaneousGesture

            
            // -----
            NavigationLink(destination: PlaylistsView())
            {
              MyRectangleView(buttonLabel: "Playlists")
            }
            .simultaneousGesture(
              TapGesture().onEnded
              {
                musicVM.clearSelections()
              } ) // simultaneousGesture

          } // HStack
          .padding(.horizontal, 5)

            
          // --------------
          HStack 
          {
            
            // -----
            NavigationLink(destination: ArtistsView())
            {
              MyRectangleView(buttonLabel: "Artists")
            }
            .simultaneousGesture(
              TapGesture().onEnded
              {
                musicVM.clearSelections()
              } ) // simultaneousGesture


            // -----
            NavigationLink(destination: AlbumsView()) 
            {
              MyRectangleView(buttonLabel: "Albums")
            }
            .simultaneousGesture(
              TapGesture().onEnded
              {
                musicVM.clearSelections()
              } ) // simultaneousGesture

          } // HStack
          .padding(.horizontal, 5)
          
          
          // --------------
            NavigationLink(
             destination: 
               TranscribeView( 
                 localTrackSelected: musicVM.getSelectedTrackIndex() ?? 0,
                    savedElapsedTime: musicVM.savedElapsedTime() ) )
           {
              MyRectangleView(
                  buttonLabel: "Resume",
                  disabled: !musicVM.ASusable )
            }
            .disabled( !musicVM.ASusable )

            .simultaneousGesture(
              TapGesture().onEnded
              {
                musicVM.restoreTracksFromAppStorage()
                musicVM.prepareTracksToPlay( fromAppStorage: true )
              } ) // simultaneousGesture
              .disabled( !musicVM.ASusable )
            .padding(.horizontal, 5)

        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        .navigationBarHidden(true)

        } // VStack
      } // ZStack
    } // NavigationStack


    // --------------
    // ScenePhase indicates the operational state of the app.  I can
    // use it to update the music library access authorization when
    // this app is not active, i.e. when this app has pushed to the
    // Settings app so the user can permit access to the music
    // library, and has returned.
    // I have left in, but commented out, the print statements.

    .task( id: scenePhase )
    { 
      notAuthorized = !musicVM.isAuthorizedToAccessMusic()

//      switch scenePhase 
//      {
//        case .background:
//            print("appMoveToBackground - notAuthorized == \(notAuthorized)")
//            break
//        case .inactive:
//            print("appMoveToInactive - notAuthorized == \(notAuthorized)")
//        case .active:
//            print("appMoveToActive - notAuthorized == \(notAuthorized)")
//        @unknown default:
//            print("scenePhase: @unknown default for ")
//            break
//        } // switch

    } // .task



    // --------------
    .alert( isPresented: $notAuthorized )
    {
      Alert( 
                title: Text( "SayItAgain needs access to the Music Library." ),
              message: Text( "Go to Settings > SayItAgain\nto Allow Access to Apple Music" ),
        dismissButton: 
          Alert.Button.default( Text( "Settings" ),
            action: 
            {
              UIApplication.shared.open(
                URL( string: UIApplication.openSettingsURLString)!, 
                            options: [:], 
                  completionHandler: nil )
            } ) ) // Alert
    } // .alert

  } // var body

} // LaunchScreenView



// --------------------------------------------
struct MyRectangleView: View 
{
  let buttonLabel: String
  
  var disabled : Bool = false
  
  var body: some View 
  {
    Rectangle()
      .fill(Color.black)
      .overlay(
        Text(buttonLabel)
          .font(.largeTitle)
          .foregroundColor( disabled ? .gray : .white )
        
      )
  }
} // MyRectangleView

// --------------------------------------------

