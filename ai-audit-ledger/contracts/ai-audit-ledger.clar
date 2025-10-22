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

