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

;; Read-only functions
(define-read-only (get-model (model-id uint))
  (map-get? models { model-id: model-id })
)

(define-read-only (get-auditor (auditor principal))
  (map-get? auditors { auditor: auditor })
)

(define-read-only (get-audit (audit-id uint))
  (map-get? audits { audit-id: audit-id })
)

(define-read-only (is-certified-auditor (auditor principal))
  (match (get-auditor auditor)
    auditor-data (ok (get certified auditor-data))
    (ok false)
  )
)

(define-read-only (get-model-audit-history (model-id uint) (audit-index uint))
  (match (map-get? model-audits { model-id: model-id, audit-index: audit-index })
    audit-ref (get-audit (get audit-id audit-ref))
    none
  )
)

(define-read-only (get-latest-compliance (model-id uint))
  (match (get-model model-id)
    model-data (ok (get latest-compliance-status model-data))
    (err err-not-found)
  )
)

(define-read-only (get-auditor-statistics (auditor principal))
  (match (get-auditor auditor)
    auditor-data (ok {
      name: (get name auditor-data),
      certified: (get certified auditor-data),
      certified-block: (get certified-block auditor-data),
      total-audits-conducted: (get total-audits-conducted auditor-data),
      certification-hash: (get certification-hash auditor-data)
    })
    err-not-found
  )
)

(define-read-only (get-model-compliance-summary (model-id uint))
  (match (get-model model-id)
    model-data (ok {
      owner: (get owner model-data),
      name: (get name model-data),
      registered-block: (get registered-block model-data),
      latest-compliance-status: (get latest-compliance-status model-data),
      total-audits: (get total-audits model-data),
      model-hash: (get model-hash model-data)
    })
    err-not-found
  )
)