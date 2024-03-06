//
//  AlbumsFromArtistView.swift
//  BigPlayer1
//
//  Created by Stewart French on 2/10/23.
//  Adapted for SayItAgain on 2/6/2024.
//  

import SwiftUI

//--------------------------------------------
struct AlbumsFromArtistView: View
{
  @EnvironmentObject var musicVM : MusicViewModel

  @State private var tSelectedAlbum: Int? = nil

  @State private var scrollToCurrentAlbum : Bool = false

  var tappedArtistIndex : Int

  @Binding var tSelectedArtist : Int?



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
                albumIndex: feIndex,
                artistIndex: tSelectedArtist )

              musicVM.retrieveTracksFromAlbum( 
                albumIndex: feIndex )

              musicVM.prepareTracksToPlay()
            } )

        } // ForEach
        .onChange(of: scrollToCurrentAlbum)
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
      tSelectedArtist != nil ? 
        musicVM.getArtistName( index: tSelectedArtist! ) : 
        "Artists",
      displayMode: .inline )
      .font(.largeTitle)
      .foregroundColor(.white)

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
              } )
         } ) // .navigationBarItems

    .onAppear 
    {
      tSelectedAlbum = musicVM.getSelectedAlbumIndex()
      
      tSelectedArtist = tappedArtistIndex

      musicVM.selectedArtistIndex =
        tappedArtistIndex

      musicVM.retrieveAlbums(
        artistNameIndex: musicVM.selectedArtistIndex )
    } // .onAppear

  } // var body

} // AlbumsFromArtistView


//--------------------------------------------
