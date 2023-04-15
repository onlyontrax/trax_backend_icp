
import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Map  "mo:stable-hash-map/Map";

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

    let { ihash; nhash; thash; phash; calcHash } = Map;

    public class ArtistContentData() {
        private var content = Map.new<ContentId, Content>(thash);
        private var chunksData = Map.new<ChunkId, ChunkData>(thash);
        // global mapping to store contentIDs to canisterid 
        // when uploading new content, need to check current canister available memory, if not enough space for incoming file, create new canister

        public func put(id: ContentId, data: Content) {
          let a = Map.put(content, thash, id, data);
        };

        public func get(id: ContentId) : ?Content {
          return Map.get(content, thash, id);
        };

        public func del(id : ContentId) : ?Content {
          let entry : ?Content = get(id);

          switch (entry) {
            case (?entry) {
              Map.delete(content, thash, id);
            };
            case (null) {};
          };

          return entry;
        };

        public func update(id: ContentId, data: Content) : async (){
            var update = Map.replace(content, thash, id, data);
        };

        public func entries() : Iter.Iter<(ContentId, Content)> {
          return Map.entries(content);
        };



        public func chunksPut(id: ChunkId, data: ChunkData) {
          let a = Map.put(chunksData, thash, id, data);
        };

        public func chunksGet(id: ChunkId) : ?ChunkData {
          Map.get(chunksData, thash, id);
        };

        public func chunksDel(id : ChunkId) : ?ChunkData {
          let entry : ?ChunkData = chunksGet(id);
          switch (entry) {
            case (?entry) {
              Map.delete(chunksData, thash, id);
            };
            case (null) {};
          };

          return entry;
        };

        public func chunksEntries() : Iter.Iter<(ChunkId, ChunkData)> {
          return Map.entries(chunksData);
        };


    }
}