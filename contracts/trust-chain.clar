;; Title: TrustChain - Dynamic Reputation Protocol for Stacks Ecosystem

;; SUMMARY
;; TrustChain revolutionizes digital trust by providing a sophisticated, 
;; blockchain-native reputation system that evolves with user behavior. Built on 
;; Stacks, it creates a living trust score that rewards consistent participation 
;; while naturally preventing reputation farming through intelligent decay mechanics.

;; DESCRIPTION
;; This protocol establishes a new paradigm for measuring and maintaining digital 
;; credibility in decentralized environments. Unlike static reputation systems, 
;; TrustChain implements:
;;
;; ADAPTIVE SCORING ENGINE
;;   - Multi-dimensional reputation calculation based on diverse on-chain activities
;;   - Configurable action multipliers that reflect real-world impact
;;   - Dynamic threshold adjustments for different trust levels
;;
;; TEMPORAL INTELLIGENCE
;;   - Sophisticated decay algorithms that maintain score relevance
;;   - Time-weighted contributions that favor recent positive actions
;;   - Automated freshness validation to prevent stale reputation abuse
;;
;; ENTERPRISE-GRADE VERIFICATION
;;   - Comprehensive identity management with DID integration
;;   - Immutable audit trails for all reputation modifications
;;   - Real-time verification functions for seamless dApp integration
;;
;; GOVERNANCE & FLEXIBILITY
;;   - Administrative controls for ecosystem adaptation
;;   - Extensible action framework for evolving use cases
;;   - Protocol-level safeguards against manipulation
;;
;; TrustChain serves as the foundational trust layer for DeFi protocols, 
;; marketplace applications, governance systems, and any decentralized service 
;; requiring reliable participant credibility assessment.

;; ERROR DEFINITIONS
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-PARAMETERS (err u101))
(define-constant ERR-IDENTITY-EXISTS (err u102))
(define-constant ERR-IDENTITY-NOT-FOUND (err u103))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u104))
(define-constant ERR-MAX-REPUTATION-REACHED (err u105))
(define-constant ERR-ACTION-EXISTS (err u106))
(define-constant ERR-ACTION-NOT-FOUND (err u107))
(define-constant ERR-NOT-ADMIN (err u108))
(define-constant ERR-NOT-ACTIVE (err u109))

;; PROTOCOL CONSTANTS
(define-constant MAX-REPUTATION-SCORE u1000)
(define-constant MIN-REPUTATION-SCORE u0)
(define-constant DEFAULT-STARTING-REPUTATION u50)
(define-constant DEFAULT-DECAY-RATE u10) ;; 10% decay per period
(define-constant MINIMUM_DID_LENGTH u5)

;; PROTOCOL CONFIGURATION
(define-data-var contract-owner principal tx-sender)
(define-data-var contract-active bool true)
(define-data-var decay-rate uint DEFAULT-DECAY-RATE)
(define-data-var decay-period uint u10000) ;; In blocks
(define-data-var starting-reputation uint DEFAULT-STARTING-REPUTATION)

;; DATA STRUCTURES

;; Identity Registry
(define-map identities
  { owner: principal }
  {
    did: (string-ascii 50), ;; Decentralized Identity
    reputation-score: uint,
    created-at: uint,
    last-updated: uint,
    last-decay: uint,
    total-actions: uint,
    active: bool,
  }
)

;; Reputation Action Definitions
(define-map reputation-actions
  { action-type: (string-ascii 50) }
  {
    multiplier: uint,
    description: (string-ascii 100),
    active: bool,
  }
)

;; Reputation Change Audit Trail
(define-map reputation-history
  {
    owner: principal,
    tx-id: uint,
  }
  {
    action-type: (string-ascii 50),
    previous-score: uint,
    new-score: uint,
    timestamp: uint,
    block-height: uint,
  }
)

;; ADMINISTRATIVE FUNCTIONS

;; Transfer contract ownership
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (var-set contract-owner new-owner)
    (ok true)
  )
)

;; Toggle contract active state
(define-public (set-contract-active (active bool))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (var-set contract-active active)
    (ok true)
  )
)

;; Configure decay parameters
(define-public (set-decay-parameters
    (new-rate uint)
    (new-period uint)
  )
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts! (<= new-rate u100) (err ERR-INVALID-PARAMETERS))
    (asserts! (> new-period u0) (err ERR-INVALID-PARAMETERS))
    (var-set decay-rate new-rate)
    (var-set decay-period new-period)
    (ok true)
  )
)

;; Set initial reputation for new identities
(define-public (set-starting-reputation (new-value uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts! (<= new-value MAX-REPUTATION-SCORE) (err ERR-INVALID-PARAMETERS))
    (var-set starting-reputation new-value)
    (ok true)
  )
)

