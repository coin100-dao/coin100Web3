// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title COIN100: A Rebase Token Tracking Top 100 Crypto Market Cap
/// @notice Implements a proportional rebase mechanism. As the underlying index (top 100 crypto mcap) changes,
///         all balances are scaled up or down to keep the token price aligned to a target price. Holders gain
///         value when the index grows, as their balances scale proportionally, mirroring an index fund's growth.
contract COIN100 is IERC20, Ownable, Pausable, ReentrancyGuard {
    // --------------------------------------
    // Token Metadata
    // --------------------------------------
    string public constant name = "COIN100";
    string public constant symbol = "C100";
    uint8 public constant decimals = 18;

    // --------------------------------------
    // Initial Supply and Internal Math
    // --------------------------------------
    // Initial supply: 1,000,000,000 tokens (1e9) with 18 decimals = 1e27 total "fragments"
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000_000e18;

    // GON_UNIT defines the granularity. By choosing a large GON_UNIT, we get a huge TOTAL_GONS.
    // This allows for stable mathematical operations and maintaining precision during rebases.
    uint256 private constant GON_UNIT = 1e9;
    uint256 private constant TOTAL_GONS = INITIAL_FRAGMENTS_SUPPLY * GON_UNIT; // 1e36 total gons

    // gonsPerFragment maps internal gons to external "fragment" balances. Initially:
    // gonsPerFragment = TOTAL_GONS / INITIAL_FRAGMENTS_SUPPLY = 1e9
    uint256 private gonsPerFragment = TOTAL_GONS / INITIAL_FRAGMENTS_SUPPLY;

    // Each account's balance is stored as an integer number of gons.
    mapping(address => uint256) private _gonBalances;

    // --------------------------------------
    // Allowances (Stored in Gons)
    // --------------------------------------
    mapping(address => mapping(address => uint256)) private _allowedGons;

    // --------------------------------------
    // Rolling Average Market Cap Logic
    // --------------------------------------
    // We keep a history of recent MCap values to compute a rolling average.
    uint256 public averagingPeriod = 7; 
    uint256[] public mcapHistory;
    uint256 public currentIndex = 0;

    // --------------------------------------
    // Rebase Parameters
    // --------------------------------------
    uint256 public lastRebaseTime;
    uint256 public rebaseInterval = 1 days;

    // targetPrice represents the desired price per token in scaled USD terms (1e18 = 1 USD).
    // If targetPrice = 1e15, that means $0.001 per token.
    // On each upkeep:
    //   desiredNewSupply = avgMCap / targetPrice
    //   gonsPerFragment = TOTAL_GONS / desiredNewSupply
    uint256 public targetPrice = 1e15; // $0.001 with 18 decimals scaling.

    // --------------------------------------
    // Events
    // --------------------------------------
    event Rebase(uint256 newGonsPerFragment, uint256 timestamp, uint256 avgMCap, uint256 desiredSupply);
    event RebaseIntervalUpdated(uint256 newInterval);
    event TargetPriceUpdated(uint256 newTargetPrice);

    // --------------------------------------
    // Constructor
    // --------------------------------------
    constructor() {
        // Assign the entire initial supply to the owner in gons:
        _gonBalances[_msgSender()] = TOTAL_GONS;
        lastRebaseTime = block.timestamp;
        // mcapHistory is initially empty; first upkeep will seed it if needed.
    }

    // --------------------------------------
    // ERC20 Standard Functions (View)
    // --------------------------------------
    function totalSupply() public view override returns (uint256) {
        // totalSupply = TOTAL_GONS / gonsPerFragment
        return TOTAL_GONS / gonsPerFragment;
    }

    function balanceOf(address account) public view override returns (uint256) {
        // user balance = _gonBalances[account] / gonsPerFragment
        return _gonBalances[account] / gonsPerFragment;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        // allowance = _allowedGons[owner_][spender] / gonsPerFragment
        return _allowedGons[owner_][spender] / gonsPerFragment;
    }

    // --------------------------------------
    // ERC20 Standard Functions (Mutative)
    // --------------------------------------
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 gonAmount = amount * gonsPerFragment;
        _allowedGons[_msgSender()][spender] = gonAmount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 gonAmount = amount * gonsPerFragment;
        uint256 currentAllowance = _allowedGons[sender][_msgSender()];
        require(currentAllowance >= gonAmount, "ERC20: transfer amount exceeds allowance");

        _allowedGons[sender][_msgSender()] = currentAllowance - gonAmount;
        _transfer(sender, recipient, amount);
        return true;
    }

    // Increase/Decrease allowance in a standard manner:
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 gonValue = addedValue * gonsPerFragment;
        _allowedGons[_msgSender()][spender] += gonValue;
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 gonValue = subtractedValue * gonsPerFragment;
        uint256 currentAllowance = _allowedGons[_msgSender()][spender];
        require(currentAllowance >= gonValue, "Decrease exceeds allowance");
        _allowedGons[_msgSender()][spender] = currentAllowance - gonValue;
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender) - subtractedValue);
        return true;
    }

    // --------------------------------------
    // Internal Transfer Logic
    // --------------------------------------
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        uint256 gonAmount = amount * gonsPerFragment;
        require(_gonBalances[sender] >= gonAmount, "Balance too low");

        _gonBalances[sender] -= gonAmount;
        _gonBalances[recipient] += gonAmount;

        emit Transfer(sender, recipient, amount);
    }

    // --------------------------------------
    // Rolling Average Market Cap Management
    // --------------------------------------
    function updateMcapHistory(uint256 newMCap) internal {
        if (mcapHistory.length < averagingPeriod) {
            // Still filling up the initial window
            mcapHistory.push(newMCap);
        } else {
            // Overwrite in a circular manner
            mcapHistory[currentIndex] = newMCap;
            currentIndex = (currentIndex + 1) % averagingPeriod;
        }
    }

    function getRollingAverageMcap() public view returns (uint256) {
        require(mcapHistory.length > 0, "No MCap data");
        uint256 sum = 0;
        uint256 count = mcapHistory.length;
        for (uint256 i = 0; i < count; i++) {
            sum += mcapHistory[i];
        }
        return sum / count;
    }

    // --------------------------------------
    // Rebase (Upkeep) Logic
    // --------------------------------------
    /// @notice Rebase token supply based on updated market cap data.
    /// @dev If this is the first time and no MCap data is seeded, we initialize it with the fetched MCap.
    function upkeep(uint256 _fetchedMCap) external onlyOwner nonReentrant {
        require(block.timestamp >= lastRebaseTime + rebaseInterval, "Rebase interval not passed");
        require(_fetchedMCap > 0, "MCap zero");

        // If no data yet, initialize mcapHistory with the fetched MCap
        if (mcapHistory.length == 0) {
            mcapHistory.push(_fetchedMCap);
        } else {
            updateMcapHistory(_fetchedMCap);
        }

        uint256 avgMCap = getRollingAverageMcap();

        // desiredNewTotalSupply = avgMCap / targetPrice
        // Both are scaled by 1e18. Ensure at least 1 to avoid division by zero or zero supply.
        uint256 desiredNewTotalSupply = avgMCap / targetPrice;
        if (desiredNewTotalSupply < 1) {
            desiredNewTotalSupply = 1;
        }

        // gonsPerFragment = TOTAL_GONS / desiredNewTotalSupply
        uint256 newGonsPerFragment = TOTAL_GONS / desiredNewTotalSupply;
        require(newGonsPerFragment > 0, "Invalid rebase calc");

        gonsPerFragment = newGonsPerFragment;
        lastRebaseTime = block.timestamp;

        emit Rebase(gonsPerFragment, block.timestamp, avgMCap, desiredNewTotalSupply);
    }

    // --------------------------------------
    // Administrative Functions
    // --------------------------------------
    function setRebaseInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval >= 1 days && _newInterval <= 365 days, "Invalid interval");
        rebaseInterval = _newInterval;
        emit RebaseIntervalUpdated(_newInterval);
    }

    function setTargetPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Price zero");
        targetPrice = _newPrice;
        emit TargetPriceUpdated(_newPrice);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Optional: Owner can seed initial mcap data if desired.
    /// @dev Not mandatory since we now handle empty history in upkeep().
    function seedMcap(uint256[] calldata initialData) external onlyOwner {
        require(mcapHistory.length == 0, "Already seeded");
        for (uint256 i = 0; i < initialData.length; i++) {
            require(initialData[i] > 0, "Zero mcap entry");
            mcapHistory.push(initialData[i]);
        }
    }

    // --------------------------------------
    // Context Override
    // --------------------------------------
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // --------------------------------------
    // Fallback
    // --------------------------------------
    receive() external payable {
        revert("No direct MATIC");
    }
}
