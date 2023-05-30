import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
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
import CanisterUtils  "../utils/canister.utils";
import Prim "mo:⛔";
import Map  "mo:stable-hash-map/Map";
// import ContentStorageBucket "./artist-bucket";
import ArtistContentBucket "./artist-content-bucket";
import B "mo:stable-buffer/StableBuffer";
import Utils              "../utils/utils";
import WalletUtils        "../utils/wallet.utils";
// import ArtistAccountBucket "artist-account-bucket";
import IC "../ic.types";
// import Manager "canister:dyn_canisters_backend";
import Env "../env";
// import Manager "../manager/manager";




 shared({caller = manager}) actor class ArtistBucket(accountInfo: ?T.ArtistAccountData, artistAccount: Principal) = this {

  let { ihash; nhash; thash; phash; calcHash } = Map;

  type ArtistAccountData         = T.ArtistAccountData;
  type UserId                    = T.UserId;
  type ContentInit               = T.ContentInit;
  type ContentId                 = T.ContentId;
  type ContentData               = T.ContentData;
  type ChunkId                   = T.ChunkId;
  type CanisterId                = T.CanisterId;
  type StatusRequest             = T.StatusRequest;
  type StatusResponse             = T.StatusResponse;
  type ManagerId = Principal;

  // var managerId: ManagerId;
  // type Manager = Manager.Manager;
  
  stable var MAX_CANISTER_SIZE: Nat =     48_000_000_000; // <-- approx. 40GB
  // stable var CYCLE_AMOUNT : Nat     =  1_000_000_000_000;
  stable var CYCLE_AMOUNT : Nat = 100_000_000_000;
  let maxCycleAmount = 20_000_000_000_000;
  let limit                         = 1_000_000_000_000;


  private let ic : IC.Self = actor "aaaaa-aa";

  stable var VERSION: Nat = 1;
  stable var initialised: Bool = false;

  
  stable var owner: Principal = artistAccount;

  private let walletUtils : WalletUtils.WalletUtils = WalletUtils.WalletUtils();
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();

  private let artistData = Map.new<UserId, ArtistAccountData>(phash);
  private let contentToCanister = Map.new<ContentId, CanisterId>(thash);

  private let contentCanisterIds = B.init<CanisterId>();


  // public query func getCreatorPrincipal() : async (Principal){
  //   creator;
  // };


  public query func getCanisterOfContent(contentId: ContentId) : async ?(CanisterId){
    Map.get(contentToCanister, thash, contentId);
  };



  public query func getAllContentCanisters() : async [CanisterId]{
    B.toArray(contentCanisterIds);
  };



  public func getAvailableMemoryCanister(canisterId: Principal) : async ?Nat{
    let can = actor(Principal.toText(canisterId)): actor { 
        getStatus: (?StatusRequest) -> async ?StatusResponse;
    };

    let request : StatusRequest = {
        cycles: Bool = false;
        heap_memory_size: Bool = false; 
        memory_size: Bool = true;
    };
    
    // let memStatus: ?StatusResponse = await can.getStatus(?request);
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



  public func initCanister() :  async(Bool) { // Initialise new cansiter. This is called only once after the account has been created. I
    assert(initialised == false);
    switch(accountInfo){
      case(?info){
        let a = Map.put(artistData, phash, artistAccount, info);
        initialised := true;
        return true;
      };case null return false;
    };
  };



  public func updateProfileInfo(caller: UserId, info: ArtistAccountData) : async (Bool){
    assert(owner == caller);
    switch(Map.get(artistData, phash, caller)){
      case(?exists){
        var update = Map.replace(artistData, phash, caller, info);
        true
      };case null false;
    };
  };


  public shared ({caller}) func transferFreezingThresholdCycles() : async () {
    if (not Utils.isManager(caller)) {
      throw Error.reject("Unauthorized access. Caller is not a manager.");
    };

    await walletUtils.transferFreezingThresholdCycles(caller);
  };



  



  public func getProfileInfo(user: UserId) : async (?ArtistAccountData){
    // assert(owner == msg.caller);
    Map.get(artistData, phash, user);
  };




  public shared({caller}) func deleteAccount(user: Principal): async(){
    let canisterId :?Principal = ?(Principal.fromActor(this));
    let res = await canisterUtils.deleteCanister(canisterId);
  };




  public func removeContent(contentId: ContentId, chunkNum : Nat) : async () {
    switch(Map.get(contentToCanister, thash, contentId)){
      case(?canID){
        let can = actor(Principal.toText(canID)): actor { 
          removeContent: (ContentId, Nat) -> async ();
        };
        await can.removeContent(contentId, chunkNum);
        let a = Map.remove(contentToCanister, thash, contentId);
      };
      case null { };
    };
  };
  


  public  func createContent(i : ContentInit) : async ?(ContentId, Principal) {
    // assert();
    // if(caller != i.userId){
    //   throw Error.reject("caller is not the publisher");
    // };

    // var canIdToReturn : ?Principal;
    // check if there is free space in current canister 
    // let index : Nat = contentCanisterIds.size();
    // let currCanID = contentCanisterIds.get(index);

    var uploaded : Bool = false;
    for(canisters in B.vals(contentCanisterIds)){
      Debug.print("canister: " # debug_show canisters);

      // Debug.print("currCanID: " #debug_show currCanID);

      let availableMemory: ?Nat = await getAvailableMemoryCanister(canisters);

      switch(await getAvailableMemoryCanister(canisters)){
        case(?availableMemory){
          if(availableMemory > i.size){ // replace hardcoded val with size of ingress message

          let can = actor(Principal.toText(canisters)): actor { 
            createContent: (ContentInit, Nat) -> async (?ContentId);
          };

          switch(await can.createContent(i, i.size)){
            case(?contentId){ 
              let a = Map.put(contentToCanister, thash, contentId, canisters);
              uploaded := true;
              return ?(contentId, canisters);
            };
            case null { 
              return null
            };
          };
        };

        };
        case null { 
          return null
        };
      };
    };

    if(uploaded == false){
      switch(await createStorageCanister(i.userId)){
        case(?canID){
          B.add(contentCanisterIds, canID);
          let newCan = actor(Principal.toText(canID)): actor { 
            createContent: (ContentInit, Nat) -> async (?ContentId);
          };
          switch(await newCan.createContent(i, i.size)){
            case(?contentId){ 
              let a = Map.put(contentToCanister, thash, contentId, canID);
              uploaded := true;
              return ?(contentId, canID)  
            };
            case null { 
              return null
            };
          };

        };
        case null {
          return null;
        };

      }
    }else{
      return null;
    }
  };


  private func createStorageCanister(owner: UserId) : async ?(Principal) {
    await checkCyclesBalance();
    Debug.print(debug_show Principal.toText(owner));
    Cycles.add(CYCLE_AMOUNT);

   

    var canisterId: ?Principal = null;
    // let {canister_id} = await ic.create_canister({settings = null});

    let b = await ArtistContentBucket.ArtistContentBucket(owner, manager);
    canisterId := ?(Principal.fromActor(b));

    switch (canisterId) {
      case null {
        throw Error.reject("Bucket init error");
      };
      case (?canisterId) {

        

        let self: Principal = Principal.fromActor(this);

        let controllers: ?[Principal] = ?[canisterId, owner, self];

        let cid = { canister_id = Principal.fromActor(this)};
        Debug.print("IC status..."  # debug_show(await ic.canister_status(cid)));
        
        await ic.update_settings(({canister_id = canisterId; 
          settings = {
            controllers = controllers;
            freezing_threshold = null;
            memory_allocation = null;
            compute_allocation = null;
          }}));
      };
    };

     

    

    return canisterId;
  };


  public func transferCyclesToThisCanister() : async (){
    let self: Principal = Principal.fromActor(this);
    // Manager.transferCyclesToCanister(self, limit);

    let can = actor(Principal.toText(manager)): actor { 
            transferCycles: (CanisterId, Nat) -> async ();
          };
    
    await can.transferCycles(self, limit);

  };

  public func checkCyclesBalance () : async(){
    Debug.print("creator of this smart contract: " #debug_show manager);
    let bal = getCurrentCycles();
    Debug.print("Cycles Balance After Canister Creation: " #debug_show bal);
    if(bal < CYCLE_AMOUNT){
       await transferCyclesToThisCanister();
    };
  };


  public func changeCycleAmount(amount: Nat) : (){
    CYCLE_AMOUNT := amount;
  };

  public func changeCanisterSize(newSize: Nat) : (){
    MAX_CANISTER_SIZE := newSize;
  };

  // public func getMemoryStatus() : async (Nat, Nat){
  //   let memSize = Prim.rts_memory_size();
  //   let heapSize = Prim.rts_heap_size();
  //   return (memSize, heapSize);
  // }; 

  

  func chunkId(contentId : ContentId, chunkNum : Nat) : ChunkId {
    contentId # (Nat.toText(chunkNum))
  };

  // public shared(msg) func putContentChunk(contentId : ContentId, chunkNum : Nat, chunkData : [Nat8]) : async ?()
  // {
  //   do ? {
  //     // accessCheck(msg.caller, #update, #video videoId)!;
  //     contentData.chunksPut(chunkId(contentId, chunkNum), chunkData);
  //   }
  // };

  // public func getContentChunk(contentId : ContentId, chunkNum : Nat) : async ?[Nat8] {
  //   do ? {
  //     // accessCheck(msg.caller, #view, #video videoId)!;
  //     contentData.chunksGet(chunkId(contentId, chunkNum))!
  //   }
  // };

  private func getCurrentHeapMemory(): Nat {
    Prim.rts_heap_size();
  };

  private func getCurrentMemory(): Nat {
    Prim.rts_memory_size();
  };

  private func getCurrentCycles(): Nat {
    Cycles.balance();
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




  public func wallet_receive() : async { accepted: Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept(Nat.min(available, limit));
    { accepted = Nat64.fromNat(accepted) };
  };

  public shared func wallet_send(wallet_send: shared () -> async { accepted: Nat }, amount : Nat) : async { accepted: Nat } {// Signature of the wallet recieve function in the calling canister
    Cycles.add(amount);
    let l = await wallet_send();
    { accepted = amount };
  };


  public query func getPrincipalThis() :  async (Principal){
    Principal.fromActor(this);
  };

  public query func version() : async Nat {
		return VERSION;
	};

  // public shared({caller}) func cyclesBalance() : async (Nat) {
  //   if (not Utils.isAdmin(caller)) {
  //     throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
  //   };

  //   return walletUtils.cyclesBalance();
  // };

  
}