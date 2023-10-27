package org.ballerinalang.stdlib.transaction;

import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.transactions.FileRecoveryLog;
import io.ballerina.runtime.transactions.TransactionResourceManager;

public class WriteToLogFile {
    public static void writeToLogFile(BString logMessage) {
        FileRecoveryLog fileRecoveryLog = TransactionResourceManager.getInstance().getFileRecoveryLog();
        fileRecoveryLog.put((logMessage.getValue()));
    }
}