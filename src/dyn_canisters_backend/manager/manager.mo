import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import IC "../ic.types";
import FanBucket "../fan/fan-bucket";
import ArtistBucket "../artist/artist-account-bucket";
import Nat "mo:base/Nat";
import Map  "mo:stable-hash-map/Map";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import T          "./types";
import Hash       "mo:base/Hash";
import Nat32      "mo:base/Nat32";
import Nat64      "mo:base/Nat64";
import Iter       "mo:base/Iter";
import Float      "mo:base/Float";
import Time       "mo:base/Time";
import Int        "mo:base/Int";
import Result     "mo:base/Result";
import Blob       "mo:base/Blob";
import Array      "mo:base/Array";
import Buffer     "mo:base/Buffer";
import Trie       "mo:base/Trie";
import TrieMap    "mo:base/TrieMap";
import CanisterUtils "../utils/canister.utils";
import WalletUtils "../utils/wallet.utils";
import Utils "../utils/utils";
import Prim "mo:⛔";

// 1. User creates account through sign up page 
// 2. Once completed userID (from frontend), principal (if the user has one), and initial information and documents,  will be sent to the contract as params
// 3. A new canister will be initialised with the data given 
// 4. Information about the owner of the canister will be stored in the hashmap of the mananger canister
// 5. 

// Hybrid web application: users who sign up using NFID will have their data stored on ICP, users who arent will have their data stored on AWS

