require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with", deployer.address);

  const LionKing = await hre.ethers.getContractFactory("LionKing");

  const name = "Lion King";
  const symbol = "LIONK";
  const maxSupply = 5000; // change as you like
  const mintPrice = hre.ethers.utils.parseEther("0.03"); // price per NFT
  const maxPerTx = 5;
  const baseTokenURI = "ipfs://Qm.../metadata/"; // set later or empty
  const royaltyReceiver = deployer.address;
  const royaltyFeeNumerator = 500; // 5% (out of 10000)

  const contract = await LionKing.deploy(
    name,
    symbol,
    maxSupply,
    mintPrice,
    maxPerTx,
    baseTokenURI,
    royaltyReceiver,
    royaltyFeeNumerator
  );

  await contract.deployed();
  console.log("LionKing deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
