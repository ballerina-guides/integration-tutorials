import ballerina/http;
import ballerina/log;
import ballerina/mime;

xmlns "http://services.samples" as ns0;
xmlns "http://services.samples/xsd" as ns1;

configurable int port = 9000;

enum SoapVersion {
    ONE_ONE,
    ONE_TWO
}

const string GET_QUOTE = "getQuote";
const string PLACE_ORDER = "placeOrder";

service /services on new http:Listener(port) {
    resource function default [string... paths](
            @http:Header {name: "SOAPAction"} string? soapActionHeader, 
            @http:Header {name: mime:CONTENT_TYPE} string? contentTypeHeader, 
            xml payload) returns xml|http:BadRequest {

        SoapVersion soapVersion;
        string soapAction;

        if soapActionHeader !is () {
            soapVersion = ONE_ONE;
            soapAction = soapActionHeader;
        } else if contentTypeHeader !is () {
            soapVersion = ONE_TWO;
            string? soap12Action = getSoap12Action(contentTypeHeader);
            if soap12Action is () {
                log:printError("invalid request, cannot find SOAP action");
                return {body: "expected a SOAP request"};
            }
            soapAction = soap12Action;
        } else {
            log:printError("invalid request, cannot find SOAP action");
            return {body: "expected a SOAP request"};
        }

        match soapAction {
            GET_QUOTE => {
                string company = (payload.<ns0:symbol>).data();
                return getQuote(company, soapVersion);
            }
            PLACE_ORDER => {
                string company = (payload.<ns0:symbol>).data();
                return placeOrder(company, soapVersion);
            }
        }

        log:printError("unknown SOAP action", action = soapAction);
        return getFaultResponseForUnknownSOAPAction(soapAction, soapVersion);
    }
}

function getSoap12Action(string contentTypeHeader) returns string? {
    mime:MediaType|mime:InvalidContentTypeError mediaHeader = 
        mime:getMediaType(contentTypeHeader);
    if mediaHeader is mime:InvalidContentTypeError {
        return ();
    }
    map<string> actionMap = mediaHeader.parameters;
    return actionMap["action"];
}

function getQuote(string company, SoapVersion soapVersion) returns xml {
    if company.trim().length() == 0 {
        return getFaultResponseForEmptyCompany(soapVersion);
    }

    xml body = xml `<ns0:getQuoteResponse>
                        <ns1:change>-2.86843917118114</ns1:change>
                        <ns1:earnings>-8.540305401672558</ns1:earnings>
                        <ns1:high>-176.67958828498735</ns1:high>
                        <ns1:last>177.66987465262923</ns1:last>
                        <ns1:low>-176.30898912339075</ns1:low>
                        <ns1:marketCap>5.649557998178506E7</ns1:marketCap>
                        <ns1:name>${company} Company</ns1:name>
                        <ns1:open>185.62740369461244</ns1:open>
                        <ns1:peRatio>24.341353665128693</ns1:peRatio>
                        <ns1:percentageChange>-1.4930577008849097</ns1:percentageChange>
                        <ns1:prevClose>192.11844053187397</ns1:prevClose>
                        <ns1:symbol>${company}</ns1:symbol>
                        <ns1:volume>7791</ns1:volume>
                    </ns0:getQuoteResponse>`;
    if soapVersion == ONE_ONE {
        xmlns "http://schemas.xmlsoap.org/soap/envelope/" as soapenv;
        return xml `<soapenv:Envelope><soapenv:Body>${body}</soapenv:Body></soapenv:Envelope>`;
    }

    xmlns "http://www.w3.org/2003/05/soap-envelope" as soapenv;
    return xml `<soapenv:Envelope><soapenv:Body>${body}</soapenv:Body></soapenv:Envelope>`;
}

function placeOrder(string company, SoapVersion soapVersion) returns xml {
    if company.trim().length() == 0 {
        return getFaultResponseForEmptyCompany(soapVersion);
    }

    xml body = xml `<ns0:placeOrderResponse>
                        <ns1:status>created</ns1:status>
                    </ns0:placeOrderResponse>`;

    if soapVersion == ONE_ONE {
        xmlns "http://schemas.xmlsoap.org/soap/envelope/" as soapenv;
        return xml `<soapenv:Envelope><soapenv:Body>${body}</soapenv:Body></soapenv:Envelope>`;
    }
    xmlns "http://www.w3.org/2003/05/soap-envelope" as soapenv;
    return xml `<soapenv:Envelope><soapenv:Body>${body}</soapenv:Body></soapenv:Envelope>`;
}

function getFaultResponseForEmptyCompany(SoapVersion soapVersion) returns xml {
    if soapVersion == ONE_ONE {
        return xml `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope">
                        <soapenv:Body>
                            <soapenv:Fault>
                                <faultcode>soapenv:Client</faultcode>
                                <faultstring xml:lang="en">Company name cannot be empty</faultstring>
                            </soapenv:Fault>
                        </soapenv:Body>
                    </soapenv:Envelope>`;
    }

    return xml `<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope">
                    <soapenv:Body>
                        <soapenv:Fault>
                            <soapenv:Code>
                                <soapenv:Value>env:Sender</soapenv:Value>
                            </soapenv:Code>
                            <soapenv:Reason>
                                <soapenv:Text xml:lang="en-US">Company name cannot be empty</soapenv:Text>
                            </soapenv:Reason>
                        </soapenv:Fault>
                    </soapenv:Body>
                </soapenv:Envelope>`;
}

function getFaultResponseForUnknownSOAPAction(string soapAction, SoapVersion soapVersion) returns xml {
    if soapVersion == ONE_ONE {
        return xml `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope">
                        <soapenv:Body>
                            <soapenv:Fault>
                                <faultcode>soapenv:Client</faultcode>
                                <faultstring xml:lang="en">Unknown SOAP Action ${soapAction}</faultstring>
                            </soapenv:Fault>
                        </soapenv:Body>
                    </soapenv:Envelope>`;
    }

    return xml `<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope">
                    <soapenv:Body>
                        <soapenv:Fault>
                            <soapenv:Code>
                                <soapenv:Value>env:Sender</soapenv:Value>
                            </soapenv:Code>
                            <soapenv:Reason>
                                <soapenv:Text xml:lang="en-US">Unknown SOAP Action ${soapAction}</soapenv:Text>
                            </soapenv:Reason>
                        </soapenv:Fault>
                    </soapenv:Body>
                </soapenv:Envelope>`;
}
