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
import ballerina/lang.'transaction as trx;

@test:Config {}
function transactionalAnonymousFuncAssignment() {
    string str = "start";
    transactional function () trxFunc1 = transactional function() {
                                             str += "-> within transactional function trxFunc1()";
                                         };

    transactional function () trxFunc2 = function() {
                                             str += "-> within transactional function trxFunc2()";
                                         };

    any foo = transactional function() {
                  str += "-> within transactional function trxFunc3()";
              };

    transactional function () trxFunc3 = <transactional function ()>foo;

    transaction {
        if (transactional) {
            trxFunc1();
            trxFunc2();
            trxFunc3();
        }
        var ign = checkpanic commit;
    }

    test:assertEquals(str, "start-> within transactional function trxFunc1()"
    + "-> within transactional function trxFunc2()-> within transactional function trxFunc3()");
}

isolated string outputCommit = "start";
isolated string outputRollback = "start";

@test:Config {}
function testTransactionalFunctionWithHandlersCommit() {
    var onRollbackFunc = isolated function(trx:Info? info, error? cause, boolean willTry) {
                             lock {
                                 outputCommit += " -> trxAborted";
                             }
                         };

    var onCommitFunc1 = isolated function(trx:Info? info) {
                            lock {
                                outputCommit += " -> trxCommited1";
                            }
                        };

    var onCommitFunc2 = isolated function(trx:Info? info) {
                            lock {
                                outputCommit += " -> trxCommited2";
                            }
                        };

    transactional function () trxFunc1 = transactional function() {
                                             lock {
                                                 outputCommit += "-> within transactional function trxFunc1()";
                                             }
                                             trx:onCommit(onCommitFunc1);
                                             trx:onRollback(onRollbackFunc);
                                         };

    transactional function () trxFunc2 = transactional function() {
                                             lock {
                                                 outputCommit += "-> within transactional function trxFunc2()";
                                             }
                                             trx:onCommit(onCommitFunc2);
                                             trx:onRollback(onRollbackFunc);
                                         };

    transaction {
        if (transactional) {
            trxFunc1();
            trxFunc2();
        }
        var ign = checkpanic commit;
        lock {
            outputCommit += " -> trx ended";
        }
    }

    lock {
        test:assertEquals(outputCommit, "start-> within transactional function trxFunc1()"
        + "-> within transactional function trxFunc2() -> trxCommited2 -> trxCommited1 -> trx ended");
        outputCommit = "";
    }
}

@test:Config {}
function testTransactionalFunctionWithHandlersRollback() {
    var onRollbackFunc1 = isolated function(trx:Info? info, error? cause, boolean willTry) {
                              lock {
                                  outputRollback += " -> trxAborted1";
                              }
                          };

    var onRollbackFunc2 = isolated function(trx:Info? info, error? cause, boolean willTry) {
                              lock {
                                  outputRollback += " -> trxAborted2";
                              }
                          };

    var onCommitFunc = isolated function(trx:Info? info) {
                           lock {
                               outputRollback += " -> trxCommited";
                           }
                       };

    transactional function () trxFunc1 = transactional function() {
                                             lock {
                                                 outputRollback += "-> within transactional function trxFunc1()";
                                             }
                                             trx:onCommit(onCommitFunc);
                                             trx:onRollback(onRollbackFunc1);
                                         };

    transactional function () trxFunc2 = transactional function() {
                                             lock {
                                                 outputRollback += "-> within transactional function trxFunc2()";
                                             }
                                             trx:onCommit(onCommitFunc);
                                             trx:onRollback(onRollbackFunc2);
                                         };

    transaction {
        if (transactional) {
            trxFunc1();
            trxFunc2();
        }
        int? a = 1;
        if a is int {
            rollback;
        } else {
            var ign = checkpanic commit;
        }
        lock {
            outputRollback += " -> trx ended";
        }
    }

    lock {
        test:assertEquals(outputRollback, "start-> within transactional function trxFunc1()"
        + "-> within transactional function trxFunc2() -> trxAborted2 -> trxAborted1 -> trx ended");
        outputRollback = "";
    }
}
