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

import ballerina/lang.'transaction as lang_trx;
import ballerina/java;

function startTransaction(string transactionBlockId, lang_trx:Info? prevAttempt = ()) returns string {
    string transactionId = "";
  //  TransactionContext|error txnContext = createTransactionContext(TWO_PHASE_COMMIT, transactionBlockId);
  TransactionContext|error txnContext = beginTransaction((), transactionBlockId, "", TWO_PHASE_COMMIT);
    if (txnContext is error) {
        panic txnContext;
    } else {

        transactionId = txnContext.transactionId;
        setTransactionContext(txnContext, prevAttempt);
    }
    return transactionId;
}

 function checkIfTransactional() {

     if(!transactional) {
         panic TransactionError("invoking transactional function " +
                                     "outside transactional scope is prohibited");
     }
}

# Commit local resource managers.
#
# + transactionId - Globally unique transaction ID.
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + return - true or false representing whether the commit is successful or not.
function commitResourceManagers(string transactionId, string transactionBlockId) returns boolean = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.CommitResourceManagers",
    name: "commitResourceManagers"
} external;

# Prepare local resource managers.
#
# + transactionId - Globally unique transaction ID.
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + return - true or false representing whether the resource manager preparation is successful or not.
function prepareResourceManagers(string transactionId, string transactionBlockId) returns boolean = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.PrepareResourceManagers",
    name: "prepareResourceManagers"
} external;

# Abort local resource managers.
#
# + transactionId - Globally unique transaction ID.
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + return - true or false representing whether the resource manager abortion is successful or not.
function abortResourceManagers(string transactionId, string transactionBlockId) returns boolean = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.AbortResourceManagers",
    name: "abortResourceManagers"
} external;

# Set the transactionContext.
#
# + transactionContext - Transaction context.
# + prevAttempt - Information related to previous attempt.
function setTransactionContext(TransactionContext transactionContext, lang_trx:Info? prevAttempt = ()) = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.SetTransactionContext",
    name: "setTransactionContext"
} external;

# Rollback the transaction.
#
# + transactionBlockId - ID of the transaction block.
# + err - The cause of the rollback.
function rollbackTransaction(string transactionBlockId, error? err = ()) = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.RollbackTransaction",
    name: "rollbackTransaction"
} external;

# Get and Cleanup the failure.
#
# + return - is failed.
function getAndClearFailure() returns boolean = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.GetAndClearFailure",
    name: "getAndClearFailure"
} external;

# Cleanup the transaction context.
#
# + transactionBlockId - ID of the transaction block.
function cleanupTransactionContext(string transactionBlockId) = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.CleanUpTransactionContext",
    name: "cleanupTransactionContext"
} external;

function isTransactional() returns boolean = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.IsTransactional",
    name: "isTransactional"
} external;

function getAvailablePort() returns int = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.GetAvailablePort",
    name: "getAvailablePort"
} external;

public function getHostAddress() returns string = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.GetHostAddress",
    name: "getHostAddress"
} external;

function uuid() returns string = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.UUID",
    name: "uuid"
} external;

function timeNow() returns int = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.CurrentTime",
    name: "timeNow"
} external;

function getRollbackOnlyError() returns lang_trx:Error? = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.GetRollbackOnlyError",
    name: "getRollbackOnlyError"
} external;

function setContextAsNonTransactional() = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.SetContextAsNonTransactional",
    name: "setContextAsNonTransactional"
} external;
