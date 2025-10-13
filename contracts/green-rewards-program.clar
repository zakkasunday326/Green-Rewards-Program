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
(define-constant err-streak-not-found (err u111))
(define-constant err-invalid-day (err u112))
(define-constant err-self-referral (err u113))
(define-constant err-already-referred (err u114))
(define-constant err-invalid-referrer (err u115))
(define-constant err-referral-limit-reached (err u116))

(define-data-var total-users uint u0)
(define-data-var streak-bonus-multiplier uint u2)
(define-data-var max-streak-bonus uint u50)
(define-data-var leaderboard-size uint u10)
(define-data-var total-actions uint u0)
(define-data-var total-rewards uint u0)
(define-data-var contract-active bool true)
(define-data-var current-day uint u1)
(define-data-var referrer-bonus uint u50)
(define-data-var referee-bonus uint u30)
(define-data-var max-referrals-per-user uint u100)

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

(define-map user-streaks
  { user: principal }
  {
    current-streak: uint,
    best-streak: uint,
    last-action-day: uint,
    total-streak-points: uint,
    streak-milestones: uint
  }
)

(define-map streak-milestones
  { milestone: uint }
  {
    days-required: uint,
    bonus-points: uint,
    milestone-name: (string-ascii 32)
  }
)

(define-map daily-action-tracker
  { user: principal, day: uint }
  {
    actions-completed: uint,
    points-earned: uint
  }
)

(define-map referral-data
  { user: principal }
  {
    referrer: (optional principal),
    total-referrals: uint,
    referral-points-earned: uint,
    is-referee: bool
  }
)

