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
import ContentStorageBucket "./artist-bucket";


actor class ArtistContentBucket(owner: Principal) = this {


//   type ArtistAccountData         = T.ArtistAccountData;
  type UserId                    = T.UserId;
  type ContentInit               = T.ContentInit;
  type ContentId                 = T.ContentId;
  type ContentInfo               = T.ContentInfo;
  type ChunkId                   = T.ChunkId;
  type CanisterId                = T.CanisterId;
  type Content = T.Content;
    type ChunkData = T.ChunkData;
    type ChunkId = T.ChunkId;
  
  let { ihash; nhash; thash; phash; calcHash } = Map;

  stable var canisterOwner: Principal = owner;

//   private let accountData : ArtistData.ArtistData = ArtistData.ArtistData();
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();

//   stable let contentToCanister = Map.new<ContentId, CanisterId>(thash);
  private var content = Map.new<ContentId, Content>(thash);
  private var chunksData = Map.new<ChunkId, ChunkData>(thash);
//   stable let contentCanisters = Map.new<CanisterId, 

  // stable var spaceFilled = Nat
  
  var version: Nat = 1;


  stable var initialised: Bool = false;


  public func deleteCanister(user: Principal): async(){
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
  


  public func createContent(i : ContentInit) : async ?ContentId {

    // check if there is free space in current canister 
 
    // if so, make inter canister call to add content to canisters db and add canisterId + contentId to hashmap 
    // if not create new canister, and initialise it with new content and add canisterId + contentId to hashmap 
    // 
    

    let now = Time.now();
    let videoId = Principal.toText(i.userId) # "-" # i.name # "-" # (Int.toText(now));
    switch (Map.get(content, thash, videoId)) {
    case (?_) { /* error -- ID already taken. */ null };
    case null { /* ok, not taken yet. */
           Map.put(content, thash, videoId,
                            {
                              videoId = videoId;
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
          //  state.uploaded.put(i.userId, videoId);
          //  logEvent(#createVideo({info = i}));
           ?videoId
         };
    }
  };

  public func getMemoryStatus() : async (Nat, Nat){
          let memSize = Prim.rts_memory_size();
          let heapSize = Prim.rts_heap_size();
          return (memSize, heapSize);
  }; 


  func chunkId(contentId : ContentId, chunkNum : Nat) : ChunkId {
    contentId # (Nat.toText(chunkNum))
  };

  public shared(msg) func putContentChunk(contentId : ContentId, chunkNum : Nat, chunkData : [Nat8]) : async ?()
  {
    do ? {
      // accessCheck(msg.caller, #update, #video videoId)!;
      Map.put(chunksData, thash, chunkId(contentId, chunkNum), chunkData);
    }
  };

  public func getContentChunk(contentId : ContentId, chunkNum : Nat) : async ?[Nat8] {
    do ? {
      // accessCheck(msg.caller, #view, #video videoId)!;
      Map.get(chunksData, thash, id);
    }
  };

  public func getContentInfo(caller: UserId, id: ContentId) : async ?ContentInfo{
    do ? {
      let res = Map.get(content, thash, id);
      {
        contentId = id;
        userId = res.userId;
        createdAt = res.createdAt;
        uploadedAt = res.uploadedAt;
        caption = res.caption;
        tags = res.tags;
        viewCount = res.viewCount;
        name = res.name;
        chunkCount = res.chunkCount;
        contentType = res.contentType;
      }
    }
  };



  // public func getMemoryStatus() : async (Nat, Nat){
  //   let memSize = Prim.rts_memory_size();
  //   let heapSize = Prim.rts_heap_size();
  //   return (memSize, heapSize);
  // };  

  public query func getPrincipalThis() :  async (Principal){
    Principal.fromActor(this);
  };

  
}