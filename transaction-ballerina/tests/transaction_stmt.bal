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
import ballerina/io;
import ballerina/test;
import ballerina/lang.'transaction as transactions;

@test:Config {
}
function testRollback() {
    string|error x =  trap actualCode(0, false);
    if(x is string) {
        test:assertEquals("start fc-0 inTrx Commit endTrx end", x);
    }
}

@test:Config {
}
function testCommit() {
    string|error x =  trap actualCode(0, false);
    if(x is string) {
        test:assertEquals("start fc-0 inTrx Commit endTrx end", x);
    }
}

@test:Config {
}
function testPanic() {
    string|error x =  trap actualCode(1, false);
    if(x is string) {
        test:assertEquals(x, "start fc-1 inTrx blowUp");
    }
}

function actualCode(int failureCutOff, boolean requestRollback) returns (string) {
    string a = "";
    a = a + "start";
    a = a + " fc-" + failureCutOff.toString();
    int count = 0;

    transaction {
        a = a + " inTrx";
        count = count + 1;
        if transactional {
            io:println("Transactional mode");
        }
        if (count <= failureCutOff) {
            a = a + " blowUp"; // transaction block panic scenario, Set failure cutoff to 0, for not blowing up.
            int bV = blowUp();
        }
        if (requestRollback) { // Set requestRollback to true if you want to try rollback scenario, otherwise commit
            a = a + " Rollback";
            rollback;
        } else {
            a = a + " Commit";
            var i = commit;
        }
        a = a + " endTrx";
        a = (a + " end");
    }

    io:println("## Transaction execution completed ##");
    return a;
}

function blowUp()  returns int {
    if (5 == 5) {
        error err = error("TransactionError");
        panic err;
    }
    return 5;
}

function testLocalTransaction1(int i) returns int|error {
    int x = i;

    transaction {
        x += 1;
        check commit;
    }

    transaction {
        x += 1;
        check commit;
    }
    return x;
}

function testLocalTransaction2(int i) returns int|error {
    int x = i;

    transaction {
        x += 1;
        check commit;
    }

    return x;
}

@test:Config {
}
function testMultipleTrxBlocks() returns error? {
    int i = check testLocalTransaction1(1);
    int j = check testLocalTransaction2(i);

    test:assertEquals(4, j);
}

string ss = "";

@test:Config {
}
function testNewStrandWithTransactionalFunc() returns error? {
    string str = "";
    transaction {
        str += "trx started";
        var o = start testTransactionalInvo(ss);
        str += wait o;
        check commit;
        str += " -> trx end";
    }

    test:assertEquals("trx started -> transactional call -> trx end", str);
}

transactional function testTransactionalInvo(string str) returns string {
    return str + " -> transactional call";
}

@test:Config {
}
function testTrxHandlers() {
    ss = ss + "started";
    transactions:Info transInfo;
    var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
        ss = ss + " trxAborted";
    };

    var onCommitFunc = function(transactions:Info? info) {
        ss = ss + " trxCommited";
    };

    transaction {
        transInfo = transactions:info();
        transactions:onRollback(onRollbackFunc);
        transactions:onCommit(onCommitFunc);
        trxfunction();
        var commitRes = commit;
    }
    ss += " endTrx";
    test:assertEquals(ss, "started within transactional func trxCommited endTrx");
}

transactional function trxfunction() {
    ss = ss + " within transactional func";
}

@test:Config {
}
public function testTransactionInsideIfStmt() {
    int a = 10;
    if (a == 10) {
        int c = 8;
        transaction {
            int b = a + c;
            a = b;
            var commitRes = commit;
        }
    }
    test:assertEquals(a, 18);
}

@test:Config {
}
public function testArrowFunctionInsideTransaction() {
    int a = 10;
    int b = 11;
    transaction {
        int c = a + b;
        function (int, int) returns int arrow = (x, y) => x + y + a + b + c;
        a = arrow(1, 1);
        var commitRes = commit;
    }
    test:assertEquals(a, 44);
}

@test:Config {
}
public function testAssignmentToUninitializedVariableOfOuterScopeFromTrxBlock() {
    int|string s;
    transaction {
        s = "init-in-transaction-block";
        var commitRes = commit;
    }
    test:assertEquals(s, "init-in-transaction-block");
}

