# 🌱 Green Rewards Program

> **Incentivizing sustainable actions through blockchain rewards** 🚀

A Clarity smart contract that gamifies environmental responsibility by rewarding users with points for completing green actions and allowing them to redeem rewards with their earned points.

## 🌟 Features

- 👤 **User Registration** - Join the green movement
- 🌿 **Green Actions** - Complete eco-friendly activities to earn points
- 🏆 **Rewards System** - Redeem points for valuable rewards  
- 📊 **Progress Tracking** - Monitor your environmental impact
- 🔧 **Admin Controls** - Manage actions and rewards
- 📈 **Analytics** - View contract statistics and user data

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://docs.stacks.co/stacks-cli) (optional)

### Installation

```bash
git clone <your-repo>
cd Green-Rewards-Program
clarinet check
```

## 📖 Usage Guide

### 🔐 For Users

#### 1. Register as a User
```clarity
(contract-call? .green-rewards-program register-user)
```

#### 2. Complete Green Actions
```clarity
(contract-call? .green-rewards-program complete-action u1)
```

#### 3. Redeem Rewards
```clarity
(contract-call? .green-rewards-program redeem-reward u1)
```

#### 4. Check Your Points
```clarity
(contract-call? .green-rewards-program get-user-points 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

### 👨‍💼 For Administrators

#### 1. Add Green Actions
```clarity
(contract-call? .green-rewards-program add-green-action 
  "Recycle Plastic" 
  "Properly recycle plastic bottles and containers" 
  u10 
  "Recycling")
```

#### 2. Add Rewards
```clarity
(contract-call? .green-rewards-program add-reward 
  "Eco Water Bottle" 
  "Sustainable bamboo water bottle" 
  u50 
  "Merchandise")
```

#### 3. Manage Actions & Rewards
```clarity
;; Toggle action availability
(contract-call? .green-rewards-program toggle-action-status u1)

;; Toggle reward availability  
(contract-call? .green-rewards-program toggle-reward-availability u1)
```

## 🎯 Green Action Examples

| Action | Points | Category |
|--------|--------|----------|
| 🚴 Bike to Work | 15 | Transportation |
| ♻️ Recycle Plastic | 10 | Recycling |
| 🚌 Use Public Transport | 8 | Transportation |
| 🌱 Plant a Tree | 25 | Conservation |
| 💡 Use LED Bulbs | 12 | Energy |
| 🚰 Save Water | 5 | Conservation |

## 🏆 Reward Examples

| Reward | Cost | Category |
|--------|------|----------|
| 🌿 Eco Water Bottle | 50 pts | Merchandise |
| 🎫 Movie Tickets | 100 pts | Entertainment |
| 🌳 Tree Planting Kit | 75 pts | Gardening |
| 🚲 Bike Accessories | 150 pts | Transportation |

## 📊 Contract Functions

### Public Functions

| Function | Description | Access |
|----------|-------------|--------|
| `register-user` | Register as a new user | Anyone |
| `complete-action` | Complete a green action | Registered Users |
| `redeem-reward` | Redeem points for rewards | Registered Users |
| `add-green-action` | Add new green actions | Admin Only |
| `add-reward` | Add new rewards | Admin Only |
| `toggle-action-status` | Enable/disable actions | Admin Only |
| `toggle-reward-availability` | Enable/disable rewards | Admin Only |
| `toggle-contract-status` | Pause/unpause contract | Admin Only |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-user-data` | Get user profile and stats |
| `get-action-data` | Get green action details |
| `get-reward-data` | Get reward details |
| `get-contract-stats` | Get contract statistics |
| `get-user-points` | Get user's current points |
| `is-user-registered` | Check if user is registered |

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

Test specific functions:

```bash
# Test user registration
clarinet console
> (contract-call? .green-rewards-program register-user)

# Test completing actions
> (contract-call? .green-rewards-program complete-action u1)
```

## 🏗️ Contract Architecture

```
Green Rewards Program
├── User Management
│   ├── Registration
│   ├── Points Balance
│   └── Activity History
├── Actions System
│   ├── Green Actions Database
│   ├── Point Rewards
│   └── Category Management
├── Rewards System
│   ├── Rewards Catalog
│   ├── Redemption Process
│   └── Point Deduction
└── Admin Controls
    ├── Action Management
    ├── Reward Management
    └── Contract Controls
```

## 🔒 Security Features

- ✅ Owner-only admin functions
- ✅ Input validation and error handling
- ✅ Duplicate prevention
- ✅ Balance verification for redemptions
- ✅ Contract pause functionality

## 📈 Data Structures

### User Profile
```clarity
{
  points: uint,
  total-earned: uint,
  total-redeemed: uint,
  actions-completed: uint,
  registration-height: uint
}
```

### Green Action
```clarity
{
  name: (string-ascii 64),
  description: (string-ascii 256),
  points-reward: uint,
  category: (string-ascii 32),
  active: bool,
  times-completed: uint
}
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Run `clarinet check` and `clarinet test`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🌍 Impact

Join thousands of users making a positive environmental impact:
- 🌱 **Actions Completed**: Track your green activities
- 🏆 **Points Earned**: Gamify sustainability
- ♻️ **Community Growth**: Build eco-conscious communities
- 📊 **Real Impact**: Measurable environmental benefits

---

**Start your green journey today!** 🌿✨
