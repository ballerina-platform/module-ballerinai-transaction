/*
 *  Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package org.ballerinalang.stdlib.transaction;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BFunctionPointer;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.transactions.TransactionConstants;
import io.ballerina.runtime.transactions.TransactionLocalContext;
import io.ballerina.runtime.transactions.TransactionResourceManager;

import java.io.IOException;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.ServerSocket;
import java.net.UnknownHostException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

import static io.ballerina.runtime.api.constants.RuntimeConstants.GLOBAL_TRANSACTION_ID;
import static io.ballerina.runtime.api.constants.RuntimeConstants.TRANSACTION_INFO;
import static io.ballerina.runtime.api.constants.RuntimeConstants.TRANSACTION_URL;
import static io.ballerina.runtime.transactions.TransactionConstants.DEFAULT_COORDINATION_TYPE;
import static io.ballerina.runtime.transactions.TransactionConstants.TRANSACTION_PACKAGE_ID;

/**
 * Native function implementations of the transactions module.
 *
 * @since 1.1.0
 * @deprecated use lang.transaction instead.
 */

public class Utils {
    private static final String STRUCT_TYPE_TRANSACTION_CONTEXT = "TransactionContext";
    private static final String STRUCT_TYPE_TRANSACTION_INFO = "Info";
    private static final String STRUCT_TYPE_TRANSACTION_INFO_INTERNAL = "InfoInternal";
    private static final String STRUCT_TYPE_TIMESTAMP = "TimestampImpl";

    public static void notifyResourceManagerOnAbort(BString transactionBlockId) {
        TransactionLocalContext transactionLocalContext =
                TransactionResourceManager.getInstance().getCurrentTransactionContext();
        TransactionResourceManager.getInstance()
                .notifyAbort(transactionLocalContext.getGlobalTransactionId(), transactionBlockId.getValue());
    }

    public static void rollbackTransaction(BString transactionBlockId) {
        TransactionResourceManager.getInstance().notifyTransactionAbort(transactionBlockId.getValue());
    }

    public static void cleanupTransactionContext(BString transactionBlockId) {
        TransactionResourceManager.getInstance().cleanupTransactionContext();
    }

    public static boolean getAndClearFailure() {
        return TransactionResourceManager.getInstance().getAndClearFailure();
    }

    public static void notifyRemoteParticipantOnFailure() {
        TransactionLocalContext transactionLocalContext =
                TransactionResourceManager.getInstance().getCurrentTransactionContext();
        if (transactionLocalContext == null) {
            return;
        }
        transactionLocalContext.notifyLocalRemoteParticipantFailure();
    }

    public static void notifyLocalParticipantOnFailure() {
        TransactionLocalContext transactionLocalContext =
                TransactionResourceManager.getInstance().getCurrentTransactionContext();
        if (transactionLocalContext == null) {
            return;
        }
        transactionLocalContext.notifyLocalParticipantFailure();
    }

    public static Object registerRemoteParticipant(Environment env, BString transactionBlockId) {
        TransactionResourceManager transactionResourceManager = TransactionResourceManager.getInstance();
        TransactionLocalContext transactionLocalContext = recreateTrxContext(env);
        transactionResourceManager.setCurrentTransactionContext(transactionLocalContext);

        // Register committed and aborted function handler if exists.
        transactionResourceManager.registerParticipation(transactionLocalContext.getGlobalTransactionId(),
                transactionBlockId.getValue());
        BMap<BString, Object> trxContext = ValueCreator.createRecordValue(env.getCurrentModule(),
                                                                           STRUCT_TYPE_TRANSACTION_CONTEXT);
        Object[] trxContextData = new Object[] {
                TransactionConstants.DEFAULT_CONTEXT_VERSION, transactionLocalContext.getGlobalTransactionId(),
                transactionBlockId.getValue(), transactionLocalContext.getProtocol(), transactionLocalContext.getURL()
        };
        return ValueCreator.createRecordValue(trxContext, trxContextData);
    }

    public static void createTrxContextFromGlobalID(Environment env) {
        TransactionLocalContext transactionLocalContext = recreateTrxContext(env);
        TransactionResourceManager.getInstance().setCurrentTransactionContext(transactionLocalContext);
    }

