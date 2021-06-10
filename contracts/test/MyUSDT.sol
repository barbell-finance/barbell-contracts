// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyUSDT is ERC20 {
    constructor(uint256 initialSupply) ERC20("My USDT", "USDT") {
        _mint(msg.sender, initialSupply);
    }
}
