// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./BaseGridFactory.sol";
import "./FixedRateGrid.sol";

contract GridFactory is BaseGridFactory {

    constructor(address _router) BaseGridFactory(_router) {}

    function createFixedRateGrid0(address _router, address _pair,
            address _tokenT, address _tokenU, uint256 _j, uint256 _k) internal override returns (address) {
        return address(new FixedRateGrid(_router, _pair, _tokenT, _tokenU, _j, _k));
    }

}
