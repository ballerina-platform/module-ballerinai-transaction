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
import ballerina/regex;
import ballerina/test;
import ballerina/jballerina.java;

const UTF_8 = "UTF-8";
configurable string bal_exec_path = ?;

const string TRX_STATEMENT_FILE = "tests/resources/transaction_stmt_negative.bal";
const string INVALID_TRX_HANDLER_FILE = "tests/resources/transaction_handlers_negative.bal";
const string ROLLBACK_ONLT_TRX_FILE = "tests/resources/transaction_with_setrollbackonly_test_negative.bal";
const string TRX_ON_FAIL_FILE = "tests/resources/transaction_on_fail_negative.bal";
const string TRANSACTIONAL_FUNC_FILE = "tests/resources/transactional_functions_negative.bal";

@test:Config {}
public function testTransactionStatement() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run",TRX_STATEMENT_FILE);
    string[] logLines = getLogLinesFromExecResult(execResult);
    string[] errorLines = getErrorLogLines(logLines);
    test:assertEquals(errorLines.length(), 32);
    validateLog(errorLines[0], "ERROR", "transaction_stmt_negative.bal:(21:5,29:6)", "invalid transaction commit count");
    validateLog(errorLines[1], "ERROR", "transaction_stmt_negative.bal:(27:9,27:18)", "rollback not allowed here");
    validateLog(errorLines[2], "ERROR", "transaction_stmt_negative.bal:(36:5,44:6)", "transaction statement cannot " +
    "be used within a transactional scope");
    validateLog(errorLines[3], "ERROR", "transaction_stmt_negative.bal:(45:13,45:30)", "usage of start within a " +
    "transactional scope is prohibited");
    validateLog(errorLines[4], "ERROR", "transaction_stmt_negative.bal:(54:15,54:32)", "usage of start within a " +
    "transactional scope is prohibited");
    validateLog(errorLines[5], "ERROR", "transaction_stmt_negative.bal:(56:15,56:39)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[6], "ERROR", "transaction_stmt_negative.bal:(75:28,75:34)", "commit not allowed here");
    validateLog(errorLines[7], "ERROR", "transaction_stmt_negative.bal:(86:21,86:45)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[8], "ERROR", "transaction_stmt_negative.bal:(89:28,89:34)", "commit not allowed here");
    validateLog(errorLines[9], "ERROR", "transaction_stmt_negative.bal:(112:17,112:26)", "rollback not allowed here");
    validateLog(errorLines[10], "ERROR", "transaction_stmt_negative.bal:(116:9,116:18)", "rollback not allowed here");
    validateLog(errorLines[11], "ERROR", "transaction_stmt_negative.bal:(118:28,118:34)", "commit not allowed here");
    validateLog(errorLines[12], "ERROR", "transaction_stmt_negative.bal:(132:9,136:10)", "invalid transaction commit count");
    validateLog(errorLines[13], "ERROR", "transaction_stmt_negative.bal:(134:17,134:23)", "break statement cannot be " +
    "used to exit from a transaction without a commit or a rollback statement");
    validateLog(errorLines[14], "ERROR", "transaction_stmt_negative.bal:(138:24,138:30)", "commit cannot be used outside a " +
    "transaction statement");
    validateLog(errorLines[15], "ERROR", "transaction_stmt_negative.bal:(148:17,148:26)", "continue statement cannot be " +
    "used to exit from a transaction without a commit or a rollback statement");
    validateLog(errorLines[16], "ERROR", "transaction_stmt_negative.bal:(163:17,163:29)", "return statement cannot be used " +
    "to exit from a transaction without a commit or a rollback statement");
    validateLog(errorLines[17], "ERROR", "transaction_stmt_negative.bal:(180:13,180:20)", "return statement cannot be used " +
    "to exit from a transaction without a commit or a rollback statement");
    validateLog(errorLines[18], "ERROR", "transaction_stmt_negative.bal:(200:21,200:33)", "return statement cannot be used " +
    "to exit from a transaction without a commit or a rollback statement");
    validateLog(errorLines[19], "ERROR", "transaction_stmt_negative.bal:(204:21,204:33)", "return statement cannot be used " +
    "to exit from a transaction without a commit or a rollback statement");
    validateLog(errorLines[20], "ERROR", "transaction_stmt_negative.bal:(223:16,223:42)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[21], "ERROR", "transaction_stmt_negative.bal:(252:9,252:48)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[22], "ERROR", "transaction_stmt_negative.bal:(253:9,253:44)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[23], "ERROR", "transaction_stmt_negative.bal:(254:34,254:64)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[24], "ERROR", "transaction_stmt_negative.bal:(256:17,256:36)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[25], "ERROR", "transaction_stmt_negative.bal:(289:17,289:27)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[26], "ERROR", "transaction_stmt_negative.bal:(306:27,306:44)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[27], "ERROR", "transaction_stmt_negative.bal:(307:26,307:44)", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(errorLines[28], "ERROR", "transaction_stmt_negative.bal:(325:40,325:46)", "commit not allowed here");
    validateLog(errorLines[29], "ERROR", "transaction_stmt_negative.bal:(335:17,335:26)", "rollback not allowed here");
    validateLog(errorLines[30], "ERROR", "transaction_stmt_negative.bal:(347:17,347:26)",
    "return statement cannot be used to exit from a transaction without a commit or a rollback statement");
    validateLog(errorLines[31], "ERROR", "transaction_stmt_negative.bal:(362:13,362:22)", "unreachable code");
}

@test:Config {}
public function testInvalidTrxHandlers() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", INVALID_TRX_HANDLER_FILE);
    string[] logLines = getLogLinesFromExecResult(execResult);
    string[] errorLines = getErrorLogLines(logLines);
    test:assertEquals(errorLines.length(), 2);
    validateLog(errorLines[0], "ERROR", "transaction_handlers_negative.bal:(31:33,31:47)", "incompatible types: expected " +
    "'ballerina/lang.transaction:0.0.0:RollbackHandler', found 'function (boolean) returns ()'");
    validateLog(errorLines[1], "ERROR", "transaction_handlers_negative.bal:(32:31,32:43)", "incompatible types: expected " +
    "'ballerina/lang.transaction:0.0.0:CommitHandler', found 'function (string) returns ()'");
}

@test:Config {}
public function testTransactionWithSetRollbackOnly() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", ROLLBACK_ONLT_TRX_FILE);
    string[] logLines = getLogLinesFromExecResult(execResult);
    string[] errorLines = getErrorLogLines(logLines);
    test:assertEquals(errorLines.length(), 1);
    validateLog(errorLines[0], "ERROR", "transaction_with_setrollbackonly_test_negative.bal:(26:5,26:27)",
    "invoking transactional function outside transactional scope is prohibited");
}

