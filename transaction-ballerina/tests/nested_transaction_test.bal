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
import ballerina/test;
import ballerina/io;
import ballerina/lang.'transaction as transactions;

@test:Config {
}
function testRollbackWithNestedTransactions() {
    string|error x =  trap actualCodeWithNestedTransactions(0, false);
    if(x is string) {
        test:assertEquals(x, "start fc-0 inTrx Commit endTrx end");
    }
}

@test:Config {
}
function testCommitWithNestedTransactions() {
    string|error x =  trap actualCodeWithNestedTransactions(0, false);
    if(x is string) {
        test:assertEquals(x, "start fc-0 inTrx Commit endTrx end");
    }
}

@test:Config {
}
function testPanicWithNestedTransactions() {
    string|error x =  trap actualCodeWithNestedTransactions(1, false);
    if(x is string) {
        test:assertEquals(x, "start fc-1 inTrx blowUp");
    }
}

function actualCodeWithNestedTransactions(int failureCutOff, boolean requestRollback) returns (string) {
    string a = "";
    a = a + "start";
    a = a + " fc-" + failureCutOff.toString();
    int count = 0;
    transaction {
        transaction {
            a = a + " inTrx";
            count = count + 1;
            if (count <= failureCutOff) {
                a = a + " blowUp"; // transaction block panic scenario, Set failure cutoff to 0, for not blowing up.
                int bV = blowUpInNestedTransactions();
            }
            if (requestRollback) { // Set requestRollback to true if you want to try rollback scenario, otherwise commit
                a = a + " Rollback";
                rollback;
            } else {
                a = a + " Commit";
                var i = checkpanic commit;
            }
            a = a + " endTrx";
            a = (a + " end");
        }
        var ii = checkpanic commit;
    }
    return a;
}

function blowUpInNestedTransactions()  returns int {
    if (5 == 5) {
        error err = error("TransactionError");
        panic err;
    }
    return 5;
}

function testLocalTransactionWithNestedTransactions1(int i) returns int|error {
    int x = i;

    transaction {
        transaction {
            x += 1;
            check commit;
        }

        transaction {
            x += 1;
            check commit;
        }
        check commit;
    }
    return x;
}

function testLocalTransactionWithNestedTransactions2(int i) returns int|error {
    int x = i;

    transaction {
        transaction {
            x += 1;
            check commit;
        }
        check commit;
    }

    return x;
}

@test:Config {
}
function testMultipleTrxBlocksWithNestedTransactions() returns error? {
    int i = check testLocalTransactionWithNestedTransactions1(1);
    int j = check testLocalTransactionWithNestedTransactions2(i);

    test:assertEquals(j, 4);
}

string a = "";
@test:Config {
}
function testTrxHandlersWithNestedTransactions() {
    a = a + "started";
    transactions:Info transInfo;
    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
        io:println(" trxAborted");
    };

    var onCommitFunc = isolated function(transactions:Info? info) {
        io:println(" trxCommited");
    };

    transaction {
        transaction {
            transInfo = transactions:info();
            transactions:onRollback(onRollbackFunc);
            transactions:onCommit(onCommitFunc);
            trxfunctionForNestedTransactions();
            var commitRes = checkpanic commit;
        }
        var ii = checkpanic commit;
    }
    a += " endTrx";
    test:assertEquals(a, "started within transactional func endTrx");
}

transactional function trxfunctionForNestedTransactions() {
    a = a + " within transactional func";
}

@test:Config {
}
function testTransactionInsideIfStmtWithNestedTransactions() {
    int a = 10;
    if (a == 10) {
        int c = 8;
        transaction {
            transaction {
                int b = a + c;
                a = b;
                var commitRes = checkpanic commit;
            }
            var ii = checkpanic commit;
        }
    }
    test:assertEquals(a, 18);
}

@test:Config {
}
function testArrowFunctionInsideTransactionWithNestedTransactions() {
    int a = 10;
    int b = 11;
    transaction {
        function (int, int) returns int arrow1 = (x, y) => x + y + a + b;
        a = arrow1(1, 1);
        transaction {
            int c = a + b;
            function (int, int) returns int arrow2 = (x, y) => x + y + a + b + c;
            a = arrow2(2, 2);
            var commitRes = checkpanic commit;
        }
        var ii = checkpanic commit;
    }
    test:assertEquals(a, 72);
}

@test:Config {
}
function testAssignmentToUninitializedVariableOfOuterScopeFromTrxBlockWithNestedTrx() {
    int|string s;
    transaction {
        transaction {
            s = "init-in-transaction-block";
            var commitRes = checkpanic commit;
        }
        var ii = checkpanic commit;
    }
    test:assertEquals(s, "init-in-transaction-block");
}

@test:Config {
}
function testTrxReturnValWithNestedTransactions() {
    string str = "start";
    transaction {
        var ii = checkpanic commit;
        transaction {
            str = str + " within transaction";
            var commitRes = checkpanic commit;
            str = str + " end.";
            test:assertEquals(str, "start within transaction end.");
        }
    }
}

@test:Config {
}
function testInvokingTrxFuncForNestedTrx() {
    string str = "start";
    string res = funcWithTrxForNestedTrx(str);
    test:assertEquals(res + " end.", "start within transaction end.");
}

function funcWithTrxForNestedTrx(string str) returns string {
    transaction {
        var ii = checkpanic commit;
        transaction {
            string res = str + " within transaction";
            var commitRes = checkpanic commit;
            return res;
        }
    }
}

