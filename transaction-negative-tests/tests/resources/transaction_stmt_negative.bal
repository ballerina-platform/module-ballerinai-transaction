// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import ballerina/lang.'transaction as transactions;
import ballerina/io;

function commitExpMissingInTransactionStmt(int i) returns (string) {
    string a = "start";
    transaction {
        a = a + " inTrx";
        if (i == 0) {
            a = a + " rollback";
            rollback;
        }
        rollback;
        a = a + " endTrx";
    }
    return a;
}

transactional function txStmtWithinTransactionalScope(int i) returns (string) {
    string a = "start";
    var o = testTransactionalInvo(a);
    transaction {
        a = a + " inTrx";
        if (i == -1) {
            a = a + " rollback";
            rollback;
        }
        var res = checkpanic commit;
        a = a + " endTrx";
    }
    var c = start testInvo(a);
    return a;
}

function invocationsWithinTx(int i) returns (string) {
   string a = "start";

   transaction {
      a = a + " inTrx";
      var b = start testInvo(a);
      var c = checkpanic commit;
      var d = testTransactionalInvo(a);
   }
   return a;
}

function txWithMultiplePaths(int i)  {
    string a = "start";

    transaction {
        a = a + " inTrx";
        if(i == 3) {
            a = a + " inIf3";
            var b = testTransactionalInvo(a);
            var o = checkpanic commit;
        } else {
            a = a + " inElse";
            var b = testTransactionalInvo(a);
            rollback;
        }
        var o = checkpanic commit;
    }

    transaction {
        a = a + " inTrx";
        if(i == 3) {
            a = a + " inIf3";
            var b = testTransactionalInvo(a);
            var o = checkpanic commit;
        } else if (i == 5) {
            a = a + " inIf5";
            var b = testTransactionalInvo(a);
            //var o = checkpanic commit;
        }
        var o = checkpanic commit;
    }
}

function testInvo(string str) returns string {
 return str + " non-transactional call";
}

transactional function testTransactionalInvo(string str) returns string {
    return str + " transactional call";
}


function testTransactionRollback() {
    int i = 10;
    transaction {
        i = i + 1;
        if (i > 10) {
            rollback;
        }
        while (i < 40) {
            i = i + 2;
            if (i == 44) {
                rollback;
                int k = 9;
            }
        }
        rollback;
        i = i + 2;
        checkpanic commit;
    }
}

function testBreakWithinTransaction() returns (string) {
    int i = 0;
    while (i < 5) {
        i = i + 1;
        transaction {
            if (i == 2) {
                checkpanic commit;
                break;
            }
        }
        transaction {
            if (i == 4) {
                break;
            }
        }
    }
    checkpanic commit;
    return "done";
}

function testNextWithinTransaction() returns (string) {
    int i = 0;
    while (i < 5) {
        i = i + 1;
        transaction {
            if (i == 2) {
                continue;
            } else {
                checkpanic commit;
            }
        }
    }
    return "done";
}

function testReturnWithinTransaction() returns (string) {
    int i = 0;
    while (i < 5) {
        i = i + 1;
        transaction {
            if (i == 2) {
                return "ff";
            } else {
                checkpanic commit;
            }
        }
    }
    return "done";
}

function testInvalidDoneWithinTransaction() {
    string workerTest = "";

    int i = 0;
    transaction {
        workerTest = workerTest + " withinTx";
        if (i == 0) {
            workerTest = workerTest + " beforeDone";
            return;
        } else {
            var o = checkpanic commit;
        }
    }
    workerTest = workerTest + " beforeReturn";
    return;
}

function testReturnWithinMatchWithinTransaction() returns (string) {
    int i = 0;
    string|int unionVar = "test";
    while (i < 5) {
        i = i + 1;
        transaction {
            if (unionVar is string) {
                if (i == 2) {
                    checkpanic commit;
                    return "ff";
                } else {
                    return "ff";
                }
            } else {
                if (i == 2) {
                    return "ff";
                } else {
                    checkpanic commit;
                    return "ff";
                }
            }
        }
    }
    return "done";
}

function isTransactionalBlockFunc(string str) returns string {
    if transactional {
        if (str == "test") {
            rollback;
        } else {
            _ = testTransactionalInvo(str);
        }
    }
    _ = testTransactionalInvo(str);
    return str + " non-transactional call";
}

function testNestedTrxBlocks() returns (string) {
   string a = "";
   retry(2) transaction {
        transaction {
            a += "nested block";
            checkpanic commit;
        }
        var commitResOuter = checkpanic commit;
    }
    return a;
}

function testTrxHandlers() returns string {
    string ss = "started";
    transactions:Info transInfo;
    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
        io:println("trxAborted");
    };

    var onCommitFunc = isolated function(transactions:Info? info) {
        io:println(" trxCommited");
    };

    transaction {
        checkpanic commit;
        transactions:onRollback(onRollbackFunc);
        transactions:onCommit(onCommitFunc);
        boolean isRollbackOnly = transactions:getRollbackOnly();
    }
    transInfo = transactions:info();

    ss += " endTrx";
    return ss;
}

function testWithinTrxMode() returns string {
    string ss;
    transactions:Info transInfo;

    transaction {
        ss = "started";
        if (!transactional) {
            transInfo = transactions:info();
        }
        var commitRes = checkpanic commit;
    }
    ss += " endTrx";
    return ss;
}

function testTransactionalInvoWithinMultiLevelFunc() returns string {
    string ss = "";
    transaction {
        ss = "trxStarted";
        ss = func1(ss);
        checkpanic commit;
        ss += " -> trxEnded.";
    }
    return ss;
}

function func1(string str) returns string {
    string ss = func2(str);
    return ss + " -> non Trx Func";
}

transactional function func2(string str) returns string {
 return str + " -> within Trx Func";
}

client class Bank {
    remote transactional function deposit(string str) returns string {
        return str + "-> deposit trx func ";
    }

    function doTransaction() {
        string str = "";
        transaction {
            checkpanic commit;
            _ = checkBalance(str);
            _ = self->deposit(str);
        }
    }
}

transactional function checkBalance(string str) returns string {
    return str + "-> check balance function ";
}

function testInvokeRemoteTransactionalMethodInNonTransactionalScope() returns Bank {
    Bank bank = new;
    return bank;
}

function testCommitWithinLoop() {
    int[] intArr = [1, 2, 3];
    transaction {
        foreach int i in intArr {
            checkpanic commit;
        }
    }
}

function testRollbackWithinLoop() {
    int[] intArr = [1, 2, 3];
    transaction {
        foreach int i in intArr {
            if(i == 1) {
                rollback;
            }
        }
        checkpanic commit;
    }
}

function testReturnBeforeCommitInIf() returns int {
    int[] intArr = [1, 2, 3];
    transaction {
        foreach int i in intArr {
            if(i == 1) {
                return 0;
            }
        }
        var commitRes = checkpanic commit;
    }
    return 1;
}

function checkRollbackRechability() returns error? {
    transaction {
        int? a = 5;
        if a is int {
            error? res = commit;
        } else {
            fail error("");
            rollback;    // not reachable
        }
    }
    return;
}
