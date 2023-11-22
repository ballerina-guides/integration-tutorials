import ballerina/http;
import ballerinax/rabbitmq;

type Patient record {
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
};

type ReservationRequest record {|
    Patient patient;
    string doctor;
    string hospital_id;
    string hospital;
    string appointment_date;
|};

const queueName = "ReservationQueue";
const exchangeName = "ReservationExchange";

final rabbitmq:Client rabbitmqClient = check new (rabbitmq:DEFAULT_HOST, rabbitmq:DEFAULT_PORT);

service /healthcare on new http:Listener(8290) {
    function init() returns error? {
        check rabbitmqClient->exchangeDeclare(exchangeName, rabbitmq:DIRECT_EXCHANGE);
        check rabbitmqClient->queueDeclare(queueName);
    }

    resource function post categories/[string category]/reserve(ReservationRequest request)
                    returns http:Created|http:InternalServerError {
        do {
            check rabbitmqClient->publishMessage({content: {...request, category}, routingKey: queueName});
            return <http:Created>{};
        } on fail {
            return <http:InternalServerError>{};
        }
    }
}
