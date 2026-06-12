import 'package:flutter/material.dart';
import '../services/tamper_check.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TamperResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() => _loading = true);
    final result = await TamperCheck.runAllChecks();
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Anti Tamper',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _runChecks,
          )
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent))
          : _buildResult(),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: r.passed
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: r.passed ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                r.passed ? Icons.verified_user : Icons.gpp_bad,
                size: 64,
                color: r.passed ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(height: 8),
              Text(
                r.passed ? 'APP IS SECURE' : 'TAMPER DETECTED',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: r.passed ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Security Checks',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // اعرض كل الـ checks من failedChecks
        ...r.failedChecks.map((c) => _checkTile(c, false)),
      ],
    );
  }

  Widget _checkTile(CheckResult c, bool passed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: passed ? Colors.greenAccent.withOpacity(0.3)
                        : Colors.redAccent.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.greenAccent : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(c.detail,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
