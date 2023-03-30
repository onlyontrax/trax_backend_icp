import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Map "mo:base/HashMap";
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


actor class ArtistBucket(accountInfo: ?T.ArtistAccountData, artistAccount: Principal) = this {


  type ArtistAccountData         = T.ArtistAccountData;
  type UserId                    = T.UserId;
  type ContentInit               = T.ContentInit;
  type ContentId                 = T.ContentId;
  type ContentInfo               = T.ContentInfo;
  type ChunkId = T.ChunkId;

  stable var owner: Principal = artistAccount;

  private let accountData : ArtistData.ArtistData = ArtistData.ArtistData();
  private let contentData : ArtistContentData.ArtistContentData = ArtistContentData.ArtistContentData();
  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();
  
  var version: Nat = 1;

  var artistToProfileInfoMap = Map.HashMap<UserId, ArtistAccountData>(1, Principal.equal, Principal.hash);

  stable var initialised: Bool = false;

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


  public func deleteCanister(user: Principal): async(){
    let canisterId :?Principal = ?(Principal.fromActor(this));
    let res = await canisterUtils.deleteCanister(canisterId);
  };


  public query func getPrincipalThis() :  async (Principal){
    Principal.fromActor(this);
  };

  // upload cover photo 
  // upload profile pic 
  // get profile pic 
  // get upload pic
  // make upgradable 
  // 


  public func createContent(i : ContentInit) : async ?ContentId {
   let now = Time.now();
    let videoId = Principal.toText(i.userId) # "-" # i.name # "-" # (Int.toText(now));
    switch (contentData.get(videoId)) {
    case (?_) { /* error -- ID already taken. */ null };
    case null { /* ok, not taken yet. */
           contentData.put(videoId,
                            {
                              videoId = videoId;
                              userId = i.userId ;
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

  func chunkId(contentId : ContentId, chunkNum : Nat) : ChunkId {
    contentId # (Nat.toText(chunkNum))
  };

  public shared(msg) func putContentChunk(contentId : ContentId, chunkNum : Nat, chunkData : [Nat8]) : async ?()
  {
    do ? {
      // accessCheck(msg.caller, #update, #video videoId)!;
      contentData.chunksPut(chunkId(contentId, chunkNum), chunkData);
    }
  };

  public func getContentChunk(contentId : ContentId, chunkNum : Nat) : async ?[Nat8] {
    do ? {
      // accessCheck(msg.caller, #view, #video videoId)!;
      contentData.chunksGet(chunkId(contentId, chunkNum))!
    }
  };

  public func getContentInfo(caller: UserId, id: ContentId) : async ?ContentInfo{
    do ? {
      let res = contentData.get(id)!;
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

  
}