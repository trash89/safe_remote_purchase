from brownie import accounts, Purchase


def main():
    # seller and contract owner is alice
    alice = accounts[0]
    bob = accounts[1]
    print("Accounts[0] is deploying Purchase contract with 2 ether...")
    pc = Purchase.deploy({"from": alice, "amount": "2 ether"})
    print(f"Deployed at {pc}")

    # print("Alice aborts the purchase")
    # tx = pc.abort({"from": alice})
    # tx.wait(1)
    # print("Aborted")

    print("Bob confirms the purchase for 2 ether")
    tx = pc.confirmPurchase({"from": bob, "amount": "2 ether"})
    tx.wait(1)
    print("Confirmed")

    print("Bob confirms the receiving of goods")
    tx = pc.confirmReceived({"from": bob})
    tx.wait(1)
    print("Confirmed")

    print("Refunding Alice for the rest")
    tx = pc.refundSeller({"from": alice})
    tx.wait(1)
    print("Refunded")
