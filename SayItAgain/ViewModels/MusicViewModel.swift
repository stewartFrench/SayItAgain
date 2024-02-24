//---------------------------------------------------------
//
//  MusicViewModel.swift
//  Copyright (c) 2023 Stewart French. All rights reserved.
//
//  Created by Stewart French on 1/25/23.
//  Adapted for SayItAgain on 2/6/2024.
//

import Foundation
import MediaPlayer
import SwiftUI

//-----------------------------------------------------------
class MusicViewModel : ObservableObject
{
            // I will keep track of all the Playlists, Artists,
            // Albums, and Tracks within the selected
            // collection, once set.


  @Published var   MMArtists : [MPMediaItemCollection] = []
  @Published var    MMAlbums : [MPMediaItemCollection] = []
  @Published var MMPlaylists : [MPMediaItemCollection] = []
  @Published var    MMTracks : [MPMediaItem] = []

            // The Alpha Maps are arrays of integers, 0..26,
            // representing the letters A..Z.  For each
            // Artist/Album/Playlist collection array the entries
            // indicate the location index in the collection array
            // where the first letter of that name appears.

  @Published var   MMArtistsAlphaMap : [Int] = []
  @Published var    MMAlbumsAlphaMap : [Int] = []
  @Published var MMPlaylistsAlphaMap : [Int] = []

            // There is a single selected Artist, Album, Playlist, and
            // Track.  Each of these is an Intger, used as an index
            // into the list of Artists, Albums, Playlists, and Tracks
            // (zero based).  Each of these could be nil to indicate
            // not set.

  @Published var selectedArtistIndex : Int? = nil
  @Published var selectedAlbumIndex : Int? = nil
  @Published var selectedPlaylistIndex : Int? = nil
  @Published var selectedTrackIndex : Int? = nil

            // Whenever tracks are queued and ready for play this var
            // will be true.

  @Published var tracksAreQueued : Bool = false

            // The Selected Playlist is kept as an index into the
            // NSArray of all Playlists.
            // The Selected Track is kept as both an index into the
            // Array of all Tracks for the selected playlist, and as
            // an MPMediaItem.  I will only keep the tracks around for
            // the selected playlist, no others.

  @Published var MMSelectedPlaylist : Int? = nil
  @Published var MMSelectedTrack : MPMediaItem? = nil


            // The user chooses an artist, album, or playlist in order
            // to see a list of tracks to play.  Once the album or
            // playlist is selected and the tracks are shown, along
            // with the play controls, the user can still back up
            // through the views and select other artists or
            // playlists.  If they push the Now Playing button at that
            // point I will need to restore the state of the tracks
            // that are currently queued and playing.

            // I put all this saved data in a class so that I can
            // archive and write/read it to the file system.

//-----------

  var savedMMTracks : [MPMediaItem] = []
  var savedMMAlbums : [MPMediaItemCollection] = []

  var savedSelectedArtistIndex : Int? = nil
  var savedSelectedAlbumIndex : Int? = nil
  var savedSelectedPlaylistIndex : Int? = nil

  var savedSelectedTrackIndex : Int? = nil


//-----------

            // When the app is first loaded Apple requires the user to
            // authorize access to the music library by popping up an
            // alert.  If the user authorizes the device the var
            // authorizedToAccessMusic will be set to true.  If not,
            // it will be set to false.

  var authorizedToAccessMusic : Bool = false

//-----------

          // I will use the System Music Player in this app.

  var MMPlayer : MPMusicPlayerController =
                      MPMusicPlayerController.systemMusicPlayer


          // Here are the complete set of states that are possible for
          // the MM player to be in.

  enum MMState 
  {
    case kMusicManagerTrackStopped
    case kMusicManagerTrackPlaying
    case kMusicManagerTrackPaused
    case kMusicManagerTrackInterrupted
    case kMusicManagerTrackSeekingForward
    case kMusicManagerTrackSeekingBackward
  }

  var MMTrackState: MMState = .kMusicManagerTrackStopped

            // I'll keep a local private copy of the playback rate.
            // It seems that setting the playback rate > 0.0 is the
            // same as calling play().  If I do both I hear a hiccup
            // in the music.

  private var localPlaybackRate : Float = 1.0


  //---------------------------------------------------------
  init()
  {

            // Check for music libary access authorization

   let status = MPMediaLibrary.authorizationStatus()
   switch status
   {
     case .authorized:
           DispatchQueue.main.async
           {
             self.authorizedToAccessMusic = true
             self.readMusicLibrary()
           }

     case .notDetermined:
       MPMediaLibrary.requestAuthorization()
       { status in
         if status == .authorized
         {
           DispatchQueue.main.async
           {
             self.authorizedToAccessMusic = true
             self.readMusicLibrary()
           }
         }
       } // closure

     default: break

   } // switch
  } // init
  


  //---------------------------------------------------------
  //---------------------------------------------------------
  func readMusicLibrary()
  {
    self.retrieveArtists()
    self.retrievePlaylists()

    MMPlayer.stop()
    MMTrackState = .kMusicManagerTrackStopped

    MMPlayer.shuffleMode = .off
    MMPlayer.repeatMode = .none

    self.restoreTracksFromAppStorage()

    MMPlayer.beginGeneratingPlaybackNotifications()

    NotificationCenter.default.addObserver(self,
         selector: #selector(catchMPMusicPlayerControllerNowPlayingItemDidChange),
             name: .MPMusicPlayerControllerNowPlayingItemDidChange,
           object: nil)

     NotificationCenter.default.addObserver(self,
         selector: #selector(catchMPMusicPlayerControllerPlaybackStateDidChange),
             name: .MPMusicPlayerControllerPlaybackStateDidChange,
           object: nil)

  } // readMusicLibrary()


