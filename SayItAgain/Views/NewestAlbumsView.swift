//
//  NewestAlbumsView.swift
//  BigPlayer1
//
//  Created by Stewart French on 2/24/23.
//  Adapted for SayItAgain on 2/6/2024.
//

import SwiftUI

//--------------------------------------------
struct NewestAlbumsView: View
{
  @EnvironmentObject var musicVM : MusicViewModel

  @State private var tSelectedAlbum: Int? = nil

  @State private var scrollToCurrentAlbum : Bool = false

  @State var notAuthorized : Bool = false


  //-------------------
  var body: some View 
  {
    ScrollView
    {
      ScrollViewReader
      { proxy in
      
        ForEach( musicVM.MMAlbums.indices, id: \.self )
        { feIndex in
  
            NavigationLink(
              destination: TracksView(),
            label: 
            {
              VStack
              {
                Text(musicVM.getAlbumName(index: feIndex))
                .font(.system(size: 36.0))
                .frame(
                    maxWidth: .infinity,
                   minHeight: 50,
                   maxHeight: .infinity,
                   alignment: .leading )
                .multilineTextAlignment(.leading)
                .lineLimit( 3 )
                .foregroundColor(
                  tSelectedAlbum==feIndex ?
                    Color(uiColor: .green) : .white )
                .background(
                  tSelectedAlbum==feIndex ?
                    Color(uiColor: .darkGray) : .black )
                Divider()
              } // VStack
            } ) // NavigationLink
          .id( feIndex )

          .simultaneousGesture(
            TapGesture().onEnded
            {
              musicVM.setSelectedAlbum(
                albumIndex: feIndex )

              musicVM.retrieveTracksFromAlbum( 
                albumIndex: feIndex )

              musicVM.prepareTracksToPlay()
            } )

        } // ForEach

        .onChange(
          of: scrollToCurrentAlbum )
          {
            withAnimation(.spring() )
            {
              proxy.scrollTo(tSelectedAlbum, anchor: .center)
            }
          } // onChange
      } // ScrollViewReader
    } // ScrollView


        //-------------------------------------------
        // Navigation Bar


    .navigationBarTitle( 
      "Newest Albums",
      displayMode: .inline )
      .font(.largeTitle)
      .foregroundColor(.white )


    .navigationBarItems(
      trailing:
        HStack
        {
          Button(
            action:
              {
                scrollToCurrentAlbum.toggle()
              },
            label:
              {
                Image( systemName: "filemenu.and.selection" )
              } ) // Button
         } ) // .navigationBarItems


        //-------------------------------------------
        // When the View appears
    
    .onAppear 
    {
      notAuthorized = !musicVM.authorizedToAccessMusic

      if !notAuthorized
      { 
        tSelectedAlbum = musicVM.getSelectedAlbumIndex()
      
        musicVM.retrieveNewestAlbums( 
          artistNameIndex: nil )
      } // if
    } // .onAppear

    .alert( isPresented: $notAuthorized )
    {
      Alert( 
                title: Text( "SayItAgain needs access to the Music Library." ),
              message: Text( "Go to Settings > SayItAgain\nto Allow Access to Apple Music" ),
        dismissButton: 
          Alert.Button.default( Text( "OK" ),
            action: 
            {
              exit(0)
            } ) ) // Alert
    } // .alert

  } // var body
  
} // NewestAlbumsView

//--------------------------------------------
