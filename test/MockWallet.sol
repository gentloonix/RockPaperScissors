// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract MockWallet {
    function call(
        address target,
        bytes memory data,
        uint256 value
    ) public {
        Address.functionCallWithValue(target, data, value);
    }

    fallback() external payable {}

    receive() external payable {}
}
