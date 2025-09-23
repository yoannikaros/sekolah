import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Kebijakan Privasi",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kebijakan Privasi Seangkatan.id',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Terakhir diperbarui: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSection(
                '1. Informasi yang Kami Kumpulkan',
                'Kami mengumpulkan informasi yang Anda berikan secara langsung kepada kami, seperti:\n\n'
                '• Informasi akun (nama, email, password)\n'
                '• Informasi profil dan preferensi\n'
                '• Data penggunaan aplikasi\n'
                '• Informasi perangkat dan log teknis\n'
                '• Kode kelas dan data akademik yang Anda masukkan',
              ),
              
              _buildSection(
                '2. Bagaimana Kami Menggunakan Informasi',
                'Kami menggunakan informasi yang dikumpulkan untuk:\n\n'
                '• Menyediakan dan memelihara layanan aplikasi\n'
                '• Memproses pendaftaran dan autentikasi pengguna\n'
                '• Mengelola kelas dan konten pembelajaran\n'
                '• Meningkatkan pengalaman pengguna\n'
                '• Mengirim notifikasi penting terkait layanan\n'
                '• Melakukan analisis untuk pengembangan aplikasi',
              ),
              
              _buildSection(
                '3. Berbagi Informasi',
                'Kami tidak menjual, memperdagangkan, atau mentransfer informasi pribadi Anda kepada pihak ketiga tanpa persetujuan Anda, kecuali:\n\n'
                '• Untuk mematuhi hukum yang berlaku\n'
                '• Untuk melindungi hak dan keamanan kami atau pengguna lain\n'
                '• Dengan penyedia layanan tepercaya yang membantu operasi aplikasi\n'
                '• Dalam kasus merger, akuisisi, atau penjualan aset',
              ),
              
              _buildSection(
                '4. Keamanan Data',
                'Kami menerapkan langkah-langkah keamanan yang sesuai untuk melindungi informasi pribadi Anda:\n\n'
                '• Enkripsi data saat transmisi dan penyimpanan\n'
                '• Autentikasi multi-faktor\n'
                '• Pemantauan keamanan berkelanjutan\n'
                '• Akses terbatas pada data pribadi\n'
                '• Backup data reguler dengan enkripsi',
              ),
              
              _buildSection(
                '5. Hak Pengguna',
                'Anda memiliki hak untuk:\n\n'
                '• Mengakses informasi pribadi yang kami simpan\n'
                '• Memperbarui atau mengoreksi informasi Anda\n'
                '• Menghapus akun dan data pribadi Anda\n'
                '• Membatasi pemrosesan data tertentu\n'
                '• Memindahkan data Anda ke layanan lain\n'
                '• Menarik persetujuan kapan saja',
              ),
              
              _buildSection(
                '6. Penyimpanan Data',
                'Kami menyimpan informasi pribadi Anda selama:\n\n'
                '• Akun Anda aktif\n'
                '• Diperlukan untuk menyediakan layanan\n'
                '• Diwajibkan oleh hukum yang berlaku\n'
                '• Diperlukan untuk tujuan bisnis yang sah\n\n'
                'Setelah periode ini, data akan dihapus secara aman.',
              ),
              
              _buildSection(
                '7. Cookies dan Teknologi Pelacakan',
                'Aplikasi kami menggunakan teknologi berikut:\n\n'
                '• Cookies untuk menyimpan preferensi pengguna\n'
                '• Analytics untuk memahami penggunaan aplikasi\n'
                '• Crash reporting untuk meningkatkan stabilitas\n'
                '• Push notifications untuk komunikasi penting\n\n'
                'Anda dapat mengelola preferensi ini melalui pengaturan aplikasi.',
              ),
              
              _buildSection(
                '8. Layanan Pihak Ketiga',
                'Aplikasi kami terintegrasi dengan layanan pihak ketiga:\n\n'
                '• Firebase (Google) untuk autentikasi dan database\n'
                '• Google Analytics untuk analisis penggunaan\n'
                '• Layanan cloud untuk penyimpanan data\n\n'
                'Setiap layanan memiliki kebijakan privasi tersendiri yang dapat Anda tinjau.',
              ),
              
              _buildSection(
                '9. Perubahan Kebijakan',
                'Kami dapat memperbarui kebijakan privasi ini dari waktu ke waktu. Perubahan akan diberitahukan melalui:\n\n'
                '• Notifikasi dalam aplikasi\n'
                '• Email ke alamat terdaftar\n'
                '• Pengumuman di halaman utama\n\n'
                'Penggunaan berkelanjutan setelah perubahan menunjukkan persetujuan Anda.',
              ),
              
              _buildSection(
                '10. Kontak',
                'Jika Anda memiliki pertanyaan tentang kebijakan privasi ini, silakan hubungi kami:\n\n'
                '• Email: privacy@seangkatan.id\n'
                '• Alamat: [Alamat Perusahaan]\n'
                '• Telepon: [Nomor Telepon]\n\n'
                'Kami akan merespons pertanyaan Anda dalam waktu 7 hari kerja.',
              ),
              
              const SizedBox(height: 24),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.info,
                          color: Color(0xFF4F46E5),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Penting',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dengan menggunakan aplikasi Seangkatan.id, Anda menyetujui pengumpulan dan penggunaan informasi sesuai dengan kebijakan privasi ini. Jika Anda tidak setuju dengan kebijakan ini, harap berhenti menggunakan aplikasi kami.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF475569),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}