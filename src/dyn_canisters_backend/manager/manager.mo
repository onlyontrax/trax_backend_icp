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
import T          "../types";
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




actor Manager {

  type FanAccountData                 = T.FanAccountData;
  type ArtistAccountData              = T.ArtistAccountData;
  type UserType                       = T.UserType;
  type UserId                         = T.UserId;
  type CanisterId                     = T.CanisterId;
  type StatusRequest                  = T.StatusRequest;
  type StatusResponse                 = T.StatusResponse;
  
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  private let walletUtils : WalletUtils.WalletUtils = WalletUtils.WalletUtils();

  private let ic : IC.Self = actor "aaaaa-aa";

  let { ihash; nhash; thash; phash; calcHash } = Map;

  stable var numOfFanAccounts: Nat = 0;
  stable var numOfArtistAccounts: Nat = 0;
  stable var MAX_CANISTER_SIZE: Nat = 48_000_000_000; // <-- approx. 48MB
  stable var CYCLE_AMOUNT : Nat = 1_000_000_000_000;

  var userToCanisterMap = Map.new<Text, (Principal, Nat64)>(thash);
  var fanAccountsMap = Map.new<UserId, CanisterId>(phash);
  var artistAccountsMap = Map.new<UserId, CanisterId>(phash);






// #region - CREATE ACCOUNT CANISTERS
  public shared({caller}) func createProfileFan(accountData: FanAccountData) : async (Principal){
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    await createCanister(accountData.userPrincipal, #fan, ?accountData, null);
  };  



  public shared({caller}) func createProfileArtist(accountData: ArtistAccountData) : async (Principal){
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    await createCanister(accountData.userPrincipal, #artist, null, ?accountData);
  };  



  private func createCanister(userID: Principal, userType: UserType, accountDataFan: ?FanAccountData, accountDataArtist: ?ArtistAccountData): async (Principal) {
    Debug.print(debug_show Principal.toText(userID));
    
    Cycles.add(CYCLE_AMOUNT);

    var canisterId: ?Principal = null;

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
      };
    };

    let bal = getCurrentCycles();
    Debug.print("Cycles Balance After Canister Creation: " #debug_show bal);

    if(bal < CYCLE_AMOUNT){
       // notify frontend that cycles is below threshold
    };

    switch (canisterId) {
      case null {
        throw Error.reject("Bucket init error, your account canister could not be created.");
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
        }else{   
          let b = Map.put(artistAccountsMap, phash, userID, canisterId);
          numOfArtistAccounts := numOfArtistAccounts + 1;
        };
        return canisterId;
      };
    };
  };
// #endregion






// #region - FETCH STATE
  public query func getTotalFanAccounts() :  async Nat{    
    numOfFanAccounts   
  };  



  public query func getTotalArtistAccounts() :  async Nat{   
    numOfArtistAccounts   
  }; 



  public shared({caller}) func getFanAccountEntries() : async [(Principal, Principal)]{    
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    Iter.toArray(Map.entries(fanAccountsMap));    
  };



  public query func getArtistAccountEntries() : async [(Principal, Principal)]{   
    Iter.toArray(Map.entries(artistAccountsMap));    
  };



  public shared({caller}) func getCanisterFan(fan: Principal) : async (?Principal){    
    assert(caller == fan or Utils.isManager(caller));
    Map.get(fanAccountsMap, phash, fan);   
  };



  public shared({caller}) func getCanisterArtist(artist: Principal) : async (?Principal){   
    assert(caller == artist or Utils.isManager(caller));
    Map.get(artistAccountsMap, phash, artist);    
  };



  public shared({caller}) func getOwnerOfFanCanister(canisterId: Principal) : async (?UserId){ 
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    for((key, value) in Map.entries(fanAccountsMap)){
      var fan: ?UserId = ?key;
      var canID = value;
      if (canID == canisterId){
        return fan;
      };
    };
    return null;
  };



  public shared({caller}) func getOwnerOfArtistCanister(canisterId: Principal) : async (?UserId){ 
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    for((key, value) in Map.entries(artistAccountsMap)){
      var artist: ?UserId = ?key;
      var canID = value;
      if (canID == canisterId){
        return artist;
      };
    };
    return null;
  };



  public shared({caller}) func getAvailableMemoryCanister(canisterId: Principal) : async ?Nat{
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };

    let can = actor(Principal.toText(canisterId)): actor { 
        getStatus: (?StatusRequest) -> async ?StatusResponse;
    };

    let request : StatusRequest = {
        cycles: Bool = false;
        heap_memory_size: Bool = false; 
        memory_size: Bool = true;
    };
    
    switch(await can.getStatus(?request)){
      case(?status){
        switch(status.memory_size){
          case(?memSize){
            let availableMemory: Nat = MAX_CANISTER_SIZE - memSize;
            return ?availableMemory;
          };
          case null null;
        };
      };
      case null null;
    };
  };




  public func getStatus(request: ?StatusRequest): async ?StatusResponse {
      switch(request) {
          case (null) {
              return null;
          };
          case (?_request) {
              var cycles: ?Nat = null;
              if (_request.cycles) {
                  cycles := ?getCurrentCycles();
              };
              var memory_size: ?Nat = null;
              if (_request.memory_size) {
                  memory_size := ?getCurrentMemory();
              };
              var heap_memory_size: ?Nat = null;
              if (_request.heap_memory_size) {
                  heap_memory_size := ?getCurrentHeapMemory();
              };
              return ?{
                  cycles = cycles;
                  memory_size = memory_size;
                  heap_memory_size = heap_memory_size;
              };
          };
      };
  };



  private func getCurrentHeapMemory(): Nat {
    Prim.rts_heap_size();
  };



  private func getCurrentMemory(): Nat {
    Prim.rts_memory_size();
  };



  private func getCurrentCycles(): Nat {
    Cycles.balance();
  };



  public shared({caller}) func cyclesBalance() : async (Nat) {
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    return walletUtils.cyclesBalance();
  };
