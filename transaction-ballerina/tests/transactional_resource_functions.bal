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

listener ABC ep = new;

service on ep {
    transactional resource function get foo(string b) {

    }
}

public class ABC {

    public int startCount;
    public int attachCount;

    public isolated function 'start() returns error? {
        self.startCount += 1;
        return;
    }
    public isolated function gracefulStop() returns error? {
        return;
    }
    public isolated function immediateStop() returns error? {
        return;
    }
    public isolated function detach(service object {} s) returns error? {
        return;
    }
    public isolated function attach(service object {} s, string[]|string? name = ()) returns error? {
        self.attachCount += 1;
        return;
    }

    public function init() {
        self.startCount = 0;
        self.attachCount = -2;
    }
}

@test:Config {
}
function test () {
    test:assertEquals(ep.startCount, 1);
    test:assertEquals(ep.attachCount, -1);
}
