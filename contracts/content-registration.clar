;; Content Registration Contract
;; Records ownership of digital creative works

(define-data-var last-content-id uint u0)

;; Map of content ID to content details
(define-map contents
  { id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    hash: (buff 32),
    created-at: uint
  }
)

;; Map of content hash to owner
(define-map content-owners
  { hash: (buff 32) }
  { owner: principal }
)

;; Get content by ID
(define-read-only (get-content (id uint))
  (map-get? contents { id: id })
)

;; Get content owner by hash
(define-read-only (get-content-owner (hash (buff 32)))
  (map-get? content-owners { hash: hash })
)

;; Register new content
(define-public (register-content
                (title (string-ascii 100))
                (hash (buff 32)))
  (let ((id (+ (var-get last-content-id) u1))
        (existing-owner (get-content-owner hash)))

    ;; Check if content hash already registered
    (asserts! (is-none existing-owner) (err u1))

    ;; Store content details
    (map-set contents
             { id: id }
             {
               creator: tx-sender,
               title: title,
               hash: hash,
               created-at: block-height
             })

    ;; Store content ownership
    (map-set content-owners
             { hash: hash }
             { owner: tx-sender })

    ;; Update last content ID
    (var-set last-content-id id)

    (ok id)))

;; Transfer content ownership
(define-public (transfer-ownership
                (id uint)
                (new-owner principal))
  (let ((content (get-content id)))

    ;; Check if content exists
    (asserts! (is-some content) (err u2))

    ;; Check if sender is the current owner
    (asserts! (is-eq tx-sender (get creator (unwrap! content (err u3)))) (err u4))

    ;; Update ownership
    (map-set content-owners
             { hash: (get hash (unwrap! content (err u3))) }
             { owner: new-owner })

    (ok true)))

