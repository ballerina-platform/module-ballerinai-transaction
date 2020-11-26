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
    test:assertEquals(logLines.length(), 40);
    validateLog(logLines[3], "ERROR", "transaction_stmt_negative.bal:(21:5,29:6)", "invalid transaction commit count");
    validateLog(logLines[4], "ERROR", "transaction_stmt_negative.bal:(36:5,44:6)", "transaction statement cannot " +
    "be used within a transactional scope");
    validateLog(logLines[5], "ERROR", "transaction_stmt_negative.bal:(45:13,45:30)", "usage of start within a " +
    "transactional scope is prohibited");
    validateLog(logLines[6], "ERROR", "transaction_stmt_negative.bal:(54:15,54:32)", "usage of start within a " +
    "transactional scope is prohibited");
    validateLog(logLines[7], "ERROR", "transaction_stmt_negative.bal:(56:15,56:39)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[8], "ERROR", "transaction_stmt_negative.bal:(75:17,75:23)", "commit not allowed here");
    validateLog(logLines[9], "ERROR", "transaction_stmt_negative.bal:(118:17,118:23)", "commit not allowed here");
    validateLog(logLines[10], "ERROR", "transaction_stmt_negative.bal:(132:9,136:10)", "invalid transaction " +
    "commit count");
    validateLog(logLines[11], "ERROR", "transaction_stmt_negative.bal:(134:17,134:23)", "break statement cannot be " +
    "used to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[12], "ERROR", "transaction_stmt_negative.bal:(138:13,138:19)", "commit cannot be used " +
    "outside a transaction statement");
    validateLog(logLines[13], "ERROR", "transaction_stmt_negative.bal:(148:17,148:26)", "continue statement " +
    "cannot be used to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[14], "ERROR", "transaction_stmt_negative.bal:(163:17,163:29)", "return statement cannot " +
    "be used to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[15], "ERROR", "transaction_stmt_negative.bal:(180:13,180:20)", "return statement cannot " +
    "be used to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[16], "ERROR", "transaction_stmt_negative.bal:(200:21,200:33)", "return statement cannot " +
    "be used to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[17], "ERROR", "transaction_stmt_negative.bal:(204:21,204:33)", "return statement cannot " +
    "be used to exit from a transaction without a commit or a rollback statement");
    validateLog(logLines[18], "ERROR", "transaction_stmt_negative.bal:(223:16,223:42)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[19], "ERROR", "transaction_stmt_negative.bal:(252:9,252:48)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[20], "ERROR", "transaction_stmt_negative.bal:(253:9,253:44)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[21], "ERROR", "transaction_stmt_negative.bal:(254:34,254:64)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[22], "ERROR", "transaction_stmt_negative.bal:(256:17,256:36)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[23], "ERROR", "transaction_stmt_negative.bal:(289:17,289:27)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[24], "ERROR", "transaction_stmt_negative.bal:(306:27,306:44)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[25], "ERROR", "transaction_stmt_negative.bal:(307:26,307:44)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[26], "ERROR", "transaction_stmt_negative.bal:(329:13,329:22)", "rollback not allowed here");
    validateLog(logLines[27], "ERROR", "transaction_stmt_negative.bal:(346:13,346:22)", "rollback not allowed here");
    validateLog(logLines[28], "ERROR", "transaction_stmt_negative.bal:(357:13,357:19)", "commit cannot be used " +
    "outside a transaction statement");
    validateLog(logLines[29], "ERROR", "transaction_stmt_negative.bal:(367:19,367:44)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[30], "ERROR", "transaction_stmt_negative.bal:(376:5,376:14)", "rollback cannot be used " +
    "outside of a transaction block");
    validateLog(logLines[31], "ERROR", "transaction_stmt_negative.bal:(386:17,386:42)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[32], "ERROR", "transaction_stmt_negative.bal:(398:21,398:27)", "commit not allowed here");
    validateLog(logLines[33], "ERROR", "transaction_stmt_negative.bal:(402:13,402:22)", "rollback not allowed here");
    validateLog(logLines[34], "ERROR", "transaction_stmt_negative.bal:(404:17,404:42)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[35], "ERROR", "transaction_stmt_negative.bal:(416:21,416:27)", "commit not allowed here");
    validateLog(logLines[36], "ERROR", "transaction_stmt_negative.bal:(420:13,420:22)", "rollback not allowed here");
    validateLog(logLines[37], "ERROR", "transaction_stmt_negative.bal:(422:17,422:42)", "invoking transactional " +
    "function outside transactional scope is prohibited");
    validateLog(logLines[38], "ERROR", "transaction_stmt_negative.bal:(440:17,440:42)", "invoking transactional " +
    "function outside transactional scope is prohibited");
}

@test:Config {}
public function testInvalidTrxHandlers() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run",
    "tests/resources/transaction_handlers_negative.bal");
    string[] logLines = getLogLinesFromExecResult(execResult);
    test:assertEquals(logLines.length(), 6);
    validateLog(logLines[3], "ERROR", "transaction_handlers_negative.bal:(31:33,31:47)", "incompatible types: expected " +
    "'function (ballerina/lang.transaction:0.0.1:Info,error?,boolean) returns ()', " +
    "found 'function (boolean) returns ()'");
    validateLog(logLines[4], "ERROR", "transaction_handlers_negative.bal:(32:31,32:43)", "incompatible types: expected " +
    "'function (ballerina/lang.transaction:0.0.1:Info) returns ()', found 'function (string) returns ()'");
}

@test:Config {}
public function testTransactionWithSetRollbackOnly() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run",
    "tests/resources/transaction_with_setrollbackonly_test_negative.bal");
    string[] logLines = getLogLinesFromExecResult(execResult);
    test:assertEquals(logLines.length(), 5);
    validateLog(logLines[3], "ERROR", "transaction_with_setrollbackonly_test_negative.bal:(26:5,26:27)",
    "invoking transactional function outside transactional scope is prohibited");
}

@test:Config {}
public function testTransactionOnFail() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run",
    "tests/resources/transaction_on_fail_negative.bal");
    string[] logLines = getLogLinesFromExecResult(execResult);
    test:assertEquals(logLines.length(), 8);
    validateLog(logLines[3], "ERROR", "transaction_on_fail_negative.bal:(32:6,32:35)", "unreachable code");
    validateLog(logLines[4], "ERROR", "transaction_on_fail_negative.bal:(48:4,50:5)", "incompatible error " +
    "definition type: 'ErrorTypeA' will not be matched to 'ErrorTypeB'");
    validateLog(logLines[5], "ERROR", "transaction_on_fail_negative.bal:(80:7,80:42)", "unreachable code");
    validateLog(logLines[6], "ERROR", "transaction_on_fail_negative.bal:(96:7,96:70)", "unreachable code");
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
