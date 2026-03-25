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

    static bool canPerform(String role, String action, {bool isOwner = false, bool isPrivate = false}) {
        if (action == actionUpdate || action == actionDelete) {
            // Berlakukan Kedaulatan Data mutlak:
            // Jika catatan di-set Private -> HANYA pembuat (Owner) yang bisa mengedit/menghapus. (Bahkan Ketua tidak bisa)
            if (isPrivate) {
                return isOwner;
            }

            // Jika catatan di-set Public ->
            // 1. Pembuat (Owner) selalu bisa edit/hapus
            if (isOwner) {
                return true;
            }
            // 2. Ketua/Admin punya wewenang mengelola (edit/hapus) catatan tim yang publik
            if (role == 'Ketua' || role == 'Admin') {
                return true;
            }
        }

        final permissions = rolePermissions[role] ?? [];
        return permissions.contains(action);
    }
}