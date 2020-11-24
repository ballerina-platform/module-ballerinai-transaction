import ballerina/config;
import ballerina/io;
import ballerina/system;
import ballerina/stringutils;
import ballerina/test;

const BAL_EXEC_PATH = "bal_exec_path";
const UTF_8 = "UTF-8";

@test:Config {}
public function testTransactionStatement() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run",
    "tests/resources/transaction_stmt_negative.bal");
    string[] logLines = getLogLinesFromExecResult(execResult);
    test:assertEquals(logLines.length(), 38);
    validateLog(logLines[2], "error", "transaction_stmt_negative.bal:21:5", "invalid transaction commit count");
    validateLog(logLines[3], "error", "transaction_stmt_negative.bal:36:5", "transaction statement cannot " +
    "be used within a transactional scope");
    validateLog(logLines[4], "error", "transaction_stmt_negative.bal:45:19", "usage of start within a " +
    "transactional scope is prohibited");
    validateLog(logLines[5], "error", "transaction_stmt_negative.bal:54:21", "usage of start within a " +
    "transactional scope is prohibited");
    validateLog(logLines[6], "error", "transaction_stmt_negative.bal:56:15", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[7], "error", "transaction_stmt_negative.bal:75:17", "commit not allowed here");
    validateLog(logLines[9], "error", "transaction_stmt_negative.bal:118:17", "commit not allowed here");
    validateLog(logLines[10], "error", "transaction_stmt_negative.bal:132:9", "invalid transaction commit count");
    validateLog(logLines[11], "error", "transaction_stmt_negative.bal:134:17", "break statement cannot be " +
    "used to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[12], "error", "transaction_stmt_negative.bal:138:13", "commit cannot be used outside a " +
    "transaction statement");
    validateLog(logLines[13], "error", "transaction_stmt_negative.bal:148:17", "continue statement cannot be " +
    "used to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[14], "error", "transaction_stmt_negative.bal:163:17", "return statement cannot be used " +
    "to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[15], "error", "transaction_stmt_negative.bal:180:13", "return statement cannot be used " +
    "to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[16], "error", "transaction_stmt_negative.bal:200:21", "return statement cannot be used " +
    "to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[17], "error", "transaction_stmt_negative.bal:204:21", "return statement cannot be used " +
    "to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[18], "error", "transaction_stmt_negative.bal:223:16", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[19], "error", "transaction_stmt_negative.bal:252:9", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[20], "error", "transaction_stmt_negative.bal:253:9", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[21], "error", "transaction_stmt_negative.bal:254:34", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[22], "error", "transaction_stmt_negative.bal:256:17", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[23], "error", "transaction_stmt_negative.bal:289:17", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[24], "error", "transaction_stmt_negative.bal:306:27", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[25], "error", "transaction_stmt_negative.bal:307:26", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[26], "error", "transaction_stmt_negative.bal:329:13", "rollback not allowed here");
    validateLog(logLines[27], "error", "transaction_stmt_negative.bal:346:13", "rollback not allowed here");
    validateLog(logLines[28], "error", "transaction_stmt_negative.bal:357:13", "commit cannot be used outside a " +
    "transaction statement");
    validateLog(logLines[29], "error", "transaction_stmt_negative.bal:367:19", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[30], "error", "transaction_stmt_negative.bal:376:5", "rollback cannot be used outside of a " +
    "transaction block");
    validateLog(logLines[31], "error", "transaction_stmt_negative.bal:386:17", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[32], "error", "transaction_stmt_negative.bal:398:21", "commit not allowed here");
    validateLog(logLines[33], "error", "transaction_stmt_negative.bal:402:13", "rollback not allowed here");
    validateLog(logLines[34], "error", "transaction_stmt_negative.bal:404:17", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[35], "error", "transaction_stmt_negative.bal:416:21", "commit not allowed here");
    validateLog(logLines[36], "error", "transaction_stmt_negative.bal:420:13", "rollback not allowed here");
    validateLog(logLines[37], "error", "transaction_stmt_negative.bal:422:17", "invoking transactional function " +
    "outside transactional scope is prohibited");
    validateLog(logLines[38], "error", "transaction_stmt_negative.bal:440:17", "invoking transactional function " +
    "outside transactional scope is prohibited");
}

@test:Config {}
public function testInvalidTrxHandlers() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run",
    "tests/resources/transaction_handlers_negative.bal");
    string[] logLines = getLogLinesFromExecResult(execResult);
    io:println(logLines);
    test:assertEquals(logLines.length(), 4);
    validateLog(logLines[2], "error", "transaction_handlers_negative.bal:31:33", "incompatible types: expected " +
    "'function (ballerina/lang.transaction:0.0.1:Info,error?,boolean) returns ()', " +
    "found 'function (boolean) returns ()'");
    validateLog(logLines[3], "error", "transaction_handlers_negative.bal:32:31", "incompatible types: expected " +
    "'function (ballerina/lang.transaction:0.0.1:Info) returns ()', found 'function (string) returns ()'");
}

@test:Config {}
public function testTransactionWithSetRollbackOnly() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run",
    "tests/resources/transaction_with_setrollbackonly_test_negative.bal");
    string[] logLines = getLogLinesFromExecResult(execResult);
    test:assertEquals(logLines.length(), 3);
    validateLog(logLines[2], "error", "transaction_with_setrollbackonly_test_negative.bal:26:5",
    "invoking transactional function outside transactional scope is prohibited");
}

@test:Config {}
public function testTransactionOnFail() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run",
    "tests/resources/transaction_on_fail_negative.bal");
    string[] logLines = getLogLinesFromExecResult(execResult);
    test:assertEquals(logLines.length(), 6);
    validateLog(logLines[2], "error", "transaction_on_fail_negative.bal:32:6", "unreachable code");
    validateLog(logLines[3], "error", "transaction_on_fail_negative.bal:48:4", "incompatible error " +
    "definition type: 'ErrorTypeA' will not be matched to 'ErrorTypeB'");
    validateLog(logLines[4], "error", "transaction_on_fail_negative.bal:80:7", "unreachable code");
    validateLog(logLines[5], "error", "transaction_on_fail_negative.bal:96:7", "unreachable code");
}

function getLogLinesFromExecResult(system:Process|error execResult) returns string[] {
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    return logLines;
}

function validateLog(string log, string logLevel, string logLocation, string logMsg) {
    test:assertTrue(stringutils:contains(log, logLevel));
    test:assertTrue(stringutils:contains(log, logLocation));
    test:assertTrue(stringutils:contains(log, logMsg));
}
