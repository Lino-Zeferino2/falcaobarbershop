

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Instância global do Firestore (aponta somente para a database padrão "(default)").
final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
);


