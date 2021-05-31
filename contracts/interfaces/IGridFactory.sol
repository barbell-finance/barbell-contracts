// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGridFactory {
    event GridCreated(address indexed tokenT, 
                      address indexed tokenU, 
                      address indexed grid);

    // TODO: owner()?
    function getOwner() external view returns (address);

    function feeTo() external view returns (address);
    function setFeeTo(address) external;

    function bot() external view returns (address);
    function setBot(address) external;

    function allGrids(uint256) external view returns (address grid);
    function allGridsLength() external view returns (uint256);
    function createFixedRateGrid(address _tokenT, address _tokenU,
        uint256 _j, uint256 _k) external returns (address);
}
