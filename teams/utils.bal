import ballerina/http;

isolated function createUrl(string[] pathParameters, string[] queryParameters = []) returns string|error {
    string url = EMPTY_STRING;
    if (pathParameters.length() > ZERO) {
        foreach string element in pathParameters {
            if (!element.startsWith(FORWARD_SLASH)) {
                url = url + FORWARD_SLASH;
            }
            url += element;
        }
    }
    if (queryParameters.length() > ZERO) {
        url = url + check appendQueryOption(queryParameters[ZERO], QUESTION_MARK);
        foreach string element in queryParameters.slice(1, queryParameters.length()) {
            url += check appendQueryOption(element, AMPERSAND);
        }
    }
    return url;
}

isolated function appendQueryOption(string queryParameter, string connectingString) returns string|Error {
    string url = EMPTY_STRING;
    int? indexOfEqual = queryParameter.indexOf(EQUAL_SIGN);
    if (indexOfEqual is int) {
        string queryOptionName = queryParameter.substring(ZERO, indexOfEqual);
        string queryOptionValue = queryParameter.substring(indexOfEqual);
        if (queryOptionName.startsWith(DOLLAR_SIGN)) {
            if (validateOdataSystemQueryOption(queryOptionName.substring(1), queryOptionValue)) {
                url += connectingString + queryParameter;
            } else {
                return error QueryParameterValidationError(INVALID_QUERY_PARAMETER);
            }
        } else {
            // non odata query parameters
            url += connectingString + queryParameter;
        }
    } else {
        return error QueryParameterValidationError(INVALID_QUERY_PARAMETER);
    }
    return url;
}

isolated function validateOdataSystemQueryOption(string queryOptionName, string queryOptionValue) returns boolean {
    boolean isValid = false;
    string[] characterArray = [];
    if (queryOptionName is SystemQueryOption) {
        isValid = true;
    } else {
        return false;
    }
    foreach string character in queryOptionValue {
        if (character is OpeningCharacters) {
            characterArray.push(character);
        } else if (character is ClosingCharacters) {
            _ = characterArray.pop();
        }
    }
    if (characterArray.length() == ZERO){
        isValid = true;
    }
    return isValid;
}

isolated function handleResponse(http:Response httpResponse) returns map<json>|Error? {
    if (httpResponse.statusCode is http:STATUS_ACCEPTED|http:STATUS_OK|http:STATUS_CREATED) {
        json jsonResponse = check httpResponse.getJsonPayload();
        return <map<json>>jsonResponse;
    } else if (httpResponse.statusCode is http:STATUS_NO_CONTENT) {
        return;
    }
    json errorPayload = check httpResponse.getJsonPayload();
    string message = errorPayload.toString();
    return error PayloadValidationError(message);
}

isolated function handleAsyncResponse(http:Client httpClient, http:Response httpResponse) returns string|Error {
    if (httpResponse.statusCode is http:STATUS_ACCEPTED) {
        string locationHeader = check httpResponse.getHeader(http:LOCATION);
        return check getasyncJobStatus(httpClient, <@untainted>locationHeader); 
    }
    json errorPayload = check httpResponse.getJsonPayload();
    string message = errorPayload.toString(); // Error should be defined as a user defined object
    return error PayloadValidationError(message);
}

isolated function getasyncJobStatus(http:Client httpClient, string monitorUrl) returns string|Error {
    http:Response response = check httpClient->get(monitorUrl);
    if (response.statusCode is http:STATUS_OK|http:STATUS_ACCEPTED|http:REDIRECT_SEE_OTHER_303) {
        json jsonResponse = check response.getJsonPayload();
        TeamsAsyncOperation asyncStatus = check jsonResponse.cloneWithType(TeamsAsyncOperation);
        if (asyncStatus.status == SUCCEEDED) {
            return asyncStatus.targetResourceId;
        } else if (asyncStatus.status == FAILED) {
            return error AsyncRequestFailedError("", code = "");
        } else {
            return check getasyncJobStatus(httpClient, monitorUrl);
        }
    }
    json errorPayload = check response.getJsonPayload();
    string message = errorPayload.toString(); // Error should be defined as a user defined object
    return error PayloadValidationError(message);
}
