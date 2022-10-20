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

    // === MUTATIVES ===

    // player_1 (responder)
    function playerDeposit(
        uint256 _round,
        uint256 _nonce,
        address _player_0
    ) public payable {
        require(
            _player_0 != msg.sender,
            "player1Deposit: cannot bet against yourself"
        );
    }

    function playerWithdraw(uint256 _round, uint256 _nonce) public {}

    function concludeGame(uint256 _round, uint256 _nonce) public {
        Bet memory player_bet = userRoundNonceBet[msg.sender][_round][_nonce];
        require(
            player_bet.block_number != 0,
            "concludeGame:: player bet not found"
        );
        delete userRoundNonceBet[msg.sender][_round][_nonce];

        uint256 player_nonce;
        uint256 opponent_nonce;
        address opponent;
        if (player_bet.player_0 == msg.sender) {
            player_nonce = player_bet.player_0_nonce;
            opponent_nonce = player_bet.player_1_nonce;
            opponent = player_bet.player_1;
        } else {
            player_nonce = player_bet.player_1_nonce;
            opponent_nonce = player_bet.player_0_nonce;
            opponent = player_bet.player_0;
        }
        address player = msg.sender;

        Bet memory opponent_bet = userRoundNonceBet[opponent][_round][
            opponent_nonce
        ];
        require(
            opponent_bet.block_number != 0,
            "concludeGame:: opponent bet not found"
        );
        delete userRoundNonceBet[opponent][_round][opponent_nonce];

        uint256 player_choice = vrf.generate(
            0,
            2,
            _round,
            player_nonce,
            abi.encodePacked(
                player_bet.amount,
                blockhash(player_bet.block_number)
            )
        );
        uint256 opponent_choice = vrf.generate(
            0,
            2,
            _round,
            opponent_nonce,
            abi.encodePacked(
                opponent_bet.amount,
                blockhash(opponent_bet.block_number)
            )
        );

        // TODO rock-paper-scissors logic
        // TODO transfer tokens accordingly
    }
}