actor Manager {

  type FanAccountData                 = T.FanAccount;
  type ArtistAccountData              = T.ArtistAccountData;
  type UserType                       = T.UserType;
  type UserId                         = T.UserId;
  type CanisterId                     = T.CanisterId;
  // private stable var canisterId: ?Principal = null;
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  private let walletUtils : WalletUtils.WalletUtils = WalletUtils.WalletUtils();

  private let ic : IC.Self = actor "aaaaa-aa";

     let { ihash; nhash; thash; phash; calcHash } = Map;

  // private type fan_bucket = FanBucket.FanBucket;

  stable var numOfFanAccounts: Nat = 0;
  stable var numOfArtistAccounts: Nat = 0;
  stable var MAX_CANISTER_SIZE: Nat = 48_000_000_000; // <-- approx. 40MB
  stable var CYCLE_AMOUNT : Nat = 1_000_000_000_000;

//  let fanBucket : FanBucket.FanBucket = FanBucket.FanBucket();

  var userToCanisterMap = Map.new<Text, (Principal, Nat64)>(thash);

  var fanAccountsMap = Map.new<UserId, CanisterId>(phash);
  var artistAccountsMap = Map.new<UserId, CanisterId>(phash); // array of canister id 


  public query func getTotalFanAccounts() :  async Nat{    numOfFanAccounts    };  
  public query func getTotalArtistAccounts() :  async Nat{   numOfArtistAccounts   }; 
  public query func getFanAccountEntries() : async [(Principal, Principal)]{    Iter.toArray(Map.entries(fanAccountsMap));     };
  public query func getArtistAccountEntries() : async [(Principal, Principal)]{   Iter.toArray(Map.entries(artistAccountsMap));    };
  public query func getCanisterFan(fan: Principal) : async (?Principal){    Map.get(fanAccountsMap, phash, fan);   };
  public query func getCanisterArtist(artist: Principal) : async (?Principal){   Map.get(artistAccountsMap, phash, artist);    };

  public func changeCycleAmount(amount: Nat) : (){
    CYCLE_AMOUNT := amount;
  };

  public func changeCanisterSize(newSize: Nat) : (){
    MAX_CANISTER_SIZE := newSize;
  };


  public query func getOwnerOfFanCanister(canisterId: Principal) : async (?UserId){ 
    
    for((key, value) in Map.entries(fanAccountsMap)){
      var fan: ?UserId = ?key;
      var canID = value;
      if (canID == canisterId){
        return fan;
      };
    };

    return null;
  };

  public query func getOwnerOfArtistCanister(canisterId: Principal) : async (?UserId){ 
    
    for((key, value) in Map.entries(artistAccountsMap)){
      var artist: ?UserId = ?key;
      var canID = value;
      if (canID == canisterId){
        return artist;
      };
    };

    return null;
  };


  public func transferOwnershipFan(currentOwner: Principal, newOwner: Principal) : async (){
    switch(Map.get(fanAccountsMap, phash, currentOwner)){
      case(?canisterId){
        Map.delete(fanAccountsMap, phash, currentOwner);
        let a = Map.put(fanAccountsMap, phash, newOwner, canisterId);

      }; case null throw Error.reject("This fan account doesnt exist");
    }
  };

  public func transferOwnershipArtist(currentOwner: Principal, newOwner: Principal) : async (){
    switch(Map.get(artistAccountsMap, phash, currentOwner)){
      case(?canisterId){
        let update = Map.replace(artistAccountsMap, phash, newOwner, canisterId);
      }; case null throw Error.reject("This artist account doesnt exist");
    };
  };

  public func createProfileFan(accountData: FanAccountData) : async (Principal){
    await createCanister(accountData.userPrincipal, #fan, ?accountData, null);
  };  

  public  func createProfileArtist(accountData: ArtistAccountData) : async (Principal){
    await createCanister(accountData.userPrincipal, #artist, null, ?accountData);
  };  

  private func createCanister(userID: Principal, userType: UserType, accountDataFan: ?FanAccountData, accountDataArtist: ?ArtistAccountData): async (Principal) {
    // assert((accountDataArtist != null) && (accountDataFan != null));
    Debug.print(debug_show Principal.toText(userID));
    Cycles.add(CYCLE_AMOUNT);

    var canisterId: ?Principal = null;
    // let {canister_id} = await ic.create_canister({settings = null});

    if(userType == #fan){
      switch(Map.get(fanAccountsMap, phash, userID)){
        case(?exists){
          throw Error.reject("This principal is already associated with an account");
        }; case null{
          let b = await FanBucket.FanBucket(accountDataFan, userID);
          canisterId := ?(Principal.fromActor(b));
        }
      }
      
    }else{
      switch(Map.get(artistAccountsMap, phash, userID)){
        case(?exists){
          throw Error.reject("This principal is already associated with an account");
        }; case null {
          let b = await ArtistBucket.ArtistBucket(accountDataArtist, userID);
          canisterId := ?(Principal.fromActor(b));
        }
      }
      
    };

  
    switch (canisterId) {
      case null {
        throw Error.reject("Bucket init error");
      };
      case (?canisterId) {
        let self: Principal = Principal.fromActor(Manager);

        let controllers: ?[Principal] = ?[canisterId, userID, self];

        await ic.update_settings(({canister_id = canisterId; 
          settings = {
            controllers = controllers;
            freezing_threshold = null;
            memory_allocation = null;
            compute_allocation = null;
          }}));

        if(userType == #fan){   
          let a = Map.put(fanAccountsMap, phash, userID, canisterId);
          numOfFanAccounts := numOfFanAccounts + 1;
        }
        else{   
          let b = Map.put(artistAccountsMap, phash, userID, canisterId);
          numOfArtistAccounts := numOfArtistAccounts + 1;
        };
        return canisterId;
      };
    };
  };


  public func getCanisterMemoryAvailable(canisterId: Principal) : async (Nat){
    let can = actor(Principal.toText(canisterId)): actor { 
        getMemoryStatus: () -> async (Nat, Nat);
    };
    
    let memStatus = await can.getMemoryStatus();
    let availableMemory: Nat = MAX_CANISTER_SIZE - memStatus.0;
    return availableMemory;
  };





  public func deleteCanister(user: UserId, canisterId: Principal, userType: UserType) :  async (Bool){
    if(userType == #fan){
      switch(Map.get(fanAccountsMap, phash, user)){
        case(?fanAccount){
          Map.delete(fanAccountsMap, phash, user);
          let res = await canisterUtils.deleteCanister(?canisterId);
          return true;
        };
        case null false
      }
    }else{
       switch(Map.get(artistAccountsMap, phash, user)){
        case(?artistAccount){
          Map.delete(artistAccountsMap, phash, user);
          return true;
        };
        case null false
      }
    }
  };

  public func getMemoryStatus() : async (Nat, Nat){
    let memSize = Prim.rts_memory_size();
    let heapSize = Prim.rts_heap_size();
    return (memSize, heapSize);
  }; 



   public  func installCode(canisterId : Principal, owner : Blob, wasmModule : Blob) : async () {
    // if (not Utils.isAdmin(caller)) {
      // throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    // };

    await canisterUtils.installCode(canisterId, owner, wasmModule);
  };

  public shared func cyclesBalance() : async (Nat) {
    // if (not Utils.isAdmin(caller)) {
    //   throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    // };

    return walletUtils.cyclesBalance();
  };
};
