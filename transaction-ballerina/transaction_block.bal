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

import ballerina/jballerina.java;
import ballerina/lang.'transaction as lang_trx;
import ballerina/log;

# Handles the transaction remote participant function.
# Transaction remote participant function will be desugared to following method.
#
# + transactionBlockId - ID of the transaction block.
function beginRemoteParticipant(string transactionBlockId) {
    TransactionContext? txnContext = registerRemoteParticipant(transactionBlockId);
    if (txnContext is TransactionContext) {
        TransactionContext|error returnContext = beginTransaction(txnContext.transactionId, transactionBlockId,
            txnContext.registerAtURL, txnContext.coordinationType);
        if (returnContext is error) {
            notifyRemoteParticipantOnFailure();
            panic returnContext;
        } else {
            final string trxId = returnContext.transactionId;
            setTransactionContext(returnContext);
            log:printDebug("participant registered: " + trxId);
        }
    }
}

# When a transaction block in Ballerina code begins, it will call this function to begin a transaction.
# If this is a new transaction (transactionId == () ), then this instance will become the initiator and will
# create a new transaction context.
# If the participant and initiator are in the same process, this transaction block will register with the local
# initiator via a local function call.
# If the participant and initiator are in different processes, this transaction block will register with the remote
# initiator via a network call.
#
# + transactionId - Globally unique transaction ID. If this is a new transaction which is initiated, then this
#                   will be null.
#                   If this is a participant in an existing transaction, then it will have a value.
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + registerAtUrl - The URL of the initiator
# + coordinationType - Coordination type of this transaction
# + return - Newly created/existing TransactionContext for this transaction.
public function beginTransaction(string? transactionId, string transactionBlockId, string registerAtUrl,
                          string coordinationType) returns TransactionContext|error {
    if (transactionId is string) {
        if (initiatedTransactions.hasKey(transactionId)) { // if participant & initiator are in the same process
            // we don't need to do a network call and can simply do a local function call
            return registerLocalParticipantWithInitiator(transactionId, transactionBlockId, registerAtUrl);
        } else {
            //TODO: set the proper protocol
            string protocolName = PROTOCOL_DURABLE;
            RemoteProtocol[] protocols = [{
            name:protocolName, url:getParticipantProtocolAt(protocolName, <@untainted> transactionBlockId)
            }];
            return registerParticipantWithRemoteInitiator(transactionId, transactionBlockId, registerAtUrl, protocols);
        }
    } else {
        return createTransactionContext(coordinationType, transactionBlockId);
    }
}

# When an abort statement is executed, this function gets called.
#
# + transactionId - Globally unique transaction ID.
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + return - nil or error when transaction abortion is successful or not respectively.
# # Deprecated
@deprecated
function abortTransaction(string transactionId, string transactionBlockId) returns @tainted error? {
    string participatedTxnId = getParticipatedTransactionId(transactionId, transactionBlockId);
    var txn = participatedTransactions[participatedTxnId];
    if (txn is TwoPhaseCommitTransaction) {
        return txn.markForAbortion();
    } else {
        var initiatedTxn = initiatedTransactions[transactionId];
        if (initiatedTxn is TwoPhaseCommitTransaction) {
            return initiatedTxn.markForAbortion();
        } else {
            panic error lang_trx:Error("Unknown transaction");
        }
    }
}

# When a transaction block in Ballerina code ends, it will call this function to end a transaction.
# Ending a transaction by a participant has no effect because it is the initiator who can decide whether to
# commit or abort a transaction.
# Depending on the state of the transaction, the initiator decides to commit or abort the transaction.
#
# + transactionId - Globally unique transaction ID.
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + return - A string or an error representing the transaction end succcess status or failure respectively.
transactional function endTransaction(string transactionId, string transactionBlockId)
        returns @tainted string|lang_trx:Error? {
    if (lang_trx:getRollbackOnly()) {
        lang_trx:Error? e = getRollbackOnlyError();
        rollbackTransaction(transactionBlockId, e);
        return e;
    }

    string participatedTxnId = getParticipatedTransactionId(transactionId, transactionBlockId);
    if (!initiatedTransactions.hasKey(transactionId) && !participatedTransactions.hasKey(participatedTxnId)) {
        error err = error("Transaction: " + participatedTxnId + " not found");
        panic err;
    }

    var initiatedTxn = initiatedTransactions[transactionId];
    if (initiatedTxn is ()) {
        return "";
    } else {
        if (initiatedTxn.state == TXN_STATE_ABORTED) {
            return initiatedTxn.abortInitiatorTransaction();
        } else {
            string|lang_trx:Error ret = initiatedTxn.twoPhaseCommit();
            removeInitiatedTransaction(transactionId);
            return ret;
        }
    }
}

# Register remote participant. Functions with participant annotations will be desugered to below functions.
#
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + return - Transaction context.
function registerRemoteParticipant(string transactionBlockId) returns  TransactionContext? = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.Utils",
    name: "registerRemoteParticipant"
} external;

# Notify the transaction resource manager on remote participant failture.
function notifyRemoteParticipantOnFailure() = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.Utils",
    name: "notifyRemoteParticipantOnFailure"
} external;

# Creates a transaction context from global participant
#
function createTrxContextFromGlobalID() = @java:Method {
    'class: "org.ballerinalang.stdlib.transaction.Utils",
    name: "createTrxContextFromGlobalID"
} external;
