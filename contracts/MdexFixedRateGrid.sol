// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/mdex/IMdexGridPair.sol";
import "./interfaces/mdex/IMdexSwapMining.sol";
import "./interfaces/mdex/IMdexSwapRouter.sol";
import "./FixedRateGrid.sol";

contract MdexFixedRateGrid is FixedRateGrid, IMdexGridPair {
    IMdexSwapMining public immutable swapMining;

    constructor(
        address _router,
        address _pair,
        address _tokenT,
        address _tokenU,
        uint256 _j,
        uint256 _k
    ) FixedRateGrid(_router, _pair, _tokenT, _tokenU, _j, _k) {
        address swapMiningAddress = IMdexSwapRouter(_router).swapMining();
        swapMining = IMdexSwapMining(swapMiningAddress);
    }

    function swapRewardWithdraw() external override onlyBot {
        swapMining.takerWithdraw();
        IERC20 mdx = IERC20(swapMining.mdx());
        uint256 balance = mdx.balanceOf(address(this));
        TransferHelper.safeTransferFrom(address(mdx), address(this), factory.bot(), balance);
        emit RewardWithdraw(balance);
    }

    function getSwapReward() external view override returns (uint256) {
        uint256 length = swapMining.poolLength();
        uint256 sumReward;
        for (uint256 pid = 0; pid < length; ++pid) {
            (uint256 userSub, ) = swapMining.getUserReward(pid);
            sumReward += userSub;
        }
        return sumReward;
    }
}
