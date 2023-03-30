import { Actor, HttpAgent } from '@dfinity/agent';
import { dyn_canisters_backend } from '../../declarations/dyn_canisters_backend';
import { idlFactory } from '../../declarations/fan_bucket/fan_bucket.did.js';
import { Principal } from '@dfinity/principal'; 
// import PlugConnect from '@psychedelic/plug-connect';

export const createBucketActor = async ({ canisterId }) => {
  // console.log(idlFactory)
  const agent = new HttpAgent();

  if (process.env.NODE_ENV !== 'production') {
    await agent.fetchRootKey();
  }

  return Actor.createActor(idlFactory, {
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
    await initCanister(bucket);
  } catch (err) {
    console.error(err);
  }
};



const initCanister = async (bucket) => {
  
  console.log(idlFactory)
  try {
    const actor = await createBucketActor({
      canisterId: bucket
    });
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
  console.log(canId);

  // let connected = document.querySelector("#connectCanID")
  // console.log(connected.value);
  
  try {
    const actor = await createBucketActor({
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





const updateFanProfile = async () =>{
  let principal = document.querySelector('#getInfoPrince')
  let canId = await dyn_canisters_backend.getCanisterFan(Principal.fromText(principal.value))
  console.log(canId);

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
      canisterId: canId.toString()
    });
    console.log(await actor.updateProfileInfo(newFanAccountData.userPrincipal, newFanAccountData));
  } catch (err) {
    console.error(err);
  }


}





const getThisPrincipal = async () =>{
  let connected = document.querySelector("#connectCanID")
  try {
    const actor = await createBucketActor({
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
    console.log(error)
  }
}




async function processAndUploadChunk(
  videoBuffer: ArrayBuffer,
  byteStart: number,
  videoSize: number,
  videoId: string,
  chunk: number
) {
  const videoSlice = videoBuffer.slice(
    byteStart,
    Math.min(videoSize, byteStart + MAX_CHUNK_SIZE)
  );
  const sliceToNat = encodeArrayBuffer(videoSlice);
  return putVideoChunk(videoId, chunk, sliceToNat); // sc call
}

// Wraps up the previous functions into one step for the UI to trigger
async function uploadVideo(userId: string, file: File, caption: string) {
  const videoBuffer = (await file?.arrayBuffer()) || new ArrayBuffer(0);

  const videoInit = getVideoInit(userId, file, caption);
  const videoId = await createVideo(videoInit);

  let chunk = 1;
  const thumb = await generateThumbnail(file);
  await uploadVideoPic(videoId, thumb);

  const putChunkPromises = [];
  for (
    let byteStart = 0;
    byteStart < file.size;
    byteStart += MAX_CHUNK_SIZE, chunk++
  ) {
    putChunkPromises.push(
      processAndUploadChunk(videoBuffer, byteStart, file.size, videoId, chunk)
    );
  }







const init = () => {

  const btnInit = document.querySelector('button#create');
  btnInit.addEventListener('click', createFanProfile);

  const btnGetProfile = document.querySelector('#getProfile');
  btnGetProfile.addEventListener('click', getProfileInfo);
  
  const transferOwnership = document.querySelector('button#transferOwnership');
  transferOwnership.addEventListener('click', transferOwner);

  const update = document.querySelector('button#updateProfile');
  update.addEventListener('click', updateFanProfile);

  const getCanisterID = document.querySelector('button#getCanID');
  getCanisterID .addEventListener('click', getMyCanisterID);

  const getOwnerOfCanister = document.querySelector('button#getFanID');
  getOwnerOfCanister.addEventListener('click', getOwnerOfCanisterId);

  const getAllBuckets = document.querySelector('button#getAllBuckets');
  getAllBuckets.addEventListener('click', getAllCanisters);

  const getActorPrincipal = document.querySelector('button#getThisPrincipal');
  getActorPrincipal.addEventListener('click', getThisPrincipal);

  
};

document.addEventListener('DOMContentLoaded', init);
