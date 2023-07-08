//
//  APNsSender.swift
//  LifespanTester
//
//  Created by Dan Crosby on 7/8/23.
//

import Foundation
import CommonCrypto

extension Data {
    func base64EncodedURLString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}

struct APNsSecretInfo : Decodable {
    let keyId: String
    let asnKeyBase64EncodedData: String
    let deviceToken: String
    let teamId: String
    
    public static let shared: APNsSecretInfo = makeSecretInfo()!
    
    private static func makeSecretInfo() -> APNsSecretInfo? {
        guard let secretDataURL = Bundle.main.url(forResource: "APNsSecretData", withExtension: "json") else {
            print("Unable to get URL for APNsSecretData")
            return nil
        }
        guard let secretData = try? Data(contentsOf: secretDataURL) else {
            print("Unable to load contents of APNsSecretData")
            return nil
        }
        guard let secretInfo = try? JSONDecoder().decode(APNsSecretInfo.self, from: secretData) else {
            print("Unable to decode APNsSecretData")
            return nil
        }
        
        return secretInfo
    }
}

class APNsSender : NSObject {
    static private let secretInfo = APNsSecretInfo.shared
    
    static let alg = "ES256"
    static let header = ["alg" : alg, "kid" : secretInfo.keyId]
    static let headerString = try! JSONEncoder().encode(header).base64EncodedURLString()
    
    static let signingKey = makeSigningKey()!
    
    static private func makeSigningKey() -> SecKey? {
        guard let asnKeyData = Data(base64Encoded: secretInfo.asnKeyBase64EncodedData) else {
            print("Unable to decode asn key data")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        let keyParams: [CFString : Any] = [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                                          kSecAttrKeyClass: kSecAttrKeyClassPrivate,
                                     kSecAttrKeySizeInBits: 256]
        let key = SecKeyCreateWithData(asnKeyData as CFData,
                                       keyParams as CFDictionary,
                                       &error)!
        
        return key
    }
    
    static public func digest() -> String {
        let issueDate = NSDate().timeIntervalSince1970.rounded()
        let payload: [String : Any] = ["iss" : secretInfo.teamId, "iat" : issueDate]
        
        let payloadString = try! JSONSerialization.data(withJSONObject: payload, options: []).base64EncodedURLString()
        
        let digest = "\(headerString).\(payloadString)"
        return digest
    }
    
    static public func signature(_ digest: String) -> String? {
        let message = digest.data(using: .utf8)!
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256((message as NSData).bytes, CC_LONG(message.count), &hash)
        let digestData = Data(hash)
        
        let algorithm = SecKeyAlgorithm.ecdsaSignatureDigestX962SHA256
        
        var error: Unmanaged<CFError>?
        
        let signature = SecKeyCreateSignature(signingKey, algorithm, digestData as CFData, &error)! as Data
        
        // Break up the signature into left and right pieces
        guard signature[0] == 0x30 else {
            print("Signature should be an ASN1 sequence")
            return nil
        }
        guard signature[1] == signature.count - 2 else {
            print("Invalid length in signature")
            return nil
        }
        guard signature[2] == 0x02 else {
            print("Next element should be an integer")
            return nil
        }
        let leftLength = Int(signature[3])
        let leftS = leftLength == 33 ? signature[4..<leftLength + 4].dropFirst() : signature[4..<leftLength + 4]
        
        guard signature[leftLength + 4] == 0x02 else {
            print("Next element should be an integer")
            return nil
        }
        let rightLength = Int(signature[leftLength + 5])
        let rightS = rightLength == 33 ? signature[(leftLength + 6)...].dropFirst() : signature[(leftLength + 6)...]
        
        let rawSignature = leftS + rightS
        
        return rawSignature.base64EncodedURLString()
    }
    
    static func authorizationToken() -> String? {
        let d = digest()
        guard let sig = signature(d) else {
            print("Unable to get signature!")
            return nil
        }
        return "\(d).\(sig)"
    }
    
    func send(timestamp: String, timeInSeconds: Int, steps: Int, distanceInMiles: Double, calories: Int, to deviceToken: String) {
        let dict: [String : Any] = [
            "timestamp" : timestamp,
            "timeInSeconds" : timeInSeconds,
            "steps" : steps,
            "distanceInMiles" : distanceInMiles,
            "calories" : calories
        ]
        
        send(dict)
    }
    
    func send(_ newValue: [String: Any]) {
        let url = URL(string: "https://api.development.push.apple.com/3/device/\(APNsSecretInfo.shared.deviceToken)")!
        guard let authToken = APNsSender.authorizationToken() else {
            print("Unable to get auth token")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("bearer \(authToken)", forHTTPHeaderField: "authorization")
        request.setValue("background", forHTTPHeaderField: "apns-push-type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "apns-id")
        request.setValue("5", forHTTPHeaderField: "apns-priority")
        request.setValue("com.dancrosby.LifeSpan-Sync", forHTTPHeaderField: "apns-topic")
        
        let aps = ["aps": ["content-available": 1] ].merging(newValue) { (a, b) in a }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: aps)
        
        let task = URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse else {
                print("Not an HTTPURLResponse")
                return
            }
            guard (200...299).contains(response.statusCode) else {
                print ("server error \(String(describing: response))")
                return
            }
        }
        task.resume()
    }
}
