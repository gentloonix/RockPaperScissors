// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/VRF.sol";
import "../contracts/RockPaperScissors.sol";

contract MockRockPaperScissors {
    IVRF public immutable vrf;
    RockPaperScissors public immutable game;

    constructor() {
        vrf = new VRF(address(this), address(this));
        game = new RockPaperScissors(address(vrf));
    }

    function testAll() public {
    }
}
