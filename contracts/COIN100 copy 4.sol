// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title COIN100: Dynamic Market Cap-Tracking Token
/// @notice This contract adjusts its total supply based on the total market cap of the top 100 cryptocurrencies.
/// It allocates 3% of the supply to the owner and 97% to a public sale address. Supply adjustments are performed manually by the owner.
contract COIN100 is IERC20, Ownable, Pausable, ReentrancyGuard {
    // --------------------------------------
    // Token Metadata
    // --------------------------------------
    string public constant name = "COIN100";
    string public constant symbol = "C100";
    uint8 public constant decimals = 18;

    // --------------------------------------
    // Supply and Scaling
    // --------------------------------------
    uint256 public scalingFactor = 1_000_000; // Scaling factor S = 1e6

    uint256 private _totalSupply;
    uint256 public ownerAllocation;      // 3% of total supply
    uint256 public publicSaleAllocation; // 97% of total supply

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // --------------------------------------
    // Addresses
    // --------------------------------------
    address public publicSaleAddress;

    // --------------------------------------
    // Events
    // --------------------------------------
    event SupplyAdjusted(uint256 newTotalSupply, uint256 timestamp);
    event PublicSaleAddressSet(address indexed publicSaleAddress);
    event ScalingFactorUpdated(uint256 newScalingFactor);

    // --------------------------------------
    // Constructor
    // --------------------------------------
    /// @param initialMCap The initial total market cap of the top 100 cryptocurrencies in USD.
    /// @param _publicSaleAddress The address designated to hold the 97% public sale allocation.
    constructor(uint256 initialMCap, address _publicSaleAddress)
        Ownable(msg.sender)
        Pausable()
        ReentrancyGuard()
    {
        require(initialMCap > 0, "Initial market cap must be greater than zero");
        require(_publicSaleAddress != address(0), "Public sale address cannot be zero");

        publicSaleAddress = _publicSaleAddress;
        emit PublicSaleAddressSet(_publicSaleAddress);

        // Calculate total supply based on initial market cap and scaling factor
        _totalSupply = initialMCap / scalingFactor;

        // Calculate allocations
        ownerAllocation = (_totalSupply * 3) / 100;             // 3%
        publicSaleAllocation = _totalSupply - ownerAllocation;  // 97%

        // Mint allocations
        _balances[owner()] += ownerAllocation;
        emit Transfer(address(0), owner(), ownerAllocation);

        _balances[publicSaleAddress] += publicSaleAllocation;
        emit Transfer(address(0), publicSaleAddress, publicSaleAllocation);

        emit SupplyAdjusted(_totalSupply, block.timestamp);
    }

    // --------------------------------------
    // ERC20 Standard (View)
    // --------------------------------------
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    // --------------------------------------
    // ERC20 Standard (Mutative)
    // --------------------------------------
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // --------------------------------------
    // ERC20 Standard (Allowances)
    // --------------------------------------
    function increaseAllowance(address spender, uint256 addedValue) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // --------------------------------------
    // Internal Transfer Logic
    // --------------------------------------
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    // --------------------------------------
    // Internal Approve Logic
    // --------------------------------------
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    // --------------------------------------
    // Supply Adjustment (Upkeep)
    // --------------------------------------
    /// @notice Adjusts the total supply based on the new total market cap.
    /// @param newMCap The updated total market cap of the top 100 cryptocurrencies in USD.
    function upkeep(uint256 newMCap) external onlyOwner nonReentrant whenNotPaused {
        require(newMCap > 0, "New market cap must be greater than zero");

        // Calculate new total supply based on new market cap
        uint256 newTotalSupply = newMCap / scalingFactor;

        // Calculate new allocations
        uint256 newOwnerAllocation = (newTotalSupply * 3) / 100;             // 3%
        uint256 newPublicSaleAllocation = newTotalSupply - newOwnerAllocation; // 97%

        // Calculate differences
        int256 deltaOwner = int256(newOwnerAllocation) - int256(ownerAllocation);
        int256 deltaPublicSale = int256(newPublicSaleAllocation) - int256(publicSaleAllocation);

        // Adjust owner supply
        if (deltaOwner > 0) {
            _mint(owner(), uint256(deltaOwner));
        } else if (deltaOwner < 0) {
            _burn(owner(), uint256(-deltaOwner));
        }

        // Adjust public sale supply
        if (deltaPublicSale > 0) {
            _mint(publicSaleAddress, uint256(deltaPublicSale));
        } else if (deltaPublicSale < 0) {
            _burn(publicSaleAddress, uint256(-deltaPublicSale));
        }

        // Update allocations and total supply
        ownerAllocation = newOwnerAllocation;
        publicSaleAllocation = newPublicSaleAllocation;
        _totalSupply = newTotalSupply;

        emit SupplyAdjusted(_totalSupply, block.timestamp);
    }

    // --------------------------------------
    // Mint Function (Internal)
    // --------------------------------------
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");

        _totalSupply += amount;
        _balances[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    // --------------------------------------
    // Burn Function (Internal)
    // --------------------------------------
    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "Burn from zero address");
        require(_balances[from] >= amount, "Burn amount exceeds balance");

        _balances[from] -= amount;
        _totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }

    // --------------------------------------
    // Admin Functions
    // --------------------------------------
    /// @notice Sets a new public sale address.
    /// @param _newPublicSaleAddress The new public sale address.
    function setPublicSaleAddress(address _newPublicSaleAddress) external onlyOwner {
        require(_newPublicSaleAddress != address(0), "Public sale address cannot be zero");
        publicSaleAddress = _newPublicSaleAddress;
        emit PublicSaleAddressSet(_newPublicSaleAddress);
    }

    /// @notice Updates the scaling factor.
    /// @param _newScalingFactor The new scaling factor to set.
    function updateScalingFactor(uint256 _newScalingFactor) external onlyOwner {
        require(_newScalingFactor > 0, "Scaling factor must be greater than zero");
        scalingFactor = _newScalingFactor;
        emit ScalingFactorUpdated(_newScalingFactor);
    }

    /// @notice Pauses all token transfers.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses all token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --------------------------------------
    // Fallback
    // --------------------------------------
    receive() external payable {
        revert("Contract does not accept Ether");
    }

    fallback() external payable {
        revert("Contract does not accept Ether");
    }
}