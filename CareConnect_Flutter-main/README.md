# CareConnect - Blockchain-Powered Aid Platform

A comprehensive platform for Cancer Warrior Foundation to manage pediatric cancer resources with blockchain transparency.

## 🏗️ Project Structure

\`\`\`
careconnect/
├── flutter_app/              # Flutter (Web + Mobile)
├── backend/                  # Node.js + Firebase Cloud Functions
├── smart-contracts/          # Solidity contracts for Polygon
└── docs/                     # Documentation
\`\`\`

## 🚀 Tech Stack

- **Frontend**: Flutter (Web, iOS, Android)
- **Backend**: Node.js + Express.js + Firebase
- **Database**: Firebase Firestore + Realtime Database
- **Blockchain**: Polygon (MATIC) with Solidity smart contracts
- **AI**: Google Gemini API
- **Authentication**: Firebase Auth with Custom Claims (RBAC)
- **Storage**: Firebase Storage
- **Payments**: PayMaya, GCash, Cards + Web3 wallets

## 📋 Prerequisites

### Required Tools
- Node.js 18+ and npm
- Flutter SDK 3.16+
- Firebase CLI: `npm install -g firebase-tools`
- Hardhat for smart contracts: `npm install -g hardhat`
- MetaMask or Web3 wallet

### Required Accounts
- Firebase project (https://console.firebase.google.com)
- Google Cloud account (for Gemini API)
- Polygon wallet with MATIC for gas fees
- PayMaya/GCash merchant accounts

## 🔧 Setup Instructions

### 1. Firebase Setup

\`\`\`bash
# Login to Firebase
firebase login

# Initialize Firebase project
firebase init

# Select:
# - Firestore
# - Functions
# - Storage
# - Hosting (for Flutter web)
\`\`\`

### 2. Environment Variables

Create `backend/functions/.env`:

\`\`\`env
# Firebase
FIREBASE_PROJECT_ID=your-project-id

# Polygon Blockchain
POLYGON_RPC_URL=
POLYGON_PRIVATE_KEY=
DONATION_CONTRACT_ADDRESS=
AUCTION_CONTRACT_ADDRESS=deployed-contract-address

# Google Gemini AI
GEMINI_API_KEY=

# Payment Gateways
PAYMAYA_PUBLIC_KEY=
PAYMAYA_SECRET_KEY=your-paymaya-secret-key
GCASH_MERCHANT_ID=your-gcash-merchant-id
GCASH_SECRET_KEY=your-gcash-secret-key

# Multi-sig Treasury Wallet
TREASURY_WALLET_ADDRESS=
\`\`\`

Create `flutter_app/.env`:

\`\`\`env
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_AUTH_DOMAIN=
\`\`\`

### 3. Smart Contract Deployment

\`\`\`bash
cd smart-contracts

# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Deploy to Polygon Amoy Testnet
npx hardhat run scripts/deploy.js --network amoy

# Deploy to Polygon Mainnet (production)
npx hardhat run scripts/deploy.js --network polygon
\`\`\`

### 4. Backend Setup

\`\`\`bash
cd backend/functions

# Install dependencies
npm install

# Deploy Cloud Functions
firebase deploy --only functions
\`\`\`

### 5. Flutter App Setup

\`\`\`bash
cd flutter_app

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Build for production
flutter build web
flutter build apk
flutter build ios
\`\`\`

## 🔐 Firebase Security Rules

### Firestore Rules

\`\`\`javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
             request.auth.token.admin == true;
    }
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Patients collection - ADMIN ONLY
    match /patients/{patientId} {
      allow read, write: if isAdmin();
    }
    
    // Public patients - READ ONLY for authenticated users
    match /public_patients/{patientId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Donations - Users can read their own, admins can read all
    match /donations/{donationId} {
      allow read: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated();
      allow update, delete: if isAdmin();
    }
    
    // Auctions - Public read, admin write
    match /auctions/{auctionId} {
      allow read: if true; // Public
      allow write: if isAdmin();
    }
    
    // Auction submissions - Users can create, admins can manage
    match /auction_submissions/{submissionId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAdmin();
    }
    
    // Donor profiles
    match /donors/{userId} {
      allow read: if isAuthenticated() && 
                     (request.auth.uid == userId || isAdmin());
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
\`\`\`

### Storage Rules

\`\`\`javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Patient documents - ADMIN ONLY
    match /patients/{patientId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
                            request.auth.token.admin == true;
    }
    
    // Auction item images - Public read, authenticated write
    match /auction_items/{itemId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // User uploads
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
  }
}
\`\`\`

## 👥 User Roles

### Admin Role
- Firebase Custom Claim: `{ admin: true }`
- Full system access
- Patient management
- Blockchain treasury management
- Auction approval
- Analytics dashboard

### Donor Role
- Firebase Custom Claim: `{ donor: true }` or standard user
- Make donations (traditional + crypto)
- Participate in auctions
- Submit items for auction
- View de-identified patient profiles
- Track personal impact
- Loyalty tier benefits

## 🎯 Key Features

### 1. Blockchain Donations (Polygon)
- Traditional payments (PayMaya/GCash/Cards)
- Cryptocurrency donations (MATIC/USDC)
- Low gas fees on Polygon network
- Real-time blockchain verification
- Public transparency via Polygonscan

### 2. Blockchain Auctions
- Physical item donations
- ERC-721 tokenization
- Automated smart contract bidding
- Transparent bid history
- Automatic fund transfer to foundation

### 3. Patient Management
- Admin: Full patient records
- Donors: De-identified profiles only
- AI-powered priority system
- Impact story tracking

### 4. AI Features (Google Gemini)
- 24/7 chatbot support
- Personalized donation prompts
- Auction recommendations
- Donor retention predictions
- Engagement optimization

### 5. Donor Loyalty System
- 4 tiers: Bronze, Silver, Gold, Platinum
- Blockchain-verified NFT badges
- Donation streak tracking
- Leaderboards and achievements
- Personalized impact reports

## 📊 Analytics Dashboard

- Real-time donation metrics
- Blockchain transaction monitoring
- Donor retention analytics
- Patient funding progress
- Geographic impact visualization

## 🧪 Testing

### Smart Contracts
\`\`\`bash
cd smart-contracts
npx hardhat test
\`\`\`

### Backend Functions
\`\`\`bash
cd backend/functions
npm test
\`\`\`

### Flutter App
\`\`\`bash
cd flutter_app
flutter test
\`\`\`

## 🚀 Deployment

### Production Checklist
- [ ] Deploy smart contracts to Polygon mainnet
- [ ] Update contract addresses in environment variables
- [ ] Deploy Firebase Cloud Functions
- [ ] Build and deploy Flutter web app
- [ ] Submit Flutter mobile apps to App Store / Play Store
- [ ] Configure production payment gateways
- [ ] Set up multi-signature treasury wallet
- [ ] Enable Firebase Analytics
- [ ] Configure monitoring and alerts

### Deploy Commands

\`\`\`bash
# Deploy smart contracts
cd smart-contracts && npx hardhat run scripts/deploy.js --network polygon

# Deploy backend
cd backend && firebase deploy --only functions

# Deploy web app
cd flutter_app && flutter build web && firebase deploy --only hosting

# Build mobile apps
flutter build apk --release
flutter build ios --release
\`\`\`

## 📱 Mobile App Submission

### Android (Google Play)
1. Build release APK: `flutter build apk --release`
2. Sign APK with keystore
3. Upload to Google Play Console
4. Complete store listing

### iOS (App Store)
1. Build release IPA: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect
4. Submit for review

## 🔒 Security Best Practices

1. **Never commit private keys or secrets**
2. **Use environment variables for all sensitive data**
3. **Enable Firebase App Check**
4. **Implement rate limiting on Cloud Functions**
5. **Use multi-signature wallet for treasury**
6. **Regular security audits of smart contracts**
7. **Encrypt sensitive patient data**
8. **Implement proper RBAC with Firebase Custom Claims**

## 📞 Support

For issues or questions:
- Technical: Create an issue in this repository
- Foundation: contact@cancerwarriorfoundation.org

## 📄 License

Proprietary - Cancer Warrior Foundation

---

Built with ❤️ for pediatric cancer warriors
