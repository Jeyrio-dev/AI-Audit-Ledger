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

;; Public functions
;; #[allow(unchecked_data)]
(define-public (register-model (name (string-ascii 100)) (model-hash (string-ascii 64)))
  (let
    (
      (model-id (var-get next-model-id))
    )
    (map-set models
      { model-id: model-id }
      {
        owner: tx-sender,
        name: name,
        model-hash: model-hash,
        registered-block: stacks-block-height,
        latest-compliance-status: compliance-pending,
        total-audits: u0
      }
    )
    (var-set next-model-id (+ model-id u1))
    (ok model-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (certify-auditor (auditor principal) (name (string-ascii 100)) (certification-hash (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (get-auditor auditor)) err-already-exists)
    
    (map-set auditors
      { auditor: auditor }
      {
        name: name,
        certification-hash: certification-hash,
        certified: true,
        certified-block: stacks-block-height,
        total-audits-conducted: u0
      }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (revoke-auditor-certification (auditor principal))
  (let
    (
      (auditor-data (unwrap! (get-auditor auditor) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set auditors
      { auditor: auditor }
      (merge auditor-data { certified: false })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (submit-audit 
  (model-id uint) 
  (findings-hash (string-ascii 64))
  (compliance-status uint)
  (severity-level uint))
  (let
    (
      (model-data (unwrap! (get-model model-id) err-not-found))
      (auditor-data (unwrap! (get-auditor tx-sender) err-not-certified))
      (audit-id (var-get next-audit-id))
      (current-audit-index (get total-audits model-data))
    )
    (asserts! (get certified auditor-data) err-not-certified)
    (asserts! (<= compliance-status compliance-conditional) err-invalid-params)
    (asserts! (<= severity-level u5) err-invalid-params)
    
    (map-set audits
      { audit-id: audit-id }
      {
        model-id: model-id,
        auditor: tx-sender,
        audit-block: stacks-block-height,
        findings-hash: findings-hash,
        compliance-status: compliance-status,
        severity-level: severity-level
      }
    )
    
    (map-set model-audits
      { model-id: model-id, audit-index: current-audit-index }
      { audit-id: audit-id }
    )
    
    (map-set models
      { model-id: model-id }
      (merge model-data {
        latest-compliance-status: compliance-status,
        total-audits: (+ current-audit-index u1)
      })
    )
    
    (map-set auditors
      { auditor: tx-sender }
      (merge auditor-data { total-audits-conducted: (+ (get total-audits-conducted auditor-data) u1) })
    )
    
    (var-set next-audit-id (+ audit-id u1))
    (ok audit-id)
  )
)

(define-public (update-model-hash (model-id uint) (new-model-hash (string-ascii 64)))
  (let
    (
      (model-data (unwrap! (get-model model-id) err-not-found))
    )
    (asserts! (is-eq (get owner model-data) tx-sender) err-unauthorized)
    
    (map-set models
      { model-id: model-id }
      (merge model-data { 
        model-hash: new-model-hash,
        latest-compliance-status: compliance-pending
      })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (add-compliance-requirement (requirement-id uint) (name (string-ascii 100)) (description-hash (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set compliance-requirements
      { requirement-id: requirement-id }
      {
        name: name,
        description-hash: description-hash,
        active: true
      }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (record-requirement-compliance (audit-id uint) (requirement-id uint) (compliant bool))
  (let
    (
      (audit-data (unwrap! (get-audit audit-id) err-not-found))
    )
    (asserts! (is-eq (get auditor audit-data) tx-sender) err-unauthorized)
    (map-set audit-requirements
      { audit-id: audit-id, requirement-id: requirement-id }
      { compliant: compliant }
    )
    (ok true)
  )
)

(define-public (transfer-model-ownership (model-id uint) (new-owner principal))
  (let
    (
      (model-data (unwrap! (get-model model-id) err-not-found))
    )
    (asserts! (is-eq (get owner model-data) tx-sender) err-unauthorized)
    (asserts! (not (is-eq new-owner tx-sender)) err-invalid-params)
    
    (map-set models
      { model-id: model-id }
      (merge model-data { owner: new-owner })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (deactivate-compliance-requirement (requirement-id uint))
  (let
    (
      (requirement-data (unwrap! (map-get? compliance-requirements { requirement-id: requirement-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set compliance-requirements
      { requirement-id: requirement-id }
      (merge requirement-data { active: false })
    )
    (ok true)
  )
)