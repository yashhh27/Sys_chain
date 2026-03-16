const ZombieOwnership = artifacts.require("ZombieOwnership");
const LocalKittyCore = artifacts.require("LocalKittyCore");
const ZombieMarketplace = artifacts.require("ZombieMarketplace");

module.exports = async function (deployer, network, accounts) {
  // Deploy the main ZombieOwnership ERC721 contract
  await deployer.deploy(ZombieOwnership);
  const zombieOwnership = await ZombieOwnership.deployed();

  // Deploy the local kitty contract
  await deployer.deploy(LocalKittyCore);
  const localKitty = await LocalKittyCore.deployed();

  // Wire kitty contract into zombies so feedOnKitty uses LocalKittyCore
  await zombieOwnership.setKittyContractAddress(localKitty.address);

  // Deploy the marketplace, pointing it at the ZombieOwnership contract
  await deployer.deploy(ZombieMarketplace, zombieOwnership.address);
  const marketplace = await ZombieMarketplace.deployed();

  console.log("ZombieOwnership deployed at:", zombieOwnership.address);
  console.log("LocalKittyCore deployed at:", localKitty.address);
  console.log("ZombieMarketplace deployed at:", marketplace.address);
};

