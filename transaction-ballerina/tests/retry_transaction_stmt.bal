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
import ballerina/lang.'transaction as transactions;

@test:Config {
}
function testRetryTrx() {
    string|error x = actualRetryTrxCode(2, false, false);
    if(x is string) {
        test:assertEquals(x, "start fc-2 inTrx failed inTrx failed inTrx Commit endTrx end");
    }
}

@test:Config {
}
function testPanicInRetryStmt() {
    string|error x = trap actualRetryTrxCode(2, false, true);
    if (x is error) {
        test:assertEquals(x.message().toString(), "TransactionError");
    }
}

function actualRetryTrxCode(int failureCutOff, boolean requestRollback, boolean doPanic) returns (string|error) {
    string a = "";
    a = a + "start";
    a = a + " fc-" + failureCutOff.toString();
    int count = 0;

    retry transaction {
        a = a + " inTrx";
        count = count + 1;
        if (count <= failureCutOff) {
            a = a + " failed"; // transaction block panic error, Set failure cutoff to 0, for not blowing up.
            int bV = check trxErrorInRetry();
        }

        if (doPanic) {
            blowUpInRetry();
        }

        if (requestRollback) { // Set requestRollback to true if you want to try rollback scenario, otherwise commit
            rollback;
            a = a + " Rollback";
        } else {
            check commit;
            a = a + " Commit";
        }
        a = a + " endTrx";
        a = (a + " end");
    }
    return a;
}

function trxErrorInRetry()  returns int|error {
    if (5 == 5) {
        return error("TransactionError");
    }
    return 5;
}

function blowUpInRetry() {
    panic error("TransactionError");
}

function transactionFailedHelperWithRetry() returns string|error {
    string a = "";
    retry(2) transaction {
                 a = a + " inTrx";
                 check getErrorInRetry();
                 a = a + " afterErr";
                 check commit;
             }
    a = a + " afterTx";
    return a;
}

function getErrorInRetry() returns error? {
    return error("Generic Error", message = "Failed");
}

@test:Config {
}
function testFailedTransactionOutputWithRetry() {
    boolean testPassed = true;
    string|error result = transactionFailedHelperWithRetry();
    testPassed = (result is error) && ("Generic Error" == result.message());
    test:assertEquals(testPassed, true);
}

@test:Config {
}
function testMultipleTrxSequenceSuccessWithRetry() {
    string result = multipleTrxSequenceWithRetry(false, false, false, false);
    test:assertEquals(result, "start in-trx-1 trxCommited-1 end-1 in-trx-2 trxCommited-2 end-2");
}

@test:Config {
}
function multipleTrxSequenceAbortFirstWithRetry() {
    string result = multipleTrxSequenceWithRetry(true, false, false, false);
    test:assertEquals(result, "start in-trx-1 trxRollbacked-1 end-1 in-trx-2 trxCommited-2 end-2");
}

@test:Config {
}
function multipleTrxSequenceAbortSecondWithRetry() {
    string result = multipleTrxSequenceWithRetry(false, true, false, false);
    test:assertEquals(result, "start in-trx-1 trxCommited-1 end-1 in-trx-2 trxRollbacked-2 end-2");
}

@test:Config {
}
function multipleTrxSequenceAbortBothWithRetry() {
    string result = multipleTrxSequenceWithRetry(true, true, false, false);
    test:assertEquals(result, "start in-trx-1 trxRollbacked-1 end-1 in-trx-2 trxRollbacked-2 end-2");
}

