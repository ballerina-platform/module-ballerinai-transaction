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

import ballerina/http;
import ballerina/log;

string S2 = "";

service /hello on new http:Listener(8890) {
    transactional resource function post remoteResource(http:Caller caller, http:Request req) returns error? {
        S2 = " in-remote";
        var payload = req.getTextPayload();
        if (payload is string) {
            if (payload == "blowUp") {
                // TODO: module-ballerinai-transaction#460
                int blowNum = check trap blowUp3();
            }
        }

        http:Response res = new;
        res.setPayload(S2 + " payload-from-remote");

        var resp = caller->respond(res);
        if (resp is error) {
            log:printError("Error sending response", 'error = resp);
        }
    }
}

function blowUp3() returns int {
        error err = error("TransactionError");
        panic err;
}
