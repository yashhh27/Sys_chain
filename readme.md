# CryptoZombies DApp – Extended Version

## Overview

This project is an extended version of the CryptoZombies tutorial DApp.

Key features:

- **On‑chain Zombie NFTs**  
  - `ZombieOwnership` contract implements an ERC‑721–style NFT for zombies.
  - Users can create multiple zombies; each zombie has unique DNA and is owned by a wallet address.

- **Local Kitty Contract (CryptoKitties‑style)**  
  - `LocalKittyCore` mimics the original CryptoKitties interface.
  - It stores kitty genes on‑chain and can be used by the zombie system (backend‑ready).

- **On‑chain Zombie Marketplace**  
  - `ZombieMarketplace` lets users list zombies for sale and buy them with ETH.
  - Uses ERC‑721 `approve` + `transferFrom` flow for safe transfers.
  - ETH is transferred from buyer to seller on successful purchase.

- **Modern Single‑Page Frontend (index.html)**  
  - Sidebar UI with stats for number of zombies and kitties.
  - Zombie Barracks and Kitty Den sections with card‑style layout.
  - Connects to smart contracts via **MetaMask + ethers.js**.
  - Buttons for:
    - Connect MetaMask
    - Create Zombie / Create Army
    - Create Kitty (front‑end demo)
    - Zombie vs Zombie / Zombie vs Kitty battle (front‑end demo)
    - Rename / Remove / Sell / Buy for each zombie (see details below).

---

## Functionality Details

### Smart Contracts

- **ZombieOwnership (Zombie NFTs)**
  - Inherits from the CryptoZombies tutorial stack (`ZombieFactory`, `ZombieFeeding`, `ZombieAttack`, `ZombieHelper`, `ZombieOwnership`).
  - Important functions:
    - `createRandomZombie(string _name)`: mints a new zombie NFT with pseudo‑random DNA to `msg.sender`.
    - `getZombiesByOwner(address _owner)`: returns all zombie IDs owned by an address.
    - `zombies(uint256 id)`: returns zombie struct (name, dna, level, readyTime, winCount, lossCount).
    - `approve(address _approved, uint256 _tokenId)`: approves another address (e.g. marketplace) to transfer a token.

- **LocalKittyCore**
  - Local implementation of the `KittyInterface` used in the tutorial.
  - Stores kitty genes and metadata:
    - `createKittyGen0(uint256 _genes)`: owner‑only function to create Generation 0 kitties.
    - `getKitty(uint256 _id)`: returns full kitty data including `genes` (compatible with tutorial interface).

- **ZombieMarketplace**
  - Minimal marketplace for zombies.
  - References `ZombieOwnership` via a small interface.
  - Stores listings:
    - `struct Listing { address seller; uint256 price; }`
    - `mapping(uint256 => Listing) public listings;`
  - Functions:
    - `listZombie(uint256 zombieId, uint256 price)`:  
      - Requires caller to be current owner.
      - Requires the owner to have previously called `approve(marketplace, zombieId)` on `ZombieOwnership`.
      - Transfers the zombie into marketplace escrow and records the listing.
    - `cancelListing(uint256 zombieId)`:
      - Only seller can cancel.
      - Returns the zombie from escrow to seller.
    - `buyZombie(uint256 zombieId)`:
      - Requires `msg.value == listing.price`.
      - Transfers the zombie from escrow to buyer and sends ETH to seller.
      - Clears the listing.

---

### Frontend (index.html)

- **Connect MetaMask**
  - Button: `🦊 Connect MetaMask`
  - Uses `ethers.providers.Web3Provider(window.ethereum)` to:
    - Request accounts (`eth_requestAccounts`).
    - Create contract instances:
      - `ZombieOwnership` (zombieContract)
      - `ZombieMarketplace` (marketplaceContract)
  - Displays the connected address in the top battle banner.

- **Create Zombie / Create Army**
  - `Create Zombie`:
    - Calls `zombieContract.createRandomZombie("Zombie")`.
    - Waits for the transaction to be mined.
    - Calls `getZombiesByOwner(account)` and `zombies(id)` for each returned ID.
    - Renders a card for each zombie with image (via `robohash.org`) and DNA.
  - `Create Army`:
    - Loops `createZombie()` 5 times, resulting in multiple back‑to‑back MetaMask transactions.

- **Create Kitty**
  - `Create Kitty`:
    - Front‑end only: generates a kitty with random DNA and displays it in the “Kitty Den”.
    - Uses RoboHash images for kitty avatars.
    - Backend (`LocalKittyCore`) is prepared for on‑chain kitties, but UI keeps this as a demo view.

- **Zombie vs Zombie / Zombie vs Kitty**
  - `Zombie vs Zombie`:
    - Randomly picks two zombies from the local array and displays a battle result in the banner.
  - `Zombie vs Kitty`:
    - Randomly matches one zombie vs one kitty.
    - Uses attack/defense values from front‑end state.
  - These battles are **front‑end only** (no on‑chain changes) for an easy, fun demo.

- **Per‑Zombie Actions**
  - On each zombie card:
    - **Rename**
      - Prompts for a new name and updates the local `zombies` array, then re‑renders.
      - (Front‑end only; on‑chain rename remains available in contracts if extended later.)
    - **Remove**
      - Removes the zombie from the current UI list (`zombies.splice(index, 1)`).
      - Note: this does **not** burn on‑chain; after reconnect/refresh, `refreshZombiesFromChain` will reload all on‑chain zombies.
    - **Sell**
      - Prompts for a sale price in ETH.
      - Calls `zombieContract.approve(MARKETPLACE_ADDRESS, tokenId)`.
      - Then calls `marketplaceContract.listZombie(tokenId, priceWei)`.
      - After the tx confirms, updates local `zombies[index].price` and re‑renders.
    - **Buy**
      - Only shown when `z.price` is set.
      - Calls `marketplaceContract.buyZombie(tokenId, { value: z.price })`.
      - On success, `refreshZombiesFromChain()` reloads the zombies for the connected account, reflecting new ownership.

---

## How to Run the DApp

### Prerequisites

- **Node.js** and **npm** installed.
- **Truffle CLI** (via `npx` or global install).
- **Ganache** running locally (UI or CLI).
- **MetaMask** installed in your browser.

### 1. Start Ganache

1. Open Ganache.
2. Create or open a workspace with:
   - **Host**: `127.0.0.1`
   - **Port**: `7545`
3. Keep Ganache running for the entire session.

### 2. Configure MetaMask

1. Add a new network in MetaMask:
   - Network name: `Ganache` (any name)
   - RPC URL: `http://127.0.0.1:7545`
   - Chain ID: usually `1337` or `5777` (match Ganache settings)
   - Currency symbol: `ETH`
2. Import one of the private keys from Ganache into MetaMask (so the accounts match).

### 3. Compile & Deploy Contracts with Truffle

In a terminal from the project root (`c:\Users\ASHOK\Desktop\DApp`):

```bash
# Compile contracts
npx truffle compile

# Deploy to Ganache development network
npx truffle migrate --network development --reset