function getLogLinesFromExecResult(Process|error execResult) returns string[] {
    Process result = checkpanic execResult;
    int _ = checkpanic result.waitForExit();
    int _ = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    return logLines;
}

function getErrorLogLines(string[] logLines) returns string[] {
    return from string erStr in logLines
        where erStr.startsWith("ERROR")
        select erStr;
}

function validateLog(string log, string logLevel, string logLocation, string logMsg) {
    test:assertTrue(log.includes(logLevel));
    test:assertTrue(log.includes(logLocation));
    test:assertTrue(log.includes(logMsg));
}

@test:Config {}
public function testTransactionFunction() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", TRANSACTIONAL_FUNC_FILE);
    string[] logLines = getLogLinesFromExecResult(execResult);
    string[] errorLines = getErrorLogLines(logLines);
    test:assertEquals(errorLines.length(), 1);
    validateLog(errorLines[0], "ERROR", "transactional_functions_negative.bal:(18:23,20:6)",
    "incompatible types: expected 'function () returns ()', found 'transactional function () returns ()");
}

function exec(@untainted string command, @untainted map<string> env = {},
                     @untainted string? dir = (), @untainted string... args) returns Process|error = @java:Method {
    name: "exec",
    'class: "org.ballerinalang.stdlib.transaction.testutils.nativeimpl.Exec"
} external;
