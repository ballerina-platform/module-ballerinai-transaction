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
function testRetry() {
    string|error x = runActualCode(2, false, false);
    if(x is string) {
        test:assertEquals("start fc-2 -> in trx1 -> trx1 failed -> in trx1 -> trx1 failed -> in trx1 -> trx1 commit "
        + "-> trx1 end. -> in trx2 -> trx2 failed -> in trx2 -> trx2 failed -> in trx2 -> trx2 commit -> trx2 end. " +
        "-> all trx ended.", x);
    }
}

@test:Config {
}
function testPanicInRetry() {
    string|error x = trap runActualCode(2, false, true);
    error result = <error>x;
    test:assertEquals(result.message().toString(), "TransactionError");
}

function runActualCode(int failureCutOff, boolean requestRollback, boolean doPanic) returns (string|error) {
    string a = "";
    a = a + "start";
    a = a + " fc-" + failureCutOff.toString();
    int count1 = 0;
    retry transaction {
        a = a + " -> in trx1";
        count1 = count1 + 1;
        if (count1 <= failureCutOff) {
            a = a + " -> trx1 failed"; // transaction block panic error, Set failure cutoff to 0, for not blowing up.
            int bV = check trxError();
        }

        if (doPanic) {
            explode();
        }

        if (requestRollback) { // Set requestRollback to true if you want to try rollback scenario, otherwise commit
            rollback;
            a = a + " -> trx1 rollback";
        } else {
            check commit;
            a = a + " -> trx1 commit";
        }
        a = a + " -> trx1 end.";

        int count2 = 0;

        retry transaction {
            a = a + " -> in trx2";
            count2 = count2 + 1;
            if (count2 <= failureCutOff) {
                a = a + " -> trx2 failed"; // transaction block panic error, Set failure cutoff to 0, for not blowing up.
                int bV = check trxError();
            }

            if (doPanic) {
                explode();
            }

            if (requestRollback) { // Set requestRollback to true if you want to try rollback scenario, otherwise commit
                rollback;
                a = a + " -> trx2 rollback";
            } else {
                check commit;
                a = a + " -> trx2 commit";
            }
            a = a + " -> trx2 end.";
        }
    }
    a = (a + " -> all trx ended.");
    return a;
}

function trxError()  returns int|error {
    if (5 == 5) {
        return errors:Retriable("TransactionError");
    }
    return 5;
}

function explode() {
    panic error("TransactionError");
}

function transactionFailedHelper() returns string|error {
    string a = "start";
    retry(2) transaction {
           a = a + " -> in trx1";
           check getGenericError();
           a = a + " -> after Err";
           check commit;
           retry(2) transaction {
              a = a + " -> in trx2";
              check getGenericError();
              a = a + " -> after Err";
              check commit;
           }
           a = a + " -> after trx1";
    }
    a = a + " -> after trx2";
    return a;
}

function getGenericError() returns error? {
    return errors:Retriable("Generic Error", message = "Failed");
}

@test:Config {
}
function testFailedTransactionOutput() {
    boolean testPassed = true;
    string|error result = transactionFailedHelper();
    testPassed = (result is error) && ("Generic Error" == result.message());
    test:assertEquals(testPassed, true);
}

@test:Config {
}
function multipleTrxSequenceSuccess() {
    string result = multipleTrxSequence(false, false, false, false);
    test:assertEquals(result, "start -> in-trx-1-1 -> trxCommited-1-1 -> in-trx-1-2 -> trxCommited-1-2 "
            + "-> end-1 -> in-trx-2-1 -> trxCommited-2-1 -> in-trx-2-2 -> trxCommited-2-2 -> end-2");
}

@test:Config {
}
function multipleTrxSequenceAbortFirst() {
    string result = multipleTrxSequence(true, false, false, false);
    test:assertEquals(result, "start -> in-trx-1-1 -> trxRollbacked-1-1 -> in-trx-1-2 "
                         + "-> trxRollbacked-1-2 -> end-1 -> in-trx-2-1 -> trxCommited-2-1 -> in-trx-2-2 "
                         + "-> trxCommited-2-2 -> end-2");
}

@test:Config {
}
function multipleTrxSequenceAbortSecond() {
    string result = multipleTrxSequence(false, true, false, false);
    test:assertEquals(result, "start -> in-trx-1-1 -> trxCommited-1-1 -> in-trx-1-2 "
                          + "-> trxCommited-1-2 -> end-1 -> in-trx-2-1 -> trxRollbacked-2-1 -> in-trx-2-2 "
                          + "-> trxRollbacked-2-2 -> end-2");
}

@test:Config {
}
function multipleTrxSequenceAbortBoth() {
    string result = multipleTrxSequence(true, true, false, false);
    test:assertEquals(result, "start -> in-trx-1-1 -> trxRollbacked-1-1 -> in-trx-1-2 "
                     + "-> trxRollbacked-1-2 -> end-1 -> in-trx-2-1 -> trxRollbacked-2-1 -> in-trx-2-2 "
                     + "-> trxRollbacked-2-2 -> end-2");
}

