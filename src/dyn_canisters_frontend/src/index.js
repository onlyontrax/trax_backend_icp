import { Actor, HttpAgent } from '@dfinity/agent';
import { dyn_canisters_backend } from '../../declarations/dyn_canisters_backend';
import { idlFactory as fanBucketIDL } from '../../declarations/fan_bucket/fan_bucket.did.js';
import { idlFactory as artistBucketIDL} from '../../declarations/artist_bucket/artist_bucket.did.js'
import { Principal } from '@dfinity/principal'; 
// import PlugConnect from '@psychedelic/plug-connect';
import {useUploadVideo} from './video';

export const createBucketActor = async ({ idl, canisterId }) => {
  // console.log(idlFactory)
  const agent = new HttpAgent();

  if (process.env.NODE_ENV !== 'production') {
    await agent.fetchRootKey();
  }

  return Actor.createActor(idl, {
    agent,
    canisterId
  });
};

let bucket;
let registeredBuckets = [];


const getAllCanisters= () =>{

  console.log(registeredBuckets)
}




const createFanProfile = async () => {
  let username = document.getElementById('username');
  let displayName = document.getElementById('displayName');
  let userPrincipal = document.getElementById('principal');
  // let gender = document.getElementById('gender');
  let emailAddress = document.getElementById('email');
  let lastName = document.getElementById('lastName');
  let firstName = document.getElementById('firstName');

  let fanAccountData = {
    firstName: firstName.value,
        lastName: lastName.value,
        userPrincipal: Principal.fromText(userPrincipal.value),
        username: username.value,
        displayName: displayName.value,
        emailAddress: emailAddress.value,
  }
  try {
    bucket = await dyn_canisters_backend.createProfileFan(fanAccountData);
    console.log('New bucket:', bucket.toText());
    registeredBuckets.push(bucket.toString());
    let connected = document.querySelector("#connectCanID");
    connected.value = bucket;
    await initCanister(bucket, "fan");
  } catch (err) {
    console.error(err);
  }
};



const initCanister = async (bucket, type) => {
  // console.log(idlFactory)
  try {
    let actor;
    if(type === "artist"){
      actor = await createBucketActor({
        idl: artistBucketIDL,
        canisterId: bucket
      });
    }else{
      actor = await createBucketActor({
        idl: fanBucketIDL,
        canisterId: bucket
      });
    }
    
    let res = await actor.initCanister()
    console.log("init canister res: " + res);
  } catch (err) {
    console.error(err);
  }
};



const transferOwner = async() => {
  
  let newOwnerInput = document.querySelector("#newOwner");
  let currentOwnerInput = document.querySelector("#oldOwner");
  let currentOwner = Principal.fromText(currentOwnerInput.value);
  let newOwner = Principal.fromText(newOwnerInput.value);

  let canId = await dyn_canisters_backend.getCanisterFan(currentOwner);
  try {
    const actor = await createBucketActor({
      idl: fanBucketIDL,
      canisterId: canId.toString()
    });
    await dyn_canisters_backend.transferOwnershipFan(currentOwner, newOwner);
    let res = await actor.transferOwnership(currentOwner, newOwner);
    console.log(res);

  } catch (err) {
    console.error(err);
  }
}






const getProfileInfo = async() =>{
  let userPrincipal = document.querySelector('#getInfoPrince')
  let canId = await dyn_canisters_backend.getCanisterFan(Principal.fromText(userPrincipal.value))
  console.log(canId.toString());

  // let connected = document.querySelector("#connectCanID");
  // console.log(connected.value);
  
  try {
    const actor = await createBucketActor({
      idl: fanBucketIDL,
      canisterId: canId.toString()
    });
    let res = await actor.getProfileInfo(Principal.fromText(userPrincipal.value));
    var username = document.querySelector("#usernameP");
    var displayName = document.querySelector("#displayNameP");
    var principal = document.querySelector("#principalP");
    var firstName = document.querySelector("#firstNameP");
    var lastName = document.querySelector("#lastNameP");
    var email = document.querySelector("#emailP");
    console.log(res[0]);
    // console.log(res);

    username.value = res[0].username;
    displayName.value = res[0].displayName;
    principal.value = res[0].userPrincipal.toString();
    firstName.value = res[0].firstName;
    lastName.value = res[0].lastName;
    email.value = res[0].emailAddress;

  } catch (err) {
    console.error(err);
  }
}