@test:Config {
}
function testTransactionLangLibForNestedTransactions() returns error? {
    string str = "";
    var rollbackFunc = isolated function (transactions:Info info, error? cause, boolean willRetry) {
        if (cause is error) {
            io:println("Rollback with error: " + cause.message());
        }
    };

    transaction {
        transaction {
            readonly d = 123;
            transactions:setData(d);
            transactions:Info transInfo = transactions:info();
            transactions:Info? newTransInfo = transactions:getInfo(transInfo.xid);
            if(newTransInfo is transactions:Info) {
                test:assertEquals(transInfo.xid === newTransInfo.xid, true);
            } else {
                panic error AssertionErrorInNestedTrx(ASSERTION_ERROR_REASON_IN_NESTED_TRX,
                message = "unexpected output from getInfo");
            }
            transactions:onRollback(rollbackFunc);
            str += "In Trx";
            test:assertEquals(d === transactions:getData(), true);
            check commit;
            str += " commit";
        }
        check commit;
    }
}

type AssertionErrorInNestedTrx error;

const ASSERTION_ERROR_REASON_IN_NESTED_TRX = "AssertionError";

@test:Config {
}
function testWithinTrxModeWithNestedTransactions() {
    string ss = "";
    var onCommitFunc = isolated function(transactions:Info? info) {
        io:println(" -> trxCommited");
    };

    transaction {
        transaction {
            ss = "trxStarted";
            string invoRes = testFuncInvocationForNestedTransaction();
            ss = ss + invoRes + " -> invoked function returned";
            transactions:onCommit(onCommitFunc);
            if (transactional) {
                ss = ss + " -> strand in transactional mode";
            }
            var commitRes = checkpanic commit;
            if (!transactional) {
                ss = ss + " -> strand in non-transactional mode";
            }
            ss += " -> trxEnded.";
        }
        var ii = checkpanic commit;
    }
    test:assertEquals(ss, "trxStarted -> within invoked function "
             + "-> strand in transactional mode -> invoked function returned -> strand in transactional mode"
             + " -> strand in non-transactional mode -> trxEnded.");
}

function testFuncInvocationForNestedTransaction() returns string {
    string ss = " -> within invoked function";
    if (transactional) {
        ss = ss + " -> strand in transactional mode";
    }
    return ss;
}

@test:Config {
}
function testUnreachableCodeWithNestedTransactions() {
    string ss = "";
    var onCommitFunc = isolated function(transactions:Info? info) {
        io:println(" -> trxCommited");
    };

    transaction {
        transaction {
            ss = "trxStarted";
            transactions:onCommit(onCommitFunc);
            var commitRes = checkpanic commit;
            if (transactional) {
                //only reached when commit fails
                ss = ss + " -> strand in transactional mode";
            }
            ss += " -> trxEnded.";
        }
        var ii = checkpanic commit;
    }
    test:assertEquals(ss, "trxStarted -> trxEnded.");
}

@test:Config {
}
function testMultipleTrxReturnValWithNestedTransactions() {
    string str = "start";
    string result = "";
    int i = 0;
    transaction {
        i += 1;
        str += " -> within transaction 1";
        var commitRes1 = checkpanic commit;
        if(i >= 3) {
            result = str;
        }
        transaction {
            i += 1;
            str += " -> within transaction 2";
            var commitRes2 = checkpanic commit;
            if(i >= 3) {
                result = str;
            }
            transaction {
                i += 1;
                str += " -> within transaction 3";
                var commitRes3 = checkpanic commit;
                str += " -> returned.";
                if(i >= 3) {
                    result = str;
                }
            }
        }
    }
    test:assertEquals(result, "start -> within transaction 1 " +
                            "-> within transaction 2 -> within transaction 3 -> returned.");
}

@test:Config {
}
function testNestedReturnsWithNestedTransactions () {
    string nestedInnerReturnRes = testNestedInnerReturnWithNestedTransactions();
    test:assertEquals("start -> within trx 1 -> within trx 2 -> within trx 3", nestedInnerReturnRes);
    string nestedMiddleReturnRes = testNestedMiddleReturnWithNestedTransactions();
    test:assertEquals("start -> within trx 1 -> within trx 2", nestedMiddleReturnRes);
}

function testNestedInnerReturnWithNestedTransactions() returns string {
    string str = "start";
    transaction {
        str += " -> within trx 1";
        var res1 = checkpanic commit;
        transaction {
            var res2 = checkpanic commit;
            str += " -> within trx 2";
            transaction {
                var res3 = checkpanic commit;
                str += " -> within trx 3";
                return str;
            }
        }
    }
}

function testNestedMiddleReturnWithNestedTransactions() returns string {
    string str = "start";
    transaction {
        str += " -> within trx 1";
        var res1 = checkpanic commit;
        transaction {
            int count = 1;
            var res2 = checkpanic commit;
            str += " -> within trx 2";
            if (count == 1) {
                return str;
            }
            transaction {
                var res3 = checkpanic commit;
                str += " -> within trx 3 -> should not reach here";
                return str;
            }
        }
    }
}

@test:Config {
}
function testNestedRollback () {
   error? res = trap nestedTrxWithRollbackHandlers();
   if(res is error) {
       test:assertEquals(res.message(), "TransactionError");
   } else {
       panic error("Expected a panic.");
   }
}

function nestedTrxWithRollbackHandlers() {
     var onRollbackFunc1 = isolated function(transactions:Info? info, error? cause, boolean willTry) {
          io:println("Rollback 1 executed");
     };

     var onRollbackFunc2 = isolated function(transactions:Info? info, error? cause, boolean willTry) {
          io:println("Rollback 2 executed");
     };

     transaction {
         transactions:onRollback(onRollbackFunc1);
            var commitRes1 = checkpanic commit;
            transaction {
                transactions:onRollback(onRollbackFunc2);
                int bV = blowUpInNestedTransactions();
                var commitRes2 = checkpanic commit;
            }
     }
}
