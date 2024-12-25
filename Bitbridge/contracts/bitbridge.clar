;; Bitbridges Advanced Supply Chain Status Management Contract

;; Enum-like Status Definitions
(define-constant STATUS_CREATED "CREATED")
(define-constant STATUS_IN_TRANSIT "IN_TRANSIT")
(define-constant STATUS_SHIPPED "SHIPPED")
(define-constant STATUS_DELIVERED "DELIVERED")
(define-constant STATUS_DAMAGED "DAMAGED")
(define-constant STATUS_LOST "LOST")

;; Error Codes for Status Management
(define-constant ERR_INVALID_STATUS_TRANSITION (err u200))
(define-constant ERR_UNAUTHORIZED_STATUS_UPDATE (err u201))
(define-constant ERR_PRODUCT_NOT_FOUND (err u202))
(define-constant ERR_IOT_VERIFICATION_FAILED (err u203))
(define-constant ERR_INVALID_INPUT (err u204))
(define-constant ERR_INVALID_HASH (err u205))
(define-constant ERR_INVALID_IOT_DEVICE (err u206))

;; Product Tracking Structure
(define-map products
  { product-id: uint }
  {
    owner: principal,
    current-status: (string-ascii 20),
    manufacturer: principal,
    creation-timestamp: uint,
    iot-device-id: (optional (buff 32)),
    authentication-hash: (buff 32)
  }
)

;; Status Transition Rules
(define-map status-transitions
  { 
    from-status: (string-ascii 20), 
    to-status: (string-ascii 20) 
  }
  bool
)

;; IoT Device Verification
(define-map iot-devices
  { device-id: (buff 32) }
  {
    registered-by: principal,
    is-active: bool,
    product-id: (optional uint)
  }
)

;; Event Notification Subscriptions
(define-map status-event-subscriptions
  { 
    product-id: uint, 
    subscriber: principal 
  }
  {
    notify-statuses: (list 10 (string-ascii 20))
  }
)

;; Validation Functions
(define-private (validate-hash (hash (buff 32)))
  (> (len hash) u0))

(define-private (validate-iot-device-id (device-id (buff 32)))
  (and 
    (> (len device-id) u0)
    (match (map-get? iot-devices { device-id: device-id })
      device (get is-active device)
      false)))

;; Initialize Status Transition Rules
(define-public (initialize-status-transitions)
  (begin
    ;; Define valid status transitions
    (map-set status-transitions 
      { from-status: STATUS_CREATED, to-status: STATUS_IN_TRANSIT } true)
    (map-set status-transitions 
      { from-status: STATUS_IN_TRANSIT, to-status: STATUS_SHIPPED } true)
    (map-set status-transitions 
      { from-status: STATUS_SHIPPED, to-status: STATUS_DELIVERED } true)
    (map-set status-transitions 
      { from-status: STATUS_IN_TRANSIT, to-status: STATUS_DAMAGED } true)
    (map-set status-transitions 
      { from-status: STATUS_IN_TRANSIT, to-status: STATUS_LOST } true)
    
    (ok true)
  )
)

;; Helper function to validate status
(define-private (validate-status (status (string-ascii 20)))
  (or 
    (is-eq status STATUS_CREATED)
    (is-eq status STATUS_IN_TRANSIT)
    (is-eq status STATUS_SHIPPED)
    (is-eq status STATUS_DELIVERED)
    (is-eq status STATUS_DAMAGED)
    (is-eq status STATUS_LOST)
  )
)

