import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user as stream
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with email/password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Verify that the user also exists in the Realtime Database
      if (result.user != null) {
        UserModel? userData = await getUserData(result.user!.uid);
        if (userData == null) {
          await _auth.signOut();
          throw 'User profile not found. Please register first.';
        }
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during login.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      }
      throw errorMessage;
    } catch (e) {
      print('Sign in error: $e');
      throw 'Login failed. Please check your credentials.';
    }
  }

  // Sign up with email/password and create user profile in Firestore
  Future<UserCredential?> signUp({
    required String password,
    required UserModel userModel,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        // Use the UID from the newly created auth user
        UserModel finalUser = UserModel(
          uid: user.uid,
          email: userModel.email,
          name: userModel.name,
          role: userModel.role,
          department: userModel.department,
          semester: userModel.semester,
          studentId: userModel.studentId,
          office: userModel.office,
          designation: userModel.designation,
        );
        
        await DatabaseService().saveUserProfile(finalUser);
      }
      return result;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send reset email.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      }
      throw errorMessage;
    } catch (e) {
      throw 'An error occurred. Please try again later.';
    }
  }

  // Get user data from Realtime Database via DatabaseService
  Future<UserModel?> getUserData(String uid) async {
    try {
      final db = DatabaseService();
      Map<String, dynamic>? userInfo = await db.getUserInfo(uid);
      if (userInfo != null) {
        String? roleName = userInfo['role'];
        String? profileKey = userInfo['profileKey'];
        if (roleName != null && profileKey != null) {
          // Convert string role back to enum
          UserRole role = UserRole.values.firstWhere(
            (e) => e.name == roleName,
            orElse: () => UserRole.student,
          );
          return await db.getUserData(profileKey, role);
        }
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }
}
