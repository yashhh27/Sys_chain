pragma solidity ^0.4.25;

import "./ownable.sol";
import "./safemath.sol";

contract ZombieFactory is Ownable {

  using SafeMath for uint256;
  using SafeMath32 for uint32;
  using SafeMath16 for uint16;

  event NewZombie(uint zombieId, string name, uint dna);
  event ZombieRenamed(uint zombieId, string oldName, string newName);

  uint dnaDigits = 16;
  uint dnaModulus = 10 ** dnaDigits;
  uint cooldownTime = 1 days;

  struct Zombie {
    string name;
    uint dna;
    uint32 level;
    uint32 readyTime;
    uint16 winCount;
    uint16 lossCount;
  }

  Zombie[] public zombies;

  mapping (uint => address) public zombieToOwner;
  mapping (address => uint) public ownerZombieCount;

  modifier onlyOwnerOf(uint _zombieId) {
    require(zombieToOwner[_zombieId] == msg.sender);
    _;
  }

  function _createZombie(string _name, uint _dna) internal {
    uint id = zombies.push(
      Zombie(_name, _dna, 1, uint32(now + cooldownTime), 0, 0)
    ) - 1;

    zombieToOwner[id] = msg.sender;
    ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender].add(1);

    emit NewZombie(id, _name, _dna);
  }

  function _generateRandomDna(string _str) private view returns (uint) {
    uint rand = uint(keccak256(abi.encodePacked(_str, now, msg.sender, zombies.length)));
    return rand % dnaModulus;
  }

  // Multiple zombies allowed
  function createRandomZombie(string _name) public {
    require(bytes(_name).length > 0);

    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 100;

    _createZombie(_name, randDna);
  }

  // Rename by zombie owner
  function renameZombie(uint _zombieId, string _newName) public onlyOwnerOf(_zombieId) {
    require(_zombieId < zombies.length);
    require(bytes(_newName).length > 0);

    string memory oldName = zombies[_zombieId].name;
    zombies[_zombieId].name = _newName;

    emit ZombieRenamed(_zombieId, oldName, _newName);
  }
}