// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IVRF.sol";

contract RockPaperScissors is Ownable {
    // === STRUCTS ===
    struct Bet {
        uint256 round;
        uint256 player_0_nonce;
        uint256 player_1_nonce;
        address player_0;
        address player_1;
        uint256 amount;
        uint256 block_number;
    }

    // === STATES ===
    IVRF public immutable vrf;

    mapping(address => mapping(uint256 => mapping(uint256 => Bet)))
        public userRoundNoncePendingBet;
    mapping(address => mapping(uint256 => mapping(uint256 => Bet)))
        public userRoundNonceBet;

    constructor(address _vrf) {
        require(_vrf != address(0), "null vrf");
        vrf = IVRF(_vrf);
    }

    // === VIEWS ===

    // === VIEWS (PRIVATE) ===
    function _parse(uint256 _round, uint256 _nonce)
        private
        view
        returns (
            address player,
            uint256 player_nonce,
            address opponent,
            uint256 opponent_nonce,
            uint256 player_block_number,
            uint256 opponent_block_number,
            uint256 round,
            uint256 amount
        )
    {
        Bet memory player_bet = userRoundNonceBet[msg.sender][_round][_nonce];

        player = msg.sender;
        if (player_bet.player_0 == msg.sender) {
            player_nonce = player_bet.player_0_nonce;
            opponent = player_bet.player_1;
            opponent_nonce = player_bet.player_1_nonce;
        } else {
            player_nonce = player_bet.player_1_nonce;
            opponent = player_bet.player_0;
            opponent_nonce = player_bet.player_0_nonce;
        }

        Bet memory opponent_bet = userRoundNonceBet[opponent][_round][
            opponent_nonce
        ];

        player_block_number = player_bet.block_number;
        opponent_block_number = opponent_bet.block_number;

        require(
            player_bet.round == opponent_bet.round,
            "_parse:: mismatch round"
        );
        round = player_bet.round;
        require(
            player_bet.amount == opponent_bet.amount,
            "_parse:: mismatch amount"
        );
        amount = player_bet.amount;
    }

    // === MUTATIVES ===

    // player_1 (responder)
    function playerDeposit(
        uint256 _round,
        uint256 _nonce,
        address opponent
    ) public payable {}

    function playerWithdraw(uint256 _round, uint256 _nonce) public {}

    function concludeGame(uint256 _round, uint256 _nonce) public {
        (
            address player,
            uint256 player_nonce,
            address opponent,
            uint256 opponent_nonce,
            uint256 player_block_number,
            uint256 opponent_block_number,
            uint256 round,
            uint256 amount
        ) = _parse(_round, _nonce);
        delete userRoundNonceBet[player][round][player_nonce];
        delete userRoundNonceBet[opponent][round][opponent_nonce];

        // TODO Enum
        /*
        0 = Rock
        1 = Paper
        2 = Scissors
        */
        uint256 player_choice = vrf.generate(
            0,
            2,
            round,
            player_nonce,
            abi.encodePacked(amount, blockhash(player_block_number))
        );
        uint256 opponent_choice = vrf.generate(
            0,
            2,
            round,
            opponent_nonce,
            abi.encodePacked(amount, blockhash(opponent_block_number))
        );

        // TODO rock-paper-scissors logic
        // TODO transfer tokens accordingly
    }
}
