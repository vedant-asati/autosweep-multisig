# Auto-Sweep Multisig Wallet

A multisig wallet that automatically forwards TRX to a designated address while maintaining multisig control over critical functions.

## Deployment

1. Compile the contract in TronIDE or your preferred environment
2. Deploy with these parameters:
```js
[
    "TWp...Jx",  // owner1 address
    "TYs...bR",  // owner2 address
    "TKi...7G"   // owner3 address
], 
2,                                          // requires 2 confirmations
"TRd...XX",     // sweep receiver address
1000000                                     // sweep threshold (1 TRX)
```

## Key Functions

### Auto-Sweep Functions
- `receive()`: Auto-forwards TRX above threshold
- `setSweepReceiver(address)`: Change sweep address
- `setSweepThreshold(uint256)`: Change minimum sweep amount
- `toggleAutoSweep(bool)`: Enable/disable auto-sweep

### Multisig Functions
- `submitTransaction(address,uint,bytes)`: Submit new transaction
- `confirmTransaction(uint)`: Confirm pending transaction
- `executeTransaction(uint)`: Execute after enough confirmations
- `revokeConfirmation(uint)`: Remove your confirmation

### TRC20 Functions
- `forwardTRC20(address)`: Forward TRC20 tokens (needs multisig)

### View Functions
- `getOwners()`: List all owners
- `getTransaction(uint)`: Get transaction details
- `getTransactionCount()`: Total transaction count

## Example Workflow

1. Deploy contract
```js
// Deploy parameters for 2-of-3 multisig
[
    "owner1", "owner2", "owner3"
], 2, "sweepAddress", 1000000
```

2. Submit transaction
```js
// Example: Update sweep receiver
submitTransaction(
    contractAddress,  // this contract's address
    0,               // no TRX sent
    // encoded function call to setSweepReceiver
    "setSweepReceiver(new_address)"
)
```

3. Confirm & Execute
```js
// Two owners must run:
confirmTransaction(0)  // txIndex = 0
// Then anyone can:
executeTransaction(0)
```

## Important Notes
- All received TRX above threshold auto-forwards
- Critical functions require multisig approval
- TRC20 transfers need multisig approval
- Monitor events for sweep status
- Test with small amounts first
