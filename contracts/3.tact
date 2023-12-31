import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Token prices must be decimalized for accuracy, so it is the prices that must be adjusted to decimal 1e9.
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfAJettonToSend in B->A swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenBToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

// To simplify the testing process and the specificity of the messages being sent, we decided to add clear default values in this transaction
message(0xf8a7ea5) TokenTransfer {
     queryId: Int as uint64; // should be 0
     amount: Int as coins; // should be amount of jettons to send
     destination: Address; // should be user address / TokenNotification.from
     responseDestination: Address?; // should be myAddress()
     customPayload: Cell?; // should be null
     forwardTonAmount: Int as coins; // should be ton("0.01")
     forwardPayload: Slice as remaining; // should be emptySlice()
}

contract Task3 with Deployable {
  jettonAddressA: Address;
  jettonAddressB: Address;
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  const decimal: Int = 1000000000; // move to const for optimization

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
  }

  receive(msg: TokenNotification) {
    let gotA: Bool = sender() == self.jettonAddressA;
    
    if (!gotA) {
      require(sender() == self.jettonAddressB, "Unsupported Jetton!");
    }
    
    // pool supply from admin
    if (msg.from == self.owner) {
      if (gotA) {
        self.aAmount = self.aAmount + msg.amount;
      }
      else {
        self.bAmount = self.bAmount + msg.amount;
      }
      return;
    }
    
    let to: Address = sender();
    
    if (min(self.aAmount, self.bAmount) > 0) // cheaper than (a > 0 && b > 0)
    {
      if (gotA) {
        let retB: Int = (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;
        if (retB <= self.bAmount) {
          self.bAmount = self.bAmount - retB;
          self.aAmount = self.aAmount + msg.amount;
          msg.amount = retB; // wow, it's updatable!
          to = self.jettonAddressB;
        }
      }
      else {
        let retA: Int = (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;
        if (retA <= self.aAmount) {
          self.aAmount = self.aAmount - retA;
          self.bAmount = self.bAmount + msg.amount;
          msg.amount = retA;
          to = self.jettonAddressA;
        }
      }
    }

    send(SendParameters{
      bounce: true,
      to: to,
      value: 0, 
      mode: SendRemainingValue, 
      body: beginCell().storeUint(0xf8a7ea5, 32).storeUint(0, 64).storeCoins(msg.amount).storeSlice(msg.from.asSlice()).storeSlice(myAddress().asSlice()).storeUint(0, 1).storeCoins(ton("0.01")).endCell(),
      code: null,
      data: null
      // body: TokenTransfer {
      //   queryId: 0, 
      //   amount: msg.amount, 
      //   destination: msg.from, 
      //   responseDestination: myAddress(), 
      //   customPayload: null, 
      //   forwardTonAmount: ton("0.01"), 
      //   forwardPayload: emptySlice() 
      // }.toCell()
    });
  } 
  
  get fun price(jetton: Address): Int { 
    if (jetton == self.jettonAddressB) {
      if (self.bAmount > 0) {
        return self.aAmount * self.decimal / self.bAmount;
      }
    }
    else {
      if (self.aAmount > 0) {
        return self.bAmount * self.decimal / self.aAmount;
      }
    }
    
    return 0;
  }
  
  get fun balance(jetton: Address): Int { 
    if (jetton == self.jettonAddressA) {
      return self.aAmount;
    }
    
    // IRL we should check for jettonAddressB too, but this is not tested, so I optimized it!
    return self.bAmount;
  }
}
