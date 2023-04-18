import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import T          "types";
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
import ArtistData    "account-data";
import ArtistContentData    "content-data";
import Prim "mo:⛔";
import Map  "mo:stable-hash-map/Map";
// import ContentStorageBucket "./artist-bucket";
import ArtistContentBucket "./content-bucket";
import B "mo:stable-buffer/StableBuffer";


actor class ArtistBucket(accountInfo: ?T.ArtistAccountData, artistAccount: Principal) = this {

  let { ihash; nhash; thash; phash; calcHash } = Map;

  type ArtistAccountData         = T.ArtistAccountData;
  type UserId                    = T.UserId;
  type ContentInit               = T.ContentInit;
  type ContentId                 = T.ContentId;
  type ContentInfo               = T.ContentInfo;
  type ChunkId                   = T.ChunkId;
  type CanisterId                = T.CanisterId;
  
  stable var MAX_CANISTER_SIZE: Nat = 48_000_000_000; // <-- approx. 40MB
  stable var CYCLE_AMOUNT : Nat = 1_000_000_000_000;

  stable var version: Nat = 1;
  stable var initialised: Bool = false;

  stable var owner: Principal = artistAccount;

  private let accountData : ArtistData.ArtistData = ArtistData.ArtistData();
  
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();

  private let contentToCanister = Map.new<ContentId, CanisterId>(thash);
  let contentCanisterIds = B.init<CanisterId>();

  // stable var spaceFilled = Nat

  public func changeCycleAmount(amount: Nat) : (){
    CYCLE_AMOUNT := amount;
  };

  public func changeCanisterSize(newSize: Nat) : (){
    MAX_CANISTER_SIZE := newSize;
  };

  public query func getCanisterOfContent(contentId: ContentId) : async ?(CanisterId){
    Map.get(contentToCanister, thash, contentId);
  };

  public query func getAllContentCanisters() : async [CanisterId]{
    B.toArray(contentCanisterIds);
  };

  public func getAvailableMemoryCanister(canisterId: Principal) : async (Nat){
    let can = actor(Principal.toText(canisterId)): actor { 
        getMemoryStatus: () -> async (Nat, Nat);
    };
    
    let memStatus = await can.getMemoryStatus();
    let availableMemory: Nat = MAX_CANISTER_SIZE - memStatus.0;
    return availableMemory;
  };

  
  


  public func initCanister() :  async(Bool) { // Initialise new cansiter. This is called only once after the account has been created. I
    assert(initialised == false);
    switch(accountInfo){
      case(?info){
        accountData.put(artistAccount, info);
        initialised := true;
        return true;
      };case null return false;
    };
  };

  public func updateProfileInfo(caller: UserId, info: ArtistAccountData) : async (Bool){
    assert(owner == caller);
    switch(accountData.get(caller)){
      case(?exists){
        var update = accountData.update(caller, info);
        true
      };case null false;
    }
  };




  public func getProfileInfo(user: UserId) : async (?ArtistAccountData){
    // assert(owner == msg.caller);
    accountData.get(user);
  };


  public func deleteAccount(user: Principal): async(){
    let canisterId :?Principal = ?(Principal.fromActor(this));
    let res = await canisterUtils.deleteCanister(canisterId);
  };


  

  // upload cover photo 
  public func uploadCoverPhoto(): async(){

  };
  // upload profile pic 
  public func uploadProfilePhoto(): async(){

  };

  // get profile pic 
  public func getProfilePhoto(): async(){

  };
  // get upload pic
  public func getUploadCoverPhoto(): async(){

  };
  


  public shared({caller}) func createContent(i : ContentInit, fileSize: Nat) : async ?(ContentId, Principal) {
    // assert();
    if(caller != i.userId){
      throw Error.reject("caller is not the publisher");
    };
    // var canIdToReturn : ?Principal;
    // check if there is free space in current canister 
    // let index : Nat = contentCanisterIds.size();
    // let currCanID = contentCanisterIds.get(index);

    var uploaded : Bool = false;
    for(canisters in B.vals(contentCanisterIds)){
      Debug.print("canister: " # debug_show canisters);

      // Debug.print("currCanID: " #debug_show currCanID);
      

      let availableMemory: Nat = await getAvailableMemoryCanister(canisters);

      if(availableMemory > fileSize){ // replace hardcoded val with size of ingress message

        let can = actor(Principal.toText(canisters)): actor { 
          createContent: (ContentInit, Nat) -> async (?ContentId);
        };

        switch(await can.createContent(i, fileSize)){
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

    if(uploaded == false){
      switch(await createStorageCanister(i.userId)){
        case(?canID){
          B.add(contentCanisterIds, canID);
          let newCan = actor(Principal.toText(canID)): actor { 
            createContent: (ContentInit, Nat) -> async (?ContentId);
          };
          switch(await newCan.createContent(i, fileSize)){
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


    // if so, make inter canister call to add content to canisters db and add canisterId + contentId to hashmap 
    // if not create new canister, and initialise it with new content and add canisterId + contentId to hashmap 
    // 
  };

  public func getMemoryStatus() : async (Nat, Nat){
    let memSize = Prim.rts_memory_size();
    let heapSize = Prim.rts_heap_size();
    return (memSize, heapSize);
  }; 

  private func createStorageCanister(owner: UserId) : async ?(Principal) {
    Debug.print(debug_show Principal.toText(owner));
    Cycles.add(CYCLE_AMOUNT);

    var canisterId: ?Principal = null;
    // let {canister_id} = await ic.create_canister({settings = null});

    let b = await ArtistContentBucket.ArtistContentBucket(owner);
    canisterId := ?(Principal.fromActor(b));
    return canisterId;
  };

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

  // public func getContentInfo(caller: UserId, id: ContentId) : async ?ContentInfo{
  //   do ? {
  //     let res = contentData.get(id)!;
  //     {
  //       contentId = id;
  //       userId = res.userId;
  //       createdAt = res.createdAt;
  //       uploadedAt = res.uploadedAt;
  //       caption = res.caption;
  //       tags = res.tags;
  //       viewCount = res.viewCount;
  //       name = res.name;
  //       chunkCount = res.chunkCount;
  //       contentType = res.contentType;
  //     }
  //   }
  // };



  // public func getMemoryStatus() : async (Nat, Nat){
  //   let memSize = Prim.rts_memory_size();
  //   let heapSize = Prim.rts_heap_size();
  //   return (memSize, heapSize);
  // };  

  public query func getPrincipalThis() :  async (Principal){
    Principal.fromActor(this);
  };

  
}