(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-user-not-registered (err u105))
(define-constant err-action-not-found (err u106))
(define-constant err-reward-not-found (err u107))
(define-constant err-insufficient-points (err u108))
(define-constant err-invalid-position (err u109))
(define-constant err-leaderboard-full (err u110))

(define-data-var total-users uint u0)
(define-data-var leaderboard-size uint u10)
(define-data-var total-actions uint u0)
(define-data-var total-rewards uint u0)
(define-data-var contract-active bool true)

(define-map users
  { user: principal }
  {
    points: uint,
    total-earned: uint,
    total-redeemed: uint,
    actions-completed: uint,
    registration-height: uint
  }
)

(define-map green-actions
  { action-id: uint }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    points-reward: uint,
    category: (string-ascii 32),
    active: bool,
    times-completed: uint
  }
)

(define-map user-action-history
  { user: principal, action-id: uint }
  {
    points-earned: uint,
    completion-count: uint
  }
)

(define-map rewards
  { reward-id: uint }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    points-cost: uint,
    category: (string-ascii 32),
    available: bool,
    times-redeemed: uint
  }
)

(define-map user-redemptions
  { user: principal, reward-id: uint }
  {
    points-spent: uint,
    redemption-count: uint
  }
)

(define-map points-leaderboard
  { position: uint }
  {
    user: principal,
    points: uint
  }
)

(define-map actions-leaderboard
  { position: uint }
  {
    user: principal,
    actions-count: uint
  }
)

(define-map category-leaders
  { category: (string-ascii 32) }
  {
    user: principal,
    category-points: uint
  }
)

(define-map user-category-points
  { user: principal, category: (string-ascii 32) }
  {
    points: uint
  }
)

(define-public (register-user)
  (let
    (
      (user tx-sender)
    )
    (asserts! (var-get contract-active) (err u999))
    (asserts! (is-none (map-get? users { user: user })) err-already-exists)
    
    (map-set users
      { user: user }
      {
        points: u0,
        total-earned: u0,
        total-redeemed: u0,
        actions-completed: u0,
        registration-height: u0
      }
    )
    
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

(define-public (add-green-action (name (string-ascii 64)) (description (string-ascii 256)) (points-reward uint) (category (string-ascii 32)))
  (let
    (
      (action-id (+ (var-get total-actions) u1))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> points-reward u0) err-invalid-amount)
    
    (map-set green-actions
      { action-id: action-id }
      {
        name: name,
        description: description,
        points-reward: points-reward,
        category: category,
        active: true,
        times-completed: u0
      }
    )
    
    (var-set total-actions action-id)
    (ok action-id)
  )
)

(define-public (complete-action (action-id uint))
  (let
    (
      (user tx-sender)
      (action-data (unwrap! (map-get? green-actions { action-id: action-id }) err-action-not-found))
      (user-data (unwrap! (map-get? users { user: user }) err-user-not-registered))
      (points-to-earn (get points-reward action-data))
    )
    (asserts! (var-get contract-active) (err u999))
    (asserts! (get active action-data) err-action-not-found)
    
    (map-set user-action-history
      { user: user, action-id: action-id }
      {
        points-earned: points-to-earn,
        completion-count: (+ 
          (default-to u0 (get completion-count (map-get? user-action-history { user: user, action-id: action-id })))
          u1)
      }
    )
    
    (map-set users
      { user: user }
      {
        points: (+ (get points user-data) points-to-earn),
        total-earned: (+ (get total-earned user-data) points-to-earn),
        total-redeemed: (get total-redeemed user-data),
        actions-completed: (+ (get actions-completed user-data) u1),
        registration-height: (get registration-height user-data)
      }
    )
    
    (map-set green-actions
      { action-id: action-id }
      {
        name: (get name action-data),
        description: (get description action-data),
        points-reward: (get points-reward action-data),
        category: (get category action-data),
        active: (get active action-data),
        times-completed: (+ (get times-completed action-data) u1)
      }
    )
    
    (update-user-category-points user (get category action-data) points-to-earn)
    (update-category-leader (get category action-data) user)
    
    (ok points-to-earn)
  )
)

(define-public (add-reward (name (string-ascii 64)) (description (string-ascii 256)) (points-cost uint) (category (string-ascii 32)))
  (let
    (
      (reward-id (+ (var-get total-rewards) u1))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> points-cost u0) err-invalid-amount)
    
    (map-set rewards
      { reward-id: reward-id }
      {
        name: name,
        description: description,
        points-cost: points-cost,
        category: category,
        available: true,
        times-redeemed: u0
      }
    )
    
    (var-set total-rewards reward-id)
    (ok reward-id)
  )
)

