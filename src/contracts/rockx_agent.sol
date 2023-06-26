// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "interfaces/iface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract RockXAgent is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    address public constant RockXStaking = 0x4beFa2aA9c305238AA3E0b5D17eB20C045269E9d;   // RockX staking contract

    /**
     * @dev proxy to  mint xETH with ETH
     */
    function mint(uint256 minToMint, uint256 deadline) external payable nonReentrant whenNotPaused returns(uint256 minted) {
        return IRockXStaking(RockXStaking).mint(minToMint, deadline);
    }

 
    /**
     * proxy to redeem 
     */
    function redeemFromValidators(uint256 ethersToRedeem, uint256 maxToBurn, uint256 deadline) external nonReentrant returns(uint256 burned) {
        return IRockXStaking(RockXStaking).redeemFromValidators(ethersToRedeem, maxToBurn, deadline);
    }
}