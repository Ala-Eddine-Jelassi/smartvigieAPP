import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_vigie/utils/Appcolors.dart';

class TemperatureChart extends StatefulWidget {
  const TemperatureChart({super.key});

  @override
  State<TemperatureChart> createState() => _TemperatureChartState();
}

class _TemperatureChartState extends State<TemperatureChart> {
  bool _showTemperature = true;
  List<FlSpot> _temperatureSpots = [];
  List<FlSpot> _humiditySpots = [];
  List<String> _timestamps = []; // Store timestamps for x-axis labels
  bool _isLoading = true;
  String _errorMessage = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final DateFormat _timeFormat = DateFormat('HH:mm');
  final DateFormat _fullDateFormat = DateFormat('dd/MM HH:mm');

  @override
  void initState() {
    super.initState();
    _loadSensorData();
  }

  Future<void> _loadSensorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // FIXED: Changed collection name to 'sensor_readings' (from 'Read Sensor')
      // Also using 'createdAt' field instead of 'timestamp' based on your database service
      QuerySnapshot querySnapshot = await _firestore
          .collection('sensor_readings')  // Changed from 'Read Sensor'
          .orderBy('createdAt', descending: true)  // Changed from 'timestamp' to 'createdAt'
          .limit(30)  // Increased limit to show more data points
          .get();

      List<FlSpot> tempSpots = [];
      List<FlSpot> humiditySpots = [];
      List<String> timestamps = [];

      // Reverse to show oldest to newest (left to right)
      List<DocumentSnapshot> docs = querySnapshot.docs.reversed.toList();

