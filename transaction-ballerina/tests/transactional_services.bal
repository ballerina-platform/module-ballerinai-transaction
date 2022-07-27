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
import ballerina/test;
import ballerina/lang.'transaction as trx;

listener http:Listener serviceTestEP = new (9090);
FooClient stClient = new (9090);

@http:ServiceConfig {}
service /echo on serviceTestEP {

    @http:ResourceConfig {}
    transactional resource function get message(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->respond(res);
    }
}

public client class FooClient {

    public http:Client httpClient;

    public function init(int port) {
        self.httpClient = checkpanic new ("http://localhost:9090");
    }

    transactional remote function foo() returns @tainted any|error {
        return self.httpClient->get("/echo/message", targetType = http:Response);
    }
}

@test:Config {}
function testTransactionalServices() {
    transaction {
        var response = stClient->foo();
        var x = checkpanic commit;
        if (response is http:Response) {
            test:assertEquals(response.statusCode, 200, msg = "Found expected output");
        } else if (response is error) {
            test:assertFail(msg = "Found unexpected output type: " + response.message());
        }
    }
}

isolated string handlerClientOutput = "start";

var onRollbackFuncInsideClient = isolated function(trx:Info? info, error? cause, boolean willTry) {
                                     lock {
                                         handlerClientOutput += " -> trxAborted inside client";
                                     }
                                 };

var onCommitFuncInsideClient = isolated function(trx:Info? info) {
                                   lock {
                                       handlerClientOutput += " -> trxCommited inside client";
                                   }
                               };

public client class BarClient {

    public http:Client httpClient;

    public function init(int port) {
        self.httpClient = checkpanic new ("http://localhost:9090");
    }

    transactional remote function foo() returns @tainted any|error {
        trx:onCommit(onCommitFuncInsideClient);
        trx:onRollback(onRollbackFuncInsideClient);
        return self.httpClient->get("/echo/message", targetType = http:Response);
    }
}

BarClient barClient = new (9090);

//@test:Config {}
//function testHandlersWithinTransactionalClient() {
//    transaction {
//        lock {
//            handlerClientOutput += " -> within trx block";
//        }
//        var response = barClient->foo();
//        var x = checkpanic commit;
//        if (response is http:Response) {
//            test:assertEquals(response.statusCode, 200, msg = "Found expected output");
//        } else if (response is error) {
//            test:assertFail(msg = "Found unexpected output type: " + response.message());
//        }
//        lock {
//            handlerClientOutput += " -> trx ended";
//        }
//    }
//    lock {
//        test:assertEquals(handlerClientOutput, "start -> within trx block -> trxCommited inside client -> trx ended");
//    }
//}

isolated string handlerServiceOutput = "start";
listener http:Listener serviceTestEPWithHandler = new (9091);
ClientWithHandlers handlerClient = new (9091);

var onRollbackFuncInsideService = isolated function(trx:Info? info, error? cause, boolean willTry) {
                                      lock {
                                          handlerServiceOutput += " -> trxAborted inside service";
                                      }
                                  };

var onCommitFuncInsideService = isolated function(trx:Info? info) {
                                    lock {
                                        handlerServiceOutput += " -> trxCommited inside service";
                                    }
                                };

var onCommitFuncInsideClient2 = isolated function(trx:Info? info) {
                                    lock {
                                        handlerServiceOutput += " -> trxCommited inside client";
                                    }
                                };

var onRollbacFuncInsideClient2 = isolated function(trx:Info? info, error? cause, boolean willTry) {
                                     lock {
                                         handlerServiceOutput += " -> trxAborted inside client";
                                     }
                                 };

var onRollbacFuncInsideTrxBlock = isolated function(trx:Info? info, error? cause, boolean willTry) {
                                     lock {
                                         handlerServiceOutput += " -> trxAborted inside trx block";
                                     }
                                 };

@http:ServiceConfig {}
service /echoWithHandler on serviceTestEPWithHandler {
    @http:ResourceConfig {}
    transactional resource function get message(http:Caller caller, http:Request req) {
        trx:onCommit(onCommitFuncInsideService);
        trx:onRollback(onRollbackFuncInsideService);
        http:Response res = new;
        checkpanic caller->respond(res);
    }
}

public client class ClientWithHandlers {

    public http:Client httpClient;

    public function init(int port) {
        self.httpClient = checkpanic new ("http://localhost:9091");
    }

    transactional remote function foo() returns @tainted any|error {
        trx:onCommit(onCommitFuncInsideClient2);
        trx:onRollback(onRollbacFuncInsideClient2);
        return self.httpClient->get("/echoWithHandler/message", targetType = http:Response);
    }
}

//@test:Config {}
//function testHandlersWithinTransactionalService() {
//    transaction {
//        lock {
//            handlerServiceOutput += " -> within trx block";
//        }
//        var response = handlerClient->foo();
//        var x = checkpanic commit;
//        if (response is http:Response) {
//            test:assertEquals(response.statusCode, 200, msg = "Found expected output");
//        } else if (response is error) {
//            test:assertFail(msg = "Found unexpected output type: " + response.message());
//        }
//        lock {
//            handlerServiceOutput += " -> trx ended";
//        }
//    }
//    lock {
//        test:assertEquals(handlerServiceOutput,
//        "start -> within trx block -> trxCommited inside service " + "-> trxCommited inside client -> trx ended");
//        handlerServiceOutput = "";
//    }
//}

//@test:Config {dependsOn: [testHandlersWithinTransactionalService]}
//function testRollbackWithinTransactionalService() {
//    transaction {
//        trx:onRollback(onRollbacFuncInsideTrxBlock);
//        lock {
//            handlerServiceOutput += "-> within trx block";
//        }
//        var response = handlerClient->foo();
//        int? a = 1;
//        if a is int {
//            rollback;
//        } else {
//            var x = checkpanic commit;
//        }
//        if (response is http:Response) {
//            test:assertEquals(response.statusCode, 200, msg = "Found expected output");
//        } else if (response is error) {
//            test:assertFail(msg = "Found unexpected output type: " + response.message());
//        }
//        lock {
//            handlerServiceOutput += " -> trx ended";
//        }
//    }
//    lock {
//        test:assertEquals(handlerServiceOutput, "-> within trx block -> trxAborted inside service"
//        + " -> trxAborted inside client -> trxAborted inside trx block -> trx ended");
//    }
//}
