pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/ISwapFactory.sol";
import "./interfaces/IGridFactory.sol";

abstract contract BaseGridFactory is Ownable, IGridFactory {

    address public router;
    address public override feeTo;
    address public override bot;

    mapping(bytes32 => address) private gridByKey;
    address[] public override allGrids;

    constructor(address _router) {
        router = _router;
        feeTo  = address(0);
        bot    = msg.sender;
    }

    function allGridsLength() external view override returns (uint256) {
        return allGrids.length;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function setFeeTo(address _feeTo) external override onlyOwner {
        feeTo = _feeTo;
    }

    function setBot(address _bot) external override onlyOwner {
        bot = _bot;
    }

    function createFixedRateGrid(address _tokenT, address _tokenU,
            uint256 _j, uint256 _k) external override onlyOwner returns (address) {

        bytes32 key = keccak256(abi.encodePacked(_tokenT, _tokenU, _j, _k));
        require(gridByKey[key] == address(0), "BGF: pair exists");

        ISwapFactory factory = ISwapFactory(ISwapRouter(router).factory());
        address pair = factory.getPair(_tokenT, _tokenU);
        require(pair != address(0), "BGF: swap pair doesn't exist");

        address grid = createFixedRateGrid0(router, pair, _tokenT, _tokenU, _j, _k);
        gridByKey[key] = grid;
        allGrids.push(grid);

        emit GridCreated(_tokenT, _tokenU, grid);
        return grid;
    }

    // TODO: find a better name
    function createFixedRateGrid0(address _router, address _pair,
            address _tokenT, address _tokenU, uint256 _j, uint256 _k) internal virtual returns (address);

}
