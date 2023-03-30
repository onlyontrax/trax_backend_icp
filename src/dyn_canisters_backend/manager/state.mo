import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

// import non-base primitives

// types in separate file
import Types "types";

/// Internal CanCan canister state.
module {

  // Our representation of finite mappings.
  public type MapShared<X, Y> = Trie.Trie<X, Y>;
  public type Map<X, Y> = TrieMap.TrieMap<X, Y>;

  public type ChunkId = Types.ChunkId;
  public type ChunkData = Types.ChunkData;

  public module Event {

    public type CreateProfile = {
      userName : Text;
      pic: ?Types.ProfilePic;
    };

    public type CreateVideo = {
      info : Types.VideoInit;
    };


    public type EventKind = {
      #reset : Types.TimeMode;
      #createProfile : CreateProfile;
      #createVideo : CreateVideo;
      #likeVideo : LikeVideo;
      #superLikeVideo : SuperLikeVideo;
      #superLikeVideoFail : SuperLikeVideoFail;
      #rewardPointTransfer : RewardPointTransfer;
      #emitSignal : Signal;
      #abuseFlag : AbuseFlag;
    };

    public type Event = {
      id : Nat; // unique ID, to avoid using time as one (not always unique)
      time : Int; // using mo:base/Time and Time.now() : Int
      kind : EventKind;
    };

    public func equal(x:Event, y:Event) : Bool { x == y };
    public type Log = SeqObj.Seq<Event>;
  };

  /// State (internal CanCan use only).
  ///
  /// Not a shared type because of OO containers and HO functions.
  /// So, cannot send in messages or store in stable memory.
  ///
  public type State = {
    access : Access.Access;

    /// event log.
    eventLog : Event.Log;
    var eventCount : Nat;

    /// all profiles.
    profiles : Map<Types.UserId, Profile>;

    /// all profile pictures (aka thumbnails).
    profilePics : Map<Types.UserId, Types.ProfilePic>;

    rewards: Map<Types.UserId, Nat>;

    messages: Rel<Types.UserId, Types.Message>;

    /// all videos.
    videos : Map<Types.VideoId, Video>;

    /// all video pictures (aka thumbnails).
    videoPics : Map<Types.VideoId, Types.VideoPic>;

    /// follows relation: relates profiles and profiles.
    follows : Rel<Types.UserId, Types.UserId>;

    /// likes relation: relates profiles and videos.
    likes : Rel<Types.UserId, Types.VideoId>;

    /// super likes relation: relates profiles and videos.
    superLikes : Rel<Types.UserId, Types.VideoId>;

    /// uploaded relation: relates profiles and videos.
    uploaded : Rel<Types.UserId, Types.VideoId>;

    /// all chunks.
    chunks : Map<Types.ChunkId, ChunkData>;

    /// Users may place an abuse flag on videos and other users.
    abuseFlagUsers : Rel<Types.UserId, Types.UserId>;
    abuseFlagVideos : Rel<Types.UserId, Types.VideoId>;
  };

  // (shared) state.
  //
  // All fields have stable types.
  // This type can be stored in stable memory, for upgrades.
  //
  // All fields have shared types.
  // This type can be sent in messages.
  // (But messages may not benefit from tries; should instead use arrays).
  //
  public type StateShared = {
    /// all profiles.
    fanProfiles : MapShared<Types.UserId, Profile>;

    artistProfiles : MapShared<Types.ArtistId, ArtistProfile>;

    /// all users. see andrew for disambiguation
    users : MapShared<Principal, Types.UserId>;

    /// all videos.
    videos : MapShared<Types.VideoId, Video>;

    /// uploaded relation: relates profiles and videos.
    uploaded : RelShared<Types.UserId, Types.VideoId>;

    /// all chunks.
    chunks : MapShared<Types.ChunkId, ChunkData>;
  };

  /// User profile.
  public type FanProfile = {
    firstName: Text;
    lastName: Text;
    username: Text;
    displayName: Text;  
    userPrincipal: Principal;
    // gender: Gender;
    emailAddress: Text;
    createdAt : ?Types.Timestamp;
    profilePhoto: ?Nat;
  };

  public type ArtistProfile = {
    firstName: Text;
    lastName: Text;
    username: Text;
    displayName: Text;  
    // gender: Gender;
    userPrincipal: Principal;
    emailAddress: Text;
    country: Text;
    dateOfBirth: Nat;
    bio: Text;
    createdAt : ?Types.Timestamp;
    coverPhoto: ?Nat;
  };

  /// Video.
  public type Video = {
    userId : Types.UserId;
    createdAt : Types.Timestamp;
    uploadedAt : Types.Timestamp;
    caption: Text;
    tags: [Text];
    viewCount: Nat;
    name: Text;
    chunkCount: Nat;
  };

  public type Photo = {
    userId : Types.UserId;
    createdAt : Types.Timestamp;
    uploadedAt : Types.Timestamp;
    caption: Text;
    tags: [Text];
    viewCount: Nat;
    name: Text;
    chunkCount: Nat;
  };

  public type Audio = {
    userId : Types.UserId;
    createdAt : Types.Timestamp;
    uploadedAt : Types.Timestamp;
    caption: Text;
    tags: [Text];
    viewCount: Nat;
    name: Text;
    chunkCount: Nat;
  };
}