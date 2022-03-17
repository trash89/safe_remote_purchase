// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "./console.sol";

contract Purchase {
    uint256 public value;
    address payable public seller;
    address payable public buyer;

    enum State {
        Created,
        Locked,
        Release,
        Inactive
    }
    // The state variable has a default value of the first member, `State.created`
    State public state;

    modifier condition(bool condition_) {
        console.log("modifier condition() called");
        require(condition_);
        _;
        console.log("modifier condition passed");
    }

    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();

    modifier onlyBuyer() {
        console.log("modifier onlyBuyer() called");
        if (msg.sender != buyer) revert OnlyBuyer();
        _;
        console.log("modifier onlyBuyer() passed");
    }

    modifier onlySeller() {
        console.log("modifier onlySeller() called");
        if (msg.sender != seller) revert OnlySeller();
        _;
        console.log("modifier onlySeller() passed");
    }

    modifier inState(State state_) {
        console.log("modifier inState() called");
        if (state != state_) revert InvalidState();
        _;
        console.log("modifier inState() passed");
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    // Ensure that `msg.value` is an even number.
    // Division will truncate if it is an odd number.
    // Check via multiplication that it wasn't an odd number.
    constructor() payable {
        console.log(
            "constructor() called from %s with %d",
            msg.sender,
            msg.value
        );
        seller = payable(msg.sender);
        value = msg.value / 2;
        if ((2 * value) != msg.value) revert ValueNotEven();
        console.log("constructor() passed");
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    function abort() external onlySeller inState(State.Created) {
        console.log(
            "abort() called, transferring %d to %s",
            address(this).balance,
            seller
        );
        emit Aborted();
        state = State.Inactive;
        // We use transfer here directly. It is
        // reentrancy-safe, because it is the
        // last call in this function and we
        // already changed the state.
        seller.transfer(address(this).balance);
        console.log("abort() passed");
    }

    /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase()
        external
        payable
        inState(State.Created)
        condition(msg.value == (2 * value))
    {
        console.log("confirmPurchase() called, from %s", msg.sender);
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
        console.log("confirmPurchase() passed");
    }

    /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
    function confirmReceived() external onlyBuyer inState(State.Locked) {
        console.log("confirmReceived() called, from %s", msg.sender);
        emit ItemReceived();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Release;
        buyer.transfer(value);
        console.log(
            "confirmReceived() passed, transferred %d to %s",
            value,
            buyer
        );
    }

    /// This function refunds the seller, i.e.
    /// pays back the locked funds of the seller.
    function refundSeller() external onlySeller inState(State.Release) {
        console.log("refundSeller() called, from %s", msg.sender);
        emit SellerRefunded();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Inactive;
        seller.transfer(3 * value);
        console.log(
            "refundSeller() passed, transferring %d to %s",
            3 * value,
            seller
        );
    }
}
