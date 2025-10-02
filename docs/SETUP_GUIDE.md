# CareConnect Setup Guide

## Step-by-Step Installation

### 1. Clone Repository

\`\`\`bash
git clone <repository-url>
cd careconnect
\`\`\`

### 2. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named "CareConnect"
3. Enable the following services:
   - Authentication (Email/Password)
   - Firestore Database
   - Storage
   - Cloud Functions
   - Hosting
   - Analytics

4. Download configuration files:
   - For Web/Android: `google-services.json`
   - For iOS: `GoogleService-Info.plist`

### 3. Smart Contract Deployment

\`\`\`bash
cd smart-contracts

# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env with your Polygon private key

# Compile contracts
npm run compile

# Deploy to Amoy testnet
npm run deploy:amoy

# Verify contracts
npm run verify:amoy

# For production, deploy to Polygon mainnet
npm run deploy:polygon
\`\`\`

Save the deployed contract addresses!

### 4. Backend Setup

\`\`\`bash
cd backend/functions

# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env with:
# - Firebase project ID
# - Deployed contract addresses
# - Gemini API key
# - Payment gateway credentials

# Test locally
npm run serve

# Deploy to Firebase
cd ..
firebase deploy --only functions
\`\`\`

### 5. Flutter App Setup

\`\`\`bash
cd flutter_app

# Create .env file
cp .env.example .env
# Edit .env with Firebase and contract details

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
\`\`\`

### 6. Set Up Admin User

After deploying, create an admin user:

\`\`\`bash
# Use Firebase CLI
firebase auth:export users.json
# Manually add custom claim { "admin": true }
firebase auth:import users.json
\`\`\`

Or use the admin SDK in a Cloud Function:

\`\`\`javascript
admin.auth().setCustomUserClaims(uid, { admin: true });
\`\`\`

### 7. Configure Payment Gateways

#### PayMaya
1. Sign up at [PayMaya Developer Portal](https://developers.paymaya.com)
2. Get API keys (sandbox for testing)
3. Add to backend `.env`

#### GCash
1. Contact GCash for merchant account
2. Get API credentials
3. Add to backend `.env`

### 8. Google Gemini API

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create API key
3. Add to backend `.env`

### 9. Deploy Production

\`\`\`bash
# Deploy smart contracts to Polygon mainnet
cd smart-contracts
npm run deploy:polygon

# Update contract addresses in backend .env

# Deploy backend
cd ../backend
firebase deploy --only functions,firestore,storage

# Build Flutter web
cd ../flutter_app
flutter build web

# Deploy web app
firebase deploy --only hosting

# Build mobile apps
flutter build apk --release
flutter build ios --release
\`\`\`

## Testing

### Test Donations

1. Create donor account
2. Make test donation with test payment gateway
3. Verify blockchain transaction on Polygonscan
4. Check Firestore for donation record

### Test Auctions

1. Login as admin
2. Create test auction
3. Login as donor
4. Place bid
5. Verify smart contract interaction

### Test AI Chatbot

1. Open chatbot interface
2. Ask questions about donations
3. Verify Gemini API responses

## Troubleshooting

### Firebase Functions Not Deploying
- Check Node.js version (must be 18+)
- Verify Firebase CLI is updated
- Check billing is enabled

### Smart Contract Deployment Fails
- Ensure wallet has MATIC for gas
- Check RPC URL is correct
- Verify private key format

### Flutter Build Errors
- Run `flutter clean`
- Delete `pubspec.lock`
- Run `flutter pub get` again

### Web3 Connection Issues
- Check RPC URL is accessible
- Verify contract addresses are correct
- Ensure wallet has MATIC

## Next Steps

1. Configure multi-signature treasury wallet
2. Set up monitoring and alerts
3. Enable Firebase App Check
4. Configure rate limiting
5. Set up backup systems
6. Create admin training documentation
7. Prepare donor onboarding materials

## Support

For technical issues, contact the development team or create an issue in the repository.