function multipleTrxSequenceWithRetry(boolean abort1, boolean abort2, boolean fail1, boolean fail2) returns string {
    string a = "start";
    int count = 0;
    boolean failed1 = false;
    boolean failed2 = false;

    transactions:Info transInfo;

    retry(2) transaction {
        var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
            a = a + " trxRollbacked-1";
         };

        var onCommitFunc = function(transactions:Info? info) {
            a = a + " trxCommited-1";
        };
        a += " in-trx-1";
        transactions:onRollback(onRollbackFunc);
        transactions:onCommit(onCommitFunc);
        if ((fail1 && !failed1) || abort1) {
            if(abort1) {
              rollback;
            }
            if(fail1 && !failed1) {
              failed1 = true;
              error err = error("TransactionError");
              panic err;
            }
        } else {
            var commitRes = commit;
        }
    }
    a += " end-1";

    retry(2) transaction {
        var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
            a = a + " trxRollbacked-2";
        };

        var onCommitFunc = function(transactions:Info? info) {
            a = a + " trxCommited-2";
        };
        a += " in-trx-2";
        transactions:onRollback(onRollbackFunc);
        transactions:onCommit(onCommitFunc);
        if ((fail2 && !failed2) || abort2) {
           if(abort2) {
             rollback;
           }
           if(fail2 && !failed2) {
             failed2 = true;
             error err = error("TransactionError");
             panic err;
           }
        } else {
            var commitRes = commit;
        }
    }
    a += " end-2";
    return a;
}

public class MyRetryTrxManager {
   private int count;
   public function init(int count = 2) {
       self.count = count;
   }
   public function shouldRetry(error? e) returns boolean {
     if e is error && self.count >  0 {
        self.count -= 1;
        return true;
     } else {
        return false;
     }
   }
}

@test:Config {
}
function testCustomRetryTrxManager() {
    string|error result = customRetryTrxManager();
    if (result is string) {
        test:assertEquals(result, "start attempt 1:error, attempt 2:error, attempt 3:result " +
                                               "returned end.");
    } else {
        panic error("Expected a string");
    }

}

function customRetryTrxManager() returns string|error {
    string str = "start";
    int count = 0;
    retry<MyRetryTrxManager> (3) transaction {
        count = count+1;
        if(count < 3) {
            str += (" attempt " + count.toString() + ":error,");
            int bV = check trxErrorInRetry();
        } else {
            str += (" attempt "+ count.toString() + ":result returned end.");
            var commitRes = commit;
            return str;
        }
    }
    return str;
}

@test:Config {
}
function testGettingtPrevInfo () {
    string|error result = getPrevInfo();
    if (result is string) {
        test:assertEquals(result, "start retry count:0 attempt 1:error, retry count:1 attempt 2:error, " +
        "retry count:2 attempt 3:result returned end.");
    } else {
        panic error("Expected a string");
    }

    string|error nestedResult = getPrevInfoInNested();
    if (nestedResult is string) {
        test:assertEquals(nestedResult, "start retry1 count:0 retry2 count:0 attempt 1:error, " +
        "retry2 count:1 attempt 2:error, retry2 count:2 attempt 3:result returned end.");
    } else {
        panic error("Expected a string");
    }
}

function getPrevInfo() returns string|error {
    string str = "start";
    int count = 0;
    transactions:Info transInfo;
    retry<MyRetryTrxManager> (3) transaction {
        transInfo = transactions:info();
        int retryValRWC = transInfo.retryNumber;
        str += " retry count:" + retryValRWC.toString();
        count = count+1;
        if(count < 3) {
            str += (" attempt " + count.toString() + ":error,");
            int bV = check trxErrorInRetry();
        } else {
            str += (" attempt "+ count.toString() + ":result returned end.");
            var commitRes = commit;
        }
    }
    return str;
}

function getPrevInfoInNested() returns string|error {
    string str = "start";
    int count = 0;
    transactions:Info transInfo1;
    retry<MyRetryTrxManager> (3) transaction {
        transInfo1 = transactions:info();
        int retryValRWC1 = transInfo1.retryNumber;
        str += " retry1 count:" + retryValRWC1.toString();
        transactions:Info transInfo2;
        retry<MyRetryTrxManager> (3) transaction {
                transInfo2 = transactions:info();
                int retryValRWC2 = transInfo2.retryNumber;
                str += " retry2 count:" + retryValRWC2.toString();
                count = count+1;
                if(count < 3) {
                    str += (" attempt " + count.toString() + ":error,");
                    int bV = check trxErrorInRetry();
                } else {
                    str += (" attempt "+ count.toString() + ":result returned end.");
                    var commitRes = commit;
                }
        }
        var ign = commit;
    }
    return str;
}
