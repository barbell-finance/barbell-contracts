pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./ISwapPair.sol";
import "./ISwapRouter.sol";
import "./IGridFactory.sol";

interface IGridPair {
    event Deposit (address indexed addr, uint256 t, uint256 u, uint256 newS);
    event Withdraw(address indexed addr, uint256 t, uint256 u, uint256 newS);
    event Buy (uint256 t, uint256 u, uint256 minT, uint256 maxU);
    event Sell(uint256 t, uint256 u, uint256 maxT, uint256 minU);

    function factory() external view returns (IGridFactory);
    function tokenT() external view returns (IERC20);
    function tokenU() external view returns (IERC20);
    function swapPair() external view returns (ISwapPair);
    function swapRouter() external view returns (ISwapRouter);

    function totalShares() external view returns (uint256 s);
    function balanceOf(address owner) external view returns (uint256 t, uint256 u, uint256 s);
    function lastSwap() external view returns (uint256 t, uint256 u, bool isBuy);

    function deposit(uint256 t, uint256 u) external;
    function withdraw(uint256 t, uint256 u) external;

    function buy()  external;
    function sell() external;
}
