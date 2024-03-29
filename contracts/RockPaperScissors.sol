// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IVRF.sol";

contract RockPaperScissors is Ownable, ReentrancyGuard {
    // === ENUMS ===
    enum Result {
        Rock,
        Scissors,
        Paper
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

    // userRoundNoncePendingBet: pending bets, retractable
    mapping(address => mapping(uint256 => mapping(uint256 => Bet)))
        public userRoundNoncePendingBet;
    // userRoundNoncePendingBet: established bets, not retractable
    mapping(address => mapping(uint256 => mapping(uint256 => Bet)))
        public userRoundNonceBet;

    constructor(address _vrf) {
        require(_vrf != address(0), "null vrf");
        vrf = IVRF(_vrf);
    }

    // === VIEWS ===
    function getResult(
        uint256 _round,
        uint256 _nonce,
        address _player,
        uint256 _block_number
    ) public view returns (Result) {
        require(
            vrf.isRoundValid(_round) && !vrf.isRoundOpen(_round),
            "getResult:: round not valid or still open"
        );

        // input params as entropy
        // random number of 0 to 2, 1:1 Result mapping
        return
            Result(
                vrf.generate(
                    0,
                    2,
                    _round,
                    _nonce,
                    abi.encodePacked(_player, blockhash(_block_number))
                )
            );
    }

    // === UTILS ===
    // _getPair: parse established bet pairs
    // reverts on error
    function _getPair(
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
        Bet memory mPlayerBet = userRoundNonceBet[_player][_round][_nonce];
        require(
            mPlayerBet.player != address(0) &&
                mPlayerBet.opponent != address(0),
            "invalid player bet"
        );

        player = mPlayerBet.player;
        require(player == _player, "mismatch player");
        player_nonce = mPlayerBet.player_nonce;
        require(player_nonce == _nonce, "mismatch nonce");
        opponent = mPlayerBet.opponent;
        opponent_nonce = mPlayerBet.opponent_nonce;

        Bet memory mOpponentBet = userRoundNonceBet[opponent][_round][
            opponent_nonce
        ];
        require(
            mOpponentBet.player == mPlayerBet.opponent &&
                mOpponentBet.opponent == mPlayerBet.player,
            "invalid opponent bet"
        );

        player_block_number = mPlayerBet.block_number;
        require(player_block_number != 0, "invalid player bet");
        opponent_block_number = mOpponentBet.block_number;
        require(opponent_block_number != 0, "invalid opponent bet");

        round = _round;
        require(mPlayerBet.amount == mOpponentBet.amount, "mismatch amount");
        amount = mPlayerBet.amount;
    }

    // === MUTATIVES ===
    // deposit: place a pending bet or establish a bet pair with the desired opponent
    function deposit(
        uint256 _round,
        uint256 _player_nonce,
        address _opponent,
        uint256 _opponent_nonce
    ) public payable nonReentrant {
        address _player = msg.sender;

        require(
            vrf.isRoundValid(_round) && vrf.isRoundOpen(_round),
            "deposit:: round not valid or not open"
        );

        require(
            userRoundNoncePendingBet[_player][_round][_player_nonce]
                .block_number == 0,
            "deposit:: pending bet"
        );

        // place pending bet regardless if opponent pending bet exists
        // opponent pending bet is handled later
        userRoundNoncePendingBet[_player][_round][_player_nonce] = Bet(
            _player,
            _player_nonce,
            _opponent,
            _opponent_nonce,
            msg.value,
            block.number
        );

        // get records
        Bet memory mPendingBet = userRoundNoncePendingBet[_player][_round][
            _player_nonce
        ];
        Bet memory mOpponentPendingBet = userRoundNoncePendingBet[_opponent][
            _round
        ][_opponent_nonce];

        if (mOpponentPendingBet.block_number != 0) {
            require(
                mOpponentPendingBet.opponent == _player ||
                    mOpponentPendingBet.opponent == address(0),
                "deposit:: not opponent"
            );
            require(
                msg.value >= mOpponentPendingBet.amount,
                "deposit:: mismatch amount"
            );

            // refund user if overpaid
            if (msg.value > mOpponentPendingBet.amount) {
                Address.sendValue(
                    payable(_player),
                    msg.value - mOpponentPendingBet.amount
                );
            }

            // update values accordingly
            mOpponentPendingBet.opponent = _player;
            mOpponentPendingBet.opponent_nonce = _player_nonce;

            mPendingBet.amount = mOpponentPendingBet.amount;

            // clear records
            delete userRoundNoncePendingBet[_player][_round][_player_nonce];
            delete userRoundNoncePendingBet[_opponent][_round][_opponent_nonce];

            // set an established bet pair
            userRoundNonceBet[_player][_round][_player_nonce] = mPendingBet;
            userRoundNonceBet[_opponent][_round][
                _opponent_nonce
            ] = mOpponentPendingBet;
        }
    }

    function withdrawPendingBet(uint256 _round, uint256 _nonce) public {
        address _player = msg.sender;

        Bet memory mPendingBet = userRoundNoncePendingBet[_player][_round][
            _nonce
        ];
        require(mPendingBet.block_number != 0, "deposit:: no pending bet");

        delete userRoundNoncePendingBet[_player][_round][_nonce];

        Address.sendValue(payable(_player), mPendingBet.amount);
    }

    function concludeGame(uint256 _round, uint256 _nonce) public nonReentrant {
        address _player = msg.sender;

        require(
            vrf.isRoundValid(_round) && !vrf.isRoundOpen(_round),
            "concludeGame:: round not valid or still open"
        );

        // get records
        // reverts on invalid pair
        (
            address player,
            uint256 player_nonce,
            address opponent,
            uint256 opponent_nonce,
            uint256 player_block_number,
            uint256 opponent_block_number,
            uint256 round,
            uint256 amount
        ) = _getPair(_player, _round, _nonce);

        // clear records
        delete userRoundNonceBet[player][round][player_nonce];
        delete userRoundNonceBet[opponent][round][opponent_nonce];

        Result player_choice = getResult(
            round,
            player_nonce,
            player,
            player_block_number
        );
        Result opponent_choice = getResult(
            round,
            opponent_nonce,
            opponent,
            opponent_block_number
        );

        if (player_choice == opponent_choice) {
            // draw, refund
            Address.sendValue(payable(player), amount);
            Address.sendValue(payable(opponent), amount);
        } else {
            if (
                player_choice == Result.Paper && opponent_choice == Result.Rock
            ) {
                // player wins
                Address.sendValue(payable(player), amount * 2);
            } else if (
                opponent_choice == Result.Paper && player_choice == Result.Rock
            ) {
                // opponent wins
                Address.sendValue(payable(opponent), amount * 2);
            } else {
                uint256 player_choice_uint256 = uint256(player_choice);
                uint256 opponent_choice_uint256 = uint256(opponent_choice);
                // rock wins scissors, scissors win paper
                // rock = 0
                // scissors = 1
                // paper = 2
                // thus, smaller result wins
                if (player_choice_uint256 < opponent_choice_uint256) {
                    // player wins
                    Address.sendValue(payable(player), amount * 2);
                } else if (opponent_choice_uint256 < player_choice_uint256) {
                    // opponent wins
                    Address.sendValue(payable(opponent), amount * 2);
                } else {
                    revert("concludeGame:: unreachable");
                }
            }
        }
    }
}
