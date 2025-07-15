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