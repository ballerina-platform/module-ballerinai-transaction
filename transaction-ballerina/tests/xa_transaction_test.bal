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
import ballerina/jdbc;
import ballerina/io;
import ballerina/system;
import ballerina/file;
import ballerina/config;
import ballerina/lang.'transaction as transactions;

string xaDatasourceName = "org.h2.jdbcx.JdbcDataSource";

string libPath = checkpanic file:getAbsolutePath("lib");
string dbPath = checkpanic file:getAbsolutePath("target/databases");
string scriptPath = checkpanic file:getAbsolutePath("tests/resources/sql");

string user = "test";
string password = "Test123";

string xaTransactionDB1 = "jdbc:h2:" + dbPath + "/" + "XA_TRANSACTION_1";
string xaTransactionDB2 = "jdbc:h2:" + dbPath + "/" + "XA_TRANSACTION_2";

@test:Config {
    before: "initRequirements"
}
function testXATransaction() {
    string str = "";

    jdbc:Client dbClient1 = checkpanic new (url = xaTransactionDB1, user = user, password = password,
    options = {datasourceName: xaDatasourceName});
    jdbc:Client dbClient2 = checkpanic new (url = xaTransactionDB2, user = user, password = password,
    options = {datasourceName: xaDatasourceName});

    var onCommitFunc = function(transactions:Info? info) {
        str = str + " -> commit triggered";
    };

    transaction {
        str += "trx started";
        transactions:onCommit(onCommitFunc);
        var e1 = checkpanic dbClient1->execute("insert into Customers (customerId, name, creditLimit, country) " +
                                "values (1, 'Anne', 1000, 'UK')");
        var e2 = checkpanic dbClient2->execute("insert into Salary (id, value ) values (1, 1000)");
        var result = commit;

        if (result is ()) {
            str += " -> commit successful";
        }

        test:assertEquals(str, "trx started -> commit triggered -> commit successful");
    }

    checkpanic dbClient1.close();
    checkpanic dbClient2.close();
}

function initRequirements() {
    initializeDatabase("XA_TRANSACTION_1", "xa-transaction-test-data-1.sql");
    initializeDatabase("XA_TRANSACTION_2", "xa-transaction-test-data-2.sql");

    config:setConfig("b7a.transaction.log.base", "trxLogDir");
}

function initializeDatabase(string database, string script) {
    system:Process process = checkpanic system:exec(
            "java", {}, libPath, "-cp", "h2-1.4.200.jar", "org.h2.tools.RunScript",
            "-url", "jdbc:h2:" + checkpanic file:joinPath(dbPath, database),
            "-user", user,
            "-password", password,
            "-script", checkpanic file:joinPath(scriptPath, script));
    int exitCode = checkpanic process.waitForExit();
    test:assertExactEquals(exitCode, 0, "H2 " + database + " database creation failed!");

    io:println("Finished initialising H2 '" + database + "' databases.");
}
