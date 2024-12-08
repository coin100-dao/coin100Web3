// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title COIN100 (C100)
 * @notice A rebasing token representing the top 100 crypto market cap index.
 *         On each rebase, all balances scale proportionally to reflect changes
 *         in the top 100 market cap, ensuring each holder maintains their fraction.
 * 
 * Tokenomics at Deployment:
 * - Total supply = initialMarketCap (M0)
 * - 3% of total supply is the owner's allocation (as appreciation for upkeep).
 * - 97% of total supply is also assigned to the owner at launch (so total 100% to owner).
 *   The owner can then provide liquidity on a DEX or distribute tokens as desired.
 *
 * Over time, the owner will perform manual rebases by calling `rebase(newMCap)`,
 * adjusting everyone's balances proportionally based on changes in the top 100 market cap.
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

    mapping(address => uint256) private _gonsBalances; // Balances in gons
    mapping(address => mapping(address => uint256)) private _allowances;

    // Owner and Liquidity allocations
    uint256 public ownerAllocation;       // 3% of total supply
    uint256 public remainingAllocation;   // The other 97%

    // ---------------------------------------
    // Events
    // ---------------------------------------
    event Rebase(uint256 oldMarketCap, uint256 newMarketCap, uint256 ratio, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    constructor(uint256 initialMarketCap) Ownable(msg.sender) Pausable() ReentrancyGuard() {
        require(initialMarketCap > 0, "Initial mcap must be > 0");

        // Set initial total supply = initial market cap
        _totalSupply = initialMarketCap;
        lastMarketCap = initialMarketCap;

        // Calculate owner and remaining allocations
        ownerAllocation = (_totalSupply * 3) / 100;          // 3%
        remainingAllocation = _totalSupply - ownerAllocation; // 97%

        // Initialize gonsPerFragment
        _gonsPerFragment = MAX_GONS / _totalSupply;

        // Mint entire supply to owner
        // This includes both the 3% owner allocation and the 97% intended for liquidity or distribution.
        uint256 totalGons = _totalSupply * _gonsPerFragment;
        _gonsBalances[owner()] = totalGons;

        emit Transfer(address(0), owner(), _totalSupply);
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
        _gonsBalances[to] += gonsAmount;

        emit Transfer(from, to, amount);
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
    function rebase(uint256 newMarketCap) external onlyOwner nonReentrant whenNotPaused {
        require(newMarketCap > 0, "Mcap must be > 0");
        uint256 oldMarketCap = lastMarketCap;
        uint256 oldSupply = _totalSupply;

        // ratio = (newMarketCap / oldMarketCap) scaled by 1e18
        uint256 ratioScaled = (newMarketCap * 1e18) / oldMarketCap;

        // newSupply = oldSupply * (ratioScaled / 1e18)
        uint256 newSupply = (oldSupply * ratioScaled) / 1e18;
        require(newSupply > 0, "New supply must be > 0");

        // Update gonsPerFragment
        _gonsPerFragment = MAX_GONS / newSupply;

        _totalSupply = newSupply;
        lastMarketCap = newMarketCap;

        emit Rebase(oldMarketCap, newMarketCap, ratioScaled, block.timestamp);
    }

    // ---------------------------------------
    // Owner Controls
    // ---------------------------------------
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
