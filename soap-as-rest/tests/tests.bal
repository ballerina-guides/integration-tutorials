import ballerina/http;
import ballerina/mime;
import ballerina/soap.soap12;
import ballerina/test;

type Xml xml;

const string GET_QUOTE = "getQuote";
const string PLACE_ORDER = "placeOrder";

final http:Client cl = check new ("http://localhost:8080");

@test:Config
function testGetQuote() returns error? {
    Quote quote = check cl->/stockquote/quote/ABC;
    test:assertEquals(quote, getExpectedQuotePayload("ABC"));
}

@test:Config
function testPostOrder() returns error? {
    string orderStatus = check cl->/stockquote/'order.post({quantity: 12, symbol: "ABC"});
    test:assertEquals("created", orderStatus);
}

public client class MockSoapClient {
    remote isolated function sendReceive(xml|mime:Entity[] body,
            string? action = (),
            map<string|string[]> headers = {},
            string path = "",
            typedesc<xml|mime:Entity[]> T = Xml)
            returns xml|mime:Entity[]|soap12:Error {
        if body !is xml {
            return error("expected an XML body");
        }

        if action is () {
            return error("expected the SOAP action");
        }

        match action {
            GET_QUOTE => {
                string company = (body.<ns0:symbol>).data();
                return getQuote(company);
            }
            PLACE_ORDER => {
                string company = (body.<ns0:symbol>).data();
                return placeOrder(company);
            }
        }
        return error("unknown action: " + action);
    }
}

@test:Mock {
    functionName: "initializeSoapClient"
}
function initializeSoapClientMock() returns soap12:Client|soap12:Error =>
    test:mock(soap12:Client, new MockSoapClient());

isolated function getQuote(string company) returns xml =>
    xml `<soapenv:Envelope>
            <soapenv:Body>
                <ns0:getQuoteResponse>
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
                </ns0:getQuoteResponse>
            </soapenv:Body>
        </soapenv:Envelope>`;

isolated function placeOrder(string company) returns xml =>
    xml `<soapenv:Envelope>
            <soapenv:Body>
                <ns0:placeOrderResponse>
                    <ns1:status>created</ns1:status>
                </ns0:placeOrderResponse>
            </soapenv:Body>
        </soapenv:Envelope>`;

function getExpectedQuotePayload(string symbol) returns Quote => {
    marketCap: 5.649557998178506E7,
    symbol,
    last: 177.66987465262923,
    percentageChange: -1.4930577008849097,
    change: -2.86843917118114,
    prevClose: 192.11844053187397,
    volume: 7791,
    earnings: -8.540305401672558,
    high: -176.67958828498735,
    peRatio: 24.341353665128693,
    low: -176.30898912339075,
    name: string `${symbol} Company`,
    open: 185.62740369461244
};
