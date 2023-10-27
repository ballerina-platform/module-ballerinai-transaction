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
import ballerina/jballerina.java;
import ballerina/http;

type RollbackHandlerType lang_trx:RollbackHandler[]|()[];

type CommitHandlerType lang_trx:CommitHandler[]|()[];

readonly class TimestampImpl {
    *lang_trx:Timestamp;

    public function toMillisecondsInt() returns int {
        return externToMillisecondsInt(self);
    }

    public function toString() returns string {
        return externToString(self);
    }
}

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
    if (!transactional) {
        panic error lang_trx:Error("invoking transactional function " + "outside transactional scope is prohibited");
    }
}

function startTransactionCoordinator() returns error? {
    http:Listener coordinatorListener = checkpanic new(coordinatorPort, { host: coordinatorHost });
    //attach initiatorService to listener
    check coordinatorListener.attach(initiatorService, "/balcoordinator/initiator");
    // attach participant2pcService to listener
    check coordinatorListener.attach(participant2pcService, "/balcoordinator/participant/2pc");
    //start registered services
    return coordinatorListener.'start();
}

function commitResourceManagers(string transactionId, string transactionBlockId) returns boolean {
    string committedLog = string `${transactionId}:${transactionBlockId}|committed`;
    writeToLogFile(committedLog);
    if transactional {
        CommitHandlerType commitFunc = getCommitHandlerList();
        if (commitFunc is lang_trx:CommitHandler[]) {
            lang_trx:Info previnfo = lang_trx:info();
            foreach lang_trx:CommitHandler handler in <lang_trx:CommitHandler[]>commitFunc {
                handler(previnfo);
            }
        }
    }
    boolean res = notifyCommit(transactionId, transactionBlockId);
    cleanResourceManagers(transactionId, transactionBlockId);
    setContextAsNonTransactional();
    return res;
}

# Notify local resource managers to commit.
#
# + transactionId - Globally unique transaction ID.
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + return - true or false representing whether the commit is successful or not.
function notifyCommit(string transactionId, string transactionBlockId) returns boolean = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.CommitResourceManagers",
    name: "notifyCommit"
} external;

function cleanResourceManagers(string transactionId, string transactionBlockId) = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.CommitResourceManagers",
    name: "cleanResourceManagers"
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
# + shouldRetry - true if the transaction will be retried, false otherwise.
function rollbackTransaction(string transactionBlockId, error? err = (), boolean shouldRetry = false) {
    if transactional {
        RollbackHandlerType rollbackFunc = getRollbackHandlerList();
        if (rollbackFunc is lang_trx:RollbackHandler[]) {
            lang_trx:Info previnfo = lang_trx:info();
            foreach lang_trx:RollbackHandler handler in <lang_trx:RollbackHandler[]>rollbackFunc {
                handler(previnfo, err, shouldRetry);
            }
        }
    }
    notifyAbort(transactionBlockId);
}

# Notify transaction abort.
#
# + transactionBlockId - ID of the transaction block.
function notifyAbort(string transactionBlockId) = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.NotifyAbortTransaction",
    name: "notifyAbort"
} external;

function getRollbackHandlerList() returns RollbackHandlerType = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.GetCommitRollbackHandlers",
    name: "getRollbackHandlerList"
} external;

function getCommitHandlerList() returns CommitHandlerType = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.GetCommitRollbackHandlers",
    name: "getCommitHandlerList"
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

function getHostAddress() returns string = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.GetHostAddress",
    name: "getHostAddress"
} external;

function uuid() returns string = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.UUID",
    name: "uuid"
} external;

function getRollbackOnlyError() returns lang_trx:Error? = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.GetRollbackOnlyError",
    name: "getRollbackOnlyError"
} external;

function setContextAsNonTransactional() = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.SetContextAsNonTransactional",
    name: "setContextAsNonTransactional"
} external;

function externToMillisecondsInt(TimestampImpl timestamp) returns int = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.ToMillisecondsInt",
    name: "toMillisecondsInt"
} external;

function externToString(TimestampImpl timestamp) returns string = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.ToString",
    name: "toString",
    paramTypes: ["io.ballerina.runtime.api.values.BObject"]
} external;

function writeToLogFile(string logMessage) = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.WriteToLogFile",
    name: "writeToLogFile"
} external;
