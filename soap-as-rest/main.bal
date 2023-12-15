import ballerina/http;
import ballerina/log;
import ballerina/soap.soap12;

xmlns "http://services.samples" as ns0;
xmlns "http://services.samples/xsd" as ns1;
xmlns "http://www.w3.org/2003/05/soap-envelope" as soapenv;

const NS1 = "http://services.samples/xsd";

final soap12:Client soapEP = check initializeSoapClient();

function initializeSoapClient() returns soap12:Client|soap12:Error => 
    new ("http://localhost:9000/services/SimpleStockQuoteService");

type Quote record {|
    decimal change;
    decimal earnings;
    decimal high;
    decimal last;
    decimal low;
    decimal marketCap;
    string name;
    decimal open;
    decimal peRatio;
    decimal percentageChange;
    decimal prevClose;
    string symbol;
    int volume;
|};

type Order record {|
    int quantity;
    string symbol;
|};

service /stockquote on new http:Listener(8080) {
    resource function get quote/[string symbol]() returns Quote|http:InternalServerError {
        xml payload = xml `<ns0:symbol>${symbol}</ns0:symbol>`;
        xml|soap12:Error response = soapEP->sendReceive(payload, "getQuote");

        if response is soap12:Error {
            log:printError("Failed to get quote", response);
            return <http:InternalServerError>{body: response.message()};
        }

        xml:Element quote =
            (response/**/<soapenv:Envelope>/<soapenv:Body>/<ns0:getQuoteResponse>).get(0);
        Quote|error quoteRecord = constructQuoteRecord(quote);
        if quoteRecord is Quote {
            return quoteRecord;
        }
        log:printError("Failed to transform XML payload to a record", quoteRecord);
        return <http:InternalServerError>{body: "failed to transform XML payload to a record"};
    }

    resource function post 'order(Order 'order) returns string|http:InternalServerError {
        xml|soap12:Error response = soapEP->sendReceive(
            xml `<ns0:placeOrder>
                    <ns0:order>
                        <ns0:quantity>${'order.quantity}</ns0:quantity>
                        <ns0:symbol>${'order.symbol}</ns0:symbol>
                    </ns0:order>
                </ns0:placeOrder>`, 
            "placeOrder"
        );

        if response is soap12:Error {
            log:printError("Failed to place order", response);
            return <http:InternalServerError>{body: response.message()};
        }

        xml:Element orderResponse =
            (response/**/<soapenv:Envelope>/<soapenv:Body>/<ns0:placeOrderResponse>).get(0);
        return (orderResponse/**/<ns1:status>).data();
    }
}

function constructQuoteRecord(xml:Element quote) returns Quote|error => {
    marketCap: check parseDecimalValue(quote, "marketCap"),
    symbol: (quote/**/<ns1:symbol>).data(),
    last: check parseDecimalValue(quote, "last"),
    percentageChange: check parseDecimalValue(quote, "percentageChange"),
    change: check parseDecimalValue(quote, "change"),
    prevClose: check parseDecimalValue(quote, "prevClose"),
    volume: check int:fromString((quote/**/<ns1:volume>).data()),
    earnings: check parseDecimalValue(quote, "earnings"),
    high: check parseDecimalValue(quote, "high"),
    peRatio: check parseDecimalValue(quote, "peRatio"),
    low: check parseDecimalValue(quote, "low"),
    name: (quote/**/<ns1:name>).data(),
    open: check parseDecimalValue(quote, "open")
};

function parseDecimalValue(xml:Element quote, string name) returns decimal|error {
    string mappedField = quote.elementChildren(string `{${NS1}}${name}`).data();
    return decimal:fromString(mappedField);
}
