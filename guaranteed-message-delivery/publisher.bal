import ballerina/http;
import ballerina/log;
import ballerinax/rabbitmq;

configurable string queueName = "ReservationQueue";

final rabbitmq:Client rabbitmqClient = check initializeRabbitMqClient();

function initializeRabbitMqClient() returns rabbitmq:Client|error => new (rabbitmq:DEFAULT_HOST, rabbitmq:DEFAULT_PORT);

service /healthcare on new http:Listener(8290) {
    function init() returns error? {
        return rabbitmqClient->queueDeclare(queueName);
    }

    resource function post categories/[string category]/reserve(ReservationRequest request)
                    returns http:Created|http:InternalServerError {
        rabbitmq:Error? response = rabbitmqClient->publishMessage({
            content: {
                patient: request.patient,
                doctor: request.doctor,
                hospital_id: request.hospital_id,
                hospital: request.hospital,
                appointment_date: request.appointment_date,
                category
            },
            routingKey: queueName
        });

        if response is rabbitmq:Error {
            log:printError("Failed to publish to the message broker", patient = request.patient.name,
                                                                      doctor = request.doctor,
                                                                      hospital = request.hospital);
            return <http:InternalServerError>{body: response.message()};
        }

        return http:CREATED;
    }
}
