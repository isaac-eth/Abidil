// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract EscrowUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct Deal {
        address creator;
        address payer;
        address token;
        uint256 cost;
        uint256 commission;
        bool paid;
        bool released;
        bool canceled;
    }

    uint256 public commissionPercent; // 250 = 2.5%
    address public withdrawWallet;
    uint256 public nextDealId;

    mapping(uint256 => Deal) public deals;
    mapping(address => bool) public allowedTokens;
    mapping(address => uint256[]) public createdDeals;
    mapping(address => uint256[]) public paidDeals;
    mapping(address => uint256[]) public releasedDeals;
    mapping(address => uint256) public accumulatedCommissions;
    mapping(address => bool) public noFeeWallets;


    event DealCreated(
        address indexed creator,
        address indexed token,
        uint256 cost,
        uint256 commissionPercent,
        uint256 commissionAmount,
        uint256 indexed dealId
    );

    event DealPaid(
        uint256 indexed dealId,
        address indexed payer,
        uint256 amount
    );

    event DealReleased(
        uint256 indexed dealId,
        address indexed to
    );

    event DealCanceled(
        uint256 indexed dealID,
        address indexed by
    );

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    function __buildTag() external pure returns (string memory) { return "build-2025-08-10"; }

    // --- Admin functions ---
    function setWithdrawWallet(address _wallet) external onlyOwner {
        withdrawWallet = _wallet;
    }

    function setCommissionPercent(uint256 _percent) external onlyOwner {
        commissionPercent = _percent;
    }

    function addAllowedToken(address _token) external onlyOwner {
        allowedTokens[_token] = true;
    }

    function setNoFeeWallet(address _wallet, bool _status) external onlyOwner {
        noFeeWallets[_wallet] = _status;
    }

    // soloOwner: ajusta contabilidad legacy
    function adminSetAccumulatedCommission(address _token, uint256 amount) external onlyOwner {
        accumulatedCommissions[_token] = amount;
    }



    // --- Core Logic ---
    function createDeal(address _token, uint256 _cost) external {
        require(allowedTokens[_token], "Token not allowed");

        // Si la wallet está marcada como "noFeeWallet", la comisión es 0
        uint256 commission = noFeeWallets[msg.sender] ? 0 : (_cost * commissionPercent) / 10000;
        uint256 halfCommission = commission / 2;

        // Solo se transfiere comisión si es > 0
        if (halfCommission > 0) {
            IERC20Upgradeable(_token).transferFrom(msg.sender, address(this), halfCommission);
            accumulatedCommissions[_token] += halfCommission;
        }

        Deal storage deal = deals[nextDealId];
        deal.creator = msg.sender;
        deal.token = _token;
        deal.cost = _cost;
        deal.commission = commission;

        createdDeals[msg.sender].push(nextDealId);

        emit DealCreated(msg.sender, _token, _cost, commissionPercent, commission, nextDealId);
        nextDealId++;
    }


    function payDeal(uint256 _dealId) external nonReentrant {
        Deal storage deal = deals[_dealId];
        require(!deal.paid, "Already paid");
        require(!deal.released, "Already released");
        require(!deal.canceled, "Deal canceled");

        uint256 total = deal.cost + (deal.commission / 2);
        IERC20Upgradeable(deal.token).transferFrom(msg.sender, address(this), total);

        deal.paid = true;
        deal.payer = msg.sender;
        paidDeals[msg.sender].push(_dealId);

        uint256 halfCommission = deal.commission / 2;
        accumulatedCommissions[deal.token] += halfCommission;

        emit DealPaid(_dealId, msg.sender, total);
    }

    function releaseDeal(uint256 _dealId) external nonReentrant {
        Deal storage deal = deals[_dealId];
        require(deal.paid, "Not paid yet");
        require(!deal.released, "Already released");
        require(msg.sender == deal.creator || msg.sender == owner(), "Only payer or owner can release");

        deal.released = true;
        releasedDeals[msg.sender].push(_dealId);

        IERC20Upgradeable(deal.token).transfer(deal.creator, deal.cost);

        emit DealReleased(_dealId, deal.creator);
    }

    function cancelDeal(uint256 _dealId) external nonReentrant {
        Deal storage deal = deals[_dealId];
        require(deal.creator != address(0), "Deal does not exist");
        require(!deal.released, "Deal already released");
        require(!deal.canceled, "Deal already canceled");
        require(msg.sender == deal.creator || msg.sender == owner(), "Only creator or owner can cancel");

        deal.canceled = true;

        if (deal.paid) {
            // Si el trato ya fue pagado, se devuelve el costo al payer
            IERC20Upgradeable(deal.token).transfer(deal.payer, deal.cost);
        }

        emit DealCanceled(_dealId, msg.sender);
    }


    // --- Getters ---
    function getDeal(uint256 _dealId) external view returns (Deal memory) {
        return deals[_dealId];
    }

    function getCreatedDeals(address _user) external view returns (uint256[] memory) {
        return createdDeals[_user];
    }

    function getPaidDeals(address _user) external view returns (uint256[] memory) {
        return paidDeals[_user];
    }

    function getReleasedDeals(address _user) external view returns (uint256[] memory) {
        return releasedDeals[_user];
    }

    // --- Withdrawal ---
    function withdrawTokens(address _token) external nonReentrant {
        require(msg.sender == withdrawWallet, "Not authorized");
        
        uint256 amount = accumulatedCommissions[_token];
        require (amount > 0, "No commissions to withdraw");

        accumulatedCommissions[_token] = 0;
        IERC20Upgradeable(_token).transfer(withdrawWallet, amount);
    }
}
