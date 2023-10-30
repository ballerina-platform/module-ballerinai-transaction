package org.ballerinalang.stdlib.transaction;

import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.transactions.FileRecoveryLog;
import io.ballerina.runtime.transactions.InMemoryRecoveryLog;
import io.ballerina.runtime.transactions.RecoveryStatus;
import io.ballerina.runtime.transactions.TransactionResourceManager;
import io.ballerina.runtime.transactions.TransactionLogRecord;

public class TransactionRecoveryLog {
    public static void writeToLog(BString trxId, BString transactionBlockId, BString transactionStatus) {
        TransactionLogRecord logRecord = createLogRecord(trxId, transactionBlockId, transactionStatus);
        writeToLogFile(logRecord);
        writeToMemoryLog(logRecord);
    }

    private static TransactionLogRecord createLogRecord(BString trxId, BString transactionBlockId, BString transactionStatus) {
        TransactionLogRecord logRecord = new TransactionLogRecord(trxId.getValue(), transactionBlockId.getValue(), RecoveryStatus.valueOf(transactionStatus.getValue()));
        return logRecord;
    }

    private static void writeToLogFile(TransactionLogRecord logRecord) {
        FileRecoveryLog fileRecoveryLog = TransactionResourceManager.getInstance().getFileRecoveryLog();
        fileRecoveryLog.put(logRecord);
    }

    private static void writeToMemoryLog(TransactionLogRecord logRecord) {
        InMemoryRecoveryLog inMemoryLog = TransactionResourceManager.getInstance().getInMemoryLog();
        inMemoryLog.put(logRecord);
    }
}