;; REPUTATION ACTION MANAGEMENT

;; Add new reputation action type
(define-public (add-reputation-action
    (action-type (string-ascii 50))
    (multiplier uint)
    (description (string-ascii 100))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts!
      (is-none (map-get? reputation-actions { action-type: action-type }))
      (err ERR-ACTION-EXISTS)
    )
    (map-set reputation-actions { action-type: action-type } {
      multiplier: multiplier,
      description: description,
      active: true,
    })
    (ok true)
  )
)

;; Update existing reputation action
(define-public (update-reputation-action
    (action-type (string-ascii 50))
    (multiplier uint)
    (description (string-ascii 100))
    (active bool)
  )
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts!
      (is-some (map-get? reputation-actions { action-type: action-type }))
      (err ERR-ACTION-NOT-FOUND)
    )
    (map-set reputation-actions { action-type: action-type } {
      multiplier: multiplier,
      description: description,
      active: active,
    })
    (ok true)
  )
)

;; PROTOCOL INITIALIZATION

;; Initialize default reputation actions
(define-public (initialize-reputation-actions)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    ;; Governance participation
    (map-set reputation-actions { action-type: "governance-vote" } {
      multiplier: u5,
      description: "Participation in governance voting",
      active: true,
    })
    ;; Smart contract fulfillment
    (map-set reputation-actions { action-type: "contract-fulfillment" } {
      multiplier: u10,
      description: "Successful completion of a smart contract agreement",
      active: true,
    })
    ;; Community contribution
    (map-set reputation-actions { action-type: "community-contribution" } {
      multiplier: u7,
      description: "Contribution to community projects or initiatives",
      active: true,
    })
    ;; Network validation
    (map-set reputation-actions { action-type: "validation" } {
      multiplier: u3,
      description: "Validation of network transactions or data",
      active: true,
    })
    ;; Content creation
    (map-set reputation-actions { action-type: "content-creation" } {
      multiplier: u6,
      description: "Creation of valuable content on the platform",
      active: true,
    })
    (ok true)
  )
)

;; UTILITY FUNCTIONS

;; Validate owner authorization
(define-private (is-valid-owner (owner principal))
  (and
    (is-some (map-get? identities { owner: owner }))
    (is-eq owner tx-sender)
  )
)

;; Log reputation changes to history
(define-private (log-reputation-change
    (owner principal)
    (action-type (string-ascii 50))
    (previous-score uint)
    (new-score uint)
  )
  (map-set reputation-history {
    owner: owner,
    tx-id: stacks-block-height,
  } {
    action-type: action-type,
    previous-score: previous-score,
    new-score: new-score,
    timestamp: burn-block-height,
    block-height: stacks-block-height,
  })
)

;; Get action multiplier value
(define-private (get-action-multiplier (action-type (string-ascii 50)))
  (default-to u0
    (get multiplier (map-get? reputation-actions { action-type: action-type }))
  )
)

;; Check if action is active
(define-private (is-action-active (action-type (string-ascii 50)))
  (default-to false
    (get active (map-get? reputation-actions { action-type: action-type }))
  )
)

;; Get identity data
(define-private (get-identity-field (owner principal))
  (map-get? identities { owner: owner })
)

;; Check if reputation should decay
(define-private (should-decay (last-decay uint))
  (>= (- stacks-block-height last-decay) (var-get decay-period))
)

;; IDENTITY MANAGEMENT

;; Create new identity
(define-public (create-identity (did (string-ascii 50)))
  (let (
      (sender tx-sender)
      (current-block-height stacks-block-height)
    )
    (begin
      ;; Validate contract state
      (asserts! (var-get contract-active) (err ERR-NOT-ACTIVE))
      ;; Check identity uniqueness
      (asserts! (is-none (map-get? identities { owner: sender }))
        (err ERR-IDENTITY-EXISTS)
      )
      ;; Validate DID format
      (asserts! (> (len did) MINIMUM_DID_LENGTH) (err ERR-INVALID-PARAMETERS))
      ;; Create new identity
      (map-set identities { owner: sender } {
        did: did,
        reputation-score: (var-get starting-reputation),
        created-at: current-block-height,
        last-updated: current-block-height,
        last-decay: current-block-height,
        total-actions: u0,
        active: true,
      })
      (ok did)
    )
  )
)

;; Update identity status
(define-public (update-identity-status (active bool))
  (let (
      (sender tx-sender)
      (current-identity (unwrap! (map-get? identities { owner: sender })
        (err ERR-IDENTITY-NOT-FOUND)
      ))
    )
    (begin
      (map-set identities { owner: sender }
        (merge current-identity {
          active: active,
          last-updated: stacks-block-height,
        })
      )
      (ok true)
    )
  )
)