  //---------------------------------------------------------
  func retrieveArtists()
  {
    let query : MPMediaQuery = MPMediaQuery.artists()
    let isPresent = MPMediaPropertyPredicate(
                     value: false,
                     forProperty: MPMediaItemPropertyIsCloudItem,
                     comparisonType: .equalTo )
    query.addFilterPredicate(isPresent)

    guard let tArtists = query.collections else 
    {
      return
    }

              // Sort the artists by name

    var tName1 = "Unknown Artist"
    var tName2 = "Unknown Artist"

    let sortedArtists = 
      tArtists.sorted
      { artist1, artist2 in

        if let tRepresentativeItem1 = artist1.representativeItem
        {
          tName1 = tRepresentativeItem1.artist ?? "Unknown Artist"
        }

        if let tRepresentativeItem2 = artist2.representativeItem
        {
          tName2 = tRepresentativeItem2.artist ?? "Unknown Artist"
        }

        let t = tName1 < tName2

        return t
      }

    MMArtists = sortedArtists
    createArtistsAlphaMap()


//    SLFLog( "\(#function)" )

    //    for artists : MPMediaItemCollection in MMArtists
    //    {
    //      dumpMediaItemProperties( mediaItem: artists.representativeItem! )
    //      break  // Just print one for now
    //    }
    //    print( "Count of Artists : " + String( self.countOfArtists() ) )

  }  // retrieveArtists


  //---------------------------------------------------------
  func countOfArtists() -> Int
  {
    let tCount : Int = MMArtists.count
    return tCount
  } // countOfArtists


//---------------------------------------------------------
  func retrieveAlbums( artistNameIndex: Int? = nil )
  {
    let query : MPMediaQuery = MPMediaQuery.albums()
    let isPresent = MPMediaPropertyPredicate(
                     value: false,
                     forProperty: MPMediaItemPropertyIsCloudItem,
                     comparisonType: .equalTo )
    query.addFilterPredicate(isPresent)


    if artistNameIndex != nil, 
       artistNameIndex! < MMArtists.count
    {
      let tArtistName = getArtistName(index: artistNameIndex!)
      let forArtist = 
            MPMediaPropertyPredicate(
                value: tArtistName,
                forProperty: MPMediaItemPropertyArtist)
      query.addFilterPredicate( forArtist )
    }

    guard let tAlbums = query.collections else 
    {
      return
    }

            // Sort the artists by name

    var tName1 = "Unknown Album"
    var tName2 = "Unknown Album"

    let sortedAlbums = 
      tAlbums.sorted
      { album1, album2 in

        if let tRepresentativeItem1 = album1.representativeItem
        {
          tName1 = tRepresentativeItem1.albumTitle ?? "Unknown Album"
        }

        if let tRepresentativeItem2 = album2.representativeItem
        {
          tName2 = tRepresentativeItem2.albumTitle ?? "Unknown Album"
        }

        let t = tName1 < tName2

        return t
      } // sorted

    MMAlbums = sortedAlbums
    createAlbumsAlphaMap()

  }  // retrieveAlbums



//---------------------------------------------------------
  func retrieveNewestAlbums( artistNameIndex: Int? = nil )
  {
    let query : MPMediaQuery = MPMediaQuery.albums()
    let isPresent = MPMediaPropertyPredicate(
                     value: false,
                     forProperty: MPMediaItemPropertyIsCloudItem,
                     comparisonType: .equalTo )
    query.addFilterPredicate(isPresent)


    if artistNameIndex != nil, 
       artistNameIndex! < MMArtists.count
    {
      let tArtistName = getArtistName(index: artistNameIndex!)
      let forArtist = 
            MPMediaPropertyPredicate(
                value: tArtistName,
                forProperty: MPMediaItemPropertyArtist)
      query.addFilterPredicate( forArtist )
    }

    guard let tAlbums = query.collections else 
    {
      return
    }
            // Sort the albums in reverse date order

    let sortedAlbums = 
      tAlbums.sorted
      { album1, album2 in
        let item1 = album1.representativeItem
        let tDate1 = item1?.dateAdded

        let item2 = album2.representativeItem
        let tDate2 = item2?.dateAdded

        if ( tDate1 != nil ) &&
           ( tDate2 != nil )
           {
              let t = tDate1! > tDate2!
              return t
           }
        return false
      }
    MMAlbums = sortedAlbums

  }  // retrieveNewestAlbums



//---------------------------------------------------------
  func retrieveRecentlyPlayedAlbums( artistNameIndex: Int? = nil )
  {
    let query : MPMediaQuery = MPMediaQuery.albums()

    let isPresent = MPMediaPropertyPredicate(
                     value: false,
                     forProperty: MPMediaItemPropertyIsCloudItem,
                     comparisonType: .equalTo )
    query.addFilterPredicate(isPresent)

    if artistNameIndex != nil, 
       artistNameIndex! < MMArtists.count
    {
      let tArtistName = getArtistName(index: artistNameIndex!)
      let forArtist = 
            MPMediaPropertyPredicate(
                value: tArtistName,
                forProperty: MPMediaItemPropertyArtist)
      query.addFilterPredicate( forArtist )
    }

    guard let tAlbums = query.collections else 
    {
      return
    }
            // Sort the albums in reverse date order

    let sortedAlbums = 
      tAlbums.sorted
      { album1, album2 in
        let item1 = album1.representativeItem
        let tDate1 = item1?.lastPlayedDate

        let item2 = album2.representativeItem
        let tDate2 = item2?.lastPlayedDate

        if ( tDate1 != nil ) &&
           ( tDate2 != nil )
           {
              let t = tDate1! < tDate2!
              return t
           }
        return false
      }
    MMAlbums = sortedAlbums
  }  // retrieveRecentlyPlayedAlbums