(define-map user-referrals
  { referrer: principal, referee: principal }
  {
    referral-date: uint,
    bonus-awarded: bool
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
    
    (map-set user-streaks
      { user: user }
      {
        current-streak: u0,
        best-streak: u0,
        last-action-day: u0,
        total-streak-points: u0,
        streak-milestones: u0
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
    
    (let
      (
        (today (get-current-day))
        (streak-bonus (calculate-streak-bonus user today))
        (total-points (+ points-to-earn streak-bonus))
      )
      (update-user-streak user today)
      (update-daily-tracker user today points-to-earn)
      
      (if (> streak-bonus u0)
        (map-set users
          { user: user }
          {
            points: (+ (- (get points user-data) points-to-earn) total-points),
            total-earned: (+ (- (get total-earned user-data) points-to-earn) total-points),
            total-redeemed: (get total-redeemed user-data),
            actions-completed: (get actions-completed user-data),
            registration-height: (get registration-height user-data)
          }
        )
        true
      )
      
      (ok total-points)
    )
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

(define-private (get-current-day)
  (var-get current-day)
)

(define-public (advance-day)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set current-day (+ (var-get current-day) u1))
    (ok (var-get current-day))
  )
)

(define-private (calculate-streak-bonus (user principal) (day uint))
  (let
    (
      (streak-data (map-get? user-streaks { user: user }))
    )
    (match streak-data
      user-streak
        (let
          (
            (current-streak (get current-streak user-streak))
            (base-multiplier (var-get streak-bonus-multiplier))
            (max-bonus (var-get max-streak-bonus))
          )
          (if (>= current-streak u1)
            (if (< (* current-streak base-multiplier) max-bonus)
              (* current-streak base-multiplier)
              max-bonus
            )
            u0
          )
        )
      u0
    )
  )
)

(define-private (update-user-streak (user principal) (day uint))
  (let
    (
      (streak-data (default-to 
        { current-streak: u0, best-streak: u0, last-action-day: u0, total-streak-points: u0, streak-milestones: u0 }
        (map-get? user-streaks { user: user })
      ))
      (last-day (get last-action-day streak-data))
      (current-streak (get current-streak streak-data))
      (best-streak (get best-streak streak-data))
    )
    (let
      (
        (new-streak 
          (if (is-eq (+ last-day u1) day)
            (+ current-streak u1)
            (if (is-eq last-day day)
              current-streak
              u1
            )
          )
        )
        (new-best (if (> new-streak best-streak) new-streak best-streak))
      )
      (map-set user-streaks
        { user: user }
        {
          current-streak: new-streak,
          best-streak: new-best,
          last-action-day: day,
          total-streak-points: (get total-streak-points streak-data),
          streak-milestones: (get streak-milestones streak-data)
        }
      )
      (check-and-award-milestone user new-streak)
    )
  )
)

(define-private (update-daily-tracker (user principal) (day uint) (points uint))
  (let
    (
      (daily-data (default-to
        { actions-completed: u0, points-earned: u0 }
        (map-get? daily-action-tracker { user: user, day: day })
      ))
    )
    (map-set daily-action-tracker
      { user: user, day: day }
      {
        actions-completed: (+ (get actions-completed daily-data) u1),
        points-earned: (+ (get points-earned daily-data) points)
      }
    )
  )
)

(define-private (check-and-award-milestone (user principal) (streak uint))
  (let
    (
      (milestone-5 (map-get? streak-milestones { milestone: u1 }))
      (milestone-10 (map-get? streak-milestones { milestone: u2 }))
      (milestone-30 (map-get? streak-milestones { milestone: u3 }))
      (user-streak-data (unwrap-panic (map-get? user-streaks { user: user })))
    )
    (if (and (>= streak u5) (< (get best-streak user-streak-data) u5))
      (award-milestone-bonus user u1)
      (if (and (>= streak u10) (< (get best-streak user-streak-data) u10))
        (award-milestone-bonus user u2)
        (if (and (>= streak u30) (< (get best-streak user-streak-data) u30))
          (award-milestone-bonus user u3)
          true
        )
      )
    )
  )
)

(define-private (award-milestone-bonus (user principal) (milestone-id uint))
  (let
    (
      (milestone-data (map-get? streak-milestones { milestone: milestone-id }))
      (user-data (unwrap-panic (map-get? users { user: user })))
      (streak-data (unwrap-panic (map-get? user-streaks { user: user })))
    )
    (match milestone-data
      milestone
        (let
          (
            (bonus-points (get bonus-points milestone))
          )
          (map-set users
            { user: user }
            {
              points: (+ (get points user-data) bonus-points),
              total-earned: (+ (get total-earned user-data) bonus-points),
              total-redeemed: (get total-redeemed user-data),
              actions-completed: (get actions-completed user-data),
              registration-height: (get registration-height user-data)
            }
          )
          (map-set user-streaks
            { user: user }
            {
              current-streak: (get current-streak streak-data),
              best-streak: (get best-streak streak-data),
              last-action-day: (get last-action-day streak-data),
              total-streak-points: (+ (get total-streak-points streak-data) bonus-points),
              streak-milestones: (+ (get streak-milestones streak-data) u1)
            }
          )
        )
      true
    )
  )
)

(define-public (setup-streak-milestones)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set streak-milestones
      { milestone: u1 }
      { days-required: u5, bonus-points: u25, milestone-name: "Week Warrior" }
    )
    
    (map-set streak-milestones
      { milestone: u2 }
      { days-required: u10, bonus-points: u75, milestone-name: "Consistency Champion" }
    )
    
    (map-set streak-milestones
      { milestone: u3 }
      { days-required: u30, bonus-points: u200, milestone-name: "Eco Legend" }
    )
    
    (ok true)
  )
)

(define-read-only (get-user-streak (user principal))
  (map-get? user-streaks { user: user })
)

(define-read-only (get-daily-actions (user principal) (day uint))
  (map-get? daily-action-tracker { user: user, day: day })
)

(define-read-only (get-streak-milestone (milestone-id uint))
  (map-get? streak-milestones { milestone: milestone-id })
)

(define-read-only (get-streak-stats)
  {
    total-users: (var-get total-users),
    streak-multiplier: (var-get streak-bonus-multiplier),
    max-streak-bonus: (var-get max-streak-bonus),
    current-day: (get-current-day)
  }
)

