// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uniswap Interfaces
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

// Public Sale Interface
interface IC100PublicSale {
    function polRate() external view returns (uint256);
    function updatePOLRate(uint256 newRate) external;
}

contract COIN100 is Ownable, ReentrancyGuard, Pausable {
    // ----------------------------
    // ERC20 Metadata
    // ----------------------------
    string public constant name = "COIN100";
    string public constant symbol = "C100";
    uint8 public constant decimals = 18;

    // ----------------------------
    // Supply and Balances
    // ----------------------------
    uint256 private _totalSupply;
    uint256 public lastMcap;
    uint256 constant MAX_GONS = type(uint256).max / 1e18;
    uint256 private _gonsPerFrag;
    mapping(address => uint256) private _gonsBal;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ----------------------------
    // Governance and Treasury
    // ----------------------------
    address public gov;
    address public treasury;

    // ----------------------------
    // Transfer Fees
    // ----------------------------
    bool public feeEnabled;
    uint256 public feeBP; // Basis Points

    // ----------------------------
    // Liquidity Pools
    // ----------------------------
    mapping(address => bool) public lpPools;
    address[] public lpList;

    // ----------------------------
    // Public Sale Contract
    // ----------------------------
    IC100PublicSale public publicSale;

    // ----------------------------
    // Pools and Rates
    // ----------------------------
    address public c100USDC;
    address public c100POL;
    uint256 public polUSDCRate;
    uint256 public lastPolRate;

    // ----------------------------
    // Rebase Configuration
    // ----------------------------
    uint256 public rebaseFreq;
    bool private rebaseLock;

    // ----------------------------
    // Uniswap Router and WMATIC
    // ----------------------------
    IUniswapV2Router02 public quickSwap;
    address public wmatic; // Made mutable by removing 'immutable'

    // ----------------------------
    // Accumulated LP Rewards
    // ----------------------------
    uint256 public lpRewards;

    // ----------------------------
    // Enumerations
    // ----------------------------
    enum PoolType { USDC, POL }

    // ----------------------------
    // Events
    // ----------------------------
    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // Custom Events
    event Rebase(uint256 oldCap, uint256 newCap, uint256 ratio, uint256 ts);
    event GovSet(address oldGov, address newGov);
    event TreasurySet(address oldTreasury, address newTreasury);
    event FeeSet(bool enabled, uint256 bp);
    event LpPoolChanged(address pool, bool added);
    event PublicSaleSet(address oldSale, address newSale);
    event PolRateSet(uint256 oldRate, uint256 newRate);
    event PoolAddrSet(PoolType poolType, address oldPool, address newPool);
    event LiquidityChanged(address tokenA, address tokenB, uint256 amtA, uint256 amtB, uint256 liquidity);
    event RouterSet(address oldRouter, address newRouter);
    event WmaticSet(address oldWmatic, address newWmatic);
    event LpRewardsAcc(uint256 amt);
    event LpRewardsDist(uint256 total);

    /**
     * @notice Constructor to initialize the COIN100 token.
     * @param initMcap Initial market capitalization.
     * @param initPolRate Initial POL rate.
     * @param _quickSwap Address of the QuickSwap Router.
     * @param _wmatic Address of the WMATIC token.
     * @param _treasury Address of the treasury.
     */
    constructor(
        uint256 initMcap, 
        uint256 initPolRate,
        address _quickSwap,
        address _wmatic,
        address _treasury
    ) Ownable(_treasury) ReentrancyGuard() Pausable() {
        require(initMcap > 0, "MC0");
        require(initPolRate > 0, "PR0");
        require(_quickSwap != address(0), "QR0");
        require(_wmatic != address(0), "WM0");
        require(_treasury != address(0), "T0");

        quickSwap = IUniswapV2Router02(_quickSwap);
        wmatic = _wmatic;
        treasury = _treasury;

        uint256 scaledMcap = initMcap * 1e18;
        _totalSupply = scaledMcap;
        lastMcap = scaledMcap;

        _gonsPerFrag = MAX_GONS / _totalSupply;
        _gonsBal[treasury] = _totalSupply * _gonsPerFrag;

        emit Transfer(address(0), treasury, _totalSupply);

        rebaseFreq = 1 days;
        feeEnabled = true;
        feeBP = 100; // 1%

        lpRewards = 0;
        lastPolRate = initPolRate * 1e18;
    }

    // ----------------------------
    // Modifiers
    // ----------------------------
    modifier onlyAdmin() {
        require(msg.sender == owner() || (gov != address(0) && msg.sender == gov), "NA");
        _;
    }

    modifier notRebasing() {
        require(!rebaseLock, "RB");
        _;
    }

    // ----------------------------
    // ERC20 Standard Functions
    // ----------------------------
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address acc) external view returns (uint256) {
        return _gonsBal[acc] / _gonsPerFrag;
    }

    function allowance(address owner_, address spender) external view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function transfer(address to, uint256 amt) external whenNotPaused notRebasing returns (bool) {
        _transfer(msg.sender, to, amt);
        return true;
    }

    function approve(address spender, uint256 amt) external whenNotPaused notRebasing returns (bool) {
        _approve(msg.sender, spender, amt);
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external whenNotPaused notRebasing returns (bool) {
        uint256 current = _allowances[from][msg.sender];
        require(current >= amt, "AEx");
        _transfer(from, to, amt);
        _approve(from, msg.sender, current - amt);
        return true;
    }

    function increaseAllowance(address spender, uint256 addVal) external whenNotPaused notRebasing returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addVal);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subVal) external whenNotPaused notRebasing returns (bool) {
        uint256 current = _allowances[msg.sender][spender];
        require(current >= subVal, "B0");
        _approve(msg.sender, spender, current - subVal);
        return true;
    }

    // ----------------------------
    // Internal Transfer and Approve Functions
    // ----------------------------
    function _transfer(address from, address to, uint256 amt) internal {
        require(from != address(0), "F0");
        require(to != address(0), "T0");
        require(_gonsBal[from] >= amt * _gonsPerFrag, "B0");

        uint256 gonsAmt = amt * _gonsPerFrag;
        _gonsBal[from] -= gonsAmt;

        if (feeEnabled && feeBP > 0) {
            uint256 feeGons = (gonsAmt * feeBP) / 10000;
            uint256 tFeeGons = (feeGons * 70) / 100;
            uint256 lpFeeGons = feeGons - tFeeGons;

            _gonsBal[treasury] += tFeeGons;
            lpRewards += lpFeeGons / _gonsPerFrag;

            uint256 tFee = tFeeGons / _gonsPerFrag;
            uint256 lpFee = lpFeeGons / _gonsPerFrag;
            uint256 recipientAmt = (gonsAmt - feeGons) / _gonsPerFrag;

            emit Transfer(from, treasury, tFee);
            emit LpRewardsAcc(lpFee);
            emit Transfer(from, to, recipientAmt);
        } else {
            _gonsBal[to] += gonsAmt;
            emit Transfer(from, to, amt);
        }
    }

    function _approve(address owner_, address spender, uint256 amt) internal {
        require(owner_ != address(0), "O0");
        require(spender != address(0), "S0");
        _allowances[owner_][spender] = amt;
        emit Approval(owner_, spender, amt);
    }

    // ----------------------------
    // Rebase Functionality
    // ----------------------------
    function rebase(uint256 newMcap) internal {
        require(newMcap > 0, "M0");

        uint256 oldMcap = lastMcap;
        uint256 oldSupply = _totalSupply;

        uint256 oldPol = lastPolRate;
        uint256 newPol = _getPolRate();
        lastPolRate = newPol;

        if (address(publicSale) != address(0)) {
            publicSale.updatePOLRate(newPol);
        }
        emit PolRateSet(oldPol, newPol);

        uint256 scaledMcap = newMcap * 1e18;
        uint256 ratio = oldMcap > 0 ? (scaledMcap * 1e18) / oldMcap : 1e18;

        uint256 newSupply = (oldSupply * ratio) / 1e18;
        if (newSupply == 0) newSupply = oldSupply;

        uint256 excluded = 0;
        uint256 len = lpList.length;
        for (uint256 i = 0; i < len; ) {
            excluded += _gonsBal[lpList[i]] / _gonsPerFrag;
            unchecked { i++; }
        }

        uint256 effSupply = newSupply > excluded ? newSupply - excluded : 0;

        _gonsPerFrag = (effSupply + excluded) > 0 ? MAX_GONS / (effSupply + excluded) : _gonsPerFrag;
        _totalSupply = effSupply + excluded;
        lastMcap = scaledMcap;

        emit Rebase(oldMcap, scaledMcap, ratio, block.timestamp);
    }

    function _getPolRate() internal view returns (uint256) {
        // POL Pool
        if (c100POL != address(0)) {
            (uint112 rp0_p, uint112 rp1_p,) = IUniswapV2Pair(c100POL).getReserves();
            address t0_p = IUniswapV2Pair(c100POL).token0();
            uint256 c100R_p = t0_p == address(this) ? rp0_p : rp1_p;
            uint256 polR_p = t0_p == address(this) ? rp1_p : rp0_p;

            if (polR_p > 0) {
                uint256 rate_p = (c100R_p * 1e18) / polR_p;
                if (rate_p > 0) return rate_p;
            }
        }

        // USDC Pool
        if (c100USDC != address(0) && polUSDCRate > 0) {
            (uint112 ru0_u, uint112 ru1_u,) = IUniswapV2Pair(c100USDC).getReserves();
            address tu0_u = IUniswapV2Pair(c100USDC).token0();
            uint256 c100R_u = tu0_u == address(this) ? ru0_u : ru1_u;
            uint256 usdcR_u = tu0_u == address(this) ? ru1_u : ru0_u;

            if (c100R_u > 0) {
                uint256 price = (usdcR_u * 1e18) / c100R_u;
                if (price > 0) {
                    uint256 rate_u = (polUSDCRate * 1e18) / price;
                    if (rate_u > 0) return rate_u;
                }
            }
        }

        return lastPolRate;
    }

    // ----------------------------
    // Admin Functions
    // ----------------------------

    /**
     * @notice Sets the governor contract address and transfers ownership.
     * @param _gov The address of the new governor contract.
     */
    function setGov(address _gov) external onlyOwner {
        require(_gov != address(0), "G0");
        address oldGov = gov;
        gov = _gov;
        emit GovSet(oldGov, _gov);
        transferOwnership(_gov);
    }

    /**
     * @notice Sets the public sale contract address.
     * @param _sale The address of the new public sale contract.
     */
    function setPublicSale(address _sale) external onlyOwner {
        require(_sale != address(0), "PS0");
        address oldSale = address(publicSale);
        publicSale = IC100PublicSale(_sale);
        emit PublicSaleSet(oldSale, _sale);
    }

    /**
     * @notice Pauses the contract, halting transfers and other operations.
     */
    function pauseContract() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Unpauses the contract, resuming transfers and other operations.
     */
    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    /**
     * @notice Sets the rebase frequency.
     * @param freq The new frequency in seconds.
     */
    function setRebaseFreq(uint256 freq) external onlyAdmin {
        rebaseFreq = freq;
        // Optionally emit an event here
    }

    /**
     * @notice Sets the transfer fee parameters.
     * @param enabled Boolean to enable or disable transfer fees.
     * @param bp The new fee in basis points (max 1000).
     */
    function setFee(bool enabled, uint256 bp) external onlyAdmin {
        require(bp <= 1000, "F1");
        feeEnabled = enabled;
        feeBP = bp;
        emit FeeSet(enabled, bp);
    }

    /**
     * @notice Updates the treasury address.
     * @param newTreasury The new treasury address.
     */
    function updateTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "T0");
        address old = treasury;
        treasury = newTreasury;
        emit TreasurySet(old, newTreasury);
    }

    /**
     * @notice Burns tokens from the treasury.
     * @param amt The amount of tokens to burn.
     */
    function burnFromTreasury(uint256 amt) external onlyAdmin nonReentrant {
        require(_gonsBal[treasury] >= amt * _gonsPerFrag, "B0");
        _gonsBal[treasury] -= amt * _gonsPerFrag;
        _totalSupply -= amt;

        if (_totalSupply > 0) {
            _gonsPerFrag = MAX_GONS / _totalSupply;
        }

        emit Transfer(treasury, address(0), amt);
    }

    /**
     * @notice Adds or removes a liquidity pool from the list.
     * @param pool The address of the liquidity pool.
     * @param add Boolean indicating whether to add or remove.
     */
    function setLiquidityPool(address pool, bool add) external onlyAdmin {
        require(pool != address(0), "LP0");
        if (add) {
            require(!lpPools[pool], "LPA");
            lpPools[pool] = true;
            lpList.push(pool);
        } else {
            require(lpPools[pool], "LPR");
            lpPools[pool] = false;
            uint256 len = lpList.length;
            for (uint256 i = 0; i < len; ) {
                if (lpList[i] == pool) {
                    lpList[i] = lpList[len - 1];
                    lpList.pop();
                    break;
                }
                unchecked { i++; }
            }
        }
        emit LpPoolChanged(pool, add);
    }

    /**
     * @notice Sets the liquidity pool addresses.
     * @param pt The type of pool (USDC or POL).
     * @param pool The address of the liquidity pool.
     */
    function setPoolAddr(PoolType pt, address pool) external onlyAdmin {
        require(pool != address(0), "PA0");
        if (pt == PoolType.USDC) {
            address old = c100USDC;
            c100USDC = pool;
            emit PoolAddrSet(pt, old, pool);
        } else if (pt == PoolType.POL) {
            address old = c100POL;
            c100POL = pool;
            emit PoolAddrSet(pt, old, pool);
        } else {
            revert("PT");
        }
    }

    /**
     * @notice Sets the POL in USDC rate.
     * @param newRate The new POL in USDC rate (must be > 0).
     */
    function setPolUSDCRate(uint256 newRate) external onlyAdmin {
        require(newRate > 0, "R0");
        uint256 old = polUSDCRate;
        polUSDCRate = newRate;
        emit PolRateSet(old, newRate);
    }

    /**
     * @notice Sets the QuickSwap Router address.
     * @param _qs The new QuickSwap Router address.
     */
    function setQuickSwap(address _qs) external onlyAdmin {
        require(_qs != address(0), "QS0");
        address old = address(quickSwap);
        quickSwap = IUniswapV2Router02(_qs);
        emit RouterSet(old, _qs);
    }

    /**
     * @notice Sets the WMATIC address.
     * @param _wm The new WMATIC address.
     */
    function setWmatic(address _wm) external onlyAdmin {
        require(_wm != address(0), "WM0");
        address old = wmatic;
        wmatic = _wm;
        emit WmaticSet(old, _wm);
    }

    // ----------------------------
    // Liquidity Management Functions
    // ----------------------------

    /**
     * @notice Adds liquidity to the specified QuickSwap pool.
     * @param tokenA Address of token A (C100 or USDC).
     * @param tokenB Address of token B (WMATIC or POL).
     * @param amtA Amount of token A to add.
     * @param amtB Amount of token B to add.
     * @param to Recipient address for liquidity tokens.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amtA,
        uint256 amtB,
        address to
    ) external onlyAdmin nonReentrant whenNotPaused notRebasing {
        require(tokenA != address(0) && tokenB != address(0), "TK0");
        require(to != address(0), "T0");
        require(amtA > 0 && amtB > 0, "A0");

        rebaseLock = true;
        _pause();

        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amtA), "TF");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amtB), "TFB");

        require(IERC20(tokenA).approve(address(quickSwap), amtA), "AP");
        require(IERC20(tokenB).approve(address(quickSwap), amtB), "APB");

        (uint256 addedA, uint256 addedB, uint256 liquidity) = quickSwap.addLiquidity(
            tokenA,
            tokenB,
            amtA,
            amtB,
            0,
            0,
            to,
            block.timestamp
        );

        emit LiquidityChanged(tokenA, tokenB, addedA, addedB, liquidity);

        _unpause();
        rebaseLock = false;
    }

    /**
     * @notice Removes liquidity from the specified QuickSwap pool.
     * @param tokenA Address of token A (C100 or USDC).
     * @param tokenB Address of token B (WMATIC or POL).
     * @param liquidity Amount of liquidity tokens to remove.
     * @param to Recipient address for removed tokens.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        address to
    ) external onlyAdmin nonReentrant whenNotPaused notRebasing {
        require(tokenA != address(0) && tokenB != address(0), "TK0");
        require(to != address(0), "T0");
        require(liquidity > 0, "L0");

        address pair = IUniswapV2Factory(quickSwap.factory()).getPair(tokenA, tokenB);
        require(pair != address(0), "P0");

        rebaseLock = true;
        _pause();

        require(IERC20(pair).transferFrom(msg.sender, address(this), liquidity), "TLP");

        require(IERC20(pair).approve(address(quickSwap), liquidity), "ALP");

        (uint256 amtA, uint256 amtB) = quickSwap.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            0,
            0,
            to,
            block.timestamp
        );

        emit LiquidityChanged(tokenA, tokenB, amtA, amtB, liquidity);

        _unpause();
        rebaseLock = false;
    }

    // ----------------------------
    // Rebase Control Functions
    // ----------------------------

    /**
     * @notice Performs a manual rebase operation.
     * @param newMcap The new market capitalization to rebase to.
     */
    function performRebase(uint256 newMcap) external onlyAdmin nonReentrant whenNotPaused notRebasing {
        require(!rebaseLock, "RB");
        rebase(newMcap);
    }

    // ----------------------------
    // Liquidity Pool Exclusion Functions
    // ----------------------------

    /**
     * @notice Excludes a liquidity pool from rebasing.
     * @param pool The address of the liquidity pool to exclude.
     */
    function excludeLp(address pool) external onlyAdmin {
        require(lpPools[pool], "LP0");
        // No additional action needed as excluded pools are handled in the rebase function
    }

    // ----------------------------
    // Fee Redistribution to Liquidity Pools
    // ----------------------------

    /**
     * @notice Distributes accumulated LP rewards to liquidity pools or treasury.
     */
    function distributeLpRewards() external onlyAdmin nonReentrant whenNotPaused {
        require(lpRewards > 0, "ALP0");

        if (lpList.length > 0) {
            uint256 totalLiq = 0;
            uint256 len = lpList.length;
            for (uint256 i = 0; i < len; ) {
                totalLiq += IERC20(lpList[i]).balanceOf(address(this));
                unchecked { i++; }
            }
            require(totalLiq > 0, "TL0");

            uint256 totalDist = 0;

            for (uint256 i = 0; i < len; ) {
                address pool = lpList[i];
                uint256 bal = IERC20(pool).balanceOf(address(this));
                if (bal > 0) {
                    uint256 share = (bal * 1e18) / totalLiq;
                    uint256 reward = (lpRewards * share) / 1e18;

                    _gonsBal[pool] += reward * _gonsPerFrag;

                    emit Transfer(address(this), pool, reward);
                    totalDist += reward;
                }
                unchecked { i++; }
            }

            lpRewards -= totalDist;
            emit LpRewardsDist(totalDist);
        } else {
            // Distribute all to treasury
            uint256 reward = lpRewards;
            _gonsBal[treasury] += reward * _gonsPerFrag;

            emit Transfer(address(this), treasury, reward);
            emit LpRewardsDist(reward);

            lpRewards = 0;
        }
    }

    // ----------------------------
    // Receive and Fallback Functions
    // ----------------------------
    receive() external payable {
        revert("NE");
    }

    fallback() external payable {
        revert("NE");
    }
}
