// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

interface IMdexGridPair {
    event RewardWithdraw(uint256 s);

    function swapRewardWithdraw() external;
    function getSwapReward() external view returns (uint256);
}