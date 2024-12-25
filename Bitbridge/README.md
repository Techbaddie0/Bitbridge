# Bitbridges: Advanced Supply Chain Management on Stacks Blockchain

## Overview

Bitbridges is a cutting-edge blockchain solution for supply chain management, leveraging Clarity smart contracts on the Stacks blockchain to provide transparent, secure, and verifiable product tracking with enhanced security features and IoT integration.

## Features

### 🔒 Secure Status Management
- Comprehensive product lifecycle tracking with validated transitions
- Cryptographically secure status updates
- Immutable status history with timestamp validation
- Strict authorization controls for status modifications

### 🌡️ Enhanced IoT Integration
- Secure device registration and verification
- Real-time product condition monitoring
- Active device status tracking
- Validated IoT device-to-product mapping

### 🔍 Advanced Authenticity Verification
- Cryptographic proof of product origin
- Robust hash validation system
- Double-verification mechanism (IoT + blockchain)
- Immutable authentication records

### 📡 Event Notification System
- Customizable status change alerts
- Subscriber-based notification system
- Flexible event filtering
- Real-time status updates

## Smart Contract Security Features

### Authentication & Authorization
- Strict sender verification
- Manufacturer validation
- Role-based access control
- Device registration verification

### Data Validation
- Hash integrity checks
- IoT device validation
- Status transition verification
- Input sanitization and validation

### Product Management
- Unique product ID validation
- Creation timestamp verification
- Authentication hash verification
- IoT device association checks

## Status Lifecycle

The contract enforces a strict status transition workflow:

- `CREATED` → Initial product registration
- `IN_TRANSIT` → Product in movement
- `SHIPPED` → Product dispatched
- `DELIVERED` → Successful delivery
- `DAMAGED` → Product damage reported
- `LOST` → Product missing in transit

## Technical Implementation

### Core Data Structures

```clarity
;; Product Tracking
(define-map products
  { product-id: uint }
  {
    owner: principal,
    current-status: (string-ascii 20),
    manufacturer: principal,
    creation-timestamp: uint,
    iot-device-id: (optional (buff 32)),
    authentication-hash: (buff 32)
  })

;; IoT Device Registry
(define-map iot-devices
  { device-id: (buff 32) }
  {
    registered-by: principal,
    is-active: bool,
    product-id: (optional uint)
  })
```

### Key Functions

#### Product Registration
```clarity
(define-public (register-product
  (product-id uint)
  (manufacturer principal)
  (initial-status (string-ascii 20))
  (authentication-hash (buff 32))
  (creation-timestamp uint)
  (optional-iot-device-id (optional (buff 32))))
```

#### IoT Device Registration
```clarity
(define-public (register-iot-device
  (device-id (buff 32))
  (product-id (optional uint)))
```

#### Product Authentication
```clarity
(define-read-only (verify-product-authenticity
  (product-id uint)
  (provided-hash (buff 32)))
```

## Getting Started

### Prerequisites
- Stacks Wallet
- Understanding of Clarity smart contracts
- IoT devices (optional)

### Deployment Steps
1. Deploy the Bitbridges smart contract
2. Initialize status transition rules
3. Register IoT devices (if applicable)
4. Register products
5. Configure status subscriptions

### Example Usage

```clarity
;; Register an IoT device
(register-iot-device 
    device-id 
    (optional product-id))

;; Register a product with IoT integration
(register-product
    product-id
    manufacturer
    STATUS_CREATED
    authentication-hash
    creation-timestamp
    (some device-id))

;; Subscribe to status updates
(subscribe-to-status-events
    product-id
    notify-statuses)
```

## Security Best Practices

1. **Input Validation**
   - All inputs are validated before processing
   - Hash integrity is verified
   - IoT device status is checked
   - Status transitions are validated

2. **Access Control**
   - Manufacturer verification
   - Owner authentication
   - Device registration validation
   - Status update authorization

3. **Data Integrity**
   - Immutable status history
   - Cryptographic product verification
   - Secure IoT device mapping
   - Timestamp validation

## Error Handling

The contract includes comprehensive error handling:

- `ERR_INVALID_STATUS_TRANSITION` (u200)
- `ERR_UNAUTHORIZED_STATUS_UPDATE` (u201)
- `ERR_PRODUCT_NOT_FOUND` (u202)
- `ERR_IOT_VERIFICATION_FAILED` (u203)
- `ERR_INVALID_INPUT` (u204)
- `ERR_INVALID_HASH` (u205)
- `ERR_INVALID_IOT_DEVICE` (u206)

## Future Enhancements

- Multi-signature status updates
- Advanced IoT data validation
- Cross-chain verification
- Enhanced batch processing capabilities
- Real-time analytics integration

## Contributing

1. Fork the repository
2. Create your feature branch
3. Implement security-first features
4. Add comprehensive tests
5. Submit a pull request