const updateProfile = async () =>{
  let principal = document.querySelector('#getInfoPrince')
  let canId = await dyn_canisters_backend.getCanisterFan(Principal.fromText(principal.value))
  console.log(canId.toString());

  let username = document.getElementById('usernameP');
  let displayName = document.getElementById('displayNameP');
  let userPrincipal = document.getElementById('principalP');
  // let gender = document.getElementById('gender');
  let emailAddress = document.getElementById('emailP');
  let lastName = document.getElementById('lastNameP');
  let firstName = document.getElementById('firstNameP');

  let newFanAccountData = {
      firstName: firstName.value,
      lastName: lastName.value,
      userPrincipal: Principal.fromText(userPrincipal.value),
      username: username.value,
      displayName: displayName.value,
      emailAddress: emailAddress.value,
  }
try {
    const actor = await createBucketActor({
      idl: fanBucketIDL,
      canisterId: canId.toString()
    });
    console.log(await actor.updateProfileInfo(newFanAccountData.userPrincipal, newFanAccountData));
  } catch (err) {
    console.error(err);
  }


}

















const createProfileArtist = async () => {
  let username = document.getElementById('usernameA');
  let displayName = document.getElementById('displayNameA');
  let userPrincipal = document.getElementById('principalA');
  // let gender = document.getElementById('gender');
  let emailAddress = document.getElementById('emailA');
  let lastName = document.getElementById('lastNameA');
  let firstName = document.getElementById('firstNameA');
  let country = document.getElementById('countryA');
  let dob = document.getElementById('dateOfBirthA');
  let bio = document.getElementById('bioA');


  let artistAccountData = {
    firstName: firstName.value,
        lastName: lastName.value,
        userPrincipal: Principal.fromText(userPrincipal.value),
        username: username.value,
        displayName: displayName.value,
        emailAddress: emailAddress.value,
        country: country.value,
        dateOfBirth: BigInt(dob.value),
        bio: bio.value
  }

  try {
    bucket = await dyn_canisters_backend.createProfileArtist(artistAccountData);
    console.log('New bucket:', bucket.toText());
    registeredBuckets.push(bucket.toString());
    let connected = document.querySelector("#connectCanID");
    connected.value = bucket;
    await initCanister(bucket, "artist");
  } catch (err) {
    console.error(err);
  };
};



const getProfileInfoArtist = async() =>{
  let userPrincipal = document.querySelector('#getInfoPrinceA')
  let canId = await dyn_canisters_backend.getCanisterArtist(Principal.fromText(userPrincipal.value))
  console.log(canId.toString());

  // let connected = document.querySelector("#connectCanID");
  // console.log(connected.value);
  
  try {
    const actor = await createBucketActor({
      idl: artistBucketIDL,
      canisterId: canId.toString()
    });

    let res = await actor.getProfileInfo(Principal.fromText(userPrincipal.value));

    var username = document.querySelector("#usernamePA");
    var displayName = document.querySelector("#displayNamePA");
    var principal = document.querySelector("#principalPA");
    var firstName = document.querySelector("#firstNamePA");
    var lastName = document.querySelector("#lastNamePA");
    var email = document.querySelector("#emailPA");
    var country = document.querySelector("#countryPA");
    var dob = document.querySelector("#dateOfBirthPA");
    var bio = document.querySelector("#bioPA");
    console.log(res[0]);
    
    // console.log(res);

    username.value = res[0].username;
    displayName.value = res[0].displayName;
    principal.value = res[0].userPrincipal.toString();
    firstName.value = res[0].firstName;
    lastName.value = res[0].lastName;
    email.value = res[0].emailAddress;
    country.value = res[0].country;
    dob.value = Number(res[0].dateOfBirth);
    bio.value = res[0].bio;

  } catch (err) {
    console.error(err);
  }
}




const updateProfileArtist = async () =>{
  let principal = document.querySelector('#getInfoPrinceA');
  let canId = await dyn_canisters_backend.getCanisterArtist(Principal.fromText(principal.value))
  console.log(canId.toString());

  var username = document.querySelector("#usernamePA");
    var displayName = document.querySelector("#displayNamePA");
    // var principal = document.querySelector("#principalPA");
    var firstName = document.querySelector("#firstNamePA");
    var lastName = document.querySelector("#lastNamePA");
    var email = document.querySelector("#emailPA");
    var country = document.querySelector("#countryPA");
    var dob = document.querySelector("#dateOfBirthPA");
    var bio = document.querySelector("#bioPA");

  let newArtistAccountData = {
      firstName: firstName.value,
      lastName: lastName.value,
      userPrincipal: Principal.fromText(principal.value),
      username: username.value,
      displayName: displayName.value,
      emailAddress: email.value,
      country: country.value,
      dateOfBirth: BigInt(dob.value),
      bio: bio.value 
  }
try {
    const actor = await createBucketActor({
      idl: artistBucketIDL,
      canisterId: canId.toString()
    });
    console.log(await actor.updateProfileInfo(newArtistAccountData.userPrincipal, newArtistAccountData));
  } catch (err) {
    console.error(err);
  }


}






