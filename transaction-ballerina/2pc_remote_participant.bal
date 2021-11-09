// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;
import ballerina/lang.'transaction as lang_trx;

class RemoteParticipant {

    string participantId;
    private string transactionId;
    private RemoteProtocol[] participantProtocols;

    function init(string participantId, string transactionId, RemoteProtocol[] participantProtocols) {
        self.participantId = participantId;
        self.transactionId = transactionId;
        self.participantProtocols = participantProtocols;
    }

    function prepare(string protocol) returns @tainted [(PrepareResult|error)?, Participant] {
        int i = 0;
        while ( i < self.participantProtocols.length()) {
            var remoteProto = self.participantProtocols[i];
            i += 1;
        //TODO: commenting due to a caching issue
        //foreach var remoteProto in self.participantProtocols {
            if (remoteProto.name == protocol) {
                // We are assuming a participant will have only one instance of a protocol
                return [self.prepareMe(remoteProto.url), self];
            }
        }
        return [(), self]; // No matching protocol
    }

    function notify(string action, string? protocolName) returns @tainted NotifyResult|error? {
        if (protocolName is string) {
            int i = 0;
            while (i < self.participantProtocols.length()) {
                var remoteProtocol = self.participantProtocols[i];
                if (protocolName == remoteProtocol.name) {
                    // We are assuming a participant will have only one instance of a protocol
                    return self.notifyMe(remoteProtocol.url, action);
                }
                i += 1;
            }
        } else {
            NotifyResult|error notifyResult = (action == COMMAND_COMMIT) ? NOTIFY_RESULT_COMMITTED
                                                                         : NOTIFY_RESULT_ABORTED;
            int i = 0;
            while (i < self.participantProtocols.length()) {
                var remoteProtocol = self.participantProtocols[i];
                var result = self.notifyMe(remoteProtocol.url, action);
                if (result is error) {
                    notifyResult = result;
                }
                i += 1;
            }
            return notifyResult;
        }
        return (); // No matching protocol
    }

    function prepareMe(string protocolUrl) returns @tainted PrepareResult|error {
        Participant2pcClientEP participantEP  = getParticipant2pcClient(protocolUrl);

        // Let's set this to true and change it to false only if a participant aborted or an error occurred while trying
        // to prepare a participant
        final string participantId = self.participantId;
        log:printDebug("Preparing remote participant: " + participantId);
        // If a participant voted NO or failed then abort
        var result = participantEP->prepare(self.transactionId);
        if (result is error) {
            log:printError("Remote participant: " + self.participantId + " failed", 'error = result);
            return result;
        } else {
            if (result == "aborted") {
                  log:printDebug("Remote participant: " + participantId + " aborted.");
                  return PREPARE_RESULT_ABORTED;
            } else if (result == "committed") {
                  log:printDebug("Remote participant: " + participantId + " committed");
                return PREPARE_RESULT_COMMITTED;
            } else if (result == "read-only") {
                log:printDebug("Remote participant: " + participantId + " read-only");
                return PREPARE_RESULT_READ_ONLY;
            } else if (result == "prepared") {
                log:printDebug("Remote participant: " + participantId + " prepared");
                return PREPARE_RESULT_PREPARED;
            } else {
                final string outcome = <string>result;
                log:printDebug("Remote participant: " + participantId + ", outcome: " + outcome);
            }
        }
        panic error lang_trx:Error("Remote participant:" + self.participantId + " replied with invalid outcome");
    }

    function notifyMe(string protocolUrl, string action) returns @tainted NotifyResult|error {
        Participant2pcClientEP participantEP;

        final string prtclUrl = protocolUrl;
        final string act = action;
        final string participantId = self.participantId;
        log:printDebug("Notify(" + act + ") remote participant: " + prtclUrl);
        participantEP = getParticipant2pcClient(protocolUrl);
        var result = participantEP->notify(self.transactionId, action);
        if (result is error) {
            log:printError("Remote participant: " + self.participantId + " replied with an error", 'error = result);
            return result;
        } else {
            if (result == NOTIFY_RESULT_ABORTED_STR) {
                log:printDebug("Remote participant: " + participantId + " aborted");
                return NOTIFY_RESULT_ABORTED;
            } else if (result == NOTIFY_RESULT_COMMITTED_STR) {
                log:printDebug("Remote participant: " + participantId + " committed");
                return NOTIFY_RESULT_COMMITTED;
            }
        }
        panic error lang_trx:Error("Unknown status on notify remote participant");
    }
}
