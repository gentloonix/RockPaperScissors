// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/VRF.sol";
import "../contracts/RockPaperScissors.sol";

contract MockRockPaperScissors {
    IVRF public immutable vrf;
    RockPaperScissors public immutable game;

    uint256 round = 0;

    constructor() {
        vrf = new VRF(address(this), address(this));
        game = new RockPaperScissors(address(vrf));
    }

    function withdrawPendingBetDeposit() public {
        uint256 balanceBefore = address(this).balance;

        game.deposit{value: 1 ether}(round, 0, address(0), 0);

        uint256 balanceAfter = address(this).balance;
        assert(balanceBefore - balanceAfter == 1 ether);

        game.withdrawPendingBet(round, 0);
        assert(balanceBefore == address(this).balance);
    }
}