// #endregion






// #region - UTILS
  public shared({caller}) func changeCycleAmount(amount: Nat) : (){  // utils based 
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    CYCLE_AMOUNT := amount;   
  };



  public shared({caller}) func changeCanisterSize(newSize: Nat) : (){    // utils based
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    MAX_CANISTER_SIZE := newSize;
  };



 public shared({caller}) func transferOwnershipFan(currentOwner: Principal, newOwner: Principal) : async (){
    assert(caller == currentOwner or Utils.isManager(caller));
    switch(Map.get(fanAccountsMap, phash, currentOwner)){
      case(?canisterId){
        Map.delete(fanAccountsMap, phash, currentOwner);
        let a = Map.put(fanAccountsMap, phash, newOwner, canisterId);

      }; case null throw Error.reject("This fan account doesnt exist");
    };
  };



  public shared({caller}) func transferOwnershipArtist(currentOwner: Principal, newOwner: Principal) : async (){
    assert(caller == currentOwner or Utils.isManager(caller));
    switch(Map.get(artistAccountsMap, phash, currentOwner)){
      case(?canisterId){
        let update = Map.replace(artistAccountsMap, phash, newOwner, canisterId);
      }; case null throw Error.reject("This artist account doesnt exist");
    };
  };



  public shared({caller}) func transferCycles(canisterId : Principal, amount : Nat) : async () {
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    await walletUtils.transferCycles(canisterId, amount);
  };



  public shared({caller}) func deleteContentCanister(canId: Principal): async(){
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    let canisterId :?Principal = ?(canId);
    let res = await canisterUtils.deleteCanister(canisterId);
  };


  public shared({caller}) func deleteAccountCanister(user: UserId, canisterId: Principal, userType: UserType) :  async (Bool){
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
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
          let res = await canisterUtils.deleteCanister(?canisterId);
          return true;
        };
        case null false
      }
    }
  };


  public shared({caller}) func installCode(canisterId : Principal, owner : Blob, wasmModule : Blob) : async () {
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not the manager. " # Principal.toText(caller));
    };
    await canisterUtils.installCode(canisterId, owner, wasmModule);
  };
  // #endregion
};
