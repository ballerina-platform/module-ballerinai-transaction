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

import ballerina/cache;
import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/task;
import ballerina/time;
import ballerina/lang.'transaction as lang_trx;
import ballerina/lang.'value as value;

# ID of the local participant used when registering with the initiator.
string localParticipantId = uuid:createType4AsString();

# This map is used for caching transaction that are initiated.
map<TwoPhaseCommitTransaction> initiatedTransactions = {};

# This map is used for caching transaction that are this Ballerina instance participates in.
@tainted map<TwoPhaseCommitTransaction> participatedTransactions = {};

# This cache is used for caching HTTP connectors against the URL, since creating connectors is expensive.
cache:Cache httpClientCache = new;

time:Utc currentUtc = time:utcNow();
time:Utc newTime = time:utcAddSeconds(currentUtc, 1);
time:Civil time = time:utcToCivil(newTime);
var result = check task:scheduleJobRecurByFrequency(new Cleanup(), 60, startTime = time);

class Cleanup {
    *task:Job;

    public function execute() {
        checkpanic cleanupTransactions();
    }
}

function cleanupTransactions() returns error? {
    worker w1 {
        int i = 0;
        var participatedTransactionsArr = participatedTransactions.toArray();
        while (i < participatedTransactionsArr.length()) {
            var twopcTxn = participatedTransactionsArr[i];
            i += 1;
        //TODO: commenting due to a caching issue
        //foreach var twopcTxn in participatedTransactions {
            final string participatedTxnId = getParticipatedTransactionId(twopcTxn.transactionId,
                twopcTxn.transactionBlockId);
            if (time:utcDiffSeconds(time:utcNow(), twopcTxn.createdTime) >= 120d) {
                if (twopcTxn.state != TXN_STATE_ABORTED && twopcTxn.state != TXN_STATE_COMMITTED) {
                    if (twopcTxn.state != TXN_STATE_PREPARED) {
                        boolean prepareSuccessful =
                            prepareResourceManagers(twopcTxn.transactionId, twopcTxn.transactionBlockId);
                        if (prepareSuccessful) {
                            twopcTxn.state = TXN_STATE_PREPARED;
                            log:printDebug("Auto-prepared participated  transaction: " + participatedTxnId);
                        } else {
                            log:printError("Auto-prepare of participated transaction: " + participatedTxnId +
                                    " failed");
                        }
                    }
                    if (twopcTxn.state == TXN_STATE_PREPARED) {
                        boolean commitSuccessful = commitResourceManagers(twopcTxn.transactionId,
                            twopcTxn.transactionBlockId);
                        if (commitSuccessful) {
                            twopcTxn.state = TXN_STATE_COMMITTED;
                            log:printDebug("Auto-committed participated  transaction: " + participatedTxnId);
                            removeParticipatedTransaction(participatedTxnId);
                        } else {
                            log:printError("Auto-commit of participated transaction: " + participatedTxnId + " failed");
                        }
                    }
                }
            }
            if (time:utcDiffSeconds(time:utcNow(), twopcTxn.createdTime) >= <decimal> 600) {
                // We don't want dead transactions hanging around
                removeParticipatedTransaction(participatedTxnId);
            }
        }
    }
    worker w2 returns () {
        TwoPhaseCommitTransaction[] initiatedTransactionsArr = initiatedTransactions.toArray();
        int i = 0;
        while(i < initiatedTransactionsArr.length()) {
            var twopcTxn = initiatedTransactionsArr[i];
            i += 1;
       //TODO:commenting due to a caching issue
       //foreach var twopcTxn in initiatedTransactions {
            if (time:utcDiffSeconds(time:utcNow(), twopcTxn.createdTime) >= <decimal>120) {
                if (twopcTxn.state != TXN_STATE_ABORTED) {
                    // Commit the transaction since prepare hasn't been received
                    var result = twopcTxn.twoPhaseCommit();
                    if (result is string) {
                        final string trxId = twopcTxn.transactionId;
                        final string outcome = result;
                        log:printDebug("Auto-committed initiated transaction: " + trxId + ". Result: " + outcome);
                        removeInitiatedTransaction(twopcTxn.transactionId);
                    } else {
                        log:printError("Auto-commit of participated transaction: " +
                        twopcTxn.transactionId + " failed", 'error = result);
                    }
                }
            }
            if (time:utcDiffSeconds(time:utcNow(), twopcTxn.createdTime) >= <decimal> 600) {
                // We don't want dead transactions hanging around
                removeInitiatedTransaction(twopcTxn.transactionId);
            }
        }
        return ();
    }
    var value = wait w2;
    return value;
}


function isRegisteredParticipant(string participantId, map<Participant> participants) returns boolean {
    return participants.hasKey(participantId);
}

function isValidCoordinationType(string coordinationType) returns boolean {
    int i = 0;
    while (i < coordinationTypes.length()) {
        var coordType = coordinationTypes[i];
        i += 1;
    //TODO:commenting due to caching issue;
    //foreach var coordType in coordinationTypes {
        if (coordinationType == coordType) {
            return true;
        }
    }
    return false;
}

function protoName(UProtocol p) returns string {
    if (p is RemoteProtocol) {
        return p.name;
    } else {
        return <string> p.name;
    }
}

function protocolCompatible(string coordinationType, UProtocol?[] participantProtocols) returns boolean {
    boolean participantProtocolIsValid = false;
    string[] validProtocols = coordinationTypeToProtocolsMap[coordinationType] ?: [];
    int i = 0;
    while ( i < participantProtocols.length()) {
        var p = participantProtocols[i];
        i += 1;
    //TODO: commenting due to a caching issue
    //foreach var p in participantProtocols {
        if (p is UProtocol) {
            UProtocol participantProtocol = p;
            int j = 0;
            while (j < validProtocols.length()) {
                var validProtocol = validProtocols[j];
                j += 1;
            //TODO: commenting due to a caching issue
            //foreach var validProtocol in validProtocols {
                if (protoName(participantProtocol) == validProtocol) {
                    participantProtocolIsValid = true;
                    break;
                } else {
                    participantProtocolIsValid = false;
                }
            }
            if (!participantProtocolIsValid) {
                break;
            }
        }
    }
    return participantProtocolIsValid;
}

type JsonTypedesc typedesc<json>;

function respondToBadRequest(http:Caller ep, string msg) {
    log:printError(msg);
    http:Response res = new;  res.statusCode = http:STATUS_BAD_REQUEST;
    RequestError requestError = {errorMessage:msg};
    var resPayload = requestError.cloneWithType(JsonTypedesc);
    if (resPayload is json) {
        res.setJsonPayload(<@untainted json> resPayload);
        var resResult = ep->respond(res);
        if (resResult is error) {
            log:printError("Could not send Bad Request error response to caller", 'error = resResult);
        } else {
            return;
        }
    } else {
        panic resPayload;
    }
}

function getCoordinatorProtocolAt(string protocolName, string transactionBlockId) returns string {
    //TODO: protocolName is unused for the moment
    return "http://" + coordinatorHost + ":" + coordinatorPort.toString() + initiator2pcCoordinatorBasePath + "/" +
        transactionBlockId;
}

function getParticipantProtocolAt(string protocolName, string transactionBlockId) returns string {
    //TODO: protocolName is unused for the moment
    return "http://" + coordinatorHost + ":" + coordinatorPort.toString() + participant2pcCoordinatorBasePath + "/" +
        transactionBlockId;
}

# The initiator will create a new transaction context by calling this function. At this point, a transaction object
# corresponding to the coordinationType will also be created and stored as an initiated transaction.
#
# + coordinationType - The type of the coordination relevant to the transaction block for which this TransactionContext
#                      is being created for.
# + transactionBlockId - The ID of the transaction block.
# + return - TransactionContext if the coordination type is valid or an error in case of an invalid coordination type.
function createTransactionContext(string coordinationType, string transactionBlockId) returns TransactionContext|error {
    if (!isValidCoordinationType(coordinationType)) {
        string msg = "Invalid-Coordination-Type:" + coordinationType;
        error err = error(msg);
        return err;
    } else {
        TwoPhaseCommitTransaction txn = new(uuid(), transactionBlockId, coordinationType = coordinationType);
        string txnId = txn.transactionId;
        txn.isInitiated = true;
        initiatedTransactions[txnId] = txn;
        TransactionContext txnContext = {
            transactionId:txnId,
            transactionBlockId:transactionBlockId,
            coordinationType:coordinationType,
            registerAtURL:"http://" + value:toString(coordinatorHost) + ":" + value:toString(coordinatorPort) +
                initiatorCoordinatorBasePath + "/" + transactionBlockId + registrationPath
        };
        return txnContext;
    }
}

# Register a local participant, which corresponds to a nested transaction of the initiated transaction, with the
# initiator. Such participants and the initiator don't have to communicate over the network, so we are special casing
# such participants.
#
# + transactionId - Globally unique transaction ID
# + transactionBlockId - ID of the transaction block. Each transaction block in a process has a unique ID.
# + registerAtURL - The URL of the initiator
# + return - TransactionContext if the registration is successul or an error in case of a failure.
function registerLocalParticipantWithInitiator(string transactionId, string transactionBlockId, string registerAtURL)
    returns TransactionContext|error {

    final string trxId = transactionId;
    final string participantId = getParticipantId(transactionBlockId);
    //TODO: Protocol name should be passed down from the transaction statement
    LocalProtocol participantProtocol = {name:PROTOCOL_DURABLE};
    var initiatedTxn = initiatedTransactions[transactionId];
    if (initiatedTxn is ()) {
        return error lang_trx:Error("Transaction-Unknown. Invalid TID:" + transactionId);
    } else {
        if (isRegisteredParticipant(participantId, initiatedTxn.participants)) { // Already-Registered
            log:printDebug("Already-Registered. TID:" + trxId + ", participant ID:" + participantId);
            TransactionContext txnCtx = {
                transactionId:transactionId, transactionBlockId:transactionBlockId,
                coordinationType:TWO_PHASE_COMMIT, registerAtURL:registerAtURL
            };
            return txnCtx;
        } else if (!protocolCompatible(initiatedTxn.coordinationType, [participantProtocol])) { // Invalid-Protocol
            return error lang_trx:Error("Invalid-Protocol in local participant. TID:" + transactionId + ",participantID:" +
            participantId);
        } else {
            //Set initiator protocols
            TwoPhaseCommitTransaction participatedTxn = new(transactionId, transactionBlockId);
            //Protocol initiatorProto = {name: PROTOCOL_DURABLE, transactionBlockId:transactionBlockId};
            //participatedTxn.coordinatorProtocols = [initiatorProto];

            LocalParticipant participant = new(participantId, participatedTxn, [participantProtocol]);
            initiatedTxn.participants[participantId] = participant;

            string participatedTxnId = getParticipatedTransactionId(transactionId, transactionBlockId);
            participatedTransactions[participatedTxnId] = participatedTxn;
            TransactionContext txnCtx = {transactionId:transactionId, transactionBlockId:transactionBlockId,
            coordinationType:TWO_PHASE_COMMIT, registerAtURL:registerAtURL};
            log:printDebug("Registered local participant: " + participantId + " for transaction:" + trxId);
            return txnCtx;
        }
    }
}

function removeParticipatedTransaction(string participatedTxnId) {
    var removed = trap participatedTransactions.remove(participatedTxnId);
    if (removed is error) {
        panic error lang_trx:Error("Removing participated transaction: " + participatedTxnId + " failed");
    }
}

function removeInitiatedTransaction(string transactionId) {
    var removed = trap initiatedTransactions.remove(transactionId);
    if (removed is error) {
        panic error lang_trx:Error("Removing initiated transaction: " + transactionId + " failed");
    }
}

function getInitiatorClient(string registerAtURL) returns InitiatorClientEP {
    InitiatorClientEP initiatorEP;
    if (httpClientCache.hasKey(registerAtURL)) {
        return <InitiatorClientEP> checkpanic httpClientCache.get(registerAtURL);
    } else {
        lock {
            if (httpClientCache.hasKey(registerAtURL)) {
                return <InitiatorClientEP> checkpanic httpClientCache.get(registerAtURL);
            }
            initiatorEP = new({ registerAtURL: registerAtURL, timeout: 15,
                retryConfig: { count: 2, interval: 5 }
            });
            cache:Error? result = httpClientCache.put(registerAtURL, initiatorEP);
            if (result is cache:Error) {
                final string url = registerAtURL;
                log:printDebug("Failed to add http client with key: " + url + " to the cache.");
            }
            return initiatorEP;
        }
    }
}

function getParticipant2pcClient(string participantURL) returns Participant2pcClientEP {
    Participant2pcClientEP participantEP;
    if (httpClientCache.hasKey(<@untainted> participantURL)) {
        return <Participant2pcClientEP> checkpanic httpClientCache.get(<@untainted>participantURL);
    } else {
        lock {
            if (httpClientCache.hasKey(<@untainted> participantURL)) {
                return <Participant2pcClientEP> checkpanic httpClientCache.get(<@untainted>participantURL);
            }
            participantEP = new({ participantURL: participantURL,
                timeout: 15, retryConfig: { count: 2, interval: 5 }
            });
            cache:Error? result = httpClientCache.put(participantURL, participantEP);
            if (result is cache:Error) {
                final string url = participantURL;
                log:printDebug("Failed to add http client with key: " + url + " to the cache.");
            }
            return participantEP;
        }
    }
}

# Registers a participant with the initiator's coordinator. This function will be called by the participant.
#
# + transactionId -  Global transaction ID to which this participant is registering with.
# + transactionBlockId - The local ID of the transaction block on the participant.
# + registerAtURL - The URL of the coordinator.
# + participantProtocols - The coordination protocals supported by the participant.
# + return - TransactionContext if the registration is successful or an error in case of a failure.
function registerParticipantWithRemoteInitiator(string transactionId, string transactionBlockId,
                                                       string registerAtURL, RemoteProtocol[] participantProtocols)
    returns TransactionContext|error {

    InitiatorClientEP initiatorEP = getInitiatorClient(registerAtURL);
    final string participatedTxnId = getParticipatedTransactionId(transactionId, transactionBlockId);

    // Register with the coordinator only if the participant has not already done so
    if (participatedTransactions.hasKey(participatedTxnId)) {
        log:printDebug("Already registered with initiator for transaction:" + participatedTxnId);
        TransactionContext txnCtx = {
            transactionId:transactionId, transactionBlockId:transactionBlockId,
            coordinationType:TWO_PHASE_COMMIT, registerAtURL:registerAtURL
        };
        return txnCtx;
    }
    final string url = registerAtURL;
    log:printDebug("Registering for transaction: " + participatedTxnId + " with coordinator: " + url);

    var result = initiatorEP->register(transactionId, transactionBlockId, participantProtocols);
    if (result is error) {
        string msg = "Cannot register with coordinator for transaction: " + transactionId;
        log:printError(msg, 'error = result);
        // TODO : Fix me.
        //map data = { cause: err };
        return error lang_trx:Error(msg);
    } else {
        RemoteProtocol[] coordinatorProtocols = result.coordinatorProtocols;
        TwoPhaseCommitTransaction twopcTxn = new(transactionId, transactionBlockId);
        twopcTxn.coordinatorProtocols = toProtocolArray(coordinatorProtocols);
        participatedTransactions[participatedTxnId] = twopcTxn;
        TransactionContext txnCtx = {
            transactionId:transactionId, transactionBlockId:transactionBlockId,
            coordinationType:TWO_PHASE_COMMIT, registerAtURL:registerAtURL
        };
        final string trxId = transactionId;
        log:printDebug("Registered with coordinator for transaction: " + trxId);
        return txnCtx;
    }
}

function getParticipatedTransactionId(string transactionId, string transactionBlockId) returns string {
    string id = transactionId + ":" + transactionBlockId;
    return id;
}

function getParticipantId(string transactionBlockId) returns string {
    string participantId = localParticipantId + ":" + transactionBlockId;
    return participantId;
}

# Log and prepare `error` as a `Error`.
#
# + message - Error message
# + err - `error` instance
# + return - Prepared `lang_trx:Error` instance
isolated function prepareError(string message, error? err = ()) returns lang_trx:Error {
    if (err is error) {
        return error lang_trx:Error(message, err);
    }
    return error lang_trx:Error(message);
}
