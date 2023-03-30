
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

    type ArtistAccountData = T.ArtistAccountData;
    type UserId = T.UserId;
    let { ihash; nhash; thash; phash; calcHash } = Map;


    public class ArtistData() {
        private var artistData = Map.new<UserId, ArtistAccountData>(phash);

        public func put(caller: UserId, data: ArtistAccountData) {
          let a = Map.put(artistData, phash, caller, data);
        };

        public func get(caller: UserId) : ?ArtistAccountData {
          return Map.get(artistData, phash, caller);
        };

        public func del(caller : UserId) : ?ArtistAccountData {
          let entry : ?ArtistAccountData = get(caller);

          switch (entry) {
            case (?entry) {
              Map.delete(artistData, phash, caller);
            };
            case (null) {};
          };

          return entry;
        };

        public func update(caller: UserId, info: ArtistAccountData) : async (){
            var update = Map.replace(artistData, phash, caller, info);
        };

        public func entries() : Iter.Iter<(UserId, ArtistAccountData)> {
          return Map.entries(artistData);
        };

    }
}