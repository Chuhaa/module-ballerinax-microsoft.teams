// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;

isolated function getChannelResources(http:Client httpClient, string url) returns ChannelData[]|error {
    http:Response response = check httpClient->get(url);
    map<json> handledResponse = check handleResponse(response);
    return check handledResponse[VALUE_ARRAY].cloneWithType(ChannelDataArray);
}

isolated function createChannelResource(http:Client httpClient, string url, Channel info) returns 
                                        ChannelData|error {
    json payload = check info.cloneWithType(json);
    return check httpClient->post(url, payload, targetType = ChannelData);
}

isolated function updateChannelResource(http:Client httpClient, string url, Channel info) returns error? {
    json payload = check info.cloneWithType(json);
    http:Response response = check httpClient->patch(url, payload);
    _ = check handleResponse(response);
}

isolated function addChannelMember(http:Client httpClient, string url, string userId, string role) returns 
                                   MemberData|error {
    json payload = {
        "@odata.type": "#microsoft.graph.aadUserConversationMember",
        roles: [role],
        "user@odata.bind": string `https://graph.microsoft.com/v1.0/users('${userId}')`
    };
    return check httpClient->post(url, payload, targetType = MemberData);
}

isolated function listChannelMembersResource(http:Client httpClient, string url) returns MemberData[]|error {
    http:Response response = check httpClient->get(url);
    map<json> handledResponse = check handleResponse(response);
    return check handledResponse[VALUE_ARRAY].cloneWithType(MemberDataArray);
}

isolated function deleteChannelMemberResource(http:Client httpClient, string url) returns error? {
    http:Response response = check httpClient->delete(url);
    _ = check handleResponse(response);
}

isolated function sendMessageToChannel(http:Client httpClient, string url, Message message) returns 
                                       MessageData|error {
    json payload = check message.cloneWithType(json);
    return check httpClient->post(url, payload, targetType = MessageData);
}

isolated function sendReplyToChannel(http:Client httpClient, string url, Message reply) returns 
                                     MessageData|error {
    json payload = check reply.cloneWithType(json);
    return check httpClient->post(url, payload, targetType = MessageData);       
}

isolated function deleteChannelResource(http:Client httpClient, string url) returns error? {
    http:Response response = check httpClient->delete(url);
    _ = check handleResponse(response);
}
