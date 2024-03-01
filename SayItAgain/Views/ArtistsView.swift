//
//  ArtistsView.swift
//  BigPlayer1
//
//  Created by Stewart French on 1/25/23.
//  Adapted for SayItAgain on 2/6/2024.
//

import SwiftUI

//--------------------------------------------
struct ArtistsView: View
{
  @EnvironmentObject var musicVM : MusicViewModel
  
  @State private var tSelectedArtist: Int? = nil
  
  @State private var scrollToCurrentArtist : Bool = false
  
  @State private var thumbedArtist : Int = 0
  
  @State var notAuthorized : Bool = false


  //-------------------
  var body: some View
  {
    ZStack
    {
      // Background
      
      Color.black
        .edgesIgnoringSafeArea( .all )
      
      // content
      
      HStack
      {
        ScrollView( showsIndicators: true )
        {
          ScrollViewReader
          { proxy in
            
            ForEach( musicVM.MMArtists.indices, id: \.self )
            { feIndex in
              
              NavigationLink(
                
                destination:
                  AlbumsFromArtistView(
                    tappedArtistIndex: feIndex,
                    tSelectedArtist: $tSelectedArtist),
                
                label:
                  {
                    VStack
                    {
                      Text(musicVM.getArtistName(index: feIndex))
                        .font(.system(size: 36.0))
                        .frame(
                          maxWidth: .infinity,
                          minHeight: 50,
                          maxHeight: .infinity,
                          alignment: .leading )
                        .multilineTextAlignment(.leading)
                        .lineLimit( 3 )
                        .foregroundColor(
                          tSelectedArtist==feIndex ?
                            Color(uiColor: .green) : .white )
                        .background(
                          tSelectedArtist==feIndex ?
                            Color(uiColor: .darkGray) : .black )
                      Divider()
                    } // VStack
                  } ) // NavigationLink
              .id( feIndex )
              .simultaneousGesture(
                TapGesture().onEnded
                {
                  musicVM.setSelectedArtist( index: feIndex )
                } )
            } // ForEach
            
            .onChange(
              of: scrollToCurrentArtist )
                { old, new in
                  withAnimation(.spring() )
                  {
                    proxy.scrollTo(tSelectedArtist, anchor: .center)
                  }
                } // onChange
                
            .onChange(
              of: thumbedArtist )
                { old, new in
                  withAnimation(.spring() )
                  {
                    proxy.scrollTo( thumbedArtist, anchor: .center )
                  }
                } // onChange

          } // ScrollViewReader
        } // ScrollView

        Divider()

        Spacer()
        Spacer()

        verticalAZsliderArtists( scrollTo: $thumbedArtist )

      } // HStack
    } // ZStack
    

        //-------------------------------------------
        // Navigation Bar

    .navigationBarTitle( "Artists",
                         displayMode: .inline )
    
    .navigationBarItems(
      trailing:
        HStack
        {
          Button(
            action:
              {
                scrollToCurrentArtist.toggle()
              },
            label:
              {
                Image( systemName: "filemenu.and.selection" )
              } ) // Button
        } ) // navigationBarItems
    
    
        //-------------------------------------------
        // When the View appears
    
    .onAppear
    {

      notAuthorized = !musicVM.authorizedToAccessMusic

      if !notAuthorized
      { 
        if musicVM.selectedArtistIndex != nil
        {
          tSelectedArtist = musicVM.selectedArtistIndex
        }
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
  
}  // ArtistsView



//--------------------------------------------
struct verticalAZsliderArtists: View
{
  
  @EnvironmentObject var musicVM : MusicViewModel
  
  @Binding var scrollTo : Int
  
  var body: some View
  {
    VStack
    {
      VStack
      {
        Text( "A" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[0] }
        .font(.system(size: 20))
        Text( "B" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[1] }
        .font(.system(size: 20))
        Text( "C" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[2] }
        .font(.system(size: 20))
        Text( "D" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[3] }
        .font(.system(size: 20))
        Text( "E" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[4] }
        .font(.system(size: 20))
        Text( "F" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[5] }
        .font(.system(size: 20))
        Text( "G" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[6] }
        .font(.system(size: 20))
        Text( "H" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[7] }
        .font(.system(size: 20))
        Text( "I" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[8] }
        .font(.system(size: 20))
      }
      VStack
      {
        Text( "J" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[9] }
        .font(.system(size: 20))
        Text( "K" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[10] }
        .font(.system(size: 20))
        Text( "L" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[11] }
        .font(.system(size: 20))
        Text( "M" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[12] }
        .font(.system(size: 20))
        Text( "N" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[13] }
        .font(.system(size: 20))
        Text( "O" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[14] }
        .font(.system(size: 20))
        Text( "P" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[15] }
        .font(.system(size: 20))
        Text( "Q" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[16] }
        .font(.system(size: 20))
        Text( "R" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[17] }
        .font(.system(size: 20))
        Text( "S" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[18] }
        .font(.system(size: 20))
      }
      VStack
      {
        Text( "T" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[19] }
        .font(.system(size: 20))
        Text( "U" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[20] }
        .font(.system(size: 20))
        Text( "V" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[21] }
        .font(.system(size: 20))
        Text( "W" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[22] }
        .font(.system(size: 20))
        Text( "X" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[23] }
        .font(.system(size: 20))
        Text( "Y" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[24] }
        .font(.system(size: 20))
        Text( "Z" ).onTapGesture {
          scrollTo = musicVM.MMArtistsAlphaMap[25] }
        .font(.system(size: 20))
      }
    }
    .foregroundColor( .white )
    .background( .black )
    
  } // body
  
} // verticalAZsliderArtists



//--------------------------------------------
