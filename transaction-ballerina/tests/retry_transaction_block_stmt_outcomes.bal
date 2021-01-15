//// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
////
//// WSO2 Inc. licenses this file to you under the Apache License,
//// Version 2.0 (the "License"); you may not use this file except
//// in compliance with the License.
//// You may obtain a copy of the License at
////
//// http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing,
//// software distributed under the License is distributed on an
//// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//// KIND, either express or implied.  See the License for the
//// specific language governing permissions and limitations
//// under the License.
//import ballerina/io;
//import ballerina/test;
//import ballerina/lang.'transaction as transactions;
//import ballerina/lang.'error as errors;
//
//@test:Config {
//}
//function testCommitSuccessWithSuccessOutcome() returns error? {
//    string str = "";
//    boolean getErr = true;
//    var onCommitFunc = isolated function(transactions:Info? info) {
//        io:println("-> commit triggered ");
//    };
//    retry transaction {
//        str += "trx started ";
//        if (getErr) {
//            getErr = false;
//            str += "-> ";
//            var c = check incrementCount(2);
//        } else {
//            transactions:onCommit(onCommitFunc);
//            var e = commit;
//        }
//    }
//    str += "-> exit trx block";
//    test:assertEquals(str, "trx started -> trx started -> exit trx block");
//}
//
//@test:Config {
//}
//function testCommitSuccessWithNoRetryFailOutcome() returns error? {
//    string str = "";
//    boolean getErr = true;
//    error err = error("error");
//    var onCommitFunc = isolated function(transactions:Info? info) {
//        io:println("-> commit triggered ");
//    };
//
//    retry transaction {
//        str += "trx started ";
//        err = error("Error in block statement");
//        transactions:onCommit(onCommitFunc);
//        check commit;
//    }
//    test:assertEquals(err.message().toString(), "Error in block statement");
//}
//
//@test:Config {
//}
//function testcommitSuccessWithPanicOutcome() {
//    string|error x =  trap commitSuccessWithPanicOutcome();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "Error in increment count");
//    }
//}
//
//function commitSuccessWithPanicOutcome() returns string|error {
//    string str = "";
//    var onCommitFunc = isolated function(transactions:Info? info) {
//        io:println("-> commit triggered ");
//    };
//    retry transaction {
//        str += "trx started ";
//        transactions:onCommit(onCommitFunc);
//        var e = incrementCount(2);
//        check commit;
//        if (e is error) {
//            panic e;
//        }
//    }
//    return str;
//}
//
//@test:Config {
//}
//function testCommitFailWithUnusualSuccessOutcome() returns error? {
//    string str = "";
//    boolean getErr = true;
//
//    retry transaction {
//        str += "trx started";
//        if (getErr) {
//            getErr = false;
//            str += " -> ";
//            var c = check incrementCount(2);
//        } else {
//            setRollbackOnlyErrorForTrx();
//            var e = commit;
//        }
//
//        if (transactional) {
//            str += " -> commit failed";
//        }
//    }
//    str += " -> exit transaction block.";
//    test:assertEquals("trx started -> trx started -> commit failed -> exit transaction block.", str);
//}
//
//@test:Config {
//}
//function testCommitFailWithFailOutcome() {
//    string|error result = commitFailWithFailOutcome();
//    if (result is error) {
//        test:assertEquals(result.message().toString(), "rollback only is set, hence commit failed !");
//    }
//}
//
//function commitFailWithFailOutcome() returns string|error {
//    string str = "";
//    boolean getErr = true;
//
//    retry(2) transaction {
//        str += "trx started ";
//        if (getErr) {
//            getErr = false;
//            var c = check incrementCount(2);
//        } else {
//            setRollbackOnlyErrorForTrx();
//            check commit;
//        }
//    }
//    str += "-> exit transaction block.";
//    return str;
//}
//
//@test:Config {
//}
//function testCommitFailWithPanicOutcome() {
//    error? x =  trap commitFailWithPanicOutcome();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "Panic due to failed commit");
//    }
//}
//
//function commitFailWithPanicOutcome() returns error? {
//    string str = "";
//    boolean getErr = true;
//
//    retry transaction {
//        str += "trx started ";
//        if (getErr) {
//            getErr = false;
//            var c = check incrementCount(2);
//        } else {
//            setRollbackOnlyErrorForTrx();
//            var e = commit;
//        }
//
//        if (transactional) {
//            panic error("Panic due to failed commit");
//        }
//    }
//}
//
//@test:Config {
//}
//function testRollbackWithSuccessOutcome() returns error? {
//    string str = "";
//    boolean getErr = true;
//    int x = -10;
//    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//        io:println("-> rollback ");
//    };
//
//    retry transaction {
//        str += "trx started ";
//        x += 1;
//        if (getErr) {
//            getErr = false;
//            str += "-> ";
//            var c = check incrementCount(2);
//        } else if (x < 0) {
//            transactions:onRollback(onRollbackFunc);
//            rollback;
//        } else {
//            str += "-> commit ";
//            var o = commit;
//        }
//        str += "-> end of trx block ";
//    }
//    str += "-> exit transaction block.";
//    test:assertEquals(str, "trx started -> trx started -> end of trx block -> exit transaction block.");
//}
//
//@test:Config {
//}
//function testRollbackWithFailOutcome() {
//    string|error rollbackWithFailOutcomeRes =  rollbackWithFailOutcome();
//    if (rollbackWithFailOutcomeRes is error) {
//       test:assertEquals(rollbackWithFailOutcomeRes.message().toString(), "Invalid number");
//    } else {
//        panic error("Expected an error");
//    }
//}
//
//function rollbackWithFailOutcome() returns string|error {
//    string str = "";
//    boolean getErr = true;
//    final int[] rollbackStatusCode = [0];
//    boolean rollbackperformed = false;
//    int x = -10;
//    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//        if (cause is error) {
//           rollbackStatusCode[0] = 1;
//        }
//    };
//
//    retry transaction {
//        str += "trx started ";
//        x += 1;
//        if (getErr) {
//            getErr = false;
//            var c = check incrementCount(2);
//        } else if (x < 0) {
//            transactions:onRollback(onRollbackFunc);
//            rollback error("Invalid number");
//        } else {
//            str += "-> commit ";
//            var o = commit;
//        }
//
//        if (rollbackStatusCode[0] == 1) {
//            fail error("Invalid number");
//        }
//    }
//    str += "-> exit transaction block.";
//    return str;
//}
//
//string out = "";
//
//@test:Config {
//}
//function testRollbackWithPanicOutcome() {
//    error? rollbackWithPanicOutcomeRes =  trap rollbackWithPanicOutcome();
//    if(rollbackWithPanicOutcomeRes is error) {
//        test:assertEquals(rollbackWithPanicOutcomeRes.message(), "Invalid number");
//    } else {
//        panic error("Expected an error");
//    }
//
//    test:assertEquals(out, "trx started ");
//    out = "";
//}
//
//function rollbackWithPanicOutcome() {
//    boolean getErr = true;
//    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//        io:println("-> rollback triggered");
//    };
//
//    retry transaction {
//        transactions:onRollback(onRollbackFunc);
//        out += "trx started ";
//        if (getErr) {
//            getErr = false;
//            panic error("Invalid number");
//        }
//        out += "-> commited ";
//        var o = commit;
//    }
//    out += "-> exit transaction block.";
//}
//
//@test:Config {
//}
//function testPanicFromRollbackWithUnusualSuccessOutcome() returns error? {
//    string str = "";
//    int x = -10;
//    boolean getErr = true;
//    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//        if (cause is error) {
//            var err = trap panicWithError(cause);
//            io:println("-> panic from rollback ");
//        }
//    };
//
//    retry transaction {
//        str += "trx started ";
//        x += 1;
//        if (getErr) {
//            getErr = false;
//            str += "-> ";
//            var c = check incrementCount(2);
//        } else if (x < 0) {
//            transactions:onRollback(onRollbackFunc);
//            rollback error("Invalid number");
//        } else {
//            str += "-> commit ";
//            var o = commit;
//        }
//    }
//    str += "-> exit transaction block.";
//    test:assertEquals(str, "trx started -> trx started -> panic from rollback -> exit transaction block.");
//}
//
//@test:Config {
//}
//function testPanicFromCommitWithUnusualSuccessOutcome() returns error? {
//    string str = "";
//    int x = 1;
//    boolean getErr = true;
//
//    retry transaction {
//        str += "trx started ";
//        if (getErr) {
//            getErr = false;
//            str += "-> ";
//            var c = check incrementCount(2);
//        } else {
//            setRollbackOnlyErrorForTrx();
//            var e = trap checkpanic commit;
//            str = str + "-> panic from commit ";
//        }
//        str += "-> end of trx block ";
//    }
//    str += "-> exit transaction block.";
//    test:assertEquals("trx started -> trx started -> panic from commit -> end of trx block -> exit transaction block.",
//    str);
//}
//
//@test:Config {
//}
//function testPanicFromCommitWithRollbackOnly() {
//    string|error x =  panicFromCommitWithUnusualFailOutcome();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "rollback only is set, hence commit failed !");
//    } else {
//       panic error("Expected an error");
//    }
//}
//
//function panicFromCommitWithUnusualFailOutcome() returns string|error {
//    string str = "";
//    boolean getErr = true;
//
//    retry transaction {
//        str += "trx started ";
//        if (getErr) {
//            getErr = false;
//            var c = check incrementCount(2);
//        } else {
//            setRollbackOnlyErrorForTrx();
//            check commit;
//        }
//        str += "-> end of trx block ";
//    }
//    str += "-> exit transaction block.";
//    return str;
//}
//
//@test:Config {
//}
//function testPanicFromRollbackWithPanicOutcome() {
//    error? x =  trap panicFromRollbackWithPanicOutcome();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "Invalid number");
//    } else {
//        panic error("Expected an error");
//    }
//}
//
//function panicFromRollbackWithPanicOutcome() returns error? {
//    string str = "";
//    boolean getErr = true;
//    int x = -10;
//    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//        if (cause is error) {
//            panic cause;
//        }
//    };
//
//    retry(2) transaction {
//        str += "trx started ";
//        x += 1;
//        if (getErr) {
//            getErr = false;
//            var c = check incrementCount(2);
//        } else if (x < 0) {
//            transactions:onRollback(onRollbackFunc);
//            rollback error("Invalid number");
//        } else {
//            str += "-> commit ";
//            var o = commit;
//        }
//    }
//    str += "-> exit transaction block.";
//}
//
//@test:Config {
//}
//function testPanicFromCommitWithPanicOutcome() {
//    error? x =  trap panicFromCommitWithPanicOutcome();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "rollback only is set, hence commit failed !");
//    }
//}
//
//function panicFromCommitWithPanicOutcome() returns error? {
//    string str = "";
//    boolean getErr = true;
//
//    retry transaction {
//        str += "trx started ";
//        if (getErr) {
//            getErr = false;
//            var c = check incrementCount(2);
//        } else {
//            setRollbackOnlyErrorForTrx();
//            var e = checkpanic commit;
//        }
//        str += "-> end of trx block ";
//    }
//    str += "-> exit transaction block.";
//}
//
//@test:Config {
//}
//function testNoCommitOrRollbackPerformedWithRollbackAndFailOutcome() {
//    string|error x =  noCommitOrRollbackPerformedWithRollbackAndFailOutcome();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "Error in increment count");
//    }
//}
//
//function noCommitOrRollbackPerformedWithRollbackAndFailOutcome() returns string|error {
//    string str = "";
//    int x = 0;
//    boolean getErr = true;
//    var onCommitFunc = isolated function(transactions:Info? info) {
//        io:println("-> commit triggered ");
//    };
//
//    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//        if (cause is error) {
//            io:println("rollback due to fail");
//        }
//    };
//
//    retry transaction {
//        str += "trx started ";
//        transactions:onCommit(onCommitFunc);
//        transactions:onRollback(onRollbackFunc);
//        if (getErr) {
//            var e = check incrementCount(2);
//        } else {
//            check commit;
//        }
//        str += "-> end of trx block ";
//    }
//    str += "-> exit transaction block.";
//    return str;
//}
//
//@test:Config {
//}
//function testNoCommitOrRollbackPerformedWithRollbackAndPanicOutcome() {
//    error? x =  trap noCommitOrRollbackPerformedWithRollbackAndPanicOutcome();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "Error in increment count");
//    }
//}
//
//function noCommitOrRollbackPerformedWithRollbackAndPanicOutcome() returns error? {
//    string str = "";
//    int x = 0;
//    boolean getErr = true;
//    var onCommitFunc = isolated function(transactions:Info? info) {
//        io:println("-> commit triggered ");
//    };
//
//    var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//        if (cause is error) {
//           io:println("-> rollback triggered ");
//           panic cause;
//        }
//    };
//
//    retry transaction {
//        str += "trx started ";
//        transactions:onCommit(onCommitFunc);
//        transactions:onRollback(onRollbackFunc);
//        if (getErr) {
//            getErr = false;
//            var c = check incrementCount(2);
//        } else {
//            check commit;
//        }
//        str += "-> end of trx block ";
//    }
//    str += "-> exit transaction block.";
//}
//
//@test:Config {
//}
//function testCommitSuccessWithSuccessOutcomeInNestedRetry() returns error? {
//    var result = nestedRetryFunc(false, false);
//    test:assertEquals("trx started -> trx started -> trx started -> nested retry ->" +
//        " nested retry -> nested retry -> exit trx block", result);
//}
//
//@test:Config {
//}
//function testCommitSuccessWithPanicOutcomeInNestedRetry() {
//    error? x =  trap commitSuccessWithPanicOutcomeInNestedRetry();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "Panic in nested retry");
//    }
//}
//
//function commitSuccessWithPanicOutcomeInNestedRetry() {
//    var result = nestedRetryFunc(true, false);
//}
//
//@test:Config {
//}
//function testCommitFailWithUnusualSuccessOutcomeInNestedRetry() returns error? {
//    var result = nestedRetryFunc(false, true);
//    test:assertEquals("trx started -> trx started -> trx started -> nested retry -> nested retry" +
//    " -> nested retry -> exit trx block", result);
//}
//
//@test:Config {
//}
//function testCommitFailWithPanicOutcomeInNestedRetry() {
//    error? x =  trap commitFailWithPanicOutcomeInNestedRetry();
//    if (x is error) {
//       test:assertEquals(x.message().toString(), "Panic in nested retry");
//    }
//}
//
//function commitFailWithPanicOutcomeInNestedRetry() {
//    var result = nestedRetryFunc(true, true);
//}
//
//function nestedRetryFunc(boolean needPanic, boolean failCommit) returns string|error {
//    string str = "";
//    int count = 0;
//    var onCommitFunc = isolated function(transactions:Info? info) {
//        io:println("-> commit triggered ");
//    };
//
//    retry transaction {
//        str += "trx started ";
//        count = count + 1;
//        if (count <= 2) {
//            str += "-> ";
//            var c = check incrementCount(2);
//        } else {
//            if (failCommit) {
//               setRollbackOnlyErrorForTrx();
//            }
//            transactions:onCommit(onCommitFunc);
//            var e = commit;
//        }
//        int count2 = 0;
//        retry transaction {
//            str += "-> nested retry ";
//            count2 = count2 + 1;
//            if (count2 <= 2) {
//                var c = check incrementCount(2);
//            } else {
//                if (failCommit) {
//                    setRollbackOnlyErrorForTrx();
//                }
//                transactions:onCommit(onCommitFunc);
//                var e = commit;
//            }
//        }
//        if (needPanic) {
//            panic error("Panic in nested retry");
//        }
//    }
//    str += "-> exit trx block";
//    return str;
//}
//
//@test:Config {
//}
//function testRollbackWithFailOutcomeInFirstNestedRetryStmt() returns error? {
//    var result = nestedRetryFuncWithRollback(true, false, false, false, false);
//    if (result is error) {
//        test:assertEquals("Rollback due to error in trx 1", result.message());
//    } else {
//        panic error("Expected an error");
//    }
//}
//
//@test:Config {
//}
//function testRollbackWithFailOutcomeInSecondNestedRetryStmt() returns error? {
//    var result = nestedRetryFuncWithRollback(true, false, false, false, true);
//    if (result is error) {
//        test:assertEquals(result.message(), "Rollback due to error in trx 2");
//    } else {
//        panic error("Expected an error");
//    }
//}
//
//@test:Config {
//}
//function testRollbackWithPanicOutcomeInFirstNestedRetryStmt() {
//    var result = trap nestedRetryFuncWithRollback(true, false, true, false, false);
//    if (result is error) {
//        test:assertEquals(result.message(), "Panic in nested retry 1");
//    } else {
//        panic error("Expected an error");
//    }
//}
//
//@test:Config {
//}
//function testPanicFromRollbackWithPanicOutcomeInSecondNestedRetryStmt() {
//    var result = trap nestedRetryFuncWithRollback(true, true, false, false, true);
//    if (result is error) {
//        test:assertEquals(result.message(), "Rollback due to error in trx 2");
//    }
//}
//
//function nestedRetryFuncWithRollback(final boolean doRollback, final boolean doPanicInRollback, final boolean
//doPanicAfterRollback1,
//final boolean doPanicAfterRollback2, final boolean errInSecond) returns string|error {
//    string str = "";
//    int count = 0;
//    boolean errInRollback1 = false;
//    boolean errInRollback2 = false;
//    boolean errInFailedCheck = false;
//
//    retry(2) transaction {
//        retry(2) transaction {
//            var onCommitFunc = isolated function(transactions:Info? info) {
//                io:println("-> commit triggered in trx 1 ");
//            };
//            var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//                io:println("-> rollback triggered in trx 1 ");
//                if (cause is error) {
//                    if (doPanicInRollback && !errInSecond && !errInFailedCheck) {
//                       panic cause;
//                    } else {
//                        errInRollback1 = true;
//                    }
//                }
//            };
//            transactions:onCommit(onCommitFunc);
//            transactions:onRollback(onRollbackFunc);
//            count = count + 1;
//            str += "trx strated ";
//            if (count <= 3) {
//                errInFailedCheck = true;
//                var c = check incrementCount(2);
//            }
//            if (doRollback) {
//                str += "do rollback in 1";
//                errInFailedCheck = false;
//                rollback error("Rollback due to error in trx 1");
//            } else {
//                setRollbackOnlyErrorForTrx();
//                var e = commit;
//            }
//            if (errInRollback1 && !doPanicAfterRollback1 && !errInSecond) {
//                fail error errors:Retriable("Rollback due to error in trx 1");
//            }
//            if (doPanicAfterRollback1) {
//                panic error("Panic in nested retry 1");
//            }
//        }
//        check commit;
//    }
//    int count2 = 0;
//    errInFailedCheck = false;
//    retry(2) transaction {
//        retry(2) transaction {
//            var onCommitFunc = isolated function(transactions:Info? info) {
//                io:println("-> commit triggered in trx 2 ");
//            };
//            var onRollbackFunc = isolated function(transactions:Info? info, error? cause, boolean willTry) {
//                io:println("-> rollback triggered in trx 2 ");
//                if (cause is error) {
//                    if (doPanicInRollback && errInSecond && !errInFailedCheck) {
//                       panic cause;
//                    } else {
//                        errInRollback2 = true;
//                    }
//                }
//            };
//            transactions:onCommit(onCommitFunc);
//            transactions:onRollback(onRollbackFunc);
//            count2 = count2 + 1;
//            if (count2 <= 3) {
//                errInFailedCheck = true;
//                var c = check incrementCount(2);
//            }
//            if (doRollback) {
//                str += "do rollback in 2";
//                errInFailedCheck = false;
//                rollback error("Rollback due to error in trx 2");
//            } else {
//                setRollbackOnlyErrorForTrx();
//                var e = commit;
//            }
//            if (errInRollback2 && !doPanicAfterRollback2 && errInSecond) {
//                fail error errors:Retriable("Rollback due to error in trx 2");
//            }
//            if (doPanicAfterRollback2) {
//                panic error("Panic in nested retry 2");
//            }
//        }
//        check commit;
//    }
//    str += "-> exit trx block";
//    return str;
//}
//
//function incrementCount(int i) returns int|error {
//    if (i == 2) {
//        error err = error errors:Retriable("Error in increment count");
//        return err;
//    } else {
//        int x = i + 2;
//        return x;
//    }
//}
//
//transactional function setRollbackOnlyErrorForTrx() {
//    error cause = error("rollback only is set, hence commit failed !");
//    transactions:setRollbackOnly(cause);
//}
//
//isolated function panicWithError(error err) returns error? {
//    panic err;
//}
