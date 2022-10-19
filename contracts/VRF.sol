// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VRF is Ownable {
    mapping(uint256 => bytes32) public roundHash;
    mapping(uint256 => bytes32) public roundSecret;

    // === VIEWS ===
    function calculateHash(bytes32 _secret) public view returns (bytes32) {
        // salt (address(this)), _secret
        return keccak256(abi.encodePacked(address(this), _secret));
    }

    // === MUTATIVES ===
    function propose(uint256 _round, bytes32 _hash) external onlyOwner {
        require(roundHash[_round] == bytes32(0), "propose:: proposed");

        roundHash[_round] = _hash;
    }

    function attest(uint256 _round, bytes32 _secret) external onlyOwner {
        require(roundHash[_round] != bytes32(0), "attest:: not proposed");
        require(roundSecret[_round] == bytes32(0), "attest:: attested");

        bytes32 _hash = calculateHash(_secret);
        require(roundHash[_round] == _hash, "attest:: wrong secret");
        roundHash[_round] = _hash;
    }
}