@test:Config {
}
function testTrxReturnVal() {
    string str = "start";
    transaction {
        str = str + " within transaction";
        var commitRes = commit;
        str = str + " end.";
        test:assertEquals(str, "start within transaction end.");
    }
}

@test:Config {
}
function testInvokingTrxFunc() {
    string str = "start";
    string res = funcWithTrx(str);
    test:assertEquals(res + " end.", "start within transaction end.");
}

function funcWithTrx(string str) returns string {
    transaction {
        string res = str + " within transaction";
        var commitRes = commit;
        return res;
    }
}

@test:Config {
}
function testTransactionLangLib() returns error? {
    string str = "";
    var rollbackFunc = function (transactions:Info info, error? cause, boolean willRetry) {
        if (cause is error) {
            str += " " + cause.message();
        }
    };

    transaction {
        readonly d = 123;
        transactions:setData(d);
        transactions:Info transInfo = transactions:info();
        transactions:Info? newTransInfo = transactions:getInfo(transInfo.xid);
        if(newTransInfo is transactions:Info) {
            test:assertEquals(transInfo.xid, newTransInfo.xid);
        } else {
            panic AssertionError(ASSERTION_ERROR_REASON, message = "unexpected output from getInfo");
        }
        transactions:onRollback(rollbackFunc);
        str += "In Trx";
        test:assertEquals(d === transactions:getData(), true);
        check commit;
        str += " commit";
    }
}

type AssertionError error;

const ASSERTION_ERROR_REASON = "AssertionError";

@test:Config {
}
function testWithinTrxMode() {
    string ss = "";
    var onCommitFunc = function(transactions:Info? info) {
        ss = ss + " -> trxCommited";
    };

    transaction {
        ss = "trxStarted";
        string invoRes = testFuncInvocation();
        ss = ss + invoRes + " -> invoked function returned";
        transactions:onCommit(onCommitFunc);
        if (transactional) {
            ss = ss + " -> strand in transactional mode";
        }
        var commitRes = commit;
        if (!transactional) {
            ss = ss + " -> strand in non-transactional mode";
        }
        ss += " -> trxEnded.";
    }
    test:assertEquals(ss, "trxStarted -> within invoked function "
        + "-> strand in transactional mode -> invoked function returned -> strand in transactional mode "
        + "-> trxCommited -> strand in non-transactional mode -> trxEnded.");
}

function testFuncInvocation() returns string {
    string ss = " -> within invoked function";
    if (transactional) {
        ss = ss + " -> strand in transactional mode";
    }
    return ss;
}

@test:Config {
}
function testUnreachableCode() {
    string ss = "";
    var onCommitFunc = function(transactions:Info? info) {
        ss = ss + " -> trxCommited";
    };

    transaction {
        ss = "trxStarted";
        transactions:onCommit(onCommitFunc);
        var commitRes = commit;
        if (transactional) {
            //only reached when commit fails
            ss = ss + " -> strand in transactional mode";
        }
        ss += " -> trxEnded.";
    }
    test:assertEquals(ss, "trxStarted -> trxCommited -> trxEnded.");
}

@test:Config {
}
function testTransactionalInvoWithinMultiLevelFunc() {
    string ss = "";
    transaction {
        ss = "trxStarted";
        ss = func1(ss);
        var commitRes = commit;
        ss += " -> trxEnded.";
    }
    test:assertEquals(ss, "trxStarted -> within transactional func2 " +
                          "-> within transactional func1 -> trxEnded.");
}

transactional function func1(string str) returns string {
    string ss = func2(str);
    return ss + " -> within transactional func1";
}

transactional function func2(string str) returns string {
 transactions:Info transInfo = transactions:info();
 return str + " -> within transactional func2";
}

@test:Config {
}
function testRollbackWithBlockFailure() returns error? {
    string str = "";
    var onCommitFunc = function(transactions:Info? info) {
        str = str + " -> commit triggered";
    };

    var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
            str = str + " -> rollback triggered";
    };

    transaction {
        transactions:onCommit(onCommitFunc);
        transactions:onRollback(onRollbackFunc);
        str += "trx started";
        check getError(true);
        var o = commit;
        str += " -> trx end";
    }

    test:assertEquals(str, "trx started -> rollback triggered");
}

