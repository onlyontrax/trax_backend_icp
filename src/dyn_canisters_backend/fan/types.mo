

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
    public type BucketId = IC.canister_id;

    public type UserId = Principal; 
    public type CanisterId = IC.canister_id;

    public type Bucket = {
      bucketId : ?BucketId;
      owner : UserId;
    };

    public type ProfilePhoto = [Nat8]; //encoded as a PNG file 


    public type FanAccountData = {
        firstName: Text;
        lastName: Text;
        userPrincipal: Principal;
        username: Text;
        displayName: Text;  
        // gender: Gender;
        emailAddress: Text;
        // profilePhoto: ?ProfilePhoto;
    };
}