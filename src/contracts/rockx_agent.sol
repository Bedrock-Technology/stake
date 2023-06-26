// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "interfaces/iface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract RockXAgent is Initializable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    address public constant stakingContract = 0x4beFa2aA9c305238AA3E0b5D17eB20C045269E9d;   // RockX staking contract
    address public constant redeemContract = 0x98169228cB99Ed26c1043eD8Ca53A5Cb371D3B8D; 
    address public constant uniETHContract = 0xF1376bceF0f78459C0Ed0ba5ddce976F1ddF51F4; 

    // track ether debts to return to async caller
    struct Debt {
        address account;
        uint256 amount;
    }

    // FIFO of debts from redeemFromValidators
    mapping(uint256=>Debt) private etherDebts;
    uint256 private firstDebt;
    uint256 private lastDebt;
    mapping(address=>uint256) private userDebts;    // debts from user's perspective

    uint256 private totalDebts;             // track current unpaid debts

    /**
     * @dev This contract will not accept direct ETH transactions.
     */
    receive() external payable {
        revert("Do not send ETH here");
    }

    function initialize() initializer public {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        firstDebt = 1;
        lastDebt = 0;
    }

    /**
     * @dev pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev proxy to  mint xETH with ETH
     */
    function mint(uint256 minToMint, uint256 deadline) external payable nonReentrant whenNotPaused returns(uint256 minted) {
        return IRockXStaking(stakingContract).mint(minToMint, deadline);
    }

    /**
     * proxy to redeem 
     */
    function redeemFromValidators(uint256 ethersToRedeem, uint256 maxToBurn, uint256 deadline) external nonReentrant returns(uint256 burned) {
        return IRockXStaking(stakingContract).redeemFromValidators(ethersToRedeem, maxToBurn, deadline);
    }

    function _enqueueDebt(address account, uint256 amount) internal {
        // debt is paid in FIFO queue
        lastDebt += 1;
        etherDebts[lastDebt] = Debt({account:account, amount:amount});

        // track user debts
        userDebts[account] += amount;
        // track total debts
        totalDebts += amount;
    }

    function _dequeueDebt() internal returns (Debt memory debt) {
        require(lastDebt >= firstDebt, "SYS022");  // non-empty queue
        debt = etherDebts[firstDebt];
        delete etherDebts[firstDebt];
        firstDebt += 1;
    }

    /**
     * @dev pay debts for a given amount
     */
    function _payDebts(uint256 total) internal returns(uint256 amountPaid) {
        // ethers to pay
        for (uint i=firstDebt;i<=lastDebt;i++) {
            if (total == 0) {
                break;
            }

            Debt storage debt = etherDebts[i];

            // clean debts
            uint256 toPay = debt.amount <= total? debt.amount:total;
            debt.amount -= toPay;
            total -= toPay;
            userDebts[debt.account] -= toPay;
            amountPaid += toPay;

            // transfer money to debt contract
            IRockXRedeem(redeemContract).pay{value:toPay}(debt.account);

            // dequeue if cleared 
            if (debt.amount == 0) {
                _dequeueDebt();
            }
        }
        
        totalDebts -= amountPaid;
    }
}