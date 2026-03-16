pragma solidity ^0.4.25;

import "./ownable.sol";

/**
 * @title LocalKittyCore
 * @dev Simple local CryptoKitties-style contract implementing the KittyInterface
 *      expected by the CryptoZombies tutorial. Used so zombies can "feed on"
 *      kitties without relying on the real CryptoKitties contract.
 */
contract LocalKittyCore is Ownable {

  struct Kitty {
    uint256 genes;
    uint64 birthTime;
    uint32 matronId;
    uint32 sireId;
    uint16 generation;
  }

  Kitty[] public kitties;

  mapping (uint256 => address) public kittyIndexToOwner;

  event KittyCreated(
    uint256 indexed kittyId,
    address indexed owner,
    uint256 genes,
    uint256 matronId,
    uint256 sireId,
    uint256 generation
  );

  constructor() public {
    // Optional dummy kitty at index 0 so real IDs can start from 1 if desired.
    _createKitty(0, 0, 0, 0, address(0));
  }

  function _createKitty(
    uint256 _genes,
    uint256 _generation,
    uint256 _matronId,
    uint256 _sireId,
    address _owner
  )
    internal
    returns (uint256)
  {
    Kitty memory kitty = Kitty({
      genes: _genes,
      birthTime: uint64(now),
      matronId: uint32(_matronId),
      sireId: uint32(_sireId),
      generation: uint16(_generation)
    });

    uint256 newKittyId = kitties.push(kitty) - 1;
    kittyIndexToOwner[newKittyId] = _owner;

    emit KittyCreated(
      newKittyId,
      _owner,
      _genes,
      _matronId,
      _sireId,
      _generation
    );

    return newKittyId;
  }

  /**
   * @dev Public function for the contract owner to create Generation 0 kitties.
   *      You can call this from Remix or another script to seed the system.
   */
  function createKittyGen0(uint256 _genes)
    external
    onlyOwner
    returns (uint256)
  {
    return _createKitty(_genes, 0, 0, 0, msg.sender);
  }

  /**
   * @dev This matches the KittyInterface.getKitty(...) signature used in
   *      `zombiefeeding.sol`. Only a subset of the fields are meaningful for
   *      our use case; others are returned as simple defaults.
   */
  function getKitty(uint256 _id)
    external
    view
    returns (
      bool isGestating,
      bool isReady,
      uint256 cooldownIndex,
      uint256 nextActionAt,
      uint256 siringWithId,
      uint256 birthTime,
      uint256 matronId,
      uint256 sireId,
      uint256 generation,
      uint256 genes
    )
  {
    require(_id < kitties.length);

    Kitty storage kitty = kitties[_id];

    // For CryptoZombies, only `genes` really matters; other values
    // are provided as simple defaults.
    isGestating = false;
    isReady = true;
    cooldownIndex = 0;
    nextActionAt = 0;
    siringWithId = 0;
    birthTime = kitty.birthTime;
    matronId = kitty.matronId;
    sireId = kitty.sireId;
    generation = kitty.generation;
    genes = kitty.genes;
  }

  function totalSupply() external view returns (uint256) {
    return kitties.length;
  }
}

