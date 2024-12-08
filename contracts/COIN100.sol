// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function WETH() external pure returns (address);
    function factory() external view returns (address);
    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);
}

/// @title COIN100: Automated Rebase & Buyback Token
/// @notice This contract:
///  - Simulates market cap growth internally.
///  - Automatically rebases supply to match a target price.
///  - Detects liquidity pairs (C100/MATIC, C100/USDC) from a given factory on Polygon.
///  - Charges a small transaction fee and allows deposit of USDC to fund buybacks.
///  - Performs buybacks and burns bought tokens to benefit LPs and holders indirectly.
contract COIN100 is IERC20, Ownable, Pausable, ReentrancyGuard {
    // --------------------------------------
    // Token Metadata
    // --------------------------------------
    string public constant name = "COIN100";
    string public constant symbol = "C100";
    uint8 public constant decimals = 18;

    // --------------------------------------
    // Supply and Internal Math
    // --------------------------------------
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000_000e18; // 1 billion * 1e18
    uint256 private constant GON_UNIT = 1e9;
    uint256 private constant TOTAL_GONS = INITIAL_FRAGMENTS_SUPPLY * GON_UNIT; // 1e36
    uint256 private gonsPerFragment = TOTAL_GONS / INITIAL_FRAGMENTS_SUPPLY;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedGons;

    // --------------------------------------
    // Parameters and State
    // --------------------------------------
    uint256 public rebaseInterval = 1 days;
    uint256 public lastRebaseTime;
    uint256 public targetPrice = 1e15; // $0.001 per token
    uint256 public feePercent = 5; // 0.05% fee
    uint256 public currentMCap;  // simulate MCap
    uint256 public growthRate = 50000000000000000; // 5e16 = 5% growth per rebase

    // DEX addresses for pair detection and swaps
    address public factoryAddress;
    address public routerAddress;
    address public wMaticAddress;
    address public usdcAddress;

    address public maticPair;
    address public usdcPair;

    // Buyback parameters
    bool public buybackEnabled = true;
    uint256 public buybackPortion = 5000; // 50% of USDC spent on each buyback
    uint256 public constant MAX_PCT = 10000;
    address[] public path = new address[](2);

    // --------------------------------------
    // Events
    // --------------------------------------
    event Rebase(uint256 newGonsPerFragment, uint256 timestamp, uint256 desiredSupply);
    event RebaseIntervalUpdated(uint256 newInterval);
    event TargetPriceUpdated(uint256 newTargetPrice);
    event FeePercentUpdated(uint256 newFee);
    event GrowthRateUpdated(uint256 newRate);
    event BuybackSettingsUpdated(bool enabled, uint256 portion);
    event FactorySet(address factory);
    event RouterSet(address router);
    event TokenAddressesSet(address wMatic, address usdc);

    // --------------------------------------
    // Constructor
    // --------------------------------------
    /// @param initialMCap Initial MCap value at deployment.
    /// @param _router DEX router address (e.g., QuickSwap router).
    /// @param _factory DEX factory address.
    /// @param _wMatic WMATIC token address.
    /// @param _usdc USDC token address on Polygon.
    constructor(
        uint256 initialMCap,
        address _router,
        address _factory,
        address _wMatic,
        address _usdc
    ) Ownable(_msgSender()) Pausable() ReentrancyGuard() {
        require(initialMCap > 0, "initial MCap zero");
        require(_router != address(0) && _factory != address(0), "zero router/factory");
        require(_wMatic != address(0) && _usdc != address(0), "zero token addr");

        currentMCap = initialMCap;
        routerAddress = _router;
        factoryAddress = _factory;
        wMaticAddress = _wMatic;
        usdcAddress = _usdc;

        _gonBalances[_msgSender()] = TOTAL_GONS;
        lastRebaseTime = block.timestamp;
    }

    // --------------------------------------
    // ERC20 Standard (View)
    // --------------------------------------
    function totalSupply() public view override returns (uint256) {
        return TOTAL_GONS / gonsPerFragment;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account] / gonsPerFragment;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedGons[owner_][spender] / gonsPerFragment;
    }

    // --------------------------------------
    // ERC20 Standard (Mutative)
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
        require(currentAllowance >= gonAmount, "transfer > allowance");

        _allowedGons[sender][_msgSender()] = currentAllowance - gonAmount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 gonValue = addedValue * gonsPerFragment;
        _allowedGons[_msgSender()][spender] += gonValue;
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 gonValue = subtractedValue * gonsPerFragment;
        uint256 currentAllowance = _allowedGons[_msgSender()][spender];
        require(currentAllowance >= gonValue, "Decrease > allowance");
        _allowedGons[_msgSender()][spender] = currentAllowance - gonValue;
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender) - subtractedValue);
        return true;
    }

    // --------------------------------------
    // Internal Transfer with Fee
    // --------------------------------------
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        uint256 gonAmount = amount * gonsPerFragment;
        require(_gonBalances[sender] >= gonAmount, "Balance too low");

        // Apply fee
        uint256 feeGon = (gonAmount * feePercent) / 10000; 
        uint256 gonToRecipient = gonAmount - feeGon;

        _gonBalances[sender] -= gonAmount;
        _gonBalances[recipient] += gonToRecipient;

        // Fee to treasury (contract itself)
        _gonBalances[address(this)] += feeGon;

        emit Transfer(sender, recipient, gonToRecipient / gonsPerFragment);
        if (feeGon > 0) {
            emit Transfer(sender, address(this), feeGon / gonsPerFragment);
        }
    }

    // --------------------------------------
    // Upkeep: Rebase + Pair Detection + Buyback
    // --------------------------------------
    function upkeep() external onlyOwner nonReentrant {
        require(block.timestamp >= lastRebaseTime + rebaseInterval, "Rebase interval not passed");

        // 1. Update MCap (simulate growth)
        currentMCap = (currentMCap * (1e18 + growthRate)) / 1e18;

        // 2. Detect pairs if not found yet
        if (maticPair == address(0)) {
            maticPair = IFactory(factoryAddress).getPair(address(this), wMaticAddress);
        }
        if (usdcPair == address(0)) {
            usdcPair = IFactory(factoryAddress).getPair(address(this), usdcAddress);
        }

        // 3. Rebase
        uint256 desiredNewTotalSupply = currentMCap / targetPrice;
        if (desiredNewTotalSupply < 1) {
            desiredNewTotalSupply = 1;
        }
        uint256 newGonsPerFragment = TOTAL_GONS / desiredNewTotalSupply;
        require(newGonsPerFragment > 0, "Invalid rebase calc");
        gonsPerFragment = newGonsPerFragment;

        lastRebaseTime = block.timestamp;
        emit Rebase(gonsPerFragment, block.timestamp, desiredNewTotalSupply);

        // 4. Buyback if enabled, pairs exist, and stable tokens available
        if (buybackEnabled && usdcPair != address(0)) {
            uint256 stableBal = IERC20(usdcAddress).balanceOf(address(this));
            if (stableBal > 0 && buybackPortion > 0) {
                uint256 amountToSpend = (stableBal * buybackPortion) / MAX_PCT;
                if (amountToSpend > 0) {
                    _performBuyback(amountToSpend);
                }
            }
        }
    }

    // --------------------------------------
    // Buyback Logic
    // --------------------------------------
    function _performBuyback(uint256 amountToSpend) internal {
        // Approve the router to spend USDC
        IERC20(usdcAddress).approve(routerAddress, amountToSpend);
        
        // Declare and initialize the path array
        path[0] = usdcAddress;
        path[1] = address(this);

        // Execute the token swap
        IRouter(routerAddress).swapExactTokensForTokens(
            amountToSpend,
            0, 
            path,
            address(this),
            block.timestamp
        );

        // Calculate the balance of COIN100 tokens obtained from the swap
        uint256 c100Bal = balanceOf(address(this));
        if (c100Bal > 0) {
            uint256 gonBal = c100Bal * gonsPerFragment;
            _gonBalances[address(this)] -= gonBal;

            // Burn the tokens by sending them to the zero address
            emit Transfer(address(this), address(0), c100Bal);
            // No need to adjust TOTAL_GONS; burning effectively reduces circulating supply as tokens vanish.
        }
    }

    // --------------------------------------
    // Admin Functions
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

    function setFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 100, "Fee too high");
        feePercent = _newFee;
        emit FeePercentUpdated(_newFee);
    }

    function setGrowthRate(uint256 _newRate) external onlyOwner {
        growthRate = _newRate;
        emit GrowthRateUpdated(_newRate);
    }

    function setBuybackSettings(bool _enabled, uint256 _portion) external onlyOwner {
        require(_portion <= MAX_PCT, "portion >100%");
        buybackEnabled = _enabled;
        buybackPortion = _portion;
        emit BuybackSettingsUpdated(_enabled, _portion);
    }

    function setFactoryAddress(address _factory) external onlyOwner {
        require(_factory != address(0), "zero factory");
        factoryAddress = _factory;
        emit FactorySet(_factory);
    }

    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "zero router");
        routerAddress = _router;
        emit RouterSet(_router);
    }

    function setTokenAddresses(address _wMatic, address _usdc) external onlyOwner {
        require(_wMatic != address(0) && _usdc != address(0), "zero token addr");
        wMaticAddress = _wMatic;
        usdcAddress = _usdc;
        emit TokenAddressesSet(_wMatic, _usdc);
    }

    /// @notice Owner can deposit USDC into the contract to enable buybacks.
    function depositStableTokens(uint256 amount) external onlyOwner {
        require(IERC20(usdcAddress).transferFrom(_msgSender(), address(this), amount), "transfer failed");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // --------------------------------------
    // Fallback
    // --------------------------------------
    receive() external payable {
        revert("No direct MATIC");
    }
}
