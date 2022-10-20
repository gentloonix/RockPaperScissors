// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IVRF.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

contract VRF is IVRF, AccessControl {
    // === CONSTANTS ===
    bytes32 public constant PROPOSER_ROLE =
        bytes32(uint256(keccak256("vrf.proposer")) - 1);
    bytes32 public constant ATTESTOR_ROLE =
        bytes32(uint256(keccak256("vrf.attestor")) - 1);

    // === STATES ===
    mapping(uint256 => bytes32) public roundHash;
    mapping(uint256 => bytes32) public roundSecret;

    constructor(address _proposer, address _attestor) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(
            PROPOSER_ROLE,
            _proposer == address(0) ? msg.sender : _proposer
        );
        _setupRole(
            ATTESTOR_ROLE,
            _attestor == address(0) ? msg.sender : _attestor
        );
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

        require(isRoundValid(_round), "generate:: round is not valid");
        require(!isRoundOpen(_round), "generate:: round is not closed");

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
            ) % (_max - _min + 1)) + _min;
    }

    // === MUTATIVES (RESTRICTED) ===
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

        require(
            roundHash[_round] == computeHash(_secret),
            "attest:: wrong secret"
        );

        roundSecret[_round] = _secret;
    }
}
