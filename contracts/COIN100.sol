// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract COIN100 is ERC20Pausable, Ownable, ReentrancyGuard {
    event PriceAdj(uint256 newMCap, uint256 timestamp);
    event TokensBurned(uint256 amount);
    event TokensMinted(uint256 amount);
    event FeesUpd(uint256 devFee, uint256 burnFee, uint256 rewardFee);
    event FeePctUpd(uint256 newFeePct);
    event WalletsUpd(address devWallet);
    event RebaseIntvUpd(uint256 newIntv);
    event UpkeepDone(address indexed performer, uint256 timestamp);
    event RewardsDist(address indexed user, uint256 amount);
    event RewardRateUpd(uint256 newRate, uint256 currPrice);
    event RewardFeeUpd(uint256 newRewardFee);
    event RewardsRepl(uint256 amount, uint256 timestamp);
    event UniRouterUpd(address newRouter);
    event MaticPriceFeedUpd(address newPriceFeed);
    event C100UsdPriceFeedUpd(address newPriceFeed);
    event GovSet(address gov);
    event EligiblePairAdded(address pairAddr);
    event EligiblePairRemoved(address pairAddr);

    uint256 public constant PRICE_DECIMALS = 6;
    uint256 public constant TOKEN_DECIMALS = 18;
    uint256 public feePercent = 3;
    uint256 public devFee = 40;
    uint256 public burnFee = 40;
    uint256 public rewardFee = 20;
    uint256 public constant FEE_DIVISOR = 100;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdTime;
    uint256 public rewardRate = 1000 * 1e18;
    uint256 public totalRewards;
    uint256 public constant MAX_REWARD_RATE = 2000 * 1e18;
    uint256 public constant MIN_REWARD_RATE = 500 * 1e18;
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public lastMCap;
    uint256 public constant MAX_REBASE_PCT = 5;
    uint256 public constant MAX_MINT_AMT = 50_000_000 * 1e18;
    uint256 public constant MAX_BURN_AMT = 50_000_000 * 1e18;
    uint256 public totalMCap;
    address public devWallet;
    address public WMATIC;
    IUniswapV2Router02 public uniRouter;
    mapping(address => bool) public eligiblePairs;
    address[] public pairList;
    AggregatorV3Interface public maticUsdPriceFeed;
    AggregatorV3Interface public c100UsdPriceFeed;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    uint256 public lastRebaseTime;
    uint256 public rebaseIntv = 7 days;
    uint256 public upkeepReward = 10 * 1e18;
    address public governor;

    modifier onlyAdmin() {
        if (governor == address(0)) {
            require(owner() == msg.sender, "Not owner");
        } else {
            require(governor == msg.sender, "Not gov");
        }
        _;
    }

    constructor(
        address _wmatic,
        address _uniRouterAddr,
        address _devWallet,
        address _maticUsdPriceFeed
    ) ERC20("COIN100", "C100") Ownable(msg.sender) {
        require(_wmatic != address(0), "WMATIC zero");
        require(_devWallet != address(0), "Dev wallet zero");
        require(_uniRouterAddr != address(0), "Router zero");
        require(_maticUsdPriceFeed != address(0), "Price feed zero");

        devWallet = _devWallet;
        maticUsdPriceFeed = AggregatorV3Interface(_maticUsdPriceFeed);

        _mint(owner(), (TOTAL_SUPPLY * 90) / 100);
        _mint(devWallet, (TOTAL_SUPPLY * 5) / 100);
        _mint(address(this), (TOTAL_SUPPLY * 5) / 100);

        totalRewards += (TOTAL_SUPPLY * 5) / 100;

        lastRebaseTime = block.timestamp;
        lastUpdTime = block.timestamp;

        uniRouter = IUniswapV2Router02(_uniRouterAddr);
        WMATIC = _wmatic;

        address initialPair = IUniswapV2Factory(uniRouter.factory())
            .createPair(address(this), WMATIC);

        require(initialPair != address(0), "Pair creation failed");

        _approve(address(this), address(uniRouter), type(uint256).max);

        eligiblePairs[initialPair] = true;
        pairList.push(initialPair);
    }

    function setGov(address _gov) external onlyOwner {
        require(_gov != address(0), "Gov zero");
        require(governor == address(0), "Gov set");
        governor = _gov;
        emit GovSet(_gov);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        address sender = _msgSender();
        updReward(sender);
        updReward(recipient);

        if (sender == owner() || recipient == owner()) {
            return super.transfer(recipient, amount);
        }

        uint256 feeAmt = (amount * feePercent) / 100;
        uint256 devFeeAmt = (feeAmt * devFee) / FEE_DIVISOR;
        uint256 burnFeeAmt = (feeAmt * burnFee) / FEE_DIVISOR;
        uint256 rewardFeeAmt = (feeAmt * rewardFee) / FEE_DIVISOR;

        if (devFeeAmt > 0) {
            super.transfer(devWallet, devFeeAmt);
        }

        if (burnFeeAmt > 0) {
            _burn(sender, burnFeeAmt);
        }

        if (rewardFeeAmt > 0) {
            super.transfer(address(this), rewardFeeAmt);
            totalRewards += rewardFeeAmt;
            emit RewardsDist(address(this), rewardFeeAmt);
        }

        uint256 transferAmt = amount - feeAmt;
        return super.transfer(recipient, transferAmt);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        updReward(sender);
        updReward(recipient);

        if (sender == owner() || recipient == owner()) {
            return super.transferFrom(sender, recipient, amount);
        }

        uint256 feeAmt = (amount * feePercent) / 100;
        uint256 devFeeAmt = (feeAmt * devFee) / FEE_DIVISOR;
        uint256 burnFeeAmt = (feeAmt * burnFee) / FEE_DIVISOR;
        uint256 rewardFeeAmt = (feeAmt * rewardFee) / FEE_DIVISOR;

        if (devFeeAmt > 0) {
            super.transferFrom(sender, devWallet, devFeeAmt);
        }

        if (burnFeeAmt > 0) {
            _burn(sender, burnFeeAmt);
        }

        if (rewardFeeAmt > 0) {
            super.transferFrom(sender, address(this), rewardFeeAmt);
            totalRewards += rewardFeeAmt;
            emit RewardsDist(address(this), rewardFeeAmt);
        }

        uint256 transferAmt = amount - feeAmt;
        return super.transferFrom(sender, recipient, transferAmt);
    }

    function setFeePercent(uint256 _feePercent) external onlyAdmin {
        require(_feePercent <= 100, "Fee >100%");
        feePercent = _feePercent;
        emit FeePctUpd(_feePercent);
    }

    function updFees(
        uint256 _devFee,
        uint256 _burnFee,
        uint256 _rewardFee
    ) external onlyAdmin {
        require(
            _devFee + _burnFee + _rewardFee <= FEE_DIVISOR,
            "Fees >100%"
        );
        devFee = _devFee;
        burnFee = _burnFee;
        rewardFee = _rewardFee;
        emit FeesUpd(_devFee, _burnFee, _rewardFee);
    }

    function updWallets(address _devWallet) external onlyAdmin {
        require(_devWallet != address(0), "Dev wallet zero");
        devWallet = _devWallet;
        emit WalletsUpd(_devWallet);
    }

    function setUniRouter(address _newRouter) external onlyAdmin {
        require(_newRouter != address(0), "Router zero");
        uniRouter = IUniswapV2Router02(_newRouter);
        emit UniRouterUpd(_newRouter);
        _approve(address(this), address(uniRouter), type(uint256).max);
    }

    function updRebaseIntv(uint256 _newIntv) external onlyAdmin {
        require(_newIntv >= 7 days, "Intv <7d");
        require(_newIntv <= 365 days, "Intv >365d");
        rebaseIntv = _newIntv;
        emit RebaseIntvUpd(_newIntv);
    }

    function setUpkeepReward(uint256 _newReward) external onlyAdmin {
        upkeepReward = _newReward;
        emit RewardFeeUpd(_newReward);
    }

    function updMaticUsdPriceFeed(address _newPriceFeed) external onlyAdmin {
        require(_newPriceFeed != address(0), "Price feed zero");
        maticUsdPriceFeed = AggregatorV3Interface(_newPriceFeed);
        emit MaticPriceFeedUpd(_newPriceFeed);
    }

    function setC100UsdPriceFeed(address _newC100UsdPriceFeed)
        external
        onlyAdmin
    {
        require(_newC100UsdPriceFeed != address(0), "Price feed zero");
        c100UsdPriceFeed = AggregatorV3Interface(_newC100UsdPriceFeed);
        emit C100UsdPriceFeedUpd(_newC100UsdPriceFeed);
    }

    function upkeep(uint256 _fetchedMCap) external onlyAdmin nonReentrant {
        require(block.timestamp >= lastRebaseTime + rebaseIntv, "Intv !passed");
        require(_fetchedMCap > 0, "MCap zero");
        totalMCap = _fetchedMCap;
        adjustSupply(_fetchedMCap);
        lastRebaseTime = block.timestamp;
        emit UpkeepDone(msg.sender, block.timestamp);
    }

    function addEligiblePair(address pairAddr) external onlyAdmin {
        require(pairAddr != address(0), "Pair zero");
        require(!eligiblePairs[pairAddr], "Pair added");
        eligiblePairs[pairAddr] = true;
        pairList.push(pairAddr);
        emit EligiblePairAdded(pairAddr);
    }

    function removeEligiblePair(address pairAddr) external onlyAdmin {
        require(eligiblePairs[pairAddr], "Pair !found");
        eligiblePairs[pairAddr] = false;
        for (uint256 i = 0; i < pairList.length; i++) {
            if (pairList[i] == pairAddr) {
                pairList[i] = pairList[pairList.length - 1];
                pairList.pop();
                break;
            }
        }
        emit EligiblePairRemoved(pairAddr);
    }

    function getLatestPrice() public view returns (uint256 price) {
        if (address(c100UsdPriceFeed) != address(0)) {
            price = getPriceFromC100UsdFeed();
        } else {
            address pairMATIC = IUniswapV2Factory(uniRouter.factory()).getPair(
                address(this),
                WMATIC
            );
            if (pairMATIC != address(0)) {
                price = getDerivedPriceFromMatic(pairMATIC);
            } else {
                price = getDerivedPriceFromMaticUsd();
            }
        }
    }

    function getPriceFromC100UsdFeed() internal view returns (uint256 price) {
        (, int256 priceInt, , , ) = c100UsdPriceFeed.latestRoundData();
        require(priceInt > 0, "C100/USD price !valid");
        uint8 decimals = c100UsdPriceFeed.decimals();
        require(decimals <= PRICE_DECIMALS, "Price feed decimals >expected");
        price = uint256(priceInt) * (10 ** (PRICE_DECIMALS - decimals));
    }

    function getDerivedPriceFromMatic(address pairMATIC)
        internal
        view
        returns (uint256 priceViaMATIC)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairMATIC);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        address token0 = pair.token0();
        uint256 reserveC100;
        uint256 reserveMATIC;
        if (token0 == address(this)) {
            reserveC100 = uint256(reserve0);
            reserveMATIC = uint256(reserve1);
        } else {
            reserveC100 = uint256(reserve1);
            reserveMATIC = uint256(reserve0);
        }

        require(
            reserveC100 > 0 && reserveMATIC > 0,
            "Reserves !available"
        );

        (, int256 maticPriceInt, , , ) = maticUsdPriceFeed.latestRoundData();
        require(maticPriceInt > 0, "MATIC/USD price !valid");
        uint8 maticDecimals = maticUsdPriceFeed.decimals();
        require(
            maticDecimals <= PRICE_DECIMALS,
            "Price feed decimals >expected"
        );
        uint256 maticPriceUSD = uint256(maticPriceInt) *
            (10 ** (PRICE_DECIMALS - maticDecimals));

        priceViaMATIC = (reserveMATIC * maticPriceUSD) / reserveC100;
    }

    function getDerivedPriceFromMaticUsd()
        internal
        view
        returns (uint256 priceViaMATIC)
    {
        (, int256 maticPriceInt, , , ) = maticUsdPriceFeed.latestRoundData();
        require(maticPriceInt > 0, "MATIC/USD price !valid");
        uint8 maticDecimals = maticUsdPriceFeed.decimals();
        require(
            maticDecimals <= PRICE_DECIMALS,
            "Price feed decimals >expected"
        );
        priceViaMATIC = uint256(maticPriceInt) *
            (10 ** (PRICE_DECIMALS - maticDecimals));
        priceViaMATIC = priceViaMATIC;
    }

    function adjustSupply(uint256 fetchedMCap) internal nonReentrant {
        uint256 currPrice = getLatestPrice();
        uint256 currC100MCap = (totalSupply() * currPrice) /
            (10 ** TOKEN_DECIMALS);

        uint256 paf = (fetchedMCap * 1e18) / currC100MCap;

        if (paf > 1e18 + (MAX_REBASE_PCT * 1e16)) {
            uint256 rebaseFactor = (MAX_REBASE_PCT * 1e16);
            uint256 mintAmt = (totalSupply() * rebaseFactor) / 1e18;
            require(mintAmt <= MAX_MINT_AMT, "Mint amt >max");
            _mint(address(this), mintAmt);
            emit TokensMinted(mintAmt);
        } else if (paf < 1e18 - (MAX_REBASE_PCT * 1e16)) {
            uint256 rebaseFactor = (MAX_REBASE_PCT * 1e16);
            uint256 burnAmt = (totalSupply() * rebaseFactor) / 1e18;
            require(burnAmt <= MAX_BURN_AMT, "Burn amt >max");
            _burn(address(this), burnAmt);
            emit TokensBurned(burnAmt);
        }

        lastMCap = fetchedMCap;
        emit PriceAdj(fetchedMCap, block.timestamp);
    }

    function distributeRewards() internal {
        updReward(address(0));
        adjustRewardRate();
        uint256 distAmt = rewardRate;
        uint256 contractBal = balanceOf(address(this));
        uint256 availForDist = contractBal > totalRewards
            ? contractBal - totalRewards
            : 0;

        if (availForDist < distAmt) {
            distAmt = availForDist;
        }

        if (distAmt > 0) {
            totalRewards -= distAmt;
            lastUpdTime = block.timestamp;
            emit RewardsRepl(distAmt, block.timestamp);
        }
    }

    function claimRewards() external nonReentrant {
        updReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards");
        rewards[msg.sender] = 0;
        totalRewards -= reward;
        _transfer(address(this), msg.sender, reward);
        emit RewardsDist(msg.sender, reward);
    }

    function updReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function rewardPerToken() public view returns (uint256) {
        uint256 totalSupplyLP = getTotalSupplyOfEligibleLPs();
        if (totalSupplyLP == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((rewardRate * 1e18) / totalSupplyLP);
    }

    function earned(address account) public view returns (uint256) {
        uint256 balance = getUserBalanceInEligibleLPs(account);
        if (balance == 0) {
            return rewards[account];
        }
        return
            ((balance *
                (rewardPerTokenStored - userRewardPerTokenPaid[account])) /
                1e18) + rewards[account];
    }

    function getTotalSupplyOfEligibleLPs()
        internal
        view
        returns (uint256 totalSupplyLP)
    {
        for (uint256 i = 0; i < pairList.length; i++) {
            address pairAddr = pairList[i];
            if (eligiblePairs[pairAddr]) {
                totalSupplyLP += IUniswapV2Pair(pairAddr).totalSupply();
            }
        }
    }

    function getUserBalanceInEligibleLPs(address account)
        internal
        view
        returns (uint256 totalBalance)
    {
        for (uint256 i = 0; i < pairList.length; i++) {
            address pairAddr = pairList[i];
            if (eligiblePairs[pairAddr]) {
                totalBalance += IUniswapV2Pair(pairAddr).balanceOf(account);
            }
        }
    }

    function adjustRewardRate() internal {
        uint256 currPrice = getLatestPrice();
        uint256 newRewardRate;

        if (currPrice < 1 * 1e6) {
            newRewardRate = 2000 * 1e18;
        } else if (currPrice >= 1 * 1e6 && currPrice < 5 * 1e6) {
            newRewardRate = 1500 * 1e18;
        } else if (currPrice >= 5 * 1e6 && currPrice < 10 * 1e6) {
            newRewardRate = 1000 * 1e18;
        } else {
            newRewardRate = 500 * 1e18;
        }

        if (newRewardRate > MAX_REWARD_RATE) {
            newRewardRate = MAX_REWARD_RATE;
        } else if (newRewardRate < MIN_REWARD_RATE) {
            newRewardRate = MIN_REWARD_RATE;
        }

        if (newRewardRate != rewardRate) {
            rewardRate = newRewardRate;
            emit RewardRateUpd(newRewardRate, currPrice);
        }
    }
}