    private static TransactionLocalContext recreateTrxContext(Environment env) {
        String gTransactionId = (String) env.getStrandLocal(GLOBAL_TRANSACTION_ID);
        if (gTransactionId == null) {
            // No transaction available to participate,
            // We have no business here. This is a no-op.
            throw ErrorCreator.createError(StringUtils.fromString("No transaction is available to participate"));
        }
        String trxJsonString = env.getStrandLocal(TRANSACTION_INFO).toString();
        BMap infoRecord = null;
        if (!trxJsonString.isEmpty()) {
            BArray infoArr = (BArray) JsonUtils.parse(trxJsonString);
            infoRecord = recreateInfoRecord(env, infoArr);
        }

        // Create transaction context and store in the strand.
        TransactionLocalContext transactionLocalContext = TransactionLocalContext.create(gTransactionId,
                env.getStrandLocal(TRANSACTION_URL).toString(), DEFAULT_COORDINATION_TYPE, infoRecord);
        return transactionLocalContext;
    }

    private static Map reorderInfoRecord(Environment env, BArray infoArr, int j) {
        BMap info = (BMap) infoArr.get(j);
        Map<String, Object> infoUpdateMap = new HashMap<>();
        String xid = info.get(TransactionConstants.GLOBAL_TRX_ID).toString();
        byte[] xidArray = xid.getBytes(StandardCharsets.UTF_8);
        infoUpdateMap.put(TransactionConstants.GLOBAL_TRX_ID.getValue(), xidArray);
        infoUpdateMap.put(TransactionConstants.RETRY_NUMBER.getValue(),
                Integer.parseInt(info.get(TransactionConstants.RETRY_NUMBER).toString()));
        int startTimeInt = Integer.parseInt(info.get(TransactionConstants.START_TIME).toString());
        infoUpdateMap.put(TransactionConstants.START_TIME.getValue(), createTimeStampObject(env, startTimeInt));
        if (infoArr.getLength() - 1  > j) {
            infoUpdateMap.put(TransactionConstants.PREVIOUS_ATTEMPT.getValue(), reorderInfoRecord(env, infoArr, j++));
        }
        return infoUpdateMap;
    }

    private static BObject createTimeStampObject(Environment env, int startTime) {
        BObject startTimeObj = ValueCreator.createObjectValue(env.getCurrentModule(),
                STRUCT_TYPE_TIMESTAMP);
        startTimeObj.addNativeData(TransactionConstants.TIMESTAMP_OBJECT_VALUE_FIELD, startTime);
        return startTimeObj;
    }

    private static BMap recreateInfoRecord(Environment env, BArray infoArr) {
        Map infoMap = reorderInfoRecord(env, infoArr, 0);
        BMap<BString, Object> infoInternal = ValueCreator.createRecordValue(TRANSACTION_PACKAGE_ID,
                STRUCT_TYPE_TRANSACTION_INFO_INTERNAL);
        Object[] infoData = new Object[]{
                ValueCreator.createArrayValue((byte[]) infoMap.get(TransactionConstants.GLOBAL_TRX_ID.getValue())),
                infoMap.get(TransactionConstants.RETRY_NUMBER.getValue()),
                infoMap.get(TransactionConstants.PREVIOUS_ATTEMPT.getValue()),
                infoMap.get(TransactionConstants.START_TIME.getValue())};
        BMap<BString, Object> infoRecord = ValueCreator.createRecordValue(infoInternal, infoData);
        infoRecord.freezeDirect();
        return infoRecord;
    }

