# Firebase_AuthService_Flutter
Flutter Authentication Service for Firebase - helping to authenticate Google, Apple and Email/Password Sign-ons for application.

# auth_service.dart
auth_service.dart enables authentication via Firebase. Developer needs a Google Cloud account and active Firestore/Firebase account with enabled Google Authentication. Developer might also need Apple Client ID and Redirect ID that they would store in .env file.  This file successfully adds a new user to Firestore using Apple, Google or Email sign on credentials, and depending on which authentication used, the script collects and storesthe following data from those profiles:
* creates a userID
* user.email
* fullname - split to firstname and lastname
* photoURL - determined from Google or Apple


Dependendencies needed are:
* firebase_auth.dart
* google_sign_in.dart
* sign_in_with_apple.dart
* cloud_firestore.dart

Note: UserLevel_service is optional, but was used to create a leveling/tier service among users, but it also adds data in computation or in algorithms of your choosing. Developers can disregard if not needed.

This file successfully integrates with Login screens established in the LoginOrRegister_Screens_Flutter repo: https://github.com/Istanbulexpat/LoginOrRegister_Screens_Flutter
