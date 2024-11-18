// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract COIN100DeveloperTreasury is Ownable {
    IERC20 public coin100;
    uint256 public vestingStart;
    uint256 public vestingDuration = 730 days; // 2 years
    uint256 public totalAllocation;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(address _coin100, uint256 _totalAllocation) {
        require(_coin100 != address(0), "Invalid COIN100 address");
        coin100 = IERC20(_coin100);
        totalAllocation = _totalAllocation;
        vestingStart = block.timestamp;
    }

    function release() external onlyOwner {
        uint256 elapsedTime = block.timestamp - vestingStart;
        uint256 vestedAmount;

        if (elapsedTime >= vestingDuration) {
            vestedAmount = totalAllocation - released;
        } else {
            vestedAmount = (totalAllocation * elapsedTime) / vestingDuration - released;
        }

        require(vestedAmount > 0, "No tokens to release");

        released += vestedAmount;
        require(coin100.transfer(owner(), vestedAmount), "Transfer failed");

        emit TokensReleased(vestedAmount);
    }

    function getVestedAmount() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - vestingStart;
        if (elapsedTime >= vestingDuration) {
            return totalAllocation;
        } else {
            return (totalAllocation * elapsedTime) / vestingDuration;
        }
    }

    function getReleasableAmount() public view returns (uint256) {
        return getVestedAmount() - released;
    }
}
