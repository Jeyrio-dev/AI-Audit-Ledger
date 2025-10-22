;; AIAudit Ledger - Transparent audit logging for AI models

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-not-found (err u501))
(define-constant err-unauthorized (err u502))
(define-constant err-invalid-params (err u503))
(define-constant err-not-certified (err u504))
(define-constant err-already-exists (err u505))

;; Compliance status codes
(define-constant compliance-pending u0)
(define-constant compliance-passed u1)
(define-constant compliance-failed u2)
(define-constant compliance-conditional u3)

;; Data Variables
(define-data-var next-model-id uint u0)
(define-data-var next-audit-id uint u0)

;; Data Maps
(define-map models
  { model-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    model-hash: (string-ascii 64),
    registered-block: uint,
    latest-compliance-status: uint,
    total-audits: uint
  }
)

(define-map auditors
  { auditor: principal }
  {
    name: (string-ascii 100),
    certification-hash: (string-ascii 64),
    certified: bool,
    certified-block: uint,
    total-audits-conducted: uint
  }
)

(define-map audits
  { audit-id: uint }
  {
    model-id: uint,
    auditor: principal,
    audit-block: uint,
    findings-hash: (string-ascii 64),
    compliance-status: uint,
    severity-level: uint
  }
)

(define-map model-audits
  { model-id: uint, audit-index: uint }
  { audit-id: uint }
)

(define-map compliance-requirements
  { requirement-id: uint }
  {
    name: (string-ascii 100),
    description-hash: (string-ascii 64),
    active: bool
  }
)

(define-map audit-requirements
  { audit-id: uint, requirement-id: uint }
  { compliant: bool }
)

