// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./VRF.sol";

contract RockPaperScissors is Ownable {
    VRF public vrf;

    constructor(address _vrf) {
        require(_vrf != address(0), "null vrf");
        vrf = VRF(_vrf);
    }
}
