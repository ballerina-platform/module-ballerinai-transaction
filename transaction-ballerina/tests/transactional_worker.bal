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

@test:Config {
}
function trxWorkerTest1() {
    int res = 0;
    transaction {
        res = foo();
        var s = commit;
    }

    test:assertEquals(res, 51);
}

transactional function foo() returns int {
     int res = 0;
     transactional worker wx returns int {
        int x = 50;
        return x + 1;
     }
     res = wait wx;
     return res;
}

string ss = "";

@test:Config {
}
function testNewStrandWithTrxContext() returns error? {
    string str = "";
    transaction {
        str += "trx started";
        var o = start testTransactionalInvo(ss);
        str += wait o;
        check commit;
        str += " -> trx end";
    }

    test:assertEquals("trx started -> transactional call -> trx end", str);
}

transactional function testTransactionalInvo(string str) returns string {
    return str + " -> transactional call";
}
