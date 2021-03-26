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

@test:Config {}
function transactionalAnonymousFuncAssignment() {
    string str = "start";
    transactional function () trxFunc1 = transactional function ()  {
       str += "-> within transactional function trxFunc1()";
    };

    transactional function() trxFunc2 = function () {
        str += "-> within transactional function trxFunc2()";
    };

    any foo = transactional function () {
        str += "-> within transactional function trxFunc3()";
    };

    transactional function () trxFunc3 = <transactional function ()> foo;

    transaction {
        if(transactional) {
            trxFunc1();
            trxFunc2();
            trxFunc3();
        }
        var ign = checkpanic commit;
    }

    test:assertEquals(str, "start-> within transactional function trxFunc1()" +
    "-> within transactional function trxFunc2()-> within transactional function trxFunc3()");
}