  //---------------------------------------------------------
  func createArtistsAlphaMap()
  {
            // initialize the array representing 'A'..'Z', 26 entries,
            // I will set them each to the location in MMArtists where
            // the artist name's first character starts.

    MMArtistsAlphaMap = Array(repeating: 0, count: 26)

    if MMArtists.count > 0
    {
      for tIndex in 0..<MMArtists.count
      {
        let tArtistName = getArtistName( index: tIndex )
        let tFirst = tArtistName.first?.uppercased() ?? "Z"

        var firstLetter =
             Int( Character( tFirst )
             .asciiValue ?? 90 ) - 65

        if ( firstLetter < 0 ) ||
           ( firstLetter > 25 )
        {
          firstLetter = 0
        }

        if MMArtistsAlphaMap[firstLetter] == 0
        {
          MMArtistsAlphaMap[firstLetter] = tIndex
        }
      }

            // Now run through the map array again and correct for any
            // left-over zero values (where there were no artists that
            // started with that letter).

      var currentChar = MMArtistsAlphaMap[0]
      for tIndex in 1...25
      {
        if MMArtistsAlphaMap[tIndex] == 0
        {
          MMArtistsAlphaMap[tIndex] = currentChar
        }
        currentChar = MMArtistsAlphaMap[tIndex]
      }

           // Handle the end condition.

      if MMArtistsAlphaMap[25] < MMArtistsAlphaMap[24]
      {
        MMArtistsAlphaMap[25] = MMArtistsAlphaMap[24]
      }

    }
  } // createArtistAlphaMap


  //---------------------------------------------------------
  func createAlbumsAlphaMap()
  {
            // initialize the array representing 'A'..'Z', 26 entries,
            // I will set them each to the location in MMAlbums where
            // the album name's first character starts.

    MMAlbumsAlphaMap = Array(repeating: 0, count: 26)

    if MMAlbums.count > 0
    {
      for tIndex in 0..<MMAlbums.count
      {
        let tAlbumName = getAlbumName( index: tIndex )
        let tFirst = tAlbumName.first?.uppercased() ?? "Z"

        var firstLetter =
             Int( Character( tFirst )
             .asciiValue ?? 90 ) - 65

        if ( firstLetter < 0 ) ||
           ( firstLetter > 25 )
        {
          firstLetter = 0
        }

        if MMAlbumsAlphaMap[firstLetter] == 0
        {
          MMAlbumsAlphaMap[firstLetter] = tIndex
        }
      }

            // Now run through the map array again and correct for any
            // left-over zero values (where there were no albums that
            // started with that letter).

      var currentChar = MMAlbumsAlphaMap[0]
      for tIndex in 1...25
      {
        if MMAlbumsAlphaMap[tIndex] == 0
        {
          MMAlbumsAlphaMap[tIndex] = currentChar
        }
        currentChar = MMAlbumsAlphaMap[tIndex]
      }

           // Handle the end condition.

      if MMAlbumsAlphaMap[25] < MMAlbumsAlphaMap[24]
      {
        MMAlbumsAlphaMap[25] = MMAlbumsAlphaMap[24]
      }

    }
  } // createAlbumsAlphaMap


  //---------------------------------------------------------
  func createPlaylistsAlphaMap()
  {
            // initialize the array representing 'A'..'Z', 26 entries,
            // I will set them each to the location in MMPlaylists where
            // the Playlist name's first character starts.

    MMPlaylistsAlphaMap = Array(repeating: 0, count: 26)

    if MMPlaylists.count > 0
    {
      for tIndex in 0..<MMPlaylists.count
      {
        let tPlaylistName = getPlaylistName( index: tIndex )
        let tFirst = tPlaylistName.first?.uppercased() ?? "Z"

        var firstLetter =
             Int( Character( tFirst )
             .asciiValue ?? 90 ) - 65

        if ( firstLetter < 0 ) ||
           ( firstLetter > 25 )
        {
          firstLetter = 25
        }

        if MMPlaylistsAlphaMap[firstLetter] == 0
        {
          MMPlaylistsAlphaMap[firstLetter] = tIndex
        }
      }

            // Now run through the map array again and correct for any
            // left-over zero values (where there were no Playlists that
            // started with that letter).

      var currentChar = MMPlaylistsAlphaMap[0]
      for tIndex in 1...25
      {
        if MMPlaylistsAlphaMap[tIndex] == 0
        {
          MMPlaylistsAlphaMap[tIndex] = currentChar
        }
        currentChar = MMPlaylistsAlphaMap[tIndex]
      }

           // Handle the end condition.

      if MMPlaylistsAlphaMap[25] < MMPlaylistsAlphaMap[24]
      {
        MMPlaylistsAlphaMap[25] = MMPlaylistsAlphaMap[24]
      }

    }
  } // createPlaylistAlphaMap


  //---------------------------------------------------------
  func countOfAlbums() -> Int
  {
    let tCount : Int = MMAlbums.count
    return tCount
  } // countOfAlbums


//---------------------------------------------------------
  func retrievePlaylists()
  {
    let query : MPMediaQuery = MPMediaQuery.playlists()

    let isPresent = MPMediaPropertyPredicate(
                     value: false,
                     forProperty: MPMediaItemPropertyIsCloudItem,
                     comparisonType: .equalTo )
    query.addFilterPredicate(isPresent)


    guard let tPlaylists = query.collections else 
    {
      return
    }

            // Sort the Playlists by name

    let sortedPlaylists = 
      tPlaylists.sorted
      { playlist1, playlist2 in

        let tName1 = playlist1.value( 
                        forProperty: MPMediaPlaylistPropertyName) ??
                        "No Name"

        let tName2 = playlist2.value( 
                        forProperty: MPMediaPlaylistPropertyName) ??
                        "No Name"

        let t = "\(tName1)" < "\(tName2)"

        return t
      }

    MMPlaylists = sortedPlaylists
    createPlaylistsAlphaMap()

  }  // retrievePlaylists


