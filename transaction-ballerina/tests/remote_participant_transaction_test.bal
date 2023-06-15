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
import ballerina/test;
import ballerina/lang.'error as errors;

string S1 = "";
boolean thrown1 = false;
boolean remoteExecuted = false;

http:Client separateRMParticipant01 = checkpanic new ("http://localhost:8890");

service / on new http:Listener(8889) {
    transactional resource function post sayHello(http:Caller caller, http:Request req) {
        S1 += " in-remote";
        boolean remoteBlown = false;
        var payload = req.getTextPayload();
        if (payload is string) {
            if (payload == "blowUp") {
                int|error blowNum = trap blowUp2(2);
                remoteBlown = true;
            }
        }

        http:Response res = new;
        if (remoteBlown) {
            res.setPayload("transactionError");
            res.statusCode = 500;
        } else {
            res.setPayload("payload-from-remote");
        }

        var resp = caller->respond(res);
        if (resp is error) {
            log:printError("Error sending response", 'error = resp);
        }
    }

    transactional resource function post nestedTrx(http:Caller caller, http:Request req) {
        S1 += " in-remote";
        boolean changeCode = false;
        var payload = req.getTextPayload();
        if (payload is string) {
            if (payload == "fail") {
                var x = nestedTrxInRemoteFunction(1);
                if x is error {

                }
                changeCode = true;
            } else if (payload == "panic") {
                var y = trap nestedTrxInRemoteFunction(2);
                if y is error {

                }
                changeCode = true;
            } else {
                var z = nestedTrxInRemoteFunction(0);
                if z is error {

                }
            }
        }

        http:Response res = new;
        res.setPayload("payload-from-remote");
        if (changeCode) {
            res.setPayload("transactionError");
            res.statusCode = 500;
        } else {
            res.setPayload("payload-from-remote");
        }
        var resp = caller->respond(res);
        if (resp is error) {
            log:printError("Error sending response", 'error = resp);
        }
    }

    transactional resource function get returnError(http:Caller caller, http:Request req) returns error? {
        S1 = S1 + " in-remote";
        var payload = req.getTextPayload();
        if payload is error {

        }

        // TODO: module-ballerinai-transaction#460
         var b = check trap blowUp2(2);
         int c = check b;

        http:Response res = new;
        res.setPayload("payload-from-remote");

        var resp = caller->respond(res);
        if (resp is error) {
            log:printError("Error sending response", 'error = resp);
        }
        return;
    }

}

function nestedTrxInRemoteFunction(int j) returns error? {
    int i = 0;
    transaction {
        i += 1;
        S1 += " in-nested-trx-1";
        retry(2) transaction {
            S1 = S1 + " in-nested-trx-2";
            if (j == 1) {
                S1 += " trx-2-fail";
                int blowNum = check blowUp2(1);
            }
            var a = commit;
            if a is () {
                S1 += " nested-trx-2-committed";
            }
        }
        if (j == 2) {
            S1 += " trx-1-panic";
            int|error blowNum = trap blowUp2(2);
        }
        var b = commit;
        if b is () {
            S1 += " nested-trx-1-committed";
        }
    }
    return;
}

function blowUp2(int i) returns int|error {
    if (i == 1) {
        return error errors:Retriable("TransactionError");
    } else if (i == 2) {
        panic error("TransactionError");
    } else {
        return 5;
    }
}

function initGlobalVar() {
    thrown1 = false;
    remoteExecuted = false;
}

function initiatorFunc(boolean throw1, boolean remote1, boolean blowRemote1) returns string|error {
    http:Client participantEP = checkpanic new ("http://localhost:8889/sayHello");
    initGlobalVar();
    S1 = "";
    retry transaction {
        S1 = S1 + " in-trx-block";
        if (remoteExecuted == false && remote1) {
            remoteExecuted = true;
            string blowOrNot = blowRemote1 ? "blowUp" : "Don't-blowUp";
            http:Response|error resp = participantEP->post("", blowOrNot);

            if (resp is http:Response) {
                if (resp.statusCode == 500) {
                    S1 = S1 + " remote1-blown";
                } else {
                    var payload = resp.getTextPayload();
                    if (payload is string) {
                        S1 = S1 + " <" + <@untainted>payload + ">";
                    } else {
                        log:printError(payload.message());
                    }
                }
            } else {
                log:printError(resp.message());
            }
        }

        if (throw1 && !thrown1) {
            S1 = S1 + " throw-1";
            thrown1 = true;
            int blowNum = check blowUp2(1);
        }

        S1 = S1 + " in-trx-lastline";
        var commitResult = commit;
        if commitResult is error {

        }
        if commitResult is () {
            S1 = S1 + " trx-committed";
        }
    }
    S1 = S1 + " after-trx";
    return S1;
}

function initiateNestedTransactionInRemote(string blow) returns @tainted string {
    http:Client remoteEp = checkpanic new ("http://localhost:8889/nestedTrx");
    S1 = "";
    transaction {
        S1 += " in-trx-block";
        http:Response|error resp = remoteEp->post("", blow);
        if (resp is http:Response) {
            if (resp.statusCode == 500) {
                S1 += " remote1-excepted";
                var payload = resp.getTextPayload();
                if (payload is string) {
                    S1 += ":[" + <@untainted>payload + "]";
                }
            } else {
                var text = resp.getTextPayload();
                if (text is string) {
                    S1 += " <" + <@untainted>text + ">";
                } else {
                    S1 += " error-in-remote-response " + <@untainted>text.message();
                    log:printError(text.message());
                }
            }
        } else {
            S1 += " remote call error: " + <@untainted>resp.message();
        }
        var c = commit;
        if c is error {

        }
        if c is () {
            S1 += " trx-committed";
        }
    }
    S1 = S1 + " after-trx";
    return S1;
}

function remoteErrorReturnInitiator() returns @tainted string {
    http:Client remoteEp = checkpanic new ("http://localhost:8889");
    S1 = "";
    transaction {
        S1 += " in initiator-trx";
        http:Response|error resp = remoteEp->get("/returnError");
        if (resp is http:Response) {
            if (resp.statusCode == 500) {
                S1 += " remote1-excepted";
                var payload = resp.getJsonPayload();
                if (payload is map<json>) {
                    S1 += ":[" + <@untainted>payload["message"].toString() + "]";
                }
            } else {
                var text = resp.getTextPayload();
                if (text is string) {
                    S1 += " <" + <@untainted>text + ">";
                } else {
                    S1 += " error-in-remote-response " + <@untainted>text.message();
                    log:printError(text.message());
                }
            }
        } else {
            S1 += " remote call error: " + <@untainted>resp.message();
        }
        var c = commit;
        if c is error {

        }
        if c is () {
            S1 += " trx-committed";
        }
    }
    S1 = S1 + " after-trx";
    return S1;
}

transactional function localParticipant() returns string {
    return " from-init-local-participant";
}

function callParticipantMultipleTimes() returns string {
    http:Client participantEP = checkpanic new ("http://localhost:8889/sayHello");
    S1 = "";
    int i = 1;
    transaction {
        while (i < 5) {
            i += 1;
            http:Response|error resp = participantEP->post("", "");
            if (resp is http:Response) {
                if (resp.statusCode == 500) {
                    S1 = S1 + " remote error";
                } else {
                    var payload = resp.getTextPayload();
                    if (payload is string) {
                        S1 += " <" + <@untainted>payload + ">";
                        S1 += localParticipant();
                    } else {
                        log:printError(payload.message());
                    }
                }
            } else {
                log:printError(resp.message());
            }
        }
        S1 += " in-trx-lastline";
        var c = commit;
        if c is error {

        }
        if c is () {
            S1 += " trx-committed";
        }
    }

    S1 = S1 + " after-trx";
    return S1;
}

service / on new http:Listener(8888) {
    resource function post remoteParticipantTransactionSuccessTest(http:Caller caller,
    http:Request req) {
        string|error result = initiatorFunc(false, true, false);
        http:Response res = new;
        res.setPayload(result is error ? result.toString() : result.toString());
        var r = caller->respond(res);
        if (r is error) {
            log:printError("Error sending response: " + (result is error ? result.toString() : result.toString()),
            'error = r);
        }
    }

    resource function post remoteParticipantTransactionFailSuccessTest(http:Caller caller,
    http:Request req) {
        string|error result = initiatorFunc(true, true, false);
        http:Response res = new;
        res.setPayload(result is error ? result.toString() : result.toString());
        var r = caller->respond(res);
        if (r is error) {
            log:printError("Error sending response: " + (result is error ? result.toString() : result.toString()),
            'error = r);
        }
    }

    resource function post remoteParticipantTransactionPanicInRemote(http:Caller caller,
    http:Request req) {
        string|error result = initiatorFunc(false, true, true);
        http:Response res = new;
        res.setPayload(result is error ? result.toString() : result.toString());
        var r = caller->respond(res);
        if (r is error) {
            log:printError("Error sending response: " + (result is error ? result.toString() : result.toString()),
            'error = r);
        }
    }

    resource function post remoteParticipantStartNestedTransaction(http:Caller caller, http:Request req) {
        string result = initiateNestedTransactionInRemote("nestedInRemote");
        http:Response res = new;
        res.setPayload(<@untainted>result);
        var r = caller->respond(res);
        if (r is error) {
            log:printError("Error sending response: " + result, 'error = r);
        }
    }

    resource function post remoteParticipantFailInNestedTransaction(http:Caller caller, http:Request req) {
        string result = initiateNestedTransactionInRemote("fail");
        http:Response res = new;
        res.setPayload(<@untainted>result);
        var r = caller->respond(res);
        if (r is error) {
            log:printError("Error sending response: " + result, 'error = r);
        }
    }

    resource function post remoteParticipantPanicInNestedTransaction(http:Caller caller, http:Request req) {
        string result = initiateNestedTransactionInRemote("panic");
        http:Response res = new;
        res.setPayload(<@untainted>result);
        var r = caller->respond(res);
        if (r is error) {
            log:printError("Error sending response: " + result, 'error = r);
        }
    }

    resource function post remoteParticipantReturnsError(http:Caller caller, http:Request req) {
        string result = remoteErrorReturnInitiator();
        http:Response res = new;
        res.setPayload(<@untainted>result);
        var r = caller->respond(res);
        if (r is error) {
            log:printError("Error sending response: " + result, 'error = r);
        }
    }

    resource function post remoteParticipantSeperateResourceManager(http:Caller ep, http:Request req) {
        http:Response res = new;
        res.statusCode = 200;
        string s = "in-remote-init";
        transaction {
            s += " in-trx";
            var reqText = req.getTextPayload();
            if reqText is error {

            }
            http:Response|error result = separateRMParticipant01->post("/hello/remoteResource", <@untainted>req);
            if (result is http:Response) {
                s += " [remote-status:" + result.statusCode.toString() + "] ";
                if (result.statusCode == 500) {
                    var p = result.getJsonPayload();
                    if (p is map<json>) {
                        s += p["message"].toString();
                    }
                } else {
                    var p = result.getTextPayload();
                    if (p is string) {
                        s += p;
                    } else {
                        s += " error-getTextPayload";
                    }
                }
            } else {
                s += " error-from-remote: " + result.message() + "desc: " + result.message();
            }
            s += localParticipant();
            var c = commit;
            if c is error {

            }
            if c is () {
                s += " trx-committed";
            }
        }

        var stt = res.setTextPayload(<@untainted>s);
        checkpanic ep->respond(res);
    }

    resource function post participantMultipleExecution(http:Caller caller, http:Request req) {
        string result = callParticipantMultipleTimes();
        http:Response res = new;
        res.setPayload(result);
        var r = caller->respond(res);
        if (r is error) {
            log:printError("Error sending response: " + result, 'error = r);
        }
    }
}

@test:Config {}
function testRemoteParticipantTransactionSuccess() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantTransactionSuccessTest");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(),
        " in-trx-block in-remote <payload-from-remote> in-trx-lastline trx-committed after-trx");
    }
}

@test:Config {}
function testRemoteParticipantTransactionFailSuccess() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantTransactionFailSuccessTest");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(),
        " in-trx-block in-remote <payload-from-remote> throw-1 in-trx-block in-trx-lastline trx-committed after-trx");
    }
}

@test:Config {}
function testRemoteParticipantTransactionExceptionInRemote() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantTransactionPanicInRemote");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(),
        " in-trx-block in-remote remote1-blown in-trx-lastline trx-committed after-trx");
    }
}

@test:Config {}
function testRemoteParticipantStartNestedTransaction() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantStartNestedTransaction");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(),
        " in-trx-block in-remote in-nested-trx-1 in-nested-trx-2 nested-trx-2-committed nested-trx-1-committed " +
        "<payload-from-remote> trx-committed after-trx");
    }
}

