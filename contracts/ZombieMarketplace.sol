pragma solidity ^0.4.25;

import "./ownable.sol";

/**
 * @title Minimal interface to interact with the existing ZombieOwnership ERC721 contract
 */
interface ZombieOwnershipInterface {
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function ownerOf(uint256 _tokenId) external view returns (address);
}

/**
 * @title ZombieMarketplace
 * @dev Simple marketplace to list and buy zombies from the existing
 *      `ZombieOwnership` ERC721 contract using ETH.
 */
contract ZombieMarketplace is Ownable {

  ZombieOwnershipInterface public zombieContract;

  struct Listing {
    address seller;
    uint256 price; // in wei
  }

  // tokenId => Listing
  mapping (uint256 => Listing) public listings;

  event Listed(uint256 indexed zombieId, address indexed seller, uint256 price);
  event Delisted(uint256 indexed zombieId, address indexed seller);
  event Sold(uint256 indexed zombieId, address indexed seller, address indexed buyer, uint256 price);

  constructor(address _zombieContract) public {
    require(_zombieContract != address(0));
    zombieContract = ZombieOwnershipInterface(_zombieContract);
  }

  /**
   * @dev Owner can update the underlying ZombieOwnership contract address if needed.
   */
  function setZombieContract(address _zombieContract) external onlyOwner {
    require(_zombieContract != address(0));
    zombieContract = ZombieOwnershipInterface(_zombieContract);
  }

  /**
   * @dev List a zombie for sale. Caller must be the current owner and must have
   *      approved this marketplace contract to transfer the token.
   */
  function listZombie(uint256 _zombieId, uint256 _price) external {
    require(_price > 0);
    address owner = zombieContract.ownerOf(_zombieId);
    require(owner == msg.sender);

    // The owner must first call approve(marketplace, _zombieId) on the ZombieOwnership contract.
    // Once approved, the marketplace can transfer the token into escrow.
    zombieContract.transferFrom(msg.sender, address(this), _zombieId);

    listings[_zombieId] = Listing({
      seller: msg.sender,
      price: _price
    });

    emit Listed(_zombieId, msg.sender, _price);
  }

  /**
   * @dev Cancel an existing listing and return the zombie to the seller.
   */
  function cancelListing(uint256 _zombieId) external {
    Listing storage listing = listings[_zombieId];
    require(listing.seller != address(0));
    require(listing.seller == msg.sender);

    delete listings[_zombieId];

    // Transfer zombie back to the seller.
    zombieContract.transferFrom(address(this), msg.sender, _zombieId);

    emit Delisted(_zombieId, msg.sender);
  }

  /**
   * @dev Buy a listed zombie by paying the exact asking price in ETH.
   */
  function buyZombie(uint256 _zombieId) external payable {
    Listing storage listing = listings[_zombieId];
    require(listing.seller != address(0));
    require(msg.value == listing.price);

    address seller = listing.seller;
    uint256 price = listing.price;

    // Clear listing before external calls to prevent re-entrancy issues.
    delete listings[_zombieId];

    // Transfer zombie from marketplace escrow to buyer.
    zombieContract.transferFrom(address(this), msg.sender, _zombieId);

    // Pay the seller.
    seller.transfer(price);

    emit Sold(_zombieId, seller, msg.sender, price);
  }
}