  //---------------------------------------------------------
  func countOfPlaylists() -> Int
  {
    let tCount : Int = MMPlaylists.count
    return tCount

  } // countOfPlaylists



  //---------------------------------------------------------
  func getPlaylistName( index : Int ) -> String
  {
    let item = MMPlaylists[index]
    let playlistName =
         item.value( forProperty: MPMediaPlaylistPropertyName) ?? "No Name"

    return "\(playlistName)"

  } // getPlaylistName
  

  //---------------------------------------------------------
  func getArtistName( index : Int ) -> String
  {
    var tName : String = ""
    if index < MMArtists.count 
    {
      let item = MMArtists[index]
      guard let tRepresentativeItem = item.representativeItem else {
        return "Unknown Artist"
      }
      tName = tRepresentativeItem.artist ?? "Unknown Artist"
    }
    return tName

  } // getArtistName
  

  //---------------------------------------------------------
  func getAlbumName( index : Int ) -> String
  {
    var tName : String = ""
    if index < MMAlbums.count 
    {
      let item = MMAlbums[index]
      guard let tRepresentativeItem = item.representativeItem else {
        return "Unknown Album"
      }
      tName = tRepresentativeItem.albumTitle ?? "Unknown Album"
    }
    return tName

  } // getAlbumName
  

  //---------------------------------------------------------
  func getCollectionName() -> String
  {
            // If it's a playlist, return it's name.
            
    if selectedPlaylistIndex != nil
    {
      return getPlaylistName( index: selectedPlaylistIndex! )
    }
    
            // If it's an album, return it's name.

    if ( selectedPlaylistIndex == nil ) &&
       ( selectedAlbumIndex != nil )
    {
      return getAlbumName( index: selectedAlbumIndex! )
    }

            // If they are both nil, it must be a Resume op.

    return ASCollectionName            

  } // getCollectionName


  //---------------------------------------------------------
  func retrieveTracksFromAlbum( albumIndex: Int )
  {
    MMTracks = []
    if albumIndex < MMAlbums.count
    {
      MMTracks = MMAlbums[albumIndex].items
      setSelectedAlbum( albumIndex: albumIndex )
    }

    if MMTracks.count > 0
    {
      MMSelectedTrack = MMTracks[0]
      MMPlayer.nowPlayingItem = MMSelectedTrack
      selectedTrackIndex = 0
    }

  } // retrieveTracksFromAlbum



  //---------------------------------------------------------
  func retrieveTracksFromPlaylist( playlistIndex: Int )
  {
    MMTracks = []
    if playlistIndex < MMPlaylists.count
    {
      MMTracks = MMPlaylists[playlistIndex].items
      setSelectedPlaylist( index: playlistIndex )
    }

    if MMTracks.count > 0
    {
      MMSelectedTrack = MMTracks[0]
      MMPlayer.nowPlayingItem = MMSelectedTrack
      selectedTrackIndex = 0
    }

  } // retrieveTracksFromPlaylist


  //---------------------------------------------------------
  func trackName( trackIndex: Int ) -> String
  {
    if trackIndex < MMTracks.count
    {
      guard let tTitle = MMTracks[trackIndex].title else
      {
        return "No Track Name!"
      }
      return tTitle
    }
    return "Bad Track Index!"

  } // trackName


  //---------------------------------------------------------
  func trackArtist( trackIndex: Int ) -> String
  {
    if trackIndex < MMTracks.count
    {
      guard let tArtist = MMTracks[trackIndex].artist else
      {
        return "No Track Artist!"
      }
      return tArtist
    }
    return "Bad Track Index!"

  } // trackArtist
  


  //---------------------------------------------------------
  func trackAlbum( trackIndex: Int ) -> String
  {
    if trackIndex < MMTracks.count
    {
      guard let tAlbum = MMTracks[trackIndex].albumTitle else
      {
        return "No Album Title!"
      }
      return tAlbum
    }
    return "Bad Track Index!" 

  } // trackAlbum
  


  //---------------------------------------------------------
  func trackDuration( trackIndex: Int ) -> String
  {
    if trackIndex < MMTracks.count
    {
      let tTrack = MMTracks[trackIndex]
      let tDuration = tTrack.playbackDuration

      return "\(tDuration)"
    }
    return "Bad Track Index!" 

  } // trackDuration
  


  //---------------------------------------------------------
  func shuffleTracks()
  {
    if MMTracks.count > 0 
    {
      MMTracks.shuffle()
    }

  } // shuffleTracks



  //---------------------------------------------------------
  func prepareTracksToPlay( fromAppStorage: Bool = false )
  {
    if MMTracks.count > 0 
    {
      let tTracks : [MPMediaItem] = self.MMTracks

      selectedTrackIndex = 0

      if fromAppStorage
      {
        selectedTrackIndex = Int( AStrackNumber )
      }

      MMSelectedTrack = tTracks[selectedTrackIndex!]

      MMPlayer.setQueue(
        with: MPMediaItemCollection(items: tTracks) )
      tracksAreQueued = true

      MMPlayer.repeatMode = .none
      MMPlayer.nowPlayingItem = MMSelectedTrack
      MMPlayer.prepareToPlay()
      
    } else
    {
    
      let tTracks : [MPMediaItem] = []
      MMPlayer.setQueue(
        with: MPMediaItemCollection(items: tTracks) )
      tracksAreQueued = false
      MMPlayer.nowPlayingItem = nil
      MMPlayer.prepareToPlay()

      MMSelectedTrack = nil
      selectedTrackIndex = nil
    }

    saveTracksState()

  } // prepareTracksToPlay



  //---------------------------------------------------------
  func setSelectedArtist( index: Int )
  {
    selectedArtistIndex = index
    selectedAlbumIndex = nil
    selectedPlaylistIndex = nil

  } // setSelectedArtist



  //---------------------------------------------------------
  func clearSelections()
  {
    selectedArtistIndex = nil
    selectedAlbumIndex = nil
    selectedPlaylistIndex = nil

  } // clearSelections