(define-public (redeem-reward (reward-id uint))
  (let
    (
      (user tx-sender)
      (reward-data (unwrap! (map-get? rewards { reward-id: reward-id }) err-reward-not-found))
      (user-data (unwrap! (map-get? users { user: user }) err-user-not-registered))
      (points-to-spend (get points-cost reward-data))
      (user-points (get points user-data))
    )
    (asserts! (var-get contract-active) (err u999))
    (asserts! (get available reward-data) err-reward-not-found)
    (asserts! (>= user-points points-to-spend) err-insufficient-points)
    
    (map-set user-redemptions
      { user: user, reward-id: reward-id }
      {
        points-spent: points-to-spend,
        redemption-count: (+ 
          (default-to u0 (get redemption-count (map-get? user-redemptions { user: user, reward-id: reward-id })))
          u1)
      }
    )
    
    (map-set users
      { user: user }
      {
        points: (- user-points points-to-spend),
        total-earned: (get total-earned user-data),
        total-redeemed: (+ (get total-redeemed user-data) points-to-spend),
        actions-completed: (get actions-completed user-data),
        registration-height: (get registration-height user-data)
      }
    )
    
    (map-set rewards
      { reward-id: reward-id }
      {
        name: (get name reward-data),
        description: (get description reward-data),
        points-cost: (get points-cost reward-data),
        category: (get category reward-data),
        available: (get available reward-data),
        times-redeemed: (+ (get times-redeemed reward-data) u1)
      }
    )
    
    (ok true)
  )
)

(define-public (toggle-action-status (action-id uint))
  (let
    (
      (action-data (unwrap! (map-get? green-actions { action-id: action-id }) err-action-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set green-actions
      { action-id: action-id }
      {
        name: (get name action-data),
        description: (get description action-data),
        points-reward: (get points-reward action-data),
        category: (get category action-data),
        active: (not (get active action-data)),
        times-completed: (get times-completed action-data)
      }
    )
    
    (ok (not (get active action-data)))
  )
)

(define-public (toggle-reward-availability (reward-id uint))
  (let
    (
      (reward-data (unwrap! (map-get? rewards { reward-id: reward-id }) err-reward-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set rewards
      { reward-id: reward-id }
      {
        name: (get name reward-data),
        description: (get description reward-data),
        points-cost: (get points-cost reward-data),
        category: (get category reward-data),
        available: (not (get available reward-data)),
        times-redeemed: (get times-redeemed reward-data)
      }
    )
    
    (ok (not (get available reward-data)))
  )
)

(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

(define-read-only (get-user-data (user principal))
  (map-get? users { user: user })
)

(define-read-only (get-action-data (action-id uint))
  (map-get? green-actions { action-id: action-id })
)

(define-read-only (get-reward-data (reward-id uint))
  (map-get? rewards { reward-id: reward-id })
)

(define-read-only (get-user-action-history (user principal) (action-id uint))
  (map-get? user-action-history { user: user, action-id: action-id })
)

(define-read-only (get-user-redemption (user principal) (reward-id uint))
  (map-get? user-redemptions { user: user, reward-id: reward-id })
)

(define-read-only (get-contract-stats)
  {
    total-users: (var-get total-users),
    total-actions: (var-get total-actions),
    total-rewards: (var-get total-rewards),
    contract-active: (var-get contract-active),
    contract-owner: contract-owner
  }
)

(define-read-only (get-user-points (user principal))
  (match (map-get? users { user: user })
    user-data (ok (get points user-data))
    (err err-user-not-registered)
  )
)

(define-read-only (is-user-registered (user principal))
  (is-some (map-get? users { user: user }))
)

(define-private (update-user-category-points (user principal) (category (string-ascii 32)) (points uint))
  (let
    (
      (current-points (default-to u0 (get points (map-get? user-category-points { user: user, category: category }))))
    )
    (map-set user-category-points
      { user: user, category: category }
      { points: (+ current-points points) }
    )
  )
)

(define-public (update-leaderboard-entry (position uint) (user principal) (points uint) (actions uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= position (var-get leaderboard-size)) err-invalid-position)
    
    (map-set points-leaderboard
      { position: position }
      { user: user, points: points }
    )
    
    (map-set actions-leaderboard
      { position: position }
      { user: user, actions-count: actions }
    )
    
    (ok true)
  )
)

(define-private (update-category-leader (category (string-ascii 32)) (user principal))
  (let
    (
      (user-cat-points (default-to u0 (get points (map-get? user-category-points { user: user, category: category }))))
      (current-leader (map-get? category-leaders { category: category }))
    )
    (match current-leader
      leader-data
        (if (> user-cat-points (get category-points leader-data))
          (map-set category-leaders
            { category: category }
            { user: user, category-points: user-cat-points }
          )
          true
        )
      (map-set category-leaders
        { category: category }
        { user: user, category-points: user-cat-points }
      )
    )
  )
)

(define-read-only (get-points-leaderboard-entry (position uint))
  (map-get? points-leaderboard { position: position })
)

(define-read-only (get-actions-leaderboard-entry (position uint))
  (map-get? actions-leaderboard { position: position })
)

(define-read-only (get-category-leader (category (string-ascii 32)))
  (map-get? category-leaders { category: category })
)

(define-read-only (get-user-category-points (user principal) (category (string-ascii 32)))
  (map-get? user-category-points { user: user, category: category })
)

(define-read-only (get-leaderboard-stats)
  {
    leaderboard-size: (var-get leaderboard-size),
    points-leader: (map-get? points-leaderboard { position: u1 }),
    actions-leader: (map-get? actions-leaderboard { position: u1 })
  }
)
