// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultisigHelper {
    // Helper for setSweepReceiver
    function encodeSweepReceiverChange(address newReceiver) public pure returns (bytes memory) {
        return abi.encodeWithSignature("setSweepReceiver(address)", newReceiver);
    }

    // Helper for toggleAutoSweep
    function encodeToggleAutoSweep(bool enabled) public pure returns (bytes memory) {
        return abi.encodeWithSignature("toggleAutoSweep(bool)", enabled);
    }

    // Helper for forwardTRC20
    function encodeForwardTRC20(address token) public pure returns (bytes memory) {
        return abi.encodeWithSignature("forwardTRC20(address)", token);
    }

    // Helper for sweepFunds
    function encodeSweepFunds() public pure returns (bytes memory) {
        return abi.encodeWithSignature("sweepFunds()");
    }

    // Example usage function that shows how to use the encoded data
    function getMultisigTransactionData(
        address multisigAddress,
        bytes memory encodedFunctionCall
    ) public pure returns (
        address to,
        uint256 value,
        bytes memory data
    ) {
        return (
            multisigAddress, // The multisig contract address
            0,              // No TRX sent with the call
            encodedFunctionCall
        );
    }

    // Example function showing full transaction submission parameters
    function getSetSweepReceiverParams(
        address multisigAddress,
        address newReceiver
    ) public pure returns (
        address to,
        uint256 value,
        bytes memory data
    ) {
        bytes memory encodedCall = encodeSweepReceiverChange(newReceiver);
        return getMultisigTransactionData(multisigAddress, encodedCall);
    }

    // Example function showing toggle auto-sweep parameters
    function getToggleAutoSweepParams(
        address multisigAddress,
        bool enabled
    ) public pure returns (
        address to,
        uint256 value,
        bytes memory data
    ) {
        bytes memory encodedCall = encodeToggleAutoSweep(enabled);
        return getMultisigTransactionData(multisigAddress, encodedCall);
    }

    // Example function showing TRC20 forward parameters
    function getForwardTRC20Params(
        address multisigAddress,
        address token
    ) public pure returns (
        address to,
        uint256 value,
        bytes memory data
    ) {
        bytes memory encodedCall = encodeForwardTRC20(token);
        return getMultisigTransactionData(multisigAddress, encodedCall);
    }
    function getBalance(address add) public view returns (uint256){
     return add.balance;   
    }
}