(define-public (register-with-referral (referrer principal))
  (let
    (
      (user tx-sender)
      (referrer-data (map-get? referral-data { user: referrer }))
      (referrer-user-data (map-get? users { user: referrer }))
    )
    (asserts! (var-get contract-active) (err u999))
    (asserts! (is-none (map-get? users { user: user })) err-already-exists)
    (asserts! (not (is-eq user referrer)) err-self-referral)
    (asserts! (is-some referrer-user-data) err-invalid-referrer)
    
    (let
      (
        (referrer-ref-data (default-to 
          { referrer: none, total-referrals: u0, referral-points-earned: u0, is-referee: false }
          referrer-data
        ))
        (current-referrals (get total-referrals referrer-ref-data))
      )
      (asserts! (< current-referrals (var-get max-referrals-per-user)) err-referral-limit-reached)
      
      (map-set users
        { user: user }
        {
          points: (var-get referee-bonus),
          total-earned: (var-get referee-bonus),
          total-redeemed: u0,
          actions-completed: u0,
          registration-height: u0
        }
      )
      
      (map-set user-streaks
        { user: user }
        {
          current-streak: u0,
          best-streak: u0,
          last-action-day: u0,
          total-streak-points: u0,
          streak-milestones: u0
        }
      )
      
      (map-set referral-data
        { user: user }
        {
          referrer: (some referrer),
          total-referrals: u0,
          referral-points-earned: u0,
          is-referee: true
        }
      )
      
      (map-set user-referrals
        { referrer: referrer, referee: user }
        {
          referral-date: (get-current-day),
          bonus-awarded: true
        }
      )
      
      (let
        (
          (referrer-user (unwrap-panic referrer-user-data))
          (referrer-bonus-points (var-get referrer-bonus))
        )
        (map-set users
          { user: referrer }
          {
            points: (+ (get points referrer-user) referrer-bonus-points),
            total-earned: (+ (get total-earned referrer-user) referrer-bonus-points),
            total-redeemed: (get total-redeemed referrer-user),
            actions-completed: (get actions-completed referrer-user),
            registration-height: (get registration-height referrer-user)
          }
        )
        
        (map-set referral-data
          { user: referrer }
          {
            referrer: (get referrer referrer-ref-data),
            total-referrals: (+ current-referrals u1),
            referral-points-earned: (+ (get referral-points-earned referrer-ref-data) referrer-bonus-points),
            is-referee: (get is-referee referrer-ref-data)
          }
        )
      )
      
      (var-set total-users (+ (var-get total-users) u1))
      (ok true)
    )
  )
)

(define-public (update-referral-bonuses (new-referrer-bonus uint) (new-referee-bonus uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-referrer-bonus u0) err-invalid-amount)
    (asserts! (> new-referee-bonus u0) err-invalid-amount)
    
    (var-set referrer-bonus new-referrer-bonus)
    (var-set referee-bonus new-referee-bonus)
    (ok true)
  )
)

(define-public (update-max-referrals (new-max uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-max u0) err-invalid-amount)
    
    (var-set max-referrals-per-user new-max)
    (ok new-max)
  )
)

(define-read-only (get-referral-data (user principal))
  (map-get? referral-data { user: user })
)

(define-read-only (get-referral-relationship (referrer principal) (referee principal))
  (map-get? user-referrals { referrer: referrer, referee: referee })
)

(define-read-only (get-referral-stats)
  {
    referrer-bonus: (var-get referrer-bonus),
    referee-bonus: (var-get referee-bonus),
    max-referrals: (var-get max-referrals-per-user),
    total-users: (var-get total-users)
  }
)

(define-read-only (get-user-referral-impact (user principal))
  (let
    (
      (ref-data (map-get? referral-data { user: user }))
    )
    (match ref-data
      data
        (ok {
          total-referrals: (get total-referrals data),
          referral-points-earned: (get referral-points-earned data),
          is-referee: (get is-referee data),
          referrer: (get referrer data)
        })
      (ok {
        total-referrals: u0,
        referral-points-earned: u0,
        is-referee: false,
        referrer: none
      })
    )
  )
)
