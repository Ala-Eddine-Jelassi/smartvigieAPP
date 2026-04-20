import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_vigie/firebase/database_services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_vigie/utils/Appcolors.dart';

class HistoryPage extends StatefulWidget {
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseServices _firebaseService = DatabaseServices();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getAllReadings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No data yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const Text(
                    'Wait for sensor data to arrive',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportToCSV,
                    icon: const Icon(Icons.download),
                    label: const Text('Export to CSV'),
                  ),
                ],
              ),
            );
          }
          
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Row(
                        children: [
                          const Icon(Icons.thermostat, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            '${(data['temperature'] ?? 0).toStringAsFixed(1)}°C',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('${data['humidity'] ?? 0}%'),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTimestamp(data['timestamp'] ?? data['createdAt']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showDetailsDialog(context, data);
                      },
                    ),
                  );
                },
              ),
              if (_isExporting)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Exporting data...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
     
  floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
            floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.download),
        backgroundColor: Appcolors.secondColor,
        foregroundColor: Appcolors.backgroundColor,
        onPressed: _exportToCSV,
           
    
          
      ),
    );
  }
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      return timestamp;
    }
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp.toDate());
    }
    return 'Unknown time';
  }
  
  // Export all data to CSV (without permission_handler)
  Future<void> _exportToCSV() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Fetch all data from Firestore
      final querySnapshot = await _firebaseService.getAllReadings().first;
      final docs = querySnapshot.docs;
      
      if (docs.isEmpty) {
        _showMessage('No data to export');
        setState(() {
          _isExporting = false;
        });
        return;
      }

      // Create CSV content
      String csvContent = _buildCSVContent(docs);
      
      // Save to app-specific directory (no permission needed!)
      final String fileName = 'sensor_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent);
      
      // Share the file - this will open system share dialog
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sensor Data Export',
        subject: 'Sensor History Data',
      );
      
      _showMessage('Export completed! File saved to: ${directory.path}');
      
    } catch (e) {
      print('Export error: $e');
      _showMessage('Error exporting data: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  // Build CSV content from Firestore documents
  String _buildCSVContent(List<QueryDocumentSnapshot> docs) {
    // CSV Header
    String csv = 'Index,Temperature (°C),Humidity (%),Timestamp,Zone,Client ID,Recorded Date\n';
    
    // Add data rows
    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data() as Map<String, dynamic>;
      
      final index = i + 1;
      final temperature = (data['temperature'] ?? 0).toStringAsFixed(1);
      final humidity = data['humidity'] ?? 0;
      final timestamp = _formatTimestamp(data['timestamp'] ?? data['createdAt']);
      final zone = data['zone'] ?? 1;
      final clientId = data['clientId'] ?? 'ESP32';
      final recordedAt = _formatTimestamp(data['createdAt']);
      
      csv += '$index,$temperature,$humidity,"$timestamp",$zone,$clientId,"$recordedAt"\n';
    }
    
    return csv;
  }

  // Show message to user
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sensor Details - Zone ${data['zone'] ?? 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Temperature', '${(data['temperature'] ?? 0).toStringAsFixed(1)}°C', Icons.thermostat, Colors.red),
            const SizedBox(height: 8),
            _buildDetailRow('Humidity', '${data['humidity'] ?? 0}%', Icons.water_drop, Colors.blue),
            const SizedBox(height: 8),
            _buildDetailRow('Timestamp', data['timestamp'] ?? 'Unknown', Icons.access_time, Colors.grey),
            const SizedBox(height: 8),
            _buildDetailRow('Client ID', data['clientId'] ?? 'ESP32', Icons.devices, Colors.grey),
            const SizedBox(height: 8),
            _buildDetailRow('Recorded', _formatTimestamp(data['createdAt']), Icons.save, Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}