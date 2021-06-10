// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyWETH is ERC20 {
    constructor(uint256 initialSupply) ERC20("My WETH", "WETH") {
        _mint(msg.sender, initialSupply);
    }
}
