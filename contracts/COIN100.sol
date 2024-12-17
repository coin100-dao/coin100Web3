// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title IC100PublicSale
 * @notice Interface to interact with the C100PublicSale contract.
 */
interface IC100PublicSale {
    function polRate() external view returns (uint256);
    function updatePOLRate(uint256 newRate) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/**
 * @title COIN100 (C100)
 * @notice A rebasing token representing the top 100 crypto market cap index.
 *
 * Changes requested:
 * - Less strictness on certain calculations (no hard reverts on zero supplies, etc.).
 * - Ability to pass a large integer (e.g. 3736397370017) to rebase and scale it to 18 decimals inside rebase.
 * - For polRate, if user passes something like 600, we scale it to 600 * 1e18 internally.
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
    uint256 private _totalSupply;         
    uint256 public lastMarketCap;         
    uint256 constant MAX_GONS = type(uint256).max / 1e18;
    uint256 private _gonsPerFragment;     

    mapping(address => uint256) private _gonsBalances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public ownerAllocation;       
    uint256 public remainingAllocation;   

    // Governance
    address public govContract;

    // Treasury and fees
    address public treasury;
    bool public transfersWithFee;             
    uint256 public transferFeeBasisPoints;    

    // LP Rewards
    mapping(address => bool) public liquidityPools;
    address[] public liquidityPoolList;
    uint256 public lpRewardPercentage;        
    uint256 public maxLpRewardPercentage = 10; 

    // Public Sale Contract
    IC100PublicSale public publicSaleContract;

    // Liquidity Pools for pricing
    address public c100USDCPool;  // For fallback price in USDC
    address public c100POLPool;   // Primary source for polRate (C100 per POL)

    // polInUSDCRate: USDC per POL (scaled by 1e18) for fallback calculations
    uint256 public polInUSDCRate;

    // Last calculated polRate from pools
    uint256 public lastCalculatedPolRate;

    // Rebase frequency placeholder
    uint256 public rebaseFrequency;           

    // Events
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
    event PublicSaleContractSet(address indexed oldSaleContract, address indexed newSaleContract);
    event POLRateUpdated(uint256 oldRate, uint256 newRate);
    event C100USDCPoolSet(address oldPool, address newPool);
    event C100POLPoolSet(address oldPool, address newPool);
    event PolInUSDCRateUpdated(uint256 oldRate, uint256 newRate);

    constructor(uint256 initialMarketCap, uint256 initialPolRate) Ownable(msg.sender) Pausable() ReentrancyGuard() {
        require(initialMarketCap > 0, "Initial mcap must be > 0");
        require(initialPolRate > 0, "Initial polRate must be > 0");

        _totalSupply = initialMarketCap;
        lastMarketCap = initialMarketCap;

        ownerAllocation = (_totalSupply * 3) / 100;           
        remainingAllocation = _totalSupply - ownerAllocation; 

        _gonsPerFragment = MAX_GONS / _totalSupply;

        uint256 totalGons = _totalSupply * _gonsPerFragment;
        _gonsBalances[owner()] = totalGons;

        emit Transfer(address(0), owner(), _totalSupply);

        // Default parameters
        rebaseFrequency = 1 days;
        transfersWithFee = true;                
        transferFeeBasisPoints = 100;           
        treasury = owner();
        lpRewardPercentage = 5; 
        // Scale initialPolRate by 1e18 internally if you wish.
        // If initialPolRate is already considered scaled, leave as is.
        // Here we assume initialPolRate is already scaled. If not, do initialPolRate = initialPolRate * 1e18;
        lastCalculatedPolRate = initialPolRate;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner() || (govContract != address(0) && msg.sender == govContract), "Not admin");
        _;
    }

    // ERC20 standard
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
        require(currentAllowance >= amount, "Exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "Below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // Internal transfer and approve
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "From zero");
        require(to != address(0), "To zero");
        require(balanceOf(from) >= amount, "Balance too low");

        uint256 gonsAmount = amount * _gonsPerFragment;

        _gonsBalances[from] -= gonsAmount;

        if (transfersWithFee && transferFeeBasisPoints > 0) {
            uint256 feeGons = (gonsAmount * transferFeeBasisPoints) / 10000;
            uint256 gonsAfterFee = gonsAmount - feeGons;

            _gonsBalances[treasury] += feeGons;
            _gonsBalances[to] += gonsAfterFee;

            uint256 feeAmount = feeGons / _gonsPerFragment;
            uint256 recipientAmount = gonsAfterFee / _gonsPerFragment;

            emit Transfer(from, treasury, feeAmount);
            emit Transfer(from, to, recipientAmount);
        } else {
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

    // Rebase logic
    function rebase(uint256 newMarketCapRaw, uint256 newPolRateRaw) external onlyAdmin nonReentrant whenNotPaused {
        // newMarketCapRaw and newPolRateRaw are raw integers from user
        // We scale them to 18 decimals internally
        // Adjust this logic as needed. For demonstration, we multiply by 1e18:
        uint256 newMarketCap = newMarketCapRaw * 1e18;
        uint256 newPolRate = newPolRateRaw * 1e18;

        require(newMarketCap > 0, "Mcap > 0");
        uint256 oldMarketCap = lastMarketCap;
        uint256 oldSupply = _totalSupply;

        // Update polRate
        uint256 oldPolRate = lastCalculatedPolRate;
        lastCalculatedPolRate = newPolRate;

        // Sync with Public Sale if set
        if (address(publicSaleContract) != address(0)) {
            publicSaleContract.updatePOLRate(newPolRate);
        }
        emit POLRateUpdated(oldPolRate, newPolRate);

        uint256 ratioScaled = (newMarketCap * 1e18) / oldMarketCap;
        uint256 newSupply = (oldSupply * ratioScaled) / 1e18;
        if (newSupply == 0) {
            // If newSupply ends up zero (extremely unlikely), just skip
            return;
        }

        uint256 supplyDelta;
        bool isIncrease;
        if (newSupply > oldSupply) {
            supplyDelta = newSupply - oldSupply;
            isIncrease = true;
        } else {
            supplyDelta = oldSupply - newSupply;
            isIncrease = false;
        }

        _gonsPerFragment = MAX_GONS / newSupply;
        _totalSupply = newSupply;
        lastMarketCap = newMarketCap;

        emit Rebase(oldMarketCap, newMarketCap, ratioScaled, block.timestamp);

        // LP reward allocation
        if (isIncrease && lpRewardPercentage > 0 && liquidityPoolList.length > 0 && supplyDelta > 0) {
            uint256 rewardAmount = (supplyDelta * lpRewardPercentage) / 100;
            _allocateRewardsToLPs(rewardAmount);
        }
    }

    function _allocateRewardsToLPs(uint256 rewardAmount) internal {
        uint256 totalLpSupply = 0;
        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            totalLpSupply += balanceOf(liquidityPoolList[i]);
        }

        // If no LP supply, no rewards distributed
        if (totalLpSupply == 0 || rewardAmount == 0) {
            return;
        }

        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            address pool = liquidityPoolList[i];
            uint256 poolBalance = balanceOf(pool);
            if (poolBalance > 0) {
                uint256 poolReward = (rewardAmount * poolBalance) / totalLpSupply;
                _gonsBalances[pool] += poolReward * _gonsPerFragment;
                emit Transfer(address(this), pool, poolReward);
            }
        }

        _totalSupply += rewardAmount;
    }

    // Price Calculation
    function _getPolRateFromPools() internal view returns (uint256) {
        // Primary attempt: C100/POL pool
        if (c100POLPool != address(0)) {
            (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(c100POLPool).getReserves();
            address t0 = IUniswapV2Pair(c100POLPool).token0();
            uint256 polReserve;
            uint256 c100Reserve;
            if (t0 == address(this)) {
                c100Reserve = uint256(reserve0);
                polReserve = uint256(reserve1);
            } else {
                c100Reserve = uint256(reserve1);
                polReserve = uint256(reserve0);
            }
            
            if (polReserve > 0) {
                return (c100Reserve * 1e18) / polReserve;
            }
        }

        // Fallback: use C100/USDC pool and polInUSDCRate
        if (c100USDCPool == address(0) || polInUSDCRate == 0) {
            // If no fallback setup, return a default 1e18 to avoid revert
            return 1e18;
        }

        (uint112 r0, uint112 r1,) = IUniswapV2Pair(c100USDCPool).getReserves();
        address token0 = IUniswapV2Pair(c100USDCPool).token0();
        uint256 c100R;
        uint256 usdcR;
        if (token0 == address(this)) {
            c100R = uint256(r0);
            usdcR = uint256(r1);
        } else {
            c100R = uint256(r1);
            usdcR = uint256(r0);
        }

        if (c100R == 0) {
            // No C100 liquidity, return a default
            return 1e18; 
        }

        // c100PriceInUSDC = (usdcR * 1e18) / c100R
        uint256 c100PriceInUSDC = (usdcR * 1e18) / c100R;
        if (c100PriceInUSDC == 0) {
            return 1e18;
        }

        // C100 per POL = (polInUSDCRate * 1e18) / c100PriceInUSDC
        return (polInUSDCRate * 1e18) / c100PriceInUSDC;
    }

    // Admin functions
    function setGovernorContract(address _govContract) external onlyOwner {
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    function setPublicSaleContract(address _publicSaleContract) external onlyOwner {
        require(_publicSaleContract != address(0), "Public sale zero");
        address oldSale = address(publicSaleContract);
        publicSaleContract = IC100PublicSale(_publicSaleContract);
        emit PublicSaleContractSet(oldSale, _publicSaleContract);
    }

    function pauseContract() external onlyAdmin {
        _pause();
    }

    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    function setRebaseFrequency(uint256 newFrequency) external onlyAdmin {
        rebaseFrequency = newFrequency;
    }

    function setTransferFeeParams(bool enabled, uint256 newFeeBasisPoints) external onlyAdmin {
        require(newFeeBasisPoints <= 1000, "Fee too high");
        transfersWithFee = enabled;
        transferFeeBasisPoints = newFeeBasisPoints;
        emit FeeParametersUpdated(enabled, newFeeBasisPoints);
    }

    function updateTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Zero");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryAddressUpdated(old, newTreasury);
    }

    function burnFromTreasury(uint256 amount) external onlyAdmin nonReentrant {
        if (balanceOf(treasury) < amount) {
            // If not enough tokens, just skip
            return;
        }
        uint256 gonsAmount = amount * _gonsPerFragment;
        _gonsBalances[treasury] -= gonsAmount;
        _totalSupply -= amount;
        _gonsPerFragment = MAX_GONS / _totalSupply;
        emit Transfer(treasury, address(0), amount);
    }

    function addLiquidityPool(address pool) external onlyAdmin {
        require(pool != address(0), "Zero");
        if (!liquidityPools[pool]) {
            liquidityPools[pool] = true;
            liquidityPoolList.push(pool);
            emit LiquidityPoolAdded(pool);
        }
    }

    function removeLiquidityPool(address pool) external onlyAdmin {
        if (liquidityPools[pool]) {
            liquidityPools[pool] = false;
            for (uint256 i = 0; i < liquidityPoolList.length; i++) {
                if (liquidityPoolList[i] == pool) {
                    liquidityPoolList[i] = liquidityPoolList[liquidityPoolList.length - 1];
                    liquidityPoolList.pop();
                    break;
                }
            }
            emit LiquidityPoolRemoved(pool);
        }
    }

    function setLpRewardPercentage(uint256 _lpRewardPercentage) external onlyAdmin {
        require(_lpRewardPercentage <= maxLpRewardPercentage, "Exceeds max limit");
        lpRewardPercentage = _lpRewardPercentage;
        emit LpRewardPercentageUpdated(_lpRewardPercentage);
    }

    function setMaxLpRewardPercentage(uint256 _maxLpRewardPercentage) external onlyAdmin {
        require(_maxLpRewardPercentage <= 50, "Too high");
        maxLpRewardPercentage = _maxLpRewardPercentage;
        emit MaxLpRewardPercentageUpdated(_maxLpRewardPercentage);
    }

    function setC100USDCPool(address pool) external onlyAdmin {
        address old = c100USDCPool;
        c100USDCPool = pool;
        emit C100USDCPoolSet(old, pool);
    }

    function setC100POLPool(address pool) external onlyAdmin {
        address old = c100POLPool;
        c100POLPool = pool;
        emit C100POLPoolSet(old, pool);
    }

    function setPolInUSDCRate(uint256 newRate) external onlyAdmin {
        require(newRate > 0, "Rate must be >0");
        uint256 old = polInUSDCRate;
        polInUSDCRate = newRate;
        emit PolInUSDCRateUpdated(old, newRate);
    }

    receive() external payable {
        revert("No ETH");
    }

    fallback() external payable {
        revert("No ETH");
    }
}