const getThisPrincipal = async () =>{
  let connected = document.querySelector("#connectCanID")
  try {
    const actor = await createBucketActor({
      idl: artistBucketIDL,
      canisterId: connected.value
    });
    console.log("ACTOR: " + actor);
    
    let res = await actor.getPrincipalThis();
    console.log("RES: " + res)
    console.log("BUCKET: " + bucket)
  } catch (err) {
    console.error(err);
  }
}





const getMyCanisterID = async () =>{
  
  try{

    let input = document.querySelector("#canOwner")
    let owner = Principal.fromText(input.value);
    let res = await dyn_canisters_backend.getCanisterFan(owner);
    console.log(res.toString())

  }catch(error){
    console.log(error)
  }
  
}





const getOwnerOfCanisterId = async () =>{
  
  try{
    let input   = document.querySelector("#canID")
    let canID   = Principal.fromText(input.value)
    let res     = await dyn_canisters_backend.getOwnerOfFanCanister(canID)
    console.log(res.toString());
  }catch(error){
    console.log(error);
  };
};






const getMyCanisterIDArtist = async () =>{
  
  try{
    let input = document.querySelector("#canOwnerArtist");
    let owner = Principal.fromText(input.value);
    let res = await dyn_canisters_backend.getCanisterArtist(owner);
    console.log(res.toString())

  }catch(error){
    console.log(error)
  }
}





const getOwnerOfCanisterIdArtist = async () =>{
  
  try{
    let input   = document.querySelector("#canIDA")
    let canID   = Principal.fromText(input.value)
    let res     = await dyn_canisters_backend.getOwnerOfArtistCanister(canID)
    console.log(res.toString());
  }catch(error){
    console.log(error);
  };
};



const upload = async()=>{
  const videoFile = document.getElementById('video-upload');
  const userId = document.getElementById('id-artist-upload');
  const canisterId = await dyn_canisters_backend.getCanisterArtist(userId);
  
  const caption = document.getElementsById('caption-content');
    if (!videoFile || !caption) {
      return;
    }
    // useUploadVideo.setFile(videoFile);
    // useUploadVideo.setCaption(caption);
    // useUploadVideo.setReady(true);
    useUploadVideo(userId, videoFile, true)
    // setUploading(true);
}



const init = () => {

  const btnInit = document.querySelector('button#create');
  btnInit.addEventListener('click', createFanProfile);

  const btnGetProfile = document.querySelector('#getProfile');
  btnGetProfile.addEventListener('click', getProfileInfo);
  
  const transferOwnership = document.querySelector('button#transferOwnership');
  transferOwnership.addEventListener('click', transferOwner);

  const update = document.querySelector('button#updateProfile');
  update.addEventListener('click', updateProfile);

  const getCanisterID = document.querySelector('button#getCanID');
  getCanisterID .addEventListener('click', getMyCanisterID);

  const getOwnerOfCanister = document.querySelector('button#getFanID');
  getOwnerOfCanister.addEventListener('click', getOwnerOfCanisterId);

  const getAllBuckets = document.querySelector('button#getAllBuckets');
  getAllBuckets.addEventListener('click', getAllCanisters);

  const getActorPrincipal = document.querySelector('button#getThisPrincipal');
  getActorPrincipal.addEventListener('click', getThisPrincipal);

  const uploadVideo = document.querySelector('button#postContent');
  uploadVideo.addEventListener('click', upload)

  const createArtistProfile = document.querySelector('button#createA');
  createArtistProfile.addEventListener('click', createProfileArtist);

  const updateArtistProfile = document.querySelector('button#updateProfileA');
  updateArtistProfile.addEventListener('click', updateProfileArtist);

  const getAProfile = document.querySelector('button#getProfileA');
  getAProfile.addEventListener('click', getProfileInfoArtist);

  const getCanIDArtist = document.querySelector('button#getCanIDArtist');
  getCanIDArtist.addEventListener('click', getMyCanisterIDArtist)

  const getArtistIDCAN = document.querySelector('button#getArtistID');
  getArtistIDCAN.addEventListener('click', getOwnerOfCanisterIdArtist)
  
};

document.addEventListener('DOMContentLoaded', init);
