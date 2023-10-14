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

  Example formula for amountOfBJettonToSend in B->A swap will be
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

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
  }

  receive(msg: JettonNotification) {
    let atob: Bool = sender() == self.jAddressA;
    let btoa: Bool = sender() == self.jAddressB;    
    if (!(atob || btoa)) { return; }
    
    // pool supply from admin
    if (msg.from == self.owner) {
      if (atob) {
        self.a = self.a + msg.amount;
      }
      else {
        self.b = self.b + msg.amount;
      }
      return;
    }
    
    // exchange request
    if (atob) {
      let retb: Int = self.b / self.a * msg.amount;
      if (self.b < retb) {
        // return A
        send(SendParameters{
          to: self.jAddressA,
          value: 0, 
          mode: SendIgnoreErrors + SendRemainingValue, 
          body: TokenTransfer{queryId: msg.queryId, amount: msg.amount, destination: msg.from, responseDestination: msg.from, forwardTonAmount: ton("0.05"), customPayload: null, forwardPayload: msg.forwardPayload }.toCell()
        });
      }
      else {
        // swap to B
        self.a = self.a + msg.amount;
        self.b = self.b - retb;
        send(SendParameters{
          to: self.jAddressB,
          value: 0, 
          mode: SendIgnoreErrors + SendRemainingValue, 
          body: TokenTransfer{queryId: msg.queryId, amount: retb, destination: msg.from, responseDestination: msg.from, forwardTonAmount: ton("0.05"), customPayload: null, forwardPayload: msg.forwardPayload }.toCell()
        });
      }    
    }
    else {
      let reta: Int = self.a / self.b * msg.amount;
      if (self.a < reta) {
        // return B
        send(SendParameters{
          to: self.jAddressB,
          value: 0, 
          mode: SendIgnoreErrors + SendRemainingValue, 
          body: TokenTransfer{queryId: msg.queryId, amount: msg.amount, destination: msg.from, responseDestination: msg.from, forwardTonAmount: ton("0.05"), customPayload: null, forwardPayload: msg.forwardPayload }.toCell()
        });
      }
      else {
        // swap to A
        self.a = self.a - reta;
        self.b = self.b + msg.amount;
        send(SendParameters{
          to: self.jAddressA,
          value: 0, 
          mode: SendIgnoreErrors + SendRemainingValue, 
          body: TokenTransfer{queryId: msg.queryId, amount: reta, destination: msg.from, responseDestination: msg.from, forwardTonAmount: ton("0.05"), customPayload: null, forwardPayload: msg.forwardPayload }.toCell()
        });
      }    
    }
  } 
  
  get fun price(jetton: Address): Int { 
    if (self.a > 0 && token == self.jAddressA) {
      return self.b / self.a;
    }
    
    if (self.b > 0 && token == self.jAddressB) {
      return self.a / self.b;
    }
    
    return 0;
  }
  
  get fun balance(jetton: Address): Int { 
    if (token == self.jAddressA) {
      return self.a;
    }
    
    if (token == self.jAddressB) {
      return self.b;
    }
    
    return 0;
  }
}
