// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract COIN100 is ERC20Pausable, Ownable, ReentrancyGuard {
    event PriceAdj(uint256 newMCap, uint256 timestamp);
    event FeesUpd(uint256 devFee, uint256 rewardFee);
    event FeePctUpd(uint256 newFeePct);
    event WalletsUpd(address devWallet);
    event RebaseIntvUpd(uint256 newIntv);
    event UpkeepDone(address indexed performer, uint256 timestamp);
    event RewardsDist(address indexed user, uint256 amount);
    event RewardRateUpd(uint256 newRate, uint256 currMcap);
    event RewardFeeUpd(uint256 newReward);
    event RewardsRepl(uint256 amount, uint256 timestamp);
    event UniRouterUpd(address newRouter);
    event GovSet(address gov);
    event EligiblePairAdded(address pairAddr);
    event EligiblePairRemoved(address pairAddr);

    uint256 public constant TOKEN_DECIMALS = 18;
    uint256 public feePercent = 5; // 5 = 0.5% (fee applied on transfers)
    uint256 public devFee = 10;    // 10% of fee portion
    uint256 public rewardFee = 90; // 90% of fee portion
    uint256 public constant FEE_DIVISOR = 100;

    uint256 public rewardPerTokenStored;
    uint256 public lastUpdTime;
    uint256 public rewardRate = 1000 * 1e18;
    uint256 public totalRewards;
    uint256 public constant MAX_REWARD_RATE = 2000 * 1e18;
    uint256 public constant MIN_REWARD_RATE = 500 * 1e18;
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public lastMCap;
    uint256 public totalMCap;
    address public devWallet;
    IUniswapV2Router02 public uniRouter;
    mapping(address => bool) public eligiblePairs;
    address[] public pairList;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public lastRebaseTime;
    uint256 public rebaseIntv = 1 days;
    uint256 public upkeepReward = 10 * 1e18;
    address public governor;

    // Rolling average MCap variables
    uint256 public averagingPeriod = 7; 
    uint256[] public mcapHistory;
    uint256 public currentIndex = 0;

    // scalingFactor: used to determine supply from MCap
    // newSupply = (rollingAverageMcap * scalingFactor) / 1e18
    uint256 public scalingFactor; 

    // LP Reward Multiplier
    uint256 public lpRewardMultiplier = 120; // LP gets 20% more rewards than normal holders

    modifier onlyAdmin() {
        if (governor == address(0)) {
            require(owner() == msg.sender, "Not owner");
        } else {
            require(governor == msg.sender, "Not gov");
        }
        _;
    }

    constructor(
        address _uniRouterAddr,
        address _devWallet
    ) ERC20("COIN100", "C100") Ownable(msg.sender) {
        require(_devWallet != address(0), "Dev wallet zero");
        require(_uniRouterAddr != address(0), "Router zero");

        devWallet = _devWallet;

        // Mint initial supply
        // 90% to owner, 5% to dev, 5% to contract for rewards
        _mint(owner(), (TOTAL_SUPPLY * 90) / 100);
        _mint(devWallet, (TOTAL_SUPPLY * 5) / 100);
        _mint(address(this), (TOTAL_SUPPLY * 5) / 100);

        totalRewards += (TOTAL_SUPPLY * 5) / 100;

        lastRebaseTime = block.timestamp;
        lastUpdTime = block.timestamp;

        uniRouter = IUniswapV2Router02(_uniRouterAddr);

        address initialPair = IUniswapV2Factory(uniRouter.factory())
            .createPair(address(this), uniRouter.WETH());

        require(initialPair != address(0), "Pair creation failed");

        _approve(address(this), address(uniRouter), type(uint256).max);

        eligiblePairs[initialPair] = true;
        pairList.push(initialPair);
    }

    // -------------------
    // Governance
    // -------------------
    function setGov(address _gov) external onlyOwner {
        require(_gov != address(0), "Gov zero");
        require(governor == address(0), "Gov set");
        governor = _gov;
        emit GovSet(_gov);
    }

    // -------------------
    // Transfers with Fee
    // -------------------
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

        // feePercent=5 means 0.5%
        uint256 feeAmt = (amount * feePercent) / 1000; 
        uint256 devFeeAmt = (feeAmt * devFee) / 100; 
        uint256 rewardFeeAmt = feeAmt - devFeeAmt; 

        if (devFeeAmt > 0) {
            super.transfer(devWallet, devFeeAmt);
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

        uint256 feeAmt = (amount * feePercent) / 1000; 
        uint256 devFeeAmt = (feeAmt * devFee) / 100; 
        uint256 rewardFeeAmt = feeAmt - devFeeAmt; 

        if (devFeeAmt > 0) {
            super.transferFrom(sender, devWallet, devFeeAmt);
        }

        if (rewardFeeAmt > 0) {
            super.transferFrom(sender, address(this), rewardFeeAmt);
            totalRewards += rewardFeeAmt;
            emit RewardsDist(address(this), rewardFeeAmt);
        }

        uint256 transferAmt = amount - feeAmt;
        return super.transferFrom(sender, recipient, transferAmt);
    }

    // -------------------
    // Admin Functions
    // -------------------
    function setFeePercent(uint256 _feePercent) external onlyAdmin {
        require(_feePercent <= 1000, "Fee >100%");
        feePercent = _feePercent;
        emit FeePctUpd(_feePercent);
    }

    function updFees(
        uint256 _devFee,
        uint256 _rewardFee
    ) external onlyAdmin {
        require(_devFee + _rewardFee == 100, "Fees must total 100%");
        devFee = _devFee;
        rewardFee = _rewardFee;
        emit FeesUpd(_devFee, _rewardFee);
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
        require(_newIntv >= 1 days, "Intv <1d");
        require(_newIntv <= 365 days, "Intv >365d");
        rebaseIntv = _newIntv;
        emit RebaseIntvUpd(_newIntv);
    }

    function setUpkeepReward(uint256 _newReward) external onlyAdmin {
        upkeepReward = _newReward;
        emit RewardFeeUpd(_newReward);
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

    // -------------------
    // Rolling Average Logic
    // -------------------
    function updateMcapHistory(uint256 newMCap) internal {
        if (mcapHistory.length < averagingPeriod) {
            mcapHistory.push(newMCap);
        } else {
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

    // -------------------
    // Upkeep (Rebase) Logic
    // -------------------
    function upkeep(uint256 _fetchedMCap) external onlyAdmin nonReentrant {
        require(block.timestamp >= lastRebaseTime + rebaseIntv, "Intv !passed");
        require(_fetchedMCap > 0, "MCap zero");

        updateMcapHistory(_fetchedMCap);
        uint256 avgMCap = getRollingAverageMcap();

        // If scalingFactor not set yet (i.e., first upkeep), initialize it
        if (scalingFactor == 0) {
            // initialSupply = totalSupply() = TOTAL_SUPPLY
            // scalingFactor = (initialSupply * 1e18) / avgMCap
            scalingFactor = (totalSupply() * 1e18) / avgMCap;
        }

        uint256 oldSupply = totalSupply();
        uint256 newSupply = (avgMCap * scalingFactor) / 1e18;

        if (newSupply > oldSupply) {
            uint256 mintAmt = newSupply - oldSupply;
            _mint(address(this), mintAmt); 
        } else if (newSupply < oldSupply) {
            uint256 burnAmt = oldSupply - newSupply;
            _burn(address(this), burnAmt);
        }

        totalMCap = _fetchedMCap;
        lastMCap = _fetchedMCap;
        lastRebaseTime = block.timestamp;

        emit UpkeepDone(msg.sender, block.timestamp);
    }

    // -------------------
    // Reward Logic
    // -------------------
    function getTotalEffectiveSupply() internal view returns (uint256) {
        uint256 totalLPBal = 0;
        for (uint256 i = 0; i < pairList.length; i++) {
            if (eligiblePairs[pairList[i]]) {
                uint256 lpSupply = IUniswapV2Pair(pairList[i]).totalSupply();
                totalLPBal += lpSupply;
            }
        }
        uint256 effectiveSupply = totalSupply() + ((totalLPBal * lpRewardMultiplier) / 100);
        return effectiveSupply;
    }

    function getUserEffectiveBalance(address account) internal view returns (uint256) {
        uint256 normalBal = balanceOf(account);
        uint256 userLPBal = 0;
        for (uint256 i = 0; i < pairList.length; i++) {
            if (eligiblePairs[pairList[i]]) {
                userLPBal += IUniswapV2Pair(pairList[i]).balanceOf(account);
            }
        }
        uint256 effectiveBal = normalBal + ((userLPBal * lpRewardMultiplier) / 100);
        return effectiveBal;
    }

    function rewardPerToken() public view returns (uint256) {
        uint256 effectiveSupply = getTotalEffectiveSupply();
        if (effectiveSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((rewardRate * 1e18) / effectiveSupply);
    }

    function earned(address account) public view returns (uint256) {
        uint256 effectiveBal = getUserEffectiveBalance(account);
        return ((effectiveBal * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
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

    function adjustRewardRate() internal {
        uint256 currMcap = getRollingAverageMcap();

        // Production-ready logic for adjusting rewardRate based on MCap:
        if (currMcap < 100_000_000e18) {
            rewardRate = 2000 * 1e18; // Highest reward rate for very low MCap scenario
        } else if (currMcap >= 100_000_000e18 && currMcap < 500_000_000e18) {
            rewardRate = 1500 * 1e18; // Medium-high reward for moderate MCap
        } else if (currMcap >= 500_000_000e18 && currMcap < 1_000_000_000e18) {
            rewardRate = 1000 * 1e18; // Default reward rate for medium MCap
        } else {
            rewardRate = 500 * 1e18; // Minimum reward rate for very large MCap
        }

        // Ensure rewardRate stays within min/max bounds
        if (rewardRate > MAX_REWARD_RATE) {
            rewardRate = MAX_REWARD_RATE;
        } else if (rewardRate < MIN_REWARD_RATE) {
            rewardRate = MIN_REWARD_RATE;
        }

        emit RewardRateUpd(rewardRate, currMcap);
    }

    // -------------------
    // Pausable
    // -------------------
    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}
