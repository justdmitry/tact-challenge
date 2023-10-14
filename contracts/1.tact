import "@stdlib/deploy";

/*
  TASK 1 - Counter 
  Implement a counter contract that will have 2 opcodes ('Add' / 'Subtract'),
  which adds or subtracts the received number (int32) from the number that is stored in the state (and stores the result back in the state).
  You also need to implement one getter with the name "counter" to get the current number from the state.
*/

message Add {
  queryId: Int as uint64;
  number: Int as uint32;
}

message Subtract {
  queryId: Int as uint64;
  number: Int as uint32;
}

contract Task1 with Deployable {
    counter: Int as int32;

    init() {
      self.counter = 0;
    }
    
    receive(msg: Slice)
    {
      let op: Int = msg.loadInt(32);
      let queryId: Int = msg.loadInt(64);
      let number: Int = msg.loadInt(32);
      if (op == 1452964801) {
        self.counter = self.counter + number;
      }
      else if (op == 2241251822) {
        self.counter = self.counter - number;
      }
    }

    get fun counter(): Int {
      return self.counter;
    }
}