    public static Object registerLocalParticipant(Environment env, BString transactionBlockId,
                                                  BFunctionPointer fpCommitted, BFunctionPointer fpAborted) {
        TransactionLocalContext transactionLocalContext =
                TransactionResourceManager.getInstance().getCurrentTransactionContext();
        if (transactionLocalContext == null) {
            // No transaction available to participate,
            // We have no business here. This is a no-op.
            return null;
        }
        TransactionResourceManager transactionResourceManager = TransactionResourceManager.getInstance();

        // Register committed and aborted function handler if exists.
        transactionResourceManager.registerParticipation(transactionLocalContext.getGlobalTransactionId(),
                transactionBlockId.getValue());
        BMap<BString, Object> trxContext = ValueCreator.createRecordValue(env.getCurrentModule(),
                                                                                   STRUCT_TYPE_TRANSACTION_CONTEXT);
        Object[] trxContextData = new Object[] {
                TransactionConstants.DEFAULT_CONTEXT_VERSION, transactionLocalContext.getGlobalTransactionId(),
                transactionBlockId.getValue(), transactionLocalContext.getProtocol(), transactionLocalContext.getURL()
        };
        return ValueCreator.createRecordValue(trxContext, trxContextData);
    }

    public static void setTransactionContext(BMap txDataStruct, Object prevAttemptInfo) {
        String globalTransactionId = txDataStruct.get(TransactionConstants.TRANSACTION_ID).toString();
        String transactionBlockId = txDataStruct.get(TransactionConstants.TRANSACTION_BLOCK_ID).toString();
        String url = txDataStruct.get(TransactionConstants.REGISTER_AT_URL).toString();
        String protocol = txDataStruct.get(TransactionConstants.CORDINATION_TYPE).toString();
        long retryNmbr = getRetryNumber(prevAttemptInfo);
        BMap<BString, Object> trxContext = ValueCreator.createRecordValue(TRANSACTION_PACKAGE_ID,
                STRUCT_TYPE_TRANSACTION_INFO);
        Object[] trxContextData = new Object[]{
                ValueCreator.createArrayValue(globalTransactionId.getBytes(Charset.defaultCharset())), retryNmbr,
                System.currentTimeMillis(), prevAttemptInfo
        };
        BMap<BString, Object> infoRecord = ValueCreator.createRecordValue(trxContext, trxContextData);
        TransactionLocalContext trxCtx = TransactionLocalContext
                .createTransactionParticipantLocalCtx(globalTransactionId, url, protocol, infoRecord);
        trxCtx.beginTransactionBlock(transactionBlockId);
        TransactionResourceManager.getInstance().setCurrentTransactionContext(trxCtx);
    }

    private static long getRetryNumber(Object prevAttemptInfo) {
        if (prevAttemptInfo == null) {
            return 0;
        } else {
            Map<BString, Object> infoRecord = (Map<BString, Object>) prevAttemptInfo;
            Long retryNumber = (Long) infoRecord.get(StringUtils.fromString("retryNumber"));
            return retryNumber + 1;
        }
    }

    public static boolean isNestedTransaction() {
        TransactionLocalContext transactionLocalContext =
                TransactionResourceManager.getInstance().getCurrentTransactionContext();
        return transactionLocalContext != null;
    }

    public static BString getCurrentTransactionId() {

        String currentTransactionId = "";
        TransactionLocalContext transactionLocalContext =
                TransactionResourceManager.getInstance().getCurrentTransactionContext();
        if (transactionLocalContext != null) {
            currentTransactionId = transactionLocalContext.getGlobalTransactionId() + ":" + transactionLocalContext
                    .getCurrentTransactionBlockId();
        }
        return StringUtils.fromString(currentTransactionId);
    }

    public static boolean abortResourceManagers(BString transactionId, BString transactionBlockId) {
        return TransactionResourceManager.getInstance().notifyAbort(transactionId.getValue(),
                transactionBlockId.getValue());
    }

    public static boolean commitResourceManagers(BString transactionId, BString transactionBlockId) {
        return TransactionResourceManager
                .getInstance().notifyCommit(transactionId.getValue(), transactionBlockId.getValue());
    }

    public static boolean prepareResourceManagers(BString transactionId, BString transactionBlockId) {
        return TransactionResourceManager.getInstance().prepare(transactionId.getValue(),
                                                                transactionBlockId.getValue());
    }

    public static long getAvailablePort() {
        return findFreePort();
    }

    public static void onCommit(BFunctionPointer fpValue) {
        TransactionLocalContext transactionLocalContext =
                TransactionResourceManager.getInstance().getCurrentTransactionContext();
        TransactionResourceManager transactionResourceManager = TransactionResourceManager.getInstance();
        transactionResourceManager.registerCommittedFunction(transactionLocalContext.getGlobalTransactionId(),
                fpValue);
    }

