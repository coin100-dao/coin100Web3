// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title COIN100 (C100)
 * @notice A rebasing token representing the top 100 crypto market cap index.
 *         On each rebase, all balances scale proportionally to reflect changes
 *         in the top 100 market cap, ensuring each holder maintains their fraction.
 * 
 * New Features:
 * - Fee-Based Treasury Growth
 * - LP Rewards Allocation
 * - Governance Transition
 *
 * Tokenomics at Deployment:
 * - Total supply = initialMarketCap (M0)
 * - 3% of total supply to owner, 97% also to owner (total 100% to owner at start).
 *
 * Daily/periodic manual rebases:
 * - Admin calls `rebase(newMCap)` to adjust supply based on top 100 market cap.
 *
 * Governance Transition:
 * - Initially, owner is admin.
 * - A govContract can be set, sharing admin rights.
 */
contract COIN100 is Ownable, ReentrancyGuard, Pausable {
    // ---------------------------------------
    // Token metadata
    // ---------------------------------------
    string public constant name = "COIN100";
    string public constant symbol = "C100";
    uint8 public constant decimals = 18;

    // ---------------------------------------
    // Rebase state variables
    // ---------------------------------------
    uint256 private _totalSupply;         // Current total supply in "fragment" terms
    uint256 public lastMarketCap;         // Last known total market cap of top 100
    uint256 constant MAX_GONS = type(uint256).max / 1e18;
    uint256 private _gonsPerFragment;     // Gons per fragment scaling factor

    mapping(address => uint256) private _gonsBalances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Initial allocations
    uint256 public ownerAllocation;       // 3% of total supply
    uint256 public remainingAllocation;   // The other 97%

    // Governor contract address (initially none)
    address public govContract;

    // Treasury for fee collection
    address public treasury;

    // Future parameters for governance
    uint256 public rebaseFrequency;           // How often upkeep can be called
    bool public transfersWithFee;             // If true, transfers incur a fee
    uint256 public transferFeeBasisPoints;    // Fee in basis points (e.g., 100 = 1%)

    // ---------------------------------------
    // LP Reward Variables
    // ---------------------------------------
    mapping(address => bool) public liquidityPools;
    address[] public liquidityPoolList;
    uint256 public lpRewardPercentage;        // e.g., 5 means 5%
    uint256 public maxLpRewardPercentage = 10; // Maximum allowed reward percentage (e.g., 10%)

    // ---------------------------------------
    // Events
    // ---------------------------------------
    event Rebase(uint256 oldMarketCap, uint256 newMarketCap, uint256 ratio, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event GovernorContractSet(address indexed oldGovernor, address indexed newGovernor);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeParametersUpdated(bool transfersWithFee, uint256 transferFeeBasisPoints);
    event LiquidityPoolAdded(address indexed pool);
    event LiquidityPoolRemoved(address indexed pool);
    event LpRewardPercentageUpdated(uint256 newPercentage);
    event MaxLpRewardPercentageUpdated(uint256 newMaxPercentage);

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    constructor(uint256 initialMarketCap) Ownable(msg.sender) Pausable() ReentrancyGuard() {
        require(initialMarketCap > 0, "Initial mcap must be > 0");

        // Set initial total supply = initial market cap
        _totalSupply = initialMarketCap;
        lastMarketCap = initialMarketCap;

        // Calculate owner allocations
        ownerAllocation = (_totalSupply * 3) / 100;           // 3%
        remainingAllocation = _totalSupply - ownerAllocation; // 97%

        // Initialize gonsPerFragment
        _gonsPerFragment = MAX_GONS / _totalSupply;

        // Mint entire supply to owner
        uint256 totalGons = _totalSupply * _gonsPerFragment;
        _gonsBalances[owner()] = totalGons;

        emit Transfer(address(0), owner(), _totalSupply);

        // Initialize parameters
        rebaseFrequency = 1 days;                // Default once per day
        transfersWithFee = true;                 // Transfers incur a fee by default
        transferFeeBasisPoints = 100;            // Default 1% fee

        // Set treasury to owner initially
        treasury = owner();

        // Initialize LP reward parameters
        lpRewardPercentage = 5; // Example: 5%
    }

    // ---------------------------------------
    // Modifiers
    // ---------------------------------------
    modifier onlyAdmin() {
        // Only owner if no govContract set, else govContract or owner
        require(
            msg.sender == owner() || 
            (govContract != address(0) && msg.sender == govContract),
            "Not admin"
        );
        _;
    }

    // ---------------------------------------
    // ERC20 Standard Interface
    // ---------------------------------------
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _gonsBalances[account] / _gonsPerFragment;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "Transfer exceeds allowance");
        _transfer(from, to, amount);
        _approve(from, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decrease below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // ---------------------------------------
    // Internal Functions
    // ---------------------------------------
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "From zero");
        require(to != address(0), "To zero");
        require(balanceOf(from) >= amount, "Balance too low");

        uint256 gonsAmount = amount * _gonsPerFragment;

        _gonsBalances[from] -= gonsAmount;

        if (transfersWithFee && transferFeeBasisPoints > 0) {
            // Apply fee
            uint256 feeGons = (gonsAmount * transferFeeBasisPoints) / 10000;
            uint256 gonsAfterFee = gonsAmount - feeGons;

            // Send fee to treasury
            _gonsBalances[treasury] += feeGons;

            // Remaining to recipient
            _gonsBalances[to] += gonsAfterFee;

            uint256 feeAmount = feeGons / _gonsPerFragment;
            uint256 recipientAmount = gonsAfterFee / _gonsPerFragment;

            emit Transfer(from, treasury, feeAmount);
            emit Transfer(from, to, recipientAmount);
        } else {
            // No fee, direct transfer
            _gonsBalances[to] += gonsAmount;
            emit Transfer(from, to, amount);
        }
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "Owner zero");
        require(spender != address(0), "Spender zero");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    // ---------------------------------------
    // Rebase Function (Manual Upkeep by Admin)
    // ---------------------------------------
    /**
     * @notice Manually update the market cap and rebase all balances.
     * @param newMarketCap The new total market cap of top 100 cryptos.
     */
    function rebase(uint256 newMarketCap) external onlyAdmin nonReentrant whenNotPaused {
        require(newMarketCap > 0, "Mcap must be > 0");
        uint256 oldMarketCap = lastMarketCap;
        uint256 oldSupply = _totalSupply;

        // Calculate the new supply based on market cap ratio
        uint256 ratioScaled = (newMarketCap * 1e18) / oldMarketCap;
        uint256 newSupply = (oldSupply * ratioScaled) / 1e18;
        require(newSupply > 0, "New supply must be > 0");

        // Calculate the difference in supply
        uint256 supplyDelta;
        bool isIncrease;
        if (newSupply > oldSupply) {
            supplyDelta = newSupply - oldSupply;
            isIncrease = true;
        } else {
            supplyDelta = oldSupply - newSupply;
            isIncrease = false;
        }

        // Update gonsPerFragment based on the new supply
        _gonsPerFragment = MAX_GONS / newSupply;

        // Update total supply and last market cap
        _totalSupply = newSupply;
        lastMarketCap = newMarketCap;

        emit Rebase(oldMarketCap, newMarketCap, ratioScaled, block.timestamp);

        // If supply is increasing, allocate rewards to liquidity pools
        if (isIncrease && lpRewardPercentage > 0 && liquidityPoolList.length > 0) {
            uint256 rewardAmount = (supplyDelta * lpRewardPercentage) / 100;
            _allocateRewardsToLPs(rewardAmount);
        }
    }

    /**
     * @notice Allocate rewards to liquidity pools proportionally based on their current holdings.
     * @param rewardAmount The total amount of tokens to distribute as rewards.
     */
    function _allocateRewardsToLPs(uint256 rewardAmount) internal {
        uint256 totalLpSupply = 0;

        // Calculate the total C100 held by all liquidity pools
        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            totalLpSupply += balanceOf(liquidityPoolList[i]);
        }

        require(totalLpSupply > 0, "Total LP supply is zero");

        // Distribute rewards proportionally
        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            address pool = liquidityPoolList[i];
            uint256 poolBalance = balanceOf(pool);
            uint256 poolReward = (rewardAmount * poolBalance) / totalLpSupply;
            _gonsBalances[pool] += poolReward * _gonsPerFragment;

            emit Transfer(address(this), pool, poolReward);
        }

        // Update total supply to include rewards
        _totalSupply += rewardAmount;
    }

    // ---------------------------------------
    // Admin Functions (Owner or Governor)
    // ---------------------------------------

    /**
     * @notice Set the governor contract address. Once set, both owner and gov contract share admin rights.
     * @param _govContract The address of the new governor contract.
     */
    function setGovernorContract(address _govContract) external onlyOwner {
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    /**
     * @notice Pause the contract (pauses transfers, approvals, etc.)
     * Future governance could call this if needed.
     */
    function pauseContract() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Unpause the contract.
     */
    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    /**
     * @notice Update the rebase frequency. For future use if we want to enforce time constraints.
     * @param newFrequency The new frequency parameter (e.g., in seconds).
     */
    function setRebaseFrequency(uint256 newFrequency) external onlyAdmin {
        rebaseFrequency = newFrequency;
    }

    /**
     * @notice Enable or disable transfer fees and set fee basis points.
     * @param enabled True to enable, false to disable transfer fee.
     * @param newFeeBasisPoints The new fee in basis points (e.g., 100 = 1%).
     */
    function setTransferFeeParams(bool enabled, uint256 newFeeBasisPoints) external onlyAdmin {
        require(newFeeBasisPoints <= 1000, "Fee too high"); // e.g., max 10%
        transfersWithFee = enabled;
        transferFeeBasisPoints = newFeeBasisPoints;
        emit FeeParametersUpdated(enabled, newFeeBasisPoints);
    }

    /**
     * @notice Update the treasury address. Initially set to owner, can change when governance is established.
     * @param newTreasury The new treasury address.
     */
    function updateTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Treasury zero");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryAddressUpdated(old, newTreasury);
    }

    /**
     * @notice Admin can burn tokens from treasury, reducing supply. This is the "occasional reduction in supply".
     * @param amount The amount of tokens to burn from treasury.
     */
    function burnFromTreasury(uint256 amount) external onlyAdmin nonReentrant {
        require(balanceOf(treasury) >= amount, "Not enough tokens in treasury");
        uint256 gonsAmount = amount * _gonsPerFragment;
        _gonsBalances[treasury] -= gonsAmount;
        _totalSupply -= amount;

        // Adjust gonsPerFragment since total supply changed
        _gonsPerFragment = MAX_GONS / _totalSupply;

        emit Transfer(treasury, address(0), amount);
    }

    // ---------------------------------------
    // LP Reward Management Functions
    // ---------------------------------------

    /**
     * @notice Add a liquidity pool address to receive rewards.
     * @param pool The liquidity pool address to add.
     */
    function addLiquidityPool(address pool) external onlyAdmin {
        require(pool != address(0), "Pool address cannot be zero");
        require(!liquidityPools[pool], "Pool already registered");

        liquidityPools[pool] = true;
        liquidityPoolList.push(pool);

        emit LiquidityPoolAdded(pool);
    }

    /**
     * @notice Remove a liquidity pool address from receiving rewards.
     * @param pool The liquidity pool address to remove.
     */
    function removeLiquidityPool(address pool) external onlyAdmin {
        require(liquidityPools[pool], "Pool not registered");

        liquidityPools[pool] = false;

        // Remove from liquidityPoolList array
        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            if (liquidityPoolList[i] == pool) {
                liquidityPoolList[i] = liquidityPoolList[liquidityPoolList.length - 1];
                liquidityPoolList.pop();
                break;
            }
        }

        emit LiquidityPoolRemoved(pool);
    }

    /**
     * @notice Set the LP reward percentage.
     * @param _lpRewardPercentage The new reward percentage (e.g., 5 for 5%).
     */
    function setLpRewardPercentage(uint256 _lpRewardPercentage) external onlyAdmin {
        require(_lpRewardPercentage <= maxLpRewardPercentage, "Reward percentage exceeds max limit");
        lpRewardPercentage = _lpRewardPercentage;
        emit LpRewardPercentageUpdated(_lpRewardPercentage);
    }

    /**
     * @notice Set the maximum LP reward percentage.
     * @param _maxLpRewardPercentage The new maximum reward percentage (e.g., 15 for 15%).
     */
    function setMaxLpRewardPercentage(uint256 _maxLpRewardPercentage) external onlyAdmin {
        require(_maxLpRewardPercentage <= 50, "Max LP reward percentage too high"); // Example: 50% cap
        maxLpRewardPercentage = _maxLpRewardPercentage;
        emit MaxLpRewardPercentageUpdated(_maxLpRewardPercentage);
    }

    // ---------------------------------------
    // Fallback Functions
    // ---------------------------------------
    receive() external payable {
        revert("No ETH");
    }

    fallback() external payable {
        revert("No ETH");
    }
}
