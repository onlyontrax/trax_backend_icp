import { useEffect, useState } from "react";
// import {
//   createVideo,
//   getVideoInfo,
//   putVideoChunk,
//   putVideoPic,
// } from "./canister";
// import { VideoInfo, VideoInit } from "./canister/typings";
// import { useUploadVideo } from "./video";
// import { MAX_CHUNK_SIZE, encodeArrayBuffer, hashtagRegExp } from "./utils";



export const MAX_CHUNK_SIZE = 1024 * 500; // 500kb
export const REWARDS_CHECK_INTERVAL = 60000;
export const hashtagRegExp = /(?:\s|^)#[A-Za-z0-9\-._]+(?:\s|$)/gim;

export const encodeArrayBuffer = (file) => Array.from(new Uint8Array(file));

export function unwrap(val){
  if (val[0] === undefined) {
    return null;
  } else {
    return val[0];
  }
}


// Determines number of chunks and creates the VideoInfo
export function getVideoInit(userId,file,caption){
  const chunkCount = Number(Math.ceil(file.size / MAX_CHUNK_SIZE));
  return {
    caption,
    chunkCount,
    createdAt: Number(Date.now() * 1000), // motoko is using nanoseconds
    name: file.name.replace(/\.mp4/, ""),
    tags: caption.match(hashtagRegExp) || [],
    userId,
  };
}

// export interface UploadVideoInit {
//   name: string;
//   caption: string;
//   chunkCount: number;
//   userId: string;
// }

// Divides the file into chunks and uploads them to the canister in sequence
async function processAndUploadChunk(videoBuffer, byteStart, videoSize, videoId, chunk) {
  const actor = await createBucketActor({
      canisterId: bucket
    });

  const videoSlice = videoBuffer.slice(
    byteStart,
    Math.min(videoSize, byteStart + MAX_CHUNK_SIZE)
  );
  const sliceToNat = encodeArrayBuffer(videoSlice);
  return await actor.putContentChunk(videoId, chunk, sliceToNat);
}

// Wraps up the previous functions into one step for the UI to trigger
async function uploadVideo(userId, file, caption) { 
    const actor = await createBucketActor({
        canisterId: bucket
      });
      
  const videoBuffer = (await file?.arrayBuffer()) || new ArrayBuffer(0);

  const videoInit = getVideoInit(userId, file, caption);
  const videoId = await actor.createContent(videoInit);

  let chunk = 1;
  const thumb = generateThumbnail(file);
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

  await Promise.all(putChunkPromises);

  return await checkVidFromIC(videoId, userId);
}

// This isn't Internet Computer specific, just a helper to generate an image
// from a video file
export function generateThumbnail(videoFile) {
  const videoElement = document.createElement("video");
  const thumbnailCanvas = document.createElement("canvas");
  const canvasContext = thumbnailCanvas.getContext("2d");

  const videoUrl = URL.createObjectURL(videoFile);
  videoElement.src = videoUrl;

  videoElement.addEventListener("loadedmetadata", () => {
    thumbnailCanvas.width = videoElement.videoWidth;
    thumbnailCanvas.height = videoElement.videoHeight;
  });

  return new Promise.new((resolve, reject) => {
    videoElement.addEventListener("timeupdate", () => {
      canvasContext.drawImage(
        videoElement,
        0,
        0,
        videoElement.videoWidth,
        videoElement.videoHeight
      );

      URL.revokeObjectURL(videoUrl);

      thumbnailCanvas.toBlob(
        (canvasBlob) => {
          canvasBlob.arrayBuffer().then((arrayBuffer) => {
            resolve([...new Uint8Array(arrayBuffer)]);
          });
        },
        "image/jpeg",
        0.7
      );
    });
    setTimeout(() => {
      reject("took too long to create blob");
    }, 5000);
    videoElement.currentTime = 0.01;
  });
}

// Stores the videoPic on the canister
async function uploadVideoPic(videoId, file) {
    const actor = await createBucketActor({
        canisterId: bucket
      });
  console.log("Storing video thumbnail...");
  try {
    await actor.putContentPic(videoId, file);
    console.log(`Video thumbnail stored for ${videoId}`);
  } catch (error) {
    console.error("Unable to store video thumbnail:", error);
  }
}

// Gets videoInfo from the IC after we've uploaded
async function checkVidFromIC(videoId, userId) {
  console.log("Checking canister for uploaded video...");
  const actor = await createBucketActor({
    canisterId: bucket
  });
  
  const resultFromCanCan = await getContentInfo(userId, videoId);
  if (resultFromCanCan === null) {
    throw Error("Invalid video received from CanCan Canister");
  }
  console.log("Upload verified.");
  return resultFromCanCan;
}

// This hook exposes functions to set video data, trigger the upload, and return
// with "success" to toggle loading states.
export function useUploadVideo( userId, file, ready, caption ) {
  const [completedVideo, setCompletedVideo] = useState(null);
//   const [file, setFile] = useState<File>(null);
//   const [ready, setReady] = useState(false);

  async function handleUpload(fileToUpload) {
    console.info("Storing video...");
    try {
      console.time("Stored in");
      const video = await uploadVideo(userId, file, caption);

      setCompletedVideo(video);
    //   setReady(false);
    //   setFile(undefined);
      console.timeEnd("Stored in");
    } catch (error) {
      console.error("Failed to store video.", error);
    }
  }

  useEffect(() => {
    if (ready && file !== undefined) {
      handleUpload(file);
    }
  }, [ready]);

  return {
    completedVideo,
    setFile,
    setReady,
  };
}