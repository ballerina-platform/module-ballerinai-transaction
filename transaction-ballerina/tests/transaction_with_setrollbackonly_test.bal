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
import ballerina/io;
import ballerina/test;
import ballerina/lang.'transaction as trx;

@test:Config {
}
function testSetRollbackOnly() {
    error? setRollbackOnlyRes = setRollbackOnly();
    if (setRollbackOnlyRes is error) {
        test:assertEquals("setRollbackOnly", setRollbackOnlyRes.message());
    } else {
        panic error("Expected an error");
    }
}

function setRollbackOnly() returns error? {
    string str = "";
    var rollbackFunc = isolated function (trx:Info info, error? cause, boolean willRetry) {
        if (cause is error) {
            io:println("Rollback with error: " + cause.message());
        }
    };
    transaction {
        trx:onRollback(rollbackFunc);
        str += "In Trx";
        setRollbackOnlyErrorInTrx();
        check commit;
        str += " commit";
    }
    str += " -> Trx exited";
    test:assertEquals("In Trx -> Trx exited", str);
    return;
}

transactional function setRollbackOnlyErrorInTrx() {
    error cause = error("setRollbackOnly");
    trx:setRollbackOnly(cause);
}

@test:Config {
}
function testSetRollbackOnlyWithinLoop() {
    error? setRollbackOnlyRes = setRollbackOnlyWithinLoop();
    if (setRollbackOnlyRes is error) {
        test:assertEquals("setRollbackOnly", setRollbackOnlyRes.message());
    } else {
        panic error("Expected an error");
    }
}

function setRollbackOnlyWithinLoop() returns error? {
    string str = "";
    foreach var i in 1...5 {
        transaction {
            str += i.toString();
            setRollbackOnlyErrorInTrx();
            check commit;
            str += i.toString();
        }
    }
    return;
}

@test:Config {
}
function testSetRollbackOnlyWithRetry() {
    error? setRollbackOnlyRes = setRollbackOnlyWithRetry();
    if (setRollbackOnlyRes is error) {
        test:assertEquals("setRollbackOnly", setRollbackOnlyRes.message());
    } else {
        panic error("Expected an error");
    }
}


function setRollbackOnlyWithRetry() returns error? {
    string str = "";
    int i = 0;
    retry(5) transaction {
        i = i + 1;
        str += i.toString();
        setRollbackOnlyErrorInTrx();
        check commit;
        str += i.toString();
    }
    test:assertEquals("123456", str);
    return;
}

@test:Config {
}
function testSetRollbackOnlyWithRetryManager() {
    error? setRollbackOnlyRes = setRollbackOnlyWithRetryManager();
    if (setRollbackOnlyRes is error) {
        test:assertEquals("setRollbackOnly", setRollbackOnlyRes.message());
    } else {
        panic error("Expected an error");
    }
}

function setRollbackOnlyWithRetryManager() returns error? {
    string str = "";
    int i = 0;
    retry<RetryManager> (5) transaction {
        i = i + 1;
        str += i.toString();
        setRollbackOnlyErrorInTrx();
        check commit;
        str += i.toString();
    }
    test:assertEquals("123456", str);
    return;
}

public class RetryManager {
   private int count;
   public function init(int count = 2) {
       self.count = count;
   }
   public function shouldRetry(error? e) returns boolean {
     if e is error && self.count >  0 {
        self.count -= 1;
        return true;
     } else {
        return false;
     }
   }
}
