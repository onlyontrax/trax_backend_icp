
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

    type ArtistAccountData = T.ArtistAccountData;
    type UserId = T.UserId;

    public class ArtistData() {
        private var artistData = Map.HashMap<UserId, ArtistAccountData>(1, Principal.equal, Principal.hash);

        public func put(caller: UserId, data: ArtistAccountData) {
          artistData.put(caller, data);
        };

        public func get(caller: UserId) : ?ArtistAccountData {
          return artistData.get(caller);
        };

        public func del(caller : UserId) : ?ArtistAccountData {
          let entry : ?ArtistAccountData = get(caller);

          switch (entry) {
            case (?entry) {
              artistData.delete(caller);
            };
            case (null) {};
          };

          return entry;
        };

        public func update(caller: UserId, info: ArtistAccountData) : async (){
            var update = artistData.replace(caller, info);
        };

        public func entries() : Iter.Iter<(UserId, ArtistAccountData)> {
          return artistData.entries();
        };

        public func preupgrade() : Map.HashMap<UserId, ArtistAccountData> {
          return artistData;
        };

        public func postupgrade(stableData : [(UserId, ArtistAccountData)]) {
          artistData := Map.fromIter<UserId, ArtistAccountData>(stableData.vals(), 10, Principal.equal, Principal.hash);
        };



    }
}