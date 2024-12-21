import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:XPID/components/UserLevel_service.dart';

/* Auth Service handles the authentication of Google Sign On and Apple Sign On
buttons when either logging in or registering a new user. It also handles
the creation of a user document in the Firestore user collection.
*/

class AuthService {
  // Load environment variables
  final appleClientId = dotenv.env['APPLE_CLIENT_ID'];
  final appleRedirectUri = dotenv.env['APPLE_REDIRECT_URI'];

  //final UserLevelService userLevelService =
  //    UserLevelService(); //Create an instance of UserLevelService

  // Google Sign in
  Future<bool> signInWithGoogle() async {
    print('Signing in with Google...AuthService');
    try {
      // begin interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        // User canceled the sign-in process
        return false;
      }
      // obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      // create a new credential for the user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      // Sign in with Google credential
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

// Extract first name and last name from display name
      final fullName = userCredential.user?.displayName ?? '';
      final firstName = fullName.split(' ')[0];
      final lastName =
          fullName.split(' ').length > 1 ? fullName.split(' ')[1] : '';

// From signInWithGoogle method
      await addUserToFirestore(
        userCredential.user!,
        firstName,
        lastName,
        userCredential.user?.uid, // Pass Google User ID
        userCredential.user?.photoURL, // Pass Google Photo URL
        isGoogleSignIn: true, // Indicate it's a Google sign-in
      );
// Return true indicating successful sign-in
      return true;
    } catch (e) {
      print('Error signing in with Google: $e');
      return false;
    }
  }

  //Apple Sign in

  Future<UserCredential?> signInWithApple() async {
    print('Signing in with Apple...AuthService');
    try {
      // Obtain auth details from request
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: appleClientId!,
          redirectUri: Uri.parse(appleRedirectUri!),
        ),
      );

      // Access identityToken and authorizationCode
      final String? identityToken = credential.identityToken;
      final String? authorizationCode = credential.authorizationCode;

      if (identityToken != null) {
        // Create a new credential for the user
        final appleCredential = OAuthProvider("apple.com").credential(
          idToken: identityToken,
          accessToken: authorizationCode,
        );

        // Sign in with Apple credential
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(appleCredential);

// Extract first name and last name from full name
// final fullName = credential.fullName;
        final String? firstName = credential.givenName;
        final String? lastName = credential.familyName;

// From signInWithApple method
        await addUserToFirestore(
          userCredential.user!,
          firstName ?? '',
          lastName ?? '',
          userCredential.user?.uid, // Pass Apple User ID
          null, // Apple doesn't provide direct access to user photo
        );

        return userCredential;
      } else {
        print("Error signing in with Apple: identityToken is null");
        return null;
      }
    } catch (e) {
      print("Error signing in with Apple: $e");
      return null;
    }
  }

  Future<void> addUserToFirestore(User user, String firstName, String lastName,
      String? userId, String? photoURL,
      {bool isGoogleSignIn = false}) async {
    try {
      // Get a reference to the user's document
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Check if the user document already exists
      final userDoc = await userDocRef.get();

      // Prepare the basic user data
      final userData = {
        'date_created': DateTime.now(),
        'email': user.email,
        'fullname': {
          'firstname': firstName,
          'lastname': lastName,
        },
      };

      // Add Google-specific fields if it's a Google sign-in
      if (isGoogleSignIn) {
        userData['userIdGoogle'] = userId;
        userData['photoURLGoogle'] = photoURL;
      } else {
        // Add Apple-specific fields if it's an Apple sign-in
        userData['userIdApple'] = userId;
        userData['photoURLApple'] = photoURL;
      }

      // If the user document does not exist, add initial level data
      if (!userDoc.exists) {
        // Only add initial level data if the user document doesn't exist
        final initialLevelData = UserLevelService.getInitialLevelInfo();
        userData.addAll(initialLevelData);
      } else {
        // Ensure xpidBalance is not overwritten if it already exists
        if (userDoc.data()!.containsKey('xpidBalance')) {
          userData['xpidBalance'] = userDoc['xpidBalance'];
        }
      }

      // Merge the user data into the Firestore document
      await userDocRef.set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error adding user data to Firestore: $e');
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
