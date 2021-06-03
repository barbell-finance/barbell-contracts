pragma solidity >=0.8.0;

interface IMdexSwapMining {
    function getUserReward(uint256 _pid) external view returns (uint256, uint256);
    function poolLength() external view returns (uint256);
    function mdx() external view returns (address);
    function takerWithdraw() external;
}
