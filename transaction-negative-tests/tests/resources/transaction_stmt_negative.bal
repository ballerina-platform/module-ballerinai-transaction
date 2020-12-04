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
        var res = commit;
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
      var c = commit;
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
            var o = commit;
        } else {
            a = a + " inElse";
            var b = testTransactionalInvo(a);
            rollback;
        }
        var o = commit;
    }

    transaction {
        a = a + " inTrx";
        if(i == 3) {
            a = a + " inIf3";
            var b = testTransactionalInvo(a);
            var o = commit;
        } else if (i == 5) {
            a = a + " inIf5";
            var b = testTransactionalInvo(a);
            //var o = commit;
        }
        var o = commit;
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
        var o = commit;
    }
}

function testBreakWithinTransaction() returns (string) {
    int i = 0;
    while (i < 5) {
        i = i + 1;
        transaction {
            if (i == 2) {
                var o = commit;
                break;
            }
        }
        transaction {
            if (i == 4) {
                break;
            }
        }
    }
    var o = commit;
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
                var o = commit;
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
                var o = commit;
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
            var o = commit;
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
                    var o = commit;
                    return "ff";
                } else {
                    return "ff";
                }
            } else {
                if (i == 2) {
                    return "ff";
                } else {
                    var o = commit;
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
            var rslt = testTransactionalInvo(str);
        }
    }
    var rslt = testTransactionalInvo(str);
    return str + " non-transactional call";
}

function testNestedTrxBlocks() returns (string) {
   string a = "";
   retry(2) transaction {
        transaction {
            a += "nested block";
            var commitResInner = commit;
        }
        var commitResOuter = commit;
    }
    return a;
}

function testTrxHandlers() returns string {
    string ss = "started";
    transactions:Info transInfo;
    var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
        ss = ss + " trxAborted";
    };

    var onCommitFunc = function(transactions:Info? info) {
        ss = ss + " trxCommited";
    };

    transaction {
        var commitRes = commit;
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
        var commitRes = commit;
    }
    ss += " endTrx";
    return ss;
}

function testTransactionalInvoWithinMultiLevelFunc() returns string {
    string ss = "";
    transaction {
        ss = "trxStarted";
        ss = func1(ss);
        var commitRes = commit;
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
            var balance = checkBalance(str);
            var amount = self->deposit(str);
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

function testTransactionsWithIfElse() {
    string str = "";
    transaction {
        str = "trxStarted";
        var x = commit;
        if (x == ()) {
            str += " -> trxCommitted";
        } else {
            rollback;
            str += " -> trxRolledback.";
        }
    }
    str += "-> trxEnded.";
}


function testTransactionsWithIfElse2() {
    string str = "";
    int i = 0;
    transaction {
        str = "trxStarted";
        if (i == 0) {
            str += " -> do nothing";
        } else {
            var x = commit;
            rollback;
            str += " -> trxRolledback.";
        }
    }
    str += "-> trxEnded.";
}


function testTransactionsWithIfElse3() {
    string str = "";
    int i = 0;
    var m = commit;
    transaction {
        str = "trxStarted";
        if (i == 0) {
            var x = commit;
        } else if (i == 1) {
            str += " -> do nothing";
        } else {
            rollback;
        }
        var res = testTransactionalInvo("");
        str += res;
    }
    str += "-> trxEnded.";
}

function testTransactionsWithIfElse4() {
    string str = "";
    int i = 0;
    rollback;
    transaction {
        str = "trxStarted";
        if (i == 0) {
            var x = commit;
        } else if (i == 1) {
            str += " -> do nothing";
        } else {
            rollback;
        }
        var o = testTransactionalInvo("");
    }
    str += "-> trxEnded.";
}

function testTransactionsWithIfElse5() {
    string str = "";
    int i = 0;
    transaction {
        str = "trxStarted";
        var m = commit;
        if (i == 0) {
            var x = commit;
        } else if (i == 1) {
            str += " -> do nothing";
        } else {
            rollback;
        }
        var o = testTransactionalInvo("");
    }
    str += "-> trxEnded.";
}

function testTransactionsWithIfElse6() {
    string str = "";
    int i = 0;
    transaction {
        str = "trxStarted";
        rollback;
        if (i == 0) {
            var x = commit;
        } else if (i == 1) {
            str += " -> do nothing";
        } else {
            rollback;
        }
        var o = testTransactionalInvo("");
    }
    str += "-> trxEnded.";
}


function testTransactionsWithIfElse7() {
    string str = "";
    int i = 0;
    transaction {
        str = "trxStarted";
        if (i == 0) {
            rollback;
        } else if (i == 1) {
            str += " -> do nothing";
        } else {
            var x = commit;
        }
        var o = testTransactionalInvo("");
    }
    str += "-> trxEnded.";
}

function testTransactionsWithIfElse8() {
    string str = "";
    int i = 0;
    transaction {
        str = "trxStarted";
        if (i == 0) {
            str += " -> do nothing";
        } else if (i == 1) {
            rollback;
        } else {
            var x = commit;
        }
        var o = testTransactionalInvo("");
    }
    str += "-> trxEnded.";
}