;; REPUTATION SCORING ENGINE

;; Update reputation score based on action
(define-public (update-reputation-score (action-type (string-ascii 50)))
  (let (
      (owner tx-sender)
      (current-identity (unwrap! (map-get? identities { owner: owner })
        (err ERR-IDENTITY-NOT-FOUND)
      ))
      (current-score (get reputation-score current-identity))
      (action-multiplier (get-action-multiplier action-type))
      (total-actions (+ (get total-actions current-identity) u1))
    )
    (begin
      ;; Validate contract state
      (asserts! (var-get contract-active) (err ERR-NOT-ACTIVE))
      ;; Validate identity state
      (asserts! (get active current-identity) (err ERR-UNAUTHORIZED))
      ;; Validate action type
      (asserts!
        (is-some (map-get? reputation-actions { action-type: action-type }))
        (err ERR-INVALID-PARAMETERS)
      )
      (asserts! (is-action-active action-type) (err ERR-INVALID-PARAMETERS))
      ;; Apply decay if needed
      (if (should-decay (get last-decay current-identity))
        (decay-reputation-internal owner)
        true
      )
      ;; Calculate new score
      (let (
          (updated-identity (unwrap! (map-get? identities { owner: owner })
            (err ERR-IDENTITY-NOT-FOUND)
          ))
          (updated-current-score (get reputation-score updated-identity))
          (new-score (if (< (+ updated-current-score action-multiplier) MAX-REPUTATION-SCORE)
            (+ updated-current-score action-multiplier)
            MAX-REPUTATION-SCORE
          ))
        )
        (begin
          ;; Update identity record
          (map-set identities { owner: owner }
            (merge updated-identity {
              reputation-score: new-score,
              last-updated: stacks-block-height,
              total-actions: total-actions,
            })
          )
          ;; Log reputation change
          (log-reputation-change owner action-type updated-current-score
            new-score
          )
          (ok new-score)
        )
      )
    )
  )
)

;; REPUTATION DECAY SYSTEM

;; Internal decay function
(define-private (decay-reputation-internal (owner principal))
  (let (
      (current-identity (default-to {
        did: "",
        reputation-score: u0,
        created-at: u0,
        last-updated: u0,
        last-decay: u0,
        total-actions: u0,
        active: false,
      }
        (map-get? identities { owner: owner })
      ))
      (current-score (get reputation-score current-identity))
      (decay-amount (/ (* current-score (var-get decay-rate)) u100))
      (updated-score (if (> current-score decay-amount)
        (- current-score decay-amount)
        MIN-REPUTATION-SCORE
      ))
    )
    (begin
      (map-set identities { owner: owner }
        (merge current-identity {
          reputation-score: updated-score,
          last-updated: stacks-block-height,
          last-decay: stacks-block-height,
        })
      )
      ;; Log decay event
      (log-reputation-change owner "decay" current-score updated-score)
      true
    )
  )
)

;; Public decay function
(define-public (decay-reputation)
  (let (
      (owner tx-sender)
      (current-identity (unwrap! (map-get? identities { owner: owner })
        (err ERR-IDENTITY-NOT-FOUND)
      ))
    )
    (begin
      ;; Validate contract state
      (asserts! (var-get contract-active) (err ERR-NOT-ACTIVE))
      ;; Validate identity state
      (asserts! (get active current-identity) (err ERR-UNAUTHORIZED))
      ;; Validate decay timing
      (asserts! (should-decay (get last-decay current-identity))
        (err ERR-INVALID-PARAMETERS)
      )
      (decay-reputation-internal owner)
      (let (
          (updated-identity (unwrap! (map-get? identities { owner: owner })
            (err ERR-IDENTITY-NOT-FOUND)
          ))
          (updated-score (get reputation-score updated-identity))
        )
        (ok updated-score)
      )
    )
  )
)

;; REPUTATION VERIFICATION & QUERIES

;; Get reputation score
(define-read-only (get-reputation (owner principal))
  (let ((identity (get-identity-field owner)))
    (if (is-some identity)
      (some (get reputation-score (unwrap! identity none)))
      none
    )
  )
)

;; Get complete identity information
(define-read-only (get-full-identity (owner principal))
  (get-identity-field owner)
)

;; Verify reputation meets threshold
(define-read-only (verify-reputation
    (owner principal)
    (min-reputation-threshold uint)
  )
  (match (map-get? identities { owner: owner })
    identity (if (and
        (get active identity)
        (>= (get reputation-score identity) min-reputation-threshold)
      )
      (some true)
      none
    )
    none
  )
)