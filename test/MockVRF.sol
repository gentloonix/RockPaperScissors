// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/VRF.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract MockVRF {
    IVRF public immutable vrf;

    constructor() {
        vrf = new VRF(address(this), address(this));
    }

    function testAll() public {
        uint256 _round = 0;
        bytes32 _secret = bytes32(
            0x8f77668a9dfbf8d5848b9eeb4a7145ca96c6ed9236e4a773f6dcafa5132b2f91
        );
        bytes32 _entropy = bytes32(
            0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
        );

        assert(!vrf.isRoundValid(_round));
        assert(!vrf.isRoundOpen(_round));

        vrf.proposeRound(_round, vrf.computeHash(_secret));

        assert(vrf.isRoundValid(_round));
        assert(vrf.isRoundOpen(_round));

        vrf.attestRound(_round, _secret);

        assert(vrf.isRoundValid(_round));
        assert(!vrf.isRoundOpen(_round));

        assert(
            vrf.generate(0, 9999, _round, 0, abi.encodePacked(_entropy)) == 5223
        );
    }
}
