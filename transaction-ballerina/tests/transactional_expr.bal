// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

@test:Config {
}
function testTransactionalFalse() {
    test:assertEquals(false, transactional);
}

@test:Config {
}
function testTransactionalTrue() returns error? {
    transaction {
        test:assertEquals(true, transactional);
        check commit;
    }
}

@test:Config {
}
function testTransactionalFalse2() returns error? {
    transaction {
        check commit;
        test:assertEquals(false, transactional);
    }
}

@test:Config {
}
function testTransactionalFalse3() returns error? {
    transaction {
        check commit;
    }
    test:assertEquals(false, transactional);
}

@test:Config {
}
function testTransactionalInsideTransactionalFunction() returns error? {
    transaction {
        transactionFunc();
        check commit;
    }
}

transactional function transactionFunc() {
    test:assertEquals(true, transactional);
}