  //---------------------------------------------------------
  func setSelectedAlbum( 
          albumIndex: Int, 
         artistIndex: Int? = nil )
  {
    selectedAlbumIndex = albumIndex
    selectedArtistIndex = artistIndex
    selectedPlaylistIndex = nil

  } // setSelectedAlbum



  //---------------------------------------------------------
  func setSelectedPlaylist( index: Int )
  {
    selectedPlaylistIndex = index
    selectedAlbumIndex = nil
    selectedArtistIndex = nil

  } // setSelectedPlaylist



  //---------------------------------------------------------
  func getSelectedAlbumIndex() -> Int?
  {
    if let tAlbumIndex = selectedAlbumIndex
    {
      return tAlbumIndex
    }
    return nil

  } // getSelectedAlbumIndex



  //---------------------------------------------------------
  func setSelectedTrack( trackIndex: Int )
  {
      let nowPlayingIndex = MMPlayer.indexOfNowPlayingItem

      if trackIndex < MMTracks.count
      {
           if trackIndex < nowPlayingIndex
           {
             for _ in trackIndex..<nowPlayingIndex
             {
               MMPlayer.skipToPreviousItem()
             }
           } else
           {
             if trackIndex > nowPlayingIndex
             {
               for _ in nowPlayingIndex..<trackIndex
               {
                  MMPlayer.skipToNextItem()
               }
             }
           }

        MMSelectedTrack = MMTracks[trackIndex]
        selectedTrackIndex = trackIndex
        AStrackNumber = "\(selectedTrackIndex!)"

      } else
      {
        self.clearSelectedTrack()
      }

  } // setSelectedTrack



  //---------------------------------------------------------
  func getSelectedTrackIndex() -> Int?
  {
    if let tTrackIndex = selectedTrackIndex
    {
      return tTrackIndex
    }
    return nil

  } // getSelectedTrackIndex



  //---------------------------------------------------------
  func clearSelectedTrack()
  {
    MMPlayer.stop()
    MMTrackState = .kMusicManagerTrackStopped
    selectedTrackIndex = nil

  } // clearSelectedTrack



  //---------------------------------------------------------
  func playSelectedTrack()
  {
    if selectedTrackIndex != nil
    {
            // It seems that setting the playback rate > 0.0 is the
            // same as calling play().  If I do both I hear a hiccup
            // in the music.

      self.MMPlayer.currentPlaybackRate =  self.localPlaybackRate
      MMTrackState = .kMusicManagerTrackPlaying
    } // if

  } // playSelectedTrack



  //---------------------------------------------------------
  func pauseSelectedTrack()
  {
            // It seems that setting the playback rate to 0.0 is the
            // same as pausing.  If I do both I hear a hiccup in the music.

    MMPlayer.currentPlaybackRate =  0.0
//    MMPlayer.pause()

    MMTrackState = .kMusicManagerTrackPaused

  } // pauseSelectedTrack



  //---------------------------------------------------------
  func selectedTrackState() -> MMState
  {
    return MMTrackState

  } // selectedTrackState



  //---------------------------------------------------------
  func rewind()
  {
    if MMSelectedTrack != nil
    {
      MMPlayer.skipToBeginning()
    }

  } // rewind



  //---------------------------------------------------------
  func skipToPreviousTrack()
  {
    if MMSelectedTrack != nil
    {
      MMPlayer.skipToPreviousItem()
    }

  } // skipToPreviousItem



  //---------------------------------------------------------
  func skipToNextTrack()
  {
    if MMSelectedTrack != nil
    {
      MMPlayer.skipToNextItem()
    }

  } // skipToNextTrack



  //---------------------------------------------------------
  func skipBackInTrack( skipTime: Double )
  {
    if MMSelectedTrack != nil
    {
      let tTime = MMPlayer.currentPlaybackTime
  
      if ( tTime - skipTime ) > 0.0
      {
        MMPlayer.currentPlaybackTime = tTime - skipTime
      }
      else
      {
        MMPlayer.currentPlaybackTime = 0.0
      }
    }
  } // skipBackInTrack


  //---------------------------------------------------------
  func skipForwardInTrack( skipTime: Double )
  {
    if MMSelectedTrack != nil
    {
      let tTime = MMPlayer.currentPlaybackTime
  
      if tTime + skipTime < durationOfSelectedTrack()
      {
        MMPlayer.currentPlaybackTime = tTime + skipTime
      }
    }
  } // skipForwardInTrack


  //---------------------------------------------------------
  func skipToTimeInTrack( pTime: Double )
  {
    if MMSelectedTrack != nil
    {
      let tTime : Double = durationOfSelectedTrack()
  
      if ( pTime < tTime ) &&
         ( pTime >= 0.0 )
      {
        MMPlayer.currentPlaybackTime = pTime
      } // if
    }
  } // skipToTimeInTrack


  //---------------------------------------------------------
  func setPlaybackRate( playbackRate playbackRateP : Float )
  {
    if MMSelectedTrack != nil
    {
        MMPlayer.currentPlaybackRate =  playbackRateP
        localPlaybackRate = playbackRateP
    }
  } // setCurrentPlaybackRate



  //---------------------------------------------------------
  func previousTrackPressed()
  {
    if ( !selectedTrackIsAtBeginningOfPlaylist() )
    {
      let tElapsed : Double = elapsedTimeOfSelectedTrack()

      if ( tElapsed < 3.0 )
      {
        skipToPreviousTrack()
        selectedTrackIndex! -= 1
        MMSelectedTrack = MMTracks[selectedTrackIndex!]
      } else
      {
        rewind()
      }

    } else
    {
      rewind()
    }

  } // previousTrackPressed



