//
//  TracksView.swift
//  BigPlayer1
//
//  Created by Stewart French on 3/8/23.
//  Adapted for SayItAgain on 2/6/2024.
//

import SwiftUI

struct TracksView: View
{
  @EnvironmentObject var musicVM : MusicViewModel

  @State var localTrackSelected : Int? = nil
  @State var MusicStateChanged : Bool = false

  @State var elapsedTrackTime : Float = 0

  @State var scrollToCurrentTrack : Bool = false


  //---------------------------------------------
  var body: some View
  {
    VStack(spacing: 0)
    {
      
      //-------------------------------------------
      // Tracks Listing

      ScrollView
      {

        ScrollViewReader
        { proxy in
          ForEach( musicVM.MMTracks.indices, id: \.self )
          { feTrack in

              NavigationLink(
                       destination: TranscribeView(
                localTrackSelected: feTrack ),

              label:
              {
                  // This can't be the proper way to do this!!
                  // I created a State var that indicates music went
                  // from playing to paused and viceVersa so that these
                  // images and fields would get updated.  Works, but...
                  // yuk!

                  VStack
                  {
                    ZStack
                    {
                      Text( MusicStateChanged ? "" : "" )

                      Text( musicVM.trackName(
                        trackIndex:feTrack ) )
                      .padding( .leading )
                      .font(.system(size: 36.0))
                      .frame(
                          maxWidth: .infinity,
                          minHeight: 75,
                          maxHeight: .infinity,
                          alignment: .leading )
                      .multilineTextAlignment(.leading)
                      .lineLimit( 3 )

                      .foregroundColor(
                        ( localTrackSelected != nil &&
                          localTrackSelected == feTrack ) ?
                        Color(uiColor: .green) : .white )
                      .background(
                        ( localTrackSelected != nil &&
                          localTrackSelected == feTrack ) ?
                        Color(uiColor: .darkGray) : .black )
                    } // ZStack

                    Divider()
                  } // VStack
                } ) // NavigationLink
            .simultaneousGesture(
              TapGesture().onEnded
              {
                localTrackSelected = feTrack
                musicVM.setSelectedTrack(
                  trackIndex: feTrack)
                musicVM.saveTrackInfoToAppStorage()
                proxy.scrollTo( feTrack )
              } ) // simultaneousGesture
            .id( feTrack )

          } // ForEach

          .onChange(
            of: localTrackSelected )
          {
            withAnimation(.spring() )
            {
              musicVM.setSelectedTrack( trackIndex: localTrackSelected! )
              musicVM.saveTrackInfoToAppStorage()
              proxy.scrollTo(localTrackSelected, anchor: .center)
            }
          } // onChange

          .onChange(
            of: scrollToCurrentTrack )
          {
            withAnimation(.spring() )
            {
              proxy.scrollTo(localTrackSelected, anchor: .center)
            }
          } // onChange

        }  // ScrollViewReader

      } // ScrollView

    } // VStack


        //-------------------------------------------
        // Navigation Bar

    .navigationBarTitle(
      musicVM.getCollectionName(),
      displayMode: .inline )
    .navigationBarItems(
      trailing:
        HStack
        {
          Button(
            action:
              {
                scrollToCurrentTrack.toggle()
              },
            label:
              {
                Image( systemName: "filemenu.and.selection" )
              } )
        } // HStack
    )


    //-------------------------------------------
    // When the View appears
    
    .onAppear
    {
      localTrackSelected = musicVM.getSelectedTrackIndex()
      musicVM.saveTrackInfoToAppStorage()
      elapsedTrackTime = 0
      MusicStateChanged = !MusicStateChanged
    } // onAppear

  } // var body

} // TracksView

//--------------------------------------------