;; Register a New Product with Authenticity Proof
(define-public (register-product
  (product-id uint)
  (manufacturer principal)
  (initial-status (string-ascii 20))
  (authentication-hash (buff 32))
  (creation-timestamp uint)
  (optional-iot-device-id (optional (buff 32)))
)
  (begin
    ;; Ensure product doesn't already exist
    (asserts! (is-none (map-get? products { product-id: product-id })) ERR_PRODUCT_NOT_FOUND)
    ;; Validate initial status
    (asserts! (validate-status initial-status) ERR_INVALID_INPUT)
    ;; Validate input data
    (asserts! (> product-id u0) ERR_INVALID_INPUT)
    (asserts! (> creation-timestamp u0) ERR_INVALID_INPUT)
    ;; Validate manufacturer
    (asserts! (is-eq tx-sender manufacturer) ERR_UNAUTHORIZED_STATUS_UPDATE)
    ;; Validate authentication hash
    (asserts! (validate-hash authentication-hash) ERR_INVALID_HASH)
    
    ;; Validate optional IoT device if provided
    (asserts! (match optional-iot-device-id
                device-id (validate-iot-device-id device-id)
                true) 
              ERR_INVALID_IOT_DEVICE)
    
    ;; Register product with initial details
    (map-set products 
      { product-id: product-id }
      {
        owner: tx-sender,
        current-status: initial-status,
        manufacturer: manufacturer,
        creation-timestamp: creation-timestamp,
        iot-device-id: optional-iot-device-id,
        authentication-hash: authentication-hash
      }
    )
    
    ;; Optional IoT Device Registration
    (match optional-iot-device-id
      device-id 
        (begin
          (asserts! (validate-iot-device-id device-id) ERR_INVALID_IOT_DEVICE)
          (map-set iot-devices 
            { device-id: device-id }
            {
              registered-by: tx-sender,
              is-active: true,
              product-id: (some product-id)
            }
          ))
      true
    )
    
    (ok true)
  )
)

;; Subscribe to Status Change Notifications
(define-public (subscribe-to-status-events
  (product-id uint)
  (notify-statuses (list 10 (string-ascii 20)))
)
  (begin
    ;; Validate product-id
    (asserts! (> product-id u0) ERR_INVALID_INPUT)
    ;; Validate all statuses in the list
    (asserts! (fold check-status notify-statuses true) ERR_INVALID_INPUT)
    
    (map-set status-event-subscriptions 
      { 
        product-id: product-id, 
        subscriber: tx-sender 
      }
      { notify-statuses: notify-statuses }
    )
    (ok true)
  )
)

;; Helper function to check status validity
(define-private (check-status (status (string-ascii 20)) (valid bool))
  (and valid (validate-status status))
)

;; Internal Function to Notify Subscribers
(define-private (notify-status-subscribers
  (product-id uint)
  (new-status (string-ascii 20))
)
  (match 
    (map-get? status-event-subscriptions 
      { 
        product-id: product-id, 
        subscriber: tx-sender 
      }
    )
    subscription
    (if (is-some (index-of (get notify-statuses subscription) new-status))
        (begin
          ;; Future: Implement actual notification mechanism
          (print {
            event: "status-change-notification",
            product-id: product-id,
            status: new-status,
            subscriber: tx-sender
          })
          (ok true)
        )
        (ok false)
    )
    (ok false)
  )
)

;; IoT Device Registration
(define-public (register-iot-device
  (device-id (buff 32))
  (product-id (optional uint))
)
  (begin
    ;; Validate device-id
    (asserts! (> (len device-id) u0) ERR_INVALID_IOT_DEVICE)
    
    ;; Validate product-id if provided
    (asserts! (match product-id
                id (> id u0)
                true
              ) ERR_INVALID_INPUT)
    
    (map-set iot-devices 
      { device-id: device-id }
      {
        registered-by: tx-sender,
        is-active: true,
        product-id: product-id
      }
    )
    (ok true)
  )
)

;; Helper function for batch status processing
(define-private (process-product-status
    (product-id uint)
    (result {
        statuses: (list 50 {
            product-id: uint,
            status: (optional (string-ascii 20)),
            timestamp: (optional uint)
        }),
        count: uint
    })
)
    (let (
        (product-details (map-get? products { product-id: product-id }))
    )
        {
            statuses: (unwrap-panic 
                (as-max-len? 
                    (concat 
                        (get statuses result)
                        (list {
                            product-id: product-id,
                            status: (match product-details
                                details (some (get current-status details))
                                none
                            ),
                            timestamp: (match product-details
                                details (some (get creation-timestamp details))
                                none
                            )
                        })
                    )
                    u50
                )
            ),
            count: (+ (get count result) u1)
        }
    )
)