  //---------------------------------------------------------
  func nextTrackPressed()
  {
    skipToNextTrack()
    if let tIndex = selectedTrackIndex
    {
      selectedTrackIndex = tIndex + 1
      if selectedTrackIndex == MMTracks.count
      {
        selectedTrackIndex = 0
      }
    }

  } // nextTrackPressed



  //---------------------------------------------------------
  func selectedTrackIsAtBeginningOfPlaylist() -> Bool
  {
    let currentItem = MMPlayer.nowPlayingItem

    if let tItem = currentItem
    {
      let timeFromBeginning = MMPlayer.currentPlaybackTime
      if ( ( timeFromBeginning < 3.0 ) &&
           ( tItem == MMTracks[0] ) )
      {
        return true
      } else
      {
        return false
      }
    }

    return true
  } // selectedTrackIsAtBeginningOfPlaylist



  //-----------------------------------------------------------
  func selectedTrackIsAtEndOfPlaylist() -> Bool
  {
    if ( ( MMSelectedTrack == nil ) &&
         ( MMPlayer.playbackState == .stopped ) )
    { return true }

    return false

  } // selectedTrackIsAtEndOfPlaylist



  //-----------------------------------------------------------
  func isPlaying() -> Bool
  {
     if MMPlayer.playbackState != .playing
     { return false }

     return true

} // isPlaying



  //---------------------------------------------------------
  func durationOfSelectedTrack() -> Double
  {
    if let tDuration = MMSelectedTrack?.playbackDuration
    {
      return tDuration
    }
    return 0

  } // durationOfSelectedTrack



  //---------------------------------------------------------
  func durationOfSelectedTrack() -> String
  {
    if let tDuration = MMSelectedTrack?.playbackDuration
    {
      let tStringDuration = 
        tDuration.formatted( .number.precision( .fractionLength( 1 ) ) )
      return tStringDuration
    }
    return "0.00"

  } // durationOfSelectedTrack



  //---------------------------------------------------------
  @objc func catchMPMusicPlayerControllerNowPlayingItemDidChange()
  {
    updateTrackInfo()

  } // catchMPMusicPlayerControllerNowPlayingItemDidChange



  //---------------------------------------------------------
  @objc func catchMPMusicPlayerControllerPlaybackStateDidChange()
  {
    updateTrackInfo()

  } // catchMPMusicPlayerControllerPlaybackStateDidChange



  //---------------------------------------------------------
  func elapsedTimeOfSelectedTrack() -> Double
  {
    if MMSelectedTrack != nil
    {
      return MMPlayer.currentPlaybackTime
    }
    return 0

  } // elapsedTimeOfSelectedTrack


  //---------------------------------------------------------
  func elapsedTimeOfSelectedTrack() -> String
  {
    if MMSelectedTrack != nil
    {
      let tPlaybackTime = MMPlayer.currentPlaybackTime
      let tString = tPlaybackTime.formatted( .number.precision( .fractionLength(1) ) )
      return tString
    }
    return "0.00"

  } // elapsedTimeOfSelectedTrack


  //---------------------------------------------------------
  func savedElapsedTime() -> Double
  {
    return ASelapsedTime
  } // savedElapsedTime


  //---------------------------------------------------------
  func updateTrackInfo()
  {
    if ( MMPlayer.indexOfNowPlayingItem != NSNotFound ) &&
       ( MMTracks.count > 0 )
    {
      let currentPlayingIndex = 
            MMPlayer.indexOfNowPlayingItem % MMTracks.count

      MMSelectedTrack = MMTracks[currentPlayingIndex]
      selectedTrackIndex = currentPlayingIndex
      saveTrackInfoToAppStorage()
    } else
    {   // nothing is playing, set it to the first track

      if MMTracks.count > 0
      {
        MMSelectedTrack = MMTracks[0]
        MMPlayer.nowPlayingItem = MMSelectedTrack
        selectedTrackIndex = 0
        saveTrackInfoToAppStorage()
      } else
      {  // nothing in the tracks list, nil it all out

        MMSelectedTrack = nil
        MMPlayer.nowPlayingItem = nil
        selectedTrackIndex = nil
      }        
      MMTrackState = .kMusicManagerTrackStopped
    }

  } // updateTrackInfo



  //---------------------------------------------------------
  func saveTrackElapsedTime( saveTime: Double )
  {
    if saveTime < 0.0
    {
      ASelapsedTime = 0.0
    }
    else
    {
      ASelapsedTime = saveTime
    }
  } // saveTrackElapsedTime


  //---------------------------------------------------------
  func saveTracksState()
  {
    savedMMTracks = MMTracks
    savedMMAlbums = MMAlbums

    savedSelectedArtistIndex = selectedArtistIndex
    savedSelectedAlbumIndex = selectedAlbumIndex
    savedSelectedPlaylistIndex = selectedPlaylistIndex
    savedSelectedTrackIndex = selectedTrackIndex

} // saveTracksState



  //---------------------------------------------------------
  func restoreTracksState()
  {
    MMTracks = savedMMTracks
    MMAlbums = savedMMAlbums

    selectedArtistIndex = savedSelectedArtistIndex
    selectedAlbumIndex = savedSelectedAlbumIndex
    selectedPlaylistIndex = savedSelectedPlaylistIndex
    selectedTrackIndex = savedSelectedTrackIndex

            // This is a little tricky.  saveTracksState() was called
            // to save things but the player may have continued to
            // play making the selectedTrackIndex change!  I must go
            // directly to the player and get the current index.

    if MMPlayer.indexOfNowPlayingItem != NSNotFound
    {
      let currentPlayingIndex = 
            MMPlayer.indexOfNowPlayingItem % MMTracks.count

      MMSelectedTrack = MMTracks[currentPlayingIndex]
      selectedTrackIndex = currentPlayingIndex
    }

  } // restoreTracksState


  //---------------------------------------------------------
  // APP STORAGE SUPPORT
  //---------------------------------------------------------

