/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.stdlib.transaction;

//import io.ballerina.runtime.api.creators.ErrorCreator;
//import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.transactions.TransactionResourceManager;

/**
 * Extern function transaction:rollbackTransaction.
 *
 * @since Swan Lake
 */
public class RollbackTransaction {

    public static void rollbackTransaction(BString transactionBlockId, Object err) {
        TransactionResourceManager trxResourceMng = TransactionResourceManager.getInstance();
        if (trxResourceMng.isInTransaction()) {
            trxResourceMng.rollbackTransaction(transactionBlockId.getValue(), err);
        } else {
            throw ErrorCreator.createError(StringUtils
                    .fromString("cannot call rollback if the strand is not in transaction mode"));
        }
    }
}
