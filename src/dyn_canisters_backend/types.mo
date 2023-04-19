import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
import Result "mo:base/Result";
import IC "./ic.types";

module Types {

    public type UserId = Principal; 
    public type CanisterId = IC.canister_id;
    
    public type Timestamp = Int;
    
    public type ContentId = Text; // chosen by createVideo
    public type VideoId = Text; // chosen by createVideo
    public type ChunkId = Text; // VideoId # (toText(ChunkNum))
    
    public type ProfilePhoto = [Nat8]; // encoded as a PNG file
    public type CoverPhoto = [Nat8];
    public type VideoPic = [Nat8]; // encoded as a PNG file
    public type ChunkData = [Nat8]; // encoded as ???


    public type ContentType ={
      #video;
      #photo;
      #audio;
    };


    public type ContentInit = {
      userId : UserId;
      name: Text;
      createdAt : Timestamp;
      caption: Text;
      tags: [Text];
      chunkCount: Nat;
      contentType: ContentType;
    };

    public type ContentInfo = {
      contentId : Text;
      userId : UserId;
      createdAt : Timestamp;
      uploadedAt : Timestamp;
      caption: Text;
      tags: [Text];
      viewCount: Nat;
      name: Text;
      chunkCount: Nat;
      contentType: ContentType;
    };


    public type FanAccountData = {
        userPrincipal: Principal;
        createdAt: Timestamp;
        profilePhoto: ?ProfilePhoto;
    };

    public type UserType = {
        #fan;
        #artist;
    };

    public type ArtistAccountData = {
        createdAt: Timestamp;
        userPrincipal: Principal;
        profilePhoto: ?ProfilePhoto;
        coverPhoto: ?CoverPhoto;
    };

    public type Role = {
      // caller is a fan
      #fan;
      // caller is the admin
      #admin;
      // caller is artist
      #artist;
    };

    /// Video.
  public type Video = {
    userId : UserId;
    createdAt : Timestamp;
    uploadedAt : Timestamp;
    caption: Text;
    tags: [Text];
    viewCount: Nat;
    name: Text;
    chunkCount: Nat;
  };

  public type Photo = {
    userId : UserId;
    createdAt : Timestamp;
    uploadedAt : Timestamp;
    caption: Text;
    tags: [Text];
    viewCount: Nat;
    name: Text;
    chunkCount: Nat;
  };

  public type Audio = {
    userId : UserId;
    createdAt : Timestamp;
    uploadedAt : Timestamp;
    caption: Text;
    tags: [Text];
    viewCount: Nat;
    name: Text;
    chunkCount: Nat;
  };

  public type StatusRequest = {
        cycles: Bool;
        memory_size: Bool;
        heap_memory_size: Bool;
    };

    public type StatusResponse = {
        cycles: ?Nat;
        memory_size: ?Nat;
        heap_memory_size: ?Nat;
    }; 
}