  @AppStorage("ASisPlaylist") var ASisPlaylist : String = "false"
  @AppStorage("ASpersistentID") var ASpersistentID : String = "0"
  @AppStorage("AStrackNumber") var AStrackNumber : String = "0"
  @AppStorage("ASCollectionName") var ASCollectionName : String = ""
  @AppStorage("ASusable") var ASusable : Bool = false
  @AppStorage("ASelapsedTime") var ASelapsedTime : Double = 0.0


  //---------------------------------------------------------
  func saveTrackInfoToAppStorage()
  {
            // If both are nil we are resuming, so just save off the
            // track index.

    if ( selectedPlaylistIndex == nil ) &&
       ( selectedAlbumIndex == nil )
    {
      AStrackNumber = 
          selectedTrackIndex == nil ? "0" : "\(selectedTrackIndex!)"
      return
    }

            // 1. Determine if tracks came from Album or Playlist.  
            //    Store in AppStorage as string var ASisPlaylist

    if ( selectedPlaylistIndex != nil ) &&
       ( selectedAlbumIndex == nil )
    {
      ASisPlaylist = "true"   // is a playlist

      ASCollectionName = 
         getPlaylistName( index: selectedPlaylistIndex! )

            // 2. Retrieve the PersistentID for the Playlist.
            //    Store in AppStorage as string var ASpersistentID

      let t = 
        MMPlaylists[selectedPlaylistIndex!].persistentID

      ASpersistentID = "\(t)"
    } else
    {
      if ( selectedAlbumIndex != nil ) &&
         ( selectedPlaylistIndex == nil )
      {
        ASisPlaylist = "false"  // is an album

      ASCollectionName = 
         getAlbumName( index: selectedAlbumIndex! )

            // 2. Retrieve the PersistentID for the Album.
            //    Store in AppStorage as string var ASpersistentID

        if let item = MMAlbums[selectedAlbumIndex!].representativeItem
        {
          let p = item.albumPersistentID
          ASpersistentID = "\(p)"
        }
        else
        {
          ASusable = false
          return
        }
      }
    }

    AStrackNumber = 
        selectedTrackIndex == nil ? "0" : "\(selectedTrackIndex!)"

    ASusable = true

  } // saveTrackInfoToAppStorage



  //---------------------------------------------------------
  func restoreTracksFromAppStorage()
  {
            // if the persistent ID is "0" or can't be converted to a
            // Int64 then it should not be used.

      let p64 = UInt64( ASpersistentID )
      if p64 == nil
      {
        ASpersistentID = "0"
        ASusable = false
        return
      }

      if p64 == 0
      {
        ASusable = false
        return
      }

            // 1. Get the album based on the persistentID.
    
      if ASisPlaylist != "true"  // album
      {
        let query : MPMediaQuery = MPMediaQuery.albums()

        let tPid = UInt64( p64! )

        let pidPredicate = MPMediaPropertyPredicate(
                         value: tPid,
                         forProperty: MPMediaItemPropertyAlbumPersistentID,
                         comparisonType: .equalTo )

        query.addFilterPredicate( pidPredicate )

      guard let tAlbums = query.collections else 
      {
        return
      }

            // 2. Set the track number.

      selectedTrackIndex = Int( AStrackNumber )

            // 3. Pull the tracks from the playlist or album.
            //    There is an off-chance that their is no album with
            //    that persistent id.  Handle that case.

      if tAlbums.count == 0
      {
        ASusable = false
        return
      }

      MMTracks = tAlbums[0].items

      MMSelectedTrack = MMTracks[selectedTrackIndex!]
      MMPlayer.nowPlayingItem = MMSelectedTrack

           // 4. Pull the saved elapsed time of this track.
           
      MMPlayer.currentPlaybackTime = ASelapsedTime

           // 5. I don't know any of this information, so nil it all
           // out.

      selectedAlbumIndex = nil
      selectedArtistIndex = nil
      selectedPlaylistIndex = nil

      ASusable = true

    } // album

    else  // playlist
    {
            // 1. Get the playlist based on the persistentID.
    
        let query : MPMediaQuery = MPMediaQuery.playlists()

        let tPid = UInt64( p64! )

        let pidPredicate = MPMediaPropertyPredicate(
                         value: tPid,
                        forProperty: MPMediaPlaylistPropertyPersistentID,
                         comparisonType: .equalTo )

        query.addFilterPredicate( pidPredicate )

      guard let tPlaylists = query.collections else 
      {
        return
      }

            // 2. Set the track number.

      selectedTrackIndex = Int( AStrackNumber )

            // 3. Pull the tracks from the playlist.  It's a playlist
            //    so it must be shuffled.  Might as well set the track
            //    index to zero since it's being shuffled!
            //    There is an off-chance that their is no playlist with
            //    that persistent id.  Handle that case.

      if tPlaylists.count == 0
      {
        ASusable = false
        return
      }

      MMTracks = tPlaylists[0].items

      AStrackNumber = "\(selectedTrackIndex!)"

      MMSelectedTrack = MMTracks[selectedTrackIndex!]
      MMPlayer.nowPlayingItem = MMSelectedTrack

           // 4. Pull the saved elapsed time of this track.
           
      MMPlayer.currentPlaybackTime = ASelapsedTime

           // 5. I don't know any of this information, so nil it all
           // out.

      selectedAlbumIndex = nil
      selectedArtistIndex = nil
      selectedPlaylistIndex = nil

      ASusable = true

    } // playlist

  } // retieveTracksFromAppStorage






  //---------------------------------------------------------
  // DEBUG DEBUG DEBUG   Below This Line    DEBUG DEBUG DEBUG
  //---------------------------------------------------------

            //---------------------------------------------------------
            // Oh my, this is horrible.  In dumpMediaItemProperties()
            // below the property debugDescription wraps the results
            // in the word "Optional()".  I don't need to see that, so
            // here's a function that will strip it off and only print
            // the content.
            // 

