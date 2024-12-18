// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uniswap V3 Interfaces
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

interface IC100PublicSale {
    function polRate() external view returns (uint256);
    function updatePOLRate(uint256 newRate) external;
}

/**
 * @title COIN100 (C100) V3 Adapted
 * @notice A rebasing token representing top 100 crypto market cap index.
 *         This version uses Uniswap V3 pools for pricing and introduces
 *         a staking mechanism for LP reward distribution.
 */
contract COIN100 is Ownable, ReentrancyGuard, Pausable {
    string public constant name = "COIN100";
    string public constant symbol = "C100";
    uint8 public constant decimals = 18;

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

    // Public Sale Contract
    IC100PublicSale public publicSaleContract;

    // V3 Pools for pricing
    address public c100USDCPool;  
    address public c100POLPool;   
    uint256 public polInUSDCRate;
    uint256 public lastCalculatedPolRate;

    uint256 public rebaseFrequency; 

    // LP Reward parameters
    uint256 public lpRewardPercentage;        
    uint256 public maxLpRewardPercentage = 10; 

    // ---------------------------------------
    // New V3 Staking Mechanism for LP Rewards
    // ---------------------------------------
    // We track LP rewards by letting users stake their Uniswap V3 LP positions (NFTs).
    // When supply expands, a portion of the newly minted tokens (lpRewardPercentage%)
    // is allocated to stakers proportionally to their liquidity.

    INonfungiblePositionManager public positionManager;

    struct PositionInfo {
        address owner;
        uint128 liquidity;          // current liquidity of the staked position
        uint256 rewardPerLiquidityPaid;
        uint256 rewardsClaimed;     // optional tracking if needed
    }

    // tokenId => PositionInfo
    mapping(uint256 => PositionInfo) public stakedPositions;

    // Global accounting for rewards
    uint256 public totalStakedLiquidity;      // sum of all staked liquidity
    uint256 public rewardPerLiquidity;        // accumulative reward per liquidity (scaled by 1e18)

    // Events
    event Rebase(uint256 oldMarketCap, uint256 newMarketCap, uint256 ratio, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event GovernorContractSet(address indexed oldGovernor, address indexed newGovernor);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeParametersUpdated(bool transfersWithFee, uint256 transferFeeBasisPoints);
    event LpRewardPercentageUpdated(uint256 newPercentage);
    event MaxLpRewardPercentageUpdated(uint256 newMaxPercentage);
    event PublicSaleContractSet(address indexed oldSaleContract, address indexed newSaleContract);
    event POLRateUpdated(uint256 oldRate, uint256 newRate);
    event C100USDCPoolSet(address oldPool, address newPool);
    event C100POLPoolSet(address oldPool, address newPool);
    event PolInUSDCRateUpdated(uint256 oldRate, uint256 newRate);

    // Staking events
    event PositionStaked(address indexed owner, uint256 tokenId, uint128 liquidity);
    event PositionUnstaked(address indexed owner, uint256 tokenId);
    event RewardsClaimed(address indexed owner, uint256 tokenId, uint256 amount);

    constructor(
        uint256 initialMarketCap, 
        uint256 initialPolRate, 
        address _positionManager
    ) Ownable(msg.sender) Pausable() ReentrancyGuard() {
        require(initialMarketCap > 0, "Initial mcap must be > 0");
        require(initialPolRate > 0, "Initial polRate must be > 0");
        require(_positionManager != address(0), "Invalid position manager");

        uint256 scaledMcap = initialMarketCap * 1e18;
        _totalSupply = scaledMcap;
        lastMarketCap = scaledMcap;

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

        lastCalculatedPolRate = initialPolRate * 1e18;
        positionManager = INonfungiblePositionManager(_positionManager);
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
    function rebase(uint256 newMarketCap) external onlyAdmin nonReentrant whenNotPaused {
        require(newMarketCap > 0, "Mcap > 0");
        uint256 oldMarketCap = lastMarketCap;
        uint256 oldSupply = _totalSupply;

        uint256 oldPolRate = lastCalculatedPolRate;
        uint256 newPolRate = _getPolRateFromV3Pools(); // updated for V3
        lastCalculatedPolRate = newPolRate;

        // Sync with Public Sale if set
        if (address(publicSaleContract) != address(0)) {
            publicSaleContract.updatePOLRate(newPolRate);
        }
        emit POLRateUpdated(oldPolRate, newPolRate);

        // Scale newMarketCap by 1e18
        uint256 scaledNewMarketCap = newMarketCap * 1e18;

        uint256 ratioScaled = 1e18; 
        if (oldMarketCap > 0) {
            ratioScaled = (scaledNewMarketCap * 1e18) / oldMarketCap;
        }

        uint256 newSupply = (oldSupply * ratioScaled) / 1e18;
        if (newSupply == 0) {
            newSupply = oldSupply;
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
        lastMarketCap = scaledNewMarketCap;

        emit Rebase(oldMarketCap, scaledNewMarketCap, ratioScaled, block.timestamp);

        if (isIncrease && lpRewardPercentage > 0 && totalStakedLiquidity > 0 && supplyDelta > 0) {
            _allocateRewardsToStakers(supplyDelta);
        }
    }

    function _allocateRewardsToStakers(uint256 supplyDelta) internal {
        uint256 rewardAmount = (supplyDelta * lpRewardPercentage) / 100;
        if (rewardAmount == 0) {
            return;
        }

        // Update global reward accumulator
        uint256 increment = (rewardAmount * 1e18) / totalStakedLiquidity;
        rewardPerLiquidity += increment;

        _totalSupply += rewardAmount;
    }

    // Price Calculation with V3
    function _getPolRateFromV3Pools() internal view returns (uint256) {
        // We attempt to get price from C100/POL pool first.
        // If not available or invalid, fallback to C100/USDC with polInUSDCRate.
        
        uint256 rateFromPOL = _getRateFromV3Pool(c100POLPool, true);
        if (rateFromPOL > 0) {
            return rateFromPOL;
        }

        // Fallback with C100/USDC + polInUSDCRate
        if (c100USDCPool == address(0) || polInUSDCRate == 0) {
            return lastCalculatedPolRate;
        }

        uint256 c100PriceInUSDC = _getRateFromV3Pool(c100USDCPool, false);
        if (c100PriceInUSDC == 0) {
            return lastCalculatedPolRate;
        }

        uint256 fallbackRate = (polInUSDCRate * 1e18) / c100PriceInUSDC;
        if (fallbackRate == 0) {
            return lastCalculatedPolRate;
        }
        return fallbackRate;
    }

    // Given a V3 pool and whether it's C100/POL or C100/USDC, derive price
    // Assumes token0 or token1 might be C100. If pool is C100/POL and we return C100 per POL,
    // If pool is C100/USDC and we return C100 per USDC.
    function _getRateFromV3Pool(address poolAddress, bool c100POL) internal view returns (uint256) {
        if (poolAddress == address(0)) return 0;
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);

        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        address t0 = pool.token0();
        address t1 = pool.token1();

        // price = (token1/token0) if sqrtPriceX96 represents token1 per token0
        // formula: priceToken0InToken1 = (sqrtPriceX96^2 / 2^192)
        // If C100 is token0, price is token1 per C100. We want C100 per token1 = 1/price
        // If C100 is token1, price is C100 per token0 directly.

        uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        // shift by 2^192
        // 2^192 = 2^(64*3) = 6277101735386680763835789423207666416102355444464034512896
        // We'll do price = priceX96 / 2^192 (as a fixed-point division)
        
        // Use a formula: price = priceX96 / (2^192)
        // to get a ratio token1/token0
        uint256 shift = 2**192;
        uint256 ratio = priceX96 / shift;

        bool c100IsToken0 = (t0 == address(this));
        // If c100IsToken0:
        // ratio = token1 per C100
        // we want C100 per token1 = 1/ratio (if ratio ==0, can't invert)
        // If not c100IsToken0:
        // ratio = C100 per token0 directly

        if (c100IsToken0) {
            // ratio = token1 per C100
            // we want C100 per token1 = 1/ratio
            // If ratio is 0, means price not well-defined
            if (ratio == 0) return 0;
            // C100 per token1 = (1e18 / ratio) * 1e18 scale
            // We'll keep consistent 1e18 scaling
            // Actually, ratio is small. It's likely that ratio is a very small fraction.
            // For better precision, do a fractional division with 1e18 factor:
            uint256 c100PerOther = (1e36 / ratio); 
            return c100PerOther;
        } else {
            // ratio = C100 per token0 directly
            // scale up to 1e18
            // ratio currently ~some float~, we need 1e18 scaling
            uint256 scaled = ratio * 1e18;
            return scaled;
        }
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
        require(balanceOf(treasury) >= amount, "Not enough tokens");
        uint256 gonsAmount = amount * _gonsPerFragment;
        _gonsBalances[treasury] -= gonsAmount;
        _totalSupply -= amount;
        if (_totalSupply > 0) {
            _gonsPerFragment = MAX_GONS / _totalSupply;
        }
        emit Transfer(treasury, address(0), amount);
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

    // ---------------------------------------
    // Staking and Rewards for Uniswap V3 LPs
    // ---------------------------------------
    // Users must transfer their NFT positions to this contract. 
    // We read their liquidity from NonfungiblePositionManager.
    // On rebase, we increase rewardPerLiquidity. Users claim rewards based on 
    // (liquidity * (rewardPerLiquidity - rewardPerLiquidityPaid)) / 1e18.

    function stakePosition(uint256 tokenId) external nonReentrant whenNotPaused {
        // Transfer the NFT from user to this contract
        positionManager.safeTransferFrom(msg.sender, address(this), tokenId);
        // Once received, we'll call _onERC721Received -> finalize staking in a callback
        // But since standard ERC721Receiver logic might be needed, let's handle that logic by a separate function below.
    }

    // This function must be called after receiving NFT
    function _finalizeStaking(uint256 tokenId, address ownerOfNft) internal {
        // Query position liquidity
        ( , , , , , , , uint128 liquidity, , , , ) = positionManager.positions(tokenId);
        require(liquidity > 0, "No liquidity");

        totalStakedLiquidity += liquidity;

        // Record the position
        stakedPositions[tokenId] = PositionInfo({
            owner: ownerOfNft,
            liquidity: liquidity,
            rewardPerLiquidityPaid: rewardPerLiquidity,
            rewardsClaimed: 0
        });

        emit PositionStaked(ownerOfNft, tokenId, liquidity);
    }

    function unstakePosition(uint256 tokenId) external nonReentrant whenNotPaused {
        PositionInfo storage pos = stakedPositions[tokenId];
        require(pos.owner == msg.sender, "Not owner");
        require(pos.liquidity > 0, "Not staked");

        // Claim any pending rewards first
        claimRewards(tokenId);

        // Remove liquidity from total
        totalStakedLiquidity -= pos.liquidity;

        // Transfer the NFT back
        pos.liquidity = 0;
        positionManager.safeTransferFrom(address(this), msg.sender, tokenId);

        emit PositionUnstaked(msg.sender, tokenId);
    }

    function claimRewards(uint256 tokenId) public nonReentrant whenNotPaused {
        PositionInfo storage pos = stakedPositions[tokenId];
        require(pos.owner == msg.sender, "Not owner");
        require(pos.liquidity > 0, "No liquidity staked");

        uint256 pending = _pendingRewards(pos);
        if (pending > 0) {
            // Update record
            pos.rewardPerLiquidityPaid = rewardPerLiquidity;
            pos.rewardsClaimed += pending;

            // Mint the rewards from thin air: we already accounted them in totalSupply 
            // by incrementing during _allocateRewardsToStakers.
            // Actually, we minted them globally to totalSupply but did not assign to anyone yet.
            // We must assign them now. We can just credit user’s balance since totalSupply is already updated.

            uint256 gonsAmount = pending * _gonsPerFragment;
            _gonsBalances[address(this)] += gonsAmount; // from "pool" inside contract (no pool needed, just internal)
            // Move from contract to user
            _gonsBalances[address(this)] -= gonsAmount;
            _gonsBalances[msg.sender] += gonsAmount;

            emit Transfer(address(this), msg.sender, pending);
            emit RewardsClaimed(msg.sender, tokenId, pending);
        } else {
            // No rewards
        }
    }

    function _pendingRewards(PositionInfo memory pos) internal view returns (uint256) {
        uint256 delta = rewardPerLiquidity - pos.rewardPerLiquidityPaid;
        return (uint256(pos.liquidity) * delta) / 1e18;
    }

    // Required by ERC721 standard to accept NFT transfers
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        require(msg.sender == address(positionManager), "Not from posManager");
        // finalize staking
        _finalizeStaking(tokenId, from);
        return this.onERC721Received.selector;
    }

    // Helper function if needed:
    function pendingRewards(uint256 tokenId) external view returns (uint256) {
        PositionInfo memory pos = stakedPositions[tokenId];
        if (pos.liquidity == 0) return 0;
        return _pendingRewards(pos);
    }
}
