//
//  ContentView.swift
//  Shared
//
//  Created by Dane Walton on 2/14/22.
//

import SwiftUI

private var myDeviceId: String = "ios"
private var myHubURL: String = "dawalton-hub.azure-devices.net"

struct iotDemoView: View {
    @ObservedObject var myHubClient = AzureIoTHubClientSwift(iothub: myHubURL, deviceId: myDeviceId)
    
    var body: some View {
        VStack {
            Group {
                HStack {
                    Text("Azure C SDK on iOS")
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(/*@START_MENU_TOKEN@*/Color(hue: 0.66, saturation: 0.97, brightness: 0.664)/*@END_MENU_TOKEN@*/)
                        .padding()
                    Spacer()
                }
                Divider()
                authenticationItems(hubClient: myHubClient)
                Divider()
                metricsItems(hubClient: myHubClient)
                Divider()
                Spacer()
            }
        }
    }
}

struct authenticationItems: View {
    @ObservedObject var hubClient: AzureIoTHubClientSwift
    var body: some View {
        HStack {
            Text("Scan for SAS Key").padding()
            Spacer()
            Button(action: {
                print("Scan selected")
            }, label: {
                Text("Scan")
            }).padding()
        }
        Divider()
        HStack {
            Text("Connect to IoT Hub").padding()
            Spacer()
            Button(action: {
                if(hubClient.isConnected)
                {
                    hubClient.disconectFromIoTHub()
                } else {
                    hubClient.connectToIoTHub()
                }
            }, label: {
                if(hubClient.isConnected)
                {
                    Text("Disconnect")
                } else {
                    Text("Connect")
                }
            }).padding()
        }
        HStack {
            Text("Connection Status").padding()
            Spacer()
            if(hubClient.isConnected) {
                Text("Connected").foregroundColor(Color.green).padding()
            } else {
                Text("Disconnected").foregroundColor(Color.red).padding()
            }
        }
    }
}

struct metricsItems: View {
    @State private var isSendingTelemetryButtonText: String = "Start"
    @State private var methodName = "nil"
    
    @ObservedObject var hubClient: AzureIoTHubClientSwift

    var body: some View {
        HStack {
            Text("Send Telemetry").padding()
            Spacer()
            Button(action: {
                if(hubClient.isSendingTelemetry) {
                    print("Stopping Telemetry")
                    isSendingTelemetryButtonText = "Start"
                    hubClient.stopSendTelemetryMessages()
                }
                else {
                    print("Starting Telemetry")
                    isSendingTelemetryButtonText = "Stop"
                    hubClient.startSendTelemetryMessages()
                }
            }, label: {
                Text("\(isSendingTelemetryButtonText)")
            }).padding()
        }
        HStack {
            Text("Last Sent Message").padding()
            Spacer()
            Text("<\(hubClient.telemetryMessage)>").padding()
        }
        HStack {
            Text("Messages Sent").padding()
            Spacer()
            VStack {
                Text("Sent")
                Text("\(hubClient.numSentMessages)")
            }.padding()
            VStack {
                Text("+")
                    .foregroundColor(Color.green)
                Text("\(hubClient.numSentMessagesGood)")
                    .foregroundColor(Color.green)
            }.padding()
            VStack {
                Text("-")
                    .foregroundColor(Color.red)
                Text("\(hubClient.numSentMessagesBad)")
                    .foregroundColor(Color.red)
            }.padding()
        }
    }
}

//struct ContentView: View {
//    var body: some View {
//        Text("Hello, world!")
//            .padding()
//    }
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        iotDemoView()
    }
}