function multipleTrxSequence(boolean abort1, boolean abort2, boolean fail1, boolean fail2) returns string {
    string a = "start";
    int count = 0;
    boolean failed1 = false;
    boolean failed2 = false;

    transactions:Info transInfo;

    retry(2) transaction {
        retry(2) transaction {
                var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
                    a = a + " -> trxRollbacked-1-1";
                 };

                var onCommitFunc = function(transactions:Info? info) {
                    a = a + " -> trxCommited-1-1";
                };
                a += " -> in-trx-1-1";
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
        var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
            a = a + " -> trxRollbacked-1-2";
         };

        var onCommitFunc = function(transactions:Info? info) {
            a = a + " -> trxCommited-1-2";
        };
        a += " -> in-trx-1-2";
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
    a += " -> end-1";

    retry(2) transaction {
            retry(2) transaction {
                var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
                    a = a + " -> trxRollbacked-2-1";
                };

                var onCommitFunc = function(transactions:Info? info) {
                    a = a + " -> trxCommited-2-1";
                };
                a += " -> in-trx-2-1";
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
        var onRollbackFunc = function(transactions:Info? info, error? cause, boolean willTry) {
            a = a + " -> trxRollbacked-2-2";
        };

        var onCommitFunc = function(transactions:Info? info) {
            a = a + " -> trxCommited-2-2";
        };
        a += " -> in-trx-2-2";
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
    a += " -> end-2";
    return a;
}

public class MyRetryManager {
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
function testCustomRetryManager() returns error? {
    string str = "start";
    int count1 = 0;
    retry<MyRetryManager> (3) transaction {
        str += " -> inside trx1 ";
        count1 = count1 + 1;
        if(count1 < 3) {
            str += (" -> attempt " + count1.toString() + ":error,");
            int bV = check trxError();
        } else {
            str += (" -> attempt "+ count1.toString());
            var commitRes = commit;
            str += " -> result commited -> trx1 end.";
        }
        int count2 = 0;
        retry<MyRetryManager> (3) transaction {
                str += " -> inside trx2 ";
                count2 = count2 + 1;
                if(count2 < 3) {
                    str += (" -> attempt " + count2.toString() + ":error,");
                    int bV = check trxError();
                } else {
                    str += (" -> attempt "+ count2.toString());
                    var commitRes = commit;
                    str += " -> result commited -> trx2 end.";
                }
        }
    }
    test:assertEquals(str, "start -> inside trx1  -> attempt 1:error, "
          + "-> inside trx1  -> attempt 2:error, -> inside trx1  -> attempt 3 -> result commited -> trx1 end. "
          + "-> inside trx2  -> attempt 1:error, -> inside trx2  -> attempt 2:error, -> inside trx2  "
          + "-> attempt 3 -> result commited -> trx2 end.");
}

@test:Config {
}
function testNestedTrxWithinRetryTrx() returns error? {
    string str = "start";
    int count = 0;
    retry transaction {
        str += " -> inside trx1 ";
        count = count + 1;
        if(count < 3) {
            str += (" -> attempt " + count.toString() + ":error,");
            int bV = check trxError();
        } else {
            str += (" -> attempt "+ count.toString());
            var commitRes = commit;
            str += " -> result commited -> trx1 end.";
        }
        transaction {
            str += " -> inside trx2 ";
            var commitRes = commit;
            str += " -> result commited -> trx2 end.";
        }
    }
    test:assertEquals(str, "start -> inside trx1  -> attempt 1:error, "
               + "-> inside trx1  -> attempt 2:error, -> inside trx1  -> attempt 3 -> result commited "
               + "-> trx1 end. -> inside trx2  -> result commited -> trx2 end.");
}

@test:Config {
}
function testNestedRetryTrxWithinTrx() returns error? {
    string str = "start";
    transaction {
        int count = 0;
        str += " -> inside trx1 ";
        retry transaction {
                str += " -> inside trx2 ";
                count = count + 1;
                if(count < 3) {
                    str += (" -> attempt " + count.toString() + ":error,");
                    int bV = check trxError();
                } else {
                    str += (" -> attempt "+ count.toString());
                    var commitRes = commit;
                    str += " -> result commited -> trx2 end.";
                }
            }
        var commitRes = commit;
        str += " -> result commited -> trx1 end.";
    }
    test:assertEquals(str, "start -> inside trx1  -> inside trx2  "
                  + "-> attempt 1:error, -> inside trx2  -> attempt 2:error, -> inside trx2  -> attempt 3 "
                  + "-> result commited -> trx2 end. -> result commited -> trx1 end.");
}

@test:Config {
}
function testNestedReturns () {
    string nestedInnerReturnRes = testNestedInnerReturn();
    test:assertEquals(nestedInnerReturnRes, "start -> within trx 1 -> within trx 2 -> within trx 3");
    string nestedMiddleReturnRes = testNestedMiddleReturn();
    test:assertEquals(nestedMiddleReturnRes, "start -> within trx 1 -> within trx 2");
}

function testNestedInnerReturn() returns string {
    string str = "start";
    retry transaction {
        str += " -> within trx 1";
        var res1 = commit;
        retry transaction {
            var res2 = commit;
            str += " -> within trx 2";
            retry transaction {
                var res3 = commit;
                str += " -> within trx 3";
                return str;
            }
        }
    }
}

function testNestedMiddleReturn() returns string {
    string str = "start";
    retry transaction {
        str += " -> within trx 1";
        var res1 = commit;
        retry transaction {
            int count = 1;
            var res2 = commit;
            str += " -> within trx 2";
            if (count == 1) {
                return str;
            }
            retry transaction {
                var res3 = commit;
                str += " -> within trx 3 -> should not reach here";
                return str;
            }
        }
    }
}

@test:Config {
}
public function testUsingFuncParameter() {
    createUpdateDeleteTransaction(error("theError"));
}

function createUpdateDeleteTransaction(error? dbOperation) {
    transaction {
        error? queryResult = dbOperation;
        if(dbOperation is error) {
            test:assertEquals(dbOperation.message(), "theError");
        } else {
            panic error("Expected an error");
        }
        var ign = commit;
    }
}
