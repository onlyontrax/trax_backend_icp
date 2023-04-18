import Cycles             "mo:base/ExperimentalCycles";
import Principal          "mo:base/Principal";
import Error              "mo:base/Error";
import Nat                "mo:base/Nat";
import Debug              "mo:base/Debug";
import Text               "mo:base/Text";
import T                  "types";
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
import ArtistData         "account-data";
import ArtistContentData  "content-data";
import Prim               "mo:⛔";
import Map                "mo:stable-hash-map/Map";
import Utils              "../utils/utils";
import WalletUtils        "../utils/wallet.utils";
// import ContentStorageBucket "./artist-bucket";


actor class ArtistContentBucket(owner: Principal) = this {


//   type ArtistAccountData         = T.ArtistAccountData;
  type UserId                    = T.UserId;
  type ContentInit               = T.ContentInit;
  type ContentId                 = T.ContentId;
  type ContentInfo               = T.ContentInfo;
  type ChunkId                   = T.ChunkId;
  type CanisterId                = T.CanisterId;
  type Content                   = T.Content;
  type ChunkData                 = T.ChunkData;
  
  let { ihash; nhash; thash; phash; calcHash } = Map;

  stable var canisterOwner: Principal = owner;
  stable var MAX_CANISTER_SIZE: Nat = 48_000_000_000; // <-- approx. 48MB
  var version: Nat = 1;

  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  private let walletUtils : WalletUtils.WalletUtils = WalletUtils.WalletUtils();

  private var content = Map.new<ContentId, ContentInfo>(thash);
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


  public func createContent(i : ContentInit, fileSize: Nat) : async ?ContentId {
    
    let now = Time.now();
    let videoId = Principal.toText(i.userId) # "-" # i.name # "-" # (Int.toText(now));
    switch (Map.get(content, thash, videoId)) {
    case (?_) { throw Error.reject("Content ID already taken")};
    case null { 
           let a = Map.put(content, thash, videoId,
                            {
                              contentId = videoId;
                              userId = i.userId;
                              name = i.name ;
                              createdAt = i.createdAt ;
                              uploadedAt = now ;
                              caption =  i.caption ;
                              chunkCount = i.chunkCount ;
                              tags = i.tags ;
                              viewCount = 0 ;
                              contentType = i.contentType;
                            });
           ?videoId
         };
    }
  };

  

  

  public shared(msg) func putContentChunk(contentId : ContentId, chunkNum : Nat, chunkData : [Nat8]) : async (){
      // accessCheck(msg.caller, #update, #video videoId)!;
      let a = Map.put(chunksData, thash, chunkId(contentId, chunkNum), chunkData);
  };

  func chunkId(contentId : ContentId, chunkNum : Nat) : ChunkId {
    contentId # (Nat.toText(chunkNum))
  };

  public func getContentChunk(contentId : ContentId, chunkNum : Nat) : async ?[Nat8] {
      Map.get(chunksData, thash, contentId);
  };

  public func getContentInfo(caller: UserId, id: ContentId) : async ?ContentInfo{
      Map.get(content, thash, id);
  };

  public func getMemoryStatus() : async (Nat, Nat){
    let memSize = Prim.rts_memory_size();
    let heapSize = Prim.rts_heap_size();
    return (memSize, heapSize);
  }; 

  public shared({caller}) func cyclesBalance() : async (Nat) {
    if (not Utils.isAdmin(caller)) {
      throw Error.reject("Unauthorized access. Caller is not an admin. " # Principal.toText(caller));
    };

    return walletUtils.cyclesBalance();
  };

  public query func getPrincipalThis() :  async (Principal){
    Principal.fromActor(this);
  };

  
}