//
//  AzureIoTSwiftViewController.swift
//  AzureIoTSwiftSample
//
//  Created by Dane Walton on 2/14/22.
//

import Foundation
import MQTT
import NIOSSL
import AzureSDKForCSwift

let sem = DispatchSemaphore(value: 0)
let queue = DispatchQueue(label: "a", qos: .background)

class AzureIoTHubClientSwift: MQTTClientDelegate, ObservableObject {
    
    private var iothub: String = ""
    private var deviceId: String = ""
    private var sasKey: String = ""
    
    private var connectionString: String = ""
    
    private(set) var numReceivedMessages: Int = 0
    
    @Published private(set) var numSentMessages: Int = 0
    @Published private(set) var numSentMessagesGood: Int = 0
    @Published private(set) var numSentMessagesBad: Int = 0
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isSendingTelemetry: Bool = false
    
    private(set) var lastTempValue : String = ""
    private(set) var lastHumidityValue : String = ""
    @Published private(set) var telemetryMessage : String = ""
    
    // Timers used to control message and polling rates
    var timerMsgRate: Timer!
    var timerDoWork: Timer!
    
    // IoT hub handle
    private var azIoTHubClient: az_iot_hub_client!

    // MQTT Client
    private var mqttClient: MQTTClient
    
    var delegateDispatchQueue: DispatchQueue {
        queue
    }

    init(iothub: String, deviceId: String)
    {
        self.iothub = iothub
        self.deviceId = deviceId
        
        let caCert = Bundle.main.path(forResource: "baltimore",
                                      ofType: ".pem",
                                      inDirectory: "certs/")!
        let clientCert = Bundle.main.path(forResource: "client",
                                          ofType: ".pem",
                                          inDirectory: "certs/")!
        let keyCert = Bundle.main.path(forResource: "client-key",
                                       ofType: ".pem",
                                       inDirectory: "certs/")!
        let tlsConfiguration = try! TLSConfiguration.forClient(minimumTLSVersion: .tlsv11,
                                                               maximumTLSVersion: .tlsv12,
                                                               certificateVerification: .noHostnameVerification,
                                                               trustRoots: NIOSSLTrustRoots.certificates(NIOSSLCertificate.fromPEMFile(caCert)),
                                                               certificateChain: NIOSSLCertificate.fromPEMFile(clientCert).map { .certificate($0) },
                                                               privateKey: .privateKey(.init(file: keyCert, format: .pem)))
        mqttClient = MQTTClient(
            host: "\(self.iothub)",
            port: 8883,
            clientID: "\(self.deviceId)",
            cleanSession: true,
            keepAlive: 30,
            username: "dawalton-hub.azure-devices.net/ios/?api-version=2018-06-30",
            password: "",
            tlsConfiguration: tlsConfiguration
        )
        mqttClient.tlsConfiguration = tlsConfiguration
        mqttClient.delegate = self
    }
    
/// Needed Functions for MQTTClientDelegate
    
    func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket) {
        switch packet {
        case let packet as ConnAckPacket:
            print("Connack \(packet)")
            isConnected = true;
        default:
            print(packet)
        }
    }

    func mqttClient(_: MQTTClient, didChange state: ConnectionState) {
        if state == .disconnected {
            sem.signal()
        }
        print(state)
    }

    func mqttClient(_: MQTTClient, didCatchError error: Error) {
        print("Error: \(error)")
    }
    
    private func connectionStringCreateFromSAS() -> String {
        return "HostName=\(iothub);DeviceId=\(deviceId);SharedAccessKey=\(sasKey)"
    }
    
    private func incReceivedMessage() {
        numReceivedMessages += 1
    }
    
    private func incSentMessagesGood() {
        numSentMessagesGood += 1
    }
    
    private func incSentMessagesBad() {
        numSentMessagesBad += 1
    }
    
    private func createTelemetryMessage() -> String {
        let temperature = String(format: "%.2f",drand48() * 15 + 20)
        let humidity = String(format: "%.2f", drand48() * 20 + 60)
        let data : [String : String] = ["temperature":temperature,
                                    "humidity": humidity]
        lastTempValue = data["temperature"]!
        lastHumidityValue = data["humidity"]!
        
        return data.description
    }
    
    /// Sends a message to the IoT hub
    @objc private func sendMessage() {

        // This the message
        telemetryMessage = createTelemetryMessage()

        var topicCharArray = [CChar](repeating: 0, count: 100)
        var topicLength : Int = 0
        
//        let _ : az_result = az_iot_hub_client_telemetry_get_publish_topic(UnsafeMutablePointer<az_iot_hub_client>(&self.azIoTHubClient), nil, UnsafeMutablePointer<CChar>(mutating: topicCharArray), 100, &topicLength )
        
        print("Send a message")
        mqttClient.publish(topic: "devices/ios/messages/events/", retain: false, qos: QOS.0, payload: "Hello iOS")
    }
    
    @objc private func doWork() {
        print("Doing work")
        
    }

    func connect() throws {
        mqttClient.connect()
    }
    
    //Connect the device to iothub
    func connectToIoTHub() {
        
        do
        {
            try self.connect()
        }
        catch
        {
            print("Coulnd't connect")
        }
        
    }
    
    func disconectFromIoTHub() {
        stopSendTelemetryMessages()

        isConnected = false
    }
    
    func startSendTelemetryMessages() {
        // Timer for message sends and timer for message polls
        if(isConnected)
        {
            isSendingTelemetry = true
            timerMsgRate = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(sendMessage), userInfo: nil, repeats: true)
        }
    }
    
    func stopSendTelemetryMessages() {
        isSendingTelemetry = false
        if(timerMsgRate.isValid) {
            timerMsgRate.invalidate()
        }
    }
}
