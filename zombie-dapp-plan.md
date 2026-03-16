## Goal

Build a fully working CryptoZombies-style DApp where:
- Zombies are real on-chain NFTs.
- A local kitty contract is used for feeding / battles.
- A simple on-chain zombie marketplace lets users list and buy zombies with ETH.
- The existing `index.html` UI talks to these contracts via MetaMask.

## Architecture Overview

- **Frontend**: Single-page app in `index.html`, served by `http-server`, using `ethers.js` and MetaMask.
- **Contracts** (deployed to Ganache or Sepolia via Remix):
  - `ZombieNFT`: ERC721-like NFT that mints and tracks zombie ownership and DNA.
  - `LocalKittyCore`: Local kitty contract that stores kitty genes and implements `getKitty(...)` like CryptoZombies.
  - `ZombieMarketplace`: Marketplace contract that lets users list and buy `ZombieNFT` tokens with ETH.
- **Wallet / Network**:
  - MetaMask connected to the same network as the deployed contracts (Ganache or Sepolia testnet).
  - `index.html` hardcodes contract addresses and ABIs for all three contracts.

## Step 1 – Add Smart Contracts

### 1.1 `ZombieNFT` (on-chain zombies)

- Create `contracts/ZombieNFT.sol`:
  - Minimal ERC721-like implementation (owner mapping, balance mapping, transfer functions).
  - `struct Zombie { uint256 dna; }` and array `zombies`.
  - `event ZombieCreated(uint256 indexed zombieId, address indexed owner, uint256 dna);`
  - `function createRandomZombie()` (or `createZombie()`):
    - Generates pseudo-random DNA using `block.timestamp` and sender address.
    - Mints a new token to `msg.sender`.
    - Emits `ZombieCreated` with the new `zombieId` and `dna`.

### 1.2 `LocalKittyCore`

- Create `contracts/LocalKittyCore.sol`:
  - Use the earlier interface compatible with CryptoZombies:
    - `function getKitty(uint256 _id) external view returns (...)`
  - `struct Kitty { uint256 genes; uint64 birthTime; uint32 matronId; uint32 sireId; uint16 generation; }`
  - An internal `_createKitty(...)` and public `createKittyGen0(uint256 _genes)` restricted to contract owner.

### 1.3 `ZombieMarketplace`

- Create `contracts/ZombieMarketplace.sol`:
  - Interface for the NFT: `function transferFrom(address from, address to, uint256 tokenId) external;` and `function ownerOf(uint256 tokenId) external view returns (address);`
  - `struct Listing { address seller; uint256 price; }`
  - `mapping(uint256 => Listing) public listings;`
  - `event Listed(uint256 indexed zombieId, address indexed seller, uint256 price);`
  - `event Sold(uint256 indexed zombieId, address indexed seller, address indexed buyer, uint256 price);`
  - `function listZombie(uint256 zombieId, uint256 price)`:
    - Require `msg.sender` is `ownerOf(zombieId)`.
    - Transfer zombie from seller to marketplace contract.
    - Store `Listing`.
  - `function buyZombie(uint256 zombieId) external payable`:
    - Require listing exists and `msg.value == price`.
    - Pay ETH to seller.
    - Transfer zombie from marketplace to buyer.
    - Delete listing and emit `Sold`.

## Step 2 – Deploy Contracts (Remix + Ganache or Sepolia)

