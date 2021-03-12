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
import ballerina/lang.'transaction as lang_trx;

type Participant2pcClientConfig record {
    string participantURL = "";
    decimal timeout = 0;
    record {
        int count = 0;
        decimal interval = 0;
    } retryConfig = {};
};

type PrepareResponseTypedesc typedesc<PrepareResponse>;
type NotifyResponseTypedesc typedesc<NotifyResponse>;

client class Participant2pcClientEP {

    http:Client httpClient;
    Participant2pcClientConfig conf = {};

    function init(Participant2pcClientConfig c) {
        http:Client httpEP = checkpanic new(c.participantURL, {
            timeout: c.timeout,
            retryConfig:{
                count: c.retryConfig.count, interval: c.retryConfig.interval
            }
        });
        self.httpClient = httpEP;
        self.conf = c;
    }

    remote function prepare(string transactionId) returns @tainted string|error {
        http:Client httpClient = self.httpClient;
        http:Request req = new;
        PrepareRequest prepareReq = {transactionId:transactionId};
        json j = check prepareReq.cloneWithType(JsonTypedesc);
        req.setJsonPayload(j);
        var result = check httpClient->post("/prepare", req);
        http:Response res = <http:Response> result;
        int statusCode = res.statusCode;
        if (statusCode == http:STATUS_NOT_FOUND) {
            return error lang_trx:Error(TRANSACTION_UNKNOWN);
        } else if (statusCode == http:STATUS_OK) {
            json payload = check res.getJsonPayload();
            PrepareResponse prepareRes = check payload.cloneWithType(PrepareResponseTypedesc);
            return <@untainted> prepareRes.message;
        } else {
            return error lang_trx:Error("Prepare failed. Transaction: " + transactionId + ", Participant: " +
                self.conf.participantURL);
        }
    }

    remote function notify(string transactionId, string message) returns @tainted string|error {
        http:Client httpClient = self.httpClient;
        http:Request req = new;
        NotifyRequest notifyReq = {transactionId:transactionId, message:message};
        json j = check notifyReq.cloneWithType(JsonTypedesc);
        req.setJsonPayload(j);
        var result = check httpClient->post("/notify", req);
        http:Response res = <http:Response> result;
        json payload = check res.getJsonPayload();
        NotifyResponse notifyRes = check payload.cloneWithType(NotifyResponseTypedesc);
        string msg = notifyRes.message;
        int statusCode = res.statusCode;
        if (statusCode == http:STATUS_OK) {
            return <@untainted string> msg;
        } else if ((statusCode == http:STATUS_BAD_REQUEST && msg == NOTIFY_RESULT_NOT_PREPARED_STR) ||
            (statusCode == http:STATUS_NOT_FOUND && msg == TRANSACTION_UNKNOWN) ||
            (statusCode == http:STATUS_INTERNAL_SERVER_ERROR && msg == NOTIFY_RESULT_FAILED_EOT_STR)) {
            return error lang_trx:Error(msg);
        } else { // Some other error state
            return error lang_trx:Error("Notify failed. Transaction: " + transactionId + ", Participant: " +
                self.conf.participantURL);
        }
    }
}
