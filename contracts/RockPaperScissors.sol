// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IVRF.sol";

contract RockPaperScissors is Ownable {
    // === STRUCTS ===
    struct Bet {
        uint256 round;
        address player_0;
        address player_1;
        uint256 amount;
        uint256 blocknumber;
    }

    // === STATES ===
    IVRF public immutable vrf;

    mapping(address => Bet) public userPendingBet;
    mapping(address => Bet) public userBet;

    constructor(address _vrf) {
        require(_vrf != address(0), "null vrf");
        vrf = IVRF(_vrf);
    }

    // === MUTATIVES ===
    function depositBet(uint256 _round, address _opponent) public payable {}

    function withdrawBet(uint256 _round, address _opponent) public {}

    function acceptBet(uint256 _round, address _opponent) public payable {}

    function declineBet(uint256 _round, address _opponent) public {}
}
