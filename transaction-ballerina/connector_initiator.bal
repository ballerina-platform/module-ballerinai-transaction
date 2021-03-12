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

type InitiatorClientConfig record {
    string registerAtURL = "";
    decimal timeout = 0;
    record {
        int count = 0;
        decimal interval = 0;
    } retryConfig = {};
};

type RegistrationResponseTypedesc typedesc<RegistrationResponse>;

client class InitiatorClientEP {
    http:Client httpClient;

    function init(InitiatorClientConfig conf) {
        http:Client httpEP = checkpanic new(conf.registerAtURL, {
                timeout:conf.timeout,
                retryConfig:{
                    count:conf.retryConfig.count,
                    interval:conf.retryConfig.interval
                }
            });
        self.httpClient = httpEP;
    }

    remote function register(string transactionId, string transactionBlockId, RemoteProtocol[] participantProtocols)
                 returns @tainted RegistrationResponse|error {
        http:Client httpClient = self.httpClient;
        string participantId = getParticipantId(transactionBlockId);
        RegistrationRequest regReq = {
            transactionId:transactionId, participantId:participantId, participantProtocols:participantProtocols
        };

        json reqPayload = check regReq.cloneWithType(JsonTypedesc);
        http:Request req = new;
        req.setJsonPayload(reqPayload);
        var result = check httpClient->post("", req);
        http:Response res = <http:Response> result;
        int statusCode = res.statusCode;
        if (statusCode != http:STATUS_OK) {
            return error lang_trx:Error("Registration for transaction: " + transactionId + " failed response code: "
                + statusCode.toString());
        }
        json resPayload = check res.getJsonPayload();
        return <@untainted> resPayload.cloneWithType(RegistrationResponseTypedesc);
    }
}
