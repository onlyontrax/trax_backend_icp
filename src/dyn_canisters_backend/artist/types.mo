

import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
import Result "mo:base/Result";
import IC "../ic.types";

module{

    public type ContentId = Text; // chosen by createVideo
    public type ChunkId = Text; // VideoId # (toText(ChunkNum))
    public type ChunkData = [Nat8];
    public type ProfilePhoto = [Nat8];
    public type CoverPhoto = [Nat8];
    public type GovIdPhoto = [Nat8];
    public type SelfiePhoto = [Nat8];


    public type BucketId = IC.canister_id;
    public type Timestamp = Int; // See mo:base/Time and Time.now()
    public type UserId = Principal; 
    public type CanisterId = IC.canister_id;

    public type Bucket = {
      bucketId : ?BucketId;
      owner : UserId;
    };


    public type Gender = {
        #male;
        #female;
        #other;
    };


    public type InitArtistAccountData = {
        firstName: Text;
        lastName: Text;
        username: Text;
        displayName: Text;  
        gender: Gender;
        userPrincipal: Principal;
        emailAddress: Text;
        country: ?Text;
        dateOfBirth: Nat;
        govIdPhoto: GovIdPhoto;
        selfiePhoto: SelfiePhoto;
    };

    public type ArtistAccountData = {
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
        

    };

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

    public type Content = {
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
}