1. Start **Ganache** (or connect MetaMask to **Sepolia**).
2. Open [Remix](https://remix.ethereum.org) in your browser.
3. Create three files inside Remix:
   - `ZombieNFT.sol`
   - `LocalKittyCore.sol`
   - `ZombieMarketplace.sol`
4. Compile each contract with Solidity `^0.8.x`.
5. In Remix **Deploy & Run**:
   - Set Environment to **Injected Provider - MetaMask** (Ganache or Sepolia).
   - Deploy `ZombieNFT` → copy its address.
   - Deploy `LocalKittyCore` → copy its address.
   - Deploy `ZombieMarketplace`, passing the `ZombieNFT` address into the constructor (if needed), then copy its address.
6. (Optional) Use Remix to call:
   - `LocalKittyCore.createKittyGen0(genes)` a few times to create kitties.

You will paste these three addresses into `index.html` in Step 3.

## Step 3 – Wire Frontend to Contracts

### 3.1 Load ethers.js and contract constants

- In `index.html`:
  - Add `<script src="https://cdn.jsdelivr.net/npm/ethers@5.7.2/dist/ethers.umd.min.js"></script>` before your main `<script>` block.
  - Inside the `<script>` block, define:
    - `const ZOMBIE_NFT_ADDRESS = "PASTE_ZOMBIE_NFT_ADDRESS_HERE";`
    - `const KITTY_ADDRESS = "PASTE_LOCAL_KITTY_ADDRESS_HERE";`
    - `const MARKETPLACE_ADDRESS = "PASTE_MARKETPLACE_ADDRESS_HERE";`
    - `const ZOMBIE_NFT_ABI = [ ... ];`
    - `const KITTY_ABI = [ ... ];`
    - `const MARKETPLACE_ABI = [ ... ];`

### 3.2 Update `connectWallet`

- Replace the current raw `window.ethereum.request` logic with:
  - Create `provider = new ethers.providers.Web3Provider(window.ethereum);`
  - Request accounts and set `account`.
  - Create `signer = provider.getSigner();`
  - Initialize:
    - `zombieContract = new ethers.Contract(ZOMBIE_NFT_ADDRESS, ZOMBIE_NFT_ABI, signer);`
    - `kittyContract = new ethers.Contract(KITTY_ADDRESS, KITTY_ABI, signer);`
    - `marketplaceContract = new ethers.Contract(MARKETPLACE_ADDRESS, MARKETPLACE_ABI, signer);`

### 3.3 On-chain zombie creation

- Update `createZombie()`:
  - Require `account` is connected.
  - Call `const tx = await zombieContract.createRandomZombie();`
  - `const receipt = await tx.wait();`
  - Read the `ZombieCreated` event from `receipt.events` to get `zombieId` and `dna`.
  - Push `{ id: zombieId, name: "Zombie #" + (zombies.length+1), dna, attack, defense, price: null }` into the UI array and call `displayZombies()`.
- Update `createArmy()` to call `createZombie()` N times (already present).

### 3.4 On-chain kitties and feeding (optional UI)

- Add a button or reuse `createKitty()` JS to:
  - For demo, still generate random DNA but also call `LocalKittyCore.createKittyGen0(genes)` from Remix or via JS.
  - For fighting / feeding:
    - Front-end can call a `feedOnKitty(zombieId, kittyId)` function on `ZombieNFT` (if implemented) or keep battle logic off-chain and use only kitty genes for display.

## Step 4 – On-chain Marketplace Integration

### 4.1 Update `sellZombie(index)`

- Use `zombies[index].id` as the token ID.
- Ask user for a price in ETH and convert to wei with `ethers.utils.parseEther(priceInEthString)`.
- Call:
  - `const tx = await marketplaceContract.listZombie(tokenId, priceWei);`
  - `await tx.wait();`
- Update local `zombies[index].price = priceWei;` and refresh UI.

### 4.2 Update `buyZombie(index)`

- Read `tokenId` and `priceWei` from `zombies[index]` or directly from `marketplaceContract.listings(tokenId)`.
- Call:
  - `const tx = await marketplaceContract.buyZombie(tokenId, { value: priceWei });`
  - `await tx.wait();`
- Clear `zombies[index].price = null;` and refresh UI.

## Step 5 – Run and Demo Instructions

1. **Start network & contracts**
   - Start Ganache **or** connect MetaMask to Sepolia.
   - Deploy `ZombieNFT`, `LocalKittyCore`, `ZombieMarketplace` using Remix as in Step 2.
   - Paste their addresses into `index.html` constants.
2. **Serve the frontend**
   - From `DApp` folder:
     - Run `http-server` (already installed) or `npx http-server . -p 8080`.
   - Open `http://localhost:8080/index.html` in the same browser as MetaMask.
3. **Connect & demo**
   - Click `🦊 Connect MetaMask` and approve.
   - Click **Create Zombie** / **Create Army**:
     - MetaMask should show a transaction for `createRandomZombie`.
     - After confirmation, new zombies appear in the UI.
   - (Optional) Use Remix to create kitties or wire `createKitty()` to `LocalKittyCore`.
   - Click **Sell** on a zombie:
     - Input price in ETH, confirm MetaMask tx.
   - Switch to a second MetaMask account (same network) and click **Buy** on that zombie:
     - Confirm the `buyZombie` tx and see ownership / UI update.

This plan keeps your existing UI while moving the key game elements—zombies, kitties, and marketplace—onto real smart contracts that MetaMask interacts with.