    public static void onRollback(BFunctionPointer fpValue) {
        TransactionLocalContext transactionLocalContext =
                TransactionResourceManager.getInstance().getCurrentTransactionContext();
        TransactionResourceManager transactionResourceManager = TransactionResourceManager.getInstance();
        transactionResourceManager.registerAbortedFunction(transactionLocalContext.getGlobalTransactionId(),
                fpValue);
    }

    public static boolean isTransactional() {
        return TransactionResourceManager.getInstance().isInTransaction();
    }

    public static BMap<BString, Object> info() {
        if (isTransactional()) {
            TransactionLocalContext transactionLocalContext =
                    TransactionResourceManager.getInstance().getCurrentTransactionContext();
            return (BMap<BString, Object>) transactionLocalContext.getInfoRecord();
        }
        throw ErrorCreator.createError(StringUtils
                .fromString("cannot call info() if the strand is not in transaction mode"));
    }

    private static int findFreePort() {
        ServerSocket socket = null;
        try {
            socket = new ServerSocket(0);
            socket.setReuseAddress(true);
            int port = socket.getLocalPort();
            try {
                socket.close();
            } catch (IOException e) {
                // Ignore IOException on close()
            }
            return port;
        } catch (IOException ignored) {
        } finally {
            if (socket != null) {
                try {
                    socket.close();
                } catch (IOException ignored) {
                }
            }
        }
        throw new IllegalStateException("Could not find a free TCP/IP port");
    }

    public static BString getHostAddress() {
        return StringUtils.fromString(getLocalHostLANAddress().getHostAddress());
    }

    private static InetAddress getLocalHostLANAddress() throws RuntimeException {
        try {
            InetAddress candidateAddress = null;
            // Iterate all NICs (network interface cards)...
            for (Enumeration ifaces = NetworkInterface.getNetworkInterfaces(); ifaces.hasMoreElements(); ) {
                NetworkInterface iface = (NetworkInterface) ifaces.nextElement();
                // Iterate all IP addresses assigned to each card...
                for (Enumeration inetAddrs = iface.getInetAddresses(); inetAddrs.hasMoreElements(); ) {
                    InetAddress inetAddr = (InetAddress) inetAddrs.nextElement();
                    if (!inetAddr.isLoopbackAddress()) {

                        if (inetAddr.isSiteLocalAddress()) {
                            // Found non-loopback site-local address. Return it immediately...
                            return inetAddr;
                        } else if (candidateAddress == null) {
                            // Found non-loopback address, but not necessarily site-local.
                            // Store it as a candidate to be returned if site-local address is not subsequently found...
                            candidateAddress = inetAddr;
                            // Note that we don't repeatedly assign non-loopback non-site-local addresses as candidates,
                            // only the first. For subsequent iterations, candidate will be non-null.
                        }
                    }
                }
            }
            if (candidateAddress != null) {
                // We did not find a site-local address, but we found some other non-loopback address.
                // Server might have a non-site-local address assigned to its NIC (or it might be running
                // IPv6 which deprecates the "site-local" concept).
                // Return this non-loopback candidate address...
                return candidateAddress;
            }
            // At this point, we did not find a non-loopback address.
            // Fall back to returning whatever InetAddress.getLocalHost() returns...
            InetAddress jdkSuppliedAddress = InetAddress.getLocalHost();
            if (jdkSuppliedAddress == null) {
                throw new UnknownHostException("The JDK InetAddress.getLocalHost() method unexpectedly returned null.");
            }
            return jdkSuppliedAddress;
        } catch (Exception e) {
            throw new RuntimeException("Failed to determine LAN address: " + e, e);
        }
    }

    public static int getTransactionAutoCommitTimeout() {
        return TransactionResourceManager.getInstance().getTransactionAutoCommitTimeout();
    }

    public static int getTransactionCleanupTimeout() {
        return TransactionResourceManager.getInstance().getTransactionCleanupTimeout();
    }
}
