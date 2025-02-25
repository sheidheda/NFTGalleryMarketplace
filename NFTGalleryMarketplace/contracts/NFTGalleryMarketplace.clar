;; NFT Gallery Marketplace
;; A comprehensive NFT marketplace with input validation

;; Constants for error handling
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NFT-EXISTS (err u101))
(define-constant ERR-INVALID-PRICE (err u102))
(define-constant ERR-NOT-OWNER (err u103))
(define-constant ERR-NOT-LISTED (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-INVALID-URI (err u106))
(define-constant ERR-INVALID-NAME (err u107))
(define-constant ERR-INVALID-DESCRIPTION (err u108))
(define-constant ERR-INVALID-PROPERTIES (err u109))
(define-constant ERR-INVALID-TOKEN-ID (err u110))
(define-constant ERR-INVALID-RECIPIENT (err u111))

;; Data Maps
(define-map tokens 
    { token-id: uint }
    { 
        owner: principal,
        metadata-uri: (string-utf8 256),
        creator: principal
    }
)

(define-map token-listings
    { token-id: uint }
    {
        price: uint,
        seller: principal
    }
)

(define-map token-metadata
    { token-id: uint }
    {
        name: (string-utf8 64),
        description: (string-utf8 256),
        properties: (list 10 (string-utf8 64))
    }
)

;; NFT counter for generating unique IDs
(define-data-var next-token-id uint u1)

;; Validation functions
(define-private (validate-token-id (token-id uint))
    (and 
        (> token-id u0)
        (< token-id (var-get next-token-id))
    )
)

(define-private (validate-string-not-empty (str (string-utf8 256)))
    (> (len (unwrap-panic (as-max-len? str u256))) u0)
)

(define-private (validate-properties (props (list 10 (string-utf8 64))))
    (and
        (> (len props) u0)
        (<= (len props) u10)
    )
)

;; Read-only functions
(define-read-only (get-token-owner (token-id uint))
    (match (map-get? tokens {token-id: token-id})
        token-data (ok (get owner token-data))
        (err "Token does not exist")
    )
)

(define-read-only (get-listing (token-id uint))
    (map-get? token-listings {token-id: token-id})
)

(define-read-only (get-token-metadata (token-id uint))
    (map-get? token-metadata {token-id: token-id})
)

;; Public functions
(define-public (mint (metadata-uri (string-utf8 256)) 
                    (name (string-utf8 64))
                    (description (string-utf8 256))
                    (properties (list 10 (string-utf8 64))))
    (let ((token-id (var-get next-token-id)))
        ;; Input validation
        (asserts! (validate-string-not-empty metadata-uri) ERR-INVALID-URI)
        (asserts! (> (len (unwrap-panic (as-max-len? name u64))) u0) ERR-INVALID-NAME)
        (asserts! (validate-string-not-empty description) ERR-INVALID-DESCRIPTION)
        (asserts! (validate-properties properties) ERR-INVALID-PROPERTIES)
        
        ;; Check if token already exists
        (asserts! (is-none (map-get? tokens {token-id: token-id})) ERR-NFT-EXISTS)
        
        ;; Store token data
        (map-set tokens
            {token-id: token-id}
            {
                owner: tx-sender,
                metadata-uri: metadata-uri,
                creator: tx-sender
            }
        )
        
        ;; Store metadata
        (map-set token-metadata
            {token-id: token-id}
            {
                name: name,
                description: description,
                properties: properties
            }
        )
        
        ;; Increment token counter
        (var-set next-token-id (+ token-id u1))
        (ok token-id)
    )
)

(define-public (list-token (token-id uint) (price uint))
    (begin
        ;; Validate token-id
        (asserts! (validate-token-id token-id) ERR-INVALID-TOKEN-ID)
        (let ((token-data (unwrap! (map-get? tokens {token-id: token-id}) ERR-NOT-AUTHORIZED)))
            ;; Validate ownership
            (asserts! (is-eq tx-sender (get owner token-data)) ERR-NOT-OWNER)
            ;; Validate price
            (asserts! (> price u0) ERR-INVALID-PRICE)
            
            ;; Create listing
            (map-set token-listings
                {token-id: token-id}
                {
                    price: price,
                    seller: tx-sender
                }
            )
            (ok true)
        )
    )
)

(define-public (cancel-listing (token-id uint))
    (begin
        (asserts! (validate-token-id token-id) ERR-INVALID-TOKEN-ID)
        (let ((listing (unwrap! (map-get? token-listings {token-id: token-id}) ERR-NOT-LISTED))
              (token-data (unwrap! (map-get? tokens {token-id: token-id}) ERR-NOT-AUTHORIZED)))
            ;; Validate ownership
            (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-AUTHORIZED)
            
            ;; Remove listing
            (map-delete token-listings {token-id: token-id})
            (ok true)
        )
    )
)

(define-public (buy-token (token-id uint))
    (begin
        (asserts! (validate-token-id token-id) ERR-INVALID-TOKEN-ID)
        (let ((listing (unwrap! (map-get? token-listings {token-id: token-id}) ERR-NOT-LISTED))
              (price (get price listing))
              (seller (get seller listing)))
            
            ;; Transfer payment to seller
            (try! (stx-transfer? price tx-sender seller))
            
            ;; Update token ownership
            (map-set tokens
                {token-id: token-id}
                {
                    owner: tx-sender,
                    metadata-uri: (get metadata-uri (unwrap! (map-get? tokens {token-id: token-id}) ERR-NOT-AUTHORIZED)),
                    creator: (get creator (unwrap! (map-get? tokens {token-id: token-id}) ERR-NOT-AUTHORIZED))
                }
            )
            
            ;; Remove listing
            (map-delete token-listings {token-id: token-id})
            (ok true)
        )
    )
)

(define-public (transfer-token (token-id uint) (recipient principal))
    (begin
        ;; Validate inputs
        (asserts! (validate-token-id token-id) ERR-INVALID-TOKEN-ID)
        (asserts! (not (is-eq recipient tx-sender)) ERR-INVALID-RECIPIENT)
        
        (let ((token-data (unwrap! (map-get? tokens {token-id: token-id}) ERR-NOT-AUTHORIZED)))
            ;; Validate ownership
            (asserts! (is-eq tx-sender (get owner token-data)) ERR-NOT-OWNER)
            ;; Check if token is listed
            (asserts! (is-none (map-get? token-listings {token-id: token-id})) ERR-NOT-LISTED)
            
            ;; Transfer token
            (map-set tokens
                {token-id: token-id}
                {
                    owner: recipient,
                    metadata-uri: (get metadata-uri token-data),
                    creator: (get creator token-data)
                }
            )
            (ok true)
        )
    )
)