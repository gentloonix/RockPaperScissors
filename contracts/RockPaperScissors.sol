// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IVRF.sol";

contract RockPaperScissors is Ownable {
    // === ENUMS ===
    enum Result {
        Rock,
        Paper,
        Scissors
    }

    // === STRUCTS ===
    struct Bet {
        address player;
        uint256 player_nonce;
        address opponent;
        uint256 opponent_nonce;
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
    function generateResult(
        uint256 _round,
        uint256 _nonce,
        uint256 _block_number
    ) public view returns (Result) {
        return
            Result(
                vrf.generate(
                    0,
                    2,
                    _round,
                    _nonce,
                    abi.encodePacked(blockhash(_block_number))
                )
            );
    }

    // === VIEWS PRIVATE ===
    function _parseBetPair(
        address _player,
        uint256 _round,
        uint256 _nonce
    )
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
        Bet memory player_bet = userRoundNonceBet[_player][_round][_nonce];
        require(
            player_bet.player != address(0) &&
                player_bet.opponent != address(0),
            "_parseBetPair:: invalid player bet"
        );

        player = _player;
        player_nonce = player_bet.player_nonce;
        require(
            player_nonce == _nonce,
            "_parseBetPair:: invalid player bet nonce"
        );
        opponent = player_bet.opponent;
        opponent_nonce = player_bet.opponent_nonce;

        Bet memory opponent_bet = userRoundNonceBet[opponent][_round][
            opponent_nonce
        ];
        require(
            opponent_bet.player != address(0) &&
                opponent_bet.opponent != address(0),
            "_parseBetPair:: invalid opponent bet"
        );

        player_block_number = player_bet.block_number;
        require(player_block_number != 0, "_parseBetPair:: missing player bet");
        opponent_block_number = opponent_bet.block_number;
        require(
            opponent_block_number != 0,
            "_parseBetPair:: missing opponent bet"
        );

        round = _round;
        require(
            player_bet.amount == opponent_bet.amount,
            "_parseBetPair:: mismatch amount"
        );
        amount = player_bet.amount;
    }

    // === MUTATIVES ===
    function deposit(
        uint256 _round,
        uint256 _player_nonce,
        address _opponent,
        uint256 _opponent_nonce
    ) public payable {
        require(
            userRoundNoncePendingBet[msg.sender][_round][_player_nonce]
                .block_number == 0,
            "deposit:: pending bet exists"
        );

        if (
            userRoundNoncePendingBet[_opponent][_round][_opponent_nonce]
                .opponent == msg.sender
        ) {}

        userRoundNoncePendingBet[msg.sender][_round][_player_nonce] = Bet(
            msg.sender,
            _player_nonce,
            _opponent,
            _opponent_nonce,
            msg.value,
            block.number
        );
    }

    function withdraw(uint256 _round, uint256 _nonce) public {
        Bet memory pendingBet = userRoundNoncePendingBet[msg.sender][_round][
            _nonce
        ];
        require(pendingBet.block_number != 0, "deposit:: pending bet missing");

        delete userRoundNoncePendingBet[msg.sender][_round][_nonce];

        Address.sendValue(payable(msg.sender), pendingBet.amount);
    }

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
        ) = _parseBetPair(msg.sender, _round, _nonce);
        delete userRoundNonceBet[player][round][player_nonce];
        delete userRoundNonceBet[opponent][round][opponent_nonce];

        Result player_choice = generateResult(
            round,
            player_nonce,
            player_block_number
        );
        Result opponent_choice = generateResult(
            round,
            opponent_nonce,
            opponent_block_number
        );

        // TODO rock-paper-scissors logic
        // TODO transfer tokens accordingly
    }
}
