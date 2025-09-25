import 'package:flutter/material.dart';
import '../../models/ai_chat_models.dart';
import '../../services/ai_chat_service.dart';

class AIChatConfigScreen extends StatefulWidget {
  const AIChatConfigScreen({super.key});

  @override
  State<AIChatConfigScreen> createState() => _AIChatConfigScreenState();
}

class _AIChatConfigScreenState extends State<AIChatConfigScreen> {
  final AIChatService _aiChatService = AIChatService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  
  String _selectedModel = 'gpt-3.5-turbo';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _obscureApiKey = true;
  
  AIChatConfig? _currentConfig;
  List<AIChatConfig> _allConfigs = [];
  Map<String, dynamic> _statistics = {};

  final List<String> _availableModels = [
    'gpt-3.5-turbo',
    'gpt-3.5-turbo-16k',
    'gpt-4',
    'gpt-4-turbo-preview',
  ];

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
    _loadStatistics();
    _systemPromptController.text = AIChatConfig.defaultSystemPrompt;
    _maxTokensController.text = '1000';
    _temperatureController.text = '0.7';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    _maxTokensController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigurations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await _aiChatService.getAllConfigs();
      final activeConfig = await _aiChatService.getActiveConfig();
      
      setState(() {
        _allConfigs = configs;
        _currentConfig = activeConfig;
        
        if (activeConfig != null) {
          _apiKeyController.text = activeConfig.apiKey;
          _selectedModel = activeConfig.model;
          _maxTokensController.text = activeConfig.maxTokens.toString();
          _temperatureController.text = activeConfig.temperature.toString();
          _systemPromptController.text = activeConfig.systemPrompt;
          _isActive = activeConfig.isActive;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat konfigurasi: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _aiChatService.getChatStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final config = AIChatConfig(
        id: _currentConfig?.id ?? '',
        apiKey: _apiKeyController.text.trim(),
        model: _selectedModel,
        temperature: double.parse(_temperatureController.text),
        maxTokens: int.parse(_maxTokensController.text),
        systemPrompt: _systemPromptController.text.trim(),
        isActive: _isActive,
        createdAt: _currentConfig?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: _currentConfig?.createdBy ?? 'admin', // Should be current admin ID
      );

      final configId = await _aiChatService.saveConfig(config);
      
      if (configId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfigurasi berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        _loadConfigurations();
      } else {
        _showErrorSnackBar('Gagal menyimpan konfigurasi');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showErrorSnackBar('Masukkan API Key terlebih dahulu');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create temporary config for testing
      final tempConfig = AIChatConfig(
        id: 'temp',
        apiKey: _apiKeyController.text.trim(),
        model: _selectedModel,
        temperature: double.parse(_temperatureController.text),
        maxTokens: int.parse(_maxTokensController.text),
        systemPrompt: _systemPromptController.text.trim(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin',
      );

      // Save temporarily and test
      await _aiChatService.saveConfig(tempConfig);
      final response = await _aiChatService.sendMessageToAI('Halo, ini adalah tes koneksi.');
      
      if (response != null && response.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Koneksi Berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('API Key valid dan koneksi berhasil!'),
                const SizedBox(height: 16),
                const Text('Respons AI:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    response,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
        builder: (context) => AlertDialog(
            title: const Text('❌ Koneksi Gagal'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteConfiguration(String configId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Konfigurasi'),
        content: const Text('Apakah Anda yakin ingin menghapus konfigurasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _aiChatService.deleteConfig(configId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfigurasi berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadConfigurations();
      } else {
        _showErrorSnackBar('Gagal menghapus konfigurasi');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetToDefault() {
    setState(() {
      _systemPromptController.text = AIChatConfig.defaultSystemPrompt;
      _selectedModel = 'gpt-3.5-turbo';
      _maxTokensController.text = '1000';
      _temperatureController.text = '0.7';
      _isActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi AI Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _loadConfigurations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsCard(),
                  const SizedBox(height: 24),
                  _buildConfigurationForm(),
                  const SizedBox(height: 24),
                  _buildConfigurationHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik AI Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Pesan',
                    _statistics['totalMessages']?.toString() ?? '0',
                    Icons.chat_bubble_outline,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pengguna Aktif',
                    _statistics['uniqueUsers']?.toString() ?? '0',
                    Icons.people_outline,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_statistics['messagesByType'] != null) ...[
              const Text(
                'Kategori Pesan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._statistics['messagesByType'].entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_getCategoryName(entry.key)),
                      Text(entry.value.toString()),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String key) {
    switch (key) {
      case 'studyTips':
        return 'Tips Belajar';
      case 'antiBullying':
        return 'Anti-Bullying';
      case 'socialMediaLiteracy':
        return 'Literasi Medsos';
      case 'general':
        return 'Umum';
      default:
        return key;
    }
  }

  Widget _buildConfigurationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Konfigurasi API',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetToDefault,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset Default'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // API Key
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'OpenAI API Key *',
                  hintText: 'sk-...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                obscureText: _obscureApiKey,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'API Key wajib diisi';
                  }
                  if (!value.startsWith('sk-')) {
                    return 'API Key harus dimulai dengan "sk-"';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Model Selection
              DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: const InputDecoration(
                  labelText: 'Model AI',
                  border: OutlineInputBorder(),
                ),
                items: _availableModels.map((model) => DropdownMenuItem(
                  value: model,
                  child: Text(model),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedModel = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Temperature and Max Tokens
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _temperatureController,
                      decoration: const InputDecoration(
                        labelText: 'Temperature',
                        hintText: '0.0 - 2.0',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Wajib diisi';
                        final temp = double.tryParse(value);
                        if (temp == null || temp < 0 || temp > 2) {
                          return 'Nilai 0.0 - 2.0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxTokensController,
                      decoration: const InputDecoration(
                        labelText: 'Max Tokens',
                        hintText: '1 - 4000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Wajib diisi';
                        final tokens = int.tryParse(value);
                        if (tokens == null || tokens < 1 || tokens > 4000) {
                          return 'Nilai 1 - 4000';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // System Prompt
              TextFormField(
                controller: _systemPromptController,
                decoration: const InputDecoration(
                  labelText: 'System Prompt *',
                  hintText: 'Instruksi untuk AI sebagai wali kelas...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'System prompt wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Active Status
              SwitchListTile(
                title: const Text('Aktifkan AI Chat'),
                subtitle: const Text('Siswa dapat menggunakan fitur AI Chat'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _testConnection,
                      icon: const Icon(Icons.wifi_protected_setup),
                      label: const Text('Test Koneksi'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveConfiguration,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationHistory() {
    if (_allConfigs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Konfigurasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allConfigs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final config = _allConfigs[index];
                final isActive = config.isActive;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.grey,
                    child: Icon(
                      isActive ? Icons.check : Icons.pause,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    config.model,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dibuat: ${_formatDate(config.createdAt)}'),
                      Text('Diperbarui: ${_formatDate(config.updatedAt)}'),
                      Text('Status: ${isActive ? "Aktif" : "Tidak Aktif"}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          _deleteConfiguration(config.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}