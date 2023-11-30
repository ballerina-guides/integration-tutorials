import ballerina/http;
import ballerinax/rabbitmq;

configurable string queueName = "ReservationQueue";

final rabbitmq:Client rabbitmqClient = check new (rabbitmq:DEFAULT_HOST, rabbitmq:DEFAULT_PORT);

service /healthcare on new http:Listener(8290) {
    function init() returns error? {
        check rabbitmqClient->queueDeclare(queueName);
    }

    resource function post categories/[string category]/reserve(ReservationRequest request)
                    returns http:Created|http:InternalServerError {

        rabbitmq:Error? response = rabbitmqClient->publishMessage({content: {...request, category}, routingKey: queueName});

        if response is rabbitmq:Error {
            return <http:InternalServerError>{};
        }

        return <http:Created>{};
    }
}
