//
//  Address.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/01/31.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// A Bitcoin address looks like 1MsScoe2fTJoq4ZPdQgqyhgWeoNamYPevy and is derived from an elliptic curve public key
/// plus a set of network parameters.
/// A standard address is built by taking the RIPE-MD160 hash of the public key bytes, with a version prefix and a
/// checksum suffix, then encoding it textually as base58. The version prefix is used to both denote the network for
/// which the address is valid.
public struct Address {
    public typealias Base58Check = String
    
    let network: Network

    let publicKeyHash: Data
    let base58: Base58Check

    public init(_ publicKey: PublicKey) {
        network = publicKey.network
        publicKeyHash = Crypto.sha256ripemd160(publicKey.raw)
        base58 = publicKey.toAddress()
    }

    public init(_ base58: Base58Check) throws {
        self.base58 = base58

        let raw = Base58.decode(base58)
        let checksum = raw.suffix(4)
        let pubKeyHash = raw.dropLast(4)
        let checksumConfirm = Crypto.sha256sha256(pubKeyHash).prefix(4)
        guard checksum == checksumConfirm else {
            throw AddressError.invalid
        }

        let network: Network
        let addressPrefix = pubKeyHash[0]
        switch addressPrefix {
        case Network.mainnet.pubkeyhash:
            network = .mainnet
        case Network.testnet.pubkeyhash:
            network = .testnet
        default:
            throw AddressError.wrongNetwork
        }
        self.network = network

        self.publicKeyHash = pubKeyHash.dropFirst()
    }
}

extension Address : Equatable {
    public static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.network == rhs.network && lhs.publicKeyHash == rhs.publicKeyHash
    }
}

extension Address : CustomStringConvertible {
    public var description: String {
        return base58
    }
}

public enum AddressError: Error {
    case invalid
    case wrongNetwork
}
