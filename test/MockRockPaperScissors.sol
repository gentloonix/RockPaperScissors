// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/VRF.sol";
import "../contracts/RockPaperScissors.sol";

contract MockRockPaperScissors {
    IVRF public immutable vrf;
    RockPaperScissors public immutable game;

    constructor() payable {
        vrf = new VRF(address(this), address(this));
        game = new RockPaperScissors(address(vrf));
    }

    fallback() external payable {}

    receive() external payable {}

    function withdrawPendingBetDeposit() public {
        uint256 _round = 0;
        uint256 _nonce = 0;

        uint256 balanceBefore = address(this).balance;

        game.deposit{value: 1 ether}(_round, _nonce, address(0), 0);

        uint256 balanceAfter = address(this).balance;
        assert(balanceBefore - balanceAfter == 1 ether);

        game.withdrawPendingBet(_round, _nonce);
        assert(balanceBefore == address(this).balance);
    }
}
