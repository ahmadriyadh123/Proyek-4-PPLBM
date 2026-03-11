import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
    //Mengambil roles dari .env di root
    static List<String> get availableRoles =>
        dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

    static const String actionCreate = 'create';
    static const String actionRead = 'read';
    static const String actionUpdate = 'update';
    static const String actionDelete = 'delete';

    //Matrix perizinan yang tetap fleksibel
    static final Map<String, List<String>> rolePermissions = {
        'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
        'Anggota': [actionCreate, actionRead],
        'Asisten': [actionRead, actionUpdate],
    };

    static bool canPerform(String role, String action, {bool isOwner = false}) {
        if (action == actionUpdate || action == actionDelete) {
            // Berlakukan Kedaulatan Data (Sovereignty) mutlak untuk Task 5
            // HANYA pembuat (Owner) yang bisa mengedit/menghapus, mengabaikan peran/role apapun.
            return isOwner;
        }

        final permissions = rolePermissions[role] ?? [];
        return permissions.contains(action);
    }
}