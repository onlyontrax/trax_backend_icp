import Cycles             "mo:base/ExperimentalCycles";
import Principal          "mo:base/Principal";
import Error              "mo:base/Error";
import Nat                "mo:base/Nat";
import Debug              "mo:base/Debug";
import Text               "mo:base/Text";
import T                  "../types";
import Hash               "mo:base/Hash";
import Nat32              "mo:base/Nat32";
import Nat64              "mo:base/Nat64";
import Iter               "mo:base/Iter";
import Float              "mo:base/Float";
import Time               "mo:base/Time";
import Int                "mo:base/Int";
import Result             "mo:base/Result";
import Blob               "mo:base/Blob";
import Array              "mo:base/Array";
import Buffer             "mo:base/Buffer";
import Trie               "mo:base/Trie";
import TrieMap            "mo:base/TrieMap";
import CanisterUtils      "../utils/canister.utils";
import Prim               "mo:⛔";
import Map                "mo:stable-hash-map/Map";
import Utils              "../utils/utils";
import WalletUtils        "../utils/wallet.utils";
// import Manager "canister:dyn_canisters_backend";
// import ContentStorageBucket "./artist-bucket";


actor class ArtistContentBucket(owner: Principal) = this {
  // change [Nat] to Blob for sc memory improvement
  // pull cycles from parent canister if balance is below threshold 
  //  


//   type ArtistAccountData         = T.ArtistAccountData;
  type UserId                    = T.UserId;
  type ContentInit               = T.ContentInit;
  type ContentId                 = T.ContentId;
  type ContentData               = T.ContentData;
  type ChunkId                   = T.ChunkId;
  type CanisterId                = T.CanisterId;
  type ChunkData                 = T.ChunkData;
  type StatusRequest             = T.StatusRequest;
  type StatusResponse             = T.StatusResponse;
  // type Manager = Manager.Manager;
  
  let { ihash; nhash; thash; phash; calcHash } = Map;

  stable var canisterOwner: Principal = owner;
  stable var MAX_CANISTER_SIZE: Nat = 48_000_000_000; // <-- approx. 48GB
  var version: Nat = 1;


  let limit                         = 20_000_000_000_000; // canister cycles capacity 
  stable var CYCLE_AMOUNT : Nat     =  1_000_000_000_000; // minimum amount of cycles needed to create new canister 

  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  private let walletUtils : WalletUtils.WalletUtils = WalletUtils.WalletUtils();

  private var content = Map.new<ContentId, ContentData>(thash);
  private var chunksData = Map.new<ChunkId, ChunkData>(thash);

  stable var initialised: Bool = false;

  public func deleteCanister(user: Principal): async(){
    let canisterId :?Principal = ?(Principal.fromActor(this));
    let res = await canisterUtils.deleteCanister(canisterId);
  };

  public shared({caller})func changeMaxCanisterSize(value: Nat) : (){
    if (not Utils.isAdmin(caller)) {
      throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    };
  };


// #region - CREATE & UPLOAD CONTENT
  public func createContent(i : ContentInit) : async ?ContentId {
    
    let now = Time.now();
    let videoId = Principal.toText(i.userId) # "-" # i.name # "-" # (Int.toText(now));
    switch (Map.get(content, thash, videoId)) {
    case (?_) { throw Error.reject("Content ID already taken")};
    case null { 
           let a = Map.put(content, thash, videoId,
                            {
                              contentId = videoId;
                              userId = i.userId;
                              name = i.name;
                              createdAt = i.createdAt;
                              uploadedAt = now;
                              caption =  i.caption;
                              chunkCount = i.chunkCount;
                              tags = i.tags;
                              extension = i.extension;
                              size = i.size
                            });
            // await checkCyclesBalance();
           ?videoId
           
         };
    }
  };


  // public func checkCyclesBalance () : async(){
  //   let bal = getCurrentCycles();
  //   Debug.print("Cycles Balance After Canister Creation: " #debug_show bal);
  //   if(bal < CYCLE_AMOUNT){
  //      await transferCyclesToThisCanister();
  //   };
  // };


  // public func transferCyclesToThisCanister() : async (){
  //   let self: Principal = Principal.fromActor(this);
  //   Manager.transferCyclesToCanister(self, limit);

  // };

  

  

  public shared(msg) func putContentChunk(contentId : ContentId, chunkNum : Nat, chunkData : Blob) : async (){
      // accessCheck(msg.caller, #update, #video videoId)!;
      // await checkCyclesBalance();
      let a = Map.put(chunksData, thash, chunkId(contentId, chunkNum), chunkData);
  };


  func chunkId(contentId : ContentId, chunkNum : Nat) : ChunkId {
    contentId # (Nat.toText(chunkNum))
  };


  public func getContentChunk(contentId : ContentId, chunkNum : Nat) : async ?Blob {
    // await checkCyclesBalance();
      Map.get(chunksData, thash, chunkId(contentId, chunkNum));
  };

  public func removeContent(contentId: ContentId, chunkNum : Nat) : async () {
    let a = Map.remove(chunksData, thash, chunkId(contentId, chunkNum));
    let b = Map.remove(content, thash, contentId);
  };
// #endregion



  public func getContentInfo(caller: UserId, id: ContentId) : async ?ContentData{
    // await checkCyclesBalance();
    Map.get(content, thash, id);
  };


  // public query func is_full() : async Bool {
	// 	let MAX_SIZE_THRESHOLD_MB : Float = 1500;

	// 	let rts_memory_size : Nat = Prim.rts_memory_size();
	// 	let mem_size : Float = Float.fromInt(rts_memory_size);
	// 	let memory_in_megabytes = Float.abs(mem_size * 0.000001);

	// 	if (memory_in_megabytes > MAX_SIZE_THRESHOLD_MB) {
	// 		return true;
	// 	} else {
	// 		return false;
	// 	};
	// };




// #region - UTILS
  public query func getPrincipalThis() :  async (Principal){
    Principal.fromActor(this);
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
// #endregion
  
}