// Copyright (c) 2023 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.runtime;
import ballerina/task;
import ballerina/test;

isolated map<int> taskCounterMap = {"A": 0, "B": 0, "C": 0, "D": 0, "E": 0};

public isolated function performTransaction() returns error? {
    transaction {
        check commit;
    }
}

public isolated class TaskExecuter {

    *task:Job;
    private int counter = 0;
    private final string name;

    function init(string name) {
        self.name = name;
    }

    public isolated function execute() {
        int count = 0;
        lock {
            count = self.counter.cloneReadOnly();
            if (count >= 100) {
                return;
            }
            self.counter += 1;
        }

        var err = trap performTransaction();

        if !(err is ()) {
            test:assertFail("Error in task " + self.name + " : " + err.toString());
        }

        lock {
            int i = taskCounterMap.get(self.name);
            taskCounterMap[self.name] = (i + 1);
        }
    }

    public isolated function scheduleTaskExecution(decimal interval) {
        do {
            var _ = check task:scheduleJobRecurByFrequency(self, interval);
        } on fail error err {
            test:assertFail("Error in scheduling task " + self.name + " : " + err.toString());
        }
    }
}

public function scheduleTasks() returns error? {
    var taskA = new TaskExecuter("A");
    var taskB = new TaskExecuter("B");
    var taskC = new TaskExecuter("C");
    var taskD = new TaskExecuter("D");
    var taskE = new TaskExecuter("E");

    decimal interval = 0.1;

    taskA.scheduleTaskExecution(interval);
    taskB.scheduleTaskExecution(interval);
    taskC.scheduleTaskExecution(interval);
    taskD.scheduleTaskExecution(interval);
    taskE.scheduleTaskExecution(interval);

    runtime:sleep(10); // Sleep to allow tasks to run
}

@test:Config {
    before: scheduleTasks
}
public function testTransactionConcurrency() {
    map<int> expectedCountsMap = {"A": 100, "B": 100, "C": 100, "D": 100, "E": 100};
    map<int> actualCountsMap;
    lock {
        actualCountsMap = taskCounterMap.cloneReadOnly();
    }
    test:assertEquals(actualCountsMap, expectedCountsMap, "Transaction concurrency test failed");
}
