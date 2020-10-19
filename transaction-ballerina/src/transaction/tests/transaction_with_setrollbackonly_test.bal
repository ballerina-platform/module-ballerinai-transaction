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
import ballerina/test;
import ballerina/lang.'transaction as trx;

@test:Config {
}
function testSetRollbackOnly() returns error? {
    string str = "";
    var rollbackFunc = function (trx:Info info, error? cause, boolean willRetry) {
        if (cause is error) {
            str += " " + cause.message();
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
}

transactional function setRollbackOnlyErrorInTrx() {
    error cause = error("setRollbackOnly");
    trx:setRollbackOnly(cause);
}
