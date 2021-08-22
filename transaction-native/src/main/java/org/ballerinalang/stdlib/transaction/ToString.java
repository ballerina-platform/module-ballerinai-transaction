/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.stdlib.transaction;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Implementation of transaction.Timestamp:toString().
 *
 * @since 2.0.0
 */
public class ToString {

    public static BString toString(BObject m) {
        //TODO: Sometimes the timeValue is Integer sometimes it is a Long. it should be a Long always. Need to fix
        Number timeValue = (Number) m.getNativeData("timeValue");
        Date date = new Date(timeValue.longValue());
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss,SSS");
        String dateAsString = simpleDateFormat.format(date);
        return StringUtils.fromString(dateAsString);
    }
}
