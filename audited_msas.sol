// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ITRC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract AutoSweepMultiSigWallet is ReentrancyGuard {
    using SafeERC20 for ITRC20;
    
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event AutoSweepEnabled(address indexed sweepAddress);
    event AutoSweepDisabled();
    event Swept(address indexed to, uint256 amount);
    event SweepFailed(string reason);
    event ForwardedTRC20(address indexed token, uint256 amount);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    
    // Auto-sweep related variables
    address public sweepReceiver;
    bool public autoSweepEnabled;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
        bytes32 txHash;
    }

    mapping(bytes32 => bool) public executedTxHashes;
    mapping(uint => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(
        address[] memory _owners, 
        uint _numConfirmationsRequired,
        address _initialSweepReceiver
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
            _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );
        require(_initialSweepReceiver != address(0), "invalid sweep receiver");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        sweepReceiver = _initialSweepReceiver;
        autoSweepEnabled = true;
        emit AutoSweepEnabled(_initialSweepReceiver);
    }

    receive() external payable nonReentrant {
        emit Deposit(msg.sender, msg.value);
         // Only sweep the newly received amount
    	if (autoSweepEnabled && msg.value > 0) {
        (bool success, ) = sweepReceiver.call{value: msg.value}("");
        if (success) {
            emit Swept(sweepReceiver, msg.value);
        } else {
            emit SweepFailed("Forward failed");
        }
    }
    }

    function depositFunds() external payable onlyOwner {}
    
    function sweepFunds() external payable {
        require(msg.sender == address(this), "only internal");
        require(autoSweepEnabled, "sweep disabled");
        require(msg.value > 0, "no balance");
        
        (bool success, ) = sweepReceiver.call{value: msg.value}("");
        require(success, "sweep failed");
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        bytes32 _txHash = keccak256(abi.encodePacked(address(this), block.number, _to, _value, _data));
        require(!executedTxHashes[_txHash], "Transaction already submitted");
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0,
                txHash: _txHash
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        nonReentrant
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;
        executedTxHashes[transaction.txHash] = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function setSweepReceiver(address _newReceiver) public {
        require(
            msg.sender == address(this),
            "only through multisig transaction"
        );
        require(_newReceiver != address(0), "invalid address");
        sweepReceiver = _newReceiver;
        emit AutoSweepEnabled(_newReceiver);
    }

    function toggleAutoSweep(bool _enabled) public {
        require(
            msg.sender == address(this),
            "only through multisig transaction"
        );
        autoSweepEnabled = _enabled;
        if (_enabled) {
            emit AutoSweepEnabled(sweepReceiver);
        } else {
            emit AutoSweepDisabled();
        }
    }

    // Function to forward TRC20 tokens through multisig
    function forwardTRC20(address token) external {
        require(
            msg.sender == address(this),
            "only through multisig transaction"
        );
        uint256 tokenBalance = ITRC20(token).balanceOf(address(this));
        require(tokenBalance > 0, "No TRC20 tokens to forward");
        bool success = ITRC20(token).transfer(sweepReceiver, tokenBalance);
        require(success, "Forwarding TRC20 failed");
        emit ForwardedTRC20(token, tokenBalance);
    }

    // Helper functions
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}