@test:Config {}
function testRemoteParticipantFailInNestedTransaction() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantFailInNestedTransaction");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(), " in-trx-block in-remote in-nested-trx-1 " +
        "in-nested-trx-2 trx-2-fail in-nested-trx-2 trx-2-fail in-nested-trx-2 trx-2-fail " +
        "remote1-excepted:[transactionError] trx-committed after-trx");
    }
}

@test:Config {}
function testRemoteParticipantPanicInNestedTransaction() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantPanicInNestedTransaction");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(), " in-trx-block in-remote in-nested-trx-1 " +
        "in-nested-trx-2 nested-trx-2-committed trx-1-panic nested-trx-1-committed " +
        "remote1-excepted:[transactionError] trx-committed after-trx");
    }
}

// TODO: module-ballerinai-transaction#460
@test:Config {}
function testRemoteParticipantReturnsError() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantReturnsError");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(), " in initiator-trx in-remote " +
        "remote1-excepted:[TransactionError] trx-committed after-trx");
    }
}

@test:Config {}
function testRemoteParticipantSeperateResourceManagerSuccess() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantSeperateResourceManager");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(), "in-remote-init in-trx [remote-status:200]  " +
        "in-remote payload-from-remote from-init-local-participant trx-committed");
    }
}

// TODO: module-ballerinai-transaction#460
@test:Config {}
function testRemoteParticipantSeperateResourceManagerRemoteFail() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/remoteParticipantSeperateResourceManager");
    http:Request req = new;
    req.setPayload("blowUp");
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(), "in-remote-init in-trx [remote-status:500] " +
        "TransactionError from-init-local-participant trx-committed");
    }
}

@test:Config {}
function testparticipantMultipleExecution() {
    http:Client participantEP = checkpanic new ("http://localhost:8888/participantMultipleExecution");
    http:Request req = new;
    http:Response|error response = participantEP->post("", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Response code mismatched");
        test:assertEquals(response.getTextPayload(), " in-remote <payload-from-remote> from-init-local-participant" +
        " in-remote <payload-from-remote> from-init-local-participant in-remote <payload-from-remote> " +
        "from-init-local-participant in-remote <payload-from-remote> from-init-local-participant in-trx-lastline" +
        " trx-committed after-trx");
    }
}