      for (int i = 0; i < docs.length; i++) {
        var data = docs[i].data() as Map<String, dynamic>;

        // Extract data with null safety
        double temperature = (data['temperature'] ?? 0.0).toDouble();
        double humidity = (data['humidity'] ?? 0.0).toDouble();

        // Handle timestamp - try multiple possible field names
        DateTime timestamp;
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            timestamp = (data['createdAt'] as Timestamp).toDate();
          } else if (data['createdAt'] is DateTime) {
            timestamp = data['createdAt'];
          } else {
            timestamp = DateTime.now();
          }
        } else if (data['timestamp'] != null) {
          if (data['timestamp'] is Timestamp) {
            timestamp = (data['timestamp'] as Timestamp).toDate();
          } else if (data['timestamp'] is String) {
            timestamp = DateTime.parse(data['timestamp']);
          } else {
            timestamp = DateTime.now();
          }
        } else {
          timestamp = DateTime.now();
        }

        tempSpots.add(FlSpot(i.toDouble(), temperature));
        humiditySpots.add(FlSpot(i.toDouble(), humidity));
        timestamps.add(_timeFormat.format(timestamp));
      }

      // If no data found, try alternative collection 'sensor_history'
      if (tempSpots.isEmpty) {
        print('No data in sensor_readings, trying sensor_history...');
        QuerySnapshot historySnapshot = await _firestore
            .collection('sensor_history')
            .orderBy('createdAt', descending: true)
            .limit(30)
            .get();

        List<DocumentSnapshot> historyDocs = historySnapshot.docs.reversed.toList();

        for (int i = 0; i < historyDocs.length; i++) {
          var data = historyDocs[i].data() as Map<String, dynamic>;

          double temperature = (data['temperature'] ?? 0.0).toDouble();
          double humidity = (data['humidity'] ?? 0.0).toDouble();

          DateTime timestamp;
          if (data['createdAt'] != null) {
            if (data['createdAt'] is Timestamp) {
              timestamp = (data['createdAt'] as Timestamp).toDate();
            } else if (data['createdAt'] is DateTime) {
              timestamp = data['createdAt'];
            } else {
              timestamp = DateTime.now();
            }
          } else if (data['timestamp'] != null) {
            if (data['timestamp'] is Timestamp) {
              timestamp = (data['timestamp'] as Timestamp).toDate();
            } else if (data['timestamp'] is String) {
              timestamp = DateTime.parse(data['timestamp']);
            } else {
              timestamp = DateTime.now();
            }
          } else {
            timestamp = DateTime.now();
          }

          tempSpots.add(FlSpot(i.toDouble(), temperature));
          humiditySpots.add(FlSpot(i.toDouble(), humidity));
          timestamps.add(_timeFormat.format(timestamp));
        }
      }

      setState(() {
        _temperatureSpots = tempSpots;
        _humiditySpots = humiditySpots;
        _timestamps = timestamps;
        _isLoading = false;
        
        if (tempSpots.isEmpty) {
          _errorMessage = 'No sensor data found in database. Please wait for ESP32 to send data.';
        }
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
      print('Error loading sensor data: $e');
    }
  }

  List<FlSpot> get _currentSpots {
    return _showTemperature ? _temperatureSpots : _humiditySpots;
  }

  String get _chartTitle {
    return _showTemperature ? 'Temperature (°C)' : 'Humidity (%)';
  }

  Color get _chartColor {
    return _showTemperature ? Colors.orange : Colors.blue;
  }

  double get _maxY {
    if (_currentSpots.isEmpty) return _showTemperature ? 50 : 100;
    double maxValue = _currentSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxValue + 5).ceilToDouble();
  }

  double get _minY {
    if (_currentSpots.isEmpty) return 0;
    double minValue = _currentSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    return (minValue - 5).floorToDouble().clamp(0.0, double.infinity);
  }

  Future<void> _refreshData() async {
    await _loadSensorData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _currentSpots.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Column(
                children: [
                  // Toggle buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToggleButton('Temperature', true),
                        const SizedBox(width: 16),
                        _buildToggleButton('Humidity', false),
                      ],
                    ),
                  ),

                  // Chart
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chart title
                              Text(
                                _chartTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Chart
                              Expanded(
                                child: _currentSpots.isEmpty
                                    ? const Center(
                                        child: Text('No data available'),
                                      )
                                    : LineChart(
                                        _buildLineChartData(),
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeInOut,
                                      ),
                              ),

                              // Statistics
                              const SizedBox(height: 16),
                              _buildStatistics(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
            floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        backgroundColor: Appcolors.secondColor,
        foregroundColor: Appcolors.backgroundColor,
        onPressed: _refreshData,
          
      ),
    );
  }

  // Build toggle button
  Widget _buildToggleButton(String label, bool isTemperature) {
    bool isSelected = _showTemperature == isTemperature;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showTemperature = isTemperature;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build statistics
  Widget _buildStatistics() {
    if (_currentSpots.isEmpty) return const SizedBox();

    double currentValue = _currentSpots.last.y;
    double maxValue = _currentSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    double minValue = _currentSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double averageValue = _currentSpots.map((spot) => spot.y).reduce((a, b) => a + b) / _currentSpots.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Current', '${currentValue.toStringAsFixed(1)}${_showTemperature ? '°C' : '%'}', Colors.green),
          _buildStatItem('Max', '${maxValue.toStringAsFixed(1)}${_showTemperature ? '°C' : '%'}', Colors.red),
          _buildStatItem('Min', '${minValue.toStringAsFixed(1)}${_showTemperature ? '°C' : '%'}', Colors.blue),
          _buildStatItem('Avg', '${averageValue.toStringAsFixed(1)}${_showTemperature ? '°C' : '%'}', Colors.orange),
        ],
      ),
    );
  }

  // Build stat item
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Build line chart data
  LineChartData _buildLineChartData() {
    return LineChartData(
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: true,
        horizontalInterval: _showTemperature ? 10 : 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: _getInterval(),
            getTitlesWidget: _getBottomTitles,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _showTemperature ? 10 : 20,
            getTitlesWidget: _getLeftTitles,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _currentSpots,
          isCurved: true,
          curveSmoothness: 0.3,
          barWidth: 3,
          color: _chartColor,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: _chartColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: _chartColor.withOpacity(0.1),
          ),
          aboveBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot spot) {
              int index = spot.spotIndex.toInt();
              String value = '${spot.y.toStringAsFixed(1)}${_showTemperature ? '°C' : '%'}';
              String time = index < _timestamps.length ? _timestamps[index] : '';
              
              return LineTooltipItem(
                '$value\n$time',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
          getTooltipColor: (touchedSpot) => _chartColor,
          tooltipHorizontalOffset: 8,
          tooltipRoundedRadius: 8,
        ),
        handleBuiltInTouches: true,
      ),
      minX: 0,
      maxX: _currentSpots.isEmpty ? 1 : (_currentSpots.length - 1).toDouble(),
      minY: _minY,
      maxY: _maxY,
    );
  }

  // Get interval for x-axis
  double _getInterval() {
    if (_currentSpots.length <= 5) return 1;
    if (_currentSpots.length <= 10) return 2;
    if (_currentSpots.length <= 20) return 3;
    return 5;
  }

  // Get bottom titles (x-axis) - shows time
  Widget _getBottomTitles(double value, TitleMeta meta) {
    int index = value.toInt();
    if (index < 0 || index >= _timestamps.length) {
      return const SizedBox();
    }

    String label = _timestamps[index];
    
    // Show fewer labels on small screens
    if (_currentSpots.length > 15 && index % 2 != 0) {
      return const SizedBox();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Transform.rotate(
        angle: -0.5, // Rotate for better readability
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // Get left titles (y-axis)
  Widget _getLeftTitles(double value, TitleMeta meta) {
    String label = value.toInt().toString();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }
}