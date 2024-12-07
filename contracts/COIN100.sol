// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract COIN100 is IERC20, Ownable, Pausable, ReentrancyGuard {
    // Numbers chosen for large precision and stable rebase math.
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000_000e18; 
    uint256 private constant GON_UNIT = 1e9; 
    
    // totalGons is mutable to allow burning supply over time.
    uint256 private totalGons = INITIAL_FRAGMENTS_SUPPLY * GON_UNIT; 
    uint256 private gonsPerFragment = totalGons / INITIAL_FRAGMENTS_SUPPLY;

    // Fee and burn ratio in basis points: 5 = 0.05%, 1000 = 10%
    uint256 public treasuryFee = 5;
    uint256 public burnRatio = 1000; 
    uint256 public targetPrice = 1e15; // 0.001 *1e18

    string public constant name = "COIN100";
    string public constant symbol = "C100";
    uint8 public constant decimals = 18;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedGons;

    uint256 public averagingPeriod = 7;
    uint256[] public mcapHistory;
    uint256 public currentIndex = 0;

    uint256 public lastRebaseTime;
    uint256 public rebaseInterval = 1 days;

    event Rebase(uint256 newGonsPerFragment, uint256 time, uint256 avgMCap, uint256 desiredSupply);
    event RebaseIntervalUpdated(uint256 newInterval);
    event TargetPriceUpdated(uint256 newPrice);
    event TreasuryFeeUpdated(uint256 newFee);
    event BurnRatioUpdated(uint256 newRatio);

    constructor() {
        _gonBalances[_msgSender()] = totalGons;
        lastRebaseTime = block.timestamp;
    }

    function totalSupply() public view override returns (uint256) {
        return totalGons / gonsPerFragment;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account] / gonsPerFragment;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedGons[owner_][spender] / gonsPerFragment;
    }

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
        require(currentAllowance >= gonAmount, "Allowance exceeded");
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
        require(currentAllowance >= gonValue, "Decrease exceeds allowance");
        _allowedGons[_msgSender()][spender] = currentAllowance - gonValue;
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender) - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0),"From zero");
        require(recipient != address(0),"To zero");

        uint256 gonAmount = amount * gonsPerFragment;
        require(_gonBalances[sender] >= gonAmount, "Balance low");

        uint256 gonFee = (gonAmount * treasuryFee) / 10000;
        uint256 gonToRecipient = gonAmount - gonFee;

        _gonBalances[sender] -= gonAmount;
        _gonBalances[address(this)] += gonFee;
        _gonBalances[recipient] += gonToRecipient;

        emit Transfer(sender, recipient, amount - (gonFee / gonsPerFragment));
    }

    function updateMcapHistory(uint256 newMCap) internal {
        if (mcapHistory.length < averagingPeriod) {
            mcapHistory.push(newMCap);
        } else {
            mcapHistory[currentIndex] = newMCap;
            currentIndex = (currentIndex + 1) % averagingPeriod;
        }
    }

    function getRollingAverageMcap() public view returns (uint256) {
        require(mcapHistory.length > 0, "No data");
        uint256 sum = 0;
        uint256 count = mcapHistory.length;
        for (uint256 i = 0; i < count; i++) {
            sum += mcapHistory[i];
        }
        return sum / count;
    }

    function upkeep(uint256 _fetchedMCap) external onlyOwner nonReentrant {
        require(block.timestamp >= lastRebaseTime + rebaseInterval, "Wait");
        require(_fetchedMCap > 0, "Zero MCap");

        if (mcapHistory.length == 0) {
            mcapHistory.push(_fetchedMCap);
        } else {
            updateMcapHistory(_fetchedMCap);
        }

        uint256 avgMCap = getRollingAverageMcap();
        uint256 desiredNewTotalSupply = avgMCap / targetPrice;
        if (desiredNewTotalSupply < 1) {desiredNewTotalSupply = 1;}

        uint256 newGonsPerFragment = totalGons / desiredNewTotalSupply;
        require(newGonsPerFragment > 0, "Invalid");
        gonsPerFragment = newGonsPerFragment;
        lastRebaseTime = block.timestamp;

        // Burn part of treasury
        uint256 gonTreasury = _gonBalances[address(this)];
        if (gonTreasury > 0 && burnRatio > 0) {
            uint256 toBurn = (gonTreasury * burnRatio) / 10000;
            if (toBurn > 0) {
                _gonBalances[address(this)] -= toBurn;
                totalGons -= toBurn; 
            }
        }

        emit Rebase(gonsPerFragment, block.timestamp, avgMCap, desiredNewTotalSupply);
    }

    function setRebaseInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval >= 1 days && _newInterval <= 365 days, "Invalid");
        rebaseInterval = _newInterval;
        emit RebaseIntervalUpdated(_newInterval);
    }

    function setTargetPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Zero price");
        targetPrice = _newPrice;
        emit TargetPriceUpdated(_newPrice);
    }

    function setTreasuryFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 100, "Too high"); // max 1%
        treasuryFee = _newFee;
        emit TreasuryFeeUpdated(_newFee);
    }

    function setBurnRatio(uint256 _newRatio) external onlyOwner {
        require(_newRatio <= 10000, "Max 100%");
        burnRatio = _newRatio;
        emit BurnRatioUpdated(_newRatio);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function seedMcap(uint256[] calldata initialData) external onlyOwner {
        require(mcapHistory.length == 0, "Seeded");
        for (uint256 i = 0; i < initialData.length; i++) {
            require(initialData[i] > 0, "Zero");
            mcapHistory.push(initialData[i]);
        }
    }

    receive() external payable {
        revert("No direct MATIC");
    }
}