function getError(boolean err) returns error? {
    if(err) {
       error er = error("Custom Error");
       return er;
    }
}

@test:Config {
}
function testRollbackWithCommitFailure() returns error? {
    string str = "";
    var onCommitFunc = function(transactions:Info? info) {
        str = str + " -> commit triggered";
    };

    var rollbackFunc = function (transactions:Info info, error? cause, boolean willRetry) {
        str += "-> rollback triggered ";
    };

    transaction {
        transactions:onRollback(rollbackFunc);
        str += "trx started";
        setRollbackOnlyError();
        check commit;
        str += " commit";
    }
    str += "-> transaction block exited.";
    test:assertEquals(str, "trx started-> transaction block exited.");
}

transactional function setRollbackOnlyError() {
    error cause = error("rollback only is set, hence commit failed !");
    transactions:setRollbackOnly(cause);
}

client class Bank {
    remote transactional function deposit(string str) returns string {
        return str + "-> deposit trx func";
    }

    function doTransaction() returns string {
        string str = "";
        transaction {
            str += "trx started ";
            var amount = self->deposit(str);
            str = amount;
            checkpanic commit;
        }
        return str;
    }
}

@test:Config {
}
function testInvokeRemoteTransactionalMethodInTransactionalScope() {
    Bank bank = new;
    test:assertEquals(bank.doTransaction(), "trx started -> deposit trx func");
}

@test:Config {
}
function testAsyncReturn() {
    transaction {
        var x = start getInt();
        int f = wait x;
        var y = commit;
        test:assertEquals(f, 10);
    }
}

transactional function getInt() returns int {
    return 10;
}

transactional function (string) returns string anonFunc1 = transactional function (string str) returns string {
    return str + " -> within transactional anon func1";
};

@test:Config {
}
function testTransactionalAnonFunc1() {
    string ss = "";
    transaction {
        ss = "trxStarted";
        ss = anonFunc1(ss);
        var commitRes = commit;
        ss += " -> trxEnded.";
    }
    test:assertEquals(ss, "trxStarted -> within transactional anon func1 -> trxEnded.");
}

var anonFunc2 = transactional function (string str) returns string {
    return str + " -> within transactional anon func2";
};

@test:Config {
}
function testTransactionalAnonFunc2() {
    var ss = "";
    transaction {
        ss = "trxStarted";
        ss = anonFunc2(ss);
        var commitRes = commit;
        ss += " -> trxEnded.";
    }
    test:assertEquals(ss, "trxStarted -> within transactional anon func2 -> trxEnded.");
}

isolated transactional function isolatedFunc (string str) returns string {
    return str + " -> within isolated transactional func";
}

@test:Config {
}
function testIsolatedTransactionalFunc() {
    string ss = "";
    transaction {
        ss = "trxStarted";
        ss = isolatedFunc(ss);
        var commitRes = commit;
        ss += " -> trxEnded.";
    }
    test:assertEquals(ss, "trxStarted -> within isolated transactional func -> trxEnded.");
}

var isolatedFunc2 = isolated transactional function (string str) returns string {
    return str + " -> within isolated transactional anon func";
};

@test:Config {
}
function testIsolatedTransactionalAnonFunc() {
    var ss = "";
    transaction {
        ss = "trxStarted";
        ss = isolatedFunc2(ss);
        var commitRes = commit;
        ss += " -> trxEnded.";
    }
    test:assertEquals(ss, "trxStarted -> within isolated transactional anon func -> trxEnded.");
}

@test:Config {
}
function testMultipleRollbackInvocation()  {
    error? invokeMultipleRollbackRes = trap invokeMultipleRollback();
    if(invokeMultipleRollbackRes is error) {
        test:assertEquals(invokeMultipleRollbackRes.message(),
        "cannot call rollback if the strand is not in transaction mode");
    } else {
        panic error("Expected an error");
    }
}

function invokeMultipleRollback() {
   string str = "start";
   var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
       str += " -> trx rollback";
   };

   transaction {
      transactions:onRollback(onRollbackFunc);
      if(3 == 3) {
         rollback;
      }

      if (5 == 5) {
         rollback;
      } else {
          var resCommit = commit;
      }
   }
}
