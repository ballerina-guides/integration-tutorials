/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.example;

import com.icegreen.greenmail.util.GreenMail;
import com.icegreen.greenmail.util.ServerSetupTest;

import javax.mail.MessagingException;
import javax.mail.internet.MimeMessage;

/**
 * 
 *
 * @since slp9
 */
public class SmtpServer {

    private static final String USER_PASSWORD = "abcdef123";
    private static final String USER_NAME = "hascode";
    private static final String EMAIL_USER_ADDRESS_1 = "hascode1@localhost";
    private static GreenMail mailServer;

    public static Object startSendWithOptionsSmtpServer() {
        mailServer = new GreenMail(ServerSetupTest.SMTP);
        mailServer.start();
        mailServer.setUser(EMAIL_USER_ADDRESS_1, USER_NAME, USER_PASSWORD);
        return null;
    }

    public static Object stopSendWithOptionsSmtpServer() {
        mailServer.stop();
        return null;
    }

    public static Object validateComplexEmails() throws Exception {
        MimeMessage[] messages = mailServer.getReceivedMessages();
        return null;
    }
}
