import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import IC "../ic.types";
import FanBucket "../fan/fan-bucket";
import ArtistBucket "../artist/artist-bucket";
import Nat "mo:base/Nat";
import Map "mo:base/HashMap";
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

// 1. User creates account through sign up page 
// 2. Once completed userID (from frontend), principal (if the user has one), and initial information and documents,  will be sent to the contract as params
// 3. A new canister will be initialised with the data given 
// 4. Information about the owner of the canister will be stored in the hashmap of the mananger canister
// 5. 

// Hybrid web application: users who sign up using NFID will have their data stored on ICP, users who arent will have their data stored on AWS

actor Manager {

  type FanAccountData                 = T.FanAccountData;
  type ArtistAccountData              = T.ArtistAccountData;
  type UserType                       = T.UserType;
  type UserId                         = T.UserId;
  type CanisterId                     = T.CanisterId;
  // private stable var canisterId: ?Principal = null;
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  private let walletUtils : WalletUtils.WalletUtils = WalletUtils.WalletUtils();

  private let ic : IC.Self = actor "aaaaa-aa";

  // private type fan_bucket = FanBucket.FanBucket;

  stable var numOfFanAccounts: Nat = 0;
  stable var numOfArtistAccounts: Nat = 0;

//  let fanBucket : FanBucket.FanBucket = FanBucket.FanBucket();

  var userToCanisterMap = Map.HashMap<Text, (Principal, Nat64)>(1, Text.equal, Text.hash);

  var fanAccountsMap = Map.HashMap<UserId, CanisterId>(1, Principal.equal, Principal.hash);
  var artistAccountsMap = Map.HashMap<UserId, CanisterId>(1, Principal.equal, Principal.hash);


  public query func getTotalFanAccounts() :  async Nat{    numOfFanAccounts    };  
  public query func getTotalArtistAccounts() :  async Nat{   numOfArtistAccounts   };
  public query func getFanAccountEntries() : async [(Principal, Principal)]{    Iter.toArray(fanAccountsMap.entries());     };
  public query func getArtistAccountEntries() : async [(Principal, Principal)]{   Iter.toArray(artistAccountsMap.entries());    };
  public query func getCanisterFan(fan: Principal) : async (?Principal){    fanAccountsMap.get(fan);   };
  public query func getCanisterArtist(artist: Principal) : async (?Principal){   artistAccountsMap.get(artist);    };

  public query func getOwnerOfFanCanister(canisterId: Principal) : async (?UserId){ 
    var fanID : ?UserId = null;
    for(fan in fanAccountsMap.entries()){
      var canID = fan.1;
      if (canID == canisterId){
        fanID := ?fan.0;
      };
    };
    return fanID;
  };


  public func transferOwnershipFan(currentOwner: Principal, newOwner: Principal) : async (){
    switch(fanAccountsMap.get(currentOwner)){
      case(?canisterId){
        let update = fanAccountsMap.delete(currentOwner);
        fanAccountsMap.put(newOwner, canisterId);

      }; case null throw Error.reject("This fan account doesnt exist");
    }
  };

  public func transferOwnershipArtist(currentOwner: Principal, newOwner: Principal) : async (){
    switch(artistAccountsMap.get(currentOwner)){
      case(?canisterId){
        let update = artistAccountsMap.replace(newOwner, canisterId)
      }; case null throw Error.reject("This artist account doesnt exist");
    }
  };

  public func createProfileFan(accountData: FanAccountData) : async (Principal){
    await createCanister(accountData.userPrincipal, #fan, ?accountData, null);
  };  

  public  func createProfileArtist(accountData: ArtistAccountData) : async (Principal){
    await createCanister(accountData.userPrincipal, #artist, null, ?accountData);
  };  

  private func createCanister(userID: Principal, userType: UserType, accountDataFan: ?FanAccountData, accountDataArtist: ?ArtistAccountData): async (Principal) {
    // assert((accountDataArtist != null) && (accountDataFan != null));
    Debug.print(debug_show userID);
    Cycles.add(1_000_000_000_000);

    var canisterId: ?Principal = null;
    // let {canister_id} = await ic.create_canister({settings = null});

    if(userType == #fan){
      switch(fanAccountsMap.get(userID)){
        case(?exists){
          throw Error.reject("This principal is already associated with an account");
        }; case null{
          let b = await FanBucket.FanBucket(accountDataFan, userID);
          
            canisterId := ?(Principal.fromActor(b));
        }
      }
      
    }else{
      switch(artistAccountsMap.get(userID)){
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
          fanAccountsMap.put(userID, canisterId);
          numOfFanAccounts := numOfFanAccounts + 1;
        }
        else{   
          artistAccountsMap.put(userID, canisterId);
          numOfArtistAccounts := numOfArtistAccounts + 1;
        };

        return canisterId;
      };
    };
    
  };



  public func deleteCanister(user: UserId, canisterId: Principal, userType: UserType) :  async (Bool){
    if(userType == #fan){
      switch(fanAccountsMap.get(user)){
        case(?fanAccount){
          let removedFan = fanAccountsMap.remove(user);
          let res = await canisterUtils.deleteCanister(?canisterId);
          return true;
        };
        case null false
      }
    }else{
       switch(artistAccountsMap.get(user)){
        case(?artistAccount){
          let removedArtist = artistAccountsMap.remove(user);
          return true;
        };
        case null false
      }
    }
  };



   public  func installCode(canisterId : Principal, owner : Blob, wasmModule : Blob) : async () {
    // if (not Utils.isAdmin(caller)) {
      // throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    // };

    await canisterUtils.installCode(canisterId, owner, wasmModule);
  };

  public shared query func cyclesBalance() : async (Nat) {
    // if (not Utils.isAdmin(caller)) {
    //   throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    // };

    return walletUtils.cyclesBalance();
  };
};