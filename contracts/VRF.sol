// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract VRF is AccessControl {
    bytes32 public constant MANAGER_ROLE =
        bytes32(uint256(keccak256("vrf.manager")) - 1);
    bytes32 public constant PROPOSER_ROLE =
        bytes32(uint256(keccak256("vrf.proposer")) - 1);
    bytes32 public constant ATTESTOR_ROLE =
        bytes32(uint256(keccak256("vrf.attestor")) - 1);

    mapping(uint256 => bytes32) public roundHash;
    mapping(uint256 => bytes32) public roundSecret;

    constructor() {
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(PROPOSER_ROLE, msg.sender);
        _setupRole(ATTESTOR_ROLE, msg.sender);
    }

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

    // === MUTATIVES (RESTRICTED) ===
    function propose(uint256 _round, bytes32 _hash) external {
        require(hasRole(PROPOSER_ROLE, msg.sender), "propose:: not proposer");

        require(!isRound(_round), "propose:: proposed");

        roundHash[_round] = _hash;
    }

    function attest(uint256 _round, bytes32 _secret) external {
        require(hasRole(ATTESTOR_ROLE, msg.sender), "attest:: not attestor");

        require(isRound(_round), "attest:: not proposed");
        require(isRoundOpen(_round), "attest:: attested");

        bytes32 _hash = computeHash(_secret);
        require(roundHash[_round] == _hash, "attest:: wrong secret");

        roundHash[_round] = _hash;
    }
}
