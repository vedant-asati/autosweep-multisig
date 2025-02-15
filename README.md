# Auto-Sweep MultiSig Wallet - Quick Reference Guide

## Setup

1. Deploy contract with:
   - List of owner addresses
   - Number of required confirmations
   - Initial sweep receiver address

2. Requirements:
   - Solidity ^0.8.0
   - TRON compatible wallet
   - Owner addresses must be unique and valid

## Core Operations

### 1. Basic Multisig Transactions' Flow
```
Submit a txn -> Get Confirmations -> Execute
```

### 2. Submit Transaction
```solidity
submitTransaction(
    address _to,    // Destination
    uint _value,    // TRX amount
    bytes _data     // Function data
)
```

### 3. Confirm & Execute
```solidity
// Confirm a transaction
confirmTransaction(uint _txIndex)

// Execute after required confirmations
executeTransaction(uint _txIndex)

// Cancel your confirmation if needed
revokeConfirmation(uint _txIndex)
```

### 4. Auto-Sweep Management
These are additional functions to help generate params to submit on multisig contract and when approved the functions in which (msg.sender == address(this)) condition is checked in the autosweepMultisig contract could be called. Use MultisigHelper to generate transaction data:

```solidity
// Change sweep receiver
getSetSweepReceiverParams(
    multisigAddress,
    newReceiver
)

// Toggle auto-sweep
getToggleAutoSweepParams(
    multisigAddress,
    enabled
)

// Forward TRC20 tokens
getForwardTRC20Params(
    multisigAddress,
    tokenAddress
)

// Custom sweep function
encodeSweepFunds()
```

## Important Events to Monitor

- `SubmitTransaction`: New transaction submitted
- `ConfirmTransaction`: Transaction confirmed by owner 
- `ExecuteTransaction`: Transaction executed
- `Swept`: TRX swept to receiver
- `SweepFailed`: Sweep operation failed
- `ForwardedTRC20`: TRC20 tokens forwarded

## Quick Security Checklist

1. Verify addresses before transactions
2. Check transaction data matches intention
3. Wait for required confirmations
4. Test sweeping with small amounts first

## Helper Contract Usage

1. Import MultisigHelper contract
2. Use helper functions to generate correct transaction data
3. Submit generated data through main wallet contract

## Limitations

- Fixed owner set after deployment
- Fixed confirmation requirement
- No emergency pause
- All owners have equal voting weight

## Common Issues & Solutions

1. Transaction stuck:
   - Check confirmation count
   - Verify execution permissions
   - Ensure sufficient TRX

2. Sweep not working:
   - Verify receiver address
   - Check auto-sweep status
   - Check TRX balance

3. TRC20 forward failed:
   - Verify token contract
   - Check token balance
   - Ensure sufficient TRX for gas
