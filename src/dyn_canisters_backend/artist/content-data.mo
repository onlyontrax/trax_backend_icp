
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
import Prim "mo:⛔";

module {
    type ContentId = T.ContentId;
    

    type Content = T.Content;
    type ChunkData = T.ChunkData;
    type ChunkId = T.ChunkId;

    type ArtistAccountData = T.ArtistAccountData;
    type UserId = T.UserId;

    public class ArtistContentData() {
        private var content = Map.HashMap<ContentId, Content>(1, Text.equal, Text.hash);
        private var chunksData = Map.HashMap<ChunkId, ChunkData>(1, Text.equal, Text.hash);

        public func put(id: ContentId, data: Content) {
          content.put(id, data);
        };

        public func get(id: ContentId) : ?Content {
          return content.get(id);
        };

        public func del(id : ContentId) : ?Content {
          let entry : ?Content = get(id);

          switch (entry) {
            case (?entry) {
              content.delete(id);
            };
            case (null) {};
          };

          return entry;
        };

        public func update(id: ContentId, data: Content) : async (){
            var update = content.replace(id, data);
        };

        public func entries() : Iter.Iter<(ContentId, Content)> {
          return content.entries();
        };



        public func chunksPut(id: ChunkId, data: ChunkData) {
          chunksData.put(id, data);
        };

        public func chunksGet(id: ChunkId) : ?ChunkData {
          chunksData.get(id);
        };

        public func chunksDel(id : ChunkId) : ?ChunkData {
          let entry : ?ChunkData = chunksGet(id);
          switch (entry) {
            case (?entry) {
              chunksData.delete(id);
            };
            case (null) {};
          };

          return entry;
        };

        public func chunksEntries() : Iter.Iter<(ChunkId, ChunkData)> {
          return chunksData.entries();
        };





        public func preupgrade() : Map.HashMap<ContentId, Content> {
          return content;

        };

        public func postupgrade(stableData : [(ContentId, Content)]) {
          content := Map.fromIter<ContentId, Content>(stableData.vals(), 10, Text.equal, Text.hash);
        };



    }
}