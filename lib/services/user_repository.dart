import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import 'user_services.dart';

class UserRepository {
  final UserService _userService = UserService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Obtém o usuário autenticado atualmente
  User? get currentUser => _firebaseAuth.currentUser;

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Stream que emite as mudanças do usuário autenticado
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Registra um novo usuário
  /// 
  /// Parâmetros:
  /// - [name]: Nome completo do usuário
  /// - [email]: E-mail único
  /// - [phone]: Número de telefone (opcional)
  /// - [password]: Senha do usuário
  /// 
  /// Retorna: Um Future que completa quando o usuário é criado
  /// 
  /// Lança: FirebaseAuthException se houver erro
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Criar usuário no Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception('Falha ao obter UID do usuário');
      }

      // Criar documento no Firestore
      final userModel = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        password: password,
      );

      await _userService.createUser(
        user: userModel,
        password: password,
      );

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  /// Faz login com e-mail e senha
  /// 
  /// Parâmetros:
  /// - [email]: E-mail do usuário
  /// - [password]: Senha do usuário
  /// 
  /// Retorna: Um Future que completa com o usuário quando faz login com sucesso
  /// 
  /// Lança: FirebaseAuthException se houver erro
  Future<User?> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtém o perfil do usuário atualmente autenticado
  /// 
  /// Retorna: Um Future com UserModel ou null se não encontrado
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) return null;
      return await _userService.getCurrentUserProfile();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream contínuo do perfil do usuário autenticado
  /// 
  /// Retorna: Um Stream que emite as mudanças do perfil do usuário
  Stream<UserModel?> streamUserProfile() {
    if (!isAuthenticated) {
      return Stream.value(null);
    }
    return _userService.streamUserProfile();
  }

  /// Atualiza o perfil do usuário
  /// 
  /// Parâmetros:
  /// - [user]: Objeto UserModel com os dados atualizados
  /// 
  /// Retorna: Um Future que completa quando o perfil é atualizado
  /// 
  /// Lança: Exception se o usuário não estiver autenticado
  Future<void> updateUserProfile(UserModel user) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }
      await _userService.updateUserProfile(user);
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza apenas nome e telefone do usuário
  /// 
  /// Parâmetros:
  /// - [name]: Novo nome do usuário
  /// - [phone]: Novo telefone do usuário
  /// 
  /// Retorna: Um Future que completa quando os dados são atualizados
  /// 
  /// Lança: Exception se o usuário não estiver autenticado
  Future<void> updateUserBasicInfo({
    required String name,
    required String phone,
  }) async {
    try {
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('Perfil do usuário não encontrado');
      }

      final updatedUser = currentProfile.copyWith(
        name: name.trim(),
        phone: phone.trim(),
      );

      await updateUserProfile(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza o e-mail do usuário
  /// 
  /// Parâmetros:
  /// - [newEmail]: Novo e-mail
  /// 
  /// Retorna: Um Future que completa quando o e-mail é atualizado
  /// 
  /// Lança: FirebaseAuthException se houver erro
  Future<void> updateUserEmail(String newEmail) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      await currentUser?.verifyBeforeUpdateEmail(newEmail.trim().toLowerCase());
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza a senha do usuário
  /// 
  /// Parâmetros:
  /// - [newPassword]: Nova senha
  /// 
  /// Retorna: Um Future que completa quando a senha é atualizada
  /// 
  /// Lança: FirebaseAuthException se houver erro
  Future<void> updatePassword(String newPassword) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      await currentUser?.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  /// Deleta a conta do usuário
  /// 
  /// Retorna: Um Future que completa quando a conta é deletada
  /// 
  /// Lança: FirebaseAuthException ou Exception se houver erro
  Future<void> deleteAccount() async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      await _userService.deleteAccount();
    } catch (e) {
      rethrow;
    }
  }

  /// Faz logout do usuário
  /// 
  /// Retorna: Um Future que completa quando o logout é feito
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Envia e-mail de recuperação de senha
  /// 
  /// Parâmetros:
  /// - [email]: E-mail do usuário
  /// 
  /// Retorna: Um Future que completa quando o e-mail é enviado
  /// 
  /// Lança: FirebaseAuthException se houver erro
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } catch (e) {
      rethrow;
    }
  }

  /// Recarrega os dados do usuário autenticado
  /// 
  /// Retorna: Um Future que completa quando os dados são recarregados
  /// 
  /// Lança: FirebaseAuthException se houver erro
  Future<void> reloadCurrentUser() async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }
      await currentUser?.reload();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtém o token ID do usuário autenticado
  /// 
  /// Parâmetros:
  /// - [forceRefresh]: Se true, força a renovação do token
  /// 
  /// Retorna: String com o token ID ou null se não autenticado
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      if (!isAuthenticated) return null;
      return await currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica se o e-mail do usuário foi verificado
  /// 
  /// Retorna: true se o e-mail foi verificado, false caso contrário
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Envia e-mail de verificação
  /// 
  /// Retorna: Um Future que completa quando o e-mail é enviado
  /// 
  /// Lança: FirebaseAuthException se houver erro
  Future<void> sendEmailVerification() async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }
      await currentUser?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }
}
