import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
import Result "mo:base/Result";
import IC "../ic.types";

module Types {

    public type BucketId = IC.canister_id;

    public type UserId = Principal; 
    public type CanisterId = IC.canister_id;
    
    
    public type Timestamp = Int; // See mo:base/Time and Time.now()
    
    public type VideoId = Text; // chosen by createVideo
    public type ChunkId = Text; // VideoId # (toText(ChunkNum))
    
    public type ProfilePhoto = [Nat8]; // encoded as a PNG file
    public type VideoPic = [Nat8]; // encoded as a PNG file
    public type ChunkData = [Nat8]; // encoded as ???

    public type Bucket = {
      bucketId : ?BucketId;
      owner : UserId;
    };


    public type FanAccount = {
        firstName: Text;
        lastName: Text;
        username: Text;
        displayName: Text;  
        // gender: Gender;
        emailAddress: Text;
    };

    public type FanAccountData = {
        firstName: Text;
        lastName: Text;
        userPrincipal: Principal;
        username: Text;
        displayName: Text;  
        // gender: Gender;
        emailAddress: Text;
        createdAt: Int;
        profilePhoto: ?ProfilePhoto;
    };

    public type Gender = {
        #male;
        #female;
        #other;
    };

    public type UserType = {
        #fan;
        #artist;
    };


    public type ArtistAccountData = {
        firstName: Text;
        lastName: Text;
        username: Text;
        displayName: Text;  
        gender: Gender;
        userPrincipal: Principal;
        emailAddress: Text;
        country: Text;
        dateOfBirth: Nat;
        bio: ?Text;
    };

    public type Role = {
      // caller is a fan
      #fan;
      // caller is the admin
      #admin;
      // caller is artist
      #artist
    };

    public type Content = {

    }
}