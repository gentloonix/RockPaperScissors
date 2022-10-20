// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract VRF is AccessControl {
    // === CONSTANTS ===
    bytes32 public constant MANAGER_ROLE =
        bytes32(uint256(keccak256("vrf.manager")) - 1);
    bytes32 public constant PROPOSER_ROLE =
        bytes32(uint256(keccak256("vrf.proposer")) - 1);
    bytes32 public constant ATTESTOR_ROLE =
        bytes32(uint256(keccak256("vrf.attestor")) - 1);

    // === STATES ===
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

    function isRoundValid(uint256 _round) public view returns (bool) {
        return roundHash[_round] != bytes32(0);
    }

    function isRoundOpen(uint256 _round) public view returns (bool) {
        return isRoundValid(_round) && roundSecret[_round] == bytes32(0);
    }

    function generate(
        uint256 _min,
        uint256 _max,
        uint256 _round,
        uint256 _nonce,
        bytes memory _entropy
    ) public view returns (uint256) {
        require(_max > _min, "generate:: invalid range");

        require(isRoundValid(_round), "generate:: round is not proposed");
        require(!isRoundOpen(_round), "generate:: round is not attested");

        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        roundHash[_round],
                        roundSecret[_round],
                        _nonce,
                        _entropy
                    )
                )
            ) % (_max - _min)) + _min;
    }

    // === MUTATIVES (RESTRICTED) ===
    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(MANAGER_ROLE)
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(MANAGER_ROLE)
    {
        _revokeRole(role, account);
    }

    function proposeRound(uint256 _round, bytes32 _hash)
        external
        onlyRole(PROPOSER_ROLE)
    {
        require(!isRoundValid(_round), "propose:: proposed");

        roundHash[_round] = _hash;
    }

    function attestRound(uint256 _round, bytes32 _secret)
        external
        onlyRole(ATTESTOR_ROLE)
    {
        require(isRoundValid(_round), "attest:: not proposed");
        require(isRoundOpen(_round), "attest:: attested");

        bytes32 _hash = computeHash(_secret);
        require(roundHash[_round] == _hash, "attest:: wrong secret");

        roundHash[_round] = _hash;
    }
}
