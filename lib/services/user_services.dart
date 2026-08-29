import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Coleção principal
  CollectionReference get _usersRef => _firestore.collection('users');

  Future<void> createUser({
    required UserModel user,
    required String password,
  }) async {
    // Validações
    if (user.email.trim().isEmpty) {
      throw Exception('E-mail não pode estar vazio');
    }
    if (user.name.trim().isEmpty) {
      throw Exception('Nome não pode estar vazio');
    }
    if (password.isEmpty || password.length < 6) {
      throw Exception('Senha deve ter no mínimo 6 caracteres');
    }

    // Cria a conta no Firebase Auth
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: user.email.trim().toLowerCase(),
      password: password,
    );

    String? uid = credential.user?.uid;

    if (uid != null) {
      // Cria o documento no Firestore com o mesmo ID (UID) do Auth
      // Usa o uid do Firebase, não do UserModel
      final userToSave = user.copyWith(uid: uid);
      await _usersRef.doc(uid).set(userToSave.toMap());
    } else {
      throw Exception('Falha ao criar usuário: UID não obtido');
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    DocumentSnapshot doc = await _usersRef.doc(uid).get();

    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<UserModel?> streamUserProfile() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUserProfile(UserModel user) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");

    await _usersRef.doc(uid).update({
      'name': user.name,
      'phone': user.phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAccount() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Remove o documento do Firestore
    await _usersRef.doc(currentUser.uid).delete();

    // Remove a conta de acesso do Firebase Auth
    await currentUser.delete();
  }
}