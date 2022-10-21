// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/VRF.sol";
import "../contracts/RockPaperScissors.sol";
import "./MockWallet.sol";

contract MockRockPaperScissors {
    uint256 gameNonce = 0;

    IVRF public immutable vrf;
    RockPaperScissors public immutable game;
    MockWallet public immutable mockWallet;

    constructor() payable {
        require(msg.value >= 0.01 ether, "ether required");
        IVRF _vrf = new VRF(address(this), address(this));
        vrf = _vrf;
        game = new RockPaperScissors(address(_vrf));
        mockWallet = new MockWallet();
    }

    fallback() external payable {}

    receive() external payable {}

    function testDeposit() public {
        uint256 _round = 0;
        bytes32 _secret = bytes32(
            0x8f77668a9dfbf8d5848b9eeb4a7145ca96c6ed9236e4a773f6dcafa5132b2f91
        );

        uint256 _nonce = 0;

        vrf.proposeRound(_round, vrf.computeHash(_secret));

        game.deposit{value: 0.01 ether}(_round, _nonce, address(0), 0);
    }

    function testWithdrawPendingBet() public {
        uint256 _round = 1;
        bytes32 _secret = bytes32(
            0x8f77668a9dfbf8d5848b9eeb4a7145ca96c6ed9236e4a773f6dcafa5132b2f91
        );

        uint256 _nonce = 0;

        uint256 balanceBefore = address(this).balance;

        vrf.proposeRound(_round, vrf.computeHash(_secret));

        game.deposit{value: 0.01 ether}(_round, _nonce, address(0), 0);

        uint256 balanceAfter = address(this).balance;
        assert(balanceBefore - balanceAfter == 0.01 ether);

        game.withdrawPendingBet(_round, _nonce);
        assert(balanceBefore == address(this).balance);
    }

    function testGame() public {
        uint256 _round = 2;
        bytes32 _secret = bytes32(
            0x8f77668a9dfbf8d5848b9eeb4a7145ca96c6ed9236e4a773f6dcafa5132b2f91
        );

        uint256 balanceBefore = address(this).balance;

        vrf.proposeRound(_round, vrf.computeHash(_secret));

        game.deposit{value: 0.01 ether}(_round, gameNonce, address(0), 0);
        Address.sendValue(payable(address(mockWallet)), 0.01 ether);
        mockWallet.call(
            address(vrf),
            abi.encodeWithSignature(
                "deposit(uint256,uint256,address,uint256)",
                _round,
                gameNonce,
                address(this),
                gameNonce
            ),
            0.01 ether
        );
        gameNonce += 1;

        uint256 balanceAfter = address(this).balance;
        assert(balanceBefore - balanceAfter == 0.01 ether);

        vrf.attestRound(_round, _secret);

        game.concludeGame(_round, gameNonce);
        assert(balanceBefore == address(this).balance);

        // TODO Show results
    }
}
