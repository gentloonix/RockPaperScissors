// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VRF is Ownable {
    mapping(uint256 => bytes32) public roundHash;
    mapping(uint256 => bytes32) public roundSecret;

    // === VIEWS ===
    function computeHash(bytes32 _secret) public view returns (bytes32) {
        // salt (address(this)), _secret
        return keccak256(abi.encodePacked(address(this), _secret));
    }

    function isRound(uint256 _round) public view returns (bool) {
        return roundHash[_round] != bytes32(0);
    }

    function isRoundOpen(uint256 _round) public view returns (bool) {
        return isRound(_round) && roundSecret[_round] == bytes32(0);
    }

    // === MUTATIVES ===
    function propose(uint256 _round, bytes32 _hash) external onlyOwner {
        require(!isRound(_round), "propose:: proposed");

        roundHash[_round] = _hash;
    }

    function attest(uint256 _round, bytes32 _secret) external onlyOwner {
        require(isRound(_round), "attest:: not proposed");
        require(isRoundOpen(_round), "attest:: attested");

        bytes32 _hash = computeHash(_secret);
        require(roundHash[_round] == _hash, "attest:: wrong secret");
        roundHash[_round] = _hash;
    }
}
