// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./interfaces/IGridPair.sol";
import "./BaseGrid.sol";

// price = u / t
struct Swap {
    uint120 t;
    uint120 u;
    bool isBuy;
}

contract FixedRateGrid is IGridPair, BaseGrid {

    // params
    uint256 public immutable j; // ‱
    uint256 public immutable k; // ‱

    Swap[] private swapStack;

    constructor(address _router, 
                address _pair, 
                address _tokenT, 
                address _tokenU, 
                uint256 _j, 
                uint256 _k) BaseGrid(_tokenT, _tokenU, _pair, _router) {
        (j, k)  = (_j, _k);
    }

    modifier onlyBot() {
        require(factory.bot() == msg.sender, "FRG: caller is not the bot");
        _;
    }

    // TODO: make swapStack public
    function getSwapStackSize() public view returns (uint256) {
        return swapStack.length;
    }
    function getSwapStackElem(uint256 i) public view returns (Swap memory) {
        return swapStack[i];
    }

    function lastSwap() external override view returns (uint256 t, uint256 u, bool isBuy) {
        if (swapStack.length > 0) {
            Swap memory swap = swapStack[swapStack.length - 1];
            (t, u, isBuy) = (swap.t, swap.u, swap.isBuy);
        }
    }

    function buy() external override onlyBot {
        bool lastIsBuy = false;
        uint256 u0 = tokenU.balanceOf(address(this));
        uint256 u;
        uint256 t;
        if (swapStack.length == 0) {
            u = u0 * k / _10K;
            t = 0;
        } else {
            Swap memory _lastSwap = swapStack[swapStack.length - 1];
            uint256 t1 = _lastSwap.t;
            uint256 u1 = _lastSwap.u;
            lastIsBuy = _lastSwap.isBuy;
            if (lastIsBuy) {
                u = u0 * k / _10K;
            } else {
                u = min(u0, u1);
                swapStack.pop(); // pop last sell
            }
            t = u * t1 * _10K / u1 / (_10K - j);
        }

        if (PRICE_TOLERANCE > 0) {
            t = t * (_10K - PRICE_TOLERANCE) / _10K;
        }

        uint256 gotT = swap(tokenU, u, t);
        if (t == 0) { t = gotT; }
        if (lastIsBuy || swapStack.length == 0) {
            pushSwap(t, u, true);
        }
        emit Buy(gotT, u, t, u);
    }

    function sell() external override onlyBot {
        bool lastIsSell = false;
        uint256 t0 = tokenT.balanceOf(address(this));
        uint256 u;
        uint256 t;
        if (swapStack.length == 0) {
            t = t0 * k / _10K;
            u = 0;
        } else {        
            Swap memory _lastSwap = swapStack[swapStack.length - 1];
            uint256 t1 = _lastSwap.t;
            uint256 u1 = _lastSwap.u;
            lastIsSell = !_lastSwap.isBuy;
            if (lastIsSell) {
                t = t0 * k / _10K;
            } else {
                t = min(t0, t1);
                swapStack.pop(); // pop last buy
            }
            u = t * u1 * (_10K + j) / t1 / _10K;
        }

        if (PRICE_TOLERANCE > 0) {
            u = u * (_10K - PRICE_TOLERANCE) / _10K;
        }

        uint256 gotU = swap(tokenT, t, u);
        if (u == 0) { u = gotU; }
        if (lastIsSell || swapStack.length == 0) {
            pushSwap(t, u, false);
        }
        emit Sell(t, gotU, t, u);

        collectFee(gotU);
    }

    function pushSwap(uint256 t, uint256 u, bool isBuy) private {
        assert(t < 2**120 && u < 2**120);
        swapStack.push(Swap(uint120(t), uint120(u), isBuy));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

}
