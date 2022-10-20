// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRF {
    // === VIEWS ===
    function computeHash(bytes32 _secret) external view returns (bytes32);

    function isRoundValid(uint256 _round) external view returns (bool);

    function isRoundOpen(uint256 _round) external view returns (bool);

    function generate(
        uint256 _min,
        uint256 _max,
        uint256 _round,
        uint256 _nonce,
        bytes memory _entropy
    ) external view returns (uint256);

    // === MUTATIVES (RESTRICTED) ===
    function proposeRound(uint256 _round, bytes32 _hash) external;

    function attestRound(uint256 _round, bytes32 _secret) external;
}
