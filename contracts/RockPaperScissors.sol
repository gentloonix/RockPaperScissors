// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IVRF.sol";

contract RockPaperScissors is Ownable {
    // === STRUCTS ===
    struct Bet {
        uint256 round;
        uint256 nonce;
        address player_0;
        address player_1;
        uint256 amount;
        uint256 block_number;
    }

    // === STATES ===
    IVRF public immutable vrf;

    mapping(address => mapping(uint256 => mapping(uint256 => Bet)))
        public userRoundNonceBet;

    constructor(address _vrf) {
        require(_vrf != address(0), "null vrf");
        vrf = IVRF(_vrf);
    }

    // === MUTATIVES ===

    // player_0
    function player0Deposit(
        uint256 _round,
        uint256 _nonce,
        address _player_1
    ) public payable {}

    function player0Withdraw(
        uint256 _round,
        uint256 _nonce,
        address _player_1
    ) public {}

    // player_1
    function player1Deposit(
        uint256 _round,
        uint256 _nonce,
        address _player_0
    ) public payable {}

    function player1Withdraw(
        uint256 _round,
        uint256 _nonce,
        address _player_0
    ) public {}

    function concludeGame() public {}
}
