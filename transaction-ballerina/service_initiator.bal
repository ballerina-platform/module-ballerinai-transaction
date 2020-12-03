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

import ballerina/http;
import ballerina/io;
import ballerina/log;

public const string TWO_PHASE_COMMIT = "2pc";
const string PROTOCOL_COMPLETION = "completion";
const string PROTOCOL_VOLATILE = "volatile";
const string PROTOCOL_DURABLE = "durable";

string[] coordinationTypes = [TWO_PHASE_COMMIT];

map<string[]> coordinationTypeToProtocolsMap = getCoordinationTypeToProtocolsMap();
function getCoordinationTypeToProtocolsMap() returns map<string[]> {
    string[] twoPhaseCommitProtocols = [PROTOCOL_COMPLETION, PROTOCOL_VOLATILE, PROTOCOL_DURABLE];
    map<string[]> m = {};
    m[TWO_PHASE_COMMIT] = twoPhaseCommitProtocols;
    return m;
}

@http:ServiceConfig {
    basePath:"/balcoordinator/initiator"
}
//# Service on the initiator which is independent from the coordination type and handles registration of remote
//# participants.
service InitiatorService on coordinatorListener {

    # register(in: Micro-Transaction-Registration,
    # out: Micro-Transaction-Coordination?,
    # fault: ( Invalid-Protocol |
    # Already-Registered |
    # Cannot-Register |
    # Micro-Transaction-Unknown )? )
    #
    # If the registering participant specified a protocol name not matching the coordination type of the
    # micro-transaction, the following fault is returned:
    #
    # Invalid-Protocol
    #
    #         If the registering participant is already registered to the micro-transaction,
    # the following fault is returned:
    #
    # Already-Registered
    #
    #          If the coordinator already started the end-of-transaction processing for participants of the Durable
    #  protocol (see section 3.1.2) of the micro-transaction, the following fault is returned. Note explicitly,
    #  that registration for the Durable protocol is allowed while the coordinator is running the end-of-transaction
    #  processing for participants of the Volatile protocol (see section 3.1.3).
    #
    #  Cannot-Register
    # If the registering participant specified an unknown micro-transaction identifier, the following fault is
    # returned:
    #
    # Micro-Transaction-Unknown
    @http:ResourceConfig {
        methods:["POST"],
        path:"/{transactionBlockId}/register",
        body:"regReq",
        consumes:["application/json"]
    }
    resource function register(http:Caller conn, http:Request req, string transactionBlockId,
                    RegistrationRequest regReq) {
        final string participantId = regReq.participantId;
        final string txnId = regReq.transactionId;
        var initiatedTxn = initiatedTransactions[txnId];
        if (initiatedTxn is ()) {
            respondToBadRequest(conn, "Transaction-Unknown. Invalid TID:" + txnId);
        } else {
            if (!protocolCompatible(initiatedTxn.coordinationType, toProtocolArray(regReq.participantProtocols))) {
                // Invalid-Protocol
                respondToBadRequest(conn, "Invalid-Protocol in remote participant. TID:" + txnId + ",participant ID:" +
                participantId);
            } else {
                RemoteProtocol[] participantProtocols = regReq.participantProtocols;
                if (isRegisteredParticipant(participantId, initiatedTxn.participants)) {
                    log:printDebug(() => io:sprintf("Already-Registered. TID:%s,participant ID:%s", txnId,
                            participantId));
                } else {
                    RemoteParticipant participant = new(participantId, initiatedTxn.transactionId,
                                                        participantProtocols);
                    initiatedTxn.participants[participantId] = participant;
                }
                RemoteProtocol[] coordinatorProtocols = [];
                int i = 0;
                int j = 0;
                while (j < participantProtocols.length()) {
                    var participantProtocol = participantProtocols[j];
                    j += 1;
                //TODO:commenting due to a caching issue
                //foreach var participantProtocol in participantProtocols {
                    RemoteProtocol coordinatorProtocol = {
                        name:participantProtocol.name,
                        url:getCoordinatorProtocolAt(participantProtocol.name, transactionBlockId)
                    };
                    coordinatorProtocols[i] = coordinatorProtocol;
                    i = i + 1;
                }
                RegistrationResponse regRes = {transactionId:txnId, coordinatorProtocols:coordinatorProtocols};
                var resPayload = regRes.cloneWithType(JsonTypedesc);
                if (resPayload is json) {
                    http:Response res = new;
                    res.statusCode = http:STATUS_OK;
                    res.setJsonPayload(<@untainted json> resPayload);
                    var resResult = conn->respond(res);
                    if (resResult is http:ListenerError) {
                        log:printError("Sending response for register request for transaction " + txnId +
                                " failed", resResult);
                    } else {
                        log:printDebug(() => io:sprintf("Registered remote participant: %s for transaction: %s",
                                participantId, txnId));
                    }
                } else {
                    panic resPayload;
                }
            }
        }
        //TODO: Need to handle the  Cannot-Register error case
    }
}
