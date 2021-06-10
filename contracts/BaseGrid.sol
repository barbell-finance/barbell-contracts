// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "./interfaces/ISwapRouter.sol";
import "./interfaces/ISwapPair.sol";
import "./interfaces/IGridPair.sol";

// fit in one slot
struct UserInfo {
    uint192 shares;
    uint64  lastDepositTime; // in block
}

abstract contract BaseGrid is IGridPair, ReentrancyGuard {
    uint256 internal constant _10K = 10000;

    // TODO: set these params later
    bool    internal constant AUTO_BALANCE_UT   = true;
    uint256 internal constant DEPOSIT_LOCK_TIME = 1;    // in blocks, ~15s
    uint256 internal constant SERVICE_FEE_BPS   = 0;    // ‱
    uint256 internal constant WITHDRAW_FEE_BPS  = 0;    // ‱, WITHDRAWAL_FEE_BPS?
    uint256 internal constant PRICE_TOLERANCE   = 0;    // ‱


    IERC20       public immutable override tokenT;
    IERC20       public immutable override tokenU;
    ISwapPair    public immutable override swapPair;
    ISwapRouter  public immutable override swapRouter;
    IGridFactory public immutable override factory;

    uint256 public override totalShares;
    mapping(address => UserInfo) private users;

    constructor(address _tokenT, address _tokenU, address _swapPair, address _swapRouter) {
        factory  = IGridFactory(msg.sender);
        tokenT   = IERC20(_tokenT);
        tokenU   = IERC20(_tokenU);
        swapPair = ISwapPair(_swapPair);
        swapRouter = ISwapRouter(_swapRouter);

        // we trust grid factory
        // address token0 = ISwapPair(_swapPair).token0();
        // address token1 = ISwapPair(_swapPair).token1();
        // if (_tokenT == token0) {
        //     require(_tokenU == token1, "BG: tokenU != token1");
        // } else {
        //     require(_tokenT == token1, "BG: tokenT != token1");
        //     require(_tokenU == token0, "BG: tokenU != token0");
        // }
    }

    // TODO: use price oracle ?
    function getPrice() private view returns (uint256 t, uint256 u) {
        (uint112 r0, uint112 r1, ) = swapPair.getReserves();
        assert(r0 > 0 && r1 > 0);
        return address(tokenT) == swapPair.token0() ? (r0, r1) : (r1, r0);
    }

    function swap(IERC20 tokenA, uint256 amtA, uint256 minAmtB) internal returns (uint256 amtB) {
        IERC20 tokenB = (tokenA == tokenT) ? tokenU : tokenT;

        tokenA.approve(address(swapRouter), amtA); // TODO: TransferHelper.safeApprove() ?
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        uint[] memory results = swapRouter.swapExactTokensForTokens(amtA, 0, path, address(this), block.timestamp);
        amtB = results[1];

        // require(results[0] == amtA,    "BG: swap results[0] != amtA");
        // require(results[1] >= minAmtB, "BG: swap results[1] < minAmtB");
        // require(amtB >= minAmtB, string(abi.encodePacked(
        //     "BG: out:", amtA.toString(), ", minIn:", minAmtB.toString(), ", in:", amtB.toString())));
        require(amtB >= minAmtB, "BG: swap failed");
    }

    function collectFee(uint256 gotU) internal {
        if (SERVICE_FEE_BPS > 0) {
            address feeToAddr = factory.feeTo();
            if (feeToAddr != address(0)) {
                uint256 fee = gotU * SERVICE_FEE_BPS / _10K;
                totalShares += fee;
                // users[feeToAddr].shares += fee;
                UserInfo memory feeToUser = users[feeToAddr];
                feeToUser.shares += uint192(fee);
                users[feeToAddr] = feeToUser;
            }
        }
    }

    function lastDepositTime(address addr) public view returns (uint256) {
        return users[addr].lastDepositTime;
    }

    function balanceOf(address addr) external view override returns (uint256 t, uint256 u, uint256 s) {
        uint256 s0 = totalShares;
        if (s0 > 0) {
            uint256 t0 = tokenT.balanceOf(address(this));
            uint256 u0 = tokenU.balanceOf(address(this));
            s = users[addr].shares;
            t = (t0 * s) / s0;
            u = (u0 * s) / s0;
        }
    }

    function deposit(uint256 t, uint256 u) external override nonReentrant {
        require(t > 0 || u > 0, "BG: deposit 0");

        (uint256 pt, uint256 pu) = getPrice();
        uint256 s0 = totalShares;
        uint256 t0 = tokenT.balanceOf(address(this));
        uint256 u0 = tokenU.balanceOf(address(this));
        uint256 s = (s0 == 0) 
            ? (t * pu/pt) + u 
            : s0 * ((t * pu/pt) + u) / (t0 * pu/pt + u0);

        if (t > 0) { TransferHelper.safeTransferFrom(address(tokenT), msg.sender, address(this), t); }
        if (u > 0) { TransferHelper.safeTransferFrom(address(tokenU), msg.sender, address(this), u); }

        // balance t & u
        uint256 balancedT = t;
        uint256 balancedU = u;
        if (AUTO_BALANCE_UT) {        
            uint256 u1 = u0 + u;
            uint256 v1 = (t0 + t) * pu/pt;
            if (u > 0 && u1 > 3 * v1) {
                // u/2 -> t
                balancedU = u/2;
                balancedT += swap(tokenU, u/2, 0);
            } else if (t > 0 && v1 > 3 * u1) {
                // t/2 -> u
                balancedT = t/2;
                balancedU += swap(tokenT, t/2, 0);
            }
        }

        assert(s < 2**192);
        totalShares += s;
        UserInfo memory user = users[msg.sender];
        user.lastDepositTime = uint64(block.number);
        user.shares += uint192(s);
        users[msg.sender] = user;
        emit Deposit(msg.sender, t, u, user.shares, balancedT, balancedU);
    }

    function withdraw(uint256 t, uint256 u) external override nonReentrant {
        UserInfo memory user = users[msg.sender];
        require(block.number > user.lastDepositTime + DEPOSIT_LOCK_TIME,
            "BG: withdraw in lock time");
        require(t > 0 || u > 0, "BG: withdraw 0");

        (uint256 pt, uint256 pu) = getPrice();
        uint256 t0 = tokenT.balanceOf(address(this));
        uint256 u0 = tokenU.balanceOf(address(this));
        uint256 s0 = totalShares;
        uint256 s1 = user.shares;
        uint256 t1 = t0 * s1 / s0;
        uint256 u1 = u0 * s1 / s0;
        if (t > t1) { t = t1; }
        if (u > u1) { u = u1; }

        uint256 s = s0 * ((t * pu/pt) + u) / (t0 * pu/pt + u0);
        assert(s < 2**192);
        totalShares -= s;
        user.shares -= uint192(s);
        users[msg.sender] = user;

        // deduct fee
        if (WITHDRAW_FEE_BPS > 0) {
            t = t * (_10K - WITHDRAW_FEE_BPS) / _10K;
            u = u * (_10K - WITHDRAW_FEE_BPS) / _10K;
        }

        if (t > 0) { TransferHelper.safeTransfer(address(tokenT), msg.sender, t); }
        if (u > 0) { TransferHelper.safeTransfer(address(tokenU), msg.sender, u); }
        emit Withdraw(msg.sender, t, u, user.shares);
    }

}
