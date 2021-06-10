// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

interface ISwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
