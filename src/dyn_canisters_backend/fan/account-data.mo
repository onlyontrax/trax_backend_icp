
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

    type FanAccountData                 = T.FanAccountData;
    type UserId = T.UserId;

       let { ihash; nhash; thash; phash; calcHash } = Map;

    public class FanData() {
        private var fanData = Map.new<UserId, FanAccountData>(phash);

        public func put(caller: UserId, data: FanAccountData) {
          let a = Map.put(fanData, phash, caller, data);
        };

        public func getMemoryStatus() : async (Nat, Nat){
          let memSize = Prim.rts_memory_size();
          let heapSize = Prim.rts_heap_size();
          return (memSize, heapSize);
        };  

        public func get(caller: UserId) : ?FanAccountData {
          return Map.get(fanData, phash, caller);
        };

        public func del(caller : UserId) : ?FanAccountData {
          let entry : ?FanAccountData = get(caller);

          switch (entry) {
            case (?entry) {
              Map.delete(fanData, phash, caller);
            };
            case (null) {};
          };

          return entry;
        };

        public func update(caller: UserId, info: FanAccountData) : async (){
            var update = Map.replace(fanData, phash, caller, info);
        };

        public func entries() : Iter.Iter<(UserId, FanAccountData)> {
          return Map.entries(fanData);
        };




    }
}