  func removeOptionalString( from: String ) -> String
  {
    let regex = 
        try? NSRegularExpression(
                 pattern: "Optional\\((.+)\\)" )

    let matches = regex?.matches(
                          in: from,
                     options: [],
                       range: NSRange(
                                 location: 0,
                                   length: from.utf16.count))
    if let match = matches?.first
    {
      let range = match.range( at: 1 )
      if let tRange = Range( range, in: from )
      {
        let name = from[ tRange ]
        return String( name )
      }
    }
    return from

  }  // removeOptionalString


            //---------------------------------------------------------
            // This is a debug function that will print out all the
            // properties for a given MPMediaItem.
            //
  
  func dumpMediaItemProperties( mediaItem : MPMediaItem )
  {
    var tProp : Any?

    print( "\n\n-------------------------------------------\n"  )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyArtist )
    print( "                 MPMediaItemPropertyArtist : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyAlbumArtist )
    print( "            MPMediaItemPropertyAlbumArtist : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyPersistentID )
    print( "           MPMediaItemPropertyPersistentID : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyAlbumPersistentID )
    print( "      MPMediaItemPropertyAlbumPersistentID : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyArtistPersistentID )
    print( "     MPMediaItemPropertyArtistPersistentID : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyAlbumArtistPersistentID )
    print( "MPMediaItemPropertyAlbumArtistPersistentID : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyGenrePersistentID )
    print( "      MPMediaItemPropertyGenrePersistentID : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyComposerPersistentID )
    print( "   MPMediaItemPropertyComposerPersistentID : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyPodcastPersistentID )
    print( "    MPMediaItemPropertyPodcastPersistentID : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyMediaType )
    print( "              MPMediaItemPropertyMediaType : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyTitle )
    print( "                  MPMediaItemPropertyTitle : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyPodcastTitle )
    print( "           MPMediaItemPropertyPodcastTitle : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertySkipCount )
    print( "              MPMediaItemPropertySkipCount : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyRating )
    print( "                 MPMediaItemPropertyRating : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyLastPlayedDate )
    print( "         MPMediaItemPropertyLastPlayedDate : " +
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyUserGrouping )
    print( "           MPMediaItemPropertyUserGrouping : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyBookmarkTime )
    print( "           MPMediaItemPropertyBookmarkTime : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyAlbumTitle )
    print( "             MPMediaItemPropertyAlbumTitle : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyGenre )
    print( "                  MPMediaItemPropertyGenre : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyComposer )
    print( "               MPMediaItemPropertyComposer : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyPlaybackDuration )
    print( "       MPMediaItemPropertyPlaybackDuration : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyAlbumTrackNumber )
    print( "       MPMediaItemPropertyAlbumTrackNumber : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyAlbumTrackCount )
    print( "        MPMediaItemPropertyAlbumTrackCount : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyDiscNumber )
    print( "             MPMediaItemPropertyDiscNumber : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyDiscCount )
    print( "              MPMediaItemPropertyDiscCount : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyArtwork )
    print( "                MPMediaItemPropertyArtwork : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyLyrics )
    print( "                 MPMediaItemPropertyLyrics : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyIsCompilation )
    print( "          MPMediaItemPropertyIsCompilation : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyReleaseDate )
    print( "            MPMediaItemPropertyReleaseDate : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyBeatsPerMinute )
    print( "         MPMediaItemPropertyBeatsPerMinute : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyComments )
    print( "               MPMediaItemPropertyComments : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyAssetURL )
    print( "               MPMediaItemPropertyAssetURL : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyIsCloudItem )
    print( "            MPMediaItemPropertyIsCloudItem : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyLastPlayedDate )
    print( "         MPMediaItemPropertyLastPlayedDate : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyBookmarkTime )
    print( "           MPMediaItemPropertyBookmarkTime : " + 
             removeOptionalString( from: tProp.debugDescription ) )

    tProp = mediaItem.value( 
              forProperty: MPMediaItemPropertyDateAdded )
    print( "              MPMediaItemPropertyDateAdded : " + 
             removeOptionalString( from: tProp.debugDescription ) )

  }

}  // MusicViewModel


//---------------------------------------------------------
// NOTES -
//---------------------------------------------------------
// Here are the media-related properties of an object of 
// type MPMediaItem.
// 
// Condensed from : https://developer.apple.com/documentation/mediaplayer/mpmediaitem#//apple_ref/occ/cl/MPMediaItem
//  
//              albumArtist: String?
//  albumArtistPersistentID: MPMediaEntityPersistentID
//        albumPersistentID: MPMediaEntityPersistentID
//               albumTitle: String?
//          albumTrackCount: Int
//         albumTrackNumber: Int
//                   artist: String?
//       artistPersistentID: MPMediaEntityPersistentID
//                  artwork: MPMediaItemArtwork?
//                 assetURL: URL?
//           beatsPerMinute: Int
//             bookmarkTime: TimeInterval
//              isCloudItem: Bool
//                 comments: String?
//            isCompilation: Bool
//                 composer: String?
//     composerPersistentID: MPMediaEntityPersistentID
//                dateAdded: Date
//                discCount: Int
//               discNumber: Int
//           isExplicitItem: Bool
//                    genre: String?
//        genrePersistentID: MPMediaEntityPersistentID
//           lastPlayedDate: Date?
//                   lyrics: String?
//                mediaType: MPMediaType
//             persistentID: MPMediaEntityPersistentID
//                playCount: Int
//         playbackDuration: TimeInterval
//          playbackStoreID: String
//      podcastPersistentID: MPMediaEntityPersistentID
//             podcastTitle: String?
//        hasProtectedAsset: Bool
//                   rating: Int
//              releaseDate: Date?
//                skipCount: Int
//                    title: String?
//             userGrouping: String?
//---------------------------------------------------------
