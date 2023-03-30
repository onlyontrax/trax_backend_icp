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
import FanData    "account-data";



actor class FanBucket(accountInfo: ?T.FanAccountData, fanAccount: Principal) = this {

  type FanAccountData                 = T.FanAccountData;
  type UserId = T.UserId;
  var version: Nat = 1;

  stable var owner: Principal = fanAccount;

  private let canisterUtils : CanisterUtils.CanisterUtils = CanisterUtils.CanisterUtils();

  private let fanAccountData : FanData.FanData = FanData.FanData();

  stable var initialised: Bool = false;

  public func initCanister() :  async(Bool) {
    assert(initialised == false);
    switch(accountInfo){
      case(?data){
        fanAccountData.put(fanAccount, data);
        initialised := true;
        return true;
      };case null return false;
    };
  };
  

  public func transferOwnership(currentOwner: Principal, newOwner: Principal) : async(Principal){
    assert(currentOwner == owner);
    switch(fanAccountData.get(currentOwner)){
      case(?fanData){
        fanAccountData.put(newOwner, fanData);
        let res = fanAccountData.del(currentOwner);
      }; case(null){
        throw Error.reject("This principal is already associated with an account");
      };
    };

    owner := newOwner;

    owner;
  };

  public func getProfileInfo(user: Principal) : async (?FanAccountData){
    // assert(owner == msg.caller);
    fanAccountData.get(user);
  };

  public func updateProfileInfo(caller: Principal, info: FanAccountData) : async (Bool){
    assert(owner == caller);
    switch(fanAccountData.get(caller)){
      case(?exists){
        var update = fanAccountData.update(caller, info);
        true
      };case null false;
    }
  };

  public func deleteCanister(user: Principal): async(){
    let canisterId :?Principal = ?(Principal.fromActor(this));
    let res = await canisterUtils.deleteCanister(canisterId);
  };

  public query func getPrincipalThis() :  async (Principal){
    Principal.fromActor(this);
  };


  public func onlyOwner(user: Principal) : async Bool{    user == owner     };
  private func onlyAdmin(admin: Principal) : async Bool{  admin == owner   };

  

}