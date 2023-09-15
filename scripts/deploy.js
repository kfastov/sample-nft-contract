// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.

const NFT_STORAGE_TOKEN = process.env.NFT_STORAGE_KEY ?? '';

import hre from 'hardhat';
import path from 'path';
import { readdir, readFile } from 'fs/promises';
import { NFTStorage, File, Blob } from 'nft.storage'

const readImages = async () => {
  // Get the images to upload from the local filesystem (/images)
  const imgDirPath = 'images';
  console.log(`Importing images from the ${imgDirPath} directory...`)
  const filesName = await readdir(imgDirPath).catch((err) => {
    console.log("Import from directory failed: ", err);
    return [];
  })
  const imagesName = filesName.filter((fileName) => fileName.includes('.png'));
  let images = [];
  for await (const imageName of imagesName) {
    let imageFilePath = path.join(imgDirPath, imageName);
    let imageData = await readFile(imageFilePath);
    const file = new File([imageData], imageName)
    images.push(file);
  };
  console.log(`Read images as NFT.Storage files`)
  return images
}

// Uploading images to IPFS
const uploadFiles = async (client, imageFiles) => {
  console.log(`Uploading image data to IPFS...`);

  // create car file
  const { cid, car } = await NFTStorage.encodeDirectory(imageFiles)

  // Root CID of the directory
  console.log(`Packed all images into CAR file: ${cid.toString()}`)

  // Now store the CAR file on NFT.Storage
  await client.storeCar(car)

  return cid;
}

// Helper function to form the metadata JSON object
function generateNFTMetadata(rootCID, files, name, description) {
  return files.map((file) => ({
    name,
    description,
    attributes: [
      {
        "trait_type": "Trait Count",
        "value": "0"
      }
    ],
    image: `ipfs://${rootCID}/${file.name}`,
  }))
}

const multiplicate = (smth, count) => {
  return Array.from({ length: count }, () => smth)
}

const uploadMetadata = async (client, metadatas) => {
  console.log(`Uploading metadata to IPFS...`);

  const files = metadatas.map((data, i) => new File([JSON.stringify(data)], `${i}.json`))

  // create car file
  const { cid, car } = await NFTStorage.encodeDirectory(files)

  // Root CID of the directory
  console.log(`Packed all metadata into CAR file: ${cid.toString()}`)

  // Now store the CAR file on NFT.Storage
  await client.storeCar(car)

  return cid;
}

async function main() {
  // const client = new NFTStorage({ token: NFT_STORAGE_TOKEN })

  // const imageFiles = await readImages()
  // const imagesCID = await uploadFiles(client, imageFiles)

  // console.log(imagesCID.toString());

  // const metadataJSONs = generateNFTMetadata(imagesCID, imageFiles, "Cool contract", "Cool NFT contract for you")

  // const metaCID = await uploadMetadata(client, metadataJSONs)

  const testNFT = await ethers.deployContract("CoolContract", []);
  await testNFT.waitForDeployment();

  console.log(
    `TestNFT deployed to ${testNFT.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
